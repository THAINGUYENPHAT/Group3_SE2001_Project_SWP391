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
import java.util.regex.Pattern;

@WebServlet(name = "ProfileServlet", urlPatterns = {"/profile"})
public class ProfileServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(ProfileServlet.class.getName());

    // Regex kiểm tra định dạng email
    private static final String EMAIL_REGEX = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            HttpSession session = request.getSession(false);
            User user = (session != null) ? (User) session.getAttribute("loggedInUser") : null;

            if (user == null) {
                response.sendRedirect(request.getContextPath() + "/login");
                return;
            }

            request.getRequestDispatcher("/WEB-INF/profile.jsp").forward(request, response);

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi hiển thị trang Profile!", e);
            response.sendRedirect(request.getContextPath() + "/home");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("loggedInUser") : null;

        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        UserDAO dao = new UserDAO();

        try {
            if ("updateProfile".equals(action)) {
                // ========================================================
                // 1. XỬ LÝ CẬP NHẬT HỒ SƠ (PROFILE)
                // ========================================================
                // Trong doPost() -> if ("updateProfile".equals(action))
                String email = request.getParameter("email");
                String phone = request.getParameter("phone");
                String address = request.getParameter("address");

                // Validation Email...
                if (email == null || !Pattern.matches(EMAIL_REGEX, email.trim())) {
                    request.setAttribute("profileError", "Email không đúng định dạng!");
                    request.getRequestDispatcher("/WEB-INF/profile.jsp").forward(request, response);
                    return;
                }

                // Check Email trùng...
                if (!email.trim().equalsIgnoreCase(user.getEmail())) {
                    if (dao.checkUserExist("", email.trim())) {
                        request.setAttribute("profileError", "Email này đã được sử dụng!");
                        request.getRequestDispatcher("/WEB-INF/profile.jsp").forward(request, response);
                        return;
                    }
                }

                // Cập nhật Profile vào DB
                boolean isUpdated = dao.updateProfile(user.getUserId(), email.trim(), phone, address, user.getUsername());

                if (isUpdated) {
                    user.setEmail(email.trim());
                    user.setPhone(phone);
                    user.setAddress(address != null ? address.trim() : "");
                    session.setAttribute("loggedInUser", user);

                    request.setAttribute("profileSuccess", "Cập nhật thông tin cá nhân thành công!");
                } else {
                    request.setAttribute("profileError", "Cập nhật thất bại, vui lòng thử lại!");
                }

            } else if ("changePassword".equals(action)) {
                // ========================================================
                // 2. XỬ LÝ ĐỔI MẬT KHẨU (CHANGE PASSWORD)
                // ========================================================
                String oldPassword = request.getParameter("oldPassword");
                String newPassword = request.getParameter("newPassword");
                String confirmPassword = request.getParameter("confirmPassword");

                if (newPassword == null || confirmPassword == null || !newPassword.equals(confirmPassword)) {
                    request.setAttribute("pwdError", "Mật khẩu mới và Mật khẩu xác nhận không trùng khớp!");
                } else if (newPassword.length() < 6) {
                    request.setAttribute("pwdError", "Mật khẩu mới phải có ít nhất 6 ký tự!");
                } else {
                    boolean isPwdChanged = dao.changePassword(user.getUserId(), oldPassword, newPassword);

                    if (isPwdChanged) {
                        request.setAttribute("pwdSuccess", "Đổi mật khẩu thành công!");
                    } else {
                        request.setAttribute("pwdError", "Mật khẩu hiện tại không chính xác!");
                    }
                }
            }

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi xử lý thông tin Profile!", e);
            request.setAttribute("profileError", "Có lỗi hệ thống xảy ra. Vui lòng thử lại sau!");
        }

        request.getRequestDispatcher("/WEB-INF/profile.jsp").forward(request, response);
    }
}
