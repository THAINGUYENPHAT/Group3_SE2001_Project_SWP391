package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.logging.Level;
import java.util.logging.Logger;
import service.EmailService;
import service.PasswordResetService;

@WebServlet(name = "ForgotPasswordServlet", urlPatterns = {"/forgot-password"})
public class ForgotPasswordServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(ForgotPasswordServlet.class.getName());

    private final PasswordResetService passwordResetService
            = new PasswordResetService();

    private final EmailService emailService
            = new EmailService();

    // =====================================================
    // GET - HIỂN THỊ FORM QUÊN MẬT KHẨU
    // =====================================================
    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.getRequestDispatcher("/WEB-INF/forgot-password.jsp")
                .forward(request, response);
    }

    // =====================================================
    // POST - XỬ LÝ YÊU CẦU QUÊN MẬT KHẨU
    // =====================================================
    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String email = request.getParameter("email");

        // Kiểm tra email rỗng
        if (email == null || email.trim().isEmpty()) {

            request.setAttribute(
                    "errorMessage",
                    "Vui lòng nhập email!"
            );

            request.getRequestDispatcher("/WEB-INF/forgot-password.jsp")
                    .forward(request, response);

            return;
        }

        email = email.trim();

        try {
            // Kiểm tra email tồn tại trong hệ thống
            if (!emailService.emailExists(email)) {
                request.setAttribute(
                        "errorMessage",
                        "Email chưa được đăng ký trong hệ thống"
                );

                request.getRequestDispatcher("/WEB-INF/forgot-password.jsp")
                        .forward(request, response);
                return;

            }

            try {

                // =================================================
                // 1. TẠO RESET TOKEN
                // =================================================
                String token
                        = passwordResetService.createResetToken(email);

                if (token != null) {

                    // =============================================
                    // 2. TẠO LINK RESET PASSWORD
                    // =============================================
                    String resetLink = buildResetLink(
                            request,
                            token
                    );

                    // =============================================
                    // 3. GỬI EMAIL
                    // =============================================
                    boolean sent
                            = emailService.sendResetPasswordEmail(
                                    email,
                                    resetLink
                            );

                    if (!sent) {
                        LOGGER.log(
                                Level.WARNING,
                                "Không thể gửi email reset password tới: {0}",
                                email);
                        request.getRequestDispatcher("/WEB-INF/forgot-password.jsp")
                                .forward(request, response);

                        return;
                    }

                }
                // =============================================
                // 4. GỬI EMAIL THÀNH CÔNG
                // =============================================
                request.setAttribute(
                        "successMessage",
                        "Nếu email tồn tại trong hệ thống, "
                        + "Liên kết đặt lại mật khẩu đã được gửi đến email của bạn."
                );

                request.getRequestDispatcher("/WEB-INF/forgot-password.jsp")
                        .forward(request, response);

            } catch (Exception ex) {

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi xử lý quên mật khẩu!",
                        ex
                );

                request.setAttribute(
                        "errorMessage",
                        "Đã xảy ra lỗi. Vui lòng thử lại sau!"
                );

                request.getRequestDispatcher("/WEB-INF/forgot-password.jsp")
                        .forward(request, response);
            }
        } catch (Exception ex) {
            Logger.getLogger(ForgotPasswordServlet.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    // =====================================================
    // TẠO ĐƯỜNG LINK RESET PASSWORD
    // =====================================================
    private String buildResetLink(
            HttpServletRequest request,
            String token) {

        StringBuilder url = new StringBuilder();

        url.append(request.getScheme())
                .append("://")
                .append(request.getServerName());

        int port = request.getServerPort();

        boolean defaultHttpPort
                = request.getScheme().equals("http")
                && port == 80;

        boolean defaultHttpsPort
                = request.getScheme().equals("https")
                && port == 443;

        if (!defaultHttpPort && !defaultHttpsPort) {
            url.append(":").append(port);
        }

        url.append(request.getContextPath())
                .append("/reset-password?token=")
                .append(
                        URLEncoder.encode(
                                token,
                                StandardCharsets.UTF_8
                        )
                );

        return url.toString();
    }
}
