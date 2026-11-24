package model;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class SalesReport {
    private BigDecimal revenue = BigDecimal.ZERO;
    private int totalOrders;
    private int completedOrders;
    private int revenueOrders;
    private int productsSold;
    private final List<Object[]> inventory = new ArrayList<>();
    private final List<Object[]> payments = new ArrayList<>();
    private final List<Object[]> statuses = new ArrayList<>();
    private final List<Object[]> revenueByDate = new ArrayList<>();
    private final List<Object[]> topProducts = new ArrayList<>();

    public BigDecimal getRevenue() {
        return revenue;
    }

    public void setRevenue(BigDecimal revenue) {
        this.revenue = revenue;
    }

    public int getTotalOrders() {
        return totalOrders;
    }

    public void setTotalOrders(int totalOrders) {
        this.totalOrders = totalOrders;
    }

    public int getCompletedOrders() {
        return completedOrders;
    }

    public void setCompletedOrders(int completedOrders) {
        this.completedOrders = completedOrders;
    }

    public int getRevenueOrders() {
        return revenueOrders;
    }

    public void setRevenueOrders(int revenueOrders) {
        this.revenueOrders = revenueOrders;
    }

    public int getProductsSold() {
        return productsSold;
    }

    public void setProductsSold(int productsSold) {
        this.productsSold = productsSold;
    }

    public List<Object[]> getInventory() {
        return Collections.unmodifiableList(inventory);
    }

    public void addInventoryRow(Object[] row) {
        inventory.add(row);
    }

    public List<Object[]> getPayments() {
        return Collections.unmodifiableList(payments);
    }

    public void addPaymentRow(Object[] row) {
        payments.add(row);
    }

    public List<Object[]> getStatuses() {
        return Collections.unmodifiableList(statuses);
    }

    public void addStatus(Object[] row) {
        statuses.add(row);
    }

    public List<Object[]> getRevenueByDate() {
        return Collections.unmodifiableList(revenueByDate);
    }

    public void addRevenueRow(Object[] row) {
        revenueByDate.add(row);
    }

    public List<Object[]> getTopProducts() {
        return Collections.unmodifiableList(topProducts);
    }

    public void addTopProduct(Object[] row) {
        topProducts.add(row);
    }
}
