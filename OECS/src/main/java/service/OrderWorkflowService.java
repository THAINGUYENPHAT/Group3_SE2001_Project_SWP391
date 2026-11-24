package service;

import dao.NotificationDAO;
import dao.OrderInventoryDAO;
import dao.OrderPolicyDAO;
import dao.OrderWorkflowDAO;
import model.OrderWorkflowState;
import db.CheckoutConnectionFactory;
import db.DBContext;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Arrays;

/** Handles order status changes and cancellation requests. */
public final class OrderWorkflowService {
    private enum CancellationAction {
        CUSTOMER_CANCEL, STAFF_CANCEL, APPROVE_REQUEST, REJECT_REQUEST
    }

    private final CheckoutConnectionFactory connections;
    private final OrderWorkflowDAO workflow = new OrderWorkflowDAO();

    public OrderWorkflowService() {
        this(() -> new DBContext().getConnection());
    }

    public OrderWorkflowService(CheckoutConnectionFactory connections) {
        this.connections = connections;
    }

    public String advanceOrder(int staffId, int orderId, String action, String expectedStatus) throws SQLException {
        if (staffId <= 0 || orderId <= 0) {
            throw new IllegalArgumentException("Thông tin đơn hàng không hợp lệ.");
        }
        try (Connection connection = connections.open()) {
            if (connection == null) {
                throw new SQLException("Không kết nối được cơ sở dữ liệu.");
            }
            connection.setAutoCommit(false);
            try {
                workflow.requireStaff(connection, staffId);
                OrderWorkflowState order = workflow.lockOrder(connection, orderId, null);
                if ("PENDING".equals(order.getCancelRequestStatus())) {
                    throw new IllegalArgumentException("Cần duyệt hoặc từ chối yêu cầu hủy trước khi xử lý tiếp.");
                }
                String currentStatus = OrderStatusPolicy.normalize(order.getOrderStatus());
                if (currentStatus == null || !currentStatus.equals(OrderStatusPolicy.normalize(expectedStatus))) {
                    throw new IllegalArgumentException("Trạng thái đơn đã thay đổi. Vui lòng tải lại đơn hàng.");
                }

                String next = OrderStatusPolicy.requestedStatus(currentStatus, action);
                if (next == null) {
                    throw new IllegalArgumentException("Trạng thái đơn đã thay đổi hoặc thao tác không đúng trình tự.");
                }
                if ("CONFIRMED".equals(next)) {
                    if (order.isStockRestored()) {
                        throw new IllegalArgumentException("Đơn đã hoàn kho, không thể xác nhận lại.");
                    }
                    if (!"COD".equals(order.getPaymentMethod()) && !"PAID".equals(order.getPaymentStatus())) {
                        throw new IllegalArgumentException("Đơn thanh toán online phải thanh toán thành công trước khi xác nhận.");
                    }
                    if ("COD".equals(order.getPaymentMethod()) && !"UNPAID".equals(order.getPaymentStatus()) && !isFreeOrder(order)) {
                        throw new IllegalArgumentException("Trạng thái thanh toán COD không hợp lệ, cần đối soát.");
                    }
                    new OrderInventoryDAO().deduct(connection, orderId);
                }
                workflow.advance(connection, order, next);
                workflow.addHistory(connection, order, next, "STAFF", staffId, null);
                if (!NotificationDAO.createOrderStatusNotification(connection, orderId, next)) {
                    throw new SQLException("Không tạo được thông báo đơn hàng.");
                }
                connection.commit();
                return next;
            } catch (SQLException | RuntimeException e) {
                rollback(connection, e);
                throw e;
            }
        }
    }

    public static boolean canCancel(String status) {
        return Arrays.asList("PENDING_PAYMENT", "PENDING_CONFIRMATION", "CONFIRMED", "PACKING")
                .contains(OrderService.normalizeStatus(status));
    }

    public String customerCancel(int userId, int orderId, String reason) throws SQLException {
        return cancelOrReview(userId, orderId, CancellationAction.CUSTOMER_CANCEL, reason, null);
    }

    public String staffCancel(int staffId, int orderId, String reason) throws SQLException {
        return cancelOrReview(staffId, orderId, CancellationAction.STAFF_CANCEL, reason, null);
    }

    public String review(int staffId, int orderId, boolean approve, String note, String expectedRequestVersion)
            throws SQLException {
        CancellationAction action = approve ? CancellationAction.APPROVE_REQUEST : CancellationAction.REJECT_REQUEST;
        return cancelOrReview(staffId, orderId, action, note, expectedRequestVersion);
    }

    private String cancelOrReview(int actorId, int orderId, CancellationAction action, String input,
            String expectedRequestVersion) throws SQLException {
        if (actorId <= 0 || orderId <= 0) {
            throw new IllegalArgumentException("Thông tin đơn hàng không hợp lệ.");
        }

        boolean customer = action == CancellationAction.CUSTOMER_CANCEL;
        String note = customer ? null : validateReason(input);
        try (Connection connection = connections.open()) {
            if (connection == null) {
                throw new SQLException("Không kết nối được cơ sở dữ liệu.");
            }
            connection.setAutoCommit(false);
            try {
                if (!customer) {
                    workflow.requireStaff(connection, actorId);
                }
                OrderWorkflowState order = workflow.lockOrder(connection, orderId, customer ? actorId : null);
                String result;
                switch (action) {
                    case CUSTOMER_CANCEL:
                        result = cancelAsCustomer(connection, order, actorId, input);
                        break;
                    case STAFF_CANCEL:
                        result = cancelAsStaff(connection, order, actorId, note);
                        break;
                    default:
                        result = reviewRequest(connection, order, actorId,
                                action == CancellationAction.APPROVE_REQUEST, note, expectedRequestVersion);
                        break;
                }
                connection.commit();
                return result;
            } catch (SQLException | RuntimeException e) {
                rollback(connection, e);
                throw e;
            }
        }
    }

