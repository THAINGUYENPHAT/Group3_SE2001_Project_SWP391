package dao;

import db.CheckoutConnectionFactory;
import db.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class PaymentRefundDAO {
    private final CheckoutConnectionFactory connections;

    public PaymentRefundDAO() {
        this(() -> new DBContext().getConnection());
    }

    public PaymentRefundDAO(CheckoutConnectionFactory connections) {
        this.connections = connections;
    }

    public List<Map<String, Object>> findForCustomer(int orderId, int userId) throws SQLException {
        return find("WHERE t.order_id = ? AND o.user_id = ? ORDER BY r.refund_id DESC", orderId, userId);
    }

    public List<Map<String, Object>> findPage(int page) throws SQLException {
        return find("ORDER BY r.requested_at DESC, r.refund_id DESC OFFSET ? ROWS FETCH NEXT 50 ROWS ONLY",
                (page - 1) * 50);
    }

    private List<Map<String, Object>> find(String suffix, int... parameters) throws SQLException {
        String sql = "SELECT r.*, t.order_id, t.transaction_code, t.payment_method, "
                + "t.provider_transaction_id FROM dbo.PAYMENT_REFUND r "
                + "JOIN dbo.PAYMENT_TRANSACTION t ON t.transaction_id = r.transaction_id "
                + "JOIN dbo.[ORDER] o ON o.order_id = t.order_id " + suffix;
        List<Map<String, Object>> rows = new ArrayList<>();
        try (Connection c = connections.open(); PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < parameters.length; i++) {
                ps.setInt(i + 1, parameters[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("id", rs.getLong("refund_id"));
                    row.put("orderId", rs.getInt("order_id"));
                    row.put("transactionCode", rs.getString("transaction_code"));
                    row.put("providerTransactionId", rs.getString("provider_transaction_id"));
                    row.put("method", rs.getString("payment_method"));
                    row.put("amount", rs.getBigDecimal("refund_amount"));
                    row.put("status", rs.getString("refund_status"));
                    row.put("statusLabel", statusLabel(rs.getString("refund_status")));
                    row.put("reference", rs.getString("provider_refund_id"));
                    row.put("reason", rs.getString("reason"));
                    row.put("requestedAt", rs.getTimestamp("requested_at"));
                    row.put("completedAt", rs.getTimestamp("completed_at"));
                    rows.add(row);
                }
            }
        }
        return rows;
    }

    private static String statusLabel(String status) {
        switch (status) {
            case "PENDING": return "Chờ đối soát";
            case "PROCESSING": return "Đang xử lý";
            case "SUCCESS": return "Đã hoàn tiền";
            case "FAILED": return "Hoàn tiền chưa thành công";
            default: return status;
        }
    }

    public void updateStatus(long refundId, String expectedStatus, String nextStatus,
            String reference, int staffId) throws SQLException {
        boolean start = ("PENDING".equals(expectedStatus) || "FAILED".equals(expectedStatus))
                && "PROCESSING".equals(nextStatus);
        boolean finish = "PROCESSING".equals(expectedStatus)
                && ("SUCCESS".equals(nextStatus) || "FAILED".equals(nextStatus));
        if (refundId <= 0 || staffId <= 0 || (!start && !finish)) {
            throw new IllegalArgumentException("Chuyển trạng thái hoàn tiền không hợp lệ.");
        }
        String trimmed = reference == null ? "" : reference.trim();
        if (trimmed.length() > 150 || ("SUCCESS".equals(nextStatus) && trimmed.isEmpty())) {
            throw new IllegalArgumentException("Cần mã tham chiếu hoàn tiền thực tế, tối đa 150 ký tự.");
        }
        String sql = "UPDATE dbo.PAYMENT_REFUND SET refund_status = ?, "
                + "provider_refund_id = CASE WHEN ? = 'SUCCESS' THEN ? ELSE provider_refund_id END, "
                + "completed_at = CASE WHEN ? = 'SUCCESS' THEN SYSUTCDATETIME() ELSE NULL END, "
                + "processed_by = ?, updated_at = SYSUTCDATETIME() "
                + "WHERE refund_id = ? AND refund_status = ?";
        try (Connection c = connections.open(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, nextStatus);
            ps.setString(2, nextStatus);
            ps.setString(3, trimmed);
            ps.setString(4, nextStatus);
            ps.setInt(5, staffId);
            ps.setLong(6, refundId);
            ps.setString(7, expectedStatus);
            if (ps.executeUpdate() != 1) {
                throw new IllegalArgumentException("Yêu cầu đã được cập nhật. Hãy tải lại trang.");
            }
        }
    }
}
