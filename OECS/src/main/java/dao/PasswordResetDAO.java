package dao;

import db.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import model.PasswordResetToken;

public class PasswordResetDAO {

   
    public boolean resetPasswordAtomically(String tokenHash, String newPassword,
            UserDAO users) throws SQLException {
        try (Connection conn = new DBContext().getConnection()) {
            if (conn == null) throw new SQLException("Không kết nối được database.");
            conn.setAutoCommit(false);
            try {
                Integer userId = null;
                int resetId = 0;
                String select = "SELECT reset_id,user_id FROM dbo.PASSWORD_RESET_TOKEN "
                        + "WITH (UPDLOCK,HOLDLOCK) WHERE token_hash=? "
                        + "AND used_at IS NULL AND expires_at>GETDATE()";
                try (PreparedStatement ps = conn.prepareStatement(select)) {
                    ps.setString(1, tokenHash);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            resetId = rs.getInt("reset_id");
                            userId = rs.getInt("user_id");
                        }
                    }
                }
                if (userId == null) {
                    conn.rollback();
                    return false;
                }
              
                if (!users.resetPassword(conn, userId, newPassword)) {
                    conn.rollback();
                    return false;
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.PASSWORD_RESET_TOKEN SET used_at=GETDATE() "
                        + "WHERE reset_id=? AND used_at IS NULL AND expires_at>GETDATE()")) {
                    ps.setInt(1, resetId);
                    if (ps.executeUpdate() != 1) {
                        conn.rollback();
                        return false;
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.PASSWORD_RESET_TOKEN SET used_at=GETDATE() "
                        + "WHERE user_id=? AND used_at IS NULL")) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }
                conn.commit();
                return true;
            } catch (SQLException | RuntimeException ex) {
                try { conn.rollback(); } catch (SQLException e) { ex.addSuppressed(e); }
                throw ex;
            }
        }
    }


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