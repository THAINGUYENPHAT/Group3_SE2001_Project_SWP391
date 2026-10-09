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

        String sql
                = "SELECT o.order_id, "
                + "o.user_id, "
                + "o.address_id, "
                + "o.shipping_partner_id, "
                + "o.total_amount, "
                + "o.shipping_fee, "
                + "o.discount_amount, "
                + "o.order_status, "
                + "o.payment_method, "
                + "o.payment_status, "
                + "o.recipient_name, "
                + "o.recipient_phone, "
                + "o.shipping_address, "
                + "o.created_at, "
                + "o.payment_expires_at "
                + "FROM dbo.[ORDER] o "
                + "ORDER BY o.order_id ASC";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {

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

                order.setDiscountAmount(
                        rs.getBigDecimal("discount_amount")
                );

                // Trạng thái hiện tại lấy trực tiếp từ ORDER
                order.setOrderStatus(
                        rs.getString("order_status")
                );

                order.setPaymentMethod(
                        rs.getString("payment_method")
                );

                order.setPaymentStatus(
                        rs.getString("payment_status")
                );

                order.setRecipientName(
                        rs.getString("recipient_name")
                );

                order.setRecipientPhone(
                        rs.getString("recipient_phone")
                );

                order.setShippingAddress(
                        rs.getString("shipping_address")
                );

                order.setCreatedAt(
                        rs.getTimestamp("created_at")
                );

                order.setPaymentExpiresAt(
                        rs.getTimestamp("payment_expires_at")
                );

                list.add(order);
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy danh sách Order!",
                    ex
            );
        }

        return list;
    }

    // =========================================================
    // 2. LẤY CHI TIẾT ĐƠN HÀNG
    // =========================================================
    public Order getById(int id) {

        String sql
                = "SELECT o.order_id, "
                + "o.user_id, "
                + "o.address_id, "
                + "o.shipping_partner_id, "
                + "o.total_amount, "
                + "o.shipping_fee, "
                + "o.discount_amount, "
                + "o.order_status, "
                + "o.payment_method, "
                + "o.payment_status, "
                + "o.recipient_name, "
                + "o.recipient_phone, "
                + "o.shipping_address, "
                + "o.created_at, "
                + "o.payment_expires_at "
                + "FROM dbo.[ORDER] o "
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

                    order.setDiscountAmount(
                            rs.getBigDecimal("discount_amount")
                    );

                    order.setOrderStatus(
                            rs.getString("order_status")
                    );

                    order.setPaymentMethod(
                            rs.getString("payment_method")
                    );

                    order.setPaymentStatus(
                            rs.getString("payment_status")
                    );

                    order.setRecipientName(
                            rs.getString("recipient_name")
                    );

                    order.setRecipientPhone(
                            rs.getString("recipient_phone")
                    );

                    order.setShippingAddress(
                            rs.getString("shipping_address")
                    );

                    order.setCreatedAt(
                            rs.getTimestamp("created_at")
                    );

                    order.setPaymentExpiresAt(
                            rs.getTimestamp("payment_expires_at")
                    );

                    return order;
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy Order theo ID!",
                    ex
            );
        }

        return null;
    }

    // =========================================================
    // 3. LẤY CÁC SẢN PHẨM TRONG ĐƠN
    // =========================================================
    public List<OrderItem> getItemsByOrderId(int orderId) {

        List<OrderItem> list = new ArrayList<>();

        String sql
                = "SELECT order_item_id, "
                + "order_id, "
                + "sku_id, "
                + "price, "
                + "quantity "
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

    // =========================================================
    // 5. CẬP NHẬT TRẠNG THÁI
    // =========================================================
    public int updateStatus(int orderId, String status) {

        String updateOrderSql
                = "UPDATE dbo.[ORDER] "
                + "SET order_status = ? "
                + "WHERE order_id = ?";

        String insertHistorySql
                = "INSERT INTO ORDER_STATUS_HISTORY "
                + "(order_id, status) "
                + "VALUES (?, ?)";

        try (Connection conn = getConnection()) {

            // Đảm bảo update ORDER và insert HISTORY
            // thành công cùng nhau
            conn.setAutoCommit(false);

            try (PreparedStatement updateOrderStmt
                    = conn.prepareStatement(updateOrderSql); PreparedStatement insertHistoryStmt
                    = conn.prepareStatement(insertHistorySql)) {

                // -------------------------------------------------
                // BƯỚC 1: UPDATE trạng thái hiện tại trong ORDER
                // -------------------------------------------------
                updateOrderStmt.setString(
                        1,
                        status.toUpperCase()
                );

                updateOrderStmt.setInt(
                        2,
                        orderId
                );

                int updated
                        = updateOrderStmt.executeUpdate();

                if (updated == 0) {
                    conn.rollback();
                    return 0;
                }

                // -------------------------------------------------
                // BƯỚC 2: LƯU LỊCH SỬ
                // -------------------------------------------------
                insertHistoryStmt.setInt(
                        1,
                        orderId
                );

                // History giữ status dạng dễ đọc
                insertHistoryStmt.setString(
                        2,
                        status
                );

                insertHistoryStmt.executeUpdate();

                // -------------------------------------------------
                // BƯỚC 3: COMMIT
                // -------------------------------------------------
                conn.commit();

                return 1;

            } catch (SQLException ex) {

                conn.rollback();
                throw ex;
            }

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

        // Dùng chung logic updateStatus:
        // ORDER.order_status -> CANCELLED
        // ORDER_STATUS_HISTORY -> Cancelled
        return updateStatus(
                orderId,
                "Cancelled"
        );
    }
}
