
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

public class OrderService {

    private final OrderDAO orderDAO = new OrderDAO();

    // LUU THONG TIN SAN PHAM TRONG GIO HANG
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

    // GIU LAI HAM CU DE KHONG ANH HUONG CODE KHAC
    public int placeCodOrder(
            int userId,
            int addressId,
            String name,
            String phone,
            String address,
            BigDecimal shippingFee
    ) throws SQLException {

        return placeCodOrder(
                userId,
                addressId,
                name,
                phone,
                address,
                shippingFee,
                BigDecimal.ZERO
        );
    }

    // DAT HANG COD CO HO TRO GIAM GIA
    public int placeCodOrder(
            int userId,
            int addressId,
            String name,
            String phone,
            String address,
            BigDecimal shippingFee,
            BigDecimal discountAmount
    ) throws SQLException {

        // KIEM TRA THONG TIN DAU VAO
        if (userId <= 0 || addressId <= 0) {
            throw new IllegalArgumentException(
                    "Thông tin tài khoản hoặc địa chỉ không hợp lệ."
            );
        }

        if (isBlank(name) || isBlank(phone) || isBlank(address)) {
            throw new IllegalArgumentException(
                    "Vui lòng nhập đầy đủ thông tin người nhận."
            );
        }

        if (name.trim().length() > 100
                || !phone.trim().matches("[0-9]{9,11}")) {
            throw new IllegalArgumentException(
                    "Tên hoặc số điện thoại không hợp lệ."
            );
        }

        if (shippingFee == null || shippingFee.signum() < 0) {
            throw new IllegalArgumentException(
                    "Phí vận chuyển không hợp lệ."
            );
        }

        if (discountAmount == null || discountAmount.signum() < 0) {
            throw new IllegalArgumentException(
                    "Số tiền giảm giá không hợp lệ."
            );
        }

        Connection conn = new DBContext().getConnection();

        if (conn == null) {
            throw new SQLException("Không thể kết nối database.");
        }

        try (Connection closeMe = conn) {

            conn.setAutoCommit(false);

            try {

                // 1. KHOA GIO HANG DE TRANH XU LY DONG THOI
                int cartId;

                String cartSql =
                        "SELECT cart_id "
                        + "FROM dbo.CART WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE user_id = ?";

                try (PreparedStatement ps =
                        conn.prepareStatement(cartSql)) {

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

                // 2. KIEM TRA DIA CHI THUOC USER VA CHUA BI XOA
                // QUAN TRONG: THEM is_deleted = 0
                String addressSql =
                        "SELECT recipient_name, phone_number, address_line "
                        + "FROM dbo.ADDRESSBOOK "
                        + "WHERE address_id = ? "
                        + "AND user_id = ? "
                        + "AND is_deleted = 0";

                String recipientName;
                String recipientPhone;
                String shippingAddress;

                try (PreparedStatement ps =
                        conn.prepareStatement(addressSql)) {

                    ps.setInt(1, addressId);
                    ps.setInt(2, userId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {
                            throw new IllegalArgumentException(
                                    "Địa chỉ không tồn tại hoặc đã bị xóa."
                            );
                        }

                        recipientName = rs.getString("recipient_name");
                        recipientPhone = rs.getString("phone_number");
                        shippingAddress = rs.getString("address_line");
                    }
                }

                // 3. LAY SAN PHAM VA GIA HIEN TAI
                List<CartLine> lines = new ArrayList<>();
                BigDecimal subtotal = BigDecimal.ZERO;

                String itemsSql =
                        "SELECT ci.cart_item_id, "
                        + "ci.sku_id, "
                        + "ci.quantity, "
                        + "s.price "
                        + "FROM dbo.CART_ITEMS ci WITH (UPDLOCK, HOLDLOCK) "
                        + "JOIN dbo.PRODUCT_SKU s "
                        + "ON s.sku_id = ci.sku_id "
                        + "WHERE ci.cart_id = ? "
                        + "ORDER BY ci.cart_item_id";

                try (PreparedStatement ps =
                        conn.prepareStatement(itemsSql)) {

                    ps.setInt(1, cartId);

                    try (ResultSet rs = ps.executeQuery()) {

                        while (rs.next()) {

                            int itemId = rs.getInt("cart_item_id");
                            int skuId = rs.getInt("sku_id");
                            int quantity = rs.getInt("quantity");
                            BigDecimal price = rs.getBigDecimal("price");

                            if (quantity <= 0
                                    || price == null
                                    || price.signum() < 0) {

                                throw new IllegalArgumentException(
                                        "Sản phẩm trong giỏ hàng không hợp lệ."
                                );
                            }

                            lines.add(
                                    new CartLine(
                                            itemId,
                                            skuId,
                                            quantity,
                                            price
                                    )
                            );

                            BigDecimal lineTotal = price.multiply(
                                    BigDecimal.valueOf(quantity)
                            );

                            subtotal = subtotal.add(lineTotal);
                        }
                    }
                }

                if (lines.isEmpty()) {
                    throw new IllegalArgumentException(
                            "Giỏ hàng đang trống."
                    );
                }

                // 4. KIEM TRA SO TIEN GIAM GIA
                if (discountAmount.compareTo(subtotal) > 0) {
                    throw new IllegalArgumentException(
                            "Số tiền giảm giá vượt quá giá trị đơn hàng."
                    );
                }

                // 5. TINH TONG TIEN DON HANG
                BigDecimal totalAmount = subtotal
                        .add(shippingFee)
                        .subtract(discountAmount);

                if (totalAmount.signum() < 0) {
                    totalAmount = BigDecimal.ZERO;
                }

                // 6. TRU TON KHO AN TOAN
                for (CartLine line : lines) {

                    String stockSql =
                            "UPDATE dbo.PRODUCT_SKU "
                            + "SET stock_quantity = stock_quantity - ? "
                            + "WHERE sku_id = ? "
                            + "AND stock_quantity >= ?";

                    try (PreparedStatement ps =
                            conn.prepareStatement(stockSql)) {

                        ps.setInt(1, line.quantity);
                        ps.setInt(2, line.skuId);
                        ps.setInt(3, line.quantity);

                        int updatedRows = ps.executeUpdate();

                        if (updatedRows != 1) {
                            throw new IllegalArgumentException(
                                    "Sản phẩm SKU " + line.skuId
                                    + " không đủ số lượng tồn kho."
                            );
                        }
                    }
                }

                // 7. TAO DON HANG COD
                Order order = new Order();

                order.setUserId(userId);
                order.setAddressId(addressId);

                // LAY THONG TIN TRUC TIEP TU DATABASE
                // TRANH SU DUNG DIA CHI KHONG HOP LE
                order.setRecipientName(recipientName);
                order.setRecipientPhone(recipientPhone);
                order.setShippingAddress(shippingAddress);

                order.setShippingFee(shippingFee);
                order.setDiscountAmount(discountAmount);
                order.setTotalAmount(totalAmount);

                order.setOrderStatus("PENDING_CONFIRMATION");
                order.setPaymentMethod("COD");

                if (totalAmount.signum() == 0) {
                    order.setPaymentStatus("PAID");
                } else {
                    order.setPaymentStatus("UNPAID");
                }

                int orderId = orderDAO.insert(conn, order);

                if (orderId <= 0) {
                    throw new SQLException(
                            "Không thể tạo đơn hàng."
                    );
                }

                // 8. LUU CHI TIET DON HANG
                for (CartLine line : lines) {

                    orderDAO.insertItem(
                            conn,
                            orderId,
                            line.skuId,
                            line.price,
                            line.quantity
                    );
                }

                // 9. LUU LICH SU TRANG THAI
                orderDAO.addHistory(
                        conn,
                        orderId,
                        "PENDING_CONFIRMATION"
                );

                // 10. XOA SAN PHAM KHOI GIO HANG
                String deleteCartSql =
                        "DELETE FROM dbo.CART_ITEMS "
                        + "WHERE cart_id = ?";

                try (PreparedStatement ps =
                        conn.prepareStatement(deleteCartSql)) {

                    ps.setInt(1, cartId);
                    ps.executeUpdate();
                }

                // 11. COMMIT KHI TAT CA THANH CONG
                conn.commit();

                return orderId;

            } catch (SQLException | RuntimeException e) {

                // CO LOI THI HOAN TAC TOAN BO
                conn.rollback();
                throw e;

            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    // KIEM TRA CHUOI RONG
    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
