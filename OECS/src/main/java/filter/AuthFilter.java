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

@WebFilter(
        filterName = "AuthFilter",
        urlPatterns = {"/*"}
)
public class AuthFilter implements Filter {

    // Cac duong dan khong yeu cau dang nhap
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
            "/favicon.ico",
            "/guide",

            // Callback thanh toan tu cong sandbox
            "/payment/vnpay/ipn",
            "/payment/momo/ipn",
            "/payment/vnpay/return",
            "/payment/momo/return"
    );

    // Chi Customer duoc truy cap
    private static final List<String> CUSTOMER_URLS = Arrays.asList(
            "/cart",
            "/review",
            "/checkout",
            "/my-orders",
            "/my-orders/detail",
            "/my-orders/cancel",
            "/order-success",
            "/payment",
            "/payment/action"
    );

    // Chi Staff duoc truy cap
    private static final List<String> STAFF_URLS = Arrays.asList(
            "/brand",
            "/category",
            "/product",
            "/admin/orders",
            "/staff/voucher",
            "/product-sku"
    );

    // Chi Admin duoc truy cap
    private static final List<String> ADMIN_URLS = Arrays.asList(
            "/admin/dashboard",
            "/admin/report",
            "/admin/report/export",
            "/user",
            "/admin/audit-log"
    );

    // Moi user da dang nhap deu duoc truy cap
    private static final List<String> AUTHENTICATED_URLS =
            Arrays.asList(
                    "/profile",
                    "/notification"
            );

    // Tai nguyen tinh
    private static final List<String> PUBLIC_PREFIXES =
            Arrays.asList(
                    "/assets/",
                    "/css/",
                    "/js/",
                    "/images/",
                    "/uploads/"
            );

    @Override
    public void init(FilterConfig filterConfig)
            throws ServletException {
    }

    @Override
    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain
    ) throws IOException, ServletException {

        HttpServletRequest httpRequest =
                (HttpServletRequest) request;

        HttpServletResponse httpResponse =
                (HttpServletResponse) response;

        HttpSession session = httpRequest.getSession(false);

        String requestURI = httpRequest.getRequestURI();
        String contextPath = httpRequest.getContextPath();

        String relativePath = requestURI.substring(
                contextPath.length()
        );

        User user = session == null
                ? null
                : (User) session.getAttribute("loggedInUser");

        // 1. Cho phep trang cong khai va tai nguyen tinh
        boolean isPublicUrl = PUBLIC_URLS.contains(relativePath);

        boolean isStaticResource = PUBLIC_PREFIXES.stream()
                .anyMatch(relativePath::startsWith);

        if (isPublicUrl || isStaticResource) {
            chain.doFilter(request, response);
            return;
        }

        // 2. Chua dang nhap thi chuyen den Login
        if (user == null) {
            if (session == null) {
                session = httpRequest.getSession(true);
            }

            String queryString = httpRequest.getQueryString();

            String fullRedirectUrl = requestURI
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

        // 3. Duong dan danh cho moi user da dang nhap
        if (AUTHENTICATED_URLS.contains(relativePath)) {
            chain.doFilter(request, response);
            return;
        }

        // 4. Kiem tra quyen Customer
        boolean isCustomerUrl =
                CUSTOMER_URLS.contains(relativePath);

        if (isCustomerUrl && !user.isCustomer()) {
            session.setAttribute(
                    "toastMessage",
                    "Bạn không có quyền truy cập "
                    + "chức năng dành cho khách hàng!"
            );

            session.setAttribute("toastType", "error");

            httpResponse.sendRedirect(
                    contextPath + "/home"
            );

            return;
        }

        // 5. Kiem tra quyen Staff
        boolean isStaffUrl =
                STAFF_URLS.contains(relativePath)
                || relativePath.startsWith("/admin/orders/")
                || relativePath.startsWith("/staff/voucher/");

        if (isStaffUrl && !user.isStaff()) {
            session.setAttribute(
                    "toastMessage",
                    "Bạn không có quyền truy cập "
                    + "khu vực dành cho nhân viên!"
            );

            session.setAttribute("toastType", "error");

            httpResponse.sendRedirect(
                    contextPath + "/home"
            );

            return;
        }

        // 6. Kiem tra quyen Admin
        boolean isAdminUrl =
                ADMIN_URLS.contains(relativePath);

        if (isAdminUrl && !user.isAdmin()) {
            session.setAttribute(
                    "toastMessage",
                    "Bạn không có quyền truy cập "
                    + "khu vực quản trị!"
            );

            session.setAttribute("toastType", "error");

            httpResponse.sendRedirect(
                    contextPath + "/home"
            );

            return;
        }

        // 7. Cho request di tiep
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}