package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import model.User;
import service.OrderService;

import java.io.IOException;

@WebServlet(
        name = "CancelOrderServlet",
        urlPatterns = {"/cancel-order"}
)
public class CancelOrderServlet extends HttpServlet {

    private OrderService orderService;

    @Override
    public void init() throws ServletException {
        orderService = new OrderService();
    }

    // ================================
    // HUY DON HANG
    // ================================
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        HttpSession session =
                request.getSession(false);

        User user = session == null
                ? null
                : (User) session.getAttribute(
                        "loggedInUser"
                );

        // Kiem tra dang nhap
        if (user == null) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/login"
            );

            return;
        }

        try {

            String orderIdRaw =
                    request.getParameter(
                            "orderId"
                    );

            if (orderIdRaw == null
                    || orderIdRaw.trim().isEmpty()) {

                throw new IllegalArgumentException(
                        "Don hang khong hop le."
                );
            }

            int orderId =
                    Integer.parseInt(
                            orderIdRaw
                    );

            // Goi service huy don
            orderService.cancelOrder(
                    orderId,
                    user.getUserId()
            );

            session.setAttribute(
                    "orderMessage",
                    "Hủy đơn hàng thành công."
            );

        } catch (Exception e) {

            session.setAttribute(
                    "orderError",
                    e.getMessage()
            );
        }

        response.sendRedirect(
                request.getContextPath()
                + "/my-orders"
        );
    }
}