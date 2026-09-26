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
                   + "WHERE (u.username = ? OR u.email = ?) AND u.password_hash = ?";

        try (Connection conn = this.getConnection();
             PreparedStatement statement = conn.prepareStatement(sql)) {

            String hashedPassword = hashMd5(rawPassword);

            statement.setString(1, username);
            statement.setString(2, username);
            statement.setString(3, hashedPassword);

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
        if (raw == null) return "";
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
}