package dao;

import db.DBContext;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class ReportDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(ReportDAO.class.getName());

    // Chỉ tính doanh thu từ đơn đã hoàn thành
    private static final String COMPLETED_CONDITION
            = " o.order_status = 'COMPLETED' ";

    // =====================================================
    // 1. TOTAL REVENUE
    // =====================================================
    public BigDecimal getTotalRevenueByRange(
            LocalDate startDate, LocalDate endDate) {

        String sql
                = "SELECT ISNULL(SUM(o.total_amount), 0) AS total_revenue "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setDateRange(ps, startDate, endDate);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    BigDecimal result
                            = rs.getBigDecimal("total_revenue");

                    return result != null
                            ? result : BigDecimal.ZERO;
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error getting total revenue", e);
        }

        return BigDecimal.ZERO;
    }

    // =====================================================
    // 2. COMPLETED ORDERS
    // =====================================================
    public int getCompletedOrdersByRange(
            LocalDate startDate, LocalDate endDate) {

        String sql
                = "SELECT COUNT(*) AS total_orders "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setDateRange(ps, startDate, endDate);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total_orders");
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error getting completed orders", e);
        }

        return 0;
    }

    // =====================================================
    // 3. TOTAL PRODUCTS SOLD
    // =====================================================
    public int getTotalProductsSoldByRange(
            LocalDate startDate, LocalDate endDate) {

        String sql
                = "SELECT ISNULL(SUM(oi.quantity), 0) AS total_products "
                + "FROM ORDER_ITEM oi "
                + "INNER JOIN dbo.[ORDER] o "
                + "ON oi.order_id = o.order_id "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setDateRange(ps, startDate, endDate);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total_products");
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error getting products sold", e);
        }

        return 0;
    }

    // =====================================================
    // 4. REVENUE BY DATE
    // Object[]: [date, revenue, orderCount]
    // =====================================================
    public List<Object[]> getRevenueByDateRange(
            LocalDate startDate, LocalDate endDate) {

        List<Object[]> list = new ArrayList<>();

        String sql
                = "SELECT CAST(o.created_at AS DATE) AS report_date, "
                + "SUM(o.total_amount) AS revenue, "
                + "COUNT(*) AS order_count "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION
                + " GROUP BY CAST(o.created_at AS DATE) "
                + "ORDER BY report_date DESC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setDateRange(ps, startDate, endDate);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new Object[]{
                        rs.getDate("report_date"),
                        rs.getBigDecimal("revenue"),
                        rs.getInt("order_count")
                    });
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error getting revenue by date", e);
        }

        return list;
    }

    // =====================================================
    // 5. AVERAGE ORDER VALUE (AOV)
    // =====================================================
    public BigDecimal getAverageOrderValueByRange(
            LocalDate startDate, LocalDate endDate) {

        BigDecimal revenue
                = getTotalRevenueByRange(startDate, endDate);

        int orders
                = getCompletedOrdersByRange(startDate, endDate);

        if (orders == 0) {
            return BigDecimal.ZERO;
        }

        return revenue.divide(
                BigDecimal.valueOf(orders),
                2,
                RoundingMode.HALF_UP
        );
    }

    // =====================================================
    // 6. ORDER STATUS STATISTICS
    // Object[]: [status, count]
    // =====================================================
    public List<Object[]> getOrderStatusByRange(
            LocalDate startDate, LocalDate endDate) {

        List<Object[]> list = new ArrayList<>();

        String sql
                = "SELECT o.order_status, COUNT(*) AS total "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "GROUP BY o.order_status "
                + "ORDER BY total DESC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setDateRange(ps, startDate, endDate);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new Object[]{
                        rs.getString("order_status"),
                        rs.getInt("total")
                    });
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error getting order statuses", e);
        }

        return list;
    }

    // =====================================================
    // 7. TOP 5 BEST SELLING PRODUCTS
    // Object[]: [productName, quantity]
    // =====================================================
    public List<Object[]> getTopSellingProductsByRange(
            LocalDate startDate, LocalDate endDate) {

        List<Object[]> list = new ArrayList<>();

        String sql
                = "SELECT TOP 5 "
                + "p.product_name, "
                + "SUM(oi.quantity) AS total_sold "
                + "FROM dbo.ORDER_ITEM oi "
                + "INNER JOIN dbo.[ORDER] o "
                + "ON oi.order_id = o.order_id "
                + "INNER JOIN dbo.PRODUCT_SKU ps "
                + "ON oi.sku_id = ps.sku_id "
                + "INNER JOIN dbo.PRODUCT p "
                + "ON ps.product_id = p.product_id "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND o.order_status = 'COMPLETED' "
                + "GROUP BY p.product_id, p.product_name "
                + "ORDER BY total_sold DESC, p.product_name ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setDateRange(ps, startDate, endDate);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {

                    Object[] row = new Object[2];

                    row[0] = rs.getString("product_name");
                    row[1] = rs.getInt("total_sold");

                    list.add(row);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error getting top selling products", e);
        }

        return list;
    }

    // =====================================================
    // HELPER: DATE RANGE
    // Bao gồm toàn bộ ngày kết thúc
    // =====================================================
    private void setDateRange(
            PreparedStatement ps,
            LocalDate startDate,
            LocalDate endDate) throws SQLException {

        ps.setDate(1, java.sql.Date.valueOf(startDate));

        ps.setDate(2,
                java.sql.Date.valueOf(endDate.plusDays(1)));
    }
}
