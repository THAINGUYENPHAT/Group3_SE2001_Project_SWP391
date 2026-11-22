
package model;

public class Attribute {

    private int attributeId;
    private String attributeName;
    private String dataType;
    private String unit;
    private boolean isActive = true;

    public Attribute() {
    }

    public Attribute(int attributeId, String attributeName) {
        this.attributeId = attributeId;
        this.attributeName = attributeName;
    }

    public Attribute(int attributeId, String attributeName,
                     String dataType, String unit, boolean isActive) {
        this.attributeId = attributeId;
        this.attributeName = attributeName;
        this.dataType = dataType;
        this.unit = unit;
        this.isActive = isActive;
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

    public boolean isActive() {
        return isActive;
    }

    public boolean getIsActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public void setIsActive(boolean active) {
        isActive = active;
    }
}
