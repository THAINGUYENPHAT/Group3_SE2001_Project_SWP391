package model;

import java.math.BigDecimal;

public class SkuAttributeValue {

    private int skuId;
    private int attributeId;

    private String textValue;
    private BigDecimal numericValue;
    private Boolean booleanValue;

    private String attributeName;
    private String dataType;
    private String unit;

    public SkuAttributeValue() {
    }

    public SkuAttributeValue(int skuId,
            int attributeId,
            String textValue) {

        this.skuId = skuId;
        this.attributeId = attributeId;
        this.textValue = textValue;
    }

    public SkuAttributeValue(int skuId,
            int attributeId,
            String textValue,
            BigDecimal numericValue,
            Boolean booleanValue) {

        this.skuId = skuId;
        this.attributeId = attributeId;
        this.textValue = textValue;
        this.numericValue = numericValue;
        this.booleanValue = booleanValue;
    }

    public SkuAttributeValue(int skuId,
            int attributeId,
            String textValue,
            BigDecimal numericValue,
            Boolean booleanValue,
            String attributeName,
            String dataType,
            String unit) {

        this(skuId, attributeId,
                textValue, numericValue, booleanValue);

        this.attributeName = attributeName;
        this.dataType = dataType;
        this.unit = unit;
    }

    public int getSkuId() {
        return skuId;
    }

    public void setSkuId(int skuId) {
        this.skuId = skuId;
    }

    public int getAttributeId() {
        return attributeId;
    }

    public void setAttributeId(int attributeId) {
        this.attributeId = attributeId;
    }

    public String getTextValue() {
        return textValue;
    }

    public void setTextValue(String textValue) {
        this.textValue = textValue;
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

    public String getAttributeName() {
        return attributeName;
    }

    public void setAttributeName(String attributeName) {
        this.attributeName = attributeName;
    }

    public String getDataType() {
        return dataType;
    }

    public void setDataType(String dataType) {
        this.dataType = dataType;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public String getDisplayValue() {

        if (textValue != null) {
            return textValue;
        }

        if (numericValue != null) {
            String number = numericValue
                    .stripTrailingZeros()
                    .toPlainString();

            if (unit != null && !unit.trim().isEmpty()) {
                return number + " " + unit;
            }

            return number;
        }

        if (booleanValue != null) {
            return booleanValue ? "Có" : "Không";
        }

        return "";
    }
}
