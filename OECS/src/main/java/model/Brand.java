package model;

public class Brand {

    private int brandId;
    private String brandName;
    private String logoUrl;

    private boolean active = true;

    public Brand() {
    }

    public Brand(int brandId,
            String brandName,
            String logoUrl) {

        this.brandId = brandId;
        this.brandName = brandName;
        this.logoUrl = logoUrl;
    }

    public Brand(int brandId,
            String brandName,
            String logoUrl,
            boolean active) {

        this.brandId = brandId;
        this.brandName = brandName;
        this.logoUrl = logoUrl;
        this.active = active;
    }

    public int getBrandId() {
        return brandId;
    }

    public void setBrandId(int brandId) {
        this.brandId = brandId;
    }

    public String getBrandName() {
        return brandName;
    }

    public void setBrandName(String brandName) {
        this.brandName = brandName;
    }

    public String getLogoUrl() {
        return logoUrl;
    }

    public void setLogoUrl(String logoUrl) {
        this.logoUrl = logoUrl;
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
