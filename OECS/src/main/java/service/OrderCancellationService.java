
package service;

import dao.OrderPolicyDAO;
import dao.NotificationDAO;
import dao.OrderInventoryDAO;
import db.CheckoutConnectionFactory;
import db.DBContext;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;

public class OrderCancellationService {

    private final CheckoutConnectionFactory connections;

    public OrderCancellationService() {
        this(() -> new DBContext().getConnection());
    }

    public OrderCancellationService(
            CheckoutConnectionFactory connections) {
        this.connections = connections;
    }

    public String staffCancel(int staffId, int orderId)
            throws SQLException {
        return cancel(staffId, orderId, false);
    }

    public boolean customerCancel(int userId, int orderId)
            throws SQLException {
        return "CANCELLED".equals(cancel(userId, orderId, true));
    }

    public static boolean canCancel(String status) {
        return Arrays.asList(
                "PENDING_PAYMENT",
                "PENDING_CONFIRMATION",
                "CONFIRMED",
                "PACKING"
        ).contains(OrderService.normalizeStatus(status));
    }

    private String cancel(
            int actorId,
            int orderId,
            boolean customer) throws SQLException {

        if (actorId <= 0 || orderId <= 0) {
            throw new IllegalArgumentException(
                    "Thông tin đơn hàng không hợp lệ.");
        }

        try (Connection c = connections.open()) {

            if (c == null) {
                throw new SQLException(
                        "Không kết nối được database.");
            }

            c.setAutoCommit(false);

            try {
                int owner;

                String ownerSql =
                        "SELECT user_id FROM dbo.[ORDER] "
                        + "WHERE order_id = ?";

                try (PreparedStatement p =
                        c.prepareStatement(ownerSql)) {

                    p.setInt(1, orderId);

                    try (ResultSet r = p.executeQuery()) {
                        if (!r.next()) {
                            throw new IllegalArgumentException(
                                    "Không tìm thấy đơn hàng.");
                        }

                        owner = r.getInt("user_id");
                    }
                }

                if (customer && owner != actorId) {
                    throw new IllegalArgumentException(
                            "Không tìm thấy đơn hàng.");
                }

                new OrderPolicyDAO().lockCustomer(c, owner);

                String status;
                String payment;
                boolean timedOut;
                BigDecimal total;

                String orderSql =
                        "SELECT order_status, payment_status, "
                        + "total_amount, stock_restored_at, "
                        + "CASE WHEN payment_expires_at "
                        + "<= SYSUTCDATETIME() "
                        + "THEN 1 ELSE 0 END AS timed_out "
                        + "FROM dbo.[ORDER] WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE order_id = ?";

                try (PreparedStatement p =
                        c.prepareStatement(orderSql)) {

                    p.setInt(1, orderId);

                    try (ResultSet r = p.executeQuery()) {

                        if (!r.next()) {
                            throw new IllegalArgumentException(
                                    "Không tìm thấy đơn hàng.");
                        }

                        status = OrderService.normalizeStatus(
                                r.getString("order_status"));

                        if ("CANCELLED".equals(status)) {
                            c.commit();
                            return "UNCHANGED";
                        }

                        if (!canCancel(status)) {
                            throw new IllegalArgumentException(
                                    "Chỉ được hủy đơn hàng "
                                    + "trước khi vận chuyển.");
                        }

                        if (r.getTimestamp(
                                "stock_restored_at") != null) {
                            throw new IllegalArgumentException(
                                    "Đơn đã hoàn kho.");
                        }

                        payment = r.getString("payment_status");
                        total = r.getBigDecimal("total_amount");

                        timedOut =
                                "PENDING_PAYMENT".equals(status)
                                && !"PAID".equals(payment)
                                && r.getBoolean("timed_out");
                    }
                }

                String cancellationReason =
                        timedOut
                        ? "Hết thời hạn thanh toán online"
                        : customer
                        ? "Khách hàng hủy đơn hàng"
                        : "Nhân viên hủy đơn hàng";

                // Chỉ kiểm tra giao dịch đã thu tiền.
                // Không tạo yêu cầu Refund trong hệ thống.
                boolean hasSuccessfulPayment = false;

                String paymentSql =
                        "SELECT transaction_id "
                        + "FROM dbo.PAYMENT_TRANSACTION "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE order_id = ? "
                        + "AND status = 'SUCCESS' "
                        + "AND amount > 0";

                try (PreparedStatement p =
                        c.prepareStatement(paymentSql)) {

                    p.setInt(1, orderId);

                    try (ResultSet r = p.executeQuery()) {
                        hasSuccessfulPayment = r.next();
                    }
                }

                // Không hủy một đơn đã ghi nhận tiền
                // nhưng lại không tìm thấy giao dịch online.
                // Cần đối soát trước để tránh thất lạc tiền.
                if ("PAID".equals(payment)
                        && total != null
                        && total.signum() > 0
                        && !hasSuccessfulPayment) {

                    throw new IllegalArgumentException(
                            "Đơn đã được ghi nhận thanh toán "
                            + "nhưng không tìm thấy giao dịch thu tiền. "
                            + "Vui lòng đối soát trước khi hủy.");
                }

                // Khôi phục tồn kho theo quy trình cũ.
                boolean deducted =
                        "CONFIRMED".equals(status)
                        || "PACKING".equals(status);

                if (deducted) {
                    new OrderInventoryDAO().restore(c, orderId);
                } else {
                    new OrderInventoryDAO()
                            .releaseReservation(c, orderId);
                }

                String cancellationSource =
                        timedOut
                        ? "SYSTEM"
                        : customer
                        ? "CUSTOMER"
                        : "STAFF";

                // Đơn đã nhận tiền vẫn giữ PAID.
                // PAID không có nghĩa là đã hoàn tiền.
                String updatedPaymentStatus =
                        hasSuccessfulPayment ? "PAID" : payment;

                String updateOrderSql =
                        "UPDATE dbo.[ORDER] SET "
                        + "order_status = 'CANCELLED', "
                        + "cancellation_source = "
                        + "CASE WHEN ? = 'CUSTOMER' "
                        + "THEN NULL ELSE ? END, "
                        + "cancelled_at = "
                        + "CASE WHEN ? = 'CUSTOMER' "
                        + "THEN NULL ELSE SYSUTCDATETIME() END, "
                        + "cancel_request_status = NULL, "
                        + "cancel_request_reason = NULL, "
                        + "cancel_requested_at = NULL, "
                        + "cancel_reviewed_by = NULL, "
                        + "cancel_reviewed_at = NULL, "
                        + "cancel_review_note = NULL, "
                        + "stock_restored_at = "
                        + "CASE WHEN ? = 1 "
                        + "THEN SYSDATETIME() "
                        + "ELSE stock_restored_at END, "
                        + "payment_expires_at = NULL, "
                        + "payment_status = ? "
                        + "WHERE order_id = ?";

                update(
                        c,
                        updateOrderSql,
                        cancellationSource,
                        cancellationSource,
                        cancellationSource,
                        deducted ? 1 : 0,
                        updatedPaymentStatus,
                        orderId
                );

                // Đóng các giao dịch đang chờ.
                update(
                        c,
                        "UPDATE dbo.PAYMENT_TRANSACTION "
                        + "SET status = ? "
                        + "WHERE order_id = ? "
                        + "AND status = 'PENDING'",
                        timedOut ? "EXPIRED" : "CANCELLED",
                        orderId
                );

                // Ghi lịch sử hủy đơn.
                update(
                        c,
                        "INSERT INTO dbo.ORDER_STATUS_HISTORY "
                        + "(order_id, status, old_status, "
                        + "actor_type, changed_by, reason) "
                        + "VALUES (?, 'CANCELLED', ?, ?, ?, ?)",
                        orderId,
                        status,
                        cancellationSource,
                        "SYSTEM".equals(cancellationSource)
                                ? null : actorId,
                        cancellationReason
                );

                // Nếu đã thu tiền online, ghi nhật ký
                // để Staff kiểm tra và xử lý thủ công.
                if (hasSuccessfulPayment) {

                    String description =
                            "Đơn hàng đã hủy nhưng đã nhận "
                            + "thanh toán online. Staff cần "
                            + "liên hệ khách hàng và đối soát "
                            + "khoản tiền ngoài hệ thống.";

                    update(
                            c,
                            "INSERT INTO dbo.AUDIT_LOG "
                            + "(actor_user_id, action, entity_type, "
                            + "entity_id, description) "
                            + "VALUES (?, ?, ?, ?, ?)",
                            "SYSTEM".equals(cancellationSource)
                                    ? null : actorId,
                            "PAYMENT_REVIEW",
                            "ORDER",
                            orderId,
                            description
                    );
                }

                // Thông báo hủy đơn.
                if (!NotificationDAO
                        .createOrderStatusNotification(
                                c, orderId, "CANCELLED")) {

                    throw new SQLException(
                            "Không tạo được thông báo hủy đơn.");
                }

                // Ghi nhận số lần khách tự hủy đơn.
                if (customer && !timedOut) {
                    new OrderPolicyDAO()
                            .recordCancellation(c, owner, orderId);
                }

                c.commit();
                return "CANCELLED";

            } catch (SQLException | RuntimeException e) {

                try {
                    c.rollback();
                } catch (SQLException rollback) {
                    e.addSuppressed(rollback);
                }

                throw e;
            }
        }
    }

    private static int update(
            Connection c,
            String sql,
            Object... values) throws SQLException {

        try (PreparedStatement p = c.prepareStatement(sql)) {

            for (int i = 0; i < values.length; i++) {
                p.setObject(i + 1, values[i]);
            }

            return p.executeUpdate();
        }
    }
}
