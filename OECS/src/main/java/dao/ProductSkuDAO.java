package dao;

import db.DBContext;
import model.ProductSku;
import model.SkuAttributeValue;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import java.util.logging.Level;
import java.util.logging.Logger;

public class ProductSkuDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(ProductSkuDAO.class.getName());

    private static final String SKU_SELECT
            = "SELECT "
            + "s.sku_id, "
            + "s.product_id, "
            + "s.sku_code, "
            + "s.price, "
            + "s.original_price, "
            + "s.stock_quantity, "
            + "s.created_at, "
            + "s.is_active, "
            + "s.variant_key, "
            + "sav.attribute_id, "
            + "sav.text_value, "
            + "sav.numeric_value, "
            + "sav.boolean_value, "
            + "a.attribute_name, "
            + "a.data_type, "
            + "a.unit "
            + "FROM PRODUCT_SKU s "
            + "LEFT JOIN SKU_ATTRIBUTE_VALUE sav "
            + "ON sav.sku_id = s.sku_id "
            + "LEFT JOIN ATTRIBUTE a "
            + "ON a.attribute_id = sav.attribute_id ";

    private ProductSku mapSku(ResultSet rs)
            throws SQLException {

        BigDecimal originalPrice
                = rs.getBigDecimal("original_price");

        return new ProductSku(
                rs.getInt("sku_id"),
                rs.getInt("product_id"),
                rs.getString("sku_code"),
                rs.getDouble("price"),
                rs.getInt("stock_quantity"),
                rs.getTimestamp("created_at"),
                originalPrice == null
                        ? null
                        : originalPrice.doubleValue(),
                rs.getBoolean("is_active"),
                rs.getBytes("variant_key")
        );
    }

    private SkuAttributeValue mapAttributeValue(
            ResultSet rs) throws SQLException {

        Boolean booleanValue = null;

        Object rawBoolean
                = rs.getObject("boolean_value");

        if (rawBoolean != null) {
            booleanValue
                    = rs.getBoolean("boolean_value");
        }

        return new SkuAttributeValue(
                rs.getInt("sku_id"),
                rs.getInt("attribute_id"),
                rs.getString("text_value"),
                rs.getBigDecimal("numeric_value"),
                booleanValue,
                rs.getString("attribute_name"),
                rs.getString("data_type"),
                rs.getString("unit")
        );
    }

    private List<ProductSku> mapSkuList(ResultSet rs)
            throws SQLException {

        Map<Integer, ProductSku> skuMap
                = new LinkedHashMap<>();

        while (rs.next()) {

            int skuId = rs.getInt("sku_id");

            ProductSku sku = skuMap.get(skuId);

            if (sku == null) {
                sku = mapSku(rs);
                skuMap.put(skuId, sku);
            }

            Object attributeId
                    = rs.getObject("attribute_id");

            if (attributeId != null) {
                sku.getAttributeValues().add(
                        mapAttributeValue(rs)
                );
            }
        }

        return new ArrayList<>(skuMap.values());
    }

    public List<ProductSku> getByProductId(int productId) {

        String sql = SKU_SELECT
                + "WHERE s.product_id = ? "
                + "ORDER BY s.sku_id DESC, "
                + "sav.attribute_id ASC";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {
                return mapSkuList(rs);
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy SKU theo Product ID!",
                    ex
            );
        }

        return new ArrayList<>();
    }

    public ProductSku getBySkuId(int skuId) {

        String sql = SKU_SELECT
                + "WHERE s.sku_id = ? "
                + "ORDER BY sav.attribute_id ASC";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            try (ResultSet rs = ps.executeQuery()) {

                List<ProductSku> list = mapSkuList(rs);

                if (!list.isEmpty()) {
                    return list.get(0);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy SKU theo ID!",
                    ex
            );
        }

        return null;
    }

    public List<ProductSku> getActiveByProductId(
            int productId) {

        String sql = SKU_SELECT
                + "WHERE s.product_id = ? "
                + "AND s.is_active = 1 "
                + "ORDER BY s.sku_id DESC, "
                + "sav.attribute_id ASC";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {
                return mapSkuList(rs);
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy SKU đang hoạt động!",
                    ex
            );
        }

        return new ArrayList<>();
    }

    public int insert(ProductSku sku) {

        String sql
                = "INSERT INTO PRODUCT_SKU "
                + "(product_id, sku_code, price, "
                + "stock_quantity, original_price, is_active) "
                + "VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            bindSkuInsert(ps, sku);

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi thêm Product SKU!",
                    ex
            );

            return 0;
        }
    }

    public int update(ProductSku sku) {

        String sql
                = "UPDATE PRODUCT_SKU SET "
                + "sku_code = ?, "
                + "price = ?, "
                + "stock_quantity = ?, "
                + "original_price = ?, "
                + "is_active = ? "
                + "WHERE sku_id = ? "
                + "AND product_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            bindSkuUpdate(ps, sku);

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi cập nhật Product SKU!",
                    ex
            );

            return 0;
        }
    }

    public int delete(int skuId) {

        return setSkuActive(skuId, false);
    }

    public int setSkuActive(int skuId, boolean active) {

        String sql
                = "UPDATE PRODUCT_SKU "
                + "SET is_active = ? "
                + "WHERE sku_id = ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setBoolean(1, active);
            ps.setInt(2, skuId);

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi cập nhật trạng thái SKU!",
                    ex
            );
        }

        return 0;
    }

    public boolean checkSkuCodeExists(String skuCode) {

        String sql
                = "SELECT 1 FROM PRODUCT_SKU "
                + "WHERE sku_code = ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setString(1, skuCode);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi kiểm tra trùng SKU code!",
                    ex
            );
        }

        return false;
    }

    public boolean checkSkuCodeExistsForUpdate(
            String skuCode,
            int excludeSkuId) {

        String sql
                = "SELECT 1 FROM PRODUCT_SKU "
                + "WHERE sku_code = ? "
                + "AND sku_id <> ?";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setString(1, skuCode);
            ps.setInt(2, excludeSkuId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi kiểm tra SKU code khi Update!",
                    ex
            );
        }

        return false;
    }

    public List<SkuAttributeValue> getAttributeValuesBySkuId(
            int skuId) {

        List<SkuAttributeValue> list
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "sav.sku_id, "
                + "sav.attribute_id, "
                + "sav.text_value, "
                + "sav.numeric_value, "
                + "sav.boolean_value, "
                + "a.attribute_name, "
                + "a.data_type, "
                + "a.unit "
                + "FROM SKU_ATTRIBUTE_VALUE sav "
                + "JOIN ATTRIBUTE a "
                + "ON a.attribute_id = sav.attribute_id "
                + "WHERE sav.sku_id = ? "
                + "ORDER BY sav.attribute_id";

        try (Connection conn = this.getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    list.add(mapAttributeValue(rs));
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi lấy thuộc tính SKU!",
                    ex
            );
        }

        return list;
    }

    public int insertWithAttributes(
            ProductSku sku,
            List<SkuAttributeValue> attributeValues) {

        if (sku == null || attributeValues == null) {
            return 0;
        }

        String sql
                = "INSERT INTO PRODUCT_SKU "
                + "(product_id, sku_code, price, "
                + "stock_quantity, original_price, is_active) "
                + "VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = this.getConnection()) {

            boolean oldAutoCommit
                    = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                int newSkuId = 0;

                try (PreparedStatement ps
                        = conn.prepareStatement(
                                sql,
                                Statement.RETURN_GENERATED_KEYS
                        )) {

                            bindSkuInsert(ps, sku);

                            if (ps.executeUpdate() != 1) {
                                throw new SQLException(
                                        "Không thể tạo SKU mới."
                                );
                            }

                            try (ResultSet rs = ps.getGeneratedKeys()) {

                                if (rs.next()) {
                                    newSkuId = rs.getInt(1);
                                }
                            }
                        }

                        if (newSkuId <= 0) {
                            throw new SQLException(
                                    "Không lấy được ID của SKU mới."
                            );
                        }

                        replaceSkuAttributes(
                                conn,
                                newSkuId,
                                attributeValues
                        );

                        refreshVariantKey(conn, newSkuId);

                        conn.commit();

                        sku.setSkuId(newSkuId);

                        return newSkuId;

            } catch (SQLException
                    | IllegalArgumentException ex) {

                rollbackQuietly(conn, ex);

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi thêm SKU kèm biến thể!",
                        ex
                );

                return 0;

            } finally {
                restoreAutoCommit(conn, oldAutoCommit);
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi kết nối khi thêm SKU!",
                    ex
            );
        }

        return 0;
    }

    public int updateWithAttributes(
            ProductSku sku,
            List<SkuAttributeValue> attributeValues) {

        if (sku == null
                || sku.getSkuId() <= 0
                || attributeValues == null) {
            return 0;
        }

        String sql
                = "UPDATE PRODUCT_SKU SET "
                + "sku_code = ?, "
                + "price = ?, "
                + "stock_quantity = ?, "
                + "original_price = ?, "
                + "is_active = ? "
                + "WHERE sku_id = ? "
                + "AND product_id = ?";

        try (Connection conn = this.getConnection()) {

            boolean oldAutoCommit
                    = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                int affectedRows;

                try (PreparedStatement ps
                        = conn.prepareStatement(sql)) {

                    bindSkuUpdate(ps, sku);

                    affectedRows = ps.executeUpdate();
                }

                if (affectedRows != 1) {
                    conn.rollback();
                    return 0;
                }

                replaceSkuAttributes(
                        conn,
                        sku.getSkuId(),
                        attributeValues
                );

                refreshVariantKey(
                        conn,
                        sku.getSkuId()
                );

                conn.commit();

                return 1;

            } catch (SQLException
                    | IllegalArgumentException ex) {

                rollbackQuietly(conn, ex);

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi cập nhật SKU kèm biến thể!",
                        ex
                );

                return 0;

            } finally {
                restoreAutoCommit(conn, oldAutoCommit);
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi kết nối khi cập nhật SKU!",
                    ex
            );
        }

        return 0;
    }

    private void bindSkuInsert(
            PreparedStatement ps,
            ProductSku sku) throws SQLException {

        if (sku == null) {
            throw new IllegalArgumentException(
                    "SKU không được null."
            );
        }

        validateSku(sku);

        ps.setInt(1, sku.getProductId());
        ps.setString(2, sku.getSkuCode().trim());
        ps.setDouble(3, sku.getPrice());
        ps.setInt(4, sku.getStockQuantity());

        bindOriginalPrice(ps, 5, sku.getOriginalPrice());

        ps.setBoolean(6, sku.isActive());
    }

    private void bindSkuUpdate(
            PreparedStatement ps,
            ProductSku sku) throws SQLException {

        if (sku == null) {
            throw new IllegalArgumentException(
                    "SKU không được null."
            );
        }

        validateSku(sku);

        ps.setString(1, sku.getSkuCode().trim());
        ps.setDouble(2, sku.getPrice());
        ps.setInt(3, sku.getStockQuantity());

        bindOriginalPrice(ps, 4, sku.getOriginalPrice());

        ps.setBoolean(5, sku.isActive());
        ps.setInt(6, sku.getSkuId());
        ps.setInt(7, sku.getProductId());
    }

    private void bindOriginalPrice(
            PreparedStatement ps,
            int parameterIndex,
            Double originalPrice) throws SQLException {

        if (originalPrice == null) {

            ps.setNull(
                    parameterIndex,
                    Types.DECIMAL
            );

        } else {

            ps.setDouble(
                    parameterIndex,
                    originalPrice
            );
        }
    }

    private void validateSku(ProductSku sku) {

        if (sku.getProductId() <= 0) {
            throw new IllegalArgumentException(
                    "Product ID không hợp lệ."
            );
        }

        if (sku.getSkuCode() == null
                || sku.getSkuCode().trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "SKU code không được trống."
            );
        }

        if (sku.getSkuCode().trim().length() > 100) {
            throw new IllegalArgumentException(
                    "SKU code vượt quá 100 ký tự."
            );
        }

        if (!Double.isFinite(sku.getPrice())
                || sku.getPrice() < 0) {
            throw new IllegalArgumentException(
                    "Giá bán không hợp lệ."
            );
        }

        if (sku.getOriginalPrice() != null
                && (!Double.isFinite(sku.getOriginalPrice())
                || sku.getOriginalPrice() < 0)) {
            throw new IllegalArgumentException(
                    "Giá niêm yết không hợp lệ."
            );
        }

        if (sku.getStockQuantity() < 0) {
            throw new IllegalArgumentException(
                    "Số lượng tồn kho không được âm."
            );
        }
    }

    private void replaceSkuAttributes(
            Connection conn,
            int skuId,
            List<SkuAttributeValue> values)
            throws SQLException {

        validateAttributeValues(values);

        String sqlDelete
                = "DELETE FROM SKU_ATTRIBUTE_VALUE "
                + "WHERE sku_id = ?";

        try (PreparedStatement ps
                = conn.prepareStatement(sqlDelete)) {

            ps.setInt(1, skuId);
            ps.executeUpdate();
        }

        if (values.isEmpty()) {
            return;
        }

        String sqlInsert
                = "INSERT INTO SKU_ATTRIBUTE_VALUE "
                + "(sku_id, attribute_id, "
                + "text_value, numeric_value, boolean_value) "
                + "VALUES (?, ?, ?, ?, ?)";

        try (PreparedStatement ps
                = conn.prepareStatement(sqlInsert)) {

            for (SkuAttributeValue value : values) {

                ps.setInt(1, skuId);
                ps.setInt(2, value.getAttributeId());

                // TEXT
                if (value.getTextValue() != null) {

                    ps.setNString(
                            3,
                            value.getTextValue().trim()
                    );

                } else {

                    ps.setNull(
                            3,
                            Types.NVARCHAR
                    );
                }

                // NUMBER
                if (value.getNumericValue() != null) {

                    ps.setBigDecimal(
                            4,
                            value.getNumericValue()
                    );

                } else {

                    ps.setNull(
                            4,
                            Types.DECIMAL
                    );
                }

                // BOOLEAN
                if (value.getBooleanValue() != null) {

                    ps.setBoolean(
                            5,
                            value.getBooleanValue()
                    );

                } else {

                    ps.setNull(
                            5,
                            Types.BIT
                    );
                }

                ps.addBatch();
            }

            ps.executeBatch();
        }
    }

    private void validateAttributeValues(
            List<SkuAttributeValue> values) {

        if (values == null) {
            throw new IllegalArgumentException(
                    "Danh sách thuộc tính không được null."
            );
        }

        Set<Integer> attributeIds = new HashSet<>();

        for (SkuAttributeValue value : values) {

            if (value == null) {
                throw new IllegalArgumentException(
                        "Thuộc tính SKU không được null."
                );
            }

            if (value.getAttributeId() <= 0) {
                throw new IllegalArgumentException(
                        "Attribute ID không hợp lệ."
                );
            }

            if (!attributeIds.add(
                    value.getAttributeId())) {

                throw new IllegalArgumentException(
                        "Một thuộc tính bị lặp trong SKU."
                );
            }

            int count = 0;

            if (value.getTextValue() != null) {

                if (value.getTextValue()
                        .trim().isEmpty()) {

                    throw new IllegalArgumentException(
                            "Giá trị TEXT không được trống."
                    );
                }

                if (value.getTextValue().length() > 255) {

                    throw new IllegalArgumentException(
                            "Giá trị TEXT vượt quá 255 ký tự."
                    );
                }

                count++;
            }

            if (value.getNumericValue() != null) {
                count++;
            }

            if (value.getBooleanValue() != null) {
                count++;
            }

            if (count != 1) {

                throw new IllegalArgumentException(
                        "Mỗi thuộc tính SKU phải có "
                        + "đúng một kiểu giá trị."
                );
            }
        }
    }

    private void refreshVariantKey(
            Connection conn,
            int skuId) throws SQLException {

        SkuVariantKeyHelper.refresh(conn, skuId);
    }

    private void rollbackQuietly(
            Connection conn,
            Exception originalException) {

        try {
            conn.rollback();

        } catch (SQLException rollbackEx) {

            originalException.addSuppressed(
                    rollbackEx
            );

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi rollback transaction SKU!",
                    rollbackEx
            );
        }
    }

    private void restoreAutoCommit(
            Connection conn,
            boolean oldAutoCommit) {

        try {
            conn.setAutoCommit(oldAutoCommit);

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.WARNING,
                    "Không khôi phục được autoCommit!",
                    ex
            );
        }
    }
}
