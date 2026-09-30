package model;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class ProductReview {

    private int reviewId;
    private int userId;
    private int orderItemId;
    private int skuId;

    private int rating;
    private String comment;

    private Timestamp createdAt;

    private List<String> images;

    public ProductReview() {
        images = new ArrayList<>();
    }

    public int getReviewId() {
        return reviewId;
    }

    public void setReviewId(int reviewId) {
        this.reviewId = reviewId;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public int getOrderItemId() {
        return orderItemId;
    }

    public void setOrderItemId(int orderItemId) {
        this.orderItemId = orderItemId;
    }

    public int getSkuId() {
        return skuId;
    }

    public void setSkuId(int skuId) {
        this.skuId = skuId;
    }

    public int getRating() {
        return rating;
    }

    public void setRating(int rating) {
        this.rating = rating;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(
            Timestamp createdAt) {

        this.createdAt = createdAt;
    }

    public List<String> getImages() {
        return images;
    }

    public void setImages(
            List<String> images) {

        this.images = images;
    }
}
