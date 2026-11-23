package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

/**
 * Records stock movements from Java instead of relying on a database trigger.
 * IMPORTANT: call within the same open transaction as the stock UPDATE.
 */
public final class InventoryMovementHelper {
    private InventoryMovementHelper() { }

    public static void record(Connection conn, int skuId, String movementType,
                              int before, int after, String note, Integer actorUserId)
            throws SQLException {
        if (conn == null || skuId <= 0 || before < 0 || after < 0) {
            throw new IllegalArgumentException("Invalid stock-movement arguments.");
        }
        if (movementType == null ||
                !(movementType.equals("OPENING") || movementType.equals("IN") ||
                  movementType.equals("OUT") || movementType.equals("SET") ||
                  movementType.equals("SYSTEM"))) {
            throw new IllegalArgumentException("Invalid movement type.");
        }
        if (note != null && note.length() > 500) {
            throw new IllegalArgumentException("Movement note exceeds 500 characters.");
        }

        long delta = (long) after - before;
        if (delta > Integer.MAX_VALUE || delta < Integer.MIN_VALUE) {
            throw new IllegalArgumentException("Movement delta out of SQL INT range.");
        }
        String sql = "INSERT INTO dbo.INVENTORY_MOVEMENT "
                + "(sku_id,movement_type,quantity_delta,quantity_before,"
                + "quantity_after,note,actor_user_id) VALUES (?,?,?,?,?,?,?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, skuId);
            ps.setString(2, movementType);
            ps.setInt(3, (int) delta);
            ps.setInt(4, before);
            ps.setInt(5, after);
            if (note == null) ps.setNull(6, Types.NVARCHAR);
            else ps.setNString(6, note);
            if (actorUserId == null) ps.setNull(7, Types.INTEGER);
            else ps.setInt(7, actorUserId);
            if (ps.executeUpdate() != 1) {
                throw new SQLException("Could not write inventory movement.");
            }
        }
    }

    /** Call immediately after a successful +/- stock UPDATE in the same transaction. */
    public static void recordAfterDelta(Connection conn, int skuId, int delta,
                                        String movementType, String note,
                                        Integer actorUserId) throws SQLException {
        String sql = "SELECT stock_quantity FROM dbo.PRODUCT_SKU WITH (UPDLOCK,HOLDLOCK) "
                   + "WHERE sku_id=?";
        int after;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, skuId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new SQLException("SKU not found: " + skuId);
                after = rs.getInt(1);
                if (rs.wasNull()) throw new SQLException("SKU stock is NULL.");
            }
        }
        long before = (long) after - delta;
        if (before < 0 || before > Integer.MAX_VALUE) {
            throw new SQLException("Invalid prior stock value for SKU " + skuId);
        }
        record(conn, skuId, movementType, (int) before, after, note, actorUserId);
    }
}
