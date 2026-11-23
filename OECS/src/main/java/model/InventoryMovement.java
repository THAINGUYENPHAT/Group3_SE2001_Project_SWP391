package model;

import java.sql.Timestamp;

public class InventoryMovement {

    private final long movementId;
    private final String skuCode;
    private final String productName;
    private final String movementType;
    private final int quantityDelta;
    private final int quantityBefore;
    private final int quantityAfter;
    private final String note;
    private final String actorName;
    private final Timestamp createdAt;

    public InventoryMovement(long movementId, String skuCode, String productName,
            String movementType, int quantityDelta,
            int quantityBefore, int quantityAfter,
            String note, String actorName, Timestamp createdAt) {
        this.movementId = movementId;
        this.skuCode = skuCode;
        this.productName = productName;
        this.movementType = movementType;
        this.quantityDelta = quantityDelta;
        this.quantityBefore = quantityBefore;
        this.quantityAfter = quantityAfter;
        this.note = note;
        this.actorName = actorName;
        this.createdAt = createdAt;
    }

    public long getMovementId() {
        return movementId;
    }

    public String getSkuCode() {
        return skuCode;
    }

    public String getProductName() {
        return productName;
    }

    public String getMovementType() {
        return movementType;
    }

    public int getQuantityDelta() {
        return quantityDelta;
    }

    public int getQuantityBefore() {
        return quantityBefore;
    }

    public int getQuantityAfter() {
        return quantityAfter;
    }

    public String getNote() {
        return note;
    }

    public String getActorName() {
        return actorName;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }
}
