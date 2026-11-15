package controller.admin;

import dao.AdminOrderDAO;
import model.Order;
import model.OrderItem;
import dao.NotificationDAO;
import model.User;
import service.AuditLogService;
import service.OrderCancellationService;
import service.OrderStatusPolicy;
import java.util.UUID;

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
    private NotificationDAO notificationDAO;

    private final AuditLogService auditLogService = new AuditLogService();

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
        if (request.getSession().getAttribute("staffOrderToken") == null) {
            request.getSession().setAttribute("staffOrderToken", UUID.randomUUID().toString());
        }

        if ("/detail".equals(path)) {
            try {
                int orderId = Integer.parseInt(
                        request.getParameter("id")
                );

                Order order = orderDAO.getById(orderId);
                List<OrderItem> items = orderDAO.getItemsByOrderId(orderId);
                String status = orderDAO.getCurrentStatus(orderId);

                if (status == null && order != null) {
                    status = order.getOrderStatus();
                }

                request.setAttribute("order", order);
                request.setAttribute("items", items);
                request.setAttribute("status", status);

                request.getRequestDispatcher("/WEB-INF/admin/order-detail.jsp").forward(request, response);
            } catch (NumberFormatException e) {
                LOGGER.log(Level.WARNING, "Order ID không hợp lệ khi xem chi tiết!", e);

                response.sendRedirect(
                        request.getContextPath() + "/admin/orders"
                );
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi khi tải thông tin chi tiết đơn hàng!", e);

                response.sendRedirect(
                        request.getContextPath() + "/admin/orders"
                );
            }
        } else {
            try {
                List<Order> orders = orderDAO.getList();

                request.setAttribute("orders", orders);

                request.getRequestDispatcher("/WEB-INF/admin/orders.jsp").forward(request, response);
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi khi lấy danh sách đơn hàng!", e);

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
        Object expected = request.getSession().getAttribute("staffOrderToken");
        if (!(expected instanceof String) || !expected.equals(request.getParameter("csrfToken"))) {
            response.sendError(403, "Yêu cầu không hợp lệ. Vui lòng tải lại trang.");
            return;
        }
        if ("cancel".equals(action)) {
            cancelOrder(request, orderId);
            response.sendRedirect(request.getContextPath() + "/admin/orders/detail?id=" + orderId);
            return;
        }

        try {
            String current = OrderStatusPolicy.normalize(orderDAO.getCurrentStatus(orderId));
            String nextStatus = OrderStatusPolicy.requestedStatus(current, action);

            if (nextStatus == null) {
                request.getSession().setAttribute(
                        "errorMessage",
                        "Không thể cập nhật! Vui lòng thực hiện đúng trình tự: "
                        + "Confirmed → Packing → Shipping → Completed."
                );
            } else if (orderDAO.transitionStatus(orderId, nextStatus)) {
                request.getSession().setAttribute("successMessage", statusSuccessMessage(nextStatus));

                User loggedInUser = (User) request.getSession()
                                .getAttribute("loggedInUser");

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

                notifyOrderStatus(orderId, nextStatus);
            } else {
                request.getSession().setAttribute("errorMessage", "Không thể chuyển trạng thái. Vui lòng tải lại đơn hàng!");
            }
        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi cập nhật trạng thái đơn hàng #" + orderId,
                    e
            );

            request.getSession().setAttribute("errorMessage", "Thao tác thất bại! Vui lòng kiểm tra lại.");
        }

        response.sendRedirect(
                request.getContextPath()
                + "/admin/orders/detail?id=" + orderId
        );
    }

    private String statusSuccessMessage(String status) {
        switch (status) {
            case "CONFIRMED":
                return "Xác nhận đơn hàng thành công!";
            case "PACKING":
                return "Đơn hàng đã chuyển sang đóng gói!";
            case "SHIPPING":
                return "Đơn hàng đã chuyển sang giao hàng!";
            case "COMPLETED":
                return "Đơn hàng đã hoàn thành!";
            default:
                throw new IllegalArgumentException("Unsupported order status: " + status);
        }
    }

    private void cancelOrder(HttpServletRequest request, int orderId) {
        try {
            User staff = (User) request.getSession().getAttribute("loggedInUser");
            OrderCancellationService cancellation = new OrderCancellationService();
            String result = cancellation.staffCancel(staff.getUserId(), orderId);
            auditLogService.log(staff, "CANCEL_ORDER", "ORDER", (long) orderId, "Staff cancellation: " + result, request);
            request.getSession().setAttribute("successMessage", "UNCHANGED".equals(result)
                    ? "Đơn hàng đã được hủy trước đó."
                    : "Đã hủy đơn và hoàn kho thành công");
        } catch (IllegalArgumentException e) {
            request.getSession().setAttribute("errorMessage", e.getMessage());
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Cannot process cancellation", e);
            request.getSession().setAttribute("errorMessage", "Chưa xử lý được yêu cầu. Vui lòng tải lại đơn và thử lại.");
        }
    }

    private void notifyOrderStatus(int orderId, String nextStatus) {
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
    }
}
