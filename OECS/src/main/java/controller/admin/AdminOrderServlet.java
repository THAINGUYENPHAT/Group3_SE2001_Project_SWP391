package controller.admin;

import dao.AdminOrderDAO;
import model.Order;
import model.OrderItem;
import dao.NotificationDAO;
import model.User;
import service.AuditLogService;

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

    private static final Logger LOGGER
            = Logger.getLogger(AdminOrderServlet.class.getName());

    private AdminOrderDAO orderDAO;
    private NotificationDAO notificationDAO;

    private final AuditLogService auditLogService
            = new AuditLogService();

    @Override
    public void init() {
        orderDAO = new AdminOrderDAO();
        notificationDAO = new NotificationDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String path = request.getPathInfo();

        if (path != null && "/detail".equals(path)) {
            // 1. CHI TIẾT ĐƠN HÀNG
            try {
                int orderId = Integer.parseInt(
                        request.getParameter("id")
                );

                Order order = orderDAO.getById(orderId);
                List<OrderItem> items
                        = orderDAO.getItemsByOrderId(orderId);
                String status = orderDAO.getCurrentStatus(orderId);

                if (status == null && order != null) {
                    status = order.getOrderStatus();
                }

                request.setAttribute("order", order);
                request.setAttribute("items", items);
                request.setAttribute("status", status);

                request.getRequestDispatcher(
                        "/WEB-INF/admin/order-detail.jsp"
                ).forward(request, response);

            } catch (NumberFormatException e) {
                LOGGER.log(
                        Level.WARNING,
                        "Order ID không hợp lệ khi xem chi tiết!",
                        e
                );

                response.sendRedirect(
                        request.getContextPath() + "/admin/orders"
                );

            } catch (Exception e) {
                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi khi tải thông tin chi tiết đơn hàng!",
                        e
                );

                response.sendRedirect(
                        request.getContextPath() + "/admin/orders"
                );
            }

        } else {
            // 2. DANH SÁCH ĐƠN HÀNG
            try {
                List<Order> orders = orderDAO.getList();

                request.setAttribute("orders", orders);

                request.getRequestDispatcher(
                        "/WEB-INF/admin/orders.jsp"
                ).forward(request, response);

            } catch (Exception e) {
                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi khi lấy danh sách đơn hàng!",
                        e
                );

                response.sendRedirect(
                        request.getContextPath() + "/admin/dashboard"
                );
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        int orderId;

        try {
            orderId = Integer.parseInt(request.getParameter("orderId"));
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/orders");
            return;
        }

        String action = request.getParameter("action");

        try {
            String current = orderDAO.getCurrentStatus(orderId);
            String nextStatus = null;
            String successMessage = null;

            if (current != null) {
                current = current.trim().toUpperCase();
            }

            if ("PENDING".equals(current)) {
                current = "PENDING_CONFIRMATION";
            }

            if ("confirm".equals(action)) {

                if ("PENDING_CONFIRMATION".equals(current)) {
                    nextStatus = "CONFIRMED";
                    successMessage = "Xác nhận đơn hàng thành công!";
                }

            } else if ("changeStatus".equals(action)) {

                String requested = request.getParameter("status");

                if (requested != null) {
                    requested = requested.trim().toUpperCase();
                }

                String expected = null;

                if ("CONFIRMED".equals(current)) {
                    expected = "PACKING";
                } else if ("PACKING".equals(current)) {
                    expected = "SHIPPING";
                } else if ("SHIPPING".equals(current)) {
                    expected = "COMPLETED";
                }

                if (expected != null && expected.equals(requested)) {
                    nextStatus = expected;
                    successMessage = "Cập nhật trạng thái đơn hàng thành công!";
                }

            } else if ("cancel".equals(action)) {

                if ("PENDING_CONFIRMATION".equals(current)
                        || "CONFIRMED".equals(current)
                        || "PACKING".equals(current)
                        || "SHIPPING".equals(current)) {

                    nextStatus = "CANCELLED";
                    successMessage = "Hủy đơn hàng thành công!";
                }
            }

            if (nextStatus == null) {

                request.getSession().setAttribute(
                        "errorMessage",
                        "Không thể cập nhật! Vui lòng thực hiện đúng trình tự: "
                        + "Confirmed → Packing → Shipping → Completed."
                );

            } else if (orderDAO.transitionStatus(orderId, nextStatus)) {

                request.getSession().setAttribute(
                        "successMessage",
                        successMessage
                );

                User loggedInUser
                        = (User) request.getSession()
                                .getAttribute("loggedInUser");

                if ("CANCELLED".equals(nextStatus)) {

                    auditLogService.log(
                            loggedInUser,
                            "CANCEL_ORDER",
                            "ORDER",
                            (long) orderId,
                            "Cancelled order #" + orderId
                            + " from status " + current,
                            request
                    );

                } else {

                    auditLogService.log(
                            loggedInUser,
                            "UPDATE_ORDER_STATUS",
                            "ORDER",
                            (long) orderId,
                            "Changed order #" + orderId
                            + " status from "
                            + current
                            + " to "
                            + nextStatus,
                            request
                    );
                }

                try {
                    boolean notified = notificationDAO
                            .createOrderStatusNotification(orderId, nextStatus);

                    if (!notified) {
                        LOGGER.warning(
                                "Không tạo được thông báo cho đơn hàng #" + orderId
                        );
                    }
                } catch (Exception notificationError) {
                    LOGGER.log(
                            Level.WARNING,
                            "Lỗi tạo thông báo cho đơn hàng #" + orderId,
                            notificationError
                    );
                }

            } else {

                request.getSession().setAttribute(
                        "errorMessage",
                        "Không thể chuyển trạng thái. Vui lòng tải lại đơn hàng!"
                );
            }

        } catch (Exception e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi cập nhật trạng thái đơn hàng #" + orderId,
                    e
            );

            request.getSession().setAttribute(
                    "errorMessage",
                    "Thao tác thất bại! Vui lòng kiểm tra lại."
            );
        }

        response.sendRedirect(
                request.getContextPath()
                + "/admin/orders/detail?id=" + orderId
        );
    }
}
