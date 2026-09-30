package model;

public class ProductSKU {

    private int skuId;
    private int productId;
    private String skuCode;
    private double price;
    private int stockQuantity;

    public ProductSKU() {
    }

    public ProductSKU(int skuId, int productId, String skuCode, double price, int stockQuantity) {
        this.skuId = skuId;
        this.productId = productId;
        this.skuCode = skuCode;
        this.price = price;
        this.stockQuantity = stockQuantity;
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
}
