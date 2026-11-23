package model;

public class ProductOverviewSection {

    private int sectionId;
    private int productId;
    private String sectionKey;
    private String sectionTitle;
    private String sectionContent;
    private String imageUrl;
    private String imageAlt;
    private int displayOrder;

    public ProductOverviewSection() {
    }

    public ProductOverviewSection(
            int sectionId,
            int productId,
            String sectionKey,
            String sectionTitle,
            String sectionContent,
            String imageUrl,
            String imageAlt,
            int displayOrder) {

        this.sectionId = sectionId;
        this.productId = productId;
        this.sectionKey = sectionKey;
        this.sectionTitle = sectionTitle;
        this.sectionContent = sectionContent;
        this.imageUrl = imageUrl;
        this.imageAlt = imageAlt;
        this.displayOrder = displayOrder;
    }

    public int getSectionId() {
        return sectionId;
    }

    public int getProductId() {
        return productId;
    }

    public String getSectionKey() {
        return sectionKey;
    }

    public String getSectionTitle() {
        return sectionTitle;
    }

    public String getSectionContent() {
        return sectionContent;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public String getImageAlt() {
        return imageAlt;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }
}
