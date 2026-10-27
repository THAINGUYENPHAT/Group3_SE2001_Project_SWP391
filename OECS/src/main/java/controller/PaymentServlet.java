package controller;

import dao.OrderDAO;
import dao.PaymentDAO;

import model.Order;
import model.User;

import payment.PaymentGateway;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "PaymentServlet",
        urlPatterns = {
            "/payment",
            "/payment/action"
        }
)
public class PaymentServlet extends HttpServlet {

    private static final Logger LOGGER =
            Logger.getLogger(PaymentServlet.class.getName());

    private final PaymentDAO payments = new PaymentDAO();
    private final OrderDAO orders = new OrderDAO();

    // Kiem tra dang nhap va quyen Customer
    private User customer(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        HttpSession session = request.getSession(false);

        Object value = session == null
                ? null
                : session.getAttribute("loggedInUser");

        if (!(value instanceof User)) {
            request.getSession().setAttribute(
                    "redirectUrl",
                    request.getContextPath() + "/my-orders"
            );

            response.sendRedirect(
                    request.getContextPath() + "/login"
            );

            return null;
        }

        User user = (User) value;

        if (!user.isCustomer()) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN
            );

            return null;
        }

        return user;
    }

    private int getOrderId(HttpServletRequest request) {
        try {
            return Integer.parseInt(
                    request.getParameter("id")
            );
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    // Hien thi trang thanh toan
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        User user = customer(request, response);

        if (user == null) {
            return;
        }

        if (!"/payment".equals(request.getServletPath())) {
            response.setHeader("Allow", "POST");
            response.sendError(
                    HttpServletResponse.SC_METHOD_NOT_ALLOWED
            );
            return;
        }

        try {
            int orderId = getOrderId(request);

            Order order = orders.findByIdAndUser(
                    orderId,
                    user.getUserId()
            );

            if (order == null) {
                response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "Không tìm thấy đơn hàng."
                );
                return;
            }

            // Kiem tra het han truoc khi hien thi
            payments.expireOrder(
                    user.getUserId(),
                    orderId
            );

            order = orders.findByIdAndUser(
                    orderId,
                    user.getUserId()
            );

            if (order == null) {
                response.sendError(
                        HttpServletResponse.SC_NOT_FOUND
                );
                return;
            }

            if (!"PENDING_PAYMENT".equals(
                    order.getOrderStatus()
            )) {
                response.sendRedirect(
                        request.getContextPath()
                        + "/my-orders/detail?id="
                        + orderId
                );
                return;
            }

            HttpSession session = request.getSession();

            synchronized (session) {
                if (session.getAttribute("paymentCsrf") == null) {
                    session.setAttribute(
                            "paymentCsrf",
                            UUID.randomUUID().toString()
                    );
                }
            }

            request.setAttribute("order", order);

            request.getRequestDispatcher(
                    "/WEB-INF/checkout/payment.jsp"
            ).forward(request, response);

        } catch (IllegalArgumentException e) {
            response.sendError(
                    HttpServletResponse.SC_NOT_FOUND,
                    "Không tìm thấy đơn hàng."
            );

        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Không tải được trang thanh toán.",
                    e
            );

            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Chưa tải được thanh toán. Vui lòng thử lại."
            );
        }
    }

    // Thanh toan, doi COD hoac huy don
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        request.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");

        User user = customer(request, response);

        if (user == null) {
            return;
        }

        if (!"/payment/action".equals(
                request.getServletPath()
        )) {
            response.setHeader("Allow", "GET");
            response.sendError(
                    HttpServletResponse.SC_METHOD_NOT_ALLOWED
            );
            return;
        }

        HttpSession session = request.getSession();

        String token = request.getParameter("csrfToken");

        if (token == null
                || !token.equals(
                        session.getAttribute("paymentCsrf")
                )) {

            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Yêu cầu không hợp lệ. Vui lòng tải lại trang."
            );
            return;
        }

        int orderId = getOrderId(request);

        if (orderId <= 0) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Mã đơn hàng không hợp lệ."
            );
            return;
        }

        try {
            String action = request.getParameter("action");

            if ("pay".equals(action)) {

                PaymentDAO.Attempt attempt = payments.begin(
                        user.getUserId(),
                        orderId
                );

                String paymentUrl = attempt.url;

                // Chua co link thi tao yeu cau toi cong sandbox
                if (paymentUrl == null) {
                    paymentUrl = PaymentGateway.create(
                            attempt.method,
                            attempt.ref,
                            attempt.amount,
                            attempt.seconds,
                            request.getRemoteAddr()
                    );

                    payments.saveUrl(
                            attempt.ref,
                            paymentUrl
                    );
                }

                response.setStatus(
                        HttpServletResponse.SC_SEE_OTHER
                );

                response.setHeader(
                        "Location",
                        paymentUrl
                );

                return;

            } else if ("cod".equals(action)
                    || "cancel".equals(action)) {

                payments.changeOrCancel(
                        user.getUserId(),
                        orderId,
                        "cod".equals(action)
                );

                response.setStatus(
                        HttpServletResponse.SC_SEE_OTHER
                );

                response.setHeader(
                        "Location",
                        request.getContextPath()
                        + "/my-orders/detail?id="
                        + orderId
                );

                return;

            } else {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "Thao tác không hợp lệ."
                );
                return;
            }

        } catch (IllegalArgumentException e) {
            session.setAttribute(
                    "paymentError",
                    e.getMessage()
            );

        } catch (Exception e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }

            LOGGER.log(
                    Level.WARNING,
                    "Không khởi tạo được thanh toán.",
                    e
            );

            session.setAttribute(
                    "paymentError",
                    "Chưa mở được cổng thanh toán. "
                    + "Đơn vẫn được giữ đến hạn; "
                    + "thử lại sau 30 giây hoặc đổi COD."
            );
        }

        response.setStatus(
                HttpServletResponse.SC_SEE_OTHER
        );

        response.setHeader(
                "Location",
                request.getContextPath()
                + "/payment?id="
                + orderId
        );
    }
}
