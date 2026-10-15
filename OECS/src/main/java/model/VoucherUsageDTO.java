package model;

import java.sql.Timestamp;

public class VoucherUsageDTO {

    private int usageId;
    private int voucherId;
    private String voucherCode;
    private int orderId;
    private int userId;
    private Timestamp usedAt;

    public VoucherUsageDTO() {
    }

    public VoucherUsageDTO(
            int usageId,
            int voucherId,
            String voucherCode,
            int orderId,
            int userId,
            Timestamp usedAt) {

        this.usageId = usageId;
        this.voucherId = voucherId;
        this.voucherCode = voucherCode;
        this.orderId = orderId;
        this.userId = userId;
        this.usedAt = usedAt;
    }

    public int getUsageId() {
        return usageId;
    }

    public void setUsageId(int usageId) {
        this.usageId = usageId;
    }

    public int getVoucherId() {
        return voucherId;
    }

    public void setVoucherId(int voucherId) {
        this.voucherId = voucherId;
    }

    public String getVoucherCode() {
        return voucherCode;
    }

    public void setVoucherCode(String voucherCode) {
        this.voucherCode = voucherCode;
    }

    public int getOrderId() {
        return orderId;
    }

    public void setOrderId(int orderId) {
        this.orderId = orderId;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public Timestamp getUsedAt() {
        return usedAt;
    }

    public void setUsedAt(Timestamp usedAt) {
        this.usedAt = usedAt;
    }

    @Override
    public String toString() {
        return "VoucherUsageDTO{"
                + "usageId=" + usageId
                + ", voucherId=" + voucherId
                + ", voucherCode='" + voucherCode + '\''
                + ", orderId=" + orderId
                + ", userId=" + userId
                + ", usedAt=" + usedAt
                + '}';
    }
}
