
package dao;

import db.DBContext;
import model.ProductReview;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class ProductReviewDAO {

    public static final int SAVE_FAILED = -1;
    public static final int ALREADY_REVIEWED = -2;
    public static final int RATE_LIMIT_REACHED = -3;
    public static final int NOT_ELIGIBLE = -4;

    // Mỗi thao tác mở một kết nối riêng.
    private Connection getConnection() throws SQLException {
        Connection conn = new DBContext().getConnection();

        if (conn == null) {
            throw new SQLException("Cannot connect to OECS database");
        }

        return conn;
    }

    public int getSkuIdByOrderItemId(int orderItemId) {
        String sql = "SELECT sku_id FROM ORDER_ITEM "
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

    public boolean canReview(int userId, int orderItemId, int skuId) {
        String sql =
                "SELECT 1 "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.[ORDER] o ON oi.order_id = o.order_id "
                + "WHERE oi.order_item_id = ? "
                + "AND oi.sku_id = ? "
                + "AND o.user_id = ? "
                + "AND UPPER(LTRIM(RTRIM(o.order_status))) "
                + "IN ('COMPLETED', 'DELIVERED') "
                + "AND NOT EXISTS ( "
                + "SELECT 1 FROM dbo.PRODUCT_REVIEWS pr "
                + "WHERE pr.order_item_id = oi.order_item_id "
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
            java.util.logging.Logger
                    .getLogger(ProductReviewDAO.class.getName())
                    .log(
                            java.util.logging.Level.SEVERE,
                            "Lỗi kiểm tra quyền đánh giá", e);
        }

        return false;
    }

    public boolean alreadyReviewed(int orderItemId) {
        String sql = "SELECT review_id FROM PRODUCT_REVIEWS "
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

    // Kiểm tra điều kiện, chống trùng và giới hạn 10 review trong 10 phút.
    // Tất cả được xử lý cùng một transaction.
    public int insertReview(ProductReview review) {

        if (review == null
                || review.getUserId() <= 0
                || review.getOrderItemId() <= 0
                || review.getSkuId() <= 0
                || review.getRating() < 1
                || review.getRating() > 5
                || (review.getComment() != null
                    && review.getComment().length() > 2000)) {
            return NOT_ELIGIBLE;
        }

        String lockUserSql =
                "SELECT user_id FROM dbo.[USER] WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE user_id = ?";

        String eligibleSql =
                "SELECT 1 FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.[ORDER] o ON o.order_id = oi.order_id "
                + "WHERE oi.order_item_id = ? "
                + "AND oi.sku_id = ? "
                + "AND o.user_id = ? "
                + "AND UPPER(LTRIM(RTRIM(o.order_status))) "
                + "IN ('COMPLETED', 'DELIVERED')";

        String existingSql =
                "SELECT 1 FROM dbo.PRODUCT_REVIEWS "
                + "WHERE order_item_id = ?";

        String countSql =
                "SELECT COUNT(*) FROM dbo.PRODUCT_REVIEWS "
                + "WHERE user_id = ? "
                + "AND created_at >= DATEADD(MINUTE, -10, GETDATE())";

        String insertSql =
                "INSERT INTO dbo.PRODUCT_REVIEWS "
                + "(user_id, order_item_id, sku_id, rating, comment, created_at) "
                + "VALUES (?, ?, ?, ?, ?, GETDATE())";

        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);

            try {
                // Khóa user đến khi commit.
                try (PreparedStatement ps =
                        conn.prepareStatement(lockUserSql)) {

                    ps.setInt(1, review.getUserId());

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return NOT_ELIGIBLE;
                        }
                    }
                }

                // Đơn hàng phải thuộc khách và đã hoàn tất.
                try (PreparedStatement ps =
                        conn.prepareStatement(eligibleSql)) {

                    ps.setInt(1, review.getOrderItemId());
                    ps.setInt(2, review.getSkuId());
                    ps.setInt(3, review.getUserId());

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return NOT_ELIGIBLE;
                        }
                    }
                }

                // Review ẩn vẫn được tính là đã đánh giá.
                try (PreparedStatement ps =
                        conn.prepareStatement(existingSql)) {

                    ps.setInt(1, review.getOrderItemId());

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            conn.rollback();
                            return ALREADY_REVIEWED;
                        }
                    }
                }

                // Đếm lại số review gần đây ngay trước INSERT.
                try (PreparedStatement ps =
                        conn.prepareStatement(countSql)) {

                    ps.setInt(1, review.getUserId());

                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();

                        if (rs.getInt(1) >= 10) {
                            conn.rollback();
                            return RATE_LIMIT_REACHED;
                        }
                    }
                }

                try (PreparedStatement ps =
                        conn.prepareStatement(
                                insertSql,
                                Statement.RETURN_GENERATED_KEYS)) {

                    ps.setInt(1, review.getUserId());
                    ps.setInt(2, review.getOrderItemId());
                    ps.setInt(3, review.getSkuId());
                    ps.setInt(4, review.getRating());
                    ps.setString(5, review.getComment());

                    if (ps.executeUpdate() != 1) {
                        conn.rollback();
                        return SAVE_FAILED;
                    }

                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (!keys.next()) {
                            conn.rollback();
                            return SAVE_FAILED;
                        }

                        int reviewId = keys.getInt(1);
                        conn.commit();
                        return reviewId;
                    }
                }

            } catch (SQLException e) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;
            }

        } catch (SQLException e) {
            java.util.logging.Logger
                    .getLogger(ProductReviewDAO.class.getName())
                    .log(
                            java.util.logging.Level.SEVERE,
                            "Atomic review insert failed", e);

            return SAVE_FAILED;
        }
    }

    public boolean insertReviewImage(int reviewId, String imageUrl) {
        String sql =
                "INSERT INTO REVIEW_IMAGES (review_id, image_url) "
                + "VALUES (?, ?)";

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

    public ProductReview getReviewByIdAndUserId(
            int reviewId, int userId) {

        String sql =
                "SELECT review_id, user_id, order_item_id, sku_id, "
                + "rating, comment, created_at "
                + "FROM PRODUCT_REVIEWS "
                + "WHERE review_id = ? AND user_id = ?";

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

    public List<String> getReviewImages(int reviewId) {
        List<String> images = new ArrayList<>();

        String sql =
                "SELECT image_url FROM REVIEW_IMAGES "
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

    public boolean updateReview(ProductReview review) {
        String sql =
                "UPDATE PRODUCT_REVIEWS "
                + "SET rating = ?, comment = ? "
                + "WHERE review_id = ? AND user_id = ?";

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

    // Cập nhật rating, bình luận và ảnh trong cùng transaction.
    public boolean updateReviewWithImages(
            ProductReview review,
            List<String> removeImages,
            List<String> newImages) throws SQLException {

        if (review == null
                || review.getRating() < 1
                || review.getRating() > 5
                || (review.getComment() != null
                    && review.getComment().length() > 2000)) {
            throw new IllegalArgumentException(
                    "Dữ liệu đánh giá không hợp lệ.");
        }

        List<String> toRemove = removeImages == null
                ? new ArrayList<>() : removeImages;

        List<String> toAdd = newImages == null
                ? new ArrayList<>() : newImages;

        String lockSql =
                "SELECT review_id "
                + "FROM dbo.PRODUCT_REVIEWS WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE review_id = ? AND user_id = ?";

        String imageSql =
                "SELECT image_url "
                + "FROM dbo.REVIEW_IMAGES WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE review_id = ?";

        String updateSql =
                "UPDATE dbo.PRODUCT_REVIEWS "
                + "SET rating = ?, comment = ? "
                + "WHERE review_id = ? AND user_id = ?";

        String removeSql =
                "DELETE FROM dbo.REVIEW_IMAGES "
                + "WHERE review_id = ? AND image_url = ?";

        String addSql =
                "INSERT INTO dbo.REVIEW_IMAGES "
                + "(review_id, image_url) VALUES (?, ?)";

        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);

            try {
                // Khóa review để tránh hai request sửa ảnh cùng lúc.
                try (PreparedStatement ps =
                        conn.prepareStatement(lockSql)) {

                    ps.setInt(1, review.getReviewId());
                    ps.setInt(2, review.getUserId());

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return false;
                        }
                    }
                }

                Set<String> currentImages = new HashSet<>();

                try (PreparedStatement ps =
                        conn.prepareStatement(imageSql)) {

                    ps.setInt(1, review.getReviewId());

                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            currentImages.add(
                                    rs.getString("image_url"));
                        }
                    }
                }

                Set<String> removalSet = new HashSet<>(toRemove);

                if (removalSet.size() != toRemove.size()
                        || !currentImages.containsAll(removalSet)) {
                    throw new IllegalArgumentException(
                            "Ảnh cần xóa không hợp lệ.");
                }

                int finalCount =
                        currentImages.size()
                        - removalSet.size()
                        + toAdd.size();

                if (finalCount > 3) {
                    throw new IllegalArgumentException(
                            "Mỗi đánh giá chỉ có tối đa 3 ảnh.");
                }

                try (PreparedStatement ps =
                        conn.prepareStatement(updateSql)) {

                    ps.setInt(1, review.getRating());
                    ps.setString(2, review.getComment());
                    ps.setInt(3, review.getReviewId());
                    ps.setInt(4, review.getUserId());

                    if (ps.executeUpdate() != 1) {
                        conn.rollback();
                        return false;
                    }
                }

                try (PreparedStatement ps =
                        conn.prepareStatement(removeSql)) {

                    for (String url : removalSet) {
                        ps.setInt(1, review.getReviewId());
                        ps.setString(2, url);

                        if (ps.executeUpdate() != 1) {
                            throw new SQLException(
                                    "Không thể xóa ảnh đánh giá.");
                        }
                    }
                }

                try (PreparedStatement ps =
                        conn.prepareStatement(addSql)) {

                    for (String url : toAdd) {
                        ps.setInt(1, review.getReviewId());
                        ps.setString(2, url);

                        if (ps.executeUpdate() != 1) {
                            throw new SQLException(
                                    "Không thể thêm ảnh đánh giá.");
                        }
                    }
                }

                conn.commit();
                return true;

            } catch (SQLException | RuntimeException e) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;
            }
        }
    }

    public boolean deleteReview(int reviewId, int userId) {
        String lockSql =
                "SELECT review_id "
                + "FROM dbo.PRODUCT_REVIEWS WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE review_id = ? AND user_id = ?";

        String deleteImagesSql =
                "DELETE FROM dbo.REVIEW_IMAGES WHERE review_id = ?";

        String deleteReviewSql =
                "DELETE FROM dbo.PRODUCT_REVIEWS "
                + "WHERE review_id = ? AND user_id = ?";

        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);

            try {
                // Xác nhận quyền sở hữu trước khi xóa ảnh.
                try (PreparedStatement ps =
                        conn.prepareStatement(lockSql)) {

                    ps.setInt(1, reviewId);
                    ps.setInt(2, userId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return false;
                        }
                    }
                }

                try (PreparedStatement ps =
                        conn.prepareStatement(deleteImagesSql)) {

                    ps.setInt(1, reviewId);
                    ps.executeUpdate();
                }

                int deleted;

                try (PreparedStatement ps =
                        conn.prepareStatement(deleteReviewSql)) {

                    ps.setInt(1, reviewId);
                    ps.setInt(2, userId);

                    deleted = ps.executeUpdate();
                }

                if (deleted != 1) {
                    conn.rollback();
                    return false;
                }

                conn.commit();
                return true;

            } catch (SQLException | RuntimeException e) {
                conn.rollback();
                throw e;
            }

        } catch (SQLException e) {
            java.util.logging.Logger
                    .getLogger(ProductReviewDAO.class.getName())
                    .log(
                            java.util.logging.Level.SEVERE,
                            "Không thể xóa đánh giá", e);

            return false;
        }
    }

    public List<ProductReview> getReviewsBySkuId(int skuId) {
        List<ProductReview> reviews = new ArrayList<>();

        String sql =
                "SELECT review_id, user_id, order_item_id, sku_id, "
                + "rating, comment, created_at "
                + "FROM PRODUCT_REVIEWS "
                + "WHERE sku_id = ? AND is_hidden = 0 "
                + "ORDER BY created_at DESC";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductReview review = mapReview(rs);
                    review.setImages(
                            getReviewImages(review.getReviewId()));
                    reviews.add(review);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return reviews;
    }

    public List<ProductReview> getReviewsByProductId(int productId) {
        List<ProductReview> reviews = new ArrayList<>();

        String sql =
                "SELECT pr.review_id, pr.user_id, "
                + "pr.order_item_id, pr.sku_id, "
                + "pr.rating, pr.comment, pr.created_at "
                + "FROM dbo.PRODUCT_REVIEWS pr "
                + "JOIN dbo.PRODUCT_SKU ps ON pr.sku_id = ps.sku_id "
                + "WHERE ps.product_id = ? "
                + "AND pr.is_hidden = 0 "
                + "ORDER BY pr.created_at DESC, pr.review_id DESC";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    reviews.add(mapReview(rs));
                }
            }

        } catch (SQLException e) {
            throw new IllegalStateException(
                    "Lỗi tải đánh giá cho sản phẩm ID " + productId, e);
        }

        for (ProductReview review : reviews) {
            review.setImages(
                    getReviewImages(review.getReviewId()));
        }

        return reviews;
    }

    public double getAverageRating(int skuId) {
        String sql =
                "SELECT AVG(CAST(rating AS FLOAT)) AS average_rating "
                + "FROM PRODUCT_REVIEWS "
                + "WHERE sku_id = ? AND is_hidden = 0";

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

    public int countReviewsBySkuId(int skuId) {
        String sql =
                "SELECT COUNT(*) AS total "
                + "FROM PRODUCT_REVIEWS "
                + "WHERE sku_id = ? AND is_hidden = 0";

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

    public int getPurchaseCountByProductId(int productId) {
        String sql =
                "SELECT COUNT(DISTINCT oi.order_item_id) AS purchase_count "
                + "FROM dbo.ORDER_ITEM oi "
                + "JOIN dbo.PRODUCT_SKU ps ON oi.sku_id = ps.sku_id "
                + "JOIN dbo.[ORDER] o ON oi.order_id = o.order_id "
                + "WHERE ps.product_id = ? "
                + "AND UPPER(LTRIM(RTRIM(o.order_status))) "
                + "IN ('COMPLETED', 'DELIVERED')";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("purchase_count");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    private ProductReview mapReview(ResultSet rs)
            throws SQLException {

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

    public ProductReview getReviewByOrderItemIdAndUserId(
            int orderItemId, int userId) {

        String sql =
                "SELECT pr.review_id, pr.user_id, "
                + "pr.order_item_id, pr.sku_id, "
                + "pr.rating, pr.comment, pr.created_at "
                + "FROM dbo.PRODUCT_REVIEWS pr "
                + "JOIN dbo.ORDER_ITEM oi "
                + "ON oi.order_item_id = pr.order_item_id "
                + "JOIN dbo.[ORDER] o ON o.order_id = oi.order_id "
                + "WHERE pr.order_item_id = ? "
                + "AND pr.user_id = ? AND o.user_id = ?";

        ProductReview review = null;

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, orderItemId);
            ps.setInt(2, userId);
            ps.setInt(3, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    review = mapReview(rs);
                }
            }

        } catch (SQLException e) {
            throw new IllegalStateException(
                    "Không thể tải đánh giá sản phẩm", e);
        }

        if (review != null) {
            review.setImages(
                    getReviewImages(review.getReviewId()));
        }

        return review;
    }

    public int countRecentReviews(int userId) {
        String sql =
                "SELECT COUNT(*) AS total "
                + "FROM dbo.PRODUCT_REVIEWS "
                + "WHERE user_id = ? "
                + "AND created_at >= DATEADD(MINUTE, -10, GETDATE())";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }

        } catch (SQLException e) {
            throw new IllegalStateException(
                    "Không thể kiểm tra tần suất đánh giá", e);
        }

        return 0;
    }
}
