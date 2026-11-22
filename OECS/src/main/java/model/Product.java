package model;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class Product {

    private int productId;
    private int categoryId;
    private int brandId;

    private String productName;
    private String description;
    private String imageUrl;

    private Timestamp createdAt;

    private String modelCode;
    private boolean active = true;
    private Timestamp updatedAt;

    private double minPrice;

    private double averageRating;
    private int reviewCount;

    private Category category;
    private Brand brand;

    private List<ProductImage> galleryImages = new ArrayList<>();
    private List<ProductSku> skus = new ArrayList<>();
    private List<ProductSpec> specifications = new ArrayList<>();

    public Product() {
    }

    public Product(int categoryId,
            int brandId,
            String productName,
            String description,
            String imageUrl) {

        this.categoryId = categoryId;
        this.brandId = brandId;
        this.productName = productName;
        this.description = description;
        this.imageUrl = imageUrl;
    }

    public Product(int productId,
            int categoryId,
            int brandId,
            String productName,
            String description,
            Timestamp createdAt) {

        this.productId = productId;
        this.categoryId = categoryId;
        this.brandId = brandId;
        this.productName = productName;
        this.description = description;
        this.createdAt = createdAt;
    }

    public Product(int productId,
            int categoryId,
            int brandId,
            String productName,
            String description,
            Timestamp createdAt,
            Category category,
            Brand brand) {

        this.productId = productId;
        this.categoryId = categoryId;
        this.brandId = brandId;
        this.productName = productName;
        this.description = description;
        this.createdAt = createdAt;

        setCategory(category);
        setBrand(brand);
    }

    public Product(int productId,
            int categoryId,
            int brandId,
            String productName,
            String description,
            Timestamp createdAt,
            String imageUrl,
            Category category,
            Brand brand) {

        this.productId = productId;
        this.categoryId = categoryId;
        this.brandId = brandId;
        this.productName = productName;
        this.description = description;
        this.createdAt = createdAt;
        this.imageUrl = imageUrl;

        setCategory(category);
        setBrand(brand);
    }

    public Product(int productId,
            int categoryId,
            int brandId,
            String productName,
            String description,
            String imageUrl,
            Timestamp createdAt,
            String modelCode,
            boolean active,
            Timestamp updatedAt) {

        this.productId = productId;
        this.categoryId = categoryId;
        this.brandId = brandId;
        this.productName = productName;
        this.description = description;
        this.imageUrl = imageUrl;
        this.createdAt = createdAt;
        this.modelCode = modelCode;
        this.active = active;
        this.updatedAt = updatedAt;
    }

    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
    }

    public int getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(int categoryId) {
        this.categoryId = categoryId;
    }

    public int getBrandId() {
        return brandId;
    }

    public void setBrandId(int brandId) {
        this.brandId = brandId;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public String getModelCode() {
        return modelCode;
    }

    public void setModelCode(String modelCode) {
        this.modelCode = modelCode;
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

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }

    public double getMinPrice() {
        return minPrice;
    }

    public void setMinPrice(double minPrice) {
        this.minPrice = minPrice;
    }

    public double getAverageRating() {
        return averageRating;
    }

    public void setAverageRating(double averageRating) {
        this.averageRating = averageRating;
    }

    public int getReviewCount() {
        return reviewCount;
    }

    public void setReviewCount(int reviewCount) {
        this.reviewCount = reviewCount;
    }

    public Category getCategory() {
        return category;
    }

    public void setCategory(Category category) {
        this.category = category;

        if (category != null) {
            this.categoryId = category.getCategoryId();
        }
    }

    public Brand getBrand() {
        return brand;
    }

    public void setBrand(Brand brand) {
        this.brand = brand;

        if (brand != null) {
            this.brandId = brand.getBrandId();
        }
    }

    public List<ProductImage> getGalleryImages() {
        return galleryImages;
    }

    public void setGalleryImages(
            List<ProductImage> galleryImages) {

        this.galleryImages = galleryImages != null
                ? galleryImages
                : new ArrayList<>();
    }

    public List<ProductSku> getSkus() {
        return skus;
    }

    public void setSkus(List<ProductSku> skus) {
        this.skus = skus != null
                ? skus
                : new ArrayList<>();
    }

    public List<ProductSpec> getSpecifications() {
        return specifications;
    }

    public void setSpecifications(
            List<ProductSpec> specifications) {

        this.specifications = specifications != null
                ? specifications
                : new ArrayList<>();
    }
}
