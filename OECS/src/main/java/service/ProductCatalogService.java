package service;

import db.DBContext;
import model.Product;
import model.ProductSpec;

import java.math.BigDecimal;
import java.math.RoundingMode;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import java.util.logging.Level;
import java.util.logging.Logger;

public class ProductCatalogService extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(
                    ProductCatalogService.class.getName()
            );

    // ========================================
    // 1. TẠO SẢN PHẨM TRONG MỘT TRANSACTION
    // ========================================
    public int createProduct(
            Product product,
            List<ProductSpec> specifications,
            List<String> galleryUrls)
            throws SQLException {

        validateProduct(product);
        validateGalleryUrls(galleryUrls);

        try (Connection conn = getConnection()) {

            boolean oldAutoCommit = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                validateReferences(
                        conn,
                        product,
                        null
                );

                List<ValidatedSpec> validatedSpecs
                        = validateSpecifications(
                                conn,
                                product.getCategoryId(),
                                specifications
                        );

                int productId
                        = insertProduct(conn, product);

                insertSpecifications(
                        conn,
                        productId,
                        validatedSpecs
                );

                insertGalleryImages(
                        conn,
                        productId,
                        galleryUrls
                );

                conn.commit();

                product.setProductId(productId);

                return productId;

            } catch (SQLException | RuntimeException ex) {

                rollback(conn, ex);
                throw ex;

            } finally {

                restoreAutoCommit(
                        conn,
                        oldAutoCommit
                );
            }
        }
    }

    // ========================================
    // 2. CẬP NHẬT SẢN PHẨM TRONG TRANSACTION
    // ========================================
    public boolean updateProduct(
            Product product,
            List<ProductSpec> specifications,
            List<String> newGalleryUrls,
            List<Integer> deleteImageIds)
            throws SQLException {

        validateProduct(product);
        validateGalleryUrls(newGalleryUrls);
        validateDeleteImageIds(deleteImageIds);

        if (product.getProductId() <= 0) {

            throw new IllegalArgumentException(
                    "Product ID không hợp lệ."
            );
        }

        try (Connection conn = getConnection()) {

            boolean oldAutoCommit = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                ProductIdentity existing
                        = lockProduct(
                                conn,
                                product.getProductId()
                        );

                if (existing == null) {

                    conn.rollback();
                    return false;
                }

                if (existing.categoryId
                        != product.getCategoryId()) {

                    throw new IllegalArgumentException(
                            "Không thể đổi danh mục trực tiếp. "
                            + "Cần thực hiện quy trình chuyển "
                            + "danh mục riêng."
                    );
                }

                validateReferences(
                        conn,
                        product,
                        existing
                );

                List<ValidatedSpec> validatedSpecs
                        = validateSpecifications(
                                conn,
                                product.getCategoryId(),
                                specifications
                        );

                /*
                 * Không được âm thầm xóa các thông số
                 * cũ đã mất cấu hình hoặc bị vô hiệu hóa.
                 *
                 * Nếu có dữ liệu như vậy, yêu cầu
                 * quản trị viên xử lý cấu hình trước.
                 */
                validateExistingSpecifications(
                        conn,
                        product.getProductId(),
                        product.getCategoryId()
                );

                int affected
                        = updateProductRow(conn, product);

                if (affected != 1) {

                    throw new SQLException(
                            "Không thể cập nhật PRODUCT."
                    );
                }

                deleteAllSpecifications(
                        conn,
                        product.getProductId()
                );

                insertSpecifications(
                        conn,
                        product.getProductId(),
                        validatedSpecs
                );

                deleteGalleryImages(
                        conn,
                        product.getProductId(),
                        deleteImageIds
                );

                insertGalleryImages(
                        conn,
                        product.getProductId(),
                        newGalleryUrls
                );

                conn.commit();

                return true;

            } catch (SQLException | RuntimeException ex) {

                rollback(conn, ex);
                throw ex;

            } finally {

                restoreAutoCommit(
                        conn,
                        oldAutoCommit
                );
            }
        }
    }

    // ========================================
    // 3. INSERT PRODUCT
    // ========================================
    private int insertProduct(
            Connection conn,
            Product product)
            throws SQLException {

        String sql
                = "INSERT INTO PRODUCT "
                + "(category_id, brand_id, "
                + "product_name, model_code, "
                + "description, image_url, is_active) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement ps
                = conn.prepareStatement(
                        sql,
                        Statement.RETURN_GENERATED_KEYS
                )) {

                    ps.setInt(1, product.getCategoryId());
                    ps.setInt(2, product.getBrandId());

                    ps.setNString(
                            3,
                            product.getProductName().trim()
                    );

                    setNullableString(
                            ps,
                            4,
                            product.getModelCode(),
                            Types.VARCHAR
                    );

                    setNullableString(
                            ps,
                            5,
                            product.getDescription(),
                            Types.NVARCHAR
                    );

                    setNullableString(
                            ps,
                            6,
                            product.getImageUrl(),
                            Types.VARCHAR
                    );

                    ps.setBoolean(7, product.isActive());

                    if (ps.executeUpdate() != 1) {

                        throw new SQLException(
                                "Không thể tạo PRODUCT."
                        );
                    }

                    try (ResultSet rs = ps.getGeneratedKeys()) {

                        if (rs.next()) {

                            int productId = rs.getInt(1);

                            if (productId > 0) {
                                return productId;
                            }
                        }
                    }
                }

                throw new SQLException(
                        "Không lấy được ID của PRODUCT mới."
                );
    }

    // ========================================
    // 4. UPDATE PRODUCT
    // ========================================
    private int updateProductRow(
            Connection conn,
            Product product)
            throws SQLException {

        String sql
                = "UPDATE PRODUCT SET "
                + "product_name = ?, "
                + "brand_id = ?, "
                + "model_code = ?, "
                + "description = ?, "
                + "image_url = COALESCE(?, image_url), "
                + "updated_at = SYSDATETIME() "
                + "WHERE product_id = ? "
                + "AND category_id = ?";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setNString(
                    1,
                    product.getProductName().trim()
            );

            ps.setInt(2, product.getBrandId());

            setNullableString(
                    ps,
                    3,
                    product.getModelCode(),
                    Types.VARCHAR
            );

            setNullableString(
                    ps,
                    4,
                    product.getDescription(),
                    Types.NVARCHAR
            );

            setNullableString(
                    ps,
                    5,
                    product.getImageUrl(),
                    Types.VARCHAR
            );

            ps.setInt(6, product.getProductId());
            ps.setInt(7, product.getCategoryId());

            return ps.executeUpdate();
        }
    }

    // ========================================
    // 5. KHÓA PRODUCT KHI CẬP NHẬT
    // ========================================
    private ProductIdentity lockProduct(
            Connection conn,
            int productId)
            throws SQLException {

        String sql
                = "SELECT category_id, brand_id "
                + "FROM PRODUCT WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE product_id = ?";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    return new ProductIdentity(
                            rs.getInt("category_id"),
                            rs.getInt("brand_id")
                    );
                }
            }
        }

        return null;
    }

    // ========================================
    // 6. KIỂM TRA THÔNG TIN PRODUCT
    // ========================================
    private void validateProduct(Product product) {

        if (product == null) {

            throw new IllegalArgumentException(
                    "Product không được null."
            );
        }

        if (product.getCategoryId() <= 0
                || product.getBrandId() <= 0) {

            throw new IllegalArgumentException(
                    "Danh mục hoặc thương hiệu không hợp lệ."
            );
        }

        String name = product.getProductName();

        if (name == null
                || name.trim().isEmpty()
                || name.trim().length() > 255) {

            throw new IllegalArgumentException(
                    "Tên sản phẩm phải có từ 1 đến 255 ký tự."
            );
        }

        if (product.getModelCode() != null
                && product.getModelCode().length() > 100) {

            throw new IllegalArgumentException(
                    "Mã model vượt quá 100 ký tự."
            );
        }

        if (product.getImageUrl() != null
                && (product.getImageUrl().trim().isEmpty()
                || product.getImageUrl().length() > 2048)) {

            throw new IllegalArgumentException(
                    "Đường dẫn ảnh đại diện không hợp lệ."
            );
        }
    }

    // ========================================
    // 7. KIỂM TRA CATEGORY VÀ BRAND
    // ========================================
    private void validateReferences(
            Connection conn,
            Product product,
            ProductIdentity existing)
            throws SQLException {

        String sql
                = "SELECT "
                + "(SELECT is_active FROM CATEGORY "
                + "WHERE category_id = ?) AS category_active, "
                + "(SELECT is_active FROM BRAND "
                + "WHERE brand_id = ?) AS brand_active";

        Boolean categoryActive;
        Boolean brandActive;

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, product.getCategoryId());
            ps.setInt(2, product.getBrandId());

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {

                    throw new SQLException(
                            "Không kiểm tra được CATEGORY/BRAND."
                    );
                }

                categoryActive
                        = readNullableBoolean(
                                rs,
                                "category_active"
                        );

                brandActive
                        = readNullableBoolean(
                                rs,
                                "brand_active"
                        );
            }
        }

        /*
         * Đã đóng ResultSet trước khi tiếp tục.
         */
        if (categoryActive == null
                || brandActive == null) {

            throw new IllegalArgumentException(
                    "Danh mục hoặc thương hiệu không tồn tại."
            );
        }

        if (existing == null) {

            if (!categoryActive || !brandActive) {

                throw new IllegalArgumentException(
                        "Danh mục và thương hiệu "
                        + "phải đang hoạt động."
                );
            }

            return;
        }

        /*
         * Khi sửa sản phẩm:
         * - Category đã được khóa và giữ nguyên.
         * - Cho phép giữ category cũ đã ngừng dùng.
         * - Cho phép giữ brand cũ đã ngừng dùng.
         * - Không cho đổi sang brand khác đã ngừng dùng.
         */
        if (!brandActive
                && existing.brandId
                != product.getBrandId()) {

            throw new IllegalArgumentException(
                    "Không thể chuyển sang thương hiệu "
                    + "đã ngừng sử dụng."
            );
        }
    }

    // ========================================
    // 8. BOOLEAN NULLABLE TỪ SQL
    // ========================================
    private Boolean readNullableBoolean(
            ResultSet rs,
            String column)
            throws SQLException {

        boolean value = rs.getBoolean(column);

        return rs.wasNull() ? null : value;
    }

    // ========================================
    // 9. VALIDATE SPECIFICATIONS
    // ========================================
    private List<ValidatedSpec> validateSpecifications(
            Connection conn,
            int categoryId,
            List<ProductSpec> specifications)
            throws SQLException {

        List<ProductSpec> input
                = specifications == null
                        ? new ArrayList<>()
                        : specifications;

        Map<Integer, SpecConfig> configs
                = loadSpecificationConfigs(
                        conn,
                        categoryId
                );

        Set<Integer> submittedIds
                = new HashSet<>();

        Set<Integer> savedIds
                = new HashSet<>();

        List<ValidatedSpec> validated
                = new ArrayList<>();

        for (ProductSpec spec : input) {

            if (spec == null) {

                throw new IllegalArgumentException(
                        "Thông số kỹ thuật không hợp lệ."
                );
            }

            int attributeId = spec.getAttributeId();

            SpecConfig config
                    = configs.get(attributeId);

            if (config == null) {

                throw new IllegalArgumentException(
                        "Thuộc tính không thuộc danh mục: "
                        + attributeId
                );
            }

            if (!submittedIds.add(attributeId)) {

                throw new IllegalArgumentException(
                        "Thuộc tính bị trùng: "
                        + config.attributeName
                );
            }

            String rawValue = spec.getValue();

            String value = rawValue == null
                    ? ""
                    : rawValue.trim();

            if (value.isEmpty()) {

                if (config.required) {

                    throw new IllegalArgumentException(
                            "Thiếu thông số bắt buộc: "
                            + config.attributeName
                    );
                }

                continue;
            }

            if (value.length() > 255) {

                throw new IllegalArgumentException(
                        "Giá trị vượt quá 255 ký tự: "
                        + config.attributeName
                );
            }

            BigDecimal numericValue = null;
            Boolean booleanValue = null;

            if ("NUMBER".equals(config.dataType)) {

                try {

                    BigDecimal parsed
                            = new BigDecimal(value);

                    numericValue
                            = parsed.setScale(
                                    4,
                                    RoundingMode.UNNECESSARY
                            );

                    if (numericValue.precision() > 18) {

                        throw new IllegalArgumentException(
                                "Giá trị vượt DECIMAL(18,4): "
                                + config.attributeName
                        );
                    }

                } catch (NumberFormatException
                        | ArithmeticException ex) {

                    throw new IllegalArgumentException(
                            "Giá trị NUMBER không hợp lệ: "
                            + config.attributeName,
                            ex
                    );
                }

            } else if ("BOOLEAN".equals(config.dataType)) {

                booleanValue
                        = parseBooleanSpec(
                                value,
                                config.attributeName
                        );

                value = booleanValue
                        ? "true"
                        : "false";

            } else if (!"TEXT".equals(config.dataType)) {

                throw new IllegalArgumentException(
                        "Kiểu dữ liệu không hợp lệ: "
                        + config.attributeName
                );
            }

            savedIds.add(attributeId);

            validated.add(
                    new ValidatedSpec(
                            attributeId,
                            value,
                            numericValue,
                            booleanValue
                    )
            );
        }

        /*
         * Kiểm tra trên savedIds,
         * không phải submittedIds.
         *
         * Attribute bắt buộc có gửi ID
         * nhưng giá trị trống vẫn bị từ chối.
         */
        for (SpecConfig config : configs.values()) {

            if (config.required
                    && !savedIds.contains(
                            config.attributeId)) {

                throw new IllegalArgumentException(
                        "Thiếu thông số bắt buộc: "
                        + config.attributeName
                );
            }
        }

        return validated;
    }

    // ========================================
    // 10. PARSE BOOLEAN SPEC
    // ========================================
    private boolean parseBooleanSpec(
            String value,
            String attributeName) {

        if ("true".equalsIgnoreCase(value)
                || "1".equals(value)
                || "Có".equalsIgnoreCase(value)) {

            return true;
        }

        if ("false".equalsIgnoreCase(value)
                || "0".equals(value)
                || "Không".equalsIgnoreCase(value)) {

            return false;
        }

        throw new IllegalArgumentException(
                "Giá trị BOOLEAN không hợp lệ: "
                + attributeName
        );
    }

    // ========================================
    // 11. LẤY CẤU HÌNH SPEC CỦA CATEGORY
    // ========================================
    private Map<Integer, SpecConfig> loadSpecificationConfigs(
            Connection conn,
            int categoryId)
            throws SQLException {

        Map<Integer, SpecConfig> configs
                = new HashMap<>();

        String sql
                = "SELECT "
                + "ca.attribute_id, "
                + "ca.is_required, "
                + "a.attribute_name, "
                + "a.data_type "
                + "FROM CATEGORY_ATTRIBUTE ca "
                + "JOIN ATTRIBUTE a "
                + "ON a.attribute_id = ca.attribute_id "
                + "WHERE ca.category_id = ? "
                + "AND ca.attribute_type IN "
                + "('SPECIFICATION', 'BOTH') "
                + "AND a.is_active = 1";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    SpecConfig config
                            = new SpecConfig(
                                    rs.getInt("attribute_id"),
                                    rs.getString("attribute_name"),
                                    rs.getString("data_type"),
                                    rs.getBoolean("is_required")
                            );

                    configs.put(
                            config.attributeId,
                            config
                    );
                }
            }
        }

        return configs;
    }

    // ========================================
    // 12. PHÁT HIỆN SPEC CŨ MẤT CẤU HÌNH
    // ========================================
    private void validateExistingSpecifications(
            Connection conn,
            int productId,
            int categoryId)
            throws SQLException {

        String sql
                = "SELECT TOP (1) ps.attribute_id "
                + "FROM PRODUCT_SPECIFICATION ps "
                + "LEFT JOIN CATEGORY_ATTRIBUTE ca "
                + "ON ca.attribute_id = ps.attribute_id "
                + "AND ca.category_id = ? "
                + "AND ca.attribute_type IN "
                + "('SPECIFICATION', 'BOTH') "
                + "LEFT JOIN ATTRIBUTE a "
                + "ON a.attribute_id = ps.attribute_id "
                + "AND a.is_active = 1 "
                + "WHERE ps.product_id = ? "
                + "AND (ca.attribute_id IS NULL "
                + "OR a.attribute_id IS NULL)";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);
            ps.setInt(2, productId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    throw new IllegalArgumentException(
                            "Sản phẩm có thông số cũ chưa "
                            + "được cấu hình hợp lệ. "
                            + "Attribute ID: "
                            + rs.getInt("attribute_id")
                    );
                }
            }
        }
    }

    // ========================================
    // 13. INSERT SPECIFICATIONS
    // ========================================
    private void insertSpecifications(
            Connection conn,
            int productId,
            List<ValidatedSpec> specifications)
            throws SQLException {

        if (specifications.isEmpty()) {
            return;
        }

        String sql
                = "INSERT INTO PRODUCT_SPECIFICATION "
                + "(product_id, attribute_id, value, "
                + "numeric_value, boolean_value) "
                + "VALUES (?, ?, ?, ?, ?)";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            for (ValidatedSpec spec : specifications) {

                ps.setInt(1, productId);
                ps.setInt(2, spec.attributeId);

                /*
                 * PRODUCT_SPECIFICATION.value
                 * vẫn NOT NULL trong SQL V2.
                 */
                ps.setNString(3, spec.value);

                if (spec.numericValue == null) {

                    ps.setNull(4, Types.DECIMAL);

                } else {

                    ps.setBigDecimal(
                            4,
                            spec.numericValue
                    );
                }

                if (spec.booleanValue == null) {

                    ps.setNull(5, Types.BIT);

                } else {

                    ps.setBoolean(
                            5,
                            spec.booleanValue
                    );
                }

                ps.addBatch();
            }

            ps.executeBatch();
        }
    }

    // ========================================
    // 14. XÓA SPECIFICATIONS CŨ
    // ========================================
    private void deleteAllSpecifications(
            Connection conn,
            int productId)
            throws SQLException {

        String sql
                = "DELETE FROM PRODUCT_SPECIFICATION "
                + "WHERE product_id = ?";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);
            ps.executeUpdate();
        }
    }

    // ========================================
    // 15. KIỂM TRA ĐƯỜNG DẪN ẢNH
    // ========================================
    private void validateGalleryUrls(
            List<String> galleryUrls) {

        if (galleryUrls == null) {
            return;
        }

        for (String url : galleryUrls) {

            if (url == null
                    || url.trim().isEmpty()
                    || url.length() > 2048) {

                throw new IllegalArgumentException(
                        "Đường dẫn ảnh gallery không hợp lệ."
                );
            }
        }
    }

    // ========================================
    // 16. THÊM GALLERY IMAGES
    // ========================================
    private void insertGalleryImages(
            Connection conn,
            int productId,
            List<String> galleryUrls)
            throws SQLException {

        if (galleryUrls == null || galleryUrls.isEmpty()) {
            return;
        }

        /*
         * Lấy vị trí tiếp theo để không
         * trùng display_order khi cập nhật.
         */
        int nextOrder
                = getNextGalleryOrder(
                        conn,
                        productId
                );

        String sql
                = "INSERT INTO PRODUCT_IMAGES "
                + "(product_id, sku_id, image_url, "
                + "is_primary, display_order) "
                + "VALUES (?, NULL, ?, 0, ?)";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            for (String url : galleryUrls) {

                ps.setInt(1, productId);
                ps.setString(2, url.trim());
                ps.setInt(3, nextOrder++);

                ps.addBatch();
            }

            ps.executeBatch();
        }
    }

    // ========================================
    // 17. VỊ TRÍ TIẾP THEO CỦA GALLERY
    // ========================================
    private int getNextGalleryOrder(
            Connection conn,
            int productId)
            throws SQLException {

        String sql
                = "SELECT ISNULL(MAX(display_order), -1) + 1 "
                + "AS next_order "
                + "FROM PRODUCT_IMAGES WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE product_id = ? "
                + "AND sku_id IS NULL";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt("next_order");
                }
            }
        }

        return 0;
    }

    // ========================================
    // 18. KIỂM TRA ID ẢNH CẦN XÓA
    // ========================================
    private void validateDeleteImageIds(
            List<Integer> imageIds) {

        if (imageIds == null) {
            return;
        }

        for (Integer id : imageIds) {

            if (id == null || id <= 0) {

                throw new IllegalArgumentException(
                        "Image ID không hợp lệ."
                );
            }
        }
    }

    // ========================================
    // 19. XÓA GALLERY CHUNG
    // ========================================
    private void deleteGalleryImages(
            Connection conn,
            int productId,
            List<Integer> imageIds)
            throws SQLException {

        if (imageIds == null || imageIds.isEmpty()) {
            return;
        }

        Set<Integer> uniqueIds
                = new HashSet<>(imageIds);

        String sql
                = "DELETE FROM PRODUCT_IMAGES "
                + "WHERE image_id = ? "
                + "AND product_id = ? "
                + "AND sku_id IS NULL";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            for (Integer imageId : uniqueIds) {

                ps.setInt(1, imageId);
                ps.setInt(2, productId);

                if (ps.executeUpdate() != 1) {

                    throw new IllegalArgumentException(
                            "Ảnh không thuộc gallery chung "
                            + "hoặc không tồn tại. ID: "
                            + imageId
                    );
                }
            }
        }
    }

    // ========================================
    // 20. SET STRING NULLABLE
    // ========================================
    private void setNullableString(
            PreparedStatement ps,
            int index,
            String value,
            int sqlType)
            throws SQLException {

        if (value == null) {

            ps.setNull(index, sqlType);

        } else if (sqlType == Types.NVARCHAR) {

            ps.setNString(index, value);

        } else {

            ps.setString(index, value);
        }
    }

    // ========================================
    // 21. ROLLBACK
    // ========================================
    private void rollback(
            Connection conn,
            Exception originalException) {

        try {

            conn.rollback();

        } catch (SQLException rollbackException) {

            originalException.addSuppressed(
                    rollbackException
            );

            LOGGER.log(
                    Level.SEVERE,
                    "Rollback ProductCatalogService thất bại",
                    rollbackException
            );
        }
    }

    // ========================================
    // 22. KHÔI PHỤC AUTOCOMMIT
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

    // ========================================
    // 23. CLASS NỘI BỘ: PRODUCT IDENTITY
    // ========================================
    private static class ProductIdentity {

        private final int categoryId;
        private final int brandId;

        private ProductIdentity(
                int categoryId,
                int brandId) {

            this.categoryId = categoryId;
            this.brandId = brandId;
        }
    }

    // ========================================
    // 24. CLASS NỘI BỘ: SPEC CONFIG
    // ========================================
    private static class SpecConfig {

        private final int attributeId;
        private final String attributeName;
        private final String dataType;
        private final boolean required;

        private SpecConfig(
                int attributeId,
                String attributeName,
                String dataType,
                boolean required) {

            this.attributeId = attributeId;
            this.attributeName = attributeName;
            this.dataType = dataType;
            this.required = required;
        }
    }

    // ========================================
    // 25. CLASS NỘI BỘ: VALIDATED SPEC
    // ========================================
    private static class ValidatedSpec {

        private final int attributeId;
        private final String value;
        private final BigDecimal numericValue;
        private final Boolean booleanValue;

        private ValidatedSpec(
                int attributeId,
                String value,
                BigDecimal numericValue,
                Boolean booleanValue) {

            this.attributeId = attributeId;
            this.value = value;
            this.numericValue = numericValue;
            this.booleanValue = booleanValue;
        }
    }
}
