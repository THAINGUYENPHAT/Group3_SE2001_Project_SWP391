package dao;

import db.DBContext;
import model.Brand;
import model.Category;
import model.Product;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class ProductDAO extends DBContext {

    public List<Product> getList() {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, p.image_url, "
                + "c.category_id, c.category_name, c.parent_id, "
                + "b.brand_id, b.brand_name, b.logo_url "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "ORDER BY p.product_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {
                Category category = new Category(
                        rs.getInt("category_id"),
                        rs.getString("category_name"),
                        rs.getObject("parent_id") != null ? rs.getInt("parent_id") : null
                );

                Brand brand = new Brand(
                        rs.getInt("brand_id"),
                        rs.getString("brand_name"),
                        rs.getString("logo_url")
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

                list.add(product);
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, "Lỗi lấy danh sách Product!", ex);
        }
        return list;
    }

    public int insert(Product product) {
        String sql = "INSERT INTO PRODUCT (product_name, description, category_id, brand_id, image_url) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setString(1, product.getProductName());
            statement.setString(2, product.getDescription());
            statement.setInt(3, product.getCategoryId());
            statement.setInt(4, product.getBrandId());
            statement.setString(5, product.getImageUrl()); // Lưu đường dẫn ảnh

            return statement.executeUpdate();
        } catch (SQLException ex) {
            ex.printStackTrace();
            return 0;
        }
    }

    
    public int insertReturnId(Product product) {
        String sql = "INSERT INTO PRODUCT (product_name, description, category_id, brand_id, image_url) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {

            statement.setString(1, product.getProductName());
            statement.setString(2, product.getDescription());
            statement.setInt(3, product.getCategoryId());
            statement.setInt(4, product.getBrandId());
            statement.setString(5, product.getImageUrl());

            int affectedRows = statement.executeUpdate();

            if (affectedRows > 0) {
                try (ResultSet rs = statement.getGeneratedKeys()) {
                    if (rs.next()) {
                        return rs.getInt(1); 
                    }
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, "Lỗi insertReturnId Product!", ex);
        }
        return 0;
    }

    public int update(Product product) {
        String sql = "UPDATE PRODUCT SET product_name=?, description=?, category_id=?, brand_id=?, image_url=COALESCE(?, image_url) WHERE product_id=?";
        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setString(1, product.getProductName());
            statement.setString(2, product.getDescription());
            statement.setInt(3, product.getCategoryId());
            statement.setInt(4, product.getBrandId());
            statement.setString(5, product.getImageUrl());
            statement.setInt(6, product.getProductId());

            return statement.executeUpdate();
        } catch (SQLException ex) {
            ex.printStackTrace();
            return 0;
        }
    }

    public int delete(int productId) {
        String sql = "DELETE FROM PRODUCT WHERE product_id = ?";
        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, productId);
            return statement.executeUpdate();
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, "Lỗi xóa Product!", ex);
            return 0;
        }
    }

    public Product getById(int id) {
        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, p.image_url, "
                + "c.category_id, c.category_name, c.parent_id, "
                + "b.brand_id, b.brand_name, b.logo_url "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "WHERE p.product_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, id);

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    Category category = new Category(
                            rs.getInt("category_id"),
                            rs.getString("category_name"),
                            rs.getObject("parent_id") != null ? rs.getInt("parent_id") : null
                    );

                    Brand brand = new Brand(
                            rs.getInt("brand_id"),
                            rs.getString("brand_name"),
                            rs.getString("logo_url")
                    );

                    return new Product(
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
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, "Lỗi lấy Product theo ID!", ex);
        }
        return null;
    }

   
    public List<Product> searchProducts(String keyword) {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, p.image_url, "
                + "c.category_id, c.category_name, c.parent_id, "
                + "b.brand_id, b.brand_name, b.logo_url "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "WHERE p.product_name LIKE ? OR c.category_name LIKE ? OR b.brand_name LIKE ? "
                + "ORDER BY p.product_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            String searchPattern = "%" + keyword + "%";
            statement.setNString(1, searchPattern);
            statement.setNString(2, searchPattern);
            statement.setNString(3, searchPattern);

            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Category category = new Category(
                            rs.getInt("category_id"),
                            rs.getString("category_name"),
                            rs.getObject("parent_id") != null ? rs.getInt("parent_id") : null
                    );

                    Brand brand = new Brand(
                            rs.getInt("brand_id"),
                            rs.getString("brand_name"),
                            rs.getString("logo_url")
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
                    list.add(product);
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, "Lỗi tìm kiếm Product!", ex);
        }
        return list;
    }
    
    public boolean checkProductNameExists(String productName) {
        String sql = "SELECT 1 FROM PRODUCT WHERE product_name = ?";
        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {
            statement.setString(1, productName);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next(); 
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, "Lỗi kiểm tra trùng tên Product!", ex);
        }
        return false;
    }

    public boolean checkProductNameExistsForUpdate(String productName, int excludeProductId) {
        String sql = "SELECT 1 FROM PRODUCT WHERE product_name = ? AND product_id != ?";
        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {
            statement.setString(1, productName);
            statement.setInt(2, excludeProductId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, "Lỗi kiểm tra trùng tên Product lúc Edit!", ex);
        }
        return false;
    }

    public void insertGalleryImages(int productId, List<String> imageUrls) {
        if (imageUrls == null || imageUrls.isEmpty()) {
            return;
        }
        String sql = "INSERT INTO PRODUCT_IMAGES (product_id, image_url) VALUES (?, ?)";
        try (Connection conn = this.getConnection(); PreparedStatement stm = conn.prepareStatement(sql)) {
            for (String url : imageUrls) {
                stm.setInt(1, productId);
                stm.setString(2, url);
                stm.addBatch();
            }
            stm.executeBatch();
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
    }

    public void deleteGalleryImages(int productId) {
        String sql = "DELETE FROM PRODUCT_IMAGES WHERE product_id = ?";
        try (Connection conn = this.getConnection(); PreparedStatement stm = conn.prepareStatement(sql)) {
            stm.setInt(1, productId);
            stm.executeUpdate();
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
    }

   
    public List<model.ProductImage> getProductImages(int productId) {
        List<model.ProductImage> list = new ArrayList<>();
        String sql = "SELECT image_id, product_id, image_url FROM PRODUCT_IMAGES WHERE product_id = ?";
        try (Connection conn = this.getConnection(); PreparedStatement stm = conn.prepareStatement(sql)) {
            stm.setInt(1, productId);
            try (ResultSet rs = stm.executeQuery()) {
                while (rs.next()) {
                    list.add(new model.ProductImage(
                            rs.getInt("image_id"),
                            rs.getInt("product_id"),
                            rs.getString("image_url")
                    ));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public void deleteGalleryImageById(int imageId) {
        String sql = "DELETE FROM PRODUCT_IMAGES WHERE image_id = ?";
        try (Connection conn = this.getConnection(); PreparedStatement stm = conn.prepareStatement(sql)) {
            stm.setInt(1, imageId);
            stm.executeUpdate();
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
    }
}
