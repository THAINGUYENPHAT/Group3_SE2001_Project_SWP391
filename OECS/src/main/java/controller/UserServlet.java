package controller;

import dao.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;
import service.AuditLogService;

import java.io.IOException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

import service.EmailService;
import service.PasswordResetService;

@WebServlet(name = "UserServlet", urlPatterns = {"/user"})
public class UserServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(UserServlet.class.getName());

    private final AuditLogService auditLogService = new AuditLogService();
    private final PasswordResetService passwordResetService = new PasswordResetService();
    private final EmailService emailService = new EmailService();

    private boolean checkPermission(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        HttpSession session = request.getSession(false);

        if (session == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return false;
        }

        User loggedInUser = (User) session.getAttribute("loggedInUser");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return false;
        }

        if (!loggedInUser.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/home");
            return false;
        }

        return true;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        if (!checkPermission(request, response)) {
            return;
        }

        String view = request.getParameter("view");

        UserDAO dao = new UserDAO();
        HttpSession session = request.getSession();

        if (view == null || "list".equals(view)) {

            String keyword = request.getParameter("keyword");

            String role = request.getParameter("role");

            String status = request.getParameter("status");

            String sort = request.getParameter("sort");

            keyword = keyword != null
                    ? keyword.trim()
                    : "";

            role = role != null
                    ? role.trim()
                    : "";

            status = status != null
                    ? status.trim()
                    : "";

            sort = sort != null
                    ? sort.trim()
                    : "newest";

            List<User> userList
                    = dao.getAllUsers(
                            keyword,
                            role,
                            status,
                            sort
                    );

            request.setAttribute(
                    "userList",
                    userList
            );

            request.setAttribute(
                    "keyword",
                    keyword
            );

            request.setAttribute(
                    "role",
                    role
            );

            request.setAttribute(
                    "status",
                    status
            );

            request.setAttribute(
                    "sort",
                    sort
            );
            request.setAttribute("keyword", keyword);
            request.setAttribute("message", session.getAttribute("message"));
            request.setAttribute("error", session.getAttribute("error"));

            session.removeAttribute("message");
            session.removeAttribute("error");

            request.getRequestDispatcher("/WEB-INF/user/list.jsp").forward(request, response);

        } else if ("create".equals(view)) {

            request.setAttribute("roleList", dao.getAllRoles());

            request.getRequestDispatcher("/WEB-INF/user/create.jsp").forward(request, response);

        } else {

            response.sendRedirect(request.getContextPath() + "/user?view=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        if (!checkPermission(request, response)) {
            return;
        }

        String action = request.getParameter("action");

        UserDAO dao = new UserDAO();
        HttpSession session = request.getSession();

        if ("create".equals(action)) {

            String username = request.getParameter("username");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String roleIdParam = request.getParameter("roleId");

            username = username != null ? username.trim() : "";
            email = email != null ? email.trim() : "";
            phone = phone != null ? phone.trim() : "";

            try {

                if (username.isEmpty()
                        || email.isEmpty()
                        || roleIdParam == null
                        || roleIdParam.isEmpty()) {

                    session.setAttribute("error", "Vui lòng nhập đầy đủ thông tin!");

                    response.sendRedirect(request.getContextPath() + "/user?view=create");
                    return;
                }

                int roleId = Integer.parseInt(roleIdParam);

                if (dao.checkUserExist(username, email)) {

                    session.setAttribute("error", "Username hoặc Email đã tồn tại!");

                    response.sendRedirect(request.getContextPath() + "/user?view=create");
                    return;
                }

                User newUser = new User();

                newUser.setUsername(username);
                newUser.setEmail(email);
                newUser.setPhone(phone);
                newUser.setRoleId(roleId);

                String temporaryPassword = UUID.randomUUID().toString()
                        + UUID.randomUUID().toString();

                boolean success = dao.createUser(newUser, temporaryPassword);

                if (!success) {

                    session.setAttribute("error", "Tạo tài khoản thất bại!");

                    response.sendRedirect(request.getContextPath() + "/user?view=create");
                    return;
                }

                User createdUser = dao.findByEmail(email);

                String token = passwordResetService.createResetToken(email, 24 * 60);

                boolean emailSent = false;

                if (token != null) {

                    String setupLink = buildResetLink(request, token);

                    emailSent = emailService.sendAccountSetupEmail(email, setupLink);
                }

                if (emailSent) {

                    session.setAttribute(
                            "message",
                            "Tạo tài khoản thành công! "
                            + "Liên kết thiết lập mật khẩu "
                            + "đã được gửi đến email người dùng."
                    );

                } else {

                    session.setAttribute(
                            "message",
                            "Tài khoản đã được tạo, "
                            + "nhưng không thể gửi email "
                            + "thiết lập mật khẩu."
                    );
                }

                User loggedInUser = (User) session.getAttribute("loggedInUser");

                Long createdUserId = createdUser != null
                        ? (long) createdUser.getUserId()
                        : null;

                auditLogService.log(
                        loggedInUser,
                        "CREATE_USER",
                        "USER",
                        createdUserId,
                        "Created new user account: " + username,
                        request
                );

                response.sendRedirect(request.getContextPath() + "/user?view=list");
                return;

            } catch (Exception e) {

                LOGGER.log(Level.SEVERE, "Lỗi khi tạo User!", e);

                session.setAttribute("error", "Lỗi khi tạo tài khoản!");

                response.sendRedirect(request.getContextPath() + "/user?view=create");
                return;
            }

        } else if ("toggleStatus".equals(action)) {

            try {

                int id = Integer.parseInt(request.getParameter("id"));

                boolean active = Boolean.parseBoolean(request.getParameter("active"));

                User loggedInUser = (User) session.getAttribute("loggedInUser");

                if (loggedInUser != null && loggedInUser.getUserId() == id) {

                    session.setAttribute("error", "Không thể khóa tài khoản "
                            + "đang đăng nhập!");

                    response.sendRedirect(request.getContextPath() + "/user?view=list");
                    return;
                }

                User selectedUser = dao.getUserById(id);

                if (selectedUser == null) {

                    session.setAttribute("error", "Không tìm thấy tài khoản!");

                    response.sendRedirect(request.getContextPath() + "/user?view=list");
                    return;
                }

                boolean success = dao.updateUserStatus(id, active);

                if (success) {

                    if (active) {

                        session.setAttribute("message", "Mở khóa tài khoản thành công!");

                        auditLogService.log(
                                loggedInUser,
                                "UNLOCK_USER",
                                "USER",
                                (long) id,
                                "Unlocked user account: " + selectedUser.getUsername(),
                                request
                        );

                    } else {

                        session.setAttribute("message", "Khóa tài khoản thành công!");

                        auditLogService.log(
                                loggedInUser,
                                "LOCK_USER",
                                "USER",
                                (long) id,
                                "Locked user account: " + selectedUser.getUsername(),
                                request
                        );
                    }

                } else {

                    session.setAttribute("error", "Cập nhật trạng thái tài khoản thất bại!");
                }

                response.sendRedirect(request.getContextPath() + "/user?view=list");

            } catch (Exception e) {

                LOGGER.log(Level.SEVERE, "Lỗi cập nhật trạng thái User!", e);

                session.setAttribute("error", "Lỗi khi cập nhật trạng thái tài khoản!");

                response.sendRedirect(request.getContextPath() + "/user?view=list");
            }

        } else {

            response.sendRedirect(request.getContextPath() + "/user?view=list");
        }
    }

    private String buildResetLink(HttpServletRequest request, String token) {

        StringBuilder url = new StringBuilder();

        url.append(request.getScheme())
                .append("://")
                .append(request.getServerName());

        int port = request.getServerPort();

        boolean defaultHttpPort = request.getScheme().equals("http")
                && port == 80;

        boolean defaultHttpsPort = request.getScheme().equals("https")
                && port == 443;

        if (!defaultHttpPort && !defaultHttpsPort) {
            url.append(":").append(port);
        }

        url.append(request.getContextPath())
                .append("/reset-password?token=")
                .append(
                        URLEncoder.encode(
                                token,
                                StandardCharsets.UTF_8
                        )
                );

        return url.toString();
    }
}
