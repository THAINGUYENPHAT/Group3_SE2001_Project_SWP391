/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/JSP_Servlet/Servlet.java to edit this template
 */
package controller;

import dao.AdminOrderDAO;
import java.io.IOException;
import java.io.PrintWriter;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.List;
import model.Order;
import model.OrderItem;

/**
 *
 */
@WebServlet(name = "AdminOrderServlet", urlPatterns = "/admin/orders/*")
public class AdminOrderServlet extends HttpServlet {

    private AdminOrderDAO orderDAO;

    @Override
    public void init() {
        orderDAO = new AdminOrderDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String path = request.getPathInfo();

        if (path != null && path.equals("/detail")) {

            int orderId = Integer.parseInt(
                    request.getParameter("id")
            );

            Order order = orderDAO.getById(orderId);

            List<OrderItem> items
                    = orderDAO.getItemsByOrderId(orderId);

            String status
                    = orderDAO.getCurrentStatus(orderId);

            request.setAttribute("order", order);
            request.setAttribute("items", items);
            request.setAttribute("status", status);

            request.getRequestDispatcher(
                    "/WEB-INF/admin/order-detail.jsp"
            ).forward(request, response);

        } else {

            request.setAttribute("orders", orderDAO.getList());

            request.getRequestDispatcher(
                    "/WEB-INF/admin/orders.jsp"
            ).forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        int orderId = Integer.parseInt(
                request.getParameter("orderId")
        );

        if ("confirm".equals(action)) {

            orderDAO.updateStatus(orderId, "Confirmed");

        } else if ("cancel".equals(action)) {

            orderDAO.cancelOrder(orderId);
        } else if ("changeStatus".equals(action)) {

            String status = request.getParameter("status");

            orderDAO.updateStatus(orderId, status);
        }

        response.sendRedirect(
                request.getContextPath()
                + "/admin/orders/detail?id=" + orderId
        );
    }
}
