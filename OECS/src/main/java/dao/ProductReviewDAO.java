package dao;

import db.DBContext;
import model.ProductReview;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Level;
import java.util.logging.Logger;

public class ProductReviewDAO extends DBContext {

    private static final Logger LOGGER = Logger.getLogger(ProductReviewDAO.class.getName());

    public boolean canReview(int userId, int orderItemId, int skuId) {
        String sql = "SELECT oi.order_item_id "
                + "FROM ORDER_ITEM oi "
                + "JOIN [ORDER] o ON oi.order_id = o.order_id "
                + "WHERE oi.order_item_id = ? "
                + "AND oi.sku_id = ? "
                + "AND o.user_id = ? "
                + "AND EXISTS ( "
                + "    SELECT 1 FROM ORDER_STATUS_HISTORY osh "
                + "    WHERE osh.order_id = o.order_id AND osh.status = 'Delivered' "
                + ") "
                + "AND NOT EXISTS ( "
                + "    SELECT 1 FROM PRODUCT_REVIEWS pr "
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
            LOGGER.log(Level.SEVERE, "Lỗi kiểm tra quyền đánh giá sản phẩm!", e);
        }

        return false;
    }

    public boolean alreadyReviewed(int orderItemId) {
        String sql = "SELECT review_id FROM PRODUCT_REVIEWS WHERE order_item_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, orderItemId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi kiểm tra trạng thái đánh giá!", e);
        }

        return false;
    }

    public int insertReview(ProductReview review) {
        String sql = "INSERT INTO PRODUCT_REVIEWS (user_id, order_item_id, sku_id, rating, comment, created_at) "
                + "VALUES (?, ?, ?, ?, ?, GETDATE())";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, review.getUserId());
            ps.setInt(2, review.getOrderItemId());
            ps.setInt(3, review.getSkuId());
            ps.setInt(4, review.getRating());
            ps.setString(5, review.getComment());

            int affectedRows = ps.executeUpdate();

            if (affectedRows > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi thêm đánh giá sản phẩm!", e);
        }

        return -1;
    }

    public boolean insertReviewImage(int reviewId, String imageUrl) {
        String sql = "INSERT INTO REVIEW_IMAGES (review_id, image_url) VALUES (?, ?)";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, reviewId);
            ps.setString(2, imageUrl);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi lưu hình ảnh đánh giá!", e);
        }

        return false;
    }

    public int getSkuIdByOrderItemId(int orderItemId) {
        String sql = "SELECT sku_id FROM ORDER_ITEM WHERE order_item_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, orderItemId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("sku_id");
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy SKU ID từ Order Item ID!", e);
        }

        return -1;
    }
}