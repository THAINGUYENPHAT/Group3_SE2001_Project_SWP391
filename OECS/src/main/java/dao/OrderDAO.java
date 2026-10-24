package dao;

import db.DBContext;
import db.CheckoutConnectionFactory;
import model.Order;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.LinkedHashMap;
import java.util.Collections;

public class OrderDAO {
    private final CheckoutConnectionFactory connections;

    public OrderDAO() {
        this(() -> new DBContext().getConnection());
    }

    public OrderDAO(CheckoutConnectionFactory connections) {
        this.connections = connections;
    }

    // Servlet instances are shared across requests; never share a JDBC connection.
    private Connection getConnection() throws SQLException {
        Connection conn = connections.open();
        if (conn == null) throw new SQLException("Khong ket noi duoc database.");
        return conn;
    }

    public List<Order> findByUser(int userId) throws SQLException {
        try (Connection conn = getConnection()) {
            return findByUser(conn, userId);
        }
    }

    private static final String PURCHASE_SEARCH = " FROM dbo.[ORDER] o WHERE o.user_id = ? "
            + "AND (? = N'' OR CONVERT(varchar(20), o.order_id) = ? OR EXISTS ("
            + "SELECT 1 FROM dbo.ORDER_ITEM si JOIN dbo.PRODUCT_SKU ss ON ss.sku_id = si.sku_id "
            + "JOIN dbo.PRODUCT sp ON sp.product_id = ss.product_id WHERE si.order_id = o.order_id "
            + "AND (sp.product_name LIKE ? ESCAPE '\\' OR ss.sku_code LIKE ? ESCAPE '\\'))) ";

    private int bindPurchaseSearch(PreparedStatement ps, int userId, String query) throws SQLException {
        String text = query == null ? "" : query.trim();
        String pattern = "%" + text.replace("\\", "\\\\").replace("%", "\\%")
                .replace("_", "\\_").replace("[", "\\[") + "%";
        ps.setInt(1, userId);
        ps.setNString(2, text);
        ps.setString(3, text.startsWith("#") ? text.substring(1) : text);
        ps.setNString(4, pattern);
        ps.setNString(5, pattern);
        return 6;
    }

