package controller;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import dao.PaymentDAO;
import payment.PaymentGateway;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.Reader;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "PaymentCallbackServlet",
        urlPatterns = {
            "/payment/vnpay/ipn",
            "/payment/momo/ipn",
            "/payment/vnpay/return",
            "/payment/momo/return"
        }
)
public class PaymentCallbackServlet extends HttpServlet {

    private static final Logger LOGGER =
            Logger.getLogger(
                    PaymentCallbackServlet.class.getName()
            );

    private final PaymentDAO payments = new PaymentDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        String path = request.getServletPath();

        // Return hien thi ket qua da xac minh; IPN van cap nhat don hang.
        if (path.endsWith("/return")) {
            showReturnResult(request, response);
            return;
        }

        // VNPay gui IPN bang GET
        if (!"/payment/vnpay/ipn".equals(path)) {
            response.setHeader("Allow", "POST");
            response.sendError(
                    HttpServletResponse.SC_METHOD_NOT_ALLOWED
            );
            return;
        }

        response.setContentType(
                "application/json;charset=UTF-8"
        );

        try {
            Map<String, String> params = new HashMap<>();

            for (Map.Entry<String, String[]> entry
                    : request.getParameterMap().entrySet()) {

                // Chan tham so trung ten
                if (entry.getValue().length != 1) {
                    throw new IllegalArgumentException(
                            "Tham số callback bị trùng."
                    );
                }

                params.put(
                        entry.getKey(),
                        entry.getValue()[0]
                );
            }

            // Xac minh chu ky truoc khi cap nhat database
            if (!PaymentGateway.verifyVnp(params)) {
                sendVnpResponse(response, "97");
                return;
            }

            String providerCode =
                    params.get("vnp_ResponseCode");

            boolean success =
                    "00".equals(providerCode)
                    && "00".equals(
                            params.get("vnp_TransactionStatus")
                    );

            // So tien VNPay tra ve da nhan 100
            BigDecimal amount = new BigDecimal(
                    params.get("vnp_Amount")
            ).movePointLeft(2);

            String result = payments.settle(
                    "VNPAY",
                    params.get("vnp_TxnRef"),
                    amount,
                    params.get("vnp_TransactionNo"),
                    providerCode,
                    success
            );

            sendVnpResponse(response, result);

        } catch (Exception e) {
            LOGGER.log(
                    Level.WARNING,
                    "Không xử lý được VNPay IPN.",
                    e
            );

            sendVnpResponse(response, "99");
        }
    }

    private void showReturnResult(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {
        boolean success = false;
        String message = "Chưa xác minh được kết quả thanh toán. "
                + "Vui lòng kiểm tra trạng thái trong Đơn mua trước khi thử lại.";

        try {
            Map<String, String> params = new HashMap<>();
            for (Map.Entry<String, String[]> entry
                    : request.getParameterMap().entrySet()) {
                if (entry.getValue().length != 1) {
                    throw new IllegalArgumentException("Tham số callback bị trùng.");
                }
                params.put(entry.getKey(), entry.getValue()[0]);
            }

            boolean vnpay = "/payment/vnpay/return".equals(request.getServletPath());
            boolean verified = vnpay
                    ? PaymentGateway.verifyVnp(params)
                    : PaymentGateway.verifyMomo(params);

            if (verified) {
                success = vnpay
                        ? "00".equals(params.get("vnp_ResponseCode"))
                            && "00".equals(params.get("vnp_TransactionStatus"))
                        : "0".equals(params.get("resultCode"));
                message = success
                        ? "Cổng thanh toán đã xác nhận giao dịch thành công. "
                            + "Cảm ơn bạn đã mua sắm tại OECS!"
                        : "Thanh toán chưa hoàn tất hoặc đã bị hủy. "
                            + "Bạn có thể kiểm tra đơn hàng và thanh toán lại trong Đơn mua.";
            }
        } catch (IllegalArgumentException e) {
            LOGGER.warning("Không xác minh được kết quả thanh toán trả về.");
        }

        response.setHeader("Referrer-Policy", "no-referrer");
        request.setAttribute("paymentSuccess", success);
        request.setAttribute("paymentResultMessage", message);
        request.getRequestDispatcher(
                "/WEB-INF/checkout/payment-result.jsp"
        ).forward(request, response);
    }

    private void sendVnpResponse(
            HttpServletResponse response,
            String code
    ) throws IOException {

        String message;

        switch (code) {
            case "00":
                message = "Confirm Success";
                break;

            case "02":
                message = "Already confirmed";
                break;

            case "01":
                message = "Order not found";
                break;

            case "04":
                message = "Invalid amount";
                break;

            case "97":
                message = "Invalid signature";
                break;

            default:
                message = "Unknown error";
                break;
        }

        JsonObject body = new JsonObject();
        body.addProperty("RspCode", code);
        body.addProperty("Message", message);

        response.getWriter().write(body.toString());
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        response.setHeader("Cache-Control", "no-store");

        // MoMo gui IPN bang POST JSON
        if (!"/payment/momo/ipn".equals(
                request.getServletPath()
        )) {
            response.setHeader("Allow", "GET");
            response.sendError(
                    HttpServletResponse.SC_METHOD_NOT_ALLOWED
            );
            return;
        }

        request.setCharacterEncoding("UTF-8");

        try {
            // Gioi han kich thuoc callback
            char[] buffer = new char[16385];

            int total = 0;
            int count;

            Reader reader = request.getReader();

            while (total < buffer.length
                    && (count = reader.read(
                            buffer,
                            total,
                            buffer.length - total
                    )) != -1) {

                total += count;
            }

            if (total > 16384) {
                response.sendError(413);
                return;
            }

            String json = new String(
                    buffer,
                    0,
                    total
            );

            JsonObject body = JsonParser.parseString(
                    json
            ).getAsJsonObject();

            Map<String, String> params = new HashMap<>();

            for (Map.Entry<String, JsonElement> entry
                    : body.entrySet()) {

                if (entry.getValue().isJsonPrimitive()) {
                    params.put(
                            entry.getKey(),
                            entry.getValue().getAsString()
                    );
                }
            }

            // Xac minh merchant, requestId va chu ky
            if (!PaymentGateway.verifyMomo(params)) {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST
                );
                return;
            }

            String providerCode = params.get("resultCode");

            BigDecimal amount = new BigDecimal(
                    params.get("amount")
            );

            String result = payments.settle(
                    "MOMO",
                    params.get("orderId"),
                    amount,
                    params.get("transId"),
                    providerCode,
                    "0".equals(providerCode)
            );

            // Da xu ly hoac callback lap da thanh cong
            if ("00".equals(result)
                    || "02".equals(result)) {

                response.setStatus(
                        HttpServletResponse.SC_NO_CONTENT
                );

            } else {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST
                );
            }

        } catch (SQLException e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi database khi nhận MoMo IPN.",
                    e
            );

            response.sendError(
                    HttpServletResponse.SC_SERVICE_UNAVAILABLE
            );

        } catch (Exception e) {
            LOGGER.log(
                    Level.WARNING,
                    "MoMo IPN không hợp lệ.",
                    e
            );

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST
            );
        }
    }
}
