package model;

public class InventoryItem {

    private final int skuId;
    private final int productId;
    private final String skuCode;
    private final String productName;
    private final int stockQuantity;
    private final boolean skuActive;
    private final boolean productActive;

    public InventoryItem(int skuId, int productId, String skuCode,
            String productName, int stockQuantity,
            boolean skuActive, boolean productActive) {
        this.skuId = skuId;
        this.productId = productId;
        this.skuCode = skuCode;
        this.productName = productName;
        this.stockQuantity = stockQuantity;
        this.skuActive = skuActive;
        this.productActive = productActive;
    }

    public int getSkuId() {
        return skuId;
    }

    public int getProductId() {
        return productId;
    }

    public String getSkuCode() {
        return skuCode;
    }

    public String getProductName() {
        return productName;
    }

    public int getStockQuantity() {
        return stockQuantity;
    }

    public boolean isSkuActive() {
        return skuActive;
    }

    public boolean isProductActive() {
        return productActive;
    }

    public boolean isEditable() {
        return skuActive && productActive;
    }
}
