package dao;

import db.DBContext;
import model.Category;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class CategoryDAO extends DBContext {

    private static final Logger LOGGER = Logger.getLogger(CategoryDAO.class.getName());

    // =====================================================
    // 1. LẤY DANH SÁCH TẤT CẢ CÁC DANH MỤC
    // =====================================================
    public List<Category> getList() {
        List<Category> list = new ArrayList<>();
        String sql = "SELECT category_id, category_name, parent_id "
                + "FROM CATEGORY ORDER BY parent_id ASC, category_name ASC";

        try (Connection conn = getConnection();
             PreparedStatement statement = conn.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {
                Category category = new Category(
                        rs.getInt("category_id"),
                        rs.getString("category_name"),
                        rs.getObject("parent_id") != null
                                ? rs.getInt("parent_id")
                                : null
                );

                list.add(category);
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy danh sách Category!", ex);
        }

        return list;
    }

    // =====================================================
    // 2. THÊM DANH MỤC MỚI
    // =====================================================
    public int insert(Category category) {
        String sql = "INSERT INTO CATEGORY (category_name, parent_id) VALUES (?, ?)";

        try (Connection conn = getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setString(1, category.getCategoryName());

            if (category.getParentId() != null) {
                statement.setInt(2, category.getParentId());
            } else {
                statement.setNull(2, java.sql.Types.INTEGER);
            }

            return statement.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi thêm Category!", ex);
            return 0;
        }
    }

    // =====================================================
    // 3. CẬP NHẬT DANH MỤC
    // =====================================================
    public int edit(Category category) {
        String sql = "UPDATE CATEGORY "
                + "SET category_name = ?, parent_id = ? "
                + "WHERE category_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setString(1, category.getCategoryName());

            if (category.getParentId() != null) {
                statement.setInt(2, category.getParentId());
            } else {
                statement.setNull(2, java.sql.Types.INTEGER);
            }

            statement.setInt(3, category.getCategoryId());

            return statement.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi cập nhật Category!", ex);
            return 0;
        }
    }

    // =====================================================
    // 4. XÓA DANH MỤC
    // =====================================================
    public int delete(Category category) {
        String sql = "DELETE FROM CATEGORY WHERE category_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, category.getCategoryId());

            return statement.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi xóa Category!", ex);
            return 0;
        }
    }

    // =====================================================
    // 5. LẤY DANH MỤC THEO ID
    // =====================================================
    public Category getById(int id) {
        String sql = "SELECT category_id, category_name, parent_id "
                + "FROM CATEGORY WHERE category_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, id);

            try (ResultSet rs = statement.executeQuery()) {

                if (rs.next()) {
                    return new Category(
                            rs.getInt("category_id"),
                            rs.getString("category_name"),
                            rs.getObject("parent_id") != null
                                    ? rs.getInt("parent_id")
                                    : null
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy Category theo ID!", ex);
        }

        return null;
    }
}