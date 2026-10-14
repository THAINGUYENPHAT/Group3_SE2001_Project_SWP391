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

    // =========================
    // 1. CREATE ORDER STATUS NOTIFICATION
    // =========================
    public boolean createOrderStatusNotification(
            int orderId, String status) {

        String title = "Cap nhat don hang #" + orderId;
        String message = "Don hang #" + orderId
                + " da duoc cap nhat trang thai: " + status + ".";

        String sql = "INSERT INTO dbo.NOTIFICATION "
                + "(user_id, order_id, title, message) "
                + "SELECT o.user_id, o.order_id, ?, ? "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.order_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, title);
            ps.setString(2, message);
            ps.setInt(3, orderId);

            return ps.executeUpdate() > 0;

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error creating order status notification",
                    ex
            );
        }

        return false;
    }

    // =========================
    // 2. COUNT UNREAD NOTIFICATIONS
    // =========================
    public int countUnread(int userId) {

        String sql = "SELECT COUNT(*) "
                + "FROM dbo.NOTIFICATION "
                + "WHERE user_id = ? AND is_read = 0";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error counting unread notifications",
                    ex
            );
        }

        return 0;
    }

    // =========================
    // 3. GET LATEST NOTIFICATIONS
    // =========================
    public List<Notification> findLatest(int userId) {

        List<Notification> list = new ArrayList<>();

        String sql = "SELECT TOP 20 "
                + "notification_id, user_id, order_id, "
                + "title, message, is_read, created_at "
                + "FROM dbo.NOTIFICATION "
                + "WHERE user_id = ? "
                + "ORDER BY created_at DESC, notification_id DESC";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

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
            LOGGER.log(
                    Level.SEVERE,
                    "Error getting latest notifications",
                    ex
            );
        }

        return list;
    }

    // =========================
    // 4. MARK NOTIFICATION AS READ
    // =========================
    public boolean markAsRead(int notificationId, int userId) {

        String sql = "UPDATE dbo.NOTIFICATION "
                + "SET is_read = 1 "
                + "WHERE notification_id = ? "
                + "AND user_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, notificationId);
            ps.setInt(2, userId);

            return ps.executeUpdate() > 0;

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error marking notification as read",
                    ex
            );
        }

        return false;
    }
}