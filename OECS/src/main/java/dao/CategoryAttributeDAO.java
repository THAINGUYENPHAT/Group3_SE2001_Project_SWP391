package dao;

import db.DBContext;
import model.CategoryAttribute;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class CategoryAttributeDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(CategoryAttributeDAO.class.getName());

    private static final String BASE_SELECT
            = "SELECT "
            + "ca.category_id, "
            + "ca.attribute_id, "
            + "ca.group_name, "
            + "ca.attribute_type, "
            + "ca.is_required, "
            + "ca.is_filterable, "
            + "ca.display_order, "
            + "a.attribute_name, "
            + "a.data_type, "
            + "a.unit "
            + "FROM CATEGORY_ATTRIBUTE ca "
            + "INNER JOIN ATTRIBUTE a "
            + "ON ca.attribute_id = a.attribute_id ";

    private CategoryAttribute mapCategoryAttribute(
            ResultSet rs) throws SQLException {

        return new CategoryAttribute(
                rs.getInt("category_id"),
                rs.getInt("attribute_id"),
                rs.getString("group_name"),
                rs.getString("attribute_type"),
                rs.getBoolean("is_required"),
                rs.getBoolean("is_filterable"),
                rs.getInt("display_order"),
                rs.getString("attribute_name"),
                rs.getString("data_type"),
                rs.getString("unit")
        );
    }

    public List<CategoryAttribute> getByCategoryId(
            int categoryId) {

        List<CategoryAttribute> list
                = new ArrayList<>();

        String sql = BASE_SELECT
                + "WHERE ca.category_id = ? "
                + "ORDER BY ca.display_order, "
                + "ca.attribute_id";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    list.add(mapCategoryAttribute(rs));
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi lay thuoc tinh theo danh muc!",
                    ex
            );

            throw new IllegalStateException(
                    "Khong the tai cau hinh thuoc tinh danh muc.",
                    ex
            );
        }

        return list;
    }

    public List<CategoryAttribute> getSpecificationAttributes(
            int categoryId) {

        List<CategoryAttribute> list
                = new ArrayList<>();

        String sql = BASE_SELECT
                + "WHERE ca.category_id = ? "
                + "AND ca.attribute_type IN "
                + "('SPECIFICATION', 'BOTH') "
                + "AND a.is_active = 1 "
                + "ORDER BY ca.display_order, "
                + "ca.attribute_id";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    list.add(mapCategoryAttribute(rs));
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi lay thuoc tinh thong so ky thuat!",
                    ex
            );

            throw new IllegalStateException(
                    "Khong the tai thuoc tinh thong so ky thuat.",
                    ex
            );
        }

        return list;
    }

    public List<CategoryAttribute> getVariantAttributes(
            int categoryId) {

        List<CategoryAttribute> list
                = new ArrayList<>();

        String sql = BASE_SELECT
                + "WHERE ca.category_id = ? "
                + "AND ca.attribute_type IN "
                + "('VARIANT', 'BOTH') "
                + "AND a.is_active = 1 "
                + "ORDER BY ca.display_order, "
                + "ca.attribute_id";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    list.add(mapCategoryAttribute(rs));
                }
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi lay thuoc tinh bien the SKU!",
                    ex
            );

            throw new IllegalStateException(
                    "Khong the tai thuoc tinh bien the SKU.",
                    ex
            );
        }

        return list;
    }

    public CategoryAttribute getByCategoryAndAttribute(
            int categoryId,
            int attributeId) {

        String sql = BASE_SELECT
                + "WHERE ca.category_id = ? "
                + "AND ca.attribute_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);
            ps.setInt(2, attributeId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return mapCategoryAttribute(rs);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lá»—i láº¥y cáº¥u hÃ¬nh CategoryAttribute!",
                    ex
            );
        }

        return null;
    }

    public boolean save(CategoryAttribute config) {

        if (config == null
                || config.getCategoryId() <= 0
                || config.getAttributeId() <= 0) {
            return false;
        }

        String attributeType
                = config.getAttributeType();

        if (!isValidAttributeType(attributeType)) {
            return false;
        }

        if (config.getDisplayOrder() < 0) {
            return false;
        }

        String groupName = config.getGroupName();

        if (groupName == null
                || groupName.trim().isEmpty()
                || groupName.trim().length() > 100) {
            return false;
        }

        String sql
                = "UPDATE CATEGORY_ATTRIBUTE "
                + "WITH (UPDLOCK, SERIALIZABLE) "
                + "SET group_name = ?, "
                + "attribute_type = ?, "
                + "is_required = ?, "
                + "is_filterable = ?, "
                + "display_order = ? "
                + "WHERE category_id = ? "
                + "AND attribute_id = ?; "
                + "IF @@ROWCOUNT = 0 "
                + "BEGIN "
                + "INSERT INTO CATEGORY_ATTRIBUTE "
                + "(category_id, attribute_id, "
                + "group_name, attribute_type, "
                + "is_required, is_filterable, "
                + "display_order) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?); "
                + "END";

        try (Connection conn = this.getConnection()) {

            boolean oldAutoCommit
                    = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                try (PreparedStatement ps
                        = conn.prepareStatement(sql)) {

                    ps.setNString(1, groupName.trim());
                    ps.setString(2, attributeType);
                    ps.setBoolean(3, config.isRequired());
                    ps.setBoolean(4, config.isFilterable());
                    ps.setInt(5, config.getDisplayOrder());
                    ps.setInt(6, config.getCategoryId());
                    ps.setInt(7, config.getAttributeId());

                    ps.setInt(8, config.getCategoryId());
                    ps.setInt(9, config.getAttributeId());
                    ps.setNString(10, groupName.trim());
                    ps.setString(11, attributeType);
                    ps.setBoolean(12, config.isRequired());
                    ps.setBoolean(13, config.isFilterable());
                    ps.setInt(14, config.getDisplayOrder());

                    ps.executeUpdate();
                }

                conn.commit();
                return true;

            } catch (SQLException ex) {

                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    ex.addSuppressed(rollbackEx);
                }

                LOGGER.log(
                        Level.SEVERE,
                        "Lá»—i lÆ°u CategoryAttribute!",
                        ex
                );

                return false;

            } finally {
                try {
                    conn.setAutoCommit(oldAutoCommit);
                } catch (SQLException ex) {
                    LOGGER.log(
                            Level.WARNING,
                            "Lá»—i khÃ´i phá»¥c autoCommit!",
                            ex
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lá»—i káº¿t ná»‘i CategoryAttribute!",
                    ex
            );
        }

        return false;
    }

    public boolean delete(
            int categoryId,
            int attributeId) {

        if (categoryId <= 0 || attributeId <= 0) {
            return false;
        }

        String sql
                = "DELETE FROM CATEGORY_ATTRIBUTE "
                + "WHERE category_id = ? "
                + "AND attribute_id = ? "
                + "AND NOT EXISTS ("
                + "SELECT 1 "
                + "FROM PRODUCT p "
                + "JOIN PRODUCT_SPECIFICATION ps "
                + "ON ps.product_id = p.product_id "
                + "WHERE p.category_id = ? "
                + "AND ps.attribute_id = ?"
                + ") "
                + "AND NOT EXISTS ("
                + "SELECT 1 "
                + "FROM PRODUCT p "
                + "JOIN PRODUCT_SKU s "
                + "ON s.product_id = p.product_id "
                + "JOIN SKU_ATTRIBUTE_VALUE sav "
                + "ON sav.sku_id = s.sku_id "
                + "WHERE p.category_id = ? "
                + "AND sav.attribute_id = ?"
                + ")";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, categoryId);
            ps.setInt(2, attributeId);

            ps.setInt(3, categoryId);
            ps.setInt(4, attributeId);

            ps.setInt(5, categoryId);
            ps.setInt(6, attributeId);

            return ps.executeUpdate() > 0;

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lá»—i xÃ³a cáº¥u hÃ¬nh CategoryAttribute!",
                    ex
            );
        }

        return false;
    }

    // ======================================================
    // QUáº¢N LÃ THÃ”NG Sá» THEO DANH Má»¤C (FORM EDIT CATEGORY)
    // - Chá»‰ quáº£n lÃ½ pháº§n SPECIFICATION.
    // - KhÃ´ng lÃ m máº¥t VARIANT cá»§a SKU hoáº·c cáº¥u hÃ¬nh inactive.
    // - ToÃ n bá»™ thay Ä‘á»•i Ä‘Æ°á»£c commit/rollback trong má»™t transaction.
    // ======================================================
    public static final class SpecificationSelection {

        private final int attributeId;
        private final String groupName;
        private final boolean required;
        private final boolean filterable;
        private final int displayOrder;

        public SpecificationSelection(int attributeId, String groupName,
                boolean required, boolean filterable, int displayOrder) {
            this.attributeId = attributeId;
            this.groupName = groupName;
            this.required = required;
            this.filterable = filterable;
            this.displayOrder = displayOrder;
        }
    }

    private static final class ExistingConfig {

        private final String type;
        private final boolean required;

        private ExistingConfig(String type, boolean required) {
            this.type = type;
            this.required = required;
        }
    }

    /**
     * Ãp dá»¥ng danh sÃ¡ch thÃ´ng sá»‘ Ä‘Æ°á»£c chá»n trÃªn form Edit
     * Category. CÃ¡c liÃªn káº¿t VARIANT/BOTH Ä‘ang dÃ¹ng cho SKU Ä‘Æ°á»£c
     * báº£o toÃ n. KhÃ´ng gá»i save()/delete() láº·p láº¡i vÃ¬ chÃºng má»Ÿ
     * connection riÃªng.
     */
    public void saveSpecificationSelections(int categoryId,
            java.util.Set<Integer> visibleAttributeIds,
            List<SpecificationSelection> selections) throws SQLException {

        if (categoryId <= 0 || visibleAttributeIds == null
                || selections == null) {
            throw new IllegalArgumentException("Danh má»¥c hoáº·c cáº¥u hÃ¬nh khÃ´ng há»£p lá»‡.");
        }

        java.util.Map<Integer, SpecificationSelection> chosen
                = new java.util.LinkedHashMap<>();

        for (SpecificationSelection item : selections) {
            if (item == null || item.attributeId <= 0
                    || chosen.putIfAbsent(item.attributeId, item) != null) {
                throw new IllegalArgumentException(
                        "Danh sÃ¡ch thuá»™c tÃ­nh cÃ³ ID khÃ´ng há»£p lá»‡ hoáº·c bá»‹ trÃ¹ng.");
            }
        }

        try (Connection conn = getConnection()) {
            boolean oldAutoCommit = conn.getAutoCommit();
            int oldIsolation = conn.getTransactionIsolation();
            try {
                conn.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
                conn.setAutoCommit(false);

                assertChildCategory(conn, categoryId);

                java.util.Set<Integer> activeIds = loadActiveAttributeIds(conn);
                if (!activeIds.containsAll(visibleAttributeIds)
                        || !visibleAttributeIds.containsAll(chosen.keySet())) {
                    throw new IllegalArgumentException(
                            "Thuá»™c tÃ­nh khÃ´ng tá»“n táº¡i hoáº·c Ä‘Ã£ ngá»«ng sá»­ dá»¥ng. Táº£i láº¡i trang.");
                }

                java.util.Map<Integer, ExistingConfig> existing
                        = loadExistingConfigurations(conn, categoryId);

                // Chá»‰ xá»­ lÃ½ thuá»™c tÃ­nh Ä‘ang hoáº¡t Ä‘á»™ng. LiÃªn káº¿t cá»§a thuá»™c tÃ­nh
                // inactive Ä‘Æ°á»£c giá»¯ nguyÃªn, trÃ¡nh xÃ³a dá»¯ liá»‡u ngoÃ i Ã½ muá»‘n.
                for (Integer attrId : new java.util.TreeSet<>(visibleAttributeIds)) {
                    ExistingConfig old = existing.get(attrId);
                    SpecificationSelection item = chosen.get(attrId);

                    if (item == null) {
                        if (old == null || "VARIANT".equals(old.type)) {
                            continue;
                        }
                        if (hasProductSpecValue(conn, categoryId, attrId)) {
                            throw new IllegalStateException(
                                    "KhÃ´ng thá»ƒ bá» thuá»™c tÃ­nh #" + attrId
                                    + " vÃ¬ Ä‘Ã£ cÃ³ sáº£n pháº©m dÃ¹ng thÃ´ng sá»‘ nÃ y.");
                        }

                        if ("BOTH".equals(old.type)) {
                            // Chá»‰ táº¯t SPECIFICATION; giá»¯ VARIANT vÃ  metadata SKU.
                            changeAttributeType(conn, categoryId, attrId, "VARIANT");
                        } else {
                            if (hasSkuAttributeValue(conn, categoryId, attrId)) {
                                throw new IllegalStateException(
                                        "Thuá»™c tÃ­nh #" + attrId
                                        + " Ä‘Ã£ cÃ³ SKU sá»­ dá»¥ng, khÃ´ng thá»ƒ bá» cáº¥u hÃ¬nh.");
                            }
                            deleteConfiguration(conn, categoryId, attrId);
                        }
                        continue;
                    }

                    if (old != null && "BOTH".equals(old.type)) {
                        // ÄÃ£ lÃ  SPEC + VARIANT. KhÃ´ng sá»­a thuá»™c tÃ­nh dÃ¹ng chung
                        // (required/group/order/filterable) trÃ¡nh tÃ¡c Ä‘á»™ng SKU.
                        continue;
                    }
                    if (old != null && "VARIANT".equals(old.type)) {
                        // is_required dÃ¹ng chung giá»¯a SKU vÃ  Product.
                        // KhÃ´ng thay Ä‘á»•i flag, chá»‰ thÃªm vai trÃ² SPECIFICATION.
                        if (old.required && hasProductMissingSpec(conn, categoryId, attrId)) {
                            throw new IllegalStateException(
                                    "Thuá»™c tÃ­nh #" + attrId
                                    + " báº¯t buá»™c vá»›i SKU. HÃ£y bá»• sung thÃ´ng sá»‘"
                                    + " cho sáº£n pháº©m hiá»‡n cÃ³ trÆ°á»›c khi báº­t BOTH.");
                        }
                        changeAttributeType(conn, categoryId, attrId, "BOTH");
                        continue;
                    }

                    validateSpecItem(item);
                    if (item.required && hasProductMissingSpec(conn, categoryId, attrId)) {
                        throw new IllegalStateException(
                                "ChÆ°a thá»ƒ Ä‘áº·t thuá»™c tÃ­nh #" + attrId
                                + " lÃ  báº¯t buá»™c: cÃ³ sáº£n pháº©m trong danh má»¥c chÆ°a nháº­p giÃ¡ trá»‹.");
                    }

                    if (old == null) {
                        insertSpecConfiguration(conn, categoryId, item);
                    } else {
                        updateSpecConfiguration(conn, categoryId, item);
                    }
                }

                conn.commit();
            } catch (SQLException | RuntimeException ex) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    ex.addSuppressed(rollbackEx);
                }
                throw ex;
            } finally {
                try {
                    conn.setAutoCommit(oldAutoCommit);
                    conn.setTransactionIsolation(oldIsolation);
                } catch (SQLException ex) {
                    LOGGER.log(Level.WARNING,
                            "KhÃ´ng thá»ƒ khÃ´i phá»¥c cáº¥u hÃ¬nh Connection.", ex);
                }
            }
        }
    }

    private void assertChildCategory(Connection conn, int categoryId)
            throws SQLException {
        String sql = "SELECT parent_id FROM CATEGORY WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE category_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Danh má»¥c khÃ´ng tá»“n táº¡i.");
                }
                if (rs.getObject("parent_id") == null) {
                    throw new IllegalArgumentException(
                            "Chá»‰ cáº¥u hÃ¬nh thÃ´ng sá»‘ cho danh má»¥c con.");
                }
            }
        }
    }

    private java.util.Set<Integer> loadActiveAttributeIds(Connection conn)
            throws SQLException {
        java.util.Set<Integer> ids = new java.util.LinkedHashSet<>();
        String sql = "SELECT attribute_id FROM ATTRIBUTE WITH (HOLDLOCK) "
                + "WHERE is_active = 1 ORDER BY attribute_id";
        try (PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ids.add(rs.getInt(1));
            }
        }
        return ids;
    }

    private java.util.Map<Integer, ExistingConfig> loadExistingConfigurations(
            Connection conn, int categoryId) throws SQLException {
        java.util.Map<Integer, ExistingConfig> map = new java.util.HashMap<>();
        String sql = "SELECT attribute_id, attribute_type, is_required "
                + "FROM CATEGORY_ATTRIBUTE WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE category_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    map.put(rs.getInt("attribute_id"),
                            new ExistingConfig(rs.getString("attribute_type"),
                                    rs.getBoolean("is_required")));
                }
            }
        }
        return map;
    }

    private void validateSpecItem(SpecificationSelection item) {
        if (item.groupName == null || item.groupName.trim().isEmpty()
                || item.groupName.trim().length() > 100
                || item.displayOrder < 0) {
            throw new IllegalArgumentException(
                    "NhÃ³m thÃ´ng sá»‘ hoáº·c thá»© tá»± hiá»ƒn thá»‹ khÃ´ng há»£p lá»‡."
                    + " NhÃ³m tá»‘i Ä‘a 100 kÃ½ tá»±, thá»© tá»± khÃ´ng Ã¢m.");
        }
    }

    private boolean hasProductSpecValue(Connection conn, int categoryId,
            int attributeId) throws SQLException {
        String sql = "SELECT TOP 1 1 FROM PRODUCT p "
                + "JOIN PRODUCT_SPECIFICATION ps WITH (HOLDLOCK) "
                + "ON ps.product_id = p.product_id "
                + "WHERE p.category_id = ? AND ps.attribute_id = ?";
        return existsForCategoryAttribute(conn, sql, categoryId, attributeId);
    }

    private boolean hasSkuAttributeValue(Connection conn, int categoryId,
            int attributeId) throws SQLException {
        String sql = "SELECT TOP 1 1 FROM PRODUCT p "
                + "JOIN PRODUCT_SKU s ON s.product_id = p.product_id "
                + "JOIN SKU_ATTRIBUTE_VALUE sav WITH (HOLDLOCK) "
                + "ON sav.sku_id = s.sku_id "
                + "WHERE p.category_id = ? AND sav.attribute_id = ?";
        return existsForCategoryAttribute(conn, sql, categoryId, attributeId);
    }

    private boolean hasProductMissingSpec(Connection conn, int categoryId,
            int attributeId) throws SQLException {
        String sql = "SELECT TOP 1 1 FROM PRODUCT p WHERE p.category_id = ? "
                + "AND NOT EXISTS (SELECT 1 FROM PRODUCT_SPECIFICATION ps "
                + "WITH (HOLDLOCK) WHERE ps.product_id = p.product_id "
                + "AND ps.attribute_id = ?)";
        return existsForCategoryAttribute(conn, sql, categoryId, attributeId);
    }

    private boolean existsForCategoryAttribute(Connection conn, String sql,
            int categoryId, int attributeId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            ps.setInt(2, attributeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private void changeAttributeType(Connection conn, int categoryId,
            int attributeId, String type) throws SQLException {
        String sql = "UPDATE CATEGORY_ATTRIBUTE SET attribute_type = ? "
                + "WHERE category_id = ? AND attribute_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, type);
            ps.setInt(2, categoryId);
            ps.setInt(3, attributeId);
            if (ps.executeUpdate() != 1) {
                throw new SQLException("KhÃ´ng cáº­p nháº­t Ä‘Æ°á»£c loáº¡i thuá»™c tÃ­nh.");
            }
        }
    }

    private void deleteConfiguration(Connection conn, int categoryId,
            int attributeId) throws SQLException {
        String sql = "DELETE FROM CATEGORY_ATTRIBUTE "
                + "WHERE category_id = ? AND attribute_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            ps.setInt(2, attributeId);
            if (ps.executeUpdate() != 1) {
                throw new SQLException("KhÃ´ng xÃ³a Ä‘Æ°á»£c cáº¥u hÃ¬nh thÃ´ng sá»‘.");
            }
        }
    }

    private void insertSpecConfiguration(Connection conn, int categoryId,
            SpecificationSelection item) throws SQLException {
        String sql = "INSERT INTO CATEGORY_ATTRIBUTE "
                + "(category_id, attribute_id, group_name, attribute_type, "
                + "is_required, is_filterable, display_order) "
                + "VALUES (?, ?, ?, 'SPECIFICATION', ?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            ps.setInt(2, item.attributeId);
            ps.setNString(3, item.groupName.trim());
            ps.setBoolean(4, item.required);
            ps.setBoolean(5, item.filterable);
            ps.setInt(6, item.displayOrder);
            if (ps.executeUpdate() != 1) {
                throw new SQLException("KhÃ´ng thÃªm Ä‘Æ°á»£c cáº¥u hÃ¬nh thÃ´ng sá»‘.");
            }
        }
    }

    private void updateSpecConfiguration(Connection conn, int categoryId,
            SpecificationSelection item) throws SQLException {
        String sql = "UPDATE CATEGORY_ATTRIBUTE SET group_name = ?, "
                + "is_required = ?, is_filterable = ?, display_order = ? "
                + "WHERE category_id = ? AND attribute_id = ? "
                + "AND attribute_type = 'SPECIFICATION'";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, item.groupName.trim());
            ps.setBoolean(2, item.required);
            ps.setBoolean(3, item.filterable);
            ps.setInt(4, item.displayOrder);
            ps.setInt(5, categoryId);
            ps.setInt(6, item.attributeId);
            if (ps.executeUpdate() != 1) {
                throw new SQLException("KhÃ´ng cáº­p nháº­t Ä‘Æ°á»£c cáº¥u hÃ¬nh thÃ´ng sá»‘.");
            }
        }
    }

    private boolean isValidAttributeType(String type) {

        return "SPECIFICATION".equals(type)
                || "VARIANT".equals(type)
                || "BOTH".equals(type);
    }
}
