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

@WebServlet(name = "LoginServlet", urlPatterns = {"/login"})
public class LoginServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(LoginServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // =====================================================
            // 1. KIỂM TRA TRẠNG THÁI ĐĂNG NHẬP TRƯỚC ĐÓ
            // =====================================================
            HttpSession session = request.getSession(false);
            if (session != null && session.getAttribute("loggedInUser") != null) {
                User user = (User) session.getAttribute("loggedInUser");

                // Nếu tài khoản trong session bị khóa (roleId == 0) -> Hủy session
                if (user.getRoleId() == 0) {
                    session.invalidate();
                    request.setAttribute("errorMessage", "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ Admin!");
                    request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
                    return;
                }

                redirectByUserRole(request, response, user);
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
            // 1. XÁC THỰC TÀI KHOẢN VÀ MẬT KHẨU
            // =====================================================
            UserDAO dao = new UserDAO();
            User user = dao.login(username, password);

            if (user == null) {
                request.setAttribute("errorMessage", "Tên đăng nhập hoặc mật khẩu không chính xác!");
                request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
                return;
            }

            // =====================================================
            // 2. KIỂM TRA TÀI KHOẢN BỊ KHÓA (roleId == 0)
            // =====================================================
            if (user.getRoleId() == 0) {
                request.setAttribute("errorMessage", "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ Admin!");
                request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
                return;
            }

            // =====================================================
            // 3. THIẾT LẬP SESSION VÀ CHUYỂN HƯỚNG
            // =====================================================
            HttpSession session = request.getSession();
            session.setAttribute("loggedInUser", user);

            String redirectUrl = (String) session.getAttribute("redirectUrl");
            if (redirectUrl != null) {
                session.removeAttribute("redirectUrl"); // Xóa sau khi dùng xong
                response.sendRedirect(redirectUrl);
            } else {
                redirectByUserRole(request, response, user);
            }

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi trong quá trình xử lý đăng nhập!", e);
            request.setAttribute("errorMessage", "Hệ thống gặp sự cố trong quá trình đăng nhập!");
            request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
        }
    }

    /**
     * Phương thức phụ trợ giúp chuyển hướng người dùng tới trang phù hợp dựa theo Vai trò
     */
    private void redirectByUserRole(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {
        if (user.isAdminOrStaff()) {
            // Chuyển hướng đến trang quản trị dành cho Admin/Staff
            response.sendRedirect(request.getContextPath() + "/admin/voucher");
        } else {
            // Chuyển hướng về trang chủ dành cho Customer
            response.sendRedirect(request.getContextPath() + "/home");
        }
    }
}