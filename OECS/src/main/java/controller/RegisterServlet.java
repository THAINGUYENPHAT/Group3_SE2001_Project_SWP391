package controller;

import dao.UserDAO;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.util.regex.Pattern;

@WebServlet(name = "RegisterServlet", urlPatterns = {"/register"})
public class RegisterServlet extends HttpServlet {

    private static final String EMAIL_REGEX = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$";
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
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

        request.setAttribute("username", username);
        request.setAttribute("email", email);
        request.setAttribute("phone", phone);
        
        if (email == null || !Pattern.matches(EMAIL_REGEX, email)) {
            request.setAttribute("errorMessage", "Email không đúng định dạng (Ví dụ: user@example.com)!");
            request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
            return;
        }
        
        // 1. Kiểm tra mật khẩu xác nhận
        if (!password.equals(confirmPassword)) {
            request.setAttribute("errorMessage", "Mật khẩu xác nhận không khớp!");
            request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
            return;
        }

        UserDAO dao = new UserDAO();

        // 2. Kiểm tra username hoặc email đã tồn tại chưa
        if (dao.checkUserExist(username, email)) {
            request.setAttribute("errorMessage", "Tên đăng nhập hoặc Email đã tồn tại!");
            request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
            return;
        }

        // 3. Thực hiện lưu vào DB (Ở đây có thể mã hóa password thành password_hash trước khi lưu)
        boolean isSuccess = dao.register(username, email, password, phone);

        if (isSuccess) {
            HttpSession session = request.getSession();
            session.setAttribute("logoutMessage", "Đăng ký tài khoản thành công! Vui lòng đăng nhập.");
            response.sendRedirect(request.getContextPath() + "/login");
        } else {
            request.setAttribute("errorMessage", "Đăng ký thất bại. Vui lòng thử lại!");
            request.getRequestDispatcher("/WEB-INF/register.jsp").forward(request, response);
        }
    }
}
