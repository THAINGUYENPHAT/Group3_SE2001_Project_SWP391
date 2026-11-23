package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * Replaces the missing dbo.usp_OECS_RefreshSkuVariantKey stored procedure.
 * The caller must use the same connection and transaction that saved attributes.
 * The UNIQUE filtered index UX_SKU_ProductVariant rejects duplicate combinations.
 */
public final class SkuVariantKeyHelper {
    private SkuVariantKeyHelper() { }

    public static void refresh(Connection conn, int skuId) throws SQLException {
        if (conn == null || skuId <= 0) {
            throw new IllegalArgumentException("Connection/SKU ID khong hop le.");
        }

        String sql =
                "UPDATE s SET variant_key = "
              + "CASE WHEN av.variant_text IS NULL THEN NULL "
              + "ELSE HASHBYTES('SHA2_256', av.variant_text) END "
              + "FROM dbo.PRODUCT_SKU AS s "
              + "OUTER APPLY ( "
              + " SELECT STRING_AGG( "
              + "   CAST(CONCAT(sav.attribute_id, N'=', "
              + "     CASE WHEN sav.text_value IS NOT NULL THEN "
              + "       N'T:' + UPPER(LTRIM(RTRIM(sav.text_value))) "
              + "     WHEN sav.numeric_value IS NOT NULL THEN "
              + "       N'N:' + CONVERT(NVARCHAR(60), sav.numeric_value) "
              + "     ELSE N'B:' + CONVERT(NVARCHAR(1),sav.boolean_value) "
              + "     END) AS NVARCHAR(MAX)), N'|' "
              + " ) WITHIN GROUP (ORDER BY sav.attribute_id) AS variant_text "
              + " FROM dbo.SKU_ATTRIBUTE_VALUE AS sav WHERE sav.sku_id=s.sku_id "
              + ") AS av "
              + "WHERE s.sku_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, skuId);
            if (ps.executeUpdate() != 1) {
                throw new SQLException("Khong tim thay SKU de cap nhat variant_key: " + skuId);
            }
        }
    }
}
