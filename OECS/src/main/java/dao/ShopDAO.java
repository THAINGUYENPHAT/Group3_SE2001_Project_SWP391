package dao;

import db.DBContext;

import model.Brand;
import model.Category;
import model.Product;
import model.ProductImage;
import model.ProductSku;
import model.ProductSpec;
import model.SkuAttributeValue;

import java.math.BigDecimal;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.text.Normalizer;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import java.util.logging.Level;
import java.util.logging.Logger;

public class ShopDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(ShopDAO.class.getName());

    // ========================================
    // 1. DANH SÁCH SẢN PHẨM
    // ========================================
    public List<Product> getCatalogProducts() {

        return getFilteredCatalog(
                null,
                null,
                null,
                null,
                null
        );
    }

    // ========================================
    // 2. CHI TIẾT SẢN PHẨM
    // ========================================
    public Product getProductDetail(int productId) {

        String sql
                = "SELECT "
                + "p.product_id, "
                + "p.product_name, "
                + "p.description, "
                + "p.created_at, "
                + "p.image_url, "
                + "p.model_code, "
                + "c.category_id, "
                + "c.category_name, "
                + "b.brand_id, "
                + "b.brand_name "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c "
                + "ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b "
                + "ON p.brand_id = b.brand_id "
                + "WHERE p.product_id = ? "
                + "AND p.is_active = 1";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    Product product = mapProduct(rs);

                    product.setModelCode(
                            rs.getString("model_code")
                    );

                    return product;
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy chi tiết sản phẩm",
                    ex
            );
        }

        return null;
    }

    // ========================================
    // 3. LẤY SKU ĐANG KINH DOANH
    // ========================================
    public List<ProductSku> getProductSkus(
            int productId) {

        List<ProductSku> skus = new ArrayList<>();

        String sql
                = "SELECT "
                + "sku_id, "
                + "product_id, "
                + "sku_code, "
                + "price, "
                + "original_price, "
                + "stock_quantity, "
                + "is_active "
                + "FROM PRODUCT_SKU "
                + "WHERE product_id = ? "
                + "AND is_active = 1 "
                + "ORDER BY price ASC, sku_id ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            Map<Integer, ProductSku> skuMap
                    = new LinkedHashMap<>();

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    ProductSku sku = new ProductSku(
                            rs.getInt("sku_id"),
                            rs.getInt("product_id"),
                            rs.getString("sku_code"),
                            rs.getDouble("price"),
                            rs.getInt("stock_quantity")
                    );

                    BigDecimal originalPrice
                            = rs.getBigDecimal("original_price");

                    if (originalPrice != null) {

                        sku.setOriginalPrice(
                                originalPrice.doubleValue()
                        );
                    }

                    sku.setActive(
                            rs.getBoolean("is_active")
                    );

                    skus.add(sku);

                    skuMap.put(
                            sku.getSkuId(),
                            sku
                    );
                }
            }

            if (!skuMap.isEmpty()) {

                loadSkuAttributeValues(
                        conn,
                        productId,
                        skuMap
                );
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy danh sách SKU",
                    ex
            );
        }

        return skus;
    }

    // ========================================
    // 4. LẤY BIẾN THỂ CỦA SKU
    // ========================================
    private void loadSkuAttributeValues(
            Connection conn,
            int productId,
            Map<Integer, ProductSku> skuMap)
            throws SQLException {

        String sql
                = "SELECT "
                + "v.sku_id, "
                + "v.attribute_id, "
                + "a.attribute_name, "
                + "v.text_value, "
                + "v.numeric_value, "
                + "v.boolean_value "
                + "FROM SKU_ATTRIBUTE_VALUE v "
                + "INNER JOIN PRODUCT_SKU s "
                + "ON v.sku_id = s.sku_id "
                + "INNER JOIN ATTRIBUTE a "
                + "ON v.attribute_id = a.attribute_id "
                + "WHERE s.product_id = ? "
                + "AND s.is_active = 1 "
                + "ORDER BY v.sku_id, v.attribute_id";

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    int skuId = rs.getInt("sku_id");

                    ProductSku sku = skuMap.get(skuId);

                    if (sku == null) {
                        continue;
                    }

                    SkuAttributeValue value
                            = new SkuAttributeValue();

                    value.setAttributeId(
                            rs.getInt("attribute_id")
                    );

                    value.setAttributeName(
                            rs.getString("attribute_name")
                    );

                    value.setTextValue(
                            rs.getString("text_value")
                    );

                    value.setNumericValue(
                            rs.getBigDecimal("numeric_value")
                    );

                    boolean bit
                            = rs.getBoolean("boolean_value");

                    if (!rs.wasNull()) {
                        value.setBooleanValue(bit);
                    }

                    sku.getAttributeValues().add(value);
                }
            }
        }
    }

    public List<ProductSpec> getProductSpecs(int productId) {

        List<ProductSpec> specs = new ArrayList<>();

        String sql
                = "SELECT "
                + "ps.attribute_id, "
                + "a.attribute_name, "
                + "ps.value, "
                + "ca.group_name, "
                + "COALESCE(ca.display_order, 2147483647) AS display_order "
                + "FROM dbo.PRODUCT_SPECIFICATION ps "
                + "INNER JOIN dbo.PRODUCT p "
                + "ON p.product_id = ps.product_id "
                + "INNER JOIN dbo.ATTRIBUTE a "
                + "ON a.attribute_id = ps.attribute_id "
                + "LEFT JOIN dbo.CATEGORY_ATTRIBUTE ca "
                + "ON ca.category_id = p.category_id "
                + "AND ca.attribute_id = ps.attribute_id "
                + "WHERE ps.product_id = ? "
                + "ORDER BY display_order ASC, ps.attribute_id ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    ProductSpec spec = new ProductSpec(
                            rs.getInt("attribute_id"),
                            rs.getString("attribute_name"),
                            rs.getString("value")
                    );

                    spec.setProductId(productId);
                    spec.setGroupName(
                            rs.getString("group_name")
                    );
                    spec.setDisplayOrder(
                            rs.getInt("display_order")
                    );

                    specs.add(spec);
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi lay thong so ky thuat san pham",
                    ex
            );

            throw new IllegalStateException(
                    "Khong the tai thong so ky thuat.",
                    ex
            );
        }

        return specs;
    }

    // ========================================
    // 6. GALLERY CHUNG CỦA SẢN PHẨM
    // ========================================
    public List<ProductImage> getProductImages(
            int productId) {

        List<ProductImage> images = new ArrayList<>();

        /*
         * Chỉ lấy ảnh chung của Product.
         *
         * Ảnh riêng của SKU được truy vấn
         * trong getSkuImagesByProduct().
         */
        String sql
                = "SELECT "
                + "image_id, "
                + "product_id, "
                + "image_url, "
                + "is_primary, "
                + "display_order, "
                + "alt_text "
                + "FROM PRODUCT_IMAGES "
                + "WHERE product_id = ? "
                + "AND sku_id IS NULL "
                + "ORDER BY is_primary DESC, "
                + "display_order ASC, "
                + "image_id ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    ProductImage image = new ProductImage(
                            rs.getInt("image_id"),
                            rs.getInt("product_id"),
                            rs.getString("image_url")
                    );

                    image.setPrimary(
                            rs.getBoolean("is_primary")
                    );

                    image.setDisplayOrder(
                            rs.getInt("display_order")
                    );

                    image.setAltText(
                            rs.getString("alt_text")
                    );

                    images.add(image);
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy gallery sản phẩm",
                    ex
            );
        }

        return images;
    }

    // ========================================
    // 7. GALLERY RIÊNG CỦA SKU
    // ========================================
    public Map<Integer, List<ProductImage>>
            getSkuImagesByProduct(int productId) {

        Map<Integer, List<ProductImage>> result
                = new LinkedHashMap<>();

        /*
         * Truy vấn một lần cho tất cả SKU.
         *
         * Key   = sku_id
         * Value = danh sách ảnh của SKU
         */
        String sql
                = "SELECT "
                + "pi.image_id, "
                + "pi.product_id, "
                + "pi.sku_id, "
                + "pi.image_url, "
                + "pi.is_primary, "
                + "pi.display_order, "
                + "pi.alt_text "
                + "FROM PRODUCT_IMAGES pi "
                + "INNER JOIN PRODUCT_SKU s "
                + "ON pi.sku_id = s.sku_id "
                + "WHERE pi.product_id = ? "
                + "AND s.product_id = ? "
                + "AND s.is_active = 1 "
                + "ORDER BY pi.sku_id, "
                + "pi.is_primary DESC, "
                + "pi.display_order ASC, "
                + "pi.image_id ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);
            ps.setInt(2, productId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    int skuId = rs.getInt("sku_id");

                    ProductImage image = new ProductImage(
                            rs.getInt("image_id"),
                            rs.getInt("product_id"),
                            rs.getString("image_url")
                    );

                    image.setSkuId(skuId);

                    image.setPrimary(
                            rs.getBoolean("is_primary")
                    );

                    image.setDisplayOrder(
                            rs.getInt("display_order")
                    );

                    image.setAltText(
                            rs.getString("alt_text")
                    );

                    result.computeIfAbsent(
                            skuId,
                            key -> new ArrayList<>()
                    ).add(image);
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy ảnh riêng của SKU",
                    ex
            );
        }

        return result;
    }

    // ========================================
    // 8. CHUẨN HÓA TỪ KHÓA TÌM KIẾM
    // ========================================
    private String removeAccents(String text) {

        if (text == null) {
            return "";
        }

        return Normalizer.normalize(
                text,
                Normalizer.Form.NFD
        )
                .replaceAll(
                        "\\p{InCombiningDiacriticalMarks}+",
                        ""
                )
                .replace('đ', 'd')
                .replace('Đ', 'd')
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9\\s]", " ")
                .replaceAll("\\s+", " ")
                .trim();
    }

    private String normalizeUserQuery(
            String rawKeyword) {

        String keyword = removeAccents(rawKeyword);

        if (keyword.isEmpty()) {
            return "";
        }

        return keyword
                .replace(
                        "sac dien thoai",
                        "sac"
                )
                .replace(
                        "cap dien thoai",
                        "cap"
                )
                .replace(
                        "balo laptop",
                        "balo"
                )
                .replace(
                        "tui laptop",
                        "balo"
                )
                .replaceAll("\\s+", " ")
                .trim();
    }

    // ========================================
    // 9. TỪ ĐỒNG NGHĨA DANH MỤC
    // ========================================
    private String getCategorySynonyms(
            String categoryName) {

        switch (categoryName) {

            case "smartphone":
            case "dien thoai":
                return "dien thoai smartphone "
                        + "di dong phone dt";

            case "dong ho thong minh":
                return "dong ho thong minh "
                        + "smartwatch watch";

            case "tai nghe":
                return "tai nghe headphone "
                        + "earphone airpods buds";

            case "sac dien thoai":
                return "sac cu sac adapter "
                        + "charger fast charger";

            case "cap sac":
                return "cap sac day sac "
                        + "day cap cable";

            case "laptop van phong":
                return "laptop may tinh "
                        + "xach tay van phong";

            case "laptop gaming":
                return "laptop may tinh "
                        + "xach tay gaming";

            case "balo laptop":
                return "balo tui chong soc backpack";

            case "chuot":
                return "chuot mouse";

            case "ban phim":
                return "ban phim keyboard";

            case "may anh":
            case "may anh mirrorless":
            case "may anh compact":
                return categoryName
                        + " may anh camera mirrorless compact";

            default:
                return categoryName;
        }
    }

    // ========================================
    // 10. CHẤM ĐIỂM KẾT QUẢ TÌM KIẾM
    // ========================================
    private int calculateMatchScore(
            Product product,
            String normalizedQuery) {

        if (normalizedQuery == null
                || normalizedQuery.isEmpty()) {

            return 0;
        }

        String[] queryWords
                = normalizedQuery.split(" ");

        String categoryName
                = product.getCategory() != null
                ? removeAccents(
                        product.getCategory().getCategoryName()
                )
                : "";

        String brandName
                = product.getBrand() != null
                ? removeAccents(
                        product.getBrand().getBrandName()
                )
                : "";

        String productName
                = removeAccents(
                        product.getProductName()
                );

        String cleanName
                = "balo laptop".equals(categoryName)
                ? productName
                        .replace("laptop", "")
                        .replaceAll("\\s+", " ")
                        .trim()
                : productName;

        String searchableText
                = (cleanName + " "
                        + getCategorySynonyms(categoryName)
                        + " "
                        + brandName).trim();

        String[] searchableTokens
                = searchableText.split(" ");

        String[] nameTokens
                = cleanName.split(" ");

        int score = 0;

        for (String word : queryWords) {

            boolean matched = false;

            for (String token : searchableTokens) {

                if (token.equals(word)) {

                    score += 30;
                    matched = true;
                    break;

                } else if (token.startsWith(word)) {

                    score += 20;
                    matched = true;
                    break;

                } else if (word.length() >= 3
                        && token.contains(word)) {

                    score += 10;
                    matched = true;
                    break;
                }
            }

            if (!matched) {
                return 0;
            }

            for (String token : nameTokens) {

                if (token.startsWith(word)
                        || (word.length() >= 3
                        && token.contains(word))) {

                    score += 25;
                    break;
                }
            }
        }

        if (cleanName.contains(normalizedQuery)) {
            score += 50;
        }

        if (!"sac dien thoai".equals(categoryName)
                && !"cap sac".equals(categoryName)
                && !"balo laptop".equals(categoryName)) {

            score += 15;
        }

        return score;
    }

    // ========================================
    // 11. SEARCH GỢI Ý
    // ========================================
    public List<Product> searchProducts(
            String keyword) {

        if (keyword == null
                || keyword.trim().isEmpty()) {

            return new ArrayList<>();
        }

        List<Product> matched
                = getFilteredCatalog(
                        keyword,
                        null,
                        null,
                        null,
                        null
                );

        if (matched.size() <= 5) {
            return matched;
        }

        return new ArrayList<>(
                matched.subList(0, 5)
        );
    }

    // ========================================
    // 12. LỌC CATALOG
    // ========================================
    public List<Product> getFilteredCatalog(
            String keyword,
            String[] categoryIds,
            String priceRange,
            String minRating,
            String sort) {

        List<Product> products = new ArrayList<>();

        StringBuilder sql = new StringBuilder(
                "SELECT "
                + "p.product_id, "
                + "p.product_name, "
                + "p.description, "
                + "p.created_at, "
                + "p.image_url, "
                + "c.category_id, "
                + "c.category_name, "
                + "b.brand_id, "
                + "b.brand_name, "
                + "ISNULL(mp.min_price, 0) AS min_price, "
                + "ISNULL(rv.avg_rating, 0) AS avg_rating, "
                + "ISNULL(rv.review_count, 0) AS review_count "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c "
                + "ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b "
                + "ON p.brand_id = b.brand_id "
                + "LEFT JOIN ( "
                + "    SELECT product_id, "
                + "           MIN(price) AS min_price "
                + "    FROM PRODUCT_SKU "
                + "    WHERE is_active = 1 "
                + "    GROUP BY product_id "
                + ") mp "
                + "ON p.product_id = mp.product_id "
                + "LEFT JOIN ( "
                + "    SELECT s.product_id, "
                + "           AVG(CAST(r.rating AS FLOAT)) "
                + "               AS avg_rating, "
                + "           COUNT(r.review_id) "
                + "               AS review_count "
                + "    FROM PRODUCT_REVIEWS r "
                + "    INNER JOIN PRODUCT_SKU s "
                + "    ON r.sku_id = s.sku_id "
                + "    WHERE r.is_hidden = 0 "
                + "    GROUP BY s.product_id "
                + ") rv "
                + "ON p.product_id = rv.product_id "
                + "WHERE p.is_active = 1 "
        );

        List<Integer> parameters = new ArrayList<>();

        // ====================================
        // 12.1. LỌC DANH MỤC
        // ====================================
        List<Integer> validCategoryIds
                = new ArrayList<>();

        if (categoryIds != null) {

            for (String rawId : categoryIds) {

                try {

                    int id
                            = Integer.parseInt(
                                    rawId.trim()
                            );

                    if (id > 0
                            && !validCategoryIds.contains(id)) {

                        validCategoryIds.add(id);
                    }

                } catch (NumberFormatException
                        | NullPointerException ex) {

                    // Bỏ qua ID không hợp lệ.
                }
            }
        }

        if (!validCategoryIds.isEmpty()) {

            StringBuilder placeholders
                    = new StringBuilder();

            for (int i = 0;
                    i < validCategoryIds.size(); i++) {

                if (i > 0) {
                    placeholders.append(", ");
                }

                placeholders.append("?");
            }

            /*
             * Lọc danh mục được chọn
             * và danh mục con trực tiếp.
             */
            sql.append(
                    "AND (c.category_id IN ("
            ).append(
                    placeholders
            ).append(
                    ") OR c.parent_id IN ("
            ).append(
                    placeholders
            ).append(
                    ")) "
            );

            parameters.addAll(validCategoryIds);
            parameters.addAll(validCategoryIds);
        }

        // ====================================
        // 12.2. LỌC THEO GIÁ
        // ====================================
        if ("under5".equals(priceRange)) {

            sql.append(
                    "AND mp.min_price > 0 "
                    + "AND mp.min_price < 5000000 "
            );

        } else if ("5to15".equals(priceRange)) {

            sql.append(
                    "AND mp.min_price BETWEEN "
                    + "5000000 AND 15000000 "
            );

        } else if ("over15".equals(priceRange)) {

            sql.append(
                    "AND mp.min_price > 15000000 "
            );
        }

        // ====================================
        // 12.3. LỌC THEO ĐÁNH GIÁ
        // ====================================
        if (minRating != null
                && !minRating.trim().isEmpty()) {

            try {

                int rating
                        = Integer.parseInt(
                                minRating.trim()
                        );

                if (rating >= 1 && rating <= 5) {

                    sql.append(
                            "AND rv.review_count > 0 "
                            + "AND FLOOR(rv.avg_rating) = ? "
                    );

                    parameters.add(rating);
                }

            } catch (NumberFormatException ex) {

                // Bỏ qua rating không hợp lệ.
            }
        }

        // ====================================
        // 12.4. SẮP XẾP
        // ====================================
        if ("priceAsc".equals(sort)) {

            sql.append(
                    "ORDER BY "
                    + "CASE WHEN mp.min_price IS NULL "
                    + "THEN 1 ELSE 0 END, "
                    + "mp.min_price ASC, "
                    + "p.product_id DESC"
            );

        } else if ("priceDesc".equals(sort)) {

            sql.append(
                    "ORDER BY "
                    + "CASE WHEN mp.min_price IS NULL "
                    + "THEN 1 ELSE 0 END, "
                    + "mp.min_price DESC, "
                    + "p.product_id DESC"
            );

        } else if ("ratingDesc".equals(sort)) {

            sql.append(
                    "ORDER BY "
                    + "ISNULL(rv.avg_rating, 0) DESC, "
                    + "ISNULL(rv.review_count, 0) DESC, "
                    + "p.product_id DESC"
            );

        } else {

            sql.append(
                    "ORDER BY p.product_id DESC"
            );
        }

        // ====================================
        // 12.5. TRUY VẤN DATABASE
        // ====================================
        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(
                        sql.toString()
                )) {

            for (int i = 0;
                    i < parameters.size(); i++) {

                ps.setInt(
                        i + 1,
                        parameters.get(i)
                );
            }

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Product product = mapProduct(rs);

                    product.setMinPrice(
                            rs.getDouble("min_price")
                    );

                    product.setAverageRating(
                            rs.getDouble("avg_rating")
                    );

                    product.setReviewCount(
                            rs.getInt("review_count")
                    );

                    products.add(product);
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lọc catalog",
                    ex
            );
        }

        // ====================================
        // 12.6. SEARCH THEO TỪ KHÓA
        // ====================================
        if (keyword != null
                && !keyword.trim().isEmpty()) {

            String normalizedQuery
                    = normalizeUserQuery(keyword);

            if (!normalizedQuery.isEmpty()) {

                Map<Product, Integer> scores
                        = new HashMap<>();

                products.removeIf(product -> {

                    int score
                            = calculateMatchScore(
                                    product,
                                    normalizedQuery
                            );

                    if (score <= 0) {
                        return true;
                    }

                    scores.put(product, score);

                    return false;
                });

                if (!"priceAsc".equals(sort)
                        && !"priceDesc".equals(sort)
                        && !"ratingDesc".equals(sort)) {

                    products.sort(
                            (first, second)
                            -> Integer.compare(
                                    scores.get(second),
                                    scores.get(first)
                            )
                    );
                }
            }
        }

        return products;
    }

    // ========================================
    // 13. SẢN PHẨM TƯƠNG TỰ - OECS V2
    // ========================================
    /**
     * Lấy tối đa 8 sản phẩm tương tự.
     *
     * Quy tắc:
     *
     * 1. Cùng danh mục với sản phẩm đang xem. 2. Không lấy chính sản phẩm đó.
     * 3. PRODUCT phải đang hoạt động. 4. Phải có ít nhất một SKU đang hoạt
     * động. 5. Ưu tiên sản phẩm còn hàng. 6. Giá lấy từ SKU còn hàng nếu có. 7.
     * Nếu tất cả SKU hết hàng thì dùng giá thấp nhất của SKU đang hoạt động.
     *
     * Kết quả trả về có thể dùng trực tiếp với related-products.jsp.
     */
    public List<Product> getRelatedProducts(
            int productId,
            int categoryId) {

        List<Product> relatedProducts
                = new ArrayList<>();

        if (productId <= 0 || categoryId <= 0) {
            return relatedProducts;
        }

        String sql
                = "SELECT TOP (8) "
                + "p.product_id, "
                + "p.product_name, "
                + "p.description, "
                + "p.created_at, "
                + "p.image_url, "
                + "c.category_id, "
                + "c.category_name, "
                + "b.brand_id, "
                + "b.brand_name, "
                + "s.min_price "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c "
                + "ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b "
                + "ON p.brand_id = b.brand_id "
                + "INNER JOIN ( "
                + "    SELECT "
                + "        product_id, "
                + "        COALESCE( "
                + "            MIN( "
                + "                CASE "
                + "                    WHEN stock_quantity > 0 "
                + "                    THEN price "
                + "                END "
                + "            ), "
                + "            MIN(price) "
                + "        ) AS min_price, "
                + "        SUM(stock_quantity) AS total_stock "
                + "    FROM PRODUCT_SKU "
                + "    WHERE is_active = 1 "
                + "    GROUP BY product_id "
                + ") s "
                + "ON p.product_id = s.product_id "
                + "WHERE p.category_id = ? "
                + "AND p.product_id <> ? "
                + "AND p.is_active = 1 "
                + "ORDER BY "
                + "CASE "
                + "    WHEN s.total_stock > 0 "
                + "    THEN 0 "
                + "    ELSE 1 "
                + "END, "
                + "p.created_at DESC, "
                + "p.product_id DESC";

        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);
            ps.setInt(2, productId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Product product = mapProduct(rs);

                    product.setMinPrice(
                            rs.getDouble("min_price")
                    );

                    relatedProducts.add(product);
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy sản phẩm tương tự, productId="
                    + productId
                    + ", categoryId="
                    + categoryId,
                    ex
            );
        }

        return relatedProducts;
    }

    // ========================================
    // 14. MAPPING PRODUCT
    // ========================================
    private Product mapProduct(ResultSet rs)
            throws SQLException {

        Category category = new Category(
                rs.getInt("category_id"),
                rs.getString("category_name"),
                null
        );

        Brand brand = new Brand(
                rs.getInt("brand_id"),
                rs.getString("brand_name"),
                null
        );

        Product product = new Product(
                rs.getInt("product_id"),
                rs.getInt("category_id"),
                rs.getInt("brand_id"),
                rs.getString("product_name"),
                rs.getString("description"),
                rs.getTimestamp("created_at"),
                category,
                brand
        );

        product.setImageUrl(
                rs.getString("image_url")
        );

        return product;
    }
}
