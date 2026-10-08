package service;

import dao.OrderDAO;
import db.DBContext;
import model.Order;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class OrderService {

    private final OrderDAO orderDAO = new OrderDAO();

    // DU LIEU SAN PHAM TRONG GIO HANG
    private static final class CartLine {

        final int skuId;
        final int quantity;
        final BigDecimal price;

        CartLine(int skuId, int quantity, BigDecimal price) {
            this.skuId = skuId;
            this.quantity = quantity;
            this.price = price;
        }
    }

    // KET QUA KIEM TRA VOUCHER
    private static final class VoucherResult {

        final Integer id;
        final BigDecimal discount;

        VoucherResult(Integer id, BigDecimal discount) {
            this.id = id;
            this.discount = discount;
        }
    }

    // GIU CHU KY HAM CU TRONG LUC CAP NHAT TUNG FILE
    // SERVLET SE DUOC DOI SANG HAM CO TOKEN O BUOC TIEP THEO
    @Deprecated
    public int placeCodOrder(
            int userId,
            int addressId,
            String name,
            String phone,
            String address,
            BigDecimal shippingFee
    ) throws SQLException {

        throw new IllegalArgumentException(
                "Cần cập nhật CheckoutServlet sang luồng đặt hàng mới."
        );
    }

    @Deprecated
    public int placeCodOrder(
            int userId,
            int addressId,
            String name,
            String phone,
            String address,
            BigDecimal shippingFee,
            BigDecimal discountAmount
    ) throws SQLException {

        throw new IllegalArgumentException(
                "Cần cập nhật CheckoutServlet sang luồng đặt hàng mới."
        );
    }

    // DAT HANG COD CO TOKEN VA VOUCHER
    public int placeCodOrder(
            int userId,
            int addressId,
            String checkoutToken,
            String voucherCode
    ) throws SQLException {

        if (userId <= 0
                || addressId <= 0
                || checkoutToken == null
                || !checkoutToken.matches("[0-9a-fA-F-]{36}")) {

            throw new IllegalArgumentException(
                    "Yêu cầu đặt hàng không hợp lệ. "
                    + "Vui lòng tải lại Checkout."
            );
        }

        try (Connection conn = new DBContext().getConnection()) {

            if (conn == null) {
                throw new SQLException(
                        "Khong ket noi duoc database."
                );
            }

            conn.setAutoCommit(false);

            try {
                // 1. KHOA GIO HANG CUA USER
                int cartId;

                String sql = "SELECT cart_id "
                        + "FROM dbo.CART WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE user_id = ?";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
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

                // 2. TOKEN DA TAO DON THI TRA VE DON CU
                Integer existingOrderId = orderDAO.findIdByToken(
                        conn,
                        userId,
                        checkoutToken
                );

                if (existingOrderId != null) {
                    conn.commit();
                    return existingOrderId;
                }

                // 3. KIEM TRA DIA CHI VA LUU THONG TIN NGUOI NHAN
                Order order = new Order();
                order.setUserId(userId);
                order.setAddressId(addressId);

                sql = "SELECT recipient_name, phone_number, address_line "
                        + "FROM dbo.ADDRESSBOOK WITH (HOLDLOCK) "
                        + "WHERE address_id = ? "
                        + "AND user_id = ? "
                        + "AND is_deleted = 0";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, addressId);
                    ps.setInt(2, userId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException(
                                    "Địa chỉ không tồn tại hoặc đã bị xóa."
                            );
                        }

                        order.setRecipientName(
                                rs.getString("recipient_name")
                        );

                        order.setRecipientPhone(
                                rs.getString("phone_number")
                        );

                        order.setShippingAddress(
                                rs.getString("address_line")
                        );
                    }
                }

                // 4. DOC SAN PHAM VA GIA TU DATABASE
                List<CartLine> lines = new ArrayList<>();
                BigDecimal subtotal = BigDecimal.ZERO;

                sql = "SELECT ci.sku_id, ci.quantity, s.price "
                        + "FROM dbo.CART_ITEMS ci WITH (UPDLOCK, HOLDLOCK) "
                        + "JOIN dbo.PRODUCT_SKU s WITH (UPDLOCK, HOLDLOCK) "
                        + "ON s.sku_id = ci.sku_id "
                        + "WHERE ci.cart_id = ? "
                        + "ORDER BY ci.sku_id, ci.cart_item_id";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, cartId);

                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
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
                                    new CartLine(skuId, quantity, price)
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

                // 5. KIEM TRA VOUCHER TRONG CUNG TRANSACTION
                VoucherResult voucher = lockAndCalculateVoucher(
                        conn,
                        userId,
                        voucherCode,
                        subtotal
                );

                // PHI SHIP TAM GIU 0 THEO CHECKOUT HIEN TAI
                BigDecimal shippingFee = BigDecimal.ZERO;

                BigDecimal totalAmount = subtotal
                        .add(shippingFee)
                        .subtract(voucher.discount);

                // 6. TRU TON KHO AN TOAN
                sql = "UPDATE dbo.PRODUCT_SKU "
                        + "SET stock_quantity = stock_quantity - ? "
                        + "WHERE sku_id = ? "
                        + "AND stock_quantity >= ?";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    for (CartLine line : lines) {
                        ps.setInt(1, line.quantity);
                        ps.setInt(2, line.skuId);
                        ps.setInt(3, line.quantity);

                        if (ps.executeUpdate() != 1) {
                            throw new IllegalArgumentException(
                                    "Sản phẩm SKU " + line.skuId
                                    + " không đủ số lượng tồn kho."
                            );
                        }
                    }
                }

                // 7. TAO DON HANG
                order.setShippingFee(shippingFee);
                order.setDiscountAmount(voucher.discount);
                order.setTotalAmount(totalAmount);

                order.setOrderStatus("PENDING_CONFIRMATION");
                order.setPaymentMethod("COD");

                order.setPaymentStatus(
                        totalAmount.signum() == 0
                        ? "PAID"
                        : "UNPAID"
                );

                int orderId = orderDAO.insert(
                        conn,
                        order,
                        checkoutToken
                );

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

                // 10. GHI NHAN LUOT SU DUNG VOUCHER
                if (voucher.id != null) {
                    sql = "INSERT INTO dbo.VOUCHER_USAGES "
                            + "(voucher_id, order_id, user_id) "
                            + "VALUES (?, ?, ?)";

                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setInt(1, voucher.id);
                        ps.setInt(2, orderId);
                        ps.setInt(3, userId);

                        if (ps.executeUpdate() != 1) {
                            throw new SQLException(
                                    "Khong luu duoc luot su dung voucher."
                            );
                        }
                    }
                }

                // 11. XOA SAN PHAM DA DAT KHOI GIO HANG
                sql = "DELETE FROM dbo.CART_ITEMS WHERE cart_id = ?";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, cartId);
                    ps.executeUpdate();
                }

                // 12. TAT CA THANH CONG MOI COMMIT
                conn.commit();

                return orderId;

            } catch (SQLException | RuntimeException e) {

                // LOI O BAT KY BUOC NAO THI HOAN TAC
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;
            }
        }
    }

    // KHOA VOUCHER, KIEM TRA DIEU KIEN VA TINH GIAM GIA
    private VoucherResult lockAndCalculateVoucher(
            Connection conn,
            int userId,
            String voucherCode,
            BigDecimal subtotal
    ) throws SQLException {

        // KHONG SU DUNG VOUCHER
        if (voucherCode == null || voucherCode.trim().isEmpty()) {
            return new VoucherResult(null, BigDecimal.ZERO);
        }

        String sql = "SELECT voucher_id, discount_type, discount_value, "
                + "max_discount, usage_limit, per_user_limit "
                + "FROM dbo.VOUCHER WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE code = ? "
                + "AND GETDATE() BETWEEN valid_from AND valid_to "
                + "AND min_order_value <= ?";

        int voucherId;
        String discountType;
        BigDecimal discountValue;
        BigDecimal maxDiscount;
        Integer usageLimit;
        Integer perUserLimit;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, voucherCode.trim());
            ps.setBigDecimal(2, subtotal);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException(
                            "Voucher hết hạn hoặc đơn hàng "
                            + "chưa đủ điều kiện áp dụng."
                    );
                }

                voucherId = rs.getInt("voucher_id");
                discountType = rs.getString("discount_type");
                discountValue = rs.getBigDecimal("discount_value");
                maxDiscount = rs.getBigDecimal("max_discount");

                usageLimit
                        = (Integer) rs.getObject("usage_limit");

                perUserLimit
                        = (Integer) rs.getObject("per_user_limit");
            }
        }

        // DEM LUOT SU DUNG SAU KHI DA KHOA VOUCHER
        sql = "SELECT COUNT_BIG(*) AS total_used, "
                + "COALESCE(SUM(CASE WHEN user_id = ? "
                + "THEN CAST(1 AS bigint) ELSE 0 END), 0) AS user_used "
                + "FROM dbo.VOUCHER_USAGES "
                + "WHERE voucher_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, voucherId);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();

                long totalUsed = rs.getLong("total_used");
                long userUsed = rs.getLong("user_used");

                if (usageLimit != null && totalUsed >= usageLimit) {
                    throw new IllegalArgumentException(
                            "Voucher đã hết lượt sử dụng."
                    );
                }

                if (perUserLimit != null && userUsed >= perUserLimit) {
                    throw new IllegalArgumentException(
                            "Bạn đã dùng hết lượt của voucher này."
                    );
                }
            }
        }

        // TINH SO TIEN GIAM
        BigDecimal discount;

        if ("AMOUNT".equalsIgnoreCase(discountType)) {
            discount = discountValue;

        } else if ("PERCENT".equalsIgnoreCase(discountType)) {
            discount = subtotal.multiply(discountValue).divide(
                    BigDecimal.valueOf(100),
                    2,
                    RoundingMode.HALF_UP
            );

            if (maxDiscount != null) {
                discount = discount.min(maxDiscount);
            }

        } else {
            throw new IllegalArgumentException(
                    "Loại voucher không được hỗ trợ."
            );
        }

        // GIAM GIA KHONG AM VA KHONG VUOT TIEN HANG
        discount = discount
                .max(BigDecimal.ZERO)
                .min(subtotal)
                .setScale(2, RoundingMode.HALF_UP);

        return new VoucherResult(voucherId, discount);
    }
}
