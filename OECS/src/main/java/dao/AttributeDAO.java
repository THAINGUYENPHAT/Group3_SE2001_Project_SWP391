package dao;

import db.DBContext;
import model.Attribute;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class AttributeDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(AttributeDAO.class.getName());

    private static final String ATTRIBUTE_COLUMNS
            = "attribute_id, attribute_name, "
            + "data_type, unit, is_active ";

    private Attribute mapAttribute(ResultSet rs)
            throws SQLException {

        return new Attribute(
                rs.getInt("attribute_id"),
                rs.getString("attribute_name"),
                rs.getString("data_type"),
                rs.getString("unit"),
                rs.getBoolean("is_active")
        );
    }

    public List<Attribute> getList() {

        List<Attribute> list = new ArrayList<>();

        String sql
                = "SELECT " + ATTRIBUTE_COLUMNS
                + "FROM ATTRIBUTE "
                + "ORDER BY attribute_name, attribute_id";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapAttribute(rs));
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot get attribute list",
                    ex
            );
            throw new RuntimeException(
                    "Cannot get attribute list", ex
            );
        }

        return list;
    }

    public List<Attribute> getActiveAttributes() {

        List<Attribute> list = new ArrayList<>();

        String sql
                = "SELECT " + ATTRIBUTE_COLUMNS
                + "FROM ATTRIBUTE "
                + "WHERE is_active = 1 "
                + "ORDER BY attribute_name, attribute_id";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapAttribute(rs));
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot get active attributes",
                    ex
            );
            throw new RuntimeException(
                    "Cannot get active attributes", ex
            );
        }

        return list;
    }

    public Attribute getById(int attributeId) {

        String sql
                = "SELECT " + ATTRIBUTE_COLUMNS
                + "FROM ATTRIBUTE "
                + "WHERE attribute_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, attributeId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return mapAttribute(rs);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot get attribute by ID",
                    ex
            );
            throw new RuntimeException(
                    "Cannot get attribute by ID", ex
            );
        }

        return null;
    }

    public List<Attribute> searchByName(String keyword) {

        List<Attribute> list = new ArrayList<>();

        String sql
                = "SELECT " + ATTRIBUTE_COLUMNS
                + "FROM ATTRIBUTE "
                + "WHERE attribute_name LIKE ? "
                + "ORDER BY attribute_name, attribute_id";

        String pattern = "%"
                + (keyword == null ? "" : keyword.trim())
                + "%";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, pattern);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    list.add(mapAttribute(rs));
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot search attributes",
                    ex
            );
            throw new RuntimeException(
                    "Cannot search attributes", ex
            );
        }

        return list;
    }

    public boolean isNameExists(String attributeName) {

        return isNameExists(attributeName, 0);
    }

    public boolean isNameExists(
            String attributeName,
            int excludeAttributeId) {

        if (attributeName == null
                || attributeName.trim().isEmpty()) {
            return false;
        }

        String sql
                = "SELECT 1 "
                + "FROM ATTRIBUTE "
                + "WHERE LOWER(LTRIM(RTRIM(attribute_name))) "
                + "= LOWER(LTRIM(RTRIM(?))) "
                + "AND attribute_id <> ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, attributeName.trim());
            ps.setInt(2, excludeAttributeId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot check duplicate attribute name",
                    ex
            );
            throw new RuntimeException(
                    "Cannot check attribute name", ex
            );
        }
    }

    public int insert(Attribute attribute) {

        if (!isValidAttribute(attribute)) {
            return 0;
        }

        if (isNameExists(attribute.getAttributeName())) {
            return 0;
        }

        String sql
                = "INSERT INTO ATTRIBUTE "
                + "(attribute_name, data_type, unit, is_active) "
                + "VALUES (?, ?, ?, ?)";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(
                    1,
                    attribute.getAttributeName().trim()
            );

            ps.setString(
                    2,
                    attribute.getDataType()
            );

            ps.setNString(
                    3,
                    normalizeUnit(attribute.getUnit())
            );

            ps.setBoolean(
                    4,
                    attribute.isActive()
            );

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot insert attribute",
                    ex
            );
            return 0;
        }
    }

    public int update(Attribute attribute) {

        if (!isValidAttribute(attribute)
                || attribute.getAttributeId() <= 0) {
            return 0;
        }

        if (isNameExists(
                attribute.getAttributeName(),
                attribute.getAttributeId())) {
            return 0;
        }

        String sql
                = "UPDATE ATTRIBUTE "
                + "SET attribute_name = ?, "
                + "data_type = ?, "
                + "unit = ? "
                + "WHERE attribute_id = ? "
                + "AND ("
                + "data_type = ? "
                + "OR NOT EXISTS ("
                + "SELECT 1 "
                + "FROM CATEGORY_ATTRIBUTE ca "
                + "WHERE ca.attribute_id = ATTRIBUTE.attribute_id"
                + ") "
                + "AND NOT EXISTS ("
                + "SELECT 1 "
                + "FROM PRODUCT_SPECIFICATION ps "
                + "WHERE ps.attribute_id = ATTRIBUTE.attribute_id"
                + ") "
                + "AND NOT EXISTS ("
                + "SELECT 1 "
                + "FROM SKU_ATTRIBUTE_VALUE sav "
                + "WHERE sav.attribute_id = ATTRIBUTE.attribute_id"
                + ")"
                + ")";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(
                    1,
                    attribute.getAttributeName().trim()
            );

            ps.setString(
                    2,
                    attribute.getDataType()
            );

            ps.setNString(
                    3,
                    normalizeUnit(attribute.getUnit())
            );

            ps.setInt(
                    4,
                    attribute.getAttributeId()
            );

            ps.setString(
                    5,
                    attribute.getDataType()
            );

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot update attribute",
                    ex
            );
            return 0;
        }
    }

    public boolean isAttributeInUse(int attributeId) {

        if (attributeId <= 0) {
            return false;
        }

        String sql
                = "SELECT CASE WHEN "
                + "EXISTS ("
                + "SELECT 1 FROM CATEGORY_ATTRIBUTE "
                + "WHERE attribute_id = ?"
                + ") "
                + "OR EXISTS ("
                + "SELECT 1 FROM PRODUCT_SPECIFICATION "
                + "WHERE attribute_id = ?"
                + ") "
                + "OR EXISTS ("
                + "SELECT 1 FROM SKU_ATTRIBUTE_VALUE "
                + "WHERE attribute_id = ?"
                + ") "
                + "THEN 1 ELSE 0 END AS is_used";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, attributeId);
            ps.setInt(2, attributeId);
            ps.setInt(3, attributeId);

            try (ResultSet rs = ps.executeQuery()) {

                return rs.next()
                        && rs.getBoolean("is_used");
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot check attribute usage",
                    ex
            );
            throw new RuntimeException(
                    "Cannot check attribute usage", ex
            );
        }
    }

    public int delete(int attributeId) {

        return setAttributeActive(attributeId, false);
    }

    public int setAttributeActive(
            int attributeId,
            boolean active) {

        if (attributeId <= 0) {
            return 0;
        }

        String sql
                = "UPDATE ATTRIBUTE "
                + "SET is_active = ? "
                + "WHERE attribute_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setBoolean(1, active);
            ps.setInt(2, attributeId);

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot change attribute status",
                    ex
            );
            return 0;
        }
    }

    public int countAttributes() {

        String sql = "SELECT COUNT(*) FROM ATTRIBUTE";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            return rs.next()
                    ? rs.getInt(1)
                    : 0;

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot count attributes",
                    ex
            );
            throw new RuntimeException(
                    "Cannot count attributes", ex
            );
        }
    }

    private boolean isValidAttribute(Attribute attribute) {

        if (attribute == null
                || attribute.getAttributeName() == null
                || attribute.getDataType() == null) {
            return false;
        }

        String name = attribute.getAttributeName().trim();

        if (name.isEmpty() || name.length() > 100) {
            return false;
        }

        String dataType = attribute.getDataType();

        if (!"TEXT".equals(dataType)
                && !"NUMBER".equals(dataType)
                && !"BOOLEAN".equals(dataType)) {
            return false;
        }

        String unit = normalizeUnit(attribute.getUnit());

        return unit == null || unit.length() <= 30;
    }

    private String normalizeUnit(String unit) {

        if (unit == null || unit.trim().isEmpty()) {
            return null;
        }

        return unit.trim();
    }
}
