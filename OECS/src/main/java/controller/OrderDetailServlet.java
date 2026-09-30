package controller;

import dao.OrderDAO;
import db.DBContext;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import model.Order;
import model.OrderItem;
import model.OrderStatusHistory;
import model.User;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;

@WebServlet(
        name = "OrderDetailServlet",
        urlPatterns = {"/order-detail"}
)
public class OrderDetailServlet extends HttpServlet {

    private OrderDAO orderDAO;

    @Override
    public void init() throws ServletException {
        orderDAO = new OrderDAO();
    }

    // ================================
    // HIEN THI CHI TIET DON HANG
    // ================================
    @Override
    protected void doGet(
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

        if (user == null) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/login"
            );

            return;
        }

        String orderIdRaw =
                request.getParameter("id");

        if (orderIdRaw == null
                || orderIdRaw.trim().isEmpty()) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/my-orders"
            );

            return;
        }

        try {

            int orderId =
                    Integer.parseInt(orderIdRaw);

            Connection conn =
                    new DBContext()
                            .getConnection();

            if (conn == null) {

                throw new ServletException(
                        "Khong the ket noi Database."
                );
            }

            try (Connection connection = conn) {

                // Lay order
                Order order =
                        orderDAO.findByIdAndUser(
                                connection,
                                orderId,
                                user.getUserId()
                        );

                if (order == null) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/my-orders"
                    );

                    return;
                }

                // Lay order item
                List<OrderItem> items =
                        orderDAO.findItemsByOrder(
                                connection,
                                orderId
                        );

                // Lay lich su trang thai
                List<OrderStatusHistory> histories =
                        orderDAO.findHistoryByOrder(
                                connection,
                                orderId
                        );

                request.setAttribute(
                        "order",
                        order
                );

                request.setAttribute(
                        "items",
                        items
                );

                request.setAttribute(
                        "histories",
                        histories
                );

                request.getRequestDispatcher(
                        "/WEB-INF/order/order-detail.jsp"
                ).forward(
                        request,
                        response
                );
            }

        } catch (NumberFormatException e) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/my-orders"
            );

        } catch (SQLException e) {

            throw new ServletException(
                    "Loi khi lay chi tiet don hang.",
                    e
            );
        }
    }
}