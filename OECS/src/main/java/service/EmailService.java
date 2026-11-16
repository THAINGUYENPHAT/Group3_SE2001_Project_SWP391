package service;

import dao.UserDAO;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.logging.Level;
import java.util.logging.Logger;

public class EmailService {

    private static final Logger LOGGER = Logger.getLogger(EmailService.class.getName());

    private static final String FROM_NAME = "OECS Store";
    private static final String FROM_EMAIL = "oecs.store@gmail.com";
    private static final String BREVO_API_KEY = System.getenv("BREVO_API_KEY");
    private static final String BREVO_API_URL = "https://api.brevo.com/v3/smtp/email";

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .build();

    public boolean emailExists(String email) throws Exception {
        if (email == null || email.trim().isEmpty()) {
            return false;
        }

        UserDAO dao = new UserDAO();
        return dao.findByEmail(email.trim()) != null;
    }

    public boolean sendResetPasswordEmail(String toEmail, String resetLink) {
        String subject = "Đặt lại mật khẩu - OECS";

        String content = "<h2>Đặt lại mật khẩu</h2>"
                + "<p>Bạn vừa yêu cầu đặt lại mật khẩu cho tài khoản OECS.</p>"
                + "<p>Nhấn vào liên kết bên dưới để tạo mật khẩu mới:</p>"
                + "<p><a href=\"" + resetLink + "\">Đặt lại mật khẩu</a></p>"
                + "<p>Liên kết này có hiệu lực trong 15 phút.</p>"
                + "<p>Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.</p>";

        return sendEmail(toEmail, subject, content);
    }

    public boolean sendAccountSetupEmail(String toEmail, String setupLink) {
        String subject = "Tài khoản OECS của bạn đã được tạo";

        String content = "<h2>Chào mừng bạn đến với OECS</h2>"
                + "<p>Một tài khoản OECS đã được tạo cho địa chỉ email này.</p>"
                + "<p>Vui lòng nhấn vào liên kết bên dưới để thiết lập mật khẩu:</p>"
                + "<p><a href=\"" + setupLink + "\">Thiết lập mật khẩu</a></p>"
                + "<p>Liên kết này có hiệu lực trong 24 giờ.</p>"
                + "<p>Sau khi thiết lập mật khẩu, bạn có thể đăng nhập vào OECS.</p>";

        return sendEmail(toEmail, subject, content);
    }

    private boolean sendEmail(String toEmail, String subject, String htmlContent) {
        if (toEmail == null || toEmail.trim().isEmpty()) {
            return false;
        }

        if (BREVO_API_KEY == null || BREVO_API_KEY.isBlank()
                || "PASTE_YOUR_BREVO_API_KEY_HERE".equals(BREVO_API_KEY)) {
            LOGGER.severe("Chưa cấu hình Brevo API key.");
            return false;
        }

        try {
            String jsonBody = "{"
                    + "\"sender\":{\"name\":\"" + escapeJson(FROM_NAME)
                    + "\",\"email\":\"" + escapeJson(FROM_EMAIL) + "\"},"
                    + "\"to\":[{\"email\":\"" + escapeJson(toEmail.trim()) + "\"}],"
                    + "\"subject\":\"" + escapeJson(subject) + "\","
                    + "\"htmlContent\":\"" + escapeJson(htmlContent) + "\""
                    + "}";

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(BREVO_API_URL))
                    .timeout(Duration.ofSeconds(20))
                    .header("accept", "application/json")
                    .header("api-key", BREVO_API_KEY)
                    .header("content-type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonBody, StandardCharsets.UTF_8))
                    .build();

            HttpResponse<String> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8)
            );

            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                LOGGER.log(Level.INFO, "Đã gửi email tới {0}", toEmail);
                return true;
            }

            LOGGER.log(
                    Level.SEVERE,
                    "Brevo API error. HTTP {0}: {1}",
                    new Object[]{response.statusCode(), response.body()}
            );

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            LOGGER.log(Level.SEVERE, "Gửi email bị gián đoạn.", e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi gọi Brevo API.", e);
        }

        return false;
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }

        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}