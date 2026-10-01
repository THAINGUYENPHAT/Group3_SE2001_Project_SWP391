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

@WebFilter(filterName = "AuthFilter", urlPatterns = {"/*"})
public class AuthFilter implements Filter {

    // Danh sách các URL công khai không yêu cầu đăng nhập
    private static final List<String> PUBLIC_URLS = Arrays.asList(
            "",
            "/",
            "/login",
            "/register",
            "/logout",
            "/home",
            "/index.html",
            "/product",
            "/favicon.ico"
    );

    // Danh sách tiền tố tài nguyên tĩnh (Static resources)
    private static final List<String> PUBLIC_PREFIXES = Arrays.asList(
            "/assets/",
            "/css/",
            "/js/",
            "/images/",
            "/uploads/"
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

        User user = (session != null) ? (User) session.getAttribute("loggedInUser") : null;

        // ========================================================
        // 1. KIỂM TRA TÀI NGUYÊN TĨNH & PUBLIC URL
        // ========================================================
        boolean isPublicUrl = PUBLIC_URLS.contains(relativePath);
        boolean isStaticResource = PUBLIC_PREFIXES.stream().anyMatch(relativePath::startsWith);

        if (isPublicUrl || isStaticResource) {
            chain.doFilter(request, response);
            return;
        }

        // ========================================================
        // 2. YÊU CẦU ĐĂNG NHẬP (AUTHENTICATION)
        // ========================================================
        if (user == null) {
            if (session == null) {
                session = httpRequest.getSession(true);
            }

            // Lưu lại URL gốc để tự động quay lại sau khi đăng nhập thành công
            String queryString = httpRequest.getQueryString();
            String fullRedirectUrl = requestURI + (queryString != null ? "?" + queryString : "");
            session.setAttribute("redirectUrl", fullRedirectUrl);

            httpResponse.sendRedirect(contextPath + "/login");
            return;
        }

        // ========================================================
        // 3. KIỂM TRA PHÂN QUYỀN (AUTHORIZATION ADMIN / STAFF)
        // ========================================================
        if (relativePath.startsWith("/admin") || relativePath.startsWith("/WEB-INF/admin")) {
            if (!user.isAdminOrStaff()) {
                session.setAttribute("toastMessage", "Bạn không có quyền truy cập khu vực quản trị!");
                session.setAttribute("toastType", "error");

                httpResponse.sendRedirect(contextPath + "/home");
                return;
            }
        }

        // Cho phép Request đi tiếp
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}