    public Map<String, Long> countPurchasesByStatus(int userId, String query) throws SQLException {
        Map<String, Long> counts = new LinkedHashMap<>();
        String sql = "SELECT o.order_status, COUNT_BIG(*) AS total" + PURCHASE_SEARCH + "GROUP BY o.order_status";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            bindPurchaseSearch(ps, userId, query);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) counts.put(rs.getString("order_status"), rs.getLong("total"));
            }
        }
        return counts;
    }

    public List<Order> findPurchasePage(int userId, String query, List<String> statuses,
            long offset, int pageSize) throws SQLException {
        if (offset < 0 || pageSize < 1 || pageSize > 50) throw new IllegalArgumentException("Invalid page");
        String statusFilter = statuses.isEmpty() ? "" : "AND UPPER(LTRIM(RTRIM(o.order_status))) IN ("
                + String.join(",", Collections.nCopies(statuses.size(), "?")) + ") ";
        String sql = "SELECT o.*" + PURCHASE_SEARCH + statusFilter
                + "ORDER BY o.created_at DESC, o.order_id DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
        List<Order> result = new ArrayList<>();
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            int index = bindPurchaseSearch(ps, userId, query);
            for (String status : statuses) ps.setString(index++, status);
            ps.setLong(index++, offset);
            ps.setInt(index, pageSize);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapOrder(rs));
            }
        }
        return result;
    }

    // One query for all visible cards; ownership is checked even for supplied IDs.
    public Map<Integer, List<Map<String, Object>>> findItemsForOrders(int userId, List<Integer> ids) throws SQLException {
        Map<Integer, List<Map<String, Object>>> result = new LinkedHashMap<>();
        if (ids.isEmpty()) return result;
        if (ids.size() > 50) throw new IllegalArgumentException("Too many orders");
        String sql = "SELECT i.order_id, i.sku_id, i.price, i.quantity, s.sku_code, p.product_name "
                + "FROM dbo.ORDER_ITEM i JOIN dbo.[ORDER] o ON o.order_id = i.order_id "
                + "LEFT JOIN dbo.PRODUCT_SKU s ON s.sku_id = i.sku_id "
                + "LEFT JOIN dbo.PRODUCT p ON p.product_id = s.product_id WHERE o.user_id = ? "
                + "AND o.order_id IN (" + String.join(",", Collections.nCopies(ids.size(), "?"))
                + ") ORDER BY i.order_id, i.order_item_id";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            for (int i = 0; i < ids.size(); i++) ps.setInt(i + 2, ids.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("skuId", rs.getInt("sku_id"));
                    item.put("skuCode", rs.getString("sku_code"));
                    item.put("productName", rs.getString("product_name"));
                    item.put("price", rs.getBigDecimal("price"));
                    item.put("quantity", rs.getInt("quantity"));
                    result.computeIfAbsent(rs.getInt("order_id"), key -> new ArrayList<>()).add(item);
                }
            }
        }
        return result;
    }

    // GIU HAM CU DE ORDERSERVICE HIEN TAI VAN GOI DUOC
    public int insert(Connection conn, Order order) throws SQLException {
        return insert(conn, order, null);
    }

    // TAO DON HANG CO TOKEN CHONG TRUNG
    public int insert(
            Connection conn,
            Order order,
            String checkoutToken
    ) throws SQLException {

        String sql = "INSERT INTO dbo.[ORDER] "
                + "(user_id, address_id, total_amount, shipping_fee, "
                + "order_status, payment_method, payment_status, "
                + "recipient_name, recipient_phone, shipping_address, "
                + "discount_amount, checkout_token) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(
                sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, order.getUserId());
            ps.setInt(2, order.getAddressId());
            ps.setBigDecimal(3, order.getTotalAmount());
            ps.setBigDecimal(4, order.getShippingFee());
            ps.setString(5, order.getOrderStatus());
            ps.setString(6, order.getPaymentMethod());
            ps.setString(7, order.getPaymentStatus());
            ps.setString(8, order.getRecipientName());
            ps.setString(9, order.getRecipientPhone());
            ps.setString(10, order.getShippingAddress());
            ps.setBigDecimal(11, order.getDiscountAmount());
            ps.setString(12, checkoutToken);

            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (!rs.next()) {
                    throw new SQLException(
                            "Khong lay duoc ma don hang."
                    );
                }

                return rs.getInt(1);
            }
        }
    }

    // LUU CHI TIET DON HANG
    public void insertItem(
            Connection conn,
            int orderId,
            int skuId,
            BigDecimal price,
            int quantity
    ) throws SQLException {

        String sql = "INSERT INTO dbo.ORDER_ITEM "
                + "(order_id, sku_id, price, quantity) "
                + "VALUES (?, ?, ?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, skuId);
            ps.setBigDecimal(3, price);
            ps.setInt(4, quantity);

            ps.executeUpdate();
        }
    }

    // LUU LICH SU TRANG THAI
    public void addHistory(
            Connection conn,
            int orderId,
            String status
    ) throws SQLException {

        String sql = "INSERT INTO dbo.ORDER_STATUS_HISTORY "
                + "(order_id, status) VALUES (?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setString(2, status);

            ps.executeUpdate();
        }
    }

    // TIM DON DA TAO BANG TOKEN TRONG TRANSACTION
    public Integer findIdByToken(
            Connection conn,
            int userId,
            String checkoutToken
    ) throws SQLException {

        String sql = "SELECT order_id "
                + "FROM dbo.[ORDER] "
                + "WHERE user_id = ? AND checkout_token = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setString(2, checkoutToken);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("order_id");
                }

                return null;
            }
        }
    }

    // TIM DON BANG TOKEN KHI GOI TU SERVLET
    public Integer findIdByToken(
            int userId,
            String checkoutToken
    ) throws SQLException {

        try (Connection conn = getConnection()) {
            if (conn == null) {
                throw new SQLException(
                        "Khong ket noi duoc database."
                );
            }

            return findIdByToken(conn, userId, checkoutToken);
        }
    }

    // LAY DON THEO ID VA KIEM TRA CHU SO HUU
    public Order findByIdAndUser(
            int orderId,
            int userId
    ) throws SQLException {

        String sql = "SELECT * FROM dbo.[ORDER] "
                + "WHERE order_id = ? AND user_id = ?";

        try (Connection conn = getConnection()) {
            if (conn == null) {
                throw new SQLException(
                        "Khong ket noi duoc database."
                );
            }

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, orderId);
                ps.setInt(2, userId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return mapOrder(rs);
                    }

                    return null;
                }
            }
        }
    }

    // LAY DANH SACH DON HANG CUA USER
    public List<Order> findByUser(
            Connection conn,
            int userId
    ) throws SQLException {

        List<Order> orders = new ArrayList<>();

        String sql = "SELECT * FROM dbo.[ORDER] "
                + "WHERE user_id = ? "
                + "ORDER BY created_at DESC, order_id DESC";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    orders.add(mapOrder(rs));
                }
            }
        }

        return orders;
    }

    // CHUYEN RESULTSET THANH OBJECT ORDER
    private Order mapOrder(ResultSet rs) throws SQLException {
        Order order = new Order();

        order.setOrderId(rs.getInt("order_id"));
        order.setUserId(rs.getInt("user_id"));
        order.setAddressId(rs.getInt("address_id"));

        order.setShippingPartnerId(
                (Integer) rs.getObject("shipping_partner_id")
        );

        order.setTotalAmount(rs.getBigDecimal("total_amount"));
        order.setShippingFee(rs.getBigDecimal("shipping_fee"));
        order.setDiscountAmount(rs.getBigDecimal("discount_amount"));

        order.setOrderStatus(rs.getString("order_status"));
        order.setPaymentMethod(rs.getString("payment_method"));
        order.setPaymentStatus(rs.getString("payment_status"));

        order.setRecipientName(rs.getString("recipient_name"));
        order.setRecipientPhone(rs.getString("recipient_phone"));
        order.setShippingAddress(rs.getString("shipping_address"));

        order.setCreatedAt(rs.getTimestamp("created_at"));
        order.setPaymentExpiresAt(
                rs.getTimestamp("payment_expires_at")
        );

        return order;
    }

    // Customer detail queries always include the authenticated owner.
    public List<Map<String, Object>> findItems(int orderId, int userId) throws SQLException {
        String sql = "SELECT i.order_item_id, i.sku_id, i.price, i.quantity, s.sku_code, p.product_name "
                + "FROM dbo.ORDER_ITEM i JOIN dbo.[ORDER] o ON o.order_id = i.order_id "
                + "LEFT JOIN dbo.PRODUCT_SKU s ON s.sku_id = i.sku_id "
                + "LEFT JOIN dbo.PRODUCT p ON p.product_id = s.product_id "
                + "WHERE o.order_id = ? AND o.user_id = ? ORDER BY i.order_item_id";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("orderItemId", rs.getInt("order_item_id"));
                    item.put("skuId", rs.getInt("sku_id"));
                    item.put("skuCode", rs.getString("sku_code"));
                    item.put("productName", rs.getString("product_name"));
                    item.put("price", rs.getBigDecimal("price"));
                    item.put("quantity", rs.getInt("quantity"));
                    items.add(item);
                }
            }
        }
        return items;
    }

    public List<Map<String, Object>> findHistory(int orderId, int userId) throws SQLException {
        String sql = "SELECT h.status, h.updated_at FROM dbo.ORDER_STATUS_HISTORY h "
                + "JOIN dbo.[ORDER] o ON o.order_id = h.order_id "
                + "WHERE o.order_id = ? AND o.user_id = ? ORDER BY h.updated_at, h.status_id";
        List<Map<String, Object>> history = new ArrayList<>();
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> entry = new LinkedHashMap<>();
                    entry.put("status", rs.getString("status"));
                    entry.put("updatedAt", rs.getTimestamp("updated_at"));
                    history.add(entry);
                }
            }
        }
        return history;
    }
}
