package dao;

import db.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class StaffReviewDAO extends DBContext {

    public List<Map<String, Object>> getAllReviewsForStaff()
            throws SQLException {

        List<Map<String, Object>> reviews = new ArrayList<>();

        String sql = "SELECT pr.review_id, pr.user_id, "
                + "u.username AS reviewer_name, "
                + "pr.order_item_id, pr.sku_id, "
                + "ps.sku_code, p.product_name, "
                + "pr.rating, pr.comment, pr.created_at, "
                + "pr.is_hidden "
                + "FROM PRODUCT_REVIEWS pr "
                + "LEFT JOIN [USER] u ON pr.user_id = u.user_id "
                + "LEFT JOIN PRODUCT_SKU ps ON pr.sku_id = ps.sku_id "
                + "LEFT JOIN PRODUCT p ON ps.product_id = p.product_id "
                + "ORDER BY pr.created_at DESC";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> review = new HashMap<>();

                review.put("reviewId", rs.getInt("review_id"));
                review.put("userId", rs.getInt("user_id"));
                review.put("reviewerName", rs.getString("reviewer_name"));
                review.put("orderItemId", rs.getInt("order_item_id"));
                review.put("skuId", rs.getInt("sku_id"));
                review.put("skuCode", rs.getString("sku_code"));
                review.put("productName", rs.getString("product_name"));
                review.put("rating", rs.getInt("rating"));
                review.put("comment", rs.getString("comment"));
                review.put("createdAt", rs.getTimestamp("created_at"));
                review.put("isHidden", rs.getBoolean("is_hidden"));

                reviews.add(review);
            }
        }

        return reviews;
    }

    public boolean setReviewHidden(int reviewId, boolean hidden)
            throws SQLException {

        String sql = "UPDATE PRODUCT_REVIEWS "
                + "SET is_hidden = ? "
                + "WHERE review_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setBoolean(1, hidden);
            ps.setInt(2, reviewId);

            return ps.executeUpdate() > 0;
        }
    }
}