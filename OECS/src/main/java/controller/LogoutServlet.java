package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "LogoutServlet", urlPatterns = {"/logout"})
public class LogoutServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(LogoutServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processLogout(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processLogout(request, response);
    }

    /**
     * Phương thức tập trung xử lý đăng xuất người dùng
     */
    private void processLogout(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try {
            // =====================================================
            // 1. HỦY SESSION HIỆN TẠI
            // =====================================================
            HttpSession session = request.getSession(false);
            if (session != null) {
                session.invalidate();
            }

            // =====================================================
            // 2. TẠO SESSION MỚI VÀ GỬI THÔNG BÁO ĐĂNG XUẤT
            // =====================================================
            HttpSession newSession = request.getSession(true);
            newSession.setAttribute("logoutMessage", "Bạn đã đăng xuất thành công!");

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi xử lý đăng xuất người dùng!", e);
        } finally {
            // =====================================================
            // 3. CHUYỂN HƯỚNG VỀ TRANG ĐĂNG NHẬP
            // =====================================================
            response.sendRedirect(request.getContextPath() + "/login");
        }
    }
}