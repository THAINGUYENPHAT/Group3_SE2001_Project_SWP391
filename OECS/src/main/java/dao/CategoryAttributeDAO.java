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
                    "Lỗi lấy cấu hình CategoryAttribute!",
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
                        "Lỗi lưu CategoryAttribute!",
                        ex
                );

                return false;

            } finally {
                try {
                    conn.setAutoCommit(oldAutoCommit);
                } catch (SQLException ex) {
                    LOGGER.log(
                            Level.WARNING,
                            "Lỗi khôi phục autoCommit!",
                            ex
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi kết nối CategoryAttribute!",
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
                    "Lỗi xóa cấu hình CategoryAttribute!",
                    ex
            );
        }

        return false;
    }

    private boolean isValidAttributeType(String type) {

        return "SPECIFICATION".equals(type)
                || "VARIANT".equals(type)
                || "BOTH".equals(type);
    }
}
