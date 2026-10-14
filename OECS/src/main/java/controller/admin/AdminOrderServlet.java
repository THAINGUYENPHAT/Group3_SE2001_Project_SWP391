package controller.admin;

import dao.AdminOrderDAO;
import dao.NotificationDAO;
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

    private static final Logger LOGGER
            = Logger.getLogger(AdminOrderServlet.class.getName());

    private AdminOrderDAO orderDAO;
    private NotificationDAO notificationDAO;

    @Override
    public void init() {
        orderDAO = new AdminOrderDAO();
        notificationDAO = new NotificationDAO();
    }

    // =========================================================
    // GET
    // =========================================================
    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String path = request.getPathInfo();

        // =====================================================
        // 1. ORDER DETAIL
        // URL: /admin/orders/detail?id=1
        // =====================================================
        if ("/detail".equals(path)) {

            try {
                String idParam = request.getParameter("id");

                if (idParam == null || idParam.trim().isEmpty()) {
                    response.sendRedirect(
                            request.getContextPath() + "/admin/orders"
                    );
                    return;
                }

                int orderId = Integer.parseInt(idParam);

                Order order = orderDAO.getById(orderId);

                if (order == null) {
                    response.sendRedirect(
                            request.getContextPath() + "/admin/orders"
                    );
                    return;
                }

                List<OrderItem> items
                        = orderDAO.getItemsByOrderId(orderId);

                String status = order.getOrderStatus();

                request.setAttribute("order", order);
                request.setAttribute("items", items);
                request.setAttribute("status", status);

                request.getRequestDispatcher(
                        "/WEB-INF/admin/order-detail.jsp"
                ).forward(request, response);

            } catch (NumberFormatException e) {

                LOGGER.log(
                        Level.WARNING,
                        "Order ID khong hop le khi xem chi tiet",
                        e
                );

                response.sendRedirect(
                        request.getContextPath() + "/admin/orders"
                );

            } catch (Exception e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Loi khi tai chi tiet don hang",
                        e
                );

                response.sendRedirect(
                        request.getContextPath() + "/admin/orders"
                );
            }

            return;
        }

        // =====================================================
        // 2. ORDER LIST
        // URL: /admin/orders
        // =====================================================
        try {
            List<Order> orders = orderDAO.getList();

            request.setAttribute("orders", orders);

            request.getRequestDispatcher(
                    "/WEB-INF/admin/orders.jsp"
            ).forward(request, response);

        } catch (Exception e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi khi lay danh sach don hang",
                    e
            );

            response.sendRedirect(
                    request.getContextPath() + "/admin/dashboard"
            );
        }
    }

    // =========================================================
    // POST
    // =========================================================
    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        String orderIdParam = request.getParameter("orderId");

        try {
            // =================================================
            // 1. VALIDATE ORDER ID
            // =================================================
            if (orderIdParam == null
                    || orderIdParam.trim().isEmpty()) {

                response.sendRedirect(
                        request.getContextPath() + "/admin/orders"
                );
                return;
            }

            int orderId = Integer.parseInt(orderIdParam);

            // =================================================
            // 2. CHECK ORDER EXISTS
            // =================================================
            Order order = orderDAO.getById(orderId);

            if (order == null) {
                response.sendRedirect(
                        request.getContextPath() + "/admin/orders"
                );
                return;
            }

            // =================================================
            // 3. CONFIRM ORDER
            // =================================================
            if ("confirm".equalsIgnoreCase(action)) {

                String currentStatus = normalizeStatus(
                        order.getOrderStatus()
                );

                if ("PENDING_CONFIRMATION".equals(currentStatus)) {

                    // Cap nhat trang thai don hang
                    orderDAO.updateStatus(orderId, "Confirmed");

                    // Kiem tra lai trang thai sau khi cap nhat
                    if (isOrderStatus(orderId, "CONFIRMED")) {

                        createNotificationSafely(
                                orderId,
                                "Da xac nhan"
                        );
                    }
                }

            // =================================================
            // 4. CANCEL ORDER
            // =================================================
            } else if ("cancel".equalsIgnoreCase(action)) {

                String currentStatus = normalizeStatus(
                        order.getOrderStatus()
                );

                // Khong cho huy don da hoan thanh hoac da huy
                if (!"COMPLETED".equals(currentStatus)
                        && !"CANCELLED".equals(currentStatus)) {

                    // Huy don hang
                    orderDAO.cancelOrder(orderId);

                    // Chi tao thong bao neu don da thuc su bi huy
                    if (isOrderStatus(orderId, "CANCELLED")) {

                        createNotificationSafely(
                                orderId,
                                "Da huy"
                        );
                    }
                }

            // =================================================
            // 5. CHANGE STATUS
            // =================================================
            } else if ("changeStatus".equalsIgnoreCase(action)) {

                String status = request.getParameter("status");

                if (isValidStatus(status)) {

                    String currentStatus = normalizeStatus(
                            order.getOrderStatus()
                    );

                    String newStatus = normalizeStatus(status);

                    // Khong cap nhat neu trang thai khong thay doi
                    if (!currentStatus.equals(newStatus)) {

                        orderDAO.updateStatus(
                                orderId,
                                toHistoryStatus(newStatus)
                        );

                        // Chi tao thong bao neu cap nhat thanh cong
                        if (isOrderStatus(orderId, newStatus)) {

                            createNotificationSafely(
                                    orderId,
                                    getDisplayStatus(newStatus)
                            );
                        }
                    }
                }

            } else {

                LOGGER.warning(
                        "Action khong hop le: " + action
                );
            }

            // =================================================
            // 6. REDIRECT TO ORDER DETAIL
            // =================================================
            response.sendRedirect(
                    request.getContextPath()
                    + "/admin/orders/detail?id="
                    + orderId
            );

        } catch (NumberFormatException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Order ID khong hop le khi thuc hien action",
                    e
            );

            response.sendRedirect(
                    request.getContextPath() + "/admin/orders"
            );

        } catch (Exception e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi khi xu ly thao tac don hang",
                    e
            );

            response.sendRedirect(
                    request.getContextPath() + "/admin/orders"
            );
        }
    }

    // =========================================================
    // CHECK ORDER STATUS AFTER UPDATE
    // =========================================================
    private boolean isOrderStatus(int orderId, String expectedStatus)
            throws Exception {

        Order updatedOrder = orderDAO.getById(orderId);

        if (updatedOrder == null) {
            return false;
        }

        String actualStatus = normalizeStatus(
                updatedOrder.getOrderStatus()
        );

        return expectedStatus.equals(actualStatus);
    }

    // =========================================================
    // CREATE NOTIFICATION
    // Notification failure must not undo the order update.
    // =========================================================
    private void createNotificationSafely(
            int orderId, String displayStatus) {

        try {
            boolean created
                    = notificationDAO.createOrderStatusNotification(
                            orderId,
                            displayStatus
                    );

            if (!created) {
                LOGGER.warning(
                        "Khong tao duoc thong bao cho don hang #"
                        + orderId
                );
            }

        } catch (Exception e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi khi tao thong bao cho don hang #"
                    + orderId,
                    e
            );
        }
    }

    // =========================================================
    // VALID STATUS
    // =========================================================
    private boolean isValidStatus(String status) {

        if (status == null || status.trim().isEmpty()) {
            return false;
        }

        String normalized = normalizeStatus(status);

        return "PENDING_CONFIRMATION".equals(normalized)
                || "CONFIRMED".equals(normalized)
                || "PACKING".equals(normalized)
                || "SHIPPING".equals(normalized)
                || "COMPLETED".equals(normalized)
                || "CANCELLED".equals(normalized);
    }

    // =========================================================
    // NORMALIZE STATUS
    // =========================================================
    private String normalizeStatus(String status) {

        if (status == null) {
            return "";
        }

        String value = status.trim().toUpperCase();

        if ("PENDING".equals(value)) {
            return "PENDING_CONFIRMATION";
        }

        return value;
    }

    // =========================================================
    // STATUS FOR ORDER_STATUS_HISTORY
    // =========================================================
    private String toHistoryStatus(String status) {

        if ("PENDING_CONFIRMATION".equals(status)) {
            return "Pending";
        }

        if ("CONFIRMED".equals(status)) {
            return "Confirmed";
        }

        if ("PACKING".equals(status)) {
            return "Packing";
        }

        if ("SHIPPING".equals(status)) {
            return "Shipping";
        }

        if ("COMPLETED".equals(status)) {
            return "Completed";
        }

        if ("CANCELLED".equals(status)) {
            return "Cancelled";
        }

        return status;
    }

    // =========================================================
    // STATUS DISPLAY FOR CUSTOMER NOTIFICATION
    // =========================================================
    private String getDisplayStatus(String status) {

        if ("PENDING_CONFIRMATION".equals(status)) {
            return "Cho xac nhan";
        }

        if ("CONFIRMED".equals(status)) {
            return "Da xac nhan";
        }

        if ("PACKING".equals(status)) {
            return "Dang dong goi";
        }

        if ("SHIPPING".equals(status)) {
            return "Dang giao hang";
        }

        if ("COMPLETED".equals(status)) {
            return "Da hoan thanh";
        }

        if ("CANCELLED".equals(status)) {
            return "Da huy";
        }

        return status;
    }
}