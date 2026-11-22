package service;

import db.DBContext;
import model.ProductImage;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import java.util.logging.Level;
import java.util.logging.Logger;

public class SkuImageService extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(SkuImageService.class.getName());

    // ========================================
    // 1. LẤY ẢNH CỦA SKU
    // ========================================
    public List<ProductImage> getImagesBySkuId(
            int productId,
            int skuId) throws SQLException {

        validateIds(productId, skuId);

        List<ProductImage> images = new ArrayList<>();

        String sql
                = "SELECT image_id, product_id, sku_id, "
                + "image_url, is_primary, display_order, "
                + "alt_text, created_at "
                + "FROM PRODUCT_IMAGES "
                + "WHERE product_id = ? AND sku_id = ? "
                + "ORDER BY is_primary DESC, "
                + "display_order ASC, image_id ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);
            ps.setInt(2, skuId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    ProductImage image = new ProductImage(
                            rs.getInt("image_id"),
                            rs.getInt("product_id"),
                            rs.getString("image_url")
                    );

                    image.setSkuId(rs.getInt("sku_id"));
                    image.setPrimary(
                            rs.getBoolean("is_primary")
                    );
                    image.setDisplayOrder(
                            rs.getInt("display_order")
                    );
                    image.setAltText(
                            rs.getString("alt_text")
                    );
                    image.setCreatedAt(
                            rs.getTimestamp("created_at")
                    );

                    images.add(image);
                }
            }
        }

        return images;
    }

    // ========================================
    // 2. THÊM NHIỀU ẢNH CHO SKU
    // ========================================

    /*
     * Trả về số ảnh đã thêm.
     *
     * Nếu SKU chưa có ảnh chính, tự chọn
     * ảnh đầu tiên theo display_order.
     *
     * Toàn bộ ảnh được thêm trong cùng
     * một transaction SQL.
     */
    public int addImages(
            int productId,
            int skuId,
            List<String> imageUrls) throws SQLException {

        validateIds(productId, skuId);
        validateImageUrls(imageUrls);

        if (imageUrls == null || imageUrls.isEmpty()) {
            return 0;
        }

        try (Connection conn = getConnection()) {

            boolean oldAutoCommit = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                lockSku(conn, productId, skuId);

                int nextOrder = getNextDisplayOrder(
                        conn, productId, skuId
                );

                if ((long) nextOrder + imageUrls.size() - 1
                        > Integer.MAX_VALUE) {
                    throw new IllegalArgumentException(
                            "Thứ tự ảnh vượt giới hạn."
                    );
                }

                String sql
                        = "INSERT INTO PRODUCT_IMAGES "
                        + "(product_id, sku_id, image_url, "
                        + "is_primary, display_order) "
                        + "VALUES (?, ?, ?, 0, ?)";

                try (PreparedStatement ps
                        = conn.prepareStatement(sql)) {

                    for (String url : imageUrls) {

                        ps.setInt(1, productId);
                        ps.setInt(2, skuId);
                        ps.setString(3, url.trim());
                        ps.setInt(4, nextOrder++);

                        ps.addBatch();
                    }

                    ps.executeBatch();
                }

                ensurePrimaryImage(conn, productId, skuId);

                conn.commit();

                return imageUrls.size();

            } catch (SQLException | RuntimeException ex) {

                rollback(conn, ex);
                throw ex;

            } finally {
                restoreAutoCommit(conn, oldAutoCommit);
            }
        }
    }

    // ========================================
    // 3. ĐẶT ẢNH CHÍNH CHO SKU
    // ========================================

    /*
     * PRODUCT_IMAGES có unique filtered index
     * giới hạn mỗi SKU tối đa một ảnh chính.
     *
     * Vì vậy phải:
     * 1. Khóa SKU.
     * 2. Kiểm tra ảnh thuộc SKU.
     * 3. Bỏ trạng thái primary của ảnh cũ.
     * 4. Đặt primary cho ảnh mới.
     * 5. Commit.
     */
    public boolean setPrimaryImage(
            int productId,
            int skuId,
            int imageId) throws SQLException {

        validateIds(productId, skuId);
        validateImageId(imageId);

        try (Connection conn = getConnection()) {

            boolean oldAutoCommit = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                lockSku(conn, productId, skuId);

                if (!imageExists(
                        conn, productId, skuId, imageId)) {

                    conn.rollback();
                    return false;
                }

                String clearSql
                        = "UPDATE PRODUCT_IMAGES "
                        + "SET is_primary = 0 "
                        + "WHERE product_id = ? "
                        + "AND sku_id = ? "
                        + "AND is_primary = 1";

                try (PreparedStatement ps
                        = conn.prepareStatement(clearSql)) {

                    ps.setInt(1, productId);
                    ps.setInt(2, skuId);
                    ps.executeUpdate();
                }

                String setSql
                        = "UPDATE PRODUCT_IMAGES "
                        + "SET is_primary = 1 "
                        + "WHERE image_id = ? "
                        + "AND product_id = ? "
                        + "AND sku_id = ?";

                int updated;

                try (PreparedStatement ps
                        = conn.prepareStatement(setSql)) {

                    ps.setInt(1, imageId);
                    ps.setInt(2, productId);
                    ps.setInt(3, skuId);

                    updated = ps.executeUpdate();
                }

                if (updated != 1) {
                    throw new SQLException(
                            "Không thể đặt ảnh chính cho SKU."
                    );
                }

                conn.commit();
                return true;

            } catch (SQLException | RuntimeException ex) {

                rollback(conn, ex);
                throw ex;

            } finally {
                restoreAutoCommit(conn, oldAutoCommit);
            }
        }
    }

    // ========================================
    // 4. SẮP XẾP ẢNH SKU
    // ========================================

    /*
     * orderedImageIds phải chứa toàn bộ
     * image_id hiện tại của SKU, không trùng ID.
     *
     * Ví dụ:
     * [25, 22, 24] -> thứ tự 0, 1, 2.
     */
    public boolean reorderImages(
            int productId,
            int skuId,
            List<Integer> orderedImageIds)
            throws SQLException {

        validateIds(productId, skuId);

        if (orderedImageIds == null) {
            throw new IllegalArgumentException(
                    "Danh sách ảnh không được null."
            );
        }

        Set<Integer> submitted = new HashSet<>();

        for (Integer id : orderedImageIds) {

            if (id == null || id <= 0
                    || !submitted.add(id)) {

                throw new IllegalArgumentException(
                        "Danh sách ảnh chứa ID không hợp lệ "
                        + "hoặc bị trùng."
                );
            }
        }

        try (Connection conn = getConnection()) {

            boolean oldAutoCommit = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                lockSku(conn, productId, skuId);

                Set<Integer> existing
                        = getImageIds(conn, productId, skuId);

                if (!existing.equals(submitted)) {

                    conn.rollback();
                    return false;
                }

                String sql
                        = "UPDATE PRODUCT_IMAGES "
                        + "SET display_order = ? "
                        + "WHERE image_id = ? "
                        + "AND product_id = ? "
                        + "AND sku_id = ?";

                try (PreparedStatement ps
                        = conn.prepareStatement(sql)) {

                    for (int i = 0;
                            i < orderedImageIds.size(); i++) {

                        ps.setInt(1, i);
                        ps.setInt(2, orderedImageIds.get(i));
                        ps.setInt(3, productId);
                        ps.setInt(4, skuId);

                        if (ps.executeUpdate() != 1) {
                            throw new SQLException(
                                    "Không thể sắp xếp ảnh SKU."
                            );
                        }
                    }
                }

                conn.commit();
                return true;

            } catch (SQLException | RuntimeException ex) {

                rollback(conn, ex);
                throw ex;

            } finally {
                restoreAutoCommit(conn, oldAutoCommit);
            }
        }
    }

    // ========================================
    // 5. XÓA MỘT ẢNH SKU
    // ========================================

    /*
     * Nếu xóa ảnh chính, tự chọn ảnh còn lại
     * có display_order nhỏ nhất làm ảnh chính.
     *
     * Chỉ xóa bản ghi SQL.
     * Không xóa file vật lý trên ổ đĩa.
     */
    public boolean deleteImage(
            int productId,
            int skuId,
            int imageId) throws SQLException {

        validateIds(productId, skuId);
        validateImageId(imageId);

        try (Connection conn = getConnection()) {

            boolean oldAutoCommit = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                lockSku(conn, productId, skuId);

                String sql
                        = "DELETE FROM PRODUCT_IMAGES "
                        + "WHERE image_id = ? "
                        + "AND product_id = ? "
                        + "AND sku_id = ?";

                int affected;

                try (PreparedStatement ps
                        = conn.prepareStatement(sql)) {

                    ps.setInt(1, imageId);
                    ps.setInt(2, productId);
                    ps.setInt(3, skuId);

                    affected = ps.executeUpdate();
                }

                if (affected != 1) {

                    conn.rollback();
                    return false;
                }

                ensurePrimaryImage(conn, productId, skuId);

                conn.commit();
                return true;

            } catch (SQLException | RuntimeException ex) {

                rollback(conn, ex);
                throw ex;

            } finally {
                restoreAutoCommit(conn, oldAutoCommit);
            }
        }
    }

    // ========================================
    // 6. KHÓA SKU VÀ KIỂM TRA PRODUCT
    // ========================================
    private void lockSku(
            Connection conn,
            int productId,
            int skuId) throws SQLException {

        String sql
                = "SELECT 1 "
                + "FROM PRODUCT_SKU WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE sku_id = ? AND product_id = ?";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);
            ps.setInt(2, productId);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    throw new IllegalArgumentException(
                            "SKU không tồn tại hoặc "
                            + "không thuộc sản phẩm."
                    );
                }
            }
        }
    }

    // ========================================
    // 7. KIỂM TRA ẢNH THUỘC SKU
    // ========================================
    private boolean imageExists(
            Connection conn,
            int productId,
            int skuId,
            int imageId) throws SQLException {

        String sql
                = "SELECT 1 FROM PRODUCT_IMAGES "
                + "WHERE image_id = ? "
                + "AND product_id = ? "
                + "AND sku_id = ?";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, imageId);
            ps.setInt(2, productId);
            ps.setInt(3, skuId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // ========================================
    // 8. DANH SÁCH ID ẢNH HIỆN TẠI
    // ========================================
    private Set<Integer> getImageIds(
            Connection conn,
            int productId,
            int skuId) throws SQLException {

        Set<Integer> ids = new HashSet<>();

        String sql
                = "SELECT image_id FROM PRODUCT_IMAGES "
                + "WHERE product_id = ? AND sku_id = ?";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);
            ps.setInt(2, skuId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    ids.add(rs.getInt("image_id"));
                }
            }
        }

        return ids;
    }

    // ========================================
    // 9. TÌM THỨ TỰ ẢNH TIẾP THEO
    // ========================================
    private int getNextDisplayOrder(
            Connection conn,
            int productId,
            int skuId) throws SQLException {

        String sql
                = "SELECT MAX(display_order) AS max_order "
                + "FROM PRODUCT_IMAGES "
                + "WHERE product_id = ? "
                + "AND sku_id = ?";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);
            ps.setInt(2, skuId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    int maxOrder = rs.getInt("max_order");

                    if (rs.wasNull()) {
                        return 0;
                    }

                    if (maxOrder == Integer.MAX_VALUE) {
                        throw new IllegalArgumentException(
                                "Đã đạt giới hạn thứ tự ảnh."
                        );
                    }

                    return maxOrder + 1;
                }
            }
        }

        return 0;
    }

    // ========================================
    // 10. ĐẢM BẢO SKU CÓ ẢNH CHÍNH NẾU CÓ ẢNH
    // ========================================
    private void ensurePrimaryImage(
            Connection conn,
            int productId,
            int skuId) throws SQLException {

        String sql
                = "SELECT TOP (1) image_id, is_primary "
                + "FROM PRODUCT_IMAGES "
                + "WHERE product_id = ? "
                + "AND sku_id = ? "
                + "ORDER BY is_primary DESC, "
                + "display_order ASC, image_id ASC";

        Integer selectedId = null;
        boolean hasPrimary = false;

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);
            ps.setInt(2, skuId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    selectedId = rs.getInt("image_id");

                    hasPrimary
                            = rs.getBoolean("is_primary");
                }
            }
        }

        if (selectedId == null || hasPrimary) {
            return;
        }

        String updateSql
                = "UPDATE PRODUCT_IMAGES "
                + "SET is_primary = 1 "
                + "WHERE image_id = ? "
                + "AND product_id = ? "
                + "AND sku_id = ?";

        try (PreparedStatement ps
                = conn.prepareStatement(updateSql)) {

            ps.setInt(1, selectedId);
            ps.setInt(2, productId);
            ps.setInt(3, skuId);

            if (ps.executeUpdate() != 1) {
                throw new SQLException(
                        "Không thể thiết lập ảnh chính SKU."
                );
            }
        }
    }

    // ========================================
    // 11. VALIDATE ID
    // ========================================
    private void validateIds(int productId, int skuId) {

        if (productId <= 0 || skuId <= 0) {
            throw new IllegalArgumentException(
                    "Product ID hoặc SKU ID không hợp lệ."
            );
        }
    }

    private void validateImageId(int imageId) {

        if (imageId <= 0) {
            throw new IllegalArgumentException(
                    "Image ID không hợp lệ."
            );
        }
    }

    // ========================================
    // 12. VALIDATE URL ẢNH
    // ========================================
    private void validateImageUrls(
            List<String> imageUrls) {

        if (imageUrls == null) {
            return;
        }

        for (String url : imageUrls) {

            if (url == null
                    || url.trim().isEmpty()
                    || url.length() > 2048) {

                throw new IllegalArgumentException(
                        "Đường dẫn ảnh SKU không hợp lệ."
                );
            }
        }
    }

    // ========================================
    // 13. ROLLBACK
    // ========================================
    private void rollback(
            Connection conn,
            Exception originalException) {

        try {
            conn.rollback();

        } catch (SQLException ex) {

            originalException.addSuppressed(ex);

            LOGGER.log(
                    Level.SEVERE,
                    "Rollback SkuImageService thất bại",
                    ex
            );
        }
    }

    // ========================================
    // 14. KHÔI PHỤC AUTO COMMIT
    // ========================================
    private void restoreAutoCommit(
            Connection conn,
            boolean oldAutoCommit) {

        try {
            conn.setAutoCommit(oldAutoCommit);

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.WARNING,
                    "Không khôi phục được autoCommit",
                    ex
            );
        }
    }
}
