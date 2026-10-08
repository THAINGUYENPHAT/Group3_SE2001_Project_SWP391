package model;

import java.sql.Timestamp;

public class PasswordResetToken {

    private int resetId;
    private int userId;
    private String tokenHash;
    private Timestamp expiresAt;
    private Timestamp usedAt;
    private Timestamp createdAt;

    // Constructor rỗng
    public PasswordResetToken() {
    }

    // Constructor đầy đủ
    public PasswordResetToken(int resetId, int userId, String tokenHash,
            Timestamp expiresAt, Timestamp usedAt, Timestamp createdAt) {
        this.resetId = resetId;
        this.userId = userId;
        this.tokenHash = tokenHash;
        this.expiresAt = expiresAt;
        this.usedAt = usedAt;
        this.createdAt = createdAt;
    }

    // Constructor dùng khi tạo token mới
    public PasswordResetToken(int userId, String tokenHash, Timestamp expiresAt) {
        this.userId = userId;
        this.tokenHash = tokenHash;
        this.expiresAt = expiresAt;
    }

    public int getResetId() {
        return resetId;
    }

    public void setResetId(int resetId) {
        this.resetId = resetId;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public String getTokenHash() {
        return tokenHash;
    }

    public void setTokenHash(String tokenHash) {
        this.tokenHash = tokenHash;
    }

    public Timestamp getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(Timestamp expiresAt) {
        this.expiresAt = expiresAt;
    }

    public Timestamp getUsedAt() {
        return usedAt;
    }

    public void setUsedAt(Timestamp usedAt) {
        this.usedAt = usedAt;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    // Token đã được sử dụng chưa
    public boolean isUsed() {
        return usedAt != null;
    }

    // Token đã hết hạn chưa
    public boolean isExpired() {
        return expiresAt != null
                && expiresAt.before(new Timestamp(System.currentTimeMillis()));
    }

    // Token còn hợp lệ về thời gian và chưa sử dụng
    public boolean isValid() {
        return !isUsed() && !isExpired();
    }

    @Override
    public String toString() {
        return "PasswordResetToken{"
                + "resetId=" + resetId
                + ", userId=" + userId
                + ", expiresAt=" + expiresAt
                + ", usedAt=" + usedAt
                + ", createdAt=" + createdAt
                + '}';
    }
}