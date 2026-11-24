
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
    // 1. TONG DOANH THU TRONG KHOANG THOI GIAN
    // =====================================================

    // Doanh thu gop cua don COMPLETED.
    // Khong tru tien hoan xu ly ben ngoai he thong.

    public BigDecimal getTotalRevenueByRange(
            LocalDate start,
            LocalDate end) {

        String sql
                = "SELECT COALESCE(SUM(o.total_amount), 0) "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.order_status = 'COMPLETED' "
                + "AND o.created_at >= ? "
                + "AND o.created_at < ? ";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            setRange(ps, start, end);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getBigDecimal(1);
                }
            }

        } catch (SQLException ex) {

            throw databaseError(
                    "Lỗi lấy doanh thu",
                    ex
            );
        }

        throw new IllegalStateException(
                "Truy vấn không trả về kết quả.");
    }

    // =====================================================
    // 2. TONG SO DON HANG
    // =====================================================

    public int getTotalOrdersByRange(
            LocalDate start,
            LocalDate end) {

        String sql
                = "SELECT COUNT(*) "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? ";

        return countByRange(sql, start, end);
    }

    // =====================================================
    // 3. SO DON HANG DA HOAN THANH
    // =====================================================

    public int getCompletedOrdersByRange(
            LocalDate start,
            LocalDate end) {

        String sql
                = "SELECT COUNT(*) "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.order_status = 'COMPLETED' "
                + "AND o.created_at >= ? "
                + "AND o.created_at < ? ";

        return countByRange(sql, start, end);
    }

    // =====================================================
    // 4. SO DON HANG DA HUY
    // =====================================================

    public int getCancelledOrdersByRange(
            LocalDate start,
            LocalDate end) {

        String sql
                = "SELECT COUNT(*) "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.order_status = 'CANCELLED' "
                + "AND o.created_at >= ? "
                + "AND o.created_at < ? ";

        return countByRange(sql, start, end);
    }

    // =====================================================
    // 5. DOANH THU THEO NGAY TAO DON
    // =====================================================

    // Khong su dung PAYMENT_REFUND.
    // Ket qua la doanh thu gop cua cac don COMPLETED.

    public List<Object[]> getRevenueByDateRange(
            LocalDate start,
            LocalDate end) {

        List<Object[]> result = new ArrayList<>();

        String sql
                = "SELECT "
                + "CAST(o.created_at AS DATE) AS order_date, "
                + "SUM(o.total_amount) AS total_value "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.order_status = 'COMPLETED' "
                + "AND o.created_at >= ? "
                + "AND o.created_at < ? "
                + "GROUP BY CAST(o.created_at AS DATE) "
                + "ORDER BY order_date ASC";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

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
                    "Lỗi lấy biểu đồ doanh thu",
                    ex
            );
        }

        return result;
    }

    // =====================================================
    // 6. THONG KE TRANG THAI DON HANG
    // =====================================================

    public List<Object[]> getOrderStatusByRange(
            LocalDate start,
            LocalDate end) {

        List<Object[]> result = new ArrayList<>();

        String sql
                = "SELECT "
                + "o.order_status, "
                + "COUNT(*) AS total "
                + "FROM dbo.[ORDER] o "
                + "WHERE o.created_at >= ? "
                + "AND o.created_at < ? "
                + "GROUP BY o.order_status "
                + "ORDER BY total DESC, o.order_status ASC";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

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
                    "Lỗi thống kê trạng thái đơn",
                    ex
            );
        }

        return result;
    }

    // =====================================================
    // 7. TOP 5 SAN PHAM BAN CHAY
    // =====================================================

    // Giu cach tinh hien tai:
    // So luong ban tru so luong Return da APPROVED.
    // Day la so lieu theo yeu cau duoc duyet,
    // chua phai so hang da nhan thuc te.

    public List<Object[]> getTopSellingProductsByRange(
            LocalDate start,
            LocalDate end) {

        List<Object[]> result = new ArrayList<>();

        String sql
                = "SELECT TOP 5 "
                + "p.product_id, "
                + "p.product_name, "
                + "p.image_url, "
                + "price_info.min_price, "
                + "SUM(oi.quantity - "
                + "COALESCE(ri_ret.returned_qty, 0)) "
                + "AS total_sold "
                + "FROM dbo.ORDER_ITEM oi "
                + "INNER JOIN dbo.[ORDER] o "
                + "ON oi.order_id = o.order_id "
                + "INNER JOIN dbo.PRODUCT_SKU sku "
                + "ON oi.sku_id = sku.sku_id "
                + "INNER JOIN dbo.PRODUCT p "
                + "ON sku.product_id = p.product_id "
                + "LEFT JOIN ( "
                + "SELECT product_id, "
                + "MIN(price) AS min_price "
                + "FROM dbo.PRODUCT_SKU "
                + "GROUP BY product_id "
                + ") price_info "
                + "ON price_info.product_id = p.product_id "
                + "OUTER APPLY ( "
                + "SELECT COALESCE(SUM(ri.quantity), 0) "
                + "AS returned_qty "
                + "FROM dbo.RETURN_REQUEST_ITEM ri "
                + "JOIN dbo.RETURN_REQUEST rr "
                + "ON rr.request_id = ri.request_id "
                + "WHERE ri.order_item_id = oi.order_item_id "
                + "AND rr.request_status = 'APPROVED' "
                + ") ri_ret "
                + "WHERE o.order_status = 'COMPLETED' "
                + "AND o.created_at >= ? "
                + "AND o.created_at < ? "
                + "GROUP BY "
                + "p.product_id, "
                + "p.product_name, "
                + "p.image_url, "
                + "price_info.min_price "
                + "ORDER BY "
                + "total_sold DESC, "
                + "p.product_name ASC, "
                + "p.product_id ASC";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

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
                    "Lỗi lấy Top 5 sản phẩm",
                    ex
            );
        }

        return result;
    }

    // =====================================================
    // 8. THONG KE TON KHO HIEN TAI
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

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {

                return new int[]{
                    rs.getInt("in_stock"),
                    rs.getInt("low_stock"),
                    rs.getInt("out_stock")
                };
            }

        } catch (SQLException ex) {

            throw databaseError(
                    "Lỗi lấy tình trạng tồn kho",
                    ex
            );
        }

        throw new IllegalStateException(
                "Không đọc được dữ liệu tồn kho.");
    }

    // =====================================================
    // 9. DEM DU LIEU THEO KHOANG NGAY
    // =====================================================

    private int countByRange(
            String sql,
            LocalDate start,
            LocalDate end) {

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            setRange(ps, start, end);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException ex) {

            throw databaseError(
                    "Lỗi đếm dữ liệu Dashboard",
                    ex
            );
        }

        throw new IllegalStateException(
                "Truy vấn đếm không trả về kết quả.");
    }

    // =====================================================
    // 10. GAN KHOANG NGAY CHO PREPARED STATEMENT
    // =====================================================

    private void setRange(
            PreparedStatement ps,
            LocalDate start,
            LocalDate end) throws SQLException {

        ps.setDate(
                1,
                Date.valueOf(start)
        );

        // Ngay ket thuc duoc bao gom toan bo.
        ps.setDate(
                2,
                Date.valueOf(end.plusDays(1))
        );
    }

    // =====================================================
    // 11. XU LY LOI DATABASE
    // =====================================================

    private IllegalStateException databaseError(
            String message,
            SQLException ex) {

        LOGGER.log(
                Level.SEVERE,
                message,
                ex
        );

        return new IllegalStateException(
                message + ". Không thể tải dữ liệu.",
                ex
        );
    }

    // =====================================================
    // 12. DANH SACH SKU SAP HET HANG
    // =====================================================

    public List<Object[]> getLowStockProducts() {

        List<Object[]> result = new ArrayList<>();

        String sql
                = "SELECT "
                + "s.sku_id, "
                + "s.sku_code, "
                + "p.product_name, "
                + "p.image_url, "
                + "COALESCE(s.stock_quantity, 0) "
                + "AS stock_quantity, "
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

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {

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
