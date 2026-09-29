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
}
