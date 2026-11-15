package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.ZoneOffset;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

public class OrderPolicyDAO {
    public void lockCustomer(Connection connection, int userId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT user_id FROM dbo.[USER] WITH (UPDLOCK, HOLDLOCK) WHERE user_id = ?")) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Không tìm thấy khách hàng.");
                }
            }
        }
    }

    public void requireAllowed(Connection connection, int userId) throws SQLException {
        String message = restriction(connection, userId);
        if (message != null) {
            throw new IllegalArgumentException(message);
        }
    }

    public String restriction(Connection connection, int userId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT violation_count, blocked_until FROM dbo.ORDER_CUSTOMER_POLICY "
                + "WHERE user_id = ? AND (violation_count >= 3 OR blocked_until > SYSUTCDATETIME())")) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                if (rs.getInt("violation_count") >= 3) {
                    return "Bạn đã bị khóa đặt hàng vĩnh viễn do vi phạm chính sách hủy đơn lần thứ 3.";
                }
                Timestamp until = rs.getTimestamp("blocked_until");
                String local = until.toLocalDateTime().atOffset(ZoneOffset.UTC)
                        .atZoneSameInstant(ZoneId.of("Asia/Ho_Chi_Minh"))
                        .format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
                return "Bạn đang bị khóa đặt hàng đến " + local
                        + " (giờ Việt Nam) do hủy hơn 5 sản phẩm trong 7 ngày.";
            }
        }
    }

    public void recordCancellation(Connection connection, int userId, int orderId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO dbo.ORDER_CUSTOMER_CANCELLATION (order_id, user_id, quantity) "
                + "SELECT o.order_id, o.user_id, SUM(CAST(i.quantity AS bigint)) "
                + "FROM dbo.[ORDER] o JOIN dbo.ORDER_ITEM i ON i.order_id = o.order_id "
                + "WHERE o.order_id = ? AND o.user_id = ? AND o.order_status = 'CANCELLED' "
                + "AND NOT EXISTS (SELECT 1 FROM dbo.ORDER_CUSTOMER_CANCELLATION WHERE order_id = ?) "
                + "GROUP BY o.order_id, o.user_id")) {
            ps.setInt(1, orderId);
            ps.setInt(2, userId);
            ps.setInt(3, orderId);
            if (ps.executeUpdate() == 0) {
                return;
            }
        }
        try (PreparedStatement ps = connection.prepareStatement(
                "IF NOT EXISTS (SELECT 1 FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id = ?) "
                + "INSERT INTO dbo.ORDER_CUSTOMER_POLICY (user_id) VALUES (?)")) {
            ps.setInt(1, userId);
            ps.setInt(2, userId);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = connection.prepareStatement(
                "UPDATE p SET violation_count = violation_count + 1, "
                + "blocked_until = CASE violation_count WHEN 0 THEN DATEADD(DAY,3,SYSUTCDATETIME()) "
                + "WHEN 1 THEN DATEADD(DAY,7,SYSUTCDATETIME()) ELSE NULL END "
                + "FROM dbo.ORDER_CUSTOMER_POLICY p WHERE p.user_id = ? AND violation_count < 3 "
                + "AND (blocked_until IS NULL OR blocked_until <= SYSUTCDATETIME()) "
                + "AND (SELECT COALESCE(SUM(c.quantity),0) FROM dbo.ORDER_CUSTOMER_CANCELLATION c "
                + "WHERE c.user_id = p.user_id AND c.cancelled_at > DATEADD(DAY,-7,SYSUTCDATETIME()) "
                + "AND (p.blocked_until IS NULL OR c.cancelled_at >= p.blocked_until)) > 5")) {
            ps.setInt(1, userId);
            ps.executeUpdate();
        }
    }
}
