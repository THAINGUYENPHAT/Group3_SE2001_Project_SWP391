package model;

import java.sql.Timestamp;

public class Product {

    private int productId;
    private int categoryId;
    private int brandId;
    private String productName;
    private String description;
    private Timestamp createdAt;

    // Quan hệ đối tượng (OOP Mapping)
    private Category category;
    private Brand brand;

    public Product() {
    }

    // Constructor dùng cho thao tác CSDL cơ bản (không có object liên kết)
    public Product(int productId, int categoryId, int brandId, String productName, String description, Timestamp createdAt) {
        this.productId = productId;
        this.categoryId = categoryId;
        this.brandId = brandId;
        this.productName = productName;
        this.description = description;
        this.createdAt = createdAt;
    }

    // Constructor đầy đủ (bao gồm cả Object Category và Brand)
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