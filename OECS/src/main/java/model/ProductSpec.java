package model;

public class ProductSpec {

    private int attributeId;
    private String attributeName;
    private String value;

    public ProductSpec() {
    }

    public ProductSpec(String attributeName, String value) {
        this.attributeName = attributeName;
        this.value = value;
    }

    public ProductSpec(int attributeId, String attributeName, String value) {
        this.attributeId = attributeId;
        this.attributeName = attributeName;
        this.value = value;
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
}
