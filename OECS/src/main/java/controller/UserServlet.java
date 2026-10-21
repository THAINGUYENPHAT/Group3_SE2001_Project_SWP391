package controller;

import dao.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;

import java.io.IOException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "UserServlet", urlPatterns = {"/user"})
public class UserServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(UserServlet.class.getName());

    // =====================================================
    // CHECK PERMISSION - ADMIN ONLY
    // =====================================================
    private boolean checkPermission(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        HttpSession session = request.getSession(false);

        if (session == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login"
            );
            return false;
        }

        User loggedInUser
                = (User) session.getAttribute("loggedInUser");

        if (loggedInUser == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login"
            );
            return false;
        }

        if (!loggedInUser.isAdmin()) {
            response.sendRedirect(
                    request.getContextPath() + "/home"
            );
            return false;
        }

        return true;
    }

    // =====================================================
    // GET
    // =====================================================
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

        // =================================================
        // LIST USER
        // =================================================
        if (view == null || "list".equals(view)) {

            String keyword = request.getParameter("keyword");

            List<User> userList
                    = dao.getAllUsers(keyword);

            request.setAttribute(
                    "userList",
                    userList
            );

            request.setAttribute(
                    "keyword",
                    keyword
            );

            request.setAttribute(
                    "message",
                    session.getAttribute("message")
            );

            request.setAttribute(
                    "error",
                    session.getAttribute("error")
            );

            session.removeAttribute("message");
            session.removeAttribute("error");

            request.getRequestDispatcher(
                    "/WEB-INF/user/list.jsp"
            ).forward(request, response);

        // =================================================
        // CREATE USER
        // =================================================
        } else if ("create".equals(view)) {

            request.setAttribute(
                    "roleList",
                    dao.getAllRoles()
            );

            request.getRequestDispatcher(
                    "/WEB-INF/user/create.jsp"
            ).forward(request, response);

        // =================================================
        // MANAGE ROLE
        // =================================================
        } else if ("role".equals(view)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                User selectedUser
                        = dao.getUserById(id);

                if (selectedUser == null) {

                    session.setAttribute(
                            "error",
                            "Không tìm thấy tài khoản!"
                    );

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=list"
                    );

                    return;
                }

                request.setAttribute(
                        "user",
                        selectedUser
                );

                request.setAttribute(
                        "roleList",
                        dao.getAllRoles()
                );

                request.getRequestDispatcher(
                        "/WEB-INF/user/role.jsp"
                ).forward(request, response);

            } catch (NumberFormatException e) {

                LOGGER.log(
                        Level.WARNING,
                        "ID User không hợp lệ!",
                        e
                );

                session.setAttribute(
                        "error",
                        "ID tài khoản không hợp lệ!"
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list"
                );
            }

        } else {

            response.sendRedirect(
                    request.getContextPath()
                    + "/user?view=list"
            );
        }
    }

    // =====================================================
    // POST
    // =====================================================
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

        // =================================================
        // CREATE USER
        // =================================================
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

            phone = phone != null
                    ? phone.trim()
                    : "";

            try {

                if (username.isEmpty()
                        || email.isEmpty()
                        || password == null
                        || password.isEmpty()
                        || roleIdParam == null
                        || roleIdParam.isEmpty()) {

                    session.setAttribute(
                            "error",
                            "Vui lòng nhập đầy đủ thông tin!"
                    );

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=create"
                    );

                    return;
                }

                int roleId
                        = Integer.parseInt(roleIdParam);

                if (dao.checkUserExist(
                        username,
                        email)) {

                    session.setAttribute(
                            "error",
                            "Username hoặc Email đã tồn tại!"
                    );

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=create"
                    );

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
                                password
                        );

                if (success) {

                    session.setAttribute(
                            "message",
                            "Tạo tài khoản thành công!"
                    );

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=list"
                    );

                } else {

                    session.setAttribute(
                            "error",
                            "Tạo tài khoản thất bại!"
                    );

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=create"
                    );
                }

            } catch (Exception e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi khi tạo User!",
                        e
                );

                session.setAttribute(
                        "error",
                        "Lỗi khi tạo tài khoản!"
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=create"
                );
            }

        // =================================================
        // UPDATE ROLE
        // =================================================
        } else if ("updateRole".equals(action)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                int roleId = Integer.parseInt(
                        request.getParameter("roleId")
                );

                User loggedInUser
                        = (User) session.getAttribute(
                                "loggedInUser"
                        );

                // Không cho Admin tự đổi role của mình
                if (loggedInUser != null
                        && loggedInUser.getUserId() == id) {

                    session.setAttribute(
                            "error",
                            "Không thể thay đổi quyền "
                            + "của tài khoản đang đăng nhập!"
                    );

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=list"
                    );

                    return;
                }

                User selectedUser
                        = dao.getUserById(id);

                if (selectedUser == null) {

                    session.setAttribute(
                            "error",
                            "Không tìm thấy tài khoản!"
                    );

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=list"
                    );

                    return;
                }

                boolean success
                        = dao.updateUserRole(
                                id,
                                roleId
                        );

                if (success) {

                    session.setAttribute(
                            "message",
                            "Cập nhật quyền tài khoản thành công!"
                    );

                } else {

                    session.setAttribute(
                            "error",
                            "Cập nhật quyền tài khoản thất bại!"
                    );
                }

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list"
                );

            } catch (Exception e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi cập nhật Role!",
                        e
                );

                session.setAttribute(
                        "error",
                        "Lỗi khi cập nhật quyền tài khoản!"
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list"
                );
            }

        // =================================================
        // LOCK / UNLOCK ACCOUNT
        // =================================================
        } else if ("toggleStatus".equals(action)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                boolean active
                        = Boolean.parseBoolean(
                                request.getParameter("active")
                        );

                User loggedInUser
                        = (User) session.getAttribute(
                                "loggedInUser"
                        );

                // Không cho Admin tự khóa chính mình
                if (loggedInUser != null
                        && loggedInUser.getUserId() == id) {

                    session.setAttribute(
                            "error",
                            "Không thể khóa tài khoản "
                            + "đang đăng nhập!"
                    );

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=list"
                    );

                    return;
                }

                User selectedUser
                        = dao.getUserById(id);

                if (selectedUser == null) {

                    session.setAttribute(
                            "error",
                            "Không tìm thấy tài khoản!"
                    );

                    response.sendRedirect(
                            request.getContextPath()
                            + "/user?view=list"
                    );

                    return;
                }

                boolean success
                        = dao.updateUserStatus(
                                id,
                                active
                        );

                if (success) {

                    if (active) {

                        session.setAttribute(
                                "message",
                                "Mở khóa tài khoản thành công!"
                        );

                    } else {

                        session.setAttribute(
                                "message",
                                "Khóa tài khoản thành công!"
                        );
                    }

                } else {

                    session.setAttribute(
                            "error",
                            "Cập nhật trạng thái tài khoản thất bại!"
                    );
                }

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list"
                );

            } catch (Exception e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi cập nhật trạng thái User!",
                        e
                );

                session.setAttribute(
                        "error",
                        "Lỗi khi cập nhật trạng thái tài khoản!"
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/user?view=list"
                );
            }

        } else {

            response.sendRedirect(
                    request.getContextPath()
                    + "/user?view=list"
            );
        }
    }
}