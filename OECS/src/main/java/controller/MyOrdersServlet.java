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
import model.User;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;

@WebServlet(name = "MyOrdersServlet", urlPatterns = {"/my-orders"})
public class MyOrdersServlet extends HttpServlet {

    private OrderDAO orderDAO;

    @Override
    public void init() throws ServletException {
        orderDAO = new OrderDAO();
    }

    // ================================
    // HIEN THI DANH SACH DON HANG
    // ================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        User user = session == null
                ? null
                : (User) session.getAttribute("loggedInUser");

        // Kiem tra dang nhap
        if (user == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login"
            );
            return;
        }

        Connection conn
                = new DBContext().getConnection();

        if (conn == null) {
            throw new ServletException(
                    "Khong the ket noi Database."
            );
        }

        try (Connection connection = conn) {

            List<Order> orders
                    = orderDAO.findByUser(
                            connection,
                            user.getUserId()
                    );

            request.setAttribute(
                    "orders",
                    orders
            );

            request.getRequestDispatcher(
                    "/WEB-INF/order/my-orders.jsp"
            ).forward(
                    request,
                    response
            );

        } catch (SQLException e) {

            throw new ServletException(
                    "Loi khi lay danh sach don hang.",
                    e
            );
        }
    }
}
