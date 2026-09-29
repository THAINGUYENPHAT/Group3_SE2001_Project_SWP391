package dao;

import java.math.BigDecimal;
import java.sql.*;
import java.util.*;
import model.Order;
import model.OrderItem;

/**
 * Receives caller's Connection: transaction is owned by OrderService.
 */
public class OrderDAO {

    public int insert(Connection c, Order o) throws SQLException {
        String sql = "INSERT INTO dbo.[ORDER] (user_id,address_id,total_amount,shipping_fee,order_status,payment_method,payment_status,recipient_name,recipient_phone,shipping_address,discount_amount) "
                + "VALUES (?,?,?,?,?,?,?,?,?,?,?)";
        try (PreparedStatement p = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            p.setInt(1, o.getUserId());
            p.setInt(2, o.getAddressId());
            p.setBigDecimal(3, o.getTotalAmount());
            p.setBigDecimal(4, o.getShippingFee());
            p.setString(5, o.getOrderStatus());
            p.setString(6, o.getPaymentMethod());
            p.setString(7, o.getPaymentStatus());
            p.setString(8, o.getRecipientName());
            p.setString(9, o.getRecipientPhone());
            p.setString(10, o.getShippingAddress());
            p.setBigDecimal(11, o.getDiscountAmount());
            p.executeUpdate();
            try (ResultSet r = p.getGeneratedKeys()) {
                if (!r.next()) {
                    throw new SQLException("Cannot retrieve order ID");
                }
                return r.getInt(1);
            }
        }
    }

    public void insertItem(Connection c, int orderId, int skuId, BigDecimal price, int qty) throws SQLException {
        try (PreparedStatement p = c.prepareStatement("INSERT INTO dbo.ORDER_ITEM (order_id,sku_id,price,quantity) VALUES (?,?,?,?)")) {
            p.setInt(1, orderId);
            p.setInt(2, skuId);
            p.setBigDecimal(3, price);
            p.setInt(4, qty);
            p.executeUpdate();
        }
    }

    public void addHistory(Connection c, int orderId, String status) throws SQLException {
        try (PreparedStatement p = c.prepareStatement("INSERT INTO dbo.ORDER_STATUS_HISTORY (order_id,status) VALUES (?,?)")) {
            p.setInt(1, orderId);
            p.setString(2, status);
            p.executeUpdate();
        }
    }

    public List<Order> findByUser(Connection c, int userId) throws SQLException {
        List<Order> orders = new ArrayList<>();
        try (PreparedStatement p = c.prepareStatement("SELECT order_id,user_id,address_id,total_amount,shipping_fee,order_status,payment_method,payment_status,recipient_name,recipient_phone,shipping_address,created_at,payment_expires_at,discount_amount FROM dbo.[ORDER] WHERE user_id=? ORDER BY created_at DESC,order_id DESC")) {
            p.setInt(1, userId);
            try (ResultSet r = p.executeQuery()) {
                while (r.next()) {
                    Order o = new Order();
                    o.setOrderId(r.getInt("order_id"));
                    o.setUserId(r.getInt("user_id"));
                    o.setAddressId(r.getInt("address_id"));
                    o.setTotalAmount(r.getBigDecimal("total_amount"));
                    o.setShippingFee(r.getBigDecimal("shipping_fee"));
                    o.setOrderStatus(r.getString("order_status"));
                    o.setPaymentMethod(r.getString("payment_method"));
                    o.setPaymentStatus(r.getString("payment_status"));
                    o.setRecipientName(r.getString("recipient_name"));
                    o.setRecipientPhone(r.getString("recipient_phone"));
                    o.setShippingAddress(r.getString("shipping_address"));
                    o.setCreatedAt(r.getTimestamp("created_at"));
                    o.setPaymentExpiresAt(r.getTimestamp("payment_expires_at"));
                    o.setDiscountAmount(r.getBigDecimal("discount_amount"));
                    orders.add(o);
                }
            }
        }
        return orders;
    }
}
