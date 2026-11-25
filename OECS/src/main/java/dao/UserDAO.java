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

    public User login(String account, String rawPassword) {

        String sql
                = "SELECT u.user_id, u.username, u.email, "
                + "u.is_active, u.role_id, r.role_name "
                + "FROM [USER] u "
                + "JOIN ROLES r ON u.role_id = r.role_id "
                + "WHERE (u.username = ? OR u.email = ?) "
                + "AND u.password_hash = ?";

        try (Connection conn = getConnection();
                PreparedStatement statement = conn.prepareStatement(sql)) {

            statement.setString(1, account);
            statement.setString(2, account);
            statement.setString(3, hashMd5(rawPassword));

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    User user = new User();
                    user.setUserId(rs.getInt("user_id"));
                    user.setUsername(rs.getString("username"));
                    user.setEmail(rs.getString("email"));
                    user.setActive(rs.getBoolean("is_active"));
                    user.setRoleId(rs.getInt("role_id"));
                    user.setRoleName(rs.getString("role_name"));
                    return user;
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi đăng nhập!", ex);
        }

        return null;
    }

    public User getProfileById(int userId) {
        String sql
                = "SELECT u.user_id, u.username, u.email, u.phone, "
                + "a.address_line AS default_address "
                + "FROM [USER] u "
                + "LEFT JOIN ADDRESSBOOK a "
                + "ON a.user_id = u.user_id "
                + "AND a.is_default = 1 AND a.is_deleted = 0 "
                + "WHERE u.user_id = ?";

        try (Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    User profile = new User();
                    profile.setUserId(rs.getInt("user_id"));
                    profile.setUsername(rs.getString("username"));
                    profile.setEmail(rs.getString("email"));
                    profile.setPhone(rs.getString("phone"));
                    profile.setAddress(rs.getString("default_address"));
                    return profile;
                }
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Lỗi tải thông tin Profile!", ex);
        }

        return null;
    }

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

    public boolean register(
            String username,
            String email,
            String password,
            String phone) {

        String sql
                = "INSERT INTO [USER] "
                + "(username, email, password_hash, phone, role_id) "
                + "SELECT ?, ?, ?, ?, role_id "
                + "FROM ROLES WHERE role_name = N'CUSTOMER'";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, username);
            ps.setString(2, email);
            ps.setString(3, hashMd5(password));
            ps.setString(4, phone);

            return ps.executeUpdate() > 0;

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi đăng ký tài khoản!", ex);
        }

        return false;
    }

    public List<User> getAllUsers(
            String keyword,
            Integer roleId,
            String status,
            String sort) {

        List<User> userList = new ArrayList<>();
        List<Object> params = new ArrayList<>();

        StringBuilder sql = new StringBuilder();

        sql.append(
                "SELECT "
                + "u.user_id, "
                + "u.username, "
                + "u.email, "
                + "u.phone, "
                + "u.is_active, "
                + "u.created_at, "
                + "u.role_id, "
                + "r.role_name "
                + "FROM [USER] u "
                + "JOIN ROLES r ON u.role_id = r.role_id "
                + "WHERE 1 = 1 "
        );

        if (keyword != null && !keyword.trim().isEmpty()) {

            sql.append(
                    "AND ("
                    + "u.username LIKE ? "
                    + "OR u.email LIKE ? "
                    + "OR u.phone LIKE ?"
                    + ") "
            );

            String searchKeyword = "%" + keyword.trim() + "%";

            params.add(searchKeyword);
            params.add(searchKeyword);
            params.add(searchKeyword);
        }

        if (roleId != null) {

            sql.append("AND u.role_id = ? ");

            params.add(roleId);
        }

        if ("active".equalsIgnoreCase(status)) {

            sql.append("AND u.is_active = 1 ");

        } else if ("locked".equalsIgnoreCase(status)) {

            sql.append("AND u.is_active = 0 ");
        }

        if (sort == null || sort.trim().isEmpty()) {
            sort = "newest";
        }

        switch (sort) {

            case "oldest":
                sql.append("ORDER BY u.created_at ASC ");
                break;

            case "username_asc":
                sql.append("ORDER BY u.username ASC ");
                break;

            case "username_desc":
                sql.append("ORDER BY u.username DESC ");
                break;

            case "newest":
            default:
                sql.append("ORDER BY u.created_at DESC ");
                break;
        }

        try (Connection connection = getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) {
                statement.setObject(i + 1, params.get(i));
            }

            try (ResultSet rs = statement.executeQuery()) {

                while (rs.next()) {

                    User user = new User();

                    user.setUserId(rs.getInt("user_id"));
                    user.setUsername(rs.getString("username"));
                    user.setEmail(rs.getString("email"));
                    user.setPhone(rs.getString("phone"));
                    user.setActive(rs.getBoolean("is_active"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                    user.setRoleId(rs.getInt("role_id"));
                    user.setRoleName(rs.getString("role_name"));

                    userList.add(user);
                }
            }

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE, "Lỗi khi lấy danh sách User!", e);
        }

        return userList;
    }

    public User getUserById(int userId) {

        String sql
                = "SELECT u.user_id, u.username, u.email, "
                + "u.password_hash, u.phone, u.created_at, u.is_active, "
                + "u.role_id, r.role_name "
                + "FROM [USER] u "
                + "JOIN ROLES r ON u.role_id = r.role_id "
                + "WHERE u.user_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    return new User(
                            rs.getInt("user_id"),
                            rs.getString("username"),
                            rs.getString("email"),
                            rs.getString("password_hash"),
                            rs.getString("phone"),
                            rs.getTimestamp("created_at"),
                            rs.getInt("role_id"),
                            rs.getString("role_name"),
                            rs.getBoolean("is_active")
                    );
                }
            }

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi lấy user theo ID!", ex);
        }

        return null;
    }

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

    public boolean createUser(User user, String rawPassword) {

        String sql
                = "INSERT INTO [USER] "
                + "(username, email, password_hash, phone, role_id) "
                + "VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, user.getUsername());
            ps.setString(2, user.getEmail());
            ps.setString(3, hashMd5(rawPassword));
            ps.setString(4, user.getPhone());
            ps.setInt(5, user.getRoleId());

            return ps.executeUpdate() > 0;

        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Lỗi tạo user!", ex);
        }

        return false;
    }

    public boolean updateProfile(int userId, String email, String phone, String address, String fullName) {
        String updateProfileSql = "UPDATE [USER] SET email = ?, phone = ? WHERE user_id = ?";

        String updateAddrSql = "UPDATE ADDRESSBOOK SET address_line = ?, phone_number = ? "
                + "WHERE user_id = ? AND is_default = 1 AND is_deleted = 0";
        String insertAddrSql = "INSERT INTO ADDRESSBOOK (user_id, recipient_name, phone_number, address_line, is_default) VALUES (?, ?, ?, ?, 1)";

        Connection conn = null;
        try {
            conn = getConnection();
            conn.setAutoCommit(false);

            try (PreparedStatement psUser = conn.prepareStatement(updateProfileSql)) {
                psUser.setString(1, email);
                psUser.setString(2, phone);
                psUser.setInt(3, userId);
                if (psUser.executeUpdate() != 1) {
                    conn.rollback();
                    return false;
                }
            }

            if (address != null && !address.trim().isEmpty()) {

                int updatedRows;

                try (PreparedStatement psUpdateAddr
                        = conn.prepareStatement(updateAddrSql)) {

                    psUpdateAddr.setString(1, address.trim());
                    psUpdateAddr.setString(2, phone);
                    psUpdateAddr.setInt(3, userId);

                    updatedRows = psUpdateAddr.executeUpdate();
                }

                if (updatedRows == 0) {

                    try (PreparedStatement psInsertAddr
                            = conn.prepareStatement(insertAddrSql)) {

                        psInsertAddr.setInt(1, userId);

                        psInsertAddr.setString(
                                2,
                                fullName != null
                                        ? fullName
                                        : "Khách hàng"
                        );

                        psInsertAddr.setString(3, phone);
                        psInsertAddr.setString(4, address.trim());

                        psInsertAddr.executeUpdate();
                    }
                }
            }

            conn.commit();
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

    public boolean changePassword(
            int userId,
            String rawOldPassword,
            String rawNewPassword) {

        String sql
                = "UPDATE dbo.[USER] "
                + "SET password_hash = ? "
                + "WHERE user_id = ? "
                + "AND password_hash = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {


            ps.setString(1, hashMd5(rawNewPassword));

           
            ps.setInt(2, userId);

       
            ps.setString(3, hashMd5(rawOldPassword));

           
            return ps.executeUpdate() == 1;

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi doi mat khau nguoi dung!",
                    ex);
        }

        return false;
    }

    public boolean updateUserStatus(
            int userId,
            boolean active) {

        String sql
                = "UPDATE [USER] "
                + "SET is_active = ? "
                + "WHERE user_id = ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setBoolean(1, active);
            ps.setInt(2, userId);

            return ps.executeUpdate() > 0;

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi cập nhật trạng thái tài khoản!",
                    ex
            );
        }

        return false;
    }

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

    public User findByEmail(String email) throws SQLException {

        String sql
                = "SELECT u.user_id, u.username, u.email, "
                + "u.password_hash, u.phone, u.created_at, "
                + "u.is_active, u.role_id, r.role_name "
                + "FROM [USER] u "
                + "JOIN ROLES r ON u.role_id = r.role_id "
                + "WHERE u.email = ?";

        try (Connection connection = getConnection(); PreparedStatement ps = connection.prepareStatement(sql)) {

            ps.setString(1, email);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    User user = new User();

                    user.setUserId(rs.getInt("user_id"));
                    user.setUsername(rs.getString("username"));
                    user.setEmail(rs.getString("email"));
                    user.setPasswordHash(rs.getString("password_hash"));
                    user.setPhone(rs.getString("phone"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                    user.setRoleId(rs.getInt("role_id"));
                    user.setRoleName(rs.getString("role_name"));
                    user.setActive(rs.getBoolean("is_active"));

                    return user;
                }
            }
        }

        return null;
    }


    public boolean resetPassword(Connection connection, int userId, String rawNewPassword)
            throws SQLException {
        String sql = "UPDATE [USER] SET password_hash = ? WHERE user_id = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, hashMd5(rawNewPassword));
            ps.setInt(2, userId);
            return ps.executeUpdate() == 1;
        }
    }
}
