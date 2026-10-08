package controller.admin;

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

    private static final Logger LOGGER
            = Logger.getLogger(AdminOrderServlet.class.getName());

    private AdminOrderDAO orderDAO;

    @Override
    public void init() {
        orderDAO = new AdminOrderDAO();
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

                // Không tìm thấy Order
                if (order == null) {
                    response.sendRedirect(
                            request.getContextPath() + "/admin/orders"
                    );
                    return;
                }

                List<OrderItem> items
                        = orderDAO.getItemsByOrderId(orderId);

                // Current status lấy trực tiếp từ [ORDER].order_status
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
                    "Lỗi khi lấy danh sách đơn hàng!",
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
            // Validate Order ID
            // =================================================
            if (orderIdParam == null || orderIdParam.trim().isEmpty()) {
                response.sendRedirect(
                        request.getContextPath() + "/admin/orders"
                );
                return;
            }

            int orderId = Integer.parseInt(orderIdParam);

            // =================================================
            // Check Order tồn tại
            // =================================================
            Order order = orderDAO.getById(orderId);

            if (order == null) {
                response.sendRedirect(
                        request.getContextPath() + "/admin/orders"
                );
                return;
            }

            // =================================================
            // 1. CONFIRM ORDER
            // =================================================
            if ("confirm".equalsIgnoreCase(action)) {

                String currentStatus = normalizeStatus(
                        order.getOrderStatus()
                );

                // Chỉ Confirm khi Order đang chờ xác nhận
                if ("PENDING_CONFIRMATION".equals(currentStatus)
                        || "PENDING".equals(currentStatus)) {

                    orderDAO.updateStatus(
                            orderId,
                            "Confirmed"
                    );
                }

                // =================================================
                // 2. CANCEL ORDER
                // =================================================
            } else if ("cancel".equalsIgnoreCase(action)) {

                String currentStatus = normalizeStatus(
                        order.getOrderStatus()
                );

                // Không cho hủy Order đã hoàn tất
                if (!"COMPLETED".equals(currentStatus)
                        && !"CANCELLED".equals(currentStatus)) {

                    orderDAO.cancelOrder(orderId);
                }

                // =================================================
                // 3. CHANGE STATUS
                // =================================================
            } else if ("changeStatus".equalsIgnoreCase(action)) {

                String status = request.getParameter("status");

                if (isValidStatus(status)) {

                    String currentStatus = normalizeStatus(
                            order.getOrderStatus()
                    );

                    String newStatus = normalizeStatus(status);

                    // Không update nếu status không thay đổi
                    if (!currentStatus.equals(newStatus)) {

                        orderDAO.updateStatus(
                                orderId,
                                toHistoryStatus(newStatus)
                        );
                    }
                }

            } else {

                LOGGER.warning(
                        "Action không hợp lệ: " + action
                );
            }

            // =================================================
            // Redirect về Detail
            // =================================================
            response.sendRedirect(
                    request.getContextPath()
                    + "/admin/orders/detail?id="
                    + orderId
            );

        } catch (NumberFormatException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Order ID không hợp lệ khi thực hiện action!",
                    e
            );

            response.sendRedirect(
                    request.getContextPath() + "/admin/orders"
            );

        } catch (Exception e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi khi cập nhật trạng thái Order!",
                    e
            );

            response.sendRedirect(
                    request.getContextPath() + "/admin/orders"
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

        // DB current status
        if ("PENDING".equals(value)) {
            return "PENDING_CONFIRMATION";
        }

        // History / UI status
        if ("PENDING_CONFIRMATION".equals(value)) {
            return "PENDING_CONFIRMATION";
        }

        return value;
    }

    // =========================================================
    // STATUS FOR ORDER_STATUS_HISTORY
    // =========================================================
    private String toHistoryStatus(String status) {

        switch (status) {

            case "PENDING_CONFIRMATION":
                return "Pending";

            case "CONFIRMED":
                return "Confirmed";

            case "PACKING":
                return "Packing";

            case "SHIPPING":
                return "Shipping";

            case "COMPLETED":
                return "Completed";

            case "CANCELLED":
                return "Cancelled";

            default:
                return status;
        }
    }
}
