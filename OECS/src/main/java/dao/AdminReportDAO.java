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

public class AdminReportDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(AdminReportDAO.class.getName());

    // =====================================================
    // 1. DOANH THU THEO NGÀY
    // =====================================================
    public List<Object[]> getRevenueByDate() {

        List<Object[]> list = new ArrayList<>();

        String sql
                = "SELECT CAST(o.created_at AS DATE) AS report_date, "
                + "SUM(o.total_amount) AS revenue, "
                + "COUNT(o.order_id) AS total_orders "
                + "FROM [ORDER] o "
                + "INNER JOIN ORDER_STATUS_HISTORY h "
                + "ON o.order_id = h.order_id "
                + "WHERE h.status = 'Completed' "
                + "AND h.status_id = ( "
                + "    SELECT MAX(h2.status_id) "
                + "    FROM ORDER_STATUS_HISTORY h2 "
                + "    WHERE h2.order_id = o.order_id "
                + ") "
                + "GROUP BY CAST(o.created_at AS DATE) "
                + "ORDER BY report_date";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Object[] row = new Object[3];

                row[0] = rs.getDate("report_date");
                row[1] = rs.getBigDecimal("revenue");
                row[2] = rs.getInt("total_orders");

                list.add(row);
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy báo cáo doanh thu theo ngày!",
                    ex
            );
        }

        return list;
    }

    // =====================================================
    // 2. TỔNG DOANH THU
    // =====================================================
    public BigDecimal getTotalRevenue() {

        String sql
                = "SELECT ISNULL(SUM(o.total_amount), 0) "
                + "FROM [ORDER] o "
                + "INNER JOIN ORDER_STATUS_HISTORY h "
                + "ON o.order_id = h.order_id "
                + "WHERE h.status = 'Completed' "
                + "AND h.status_id = ( "
                + "    SELECT MAX(h2.status_id) "
                + "    FROM ORDER_STATUS_HISTORY h2 "
                + "    WHERE h2.order_id = o.order_id "
                + ")";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getBigDecimal(1);
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy tổng doanh thu!",
                    ex
            );
        }

        return BigDecimal.ZERO;
    }

    // =====================================================
    // 3. TỔNG ĐƠN HOÀN THÀNH
    // =====================================================
    public int getCompletedOrders() {

        String sql
                = "SELECT COUNT(*) "
                + "FROM [ORDER] o "
                + "INNER JOIN ORDER_STATUS_HISTORY h "
                + "ON o.order_id = h.order_id "
                + "WHERE h.status = 'Completed' "
                + "AND h.status_id = ( "
                + "    SELECT MAX(h2.status_id) "
                + "    FROM ORDER_STATUS_HISTORY h2 "
                + "    WHERE h2.order_id = o.order_id "
                + ")";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy số đơn hoàn thành!",
                    ex
            );
        }

        return 0;
    }

    // =====================================================
    // 4. TỔNG SẢN PHẨM ĐÃ BÁN
    // =====================================================
    public int getTotalProductsSold() {

        String sql
                = "SELECT ISNULL(SUM(oi.quantity), 0) "
                + "FROM ORDER_ITEM oi "
                + "INNER JOIN [ORDER] o "
                + "ON oi.order_id = o.order_id "
                + "INNER JOIN ORDER_STATUS_HISTORY h "
                + "ON o.order_id = h.order_id "
                + "WHERE h.status = 'Completed' "
                + "AND h.status_id = ( "
                + "    SELECT MAX(h2.status_id) "
                + "    FROM ORDER_STATUS_HISTORY h2 "
                + "    WHERE h2.order_id = o.order_id "
                + ")";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy tổng sản phẩm đã bán!",
                    ex
            );
        }

        return 0;
    }
}
