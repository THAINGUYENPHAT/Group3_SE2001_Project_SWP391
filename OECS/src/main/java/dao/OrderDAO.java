package dao;

import db.DBContext;
import model.Order;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class OrderDAO extends DBContext {

    // GIU HAM CU DE ORDERSERVICE HIEN TAI VAN GOI DUOC
    public int insert(Connection conn, Order order) throws SQLException {
        return insert(conn, order, null);
    }

    // TAO DON HANG CO TOKEN CHONG TRUNG
    public int insert(
            Connection conn,
            Order order,
            String checkoutToken
    ) throws SQLException {

        String sql = "INSERT INTO dbo.[ORDER] "
                + "(user_id, address_id, total_amount, shipping_fee, "
                + "order_status, payment_method, payment_status, "
                + "recipient_name, recipient_phone, shipping_address, "
                + "discount_amount, checkout_token) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(
                sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, order.getUserId());
            ps.setInt(2, order.getAddressId());
            ps.setBigDecimal(3, order.getTotalAmount());
            ps.setBigDecimal(4, order.getShippingFee());
            ps.setString(5, order.getOrderStatus());
            ps.setString(6, order.getPaymentMethod());
            ps.setString(7, order.getPaymentStatus());
            ps.setString(8, order.getRecipientName());
            ps.setString(9, order.getRecipientPhone());
            ps.setString(10, order.getShippingAddress());
            ps.setBigDecimal(11, order.getDiscountAmount());
            ps.setString(12, checkoutToken);

            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (!rs.next()) {
                    throw new SQLException(
                            "Khong lay duoc ma don hang."
                    );
                }

                return rs.getInt(1);
            }
        }
    }

    // LUU CHI TIET DON HANG
    public void insertItem(
            Connection conn,
            int orderId,
            int skuId,
            BigDecimal price,
            int quantity
    ) throws SQLException {

        String sql = "INSERT INTO dbo.ORDER_ITEM "
                + "(order_id, sku_id, price, quantity) "
                + "VALUES (?, ?, ?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, skuId);
            ps.setBigDecimal(3, price);
            ps.setInt(4, quantity);

            ps.executeUpdate();
        }
    }

    // LUU LICH SU TRANG THAI
    public void addHistory(
            Connection conn,
            int orderId,
            String status
    ) throws SQLException {

        String sql = "INSERT INTO dbo.ORDER_STATUS_HISTORY "
                + "(order_id, status) VALUES (?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setString(2, status);

            ps.executeUpdate();
        }
    }

    // TIM DON DA TAO BANG TOKEN TRONG TRANSACTION
    public Integer findIdByToken(
            Connection conn,
            int userId,
            String checkoutToken
    ) throws SQLException {

        String sql = "SELECT order_id "
                + "FROM dbo.[ORDER] "
                + "WHERE user_id = ? AND checkout_token = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setString(2, checkoutToken);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("order_id");
                }

                return null;
            }
        }
    }

    // TIM DON BANG TOKEN KHI GOI TU SERVLET
    public Integer findIdByToken(
            int userId,
            String checkoutToken
    ) throws SQLException {

        try (Connection conn = getConnection()) {
            if (conn == null) {
                throw new SQLException(
                        "Khong ket noi duoc database."
                );
            }

            return findIdByToken(conn, userId, checkoutToken);
        }
    }

    // LAY DON THEO ID VA KIEM TRA CHU SO HUU
    public Order findByIdAndUser(
            int orderId,
            int userId
    ) throws SQLException {

        String sql = "SELECT * FROM dbo.[ORDER] "
                + "WHERE order_id = ? AND user_id = ?";

        try (Connection conn = getConnection()) {
            if (conn == null) {
                throw new SQLException(
                        "Khong ket noi duoc database."
                );
            }

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, orderId);
                ps.setInt(2, userId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return mapOrder(rs);
                    }

                    return null;
                }
            }
        }
    }

    // LAY DANH SACH DON HANG CUA USER
    public List<Order> findByUser(
            Connection conn,
            int userId
    ) throws SQLException {

        List<Order> orders = new ArrayList<>();

        String sql = "SELECT * FROM dbo.[ORDER] "
                + "WHERE user_id = ? "
                + "ORDER BY created_at DESC, order_id DESC";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    orders.add(mapOrder(rs));
                }
            }
        }

        return orders;
    }

    // CHUYEN RESULTSET THANH OBJECT ORDER
    private Order mapOrder(ResultSet rs) throws SQLException {
        Order order = new Order();

        order.setOrderId(rs.getInt("order_id"));
        order.setUserId(rs.getInt("user_id"));
        order.setAddressId(rs.getInt("address_id"));

        order.setShippingPartnerId(
                (Integer) rs.getObject("shipping_partner_id")
        );

        order.setTotalAmount(rs.getBigDecimal("total_amount"));
        order.setShippingFee(rs.getBigDecimal("shipping_fee"));
        order.setDiscountAmount(rs.getBigDecimal("discount_amount"));

        order.setOrderStatus(rs.getString("order_status"));
        order.setPaymentMethod(rs.getString("payment_method"));
        order.setPaymentStatus(rs.getString("payment_status"));

        order.setRecipientName(rs.getString("recipient_name"));
        order.setRecipientPhone(rs.getString("recipient_phone"));
        order.setShippingAddress(rs.getString("shipping_address"));

        order.setCreatedAt(rs.getTimestamp("created_at"));
        order.setPaymentExpiresAt(
                rs.getTimestamp("payment_expires_at")
        );

        return order;
    }
}
