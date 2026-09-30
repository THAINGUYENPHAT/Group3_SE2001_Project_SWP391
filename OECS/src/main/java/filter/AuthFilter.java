package filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import model.User;

// 1. Áp dụng Filter cho TẤT CẢ các URL trong hệ thống
@WebFilter(filterName = "AuthFilter", urlPatterns = {"/*"})
public class AuthFilter implements Filter {

    // 2. Danh sách trắng (Whitelist) các URL KHÔNG CẦN đăng nhập
    private static final List<String> PUBLIC_URLS = Arrays.asList(
            "/login",
            "/register",
            "/logout",
            "/home",
            "/index.html"
    );

    // Danh sách các tiền tố tài nguyên tĩnh (Static resources)
    private static final List<String> PUBLIC_PREFIXES = Arrays.asList(
            "/assets/",
            "/css/",
            "/js/",
            "/images/"
    );

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);

        String requestURI = httpRequest.getRequestURI();
        String contextPath = httpRequest.getContextPath();
        String relativePath = requestURI.substring(contextPath.length());

        // Lấy User từ Session
        User user = (session != null) ? (User) session.getAttribute("loggedInUser") : null;

        // ========================================================
        // 1. CHO PHÉP QUA NẾU LÀ PUBLIC URL HOẶC TÀI NGUYÊN TĨNH
        // ========================================================
        boolean isPublicUrl = PUBLIC_URLS.contains(relativePath);
        boolean isStaticResource = PUBLIC_PREFIXES.stream().anyMatch(relativePath::startsWith);

        if (isPublicUrl || isStaticResource) {
            chain.doFilter(request, response);
            return;
        }

        // ========================================================
        // 2. BẮT BỘ LỌC CHƯA ĐĂNG NHẬP (AUTHENTICATION)
        // ========================================================
        if (user == null) {
            if (session == null) {
                session = httpRequest.getSession(true);
            }

            // Lưu lại URL gốc để quay lại sau khi đăng nhập thành công
            String queryString = httpRequest.getQueryString();
            String fullRedirectUrl = requestURI + (queryString != null ? "?" + queryString : "");
            session.setAttribute("redirectUrl", fullRedirectUrl);

            // Chuyển hướng về trang đăng nhập
            httpResponse.sendRedirect(contextPath + "/login");
            return;
        }

        // ========================================================
        // 3. KIỂM TRA PHÂN QUYỀN (AUTHORIZATION DÀNH CHO ADMIN/STAFF)
        // ========================================================
        // Nếu URL thuộc khu vực Admin nhưng tài khoản lại là Customer
        if (relativePath.startsWith("/admin") || relativePath.startsWith("/WEB-INF/admin")) {
            if (!user.isAdminOrStaff()) {
                // Lưu thông báo vào session để hiển thị bằng Toast/Alert ở giao diện trang chủ
                session.setAttribute("toastMessage", "Bạn không có quyền truy cập vào trang quản trị!");
                session.setAttribute("toastType", "error");

                // Chuyển hướng người dùng về trang chủ
                httpResponse.sendRedirect(contextPath + "/home");
                return;
            }
        }

        // Cho phép request đi tiếp nếu đã đăng nhập và hợp lệ
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}
