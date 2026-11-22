package model;

public class CategoryAttribute {

    private int categoryId;
    private int attributeId;

    private String groupName;
    private String attributeType;

    private boolean required;
    private boolean filterable;

    private int displayOrder;

    private String attributeName;
    private String dataType;
    private String unit;

    public CategoryAttribute() {
    }

    public CategoryAttribute(int categoryId, int attributeId,
            String groupName, String attributeType,
            boolean required, boolean filterable,
            int displayOrder) {
        this.categoryId = categoryId;
        this.attributeId = attributeId;
        this.groupName = groupName;
        this.attributeType = attributeType;
        this.required = required;
        this.filterable = filterable;
        this.displayOrder = displayOrder;
    }

    public CategoryAttribute(int categoryId, int attributeId,
            String groupName, String attributeType,
            boolean required, boolean filterable,
            int displayOrder, String attributeName,
            String dataType, String unit) {
        this(categoryId, attributeId, groupName, attributeType,
                required, filterable, displayOrder);

        this.attributeName = attributeName;
        this.dataType = dataType;
        this.unit = unit;
    }

    public int getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(int categoryId) {
        this.categoryId = categoryId;
    }

    public int getAttributeId() {
        return attributeId;
    }

    public void setAttributeId(int attributeId) {
        this.attributeId = attributeId;
    }

    public String getGroupName() {
        return groupName;
    }

    public void setGroupName(String groupName) {
        this.groupName = groupName;
    }

    public String getAttributeType() {
        return attributeType;
    }

    public void setAttributeType(String attributeType) {
        this.attributeType = attributeType;
    }

    public boolean isRequired() {
        return required;
    }

    public boolean getIsRequired() {
        return required;
    }

    public void setRequired(boolean required) {
        this.required = required;
    }

    public void setIsRequired(boolean required) {
        this.required = required;
    }

    public boolean isFilterable() {
        return filterable;
    }

    public boolean getIsFilterable() {
        return filterable;
    }

    public void setFilterable(boolean filterable) {
        this.filterable = filterable;
    }

    public void setIsFilterable(boolean filterable) {
        this.filterable = filterable;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
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
}
