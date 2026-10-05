package dao;

import db.DBContext;
import model.Order;
import model.OrderItem;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class AdminOrderDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(AdminOrderDAO.class.getName());

    // =========================================================
    // 1. LẤY DANH SÁCH ĐƠN HÀNG
    // =========================================================
    public List<Order> getList() {

        List<Order> list = new ArrayList<>();

        String sql = "SELECT o.order_id, "
                + "o.user_id, "
                + "o.address_id, "
                + "o.shipping_partner_id, "
                + "o.total_amount, "
                + "o.shipping_fee, "
                + "o.created_at, "
                + "h.status AS order_status "
                + "FROM dbo.[ORDER] o "
                + "OUTER APPLY ( "
                + "    SELECT TOP 1 status "
                + "    FROM ORDER_STATUS_HISTORY "
                + "    WHERE order_id = o.order_id "
                + "    ORDER BY status_id DESC "
                + ") h "
                + "ORDER BY o.created_at DESC, o.order_id DESC";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {

                Order order = new Order();

                order.setOrderId(rs.getInt("order_id"));
                order.setUserId(rs.getInt("user_id"));
                order.setAddressId(rs.getInt("address_id"));

                order.setShippingPartnerId(
                        (Integer) rs.getObject("shipping_partner_id")
                );

                order.setTotalAmount(
                        rs.getBigDecimal("total_amount")
                );

                order.setShippingFee(
                        rs.getBigDecimal("shipping_fee")
                );

                order.setCreatedAt(
                        rs.getTimestamp("created_at")
                );

                // Status lấy từ ORDER_STATUS_HISTORY
                order.setOrderStatus(
                        rs.getString("order_status")
                );

                list.add(order);
            }

        } catch (SQLException ex) {
            ex.printStackTrace();
            Logger.getLogger(AdminOrderDAO.class.getName())
                    .log(Level.SEVERE,
                            "Lỗi lấy danh sách Order!", ex);
        }

        return list;
    }

    // =========================================================
    // 2. LẤY CHI TIẾT ĐƠN HÀNG
    // =========================================================
    public Order getById(int id) {

        String sql = "SELECT o.order_id, "
                + "o.user_id, "
                + "o.address_id, "
                + "o.shipping_partner_id, "
                + "o.total_amount, "
                + "o.shipping_fee, "
                + "o.created_at, "
                + "h.status AS order_status "
                + "FROM dbo.[ORDER] o "
                + "OUTER APPLY ( "
                + "    SELECT TOP 1 status "
                + "    FROM ORDER_STATUS_HISTORY "
                + "    WHERE order_id = o.order_id "
                + "    ORDER BY status_id DESC "
                + ") h "
                + "WHERE o.order_id = ?";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, id);

            try (ResultSet rs = statement.executeQuery()) {

                if (rs.next()) {

                    Order order = new Order();

                    order.setOrderId(
                            rs.getInt("order_id")
                    );

                    order.setUserId(
                            rs.getInt("user_id")
                    );

                    order.setAddressId(
                            rs.getInt("address_id")
                    );

                    order.setShippingPartnerId(
                            (Integer) rs.getObject("shipping_partner_id")
                    );

                    order.setTotalAmount(
                            rs.getBigDecimal("total_amount")
                    );

                    order.setShippingFee(
                            rs.getBigDecimal("shipping_fee")
                    );

                    order.setCreatedAt(
                            rs.getTimestamp("created_at")
                    );

                    order.setOrderStatus(
                            rs.getString("order_status")
                    );

                    return order;
                }
            }

        } catch (SQLException ex) {
            ex.printStackTrace();
            Logger.getLogger(AdminOrderDAO.class.getName())
                    .log(Level.SEVERE,
                            "Lỗi lấy Order theo ID!", ex);
        }

        return null;
    }

    // =========================================================
    // 3. LẤY CÁC SẢN PHẨM TRONG ĐƠN
    // =========================================================
    public List<OrderItem> getItemsByOrderId(int orderId) {

        List<OrderItem> list = new ArrayList<>();

        String sql
                = "SELECT order_item_id, order_id, sku_id, "
                + "price, quantity "
                + "FROM ORDER_ITEM "
                + "WHERE order_id = ?";

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

                    list.add(item);
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy Order Item!",
                    ex
            );
        }

        return list;
    }

    // =========================================================
    // 4. LẤY TRẠNG THÁI HIỆN TẠI
    // =========================================================
    public String getCurrentStatus(int orderId) {

        String sql
                = "SELECT TOP 1 status "
                + "FROM ORDER_STATUS_HISTORY "
                + "WHERE order_id = ? "
                + "ORDER BY updated_at DESC, status_id DESC";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, orderId);

            try (ResultSet rs = statement.executeQuery()) {

                if (rs.next()) {
                    return rs.getString("status");
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy trạng thái Order!",
                    ex
            );
        }

        return null;
    }

    // =========================================================
    // 5. CẬP NHẬT TRẠNG THÁI
    // =========================================================
    public int updateStatus(int orderId, String status) {

        String sql
                = "INSERT INTO ORDER_STATUS_HISTORY "
                + "(order_id, status) "
                + "VALUES (?, ?)";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, orderId);
            statement.setString(2, status);

            return statement.executeUpdate();

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi cập nhật trạng thái Order!",
                    ex
            );
        }

        return 0;
    }

    // =========================================================
    // 6. HỦY ĐƠN
    // =========================================================
    public int cancelOrder(int orderId) {

        String sql
                = "INSERT INTO ORDER_STATUS_HISTORY "
                + "(order_id, status) "
                + "VALUES (?, ?)";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, orderId);
            statement.setString(2, "Cancelled");

            return statement.executeUpdate();

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi hủy Order!",
                    ex
            );
        }

        return 0;
    }
}
