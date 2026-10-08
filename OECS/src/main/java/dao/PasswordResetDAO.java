package dao;

import db.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import model.PasswordResetToken;

public class PasswordResetDAO {

    // =====================================================
    // 1. TẠO TOKEN RESET PASSWORD MỚI
    // =====================================================
    public boolean createToken(PasswordResetToken token) throws SQLException {

        String sql = "INSERT INTO PASSWORD_RESET_TOKEN "
                + "(user_id, token_hash, expires_at) "
                + "VALUES (?, ?, ?)";

        try (Connection connection = new DBContext().getConnection();
             PreparedStatement ps = connection.prepareStatement(sql)) {

            ps.setInt(1, token.getUserId());
            ps.setString(2, token.getTokenHash());
            ps.setTimestamp(3, token.getExpiresAt());

            return ps.executeUpdate() > 0;
        }
    }

    // =====================================================
    // 2. TÌM TOKEN CÒN HỢP LỆ
    // =====================================================
    public PasswordResetToken findValidToken(String tokenHash)
            throws SQLException {

        String sql = "SELECT reset_id, user_id, token_hash, expires_at, used_at, created_at "
                + "FROM PASSWORD_RESET_TOKEN "
                + "WHERE token_hash = ? "
                + "AND used_at IS NULL "
                + "AND expires_at > GETDATE()";

        try (Connection connection = new DBContext().getConnection();
             PreparedStatement ps = connection.prepareStatement(sql)) {

            ps.setString(1, tokenHash);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    PasswordResetToken token = new PasswordResetToken();

                    token.setResetId(rs.getInt("reset_id"));
                    token.setUserId(rs.getInt("user_id"));
                    token.setTokenHash(rs.getString("token_hash"));
                    token.setExpiresAt(rs.getTimestamp("expires_at"));
                    token.setUsedAt(rs.getTimestamp("used_at"));
                    token.setCreatedAt(rs.getTimestamp("created_at"));

                    return token;
                }
            }
        }

        return null;
    }

    // =====================================================
    // 3. ĐÁNH DẤU TOKEN ĐÃ ĐƯỢC SỬ DỤNG
    // =====================================================
    public boolean markAsUsed(int resetId) throws SQLException {

        String sql = "UPDATE PASSWORD_RESET_TOKEN "
                + "SET used_at = GETDATE() "
                + "WHERE reset_id = ? "
                + "AND used_at IS NULL";

        try (Connection connection = new DBContext().getConnection();
             PreparedStatement ps = connection.prepareStatement(sql)) {

            ps.setInt(1, resetId);

            return ps.executeUpdate() > 0;
        }
    }

    // =====================================================
    // 4. VÔ HIỆU HÓA TOKEN CŨ CỦA USER
    // =====================================================
    public void invalidateOldTokens(int userId) throws SQLException {

        String sql = "UPDATE PASSWORD_RESET_TOKEN "
                + "SET used_at = GETDATE() "
                + "WHERE user_id = ? "
                + "AND used_at IS NULL";

        try (Connection connection = new DBContext().getConnection();
             PreparedStatement ps = connection.prepareStatement(sql)) {

            ps.setInt(1, userId);
            ps.executeUpdate();
        }
    }
}