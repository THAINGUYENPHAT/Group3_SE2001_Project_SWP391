package dao;

import db.DBContext;
import model.Brand;
import model.Category;
import model.Product;
import model.ProductSku;
import model.ProductSpec;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.ProductImage;

public class ShopDAO extends DBContext {

    public List<Product> getCatalogProducts() {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, p.image_url, "
                + "c.category_id, c.category_name, "
                + "b.brand_id, b.brand_name, "
                + "(SELECT ISNULL(MIN(price), 0) FROM PRODUCT_SKU WHERE product_id = p.product_id) as min_price "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "ORDER BY p.product_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {
                Category category = new Category(rs.getInt("category_id"), rs.getString("category_name"), null);
                Brand brand = new Brand(rs.getInt("brand_id"), rs.getString("brand_name"), null);
                Product product = new Product(
                        rs.getInt("product_id"),
                        rs.getInt("category_id"),
                        rs.getInt("brand_id"),
                        rs.getString("product_name"),
                        rs.getString("description"),
                        rs.getTimestamp("created_at"),
                        category, brand
                );
                product.setImageUrl(rs.getString("image_url")); 
                product.setMinPrice(rs.getDouble("min_price"));
                list.add(product);
            }
        } catch (SQLException ex) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi lấy Catalog!", ex);
        }
        return list;
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
                    product.setImageUrl(rs.getString("image_url")); // Đồng bộ hình ảnh
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

    public List<Product> searchProducts(String keyword) {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT TOP 5 p.product_id, p.product_name, p.image_url, "
                + "(SELECT ISNULL(MIN(price), 0) FROM PRODUCT_SKU WHERE product_id = p.product_id) as min_price "
                + "FROM PRODUCT p "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "WHERE p.product_name LIKE ? OR p.description LIKE ? OR b.brand_name LIKE ? "
                + "ORDER BY p.product_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            String searchPattern = "%" + keyword + "%";
            statement.setNString(1, searchPattern);
            statement.setNString(2, searchPattern);
            statement.setNString(3, searchPattern);

            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Product p = new Product();
                    p.setProductId(rs.getInt("product_id"));
                    p.setProductName(rs.getString("product_name"));
                    p.setImageUrl(rs.getString("image_url")); // Đồng bộ hình ảnh
                    p.setMinPrice(rs.getDouble("min_price"));
                    list.add(p);
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi tìm kiếm sản phẩm!", ex);
        }
        return list;
    }

    public List<Product> searchFullCatalog(String keyword) {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, p.image_url, "
                + "c.category_id, c.category_name, "
                + "b.brand_id, b.brand_name, "
                + "(SELECT ISNULL(MIN(price), 0) FROM PRODUCT_SKU WHERE product_id = p.product_id) as min_price "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "WHERE p.product_name LIKE ? OR c.category_name LIKE ? "
                + "ORDER BY p.product_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            String searchPattern = "%" + keyword + "%";
            statement.setNString(1, searchPattern);
            statement.setNString(2, searchPattern);

            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Category category = new Category(rs.getInt("category_id"), rs.getString("category_name"), null);
                    Brand brand = new Brand(rs.getInt("brand_id"), rs.getString("brand_name"), null);
                    Product product = new Product(
                            rs.getInt("product_id"), rs.getInt("category_id"), rs.getInt("brand_id"),
                            rs.getString("product_name"), rs.getString("description"),
                            rs.getTimestamp("created_at"), category, brand
                    );
                    product.setImageUrl(rs.getString("image_url")); // Đồng bộ hình ảnh
                    product.setMinPrice(rs.getDouble("min_price"));
                    list.add(product);
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi tìm kiếm danh mục/sản phẩm!", ex);
        }
        return list;
    }

  
    public List<Product> getFilteredCatalog(String keyword, String[] categoryIds, String priceRange, String sort) {
        List<Product> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT p.product_id, p.product_name, p.description, p.created_at, p.image_url, "
                + "c.category_id, c.category_name, b.brand_id, b.brand_name, "
                + "(SELECT ISNULL(MIN(price), 0) FROM PRODUCT_SKU WHERE product_id = p.product_id) as min_price "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "WHERE 1=1 "
        );

        List<Object> parameters = new ArrayList<>();

        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (p.product_name LIKE ? OR p.description LIKE ? OR c.category_name LIKE ? OR b.brand_name LIKE ?) ");
            String searchPattern = "%" + keyword.trim() + "%";
            parameters.add(searchPattern);
            parameters.add(searchPattern);
            parameters.add(searchPattern);
            parameters.add(searchPattern);
        }

        if (categoryIds != null && categoryIds.length > 0) {
            sql.append("AND (");
            for (int i = 0; i < categoryIds.length; i++) {
                sql.append("c.category_id = ? OR c.parent_id = ?");
                parameters.add(Integer.parseInt(categoryIds[i]));
                parameters.add(Integer.parseInt(categoryIds[i]));
                if (i < categoryIds.length - 1) {
                    sql.append(" OR ");
                }
            }
            sql.append(") ");
        }

        if (priceRange != null) {
            if ("under5".equals(priceRange)) {
                sql.append("AND (SELECT ISNULL(MIN(price), 0) FROM PRODUCT_SKU WHERE product_id = p.product_id) > 0 ");
                sql.append("AND (SELECT ISNULL(MIN(price), 0) FROM PRODUCT_SKU WHERE product_id = p.product_id) < 5000000 ");
            } else if ("5to15".equals(priceRange)) {
                sql.append("AND (SELECT ISNULL(MIN(price), 0) FROM PRODUCT_SKU WHERE product_id = p.product_id) BETWEEN 5000000 AND 15000000 ");
            } else if ("over15".equals(priceRange)) {
                sql.append("AND (SELECT ISNULL(MIN(price), 0) FROM PRODUCT_SKU WHERE product_id = p.product_id) > 15000000 ");
            }
        }

        if ("priceAsc".equals(sort)) {
            sql.append("ORDER BY min_price ASC ");
        } else if ("priceDesc".equals(sort)) {
            sql.append("ORDER BY min_price DESC ");
        } else {
            sql.append("ORDER BY p.product_id DESC "); 
        }

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < parameters.size(); i++) {
                if (parameters.get(i) instanceof String) {
                    ps.setNString(i + 1, (String) parameters.get(i));
                } else if (parameters.get(i) instanceof Integer) {
                    ps.setInt(i + 1, (Integer) parameters.get(i));
                }
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
                    list.add(product);
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi khi lọc sản phẩm!", ex);
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
            e.printStackTrace();
        }
        return list;
    }
}
