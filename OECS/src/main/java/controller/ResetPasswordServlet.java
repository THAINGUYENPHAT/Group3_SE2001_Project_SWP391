package controller;

import dao.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.PasswordResetToken;
import model.User;
import service.AuditLogService;
import service.PasswordResetService;

@WebServlet(name = "ResetPasswordServlet", urlPatterns = {"/reset-password"})
public class ResetPasswordServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(ResetPasswordServlet.class.getName());

    private final PasswordResetService passwordResetService
            = new PasswordResetService();

    private final AuditLogService auditLogService
            = new AuditLogService();

    // =====================================================
    // GET - USER BẤM LINK TRONG EMAIL
    // =====================================================
    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String token = request.getParameter("token");

        if (token == null || token.trim().isEmpty()) {

            request.setAttribute(
                    "errorMessage",
                    "Liên kết đặt lại mật khẩu không hợp lệ!"
            );

            request.getRequestDispatcher("/WEB-INF/reset-password.jsp")
                    .forward(request, response);

            return;
        }

        try {

            PasswordResetToken resetToken
                    = passwordResetService.validateToken(token);

            // Token không tồn tại / hết hạn / đã sử dụng
            if (resetToken == null) {

                request.setAttribute(
                        "errorMessage",
                        "Liên kết đặt lại mật khẩu không hợp lệ "
                        + "hoặc đã hết hạn!"
                );

                request.getRequestDispatcher("/WEB-INF/reset-password.jsp")
                        .forward(request, response);

                return;
            }

            // Token hợp lệ -> gửi token sang JSP
            request.setAttribute("token", token);

            request.getRequestDispatcher("/WEB-INF/reset-password.jsp")
                    .forward(request, response);

        } catch (Exception ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi kiểm tra reset token!",
                    ex
            );

            request.setAttribute(
                    "errorMessage",
                    "Đã xảy ra lỗi. Vui lòng thử lại sau!"
            );

            request.getRequestDispatcher("/WEB-INF/reset-password.jsp")
                    .forward(request, response);
        }
    }

    // =====================================================
    // POST - ĐỔI MẬT KHẨU
    // =====================================================
    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String token = request.getParameter("token");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        // =================================================
        // 1. KIỂM TRA TOKEN
        // =================================================
        if (token == null || token.trim().isEmpty()) {

            request.setAttribute(
                    "errorMessage",
                    "Liên kết đặt lại mật khẩu không hợp lệ!"
            );

            request.getRequestDispatcher("/WEB-INF/reset-password.jsp")
                    .forward(request, response);

            return;
        }

        // =================================================
        // 2. KIỂM TRA MẬT KHẨU RỖNG
        // =================================================
        if (newPassword == null
                || newPassword.trim().isEmpty()
                || confirmPassword == null
                || confirmPassword.trim().isEmpty()) {

            request.setAttribute(
                    "errorMessage",
                    "Vui lòng nhập đầy đủ mật khẩu mới!"
            );

            request.setAttribute("token", token);

            request.getRequestDispatcher("/WEB-INF/reset-password.jsp")
                    .forward(request, response);

            return;
        }

        // =================================================
        // 3. KIỂM TRA ĐỘ DÀI
        // =================================================
        if (newPassword.length() < 6) {

            request.setAttribute(
                    "errorMessage",
                    "Mật khẩu phải có ít nhất 6 ký tự!"
            );

            request.setAttribute("token", token);

            request.getRequestDispatcher("/WEB-INF/reset-password.jsp")
                    .forward(request, response);

            return;
        }

        // =================================================
        // 4. KIỂM TRA XÁC NHẬN MẬT KHẨU
        // =================================================
        if (!newPassword.equals(confirmPassword)) {

            request.setAttribute(
                    "errorMessage",
                    "Mật khẩu xác nhận không khớp!"
            );

            request.setAttribute("token", token);

            request.getRequestDispatcher("/WEB-INF/reset-password.jsp")
                    .forward(request, response);

            return;
        }

        try {

            // =================================================
            // 5. RESET PASSWORD
            // =================================================
            PasswordResetToken resetToken
                    = passwordResetService.validateToken(token);

            if (resetToken == null) {

                request.setAttribute(
                        "errorMessage",
                        "Liên kết đặt lại mật khẩu không hợp lệ "
                        + "hoặc đã hết hạn!"
                );

                request.getRequestDispatcher(
                        "/WEB-INF/reset-password.jsp"
                ).forward(request, response);

                return;
            }

            boolean success
                    = passwordResetService.resetPassword(
                            token,
                            newPassword
                    );

            if (!success) {

                request.setAttribute(
                        "errorMessage",
                        "Liên kết đặt lại mật khẩu không hợp lệ "
                        + "hoặc đã hết hạn!"
                );

                request.getRequestDispatcher("/WEB-INF/reset-password.jsp")
                        .forward(request, response);

                return;
            }

            // =================================================
            // 6. THÀNH CÔNG -> VỀ LOGIN
            // =================================================
            HttpSession session = request.getSession();

            session.setAttribute(
                    "resetPasswordMessage",
                    "Đặt lại mật khẩu thành công. "
                    + "Bạn có thể đăng nhập bằng mật khẩu mới."
            );

            UserDAO userDAO = new UserDAO();
            User user = userDAO.getUserById(
                    resetToken.getUserId()
            );

            auditLogService.log(
                    user,
                    "RESET_PASSWORD",
                    "USER",
                    (long) user.getUserId(),
                    "Reset account password successfully",
                    request
            );

            response.sendRedirect(
                    request.getContextPath() + "/login"
            );

        } catch (Exception ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi đặt lại mật khẩu!",
                    ex
            );

            request.setAttribute(
                    "errorMessage",
                    "Đã xảy ra lỗi. Vui lòng thử lại sau!"
            );

            request.setAttribute("token", token);

            request.getRequestDispatcher("/WEB-INF/reset-password.jsp")
                    .forward(request, response);
        }
    }
}
