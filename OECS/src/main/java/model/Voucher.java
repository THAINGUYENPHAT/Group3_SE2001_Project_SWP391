package model;

import java.sql.Timestamp;

public class Voucher {

    private int voucherId;
    private String code;
    private double minOrderValue;
    private Timestamp validFrom;
    private Timestamp validTo;
    private String discountType;
    private double discountValue;
    private Double maxDiscount;
    private Integer usageLimit;
    private Integer perUserLimit;

    public Voucher() {
    }

    // All-args Constructor đầy đủ tham số
    public Voucher(int voucherId, String code, double minOrderValue, Timestamp validFrom, Timestamp validTo, 
                   String discountType, double discountValue, Double maxDiscount, Integer usageLimit, Integer perUserLimit) {
        this.voucherId = voucherId;
        this.code = code;
        this.minOrderValue = minOrderValue;
        this.validFrom = validFrom;
        this.validTo = validTo;
        this.discountType = discountType;
        this.discountValue = discountValue;
        this.maxDiscount = maxDiscount;
        this.usageLimit = usageLimit;
        this.perUserLimit = perUserLimit;
    }

    public int getVoucherId() {
        return voucherId;
    }

    public void setVoucherId(int voucherId) {
        this.voucherId = voucherId;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public double getMinOrderValue() {
        return minOrderValue;
    }

    public void setMinOrderValue(double minOrderValue) {
        this.minOrderValue = minOrderValue;
    }

    public Timestamp getValidFrom() {
        return validFrom;
    }

    public void setValidFrom(Timestamp validFrom) {
        this.validFrom = validFrom;
    }

    public Timestamp getValidTo() {
        return validTo;
    }

    public void setValidTo(Timestamp validTo) {
        this.validTo = validTo;
    }

    public String getDiscountType() {
        return discountType;
    }

    public void setDiscountType(String discountType) {
        this.discountType = discountType;
    }

    public double getDiscountValue() {
        return discountValue;
    }

    public void setDiscountValue(double discountValue) {
        this.discountValue = discountValue;
    }

    public Double getMaxDiscount() {
        return maxDiscount;
    }

    public void setMaxDiscount(Double maxDiscount) {
        this.maxDiscount = maxDiscount;
    }

    public Integer getUsageLimit() {
        return usageLimit;
    }

    public void setUsageLimit(Integer usageLimit) {
        this.usageLimit = usageLimit;
    }

    public Integer getPerUserLimit() {
        return perUserLimit;
    }

    public void setPerUserLimit(Integer perUserLimit) {
        this.perUserLimit = perUserLimit;
    }

    @Override
    public String toString() {
        return "Voucher{" +
                "voucherId=" + voucherId +
                ", code='" + code + '\'' +
                ", minOrderValue=" + minOrderValue +
                ", validFrom=" + validFrom +
                ", validTo=" + validTo +
                ", discountType='" + discountType + '\'' +
                ", discountValue=" + discountValue +
                ", maxDiscount=" + maxDiscount +
                ", usageLimit=" + usageLimit +
                ", perUserLimit=" + perUserLimit +
                '}';
    }
}