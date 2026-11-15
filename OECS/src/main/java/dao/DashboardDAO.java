package dao;

import db.DBContext;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class DashboardDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(DashboardDAO.class.getName());

    public BigDecimal getTotalRevenueByRange(
            LocalDate start, LocalDate end) {

        String sql
                = "SELECT COALESCE(SUM(total_amount), 0) "
                + "FROM dbo.[ORDER] "
                + "WHERE order_status = 'COMPLETED' "
                + "AND created_at >= ? AND created_at < ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setRange(ps, start, end);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getBigDecimal(1);
                }
            }

        } catch (SQLException ex) {
            throw databaseError(
                    "Lỗi lấy giá trị đơn hoàn thành", ex);
        }

        throw new IllegalStateException(
                "Truy vấn không trả về kết quả.");
    }

    public int getTotalOrdersByRange(
            LocalDate start, LocalDate end) {

        String sql
                = "SELECT COUNT(*) FROM dbo.[ORDER] "
                + "WHERE created_at >= ? AND created_at < ?";

        return countByRange(sql, start, end);
    }

    public int getCompletedOrdersByRange(
            LocalDate start, LocalDate end) {

        String sql
                = "SELECT COUNT(*) FROM dbo.[ORDER] "
                + "WHERE order_status = 'COMPLETED' "
                + "AND created_at >= ? AND created_at < ?";

        return countByRange(sql, start, end);
    }

    public int getCancelledOrdersByRange(
            LocalDate start, LocalDate end) {

        String sql
                = "SELECT COUNT(*) FROM dbo.[ORDER] "
                + "WHERE order_status = 'CANCELLED' "
                + "AND created_at >= ? AND created_at < ?";

        return countByRange(sql, start, end);
    }

    public List<Object[]> getRevenueByDateRange(
            LocalDate start, LocalDate end) {

        List<Object[]> result = new ArrayList<>();

        String sql
                = "SELECT CAST(created_at AS DATE) AS order_date, "
                + "SUM(total_amount) AS total_value "
                + "FROM dbo.[ORDER] "
                + "WHERE order_status = 'COMPLETED' "
                + "AND created_at >= ? AND created_at < ? "
                + "GROUP BY CAST(created_at AS DATE) "
                + "ORDER BY order_date ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setRange(ps, start, end);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(new Object[]{
                        rs.getDate("order_date"),
                        rs.getBigDecimal("total_value")
                    });
                }
            }

        } catch (SQLException ex) {
            throw databaseError(
                    "Lỗi lấy biểu đồ doanh thu", ex);
        }

        return result;
    }

    public List<Object[]> getOrderStatusByRange(
            LocalDate start, LocalDate end) {

        List<Object[]> result = new ArrayList<>();

        String sql
                = "SELECT order_status, COUNT(*) AS total "
                + "FROM dbo.[ORDER] "
                + "WHERE created_at >= ? AND created_at < ? "
                + "GROUP BY order_status "
                + "ORDER BY total DESC, order_status ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setRange(ps, start, end);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(new Object[]{
                        rs.getString("order_status"),
                        rs.getInt("total")
                    });
                }
            }

        } catch (SQLException ex) {
            throw databaseError(
                    "Lỗi thống kê trạng thái đơn", ex);
        }

        return result;
    }

    public List<Object[]> getTopSellingProductsByRange(
            LocalDate start, LocalDate end) {

        List<Object[]> result = new ArrayList<>();

        String sql
                = "SELECT TOP 5 "
                + "p.product_id, "
                + "p.product_name, "
                + "p.image_url, "
                + "price_info.min_price, "
                + "SUM(oi.quantity) AS total_sold "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.[ORDER] o "
                + "ON oi.order_id = o.order_id "
                + "JOIN dbo.PRODUCT_SKU sku "
                + "ON oi.sku_id = sku.sku_id "
                + "JOIN dbo.PRODUCT p "
                + "ON sku.product_id = p.product_id "
                + "LEFT JOIN ( "
                + "    SELECT product_id, MIN(price) AS min_price "
                + "    FROM dbo.PRODUCT_SKU "
                + "    GROUP BY product_id "
                + ") price_info "
                + "ON price_info.product_id = p.product_id "
                + "WHERE o.order_status = 'COMPLETED' "
                + "AND o.created_at >= ? AND o.created_at < ? "
                + "GROUP BY p.product_id, p.product_name, "
                + "p.image_url, price_info.min_price "
                + "ORDER BY total_sold DESC, "
                + "p.product_name ASC, p.product_id ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setRange(ps, start, end);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(new Object[]{
                        rs.getInt("product_id"),
                        rs.getString("product_name"),
                        rs.getString("image_url"),
                        rs.getBigDecimal("min_price"),
                        rs.getInt("total_sold")
                    });
                }
            }

        } catch (SQLException ex) {
            throw databaseError(
                    "Lỗi lấy Top 5 sản phẩm", ex);
        }

        return result;
    }

    
    public int[] getCurrentStockStatistics() {

        String sql
                = "SELECT "
                + "COALESCE(SUM(CASE "
                + "WHEN COALESCE(stock_quantity, 0) > 5 "
                + "THEN 1 ELSE 0 END), 0) AS in_stock, "
                + "COALESCE(SUM(CASE "
                + "WHEN stock_quantity BETWEEN 1 AND 5 "
                + "THEN 1 ELSE 0 END), 0) AS low_stock, "
                + "COALESCE(SUM(CASE "
                + "WHEN COALESCE(stock_quantity, 0) <= 0 "
                + "THEN 1 ELSE 0 END), 0) AS out_stock "
                + "FROM dbo.PRODUCT_SKU";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return new int[]{
                    rs.getInt("in_stock"),
                    rs.getInt("low_stock"),
                    rs.getInt("out_stock")
                };
            }

        } catch (SQLException ex) {
            throw databaseError(
                    "Lỗi lấy tình trạng tồn kho", ex);
        }

        throw new IllegalStateException(
                "Không đọc được dữ liệu tồn kho.");
    }

    
    private int countByRange(
            String sql, LocalDate start, LocalDate end) {

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setRange(ps, start, end);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException ex) {
            throw databaseError(
                    "Lỗi đếm dữ liệu Dashboard", ex);
        }

        throw new IllegalStateException(
                "Truy vấn đếm không trả về kết quả.");
    }

    private void setRange(
            PreparedStatement ps,
            LocalDate start,
            LocalDate end) throws SQLException {

        ps.setDate(1, Date.valueOf(start));
        ps.setDate(2, Date.valueOf(end.plusDays(1)));
    }

    private IllegalStateException databaseError(
            String message, SQLException ex) {

        LOGGER.log(Level.SEVERE, message, ex);

        return new IllegalStateException(
                message + ". Không thể tải dữ liệu.", ex);
    }

    
    public List<Object[]> getLowStockProducts() {

        List<Object[]> result = new ArrayList<>();

        String sql
                = "SELECT "
                + "s.sku_id, "
                + "s.sku_code, "
                + "p.product_name, "
                + "p.image_url, "
                + "COALESCE(s.stock_quantity, 0) AS stock_quantity, "
                + "s.price "
                + "FROM dbo.PRODUCT_SKU s "
                + "INNER JOIN dbo.PRODUCT p "
                + "ON s.product_id = p.product_id "
                + "WHERE COALESCE(s.stock_quantity, 0) <= 5 "
                + "ORDER BY "
                + "CASE WHEN COALESCE(s.stock_quantity, 0) <= 0 "
                + "THEN 0 ELSE 1 END, "
                + "COALESCE(s.stock_quantity, 0) ASC, "
                + "p.product_name ASC, "
                + "s.sku_code ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                result.add(new Object[]{
                    rs.getInt("sku_id"),
                    rs.getString("sku_code"),
                    rs.getString("product_name"),
                    rs.getString("image_url"),
                    rs.getInt("stock_quantity"),
                    rs.getBigDecimal("price")
                });
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error getting low stock products",
                    ex
            );

            throw new IllegalStateException(
                    "Không thể lấy danh sách SKU cần nhập hàng.",
                    ex
            );
        }

        return result;
    }

}
