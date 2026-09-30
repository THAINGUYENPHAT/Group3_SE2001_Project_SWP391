package model;

import java.math.BigDecimal;

public class OrderItem {

    private int orderItemId, orderId, skuId, quantity;
    private BigDecimal price;

    public int getOrderItemId() {
        return orderItemId;
    }

    public void setOrderItemId(int v) {
        orderItemId = v;
    }

    public int getOrderId() {
        return orderId;
    }

    public void setOrderId(int v) {
        orderId = v;
    }

    public int getSkuId() {
        return skuId;
    }

    public void setSkuId(int v) {
        skuId = v;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int v) {
        quantity = v;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal v) {
        price = v;
    }
}