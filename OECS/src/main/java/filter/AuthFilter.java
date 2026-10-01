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


        boolean isPublicUrl = PUBLIC_URLS.contains(relativePath);
        boolean isStaticResource = PUBLIC_PREFIXES.stream().anyMatch(relativePath::startsWith);

        if (isPublicUrl || isStaticResource) {
            chain.doFilter(request, response);
            return;
        }
        if (user == null) {
            if (session == null) {
                session = httpRequest.getSession(true);
            }

            String queryString = httpRequest.getQueryString();
            String fullRedirectUrl = requestURI + (queryString != null ? "?" + queryString : "");
            session.setAttribute("redirectUrl", fullRedirectUrl);

            httpResponse.sendRedirect(contextPath + "/login");
            return;
        }

        if (relativePath.startsWith("/admin") || relativePath.startsWith("/WEB-INF/admin")) {
            if (!user.isAdminOrStaff()) {
                session.setAttribute("toastMessage", "Bạn không có quyền truy cập khu vực quản trị!");
                session.setAttribute("toastType", "error");

                httpResponse.sendRedirect(contextPath + "/home");
                return;
            }
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}