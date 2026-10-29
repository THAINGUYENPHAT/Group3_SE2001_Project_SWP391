package dao;

import db.DBContext;
import model.Banner;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class BannerDAO extends DBContext {

    private static final Logger LOGGER =
            Logger.getLogger(BannerDAO.class.getName());

    public List<Banner> getAll() {
        List<Banner> banners = new ArrayList<>();

        String sql = "SELECT banner_id, image_url, alt_text, target_url, "
                + "is_active, display_order, created_at "
                + "FROM BANNER "
                + "ORDER BY display_order, banner_id";

        try (Connection conn = this.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Banner banner = new Banner();
                banner.setBannerId(rs.getInt("banner_id"));
                banner.setImageUrl(rs.getString("image_url"));
                banner.setAltText(rs.getString("alt_text"));
                banner.setTargetUrl(rs.getString("target_url"));
                banner.setActive(rs.getBoolean("is_active"));
                banner.setDisplayOrder(rs.getInt("display_order"));
                banner.setCreatedAt(rs.getTimestamp("created_at"));

                banners.add(banner);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot get banners", e);
        }

        return banners;
    }

    public List<Banner> getActive() {
        List<Banner> banners = new ArrayList<>();

        String sql = "SELECT banner_id, image_url, alt_text, target_url, "
                + "is_active, display_order, created_at "
                + "FROM BANNER "
                + "WHERE is_active = 1 "
                + "ORDER BY display_order, banner_id";

        try (Connection conn = this.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Banner banner = new Banner();
                banner.setBannerId(rs.getInt("banner_id"));
                banner.setImageUrl(rs.getString("image_url"));
                banner.setAltText(rs.getString("alt_text"));
                banner.setTargetUrl(rs.getString("target_url"));
                banner.setActive(rs.getBoolean("is_active"));
                banner.setDisplayOrder(rs.getInt("display_order"));
                banner.setCreatedAt(rs.getTimestamp("created_at"));

                banners.add(banner);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot get active banners", e);
        }

        return banners;
    }

    public boolean insert(Banner banner) {
        String sql = "INSERT INTO BANNER "
                + "(image_url, alt_text, target_url, is_active, display_order) "
                + "VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = this.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, banner.getImageUrl());
            ps.setString(2, banner.getAltText());
            ps.setString(3, banner.getTargetUrl());
            ps.setBoolean(4, banner.isActive());
            ps.setInt(5, banner.getDisplayOrder());

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot insert banner", e);
            return false;
        }
    }

    public boolean update(Banner banner) {
        String sql = "UPDATE BANNER "
                + "SET image_url = ?, alt_text = ?, target_url = ?, "
                + "is_active = ?, display_order = ? "
                + "WHERE banner_id = ?";

        try (Connection conn = this.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, banner.getImageUrl());
            ps.setString(2, banner.getAltText());
            ps.setString(3, banner.getTargetUrl());
            ps.setBoolean(4, banner.isActive());
            ps.setInt(5, banner.getDisplayOrder());
            ps.setInt(6, banner.getBannerId());

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot update banner", e);
            return false;
        }
    }

    public boolean updateActive(int bannerId, boolean active) {
        String sql = "UPDATE BANNER SET is_active = ? WHERE banner_id = ?";

        try (Connection conn = this.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setBoolean(1, active);
            ps.setInt(2, bannerId);

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot change banner status", e);
            return false;
        }
    }

    public boolean delete(int bannerId) {
        String sql = "DELETE FROM BANNER WHERE banner_id = ?";

        try (Connection conn = this.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, bannerId);

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Cannot delete banner", e);
            return false;
        }
    }
}