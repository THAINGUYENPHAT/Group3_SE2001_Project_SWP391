
package dao;

import db.DBContext;
import db.CheckoutConnectionFactory;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ReturnExchangeDAO {

    private final CheckoutConnectionFactory connections;

    public ReturnExchangeDAO() {
        this(() -> new DBContext().getConnection());
    }

    public ReturnExchangeDAO(CheckoutConnectionFactory connections) {
        this.connections = connections;
    }

    private Connection getConnection() throws SQLException {
        Connection conn = connections.open();

        if (conn == null) {
            throw new SQLException("Không kết nối được database.");
        }

        return conn;
    }

    // Kiểm tra đơn đã giao thành công và còn trong thời hạn 7 ngày.
    public boolean canRequest(int orderId, int userId) throws SQLException {
        String sql =
                "SELECT 1 FROM dbo.[ORDER] "
                + "WHERE order_id = ? AND user_id = ? "
                + "AND UPPER(LTRIM(RTRIM(order_status))) = 'COMPLETED' "
                + "AND delivered_at IS NOT NULL "
                + "AND delivered_at <= SYSDATETIME() "
                + "AND delivered_at >= DATEADD(DAY, -7, SYSDATETIME())";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, orderId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // Lấy sản phẩm trong đơn của đúng khách hàng.
    public List<Map<String, Object>> getOrderItems(
            int orderId, int userId) throws SQLException {

        List<Map<String, Object>> items = new ArrayList<>();

        String sql =
                "SELECT oi.order_item_id, oi.sku_id, oi.quantity, "
                + "oi.price, s.sku_code, s.product_id, p.product_name "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.[ORDER] o ON o.order_id = oi.order_id "
                + "JOIN dbo.PRODUCT_SKU s ON s.sku_id = oi.sku_id "
                + "JOIN dbo.PRODUCT p ON p.product_id = s.product_id "
                + "WHERE o.order_id = ? AND o.user_id = ? "
                + "ORDER BY oi.order_item_id";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, orderId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("orderItemId", rs.getInt("order_item_id"));
                    item.put("skuId", rs.getInt("sku_id"));
                    item.put("quantity", rs.getInt("quantity"));
                    item.put("price", rs.getBigDecimal("price"));
                    item.put("skuCode", rs.getString("sku_code"));
                    item.put("productId", rs.getInt("product_id"));
                    item.put("productName", rs.getString("product_name"));
                    items.add(item);
                }
            }
        }

        return items;
    }

    // Chỉ lấy SKU khác thuộc cùng sản phẩm.
    public List<Map<String, Object>> getExchangeSkus(
            int orderItemId, int userId) throws SQLException {

        List<Map<String, Object>> skus = new ArrayList<>();

        String sql =
                "SELECT target.sku_id, target.sku_code, "
                + "target.price, target.stock_quantity "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.[ORDER] o ON o.order_id = oi.order_id "
                + "JOIN dbo.PRODUCT_SKU original "
                + "ON original.sku_id = oi.sku_id "
                + "JOIN dbo.PRODUCT_SKU target "
                + "ON target.product_id = original.product_id "
                + "JOIN dbo.PRODUCT p "
                + "ON p.product_id = target.product_id "
                + "WHERE oi.order_item_id = ? AND o.user_id = ? "
                + "AND target.sku_id <> original.sku_id "
                + "AND target.stock_quantity > 0 "
                + "ORDER BY target.sku_code";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, orderItemId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> sku = new LinkedHashMap<>();
                    sku.put("skuId", rs.getInt("sku_id"));
                    sku.put("skuCode", rs.getString("sku_code"));
                    sku.put("price", rs.getBigDecimal("price"));
                    sku.put("stockQuantity", rs.getInt("stock_quantity"));
                    skus.add(sku);
                }
            }
        }

        return skus;
    }

    // Tạo yêu cầu và các dòng sản phẩm trong cùng transaction.
    // items: mỗi dòng có orderItemId, quantity và exchangeSkuId.
    // Với trả hàng, exchangeSkuId truyền null.
    public int createRequest(
            int orderId,
            int userId,
            String requestType,
            String reason,
            List<Map<String, Integer>> items) throws SQLException {

        if (!"RETURN".equals(requestType)
                && !"EXCHANGE".equals(requestType)) {
            throw new IllegalArgumentException("Loại yêu cầu không hợp lệ.");
        }

        if (reason == null || reason.trim().isEmpty()) {
            throw new IllegalArgumentException("Vui lòng nhập lý do.");
        }

        if (items == null || items.isEmpty()) {
            throw new IllegalArgumentException("Vui lòng chọn sản phẩm.");
        }

        String orderSql =
                "SELECT order_id FROM dbo.[ORDER] WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE order_id = ? AND user_id = ? "
                + "AND UPPER(LTRIM(RTRIM(order_status))) = 'COMPLETED' "
                + "AND delivered_at IS NOT NULL "
                + "AND delivered_at <= SYSDATETIME() "
                + "AND delivered_at >= DATEADD(DAY, -7, SYSDATETIME())";

        String itemSql =
                "SELECT oi.quantity, oi.sku_id, original.product_id "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.PRODUCT_SKU original "
                + "ON original.sku_id = oi.sku_id "
                + "WHERE oi.order_item_id = ? AND oi.order_id = ?";

        String exchangeSql =
                "SELECT product_id, stock_quantity FROM dbo.PRODUCT_SKU "
                + "WHERE sku_id = ?";

        String insertRequestSql =
                "INSERT INTO dbo.RETURN_REQUEST "
                + "(order_id, user_id, request_type, reason, request_status) "
                + "VALUES (?, ?, ?, ?, 'PENDING')";

        String insertItemSql =
                "INSERT INTO dbo.RETURN_REQUEST_ITEM "
                + "(request_id, order_item_id, quantity, exchange_sku_id) "
                + "VALUES (?, ?, ?, ?)";

        String historySql =
                "INSERT INTO dbo.RETURN_REQUEST_HISTORY "
                + "(request_id, status, updated_by, note) "
                + "VALUES (?, 'PENDING', ?, ?)";

        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);

            try {
                try (PreparedStatement ps = conn.prepareStatement(orderSql)) {
                    ps.setInt(1, orderId);
                    ps.setInt(2, userId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException(
                                    "Đơn hàng không hợp lệ hoặc đã quá hạn 7 ngày.");
                        }
                    }
                }

                int requestId;

                try (PreparedStatement ps = conn.prepareStatement(
                        insertRequestSql, Statement.RETURN_GENERATED_KEYS)) {

                    ps.setInt(1, orderId);
                    ps.setInt(2, userId);
                    ps.setString(3, requestType);
                    ps.setString(4, reason.trim());
                    ps.executeUpdate();

                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new SQLException(
                                    "Không tạo được mã yêu cầu.");
                        }

                        requestId = rs.getInt(1);
                    }
                }

                for (Map<String, Integer> item : items) {
                    if (item == null
                            || item.get("orderItemId") == null
                            || item.get("quantity") == null) {
                        throw new IllegalArgumentException(
                                "Thông tin sản phẩm không hợp lệ.");
                    }

                    int orderItemId = item.get("orderItemId");
                    int quantity = item.get("quantity");
                    Integer exchangeSkuId = item.get("exchangeSkuId");

                    if (quantity <= 0) {
                        throw new IllegalArgumentException(
                                "Số lượng phải lớn hơn 0.");
                    }

                    int originalQuantity;
                    int originalProductId;

                    try (PreparedStatement ps = conn.prepareStatement(itemSql)) {
                        ps.setInt(1, orderItemId);
                        ps.setInt(2, orderId);

                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) {
                                throw new SQLException(
                                        "Sản phẩm không thuộc đơn hàng.");
                            }

                            originalQuantity = rs.getInt("quantity");
                            originalProductId = rs.getInt("product_id");
                        }
                    }

                    if (quantity > originalQuantity) {
                        throw new IllegalArgumentException(
                                "Số lượng yêu cầu vượt quá số lượng đã mua.");
                    }

                    // Không cho tạo nhiều yêu cầu làm vượt số lượng đã mua.
                    String usedSql =
                            "SELECT COALESCE(SUM(ri.quantity), 0) "
                            + "FROM dbo.RETURN_REQUEST_ITEM ri "
                            + "JOIN dbo.RETURN_REQUEST r "
                            + "ON r.request_id = ri.request_id "
                            + "WHERE ri.order_item_id = ? "
                            + "AND r.request_status IN ('PENDING', 'APPROVED')";

                    try (PreparedStatement ps = conn.prepareStatement(usedSql)) {
                        ps.setInt(1, orderItemId);

                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()
                                    && rs.getInt(1) + quantity > originalQuantity) {
                                throw new SQLException(
                                        "Số lượng đã được yêu cầu trả/đổi trước đó.");
                            }
                        }
                    }

                    if ("EXCHANGE".equals(requestType)) {
                        if (exchangeSkuId == null) {
                            throw new IllegalArgumentException(
                                    "Vui lòng chọn SKU muốn đổi.");
                        }

                        try (PreparedStatement ps =
                                conn.prepareStatement(exchangeSql)) {
                            ps.setInt(1, exchangeSkuId);

                            try (ResultSet rs = ps.executeQuery()) {
                                if (!rs.next()
                                        || rs.getInt("product_id") != originalProductId
                                        || exchangeSkuId
                                        == getOriginalSkuId(conn, orderItemId)) {
                                    throw new SQLException(
                                            "SKU đổi phải là phiên bản khác của cùng sản phẩm.");
                                }

                                if (rs.getInt("stock_quantity") <= 0) {
                                    throw new SQLException(
                                            "SKU đổi hiện không còn hàng.");
                                }
                            }
                        }
                    } else if (exchangeSkuId != null) {
                        throw new IllegalArgumentException(
                                "Yêu cầu trả hàng không cần chọn SKU đổi.");
                    }

                    try (PreparedStatement ps = conn.prepareStatement(insertItemSql)) {
                        ps.setInt(1, requestId);
                        ps.setInt(2, orderItemId);
                        ps.setInt(3, quantity);

                        if (exchangeSkuId == null) {
                            ps.setNull(4, java.sql.Types.INTEGER);
                        } else {
                            ps.setInt(4, exchangeSkuId);
                        }

                        ps.executeUpdate();
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(historySql)) {
                    ps.setInt(1, requestId);
                    ps.setInt(2, userId);
                    ps.setString(3, "Khách hàng gửi yêu cầu.");
                    ps.executeUpdate();
                }

                conn.commit();
                return requestId;

            } catch (SQLException | RuntimeException ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private int getOriginalSkuId(
            Connection conn, int orderItemId) throws SQLException {

        String sql =
                "SELECT sku_id FROM dbo.ORDER_ITEM WHERE order_item_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderItemId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("Không tìm thấy sản phẩm trong đơn.");
                }

                return rs.getInt("sku_id");
            }
        }
    }
    
    // Lấy danh sách yêu cầu đổi/trả cho Staff.
    public List<Map<String, Object>> getAllRequests() throws SQLException {
        List<Map<String, Object>> requests = new ArrayList<>();

        String sql =
                "SELECT r.request_id, r.order_id, r.user_id, "
                + "u.username, r.request_type, r.reason, "
                + "r.request_status, r.created_at, "
                + "r.reviewed_at, r.staff_note "
                + "FROM dbo.RETURN_REQUEST r "
                + "JOIN dbo.[USER] u ON u.user_id = r.user_id "
                + "ORDER BY CASE WHEN r.request_status = 'PENDING' "
                + "THEN 0 ELSE 1 END, r.created_at DESC";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("requestId", rs.getInt("request_id"));
                item.put("orderId", rs.getInt("order_id"));
                item.put("userId", rs.getInt("user_id"));
                item.put("username", rs.getString("username"));
                item.put("requestType", rs.getString("request_type"));
                item.put("reason", rs.getString("reason"));
                item.put("requestStatus", rs.getString("request_status"));
                item.put("createdAt", rs.getTimestamp("created_at"));
                item.put("reviewedAt", rs.getTimestamp("reviewed_at"));
                item.put("staffNote", rs.getString("staff_note"));
                requests.add(item);
            }
        }

        return requests;
    }

    // Lấy chi tiết các sản phẩm trong một yêu cầu.
    public List<Map<String, Object>> getRequestItems(
            int requestId) throws SQLException {

        List<Map<String, Object>> items = new ArrayList<>();

        String sql =
                "SELECT ri.request_item_id, ri.order_item_id, "
                + "ri.quantity, ri.exchange_sku_id, "
                + "p.product_name, original.sku_code AS original_sku_code, "
                + "target.sku_code AS exchange_sku_code "
                + "FROM dbo.RETURN_REQUEST_ITEM ri "
                + "JOIN dbo.ORDER_ITEM oi "
                + "ON oi.order_item_id = ri.order_item_id "
                + "JOIN dbo.PRODUCT_SKU original "
                + "ON original.sku_id = oi.sku_id "
                + "JOIN dbo.PRODUCT p "
                + "ON p.product_id = original.product_id "
                + "LEFT JOIN dbo.PRODUCT_SKU target "
                + "ON target.sku_id = ri.exchange_sku_id "
                + "WHERE ri.request_id = ? "
                + "ORDER BY ri.request_item_id";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, requestId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("requestItemId", rs.getInt("request_item_id"));
                    item.put("orderItemId", rs.getInt("order_item_id"));
                    item.put("quantity", rs.getInt("quantity"));
                    item.put("exchangeSkuId", rs.getObject("exchange_sku_id"));
                    item.put("productName", rs.getString("product_name"));
                    item.put("originalSkuCode",
                            rs.getString("original_sku_code"));
                    item.put("exchangeSkuCode",
                            rs.getString("exchange_sku_code"));
                    items.add(item);
                }
            }
        }

        return items;
    }

    // Staff duyệt hoặc từ chối yêu cầu đang chờ xử lý.
    
    // Staff duyệt hoặc từ chối yêu cầu và cập nhật tồn kho trong cùng transaction.
    public boolean reviewRequest(
            int requestId,
            int staffId,
            String newStatus,
            String staffNote) throws SQLException {

        if (!"APPROVED".equals(newStatus)
                && !"REJECTED".equals(newStatus)) {
            throw new IllegalArgumentException(
                    "Trạng thái duyệt không hợp lệ.");
        }

        String lockRequestSql =
                "SELECT request_type, request_status "
                + "FROM dbo.RETURN_REQUEST WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE request_id = ?";

        String getItemsSql =
                "SELECT ri.quantity, ri.exchange_sku_id, "
                + "oi.sku_id AS original_sku_id, "
                + "original.product_id AS original_product_id "
                + "FROM dbo.RETURN_REQUEST_ITEM ri "
                + "JOIN dbo.ORDER_ITEM oi "
                + "ON oi.order_item_id = ri.order_item_id "
                + "JOIN dbo.PRODUCT_SKU original "
                + "ON original.sku_id = oi.sku_id "
                + "WHERE ri.request_id = ? "
                + "ORDER BY ri.request_item_id";

        String getTargetSql =
                "SELECT product_id "
                + "FROM dbo.PRODUCT_SKU WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE sku_id = ?";

        String addStockSql =
                "UPDATE dbo.PRODUCT_SKU "
                + "SET stock_quantity = stock_quantity + ? "
                + "WHERE sku_id = ?";

        String subtractStockSql =
                "UPDATE dbo.PRODUCT_SKU "
                + "SET stock_quantity = stock_quantity - ? "
                + "WHERE sku_id = ? AND stock_quantity >= ?";

        String updateRequestSql =
                "UPDATE dbo.RETURN_REQUEST "
                + "SET request_status = ?, reviewed_by = ?, "
                + "reviewed_at = SYSDATETIME(), staff_note = ? "
                + "WHERE request_id = ? AND request_status = 'PENDING'";

        String historySql =
                "INSERT INTO dbo.RETURN_REQUEST_HISTORY "
                + "(request_id, status, updated_by, note) "
                + "VALUES (?, ?, ?, ?)";

        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);

            try {
                String requestType;
                String currentStatus;

                // Khóa yêu cầu để ngăn hai nhân viên xử lý đồng thời.
                try (PreparedStatement ps =
                        conn.prepareStatement(lockRequestSql)) {
                    ps.setInt(1, requestId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return false;
                        }

                        requestType = rs.getString("request_type");
                        currentStatus = rs.getString("request_status");
                    }
                }

                if (!"PENDING".equals(currentStatus)) {
                    conn.rollback();
                    return false;
                }

                // Chỉ cập nhật tồn kho khi yêu cầu được duyệt.
                if ("APPROVED".equals(newStatus)) {
                    if (!"RETURN".equals(requestType)
                            && !"EXCHANGE".equals(requestType)) {
                        throw new SQLException(
                                "Loại yêu cầu không hợp lệ.");
                    }

                    List<Map<String, Object>> items =
                            new ArrayList<>();

                    try (PreparedStatement ps =
                            conn.prepareStatement(getItemsSql)) {
                        ps.setInt(1, requestId);

                        try (ResultSet rs = ps.executeQuery()) {
                            while (rs.next()) {
                                Map<String, Object> item =
                                        new LinkedHashMap<>();

                                item.put("quantity",
                                        rs.getInt("quantity"));
                                item.put("exchangeSkuId",
                                        (Integer) rs.getObject(
                                                "exchange_sku_id"));
                                item.put("originalSkuId",
                                        rs.getInt("original_sku_id"));
                                item.put("originalProductId",
                                        rs.getInt("original_product_id"));

                                items.add(item);
                            }
                        }
                    }

                    if (items.isEmpty()) {
                        throw new SQLException(
                                "Yêu cầu không có sản phẩm.");
                    }

                    for (Map<String, Object> item : items) {
                        int quantity = (Integer) item.get("quantity");
                        int originalSkuId =
                                (Integer) item.get("originalSkuId");
                        int originalProductId =
                                (Integer) item.get("originalProductId");

                        if (quantity <= 0) {
                            throw new SQLException(
                                    "Số lượng sản phẩm không hợp lệ.");
                        }

                        if ("RETURN".equals(requestType)) {
                            // Trả hàng: cộng hàng cũ vào kho.
                            try (PreparedStatement ps =
                                    conn.prepareStatement(addStockSql)) {
                                ps.setInt(1, quantity);
                                ps.setInt(2, originalSkuId);

                                if (ps.executeUpdate() != 1) {
                                    throw new SQLException(
                                            "Không cập nhật được tồn kho hàng trả.");
                                }
                            }
                        } else {
                            Integer exchangeSkuId =
                                    (Integer) item.get("exchangeSkuId");

                            if (exchangeSkuId == null
                                    || exchangeSkuId == originalSkuId) {
                                throw new SQLException(
                                        "SKU đổi không hợp lệ.");
                            }

                            // Đảm bảo SKU mới thuộc cùng sản phẩm.
                            try (PreparedStatement ps =
                                    conn.prepareStatement(getTargetSql)) {
                                ps.setInt(1, exchangeSkuId);

                                try (ResultSet rs = ps.executeQuery()) {
                                    if (!rs.next()
                                            || rs.getInt("product_id")
                                            != originalProductId) {
                                        throw new SQLException(
                                                "SKU đổi phải thuộc cùng sản phẩm.");
                                    }
                                }
                            }

                            // Trừ SKU mới trước, chỉ khi kho đủ số lượng.
                            try (PreparedStatement ps =
                                    conn.prepareStatement(subtractStockSql)) {
                                ps.setInt(1, quantity);
                                ps.setInt(2, exchangeSkuId);
                                ps.setInt(3, quantity);

                                if (ps.executeUpdate() != 1) {
                                    throw new SQLException(
                                            "SKU đổi không đủ tồn kho.");
                                }
                            }

                            // Cộng SKU cũ trở lại kho.
                            try (PreparedStatement ps =
                                    conn.prepareStatement(addStockSql)) {
                                ps.setInt(1, quantity);
                                ps.setInt(2, originalSkuId);

                                if (ps.executeUpdate() != 1) {
                                    throw new SQLException(
                                            "Không cập nhật được tồn kho SKU cũ.");
                                }
                            }
                        }
                    }
                }

                // Cập nhật trạng thái sau khi cập nhật tồn kho thành công.
                try (PreparedStatement ps =
                        conn.prepareStatement(updateRequestSql)) {
                    ps.setString(1, newStatus);
                    ps.setInt(2, staffId);
                    ps.setString(3, staffNote == null
                            ? null : staffNote.trim());
                    ps.setInt(4, requestId);

                    if (ps.executeUpdate() != 1) {
                        throw new SQLException(
                                "Không cập nhật được trạng thái yêu cầu.");
                    }
                }

                // Ghi lịch sử trong cùng transaction.
                try (PreparedStatement ps =
                        conn.prepareStatement(historySql)) {
                    ps.setInt(1, requestId);
                    ps.setString(2, newStatus);
                    ps.setInt(3, staffId);
                    ps.setString(4, staffNote == null
                            ? "" : staffNote.trim());
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
