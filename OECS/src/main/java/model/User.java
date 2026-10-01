package model;

import java.sql.Timestamp;

public class User {

    private int userId;
    private String username;
    private String email;
    private String passwordHash;
    private String phone;
    private Timestamp createdAt;

    private int roleId;
    private String roleName;
    private boolean active;

    private String address; // Lưu địa chỉ mặc định từ ADDRESSBOOK

    // Getter & Setter
    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public User() {
    }

    public User(int userId, String username, String email,
            String passwordHash, String phone, Timestamp createdAt) {

        this.userId = userId;
        this.username = username;
        this.email = email;
        this.passwordHash = passwordHash;
        this.phone = phone;
        this.createdAt = createdAt;
    }

    public User(int userId, String username, String email,
            String passwordHash, String phone, Timestamp createdAt,
            int roleId, String roleName, boolean active) {

        this.userId = userId;
        this.username = username;
        this.email = email;
        this.passwordHash = passwordHash;
        this.phone = phone;
        this.createdAt = createdAt;
        this.roleId = roleId;
        this.roleName = roleName;
        this.active = active;
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

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public boolean hasRole(String role) {
        return this.roleName != null
                && this.roleName.equalsIgnoreCase(role);
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

    public boolean isLocked() {
        return !active;
    }

    @Override
    public String toString() {
        return "User{"
                + "userId=" + userId
                + ", username='" + username + '\''
                + ", email='" + email + '\''
                + ", phone='" + phone + '\''
                + ", roleName='" + roleName + '\''
                + ", active=" + active
                + '}';
    }
}
