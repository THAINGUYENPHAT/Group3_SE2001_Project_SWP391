package model;

import java.sql.Timestamp;

public class User {

    private int userId;
    private String username;
    private String email;
    private String passwordHash;
    private String phone;
    private Timestamp createdAt;

    // Thuộc tính phụ trợ cho Phân quyền & Vận hành
    private int roleId;
    private String roleName;

    public User() {
    }

    // Constructor cơ bản lấy thông tin từ bảng Users
    public User(int userId, String username, String email, String passwordHash, String phone, Timestamp createdAt) {
        this.userId = userId;
        this.username = username;
        this.email = email;
        this.passwordHash = passwordHash;
        this.phone = phone;
        this.createdAt = createdAt;
    }

    // Constructor mở rộng bao gồm Role (Dùng cho Authenticate / Session)
    public User(int userId, String username, String email, String passwordHash, String phone, Timestamp createdAt, int roleId, String roleName) {
        this.userId = userId;
        this.username = username;
        this.email = email;
        this.passwordHash = passwordHash;
        this.phone = phone;
        this.createdAt = createdAt;
        this.roleId = roleId;
        this.roleName = roleName;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public int getRoleId() {
        return roleId;
    }

    public void setRoleId(int roleId) {
        this.roleId = roleId;
    }

    public String getRoleName() {
        return roleName;
    }

    public void setRoleName(String roleName) {
        this.roleName = roleName;
    }

    // ========================================================
    // HELPER METHODS DÙNG CHO CHECK PHÂN QUYỀN TRONG AUTH FILTER & JSP
    // ========================================================

    public boolean hasRole(String role) {
        return this.roleName != null && this.roleName.equalsIgnoreCase(role);
    }

    public boolean isAdmin() {
        return hasRole("Admin");
    }

    public boolean isAdminOrStaff() {
        return hasRole("Admin") || hasRole("Staff");
    }

    public boolean isCustomer() {
        return hasRole("Customer");
    }

    @Override
    public String toString() {
        return "User{" +
                "userId=" + userId +
                ", username='" + username + '\'' +
                ", email='" + email + '\'' +
                ", phone='" + phone + '\'' +
                ", roleName='" + roleName + '\'' +
                '}';
    }
}