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

@WebServlet(name = "UserServlet", urlPatterns = {"/user"})
public class UserServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(UserServlet.class.getName());

    // =========================================================
    // CHECK LOGIN + ROLE
    // =========================================================
    private boolean checkPermission(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        HttpSession session = request.getSession(false);

        if (session == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login");
            return false;
        }

        User loggedInUser
                = (User) session.getAttribute("loggedInUser");

        if (loggedInUser == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login");
            return false;
        }

        if (!loggedInUser.isAdminOrStaff()) {
            response.sendRedirect(
                    request.getContextPath() + "/login");
            return false;
        }

        return true;
    }

    // =========================================================
    // GET
    // =========================================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        if (!checkPermission(request, response)) {
            return;
        }

        String view = request.getParameter("view");

        UserDAO dao = new UserDAO();
        HttpSession session = request.getSession();

        // =====================================================
        // LIST
        // /user
        // /user?view=list
        // =====================================================
        if (view == null || view.equals("list")) {

            String keyword = request.getParameter("keyword");

            List<User> userList
                    = dao.getAllUsers(keyword);

            request.setAttribute(
                    "userList",
                    userList);

            request.setAttribute(
                    "keyword",
                    keyword);

            request.setAttribute(
                    "message",
                    session.getAttribute("message"));

            request.setAttribute(
                    "error",
                    session.getAttribute("error"));

            session.removeAttribute("message");
            session.removeAttribute("error");

            request.getRequestDispatcher(
                    "/WEB-INF/user/list.jsp")
                    .forward(request, response);

        // =====================================================
        // CREATE
        // /user?view=create
        // =====================================================
        } else if ("create".equals(view)) {

            request.setAttribute(
                    "roleList",
                    dao.getAllRoles());

            request.getRequestDispatcher(
                    "/WEB-INF/user/create.jsp")
                    .forward(request, response);

        // =====================================================
        // EDIT
        // /user?view=edit&id=1
        // =====================================================
        } else if ("edit".equals(view)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id"));

                User selectedUser
                        = dao.getUserById(id);

                if (selectedUser == null) {

                    session.setAttribute(
                            "error",
                            "Không tìm thấy User!");

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=list");

                    return;
                }

                request.setAttribute(
                        "user",
                        selectedUser);

                request.setAttribute(
                        "roleList",
                        dao.getAllRoles());

                request.getRequestDispatcher(
                        "/WEB-INF/user/edit.jsp")
                        .forward(request, response);

            } catch (NumberFormatException e) {

                LOGGER.log(
                        Level.WARNING,
                        "ID không hợp lệ khi mở Edit User",
                        e);

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list");
            }

        // =====================================================
        // DELETE
        // /user?view=delete&id=1
        // =====================================================
        } else if ("delete".equals(view)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id"));

                User selectedUser
                        = dao.getUserById(id);

                if (selectedUser == null) {

                    session.setAttribute(
                            "error",
                            "Không tìm thấy User!");

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=list");

                    return;
                }

                request.setAttribute(
                        "user",
                        selectedUser);

                request.getRequestDispatcher(
                        "/WEB-INF/user/delete.jsp")
                        .forward(request, response);

            } catch (NumberFormatException e) {

                LOGGER.log(
                        Level.WARNING,
                        "ID không hợp lệ khi mở Delete User",
                        e);

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list");
            }

        } else {

            response.sendRedirect(
                    request.getContextPath()
                    + "/user?view=list");
        }
    }

    // =========================================================
    // POST
    // =========================================================
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        if (!checkPermission(request, response)) {
            return;
        }

        String action = request.getParameter("action");

        UserDAO dao = new UserDAO();
        HttpSession session = request.getSession();

        // =====================================================
        // CREATE
        // =====================================================
        if ("create".equals(action)) {

            String username
                    = request.getParameter("username");

            String email
                    = request.getParameter("email");

            String password
                    = request.getParameter("password");

            String phone
                    = request.getParameter("phone");

            String roleIdParam
                    = request.getParameter("roleId");

            username = username != null
                    ? username.trim()
                    : "";

            email = email != null
                    ? email.trim()
                    : "";

            password = password != null
                    ? password.trim()
                    : "";

            phone = phone != null
                    ? phone.trim()
                    : "";

            try {

                if (username.isEmpty()
                        || email.isEmpty()
                        || password.isEmpty()
                        || roleIdParam == null
                        || roleIdParam.isEmpty()) {

                    session.setAttribute(
                            "error",
                            "Vui lòng nhập đầy đủ thông tin!");

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=create");

                    return;
                }

                int roleId
                        = Integer.parseInt(roleIdParam);

                if (dao.checkUserExist(
                        username,
                        email)) {

                    session.setAttribute(
                            "error",
                            "Username hoặc Email đã tồn tại!");

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=create");

                    return;
                }

                User newUser = new User();

                newUser.setUsername(username);
                newUser.setEmail(email);
                newUser.setPhone(phone);
                newUser.setRoleId(roleId);

                boolean success
                        = dao.createUser(
                                newUser,
                                password);

                if (success) {

                    session.setAttribute(
                            "message",
                            "Tạo User thành công!");

                } else {

                    session.setAttribute(
                            "error",
                            "Tạo User thất bại!");
                }

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list");

            } catch (Exception e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi khi thêm User!",
                        e);

                session.setAttribute(
                        "error",
                        "Lỗi khi tạo User!");

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=create");
            }

        // =====================================================
        // EDIT
        // =====================================================
        } else if ("edit".equals(action)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id"));

                String username
                        = request.getParameter("username");

                String email
                        = request.getParameter("email");

                String password
                        = request.getParameter("password");

                String phone
                        = request.getParameter("phone");

                int roleId = Integer.parseInt(
                        request.getParameter("roleId"));

                username = username != null
                        ? username.trim()
                        : "";

                email = email != null
                        ? email.trim()
                        : "";

                password = password != null
                        ? password.trim()
                        : "";

                phone = phone != null
                        ? phone.trim()
                        : "";

                if (username.isEmpty()
                        || email.isEmpty()) {

                    session.setAttribute(
                            "error",
                            "Username và Email không được để trống!");

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=edit&id="
                            + id);

                    return;
                }

                if (dao.checkUserExistForUpdate(
                        id,
                        username,
                        email)) {

                    session.setAttribute(
                            "error",
                            "Username hoặc Email đã tồn tại!");

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=edit&id="
                            + id);

                    return;
                }

                User user
                        = dao.getUserById(id);

                if (user == null) {

                    session.setAttribute(
                            "error",
                            "Không tìm thấy User!");

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=list");

                    return;
                }

                user.setUsername(username);
                user.setEmail(email);
                user.setPhone(phone);
                user.setRoleId(roleId);

                boolean success
                        = dao.updateUser(
                                user,
                                password);

                if (success) {

                    session.setAttribute(
                            "message",
                            "Cập nhật User thành công!");

                } else {

                    session.setAttribute(
                            "error",
                            "Cập nhật User thất bại!");
                }

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list");

            } catch (Exception e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi khi cập nhật User!",
                        e);

                session.setAttribute(
                        "error",
                        "Lỗi khi cập nhật User!");

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list");
            }

        // =====================================================
        // DELETE
        // =====================================================
        } else if ("delete".equals(action)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id"));

                User loggedInUser
                        = (User) session.getAttribute(
                                "loggedInUser");

                // Không cho tự xóa tài khoản đang đăng nhập
                if (loggedInUser != null
                        && loggedInUser.getUserId() == id) {

                    session.setAttribute(
                            "error",
                            "Không thể xóa tài khoản đang đăng nhập!");

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=list");

                    return;
                }

                boolean success
                        = dao.deleteUser(id);

                if (success) {

                    session.setAttribute(
                            "message",
                            "Xóa User thành công!");

                } else {

                    session.setAttribute(
                            "error",
                            "Xóa User thất bại! User có thể đang được sử dụng.");
                }

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list");

            } catch (Exception e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi khi xóa User!",
                        e);

                session.setAttribute(
                        "error",
                        "Lỗi khi xóa User!");

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list");
            }

        } else {

            response.sendRedirect(
                    request.getContextPath()
                    + "/user?view=list");
        }
    }
}