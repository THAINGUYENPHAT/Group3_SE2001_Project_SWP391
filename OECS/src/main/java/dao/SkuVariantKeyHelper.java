package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * Synchronize PRODUCT_SKU.variant_key with dbo.SKU_ATTRIBUTE_VALUE.
 * OECS_DB(6).sql intentionally ships WITHOUT stored procedures/triggers. This
 * query uses the SAME canonical value and SHA2_256 hashing as the seed SQL.
 * Call on the caller's Connection BEFORE commit so unique index validation
 * rolls back the entire SKU operation when two combinations are identical.
 */
public final class SkuVariantKeyHelper {

    private SkuVariantKeyHelper() {
    }

    public static void refresh(Connection conn, int skuId) throws SQLException {
        if (conn == null || skuId <= 0) {
            throw new IllegalArgumentException("Connection hoặc SKU ID không hợp lệ.");
        }

        final String sql
                = "UPDATE dbo.PRODUCT_SKU SET variant_key = ("
                + " SELECT HASHBYTES('SHA2_256', STRING_AGG("
                + " CAST(CONCAT(sav.attribute_id, N'=',"
                + " CASE WHEN sav.text_value IS NOT NULL"
                + " THEN N'T:' + UPPER(LTRIM(RTRIM(sav.text_value)))"
                + " WHEN sav.numeric_value IS NOT NULL"
                + " THEN N'N:' + CONVERT(NVARCHAR(60), sav.numeric_value)"
                + " ELSE N'B:' + CONVERT(NVARCHAR(1), sav.boolean_value) END"
                + " ) AS NVARCHAR(MAX)), N'|')"
                + " WITHIN GROUP (ORDER BY sav.attribute_id))"
                + " FROM dbo.SKU_ATTRIBUTE_VALUE sav WHERE sav.sku_id = ?"
                + ") WHERE sku_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, skuId);
            ps.setInt(2, skuId);
            if (ps.executeUpdate() != 1) {
                throw new SQLException("Không cập nhật được variant_key cho SKU ID " + skuId);
            }
        }
    }
}
