package controller;

import dao.UserDAO;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import service.AuditLogService;

@WebServlet(name = "LoginServlet", urlPatterns = {"/login"})
public class LoginServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(LoginServlet.class.getName());
    private final AuditLogService auditLogService = new AuditLogService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // =====================================================
            // 1. KIỂM TRA TRẠNG THÁI ĐĂNG NHẬP TRƯỚC ĐÓ
            // =====================================================
            HttpSession session = request.getSession(false);
            if (session != null
                    && session.getAttribute("loggedInUser") != null) {

                response.sendRedirect(
                        request.getContextPath() + "/home"
                );

                return;
            }

            // =====================================================
            // 2. HIỂN THỊ TRANG ĐĂNG NHẬP
            // =====================================================
            request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi tải trang đăng nhập!", e);
            request.setAttribute("errorMessage", "Có lỗi hệ thống xảy ra. Vui lòng thử lại sau!");
            request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        try {
            // =====================================================
            // 1. XÁC THỰC TÀI KHOẢN 
            // =====================================================
            UserDAO dao = new UserDAO();
            User user = dao.login(username, password);

            if (user == null) {

                auditLogService.log(
                        username,
                        "LOGIN_FAILED",
                        "USER",
                        null,
                        "Invalid username/email or password",
                        request
                );

                request.setAttribute("errorMessage", "Sai tài khoản hoặc mật khẩu.");
                request.getRequestDispatcher("/WEB-INF/login.jsp")
                        .forward(request, response);
                return;
            }

            if (!user.isActive()) {

                auditLogService.log(
                        user,
                        "LOGIN_FAILED",
                        "USER",
                        (long) user.getUserId(),
                        "Login attempt on locked account",
                        request
                );

                request.setAttribute("errorMessage", "Tài khoản đã bị khóa.");
                request.getRequestDispatcher("/WEB-INF/login.jsp")
                        .forward(request, response);
                return;
            }

            // =====================================================
            // 2. THIẾT LẬP SESSION VÀ CHUYỂN HƯỚNG
            // =====================================================
            HttpSession session = request.getSession();
            session.setAttribute("loggedInUser", user);
            auditLogService.log(
                    user,
                    "LOGIN_SUCCESS",
                    "USER",
                    (long) user.getUserId(),
                    "User logged in successfully",
                    request
            );

            String redirectUrl = (String) session.getAttribute("redirectUrl");
            if (redirectUrl != null) {
                session.removeAttribute("redirectUrl"); // Xóa sau khi dùng xong
                response.sendRedirect(redirectUrl);
            } else {
                response.sendRedirect(request.getContextPath() + "/home");
            }

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi trong quá trình xử lý đăng nhập!", e);
            request.setAttribute("errorMessage", "Hệ thống gặp sự cố trong quá trình đăng nhập!");
            request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
        }
    }
}
