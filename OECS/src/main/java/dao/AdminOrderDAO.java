package dao;

import db.DBContext;
import model.Order;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.OrderItem;

public class AdminOrderDAO extends DBContext {

    public List<Order> getList() {
        List<Order> list = new ArrayList<>();

        String sql = "SELECT order_id, user_id, address_id, shipping_partner_id, "
                + "total_amount, shipping_fee, discount_amount, created_at, "
                + "order_status, payment_method, payment_status, payment_expires_at, "
                + "recipient_name, recipient_phone, shipping_address "
                + "FROM dbo.[ORDER] ORDER BY created_at DESC, order_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {

                Order order = new Order();
                order.setOrderId(rs.getInt("order_id"));
                order.setUserId(rs.getInt("user_id"));
                order.setAddressId(rs.getInt("address_id"));
                order.setShippingPartnerId((Integer) rs.getObject("shipping_partner_id"));
                order.setTotalAmount(rs.getBigDecimal("total_amount"));
                order.setShippingFee(rs.getBigDecimal("shipping_fee"));
                order.setDiscountAmount(rs.getBigDecimal("discount_amount"));
                order.setCreatedAt(rs.getTimestamp("created_at"));
                order.setOrderStatus(rs.getString("order_status"));
                order.setPaymentMethod(rs.getString("payment_method"));
                order.setPaymentStatus(rs.getString("payment_status"));
                order.setPaymentExpiresAt(rs.getTimestamp("payment_expires_at"));
                order.setRecipientName(rs.getString("recipient_name"));
                order.setRecipientPhone(rs.getString("recipient_phone"));
                order.setShippingAddress(rs.getString("shipping_address"));

                list.add(order);
            }

        } catch (SQLException ex) {
            Logger.getLogger(AdminOrderDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi lấy danh sách Order!", ex);
        }

        return list;
    }

    public Order getById(int id) {

        String sql = "SELECT order_id, user_id, address_id, "
                + "shipping_partner_id, total_amount, shipping_fee, created_at "
                + "FROM [ORDER] "
                + "WHERE order_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, id);

            try (ResultSet rs = statement.executeQuery()) {

                if (rs.next()) {

                    return new Order(
                            rs.getInt("order_id"),
                            rs.getInt("user_id"),
                            rs.getInt("address_id"),
                            (Integer) rs.getObject("shipping_partner_id"),
                            rs.getBigDecimal("total_amount"),
                            rs.getBigDecimal("shipping_fee"),
                            rs.getTimestamp("created_at")
                    );
                }
            }

        } catch (SQLException ex) {
            Logger.getLogger(AdminOrderDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi lấy Order theo ID!", ex);
        }

        return null;
    }

    public List<OrderItem> getItemsByOrderId(int orderId) {

        List<OrderItem> list = new ArrayList<>();

        String sql = "SELECT order_item_id, order_id, sku_id, "
                + "price, quantity "
                + "FROM ORDER_ITEM "
                + "WHERE order_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, orderId);

            try (ResultSet rs = statement.executeQuery()) {

                while (rs.next()) {

                    OrderItem item = new OrderItem();

                    item.setOrderItemId(rs.getInt("order_item_id"));
                    item.setOrderId(rs.getInt("order_id"));
                    item.setSkuId(rs.getInt("sku_id"));
                    item.setPrice(rs.getBigDecimal("price"));
                    item.setQuantity(rs.getInt("quantity"));

                    list.add(item);
                }
            }

        } catch (SQLException ex) {
            Logger.getLogger(AdminOrderDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi lấy Order Item!", ex);
        }

        return list;
    }

    public String getCurrentStatus(int orderId) {

        String sql = "SELECT TOP 1 status "
                + "FROM ORDER_STATUS_HISTORY "
                + "WHERE order_id = ? "
                + "ORDER BY updated_at DESC, status_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, orderId);

            try (ResultSet rs = statement.executeQuery()) {

                if (rs.next()) {
                    return rs.getString("status");
                }
            }

        } catch (SQLException ex) {
            Logger.getLogger(AdminOrderDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi lấy trạng thái Order!", ex);
        }

        return null;
    }

    public int updateStatus(int orderId, String status) {

        String sql = "INSERT INTO ORDER_STATUS_HISTORY "
                + "(order_id, status) "
                + "VALUES (?, ?)";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, orderId);
            statement.setString(2, status);

            return statement.executeUpdate();

        } catch (SQLException ex) {
            Logger.getLogger(AdminOrderDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi cập nhật trạng thái Order!", ex);
        }

        return 0;
    }
    
    public int cancelOrder(int orderId) {

        String sql = "INSERT INTO ORDER_STATUS_HISTORY "
                + "(order_id, status) "
                + "VALUES (?, ?)";

        try (Connection conn = this.getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, orderId);
            statement.setString(2, "Cancelled");

            return statement.executeUpdate();

        } catch (SQLException ex) {
            Logger.getLogger(AdminOrderDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi hủy Order!", ex);
        }

        return 0;
    }
}
