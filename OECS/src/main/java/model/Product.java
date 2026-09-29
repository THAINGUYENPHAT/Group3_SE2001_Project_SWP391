package model;

import java.sql.Timestamp;

public class Product {

    private int productId;
    private String productName;
    private String description;
    private Category category;
    private Brand brand;
    private Timestamp createdAt;

    public Product() {
    }

    public Product(int productId, String productName, String description, Category category, Brand brand, Timestamp createdAt) {
        this.productId = productId;
        this.productName = productName;
        this.description = description;
        this.category = category;
        this.brand = brand;
        this.createdAt = createdAt;
    }

    // Getters and Setters
    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
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

    public Category getCategory() {
        return category;
    }

    public void setCategory(Category category) {
        this.category = category;
    }

    public Brand getBrand() {
        return brand;
    }

    public void setBrand(Brand brand) {
        this.brand = brand;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}