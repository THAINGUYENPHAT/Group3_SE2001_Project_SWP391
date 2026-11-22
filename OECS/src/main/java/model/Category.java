package model;

public class Category {

    private int categoryId;
    private String categoryName;
    private Integer parentId;

    private String description;
    private boolean active = true;

    public Category() {
    }

    public Category(int categoryId,
            String categoryName,
            Integer parentId) {

        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.parentId = parentId;
    }

    public Category(int categoryId,
            String categoryName,
            Integer parentId,
            String description,
            boolean active) {

        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.parentId = parentId;
        this.description = description;
        this.active = active;
    }

    public int getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(int categoryId) {
        this.categoryId = categoryId;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public Integer getParentId() {
        return parentId;
    }

    public void setParentId(Integer parentId) {
        this.parentId = parentId;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public boolean isActive() {
        return active;
    }

    public boolean getIsActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public void setIsActive(boolean active) {
        this.active = active;
    }
}
