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

    private void setParentId(
            PreparedStatement ps, int index, Integer parentId)
            throws SQLException {

        if (parentId == null) {
            ps.setNull(index, java.sql.Types.INTEGER);
        } else {
            ps.setInt(index, parentId);
        }
    }

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

    public Map<Integer, Integer> getProductCounts(
            List<Category> categories) {

        Map<Integer, Integer> counts = new HashMap<>();

        if (categories == null || categories.isEmpty()) {
            return counts;
        }

        for (Category category : categories) {
            counts.put(category.getCategoryId(), 0);
        }

        StringBuilder sql = new StringBuilder(
                "WITH CategoryTree AS ( "
                + "SELECT c.category_id AS root_id, "
                + "c.category_id AS descendant_id, "
                + "CAST('/' + CAST(c.category_id AS VARCHAR(20)) + '/' "
                + "AS VARCHAR(MAX)) AS category_path "
                + "FROM CATEGORY c "
                + "WHERE c.category_id IN ("
        );

        appendPlaceholders(sql, categories.size());

        sql.append(
                ") "
                + "UNION ALL "
                + "SELECT ct.root_id, child.category_id AS descendant_id, "
                + "CAST(ct.category_path "
                + "+ CAST(child.category_id AS VARCHAR(20)) + '/' "
                + "AS VARCHAR(MAX)) AS category_path "
                + "FROM CATEGORY child "
                + "INNER JOIN CategoryTree ct "
                + "ON child.parent_id = ct.descendant_id "
                + "WHERE CHARINDEX( "
                + "'/' + CAST(child.category_id AS VARCHAR(20)) + '/', "
                + "ct.category_path) = 0 "
                + ") "
                + "SELECT ct.root_id, COUNT(p.category_id) AS total "
                + "FROM CategoryTree ct "
                + "LEFT JOIN PRODUCT p "
                + "ON p.category_id = ct.descendant_id "
                + "GROUP BY ct.root_id "
                + "OPTION (MAXRECURSION 32767)"
        );

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < categories.size(); i++) {
                ps.setInt(i + 1, categories.get(i).getCategoryId());
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    counts.put(
                            rs.getInt("root_id"),
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

    private void appendPlaceholders(StringBuilder sql, int count) {
        for (int i = 0; i < count; i++) {
            if (i > 0) {
                sql.append(", ");
            }
            sql.append("?");
        }
    }

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