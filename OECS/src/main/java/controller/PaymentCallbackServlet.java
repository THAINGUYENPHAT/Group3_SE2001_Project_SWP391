package controller;

import com.google.gson.JsonObject;

import dao.PaymentDAO;
import payment.PaymentGateway;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "PaymentCallbackServlet",
        urlPatterns = {
            "/payment/vnpay/ipn",
            "/payment/vnpay/return"
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

        if ("/payment/vnpay/return".equals(path)) {
            showReturnResult(request, response);
            return;
        }

        if (!"/payment/vnpay/ipn".equals(path)) {
            response.setHeader("Allow", "GET");
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

            if (PaymentGateway.verifyVnp(params)) {
                success = "00".equals(params.get("vnp_ResponseCode"))
                        && "00".equals(params.get("vnp_TransactionStatus"));
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
}
