package dao;

import db.DBContext;
import model.Attribute;
import model.Brand;
import model.Category;
import model.Product;
import model.ProductImage;
import model.ProductSpec;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import java.util.logging.Level;
import java.util.logging.Logger;

public class ProductDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(ProductDAO.class.getName());

    private static final String PRODUCT_SELECT
            = "SELECT "
            + "p.product_id, "
            + "p.category_id, "
            + "p.brand_id, "
            + "p.product_name, "
            + "p.description, "
            + "p.image_url, "
            + "p.created_at, "
            + "p.model_code, "
            + "p.is_active AS product_active, "
            + "p.updated_at, "
            + "c.category_name, "
            + "c.parent_id, "
            + "c.description AS category_description, "
            + "c.is_active AS category_active, "
            + "b.brand_name, "
            + "b.logo_url, "
            + "b.is_active AS brand_active, "
            + "(SELECT MIN(s.price) "
            + " FROM PRODUCT_SKU s "
            + " WHERE s.product_id = p.product_id "
            + " AND s.is_active = 1) AS min_price "
            + "FROM PRODUCT p "
            + "INNER JOIN CATEGORY c "
            + "ON p.category_id = c.category_id "
            + "INNER JOIN BRAND b "
            + "ON p.brand_id = b.brand_id ";

    private Product mapProduct(ResultSet rs)
            throws SQLException {

        Integer parentId = (Integer) rs.getObject("parent_id");

        Category category = new Category(
                rs.getInt("category_id"),
                rs.getString("category_name"),
                parentId,
                rs.getString("category_description"),
                rs.getBoolean("category_active")
        );

        Brand brand = new Brand(
                rs.getInt("brand_id"),
                rs.getString("brand_name"),
                rs.getString("logo_url"),
                rs.getBoolean("brand_active")
        );

        Product product = new Product(
                rs.getInt("product_id"),
                rs.getInt("category_id"),
                rs.getInt("brand_id"),
                rs.getString("product_name"),
                rs.getString("description"),
                rs.getTimestamp("created_at"),
                rs.getString("image_url"),
                category,
                brand
        );

        product.setModelCode(rs.getString("model_code"));
        product.setActive(rs.getBoolean("product_active"));
        product.setUpdatedAt(rs.getTimestamp("updated_at"));

        double minPrice = rs.getDouble("min_price");

        if (!rs.wasNull()) {
            product.setMinPrice(minPrice);
        }

        return product;
    }

    public List<Product> getList() {

        List<Product> list = new ArrayList<>();

        String sql = PRODUCT_SELECT
                + "ORDER BY p.product_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapProduct(rs));
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi truy van danh sach san pham!",
                    ex
            );

            throw new IllegalStateException(
                    "Khong the tai danh sach san pham tu database.",
                    ex
            );
        }

        return list;
    }

    public List<Product> getActiveProducts() {

        List<Product> list = new ArrayList<>();

        String sql = PRODUCT_SELECT
                + "WHERE p.is_active = 1 "
                + "AND c.is_active = 1 "
                + "AND b.is_active = 1 "
                + "ORDER BY p.product_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapProduct(rs));
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi truy van danh sach san pham dang ban!",
                    ex
            );

            throw new IllegalStateException(
                    "Khong the tai san pham dang ban tu database.",
                    ex
            );
        }

        return list;
    }

    public Product getById(int id) {

        String sql = PRODUCT_SELECT
                + "WHERE p.product_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return mapProduct(rs);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy Product theo ID!",
                    ex
            );
        }

        return null;
    }

    public int insertReturnId(Product product) {

        String sql
                = "INSERT INTO PRODUCT "
                + "(product_name, description, "
                + "category_id, brand_id, image_url, "
                + "model_code, is_active) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(
                sql,
                Statement.RETURN_GENERATED_KEYS
        )) {

            ps.setNString(1, product.getProductName());
            ps.setNString(2, product.getDescription());
            ps.setInt(3, product.getCategoryId());
            ps.setInt(4, product.getBrandId());
            ps.setString(5, product.getImageUrl());
            ps.setString(6, product.getModelCode());
            ps.setBoolean(7, product.isActive());

            if (ps.executeUpdate() > 0) {

                try (ResultSet rs = ps.getGeneratedKeys()) {

                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi thêm Product!",
                    ex
            );
        }

        return 0;
    }

    public int update(Product product) {

        String sql
                = "UPDATE PRODUCT SET "
                + "product_name = ?, "
                + "description = ?, "
                + "category_id = ?, "
                + "brand_id = ?, "
                + "image_url = COALESCE(?, image_url), "
                + "model_code = COALESCE(?, model_code), "
                + "updated_at = GETDATE() "
                + "WHERE product_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, product.getProductName());
            ps.setNString(2, product.getDescription());
            ps.setInt(3, product.getCategoryId());
            ps.setInt(4, product.getBrandId());
            ps.setString(5, product.getImageUrl());
            ps.setString(6, product.getModelCode());
            ps.setInt(7, product.getProductId());

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi cập nhật Product!",
                    ex
            );
            return 0;
        }
    }

    public int delete(int productId) {

        String sql = "DELETE FROM PRODUCT WHERE product_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            return ps.executeUpdate();

        } catch (SQLException ex) {

            LOGGER.log(Level.SEVERE, "Lỗi xóa sản phẩm!", ex);

            if (ex.getErrorCode() == 547) {
                throw new IllegalArgumentException(
                        "Không thể xóa sản phẩm vì có dữ liệu liên quan."
                );
            }

            return 0;
        }
    }

    public int setProductActive(int productId, boolean active) {

        String sql
                = "UPDATE PRODUCT "
                + "SET is_active = ?, "
                + "updated_at = GETDATE() "
                + "WHERE product_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setBoolean(1, active);
            ps.setInt(2, productId);

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi cập nhật trạng thái Product!",
                    ex
            );

            return 0;
        }
    }

    public List<Product> searchProducts(String keyword) {

        List<Product> list = new ArrayList<>();

        String sql = PRODUCT_SELECT
                + "WHERE ("
                + "p.product_name LIKE ? "
                + "OR p.model_code LIKE ? "
                + "OR c.category_name LIKE ? "
                + "OR b.brand_name LIKE ?"
                + ") "
                + "ORDER BY p.product_id DESC";

        String searchPattern
                = "%" + (keyword == null ? "" : keyword.trim()) + "%";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, searchPattern);
            ps.setNString(2, searchPattern);
            ps.setNString(3, searchPattern);
            ps.setNString(4, searchPattern);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    list.add(mapProduct(rs));
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi tìm kiếm Product!",
                    ex
            );
        }

        return list;
    }

    public boolean checkProductNameExists(String productName) {

        String sql
                = "SELECT 1 FROM PRODUCT "
                + "WHERE product_name = ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, productName);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi kiểm tra trùng tên Product!",
                    ex
            );
        }

        return false;
    }

    public boolean checkProductNameExistsForUpdate(
            String productName,
            int excludeProductId) {

        String sql
                = "SELECT 1 FROM PRODUCT "
                + "WHERE product_name = ? "
                + "AND product_id <> ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, productName);
            ps.setInt(2, excludeProductId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi kiểm tra trùng tên khi Edit!",
                    ex
            );
        }

        return false;
    }

    public void insertGalleryImages(
            int productId,
            List<String> imageUrls) {

        if (imageUrls == null || imageUrls.isEmpty()) {
            return;
        }

        String sql
                = "INSERT INTO PRODUCT_IMAGES "
                + "(product_id, sku_id, image_url, "
                + "is_primary, display_order) "
                + "SELECT ?, NULL, ?, 0, ? "
                + "WHERE NOT EXISTS ("
                + "SELECT 1 FROM PRODUCT_IMAGES "
                + "WHERE product_id = ? "
                + "AND sku_id IS NULL "
                + "AND image_url = ?"
                + ")";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            int order = 0;

            for (String url : imageUrls) {

                if (url == null || url.trim().isEmpty()) {
                    continue;
                }

                String cleanUrl = url.trim();

                ps.setInt(1, productId);
                ps.setString(2, cleanUrl);
                ps.setInt(3, order++);
                ps.setInt(4, productId);
                ps.setString(5, cleanUrl);

                ps.addBatch();
            }

            ps.executeBatch();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lưu ảnh Gallery!",
                    ex
            );
        }
    }

    public List<ProductImage> getProductImages(int productId) {

        List<ProductImage> list = new ArrayList<>();

        String sql
                = "SELECT image_id, product_id, sku_id, "
                + "image_url, is_primary, display_order, "
                + "alt_text, created_at "
                + "FROM PRODUCT_IMAGES "
                + "WHERE product_id = ? "
                + "ORDER BY "
                + "CASE WHEN sku_id IS NULL THEN 0 ELSE 1 END, "
                + "sku_id, display_order, image_id";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Integer skuId
                            = (Integer) rs.getObject("sku_id");

                    ProductImage image = new ProductImage(
                            rs.getInt("image_id"),
                            rs.getInt("product_id"),
                            skuId,
                            rs.getString("image_url"),
                            rs.getBoolean("is_primary"),
                            rs.getInt("display_order"),
                            rs.getString("alt_text"),
                            rs.getTimestamp("created_at")
                    );

                    list.add(image);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy ảnh Product!",
                    ex
            );
        }

        return list;
    }

    public void deleteGalleryImageById(int imageId) {

        String sql
                = "DELETE FROM PRODUCT_IMAGES "
                + "WHERE image_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, imageId);
            ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi xóa ảnh Gallery!",
                    ex
            );
        }
    }

    public List<Attribute> getAllAttributes() {

        List<Attribute> list = new ArrayList<>();

        String sql
                = "SELECT attribute_id, attribute_name, "
                + "data_type, unit, is_active "
                + "FROM ATTRIBUTE "
                + "ORDER BY attribute_id";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Attribute attribute = new Attribute(
                        rs.getInt("attribute_id"),
                        rs.getString("attribute_name"),
                        rs.getString("data_type"),
                        rs.getString("unit"),
                        rs.getBoolean("is_active")
                );

                list.add(attribute);
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy danh sách Attribute!",
                    ex
            );
        }

        return list;
    }

    public void saveProductSpecs(
            int productId,
            String[] attributeIds,
            String[] specValues) {

        Map<Integer, String> uniqueSpecs
                = new LinkedHashMap<>();

        if (attributeIds != null && specValues != null) {

            int len = Math.min(
                    attributeIds.length,
                    specValues.length
            );

            for (int i = 0; i < len; i++) {

                String attributeId = attributeIds[i];
                String value = specValues[i];

                if (attributeId == null
                        || attributeId.trim().isEmpty()
                        || value == null
                        || value.trim().isEmpty()) {
                    continue;
                }

                try {
                    int id = Integer.parseInt(
                            attributeId.trim()
                    );

                    if (id > 0) {
                        uniqueSpecs.put(id, value.trim());
                    }

                } catch (NumberFormatException ex) {
                    LOGGER.log(
                            Level.WARNING,
                            "Attribute ID không hợp lệ: "
                            + attributeId,
                            ex
                    );
                }
            }
        }

        String sqlDelete
                = "DELETE FROM PRODUCT_SPECIFICATION "
                + "WHERE product_id = ?";

        String sqlInsert
                = "INSERT INTO PRODUCT_SPECIFICATION "
                + "(product_id, attribute_id, value) "
                + "VALUES (?, ?, ?)";

        try (Connection conn = this.getConnection()) {

            boolean originalAutoCommit
                    = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                try (PreparedStatement psDel
                        = conn.prepareStatement(sqlDelete)) {

                    psDel.setInt(1, productId);
                    psDel.executeUpdate();
                }

                if (!uniqueSpecs.isEmpty()) {

                    try (PreparedStatement psIns
                            = conn.prepareStatement(sqlInsert)) {

                        for (Map.Entry<Integer, String> entry
                                : uniqueSpecs.entrySet()) {

                            psIns.setInt(1, productId);
                            psIns.setInt(2, entry.getKey());
                            psIns.setNString(3, entry.getValue());

                            psIns.addBatch();
                        }

                        psIns.executeBatch();
                    }
                }

                conn.commit();

            } catch (SQLException ex) {

                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    ex.addSuppressed(rollbackEx);
                }

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi lưu thông số kỹ thuật!",
                        ex
                );

            } finally {
                try {
                    conn.setAutoCommit(originalAutoCommit);
                } catch (SQLException ex) {
                    LOGGER.log(
                            Level.WARNING,
                            "Không khôi phục được autoCommit!",
                            ex
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi kết nối khi lưu thông số!",
                    ex
            );
        }
    }

    public List<ProductSpec> getProductSpecsForAdmin(
            int productId) {

        List<ProductSpec> list = new ArrayList<>();

        String sql
                = "SELECT "
                + "ps.product_id, "
                + "ps.attribute_id, "
                + "ps.value, "
                + "ps.numeric_value, "
                + "ps.boolean_value, "
                + "a.attribute_name, "
                + "a.unit, "
                + "ca.group_name, "
                + "ca.display_order "
                + "FROM PRODUCT_SPECIFICATION ps "
                + "INNER JOIN PRODUCT p "
                + "ON p.product_id = ps.product_id "
                + "INNER JOIN ATTRIBUTE a "
                + "ON a.attribute_id = ps.attribute_id "
                + "LEFT JOIN CATEGORY_ATTRIBUTE ca "
                + "ON ca.category_id = p.category_id "
                + "AND ca.attribute_id = ps.attribute_id "
                + "WHERE ps.product_id = ? "
                + "ORDER BY ca.display_order, "
                + "ps.attribute_id";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    ProductSpec spec = new ProductSpec();

                    spec.setProductId(
                            rs.getInt("product_id")
                    );

                    spec.setAttributeId(
                            rs.getInt("attribute_id")
                    );

                    spec.setAttributeName(
                            rs.getString("attribute_name")
                    );

                    spec.setValue(
                            rs.getString("value")
                    );

                    spec.setNumericValue(
                            rs.getBigDecimal("numeric_value")
                    );

                    Object booleanObject
                            = rs.getObject("boolean_value");

                    spec.setBooleanValue(
                            booleanObject == null
                                    ? null
                                    : rs.getBoolean("boolean_value")
                    );

                    spec.setGroupName(
                            rs.getString("group_name")
                    );

                    spec.setUnit(
                            rs.getString("unit")
                    );

                    spec.setDisplayOrder(
                            rs.getInt("display_order")
                    );

                    list.add(spec);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy thông số Product!",
                    ex
            );
        }

        return list;
    }
}
