package model;

public class Attribute {

    private int attributeId;
    private String attributeName;

    // Constructor rỗng
    public Attribute() {
    }

    // Constructor đầy đủ tham số (Chính là cái đang bị gọi thiếu trong ProductDAO)
    public Attribute(int attributeId, String attributeName) {
        this.attributeId = attributeId;
        this.attributeName = attributeName;
    }

    // Getters và Setters
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
}
