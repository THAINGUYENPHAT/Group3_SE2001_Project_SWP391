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
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "UserManagementServlet", urlPatterns = {"/admin/users"})
public class UserManagementServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(UserManagementServlet.class.getName());

    // =====================================================
    // GET - HIỂN THỊ DANH SÁCH & LỌC TÌM KIẾM
    // =====================================================
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();

        // Check đăng nhập & phân quyền Admin
        User loggedInUser = (User) session.getAttribute("loggedInUser");
        if (loggedInUser == null || !loggedInUser.isAdminOrStaff()) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        try {
            UserDAO dao = new UserDAO();
            String keyword = request.getParameter("keyword");

            List<User> userList = dao.getAllUsers(keyword);

            request.setAttribute("userList", userList);
            request.setAttribute("keyword", keyword);
            request.getRequestDispatcher("/WEB-INF/admin/user-management.jsp").forward(request, response);

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi lấy danh sách người dùng quản trị!", e);
            request.setAttribute("error", "Có lỗi hệ thống xảy ra khi tải danh sách người dùng.");
            request.getRequestDispatcher("/WEB-INF/admin/user-management.jsp").forward(request, response);
        }
    }

    // =====================================================
    // POST - XỬ LÝ KHÓA / MỞ KHÓA TÀI KHOẢN (TOGGLE STATUS)
    // =====================================================
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();

        // Check đăng nhập & phân quyền Admin
        User loggedInUser = (User) session.getAttribute("loggedInUser");
        if (loggedInUser == null || !loggedInUser.isAdminOrStaff()) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");

        if ("toggleStatus".equals(action)) {
            try {
                int userId = Integer.parseInt(request.getParameter("id"));
                int currentRoleId = Integer.parseInt(request.getParameter("roleId"));

                // Không cho phép Admin tự khóa chính mình
                if (loggedInUser.getUserId() == userId) {
                    session.setAttribute("error", "Bạn không thể tự khóa tài khoản của chính mình!");
                    response.sendRedirect(request.getContextPath() + "/admin/users");
                    return;
                }

                // Nếu đang là User bình thường (roleId != 0) -> Khóa (set roleId = 0)
                // Nếu đang bị khóa (roleId == 0) -> Mở khóa (set roleId = 3)
                int newRoleId = (currentRoleId == 0) ? 3 : 0;

                UserDAO dao = new UserDAO();
                boolean updated = dao.updateUserRole(userId, newRoleId);

                if (updated) {
                    session.setAttribute("message", "Cập nhật trạng thái tài khoản thành công!");
                } else {
                    session.setAttribute("error", "Cập nhật trạng thái thất bại!");
                }

            } catch (NumberFormatException e) {
                LOGGER.log(Level.WARNING, "Tham số ID hoặc RoleId không đúng định dạng số!", e);
                session.setAttribute("error", "Dữ liệu yêu cầu không hợp lệ!");
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi hệ thống khi thay đổi trạng thái người dùng!", e);
                session.setAttribute("error", "Có lỗi hệ thống xảy ra khi cập nhật trạng thái người dùng.");
            }
        }

        response.sendRedirect(request.getContextPath() + "/admin/users");
    }
}