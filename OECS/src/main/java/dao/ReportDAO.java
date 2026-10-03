package dao;

import db.DBContext;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class ReportDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(ReportDAO.class.getName());

    // =========================================================
    // COMMON SQL
    // Chỉ tính những đơn có trạng thái mới nhất = Completed
    // =========================================================
    private static final String COMPLETED_CONDITION
            = " EXISTS ( "
            + "     SELECT 1 "
            + "     FROM ORDER_STATUS_HISTORY h "
            + "     WHERE h.order_id = o.order_id "
            + "       AND h.status = 'Completed' "
            + "       AND NOT EXISTS ( "
            + "           SELECT 1 "
            + "           FROM ORDER_STATUS_HISTORY h2 "
            + "           WHERE h2.order_id = h.order_id "
            + "             AND (h2.updated_at > h.updated_at "
            + "                  OR (h2.updated_at = h.updated_at "
            + "                      AND h2.status_id > h.status_id)) "
            + "       ) "
            + " ) ";

    // =========================================================
    // 1. TỔNG DOANH THU
    // =========================================================
    public BigDecimal getTotalRevenue() {

        String sql
                = "SELECT ISNULL(SUM(o.total_amount), 0) AS total_revenue "
                + "FROM dbo.[ORDER] o "
                + "WHERE " + COMPLETED_CONDITION;

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getBigDecimal("total_revenue");
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi lấy tổng doanh thu!", e);
        }

        return BigDecimal.ZERO;
    }

    // =========================================================
    // 2. ĐƠN HOÀN THÀNH
    // =========================================================
    public int getCompletedOrders() {

        String sql
                = "SELECT COUNT(*) AS completed_orders "
                + "FROM dbo.[ORDER] o "
                + "WHERE " + COMPLETED_CONDITION;

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt("completed_orders");
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi đếm đơn hàng hoàn thành!", e);
        }

        return 0;
    }

    // =========================================================
    // 3. SẢN PHẨM ĐÃ BÁN
    // =========================================================
    public int getTotalProductsSold() {

        String sql
                = "SELECT ISNULL(SUM(oi.quantity), 0) AS total_products "
                + "FROM ORDER_ITEM oi "
                + "INNER JOIN dbo.[ORDER] o "
                + "    ON oi.order_id = o.order_id "
                + "WHERE " + COMPLETED_CONDITION;

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt("total_products");
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi lấy tổng sản phẩm đã bán!", e);
        }

        return 0;
    }

    // =========================================================
    // 4. THEO NGÀY
    // =========================================================
    public BigDecimal getTotalRevenueByDay(LocalDate date) {

        String sql
                = "SELECT ISNULL(SUM(o.total_amount), 0) AS total_revenue "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getRevenueByRange(sql, date, date.plusDays(1));
    }

    public int getCompletedOrdersByDay(LocalDate date) {

        String sql
                = "SELECT COUNT(*) AS total_orders "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getCountByRange(sql, date, date.plusDays(1));
    }

    public int getTotalProductsSoldByDay(LocalDate date) {

        String sql
                = "SELECT ISNULL(SUM(oi.quantity), 0) AS total_products "
                + "FROM ORDER_ITEM oi "
                + "INNER JOIN dbo.[ORDER] o "
                + "    ON oi.order_id = o.order_id "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getProductsByRange(sql, date, date.plusDays(1));
    }

    public List<Object[]> getRevenueByDay(LocalDate date) {

        return getRevenueReport(
                date,
                date.plusDays(1),
                "CAST(o.created_at AS DATE)"
        );
    }

    // =========================================================
    // 5. THEO TUẦN
    // Tuần bắt đầu từ THỨ 2
    // =========================================================
    public BigDecimal getTotalRevenueByWeek(LocalDate date) {

        LocalDate start = date.with(DayOfWeek.MONDAY);
        LocalDate end = start.plusDays(7);

        String sql
                = "SELECT ISNULL(SUM(o.total_amount), 0) AS total_revenue "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getRevenueByRange(sql, start, end);
    }

    public int getCompletedOrdersByWeek(LocalDate date) {

        LocalDate start = date.with(DayOfWeek.MONDAY);
        LocalDate end = start.plusDays(7);

        String sql
                = "SELECT COUNT(*) AS total_orders "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getCountByRange(sql, start, end);
    }

    public int getTotalProductsSoldByWeek(LocalDate date) {

        LocalDate start = date.with(DayOfWeek.MONDAY);
        LocalDate end = start.plusDays(7);

        String sql
                = "SELECT ISNULL(SUM(oi.quantity), 0) AS total_products "
                + "FROM ORDER_ITEM oi "
                + "INNER JOIN dbo.[ORDER] o "
                + "    ON oi.order_id = o.order_id "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getProductsByRange(sql, start, end);
    }

    public List<Object[]> getRevenueByWeek(LocalDate date) {

        LocalDate start = date.with(DayOfWeek.MONDAY);
        LocalDate end = start.plusDays(7);

        return getRevenueReport(
                start,
                end,
                "CAST(o.created_at AS DATE)"
        );
    }

    // =========================================================
    // 6. THEO THÁNG
    // =========================================================
    public BigDecimal getTotalRevenueByMonth(LocalDate date) {

        LocalDate start = date.withDayOfMonth(1);
        LocalDate end = start.plusMonths(1);

        String sql
                = "SELECT ISNULL(SUM(o.total_amount), 0) AS total_revenue "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getRevenueByRange(sql, start, end);
    }

    public int getCompletedOrdersByMonth(LocalDate date) {

        LocalDate start = date.withDayOfMonth(1);
        LocalDate end = start.plusMonths(1);

        String sql
                = "SELECT COUNT(*) AS total_orders "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getCountByRange(sql, start, end);
    }

    public int getTotalProductsSoldByMonth(LocalDate date) {

        LocalDate start = date.withDayOfMonth(1);
        LocalDate end = start.plusMonths(1);

        String sql
                = "SELECT ISNULL(SUM(oi.quantity), 0) AS total_products "
                + "FROM ORDER_ITEM oi "
                + "INNER JOIN dbo.[ORDER] o "
                + "    ON oi.order_id = o.order_id "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getProductsByRange(sql, start, end);
    }

    public List<Object[]> getRevenueByMonth(LocalDate date) {

        LocalDate start = date.withDayOfMonth(1);
        LocalDate end = start.plusMonths(1);

        return getRevenueReport(
                start,
                end,
                "CAST(o.created_at AS DATE)"
        );
    }

    // =========================================================
    // 7. THEO NĂM
    // =========================================================
    public BigDecimal getTotalRevenueByYear(LocalDate date) {

        LocalDate start = LocalDate.of(
                date.getYear(), 1, 1);

        LocalDate end = start.plusYears(1);

        String sql
                = "SELECT ISNULL(SUM(o.total_amount), 0) AS total_revenue "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getRevenueByRange(sql, start, end);
    }

    public int getCompletedOrdersByYear(LocalDate date) {

        LocalDate start = LocalDate.of(
                date.getYear(), 1, 1);

        LocalDate end = start.plusYears(1);

        String sql
                = "SELECT COUNT(*) AS total_orders "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getCountByRange(sql, start, end);
    }

    public int getTotalProductsSoldByYear(LocalDate date) {

        LocalDate start = LocalDate.of(
                date.getYear(), 1, 1);

        LocalDate end = start.plusYears(1);

        String sql
                = "SELECT ISNULL(SUM(oi.quantity), 0) AS total_products "
                + "FROM ORDER_ITEM oi "
                + "INNER JOIN dbo.[ORDER] o "
                + "    ON oi.order_id = o.order_id "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getProductsByRange(sql, start, end);
    }

    public List<Object[]> getRevenueByYear(LocalDate date) {

        LocalDate start = LocalDate.of(
                date.getYear(), 1, 1);

        LocalDate end = start.plusYears(1);

        return getRevenueReport(
                start,
                end,
                "MONTH(o.created_at)"
        );
    }

    // =========================================================
    // 8. HELPER - DOANH THU
    // =========================================================
    private BigDecimal getRevenueByRange(
            String sql,
            LocalDate start,
            LocalDate end) {

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, start);
            ps.setObject(2, end);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    BigDecimal result
                            = rs.getBigDecimal("total_revenue");

                    return result != null
                            ? result
                            : BigDecimal.ZERO;
                }
            }

        } catch (SQLException e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy doanh thu theo khoảng thời gian!",
                    e
            );
        }

        return BigDecimal.ZERO;
    }

    // =========================================================
    // 9. HELPER - ĐẾM ĐƠN
    // =========================================================
    private int getCountByRange(
            String sql,
            LocalDate start,
            LocalDate end) {

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, start);
            ps.setObject(2, end);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt("total_orders");
                }
            }

        } catch (SQLException e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi đếm đơn hàng theo khoảng thời gian!",
                    e
            );
        }

        return 0;
    }

    // =========================================================
    // 10. HELPER - SẢN PHẨM
    // =========================================================
    private int getProductsByRange(
            String sql,
            LocalDate start,
            LocalDate end) {

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, start);
            ps.setObject(2, end);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt("total_products");
                }
            }

        } catch (SQLException e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy sản phẩm đã bán theo khoảng thời gian!",
                    e
            );
        }

        return 0;
    }

    // =========================================================
    // 11. HELPER - REPORT THEO NGÀY / THÁNG
    // =========================================================
    private List<Object[]> getRevenueReport(
            LocalDate start,
            LocalDate end,
            String groupExpression) {

        List<Object[]> list = new ArrayList<>();

        String sql
                = "SELECT "
                + groupExpression + " AS report_date, "
                + "SUM(o.total_amount) AS revenue, "
                + "COUNT(*) AS order_count "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION
                + "GROUP BY "
                + groupExpression + " "
                + "ORDER BY report_date DESC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, start);
            ps.setObject(2, end);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Object[] row = new Object[3];

                    row[0] = rs.getObject("report_date");
                    row[1] = rs.getBigDecimal("revenue");
                    row[2] = rs.getInt("order_count");

                    list.add(row);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy báo cáo doanh thu!",
                    e
            );
        }

        return list;
    }
}
