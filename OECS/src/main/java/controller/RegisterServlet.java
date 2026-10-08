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

@WebServlet(name = "RegisterServlet", urlPatterns = {"/register"})
public class RegisterServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(RegisterServlet.class.getName());

    // Regex kiểm tra định dạng email
    private static final String EMAIL_REGEX = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$";
    private static final String PHONE_REGEX = "^0\\d{8,9}$";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // =====================================================
            // 1. KIỂM TRA ĐĂNG NHẬP TRƯỚC ĐÓ
            // =====================================================
            HttpSession session = request.getSession(false);
            if (session != null && session.getAttribute("loggedInUser") != null) {
                User user = (User) session.getAttribute("loggedInUser");
                if (user.isAdminOrStaff()) {
                    response.sendRedirect(request.getContextPath() + "/admin/voucher");
                } else {
                    response.sendRedirect(request.getContextPath() + "/home");
                }
                return;
            }

            // =====================================================
            // 2. HIỂN THỊ TRANG ĐĂNG KÝ
            // =====================================================
            request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi hiển thị trang đăng ký!", e);
            response.sendRedirect(request.getContextPath() + "/login");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");

        // Giữ lại dữ liệu đã nhập trên form khi có lỗi
        request.setAttribute("username", username);
        request.setAttribute("email", email);
        request.setAttribute("phone", phone);

        try {
            // =====================================================
            // 1. VALIDATION ĐỊNH DẠNG DỮ LIỆU
            // =====================================================
            if (email == null || !Pattern.matches(EMAIL_REGEX, email.trim())) {
                request.setAttribute("errorMessage", "Email không đúng định dạng (Ví dụ: user@example.com)!");
                request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
                return;
            }

            if (phone == null || !Pattern.matches(PHONE_REGEX, phone.trim())) {
                request.setAttribute(
                        "errorMessage",
                        "Số điện thoại phải gồm 9-10 chữ số và bắt đầu bằng 0!"
                );
                request.getRequestDispatcher("/WEB-INF/register.jsp")
                        .forward(request, response);
                return;
            }

            if (password == null || confirmPassword == null || !password.equals(confirmPassword)) {
                request.setAttribute("errorMessage", "Mật khẩu xác nhận không khớp!");
                request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
                return;
            }

            if (password.length() < 6) {
                request.setAttribute("errorMessage", "Mật khẩu phải chứa ít nhất 6 ký tự!");
                request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
                return;
            }

            // =====================================================
            // 2. KIỂM TRA TRÙNG LẶP USERNAME / EMAIL
            // =====================================================
            UserDAO dao = new UserDAO();
            if (dao.checkUserExist(username, email.trim())) {
                request.setAttribute("errorMessage", "Tên đăng nhập hoặc Email đã tồn tại!");
                request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
                return;
            }

            // =====================================================
            // 3. THỰC THI ĐĂNG KÝ VÀO DB
            // =====================================================
            boolean isSuccess = dao.register(username, email.trim(), password, phone.trim());

            if (isSuccess) {
                HttpSession session = request.getSession();
                session.setAttribute("logoutMessage", "Đăng ký tài khoản thành công! Vui lòng đăng nhập.");
                response.sendRedirect(request.getContextPath() + "/login");
            } else {
                request.setAttribute("errorMessage", "Đăng ký thất bại. Vui lòng thử lại!");
                request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
            }

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi xử lý đăng ký người dùng!", e);
            request.setAttribute("errorMessage", "Có lỗi hệ thống xảy ra. Vui lòng thử lại sau!");
            request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
        }
    }
}
