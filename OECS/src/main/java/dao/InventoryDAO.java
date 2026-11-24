package dao;

import db.DBContext;
import model.InventoryItem;
import model.InventoryMovement;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class InventoryDAO extends DBContext {

    public boolean isAuthorizedStaff(int userId) throws SQLException {

        String sql
                = "SELECT TOP (1) 1 "
                + "FROM dbo.[USER] u "
                + "INNER JOIN dbo.ROLES r "
                + "ON u.role_id = r.role_id "
                + "WHERE u.user_id = ? "
                + "AND u.is_active = 1 "
                + "AND UPPER(LTRIM(RTRIM(r.role_name))) "
                + "IN ('STAFF', 'ADMIN')";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public int countItems(String keyword, String status) throws SQLException {
        Filter filter = makeFilter(keyword, status);
        String sql = "SELECT COUNT(*) " + filter.sql;
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            bindFilter(ps, filter);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public List<InventoryItem> findItems(String keyword, String status,
            int page, int pageSize) throws SQLException {
        Filter filter = makeFilter(keyword, status);
        String sql = "SELECT s.sku_id, s.product_id, s.sku_code, "
                + "p.product_name, s.stock_quantity, s.is_active AS sku_active, "
                + "p.is_active AS product_active " + filter.sql
                + " ORDER BY CASE WHEN s.is_active=1 AND p.is_active=1 "
                + "THEN 0 ELSE 1 END, s.stock_quantity ASC, s.sku_id DESC "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
        List<InventoryItem> result = new ArrayList<>();
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            int index = bindFilter(ps, filter);
            ps.setInt(index++, (page - 1) * pageSize);
            ps.setInt(index, pageSize);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(new InventoryItem(
                            rs.getInt("sku_id"), rs.getInt("product_id"),
                            rs.getString("sku_code"), rs.getString("product_name"),
                            rs.getInt("stock_quantity"), rs.getBoolean("sku_active"),
                            rs.getBoolean("product_active")));
                }
            }
        }
        return result;
    }

    public List<InventoryMovement> getRecentMovements(int limit)
            throws SQLException {
        String sql = "SELECT TOP (?) m.movement_id, s.sku_code, "
                + "p.product_name, m.movement_type, m.quantity_delta, "
                + "m.quantity_before, m.quantity_after, m.note, "
                + "u.username AS actor_name, m.created_at "
                + "FROM dbo.INVENTORY_MOVEMENT m "
                + "JOIN dbo.PRODUCT_SKU s ON s.sku_id=m.sku_id "
                + "JOIN dbo.PRODUCT p ON p.product_id=s.product_id "
                + "LEFT JOIN dbo.[USER] u ON u.user_id=m.actor_user_id "
                + "ORDER BY m.movement_id DESC";
        List<InventoryMovement> result = new ArrayList<>();
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, Math.max(1, Math.min(100, limit)));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(new InventoryMovement(
                            rs.getLong("movement_id"), rs.getString("sku_code"),
                            rs.getString("product_name"), rs.getString("movement_type"),
                            rs.getInt("quantity_delta"), rs.getInt("quantity_before"),
                            rs.getInt("quantity_after"), rs.getString("note"),
                            rs.getString("actor_name"), rs.getTimestamp("created_at")));
                }
            }
        }
        return result;
    }

  
    public int changeStock(int skuId, String action, int quantity,
            String note, int actorUserId) throws SQLException {
        if (skuId <= 0 || actorUserId <= 0) {
            throw new IllegalArgumentException("SKU hoặc nhân viên không hợp lệ.");
        }
        if (!"IN".equals(action) && !"OUT".equals(action)
                && !"SET".equals(action)) {
            throw new IllegalArgumentException("Loại điều chỉnh không hợp lệ.");
        }
        if (quantity < 0 || (!"SET".equals(action) && quantity == 0)) {
            throw new IllegalArgumentException("Số lượng không hợp lệ.");
        }
        if (note == null || note.trim().isEmpty() || note.trim().length() > 500) {
            throw new IllegalArgumentException("Cần nhập lý do (tối đa 500 ký tự).");
        }

        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try {
                int oldQty;
                String readSql = "SELECT s.stock_quantity FROM dbo.PRODUCT_SKU s "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "JOIN dbo.PRODUCT p ON p.product_id=s.product_id "
                        + "WHERE s.sku_id=? AND s.is_active=1 AND p.is_active=1";
                try (PreparedStatement ps = conn.prepareStatement(readSql)) {
                    ps.setInt(1, skuId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException(
                                    "SKU không tồn tại hoặc đã ngừng kinh doanh.");
                        }
                        oldQty = rs.getInt(1);
                        if (rs.wasNull()) {
                            throw new IllegalStateException("SKU có tồn kho NULL.");
                        }
                    }
                }

                long newQtyLong;
                if ("IN".equals(action)) {
                    newQtyLong = (long) oldQty + quantity;
                } else if ("OUT".equals(action)) {
                    newQtyLong = (long) oldQty - quantity;
                } else {
                    newQtyLong = quantity;
                }
                if (newQtyLong < 0 || newQtyLong > Integer.MAX_VALUE) {
                    throw new IllegalArgumentException("Không đủ hàng hoặc vượt giới hạn tồn kho.");
                }
                int newQty = (int) newQtyLong;
                if (newQty == oldQty) {
                    throw new IllegalArgumentException("Số tồn mới không thay đổi.");
                }

                setContext(conn, "oecs_inventory_action", action);
                setContext(conn, "oecs_inventory_note", note.trim());
                setContext(conn, "oecs_inventory_user_id", actorUserId);

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.PRODUCT_SKU SET stock_quantity=? "
                        + "WHERE sku_id=? AND stock_quantity=?")) {
                    ps.setInt(1, newQty);
                    ps.setInt(2, skuId);
                    ps.setInt(3, oldQty);
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Dữ liệu tồn kho đã thay đổi. Vui lòng tải lại.");
                    }
                }

               
                InventoryMovementHelper.record(
                        conn,
                        skuId,
                        action,
                        oldQty,
                        newQty,
                        note.trim(),
                        actorUserId
                );

                conn.commit();
                return newQty;

            } catch (SQLException | RuntimeException ex) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    ex.addSuppressed(rollbackError);
                }
                throw ex;
            } finally {
               
                SQLException clearError = null;
                for (String key : new String[]{
                    "oecs_inventory_action", "oecs_inventory_note",
                    "oecs_inventory_user_id"}) {
                    try {
                        setContext(conn, key, null);
                    } catch (SQLException ex) {
                        if (clearError == null) {
                            clearError = ex;
                        } else {
                            clearError.addSuppressed(ex);
                        }
                    }
                }
                try {
                    conn.setAutoCommit(true);
                } catch (SQLException ex) {
                    if (clearError == null) {
                        clearError = ex;
                    } else {
                        clearError.addSuppressed(ex);
                    }
                }
                if (clearError != null) {
                    throw clearError;
                }
            }
        }
    }

    private void setContext(Connection conn, String key, Object value)
            throws SQLException {
        String sql = "EXEC sys.sp_set_session_context @key=N'" + key
                + "', @value=?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            if (value == null) {
                ps.setNull(1, Types.NVARCHAR);
            } else if (value instanceof Integer) {
                ps.setInt(1, (Integer) value);
            } else {
                ps.setString(1, (String) value);
            }
            ps.execute();
        }
    }

    private Filter makeFilter(String keyword, String status) {
        StringBuilder sql = new StringBuilder(
                "FROM dbo.PRODUCT_SKU s "
                + "JOIN dbo.PRODUCT p ON p.product_id=s.product_id "
                + "WHERE 1=1");
        String normalized = keyword == null ? "" : keyword.trim();
        if (normalized.length() > 100) {
            normalized = normalized.substring(0, 100);
        }
        if (!normalized.isEmpty()) {
            sql.append(" AND (s.sku_code LIKE ? ESCAPE '~' "
                    + "OR p.product_name LIKE ? ESCAPE '~')");
        }
        if ("LOW".equals(status)) {
            sql.append(" AND s.stock_quantity BETWEEN 1 AND 5");
        } else if ("OUT".equals(status)) {
            sql.append(" AND s.stock_quantity=0");
        }
        return new Filter(sql.toString(), normalized);
    }

    private int bindFilter(PreparedStatement ps, Filter filter)
            throws SQLException {
        int i = 1;
        if (!filter.keyword.isEmpty()) {
            String pattern = "%" + filter.keyword
                    .replace("~", "~~").replace("%", "~%")
                    .replace("_", "~_").replace("[", "~[") + "%";
            ps.setString(i++, pattern);
            ps.setString(i++, pattern);
        }
        return i;
    }

    private static class Filter {

        final String sql;
        final String keyword;

        Filter(String sql, String keyword) {
            this.sql = sql;
            this.keyword = keyword;
        }
    }
}
