package dao;

import db.DBContext;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import model.ProductReview;

public class ProductReviewDAO
        extends DBContext {

    // =====================================================
    // CUSTOMER CÓ ĐƯỢC REVIEW KHÔNG
    // =====================================================
    public boolean canReview(
            int userId,
            int orderItemId,
            int skuId) {

        String sql
                = "SELECT oi.order_item_id "
                + "FROM ORDER_ITEM oi "
                + "JOIN [ORDER] o "
                + "ON oi.order_id = o.order_id "
                + "WHERE oi.order_item_id = ? "
                + "AND oi.sku_id = ? "
                + "AND o.user_id = ? "
                // Order phải có trạng thái Delivered
                + "AND EXISTS ( "
                + "    SELECT 1 "
                + "    FROM ORDER_STATUS_HISTORY osh "
                + "    WHERE osh.order_id = o.order_id "
                + "    AND osh.status = 'Delivered' "
                + ") "
                // order item chưa review
                + "AND NOT EXISTS ( "
                + "    SELECT 1 "
                + "    FROM PRODUCT_REVIEWS pr "
                + "    WHERE pr.order_item_id = oi.order_item_id "
                + ")";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    orderItemId
            );

            ps.setInt(
                    2,
                    skuId
            );

            ps.setInt(
                    3,
                    userId
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

                return rs.next();
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    // =====================================================
    // CHECK ĐÃ REVIEW CHƯA
    // =====================================================
    public boolean alreadyReviewed(
            int orderItemId) {

        String sql
                = "SELECT review_id "
                + "FROM PRODUCT_REVIEWS "
                + "WHERE order_item_id = ?";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    orderItemId
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

                return rs.next();
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    // =====================================================
    // INSERT REVIEW
    // return review_id
    // =====================================================
    public int insertReview(
            ProductReview review) {

        String sql
                = "INSERT INTO PRODUCT_REVIEWS "
                + "(user_id, order_item_id, sku_id, "
                + "rating, comment, created_at) "
                + "VALUES (?, ?, ?, ?, ?, GETDATE())";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(
                        sql,
                        Statement.RETURN_GENERATED_KEYS
                )) {

            ps.setInt(
                    1,
                    review.getUserId()
            );

            ps.setInt(
                    2,
                    review.getOrderItemId()
            );

            ps.setInt(
                    3,
                    review.getSkuId()
            );

            ps.setInt(
                    4,
                    review.getRating()
            );

            ps.setString(
                    5,
                    review.getComment()
            );

            int affectedRows
                    = ps.executeUpdate();

            if (affectedRows > 0) {

                try (
                        ResultSet rs
                        = ps.getGeneratedKeys()) {

                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return -1;
    }

    // =====================================================
    // INSERT IMAGE
    // =====================================================
    public boolean insertReviewImage(
            int reviewId,
            String imageUrl) {

        String sql
                = "INSERT INTO REVIEW_IMAGES "
                + "(review_id, image_url) "
                + "VALUES (?, ?)";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    reviewId
            );

            ps.setString(
                    2,
                    imageUrl
            );

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    // =====================================================
    // LẤY SKU CỦA ORDER ITEM
    // Dùng để không tin skuId customer gửi lên
    // =====================================================
    public int getSkuIdByOrderItemId(
            int orderItemId) {

        String sql
                = "SELECT sku_id "
                + "FROM ORDER_ITEM "
                + "WHERE order_item_id = ?";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    orderItemId
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt("sku_id");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return -1;
    }
}
