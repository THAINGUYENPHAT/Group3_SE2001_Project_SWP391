package dao;

import db.DBContext;
import model.User;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

public class UserDAO extends DBContext {

    /**
     * Xử lý đăng nhập tài khoản người dùng
     *
     * @param username Tên đăng nhập hoặc Email
     * @param rawPassword Mật khẩu chưa mã hóa
     * @return Đối tượng User nếu đăng nhập thành công, null nếu thất bại
     */
    public User login(String username, String rawPassword) {
        String sql = "SELECT u.user_id, u.username, u.email, u.password_hash, u.phone, u.created_at, "
                + "r.role_id, r.role_name "
                + "FROM [USER] u "
                + "JOIN USER_ROLES ur ON u.user_id = ur.user_id "
                + "JOIN ROLES r ON ur.role_id = r.role_id "
                + "WHERE (u.username = ?) AND u.password_hash = ?";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            String hashedPassword = hashMd5(rawPassword);

            statement.setString(1, username);
            statement.setString(2, hashedPassword);

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return new User(
                            rs.getInt("user_id"),
                            rs.getString("username"),
                            rs.getString("email"),
                            rs.getString("password_hash"),
                            rs.getString("phone"),
                            rs.getTimestamp("created_at"),
                            rs.getInt("role_id"),
                            rs.getString("role_name")
                    );
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(UserDAO.class.getName()).log(Level.SEVERE, "Lỗi đăng nhập!", ex);
        }

        return null;
    }

    /**
     * Mã hóa chuỗi đầu vào theo thuật toán MD5
     */
    private String hashMd5(String raw) {
        if (raw == null) {
            return "";
        }
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] mess = md.digest(raw.getBytes());

            StringBuilder sb = new StringBuilder();
            for (byte b : mess) {
                sb.append(String.format("%02x", b));
            }

            return sb.toString();
        } catch (NoSuchAlgorithmException ex) {
            Logger.getLogger(UserDAO.class.getName()).log(Level.SEVERE, null, ex);
            return "";
        }
    }
    
    public boolean checkUserExist(String username, String email) {
        String sql = "SELECT user_id FROM [USER] WHERE username = ? OR email = ?";
        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, email);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return true; // Đã tồn tại username hoặc email
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    // 2. Thêm người dùng mới vào bảng [USER]
    public boolean register(String username, String email, String password, String phone) {
        String sql = "INSERT INTO [USER] (username, email, password_hash, phone) VALUES (?, ?, ?, ?)";
        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, email);
            ps.setString(3, hashMd5(password));
            ps.setString(4, phone);
            
            int rowsAffected = ps.executeUpdate();
            
            if (rowsAffected > 0) {
                assignDefaultRole(username);
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
    
    private void assignDefaultRole(String username) {
        String sql = "INSERT INTO USER_ROLES (user_id, role_id) "
                   + "SELECT user_id, 3 FROM [USER] WHERE username = ?";
        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // =========================================================================
    // CÁC PHƯƠNG THỨC BỔ SUNG CHO PROFILE & ĐỔI MẬT KHẨU
    // =========================================================================

    /**
     * Cập nhật thông tin Hồ sơ cá nhân (Email, Phone)
     */
    public boolean updateProfile(int userId, String email, String phone) {
        String sql = "UPDATE [USER] SET email = ?, phone = ? WHERE user_id = ?";
        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setString(2, phone);
            ps.setInt(3, userId);
            
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    /**
     * Đổi mật khẩu tài khoản (Có kiểm tra mật khẩu cũ)
     */
    public boolean changePassword(int userId, String rawOldPassword, String rawNewPassword) {
        String checkSql = "SELECT user_id FROM [USER] WHERE user_id = ? AND password_hash = ?";
        String updateSql = "UPDATE [USER] SET password_hash = ? WHERE user_id = ?";

        try (Connection conn = this.getConnection()) {
            // 1. Kiểm tra mật khẩu cũ có chính xác không
            try (PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
                checkPs.setInt(1, userId);
                checkPs.setString(2, hashMd5(rawOldPassword));
                
                try (ResultSet rs = checkPs.executeQuery()) {
                    if (!rs.next()) {
                        return false; // Mật khẩu cũ không chính xác
                    }
                }
            }

            // 2. Tiến hành cập nhật mật khẩu mới (mã hóa MD5)
            try (PreparedStatement updatePs = conn.prepareStatement(updateSql)) {
                updatePs.setString(1, hashMd5(rawNewPassword));
                updatePs.setInt(2, userId);
                
                return updatePs.executeUpdate() > 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}