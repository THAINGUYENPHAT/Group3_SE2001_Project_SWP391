///*
// * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
// * Click nbfs://nbhost/SystemFileSystem/Templates/JSP_Servlet/Servlet.java to edit this template
// */
//package controller;
//
//import dao.UserDAO;
//import java.io.IOException;
//import java.io.PrintWriter;
//import jakarta.servlet.ServletException;
//import jakarta.servlet.annotation.WebServlet;
//import jakarta.servlet.http.Cookie;
//import jakarta.servlet.http.HttpServlet;
//import jakarta.servlet.http.HttpServletRequest;
//import jakarta.servlet.http.HttpServletResponse;
//import jakarta.servlet.http.HttpSession;
//import model.User;
//
///**
// *
// * @author tuan2
// */
//@WebServlet(name = "LoginServlet", urlPatterns = {"/login"})
//public class LoginServlet extends HttpServlet {
//
//    @Override
//    protected void doGet(HttpServletRequest request, HttpServletResponse response)
//            throws ServletException, IOException {
//
//        request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
//    }
//
//    @Override
//    protected void doPost(HttpServletRequest request, HttpServletResponse response)
//            throws ServletException, IOException {
//        String username = request.getParameter("username");
//        String password = request.getParameter("password");
//
//        UserDAO dao = new UserDAO();
//        User user = dao.login(username, password);
//
//        if (user == null) {
//            //login nếu như username = null(login fail) thì sẽ reDirect về Login.jsp
//            //nếu dùng forward thì sai vì foward sẽ trả status 200(OK) nhưng k đăng nhập được-> sai 
//            //request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
//            response.sendRedirect(request.getContextPath() + "/login");
//        } else {
//            //lưu lại phiên làm việc(trạng thái đăng nhập của người dùng)
//            HttpSession session = request.getSession();
//            session.setAttribute("loggedInUser", user);
//            // ========================== SESSION ==========================
//// 1. Tạo hoặc lấy Session hiện tại
////    - Nếu chưa có Session -> tạo mới
////    - Nếu đã có -> trả về Session hiện tại
//// HttpSession session = request.getSession();
////
//// 2. Chỉ lấy Session (không tạo mới)
////    - Nếu chưa có Session -> trả về null
//// HttpSession session = request.getSession(false);
////
//// 3. Lưu dữ liệu vào Session
//// session.setAttribute("loggedInUser", user);
//// session.setAttribute("username", username);
//// session.setAttribute("role", "Admin");
////
//// 4. Lấy dữ liệu từ Session
//// User user = (User) session.getAttribute("loggedInUser");
//// String username = (String) session.getAttribute("username");
////
//// 5. Kiểm tra người dùng đã đăng nhập chưa
//// HttpSession session = request.getSession(false);
//// if (session == null || session.getAttribute("loggedInUser") == null) {
////     response.sendRedirect("login");
////     return;
//// }
////
//// 6. Xóa một dữ liệu trong Session
//// session.removeAttribute("loggedInUser");
////
//// 7. Hủy toàn bộ Session (Logout)
//// session.invalidate();
////
//// 8. Thiết lập thời gian hết hạn Session
//// (Ví dụ: 30 phút không hoạt động thì Session tự hủy)
//// session.setMaxInactiveInterval(30 * 60);
////
//// 9. Lấy Session ID
//// String sessionId = session.getId();
////
//// 10. Kiểm tra Session mới hay cũ
//// boolean isNew = session.isNew();
////
//// 11. Lấy thời gian tạo Session
//// long createTime = session.getCreationTime();
////
//// 12. Lấy thời gian truy cập cuối cùng
//// long lastAccess = session.getLastAccessedTime();
////
//// 13. Kiểm tra Attribute có tồn tại không
//// if (session.getAttribute("loggedInUser") != null) {
////     // Đã đăng nhập
//// }
//// =============================================================
//
//            // Tao them cookie (vd: "theme")
//            Cookie themeCookie = new Cookie("theme", "dark");
//            themeCookie.setMaxAge(60 * 60 * 24 * 2); // Tinh bang second 60s * 60 -> 1h * 24 -> 1d * 2 -> 2d
//            // Response se chiu trach nhiem gui cookie nay ve cho trinh duyet
//            response.addCookie(themeCookie);
//            // ========================== COOKIE ==========================
//// 1. Tạo Cookie
//// Cookie cookie = new Cookie("username", "admin");
////
//// 2. Gửi Cookie về Browser
//// response.addCookie(cookie);
////
//// 3. Thiết lập thời gian sống của Cookie
//// (Đơn vị: giây)
//// cookie.setMaxAge(60 * 60);          // 1 giờ
//// cookie.setMaxAge(60 * 60 * 24);     // 1 ngày
//// cookie.setMaxAge(60 * 60 * 24 * 7); // 7 ngày
////
//// 4. Cookie chỉ tồn tại đến khi đóng trình duyệt
//// cookie.setMaxAge(-1);
////
//// 5. Xóa Cookie
//// Cookie cookie = new Cookie("username", "");
//// cookie.setMaxAge(0);
//// response.addCookie(cookie);
////
//// 6. Thiết lập phạm vi sử dụng Cookie
//// ("/" nghĩa là toàn bộ website)
//// cookie.setPath("/");
////
//// 7. Đọc tất cả Cookie từ Request
//// Cookie[] cookies = request.getCookies();
////
//// 8. Tìm Cookie theo tên
//// Cookie[] cookies = request.getCookies();
////
//// if (cookies != null) {
////     for (Cookie c : cookies) {
////         if (c.getName().equals("username")) {
////             String value = c.getValue();
////         }
////     }
//// }
////
//// 9. Lấy tên Cookie
//// String name = cookie.getName();
////
//// 10. Lấy giá trị Cookie
//// String value = cookie.getValue();
////
//// 11. Thay đổi giá trị Cookie
//// cookie.setValue("newValue");
////
//// 12. Kiểm tra Cookie có tồn tại không
//// Cookie[] cookies = request.getCookies();
////
//// if (cookies != null) {
////     for (Cookie c : cookies) {
////         if (c.getName().equals("theme")) {
////             // Cookie tồn tại
////         }
////     }
//// }
////
//// 13. Ví dụ lưu Remember Me
//// Cookie remember = new Cookie("rememberUser", username);
//// remember.setMaxAge(60 * 60 * 24 * 7);
//// response.addCookie(remember);
////
//// 14. Ví dụ lưu Theme
//// Cookie theme = new Cookie("theme", "dark");
//// theme.setMaxAge(60 * 60 * 24 * 30);
//// response.addCookie(theme);
////
//// ============================================================
////
//// Cookie lưu trên Browser.
//// Dùng để lưu:
//// - Remember Me
//// - Theme (Dark/Light)
//// - Language
//// - Một số tùy chọn của người dùng
////
//// Cookie KHÔNG nên lưu:
//// - Password
//// - Thông tin nhạy cảm
////
//// Cookie được gửi kèm theo mỗi Request từ Browser lên Server.
//// Server đọc Cookie bằng:
//// request.getCookies();
////
//// Browser nhận Cookie từ Server bằng:
//// response.addCookie(cookie);
//// ============================================================
//
//            //redirect về trang chủ
//            response.sendRedirect(request.getContextPath() + "/artist");
//        }
//    }
//
//}
