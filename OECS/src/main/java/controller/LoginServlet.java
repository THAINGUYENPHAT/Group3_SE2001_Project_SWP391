package controller;

import dao.UserDAO;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;

@WebServlet(name = "LoginServlet", urlPatterns = {"/login"})
public class LoginServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Nếu đã đăng nhập rồi thì không cần hiển thị trang login nữa
        HttpSession session = request.getSession(false);
        if (session != null && session.getAttribute("loggedInUser") != null) {
            User user = (User) session.getAttribute("loggedInUser");
            redirectByUserRole(request, response, user);
            return;
        }

        request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        UserDAO dao = new UserDAO();
        User user = dao.login(username, password);

        if (user == null) {
            request.setAttribute("errorMessage", "Tên đăng nhập hoặc mật khẩu không chính xác!");
            request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
        } else {
            HttpSession session = request.getSession();
            
            // 1. Lưu thông tin User (đã kèm roleId và roleName) vào Session
            session.setAttribute("loggedInUser", user);

            // 2. Kiểm tra xem trước đó user có bị AuthFilter chặn khi truy cập 1 URL cụ thể không
            String redirectUrl = (String) session.getAttribute("redirectUrl");
            if (redirectUrl != null) {
                session.removeAttribute("redirectUrl"); // Xóa sau khi dùng xong
                response.sendRedirect(redirectUrl);
            } else {
                // 3. Nếu đăng nhập bình thường -> Chuyển hướng theo Role
                redirectByUserRole(request, response, user);
            }
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