package service;

import dao.PasswordResetDAO;
import dao.UserDAO;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Base64;
import model.PasswordResetToken;
import model.User;

public class PasswordResetService {

    private final UserDAO userDAO = new UserDAO();
    private final PasswordResetDAO passwordResetDAO = new PasswordResetDAO();

    private static final long TOKEN_EXPIRE_MINUTES = 15;

    // =====================================================
    // 1. TẠO TOKEN RESET PASSWORD
    // =====================================================
    public String createResetToken(String email) throws Exception {

        if (email == null || email.trim().isEmpty()) {
            return null;
        }

        User user = userDAO.findByEmail(email.trim());

        if (user == null) {
            return null;
        }

        // Hủy các token cũ chưa sử dụng
        passwordResetDAO.invalidateOldTokens(user.getUserId());

        // Token thật gửi cho người dùng
        String rawToken = generateToken();

        // DB chỉ lưu hash của token
        String tokenHash = hashToken(rawToken);

        long expireTime = System.currentTimeMillis()
                + TOKEN_EXPIRE_MINUTES * 60 * 1000;

        Timestamp expiresAt = new Timestamp(expireTime);

        PasswordResetToken resetToken = new PasswordResetToken(
                user.getUserId(),
                tokenHash,
                expiresAt
        );

        boolean created = passwordResetDAO.createToken(resetToken);

        if (!created) {
            return null;
        }

        return rawToken;
    }

    // =====================================================
    // 2. KIỂM TRA TOKEN
    // =====================================================
    public PasswordResetToken validateToken(String rawToken)
            throws Exception {

        if (rawToken == null || rawToken.trim().isEmpty()) {
            return null;
        }

        String tokenHash = hashToken(rawToken);

        return passwordResetDAO.findValidToken(tokenHash);
    }

    // =====================================================
    // 3. RESET PASSWORD
    // =====================================================
    public boolean resetPassword(String rawToken, String newPassword)
            throws Exception {

        if (rawToken == null || rawToken.trim().isEmpty()) {
            return false;
        }

        if (newPassword == null || newPassword.length() < 6) {
            return false;
        }

        // Kiểm tra token
        PasswordResetToken token = validateToken(rawToken);

        if (token == null) {
            return false;
        }

        // Đổi mật khẩu
        boolean passwordUpdated = userDAO.resetPassword(
                token.getUserId(),
                newPassword
        );

        if (!passwordUpdated) {
            return false;
        }

        // Token chỉ được dùng 1 lần
        return passwordResetDAO.markAsUsed(token.getResetId());
    }

    // =====================================================
    // 4. TẠO TOKEN NGẪU NHIÊN
    // =====================================================
    private String generateToken() {

        SecureRandom secureRandom = new SecureRandom();

        byte[] bytes = new byte[32];

        secureRandom.nextBytes(bytes);

        return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(bytes);
    }

    // =====================================================
    // 5. HASH TOKEN BẰNG SHA-256
    // =====================================================
    private String hashToken(String rawToken)
            throws Exception {

        MessageDigest digest =
                MessageDigest.getInstance("SHA-256");

        byte[] hash = digest.digest(
                rawToken.getBytes(StandardCharsets.UTF_8)
        );

        StringBuilder result = new StringBuilder();

        for (byte b : hash) {
            result.append(String.format("%02x", b));
        }

        return result.toString();
    }
}