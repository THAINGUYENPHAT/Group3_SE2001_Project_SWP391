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

    private static final String COMPLETED_CONDITION
            = " o.order_status = 'COMPLETED' ";

    private static final String RETURN_EXCLUSION_CONDITION
            = " AND NOT EXISTS ("
            + " SELECT 1 "
            + " FROM dbo.RETURN_REQUEST rr "
            + " WHERE rr.order_id = o.order_id "
            + " AND rr.request_status = 'APPROVED' "
            + ") ";

    public BigDecimal getTotalRevenueByRange(
            LocalDate startDate,
            LocalDate endDate) {

        String sql
                = "SELECT ISNULL(SUM(o.total_amount), 0) "
                + "AS total_revenue "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION
                + RETURN_EXCLUSION_CONDITION;

        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            setDateRange(
                    ps,
                    startDate,
                    endDate
            );

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    BigDecimal result
                            = rs.getBigDecimal("total_revenue");

                    return result != null
                            ? result
                            : BigDecimal.ZERO;
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error getting total revenue",
                    ex
            );
        }

        return BigDecimal.ZERO;
    }

    public int getCompletedOrdersByRange(
            LocalDate startDate,
            LocalDate endDate) {

        String sql
                = "SELECT COUNT(*) AS total_orders "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION
                + RETURN_EXCLUSION_CONDITION;

        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            setDateRange(
                    ps,
                    startDate,
                    endDate
            );

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt("total_orders");
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error getting completed orders",
                    ex
            );
        }

        return 0;
    }

    public int getTotalProductsSoldByRange(
            LocalDate startDate,
            LocalDate endDate) {

        String sql
                = "SELECT ISNULL(SUM(oi.quantity), 0) "
                + "AS total_products "
                + "FROM dbo.ORDER_ITEM oi "
                + "INNER JOIN dbo.[ORDER] o "
                + "ON oi.order_id = o.order_id "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION
                + RETURN_EXCLUSION_CONDITION;

        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            setDateRange(
                    ps,
                    startDate,
                    endDate
            );

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt("total_products");
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error getting products sold",
                    ex
            );
        }

        return 0;
    }

    public List<Object[]> getRevenueByDateRange(
            LocalDate startDate,
            LocalDate endDate) {

        List<Object[]> list = new ArrayList<>();

        String sql
                = "SELECT "
                + "CAST(o.created_at AS DATE) AS report_date, "
                + "SUM(o.total_amount) AS revenue, "
                + "COUNT(*) AS order_count "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "AND " + COMPLETED_CONDITION
                + RETURN_EXCLUSION_CONDITION
                + "GROUP BY CAST(o.created_at AS DATE) "
                + "ORDER BY report_date DESC";

        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            setDateRange(
                    ps,
                    startDate,
                    endDate
            );

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    list.add(new Object[]{
                        rs.getDate("report_date"),
                        rs.getBigDecimal("revenue"),
                        rs.getInt("order_count")
                    });
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error getting revenue by date",
                    ex
            );
        }

        return list;
    }

    public static BigDecimal calculateAverageOrderValue(
            BigDecimal revenue,
            int completedOrders) {

        if (completedOrders == 0) {
            return BigDecimal.ZERO;
        }

        return revenue.divide(
                BigDecimal.valueOf(completedOrders),
                2,
                RoundingMode.HALF_UP
        );
    }

    public List<Object[]> getOrderStatusByRange(
            LocalDate startDate,
            LocalDate endDate) {

        List<Object[]> list = new ArrayList<>();

        String sql
                = "SELECT "
                + "o.order_status, "
                + "COUNT(*) AS total "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + RETURN_EXCLUSION_CONDITION
                + "GROUP BY o.order_status "
                + "ORDER BY total DESC";

        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            setDateRange(
                    ps,
                    startDate,
                    endDate
            );

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    list.add(new Object[]{
                        rs.getString("order_status"),
                        rs.getInt("total")
                    });
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error getting order statuses",
                    ex
            );
        }

        return list;
    }

    public List<Object[]> getTopSellingProductsByRange(
            LocalDate startDate,
            LocalDate endDate) {

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
                + "AND " + COMPLETED_CONDITION
                + RETURN_EXCLUSION_CONDITION
                + "GROUP BY p.product_id, p.product_name "
                + "ORDER BY total_sold DESC, "
                + "p.product_name ASC";

        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            setDateRange(
                    ps,
                    startDate,
                    endDate
            );

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    list.add(new Object[]{
                        rs.getString("product_name"),
                        rs.getInt("total_sold")
                    });
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error getting top selling products",
                    ex
            );
        }

        return list;
    }

    private void setDateRange(
            PreparedStatement ps,
            LocalDate startDate,
            LocalDate endDate) throws SQLException {

        ps.setDate(
                1,
                java.sql.Date.valueOf(startDate)
        );

        ps.setDate(
                2,
                java.sql.Date.valueOf(endDate.plusDays(1))
        );
    }
}
