package dao;

import db.DBContext;
import model.Order;
import model.OrderItem;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class AdminOrderDAO extends DBContext {

    public List<Order> getList() {
        List<Order> list = new ArrayList<>();

        String sql = "SELECT o.order_id, o.user_id, o.recipient_name, "
                + "o.total_amount, o.shipping_fee, o.created_at, o.order_status, o.payment_status, "
                + "o.cancel_request_status "
                + "FROM dbo.[ORDER] o "
                + "ORDER BY o.created_at DESC, o.order_id DESC";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                list.add(mapOrderSummary(rs));
            }
        } catch (SQLException ex) {
            throw new IllegalStateException("Không tải được dữ liệu đơn hàng.", ex);
        }

        return list;
    }

    public Order getById(int id) {
        String sql = "SELECT o.order_id, o.user_id, o.recipient_name, "
                + "o.total_amount, o.shipping_fee, o.created_at, o.order_status, o.payment_status, "
                + "o.cancel_request_status, o.cancel_request_reason, o.cancel_review_note, "
                + "o.address_id, o.discount_amount, o.recipient_phone, o.shipping_address, "
                + "CONVERT(VARCHAR(33), o.cancel_requested_at, 126) AS cancel_request_version, "
                + "o.payment_method "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.order_id = ?";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {
            statement.setInt(1, id);

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    Order order = mapOrderSummary(rs);
                    order.setAddressId(rs.getInt("address_id"));
                    order.setDiscountAmount(rs.getBigDecimal("discount_amount"));
                    order.setRecipientPhone(rs.getString("recipient_phone"));
                    order.setShippingAddress(rs.getString("shipping_address"));
                    order.setPaymentMethod(rs.getString("payment_method"));
                    order.setCancelRequestReason(rs.getString("cancel_request_reason"));
                    order.setCancelReviewNote(rs.getString("cancel_review_note"));
                    order.setCancelRequestVersion(rs.getString("cancel_request_version"));
                    return order;
                }
            }
        } catch (SQLException ex) {
            throw new IllegalStateException("Không tải được dữ liệu đơn hàng.", ex);
        }

        return null;
    }

    public List<OrderItem> getItemsByOrderId(int orderId) {
        List<OrderItem> list = new ArrayList<>();

        String sql = "SELECT oi.order_item_id, oi.order_id, oi.sku_id, oi.price, oi.quantity, "
                + "COALESCE(oi.product_name_snapshot,p.product_name) AS product_name, "
                + "COALESCE(oi.sku_code_snapshot,s.sku_code) AS sku_code, "
                + "s.stock_quantity "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.PRODUCT_SKU s ON oi.sku_id = s.sku_id "
                + "JOIN dbo.PRODUCT p ON s.product_id = p.product_id "
                + "WHERE oi.order_id = ? ORDER BY oi.order_item_id";

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
            throw new IllegalStateException("Không tải được dữ liệu đơn hàng.", ex);
        }

        return list;
    }

    private Order mapOrderSummary(ResultSet rs) throws SQLException {
        Order order = new Order();
        order.setOrderId(rs.getInt("order_id"));
        order.setUserId(rs.getInt("user_id"));
        order.setRecipientName(rs.getString("recipient_name"));
        order.setTotalAmount(rs.getBigDecimal("total_amount"));
        order.setShippingFee(rs.getBigDecimal("shipping_fee"));
        order.setCreatedAt(rs.getTimestamp("created_at"));
        order.setOrderStatus(rs.getString("order_status"));
        order.setPaymentStatus(rs.getString("payment_status"));
        order.setCancelRequestStatus(rs.getString("cancel_request_status"));
        return order;
    }

    public List<Map<String, Object>> getHistory(int orderId) {
        String sql = "SELECT status, old_status, reason, actor_type, changed_by, updated_at "
                + "FROM dbo.ORDER_STATUS_HISTORY "
                + "WHERE order_id = ? ORDER BY updated_at DESC, status_id DESC";
        List<Map<String, Object>> history = new ArrayList<>();

        try (Connection connection = getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, orderId);
            try (ResultSet rows = statement.executeQuery()) {
                while (rows.next()) {
                    Map<String, Object> entry = new LinkedHashMap<>();
                    entry.put("status", rows.getString("status"));
                    entry.put("oldStatus", rows.getString("old_status"));
                    entry.put("reason", rows.getString("reason"));
                    entry.put("actor", rows.getString("actor_type"));
                    entry.put("changedBy", rows.getObject("changed_by"));
                    entry.put("updatedAt", rows.getTimestamp("updated_at"));
                    history.add(entry);
                }
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Không tải được lịch sử đơn hàng.", e);
        }

        return history;
    }
}
