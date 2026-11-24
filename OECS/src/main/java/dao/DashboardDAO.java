package dao;

import db.DBContext;
import model.OrderStatistics;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class DashboardDAO extends DBContext {

    public OrderStatistics getOrderStatistics(LocalDate start, LocalDate end, boolean byMonth) {
        LocalDate endExclusive = end.plusDays(1);
        OrderStatistics statistics = new OrderStatistics();
        try (Connection conn = getConnection()) {
            if (conn == null) {
                throw new SQLException("Không kết nối được SQL Server.");
            }
            conn.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            conn.setAutoCommit(false);
            try {
                loadOrderCounts(conn, start, endExclusive, statistics);
                loadRevenue(conn, start, endExclusive, byMonth, statistics);
                loadTopProducts(conn, start, endExclusive, statistics);
                conn.commit();
                return statistics;
            } catch (SQLException | RuntimeException e) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    e.addSuppressed(rollbackError);
                }
                throw e;
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Không thể tải thống kê Dashboard.", e);
        }
    }

    private void loadOrderCounts(Connection conn, LocalDate start, LocalDate endExclusive,
            OrderStatistics statistics) throws SQLException {
        String sql = "SELECT COUNT(*) AS total_orders, "
                + "COUNT(CASE WHEN order_status = 'COMPLETED' THEN 1 END) AS completed_orders, "
                + "COUNT(CASE WHEN order_status = 'CANCELLED' THEN 1 END) AS cancelled_orders "
                + "FROM dbo.[ORDER] WHERE created_at >= ? AND created_at < ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setDateRange(ps, start, endExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                statistics.setTotalOrders(rs.getInt("total_orders"));
                statistics.setCompletedOrders(rs.getInt("completed_orders"));
                statistics.setCancelledOrders(rs.getInt("cancelled_orders"));
            }
        }
    }

    private void loadRevenue(Connection conn, LocalDate start, LocalDate endExclusive,
            boolean byMonth, OrderStatistics statistics) throws SQLException {
        String period = byMonth ? "CONVERT(CHAR(7), created_at, 126)" : "CAST(created_at AS DATE)";
        String sql = "SELECT " + period + " AS sale_period, SUM(total_amount) AS revenue "
                + "FROM dbo.[ORDER] WHERE created_at >= ? AND created_at < ? "
                + "AND order_status = 'COMPLETED' AND payment_status = 'PAID' "
                + "GROUP BY " + period + " ORDER BY sale_period";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setDateRange(ps, start, endExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BigDecimal revenue = rs.getBigDecimal("revenue");
                    Object label = byMonth ? rs.getString("sale_period") : rs.getDate("sale_period");
                    statistics.addRevenueRow(new Object[]{label, revenue});
                    statistics.setRevenue(statistics.getRevenue().add(revenue));
                }
            }
        }
    }

    private void loadTopProducts(Connection conn, LocalDate start, LocalDate endExclusive,
            OrderStatistics statistics) throws SQLException {
        String sql = "SELECT TOP 5 p.product_name, p.image_url, prices.min_price, "
                + "SUM(CAST(oi.quantity AS BIGINT)) AS sold "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.[ORDER] o ON o.order_id = oi.order_id "
                + "JOIN dbo.PRODUCT_SKU s ON s.sku_id = oi.sku_id "
                + "JOIN dbo.PRODUCT p ON p.product_id = s.product_id "
                + "JOIN (SELECT product_id, MIN(price) AS min_price "
                + "FROM dbo.PRODUCT_SKU GROUP BY product_id) prices ON prices.product_id = p.product_id "
                + "WHERE o.created_at >= ? AND o.created_at < ? "
                + "AND o.order_status = 'COMPLETED' AND o.payment_status = 'PAID' "
                + "GROUP BY p.product_id, p.product_name, p.image_url, prices.min_price "
                + "HAVING SUM(CAST(oi.quantity AS BIGINT)) > 0 "
                + "ORDER BY sold DESC, p.product_id";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setDateRange(ps, start, endExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    statistics.addTopProduct(new Object[]{
                        rs.getString("product_name"), rs.getString("image_url"),
                        rs.getBigDecimal("min_price"), Math.toIntExact(rs.getLong("sold"))
                    });
                }
            }
        }
    }

    private void setDateRange(PreparedStatement ps, LocalDate start, LocalDate endExclusive) throws SQLException {
        ps.setDate(1, Date.valueOf(start));
        ps.setDate(2, Date.valueOf(endExclusive));
        ps.setQueryTimeout(30);
    }

    // Thống kê số SKU theo tồn kho thực tế.
    // Trên 5: đủ hàng; 1-5: sắp hết; 0: hết hàng.
    public Map<String, Integer> getCurrentStockStatistics() {
        String sql = "SELECT "
                + "COALESCE(SUM(CASE WHEN stock_quantity > 5 "
                + "THEN 1 ELSE 0 END), 0) AS in_stock, "
                + "COALESCE(SUM(CASE WHEN stock_quantity BETWEEN 1 AND 5 "
                + "THEN 1 ELSE 0 END), 0) AS low_stock, "
                + "COALESCE(SUM(CASE WHEN stock_quantity = 0 "
                + "THEN 1 ELSE 0 END), 0) AS out_stock, "
                + "COALESCE(SUM(stock_quantity), 0) AS total_stock, "
                + "COALESCE(SUM(reserved_quantity), 0) AS total_reserved "
                + "FROM dbo.PRODUCT_SKU";

        try (Connection conn = getConnection()) {
            if (conn == null) {
                throw new SQLException("Không kết nối được SQL Server.");
            }
            try (PreparedStatement ps = conn.prepareStatement(sql);
                    ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int totalStock = rs.getInt("total_stock");
                    int reservedStock = rs.getInt("total_reserved");
                    return Map.of(
                            "stockAvailable", rs.getInt("in_stock"),
                            "stockLow", rs.getInt("low_stock"),
                            "stockOut", rs.getInt("out_stock"),
                            "totalStock", totalStock,
                            "reservedStock", reservedStock,
                            "sellableStock", totalStock - reservedStock);
                }
                throw new SQLException("Không đọc được thống kê tồn kho.");
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Không thể tải thống kê tồn kho.", e);
        }
    }

    // Đơn đang chờ Staff xử lý hoặc đang được chuẩn bị, không giới hạn ngày.
    public Map<String, Integer> getProcessingOrderStatistics() {
        String sql = "SELECT "
                + "COUNT(CASE WHEN order_status = 'PENDING_CONFIRMATION' THEN 1 END) AS pending, "
                + "COUNT(CASE WHEN order_status = 'CONFIRMED' THEN 1 END) AS confirmed, "
                + "COUNT(CASE WHEN order_status = 'PACKING' THEN 1 END) AS packing "
                + "FROM dbo.[ORDER] "
                + "WHERE order_status IN ('PENDING_CONFIRMATION', 'CONFIRMED', 'PACKING')";
        try (Connection conn = getConnection()) {
            if (conn == null) {
                throw new SQLException("Không kết nối được SQL Server.");
            }
            try (PreparedStatement ps = conn.prepareStatement(sql);
                    ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int pending = rs.getInt("pending");
                    int confirmed = rs.getInt("confirmed");
                    int packing = rs.getInt("packing");
                    return Map.of(
                            "pendingOrders", pending,
                            "confirmedOrders", confirmed,
                            "packingOrders", packing,
                            "processingOrders", pending + confirmed + packing);
                }
                throw new SQLException("Không đọc được số đơn đang xử lý.");
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Không thể đếm đơn đang xử lý.", e);
        }
    }

    // Danh sách SKU có tồn kho thực tế từ 0 đến 5.
    public List<Object[]> getLowStockProducts() {
        List<Object[]> products = new ArrayList<>();
        String sql = "SELECT s.sku_code, p.product_name, p.image_url, "
                + "s.stock_quantity, s.price "
                + "FROM dbo.PRODUCT_SKU s "
                + "JOIN dbo.PRODUCT p ON p.product_id = s.product_id "
                + "WHERE s.stock_quantity <= 5 "
                + "ORDER BY s.stock_quantity, p.product_name, s.sku_code";

        try (Connection conn = getConnection()) {
            if (conn == null) {
                throw new SQLException("Không kết nối được SQL Server.");
            }
            try (PreparedStatement ps = conn.prepareStatement(sql);
                    ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    products.add(new Object[]{rs.getString("sku_code"),
                        rs.getString("product_name"), rs.getString("image_url"),
                        rs.getInt("stock_quantity"), rs.getBigDecimal("price")});
                }
            }
            return products;
        } catch (SQLException e) {
            throw new IllegalStateException("Không thể tải danh sách tồn kho thấp.", e);
        }
    }
}
