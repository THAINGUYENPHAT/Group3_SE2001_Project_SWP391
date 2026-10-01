package dao;

import db.DBContext;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class DashboardDAO extends DBContext {

    // =========================
    // 1. TOTAL REVENUE
    // =========================
    public BigDecimal getTotalRevenue() {

        String sql = "SELECT ISNULL(SUM(o.total_amount), 0) "
                + "FROM [ORDER] o "
                + "JOIN ORDER_STATUS_HISTORY h "
                + "ON o.order_id = h.order_id "
                + "WHERE h.status = 'Completed' "
                + "AND h.status_id = ( "
                + "SELECT MAX(h2.status_id) "
                + "FROM ORDER_STATUS_HISTORY h2 "
                + "WHERE h2.order_id = o.order_id"
                + ")";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getBigDecimal(1);
            }

        } catch (SQLException ex) {
            Logger.getLogger(DashboardDAO.class.getName())
                    .log(Level.SEVERE, "Error getting total revenue", ex);
        }

        return BigDecimal.ZERO;
    }

    // =========================
    // 2. TOTAL ORDERS
    // =========================
    public int getTotalOrders() {

        String sql = "SELECT COUNT(*) FROM [ORDER]";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException ex) {
            Logger.getLogger(DashboardDAO.class.getName())
                    .log(Level.SEVERE, "Error getting total orders", ex);
        }

        return 0;
    }

    // =========================
    // 3. COMPLETED ORDERS
    // =========================
    public int getCompletedOrders() {

        String sql = "SELECT COUNT(*) "
                + "FROM [ORDER] o "
                + "JOIN ORDER_STATUS_HISTORY h "
                + "ON o.order_id = h.order_id "
                + "WHERE h.status = 'Completed' "
                + "AND h.status_id = ( "
                + "SELECT MAX(h2.status_id) "
                + "FROM ORDER_STATUS_HISTORY h2 "
                + "WHERE h2.order_id = o.order_id"
                + ")";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException ex) {
            Logger.getLogger(DashboardDAO.class.getName())
                    .log(Level.SEVERE, "Error getting completed orders", ex);
        }

        return 0;
    }

    // =========================
    // 4. TOTAL PRODUCTS SOLD
    // =========================
    public int getTotalProductsSold() {

        String sql = "SELECT ISNULL(SUM(oi.quantity), 0) "
                + "FROM ORDER_ITEM oi "
                + "INNER JOIN [ORDER] o ON oi.order_id = o.order_id "
                + "WHERE o.order_status = 'COMPLETED'";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException ex) {
            Logger.getLogger(DashboardDAO.class.getName())
                    .log(Level.SEVERE, "Error getting total products sold", ex);
        }

        return 0;
    }

    // =========================
    // 5. REVENUE BY DATE
    // =========================
    public List<Object[]> getRevenueByDate() {

        List<Object[]> list = new ArrayList<>();

        String sql = "SELECT CAST(o.created_at AS DATE) AS order_date, "
                + "SUM(o.total_amount) AS revenue "
                + "FROM [ORDER] o "
                + "JOIN ORDER_STATUS_HISTORY h "
                + "ON o.order_id = h.order_id "
                + "WHERE h.status = 'Completed' "
                + "AND h.status_id = ( "
                + "SELECT MAX(h2.status_id) "
                + "FROM ORDER_STATUS_HISTORY h2 "
                + "WHERE h2.order_id = o.order_id"
                + ") "
                + "GROUP BY CAST(o.created_at AS DATE) "
                + "ORDER BY order_date";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Object[] row = new Object[2];

                row[0] = rs.getDate("order_date");
                row[1] = rs.getBigDecimal("revenue");

                list.add(row);
            }

        } catch (SQLException ex) {
            Logger.getLogger(DashboardDAO.class.getName())
                    .log(Level.SEVERE, "Error getting revenue by date", ex);
        }

        return list;
    }

    // =========================
    // 6. TOP SELLING PRODUCTS
    // =========================
    public List<Object[]> getTopSellingProducts() {

        List<Object[]> list = new ArrayList<>();

        String sql = "SELECT TOP 5 "
                + "p.product_name, "
                + "SUM(oi.quantity) AS total_sold "
                + "FROM ORDER_ITEM oi "
                + "INNER JOIN [ORDER] o "
                + "ON oi.order_id = o.order_id "
                + "INNER JOIN PRODUCT_SKU sku "
                + "ON oi.sku_id = sku.sku_id "
                + "INNER JOIN PRODUCT p "
                + "ON sku.product_id = p.product_id "
                + "INNER JOIN ORDER_STATUS_HISTORY h "
                + "ON o.order_id = h.order_id "
                + "WHERE h.status = 'Completed' "
                + "AND h.status_id = ( "
                + "    SELECT MAX(h2.status_id) "
                + "    FROM ORDER_STATUS_HISTORY h2 "
                + "    WHERE h2.order_id = o.order_id "
                + ") "
                + "GROUP BY p.product_id, p.product_name "
                + "ORDER BY total_sold DESC";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Object[] row = new Object[2];

                row[0] = rs.getString("product_name");
                row[1] = rs.getInt("total_sold");

                list.add(row);
            }

        } catch (SQLException ex) {

            Logger.getLogger(DashboardDAO.class.getName())
                    .log(Level.SEVERE,
                            "Error getting top selling products",
                            ex);
        }

        return list;
    }

    // =========================
    // 7. ORDER STATUS
    // =========================
    public List<Object[]> getOrderStatusStatistics() {

        List<Object[]> list = new ArrayList<>();

        String sql = "SELECT h.status, COUNT(*) AS total "
                + "FROM ORDER_STATUS_HISTORY h "
                + "INNER JOIN ( "
                + "    SELECT order_id, MAX(status_id) AS max_status_id "
                + "    FROM ORDER_STATUS_HISTORY "
                + "    GROUP BY order_id "
                + ") latest "
                + "ON h.order_id = latest.order_id "
                + "AND h.status_id = latest.max_status_id "
                + "GROUP BY h.status "
                + "ORDER BY total DESC";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Object[] row = new Object[2];

                row[0] = rs.getString("status");
                row[1] = rs.getInt("total");

                list.add(row);
            }

        } catch (SQLException ex) {

            Logger.getLogger(DashboardDAO.class.getName())
                    .log(Level.SEVERE,
                            "Error getting order status statistics",
                            ex);
        }

        return list;
    }
}
