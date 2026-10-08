package dao;

import db.DBContext;

import java.math.BigDecimal;
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

    // =========================================================
    // COMMON CONDITION
    // Chỉ tính những đơn đang có trạng thái COMPLETED
    // =========================================================
    private static final String COMPLETED_CONDITION
            = " o.order_status = 'COMPLETED' ";

    // =========================================================
    // 1. TỔNG DOANH THU TRONG KHOẢNG NGÀY
    // =========================================================
    public BigDecimal getTotalRevenueByRange(
            LocalDate startDate,
            LocalDate endDate) {

        String sql
                = "SELECT ISNULL(SUM(o.total_amount), 0) AS total_revenue "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getRevenueByRange(
                sql,
                startDate,
                endDate.plusDays(1)
        );
    }

    // =========================================================
    // 2. ĐẾM ĐƠN HOÀN THÀNH TRONG KHOẢNG NGÀY
    // =========================================================
    public int getCompletedOrdersByRange(
            LocalDate startDate,
            LocalDate endDate) {

        String sql
                = "SELECT COUNT(*) AS total_orders "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getCountByRange(
                sql,
                startDate,
                endDate.plusDays(1)
        );
    }

    // =========================================================
    // 3. TỔNG SẢN PHẨM ĐÃ BÁN TRONG KHOẢNG NGÀY
    // =========================================================
    public int getTotalProductsSoldByRange(
            LocalDate startDate,
            LocalDate endDate) {

        String sql
                = "SELECT ISNULL(SUM(oi.quantity), 0) AS total_products "
                + "FROM ORDER_ITEM oi "
                + "INNER JOIN dbo.[ORDER] o "
                + "    ON oi.order_id = o.order_id "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION;

        return getProductsByRange(
                sql,
                startDate,
                endDate.plusDays(1)
        );
    }

    // =========================================================
    // 4. DOANH THU THEO TỪNG NGÀY TRONG KHOẢNG
    // =========================================================
    public List<Object[]> getRevenueByDateRange(
            LocalDate startDate,
            LocalDate endDate) {

        return getRevenueReport(
                startDate,
                endDate.plusDays(1),
                "CAST(o.created_at AS DATE)"
        );
    }

    // =========================================================
    // 5. HELPER - DOANH THU
    // =========================================================
    private BigDecimal getRevenueByRange(
            String sql,
            LocalDate startDate,
            LocalDate endDate) {

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, startDate);
            ps.setObject(2, endDate);

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
    // 6. HELPER - ĐẾM ĐƠN
    // =========================================================
    private int getCountByRange(
            String sql,
            LocalDate startDate,
            LocalDate endDate) {

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, startDate);
            ps.setObject(2, endDate);

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
    // 7. HELPER - SẢN PHẨM ĐÃ BÁN
    // =========================================================
    private int getProductsByRange(
            String sql,
            LocalDate startDate,
            LocalDate endDate) {

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, startDate);
            ps.setObject(2, endDate);

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
    // 8. REPORT THEO NGÀY
    // =========================================================
    private List<Object[]> getRevenueReport(
            LocalDate startDate,
            LocalDate endDate,
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
                + "AND " + COMPLETED_CONDITION + " "
                + "GROUP BY " + groupExpression + " "
                + "ORDER BY report_date DESC";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, startDate);
            ps.setObject(2, endDate);

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
