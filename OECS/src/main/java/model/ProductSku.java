package model;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class ProductSku {

    private int skuId;
    private int productId;
    private String skuCode;

    private double price;
    private int stockQuantity;
    private Timestamp createdAt;

    private Double originalPrice;
    private boolean active = true;
    private byte[] variantKey;

    private List<SkuAttributeValue> attributeValues
            = new ArrayList<>();

    private List<ProductImage> images
            = new ArrayList<>();

    public ProductSku() {
    }

    public ProductSku(int skuId,
            int productId,
            String skuCode,
            double price,
            int stockQuantity) {

        this.skuId = skuId;
        this.productId = productId;
        this.skuCode = skuCode;
        this.price = price;
        this.stockQuantity = stockQuantity;
    }

    public ProductSku(int skuId,
            int productId,
            String skuCode,
            double price,
            int stockQuantity,
            Timestamp createdAt,
            Double originalPrice,
            boolean active,
            byte[] variantKey) {

        this(skuId, productId, skuCode,
                price, stockQuantity);

        this.createdAt = createdAt;
        this.originalPrice = originalPrice;
        this.active = active;
        this.variantKey = variantKey;
    }

    public int getSkuId() {
        return skuId;
    }

    public void setSkuId(int skuId) {
        this.skuId = skuId;
    }

    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
    }

    public String getSkuCode() {
        return skuCode;
    }

    public void setSkuCode(String skuCode) {
        this.skuCode = skuCode;
    }

    public double getPrice() {
        return price;
    }

    public void setPrice(double price) {
        this.price = price;
    }

    public int getStockQuantity() {
        return stockQuantity;
    }

    public void setStockQuantity(int stockQuantity) {
        this.stockQuantity = stockQuantity;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public Double getOriginalPrice() {
        return originalPrice;
    }

    public void setOriginalPrice(Double originalPrice) {
        this.originalPrice = originalPrice;
    }

    public boolean isActive() {
        return active;
    }

    public boolean getIsActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public void setIsActive(boolean active) {
        this.active = active;
    }

    public byte[] getVariantKey() {
        return variantKey;
    }

    public void setVariantKey(byte[] variantKey) {
        this.variantKey = variantKey;
    }

    public List<SkuAttributeValue> getAttributeValues() {
        return attributeValues;
    }

    public void setAttributeValues(
            List<SkuAttributeValue> attributeValues) {

        this.attributeValues = attributeValues != null
                ? attributeValues
                : new ArrayList<>();
    }

    public List<ProductImage> getImages() {
        return images;
    }

    public void setImages(List<ProductImage> images) {
        this.images = images != null
                ? images
                : new ArrayList<>();
    }
}