    private String cancelAsCustomer(Connection connection, OrderWorkflowState order, int userId, String reason)
            throws SQLException {
        if ("CANCELLED".equals(order.getOrderStatus())) {
            return "UNCHANGED";
        }
        requireCancellable(order);
        if ("PENDING".equals(order.getCancelRequestStatus())) {
            return "REQUESTED";
        }
        if (isPaidOnline(order.getPaymentMethod(), order.getPaymentStatus(), order.getTotalAmount())) {
            throw new IllegalArgumentException("Đơn đã thanh toán online. Vui lòng liên hệ cửa hàng để hủy.");
        }
        if (hasDeductedStock(order)) {
            String note = validateReason(reason);
            workflow.requestCancellation(connection, order, note);
            workflow.addHistory(connection, order, order.getOrderStatus(), "CUSTOMER", userId, note);
            return "REQUESTED";
        }

        // Đơn chưa xác nhận có thể hủy ngay. Lịch sử vẫn cần ghi lý do.
        String note = reason == null || reason.trim().isEmpty()
                ? "Khách hàng tự hủy đơn trước khi xác nhận."
                : validateReason(reason);
        return cancelOrder(connection, order, userId, "CUSTOMER", note, false);
    }

    private String cancelAsStaff(Connection connection, OrderWorkflowState order, int staffId, String note)
            throws SQLException {
        if ("CANCELLED".equals(order.getOrderStatus())) {
            return "UNCHANGED";
        }
        requireCancellable(order);
        if ("PENDING".equals(order.getCancelRequestStatus())) {
            throw new IllegalArgumentException("Hãy duyệt hoặc từ chối yêu cầu hủy đang chờ.");
        }
        return cancelOrder(connection, order, staffId, "STAFF", note, false);
    }

    private String reviewRequest(Connection connection, OrderWorkflowState order, int staffId, boolean approve,
            String note, String expectedRequestVersion) throws SQLException {
        if (!"PENDING".equals(order.getCancelRequestStatus()) || !hasDeductedStock(order)) {
            throw new IllegalArgumentException("Yêu cầu hủy đã được xử lý hoặc không tồn tại.");
        }
        if (expectedRequestVersion == null || !expectedRequestVersion.equals(order.getCancelRequestVersion())) {
            throw new IllegalArgumentException("Yêu cầu hủy đã thay đổi. Vui lòng tải lại đơn hàng.");
        }
        if (!approve) {
            workflow.reviewCancellation(connection, order, staffId, false, note);
            workflow.addHistory(connection, order, order.getOrderStatus(), "STAFF", staffId, note);
            return "REJECTED";
        }
        return cancelOrder(connection, order, staffId, "STAFF", note, true);
    }

    private String cancelOrder(Connection connection, OrderWorkflowState order, int actorId, String actorType,
            String note, boolean approveRequest) throws SQLException {
        if (order.isStockRestored()) {
            throw new IllegalArgumentException("Đơn hàng đã hoàn kho, cần kiểm tra lại.");
        }
        if ("COD".equals(order.getPaymentMethod()) && !"UNPAID".equals(order.getPaymentStatus()) && !isFreeOrder(order)) {
            throw new IllegalArgumentException("Đơn COD đã thu tiền cần được đối soát trước khi hủy.");
        }

        int orderId = order.getOrderId();
        boolean stockDeducted = hasDeductedStock(order);
        OrderInventoryDAO inventory = new OrderInventoryDAO();
        if (stockDeducted) {
            inventory.restore(connection, orderId);
        } else if (inventory.usesReservations(connection)) {
            inventory.releaseReservation(connection, orderId);
        }

        if (approveRequest) {
            workflow.reviewCancellation(connection, order, actorId, true, note);
        }
        boolean customerSource = "CUSTOMER".equals(actorType) || approveRequest;
        workflow.cancel(connection, order, customerSource, stockDeducted);
        workflow.addHistory(connection, order, "CANCELLED", actorType, actorId, note);
        if (!NotificationDAO.createOrderStatusNotification(connection, orderId, "CANCELLED")) {
            throw new SQLException("Không tạo được thông báo hủy đơn.");
        }
        if (customerSource) {
            new OrderPolicyDAO().recordCancellation(connection, order.getCustomerId(), orderId);
        }
        return "CANCELLED";
    }

    private static void requireCancellable(OrderWorkflowState order) {
        if (!canCancel(order.getOrderStatus())) {
            throw new IllegalArgumentException("Chỉ được hủy đơn hàng trước khi vận chuyển.");
        }
    }

    private static boolean hasDeductedStock(OrderWorkflowState order) {
        return "CONFIRMED".equals(order.getOrderStatus()) || "PACKING".equals(order.getOrderStatus());
    }

    private static void rollback(Connection connection, Exception failure) {
        try {
            connection.rollback();
        } catch (SQLException e) {
            failure.addSuppressed(e);
        }
    }

    public static boolean isPaidOnline(String paymentMethod, String paymentStatus, BigDecimal totalAmount) {
        return ("VNPAY".equals(paymentMethod) || "MOMO".equals(paymentMethod))
                && "PAID".equals(paymentStatus) && totalAmount.signum() > 0;
    }

    private static boolean isFreeOrder(OrderWorkflowState order) {
        return "PAID".equals(order.getPaymentStatus()) && order.getTotalAmount().signum() == 0;
    }

    private static String validateReason(String value) {
        if (value == null || value.trim().isEmpty() || value.trim().length() > 500) {
            throw new IllegalArgumentException("Vui lòng nhập lý do từ 1 đến 500 ký tự.");
        }
        return value.trim();
    }
}
