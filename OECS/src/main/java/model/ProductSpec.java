package model;

import java.math.BigDecimal;

public class ProductSpec {

    private int productId;
    private int attributeId;
    private String value;
    private BigDecimal numericValue;
    private Boolean booleanValue;

    private String attributeName;
    private String unit;

    private String groupName;
    private int displayOrder;

    public ProductSpec() {
    }

    public ProductSpec(String attributeName, String value) {
        this.attributeName = attributeName;
        this.value = value;
    }

    public ProductSpec(int attributeId,
            String attributeName,
            String value) {
        this.attributeId = attributeId;
        this.attributeName = attributeName;
        this.value = value;
    }

    public ProductSpec(int productId,
            int attributeId,
            String value,
            BigDecimal numericValue,
            Boolean booleanValue) {
        this.productId = productId;
        this.attributeId = attributeId;
        this.value = value;
        this.numericValue = numericValue;
        this.booleanValue = booleanValue;
    }

    public ProductSpec(int productId,
            int attributeId,
            String attributeName,
            String value,
            BigDecimal numericValue,
            Boolean booleanValue,
            String groupName,
            String unit,
            int displayOrder) {
        this.productId = productId;
        this.attributeId = attributeId;
        this.attributeName = attributeName;
        this.value = value;
        this.numericValue = numericValue;
        this.booleanValue = booleanValue;
        this.groupName = groupName;
        this.unit = unit;
        this.displayOrder = displayOrder;
    }

    // =========================
    // GETTERS & SETTERS
    // =========================
    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
    }

    public int getAttributeId() {
        return attributeId;
    }

    public void setAttributeId(int attributeId) {
        this.attributeId = attributeId;
    }

    public String getAttributeName() {
        return attributeName;
    }

    public void setAttributeName(String attributeName) {
        this.attributeName = attributeName;
    }

    public String getValue() {
        return value;
    }

    public void setValue(String value) {
        this.value = value;
    }

    public BigDecimal getNumericValue() {
        return numericValue;
    }

    public void setNumericValue(BigDecimal numericValue) {
        this.numericValue = numericValue;
    }

    public Boolean getBooleanValue() {
        return booleanValue;
    }

    public void setBooleanValue(Boolean booleanValue) {
        this.booleanValue = booleanValue;
    }

    public String getGroupName() {
        return groupName;
    }

    public void setGroupName(String groupName) {
        this.groupName = groupName;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
    }
}
