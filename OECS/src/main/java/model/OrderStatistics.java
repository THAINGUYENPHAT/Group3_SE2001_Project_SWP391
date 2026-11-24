package model;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class OrderStatistics {
    private BigDecimal revenue = BigDecimal.ZERO;
    private int totalOrders;
    private int completedOrders;
    private int cancelledOrders;
    private final List<Object[]> revenueByPeriod = new ArrayList<>();
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

    public int getCancelledOrders() {
        return cancelledOrders;
    }

    public void setCancelledOrders(int cancelledOrders) {
        this.cancelledOrders = cancelledOrders;
    }

    public List<Object[]> getRevenueByPeriod() {
        return Collections.unmodifiableList(revenueByPeriod);
    }

    public void addRevenueRow(Object[] row) {
        revenueByPeriod.add(row);
    }

    public List<Object[]> getTopProducts() {
        return Collections.unmodifiableList(topProducts);
    }

    public void addTopProduct(Object[] row) {
        topProducts.add(row);
    }
}
