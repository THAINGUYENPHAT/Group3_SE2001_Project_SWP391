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

    // Lấy danh sách sắp xếp theo danh mục cha và thứ tự hiển thị
    public List<Category> getList() {
        List<Category> list = new ArrayList<>();
        String sql = "SELECT category_id, category_name, parent_id, display_order FROM CATEGORY ORDER BY parent_id ASC, display_order ASC";

        try (Connection conn = this.getConnection();
             PreparedStatement statement = conn.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {
                Category category = new Category(
                    rs.getInt("category_id"),
                    rs.getString("category_name"),
                    rs.getObject("parent_id") != null ? rs.getInt("parent_id") : null,
                    rs.getInt("display_order")
                );
                list.add(category);
            }
        } catch (SQLException ex) {
            Logger.getLogger(CategoryDAO.class.getName()).log(Level.SEVERE, "Lỗi lấy danh sách Category!", ex);
        }
        return list;
    }

    public boolean insert(Category category) {
        String sql = "INSERT INTO CATEGORY (category_name, parent_id, display_order) VALUES (?, ?, ?)";
        try (Connection conn = this.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, category.getCategoryName());
            if (category.getParentId() != null && category.getParentId() > 0) {
                ps.setInt(2, category.getParentId());
            } else {
                ps.setNull(2, java.sql.Types.INTEGER);
            }
            ps.setInt(3, category.getDisplayOrder());
            return ps.executeUpdate() > 0;
        } catch (SQLException ex) {
            Logger.getLogger(CategoryDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return false;
    }

    public boolean update(Category category) {
        String sql = "UPDATE CATEGORY SET category_name = ?, parent_id = ?, display_order = ? WHERE category_id = ?";
        try (Connection conn = this.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, category.getCategoryName());
            if (category.getParentId() != null && category.getParentId() > 0) {
                ps.setInt(2, category.getParentId());
            } else {
                ps.setNull(2, java.sql.Types.INTEGER);
            }
            ps.setInt(3, category.getDisplayOrder());
            ps.setInt(4, category.getCategoryId());
            return ps.executeUpdate() > 0;
        } catch (SQLException ex) {
            Logger.getLogger(CategoryDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return false;
    }

    public boolean delete(int categoryId) {
        // Lưu ý: Cần xử lý/xóa các danh mục con trước khi xóa danh mục cha (hoặc dùng ON DELETE CASCADE trong DB)
        String sql = "DELETE FROM CATEGORY WHERE category_id = ?";
        try (Connection conn = this.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            return ps.executeUpdate() > 0;
        } catch (SQLException ex) {
            Logger.getLogger(CategoryDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return false;
    }
}