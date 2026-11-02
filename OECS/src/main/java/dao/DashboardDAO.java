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

    // =====================================================
    // 1. GIA TRI CAC DON DA HOAN THANH TRONG KY
    // =====================================================
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

    // =====================================================
    // 2. TONG SO DON TAO TRONG KY
    // =====================================================
    public int getTotalOrdersByRange(
            LocalDate start, LocalDate end) {

        String sql
                = "SELECT COUNT(*) FROM dbo.[ORDER] "
                + "WHERE created_at >= ? AND created_at < ?";

        return countByRange(sql, start, end);
    }

    // =====================================================
    // 3. SO DON HIEN DA HOAN THANH
    // =====================================================
    public int getCompletedOrdersByRange(
            LocalDate start, LocalDate end) {

        String sql
                = "SELECT COUNT(*) FROM dbo.[ORDER] "
                + "WHERE order_status = 'COMPLETED' "
                + "AND created_at >= ? AND created_at < ?";

        return countByRange(sql, start, end);
    }

    // =====================================================
    // 4. SO DON HIEN DA HUY
    // =====================================================
    public int getCancelledOrdersByRange(
            LocalDate start, LocalDate end) {

        String sql
                = "SELECT COUNT(*) FROM dbo.[ORDER] "
                + "WHERE order_status = 'CANCELLED' "
                + "AND created_at >= ? AND created_at < ?";

        return countByRange(sql, start, end);
    }

    // =====================================================
    // 5. BIEU DO GIA TRI DON HOAN THANH THEO NGAY
    // row = [ngay, giaTri]
    // =====================================================
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

    // =====================================================
    // 6. THONG KE TRANG THAI DON HANG TRONG KY
    // row = [trangThai, soLuong]
    // =====================================================
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

    // =====================================================
    // 7. TOP 5 SAN PHAM BAN CHAY TRONG KY
    //
    // row[0] = product_id
    // row[1] = product_name
    // row[2] = image_url
    // row[3] = min_price (gia niem yet hien tai)
    // row[4] = total_sold
    //
    // MIN(price) duoc tinh tren TAT CA SKU cua san pham
    // de hien thi nhan "Gia tu..."
    // =====================================================
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

    // =====================================================
    // 8. TINH TRANG TON KHO HIEN TAI THEO SKU
    //
    // row[0] = con hang (> 5)
    // row[1] = sap het (1 den 5)
    // row[2] = het hang (<= 0)
    //
    // Nguong 5 la quy tac can thong nhat voi nhom.
    // KHONG loc theo ngay vi DB khong co ton kho lich su.
    // =====================================================
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

    // =====================================================
    // HELPER: DEM DON THEO KHOANG NGAY
    // =====================================================
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

    // Lay ca ngay bat dau va ngay ket thuc
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

    // =====================================================
    // DANH SACH SKU SAP HET HOAC HET HANG
    // 0      = Het hang
    // 1 - 5  = Sap het
    //
    // row[0] = sku_id
    // row[1] = sku_code
    // row[2] = product_name
    // row[3] = image_url
    // row[4] = stock_quantity
    // row[5] = price
    // =====================================================
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
