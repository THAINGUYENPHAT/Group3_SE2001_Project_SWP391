package model;

import java.sql.Timestamp;

public class ProductImage {

    private int imageId;
    private int productId;
    private Integer skuId;

    private String imageUrl;
    private boolean primary;
    private int displayOrder;
    private String altText;

    private Timestamp createdAt;

    public ProductImage() {
    }

    public ProductImage(int imageId,
            int productId,
            String imageUrl) {

        this.imageId = imageId;
        this.productId = productId;
        this.imageUrl = imageUrl;
    }

    public ProductImage(int productId,
            Integer skuId,
            String imageUrl,
            boolean primary,
            int displayOrder,
            String altText) {

        this.productId = productId;
        this.skuId = skuId;
        this.imageUrl = imageUrl;
        this.primary = primary;
        this.displayOrder = displayOrder;
        this.altText = altText;
    }

    public ProductImage(int imageId,
            int productId,
            Integer skuId,
            String imageUrl,
            boolean primary,
            int displayOrder,
            String altText,
            Timestamp createdAt) {

        this.imageId = imageId;
        this.productId = productId;
        this.skuId = skuId;
        this.imageUrl = imageUrl;
        this.primary = primary;
        this.displayOrder = displayOrder;
        this.altText = altText;
        this.createdAt = createdAt;
    }

    public int getImageId() {
        return imageId;
    }

    public void setImageId(int imageId) {
        this.imageId = imageId;
    }

    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
    }

    public Integer getSkuId() {
        return skuId;
    }

    public void setSkuId(Integer skuId) {
        this.skuId = skuId;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public boolean isPrimary() {
        return primary;
    }

    public boolean getIsPrimary() {
        return primary;
    }

    public void setPrimary(boolean primary) {
        this.primary = primary;
    }

    public void setIsPrimary(boolean primary) {
        this.primary = primary;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
    }

    public String getAltText() {
        return altText;
    }

    public void setAltText(String altText) {
        this.altText = altText;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
