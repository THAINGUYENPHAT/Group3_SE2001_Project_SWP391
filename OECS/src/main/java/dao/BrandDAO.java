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

    // 1. Lấy danh sách tất cả các thương hiệu
    public List<Brand> getList() {
        List<Brand> list = new ArrayList<>();
        String sql = "SELECT brand_id, brand_name, logo_url FROM BRAND";

        try (Connection conn = this.getConnection();
             PreparedStatement statement = conn.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {
                int brandId = rs.getInt("brand_id");
                String brandName = rs.getString("brand_name");
                String logoUrl = rs.getString("logo_url");

                Brand brand = new Brand(brandId, brandName, logoUrl);
                list.add(brand);
            }

        } catch (SQLException ex) {
            Logger.getLogger(BrandDAO.class.getName()).log(Level.SEVERE, "Lỗi lấy danh sách Brand!", ex);
        }
        return list;
    }

    // 2. Thêm thương hiệu mới
    public int insert(Brand brand) {
        String sql = "INSERT INTO BRAND (brand_name, logo_url) VALUES (?, ?)";

        try (Connection conn = this.getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setString(1, brand.getBrandName());
            statement.setString(2, brand.getLogoUrl());

            return statement.executeUpdate();

        } catch (SQLException ex) {
            Logger.getLogger(BrandDAO.class.getName()).log(Level.SEVERE, "Lỗi thêm Brand!", ex);
            return 0;
        }
    }

    // 3. Cập nhật thông tin thương hiệu
    public int edit(Brand brand) {
        String sql = "UPDATE BRAND SET brand_name = ?, logo_url = ? WHERE brand_id = ?";

        try (Connection conn = this.getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setString(1, brand.getBrandName());
            statement.setString(2, brand.getLogoUrl());
            statement.setInt(3, brand.getBrandId());

            return statement.executeUpdate();

        } catch (SQLException ex) {
            Logger.getLogger(BrandDAO.class.getName()).log(Level.SEVERE, "Lỗi cập nhật Brand!", ex);
            return 0;
        }
    }

    // 4. Xóa thương hiệu
    public int delete(Brand brand) {
        String sql = "DELETE FROM BRAND WHERE brand_id = ?";

        try (Connection conn = this.getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setInt(1, brand.getBrandId());

            return statement.executeUpdate();

        } catch (SQLException ex) {
            Logger.getLogger(BrandDAO.class.getName()).log(Level.SEVERE, "Lỗi xóa Brand!", ex);
            return 0;
        }
    }

    // 5. Lấy thương hiệu theo ID
    public Brand getById(int id) {
        String sql = "SELECT brand_id, brand_name, logo_url FROM BRAND WHERE brand_id = ?";

        try (Connection conn = this.getConnection();
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
            Logger.getLogger(BrandDAO.class.getName()).log(Level.SEVERE, "Lỗi lấy Brand theo ID!", ex);
        }
        return null;
    }
}