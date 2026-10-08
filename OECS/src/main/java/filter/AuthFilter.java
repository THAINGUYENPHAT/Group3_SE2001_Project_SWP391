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

    // =====================================================
    // PUBLIC - Guest và tất cả role đều có thể truy cập
    // =====================================================
    private static final List<String> PUBLIC_URLS = Arrays.asList(
            "",
            "/",
            "/login",
            "/register",
            "/logout",
            "/home",
            "/shop",
            "/api/search",
            "/forgot-password",
            "/reset-password",
            "/favicon.ico"
    );

    // =====================================================
    // CUSTOMER - Chỉ Customer đã đăng nhập
    // =====================================================
    private static final List<String> CUSTOMER_URLS = Arrays.asList(
            "/cart",
            "/profile",
            "/review"
    );

    // =====================================================
    // STAFF - Chỉ Staff
    // =====================================================
    private static final List<String> STAFF_URLS = Arrays.asList(
            "/brand",
            "/category",
            "/product",
            "/admin/orders",
            "/admin/voucher"
    );

    // =====================================================
    // ADMIN - Chỉ Admin
    // =====================================================
    private static final List<String> ADMIN_URLS = Arrays.asList(
            "/admin/dashboard",
            "/admin/report",
            "/admin/report/export",
            "/user"
    );

    // =====================================================
    // Static resources - ai cũng có thể truy cập
    // =====================================================
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
    public void doFilter(ServletRequest request,
            ServletResponse response,
            FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest
                = (HttpServletRequest) request;

        HttpServletResponse httpResponse
                = (HttpServletResponse) response;

        HttpSession session
                = httpRequest.getSession(false);

        // =====================================================
        // Lấy đường dẫn request
        // =====================================================
        String requestURI
                = httpRequest.getRequestURI();

        String contextPath
                = httpRequest.getContextPath();

        String relativePath
                = requestURI.substring(contextPath.length());

        // =====================================================
        // Lấy user đã đăng nhập trong session
        // =====================================================
        User user = (session != null)
                ? (User) session.getAttribute("loggedInUser")
                : null;

        // =====================================================
        // 1. KIỂM TRA PUBLIC
        // =====================================================
        boolean isPublicUrl
                = PUBLIC_URLS.contains(relativePath);

        boolean isStaticResource
                = PUBLIC_PREFIXES.stream()
                        .anyMatch(relativePath::startsWith);

        if (isPublicUrl || isStaticResource) {
            chain.doFilter(request, response);
            return;
        }

        // =====================================================
        // 2. CHƯA ĐĂNG NHẬP
        // =====================================================
        if (user == null) {

            if (session == null) {
                session = httpRequest.getSession(true);
            }

            String queryString
                    = httpRequest.getQueryString();

            String fullRedirectUrl
                    = requestURI
                    + (queryString != null
                            ? "?" + queryString
                            : "");

            session.setAttribute(
                    "redirectUrl",
                    fullRedirectUrl
            );

            httpResponse.sendRedirect(
                    contextPath + "/login"
            );

            return;
        }

        // =====================================================
        // 3. KIỂM TRA CUSTOMER
        // =====================================================
        boolean isCustomerUrl
                = CUSTOMER_URLS.contains(relativePath);

        if (isCustomerUrl && !user.isCustomer()) {

            session.setAttribute(
                    "toastMessage",
                    "Bạn không có quyền truy cập chức năng dành cho khách hàng!"
            );

            session.setAttribute(
                    "toastType",
                    "error"
            );

            httpResponse.sendRedirect(
                    contextPath + "/home"
            );

            return;
        }

        // =====================================================
        // 4. KIỂM TRA STAFF
        // =====================================================
        boolean isStaffUrl
                = STAFF_URLS.contains(relativePath)
                || relativePath.startsWith("/admin/orders/");

        if (isStaffUrl && !user.isStaff()) {

            session.setAttribute(
                    "toastMessage",
                    "Bạn không có quyền truy cập khu vực dành cho nhân viên!"
            );

            session.setAttribute(
                    "toastType",
                    "error"
            );

            httpResponse.sendRedirect(
                    contextPath + "/home"
            );

            return;
        }

        // =====================================================
        // 5. KIỂM TRA ADMIN
        // =====================================================
        boolean isAdminUrl
                = ADMIN_URLS.contains(relativePath);

        if (isAdminUrl && !user.isAdmin()) {

            session.setAttribute(
                    "toastMessage",
                    "Bạn không có quyền truy cập khu vực quản trị!"
            );

            session.setAttribute(
                    "toastType",
                    "error"
            );

            httpResponse.sendRedirect(
                    contextPath + "/home"
            );

            return;
        }

        // =====================================================
        // 6. CHO REQUEST ĐI TIẾP
        // =====================================================
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}
