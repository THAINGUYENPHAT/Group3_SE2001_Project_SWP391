package dao;

import model.Order;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Receives caller's Connection: transaction is owned by OrderService.
 */
public class OrderDAO {

    private static final Logger LOGGER = Logger.getLogger(OrderDAO.class.getName());

    // =====================================================
    // 1. THÊM ĐƠN HÀNG MỚI
    // =====================================================
    public int insert(Connection conn, Order order) throws SQLException {
        String sql = "INSERT INTO dbo.[ORDER] (user_id, address_id, total_amount, shipping_fee, "
                + "order_status, payment_method, payment_status, recipient_name, recipient_phone, "
                + "shipping_address, discount_amount) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
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

            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (!rs.next()) {
                    throw new SQLException("Cannot retrieve order ID");
                }
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi thêm đơn hàng mới!", e);
            throw e;
        }
    }

    // =====================================================
    // 2. THÊM CHI TIẾT ĐƠN HÀNG (ORDER ITEM)
    // =====================================================
    public void insertItem(Connection conn, int orderId, int skuId, BigDecimal price, int quantity) throws SQLException {
        String sql = "INSERT INTO dbo.ORDER_ITEM (order_id, sku_id, price, quantity) VALUES (?, ?, ?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, skuId);
            ps.setBigDecimal(3, price);
            ps.setInt(4, quantity);

            ps.executeUpdate();
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi thêm chi tiết đơn hàng!", e);
            throw e;
        }
    }

    // =====================================================
    // 3. THÊM LỊCH SỬ TRẠNG THÁI ĐƠN HÀNG
    // =====================================================
    public void addHistory(Connection conn, int orderId, String status) throws SQLException {
        String sql = "INSERT INTO dbo.ORDER_STATUS_HISTORY (order_id, status) VALUES (?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setString(2, status);

            ps.executeUpdate();
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi thêm lịch sử trạng thái đơn hàng!", e);
            throw e;
        }
    }

    // =====================================================
    // 4. LẤY DANH SÁCH ĐƠN HÀNG THEO USER ID
    // =====================================================
    public List<Order> findByUser(Connection conn, int userId) throws SQLException {
        List<Order> orders = new ArrayList<>();
        String sql = "SELECT order_id, user_id, address_id, total_amount, shipping_fee, order_status, "
                + "payment_method, payment_status, recipient_name, recipient_phone, shipping_address, "
                + "created_at, payment_expires_at, discount_amount "
                + "FROM dbo.[ORDER] WHERE user_id = ? ORDER BY created_at DESC, order_id DESC";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Order order = new Order();
                    order.setOrderId(rs.getInt("order_id"));
                    order.setUserId(rs.getInt("user_id"));
                    order.setAddressId(rs.getInt("address_id"));
                    order.setTotalAmount(rs.getBigDecimal("total_amount"));
                    order.setShippingFee(rs.getBigDecimal("shipping_fee"));
                    order.setOrderStatus(rs.getString("order_status"));
                    order.setPaymentMethod(rs.getString("payment_method"));
                    order.setPaymentStatus(rs.getString("payment_status"));
                    order.setRecipientName(rs.getString("recipient_name"));
                    order.setRecipientPhone(rs.getString("recipient_phone"));
                    order.setShippingAddress(rs.getString("shipping_address"));
                    order.setCreatedAt(rs.getTimestamp("created_at"));
                    order.setPaymentExpiresAt(rs.getTimestamp("payment_expires_at"));
                    order.setDiscountAmount(rs.getBigDecimal("discount_amount"));

                    orders.add(order);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi tìm kiếm đơn hàng theo User ID!", e);
            throw e;
        }

        return orders;
    }
}