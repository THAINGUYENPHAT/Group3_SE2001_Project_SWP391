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
        // Đã bổ sung đầy đủ INNER JOIN theo chuẩn DB[cite: 1]
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

    public int update(Product product) {
        // Nếu có upload ảnh mới thì cập nhật, nếu không thì giữ nguyên ảnh cũ bằng COALESCE
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
        // Đã bổ sung đầy đủ INNER JOIN theo chuẩn DB[cite: 1]
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

                    // Đã sửa lỗi logic: thêm return để trả về đối tượng tìm được[cite: 1]
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

    // =====================================================
    // SEARCH PRODUCTS
    // =====================================================
    public List<Product> searchProducts(String keyword) {
        List<Product> list = new ArrayList<>();
        // Đã bổ sung đầy đủ INNER JOIN và điều kiện WHERE để tìm kiếm tương đối[cite: 1]
        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, p.image_url, "
                + "c.category_id, c.category_name, c.parent_id, "
                + "b.brand_id, b.brand_name, b.logo_url "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "WHERE p.product_name LIKE ? OR c.category_name LIKE ? OR b.brand_name LIKE ? "
                + "ORDER BY p.product_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            // Thêm ký tự % để tìm kiếm chuỗi chứa từ khóa (Tương đối)
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
}
