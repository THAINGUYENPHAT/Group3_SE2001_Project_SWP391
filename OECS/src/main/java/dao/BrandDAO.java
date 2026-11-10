
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

    public List<Brand> getList() {
        List<Brand> list = new ArrayList<>();

        String sql = "SELECT brand_id, brand_name, logo_url "
                + "FROM BRAND "
                + "ORDER BY brand_id";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Brand brand = new Brand(
                        rs.getInt("brand_id"),
                        rs.getString("brand_name"),
                        rs.getString("logo_url")
                );

                list.add(brand);
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot load brand list", e);
        }

        return list;
    }

    public Brand getById(int id) {
        String sql = "SELECT brand_id, brand_name, logo_url "
                + "FROM BRAND "
                + "WHERE brand_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Brand(
                            rs.getInt("brand_id"),
                            rs.getString("brand_name"),
                            rs.getString("logo_url")
                    );
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot find brand by ID", e);
        }

        return null;
    }

    public boolean isNameExists(String name, int excludeId) {
        String sql = "SELECT COUNT(*) "
                + "FROM BRAND "
                + "WHERE LOWER(LTRIM(RTRIM(brand_name))) "
                + "= LOWER(LTRIM(RTRIM(?))) "
                + "AND brand_id <> ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, name.trim());
            ps.setInt(2, excludeId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot check duplicate brand name", e);
            throw new RuntimeException("Cannot check brand name", e);
        }

        return false;
    }

    public int countProductsByBrandId(int brandId) {
        String sql = "SELECT COUNT(*) "
                + "FROM PRODUCT "
                + "WHERE brand_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, brandId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot count products by brand", e);
            throw new RuntimeException("Cannot count products", e);
        }

        return 0;
    }

    public Map<Integer, Integer> getProductCounts(List<Brand> brandList) {
        Map<Integer, Integer> productCounts = new HashMap<>();

        if (brandList == null || brandList.isEmpty()) {
            return productCounts;
        }

        StringBuilder sql = new StringBuilder(
                "SELECT brand_id, COUNT(*) AS total "
                + "FROM PRODUCT "
                + "WHERE brand_id IN ("
        );

        for (int i = 0; i < brandList.size(); i++) {
            if (i > 0) {
                sql.append(", ");
            }
            sql.append("?");
        }

        sql.append(") GROUP BY brand_id");

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < brandList.size(); i++) {
                ps.setInt(i + 1, brandList.get(i).getBrandId());
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    productCounts.put(
                            rs.getInt("brand_id"),
                            rs.getInt("total")
                    );
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot count products by brands", e);
            throw new RuntimeException("Cannot count products by brands", e);
        }

        for (Brand brand : brandList) {
            productCounts.putIfAbsent(brand.getBrandId(), 0);
        }

        return productCounts;
    }

    public int insert(Brand brand) {
        String sql = "INSERT INTO BRAND (brand_name, logo_url) "
                + "VALUES (?, ?)";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, brand.getBrandName());
            ps.setString(2, brand.getLogoUrl());

            return ps.executeUpdate();

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot insert brand", e);
            throw new RuntimeException("Cannot insert brand", e);
        }
    }

    public int edit(Brand brand) {
        String sql = "UPDATE BRAND "
                + "SET brand_name = ?, logo_url = ? "
                + "WHERE brand_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, brand.getBrandName());
            ps.setString(2, brand.getLogoUrl());
            ps.setInt(3, brand.getBrandId());

            return ps.executeUpdate();

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot update brand", e);
            throw new RuntimeException("Cannot update brand", e);
        }
    }

    public int delete(Brand brand) {
        String sql = "DELETE FROM BRAND WHERE brand_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, brand.getBrandId());

            return ps.executeUpdate();

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot delete brand", e);
            throw new RuntimeException("Cannot delete brand", e);
        }
    }

    public List<Brand> searchByName(String keyword) {
        List<Brand> list = new ArrayList<>();

        String sql = "SELECT brand_id, brand_name, logo_url "
                + "FROM BRAND "
                + "WHERE LOWER(brand_name) LIKE LOWER(?) "
                + "ORDER BY brand_id";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, "%" + keyword.trim() + "%");

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Brand brand = new Brand(
                            rs.getInt("brand_id"),
                            rs.getString("brand_name"),
                            rs.getString("logo_url")
                    );

                    list.add(brand);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot search brands", e);
            throw new RuntimeException("Cannot search brands", e);
        }

        return list;
    }

    public List<Brand> getListByPage(int page, int pageSize) {
        List<Brand> list = new ArrayList<>();

        String sql = "SELECT brand_id, brand_name, logo_url "
                + "FROM BRAND "
                + "ORDER BY brand_id "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, (page - 1) * pageSize);
            ps.setInt(2, pageSize);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new Brand(
                            rs.getInt("brand_id"),
                            rs.getString("brand_name"),
                            rs.getString("logo_url")
                    ));
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot load brands by page", e);
            throw new RuntimeException("Cannot load brands by page", e);
        }

        return list;
    }

    public List<Brand> searchByNameAndPage(
            String keyword, int page, int pageSize) {

        List<Brand> list = new ArrayList<>();

        String sql = "SELECT brand_id, brand_name, logo_url "
                + "FROM BRAND "
                + "WHERE LOWER(brand_name) LIKE LOWER(?) "
                + "ORDER BY brand_id "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, "%" + keyword.trim() + "%");
            ps.setInt(2, (page - 1) * pageSize);
            ps.setInt(3, pageSize);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new Brand(
                            rs.getInt("brand_id"),
                            rs.getString("brand_name"),
                            rs.getString("logo_url")
                    ));
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot search brands by page", e);
            throw new RuntimeException("Cannot search brands by page", e);
        }

        return list;
    }

    public int countSearchResults(String keyword) {
        String sql = "SELECT COUNT(*) "
                + "FROM BRAND "
                + "WHERE LOWER(brand_name) LIKE LOWER(?)";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setNString(1, "%" + keyword.trim() + "%");

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot count searched brands", e);
            throw new RuntimeException("Cannot count searched brands", e);
        }

        return 0;
    }

    public int countBrands() {
        String sql = "SELECT COUNT(*) FROM BRAND";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot count brands", e);
            throw new RuntimeException("Cannot count brands", e);
        }

        return 0;
    }
}
