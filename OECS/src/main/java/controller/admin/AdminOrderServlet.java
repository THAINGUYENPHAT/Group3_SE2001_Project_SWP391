package controller.admin;

import dao.AdminOrderDAO;
import model.Order;
import model.User;
import service.AuditLogService;
import service.OrderWorkflowService;
import service.OrderService;
import service.OrderStatusPolicy;
import java.util.UUID;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "AdminOrderServlet", urlPatterns = "/admin/orders/*")
public class AdminOrderServlet extends HttpServlet {

    private final OrderWorkflowService orderWorkflow = new OrderWorkflowService();
    private static final Logger LOGGER = Logger.getLogger(AdminOrderServlet.class.getName());

    private final AuditLogService auditLogService = new AuditLogService();

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {
        AdminOrderDAO orderDAO = new AdminOrderDAO();
        request.setAttribute("statusLabels", OrderService.statusLabels());
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
                if (order == null) { response.sendError(404, "Không tìm thấy đơn hàng."); return; }
                String status = OrderService.normalizeStatus(order.getOrderStatus());
                boolean pendingCancel = "PENDING".equals(order.getCancelRequestStatus());
                request.setAttribute("pendingCancel", pendingCancel);
                request.setAttribute("canAdvanceOrder",
                        !pendingCancel && OrderStatusPolicy.nextStatus(status) != null);
                request.setAttribute("canStaffCancel",
                        !pendingCancel && OrderWorkflowService.canCancel(status));
                boolean closed = "CANCELLED".equals(status) || "EXPIRED".equals(status);
                if (closed && "PAID".equals(order.getPaymentStatus()) && order.getTotalAmount().signum() > 0) {
                    request.setAttribute("needsManualRefund", true);
                    request.setAttribute("successfulPayments", orderDAO.getSuccessfulPayments(orderId));
                }

                request.setAttribute("order", order);
                request.setAttribute("history", orderDAO.getHistory(orderId));
                request.setAttribute("items", orderDAO.getItemsByOrderId(orderId));
                request.setAttribute("status", status);

                request.getRequestDispatcher("/WEB-INF/admin/order-detail.jsp").forward(request, response);
            } catch (NumberFormatException e) {
                LOGGER.log(Level.WARNING, "Order ID không hợp lệ khi xem chi tiết!", e);

                response.sendError(400,"Mã đơn hàng không hợp lệ.");
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi khi tải thông tin chi tiết đơn hàng!", e);

                throw new ServletException("Không tải được chi tiết đơn hàng.",e);
            }
        } else {
            try {
                List<Order> orders = orderDAO.getList();

                request.setAttribute("orders", orders);

                request.getRequestDispatcher("/WEB-INF/admin/orders.jsp").forward(request, response);
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi khi lấy danh sách đơn hàng!", e);

                throw new ServletException("Không tải được danh sách đơn hàng.",e);
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
        HttpSession session = request.getSession();
        Object expected = session.getAttribute("staffOrderToken");
        if (!(expected instanceof String) || !expected.equals(request.getParameter("csrfToken"))) {
            response.sendError(403, "Yêu cầu không hợp lệ. Vui lòng tải lại trang.");
            return;
        }

        User staff = (User) session.getAttribute("loggedInUser");
        boolean cancellation = "cancel".equals(action) || "approveCancel".equals(action)
                || "rejectCancel".equals(action);
        try {
            String message;
            if (cancellation) {
                message = cancelOrder(request, staff, orderId, action);
            } else {
                String nextStatus = orderWorkflow.advanceOrder(
                        staff.getUserId(), orderId, action, request.getParameter("expectedStatus"));
                message = statusSuccessMessage(nextStatus);
                auditStaffAction(staff, orderId, "UPDATE_ORDER_STATUS", "Changed order status to " + nextStatus, request);
            }
            session.setAttribute("successMessage", message);
        } catch (IllegalArgumentException e) {
            session.setAttribute("errorMessage", e.getMessage());
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi xử lý đơn hàng #" + orderId, e);
            session.setAttribute("errorMessage", cancellation
                    ? "Chưa xử lý được yêu cầu. Vui lòng tải lại đơn và thử lại."
                    : "Thao tác thất bại! Vui lòng kiểm tra lại.");
        }

        response.sendRedirect(request.getContextPath() + "/admin/orders/detail?id=" + orderId);
    }

    private void auditStaffAction(User staff, int orderId, String action, String details, HttpServletRequest request) {
        try {
            if (!auditLogService.log(staff, action, "ORDER", (long) orderId, details, request)) {
                LOGGER.log(Level.WARNING, "Không ghi được audit log cho đơn hàng #{0}", orderId);
            }
        } catch (RuntimeException e) {
            LOGGER.log(Level.WARNING, "Lỗi ghi audit log cho đơn hàng #" + orderId, e);
        }
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

    private String cancelOrder(HttpServletRequest request, User staff, int orderId, String action)
            throws SQLException {
        String reason = request.getParameter("reason");
        String result = "cancel".equals(action)
                ? orderWorkflow.staffCancel(staff.getUserId(), orderId, reason)
                : orderWorkflow.review(staff.getUserId(), orderId, "approveCancel".equals(action),
                        reason, request.getParameter("cancelRequestVersion"));
        auditStaffAction(staff, orderId, "CANCEL_ORDER", "Staff cancellation: " + result, request);

        switch (result) {
            case "REJECTED":
                return "Đã từ chối yêu cầu hủy.";
            case "UNCHANGED":
                return "Đơn hàng đã được hủy trước đó.";
            default:
                return "Đã hủy đơn hàng thành công.";
        }
    }
}
