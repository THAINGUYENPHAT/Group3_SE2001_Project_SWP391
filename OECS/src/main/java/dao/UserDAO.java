package dao;

import db.DBContext;
import model.User;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class UserDAO extends DBContext {

    public User login(String username, String rawPassword) {
        // Dùng LEFT JOIN cho cả USER_ROLES và ROLES
        String sql = "SELECT u.user_id, u.username, u.email, u.password_hash, u.phone, u.created_at, "
                + "ISNULL(ur.role_id, 0) AS role_id, r.role_name "
                + "FROM [USER] u "
                + "LEFT JOIN USER_ROLES ur ON u.user_id = ur.user_id "
                + "LEFT JOIN ROLES r ON ur.role_id = r.role_id "
                + "WHERE (u.username = ?) AND u.password_hash = ?";

        try (Connection conn = this.getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            String hashedPassword = hashMd5(rawPassword);

            statement.setString(1, username);
            statement.setString(2, hashedPassword);

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    int roleId = rs.getInt("role_id"); // Nếu không có dòng trong USER_ROLES, role_id sẽ là 0
                    String roleName = rs.getString("role_name");
                    if (roleId == 0) {
                        roleName = "LOCKED";
                    }

                    return new User(
                            rs.getInt("user_id"),
                            rs.getString("username"),
                            rs.getString("email"),
                            rs.getString("password_hash"),
                            rs.getString("phone"),
                            rs.getTimestamp("created_at"),
                            roleId,
                            roleName
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

    // 1. Lấy danh sách tất cả User (kèm tìm kiếm theo username/email/phone)
    public List<User> getAllUsers(String keyword) {
        List<User> list = new ArrayList<>();
        String sql = "SELECT u.user_id, u.username, u.email, u.password_hash, u.phone, u.created_at, "
                + "r.role_id, r.role_name "
                + "FROM [USER] u "
                + "LEFT JOIN USER_ROLES ur ON u.user_id = ur.user_id "
                + "LEFT JOIN ROLES r ON ur.role_id = r.role_id "
                + "WHERE u.username LIKE ? OR u.email LIKE ? OR u.phone LIKE ? "
                + "ORDER BY u.created_at DESC";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            String searchPattern = "%" + (keyword != null ? keyword.trim() : "") + "%";
            ps.setString(1, searchPattern);
            ps.setString(2, searchPattern);
            ps.setString(3, searchPattern);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    User user = new User(
                            rs.getInt("user_id"),
                            rs.getString("username"),
                            rs.getString("email"),
                            rs.getString("password_hash"),
                            rs.getString("phone"),
                            rs.getTimestamp("created_at"),
                            rs.getInt("role_id"),
                            rs.getString("role_name")
                    );
                    list.add(user);
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(UserDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return list;
    }

    // 2. Khóa / Mở khóa bằng cách thay đổi role_id trong bảng USER_ROLES
    /**
     * Khóa hoặc Mở khóa tài khoản không làm vi phạm Foreign Key của bảng ROLES.
     * - newRoleId == 0 (Khóa): Xóa phân quyền của User khỏi bảng USER_ROLES. -
     * newRoleId != 0 (Mở khóa): Gán lại vai trò tương ứng vào bảng USER_ROLES.
     */
    public boolean updateUserRole(int userId, int newRoleId) {
        if (newRoleId == 0) {
            // KHÓA TÀI KHOẢN: Xóa bản ghi trong USER_ROLES
            String sql = "DELETE FROM USER_ROLES WHERE user_id = ?";
            try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.executeUpdate();
                return true; // Xóa thành công hoặc đã bị xóa
            } catch (SQLException ex) {
                Logger.getLogger(UserDAO.class.getName()).log(Level.SEVERE, "Lỗi khóa tài khoản!", ex);
            }
        } else {
            // MỞ KHÓA TÀI KHOẢN: Xóa quyền cũ (nếu có) và Thêm lại quyền mới
            String deleteSql = "DELETE FROM USER_ROLES WHERE user_id = ?";
            String insertSql = "INSERT INTO USER_ROLES (user_id, role_id) VALUES (?, ?)";

            try (Connection conn = this.getConnection()) {
                try (PreparedStatement psDel = conn.prepareStatement(deleteSql)) {
                    psDel.setInt(1, userId);
                    psDel.executeUpdate();
                }
                try (PreparedStatement psIns = conn.prepareStatement(insertSql)) {
                    psIns.setInt(1, userId);
                    psIns.setInt(2, newRoleId);
                    return psIns.executeUpdate() > 0;
                }
            } catch (SQLException ex) {
                Logger.getLogger(UserDAO.class.getName()).log(Level.SEVERE, "Lỗi mở khóa tài khoản!", ex);
            }
        }
        return false;
    }
}
