package service;

import db.DBContext;
import dao.SkuVariantKeyHelper;
import dao.SkuAdminInventoryAudit;

import model.ProductSku;
import model.SkuAttributeValue;

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
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import java.util.logging.Level;
import java.util.logging.Logger;

public class SkuBulkService extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(SkuBulkService.class.getName());

    private static final int MAX_SKUS_PER_BATCH = 200;
    private static final int MAX_SKU_CODE_LENGTH = 100;
    private static final int MAX_TEXT_VALUE_LENGTH = 255;

    // ========================================
    // 1. LƯU SKU HÀNG LOẠT
    // ========================================

    /*
     * Trả về danh sách sku_id đã tạo,
     * theo đúng thứ tự danh sách đầu vào.
     *
     * Nếu bất kỳ SKU nào thất bại:
     * rollback toàn bộ batch.
     *
     * Không gọi ProductSkuDAO.insert()
     * vì các phương thức DAO hiện tại
     * tự quản lý Connection riêng.
     */
    public List<Integer> insertBulk(
            int productId,
            List<ProductSku> skuList)
            throws SQLException {

        validateBatchInput(productId, skuList);

        try (Connection conn = getConnection()) {

            boolean oldAutoCommit
                    = conn.getAutoCommit();

            try {

                conn.setAutoCommit(false);

                // Khóa Product trong suốt transaction.
                int categoryId
                        = lockAndGetProductCategory(
                                conn,
                                productId
                        );

                // Chỉ lấy thuộc tính VARIANT / BOTH.
                Map<Integer, VariantConfig> configs
                        = loadVariantConfigs(
                                conn,
                                categoryId
                        );

                if (configs.isEmpty()) {

                    throw new IllegalArgumentException(
                            "Danh mục chưa cấu hình "
                            + "thuộc tính biến thể. "
                            + "Không thể tạo SKU hàng loạt."
                    );
                }

                /*
                 * Validate toàn bộ batch trước
                 * khi INSERT bản ghi đầu tiên.
                 */
                List<ValidatedSku> validatedSkus
                        = validateSkus(
                                productId,
                                skuList,
                                configs
                        );

                List<Integer> createdIds
                        = new ArrayList<>();

                for (ValidatedSku validated : validatedSkus) {

                    // 1. INSERT PRODUCT_SKU
                    int newSkuId
                            = insertSku(
                                    conn,
                                    productId,
                                    validated
                            );

                    // 2. INSERT SKU_ATTRIBUTE_VALUE
                    insertAttributeValues(
                            conn,
                            newSkuId,
                            validated.attributes
                    );

                    /*
                     * 3. Tính variant_key bằng cùng công thức SHA2_256
                     * với dữ liệu mẫu OECS_DB(6).sql.
                     * Unique index chống trùng là lớp bảo vệ cuối cùng.
                     */
                    refreshSkuVariantKey(
                            conn,
                            newSkuId
                    );
                    SkuAdminInventoryAudit.recordOpening(
                            conn, newSkuId, validated.stock);

                    createdIds.add(newSkuId);
                }

                /*
                 * Chỉ commit sau khi toàn bộ SKU
                 * và tính variant_key đều thành công.
                 */
                conn.commit();

                /*
                 * Chỉ cập nhật Model sau commit.
                 *
                 * Tránh để Model có ID giả
                 * nếu transaction bị rollback.
                 */
                for (int i = 0; i < skuList.size(); i++) {

                    skuList.get(i).setSkuId(
                            createdIds.get(i)
                    );
                }

                return createdIds;

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
    // 2. VALIDATE BATCH
    // ========================================
    private void validateBatchInput(
            int productId,
            List<ProductSku> skuList) {

        if (productId <= 0) {

            throw new IllegalArgumentException(
                    "Product ID không hợp lệ."
            );
        }

        if (skuList == null || skuList.isEmpty()) {

            throw new IllegalArgumentException(
                    "Danh sách SKU không được để trống."
            );
        }

        if (skuList.size() > MAX_SKUS_PER_BATCH) {

            throw new IllegalArgumentException(
                    "Chỉ được tạo tối đa "
                    + MAX_SKUS_PER_BATCH
                    + " SKU trong một lần."
            );
        }
    }

    // ========================================
    // 3. KHÓA PRODUCT
    // ========================================
    private int lockAndGetProductCategory(
            Connection conn,
            int productId)
            throws SQLException {

        String sql
                = "SELECT p.category_id, p.is_active, "
                + "c.is_active AS category_active "
                + "FROM PRODUCT p "
                + "WITH (UPDLOCK, HOLDLOCK) "
                + "JOIN CATEGORY c "
                + "ON c.category_id = p.category_id "
                + "WHERE p.product_id = ?";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {

                    throw new IllegalArgumentException(
                            "Không tìm thấy sản phẩm."
                    );
                }

                if (!rs.getBoolean("is_active")) {

                    throw new IllegalArgumentException(
                            "Sản phẩm đã ngừng kinh doanh."
                    );
                }

                if (!rs.getBoolean("category_active")) {

                    throw new IllegalArgumentException(
                            "Danh mục sản phẩm "
                            + "đã ngừng hoạt động."
                    );
                }

                return rs.getInt("category_id");
            }
        }
    }

    // ========================================
    // 4. LẤY CẤU HÌNH BIẾN THỂ
    // ========================================
    private Map<Integer, VariantConfig> loadVariantConfigs(
            Connection conn,
            int categoryId)
            throws SQLException {

        Map<Integer, VariantConfig> result
                = new HashMap<>();

        String sql
                = "SELECT ca.attribute_id, "
                + "ca.is_required, "
                + "a.attribute_name, "
                + "a.data_type "
                + "FROM CATEGORY_ATTRIBUTE ca "
                + "JOIN ATTRIBUTE a "
                + "ON a.attribute_id = ca.attribute_id "
                + "WHERE ca.category_id = ? "
                + "AND ca.attribute_type IN "
                + "('VARIANT', 'BOTH') "
                + "AND a.is_active = 1";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    VariantConfig config
                            = new VariantConfig(
                                    rs.getInt("attribute_id"),
                                    rs.getString("attribute_name"),
                                    rs.getString("data_type"),
                                    rs.getBoolean("is_required")
                            );

                    result.put(
                            config.attributeId,
                            config
                    );
                }
            }
        }

        return result;
    }

    // ========================================
    // 5. VALIDATE TOÀN BỘ SKU
    // ========================================
    private List<ValidatedSku> validateSkus(
            int productId,
            List<ProductSku> skuList,
            Map<Integer, VariantConfig> configs) {

        List<ValidatedSku> result
                = new ArrayList<>();

        Set<String> submittedCodes
                = new HashSet<>();

        for (int i = 0; i < skuList.size(); i++) {

            ProductSku sku = skuList.get(i);

            if (sku == null) {

                throw new IllegalArgumentException(
                        "SKU tại vị trí " + (i + 1)
                        + " không hợp lệ."
                );
            }

            if (sku.getSkuId() != 0) {

                throw new IllegalArgumentException(
                        "Tạo hàng loạt chỉ chấp nhận "
                        + "SKU mới chưa có ID."
                );
            }

            if (sku.getProductId() != productId) {

                throw new IllegalArgumentException(
                        "SKU không thuộc sản phẩm "
                        + productId
                );
            }

            String skuCode = sku.getSkuCode();

            if (skuCode == null
                    || skuCode.trim().isEmpty()) {

                throw new IllegalArgumentException(
                        "Mã SKU không được để trống."
                );
            }

            skuCode = skuCode.trim();

            if (skuCode.length()
                    > MAX_SKU_CODE_LENGTH) {

                throw new IllegalArgumentException(
                        "Mã SKU vượt quá 100 ký tự: "
                        + skuCode
                );
            }

            /*
             * Kiểm tra trùng mã trong chính batch.
             *
             * Kiểm tra độc lập với database.
             * Unique constraint của SQL Server
             * vẫn là nơi chống trùng cuối cùng.
             */
            String normalizedCode
                    = skuCode.toUpperCase(
                            Locale.ROOT
                    );

            if (!submittedCodes.add(normalizedCode)) {

                throw new IllegalArgumentException(
                        "Mã SKU bị trùng trong danh sách: "
                        + skuCode
                );
            }

            BigDecimal price
                    = validateMoney(
                            sku.getPrice(),
                            "Giá bán của " + skuCode
                    );

            BigDecimal originalPrice = null;

            if (sku.getOriginalPrice() != null) {

                originalPrice = validateMoney(
                        sku.getOriginalPrice(),
                        "Giá niêm yết của " + skuCode
                );
            }

            if (sku.getStockQuantity() < 0) {

                throw new IllegalArgumentException(
                        "Tồn kho không được âm: "
                        + skuCode
                );
            }

            List<ValidatedAttribute> attributes
                    = validateSkuAttributes(
                            sku,
                            configs
                    );

            result.add(
                    new ValidatedSku(
                            skuCode,
                            price,
                            originalPrice,
                            sku.getStockQuantity(),
                            sku.isActive(),
                            attributes
                    )
            );
        }

        return result;
    }

    // ========================================
    // 6. VALIDATE GIÁ TIỀN
    // ========================================
    private BigDecimal validateMoney(
            double value,
            String fieldName) {

        if (!Double.isFinite(value)
                || value < 0) {

            throw new IllegalArgumentException(
                    fieldName + " không hợp lệ."
            );
        }

        BigDecimal amount
                = BigDecimal.valueOf(value);

        try {

            amount = amount.setScale(
                    2,
                    RoundingMode.UNNECESSARY
            );

        } catch (ArithmeticException ex) {

            throw new IllegalArgumentException(
                    fieldName
                    + " có quá 2 chữ số thập phân."
            );
        }

        if (amount.precision() > 18) {

            throw new IllegalArgumentException(
                    fieldName
                    + " vượt DECIMAL(18,2)."
            );
        }

        return amount;
    }

    // ========================================
    // 7. VALIDATE SKU ATTRIBUTE VALUES
    // ========================================
    private List<ValidatedAttribute> validateSkuAttributes(
            ProductSku sku,
            Map<Integer, VariantConfig> configs) {

        List<SkuAttributeValue> values
                = sku.getAttributeValues();

        if (values == null) {
            values = new ArrayList<>();
        }

        List<ValidatedAttribute> validated
                = new ArrayList<>();

        Set<Integer> savedIds
                = new HashSet<>();

        for (SkuAttributeValue value : values) {

            if (value == null) {

                throw new IllegalArgumentException(
                        "Thuộc tính SKU không hợp lệ."
                );
            }

            int attributeId
                    = value.getAttributeId();

            VariantConfig config
                    = configs.get(attributeId);

            if (config == null) {

                throw new IllegalArgumentException(
                        "Attribute ID " + attributeId
                        + " không thuộc cấu hình biến thể."
                );
            }

            if (!savedIds.add(attributeId)) {

                throw new IllegalArgumentException(
                        "Thuộc tính bị trùng trong SKU "
                        + sku.getSkuCode() + ": "
                        + config.attributeName
                );
            }

            String textValue
                    = value.getTextValue();

            BigDecimal numericValue
                    = value.getNumericValue();

            Boolean booleanValue
                    = value.getBooleanValue();

            int populatedFields = 0;

            if (textValue != null) {
                populatedFields++;
            }

            if (numericValue != null) {
                populatedFields++;
            }

            if (booleanValue != null) {
                populatedFields++;
            }

            /*
             * SKU_ATTRIBUTE_VALUE yêu cầu
             * đúng một cột typed có giá trị.
             *
             * BOOLEAN false vẫn là một giá trị.
             */
            if (populatedFields != 1) {

                throw new IllegalArgumentException(
                        "Thuộc tính "
                        + config.attributeName
                        + " phải có đúng một giá trị."
                );
            }

            if ("TEXT".equals(config.dataType)) {

                if (textValue == null
                        || textValue.trim().isEmpty()) {

                    throw new IllegalArgumentException(
                            "Giá trị TEXT không hợp lệ: "
                            + config.attributeName
                    );
                }

                textValue = textValue.trim();

                if (textValue.length()
                        > MAX_TEXT_VALUE_LENGTH) {

                    throw new IllegalArgumentException(
                            "Giá trị TEXT vượt 255 ký tự: "
                            + config.attributeName
                    );
                }

                if (numericValue != null
                        || booleanValue != null) {

                    throw new IllegalArgumentException(
                            "Sai kiểu TEXT: "
                            + config.attributeName
                    );
                }

            } else if ("NUMBER".equals(config.dataType)) {

                if (numericValue == null
                        || textValue != null
                        || booleanValue != null) {

                    throw new IllegalArgumentException(
                            "Sai kiểu NUMBER: "
                            + config.attributeName
                    );
                }

                try {

                    numericValue
                            = numericValue.setScale(
                                    4,
                                    RoundingMode.UNNECESSARY
                            );

                } catch (ArithmeticException ex) {

                    throw new IllegalArgumentException(
                            "NUMBER có quá 4 chữ số "
                            + "thập phân: "
                            + config.attributeName
                    );
                }

                if (numericValue.precision() > 18) {

                    throw new IllegalArgumentException(
                            "NUMBER vượt DECIMAL(18,4): "
                            + config.attributeName
                    );
                }

            } else if ("BOOLEAN".equals(config.dataType)) {

                if (booleanValue == null
                        || textValue != null
                        || numericValue != null) {

                    throw new IllegalArgumentException(
                            "Sai kiểu BOOLEAN: "
                            + config.attributeName
                    );
                }

            } else {

                throw new IllegalArgumentException(
                        "Kiểu ATTRIBUTE không hợp lệ: "
                        + config.attributeName
                );
            }

            validated.add(
                    new ValidatedAttribute(
                            attributeId,
                            textValue,
                            numericValue,
                            booleanValue
                    )
            );
        }

        /*
         * Kiểm tra đủ thuộc tính bắt buộc.
         */
        for (VariantConfig config : configs.values()) {

            if (config.required
                    && !savedIds.contains(
                            config.attributeId)) {

                throw new IllegalArgumentException(
                        "SKU " + sku.getSkuCode()
                        + " thiếu thuộc tính bắt buộc: "
                        + config.attributeName
                );
            }
        }

        return validated;
    }

    // ========================================
    // 8. INSERT PRODUCT_SKU
    // ========================================
    private int insertSku(
            Connection conn,
            int productId,
            ValidatedSku sku)
            throws SQLException {

        String sql
                = "INSERT INTO PRODUCT_SKU "
                + "(product_id, sku_code, price, "
                + "stock_quantity, original_price, "
                + "is_active) "
                + "VALUES (?, ?, ?, ?, ?, ?)";

        try (PreparedStatement ps
                = conn.prepareStatement(
                        sql,
                        Statement.RETURN_GENERATED_KEYS
                )) {

                    ps.setInt(1, productId);

                    ps.setString(
                            2,
                            sku.skuCode
                    );

                    ps.setBigDecimal(
                            3,
                            sku.price
                    );

                    ps.setInt(
                            4,
                            sku.stock
                    );

                    if (sku.originalPrice == null) {

                        ps.setNull(
                                5,
                                Types.DECIMAL
                        );

                    } else {

                        ps.setBigDecimal(
                                5,
                                sku.originalPrice
                        );
                    }

                    ps.setBoolean(
                            6,
                            sku.active
                    );

                    if (ps.executeUpdate() != 1) {

                        throw new SQLException(
                                "Không thể thêm SKU: "
                                + sku.skuCode
                        );
                    }

                    try (ResultSet rs = ps.getGeneratedKeys()) {

                        if (rs.next()) {

                            int newSkuId = rs.getInt(1);

                            if (newSkuId > 0) {
                                return newSkuId;
                            }
                        }
                    }
                }

                throw new SQLException(
                        "Không lấy được ID SKU: "
                        + sku.skuCode
                );
    }

    // ========================================
    // 9. INSERT SKU_ATTRIBUTE_VALUE
    // ========================================
    private void insertAttributeValues(
            Connection conn,
            int skuId,
            List<ValidatedAttribute> attributes)
            throws SQLException {

        if (attributes.isEmpty()) {
            return;
        }

        String sql
                = "INSERT INTO SKU_ATTRIBUTE_VALUE "
                + "(sku_id, attribute_id, text_value, "
                + "numeric_value, boolean_value) "
                + "VALUES (?, ?, ?, ?, ?)";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            for (ValidatedAttribute attr : attributes) {

                ps.setInt(
                        1,
                        skuId
                );

                ps.setInt(
                        2,
                        attr.attributeId
                );

                if (attr.textValue == null) {

                    ps.setNull(
                            3,
                            Types.NVARCHAR
                    );

                } else {

                    ps.setNString(
                            3,
                            attr.textValue
                    );
                }

                if (attr.numericValue == null) {

                    ps.setNull(
                            4,
                            Types.DECIMAL
                    );

                } else {

                    ps.setBigDecimal(
                            4,
                            attr.numericValue
                    );
                }

                if (attr.booleanValue == null) {

                    ps.setNull(
                            5,
                            Types.BIT
                    );

                } else {

                    ps.setBoolean(
                            5,
                            attr.booleanValue
                    );
                }

                ps.addBatch();
            }

            ps.executeBatch();
        }
    }

    // ========================================
    // 10. REFRESH VARIANT KEY
    // ========================================
    private void refreshSkuVariantKey(
            Connection conn,
            int skuId) throws SQLException {
        SkuVariantKeyHelper.refresh(conn, skuId);
    }

    // ========================================
    // 11. ROLLBACK
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
                    "Rollback SKU bulk thất bại",
                    rollbackException
            );
        }
    }

    // ========================================
    // 12. KHÔI PHỤC AUTOCOMMIT
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
    // 13. CLASS NỘI BỘ: VARIANT CONFIG
    // ========================================
    private static class VariantConfig {

        private final int attributeId;
        private final String attributeName;
        private final String dataType;
        private final boolean required;

        private VariantConfig(
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
    // 14. CLASS NỘI BỘ: VALIDATED ATTRIBUTE
    // ========================================
    private static class ValidatedAttribute {

        private final int attributeId;
        private final String textValue;
        private final BigDecimal numericValue;
        private final Boolean booleanValue;

        private ValidatedAttribute(
                int attributeId,
                String textValue,
                BigDecimal numericValue,
                Boolean booleanValue) {

            this.attributeId = attributeId;
            this.textValue = textValue;
            this.numericValue = numericValue;
            this.booleanValue = booleanValue;
        }
    }

    // ========================================
    // 15. CLASS NỘI BỘ: VALIDATED SKU
    // ========================================
    private static class ValidatedSku {

        private final String skuCode;
        private final BigDecimal price;
        private final BigDecimal originalPrice;
        private final int stock;
        private final boolean active;

        private final List<ValidatedAttribute> attributes;

        private ValidatedSku(
                String skuCode,
                BigDecimal price,
                BigDecimal originalPrice,
                int stock,
                boolean active,
                List<ValidatedAttribute> attributes) {

            this.skuCode = skuCode;
            this.price = price;
            this.originalPrice = originalPrice;
            this.stock = stock;
            this.active = active;
            this.attributes = attributes;
        }
    }
}
