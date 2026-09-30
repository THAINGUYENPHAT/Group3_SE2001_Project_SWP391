package model;

public class ProductSpecification {

    private String attributeName; // Tên thông số (RAM, Màn hình...)
    private String value;         // Giá trị (16GB, 6.1 inch...)

    public ProductSpecification() {
    }

    public ProductSpecification(String attributeName, String value) {
        this.attributeName = attributeName;
        this.value = value;
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
