package dao;

import db.DBContext;
import model.Role;
import model.User;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class UserDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(UserDAO.class.getName());

    // =========================================================
    // LOGIN
    // =========================================================
    public User login(String account, String rawPassword) {

        String sql
                = "SELECT u.user_id, u.username, u.email, u.password_hash, u.phone, u.created_at, "
                + "ISNULL(ur.role_id, 0) AS role_id, r.role_name, a.address_line AS default_address "
                + "FROM [USER] u "
                + "LEFT JOIN USER_ROLES ur ON u.user_id = ur.user_id "
                + "LEFT JOIN ROLES r ON ur.role_id = r.role_id "
                + "LEFT JOIN ADDRESSBOOK a ON u.user_id = a.user_id AND a.is_default = 1 "
                + "WHERE (u.username = ? OR u.email = ?) AND u.password_hash = ?";

        try (Connection conn = getConnection(); PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setString(1, account);
            statement.setString(2, account);
            statement.setString(3, hashMd5(rawPassword));

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    int roleId = rs.getInt("role_id");
                    String roleName = rs.getString("role_name");

                    if (roleId == 0 || roleName == null) {
                        roleName = "LOCKED";
                    }

                    User user = new User(
                            rs.getInt("user_id"),
                            rs.getString("username"),
                            rs.getString("email"),
                            rs.getString("password_hash"),
                            rs.getString("phone"),
                            rs.getTimestamp("created_at"),
                            roleId,
                            roleName,
                            true
                    );
                    user.setAddress(rs.getString("default_address")); // Lấy địa chỉ từ ADDRESSBOOK
                    return user;
                }
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi đăng nhập!", ex);
        }
        return null;
    }

    // =========================================================
    // CHECK USER EXIST
    // =========================================================
    public boolean checkUserExist(String username, String email) {

        String sql
                = "SELECT user_id "
                + "FROM [USER] "
                + "WHERE username = ? OR email = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, username);
            ps.setString(2, email);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi kiểm tra sự tồn tại của người dùng!", ex);
        }

        return false;
    }

    // =========================================================
    // CHECK USER EXIST WHEN UPDATE
    // =========================================================
    public boolean checkUserExistForUpdate(
            int userId,
            String username,
            String email) {

        String sql
                = "SELECT user_id "
                + "FROM [USER] "
                + "WHERE (username = ? OR email = ?) "
                + "AND user_id <> ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, username);
            ps.setString(2, email);
            ps.setInt(3, userId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi kiểm tra username/email!", ex);
        }

        return false;
    }

    // =========================================================
    // REGISTER
    // =========================================================
    public boolean register(
            String username,
            String email,
            String password,
            String phone) {

        String sql
                = "INSERT INTO [USER] "
                + "(username, email, password_hash, phone) "
                + "VALUES (?, ?, ?, ?)";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, username);
            ps.setString(2, email);
            ps.setString(3, hashMd5(password));
            ps.setString(4, phone);

            int rowsAffected = ps.executeUpdate();

            if (rowsAffected > 0) {
                assignDefaultRole(username);
                return true;
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi đăng ký tài khoản!", ex);
        }

        return false;
    }

    // =========================================================
    // ASSIGN DEFAULT ROLE
    // =========================================================
    private void assignDefaultRole(String username) {

        String sql
                = "INSERT INTO USER_ROLES (user_id, role_id) "
                + "SELECT user_id, 3 "
                + "FROM [USER] "
                + "WHERE username = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, username);
            ps.executeUpdate();

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi gán vai trò mặc định!", ex);
        }
    }

    // =========================================================
    // GET ALL USERS
    // =========================================================
    public List<User> getAllUsers(String keyword) {

        List<User> list = new ArrayList<>();

        String sql
                = "SELECT u.user_id, u.username, u.email, "
                + "u.password_hash, u.phone, u.created_at, "
                + "ISNULL(ur.role_id, 0) AS role_id, "
                + "r.role_name "
                + "FROM [USER] u "
                + "LEFT JOIN USER_ROLES ur "
                + "ON u.user_id = ur.user_id "
                + "LEFT JOIN ROLES r "
                + "ON ur.role_id = r.role_id "
                + "WHERE u.username LIKE ? "
                + "OR u.email LIKE ? "
                + "OR u.phone LIKE ? "
                + "ORDER BY u.created_at DESC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            String searchPattern
                    = "%" + (keyword != null
                            ? keyword.trim()
                            : "") + "%";

            ps.setString(1, searchPattern);
            ps.setString(2, searchPattern);
            ps.setString(3, searchPattern);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    int roleId = rs.getInt("role_id");
                    String roleName = rs.getString("role_name");

                    if (roleId == 0 || roleName == null) {
                        roleName = "LOCKED";
                    }

                    User user = new User(
                            rs.getInt("user_id"),
                            rs.getString("username"),
                            rs.getString("email"),
                            rs.getString("password_hash"),
                            rs.getString("phone"),
                            rs.getTimestamp("created_at"),
                            roleId,
                            roleName,
                            true
                    );

                    list.add(user);
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi lấy danh sách người dùng!", ex);
        }

        return list;
    }

    // =========================================================
    // GET USER BY ID
    // =========================================================
    public User getUserById(int userId) {

        String sql
                = "SELECT u.user_id, u.username, u.email, "
                + "u.password_hash, u.phone, u.created_at, "
                + "ISNULL(ur.role_id, 0) AS role_id, "
                + "r.role_name "
                + "FROM [USER] u "
                + "LEFT JOIN USER_ROLES ur "
                + "ON u.user_id = ur.user_id "
                + "LEFT JOIN ROLES r "
                + "ON ur.role_id = r.role_id "
                + "WHERE u.user_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    int roleId = rs.getInt("role_id");
                    String roleName = rs.getString("role_name");

                    if (roleId == 0 || roleName == null) {
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
                            roleName,
                            true
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi lấy user theo ID!", ex);
        }

        return null;
    }

    // =========================================================
    // GET ALL ROLES
    // =========================================================
    public List<Role> getAllRoles() {

        List<Role> list = new ArrayList<>();

        String sql
                = "SELECT role_id, role_name "
                + "FROM ROLES "
                + "ORDER BY role_id";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                list.add(new Role(
                        rs.getInt("role_id"),
                        rs.getString("role_name")
                ));
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi lấy danh sách role!", ex);
        }

        return list;
    }

    // =========================================================
    // CREATE USER
    // =========================================================
    public boolean createUser(User user, String rawPassword) {

        String userSql
                = "INSERT INTO [USER] "
                + "(username, email, password_hash, phone) "
                + "VALUES (?, ?, ?, ?)";

        String roleSql
                = "INSERT INTO USER_ROLES "
                + "(user_id, role_id) "
                + "VALUES (?, ?)";

        Connection conn = null;

        try {
            conn = getConnection();
            conn.setAutoCommit(false);

            int userId;

            try (PreparedStatement ps
                    = conn.prepareStatement(
                            userSql,
                            Statement.RETURN_GENERATED_KEYS)) {

                ps.setString(1, user.getUsername());
                ps.setString(2, user.getEmail());
                ps.setString(3, hashMd5(rawPassword));
                ps.setString(4, user.getPhone());

                ps.executeUpdate();

                try (ResultSet rs = ps.getGeneratedKeys()) {

                    if (!rs.next()) {
                        conn.rollback();
                        return false;
                    }

                    userId = rs.getInt(1);
                }
            }

            try (PreparedStatement ps
                    = conn.prepareStatement(roleSql)) {

                ps.setInt(1, userId);
                ps.setInt(2, user.getRoleId());
                ps.executeUpdate();
            }

            conn.commit();
            return true;

        } catch (SQLException ex) {

            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    LOGGER.log(Level.SEVERE,
                            "Rollback lỗi!", rollbackEx);
                }
            }

            LOGGER.log(Level.SEVERE,
                    "Lỗi tạo user!", ex);

        } finally {

            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ex) {
                    LOGGER.log(Level.SEVERE,
                            "Lỗi đóng connection!", ex);
                }
            }
        }

        return false;
    }

    // =========================================================
    // UPDATE USER
    // =========================================================
    public boolean updateUser(User user, String rawPassword) {

        String updateWithPassword
                = "UPDATE [USER] "
                + "SET username = ?, "
                + "email = ?, "
                + "password_hash = ?, "
                + "phone = ? "
                + "WHERE user_id = ?";

        String updateWithoutPassword
                = "UPDATE [USER] "
                + "SET username = ?, "
                + "email = ?, "
                + "phone = ? "
                + "WHERE user_id = ?";

        String deleteRoleSql
                = "DELETE FROM USER_ROLES "
                + "WHERE user_id = ?";

        String insertRoleSql
                = "INSERT INTO USER_ROLES "
                + "(user_id, role_id) "
                + "VALUES (?, ?)";

        Connection conn = null;

        try {

            conn = getConnection();
            conn.setAutoCommit(false);

            if (rawPassword != null
                    && !rawPassword.trim().isEmpty()) {

                try (PreparedStatement ps
                        = conn.prepareStatement(
                                updateWithPassword)) {

                    ps.setString(1, user.getUsername());
                    ps.setString(2, user.getEmail());
                    ps.setString(3, hashMd5(rawPassword));
                    ps.setString(4, user.getPhone());
                    ps.setInt(5, user.getUserId());

                    ps.executeUpdate();
                }

            } else {

                try (PreparedStatement ps
                        = conn.prepareStatement(
                                updateWithoutPassword)) {

                    ps.setString(1, user.getUsername());
                    ps.setString(2, user.getEmail());
                    ps.setString(3, user.getPhone());
                    ps.setInt(4, user.getUserId());

                    ps.executeUpdate();
                }
            }

            try (PreparedStatement ps
                    = conn.prepareStatement(deleteRoleSql)) {

                ps.setInt(1, user.getUserId());
                ps.executeUpdate();
            }

            try (PreparedStatement ps
                    = conn.prepareStatement(insertRoleSql)) {

                ps.setInt(1, user.getUserId());
                ps.setInt(2, user.getRoleId());
                ps.executeUpdate();
            }

            conn.commit();
            return true;

        } catch (SQLException ex) {

            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    LOGGER.log(Level.SEVERE,
                            "Rollback lỗi!", rollbackEx);
                }
            }

            LOGGER.log(Level.SEVERE,
                    "Lỗi cập nhật user!", ex);

        } finally {

            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ex) {
                    LOGGER.log(Level.SEVERE,
                            "Lỗi đóng connection!", ex);
                }
            }
        }

        return false;
    }

    // =========================================================
    // DELETE USER
    // =========================================================
    public boolean deleteUser(int userId) {

        String sql
                = "DELETE FROM [USER] "
                + "WHERE user_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            return ps.executeUpdate() > 0;

        } catch (SQLException ex) {

            LOGGER.log(Level.SEVERE,
                    "Lỗi xóa user!", ex);
        }

        return false;
    }

    // =========================================================
    // UPDATE PROFILE
    // =========================================================
    public boolean updateProfile(int userId, String email, String phone, String address, String fullName) {
        String updateProfileSql = "UPDATE [USER] SET email = ?, phone = ? WHERE user_id = ?";

        // Câu lệnh kiểm tra xem người dùng đã có địa chỉ mặc định chưa
        String checkAddrSql = "SELECT address_id FROM ADDRESSBOOK WHERE user_id = ? AND is_default = 1";
        String updateAddrSql = "UPDATE ADDRESSBOOK SET address_line = ?, phone_number = ? WHERE user_id = ? AND is_default = 1";
        String insertAddrSql = "INSERT INTO ADDRESSBOOK (user_id, recipient_name, phone_number, address_line, is_default) VALUES (?, ?, ?, ?, 1)";

        Connection conn = null;
        try {
            conn = getConnection();
            conn.setAutoCommit(false); // Dùng Transaction để đảm bảo tính toàn vẹn dữ liệu

            // 1. Cập nhật USER
            try (PreparedStatement psUser = conn.prepareStatement(updateProfileSql)) {
                psUser.setString(1, email);
                psUser.setString(2, phone);
                psUser.setInt(3, userId);
                psUser.executeUpdate();
            }

            // 2. Cập nhật hoặc Thêm mới Địa chỉ vào ADDRESSBOOK
            if (address != null && !address.trim().isEmpty()) {
                boolean hasDefaultAddr = false;
                try (PreparedStatement psCheck = conn.prepareStatement(checkAddrSql)) {
                    psCheck.setInt(1, userId);
                    try (ResultSet rs = psCheck.executeQuery()) {
                        if (rs.next()) {
                            hasDefaultAddr = true;
                        }
                    }
                }

                if (hasDefaultAddr) {
                    try (PreparedStatement psUpdateAddr = conn.prepareStatement(updateAddrSql)) {
                        psUpdateAddr.setString(1, address.trim());
                        psUpdateAddr.setString(2, phone);
                        psUpdateAddr.setInt(3, userId);
                        psUpdateAddr.executeUpdate();
                    }
                } else {
                    try (PreparedStatement psInsertAddr = conn.prepareStatement(insertAddrSql)) {
                        psInsertAddr.setInt(1, userId);
                        psInsertAddr.setString(2, fullName != null ? fullName : "Khách hàng");
                        psInsertAddr.setString(3, phone);
                        psInsertAddr.setString(4, address.trim());
                        psInsertAddr.executeUpdate();
                    }
                }
            }

            conn.commit(); // Xắc nhận lưu thay đổi
            return true;
        } catch (SQLException ex) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            LOGGER.log(Level.SEVERE, "Lỗi cập nhật profile!", ex);
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
        return false;
    }

    // =========================================================
    // CHANGE PASSWORD
    // =========================================================
    public boolean changePassword(
            int userId,
            String rawOldPassword,
            String rawNewPassword) {

        String checkSql
                = "SELECT user_id "
                + "FROM [USER] "
                + "WHERE user_id = ? "
                + "AND password_hash = ?";

        String updateSql
                = "UPDATE [USER] "
                + "SET password_hash = ? "
                + "WHERE user_id = ?";

        try (Connection conn = getConnection()) {

            try (PreparedStatement checkPs
                    = conn.prepareStatement(checkSql)) {

                checkPs.setInt(1, userId);
                checkPs.setString(2,
                        hashMd5(rawOldPassword));

                try (ResultSet rs
                        = checkPs.executeQuery()) {

                    if (!rs.next()) {
                        return false;
                    }
                }
            }

            try (PreparedStatement updatePs
                    = conn.prepareStatement(updateSql)) {

                updatePs.setString(1,
                        hashMd5(rawNewPassword));

                updatePs.setInt(2, userId);

                return updatePs.executeUpdate() > 0;
            }

        } catch (SQLException ex) {

            LOGGER.log(Level.SEVERE,
                    "Lỗi đổi mật khẩu!", ex);
        }

        return false;
    }

    // =========================================================
    // LOCK / UNLOCK (Vô hiệu hóa tạm thời do DB không có cột is_active)
    // =========================================================
    public boolean updateUserStatus(
            int userId,
            boolean active) {

        // CSDL không có cột is_active nên trả về false để tránh lỗi SQL
        LOGGER.log(Level.WARNING, "DB hiện tại không hỗ trợ cột is_active!");
        return false;
    }

    // =========================================================
    // MD5
    // =========================================================
    private String hashMd5(String raw) {

        if (raw == null) {
            return "";
        }

        try {

            MessageDigest md
                    = MessageDigest.getInstance("MD5");

            byte[] mess = md.digest(raw.getBytes());

            StringBuilder sb = new StringBuilder();

            for (byte b : mess) {
                sb.append(String.format("%02x", b));
            }

            return sb.toString();

        } catch (NoSuchAlgorithmException ex) {

            LOGGER.log(Level.SEVERE,
                    "Lỗi thuật toán MD5!", ex);

            return "";
        }
    }
}
