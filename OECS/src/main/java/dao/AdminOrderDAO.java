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
                + "o.recipient_name, "
                + "o.recipient_phone, "
                + "o.shipping_address, "
                + "o.order_status "
                + "FROM dbo.[ORDER] o "
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
                order.setRecipientName(rs.getString("recipient_name"));
                order.setRecipientPhone(rs.getString("recipient_phone"));
                order.setShippingAddress(rs.getString("shipping_address"));

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
                + "o.recipient_name, "
                + "o.recipient_phone, "
                + "o.shipping_address, "
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
                    order.setRecipientName(rs.getString("recipient_name"));
                    order.setRecipientPhone(rs.getString("recipient_phone"));
                    order.setShippingAddress(rs.getString("shipping_address"));

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
                = "SELECT oi.*, "
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
                = "SELECT order_status "
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

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy trạng thái Order!",
                    ex
            );
        }

        return null;
    }


    private String normalizeStatus(String status) {
        if (status == null) {
            return null;
        }

        switch (status.trim().toUpperCase()) {
            case "PENDING":
            case "PENDING_CONFIRMATION":
                return "PENDING_CONFIRMATION";
            case "CONFIRMED":
                return "CONFIRMED";
            case "PACKING":
                return "PACKING";
            case "SHIPPING":
                return "SHIPPING";
            case "COMPLETED":
                return "COMPLETED";
            case "CANCELLED":
                return "CANCELLED";
            default:
                return null;
        }
    }

    public boolean transitionStatus(int orderId, String requestedStatus)
            throws SQLException {

        String next = normalizeStatus(requestedStatus);

        if (next == null || "PENDING_CONFIRMATION".equals(next)) {
            return false;
        }

        String selectSql
                = "SELECT order_status FROM dbo.[ORDER] WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE order_id = ?";

        String updateSql
        = "UPDATE dbo.[ORDER] "
        + "SET order_status = ?, "
        + "delivered_at = CASE "
        + "WHEN ? = 'COMPLETED' "
        + "THEN COALESCE(delivered_at, SYSDATETIME()) "
        + "ELSE delivered_at END "
        + "WHERE order_id = ?";

        String historySql
                = "INSERT INTO dbo.ORDER_STATUS_HISTORY (order_id, status) "
                + "VALUES (?, ?)";

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
                        current = normalizeStatus(rs.getString("order_status"));
                    }
                }

                String expectedNext;

                if ("PENDING_CONFIRMATION".equals(current)) {
                    expectedNext = "CONFIRMED";
                } else if ("CONFIRMED".equals(current)) {
                    expectedNext = "PACKING";
                } else if ("PACKING".equals(current)) {
                    expectedNext = "SHIPPING";
                } else if ("SHIPPING".equals(current)) {
                    expectedNext = "COMPLETED";
                } else {
                    expectedNext = null;
                }

                boolean valid = next.equals(expectedNext)
                        || ("CANCELLED".equals(next)
                        && expectedNext != null);

                if (!valid) {
                    conn.rollback();
                    return false;
                }

                try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
    ps.setString(1, next);
    ps.setString(2, next);
    ps.setInt(3, orderId);

    if (ps.executeUpdate() != 1) {
        conn.rollback();
        return false;
    }
}

                try (PreparedStatement ps = conn.prepareStatement(historySql)) {
                    ps.setInt(1, orderId);
                    ps.setString(2, next);
                    ps.executeUpdate();
                }

                conn.commit();
                return true;

            } catch (SQLException | RuntimeException ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }
}
