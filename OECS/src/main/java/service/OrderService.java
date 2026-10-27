package service;

import dao.OrderDAO;
import db.CheckoutConnectionFactory;
import db.DBContext;
import model.Order;
import payment.PaymentGateway;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

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

    // Thong tin san pham trong gio hang
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
            this.cartItemId = cartItemId;
            this.skuId = skuId;
            this.quantity = quantity;
            this.price = price;
        }
    }

    // Ket qua kiem tra voucher
    private static final class VoucherResult {

        final Integer id;
        final BigDecimal discount;

        VoucherResult(Integer id, BigDecimal discount) {
            this.id = id;
            this.discount = discount;
        }
    }

    // Giu chu ky ham cu de cac class cu van bien dich duoc
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

    // Tuong thich voi luong COD cu
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

    // Tuong thich voi checkout COD co san pham duoc chon
    public int placeCodOrder(
            int userId,
            int addressId,
            String checkoutToken,
            String voucherCode,
            List<Integer> selectedCartItemIds
    ) throws SQLException {
        return placeOrder(
                userId,
                addressId,
                checkoutToken,
                voucherCode,
                selectedCartItemIds,
                "COD"
        );
    }

    // Dat hang chung cho COD, VNPAY va MOMO
    public int placeOrder(
            int userId,
            int addressId,
            String checkoutToken,
            String voucherCode,
            List<Integer> selectedCartItemIds,
            String paymentMethod
    ) throws SQLException {

        PaymentGateway.requireConfigured(paymentMethod);

        if (userId <= 0
                || addressId <= 0
                || checkoutToken == null
                || !checkoutToken.matches("[0-9a-fA-F-]{36}")) {

            throw new IllegalArgumentException(
                    "Yêu cầu đặt hàng không hợp lệ. "
                    + "Vui lòng tải lại Checkout."
            );
        }

        // null chi dung cho ham tuong thich checkout toan bo gio
        boolean selectedMode = selectedCartItemIds != null;
        List<Integer> selectedIds = new ArrayList<>();

        if (selectedMode) {
            for (Integer id : selectedCartItemIds) {
                if (id != null
                        && id > 0
                        && !selectedIds.contains(id)) {
                    selectedIds.add(id);
                }
            }

            if (selectedIds.isEmpty()) {
                throw new IllegalArgumentException(
                        "Vui lòng chọn sản phẩm để đặt hàng."
                );
            }
        }

        try (Connection conn = connections.open()) {
            if (conn == null) {
                throw new SQLException(
                        "Không kết nối được database."
                );
            }

            conn.setAutoCommit(false);

            try {
                // 1. Khoa gio hang de chan dat trung dong thoi
                int cartId;

                String sql
                        = "SELECT cart_id "
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

                // 2. Token da tao don thi tra ve don cu
                Integer existingOrderId = orderDAO.findIdByToken(
                        conn,
                        userId,
                        checkoutToken
                );

                if (existingOrderId != null) {
                    conn.commit();
                    return existingOrderId;
                }

                // 3. Kiem tra dia chi va luu thong tin nguoi nhan
                Order order = new Order();
                order.setUserId(userId);
                order.setAddressId(addressId);

                sql
                        = "SELECT recipient_name, phone_number, address_line "
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

                // 4. Lay dung cac san pham duoc chon
                List<CartLine> lines = new ArrayList<>();
                BigDecimal subtotal = BigDecimal.ZERO;

                StringBuilder itemsSql = new StringBuilder(
                        "SELECT ci.cart_item_id, ci.sku_id, "
                        + "ci.quantity, s.price "
                        + "FROM dbo.CART_ITEMS ci "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "JOIN dbo.PRODUCT_SKU s "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "ON s.sku_id = ci.sku_id "
                        + "WHERE ci.cart_id = ? "
                );

                if (selectedMode) {
                    itemsSql.append("AND ci.cart_item_id IN (");

                    for (int i = 0; i < selectedIds.size(); i++) {
                        if (i > 0) {
                            itemsSql.append(",");
                        }

                        itemsSql.append("?");
                    }

                    itemsSql.append(") ");
                }

                itemsSql.append("ORDER BY ci.cart_item_id");

                try (PreparedStatement ps
                        = conn.prepareStatement(itemsSql.toString())) {

                    int index = 1;
                    ps.setInt(index++, cartId);

                    if (selectedMode) {
                        for (Integer id : selectedIds) {
                            ps.setInt(index++, id);
                        }
                    }

                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            int cartItemId = rs.getInt("cart_item_id");
                            int skuId = rs.getInt("sku_id");
                            int quantity = rs.getInt("quantity");
                            BigDecimal price = rs.getBigDecimal("price");

                            if (quantity <= 0
                                    || price == null
                                    || price.signum() < 0) {

                                throw new IllegalArgumentException(
                                        "Sản phẩm trong giỏ hàng "
                                        + "không hợp lệ."
                                );
                            }

                            lines.add(new CartLine(
                                    cartItemId,
                                    skuId,
                                    quantity,
                                    price
                            ));

                            subtotal = subtotal.add(
                                    price.multiply(
                                            BigDecimal.valueOf(quantity)
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

                if (selectedMode && lines.size() != selectedIds.size()) {
                    throw new IllegalArgumentException(
                            "Một số sản phẩm đã chọn "
                            + "không còn trong giỏ hàng."
                    );
                }

                // 5. Khoa va kiem tra voucher trong transaction
                VoucherResult voucher = lockAndCalculateVoucher(
                        conn,
                        userId,
                        voucherCode,
                        subtotal
                );

                // 6. Tinh tien tu du lieu database
                BigDecimal shippingFee = BigDecimal.ZERO;

                BigDecimal totalAmount = subtotal
                        .add(shippingFee)
                        .subtract(voucher.discount)
                        .max(BigDecimal.ZERO);

                // 7. Tru ton kho; don online giu hang bang cach nay
                sql
                        = "UPDATE dbo.PRODUCT_SKU "
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

                // 8. Tao don hang
                order.setShippingFee(shippingFee);
                order.setDiscountAmount(voucher.discount);
                order.setTotalAmount(totalAmount);
                order.setPaymentMethod(paymentMethod);

                boolean pendingPayment
                        = !"COD".equals(paymentMethod)
                        && totalAmount.signum() > 0;

                order.setOrderStatus(
                        pendingPayment
                                ? "PENDING_PAYMENT"
                                : "PENDING_CONFIRMATION"
                );

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

                if (orderId <= 0) {
                    throw new SQLException(
                            "Không thể tạo đơn hàng."
                    );
                }

                // Han thanh toan online: 15 phut, luu UTC
                if (pendingPayment) {
                    sql
                            = "UPDATE dbo.[ORDER] "
                            + "SET payment_expires_at = "
                            + "DATEADD(MINUTE, 15, SYSUTCDATETIME()) "
                            + "WHERE order_id = ?";

                    try (PreparedStatement ps
                            = conn.prepareStatement(sql)) {

                        ps.setInt(1, orderId);

                        if (ps.executeUpdate() != 1) {
                            throw new SQLException(
                                    "Không lưu được hạn thanh toán."
                            );
                        }
                    }
                }

                // 9. Luu gia va so luong tai thoi diem dat
                for (CartLine line : lines) {
                    orderDAO.insertItem(
                            conn,
                            orderId,
                            line.skuId,
                            line.price,
                            line.quantity
                    );
                }

                // 10. Luu lich su trang thai ban dau
                orderDAO.addHistory(
                        conn,
                        orderId,
                        order.getOrderStatus()
                );

                // 11. Ghi nhan luot su dung voucher
                if (voucher.id != null) {
                    sql
                            = "INSERT INTO dbo.VOUCHER_USAGES "
                            + "(voucher_id, order_id, user_id) "
                            + "VALUES (?, ?, ?)";

                    try (PreparedStatement ps
                            = conn.prepareStatement(sql)) {

                        ps.setInt(1, voucher.id);
                        ps.setInt(2, orderId);
                        ps.setInt(3, userId);

                        if (ps.executeUpdate() != 1) {
                            throw new SQLException(
                                    "Không lưu được lượt sử dụng voucher."
                            );
                        }
                    }
                }

                // 12. Chi xoa cac san pham vua dat khoi gio
                sql
                        = "DELETE FROM dbo.CART_ITEMS "
                        + "WHERE cart_id = ? AND cart_item_id = ?";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    for (CartLine line : lines) {
                        ps.setInt(1, cartId);
                        ps.setInt(2, line.cartItemId);

                        if (ps.executeUpdate() != 1) {
                            throw new SQLException(
                                    "Không xóa được sản phẩm "
                                    + "đã đặt khỏi giỏ hàng."
                            );
                        }
                    }
                }

                // 13. Hoan tat toan bo transaction
                conn.commit();
                return orderId;

            } catch (SQLException | RuntimeException e) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;
            }
        }
    }

    // Kiem tra dieu kien, gioi han luot dung va tinh giam gia
    private VoucherResult lockAndCalculateVoucher(
            Connection conn,
            int userId,
            String voucherCode,
            BigDecimal subtotal
    ) throws SQLException {

        if (voucherCode == null || voucherCode.trim().isEmpty()) {
            return new VoucherResult(null, BigDecimal.ZERO);
        }

        String sql
                = "SELECT voucher_id, discount_type, discount_value, "
                + "max_discount, usage_limit, per_user_limit "
                + "FROM dbo.VOUCHER WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE UPPER(code) = UPPER(?) "
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

                Object usageValue = rs.getObject("usage_limit");

                usageLimit = usageValue == null
                        ? null
                        : ((Number) usageValue).intValue();

                Object perUserValue = rs.getObject("per_user_limit");

                perUserLimit = perUserValue == null
                        ? null
                        : ((Number) perUserValue).intValue();
            }
        }

        if (discountValue == null || discountValue.signum() <= 0) {
            throw new IllegalArgumentException(
                    "Voucher có giá trị giảm không hợp lệ."
            );
        }

        // Dem luot su dung khi van dang giu khoa voucher
        sql
                = "SELECT COUNT_BIG(*) AS total_used, "
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

        BigDecimal discount;

        if ("AMOUNT".equalsIgnoreCase(discountType)) {
            discount = discountValue;

        } else if ("PERCENT".equalsIgnoreCase(discountType)) {
            discount = subtotal
                    .multiply(discountValue)
                    .divide(
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

        discount = discount
                .max(BigDecimal.ZERO)
                .min(subtotal)
                .setScale(2, RoundingMode.HALF_UP);

        return new VoucherResult(voucherId, discount);
    }

    // Huy COD theo luong cu; don online dang cho do PaymentDAO xu ly
    public boolean cancelOrderByCustomer(
            int userId,
            int orderId
    ) throws SQLException {

        if (userId <= 0 || orderId <= 0) {
            throw new IllegalArgumentException(
                    "Mã đơn hàng không hợp lệ."
            );
        }

        try (Connection conn = connections.open()) {
            if (conn == null) {
                throw new SQLException(
                        "Không kết nối được database."
                );
            }

            conn.setAutoCommit(false);

            try {
                String sql
                        = "SELECT order_status, payment_method, "
                        + "payment_status, total_amount, stock_restored_at "
                        + "FROM dbo.[ORDER] WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE order_id = ? AND user_id = ?";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, orderId);
                    ps.setInt(2, userId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException(
                                    "Không tìm thấy đơn hàng."
                            );
                        }

                        String status = normalizeStatus(
                                rs.getString("order_status")
                        );

                        if ("CANCELLED".equals(status)) {
                            conn.commit();
                            return false;
                        }

                        if (!"PENDING_CONFIRMATION".equals(status)) {
                            throw new IllegalArgumentException(
                                    "Chỉ được hủy đơn trước khi "
                                    + "nhân viên xác nhận."
                            );
                        }

                        boolean isCod = "COD".equalsIgnoreCase(
                                rs.getString("payment_method")
                        );

                        boolean paidPositiveAmount
                                = "PAID".equalsIgnoreCase(
                                        rs.getString("payment_status")
                                )
                                && rs.getBigDecimal("total_amount")
                                        .signum() > 0;

                        if (!isCod || paidPositiveAmount) {
                            throw new IllegalArgumentException(
                                    "Đơn này cần được hỗ trợ "
                                    + "xử lý thanh toán trước khi hủy."
                            );
                        }

                        if (rs.getTimestamp("stock_restored_at") != null) {
                            throw new IllegalArgumentException(
                                    "Đơn đã được hoàn kho. "
                                    + "Vui lòng liên hệ hỗ trợ."
                            );
                        }
                    }
                }

                // Gom cac dong cung SKU va hoan kho theo thu tu
                List<int[]> quantities = new ArrayList<>();

                sql
                        = "SELECT sku_id, SUM(quantity) AS quantity "
                        + "FROM dbo.ORDER_ITEM "
                        + "WHERE order_id = ? "
                        + "GROUP BY sku_id ORDER BY sku_id";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, orderId);

                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            int quantity = rs.getInt("quantity");

                            if (quantity <= 0) {
                                throw new SQLException(
                                        "Số lượng đơn hàng không hợp lệ."
                                );
                            }

                            quantities.add(new int[]{
                                rs.getInt("sku_id"),
                                quantity
                            });
                        }
                    }
                }

                if (quantities.isEmpty()) {
                    throw new SQLException(
                            "Đơn hàng không có chi tiết để hoàn kho."
                    );
                }

                sql
                        = "UPDATE dbo.PRODUCT_SKU "
                        + "SET stock_quantity = stock_quantity + ? "
                        + "WHERE sku_id = ?";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    for (int[] item : quantities) {
                        ps.setInt(1, item[1]);
                        ps.setInt(2, item[0]);

                        if (ps.executeUpdate() != 1) {
                            throw new SQLException(
                                    "Không hoàn được tồn kho."
                            );
                        }
                    }
                }

                sql
                        = "UPDATE dbo.[ORDER] "
                        + "SET order_status = 'CANCELLED', "
                        + "stock_restored_at = GETDATE() "
                        + "WHERE order_id = ? AND user_id = ? "
                        + "AND stock_restored_at IS NULL "
                        + "AND UPPER(order_status) "
                        + "IN ('PENDING_CONFIRMATION', 'PENDING')";

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, orderId);
                    ps.setInt(2, userId);

                    if (ps.executeUpdate() != 1) {
                        throw new SQLException(
                                "Trạng thái đơn hàng đã thay đổi."
                        );
                    }
                }

                orderDAO.addHistory(conn, orderId, "CANCELLED");

                conn.commit();
                return true;

            } catch (SQLException | RuntimeException e) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;
            }
        }
    }

    // Lay lich su kem nhan hien thi
    public List<Map<String, Object>> findHistory(
            int orderId,
            int userId
    ) throws SQLException {

        List<Map<String, Object>> history
                = orderDAO.findHistory(orderId, userId);

        for (Map<String, Object> entry : history) {
            entry.put(
                    "label",
                    statusLabel((String) entry.get("status"))
            );
        }

        return history;
    }

    // Chuan hoa trang thai cu va moi
    public static String normalizeStatus(String status) {
        if (status == null) {
            return "";
        }

        String value = status
                .trim()
                .toUpperCase(Locale.ROOT)
                .replace(' ', '_');

        return "PENDING".equals(value)
                ? "PENDING_CONFIRMATION"
                : value;
    }

    public static Map<String, String> statusLabels() {
        Map<String, String> labels = new LinkedHashMap<>();

        labels.put("PENDING_PAYMENT", "Chờ thanh toán");
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
        return statusLabels().getOrDefault(
                normalizeStatus(status),
                status
        );
    }

    // Cac tab tren trang Don mua
    public static Map<String, String> purchaseTabs() {
        Map<String, String> tabs = new LinkedHashMap<>();

        tabs.put("ALL", "Tất cả");
        tabs.put("PAYMENT", "Chờ thanh toán");
        tabs.put("PENDING", "Chờ xác nhận");
        tabs.put("PREPARING", "Đang chuẩn bị hàng");
        tabs.put("SHIPPING", "Đang giao");
        tabs.put("COMPLETED", "Hoàn thành");
        tabs.put("CANCELLED", "Đã hủy");

        return tabs;
    }

    public static List<String> statusesForTab(String tab) {
        switch (tab) {
            case "PAYMENT":
                return Collections.singletonList("PENDING_PAYMENT");

            case "PENDING":
                return Arrays.asList(
                        "PENDING",
                        "PENDING_CONFIRMATION"
                );

            case "PREPARING":
                return Arrays.asList("CONFIRMED", "PACKING");

            case "SHIPPING":
                return Collections.singletonList("SHIPPING");

            case "COMPLETED":
                return Arrays.asList("DELIVERED", "COMPLETED");

            case "CANCELLED":
                return Collections.singletonList("CANCELLED");

            default:
                return Collections.emptyList();
        }
    }

    // Dem so don theo tung tab
    public static Map<String, Long> purchaseTabCounts(
            Map<String, Long> statuses
    ) {
        Map<String, Long> counts = new LinkedHashMap<>();

        for (String tab : purchaseTabs().keySet()) {
            counts.put(tab, 0L);
        }

        for (Map.Entry<String, Long> entry : statuses.entrySet()) {
            counts.put(
                    "ALL",
                    counts.get("ALL") + entry.getValue()
            );

            for (String tab : purchaseTabs().keySet()) {
                if (statusesForTab(tab).contains(
                        normalizeStatus(entry.getKey())
                )) {
                    counts.put(
                            tab,
                            counts.get(tab) + entry.getValue()
                    );
                }
            }
        }

        return counts;
    }

    // Tao cac buoc theo doi giao hang
    public static List<Map<String, Object>> trackingSteps(
            Order order,
            List<Map<String, Object>> history
    ) {
        List<String> states = Arrays.asList(
                "PENDING_CONFIRMATION",
                "CONFIRMED",
                "PACKING",
                "SHIPPING",
                "COMPLETED"
        );

        String status = normalizeStatus(order.getOrderStatus());

        int current = states.indexOf(
                "DELIVERED".equals(status)
                ? "COMPLETED"
                : status
        );

        // Don huy hoac cho thanh toan khong hien nhu da giao
        if (current < 0) {
            return Collections.emptyList();
        }

        String[] labels = {
            "Đã đặt hàng",
            "Đã xác nhận",
            "Đang chuẩn bị",
            "Đang giao hàng",
            "Giao thành công"
        };

        String[] icons = {
            "receipt",
            "check2-circle",
            "box-seam",
            "truck",
            "house-check"
        };

        List<Map<String, Object>> steps = new ArrayList<>();

        for (int i = 0; i < states.size(); i++) {
            Map<String, Object> step = new LinkedHashMap<>();

            step.put("label", labels[i]);
            step.put("icon", icons[i]);
            step.put("done", i <= current);
            step.put("current", i == current);

            Object timestamp = i == 0
                    ? order.getCreatedAt()
                    : null;

            for (Map<String, Object> entry : history) {
                String recorded = normalizeStatus(
                        (String) entry.get("status")
                );

                if (states.get(i).equals(recorded)
                        || (i == 4 && "DELIVERED".equals(recorded))) {
                    timestamp = entry.get("updatedAt");
                }
            }

            step.put(
                    "at",
                    i <= current ? timestamp : null
            );

            steps.add(step);
        }

        return steps;
    }
}
