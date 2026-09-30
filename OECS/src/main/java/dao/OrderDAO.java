package dao;

import java.math.BigDecimal;
import java.sql.*;
import java.util.*;
import model.Order;
import model.OrderItem;
import model.OrderStatusHistory;

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
    // ================================
// LAY ORDER CUA USER THEO ID
// ================================

    public Order findByIdAndUser(
            Connection c,
            int orderId,
            int userId
    ) throws SQLException {

        String sql
                = "SELECT "
                + "order_id, user_id, address_id, "
                + "total_amount, shipping_fee, "
                + "order_status, payment_method, payment_status, "
                + "recipient_name, recipient_phone, shipping_address, "
                + "created_at, payment_expires_at, discount_amount "
                + "FROM dbo.[ORDER] "
                + "WHERE order_id = ? "
                + "AND user_id = ?";

        try (PreparedStatement p
                = c.prepareStatement(sql)) {

            p.setInt(1, orderId);
            p.setInt(2, userId);

            try (ResultSet r = p.executeQuery()) {

                if (r.next()) {

                    Order o = new Order();

                    o.setOrderId(
                            r.getInt("order_id")
                    );

                    o.setUserId(
                            r.getInt("user_id")
                    );

                    o.setAddressId(
                            r.getInt("address_id")
                    );

                    o.setTotalAmount(
                            r.getBigDecimal("total_amount")
                    );

                    o.setShippingFee(
                            r.getBigDecimal("shipping_fee")
                    );

                    o.setOrderStatus(
                            r.getString("order_status")
                    );

                    o.setPaymentMethod(
                            r.getString("payment_method")
                    );

                    o.setPaymentStatus(
                            r.getString("payment_status")
                    );

                    o.setRecipientName(
                            r.getString("recipient_name")
                    );

                    o.setRecipientPhone(
                            r.getString("recipient_phone")
                    );

                    o.setShippingAddress(
                            r.getString("shipping_address")
                    );

                    o.setCreatedAt(
                            r.getTimestamp("created_at")
                    );

                    o.setPaymentExpiresAt(
                            r.getTimestamp("payment_expires_at")
                    );

                    o.setDiscountAmount(
                            r.getBigDecimal("discount_amount")
                    );

                    return o;
                }
            }
        }

        return null;
    }

// ================================
// LAY ITEM CUA ORDER
// ================================
    public List<OrderItem> findItemsByOrder(
            Connection c,
            int orderId
    ) throws SQLException {

        List<OrderItem> items
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "order_item_id, "
                + "order_id, "
                + "sku_id, "
                + "price, "
                + "quantity "
                + "FROM dbo.ORDER_ITEM "
                + "WHERE order_id = ? "
                + "ORDER BY order_item_id";

        try (PreparedStatement p
                = c.prepareStatement(sql)) {

            p.setInt(1, orderId);

            try (ResultSet r = p.executeQuery()) {

                while (r.next()) {

                    OrderItem item
                            = new OrderItem();

                    item.setOrderItemId(
                            r.getInt("order_item_id")
                    );

                    item.setOrderId(
                            r.getInt("order_id")
                    );

                    item.setSkuId(
                            r.getInt("sku_id")
                    );

                    item.setPrice(
                            r.getBigDecimal("price")
                    );

                    item.setQuantity(
                            r.getInt("quantity")
                    );

                    items.add(item);
                }
            }
        }

        return items;
    }
    // ================================
// LAY ORDER DE HUY
// ================================

    public Order findForCancel(
            Connection c,
            int orderId,
            int userId
    ) throws SQLException {

        String sql
                = "SELECT order_id, user_id, order_status, "
                + "payment_method, payment_status "
                + "FROM dbo.[ORDER] WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE order_id = ? "
                + "AND user_id = ?";

        try (PreparedStatement p = c.prepareStatement(sql)) {

            p.setInt(1, orderId);
            p.setInt(2, userId);

            try (ResultSet r = p.executeQuery()) {

                if (r.next()) {

                    Order order = new Order();

                    order.setOrderId(
                            r.getInt("order_id")
                    );

                    order.setUserId(
                            r.getInt("user_id")
                    );

                    order.setOrderStatus(
                            r.getString("order_status")
                    );

                    order.setPaymentMethod(
                            r.getString("payment_method")
                    );

                    order.setPaymentStatus(
                            r.getString("payment_status")
                    );

                    return order;
                }
            }
        }

        return null;
    }

// ================================
// CAP NHAT TRANG THAI ORDER
// ================================
    public int updateStatus(
            Connection c,
            int orderId,
            String oldStatus,
            String newStatus
    ) throws SQLException {

        String sql
                = "UPDATE dbo.[ORDER] "
                + "SET order_status = ? "
                + "WHERE order_id = ? "
                + "AND order_status = ?";

        try (PreparedStatement p = c.prepareStatement(sql)) {

            p.setString(1, newStatus);
            p.setInt(2, orderId);
            p.setString(3, oldStatus);

            return p.executeUpdate();
        }
    }
// ================================
// LAY LICH SU TRANG THAI ORDER
// ================================

    public List<OrderStatusHistory> findHistoryByOrder(
            Connection c,
            int orderId
    ) throws SQLException {

        List<OrderStatusHistory> histories
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "history_id, "
                + "order_id, "
                + "status, "
                + "created_at "
                + "FROM dbo.ORDER_STATUS_HISTORY "
                + "WHERE order_id = ? "
                + "ORDER BY created_at ASC, history_id ASC";

        try (PreparedStatement p
                = c.prepareStatement(sql)) {

            p.setInt(1, orderId);

            try (ResultSet r = p.executeQuery()) {

                while (r.next()) {

                    OrderStatusHistory history
                            = new OrderStatusHistory();

                    history.setHistoryId(
                            r.getInt("history_id")
                    );

                    history.setOrderId(
                            r.getInt("order_id")
                    );

                    history.setStatus(
                            r.getString("status")
                    );

                    history.setCreatedAt(
                            r.getTimestamp("created_at")
                    );

                    histories.add(history);
                }
            }
        }

        return histories;
    }
}
