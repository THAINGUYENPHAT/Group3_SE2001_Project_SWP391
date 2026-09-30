package service;

import dao.OrderDAO;
import db.DBContext;
import model.Order;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import model.OrderItem;

public class OrderService {

    private final OrderDAO orderDAO = new OrderDAO();

    // Class phụ dùng để lưu item trong Cart
    private static final class CartLine {

        final int id;
        final int skuId;
        final int quantity;
        final BigDecimal price;

        CartLine(int id, int skuId, int quantity, BigDecimal price) {
            this.id = id;
            this.skuId = skuId;
            this.quantity = quantity;
            this.price = price;
        }
    }

    // ================================
    // ĐẶT HÀNG COD
    // ================================
    public int placeCodOrder(
            int userId,
            int addressId,
            String name,
            String phone,
            String address,
            BigDecimal shippingFee,
            BigDecimal discountAmount
    ) throws SQLException {

        // 1. Validate dữ liệu
        if (userId <= 0 || addressId <= 0) {
            throw new IllegalArgumentException(
                    "User hoặc địa chỉ không hợp lệ."
            );
        }

        if (isBlank(name) || isBlank(phone) || isBlank(address)) {
            throw new IllegalArgumentException(
                    "Vui lòng nhập đầy đủ thông tin người nhận."
            );
        }

        if (name.length() > 100 || phone.length() > 20) {
            throw new IllegalArgumentException(
                    "Thông tin người nhận quá dài."
            );
        }

        if (shippingFee == null || shippingFee.signum() < 0) {
            throw new IllegalArgumentException(
                    "Phí vận chuyển không hợp lệ."
            );
        }

        if (discountAmount == null || discountAmount.signum() < 0) {
            discountAmount = BigDecimal.ZERO;
        }

        // 2. Kết nối Database
        Connection conn = new DBContext().getConnection();

        if (conn == null) {
            throw new SQLException(
                    "Không thể kết nối Database."
            );
        }

        try (Connection connection = conn) {

            connection.setAutoCommit(false);

            try {

                // ================================
                // 3. Lấy Cart và lock Cart
                // ================================
                int cartId;

                String cartSql
                        = "SELECT cart_id "
                        + "FROM dbo.CART "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE user_id = ?";

                try (PreparedStatement ps
                        = connection.prepareStatement(cartSql)) {

                    ps.setInt(1, userId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {
                            throw new IllegalArgumentException(
                                    "Giỏ hàng không tồn tại."
                            );
                        }

                        cartId = rs.getInt("cart_id");
                    }
                }

                // ================================
                // 4. Kiểm tra địa chỉ
                // ================================
                String addressSql
                        = "SELECT address_id "
                        + "FROM dbo.ADDRESSBOOK "
                        + "WHERE address_id = ? "
                        + "AND user_id = ?";

                try (PreparedStatement ps
                        = connection.prepareStatement(addressSql)) {

                    ps.setInt(1, addressId);
                    ps.setInt(2, userId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {
                            throw new IllegalArgumentException(
                                    "Địa chỉ không thuộc tài khoản này."
                            );
                        }
                    }
                }

                // ================================
                // 5. Lấy sản phẩm trong Cart
                // ================================
                List<CartLine> lines = new ArrayList<>();
                BigDecimal subtotal = BigDecimal.ZERO;

                String itemSql
                        = "SELECT "
                        + "ci.cart_item_id, "
                        + "ci.sku_id, "
                        + "ci.quantity, "
                        + "s.price "
                        + "FROM dbo.CART_ITEMS ci "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "JOIN dbo.PRODUCT_SKU s "
                        + "ON s.sku_id = ci.sku_id "
                        + "WHERE ci.cart_id = ? "
                        + "ORDER BY ci.cart_item_id";

                try (PreparedStatement ps
                        = connection.prepareStatement(itemSql)) {

                    ps.setInt(1, cartId);

                    try (ResultSet rs = ps.executeQuery()) {

                        while (rs.next()) {

                            int quantity = rs.getInt("quantity");
                            BigDecimal price
                                    = rs.getBigDecimal("price");

                            if (quantity <= 0
                                    || price == null
                                    || price.signum() < 0) {

                                throw new IllegalArgumentException(
                                        "Sản phẩm trong giỏ không hợp lệ."
                                );
                            }

                            CartLine line = new CartLine(
                                    rs.getInt("cart_item_id"),
                                    rs.getInt("sku_id"),
                                    quantity,
                                    price
                            );

                            lines.add(line);

                            subtotal = subtotal.add(
                                    price.multiply(
                                            BigDecimal.valueOf(quantity)
                                    )
                            );
                        }
                    }
                }

                // ================================
                // 6. Kiểm tra Cart rỗng
                // ================================
                if (lines.isEmpty()) {
                    throw new IllegalArgumentException(
                            "Giỏ hàng đang trống."
                    );
                }

                // ================================
                // 7. Kiểm tra discount
                // ================================
                if (discountAmount.compareTo(subtotal) > 0) {
                    discountAmount = subtotal;
                }

                // ================================
                // 8. Trừ tồn kho
                // ================================
                for (CartLine line : lines) {

                    String stockSql
                            = "UPDATE dbo.PRODUCT_SKU "
                            + "SET stock_quantity = stock_quantity - ? "
                            + "WHERE sku_id = ? "
                            + "AND stock_quantity >= ?";

                    try (PreparedStatement ps
                            = connection.prepareStatement(stockSql)) {

                        ps.setInt(1, line.quantity);
                        ps.setInt(2, line.skuId);
                        ps.setInt(3, line.quantity);

                        int updated = ps.executeUpdate();

                        if (updated != 1) {
                            throw new IllegalArgumentException(
                                    "Sản phẩm SKU "
                                    + line.skuId
                                    + " không đủ tồn kho."
                            );
                        }
                    }
                }

                // ================================
                // 9. Tính tổng tiền
                // ================================
                BigDecimal totalAmount
                        = subtotal
                                .add(shippingFee)
                                .subtract(discountAmount);

                if (totalAmount.signum() < 0) {
                    totalAmount = BigDecimal.ZERO;
                }

                // ================================
                // 10. Tạo Order
                // ================================
                Order order = new Order();

                order.setUserId(userId);
                order.setAddressId(addressId);

                order.setRecipientName(name.trim());
                order.setRecipientPhone(phone.trim());
                order.setShippingAddress(address.trim());

                order.setShippingFee(shippingFee);
                order.setDiscountAmount(discountAmount);
                order.setTotalAmount(totalAmount);

                order.setOrderStatus("PENDING_CONFIRMATION");

                if (totalAmount.signum() == 0) {
                    order.setPaymentStatus("PAID");
                    order.setPaymentMethod("FREE");
                } else {
                    order.setPaymentStatus("UNPAID");
                    order.setPaymentMethod("COD");
                }

                // ================================
                // 11. Insert Order
                // ================================
                int orderId
                        = orderDAO.insert(connection, order);

                // ================================
                // 12. Insert Order Item
                // ================================
                for (CartLine line : lines) {
                    orderDAO.insertItem(
                            connection,
                            orderId,
                            line.skuId,
                            line.price,
                            line.quantity
                    );
                }

                // ================================
                // 13. Lưu lịch sử trạng thái
                // ================================
                orderDAO.addHistory(
                        connection,
                        orderId,
                        "PENDING_CONFIRMATION"
                );

                // ================================
                // 14. Xóa Cart Item
                // ================================
                String deleteCartSql
                        = "DELETE FROM dbo.CART_ITEMS "
                        + "WHERE cart_id = ?";

                try (PreparedStatement ps
                        = connection.prepareStatement(deleteCartSql)) {

                    ps.setInt(1, cartId);
                    ps.executeUpdate();
                }

                // ================================
                // 15. Commit
                // ================================
                connection.commit();

                return orderId;

            } catch (SQLException | RuntimeException ex) {

                connection.rollback();
                throw ex;

            } finally {

                connection.setAutoCommit(true);
            }
        }
    }
// ================================
// HUY DON HANG VA HOAN TON KHO
// ================================
public void cancelOrder(
        int orderId,
        int userId
) throws SQLException {

    if (orderId <= 0 || userId <= 0) {
        throw new IllegalArgumentException(
                "Don hang khong hop le."
        );
    }

    Connection conn =
            new DBContext().getConnection();

    if (conn == null) {
        throw new SQLException(
                "Khong the ket noi Database."
        );
    }

    try (Connection connection = conn) {

        connection.setAutoCommit(false);

        try {

            // ================================
            // 1. LAY VA LOCK ORDER
            // ================================
            Order order =
                    orderDAO.findForCancel(
                            connection,
                            orderId,
                            userId
                    );

            if (order == null) {
                throw new IllegalArgumentException(
                        "Khong tim thay don hang."
                );
            }

            // ================================
            // 2. KIEM TRA CO DUOC HUY KHONG
            // ================================
            if (!"PENDING_CONFIRMATION".equals(
                    order.getOrderStatus()
            )) {

                throw new IllegalArgumentException(
                        "Don hang khong con duoc phep huy."
                );
            }

            // ================================
            // 3. LAY SAN PHAM TRONG ORDER
            // ================================
            List<OrderItem> items =
                    orderDAO.findItemsByOrder(
                            connection,
                            orderId
                    );

            // ================================
            // 4. HOAN TON KHO
            // ================================
            String stockSql =
                    "UPDATE dbo.PRODUCT_SKU "
                    + "SET stock_quantity = stock_quantity + ? "
                    + "WHERE sku_id = ?";

            try (PreparedStatement p =
                         connection.prepareStatement(stockSql)) {

                for (OrderItem item : items) {

                    p.setInt(
                            1,
                            item.getQuantity()
                    );

                    p.setInt(
                            2,
                            item.getSkuId()
                    );

                    int updated =
                            p.executeUpdate();

                    if (updated != 1) {
                        throw new SQLException(
                                "Khong the hoan ton kho cho SKU "
                                + item.getSkuId()
                        );
                    }
                }
            }

            // ================================
            // 5. DOI TRANG THAI ORDER
            // ================================
            int updatedOrder =
                    orderDAO.updateStatus(
                            connection,
                            orderId,
                            "PENDING_CONFIRMATION",
                            "CANCELLED"
                    );

            if (updatedOrder != 1) {
                throw new IllegalStateException(
                        "Don hang da duoc xu ly truoc do."
                );
            }

            // ================================
            // 6. LUU HISTORY
            // ================================
            orderDAO.addHistory(
                    connection,
                    orderId,
                    "CANCELLED"
            );

            // ================================
            // 7. COMMIT
            // ================================
            connection.commit();

        } catch (SQLException | RuntimeException e) {

            connection.rollback();
            throw e;

        } finally {

            connection.setAutoCommit(true);
        }
    }
}
    // ================================
    // CHECK STRING RỖNG
    // ================================
    private static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}
