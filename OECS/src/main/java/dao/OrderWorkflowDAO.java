package dao;

import model.OrderWorkflowState;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Locale;

public final class OrderWorkflowDAO {

    public static final class OrderNotFoundException extends IllegalArgumentException {
        private OrderNotFoundException() {
            super("Không tìm thấy đơn hàng.");
        }
    }

    public OrderWorkflowState lockOrder(Connection connection, int orderId, Integer customerId) throws SQLException {
        String ownerSql = "SELECT user_id FROM dbo.[ORDER] WHERE order_id = ?"
                + (customerId == null ? "" : " AND user_id = ?");
        int ownerId;
        try (PreparedStatement statement = connection.prepareStatement(ownerSql)) {
            statement.setInt(1, orderId);
            if (customerId != null) {
                statement.setInt(2, customerId);
            }
            try (ResultSet row = statement.executeQuery()) {
                if (!row.next()) {
                    throw new OrderNotFoundException();
                }
                ownerId = row.getInt("user_id");
            }
        }

        // Giữ cùng thứ tự khóa với checkout và thanh toán: khóa khách trước, khóa đơn sau.
        new OrderPolicyDAO().lockCustomer(connection, ownerId);
        String orderSql = "SELECT order_status, payment_status, payment_method, total_amount, "
                + "cancel_request_status, CONVERT(VARCHAR(33), cancel_requested_at, 126) AS cancel_request_version, "
                + "stock_restored_at "
                + "FROM dbo.[ORDER] WITH (UPDLOCK, HOLDLOCK) WHERE order_id = ? AND user_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(orderSql)) {
            statement.setInt(1, orderId);
            statement.setInt(2, ownerId);
            try (ResultSet row = statement.executeQuery()) {
                if (!row.next()) {
                    throw new OrderNotFoundException();
                }
                return new OrderWorkflowState(orderId, ownerId,
                        normalize(row.getString("order_status")),
                        normalize(row.getString("payment_status")),
                        normalize(row.getString("payment_method")),
                        row.getBigDecimal("total_amount"),
                        normalize(row.getString("cancel_request_status")),
                        row.getString("cancel_request_version"),
                        row.getTimestamp("stock_restored_at") != null);
            }
        }
    }

    public void requireStaff(Connection connection, int staffId) throws SQLException {
        String sql = "SELECT u.user_id FROM dbo.[USER] u "
                + "JOIN dbo.ROLES r ON r.role_id = u.role_id "
                + "WHERE u.user_id = ? AND u.is_active = 1 AND r.role_name IN ('Admin', 'Staff')";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, staffId);
            try (ResultSet row = statement.executeQuery()) {
                if (!row.next()) {
                    throw new IllegalArgumentException("Bạn không có quyền xử lý đơn hàng.");
                }
            }
        }
    }

    public void addHistory(Connection connection, OrderWorkflowState order, String status, String actorType,
            int actorId, String reason) throws SQLException {
        String sql = "INSERT INTO dbo.ORDER_STATUS_HISTORY "
                + "(order_id, old_status, status, actor_type, changed_by, reason) VALUES (?, ?, ?, ?, ?, ?)";
        executeUpdate(connection, sql, order.getOrderId(), order.getOrderStatus(), status, actorType, actorId, reason);
    }

    public void requestCancellation(Connection connection, OrderWorkflowState order, String reason) throws SQLException {
        String sql = "UPDATE dbo.[ORDER] SET cancel_request_status = 'PENDING', cancel_request_reason = ?, "
                + "cancel_requested_at = SYSUTCDATETIME(), cancel_reviewed_by = NULL, "
                + "cancel_reviewed_at = NULL, cancel_review_note = NULL "
                + "WHERE order_id = ? AND user_id = ? AND order_status IN ('CONFIRMED', 'PACKING') "
                + "AND COALESCE(cancel_request_status, '') <> 'PENDING'";
        requireOne(executeUpdate(connection, sql, reason, order.getOrderId(), order.getCustomerId()));
    }

    public void reviewCancellation(Connection connection, OrderWorkflowState order, int staffId, boolean approved,
            String note) throws SQLException {
        String sql = "UPDATE dbo.[ORDER] SET cancel_request_status = ?, cancel_reviewed_by = ?, "
                + "cancel_reviewed_at = SYSUTCDATETIME(), cancel_review_note = ? "
                + "WHERE order_id = ? AND order_status = ? AND cancel_request_status = 'PENDING'";
        String reviewStatus = approved ? "APPROVED" : "REJECTED";
        requireOne(executeUpdate(connection, sql, reviewStatus, staffId, note, order.getOrderId(), order.getOrderStatus()));
    }

    public void cancel(Connection connection, OrderWorkflowState order, boolean customerSource, boolean deducted) throws SQLException {
        // OrderPolicyDAO đánh dấu đơn do khách hủy và cập nhật chính sách trong cùng transaction.
        String orderSql = "UPDATE dbo.[ORDER] SET order_status = 'CANCELLED', cancellation_source = ?, "
                + "cancelled_at = CASE WHEN ? = 1 THEN NULL ELSE SYSUTCDATETIME() END, "
                + "stock_restored_at = CASE WHEN ? = 1 THEN SYSDATETIME() ELSE stock_restored_at END, "
                + "payment_expires_at = NULL WHERE order_id = ? AND order_status = ?";
        requireOne(executeUpdate(connection, orderSql, customerSource ? null : "STAFF",
                customerSource ? 1 : 0, deducted ? 1 : 0, order.getOrderId(), order.getOrderStatus()));

        String paymentSql = "UPDATE dbo.PAYMENT_TRANSACTION SET status = 'CANCELLED' "
                + "WHERE order_id = ? AND status = 'PENDING'";
        executeUpdate(connection, paymentSql, order.getOrderId());
    }

    public void advance(Connection connection, OrderWorkflowState order, String nextStatus) throws SQLException {
        String sql = "UPDATE dbo.[ORDER] SET order_status = ?, "
                + "payment_status = CASE WHEN ? = 'COMPLETED' AND payment_method = 'COD' "
                + "THEN 'PAID' ELSE payment_status END, "
                + "delivered_at = CASE WHEN ? = 'COMPLETED' THEN COALESCE(delivered_at, SYSDATETIME()) "
                + "ELSE delivered_at END "
                + "WHERE order_id = ? AND order_status = ? AND COALESCE(cancel_request_status, '') <> 'PENDING'";
        requireOne(executeUpdate(connection, sql, nextStatus, nextStatus, nextStatus, order.getOrderId(), order.getOrderStatus()));
    }

    private static void requireOne(int changed) throws SQLException {
        if (changed != 1) {
            throw new SQLException("Trạng thái đơn đã thay đổi, vui lòng tải lại đơn hàng.");
        }
    }

    private static String normalize(String value) {
        return value == null ? null : value.trim().toUpperCase(Locale.ROOT);
    }

    private static int executeUpdate(Connection connection, String sql, Object... values) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            for (int i = 0; i < values.length; i++) {
                statement.setObject(i + 1, values[i]);
            }
            return statement.executeUpdate();
        }
    }
}
