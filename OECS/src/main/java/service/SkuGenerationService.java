package service;

import db.DBContext;

import model.ProductSku;
import model.SkuAttributeValue;

import java.math.BigDecimal;
import java.math.RoundingMode;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class SkuGenerationService extends DBContext {

    private static final int MAX_COMBINATIONS = 200;
    private static final int MAX_SKU_CODE_LENGTH = 100;
    private static final int MAX_ATTRIBUTE_LENGTH = 255;

    // ========================================
    // 1. SINH DANH SÁCH SKU XEM TRƯỚC
    // ========================================

    /*
     * Ví dụ options:
     *
     * attributeId 3:
     * ["128GB", "256GB"]
     *
     * attributeId 10:
     * ["Đen", "Bạc", "Xanh"]
     *
     * Kết quả:
     * List<ProductSku> chứa các tổ hợp mới.
     *
     * Chưa INSERT vào database.
     *
     * price, originalPrice:
     * Đơn vị VNĐ.
     */
    public List<ProductSku> generatePreview(
            int productId,
            Map<Integer, List<String>> options,
            String skuPrefix,
            double price,
            Double originalPrice,
            int stock,
            boolean active)
            throws SQLException {

        validateBasicInput(
                productId,
                options,
                skuPrefix,
                price,
                originalPrice,
                stock
        );

        try (Connection conn = getConnection()) {

            int categoryId
                    = getProductCategoryId(
                            conn,
                            productId
                    );

            List<VariantConfig> configs
                    = loadVariantConfigs(
                            conn,
                            categoryId
                    );

            if (configs.isEmpty()) {

                throw new IllegalArgumentException(
                        "Danh mục chưa cấu hình "
                        + "thuộc tính biến thể."
                );
            }

            List<VariantDimension> dimensions
                    = prepareDimensions(
                            configs,
                            options
                    );

            List<Map<Integer, NormalizedValue>> combinations
                    = new ArrayList<>();

            generateCombinations(
                    dimensions,
                    0,
                    new HashMap<>(),
                    combinations
            );

            Set<String> existingKeys
                    = loadExistingVariantKeys(
                            conn,
                            productId,
                            dimensions
                    );

            Set<String> usedSkuCodes
                    = loadUsedSkuCodes(conn);

            List<ProductSku> preview
                    = new ArrayList<>();

            String prefix = skuPrefix.trim();

            int nextSequence = 1;

            for (Map<Integer, NormalizedValue> combination
                    : combinations) {

                String combinationKey
                        = buildCombinationKey(
                                combination
                        );

                /*
                 * Bỏ qua tổ hợp đã có SKU.
                 * Bao gồm cả SKU đang ngừng bán.
                 */
                if (existingKeys.contains(combinationKey)) {
                    continue;
                }

                String skuCode;

                /*
                 * Mã SKU phải duy nhất toàn hệ thống.
                 * Không tái sử dụng mã đã tồn tại.
                 */
                do {

                    skuCode
                            = buildSkuCode(
                                    prefix,
                                    nextSequence++
                            );

                } while (usedSkuCodes.contains(
                        skuCode.toUpperCase(
                                java.util.Locale.ROOT
                        )
                ));

                usedSkuCodes.add(
                        skuCode.toUpperCase(
                                java.util.Locale.ROOT
                        )
                );

                ProductSku sku = new ProductSku(
                        0,
                        productId,
                        skuCode,
                        price,
                        stock
                );

                sku.setOriginalPrice(originalPrice);
                sku.setActive(active);

                List<Integer> attributeIds
                        = new ArrayList<>(
                                combination.keySet()
                        );

                Collections.sort(attributeIds);

                for (Integer attributeId : attributeIds) {

                    NormalizedValue value
                            = combination.get(attributeId);

                    SkuAttributeValue attributeValue
                            = new SkuAttributeValue();

                    attributeValue.setAttributeId(
                            attributeId
                    );

                    attributeValue.setTextValue(
                            value.textValue
                    );

                    attributeValue.setNumericValue(
                            value.numericValue
                    );

                    attributeValue.setBooleanValue(
                            value.booleanValue
                    );

                    sku.getAttributeValues().add(
                            attributeValue
                    );
                }

                preview.add(sku);

                /*
                 * Chặn trùng ngay trong kết quả
                 * nếu các tổ hợp tương đương nhau.
                 */
                existingKeys.add(combinationKey);
            }

            return preview;
        }
    }

    // ========================================
    // 2. VALIDATE THÔNG TIN CHUNG
    // ========================================
    private void validateBasicInput(
            int productId,
            Map<Integer, List<String>> options,
            String skuPrefix,
            double price,
            Double originalPrice,
            int stock) {

        if (productId <= 0) {

            throw new IllegalArgumentException(
                    "Product ID không hợp lệ."
            );
        }

        if (options == null || options.isEmpty()) {

            throw new IllegalArgumentException(
                    "Chưa chọn thuộc tính để tạo SKU."
            );
        }

        if (skuPrefix == null
                || skuPrefix.trim().isEmpty()) {

            throw new IllegalArgumentException(
                    "Tiền tố mã SKU không được để trống."
            );
        }

        /*
         * Giữ chỗ cho hậu tố -001, -002...
         * Kiểm tra độ dài thực tế thêm lần nữa
         * trong buildSkuCode().
         */
        if (skuPrefix.trim().length() > 95) {

            throw new IllegalArgumentException(
                    "Tiền tố SKU quá dài."
            );
        }

        validateMoney(price, "Giá bán");

        if (originalPrice != null) {

            validateMoney(
                    originalPrice,
                    "Giá niêm yết"
            );
        }

        if (stock < 0) {

            throw new IllegalArgumentException(
                    "Tồn kho không được âm."
            );
        }
    }

    // ========================================
    // 3. VALIDATE TIỀN
    // ========================================
    private void validateMoney(
            double amount,
            String fieldName) {

        if (!Double.isFinite(amount)
                || amount < 0) {

            throw new IllegalArgumentException(
                    fieldName + " không hợp lệ."
            );
        }

        /*
         * PRODUCT_SKU.price:
         * DECIMAL(18,2).
         *
         * Do Model đang dùng double,
         * chỉ nhận giá VNĐ nguyên ở tính năng này.
         */
        BigDecimal decimal
                = BigDecimal.valueOf(amount);

        try {

            decimal = decimal.setScale(
                    0,
                    RoundingMode.UNNECESSARY
            );

        } catch (ArithmeticException ex) {

            throw new IllegalArgumentException(
                    fieldName
                    + " phải là số VNĐ nguyên."
            );
        }

        if (decimal.precision() > 16) {

            throw new IllegalArgumentException(
                    fieldName + " vượt giới hạn SQL."
            );
        }
    }

    // ========================================
    // 4. LẤY CATEGORY CỦA PRODUCT
    // ========================================
    private int getProductCategoryId(
            Connection conn,
            int productId)
            throws SQLException {

        String sql
                = "SELECT category_id, is_active "
                + "FROM PRODUCT "
                + "WHERE product_id = ?";

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
                            "Sản phẩm đã ngừng kinh doanh. "
                            + "Không thể tạo SKU hàng loạt."
                    );
                }

                return rs.getInt("category_id");
            }
        }
    }

    // ========================================
    // 5. LẤY CẤU HÌNH BIẾN THỂ
    // ========================================
    private List<VariantConfig> loadVariantConfigs(
            Connection conn,
            int categoryId)
            throws SQLException {

        List<VariantConfig> configs
                = new ArrayList<>();

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
                + "AND a.is_active = 1 "
                + "ORDER BY ca.display_order, "
                + "ca.attribute_id";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    configs.add(
                            new VariantConfig(
                                    rs.getInt("attribute_id"),
                                    rs.getString("attribute_name"),
                                    rs.getString("data_type"),
                                    rs.getBoolean("is_required")
                            )
                    );
                }
            }
        }

        return configs;
    }

    // ========================================
    // 6. CHUẨN BỊ CÁC CHIỀU BIẾN THỂ
    // ========================================
    private List<VariantDimension> prepareDimensions(
            List<VariantConfig> configs,
            Map<Integer, List<String>> options) {

        Map<Integer, VariantConfig> allowed
                = new HashMap<>();

        for (VariantConfig config : configs) {

            allowed.put(
                    config.attributeId,
                    config
            );
        }

        /*
         * Không cho gửi attribute_id
         * nằm ngoài cấu hình danh mục.
         */
        for (Integer attributeId : options.keySet()) {

            if (attributeId == null
                    || !allowed.containsKey(attributeId)) {

                throw new IllegalArgumentException(
                        "Thuộc tính biến thể "
                        + "không thuộc danh mục: "
                        + attributeId
                );
            }
        }

        List<VariantDimension> dimensions
                = new ArrayList<>();

        long combinationCount = 1;

        for (VariantConfig config : configs) {

            List<String> rawValues
                    = options.get(config.attributeId);

            if (rawValues == null
                    || rawValues.isEmpty()) {

                if (config.required) {

                    throw new IllegalArgumentException(
                            "Thiếu thuộc tính bắt buộc: "
                            + config.attributeName
                    );
                }

                continue;
            }

            List<NormalizedValue> normalized
                    = new ArrayList<>();

            Set<String> uniqueValues
                    = new HashSet<>();

            for (String rawValue : rawValues) {

                NormalizedValue value
                        = normalizeValue(
                                config,
                                rawValue
                        );

                /*
                 * Loại bỏ các giá trị bị trùng
                 * trong cùng một thuộc tính.
                 */
                if (uniqueValues.add(
                        value.canonicalValue
                )) {

                    normalized.add(value);
                }
            }

            if (normalized.isEmpty()) {

                if (config.required) {

                    throw new IllegalArgumentException(
                            "Thuộc tính không có giá trị: "
                            + config.attributeName
                    );
                }

                continue;
            }

            /*
             * Giới hạn tổ hợp trước khi sinh,
             * tránh tạo danh sách quá lớn.
             */
            if (combinationCount
                    > MAX_COMBINATIONS / normalized.size()) {

                throw new IllegalArgumentException(
                        "Số tổ hợp vượt giới hạn "
                        + MAX_COMBINATIONS + " SKU/lần."
                );
            }

            combinationCount *= normalized.size();

            dimensions.add(
                    new VariantDimension(
                            config.attributeId,
                            normalized
                    )
            );
        }

        if (dimensions.isEmpty()) {

            throw new IllegalArgumentException(
                    "Không có giá trị biến thể hợp lệ."
            );
        }

        return dimensions;
    }

    // ========================================
    // 7. CHUẨN HÓA GIÁ TRỊ THEO DATA TYPE
    // ========================================
    private NormalizedValue normalizeValue(
            VariantConfig config,
            String rawValue) {

        if (rawValue == null
                || rawValue.trim().isEmpty()) {

            throw new IllegalArgumentException(
                    "Giá trị biến thể không được trống: "
                    + config.attributeName
            );
        }

        String value = rawValue.trim();

        if ("TEXT".equals(config.dataType)) {

            if (value.length() > MAX_ATTRIBUTE_LENGTH) {

                throw new IllegalArgumentException(
                        "Giá trị vượt 255 ký tự: "
                        + config.attributeName
                );
            }

            return new NormalizedValue(
                    value,
                    null,
                    null,
                    "T:" + value
            );
        }

        if ("NUMBER".equals(config.dataType)) {

            BigDecimal number;

            try {

                number = new BigDecimal(value)
                        .setScale(
                                4,
                                RoundingMode.UNNECESSARY
                        );

            } catch (NumberFormatException
                    | ArithmeticException ex) {

                throw new IllegalArgumentException(
                        "Giá trị NUMBER không hợp lệ: "
                        + config.attributeName,
                        ex
                );
            }

            if (number.precision() > 18) {

                throw new IllegalArgumentException(
                        "Giá trị vượt DECIMAL(18,4): "
                        + config.attributeName
                );
            }

            return new NormalizedValue(
                    null,
                    number,
                    null,
                    "N:" + number.stripTrailingZeros()
                            .toPlainString()
            );
        }

        if ("BOOLEAN".equals(config.dataType)) {

            boolean booleanValue;

            if ("true".equalsIgnoreCase(value)
                    || "1".equals(value)
                    || "Có".equalsIgnoreCase(value)) {

                booleanValue = true;

            } else if ("false".equalsIgnoreCase(value)
                    || "0".equals(value)
                    || "Không".equalsIgnoreCase(value)) {

                booleanValue = false;

            } else {

                throw new IllegalArgumentException(
                        "Giá trị BOOLEAN không hợp lệ: "
                        + config.attributeName
                );
            }

            return new NormalizedValue(
                    null,
                    null,
                    booleanValue,
                    booleanValue ? "B:1" : "B:0"
            );
        }

        throw new IllegalArgumentException(
                "Kiểu thuộc tính không hợp lệ: "
                + config.attributeName
        );
    }

    // ========================================
    // 8. SINH TÍCH DESCARTES
    // ========================================
    private void generateCombinations(
            List<VariantDimension> dimensions,
            int index,
            Map<Integer, NormalizedValue> current,
            List<Map<Integer, NormalizedValue>> results) {

        if (index == dimensions.size()) {

            results.add(
                    new HashMap<>(current)
            );

            return;
        }

        VariantDimension dimension
                = dimensions.get(index);

        for (NormalizedValue value : dimension.values) {

            current.put(
                    dimension.attributeId,
                    value
            );

            generateCombinations(
                    dimensions,
                    index + 1,
                    current,
                    results
            );
        }

        current.remove(dimension.attributeId);
    }

    // ========================================
    // 9. ĐỌC TỔ HỢP SKU ĐÃ TỒN TẠI
    // ========================================
    private Set<String> loadExistingVariantKeys(
            Connection conn,
            int productId,
            List<VariantDimension> dimensions)
            throws SQLException {

        Map<Integer, Map<Integer, NormalizedValue>> bySku
                = new HashMap<>();

        String sql
                = "SELECT s.sku_id, "
                + "v.attribute_id, "
                + "v.text_value, "
                + "v.numeric_value, "
                + "v.boolean_value "
                + "FROM PRODUCT_SKU s "
                + "LEFT JOIN SKU_ATTRIBUTE_VALUE v "
                + "ON v.sku_id = s.sku_id "
                + "WHERE s.product_id = ? "
                + "ORDER BY s.sku_id, v.attribute_id";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    int skuId = rs.getInt("sku_id");

                    Map<Integer, NormalizedValue> attributes
                            = bySku.computeIfAbsent(
                                    skuId,
                                    key -> new HashMap<>()
                            );

                    int attributeId
                            = rs.getInt("attribute_id");

                    if (rs.wasNull()) {
                        continue;
                    }

                    String textValue
                            = rs.getString("text_value");

                    BigDecimal numericValue
                            = rs.getBigDecimal("numeric_value");

                    Boolean booleanValue = null;

                    boolean bit
                            = rs.getBoolean("boolean_value");

                    if (!rs.wasNull()) {
                        booleanValue = bit;
                    }

                    String canonical;

                    if (textValue != null) {

                        canonical = "T:" + textValue.trim();

                    } else if (numericValue != null) {

                        canonical
                                = "N:" + numericValue
                                        .stripTrailingZeros()
                                        .toPlainString();

                    } else if (booleanValue != null) {

                        canonical
                                = booleanValue ? "B:1" : "B:0";

                    } else {
                        continue;
                    }

                    attributes.put(
                            attributeId,
                            new NormalizedValue(
                                    textValue,
                                    numericValue,
                                    booleanValue,
                                    canonical
                            )
                    );
                }
            }
        }

        Set<Integer> selectedAttributeIds
                = new HashSet<>();

        for (VariantDimension dimension : dimensions) {

            selectedAttributeIds.add(
                    dimension.attributeId
            );
        }

        Set<String> keys = new HashSet<>();

        for (Map<Integer, NormalizedValue> attributes
                : bySku.values()) {

            /*
             * Chỉ so sánh các SKU có đúng
             * tập thuộc tính của preview.
             *
             * Stored procedure trong SQL vẫn
             * là nơi quyết định chống trùng
             * chính thức lúc lưu.
             */
            if (!attributes.keySet().equals(
                    selectedAttributeIds
            )) {
                continue;
            }

            keys.add(
                    buildCombinationKey(attributes)
            );
        }

        return keys;
    }

    // ========================================
    // 10. TẠO KHÓA SO SÁNH TỔ HỢP
    // ========================================
    private String buildCombinationKey(
            Map<Integer, NormalizedValue> attributes) {

        List<Integer> ids
                = new ArrayList<>(attributes.keySet());

        Collections.sort(ids);

        StringBuilder key = new StringBuilder();

        for (Integer attributeId : ids) {

            String value
                    = attributes.get(attributeId).canonicalValue;

            /*
             * Có độ dài kèm theo để tránh
             * nhầm lẫn nếu chuỗi chứa dấu
             * phân cách đặc biệt.
             */
            key.append(attributeId)
                    .append(':')
                    .append(value.length())
                    .append(':')
                    .append(value)
                    .append(';');
        }

        return key.toString();
    }

    // ========================================
    // 11. LẤY CÁC SKU CODE ĐÃ SỬ DỤNG
    // ========================================
    private Set<String> loadUsedSkuCodes(
            Connection conn)
            throws SQLException {

        Set<String> codes = new HashSet<>();

        String sql
                = "SELECT sku_code FROM PRODUCT_SKU";

        try (PreparedStatement ps
                = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                String code = rs.getString("sku_code");

                if (code != null) {

                    codes.add(
                            code.toUpperCase(
                                    java.util.Locale.ROOT
                            )
                    );
                }
            }
        }

        return codes;
    }

    // ========================================
    // 12. TẠO MÃ SKU TỰ ĐỘNG
    // ========================================
    private String buildSkuCode(
            String prefix,
            int sequence) {

        String code = prefix
                + "-"
                + String.format(
                        java.util.Locale.ROOT,
                        "%03d",
                        sequence
                );

        if (code.length() > MAX_SKU_CODE_LENGTH) {

            throw new IllegalArgumentException(
                    "Mã SKU sinh ra vượt quá "
                    + MAX_SKU_CODE_LENGTH + " ký tự."
            );
        }

        return code;
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
    // 14. CLASS NỘI BỘ: VARIANT DIMENSION
    // ========================================
    private static class VariantDimension {

        private final int attributeId;
        private final List<NormalizedValue> values;

        private VariantDimension(
                int attributeId,
                List<NormalizedValue> values) {

            this.attributeId = attributeId;
            this.values = values;
        }
    }

    // ========================================
    // 15. CLASS NỘI BỘ: NORMALIZED VALUE
    // ========================================
    private static class NormalizedValue {

        private final String textValue;
        private final BigDecimal numericValue;
        private final Boolean booleanValue;
        private final String canonicalValue;

        private NormalizedValue(
                String textValue,
                BigDecimal numericValue,
                Boolean booleanValue,
                String canonicalValue) {

            this.textValue = textValue;
            this.numericValue = numericValue;
            this.booleanValue = booleanValue;
            this.canonicalValue = canonicalValue;
        }
    }
}
