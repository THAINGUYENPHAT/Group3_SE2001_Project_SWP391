package controller;

import dao.UserDAO;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.User;

@WebServlet(name = "UserManagementServlet", urlPatterns = {"/admin/users"})
public class UserManagementServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        UserDAO dao = new UserDAO();

        String action = request.getParameter("action");
        String keyword = request.getParameter("keyword");

        // Xử lý Khóa / Mở khóa tài khoản dựa trên roleId
        if ("toggleStatus".equals(action)) {
            try {
                int userId = Integer.parseInt(request.getParameter("id"));
                int currentRoleId = Integer.parseInt(request.getParameter("roleId"));
                
                // Nếu đang là User bình thường (roleId != 0) -> Khóa (set roleId = 0)
                // Nếu đang Bị khóa (roleId == 0) -> Mở khóa (set roleId = 3)
                int newRoleId = (currentRoleId == 0) ? 3 : 0;

                boolean updated = dao.updateUserRole(userId, newRoleId);
                if (updated) {
                    request.setAttribute("message", "Cập nhật trạng thái tài khoản thành công!");
                } else {
                    request.setAttribute("error", "Cập nhật trạng thái thất bại!");
                }
            } catch (NumberFormatException e) {
                request.setAttribute("error", "Dữ liệu không hợp lệ!");
            }
        }

        // Lấy danh sách người dùng
        List<User> userList = dao.getAllUsers(keyword);

        request.setAttribute("userList", userList);
        request.setAttribute("keyword", keyword);
        request.getRequestDispatcher("/WEB-INF/admin/user-management.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}