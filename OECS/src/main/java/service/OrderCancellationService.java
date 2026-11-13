package service;

import dao.OrderPolicyDAO;
import dao.NotificationDAO;
import db.CheckoutConnectionFactory;
import db.DBContext;
import java.math.BigDecimal;
import java.sql.*;
import java.util.*;

/** Cancellation decisions, stock and refund records share the order lock and transaction. */
public class OrderCancellationService {
    private final CheckoutConnectionFactory connections;
    public OrderCancellationService() { this(() -> new DBContext().getConnection()); }
    public OrderCancellationService(CheckoutConnectionFactory connections) { this.connections = connections; }

    /** Staff may cancel before shipment. Repeated cancellation does not restore stock again. */
    public String staffCancel(int staffId, int orderId) throws SQLException {
        if (staffId <= 0 || orderId <= 0) throw new IllegalArgumentException("Thông tin đơn hàng không hợp lệ.");
        try (Connection c = connections.open()) {
            if (c == null) throw new SQLException("Không kết nối được database.");
            c.setAutoCommit(false);
            try {
                int owner;
                try (PreparedStatement p = c.prepareStatement("SELECT user_id FROM dbo.[ORDER] WHERE order_id=?")) {
                    p.setInt(1,orderId);
                    try (ResultSet r=p.executeQuery()) {
                        if (!r.next()) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
                        owner=r.getInt(1);
                    }
                }
                new OrderPolicyDAO().lockCustomer(c,owner);
                String status,payment;
                boolean timedOut;
                BigDecimal total;
                try (PreparedStatement p=c.prepareStatement("SELECT order_status,payment_status,total_amount,stock_restored_at, "
                        + "CASE WHEN payment_expires_at <= SYSUTCDATETIME() THEN 1 ELSE 0 END AS timed_out "
                        + "FROM dbo.[ORDER] WITH (UPDLOCK,HOLDLOCK) WHERE order_id=?")) {
                    p.setInt(1,orderId);
                    try(ResultSet r=p.executeQuery()) {
                        if(!r.next()) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
                        status=OrderService.normalizeStatus(r.getString("order_status"));
                        if("CANCELLED".equals(status)) { c.commit(); return "UNCHANGED"; }
                        if(!Arrays.asList("PENDING_PAYMENT","PENDING_CONFIRMATION","CONFIRMED","PACKING").contains(status))
                            throw new IllegalArgumentException("Không thể hủy đơn đang giao hoặc đã hoàn thành.");
                        if(r.getTimestamp("stock_restored_at")!=null) throw new IllegalArgumentException("Đơn đã hoàn kho.");
                        payment=r.getString("payment_status");
                        total=r.getBigDecimal("total_amount");
                        timedOut="PENDING_PAYMENT".equals(status)&&!"PAID".equals(payment)&&r.getBoolean("timed_out");
                    }
                }
                String cancellationReason=timedOut ? "Hết thời hạn thanh toán online" : "Nhân viên hủy đơn hàng";
                boolean refund = false;
                // Never label a refund successful here. Staff reconcile using the existing refund screen.
                try (PreparedStatement p = c.prepareStatement("SELECT t.transaction_id,t.amount FROM dbo.PAYMENT_TRANSACTION t WITH (UPDLOCK,HOLDLOCK) "
                        + "WHERE t.order_id=? AND t.status='SUCCESS' AND t.amount>0 ORDER BY t.transaction_id")) {
                    p.setInt(1, orderId);
                    List<Object[]> paid = new ArrayList<>();
                    try (ResultSet r = p.executeQuery()) {
                        while (r.next()) paid.add(new Object[]{r.getLong(1), r.getBigDecimal(2)});
                    }
                    if ("PAID".equals(payment) && total.signum() > 0 && paid.isEmpty())
                        throw new IllegalArgumentException("Chưa tìm thấy giao dịch thu tiền để hoàn. Cần đối soát trước khi hủy.");
                    for (Object[] tx : paid) {
                        update(c, "INSERT INTO dbo.PAYMENT_REFUND(transaction_id,refund_amount,reason) SELECT ?,?,? "
                                + "WHERE NOT EXISTS (SELECT 1 FROM dbo.PAYMENT_REFUND WHERE transaction_id=?)",
                                tx[0], tx[1], cancellationReason, tx[0]);
                        refund = true;
                    }
                }
                List<int[]> items = new ArrayList<>();
                try (PreparedStatement p = c.prepareStatement("SELECT sku_id,SUM(quantity) FROM dbo.ORDER_ITEM WHERE order_id=? GROUP BY sku_id ORDER BY sku_id")) {
                    p.setInt(1, orderId);
                    try (ResultSet r = p.executeQuery()) { while (r.next()) items.add(new int[]{r.getInt(1),r.getInt(2)}); }
                }
                if (items.isEmpty()) throw new SQLException("Đơn không có sản phẩm để hoàn kho.");
                for (int[] item : items) {
                    if (item[1] <= 0 || update(c,"UPDATE dbo.PRODUCT_SKU SET stock_quantity=stock_quantity+? WHERE sku_id=?",item[1],item[0]) != 1)
                        throw new SQLException("Không hoàn được tồn kho.");
                }
                update(c,"UPDATE dbo.[ORDER] SET order_status='CANCELLED',stock_restored_at=SYSDATETIME(),payment_expires_at=NULL,"
                        + "payment_status=? WHERE order_id=?", refund ? "REFUND_PENDING" : payment, orderId);
                update(c,"UPDATE dbo.PAYMENT_TRANSACTION SET status=? WHERE order_id=? AND status='PENDING'",timedOut ? "EXPIRED" : "CANCELLED",orderId);
                update(c,"INSERT INTO dbo.ORDER_STATUS_HISTORY(order_id,status) VALUES (?,'CANCELLED')",orderId);
                if (!NotificationDAO.createOrderStatusNotification(c, orderId, "CANCELLED"))
                    throw new SQLException("Không tạo được thông báo hủy đơn.");
                c.commit(); return "CANCELLED";
            } catch (SQLException | RuntimeException e) {
                try { c.rollback(); } catch (SQLException rollback) { e.addSuppressed(rollback); }
                throw e;
            }
        }
    }

    private static int update(Connection c, String sql, Object... values) throws SQLException {
        try (PreparedStatement p = c.prepareStatement(sql)) {
            for (int i=0;i<values.length;i++) p.setObject(i+1,values[i]);
            return p.executeUpdate();
        }
    }
}
