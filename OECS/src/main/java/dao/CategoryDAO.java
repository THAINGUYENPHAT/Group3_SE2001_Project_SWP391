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
    // 1. LẤY DANH SÁCH DANH MỤC (SẮP XẾP THEO CHA & THỨ TỰ HIỂN THỊ)
    // =====================================================
    public List<Category> getList() {
        List<Category> list = new ArrayList<>();
        String sql = "SELECT category_id, category_name, parent_id, display_order "
                + "FROM CATEGORY ORDER BY parent_id ASC, display_order ASC";

        try (Connection conn = getConnection();
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
            LOGGER.log(Level.SEVERE, "Lỗi lấy danh sách Category!", ex);
        }
        return list;
    }

    // =====================================================
    // 2. THÊM DANH MỤC MỚI
    // =====================================================
    public boolean insert(Category category) {
        String sql = "INSERT INTO CATEGORY (category_name, parent_id, display_order) VALUES (?, ?, ?)";

        try (Connection conn = getConnection();
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
            LOGGER.log(Level.SEVERE, "Lỗi thêm Category mới!", ex);
        }
        return false;
    }

    // =====================================================
    // 3. CẬP NHẬT DANH MỤC
    // =====================================================
    public boolean update(Category category) {
        String sql = "UPDATE CATEGORY SET category_name = ?, parent_id = ?, display_order = ? WHERE category_id = ?";

        try (Connection conn = getConnection();
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
            LOGGER.log(Level.SEVERE, "Lỗi cập nhật Category!", ex);
        }
        return false;
    }

    // =====================================================
    // 4. XÓA DANH MỤC
    // =====================================================
    public boolean delete(int categoryId) {
        // Lưu ý: Cần xử lý/xóa các danh mục con trước khi xóa danh mục cha (hoặc thiết lập CASCADE trong DB)
        String sql = "DELETE FROM CATEGORY WHERE category_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            return ps.executeUpdate() > 0;

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi xóa Category!", ex);
        }
        return false;
    }
}