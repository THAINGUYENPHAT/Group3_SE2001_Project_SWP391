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

    
    public String createResetToken(String email) throws Exception {

        if (email == null || email.trim().isEmpty()) {
            return null;
        }

        User user = userDAO.findByEmail(email.trim());

        if (user == null) {
            return null;
        }

        passwordResetDAO.invalidateOldTokens(user.getUserId());

        String rawToken = generateToken();

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

    public PasswordResetToken validateToken(String rawToken)
            throws Exception {

        if (rawToken == null || rawToken.trim().isEmpty()) {
            return null;
        }

        String tokenHash = hashToken(rawToken);

        return passwordResetDAO.findValidToken(tokenHash);
    }

    public boolean resetPassword(String rawToken, String newPassword)
            throws Exception {

        if (rawToken == null || rawToken.trim().isEmpty()) {
            return false;
        }

        if (newPassword == null || newPassword.length() < 6) {
            return false;
        }

        PasswordResetToken token = validateToken(rawToken);

        if (token == null) {
            return false;
        }

        boolean passwordUpdated = userDAO.resetPassword(
                token.getUserId(),
                newPassword
        );

        if (!passwordUpdated) {
            return false;
        }

        return passwordResetDAO.markAsUsed(token.getResetId());
    }

    private String generateToken() {

        SecureRandom secureRandom = new SecureRandom();

        byte[] bytes = new byte[32];

        secureRandom.nextBytes(bytes);

        return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(bytes);
    }

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