
package dao;

import db.CheckoutConnectionFactory;
import db.DBContext;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class ReturnExchangeDAO {

    private final CheckoutConnectionFactory connections;

    public ReturnExchangeDAO() {
        this(() -> new DBContext().getConnection());
    }

    public ReturnExchangeDAO(
            CheckoutConnectionFactory connections) {
        this.connections = connections;
    }

    private Connection getConnection() throws SQLException {
        Connection conn = connections.open();

        if (conn == null) {
            throw new SQLException(
                    "Không kết nối được database.");
        }

        return conn;
    }

    // =====================================================
    // 1. KIỂM TRA ĐIỀU KIỆN TRẢ HÀNG
    // =====================================================

    public boolean canRequest(
            int orderId,
            int userId) throws SQLException {

        String sql =
                "SELECT 1 "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.order_id = ? "
                + "AND o.user_id = ? "
                + "AND o.order_status = 'COMPLETED' "
                + "AND o.delivered_at IS NOT NULL "
                + "AND o.delivered_at >= "
                + "DATEADD(DAY, -7, SYSDATETIME()) "
                + "AND o.delivered_at <= SYSDATETIME() "
                + "AND NOT EXISTS ( "
                + "    SELECT 1 FROM dbo.RETURN_REQUEST r "
                + "    WHERE r.order_id = o.order_id "
                + "    AND r.user_id = o.user_id "
                + "    AND r.request_status "
                + "    IN ('PENDING', 'APPROVED') "
                + ") "
                + "AND ( "
                + "    SELECT COUNT(*) "
                + "    FROM dbo.RETURN_REQUEST r "
                + "    WHERE r.order_id = o.order_id "
                + "    AND r.user_id = o.user_id "
                + "    AND r.request_status = 'REJECTED' "
                + ") < 2";

        try (Connection conn = getConnection();
                PreparedStatement ps =
                        conn.prepareStatement(sql)) {

            ps.setInt(1, orderId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // =====================================================
    // 2. LẤY SẢN PHẨM TRONG ĐƠN HÀNG
    // =====================================================

    public List<Map<String, Object>> getOrderItems(
            int orderId,
            int userId) throws SQLException {

        List<Map<String, Object>> items =
                new ArrayList<>();

        String sql =
                "SELECT "
                + "oi.order_item_id, "
                + "oi.sku_id, "
                + "oi.quantity, "
                + "oi.price, "
                + "s.sku_code, "
                + "s.product_id, "
                + "p.product_name "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.[ORDER] o "
                + "ON o.order_id = oi.order_id "
                + "JOIN dbo.PRODUCT_SKU s "
                + "ON s.sku_id = oi.sku_id "
                + "JOIN dbo.PRODUCT p "
                + "ON p.product_id = s.product_id "
                + "WHERE o.order_id = ? "
                + "AND o.user_id = ? "
                + "ORDER BY oi.order_item_id";

        try (Connection conn = getConnection();
                PreparedStatement ps =
                        conn.prepareStatement(sql)) {

            ps.setInt(1, orderId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Map<String, Object> item =
                            new LinkedHashMap<>();

                    item.put(
                            "orderItemId",
                            rs.getInt("order_item_id"));

                    item.put(
                            "skuId",
                            rs.getInt("sku_id"));

                    item.put(
                            "quantity",
                            rs.getInt("quantity"));

                    item.put(
                            "price",
                            rs.getBigDecimal("price"));

                    item.put(
                            "skuCode",
                            rs.getString("sku_code"));

                    item.put(
                            "productId",
                            rs.getInt("product_id"));

                    item.put(
                            "productName",
                            rs.getString("product_name"));

                    items.add(item);
                }
            }
        }

        return items;
    }

    // =====================================================
    // 3. CUSTOMER TẠO YÊU CẦU TRẢ HÀNG
    // =====================================================

    public int createRequest(
            int orderId,
            int userId,
            String requestType,
            String reason,
            List<Map<String, Integer>> items)
            throws SQLException {

        // Giữ tham số requestType để tương thích Service.
        // Hệ thống chỉ chấp nhận RETURN.

        if (!"RETURN".equals(requestType)) {
            throw new IllegalArgumentException(
                    "Hệ thống chỉ hỗ trợ trả hàng.");
        }

        if (reason == null || reason.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "Vui lòng nhập lý do trả hàng.");
        }

        if (reason.trim().length() > 1000) {
            throw new IllegalArgumentException(
                    "Lý do trả hàng không được vượt quá "
                    + "1000 ký tự.");
        }

        if (items == null || items.isEmpty()) {
            throw new IllegalArgumentException(
                    "Vui lòng chọn ít nhất một sản phẩm.");
        }

        String orderSql =
                "SELECT order_id "
                + "FROM dbo.[ORDER] WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE order_id = ? "
                + "AND user_id = ? "
                + "AND order_status = 'COMPLETED' "
                + "AND delivered_at IS NOT NULL "
                + "AND delivered_at >= "
                + "DATEADD(DAY, -7, SYSDATETIME()) "
                + "AND delivered_at <= SYSDATETIME()";

        String requestLimitSql =
                "SELECT "
                + "COUNT(CASE "
                + "WHEN request_status = 'REJECTED' "
                + "THEN 1 END) AS rejected_count, "
                + "COUNT(CASE "
                + "WHEN request_status IN ('PENDING','APPROVED') "
                + "THEN 1 END) AS blocked_count "
                + "FROM dbo.RETURN_REQUEST "
                + "WHERE order_id = ? "
                + "AND user_id = ?";

        String itemSql =
                "SELECT quantity "
                + "FROM dbo.ORDER_ITEM "
                + "WHERE order_item_id = ? "
                + "AND order_id = ?";

        String usedSql =
                "SELECT COALESCE(SUM(ri.quantity), 0) "
                + "FROM dbo.RETURN_REQUEST_ITEM ri "
                + "JOIN dbo.RETURN_REQUEST r "
                + "ON r.request_id = ri.request_id "
                + "WHERE ri.order_item_id = ? "
                + "AND r.request_status "
                + "IN ('PENDING', 'APPROVED')";

        String insertRequestSql =
                "INSERT INTO dbo.RETURN_REQUEST "
                + "(order_id, user_id, reason, request_status) "
                + "VALUES (?, ?, ?, 'PENDING')";

        String insertItemSql =
                "INSERT INTO dbo.RETURN_REQUEST_ITEM "
                + "(request_id, order_item_id, quantity) "
                + "VALUES (?, ?, ?)";

        String historySql =
                "INSERT INTO dbo.RETURN_REQUEST_HISTORY "
                + "(request_id, status, updated_by, note) "
                + "VALUES (?, 'PENDING', ?, ?)";

        try (Connection conn = getConnection()) {

            conn.setAutoCommit(false);

            try {

                // Kiểm tra đơn hàng và khóa đơn hàng.
                try (PreparedStatement ps =
                        conn.prepareStatement(orderSql)) {

                    ps.setInt(1, orderId);
                    ps.setInt(2, userId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {
                            throw new SQLException(
                                    "Đơn hàng không hợp lệ "
                                    + "hoặc đã quá hạn 7 ngày.");
                        }
                    }
                }

                // Kiểm tra yêu cầu Return trước đó.
                try (PreparedStatement ps =
                        conn.prepareStatement(requestLimitSql)) {

                    ps.setInt(1, orderId);
                    ps.setInt(2, userId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (rs.next()) {

                            int rejectedCount =
                                    rs.getInt("rejected_count");

                            int blockedCount =
                                    rs.getInt("blocked_count");

                            if (rejectedCount >= 2) {
                                throw new SQLException(
                                        "Đơn hàng đã bị từ chối "
                                        + "trả hàng 2 lần.");
                            }

                            if (blockedCount > 0) {
                                throw new SQLException(
                                        "Đơn hàng đã có yêu cầu "
                                        + "trả hàng đang chờ xử lý "
                                        + "hoặc đã được duyệt.");
                            }
                        }
                    }
                }

                // Tạo yêu cầu trả hàng.
                int requestId;

                try (PreparedStatement ps =
                        conn.prepareStatement(
                                insertRequestSql,
                                Statement.RETURN_GENERATED_KEYS)) {

                    ps.setInt(1, orderId);
                    ps.setInt(2, userId);
                    ps.setString(3, reason.trim());

                    ps.executeUpdate();

                    try (ResultSet rs = ps.getGeneratedKeys()) {

                        if (!rs.next()) {
                            throw new SQLException(
                                    "Không tạo được yêu cầu trả hàng.");
                        }

                        requestId = rs.getInt(1);
                    }
                }

                // Tránh gửi trùng một orderItemId
                // trong cùng một yêu cầu.
                Set<Integer> selectedItemIds =
                        new HashSet<>();

                // Lưu danh sách sản phẩm muốn trả.
                for (Map<String, Integer> item : items) {

                    if (item == null
                            || item.get("orderItemId") == null
                            || item.get("quantity") == null) {

                        throw new IllegalArgumentException(
                                "Thông tin sản phẩm không hợp lệ.");
                    }

                    int orderItemId =
                            item.get("orderItemId");

                    int quantity =
                            item.get("quantity");

                    if (quantity <= 0) {
                        throw new IllegalArgumentException(
                                "Số lượng trả phải lớn hơn 0.");
                    }

                    if (!selectedItemIds.add(orderItemId)) {
                        throw new IllegalArgumentException(
                                "Sản phẩm bị chọn trùng "
                                + "trong yêu cầu trả hàng.");
                    }

                    int orderedQuantity;

                    // Kiểm tra sản phẩm thuộc đơn hàng.
                    try (PreparedStatement ps =
                            conn.prepareStatement(itemSql)) {

                        ps.setInt(1, orderItemId);
                        ps.setInt(2, orderId);

                        try (ResultSet rs = ps.executeQuery()) {

                            if (!rs.next()) {
                                throw new SQLException(
                                        "Sản phẩm không thuộc đơn hàng.");
                            }

                            orderedQuantity =
                                    rs.getInt("quantity");
                        }
                    }

                    if (quantity > orderedQuantity) {
                        throw new IllegalArgumentException(
                                "Số lượng trả vượt quá "
                                + "số lượng đã mua.");
                    }

                    // Không cho trả vượt số lượng còn hợp lệ.
                    try (PreparedStatement ps =
                            conn.prepareStatement(usedSql)) {

                        ps.setInt(1, orderItemId);

                        try (ResultSet rs = ps.executeQuery()) {

                            if (rs.next()) {

                                int usedQuantity = rs.getInt(1);

                                if (usedQuantity + quantity
                                        > orderedQuantity) {

                                    throw new SQLException(
                                            "Số lượng đã được yêu cầu "
                                            + "trả trước đó vượt giới hạn.");
                                }
                            }
                        }
                    }

                    // Lưu chi tiết yêu cầu Return.
                    try (PreparedStatement ps =
                            conn.prepareStatement(insertItemSql)) {

                        ps.setInt(1, requestId);
                        ps.setInt(2, orderItemId);
                        ps.setInt(3, quantity);

                        ps.executeUpdate();
                    }
                }

                // Ghi lịch sử tạo yêu cầu.
                try (PreparedStatement ps =
                        conn.prepareStatement(historySql)) {

                    ps.setInt(1, requestId);
                    ps.setInt(2, userId);
                    ps.setString(
                            3,
                            "Khách hàng gửi yêu cầu trả hàng.");

                    ps.executeUpdate();
                }

                conn.commit();
                return requestId;

            } catch (SQLException | RuntimeException ex) {

                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    ex.addSuppressed(rollbackEx);
                }

                throw ex;
            }
        }
    }

    // =====================================================
    // 4. STAFF XEM DANH SÁCH YÊU CẦU RETURN
    // =====================================================

    public List<Map<String, Object>> getAllRequests()
            throws SQLException {

        List<Map<String, Object>> requests =
                new ArrayList<>();

        String sql =
                "SELECT "
                + "r.request_id, "
                + "r.order_id, "
                + "r.user_id, "
                + "u.username, "
                + "COALESCE(NULLIF(o.recipient_phone, ''), "
                + "u.phone) AS phone, "
                + "o.recipient_name, "
                + "o.shipping_address, "
                + "r.reason, "
                + "r.request_status, "
                + "r.created_at, "
                + "r.reviewed_at, "
                + "r.staff_note "
                + "FROM dbo.RETURN_REQUEST r "
                + "JOIN dbo.[USER] u "
                + "ON u.user_id = r.user_id "
                + "JOIN dbo.[ORDER] o "
                + "ON o.order_id = r.order_id "
                + "ORDER BY "
                + "CASE WHEN r.request_status = 'PENDING' "
                + "THEN 0 ELSE 1 END, "
                + "r.created_at DESC";

        try (Connection conn = getConnection();
                PreparedStatement ps =
                        conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Map<String, Object> item =
                        new LinkedHashMap<>();

                item.put(
                        "requestId",
                        rs.getInt("request_id"));

                item.put(
                        "orderId",
                        rs.getInt("order_id"));

                item.put(
                        "userId",
                        rs.getInt("user_id"));

                item.put(
                        "username",
                        rs.getString("username"));

                item.put(
                        "phone",
                        rs.getString("phone"));

                item.put(
                        "recipientName",
                        rs.getString("recipient_name"));

                item.put(
                        "shippingAddress",
                        rs.getString("shipping_address"));

                // Tương thích các JSP cũ.
                // Không cần cột request_type trong DB.
                item.put("requestType", "RETURN");

                item.put(
                        "reason",
                        rs.getString("reason"));

                item.put(
                        "requestStatus",
                        rs.getString("request_status"));

                item.put(
                        "createdAt",
                        rs.getTimestamp("created_at"));

                item.put(
                        "reviewedAt",
                        rs.getTimestamp("reviewed_at"));

                item.put(
                        "staffNote",
                        rs.getString("staff_note"));

                requests.add(item);
            }
        }

        return requests;
    }

    // =====================================================
    // 5. STAFF XEM CHI TIẾT SẢN PHẨM TRẢ
    // =====================================================

    public List<Map<String, Object>> getRequestItems(
            int requestId) throws SQLException {

        List<Map<String, Object>> items =
                new ArrayList<>();

        String sql =
                "SELECT "
                + "ri.request_item_id, "
                + "ri.order_item_id, "
                + "ri.quantity, "
                + "oi.price, "
                + "p.product_name, "
                + "s.sku_code AS original_sku_code "
                + "FROM dbo.RETURN_REQUEST_ITEM ri "
                + "JOIN dbo.ORDER_ITEM oi "
                + "ON oi.order_item_id = ri.order_item_id "
                + "JOIN dbo.PRODUCT_SKU s "
                + "ON s.sku_id = oi.sku_id "
                + "JOIN dbo.PRODUCT p "
                + "ON p.product_id = s.product_id "
                + "WHERE ri.request_id = ? "
                + "ORDER BY ri.request_item_id";

        try (Connection conn = getConnection();
                PreparedStatement ps =
                        conn.prepareStatement(sql)) {

            ps.setInt(1, requestId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Map<String, Object> item =
                            new LinkedHashMap<>();

                    item.put(
                            "requestItemId",
                            rs.getInt("request_item_id"));

                    item.put(
                            "orderItemId",
                            rs.getInt("order_item_id"));

                    item.put(
                            "quantity",
                            rs.getInt("quantity"));

                    item.put(
                            "price",
                            rs.getBigDecimal("price"));

                    item.put(
                            "productName",
                            rs.getString("product_name"));

                    item.put(
                            "originalSkuCode",
                            rs.getString("original_sku_code"));

                    items.add(item);
                }
            }
        }

        return items;
    }

    // =====================================================
    // 6. STAFF DUYỆT / TỪ CHỐI YÊU CẦU RETURN
    // =====================================================

    public boolean reviewRequest(
            int requestId,
            int staffId,
            String newStatus,
            String staffNote) throws SQLException {

        if (requestId <= 0 || staffId <= 0) {
            throw new IllegalArgumentException(
                    "Mã yêu cầu hoặc nhân viên không hợp lệ.");
        }

        if (!"APPROVED".equals(newStatus)
                && !"REJECTED".equals(newStatus)) {
            throw new IllegalArgumentException(
                    "Trạng thái xử lý không hợp lệ.");
        }

        if ("REJECTED".equals(newStatus)
                && (staffNote == null
                || staffNote.trim().isEmpty())) {

            throw new IllegalArgumentException(
                    "Vui lòng nhập lý do từ chối.");
        }

        String normalizedNote =
                staffNote == null ? null : staffNote.trim();

        try (Connection conn = getConnection()) {

            conn.setAutoCommit(false);

            try {
                int customerId;
                int orderId;

                String lockSql =
                        "SELECT user_id, order_id, request_status "
                        + "FROM dbo.RETURN_REQUEST "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE request_id = ?";

                try (PreparedStatement ps =
                        conn.prepareStatement(lockSql)) {

                    ps.setInt(1, requestId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {
                            conn.rollback();
                            return false;
                        }

                        String currentStatus =
                                rs.getString("request_status");

                        if (!"PENDING".equals(currentStatus)) {
                            conn.rollback();
                            return false;
                        }

                        customerId = rs.getInt("user_id");
                        orderId = rs.getInt("order_id");
                    }
                }

                // Duyệt hoặc từ chối yêu cầu.
                String updateSql =
                        "UPDATE dbo.RETURN_REQUEST SET "
                        + "request_status = ?, "
                        + "reviewed_by = ?, "
                        + "reviewed_at = SYSDATETIME(), "
                        + "staff_note = ? "
                        + "WHERE request_id = ? "
                        + "AND request_status = 'PENDING'";

                try (PreparedStatement ps =
                        conn.prepareStatement(updateSql)) {

                    ps.setString(1, newStatus);
                    ps.setInt(2, staffId);
                    ps.setString(3, normalizedNote);
                    ps.setInt(4, requestId);

                    if (ps.executeUpdate() != 1) {
                        conn.rollback();
                        return false;
                    }
                }

                // Lưu lịch sử xét duyệt.
                String historySql =
                        "INSERT INTO dbo.RETURN_REQUEST_HISTORY "
                        + "(request_id, status, updated_by, note) "
                        + "VALUES (?, ?, ?, ?)";

                try (PreparedStatement ps =
                        conn.prepareStatement(historySql)) {

                    ps.setInt(1, requestId);
                    ps.setString(2, newStatus);
                    ps.setInt(3, staffId);
                    ps.setString(4, normalizedNote);

                    ps.executeUpdate();
                }

                // Thông báo cho khách hàng.
                new NotificationDAO()
                        .createReturnExchangeNotification(
                                conn,
                                customerId,
                                orderId,
                                "RETURN",
                                newStatus
                        );

                // Không tự cộng tồn kho tại đây.
                // Không tự thực hiện hoặc ghi nhận hoàn tiền.

                conn.commit();
                return true;

            } catch (SQLException | RuntimeException ex) {

                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    ex.addSuppressed(rollbackEx);
                }

                throw ex;
            }
        }
    }

    // =====================================================
    // 7. LẤY YÊU CẦU RETURN MỚI NHẤT CỦA ĐƠN HÀNG
    // =====================================================

    public Map<String, Object> getLatestRequestByOrder(
            int orderId,
            int userId) throws SQLException {

        String sql =
                "SELECT TOP 1 "
                + "request_id, "
                + "request_status, "
                + "reason, "
                + "created_at, "
                + "reviewed_at, "
                + "staff_note "
                + "FROM dbo.RETURN_REQUEST "
                + "WHERE order_id = ? "
                + "AND user_id = ? "
                + "ORDER BY created_at DESC, request_id DESC";

        try (Connection conn = getConnection();
                PreparedStatement ps =
                        conn.prepareStatement(sql)) {

            ps.setInt(1, orderId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    Map<String, Object> request =
                            new LinkedHashMap<>();

                    request.put(
                            "requestId",
                            rs.getInt("request_id"));

                    // Tương thích JSP chi tiết đơn hàng cũ.
                    request.put("requestType", "RETURN");

                    request.put(
                            "requestStatus",
                            rs.getString("request_status"));

                    request.put(
                            "reason",
                            rs.getString("reason"));

                    request.put(
                            "createdAt",
                            rs.getTimestamp("created_at"));

                    request.put(
                            "reviewedAt",
                            rs.getTimestamp("reviewed_at"));

                    request.put(
                            "staffNote",
                            rs.getString("staff_note"));

                    return request;
                }
            }
        }

        return null;
    }
}
