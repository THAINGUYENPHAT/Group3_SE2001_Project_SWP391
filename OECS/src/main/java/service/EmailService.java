package service;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

public class EmailService {

    private static final Logger LOGGER
            = Logger.getLogger(EmailService.class.getName());

    private static final String FROM_EMAIL = "oecs.store@gmail.com";
    private static final String APP_PASSWORD = "hkyfaiketbxbotad";

    public boolean sendResetPasswordEmail(String toEmail, String resetLink) {

        // Kiểm tra cấu hình email
        if (FROM_EMAIL == null || FROM_EMAIL.isBlank()
                || APP_PASSWORD == null || APP_PASSWORD.isBlank()) {

            LOGGER.severe(
                    "Thiếu cấu hình OECS_MAIL_EMAIL hoặc OECS_MAIL_APP_PASSWORD!"
            );

            return false;
        }

        Properties properties = new Properties();

        properties.put("mail.smtp.auth", "true");
        properties.put("mail.smtp.starttls.enable", "true");
        properties.put("mail.smtp.host", "smtp.gmail.com");
        properties.put("mail.smtp.port", "587");

        Session session = Session.getInstance(
                properties,
                new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(
                        FROM_EMAIL,
                        APP_PASSWORD
                );
            }
        }
        );

        try {

            Message message = new MimeMessage(session);

            message.setFrom(new InternetAddress(FROM_EMAIL));

            message.setRecipients(
                    Message.RecipientType.TO,
                    InternetAddress.parse(toEmail)
            );

            message.setSubject("Đặt lại mật khẩu - OECS");

            String content
                    = "<h2>Đặt lại mật khẩu</h2>"
                    + "<p>Bạn vừa yêu cầu đặt lại mật khẩu cho tài khoản OECS.</p>"
                    + "<p>Nhấn vào liên kết bên dưới để tạo mật khẩu mới:</p>"
                    + "<p>"
                    + "<a href=\"" + resetLink + "\">"
                    + "Đặt lại mật khẩu"
                    + "</a>"
                    + "</p>"
                    + "<p>Liên kết này có hiệu lực trong 15 phút.</p>"
                    + "<p>Nếu bạn không yêu cầu đặt lại mật khẩu, "
                    + "hãy bỏ qua email này.</p>";

            message.setContent(
                    content,
                    "text/html; charset=UTF-8"
            );

            Transport.send(message);

            return true;

        } catch (MessagingException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi gửi email reset password!",
                    ex
            );

            return false;
        }
    }
}
