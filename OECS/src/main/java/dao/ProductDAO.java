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

        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, "
                + "c.category_id, c.category_name, c.parent_id, "
                + "b.brand_id, b.brand_name, b.logo_url "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "ORDER BY p.product_id DESC";

        try (
                Connection conn = this.getConnection();
                PreparedStatement statement = conn.prepareStatement(sql);
                ResultSet rs = statement.executeQuery()
        ) {

            while (rs.next()) {

                Category category = new Category(
                        rs.getInt("category_id"),
                        rs.getString("category_name"),
                        rs.getObject("parent_id") != null
                                ? rs.getInt("parent_id")
                                : null
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
                        category,
                        brand
                );

                list.add(product);
            }

        } catch (SQLException ex) {

            Logger.getLogger(ProductDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi lấy danh sách Product!", ex);
        }

        return list;
    }

    public int insert(Product product) {

        String sql = "INSERT INTO PRODUCT "
                + "(product_name, description, category_id, brand_id) "
                + "VALUES (?, ?, ?, ?)";

        try (
                Connection conn = this.getConnection();
                PreparedStatement statement = conn.prepareStatement(sql)
        ) {

            statement.setString(1, product.getProductName());
            statement.setString(2, product.getDescription());
            statement.setInt(3, product.getCategoryId());
            statement.setInt(4, product.getBrandId());

            return statement.executeUpdate();

        } catch (SQLException ex) {

            Logger.getLogger(ProductDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi thêm Product!", ex);

            return 0;
        }
    }

    public int update(Product product) {

        String sql = "UPDATE PRODUCT "
                + "SET product_name = ?, "
                + "description = ?, "
                + "category_id = ?, "
                + "brand_id = ? "
                + "WHERE product_id = ?";

        try (
                Connection conn = this.getConnection();
                PreparedStatement statement = conn.prepareStatement(sql)
        ) {

            statement.setString(1, product.getProductName());
            statement.setString(2, product.getDescription());
            statement.setInt(3, product.getCategoryId());
            statement.setInt(4, product.getBrandId());
            statement.setInt(5, product.getProductId());

            return statement.executeUpdate();

        } catch (SQLException ex) {

            Logger.getLogger(ProductDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi cập nhật Product!", ex);

            return 0;
        }
    }

    public int delete(int productId) {

        String sql = "DELETE FROM PRODUCT WHERE product_id = ?";

        try (
                Connection conn = this.getConnection();
                PreparedStatement statement = conn.prepareStatement(sql)
        ) {

            statement.setInt(1, productId);

            return statement.executeUpdate();

        } catch (SQLException ex) {

            Logger.getLogger(ProductDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi xóa Product!", ex);

            return 0;
        }
    }

    
    public Product getById(int id) {

        String sql = "SELECT p.product_id, p.product_name, p.description, p.created_at, "
                + "c.category_id, c.category_name, c.parent_id, "
                + "b.brand_id, b.brand_name, b.logo_url "
                + "FROM PRODUCT p "
                + "INNER JOIN CATEGORY c ON p.category_id = c.category_id "
                + "INNER JOIN BRAND b ON p.brand_id = b.brand_id "
                + "WHERE p.product_id = ?";

        try (
                Connection conn = this.getConnection();
                PreparedStatement statement = conn.prepareStatement(sql)
        ) {

            statement.setInt(1, id);

            try (ResultSet rs = statement.executeQuery()) {

                if (rs.next()) {

                    Category category = new Category(
                            rs.getInt("category_id"),
                            rs.getString("category_name"),
                            rs.getObject("parent_id") != null
                                    ? rs.getInt("parent_id")
                                    : null
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
                            category,
                            brand
                    );
                }
            }

        } catch (SQLException ex) {

            Logger.getLogger(ProductDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi lấy Product theo ID!", ex);
        }

        return null;
    }
}