package dao;

import db.DBContext;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Base64;
import model.CategoryAttribute;

public class CategoryRoleConfigDAO extends DBContext {

    public static final String SPECIFICATION = "SPECIFICATION";
    public static final String VARIANT = "VARIANT";

    public static final class ConfigInput {

        public int categoryId;
        public int attributeId; 
        public String role;
        public String attributeName;
        public String dataType;
        public String unit;
        public String groupName;
        public boolean required;
        public boolean filterable;
        public int displayOrder;
        public String expectedSignature;
    }

    private static final class Mapping {

        String type;
        String group;
        boolean required;
        boolean filterable;
        int order;
    }

    private interface Transaction<T> {

        T work(Connection connection) throws SQLException;
    }

    private <T> T inTransaction(Transaction<T> task) throws SQLException {
        try (Connection conn = getConnection()) {
            int oldIsolation = conn.getTransactionIsolation();
            boolean oldAutoCommit = conn.getAutoCommit();
            try {
                conn.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
                conn.setAutoCommit(false);
                T result = task.work(conn);
                conn.commit();
                return result;
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
                } catch (SQLException ignored) {
                }
            }
        }
    }

    public static boolean validRole(String role) {
        return SPECIFICATION.equals(role) || VARIANT.equals(role);
    }

    public static boolean includesRole(String type, String role) {
        return "BOTH".equals(type) || role != null && role.equals(type);
    }

    public static String signature(CategoryAttribute config) {
        if (config == null) {
            return "NONE";
        }
        return signature(config.getAttributeType(), config.getGroupName(),
                config.isRequired(), config.isFilterable(), config.getDisplayOrder());
    }

    private static String signature(Mapping config) {
        if (config == null) {
            return "NONE";
        }
        return signature(config.type, config.group, config.required,
                config.filterable, config.order);
    }

    private static String signature(String type, String group, boolean required,
            boolean filterable, int order) {
        String source = type.length() + ":" + type + ":"
                + group.length() + ":" + group + ":"
                + required + ":" + filterable + ":" + order;
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(source.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(digest);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("Không hỗ trợ SHA-256", ex);
        }
    }

    public int createDefinitionOnly(final String name, final String dataType,
            final String unit) throws SQLException {
        validateDefinition(name, dataType, unit);
        return inTransaction(conn -> {
            checkUniqueName(conn, name.trim(), 0);
            String sql = "INSERT INTO ATTRIBUTE "
                    + "(attribute_name, data_type, unit, is_active) "
                    + "OUTPUT INSERTED.attribute_id VALUES (?, ?, ?, 1)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setNString(1, name.trim());
                ps.setString(2, dataType);
                ps.setNString(3, normalizeUnit(unit));
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new SQLException("Không lấy được ID thuộc tính vừa tạo.");
                    }
                    return rs.getInt(1);
                }
            }
        });
    }

  
    public int save(final ConfigInput input) throws SQLException {
        if (input == null || input.categoryId <= 0 || input.attributeId < 0
                || !validRole(input.role)) {
            throw new IllegalArgumentException("Danh mục, thuộc tính hoặc vai trò không hợp lệ.");
        }
        if (input.groupName == null || input.groupName.trim().isEmpty()
                || input.groupName.trim().length() > 100 || input.displayOrder < 0) {
            throw new IllegalArgumentException("Nhóm tối đa 100 ký tự; thứ tự phải >= 0.");
        }
        if (input.attributeId == 0) {
            validateDefinition(input.attributeName, input.dataType, input.unit);
        }
        return inTransaction(conn -> {
            checkChildCategory(conn, input.categoryId);
            int attributeId = input.attributeId;
            if (attributeId == 0) {
                checkUniqueName(conn, input.attributeName.trim(), 0);
                String sql = "INSERT INTO ATTRIBUTE "
                        + "(attribute_name, data_type, unit, is_active) "
                        + "OUTPUT INSERTED.attribute_id VALUES (?, ?, ?, 1)";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setNString(1, input.attributeName.trim());
                    ps.setString(2, input.dataType);
                    ps.setNString(3, normalizeUnit(input.unit));
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException("Không lấy được ID thuộc tính mới.");
                        }
                        attributeId = rs.getInt(1);
                    }
                }
            } else {
                assertActiveAttribute(conn, attributeId);
            }

            Mapping previous = readMapping(conn, input.categoryId, attributeId);
            if (input.attributeId > 0) {
                checkSignature(previous, input.expectedSignature);
            }
            if (previous == null) {
               
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO CATEGORY_ATTRIBUTE "
                        + "(category_id, attribute_id, group_name, attribute_type, "
                        + "is_required, is_filterable, display_order) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?)")) {
                    ps.setInt(1, input.categoryId);
                    ps.setInt(2, attributeId);
                    ps.setNString(3, input.groupName.trim());
                    ps.setString(4, input.role);
                    ps.setBoolean(5, input.required);
                    ps.setBoolean(6, input.filterable);
                    ps.setInt(7, input.displayOrder);
                    ps.executeUpdate();
                }
            } else if (!includesRole(previous.type, input.role)) {
                
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE CATEGORY_ATTRIBUTE SET attribute_type = 'BOTH' "
                        + "WHERE category_id = ? AND attribute_id = ?")) {
                    ps.setInt(1, input.categoryId);
                    ps.setInt(2, attributeId);
                    ps.executeUpdate();
                }
            } else if ("BOTH".equals(previous.type)) {
                throw new IllegalArgumentException(
                        "Thuộc tính đang dùng chung SKU và thông số. "
                        + "Không thể sửa nhóm/thứ tự/bắt buộc vì đây là cấu hình chung của DB6.");
            } else {
               
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE CATEGORY_ATTRIBUTE SET group_name=?, is_required=?, "
                        + "is_filterable=?, display_order=? "
                        + "WHERE category_id=? AND attribute_id=?")) {
                    ps.setNString(1, input.groupName.trim());
                    ps.setBoolean(2, input.required);
                    ps.setBoolean(3, input.filterable);
                    ps.setInt(4, input.displayOrder);
                    ps.setInt(5, input.categoryId);
                    ps.setInt(6, attributeId);
                    ps.executeUpdate();
                }
            }
            return attributeId;
        });
    }

   
    public void removeRole(final int categoryId, final int attributeId,
            final String role, final String expectedSignature) throws SQLException {
        if (categoryId <= 0 || attributeId <= 0 || !validRole(role)) {
            throw new IllegalArgumentException("Dữ liệu gỡ thuộc tính không hợp lệ.");
        }
        inTransaction(conn -> {
            checkChildCategory(conn, categoryId);
            Mapping old = readMapping(conn, categoryId, attributeId);
            checkSignature(old, expectedSignature);
            if (old == null || !includesRole(old.type, role)) {
                throw new IllegalArgumentException("Thuộc tính chưa được gán cho vai trò này.");
            }
            if (hasValueForRole(conn, categoryId, attributeId, role)) {
                throw new IllegalArgumentException(
                        "Không thể bỏ gán vì sản phẩm/SKU trong danh mục đã có giá trị. "
                        + "Cần xử lý dữ liệu liên quan trước.");
            }
            if ("BOTH".equals(old.type)) {
                String remaining = SPECIFICATION.equals(role) ? VARIANT : SPECIFICATION;
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE CATEGORY_ATTRIBUTE SET attribute_type = ? "
                        + "WHERE category_id=? AND attribute_id=?")) {
                    ps.setString(1, remaining);
                    ps.setInt(2, categoryId);
                    ps.setInt(3, attributeId);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM CATEGORY_ATTRIBUTE WHERE category_id=? AND attribute_id=?")) {
                    ps.setInt(1, categoryId);
                    ps.setInt(2, attributeId);
                    ps.executeUpdate();
                }
            }
            return null;
        });
    }

  
    public void updateDefinition(final int categoryId, final int attributeId,
            final String role, final String name, final String dataType,
            final String unit) throws SQLException {
        validateDefinition(name, dataType, unit);
        if (categoryId <= 0 || attributeId <= 0 || !validRole(role)) {
            throw new IllegalArgumentException("Thuộc tính không hợp lệ.");
        }
        inTransaction(conn -> {
            checkChildCategory(conn, categoryId);
            Mapping mapping = readMapping(conn, categoryId, attributeId);
            if (mapping == null || !includesRole(mapping.type, role)) {
                throw new IllegalArgumentException("Thuộc tính chưa thuộc danh mục/vai trò này.");
            }
            String opposite = SPECIFICATION.equals(role) ? VARIANT : SPECIFICATION;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT TOP 1 1 FROM CATEGORY_ATTRIBUTE WITH (HOLDLOCK) "
                    + "WHERE attribute_id=? AND attribute_type IN ('BOTH', ?)")) {
                ps.setInt(1, attributeId);
                ps.setString(2, opposite);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        throw new IllegalArgumentException(
                                "Thuộc tính có dùng chung với phía "
                                + (SPECIFICATION.equals(role) ? "SKU" : "thông số")
                                + ". Chỉ được chỉnh cấu hình theo danh mục, "
                                + "không đổi tên/kiểu/đơn vị dùng chung.");
                    }
                }
            }
            if (hasAnyOtherRoleValue(conn, attributeId, role)) {
                throw new IllegalArgumentException(
                        "Thuộc tính còn dữ liệu ở phía khác, không thể sửa định nghĩa chung.");
            }
            String oldType;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT data_type FROM ATTRIBUTE WITH (UPDLOCK, HOLDLOCK) "
                    + "WHERE attribute_id=? AND is_active=1")) {
                ps.setInt(1, attributeId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Thuộc tính đã ngừng dùng.");
                    }
                    oldType = rs.getString(1);
                }
            }
            if (!oldType.equals(dataType) && hasAnyValue(conn, attributeId)) {
                throw new IllegalArgumentException(
                        "Đã có giá trị Product/SKU. Không đổi được kiểu dữ liệu; "
                        + "vẫn có thể đổi tên hoặc đơn vị nếu không dùng chung vai trò.");
            }
            checkUniqueName(conn, name.trim(), attributeId);
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE ATTRIBUTE SET attribute_name=?, data_type=?, unit=? WHERE attribute_id=?")) {
                ps.setNString(1, name.trim());
                ps.setString(2, dataType);
                ps.setNString(3, normalizeUnit(unit));
                ps.setInt(4, attributeId);
                ps.executeUpdate();
            }
            return null;
        });
    }


    public int hardDeleteAttribute(final int attributeId,
            final String confirmedAttributeName) throws SQLException {
        if (attributeId <= 0 || confirmedAttributeName == null
                || confirmedAttributeName.trim().isEmpty()) {
            throw new IllegalArgumentException("Mã hoặc tên xác nhận xóa không hợp lệ.");
        }
        return inTransaction(conn -> {
            String actualName;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT attribute_name FROM ATTRIBUTE WITH (UPDLOCK, HOLDLOCK) "
                    + "WHERE attribute_id=?")) {
                ps.setInt(1, attributeId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException(
                                "Thuộc tính không tồn tại hoặc đã bị xóa.");
                    }
                    actualName = rs.getString(1);
                }
            }
            if (!actualName.equals(confirmedAttributeName)) {
                throw new IllegalArgumentException(
                        "Tên thuộc tính đã thay đổi hoặc xác nhận chưa chính xác. "
                        + "Tải lại trang và thử lại.");
            }

            if (hasAny(conn,
                    "SELECT TOP 1 1 FROM PRODUCT_SPECIFICATION WITH (UPDLOCK, HOLDLOCK) "
                    + "WHERE attribute_id=?", attributeId)) {
                throw new IllegalArgumentException(
                        "Không thể xóa cứng: thuộc tính đã có giá trị trong "
                        + "PRODUCT_SPECIFICATION. Hãy xử lý dữ liệu sản phẩm trước.");
            }
            if (hasAny(conn,
                    "SELECT TOP 1 1 FROM SKU_ATTRIBUTE_VALUE WITH (UPDLOCK, HOLDLOCK) "
                    + "WHERE attribute_id=?", attributeId)) {
                throw new IllegalArgumentException(
                        "Không thể xóa cứng: thuộc tính đã có giá trị trong "
                        + "SKU_ATTRIBUTE_VALUE. Không được xóa thuộc tính SKU đang dùng.");
            }

            int linksRemoved;
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM CATEGORY_ATTRIBUTE WHERE attribute_id=?")) {
                ps.setInt(1, attributeId);
                linksRemoved = ps.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM ATTRIBUTE WHERE attribute_id=?")) {
                ps.setInt(1, attributeId);
                if (ps.executeUpdate() != 1) {
                    throw new SQLException("Không xóa được bản ghi ATTRIBUTE.");
                }
            }
            return linksRemoved;
        });
    }

    private static void validateDefinition(String name, String type, String unit) {
        if (name == null || name.trim().isEmpty() || name.trim().length() > 100
                || !("TEXT".equals(type) || "NUMBER".equals(type)
                || "BOOLEAN".equals(type))
                || (unit != null && unit.trim().length() > 30)) {
            throw new IllegalArgumentException(
                    "Tên tối đa 100 ký tự; kiểu TEXT/NUMBER/BOOLEAN; đơn vị tối đa 30 ký tự.");
        }
    }

    private static String normalizeUnit(String unit) {
        return unit == null || unit.trim().isEmpty() ? null : unit.trim();
    }

    private void checkSignature(Mapping actual, String expected) {
        if (expected == null || !expected.equals(signature(actual))) {
            throw new IllegalArgumentException(
                    "Cấu hình đã thay đổi ở phiên khác. Tải lại trang và thử lại.");
        }
    }

    private void checkChildCategory(Connection conn, int id) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT parent_id FROM CATEGORY WITH (UPDLOCK, HOLDLOCK) WHERE category_id=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next() || rs.getObject(1) == null) {
                    throw new IllegalArgumentException("Chỉ cấu hình cho danh mục con tồn tại.");
                }
            }
        }
    }

    private void assertActiveAttribute(Connection conn, int id) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM ATTRIBUTE WITH (HOLDLOCK) WHERE attribute_id=? AND is_active=1")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Thuộc tính không hoạt động hoặc không tồn tại.");
                }
            }
        }
    }

    private Mapping readMapping(Connection conn, int categoryId, int attributeId)
            throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT attribute_type, group_name, is_required, is_filterable, "
                + "display_order FROM CATEGORY_ATTRIBUTE WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE category_id=? AND attribute_id=?")) {
            ps.setInt(1, categoryId);
            ps.setInt(2, attributeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Mapping mapping = new Mapping();
                mapping.type = rs.getString(1);
                mapping.group = rs.getString(2);
                mapping.required = rs.getBoolean(3);
                mapping.filterable = rs.getBoolean(4);
                mapping.order = rs.getInt(5);
                return mapping;
            }
        }
    }

    private void checkUniqueName(Connection conn, String name, int excludedId)
            throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT TOP 1 attribute_id FROM ATTRIBUTE WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE LOWER(LTRIM(RTRIM(attribute_name))) = "
                + "LOWER(LTRIM(RTRIM(?))) AND attribute_id<>?")) {
            ps.setNString(1, name);
            ps.setInt(2, excludedId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    throw new IllegalArgumentException(
                            "Thuộc tính đã có trong ATTRIBUTE. Chọn từ danh sách để gán, không tạo trùng.");
                }
            }
        }
    }

    private boolean hasValueForRole(Connection conn, int categoryId, int attrId,
            String role) throws SQLException {
        String sql;
        if (VARIANT.equals(role)) {
            sql = "SELECT TOP 1 1 FROM PRODUCT p "
                    + "JOIN PRODUCT_SKU s ON s.product_id=p.product_id "
                    + "JOIN SKU_ATTRIBUTE_VALUE sav WITH (HOLDLOCK) ON sav.sku_id=s.sku_id "
                    + "WHERE p.category_id=? AND sav.attribute_id=?";
        } else {
            sql = "SELECT TOP 1 1 FROM PRODUCT p "
                    + "JOIN PRODUCT_SPECIFICATION ps WITH (HOLDLOCK) ON ps.product_id=p.product_id "
                    + "WHERE p.category_id=? AND ps.attribute_id=?";
        }
        return exists(conn, sql, categoryId, attrId);
    }

    private boolean hasAnyOtherRoleValue(Connection conn, int attrId, String currentRole)
            throws SQLException {
        String table = SPECIFICATION.equals(currentRole)
                ? "SKU_ATTRIBUTE_VALUE" : "PRODUCT_SPECIFICATION";
        return hasAny(conn, "SELECT TOP 1 1 FROM " + table
                + " WITH (HOLDLOCK) WHERE attribute_id=?", attrId);
    }

    private boolean hasAnyValue(Connection conn, int attrId) throws SQLException {
        return hasAny(conn, "SELECT TOP 1 1 FROM PRODUCT_SPECIFICATION WITH (HOLDLOCK) "
                + "WHERE attribute_id=?", attrId)
                || hasAny(conn, "SELECT TOP 1 1 FROM SKU_ATTRIBUTE_VALUE WITH (HOLDLOCK) "
                        + "WHERE attribute_id=?", attrId);
    }

    private boolean hasAny(Connection conn, String sql, int attributeId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, attributeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private boolean exists(Connection conn, String sql, int categoryId, int attributeId)
            throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            ps.setInt(2, attributeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }
}
