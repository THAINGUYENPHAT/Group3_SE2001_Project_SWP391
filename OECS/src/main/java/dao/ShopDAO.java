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

public class ShopDAO extends DBContext {

    // Lấy danh sách sản phẩm kèm giá trị nhỏ nhất từ bảng SKU
    public List<Product> getCatalogProducts() {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, "
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
                product.setMinPrice(rs.getDouble("min_price"));
                list.add(product);
            }
        } catch (SQLException ex) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi lấy Catalog!", ex);
        }
        return list;
    }

    // Lấy chi tiết 1 sản phẩm
    public Product getProductDetail(int id) {
        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, "
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
                    return new Product(
                            rs.getInt("product_id"), rs.getInt("category_id"), rs.getInt("brand_id"),
                            rs.getString("product_name"), rs.getString("description"),
                            rs.getTimestamp("created_at"), category, brand
                    );
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi chi tiết SP!", ex);
        }
        return null;
    }

    // Lấy các biến thể (SKU) của sản phẩm
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

    // Lấy thông số kỹ thuật của sản phẩm
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

        String sql = "SELECT TOP 5 p.product_id, p.product_name, "
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
                    p.setMinPrice(rs.getDouble("min_price"));
                    list.add(p);
                }
            }
        } catch (SQLException ex) {
            System.err.println("Lỗi SQL khi Search: " + ex.getMessage());
            Logger.getLogger(ShopDAO.class.getName()).log(Level.SEVERE, "Lỗi tìm kiếm sản phẩm!", ex);
        }
        return list;
    }
}
