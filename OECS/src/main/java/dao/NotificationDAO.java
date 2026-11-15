package dao;

import db.DBContext;
import model.Notification;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class NotificationDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(NotificationDAO.class.getName());

    public boolean createOrderStatusNotification(int orderId, String status) {
        try (Connection conn = getConnection()) {
            return createOrderStatusNotification(conn, orderId, status);
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Error creating order status notification", ex);
            return false;
        }
    }

    /** Reuse the caller's transaction without closing or committing its connection. */
    public static boolean createOrderStatusNotification(Connection conn, int orderId, String status) throws SQLException {
        if (conn == null || conn.isClosed()) throw new SQLException("Kết nối không hợp lệ.");
        if (orderId <= 0) throw new IllegalArgumentException("Mã đơn hàng không hợp lệ.");
        String title;
        String message;

        String normalizedStatus = status == null
                ? ""
                : status.trim().toUpperCase(java.util.Locale.ROOT);

        if (normalizedStatus.equals("CONFIRMED")) {

            title = "Đơn hàng đã được xác nhận";
            message = "Đơn hàng #" + orderId
                    + " của bạn đã được xác nhận và đang được chuẩn bị.";

        } else if (normalizedStatus.equals("PACKING")) {

            title = "Đơn hàng đang được đóng gói";
            message = "Đơn hàng #" + orderId
                    + " đã được xác nhận và đang trong quá trình đóng gói.";

        } else if (normalizedStatus.equals("SHIPPING")
                || normalizedStatus.equals("SHIPPED")) {

            title = "Đơn hàng đang được vận chuyển";
            message = "Đơn hàng #" + orderId
                    + " đã được bàn giao cho đơn vị vận chuyển. "
                    + "Vui lòng chú ý điện thoại để nhận hàng.";

        } else if (normalizedStatus.equals("DELIVERED")) {

            title = "Đơn hàng đã giao thành công";
            message = "Đơn hàng #" + orderId
                    + " đã được giao thành công. "
                    + "Cảm ơn bạn đã mua sắm tại OECS!";

        } else if (normalizedStatus.equals("COMPLETED")) {

            title = "Đơn hàng đã hoàn tất";
            message = "Đơn hàng #" + orderId
                    + " đã hoàn tất. Hy vọng bạn hài lòng với sản phẩm!";

        } else if (normalizedStatus.equals("CANCELLED")
                || normalizedStatus.equals("CANCELED")) {

            title = "Đơn hàng đã bị hủy";
            message = "Đơn hàng #" + orderId
                    + " của bạn đã bị hủy. "
                    + "Nếu cần hỗ trợ, vui lòng liên hệ nhân viên OECS.";

        } else {
            LOGGER.warning("Unsupported order status: " + status);
            return false;
        }

        String sql = "INSERT INTO dbo.NOTIFICATION "
                + "(user_id, order_id, title, message) "
                + "SELECT o.user_id, o.order_id, ?, ? "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.order_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, title);
            ps.setString(2, message);
            ps.setInt(3, orderId);

            return ps.executeUpdate() > 0;

        }
    }

    public void createReturnExchangeNotification(
            Connection conn,
            int userId,
            int orderId,
            String requestType,
            String status) throws SQLException {

        String type = "RETURN".equals(requestType)
                ? "trả hàng"
                : "đổi hàng";

        String result = "APPROVED".equals(status)
                ? "đã được chấp nhận"
                : "đã bị từ chối";

        String title = "Cập nhật yêu cầu đổi/trả hàng";
        String message = "Yêu cầu " + type
                + " cho đơn hàng #" + orderId
                + " " + result + ".";

        String sql = "INSERT INTO dbo.NOTIFICATION "
                + "(user_id, order_id, title, message) "
                + "VALUES (?, ?, ?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, orderId);
            ps.setString(3, title);
            ps.setString(4, message);

            ps.executeUpdate();
        }
    }

    public int countUnread(int userId) {

        String sql = "SELECT COUNT(*) "
                + "FROM dbo.NOTIFICATION "
                + "WHERE user_id = ? AND is_read = 0";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Error counting unread notifications", ex);
        }

        return 0;
    }

    public List<Notification> findLatest(int userId) {

        List<Notification> list = new ArrayList<>();

        String sql = "SELECT TOP 20 "
                + "notification_id, user_id, order_id, "
                + "title, message, is_read, created_at "
                + "FROM dbo.NOTIFICATION "
                + "WHERE user_id = ? "
                + "ORDER BY created_at DESC, notification_id DESC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {

                    Notification n = new Notification();

                    n.setNotificationId(
                            rs.getInt("notification_id"));

                    n.setUserId(rs.getInt("user_id"));

                    int orderId = rs.getInt("order_id");

                    if (rs.wasNull()) {
                        n.setOrderId(null);
                    } else {
                        n.setOrderId(orderId);
                    }

                    n.setTitle(rs.getString("title"));
                    n.setMessage(rs.getString("message"));
                    n.setRead(rs.getBoolean("is_read"));
                    n.setCreatedAt(
                            rs.getTimestamp("created_at"));

                    list.add(n);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Error getting latest notifications", ex);
        }

        return list;
    }

    public boolean markAsRead(int notificationId, int userId) {

        String sql = "UPDATE dbo.NOTIFICATION "
                + "SET is_read = 1 "
                + "WHERE notification_id = ? "
                + "AND user_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, notificationId);
            ps.setInt(2, userId);

            return ps.executeUpdate() > 0;

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Error marking notification as read", ex);
        }

        return false;
    }
}
