package model;

public class Category {

    private int categoryId;
    private String categoryName;
    private Integer parentId; // Dùng Integer thay vì int để cho phép giá trị null (danh mục gốc)

    public Category() {
    }

    public Category(int categoryId, String categoryName, Integer parentId) {
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.parentId = parentId;
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
}