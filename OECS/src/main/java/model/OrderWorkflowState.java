package model;

import java.math.BigDecimal;

public final class OrderWorkflowState {
    private final int orderId;
    private final int customerId;
    private final String orderStatus;
    private final String paymentStatus;
    private final String paymentMethod;
    private final BigDecimal totalAmount;
    private final String cancelRequestStatus;
    private final String cancelRequestVersion;
    private final boolean stockRestored;

    public OrderWorkflowState(int orderId, int customerId, String orderStatus, String paymentStatus,
            String paymentMethod, BigDecimal totalAmount, String cancelRequestStatus,
            String cancelRequestVersion, boolean stockRestored) {
        this.orderId = orderId;
        this.customerId = customerId;
        this.orderStatus = orderStatus;
        this.paymentStatus = paymentStatus;
        this.paymentMethod = paymentMethod;
        this.totalAmount = totalAmount;
        this.cancelRequestStatus = cancelRequestStatus;
        this.cancelRequestVersion = cancelRequestVersion;
        this.stockRestored = stockRestored;
    }

    public int getOrderId() {
        return orderId;
    }

    public int getCustomerId() {
        return customerId;
    }

    public String getOrderStatus() {
        return orderStatus;
    }

    public String getPaymentStatus() {
        return paymentStatus;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public BigDecimal getTotalAmount() {
        return totalAmount;
    }

    public String getCancelRequestStatus() {
        return cancelRequestStatus;
    }

    public String getCancelRequestVersion() {
        return cancelRequestVersion;
    }

    public boolean isStockRestored() {
        return stockRestored;
    }
}
