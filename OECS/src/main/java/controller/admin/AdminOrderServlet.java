package controller;

import dao.AdminOrderDAO;
import model.Order;
import model.OrderItem;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "AdminOrderServlet", urlPatterns = "/admin/orders/*")
public class AdminOrderServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(AdminOrderServlet.class.getName());
    private AdminOrderDAO orderDAO;

    @Override
    public void init() {
        orderDAO = new AdminOrderDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String path = request.getPathInfo();

        if (path != null && "/detail".equals(path)) {
            // =====================================================
            // 1. CHI TIẾT ĐƠN HÀNG
            // =====================================================
            try {
                int orderId = Integer.parseInt(request.getParameter("id"));

                Order order = orderDAO.getById(orderId);
                List<OrderItem> items = orderDAO.getItemsByOrderId(orderId);
                String status = orderDAO.getCurrentStatus(orderId);

                request.setAttribute("order", order);
                request.setAttribute("items", items);
                request.setAttribute("status", status);

                request.getRequestDispatcher("/WEB-INF/admin/order-detail.jsp").forward(request, response);
            } catch (NumberFormatException e) {
                LOGGER.log(Level.WARNING, "Order ID không hợp lệ khi xem chi tiết!", e);
                response.sendRedirect(request.getContextPath() + "/admin/orders");
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi khi tải thông tin chi tiết đơn hàng!", e);
                response.sendRedirect(request.getContextPath() + "/admin/orders");
            }

        } else {
            // =====================================================
            // 2. DANH SÁCH ĐƠN HÀNG
            // =====================================================
            try {
                List<Order> orders = orderDAO.getList();
                request.setAttribute("orders", orders);

                request.getRequestDispatcher("/WEB-INF/admin/orders.jsp").forward(request, response);
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi khi lấy danh sách đơn hàng!", e);
                response.sendRedirect(request.getContextPath() + "/admin/dashboard");
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            int orderId = Integer.parseInt(request.getParameter("orderId"));

            if ("confirm".equals(action)) {
                // =====================================================
                // 1. XÁC NHẬN ĐƠN HÀNG
                // =====================================================
                orderDAO.updateStatus(orderId, "Confirmed");

            } else if ("cancel".equals(action)) {
                // =====================================================
                // 2. HỦY ĐƠN HÀNG
                // =====================================================
                orderDAO.cancelOrder(orderId);

            } else if ("changeStatus".equals(action)) {
                // =====================================================
                // 3. THAY ĐỔI TRẠNG THÁI ĐƠN HÀNG
                // =====================================================
                String status = request.getParameter("status");
                if (status != null && !status.trim().isEmpty()) {
                    orderDAO.updateStatus(orderId, status);
                }
            }

            response.sendRedirect(request.getContextPath() + "/admin/orders/detail?id=" + orderId);

        } catch (NumberFormatException e) {
            LOGGER.log(Level.WARNING, "Order ID không hợp lệ khi thực hiện action đơn hàng!", e);
            response.sendRedirect(request.getContextPath() + "/admin/orders");
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi cập nhật trạng thái đơn hàng!", e);
            response.sendRedirect(request.getContextPath() + "/admin/orders");
        }
    }
}