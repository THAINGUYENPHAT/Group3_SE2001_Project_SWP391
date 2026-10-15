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

    private final OrderDAO orderDAO =
            new OrderDAO();


    // =====================================================
    // CART LINE
    // =====================================================
    private static final class CartLine {

        final int cartItemId;

        final int skuId;

        final int quantity;

        final BigDecimal price;


        CartLine(
                int cartItemId,
                int skuId,
                int quantity,
                BigDecimal price
        ) {

            this.cartItemId =
                    cartItemId;

            this.skuId =
                    skuId;

            this.quantity =
                    quantity;

            this.price =
                    price;
        }
    }


    // =====================================================
    // VOUCHER RESULT
    // =====================================================
    private static final class VoucherResult {

        final Integer id;

        final BigDecimal discount;


        VoucherResult(
                Integer id,
                BigDecimal discount
        ) {

            this.id =
                    id;

            this.discount =
                    discount;
        }
    }


    // =====================================================
    // OLD METHOD
    // =====================================================
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
                "Cần cập nhật CheckoutServlet "
                + "sang luồng đặt hàng mới."
        );
    }


    // =====================================================
    // OLD METHOD WITH DISCOUNT
    // =====================================================
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
                "Cần cập nhật CheckoutServlet "
                + "sang luồng đặt hàng mới."
        );
    }


    // =====================================================
    // OLD SELECTED METHOD
    // =====================================================
    @Deprecated
    public int placeCodOrder(
            int userId,
            int addressId,
            String name,
            String phone,
            String address,
            BigDecimal shippingFee,
            BigDecimal discountAmount,
            List<Integer> selectedCartItemIds
    ) throws SQLException {

        throw new IllegalArgumentException(
                "Cần cập nhật CheckoutServlet "
                + "sang luồng Checkout Token + Voucher mới."
        );
    }


    // =====================================================
    // TOKEN + VOUCHER
    //
    // Giữ lại để code cũ vẫn compile.
    //
    // null = checkout toàn bộ Cart.
    // =====================================================
    public int placeCodOrder(
            int userId,
            int addressId,
            String checkoutToken,
            String voucherCode
    ) throws SQLException {

        return placeCodOrder(
                userId,
                addressId,
                checkoutToken,
                voucherCode,
                null
        );
    }


    // =====================================================
    // MAIN METHOD
    //
    // TOKEN + VOUCHER + SELECTED CART ITEMS
    // =====================================================
    public int placeCodOrder(
            int userId,
            int addressId,
            String checkoutToken,
            String voucherCode,
            List<Integer> selectedCartItemIds
    ) throws SQLException {

        // =================================================
        // VALIDATE
        // =================================================

        if (userId <= 0
                || addressId <= 0
                || checkoutToken == null
                || !checkoutToken.matches(
                        "[0-9a-fA-F-]{36}"
                )) {

            throw new IllegalArgumentException(
                    "Yêu cầu đặt hàng không hợp lệ. "
                    + "Vui lòng tải lại Checkout."
            );
        }


        /*
         * selectedCartItemIds == null
         * dùng cho method tương thích cũ:
         * checkout toàn bộ Cart.
         *
         * CheckoutServlet mới luôn truyền List.
         */
        boolean selectedMode =
                selectedCartItemIds != null;


        List<Integer> selectedIds =
                new ArrayList<>();


        if (selectedMode) {

            for (Integer id
                    : selectedCartItemIds) {

                if (id != null
                        && id > 0
                        && !selectedIds.contains(
                                id
                        )) {

                    selectedIds.add(
                            id
                    );
                }
            }


            if (selectedIds.isEmpty()) {

                throw new IllegalArgumentException(
                        "Vui lòng chọn sản phẩm "
                        + "để đặt hàng."
                );
            }
        }


        try (
            Connection conn =
                    new DBContext()
                            .getConnection()
        ) {

            if (conn == null) {

                throw new SQLException(
                        "Không kết nối được database."
                );
            }


            conn.setAutoCommit(
                    false
            );


            try {

                // =========================================
                // 1. LOCK CART
                // =========================================

                int cartId;


                String sql =
                        "SELECT cart_id "
                        + "FROM dbo.CART "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE user_id = ?";


                try (
                    PreparedStatement ps =
                            conn.prepareStatement(
                                    sql
                            )
                ) {

                    ps.setInt(
                            1,
                            userId
                    );


                    try (
                        ResultSet rs =
                                ps.executeQuery()
                    ) {

                        if (!rs.next()) {

                            throw new IllegalArgumentException(
                                    "Giỏ hàng không tồn tại."
                            );
                        }


                        cartId =
                                rs.getInt(
                                        "cart_id"
                                );
                    }
                }


                // =========================================
                // 2. IDEMPOTENCY TOKEN
                // =========================================

                Integer existingOrderId =
                        orderDAO.findIdByToken(
                                conn,
                                userId,
                                checkoutToken
                        );


                if (existingOrderId != null) {

                    conn.commit();

                    return existingOrderId;
                }


                // =========================================
                // 3. ADDRESS
                // =========================================

                Order order =
                        new Order();


                order.setUserId(
                        userId
                );


                order.setAddressId(
                        addressId
                );


                sql =
                        "SELECT "
                        + "recipient_name, "
                        + "phone_number, "
                        + "address_line "
                        + "FROM dbo.ADDRESSBOOK "
                        + "WITH (HOLDLOCK) "
                        + "WHERE address_id = ? "
                        + "AND user_id = ? "
                        + "AND is_deleted = 0";


                try (
                    PreparedStatement ps =
                            conn.prepareStatement(
                                    sql
                            )
                ) {

                    ps.setInt(
                            1,
                            addressId
                    );


                    ps.setInt(
                            2,
                            userId
                    );


                    try (
                        ResultSet rs =
                                ps.executeQuery()
                    ) {

                        if (!rs.next()) {

                            throw new IllegalArgumentException(
                                    "Địa chỉ không tồn tại "
                                    + "hoặc đã bị xóa."
                            );
                        }


                        order.setRecipientName(
                                rs.getString(
                                        "recipient_name"
                                )
                        );


                        order.setRecipientPhone(
                                rs.getString(
                                        "phone_number"
                                )
                        );


                        order.setShippingAddress(
                                rs.getString(
                                        "address_line"
                                )
                        );
                    }
                }


                // =========================================
                // 4. SELECT CART ITEMS
                // =========================================

                List<CartLine> lines =
                        new ArrayList<>();


                BigDecimal subtotal =
                        BigDecimal.ZERO;


                StringBuilder itemsSql =
                        new StringBuilder();


                itemsSql.append(
                        "SELECT "
                );


                itemsSql.append(
                        "ci.cart_item_id, "
                );


                itemsSql.append(
                        "ci.sku_id, "
                );


                itemsSql.append(
                        "ci.quantity, "
                );


                itemsSql.append(
                        "s.price "
                );


                itemsSql.append(
                        "FROM dbo.CART_ITEMS ci "
                );


                itemsSql.append(
                        "WITH (UPDLOCK, HOLDLOCK) "
                );


                itemsSql.append(
                        "JOIN dbo.PRODUCT_SKU s "
                );


                itemsSql.append(
                        "WITH (UPDLOCK, HOLDLOCK) "
                );


                itemsSql.append(
                        "ON s.sku_id = ci.sku_id "
                );


                itemsSql.append(
                        "WHERE ci.cart_id = ? "
                );


                /*
                 * Chỉ lấy những cart_item_id user đã tick.
                 */
                if (selectedMode) {

                    itemsSql.append(
                            "AND ci.cart_item_id IN ("
                    );


                    for (int i = 0;
                            i < selectedIds.size();
                            i++) {

                        if (i > 0) {

                            itemsSql.append(
                                    ","
                            );
                        }


                        itemsSql.append(
                                "?"
                        );
                    }


                    itemsSql.append(
                            ") "
                    );
                }


                itemsSql.append(
                        "ORDER BY ci.cart_item_id"
                );


                try (
                    PreparedStatement ps =
                            conn.prepareStatement(
                                    itemsSql.toString()
                            )
                ) {

                    int index =
                            1;


                    ps.setInt(
                            index++,
                            cartId
                    );


                    if (selectedMode) {

                        for (Integer id
                                : selectedIds) {

                            ps.setInt(
                                    index++,
                                    id
                            );
                        }
                    }


                    try (
                        ResultSet rs =
                                ps.executeQuery()
                    ) {

                        while (rs.next()) {

                            int cartItemId =
                                    rs.getInt(
                                            "cart_item_id"
                                    );


                            int skuId =
                                    rs.getInt(
                                            "sku_id"
                                    );


                            int quantity =
                                    rs.getInt(
                                            "quantity"
                                    );


                            BigDecimal price =
                                    rs.getBigDecimal(
                                            "price"
                                    );


                            if (quantity <= 0
                                    || price == null
                                    || price.signum() < 0) {

                                throw new IllegalArgumentException(
                                        "Sản phẩm trong giỏ hàng "
                                        + "không hợp lệ."
                                );
                            }


                            lines.add(
                                    new CartLine(
                                            cartItemId,
                                            skuId,
                                            quantity,
                                            price
                                    )
                            );


                            subtotal =
                                    subtotal.add(
                                            price.multiply(
                                                    BigDecimal.valueOf(
                                                            quantity
                                                    )
                                            )
                                    );
                        }
                    }
                }


                if (lines.isEmpty()) {

                    throw new IllegalArgumentException(
                            selectedMode
                            ? "Không tìm thấy sản phẩm đã chọn."
                            : "Giỏ hàng đang trống."
                    );
                }


                /*
                 * Có item bị xóa / không thuộc Cart user
                 * thì số record sẽ không khớp.
                 */
                if (selectedMode
                        && lines.size()
                        != selectedIds.size()) {

                    throw new IllegalArgumentException(
                            "Một số sản phẩm đã chọn "
                            + "không còn trong giỏ hàng."
                    );
                }


                // =========================================
                // 5. VOUCHER
                // =========================================

                VoucherResult voucher =
                        lockAndCalculateVoucher(
                                conn,
                                userId,
                                voucherCode,
                                subtotal
                        );


                // =========================================
                // 6. TOTAL
                // =========================================

                BigDecimal shippingFee =
                        BigDecimal.ZERO;


                BigDecimal totalAmount =
                        subtotal
                                .add(
                                        shippingFee
                                )
                                .subtract(
                                        voucher.discount
                                );


                if (totalAmount.signum() < 0) {

                    totalAmount =
                            BigDecimal.ZERO;
                }


                // =========================================
                // 7. STOCK
                // =========================================

                sql =
                        "UPDATE dbo.PRODUCT_SKU "
                        + "SET stock_quantity = "
                        + "stock_quantity - ? "
                        + "WHERE sku_id = ? "
                        + "AND stock_quantity >= ?";


                try (
                    PreparedStatement ps =
                            conn.prepareStatement(
                                    sql
                            )
                ) {

                    for (CartLine line
                            : lines) {

                        ps.setInt(
                                1,
                                line.quantity
                        );


                        ps.setInt(
                                2,
                                line.skuId
                        );


                        ps.setInt(
                                3,
                                line.quantity
                        );


                        if (ps.executeUpdate()
                                != 1) {

                            throw new IllegalArgumentException(
                                    "Sản phẩm SKU "
                                    + line.skuId
                                    + " không đủ số lượng tồn kho."
                            );
                        }
                    }
                }


                // =========================================
                // 8. CREATE ORDER
                // =========================================

                order.setShippingFee(
                        shippingFee
                );


                order.setDiscountAmount(
                        voucher.discount
                );


                order.setTotalAmount(
                        totalAmount
                );


                order.setOrderStatus(
                        "PENDING_CONFIRMATION"
                );


                order.setPaymentMethod(
                        "COD"
                );


                order.setPaymentStatus(
                        totalAmount.signum() == 0
                        ? "PAID"
                        : "UNPAID"
                );


                int orderId =
                        orderDAO.insert(
                                conn,
                                order,
                                checkoutToken
                        );


                if (orderId <= 0) {

                    throw new SQLException(
                            "Không thể tạo đơn hàng."
                    );
                }


                // =========================================
                // 9. ORDER ITEMS
                // =========================================

                for (CartLine line
                        : lines) {

                    orderDAO.insertItem(
                            conn,
                            orderId,
                            line.skuId,
                            line.price,
                            line.quantity
                    );
                }


                // =========================================
                // 10. ORDER HISTORY
                // =========================================

                orderDAO.addHistory(
                        conn,
                        orderId,
                        "PENDING_CONFIRMATION"
                );


                // =========================================
                // 11. SAVE VOUCHER USAGE
                // =========================================

                if (voucher.id != null) {

                    sql =
                            "INSERT INTO dbo.VOUCHER_USAGES "
                            + "(voucher_id, order_id, user_id) "
                            + "VALUES (?, ?, ?)";


                    try (
                        PreparedStatement ps =
                                conn.prepareStatement(
                                        sql
                                )
                    ) {

                        ps.setInt(
                                1,
                                voucher.id
                        );


                        ps.setInt(
                                2,
                                orderId
                        );


                        ps.setInt(
                                3,
                                userId
                        );


                        if (ps.executeUpdate()
                                != 1) {

                            throw new SQLException(
                                    "Không lưu được lượt "
                                    + "sử dụng Voucher."
                            );
                        }
                    }
                }


                // =========================================
                // 12. DELETE PURCHASED CART ITEMS
                // =========================================

                /*
                 * Không DELETE toàn bộ cart.
                 *
                 * Chỉ xóa những cart_item_id thực sự
                 * đã được đưa vào Order.
                 */
                sql =
                        "DELETE FROM dbo.CART_ITEMS "
                        + "WHERE cart_id = ? "
                        + "AND cart_item_id = ?";


                try (
                    PreparedStatement ps =
                            conn.prepareStatement(
                                    sql
                            )
                ) {

                    for (CartLine line
                            : lines) {

                        ps.setInt(
                                1,
                                cartId
                        );


                        ps.setInt(
                                2,
                                line.cartItemId
                        );


                        if (ps.executeUpdate()
                                != 1) {

                            throw new SQLException(
                                    "Không xóa được sản phẩm "
                                    + "đã đặt khỏi giỏ hàng."
                            );
                        }
                    }
                }


                // =========================================
                // 13. COMMIT
                // =========================================

                conn.commit();


                return orderId;


            } catch (SQLException
                    | RuntimeException e) {

                try {

                    conn.rollback();

                } catch (SQLException rollbackError) {

                    e.addSuppressed(
                            rollbackError
                    );
                }


                throw e;
            }
        }
    }


    // =====================================================
    // LOCK + VALIDATE + CALCULATE VOUCHER
    // =====================================================
    private VoucherResult lockAndCalculateVoucher(
            Connection conn,
            int userId,
            String voucherCode,
            BigDecimal subtotal
    ) throws SQLException {

        /*
         * User không chọn Voucher.
         */
        if (voucherCode == null
                || voucherCode.trim().isEmpty()) {

            return new VoucherResult(
                    null,
                    BigDecimal.ZERO
            );
        }


        String sql =
                "SELECT "
                + "voucher_id, "
                + "discount_type, "
                + "discount_value, "
                + "max_discount, "
                + "usage_limit, "
                + "per_user_limit "
                + "FROM dbo.VOUCHER "
                + "WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE UPPER(code) = UPPER(?) "
                + "AND GETDATE() "
                + "BETWEEN valid_from AND valid_to "
                + "AND min_order_value <= ?";


        int voucherId;

        String discountType;

        BigDecimal discountValue;

        BigDecimal maxDiscount;

        Integer usageLimit;

        Integer perUserLimit;


        try (
            PreparedStatement ps =
                    conn.prepareStatement(
                            sql
                    )
        ) {

            ps.setString(
                    1,
                    voucherCode.trim()
            );


            ps.setBigDecimal(
                    2,
                    subtotal
            );


            try (
                ResultSet rs =
                        ps.executeQuery()
            ) {

                if (!rs.next()) {

                    throw new IllegalArgumentException(
                            "Voucher hết hạn hoặc đơn hàng "
                            + "chưa đủ điều kiện áp dụng."
                    );
                }


                voucherId =
                        rs.getInt(
                                "voucher_id"
                        );


                discountType =
                        rs.getString(
                                "discount_type"
                        );


                discountValue =
                        rs.getBigDecimal(
                                "discount_value"
                        );


                maxDiscount =
                        rs.getBigDecimal(
                                "max_discount"
                        );


                Object usageValue =
                        rs.getObject(
                                "usage_limit"
                        );


                usageLimit =
                        usageValue == null
                        ? null
                        : ((Number) usageValue)
                                .intValue();


                Object perUserValue =
                        rs.getObject(
                                "per_user_limit"
                        );


                perUserLimit =
                        perUserValue == null
                        ? null
                        : ((Number) perUserValue)
                                .intValue();
            }
        }


        if (discountValue == null
                || discountValue.signum() <= 0) {

            throw new IllegalArgumentException(
                    "Voucher có giá trị giảm không hợp lệ."
            );
        }


        // =================================================
        // USAGE LIMITS
        // =================================================

        sql =
                "SELECT "
                + "COUNT_BIG(*) AS total_used, "
                + "COALESCE("
                + "SUM("
                + "CASE WHEN user_id = ? "
                + "THEN CAST(1 AS bigint) "
                + "ELSE 0 END"
                + "), 0"
                + ") AS user_used "
                + "FROM dbo.VOUCHER_USAGES "
                + "WHERE voucher_id = ?";


        try (
            PreparedStatement ps =
                    conn.prepareStatement(
                            sql
                    )
        ) {

            ps.setInt(
                    1,
                    userId
            );


            ps.setInt(
                    2,
                    voucherId
            );


            try (
                ResultSet rs =
                        ps.executeQuery()
            ) {

                rs.next();


                long totalUsed =
                        rs.getLong(
                                "total_used"
                        );


                long userUsed =
                        rs.getLong(
                                "user_used"
                        );


                if (usageLimit != null
                        && totalUsed
                        >= usageLimit) {

                    throw new IllegalArgumentException(
                            "Voucher đã hết lượt sử dụng."
                    );
                }


                if (perUserLimit != null
                        && userUsed
                        >= perUserLimit) {

                    throw new IllegalArgumentException(
                            "Bạn đã dùng hết lượt "
                            + "của Voucher này."
                    );
                }
            }
        }


        // =================================================
        // CALCULATE DISCOUNT
        // =================================================

        BigDecimal discount;


        if ("AMOUNT".equalsIgnoreCase(
                discountType
        )) {

            discount =
                    discountValue;


        } else if ("PERCENT".equalsIgnoreCase(
                discountType
        )) {

            discount =
                    subtotal.multiply(
                            discountValue
                    ).divide(
                            BigDecimal.valueOf(
                                    100
                            ),
                            2,
                            RoundingMode.HALF_UP
                    );


            if (maxDiscount != null) {

                discount =
                        discount.min(
                                maxDiscount
                        );
            }


        } else {

            throw new IllegalArgumentException(
                    "Loại Voucher không được hỗ trợ."
            );
        }


        /*
         * Discount:
         *
         * 0 <= discount <= subtotal
         */
        discount =
                discount
                        .max(
                                BigDecimal.ZERO
                        )
                        .min(
                                subtotal
                        )
                        .setScale(
                                2,
                                RoundingMode.HALF_UP
                        );


        return new VoucherResult(
                voucherId,
                discount
        );
    }
}