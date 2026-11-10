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

    private static final List<String> CUSTOMER_URLS = Arrays.asList(
            "/cart",
            "/review",
            "/checkout",
            "/my-orders",
            "/my-orders/detail",
            "/my-orders/cancel",
            "/order-success",
            "/payment",
            "/payment/action",
            "/return-exchange",
            "/review/report"
    );

    private static final List<String> STAFF_URLS = Arrays.asList(
            "/brand",
            "/category",
            "/product",
            "/admin/orders",
            "/staff/voucher",
            "/product-sku",
            "/staff/banner",
            "/staff/return-exchange",
            "/staff/reviews",
            "/staff/payment-refunds"
    );

    private static final List<String> ADMIN_URLS = Arrays.asList(
            "/admin/dashboard",
            "/admin/report",
            "/admin/report/export",
            "/user",
            "/admin/audit-log"
    );

    private static final List<String> AUTHENTICATED_URLS
            = Arrays.asList(
                    "/profile",
                    "/notification"
            );

    private static final List<String> PUBLIC_PREFIXES
            = Arrays.asList(
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

        HttpServletRequest httpRequest
                = (HttpServletRequest) request;

        HttpServletResponse httpResponse
                = (HttpServletResponse) response;

        HttpSession session = httpRequest.getSession(false);

        String requestURI = httpRequest.getRequestURI();
        String contextPath = httpRequest.getContextPath();

        String relativePath = requestURI.substring(
                contextPath.length()
        );

        User user = session == null
                ? null
                : (User) session.getAttribute("loggedInUser");

        boolean isPublicUrl = PUBLIC_URLS.contains(relativePath);

        boolean isStaticResource = PUBLIC_PREFIXES.stream()
                .anyMatch(relativePath::startsWith);

        if (isPublicUrl || isStaticResource) {
            chain.doFilter(request, response);
            return;
        }

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

        if (AUTHENTICATED_URLS.contains(relativePath)) {
            chain.doFilter(request, response);
            return;
        }

        boolean isCustomerUrl
                = CUSTOMER_URLS.contains(relativePath);

        if (isCustomerUrl) {

            if (!user.isCustomer()) {
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

            chain.doFilter(request, response);
            return;
        }

        boolean isStaffUrl
                = STAFF_URLS.contains(relativePath)
                || relativePath.startsWith("/admin/orders/")
                || relativePath.startsWith("/staff/voucher/");

        if (isStaffUrl) {
            if (!user.isStaff()) {
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
            chain.doFilter(request, response);
            return;
        }

        boolean isAdminUrl
                = ADMIN_URLS.contains(relativePath);

        if (isAdminUrl) {
            if (!user.isAdmin()) {
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
            chain.doFilter(request, response);
            return;
        }

        session.setAttribute(
                "toastMessage",
                "Đường dẫn không hợp lệ hoặc bạn không có quyền truy cập!"
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

    @Override
    public void destroy() {
    }
}
