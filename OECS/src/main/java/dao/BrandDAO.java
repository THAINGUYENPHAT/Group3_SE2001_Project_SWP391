package dao;

import db.DBContext;
import model.Brand;

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

public class BrandDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(BrandDAO.class.getName());

    private static final String BRAND_COLUMNS
            = "brand_id, brand_name, logo_url, is_active ";

    private Brand mapBrand(ResultSet rs)
            throws SQLException {

        return new Brand(
                rs.getInt("brand_id"),
                rs.getString("brand_name"),
                rs.getString("logo_url"),
                rs.getBoolean("is_active")
        );
    }

    public List<Brand> getList() {

        List<Brand> list = new ArrayList<>();

        String sql
                = "SELECT " + BRAND_COLUMNS
                + "FROM BRAND "
                + "ORDER BY brand_id";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapBrand(rs));
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot load brand list",
                    ex
            );
        }

        return list;
    }

    public List<Brand> getActiveBrands() {

        List<Brand> list = new ArrayList<>();

        String sql
                = "SELECT " + BRAND_COLUMNS
                + "FROM BRAND "
                + "WHERE is_active = 1 "
                + "ORDER BY brand_name, brand_id";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapBrand(rs));
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot load active brands",
                    ex
            );
        }

        return list;
    }

    public Brand getById(int id) {

        String sql
                = "SELECT " + BRAND_COLUMNS
                + "FROM BRAND "
                + "WHERE brand_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return mapBrand(rs);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot find brand by ID",
                    ex
            );
        }

        return null;
    }

    public boolean isNameExists(
            String name,
            int excludeId) {

        if (name == null || name.trim().isEmpty()) {
            return false;
        }

        String sql
                = "SELECT 1 "
                + "FROM BRAND "
                + "WHERE LOWER(LTRIM(RTRIM(brand_name))) "
                + "= LOWER(LTRIM(RTRIM(?))) "
                + "AND brand_id <> ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, name.trim());
            ps.setInt(2, excludeId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot check duplicate brand name",
                    ex
            );

            throw new RuntimeException(
                    "Cannot check brand name",
                    ex
            );
        }
    }

    public int countProductsByBrandId(int brandId) {

        String sql
                = "SELECT COUNT(*) "
                + "FROM PRODUCT "
                + "WHERE brand_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, brandId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot count products by brand",
                    ex
            );

            throw new RuntimeException(
                    "Cannot count products",
                    ex
            );
        }
    }

    public Map<Integer, Integer> getProductCounts(
            List<Brand> brandList) {

        Map<Integer, Integer> productCounts
                = new HashMap<>();

        if (brandList == null || brandList.isEmpty()) {
            return productCounts;
        }

        for (Brand brand : brandList) {
            productCounts.put(brand.getBrandId(), 0);
        }

        StringBuilder sql = new StringBuilder(
                "SELECT brand_id, COUNT(*) AS total "
                + "FROM PRODUCT "
                + "WHERE brand_id IN ("
        );

        appendPlaceholders(sql, brandList.size());

        sql.append(") GROUP BY brand_id");

        try (Connection conn = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < brandList.size(); i++) {

                ps.setInt(
                        i + 1,
                        brandList.get(i).getBrandId()
                );
            }

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    productCounts.put(
                            rs.getInt("brand_id"),
                            rs.getInt("total")
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot count products by brands",
                    ex
            );

            throw new RuntimeException(
                    "Cannot count products by brands",
                    ex
            );
        }

        return productCounts;
    }

    public int insert(Brand brand) {

        if (!isValidBrand(brand)) {
            return 0;
        }

        String sql
                = "INSERT INTO BRAND "
                + "(brand_name, logo_url, is_active) "
                + "VALUES (?, ?, ?)";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(
                    1,
                    brand.getBrandName().trim()
            );

            ps.setString(
                    2,
                    brand.getLogoUrl()
            );

            ps.setBoolean(
                    3,
                    brand.isActive()
            );

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot insert brand",
                    ex
            );

            throw new RuntimeException(
                    "Cannot insert brand",
                    ex
            );
        }
    }

    public int edit(Brand brand) {

        if (!isValidBrand(brand)
                || brand.getBrandId() <= 0) {
            return 0;
        }

        String sql
                = "UPDATE BRAND "
                + "SET brand_name = ?, "
                + "logo_url = ? "
                + "WHERE brand_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(
                    1,
                    brand.getBrandName().trim()
            );

            ps.setString(
                    2,
                    brand.getLogoUrl()
            );

            ps.setInt(
                    3,
                    brand.getBrandId()
            );

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot update brand",
                    ex
            );

            throw new RuntimeException(
                    "Cannot update brand",
                    ex
            );
        }
    }

    public int delete(Brand brand) {

        if (brand == null || brand.getBrandId() <= 0) {
            return 0;
        }

        return setBrandActive(
                brand.getBrandId(),
                false
        );
    }

    public int setBrandActive(
            int brandId,
            boolean active) {

        if (brandId <= 0) {
            return 0;
        }

        String sql
                = "UPDATE BRAND "
                + "SET is_active = ? "
                + "WHERE brand_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setBoolean(1, active);
            ps.setInt(2, brandId);

            return ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot change brand status",
                    ex
            );

            return 0;
        }
    }

    public List<Brand> searchByName(String keyword) {

        List<Brand> list = new ArrayList<>();

        String sql
                = "SELECT " + BRAND_COLUMNS
                + "FROM BRAND "
                + "WHERE LOWER(brand_name) LIKE LOWER(?) "
                + "ORDER BY brand_id";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, searchPattern(keyword));

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    list.add(mapBrand(rs));
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot search brands",
                    ex
            );

            throw new RuntimeException(
                    "Cannot search brands",
                    ex
            );
        }

        return list;
    }

    public List<Brand> getListByPage(
            int page,
            int pageSize) {

        List<Brand> list = new ArrayList<>();

        validatePage(page, pageSize);

        String sql
                = "SELECT " + BRAND_COLUMNS
                + "FROM BRAND "
                + "ORDER BY brand_id "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, calculateOffset(page, pageSize));
            ps.setInt(2, pageSize);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    list.add(mapBrand(rs));
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot load brands by page",
                    ex
            );

            throw new RuntimeException(
                    "Cannot load brands by page",
                    ex
            );
        }

        return list;
    }

    public List<Brand> searchByNameAndPage(
            String keyword,
            int page,
            int pageSize) {

        List<Brand> list = new ArrayList<>();

        validatePage(page, pageSize);

        String sql
                = "SELECT " + BRAND_COLUMNS
                + "FROM BRAND "
                + "WHERE LOWER(brand_name) LIKE LOWER(?) "
                + "ORDER BY brand_id "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, searchPattern(keyword));
            ps.setInt(2, calculateOffset(page, pageSize));
            ps.setInt(3, pageSize);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    list.add(mapBrand(rs));
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot search brands by page",
                    ex
            );

            throw new RuntimeException(
                    "Cannot search brands by page",
                    ex
            );
        }

        return list;
    }

    public int countSearchResults(String keyword) {

        String sql
                = "SELECT COUNT(*) "
                + "FROM BRAND "
                + "WHERE LOWER(brand_name) LIKE LOWER(?)";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, searchPattern(keyword));

            try (ResultSet rs = ps.executeQuery()) {

                return rs.next()
                        ? rs.getInt(1)
                        : 0;
            }

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot count searched brands",
                    ex
            );

            throw new RuntimeException(
                    "Cannot count searched brands",
                    ex
            );
        }
    }

    public int countBrands() {

        String sql
                = "SELECT COUNT(*) FROM BRAND";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            return rs.next()
                    ? rs.getInt(1)
                    : 0;

        } catch (SQLException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Cannot count brands",
                    ex
            );

            throw new RuntimeException(
                    "Cannot count brands",
                    ex
            );
        }
    }

    private boolean isValidBrand(Brand brand) {

        if (brand == null
                || brand.getBrandName() == null) {
            return false;
        }

        String name = brand.getBrandName().trim();

        if (name.isEmpty() || name.length() > 100) {
            return false;
        }

        return brand.getLogoUrl() == null
                || brand.getLogoUrl().length() <= 2048;
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

        String value
                = keyword == null
                        ? ""
                        : keyword.trim();

        return "%" + value + "%";
    }

    private void validatePage(
            int page,
            int pageSize) {

        if (page <= 0 || pageSize <= 0) {
            throw new IllegalArgumentException(
                    "Page và pageSize phải lớn hơn 0."
            );
        }
    }

    private int calculateOffset(
            int page,
            int pageSize) {

        long offset
                = ((long) page - 1) * pageSize;

        if (offset > Integer.MAX_VALUE) {
            throw new IllegalArgumentException(
                    "Giá trị phân trang quá lớn."
            );
        }

        return (int) offset;
    }
}
