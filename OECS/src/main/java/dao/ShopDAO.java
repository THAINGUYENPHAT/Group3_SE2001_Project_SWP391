package dao;

import db.DBContext;
import model.Brand;
import model.Category;
import model.Product;
import model.ProductImage;
import model.ProductSku;
import model.ProductSpec;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

public class ShopDAO extends DBContext {

    public List<Product> getCatalogProducts() {
        return getFilteredCatalog(null, null, null, null, null);
    }

    public Product getProductDetail(int id) {
        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, p.image_url, "
                + "c.category_id, c.category_name, b.brand_id, b.brand_name "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "WHERE p.product_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {
            statement.setInt(1, id);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    Category category = new Category(rs.getInt("category_id"), rs.getString("category_name"), null);
                    Brand brand = new Brand(rs.getInt("brand_id"), rs.getString("brand_name"), null);
                    Product product = new Product(
                            rs.getInt("product_id"), rs.getInt("category_id"), rs.getInt("brand_id"),
                            rs.getString("product_name"), rs.getString("description"),
                            rs.getTimestamp("created_at"), category, brand
                    );
                    product.setImageUrl(rs.getString("image_url"));
                    return product;
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi chi tiết SP!", ex);
        }
        return null;
    }

    public List<ProductSku> getProductSkus(int productId) {
        List<ProductSku> list = new ArrayList<>();
        String sql = "SELECT sku_id, product_id, sku_code, price, stock_quantity FROM PRODUCT_SKU WHERE product_id = ? ORDER BY price ASC";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {
            statement.setInt(1, productId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    list.add(new ProductSku(
                            rs.getInt("sku_id"), rs.getInt("product_id"),
                            rs.getString("sku_code"), rs.getDouble("price"),
                            rs.getInt("stock_quantity")
                    ));
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi lấy SKU!", ex);
        }
        return list;
    }

    public List<ProductSpec> getProductSpecs(int productId) {
        List<ProductSpec> list = new ArrayList<>();
        String sql = "SELECT a.attribute_name, ps.value FROM PRODUCT_SPECIFICATION ps "
                + "INNER JOIN ATTRIBUTE a ON ps.attribute_id = a.attribute_id "
                + "WHERE ps.product_id = ?";
        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {
            statement.setInt(1, productId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    list.add(new ProductSpec(rs.getString("attribute_name"), rs.getString("value")));
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi lấy Specs!", ex);
        }
        return list;
    }

    public List<ProductImage> getProductImages(int productId) {
        List<ProductImage> list = new ArrayList<>();
        String sql = "SELECT image_id, product_id, image_url FROM PRODUCT_IMAGES WHERE product_id = ?";
        try (Connection conn = this.getConnection(); PreparedStatement stm = conn.prepareStatement(sql)) {
            stm.setInt(1, productId);
            try (ResultSet rs = stm.executeQuery()) {
                while (rs.next()) {
                    list.add(new ProductImage(rs.getInt("image_id"), rs.getInt("product_id"), rs.getString("image_url")));
                }
            }
        } catch (SQLException e) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi lấy ảnh phụ!", e);
        }
        return list;
    }

    private String removeAccents(String text) {
        if (text == null) {
            return "";
        }
        return Normalizer.normalize(text, Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                .replace('đ', 'd')
                .replace('Đ', 'd')
                .toLowerCase()
                .replaceAll("[^a-z0-9\\s]", " ")
                .replaceAll("\\s+", " ")
                .trim();
    }

    private String normalizeUserQuery(String rawKeyword) {
        String kw = removeAccents(rawKeyword);
        if (kw.isEmpty()) {
            return "";
        }
        return kw.replace("sac dien thoai", "sac")
                .replace("cap dien thoai", "cap")
                .replace("balo laptop", "balo")
                .replace("tui laptop", "balo")
                .replaceAll("\\s+", " ")
                .trim();
    }

    private String getCategorySynonyms(String normCategoryName) {
        switch (normCategoryName) {
            case "smartphone":
            case "dien thoai":
                return "dien thoai smartphone di dong phone dt";
            case "dong ho thong minh":
                return "dong ho thong minh smartwatch watch";
            case "tai nghe":
                return "tai nghe headphone earphone airpods buds";
            case "sac dien thoai":
                return "sac cu sac adapter charger fast charger";
            case "cap sac":
                return "cap sac day sac day cap cable";
            case "laptop van phong":
                return "laptop may tinh xach tay van phong";
            case "laptop gaming":
                return "laptop may tinh xach tay gaming";
            case "balo laptop":
                return "balo tui chong soc backpack";
            case "chuot":
                return "chuot mouse";
            case "ban phim":
                return "ban phim keyboard";
            case "may anh":
            case "may anh mirrorless":
            case "may anh compact":
                return normCategoryName + " may anh camera mirrorless compact";
            default:
                return normCategoryName;
        }
    }

    private int calculateMatchScore(Product p, String normalizedQuery) {
        String[] queryWords = normalizedQuery.split(" ");
        if (queryWords.length == 0) {
            return 0;
        }

        String normCat = p.getCategory() != null ? removeAccents(p.getCategory().getCategoryName()) : "";
        String normBrand = p.getBrand() != null ? removeAccents(p.getBrand().getBrandName()) : "";
        String normName = removeAccents(p.getProductName());

        String cleanProductName = normCat.equals("balo laptop")
                ? normName.replace("laptop", "").replaceAll("\\s+", " ").trim()
                : normName;

        String fullSearchableText = (cleanProductName + " " + getCategorySynonyms(normCat) + " " + normBrand).trim();
        String[] searchableTokens = fullSearchableText.split(" ");
        String[] nameTokens = cleanProductName.split(" ");

        int score = 0;

        for (String qWord : queryWords) {
            boolean wordMatched = false;

            for (String token : searchableTokens) {
                if (token.equals(qWord)) {
                    wordMatched = true;
                    score += 30;
                    break;
                } else if (token.startsWith(qWord)) {
                    wordMatched = true;
                    score += 20;
                    break;
                } else if (qWord.length() >= 3 && token.contains(qWord)) {
                    wordMatched = true;
                    score += 10;
                    break;
                }
            }

            if (!wordMatched) {
                return 0;
            }

            for (String nToken : nameTokens) {
                if (nToken.startsWith(qWord) || (qWord.length() >= 3 && nToken.contains(qWord))) {
                    score += 25;
                    break;
                }
            }
        }

        if (cleanProductName.contains(normalizedQuery)) {
            score += 50;
        }

        if (!normCat.equals("sac dien thoai") && !normCat.equals("cap sac") && !normCat.equals("balo laptop")) {
            score += 15;
        }

        return score;
    }

    public List<Product> searchProducts(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return new ArrayList<>();
        }
        List<Product> matched = getFilteredCatalog(keyword, null, null, null, null);
        return matched.size() > 5 ? new ArrayList<>(matched.subList(0, 5)) : matched;
    }

    public List<Product> getFilteredCatalog(String keyword, String[] categoryIds, String priceRange, String minRating, String sort) {
        List<Product> list = new ArrayList<>();

        StringBuilder sql = new StringBuilder(
                "SELECT p.product_id, p.product_name, p.description, p.created_at, p.image_url, "
                + "c.category_id, c.category_name, b.brand_id, b.brand_name, "
                + "ISNULL(mp.min_price, 0) as min_price, "
                + "ISNULL(rv.avg_rating, 0) as avg_rating, "
                + "ISNULL(rv.review_count, 0) as review_count "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "LEFT JOIN (SELECT product_id, MIN(price) as min_price FROM PRODUCT_SKU GROUP BY product_id) mp ON p.product_id = mp.product_id "
                + "LEFT JOIN ( "
                + "    SELECT ps.product_id, AVG(CAST(pr.rating AS FLOAT)) as avg_rating, COUNT(pr.review_id) as review_count "
                + "    FROM PRODUCT_REVIEWS pr "
                + "    INNER JOIN PRODUCT_SKU ps ON pr.sku_id = ps.sku_id "
                + "    WHERE pr.is_hidden = 0 "
                + "    GROUP BY ps.product_id "
                + ") rv ON p.product_id = rv.product_id "
                + "WHERE 1=1 "
        );

        List<Integer> parameters = new ArrayList<>();

        if (categoryIds != null && categoryIds.length > 0) {
            StringBuilder placeholders = new StringBuilder();
            for (int i = 0; i < categoryIds.length; i++) {
                placeholders.append("?");
                parameters.add(Integer.parseInt(categoryIds[i]));
                if (i < categoryIds.length - 1) {
                    placeholders.append(", ");
                }
            }
            for (String catId : categoryIds) {
                parameters.add(Integer.parseInt(catId));
            }

            sql.append("AND (c.category_id IN (").append(placeholders).append(") ")
                    .append("OR c.parent_id IN (").append(placeholders).append(")) ");
        }

        if (priceRange != null) {
            if ("under5".equals(priceRange)) {
                sql.append("AND mp.min_price > 0 AND mp.min_price < 5000000 ");
            } else if ("5to15".equals(priceRange)) {
                sql.append("AND mp.min_price BETWEEN 5000000 AND 15000000 ");
            } else if ("over15".equals(priceRange)) {
                sql.append("AND mp.min_price > 15000000 ");
            }
        }

        if (minRating != null && !minRating.trim().isEmpty()) {
            try {
                int ratingVal = Integer.parseInt(minRating.trim());
                if (ratingVal >= 1 && ratingVal <= 5) {
                    sql.append("AND rv.review_count > 0 AND FLOOR(rv.avg_rating) = ? ");
                    parameters.add(ratingVal);
                }
            } catch (NumberFormatException ignored) {
            }
        }

        if ("priceAsc".equals(sort)) {
            sql.append("ORDER BY mp.min_price ASC ");
        } else if ("priceDesc".equals(sort)) {
            sql.append("ORDER BY mp.min_price DESC ");
        } else if ("ratingDesc".equals(sort)) {
            sql.append("ORDER BY ISNULL(rv.avg_rating, 0) DESC, ISNULL(rv.review_count, 0) DESC, p.product_id DESC ");
        } else {
            sql.append("ORDER BY p.product_id DESC ");
        }

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < parameters.size(); i++) {
                ps.setInt(i + 1, parameters.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Category cat = new Category(rs.getInt("category_id"), rs.getString("category_name"), null);
                    Brand brand = new Brand(rs.getInt("brand_id"), rs.getString("brand_name"), null);
                    Product product = new Product(
                            rs.getInt("product_id"), rs.getInt("category_id"), rs.getInt("brand_id"),
                            rs.getString("product_name"), rs.getString("description"),
                            rs.getTimestamp("created_at"), cat, brand
                    );
                    product.setImageUrl(rs.getString("image_url"));
                    product.setMinPrice(rs.getDouble("min_price"));
                    product.setAverageRating(rs.getDouble("avg_rating"));
                    product.setReviewCount(rs.getInt("review_count"));
                    list.add(product);
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi khi lọc sản phẩm Catalog!", ex);
        }

        if (keyword != null && !keyword.trim().isEmpty()) {
            String normalizedQuery = normalizeUserQuery(keyword);
            if (!normalizedQuery.isEmpty()) {
                Map<Product, Integer> scoreMap = new HashMap<>();
                list.removeIf(p -> {
                    int score = calculateMatchScore(p, normalizedQuery);
                    if (score > 0) {
                        scoreMap.put(p, score);
                        return false;
                    }
                    return true;
                });

                if (!"priceAsc".equals(sort) && !"priceDesc".equals(sort) && !"ratingDesc".equals(sort)) {
                    list.sort((p1, p2) -> Integer.compare(scoreMap.get(p2), scoreMap.get(p1)));
                }
            }
        }

        return list;
    }
}
