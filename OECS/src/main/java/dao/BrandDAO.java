package dao;

import db.DBContext;
import model.Brand;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class BrandDAO extends DBContext {

    private static final Logger LOGGER = Logger.getLogger(BrandDAO.class.getName());

    // =====================================================
    // 1. LẤY DANH SÁCH TẤT CẢ CÁC THƯƠNG HIỆU
    // =====================================================
    public List<Brand> getList() {
        List<Brand> list = new ArrayList<>();
        String sql = "SELECT brand_id, brand_name, logo_url FROM BRAND";

        try (Connection conn = getConnection();
             PreparedStatement statement = conn.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {
                Brand brand = new Brand(
                        rs.getInt("brand_id"),
                        rs.getString("brand_name"),
                        rs.getString("logo_url")
                );
                list.add(brand);
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy danh sách Brand!", ex);
        }
        return list;
    }

    // =====================================================
    // 2. THÊM THƯƠNG HIỆU MỚI
    // =====================================================
    public int insert(Brand brand) {
        String sql = "INSERT INTO BRAND (brand_name, logo_url) VALUES (?, ?)";

        try (Connection conn = getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setString(1, brand.getBrandName());
            statement.setString(2, brand.getLogoUrl());

            return statement.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi thêm Brand!", ex);
            return 0;
        }
    }

    // =====================================================
    // 3. CẬP NHẬT THÔNG TIN THƯƠNG HIỆU
    // =====================================================
    public int edit(Brand brand) {
        String sql = "UPDATE BRAND SET brand_name = ?, logo_url = ? WHERE brand_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setString(1, brand.getBrandName());
            statement.setString(2, brand.getLogoUrl());
            statement.setInt(3, brand.getBrandId());

            return statement.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi cập nhật Brand!", ex);
            return 0;
        }
    }

    // =====================================================
    // 4. XÓA THƯƠNG HIỆU
    // =====================================================
    public int delete(Brand brand) {
        String sql = "DELETE FROM BRAND WHERE brand_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, brand.getBrandId());

            return statement.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi xóa Brand!", ex);
            return 0;
        }
    }

    // =====================================================
    // 5. LẤY THƯƠNG HIỆU THEO ID
    // =====================================================
    public Brand getById(int id) {
        String sql = "SELECT brand_id, brand_name, logo_url FROM BRAND WHERE brand_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, id);

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return new Brand(
                            rs.getInt("brand_id"),
                            rs.getString("brand_name"),
                            rs.getString("logo_url")
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy Brand theo ID!", ex);
        }
        return null;
    }
}