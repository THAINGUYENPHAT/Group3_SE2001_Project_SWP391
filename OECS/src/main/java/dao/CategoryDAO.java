package dao;

import db.DBContext;
import model.Category;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import java.util.logging.Level;
import java.util.logging.Logger;

public class CategoryDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(CategoryDAO.class.getName());

    private static final String CATEGORY_COLUMNS
            = "category_id, category_name, parent_id, "
            + "description, is_active ";

    private Category mapCategory(ResultSet rs)
            throws SQLException {

        Object parentValue = rs.getObject("parent_id");

        Integer parentId = parentValue == null
                ? null
                : ((Number) parentValue).intValue();

        return new Category(
                rs.getInt("category_id"),
                rs.getString("category_name"),
                parentId,
                rs.getString("description"),
                rs.getBoolean("is_active")
        );
    }

    public List<Category> getList() {

        List<Category> list = new ArrayList<>();

        String sql
                = "SELECT " + CATEGORY_COLUMNS
                + "FROM CATEGORY "
                + "ORDER BY parent_id ASC, "
                + "category_name ASC, category_id ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapCategory(rs));
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot get category list",
                    ex
            );
            throw new RuntimeException(
                    "Cannot get category list", ex
            );
        }

        return list;
    }

    public List<Category> getActiveCategories() {

        List<Category> list = new ArrayList<>();

        String sql
                = "SELECT " + CATEGORY_COLUMNS
                + "FROM CATEGORY "
                + "WHERE is_active = 1 "
                + "ORDER BY parent_id ASC, "
                + "category_name ASC, category_id ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapCategory(rs));
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot get active categories",
                    ex
            );
            throw new RuntimeException(
                    "Cannot get active categories", ex
            );
        }

        return list;
    }

    public Category getById(int id) {

        String sql
                = "SELECT " + CATEGORY_COLUMNS
                + "FROM CATEGORY "
                + "WHERE category_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapCategory(rs);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot get category by ID",
                    ex
            );
            throw new RuntimeException(
                    "Cannot get category by ID", ex
            );
        }

        return null;
    }

    public boolean isCategoryNameExists(String categoryName)
            throws SQLException {

        return isCategoryNameExists(categoryName, 0);
    }

    public boolean isCategoryNameExists(
            String categoryName,
            int excludeCategoryId) throws SQLException {

        if (categoryName == null
                || categoryName.trim().isEmpty()) {
            return false;
        }

        String sql
                = "SELECT 1 FROM CATEGORY "
                + "WHERE LOWER(LTRIM(RTRIM(category_name))) "
                + "= LOWER(LTRIM(RTRIM(?))) "
                + "AND category_id <> ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, categoryName.trim());
            ps.setInt(2, excludeCategoryId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public int insert(Category category) {

        if (!isValidCategory(category)) {
            return 0;
        }

        String sql
                = "INSERT INTO CATEGORY "
                + "(category_name, parent_id, "
                + "description, is_active) "
                + "VALUES (?, ?, ?, ?)";

        try (Connection conn = getConnection()) {

            if (!isValidParent(
                    conn, category.getParentId(), null)) {
                return 0;
            }

            try (PreparedStatement ps
                    = conn.prepareStatement(sql)) {

                ps.setNString(
                        1, category.getCategoryName().trim()
                );

                setParentId(ps, 2, category.getParentId());

                ps.setNString(
                        3, category.getDescription()
                );

                ps.setBoolean(4, category.isActive());

                return ps.executeUpdate();
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot insert category",
                    ex
            );
            return 0;
        }
    }

    public int edit(Category category) {

        if (!isValidCategory(category)
                || category.getCategoryId() <= 0) {
            return 0;
        }

        String sql
                = "UPDATE CATEGORY "
                + "SET category_name = ?, "
                + "parent_id = ?, "
                + "description = ?, "
                + "is_active = ? "
                + "WHERE category_id = ?";

        try (Connection conn = getConnection()) {

            boolean oldAutoCommit = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                if (!isValidParent(
                        conn,
                        category.getParentId(),
                        category.getCategoryId())) {

                    conn.rollback();
                    return 0;
                }

                int result;

                try (PreparedStatement ps
                        = conn.prepareStatement(sql)) {

                    ps.setNString(
                            1, category.getCategoryName().trim()
                    );

                    setParentId(
                            ps, 2, category.getParentId()
                    );

                    ps.setNString(
                            3, category.getDescription()
                    );

                    ps.setBoolean(4, category.isActive());

                    ps.setInt(
                            5, category.getCategoryId()
                    );

                    result = ps.executeUpdate();
                }

                conn.commit();
                return result;

            } catch (SQLException ex) {

                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    ex.addSuppressed(rollbackEx);
                }

                LOGGER.log(
                        Level.SEVERE,
                        "Cannot update category",
                        ex
                );
                return 0;

            } finally {
                try {
                    conn.setAutoCommit(oldAutoCommit);
                } catch (SQLException ex) {
                    LOGGER.log(
                            Level.WARNING,
                            "Cannot restore autoCommit",
                            ex
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot connect to update category",
                    ex
            );
            return 0;
        }
    }

    private boolean isValidCategory(Category category) {

        if (category == null
                || category.getCategoryName() == null) {
            return false;
        }

        String name = category.getCategoryName().trim();

        if (name.isEmpty() || name.length() > 100) {
            return false;
        }

        return category.getDescription() == null
                || category.getDescription().length() <= 500;
    }

    private boolean isValidParent(
            Connection conn,
            Integer parentId,
            Integer categoryId) throws SQLException {

        if (parentId == null) {
            return true;
        }

        if (parentId <= 0) {
            return false;
        }

        if (categoryId != null
                && parentId.equals(categoryId)) {
            return false;
        }

        String sql
                = "SELECT parent_id "
                + "FROM CATEGORY "
                + "WHERE category_id = ?";

        Set<Integer> visited = new HashSet<>();

        Integer currentId = parentId;

        try (PreparedStatement ps
                = conn.prepareStatement(sql)) {

            while (currentId != null) {

                if (!visited.add(currentId)) {
                    return false;
                }

                if (categoryId != null
                        && currentId.equals(categoryId)) {
                    return false;
                }

                ps.setInt(1, currentId);

                try (ResultSet rs = ps.executeQuery()) {

                    if (!rs.next()) {
                        return false;
                    }

                    Object value = rs.getObject("parent_id");

                    currentId = value == null
                            ? null
                            : ((Number) value).intValue();
                }
            }
        }

        return true;
    }

    private void setParentId(
            PreparedStatement ps,
            int index,
            Integer parentId) throws SQLException {

        if (parentId == null) {
            ps.setNull(index, Types.INTEGER);
        } else {
            ps.setInt(index, parentId);
        }
    }

    public int countCategories() {

        String sql = "SELECT COUNT(*) FROM CATEGORY";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            return rs.next() ? rs.getInt(1) : 0;

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot count categories",
                    ex
            );
            throw new RuntimeException(
                    "Cannot count categories", ex
            );
        }
    }

    public List<Category> searchByName(String keyword) {

        List<Category> list = new ArrayList<>();

        String sql
                = "SELECT " + CATEGORY_COLUMNS
                + "FROM CATEGORY "
                + "WHERE category_name LIKE ? "
                + "ORDER BY parent_id ASC, "
                + "category_name ASC, category_id ASC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, searchPattern(keyword));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapCategory(rs));
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot search categories",
                    ex
            );
            throw new RuntimeException(
                    "Cannot search categories", ex
            );
        }

        return list;
    }

    public int countSearchResults(String keyword) {

        String sql
                = "SELECT COUNT(*) FROM CATEGORY "
                + "WHERE category_name LIKE ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, searchPattern(keyword));

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot count category search results",
                    ex
            );
            throw new RuntimeException(
                    "Cannot count category search results", ex
            );
        }
    }

    public List<Category> getListByPage(
            int page,
            int pageSize) {

        List<Category> list = new ArrayList<>();

        validatePage(page, pageSize);

        String sql
                = "SELECT " + CATEGORY_COLUMNS
                + "FROM CATEGORY "
                + "ORDER BY parent_id ASC, "
                + "category_name ASC, category_id ASC "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, offset(page, pageSize));
            ps.setInt(2, pageSize);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapCategory(rs));
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot get categories by page",
                    ex
            );
            throw new RuntimeException(
                    "Cannot get categories by page", ex
            );
        }

        return list;
    }

    public List<Category> searchByNameAndPage(
            String keyword,
            int page,
            int pageSize) {

        List<Category> list = new ArrayList<>();

        validatePage(page, pageSize);

        String sql
                = "SELECT " + CATEGORY_COLUMNS
                + "FROM CATEGORY "
                + "WHERE category_name LIKE ? "
                + "ORDER BY parent_id ASC, "
                + "category_name ASC, category_id ASC "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, searchPattern(keyword));
            ps.setInt(2, offset(page, pageSize));
            ps.setInt(3, pageSize);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapCategory(rs));
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot search categories by page",
                    ex
            );
            throw new RuntimeException(
                    "Cannot search categories by page", ex
            );
        }

        return list;
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
                + "CAST('/' + CAST(c.category_id AS VARCHAR(20)) "
                + "+ '/' AS VARCHAR(MAX)) AS category_path "
                + "FROM CATEGORY c "
                + "WHERE c.category_id IN ("
        );

        appendPlaceholders(sql, categories.size());

        sql.append(
                ") "
                + "UNION ALL "
                + "SELECT ct.root_id, child.category_id, "
                + "CAST(ct.category_path "
                + "+ CAST(child.category_id AS VARCHAR(20)) "
                + "+ '/' AS VARCHAR(MAX)) "
                + "FROM CATEGORY child "
                + "JOIN CategoryTree ct "
                + "ON child.parent_id = ct.descendant_id "
                + "WHERE CHARINDEX( "
                + "'/' + CAST(child.category_id AS VARCHAR(20)) "
                + "+ '/', ct.category_path) = 0 "
                + ") "
                + "SELECT ct.root_id, "
                + "COUNT(p.product_id) AS total "
                + "FROM CategoryTree ct "
                + "LEFT JOIN PRODUCT p "
                + "ON p.category_id = ct.descendant_id "
                + "GROUP BY ct.root_id "
                + "OPTION (MAXRECURSION 32767)"
        );

        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < categories.size(); i++) {
                ps.setInt(
                        i + 1,
                        categories.get(i).getCategoryId()
                );
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    counts.put(
                            rs.getInt("root_id"),
                            rs.getInt("total")
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot get product counts",
                    ex
            );
            throw new RuntimeException(
                    "Cannot get product counts", ex
            );
        }

        return counts;
    }

    public Map<Integer, Integer> getChildCounts(
            List<Category> categories) {

        Map<Integer, Integer> counts = new HashMap<>();

        if (categories == null || categories.isEmpty()) {
            return counts;
        }

        for (Category category : categories) {
            counts.put(category.getCategoryId(), 0);
        }

        StringBuilder sql = new StringBuilder(
                "SELECT parent_id, COUNT(*) AS total "
                + "FROM CATEGORY "
                + "WHERE parent_id IN ("
        );

        appendPlaceholders(sql, categories.size());

        sql.append(") GROUP BY parent_id");

        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < categories.size(); i++) {
                ps.setInt(
                        i + 1,
                        categories.get(i).getCategoryId()
                );
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    counts.put(
                            rs.getInt("parent_id"),
                            rs.getInt("total")
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot get child counts",
                    ex
            );
            throw new RuntimeException(
                    "Cannot get child counts", ex
            );
        }

        return counts;
    }

    public int countProductsByCategoryId(int categoryId) {

        String sql
                = "SELECT COUNT(*) FROM PRODUCT "
                + "WHERE category_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot count category products",
                    ex
            );
            throw new RuntimeException(
                    "Cannot count category products", ex
            );
        }
    }

    public int countChildCategories(int categoryId) {

        String sql
                = "SELECT COUNT(*) FROM CATEGORY "
                + "WHERE parent_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot count child categories",
                    ex
            );
            throw new RuntimeException(
                    "Cannot count child categories", ex
            );
        }
    }

    public int delete(Category category) {

        if (category == null
                || category.getCategoryId() <= 0) {
            return 0;
        }

        return setCategoryActive(
                category.getCategoryId(),
                false
        );
    }

    public int setCategoryActive(
            int categoryId,
            boolean active) {

        if (categoryId <= 0) {
            return 0;
        }

        String sql
                = "UPDATE CATEGORY "
                + "SET is_active = ? "
                + "WHERE category_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setBoolean(1, active);
            ps.setInt(2, categoryId);

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot change category status",
                    ex
            );
            return 0;
        }
    }

    private void appendPlaceholders(
            StringBuilder sql,
            int count) {

        for (int i = 0; i < count; i++) {

            if (i > 0) {
                sql.append(", ");
            }

            sql.append("?");
        }
    }

    private String searchPattern(String keyword) {

        return "%" + (keyword == null
                ? ""
                : keyword.trim()) + "%";
    }

    private void validatePage(int page, int pageSize) {

        if (page <= 0 || pageSize <= 0) {
            throw new IllegalArgumentException(
                    "Page và pageSize phải lớn hơn 0."
            );
        }
    }

    private int offset(int page, int pageSize) {

        long value = ((long) page - 1) * pageSize;

        if (value > Integer.MAX_VALUE) {
            throw new IllegalArgumentException(
                    "Giá trị phân trang quá lớn."
            );
        }

        return (int) value;
    }
}
