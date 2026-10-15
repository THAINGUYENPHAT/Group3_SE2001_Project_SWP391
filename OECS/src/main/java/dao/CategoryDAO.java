package dao;

import db.DBContext;
import model.Category;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

public class CategoryDAO extends DBContext {

    private static final Logger LOGGER =
            Logger.getLogger(CategoryDAO.class.getName());

    // Lay toan bo danh muc
    public List<Category> getList() {
        List<Category> list = new ArrayList<>();

        String sql = "SELECT category_id, category_name, parent_id "
                + "FROM CATEGORY "
                + "ORDER BY parent_id ASC, category_name ASC";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapCategory(rs));
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot get category list", e);
            throw new RuntimeException("Cannot get category list", e);
        }

        return list;
    }

    // Lay danh muc theo ID
    public Category getById(int id) {
        String sql = "SELECT category_id, category_name, parent_id "
                + "FROM CATEGORY WHERE category_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapCategory(rs);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot get category by ID", e);
            throw new RuntimeException("Cannot get category by ID", e);
        }

        return null;
    }

    // Chuyen ResultSet thanh Category
    private Category mapCategory(ResultSet rs) throws SQLException {
        Object parentValue = rs.getObject("parent_id");

        Integer parentId = parentValue == null
                ? null : ((Number) parentValue).intValue();

        return new Category(
                rs.getInt("category_id"),
                rs.getString("category_name"),
                parentId
        );
    }

    // Kiem tra ten danh muc da ton tai khi them moi
    public boolean isCategoryNameExists(String categoryName)
            throws SQLException {

        String sql = "SELECT COUNT(*) "
                + "FROM CATEGORY "
                + "WHERE LOWER(LTRIM(RTRIM(category_name))) = LOWER(?)";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, categoryName.trim());

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        }

        return false;
    }

    // Kiem tra ten danh muc da ton tai khi sua
    // Bo qua danh muc dang duoc sua
    public boolean isCategoryNameExists(
            String categoryName, int excludeCategoryId)
            throws SQLException {

        String sql = "SELECT COUNT(*) "
                + "FROM CATEGORY "
                + "WHERE LOWER(LTRIM(RTRIM(category_name))) = LOWER(?) "
                + "AND category_id <> ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, categoryName.trim());
            ps.setInt(2, excludeCategoryId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        }

        return false;
    }

    // Them danh muc
    public int insert(Category category) {
        String sql = "INSERT INTO CATEGORY (category_name, parent_id) "
                + "VALUES (?, ?)";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, category.getCategoryName());
            setParentId(ps, 2, category.getParentId());

            return ps.executeUpdate();

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot insert category", e);
            return 0;
        }
    }

    // Cap nhat danh muc
    public int edit(Category category) {
        String sql = "UPDATE CATEGORY "
                + "SET category_name = ?, parent_id = ? "
                + "WHERE category_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, category.getCategoryName());
            setParentId(ps, 2, category.getParentId());
            ps.setInt(3, category.getCategoryId());

            return ps.executeUpdate();

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot update category", e);
            return 0;
        }
    }

    // Gan parent_id, cho phep de trong neu la danh muc goc
    private void setParentId(
            PreparedStatement ps, int index, Integer parentId)
            throws SQLException {

        if (parentId == null) {
            ps.setNull(index, java.sql.Types.INTEGER);
        } else {
            ps.setInt(index, parentId);
        }
    }

    // Dem tong so danh muc
    public int countCategories() {
        String sql = "SELECT COUNT(*) FROM CATEGORY";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot count categories", e);
            throw new RuntimeException("Cannot count categories", e);
        }

        return 0;
    }

    // Tim kiem danh muc theo ten
    public List<Category> searchByName(String keyword) {
        List<Category> list = new ArrayList<>();

        String sql = "SELECT category_id, category_name, parent_id "
                + "FROM CATEGORY "
                + "WHERE category_name LIKE ? "
                + "ORDER BY parent_id ASC, category_name ASC";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, "%" + keyword + "%");

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapCategory(rs));
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot search categories", e);
            throw new RuntimeException("Cannot search categories", e);
        }

        return list;
    }

    // Dem ket qua tim kiem
    public int countSearchResults(String keyword) {
        String sql = "SELECT COUNT(*) FROM CATEGORY "
                + "WHERE category_name LIKE ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, "%" + keyword + "%");

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot count search results", e);
            throw new RuntimeException("Cannot count search results", e);
        }

        return 0;
    }

    // Lay danh muc theo trang
    public List<Category> getListByPage(int page, int pageSize) {
        List<Category> list = new ArrayList<>();

        String sql = "SELECT category_id, category_name, parent_id "
                + "FROM CATEGORY "
                + "ORDER BY parent_id ASC, category_name ASC "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, (page - 1) * pageSize);
            ps.setInt(2, pageSize);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapCategory(rs));
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot get categories by page", e);
            throw new RuntimeException("Cannot get categories by page", e);
        }

        return list;
    }

    // Tim kiem danh muc va phan trang
    public List<Category> searchByNameAndPage(
            String keyword, int page, int pageSize) {

        List<Category> list = new ArrayList<>();

        String sql = "SELECT category_id, category_name, parent_id "
                + "FROM CATEGORY "
                + "WHERE category_name LIKE ? "
                + "ORDER BY parent_id ASC, category_name ASC "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, "%" + keyword + "%");
            ps.setInt(2, (page - 1) * pageSize);
            ps.setInt(3, pageSize);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapCategory(rs));
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot search categories by page", e);
            throw new RuntimeException(
                    "Cannot search categories by page", e);
        }

        return list;
    }

    // Lay ten tat ca danh muc theo ID
    public Map<Integer, String> getCategoryNames() {
        Map<Integer, String> names = new HashMap<>();

        String sql = "SELECT category_id, category_name FROM CATEGORY";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                names.put(
                        rs.getInt("category_id"),
                        rs.getString("category_name")
                );
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot get category names", e);
            throw new RuntimeException("Cannot get category names", e);
        }

        return names;
    }

    // Dem so san pham cua cac danh muc tren trang
    public Map<Integer, Integer> getProductCounts(
            List<Category> categories) {

        Map<Integer, Integer> counts = new HashMap<>();

        if (categories == null || categories.isEmpty()) {
            return counts;
        }

        StringBuilder sql = new StringBuilder(
                "SELECT category_id, COUNT(*) AS total "
                + "FROM PRODUCT WHERE category_id IN ("
        );

        appendPlaceholders(sql, categories.size());
        sql.append(") GROUP BY category_id");

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < categories.size(); i++) {
                ps.setInt(i + 1, categories.get(i).getCategoryId());
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    counts.put(
                            rs.getInt("category_id"),
                            rs.getInt("total")
                    );
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot get product counts", e);
            throw new RuntimeException("Cannot get product counts", e);
        }

        return counts;
    }

    // Dem so danh muc con cua cac danh muc tren trang
    public Map<Integer, Integer> getChildCounts(
            List<Category> categories) {

        Map<Integer, Integer> counts = new HashMap<>();

        if (categories == null || categories.isEmpty()) {
            return counts;
        }

        StringBuilder sql = new StringBuilder(
                "SELECT parent_id, COUNT(*) AS total "
                + "FROM CATEGORY WHERE parent_id IN ("
        );

        appendPlaceholders(sql, categories.size());
        sql.append(") GROUP BY parent_id");

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < categories.size(); i++) {
                ps.setInt(i + 1, categories.get(i).getCategoryId());
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    counts.put(
                            rs.getInt("parent_id"),
                            rs.getInt("total")
                    );
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot get child counts", e);
            throw new RuntimeException("Cannot get child counts", e);
        }

        return counts;
    }

    // Tao danh sach dau ? cho cau lenh SQL
    private void appendPlaceholders(StringBuilder sql, int count) {
        for (int i = 0; i < count; i++) {
            if (i > 0) {
                sql.append(", ");
            }
            sql.append("?");
        }
    }

    // Dem so san pham thuoc mot danh muc
    public int countProductsByCategoryId(int categoryId) {
        String sql = "SELECT COUNT(*) FROM PRODUCT WHERE category_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot count category products", e);
            throw new RuntimeException(
                    "Cannot count category products", e);
        }

        return 0;
    }

    // Dem so danh muc con cua mot danh muc
    public int countChildCategories(int categoryId) {
        String sql = "SELECT COUNT(*) FROM CATEGORY WHERE parent_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot count child categories", e);
            throw new RuntimeException(
                    "Cannot count child categories", e);
        }

        return 0;
    }

    // Xoa danh muc
    public int delete(Category category) {
        String sql = "DELETE FROM CATEGORY WHERE category_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, category.getCategoryId());

            return ps.executeUpdate();

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot delete category", e);
            return 0;
        }
    }
}