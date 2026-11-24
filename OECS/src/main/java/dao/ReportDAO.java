package dao;

import db.DBContext;
import model.SalesReport;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

public class ReportDAO extends DBContext {

    // Điều kiện ghi nhận doanh thu và sản phẩm bán thành công.
    private static final String SOLD_ORDER =
            "o.order_status = 'COMPLETED' AND o.payment_status = 'PAID' ";

    // 1. Tổng hợp dữ liệu báo cáo trong cùng một transaction.
    public SalesReport loadFullReport(LocalDate start, LocalDate end) {
        LocalDate endExclusive = end.plusDays(1);
        SalesReport report = new SalesReport();

        try (Connection conn = getConnection()) {
            if (conn == null) {
                throw new SQLException("Không kết nối được SQL Server.");
            }
            conn.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            conn.setAutoCommit(false);
            try {
                loadOrderStatistics(conn, start, endExclusive, report);
                loadRevenueByDate(conn, start, endExclusive, report);
                loadProductStatistics(conn, start, endExclusive, report);
                loadInventory(conn, report);
                loadPayments(conn, start, endExclusive, report);
                conn.commit();
                return report;
            } catch (SQLException | RuntimeException e) {
                try {
                    conn.rollback();
                } catch (SQLException rollback) {
                    e.addSuppressed(rollback);
                }
                throw e;
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Không thể tải báo cáo.", e);
        }
    }

    // 2. Đếm đơn theo trạng thái, không phụ thuộc thanh toán.
    private void loadOrderStatistics(Connection conn, LocalDate start,
            LocalDate endExclusive, SalesReport report) throws SQLException {
        String sql = "SELECT o.order_status, COUNT(*) AS total "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? AND o.created_at < ? "
                + "GROUP BY o.order_status "
                + "ORDER BY total DESC, o.order_status";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setDateRange(ps, start, endExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String status = rs.getString("order_status");
                    int total = rs.getInt("total");
                    report.addStatus(new Object[]{status, total});
                    report.setTotalOrders(report.getTotalOrders() + total);
                    if ("COMPLETED".equals(status)) {
                        report.setCompletedOrders(total);
                    }
                }
            }
        }
    }

    // 3. Doanh thu theo ngày tạo đơn: COMPLETED và PAID.
    private void loadRevenueByDate(Connection conn, LocalDate start,
            LocalDate endExclusive, SalesReport report) throws SQLException {
        String sql = "SELECT CAST(o.created_at AS DATE) AS sale_date, "
                + "SUM(o.total_amount) AS revenue, COUNT(*) AS order_count "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? AND o.created_at < ? "
                + "AND " + SOLD_ORDER
                + "GROUP BY CAST(o.created_at AS DATE) "
                + "ORDER BY sale_date";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setDateRange(ps, start, endExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BigDecimal revenue = rs.getBigDecimal("revenue");
                    int count = rs.getInt("order_count");
                    report.addRevenueRow(new Object[]{
                        rs.getDate("sale_date"), revenue, count
                    });
                    report.setRevenue(report.getRevenue().add(revenue));
                    report.setRevenueOrders(report.getRevenueOrders() + count);
                }
            }
        }
    }

    // 4. Số lượng bán ban đầu của đơn hoàn thành đã thanh toán.
    // Gom tất cả SKU của cùng một sản phẩm, xếp hạng từ cao xuống thấp.
    private void loadProductStatistics(Connection conn, LocalDate start,
            LocalDate endExclusive, SalesReport report) throws SQLException {
        String sql = "SELECT p.product_name, "
                + "SUM(CAST(oi.quantity AS BIGINT)) AS sold "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.[ORDER] o ON o.order_id = oi.order_id "
                + "JOIN dbo.PRODUCT_SKU s ON s.sku_id = oi.sku_id "
                + "JOIN dbo.PRODUCT p ON p.product_id = s.product_id "
                + "WHERE o.created_at >= ? AND o.created_at < ? "
                + "AND " + SOLD_ORDER
                + "GROUP BY p.product_id, p.product_name "
                + "ORDER BY sold DESC, p.product_id";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setDateRange(ps, start, endExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int sold = Math.toIntExact(rs.getLong("sold"));
                    report.setProductsSold(Math.addExact(report.getProductsSold(), sold));
                    // Chỉ lấy 5 sản phẩm bán chạy, bỏ qua sản phẩm bán 0.
                    if (sold > 0 && report.getTopProducts().size() < 5) {
                        report.addTopProduct(new Object[]{rs.getString("product_name"), sold});
                    }
                }
            }
        }
    }

    // Tồn kho hiện tại theo SKU; không áp dụng ngày tạo đơn hàng.
    private void loadInventory(Connection conn, SalesReport report) throws SQLException {
        String sql = "SELECT s.sku_code, p.product_name, s.stock_quantity, "
                + "s.reserved_quantity, s.stock_quantity - s.reserved_quantity AS available "
                + "FROM dbo.PRODUCT_SKU s "
                + "JOIN dbo.PRODUCT p ON p.product_id = s.product_id "
                + "ORDER BY p.product_name, s.sku_code";
        try (PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                report.addInventoryRow(new Object[]{rs.getString("sku_code"),
                    rs.getString("product_name"), rs.getInt("stock_quantity"),
                    rs.getInt("reserved_quantity"), rs.getInt("available")});
            }
        }
    }

    // Thống kê theo phương thức/trạng thái thanh toán của đơn tạo trong kỳ.
    // Giá trị đơn PAID là giá trị đã ghi nhận thanh toán, không phải đối soát hoàn tiền.
    private void loadPayments(Connection conn, LocalDate start,
            LocalDate endExclusive, SalesReport report) throws SQLException {
        String sql = "SELECT o.payment_method, o.payment_status, COUNT(*) AS total, "
                + "SUM(o.total_amount) AS order_value "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? AND o.created_at < ? "
                + "GROUP BY o.payment_method, o.payment_status "
                + "ORDER BY o.payment_method, o.payment_status";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setDateRange(ps, start, endExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    report.addPaymentRow(new Object[]{rs.getString("payment_method"),
                        rs.getString("payment_status"), rs.getInt("total"),
                        rs.getBigDecimal("order_value")});
                }
            }
        }
    }

    private void setDateRange(PreparedStatement ps, LocalDate start,
            LocalDate endExclusive) throws SQLException {
        ps.setDate(1, Date.valueOf(start));
        ps.setDate(2, Date.valueOf(endExclusive));
        ps.setQueryTimeout(30);
    }
}
