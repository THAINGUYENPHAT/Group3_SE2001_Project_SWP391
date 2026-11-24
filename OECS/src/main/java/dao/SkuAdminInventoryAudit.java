package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public final class SkuAdminInventoryAudit {

    private SkuAdminInventoryAudit() {
    }

    public static int lockCurrentStock(Connection conn, int productId, int skuId)
            throws SQLException {
        String sql = "SELECT stock_quantity FROM dbo.PRODUCT_SKU WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE product_id = ? AND sku_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            ps.setInt(2, skuId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("SKU không tồn tại hoặc không thuộc sản phẩm.");
                }
                int qty = rs.getInt(1);
                if (rs.wasNull()) {
                    throw new SQLException("Tồn kho SKU không được NULL.");
                }
                return qty;
            }
        }
    }

    public static void recordOpening(Connection conn, int skuId, int quantity)
            throws SQLException {
        if (quantity < 0) {
            throw new IllegalArgumentException("Tồn kho khởi tạo không được âm.");
        }
        insert(conn, skuId, "OPENING", 0, quantity, "Khởi tạo SKU qua Admin");
    }

    public static void recordAdminCorrection(Connection conn, int skuId,
            int before, int after) throws SQLException {
        if (before == after) {
            return;
        }
        insert(conn, skuId, "SET", before, after, "Điều chỉnh tồn kho từ quản lý SKU");
    }

    private static void insert(Connection conn, int skuId, String type,
            int before, int after, String note) throws SQLException {
        if (conn == null || skuId <= 0 || before < 0 || after < 0) {
            throw new IllegalArgumentException("Thông tin biến động kho không hợp lệ.");
        }
        long delta = (long) after - (long) before;
        if (delta < Integer.MIN_VALUE || delta > Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Biến động tồn kho vượt giới hạn SQL.");
        }
        String sql = "INSERT INTO dbo.INVENTORY_MOVEMENT "
                + "(sku_id, movement_type, quantity_delta, quantity_before, "
                + "quantity_after, note, actor_user_id) VALUES (?, ?, ?, ?, ?, ?, NULL)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, skuId);
            ps.setString(2, type);
            ps.setInt(3, (int) delta);
            ps.setInt(4, before);
            ps.setInt(5, after);
            ps.setNString(6, note);
            if (ps.executeUpdate() != 1) {
                throw new SQLException("Không ghi được lịch sử tồn kho SKU.");
            }
        }
    }
}
