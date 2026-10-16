package service;

import dao.OrderDAO;
import db.DBContext;
import db.CheckoutConnectionFactory;
import model.Order;

import java.math.BigDecimal;
import java.math.RoundingMode;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Arrays;
import java.util.Collections;

public class OrderService {

    private final OrderDAO orderDAO;
    private final CheckoutConnectionFactory connections;

    public OrderService() {
        this(() -> new DBContext().getConnection());
    }

    public OrderService(CheckoutConnectionFactory connections) {
        this.connections = connections;
        this.orderDAO = new OrderDAO(connections);
    }


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


        try (Connection conn = connections.open()) {

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

    /** Returns false for an already cancelled order. Stock and history change exactly once. */
    public boolean cancelOrderByCustomer(int userId, int orderId) throws SQLException {
        if (userId <= 0 || orderId <= 0) throw new IllegalArgumentException("Mã đơn hàng không hợp lệ.");
        try (Connection conn = connections.open()) {
            if (conn == null) throw new SQLException("Khong ket noi duoc database.");
            conn.setAutoCommit(false);
            try {
                String sql = "SELECT order_status, payment_method, payment_status, total_amount, stock_restored_at "
                        + "FROM dbo.[ORDER] WITH (UPDLOCK, HOLDLOCK) WHERE order_id = ? AND user_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, orderId);
                    ps.setInt(2, userId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
                        String status = normalizeStatus(rs.getString("order_status"));
                        if ("CANCELLED".equals(status)) {
                            conn.commit();
                            return false;
                        }
                        if (!"PENDING_CONFIRMATION".equals(status)) {
                            throw new IllegalArgumentException("Chỉ được hủy đơn trước khi nhân viên xác nhận.");
                        }
                        if (!"COD".equalsIgnoreCase(rs.getString("payment_method"))
                                || ("PAID".equalsIgnoreCase(rs.getString("payment_status"))
                                && rs.getBigDecimal("total_amount").signum() > 0)) {
                            throw new IllegalArgumentException("Đơn này cần được hỗ trợ xử lý thanh toán trước khi hủy.");
                        }
                        if (rs.getTimestamp("stock_restored_at") != null) {
                            throw new IllegalArgumentException("Đơn đã được hoàn kho. Vui lòng liên hệ hỗ trợ.");
                        }
                    }
                }

                // Aggregate duplicate SKU lines and lock stock in a stable order.
                List<int[]> quantities = new ArrayList<>();
                sql = "SELECT sku_id, SUM(quantity) AS quantity FROM dbo.ORDER_ITEM "
                        + "WHERE order_id = ? GROUP BY sku_id ORDER BY sku_id";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            int quantity = rs.getInt("quantity");
                            if (quantity <= 0) throw new SQLException("So luong don hang khong hop le.");
                            quantities.add(new int[]{rs.getInt("sku_id"), quantity});
                        }
                    }
                }
                if (quantities.isEmpty()) throw new SQLException("Don hang khong co chi tiet de hoan kho.");
                sql = "UPDATE dbo.PRODUCT_SKU SET stock_quantity = stock_quantity + ? WHERE sku_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    for (int[] item : quantities) {
                        ps.setInt(1, item[1]);
                        ps.setInt(2, item[0]);
                        if (ps.executeUpdate() != 1) throw new SQLException("Khong hoan duoc ton kho.");
                    }
                }
                sql = "UPDATE dbo.[ORDER] SET order_status = 'CANCELLED', stock_restored_at = GETDATE() "
                        + "WHERE order_id = ? AND user_id = ? AND stock_restored_at IS NULL "
                        + "AND UPPER(order_status) IN ('PENDING_CONFIRMATION', 'PENDING')";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, orderId);
                    ps.setInt(2, userId);
                    if (ps.executeUpdate() != 1) throw new SQLException("Trang thai don hang da thay doi.");
                }
                orderDAO.addHistory(conn, orderId, "CANCELLED");
                conn.commit();
                return true;
            } catch (SQLException | RuntimeException ex) {
                try { conn.rollback(); } catch (SQLException rollback) { ex.addSuppressed(rollback); }
                throw ex;
            }
        }
    }

    public List<Map<String, Object>> findHistory(int orderId, int userId) throws SQLException {
        List<Map<String, Object>> history = orderDAO.findHistory(orderId, userId);
        for (Map<String, Object> entry : history) {
            entry.put("label", statusLabel((String) entry.get("status")));
        }
        return history;
    }

    // Supports both checkout and staff history status formats.
    public static String normalizeStatus(String status) {
        if (status == null) return "";
        String value = status.trim().toUpperCase(Locale.ROOT).replace(' ', '_');
        return "PENDING".equals(value) ? "PENDING_CONFIRMATION" : value;
    }

    public static Map<String, String> statusLabels() {
        Map<String, String> labels = new LinkedHashMap<>();
        labels.put("PENDING_CONFIRMATION", "Chờ xác nhận");
        labels.put("CONFIRMED", "Đã xác nhận");
        labels.put("PACKING", "Đang đóng gói");
        labels.put("SHIPPING", "Đang giao hàng");
        labels.put("DELIVERED", "Đã giao hàng");
        labels.put("COMPLETED", "Hoàn tất");
        labels.put("CANCELLED", "Đã hủy");
        return labels;
    }

    public static String statusLabel(String status) {
        return statusLabels().getOrDefault(normalizeStatus(status), status);
    }

    public static Map<String, String> purchaseTabs() {
        Map<String, String> tabs = new LinkedHashMap<>();
        tabs.put("ALL", "Tất cả");
        tabs.put("PENDING", "Chờ xác nhận");
        tabs.put("PREPARING", "Chờ lấy hàng");
        tabs.put("SHIPPING", "Đang giao");
        tabs.put("COMPLETED", "Hoàn thành");
        tabs.put("CANCELLED", "Đã hủy");
        return tabs;
    }

    public static List<String> statusesForTab(String tab) {
        switch (tab) {
            case "PENDING": return Arrays.asList("PENDING", "PENDING_CONFIRMATION");
            case "PREPARING": return Arrays.asList("CONFIRMED", "PACKING");
            case "SHIPPING": return Collections.singletonList("SHIPPING");
            case "COMPLETED": return Arrays.asList("DELIVERED", "COMPLETED");
            case "CANCELLED": return Collections.singletonList("CANCELLED");
            default: return Collections.emptyList();
        }
    }

    public static Map<String, Long> purchaseTabCounts(Map<String, Long> statuses) {
        Map<String, Long> counts = new LinkedHashMap<>();
        for (String tab : purchaseTabs().keySet()) counts.put(tab, 0L);
        for (Map.Entry<String, Long> entry : statuses.entrySet()) {
            counts.put("ALL", counts.get("ALL") + entry.getValue());
            for (String tab : purchaseTabs().keySet()) {
                if (statusesForTab(tab).contains(normalizeStatus(entry.getKey()))) {
                    counts.put(tab, counts.get(tab) + entry.getValue());
                }
            }
        }
        return counts;
    }

    public static List<Map<String, Object>> trackingSteps(Order order, List<Map<String, Object>> history) {
        List<String> states = Arrays.asList("PENDING_CONFIRMATION", "CONFIRMED", "PACKING", "SHIPPING", "COMPLETED");
        String status = normalizeStatus(order.getOrderStatus());
        int current = states.indexOf("DELIVERED".equals(status) ? "COMPLETED" : status);
        if (current < 0) return Collections.emptyList(); // Cancelled/unknown must not look delivered.
        String[] labels = {"Đã đặt hàng", "Đã xác nhận", "Đang chuẩn bị", "Đang giao hàng", "Giao thành công"};
        String[] icons = {"receipt", "check2-circle", "box-seam", "truck", "house-check"};
        List<Map<String, Object>> steps = new ArrayList<>();
        for (int i = 0; i < states.size(); i++) {
            Map<String, Object> step = new LinkedHashMap<>();
            step.put("label", labels[i]);
            step.put("icon", icons[i]);
            step.put("done", i <= current);
            step.put("current", i == current);
            Object timestamp = i == 0 ? order.getCreatedAt() : null;
            for (Map<String, Object> entry : history) {
                String recorded = normalizeStatus((String) entry.get("status"));
                if (states.get(i).equals(recorded) || (i == 4 && "DELIVERED".equals(recorded))) {
                    timestamp = entry.get("updatedAt");
                }
            }
            step.put("at", i <= current ? timestamp : null);
            steps.add(step);
        }
        return steps;
    }
}
