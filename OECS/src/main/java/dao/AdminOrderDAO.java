package dao;

import db.DBContext;
import model.Order;
import model.OrderItem;
import service.OrderStatusPolicy;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class AdminOrderDAO extends DBContext {
    private static final Logger LOGGER = Logger.getLogger(AdminOrderDAO.class.getName());

    public List<Order> getList() {
        List<Order> list = new ArrayList<>();

        String sql = "SELECT o.order_id, "
                + "o.user_id, "
                + "o.address_id, "
                + "o.shipping_partner_id, "
                + "o.total_amount, "
                + "o.shipping_fee, "
                + "o.created_at, "
                + "o.recipient_name, "
                + "o.recipient_phone, "
                + "o.shipping_address, "
                + "o.order_status "
                + "FROM dbo.[ORDER] o "
                + "ORDER BY o.created_at DESC, o.order_id DESC";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                list.add(mapOrder(rs));
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                            "Lỗi lấy danh sách Order!", ex);
        }

        return list;
    }

    public Order getById(int id) {
        String sql = "SELECT o.order_id, "
                + "o.user_id, "
                + "o.address_id, "
                + "o.shipping_partner_id, "
                + "o.total_amount, "
                + "o.shipping_fee, "
                + "o.created_at, "
                + "o.recipient_name, "
                + "o.recipient_phone, "
                + "o.shipping_address, "
                + "o.order_status, "
                + "o.payment_method, "
                + "o.payment_status "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.order_id = ?";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {
            statement.setInt(1, id);

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    Order order = mapOrder(rs);
                    order.setPaymentMethod(rs.getString("payment_method"));
                    order.setPaymentStatus(rs.getString("payment_status"));

                    return order;
                }
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                            "Lỗi lấy Order theo ID!", ex);
        }

        return null;
    }

    public List<OrderItem> getItemsByOrderId(int orderId) {
        List<OrderItem> list = new ArrayList<>();

        String sql = "SELECT oi.*, "
                + "p.product_name, "
                + "s.sku_code, "
                + "s.stock_quantity "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.PRODUCT_SKU s ON oi.sku_id = s.sku_id "
                + "JOIN dbo.PRODUCT p ON s.product_id = p.product_id "
                + "WHERE oi.order_id = ?";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {
            statement.setInt(1, orderId);

            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    OrderItem item = new OrderItem();

                    item.setOrderItemId(
                            rs.getInt("order_item_id")
                    );

                    item.setOrderId(
                            rs.getInt("order_id")
                    );

                    item.setSkuId(
                            rs.getInt("sku_id")
                    );

                    item.setPrice(
                            rs.getBigDecimal("price")
                    );

                    item.setQuantity(
                            rs.getInt("quantity")
                    );
                    item.setProductName(rs.getString("product_name"));
                    item.setSkuCode(rs.getString("sku_code"));
                    item.setStockQuantity(rs.getInt("stock_quantity"));

                    list.add(item);
                }
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy Order Item!", ex);
        }

        return list;
    }

    public String getCurrentStatus(int orderId) {
        String sql = "SELECT order_status "
                + "FROM dbo.[ORDER] "
                + "WHERE order_id = ?";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {
            statement.setInt(1, orderId);

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("order_status");
                }
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy trạng thái Order!", ex);
        }

        return null;
    }

    private Order mapOrder(ResultSet rs) throws SQLException {
        Order order = new Order();
        order.setOrderId(rs.getInt("order_id"));
        order.setUserId(rs.getInt("user_id"));
        order.setAddressId(rs.getInt("address_id"));
        order.setShippingPartnerId((Integer) rs.getObject("shipping_partner_id"));
        order.setTotalAmount(rs.getBigDecimal("total_amount"));
        order.setShippingFee(rs.getBigDecimal("shipping_fee"));
        order.setCreatedAt(rs.getTimestamp("created_at"));
        order.setOrderStatus(rs.getString("order_status"));
        order.setRecipientName(rs.getString("recipient_name"));
        order.setRecipientPhone(rs.getString("recipient_phone"));
        order.setShippingAddress(rs.getString("shipping_address"));
        return order;
    }

    public boolean transitionStatus(int orderId, String requestedStatus)
            throws SQLException {
        String next = OrderStatusPolicy.normalize(requestedStatus);

        if (next == null || "PENDING_CONFIRMATION".equals(next) || "CANCELLED".equals(next)) {
            return false;
        }

        String selectSql = "SELECT order_status "
                + "FROM dbo.[ORDER] WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE order_id = ?";

        String updateSql = "UPDATE dbo.[ORDER] "
                + "SET order_status = ?, "
                + "delivered_at = CASE "
                + "WHEN ? = 'COMPLETED' "
                + "THEN COALESCE(delivered_at, SYSDATETIME()) "
                + "ELSE delivered_at END "
                + "WHERE order_id = ?";

        String historySql = "INSERT INTO dbo.ORDER_STATUS_HISTORY "
                + "(order_id, status) VALUES (?, ?)";

        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);

            try {
                String current;

                try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
                    ps.setInt(1, orderId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return false;
                        }

                        current = OrderStatusPolicy.normalize(
                                rs.getString("order_status")
                        );

                    }
                }

                if (!next.equals(OrderStatusPolicy.nextStatus(current))) {
                    conn.rollback();
                    return false;
                }

                try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                    ps.setString(1, next);
                    ps.setString(2, next);
                    ps.setInt(3, orderId);

                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Không thể cập nhật đơn hàng.");
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(historySql)) {
                    ps.setInt(1, orderId);
                    ps.setString(2, next);

                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Không thể ghi lịch sử đơn hàng.");
                    }
                }

                conn.commit();
                return true;
            } catch (SQLException | RuntimeException e) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }
}
