package dao;

import db.DBContext;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class SkuHardDeleteDAO extends DBContext {

    public String deletePermanently(
            int productId,
            int skuId) throws SQLException {

        try (Connection conn = getConnection()) {

            conn.setTransactionIsolation(
                    Connection.TRANSACTION_SERIALIZABLE
            );

            conn.setAutoCommit(false);

            try {

                String skuCode = null;

                String sqlSku
                        = "SELECT sku_code "
                        + "FROM dbo.PRODUCT_SKU "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE sku_id = ? "
                        + "AND product_id = ?";

                try (PreparedStatement ps
                        = conn.prepareStatement(sqlSku)) {

                    ps.setInt(1, skuId);
                    ps.setInt(2, productId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (rs.next()) {
                            skuCode = rs.getString("sku_code");
                        }
                    }
                }

                if (skuCode == null) {
                    throw new IllegalArgumentException(
                            "Không tìm thấy SKU thuộc sản phẩm này."
                    );
                }

                if (exists(
                        conn,
                        "SELECT 1 FROM dbo.ORDER_ITEM "
                        + "WHERE sku_id = ?",
                        skuId)) {

                    throw new IllegalArgumentException(
                            "Không thể xóa SKU đã phát sinh "
                            + "đơn hàng. Hãy dùng Ngừng bán."
                    );
                }

                if (exists(
                        conn,
                        "SELECT 1 FROM dbo.PRODUCT_REVIEWS "
                        + "WHERE sku_id = ?",
                        skuId)) {

                    throw new IllegalArgumentException(
                            "Không thể xóa SKU đã có đánh giá."
                    );
                }

                if (exists(
                        conn,
                        "SELECT 1 FROM dbo.CART_ITEMS "
                        + "WHERE sku_id = ?",
                        skuId)) {

                    throw new IllegalArgumentException(
                            "SKU đang nằm trong giỏ hàng. "
                            + "Cần xử lý giỏ hàng trước khi xóa."
                    );
                }

                if (exists(
                        conn,
                        "SELECT 1 "
                        + "FROM dbo.INVENTORY_MOVEMENT "
                        + "WHERE sku_id = ? "
                        + "AND movement_type <> 'OPENING'",
                        skuId)) {

                    throw new IllegalArgumentException(
                            "SKU đã phát sinh lịch sử "
                            + "nhập/xuất hoặc thay đổi tồn kho. "
                            + "Không thể xóa vĩnh viễn."
                    );
                }

                executeDelete(
                        conn,
                        "DELETE FROM dbo.PRODUCT_IMAGES "
                        + "WHERE product_id = ? "
                        + "AND sku_id = ?",
                        productId,
                        skuId
                );

                executeDeleteBySku(
                        conn,
                        "DELETE FROM dbo.SKU_ATTRIBUTE_VALUE "
                        + "WHERE sku_id = ?",
                        skuId
                );

                executeDeleteBySku(
                        conn,
                        "DELETE FROM dbo.INVENTORY_MOVEMENT "
                        + "WHERE sku_id = ? "
                        + "AND movement_type = 'OPENING'",
                        skuId
                );

                int deleted = executeDelete(
                        conn,
                        "DELETE FROM dbo.PRODUCT_SKU "
                        + "WHERE product_id = ? "
                        + "AND sku_id = ?",
                        productId,
                        skuId
                );

                if (deleted != 1) {
                    throw new SQLException(
                            "Không thể xóa SKU khỏi PRODUCT_SKU."
                    );
                }

                conn.commit();

                return skuCode;

            } catch (SQLException ex) {

                conn.rollback();

                if (ex.getErrorCode() == 547) {

                    throw new IllegalArgumentException(
                            "SKU vẫn được dữ liệu khác tham chiếu. "
                            + "Không thể xóa vĩnh viễn.",
                            ex
                    );
                }

                throw ex;

            } catch (RuntimeException ex) {

                conn.rollback();
                throw ex;
            }
        }
    }

    private boolean exists(
            Connection conn,
            String sql,
            int skuId) throws SQLException {

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private int executeDelete(
            Connection conn,
            String sql,
            int productId,
            int skuId) throws SQLException {

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);
            ps.setInt(2, skuId);

            return ps.executeUpdate();
        }
    }

    private int executeDeleteBySku(
            Connection conn,
            String sql,
            int skuId) throws SQLException {

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            return ps.executeUpdate();
        }
    }
}
