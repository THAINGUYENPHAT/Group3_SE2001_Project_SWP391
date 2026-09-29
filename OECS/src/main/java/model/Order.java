package model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Order {

    private int orderId;
    private int userId;
    private int addressId;
    private Integer shippingPartnerId;
    private BigDecimal totalAmount;
    private BigDecimal shippingFee;
    private Timestamp createdAt;

    public Order() {
    }

    public Order(int orderId, int userId, int addressId,
                 Integer shippingPartnerId,
                 BigDecimal totalAmount,
                 BigDecimal shippingFee,
                 Timestamp createdAt) {

        this.orderId = orderId;
        this.userId = userId;
        this.addressId = addressId;
        this.shippingPartnerId = shippingPartnerId;
        this.totalAmount = totalAmount;
        this.shippingFee = shippingFee;
        this.createdAt = createdAt;
    }

    public int getOrderId() {
        return orderId;
    }

    public void setOrderId(int orderId) {
        this.orderId = orderId;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public int getAddressId() {
        return addressId;
    }

    public void setAddressId(int addressId) {
        this.addressId = addressId;
    }

    public Integer getShippingPartnerId() {
        return shippingPartnerId;
    }

    public void setShippingPartnerId(Integer shippingPartnerId) {
        this.shippingPartnerId = shippingPartnerId;
    }

    public BigDecimal getTotalAmount() {
        return totalAmount;
    }

    public void setTotalAmount(BigDecimal totalAmount) {
        this.totalAmount = totalAmount;
    }

    public BigDecimal getShippingFee() {
        return shippingFee;
    }

    public void setShippingFee(BigDecimal shippingFee) {
        this.shippingFee = shippingFee;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}