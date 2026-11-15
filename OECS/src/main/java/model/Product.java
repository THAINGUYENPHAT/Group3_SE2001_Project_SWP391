package model;

import java.sql.Timestamp;
import java.util.List;
import java.util.ArrayList;

public class Product {

    private int productId;
    private int categoryId;
    private int brandId;
    private String productName;
    private String description;
    private Timestamp createdAt;
    private String imageUrl; 

    private double minPrice;

    private Category category;
    private Brand brand;

    private List<ProductImage> galleryImages = new ArrayList<>();

    public Product() {
    }

    public List<ProductImage> getGalleryImages() {
        return galleryImages;
    }

    public void setGalleryImages(List<ProductImage> galleryImages) {
        this.galleryImages = galleryImages;
    }

    public Product(int productId, int categoryId, int brandId, String productName,
            String description, Timestamp createdAt, String imageUrl,
            Category category, Brand brand) {
        this.productId = productId;
        this.categoryId = categoryId;
        this.brandId = brandId;
        this.productName = productName;
        this.description = description;
        this.createdAt = createdAt;
        this.imageUrl = imageUrl;
        this.category = category;
        this.brand = brand;
    }

    public Product(int categoryId, int brandId, String productName, String description, String imageUrl) {
        this.categoryId = categoryId;
        this.brandId = brandId;
        this.productName = productName;
        this.description = description;
        this.imageUrl = imageUrl;
    }

    public Product(int productId, int categoryId, int brandId, String productName, String description, Timestamp createdAt) {
        this.productId = productId;
        this.categoryId = categoryId;
        this.brandId = brandId;
        this.productName = productName;
        this.description = description;
        this.createdAt = createdAt;
    }

    public Product(int productId, int categoryId, int brandId, String productName, String description, Timestamp createdAt, Category category, Brand brand) {
        this.productId = productId;
        this.categoryId = categoryId;
        this.brandId = brandId;
        this.productName = productName;
        this.description = description;
        this.createdAt = createdAt;
        this.category = category;
        this.brand = brand;
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

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public double getMinPrice() {
        return minPrice;
    }

    public void setMinPrice(double minPrice) {
        this.minPrice = minPrice;
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
}
