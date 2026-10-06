package dao;

import db.DBContext;
import model.ProductReview;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class ProductReviewDAO extends DBContext {

    // =====================================================
    // GET SKU ID BY ORDER ITEM
    // =====================================================
    public int getSkuIdByOrderItemId(int orderItemId) {

        String sql = "SELECT sku_id "
                + "FROM ORDER_ITEM "
                + "WHERE order_item_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, orderItemId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("sku_id");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return -1;
    }

    // =====================================================
    // CHECK CAN REVIEW
    // =====================================================
    public boolean canReview(int userId, int orderItemId, int skuId) {

        String sql = "SELECT oi.order_item_id "
                + "FROM ORDER_ITEM oi "
                + "JOIN [ORDER] o ON oi.order_id = o.order_id "
                + "WHERE oi.order_item_id = ? "
                + "AND oi.sku_id = ? "
                + "AND o.user_id = ? "
                + "AND EXISTS ( "
                + "    SELECT 1 "
                + "    FROM ORDER_STATUS_HISTORY osh "
                + "    WHERE osh.order_id = o.order_id "
                + "    AND osh.status = 'Delivered' "
                + ") "
                + "AND NOT EXISTS ( "
                + "    SELECT 1 "
                + "    FROM PRODUCT_REVIEWS pr "
                + "    WHERE pr.order_item_id = oi.order_item_id "
                + ")";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, orderItemId);
            ps.setInt(2, skuId);
            ps.setInt(3, userId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    // =====================================================
    // CHECK ALREADY REVIEWED
    // =====================================================
    public boolean alreadyReviewed(int orderItemId) {

        String sql = "SELECT review_id "
                + "FROM PRODUCT_REVIEWS "
                + "WHERE order_item_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, orderItemId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    // =====================================================
    // INSERT REVIEW
    // =====================================================
    public int insertReview(ProductReview review) {

        String sql = "INSERT INTO PRODUCT_REVIEWS "
                + "(user_id, order_item_id, sku_id, rating, comment, created_at) "
                + "VALUES (?, ?, ?, ?, ?, GETDATE())";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, review.getUserId());
            ps.setInt(2, review.getOrderItemId());
            ps.setInt(3, review.getSkuId());
            ps.setInt(4, review.getRating());
            ps.setString(5, review.getComment());

            int rows = ps.executeUpdate();

            if (rows > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
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
    // INSERT REVIEW IMAGE
    // =====================================================
    public boolean insertReviewImage(int reviewId, String imageUrl) {

        String sql = "INSERT INTO REVIEW_IMAGES (review_id, image_url) VALUES (?, ?)";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, reviewId);
            ps.setString(2, imageUrl);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    // =====================================================
    // GET REVIEW BY ID + USER
    // =====================================================
    public ProductReview getReviewByIdAndUserId(int reviewId, int userId) {

        String sql = "SELECT review_id, user_id, order_item_id, sku_id, "
                + "rating, comment, created_at "
                + "FROM PRODUCT_REVIEWS "
                + "WHERE review_id = ? "
                + "AND user_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, reviewId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ProductReview review = mapReview(rs);
                    review.setImages(getReviewImages(reviewId));
                    return review;
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    // =====================================================
    // GET REVIEW IMAGES
    // =====================================================
    public List<String> getReviewImages(int reviewId) {

        List<String> images = new ArrayList<>();

        String sql = "SELECT image_url "
                + "FROM REVIEW_IMAGES "
                + "WHERE review_id = ? "
                + "ORDER BY image_id ASC";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, reviewId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    images.add(rs.getString("image_url"));
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return images;
    }

    // =====================================================
    // UPDATE REVIEW
    // =====================================================
    public boolean updateReview(ProductReview review) {

        String sql = "UPDATE PRODUCT_REVIEWS "
                + "SET rating = ?, comment = ? "
                + "WHERE review_id = ? "
                + "AND user_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, review.getRating());
            ps.setString(2, review.getComment());
            ps.setInt(3, review.getReviewId());
            ps.setInt(4, review.getUserId());

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    // =====================================================
    // DELETE REVIEW
    // =====================================================
    public boolean deleteReview(int reviewId, int userId) {

        String deleteImagesSql = "DELETE FROM REVIEW_IMAGES WHERE review_id = ?";
        String deleteReviewSql = "DELETE FROM PRODUCT_REVIEWS WHERE review_id = ? AND user_id = ?";

        Connection conn = null;

        try {
            conn = getConnection();
            conn.setAutoCommit(false);

            try (PreparedStatement psImages = conn.prepareStatement(deleteImagesSql)) {
                psImages.setInt(1, reviewId);
                psImages.executeUpdate();
            }

            int rows;
            try (PreparedStatement psReview = conn.prepareStatement(deleteReviewSql)) {
                psReview.setInt(1, reviewId);
                psReview.setInt(2, userId);

                rows = psReview.executeUpdate();
            }

            if (rows > 0) {
                conn.commit();
                return true;
            }

            conn.rollback();

        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackException) {
                    rollbackException.printStackTrace();
                }
            }
            e.printStackTrace();

        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException closeException) {
                    closeException.printStackTrace();
                }
            }
        }

        return false;
    }

    // =====================================================
    // GET REVIEWS BY SKU
    // =====================================================
    public List<ProductReview> getReviewsBySkuId(int skuId) {

        List<ProductReview> reviews = new ArrayList<>();

        String sql = "SELECT review_id, user_id, order_item_id, sku_id, "
                + "rating, comment, created_at "
                + "FROM PRODUCT_REVIEWS "
                + "WHERE sku_id = ? "
                + "ORDER BY created_at DESC";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductReview review = mapReview(rs);
                    review.setImages(getReviewImages(review.getReviewId()));
                    reviews.add(review);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return reviews;
    }

    // =====================================================
    // GET AVERAGE RATING
    // =====================================================
    public double getAverageRating(int skuId) {

        String sql = "SELECT AVG(CAST(rating AS FLOAT)) AS average_rating "
                + "FROM PRODUCT_REVIEWS "
                + "WHERE sku_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getDouble("average_rating");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    // =====================================================
    // COUNT REVIEWS
    // =====================================================
    public int countReviewsBySkuId(int skuId) {

        String sql = "SELECT COUNT(*) AS total "
                + "FROM PRODUCT_REVIEWS "
                + "WHERE sku_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    // =====================================================
    // MAP RESULTSET -> PRODUCT REVIEW
    // =====================================================
    private ProductReview mapReview(ResultSet rs) throws SQLException {

        ProductReview review = new ProductReview();

        review.setReviewId(rs.getInt("review_id"));
        review.setUserId(rs.getInt("user_id"));
        review.setOrderItemId(rs.getInt("order_item_id"));
        review.setSkuId(rs.getInt("sku_id"));
        review.setRating(rs.getInt("rating"));
        review.setComment(rs.getString("comment"));
        review.setCreatedAt(rs.getTimestamp("created_at"));

        return review;
    }
}