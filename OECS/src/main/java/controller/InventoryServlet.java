package controller;

import dao.InventoryDAO;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.SQLException;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "InventoryServlet", urlPatterns = {"/inventory"})
public class InventoryServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(InventoryServlet.class.getName());
    private static final int PAGE_SIZE = 25;
    private static final String JSP = "/WEB-INF/inventory/list.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        User user = authorize(request, response);
        if (user == null) {
            return;
        }

        String keyword = trim(request.getParameter("keyword"));
        if (keyword.length() > 100) {
            keyword = keyword.substring(0, 100);
        }
        String status = normalizeStatus(request.getParameter("status"));
        int page = positiveInt(request.getParameter("page"), 1);
        page = Math.min(page, 100000);
        InventoryDAO dao = new InventoryDAO();
        try {
            int total = dao.countItems(keyword, status);
            int pages = Math.max(1, (total + PAGE_SIZE - 1) / PAGE_SIZE);
            page = Math.min(page, pages);

            request.setAttribute("items",
                    dao.findItems(keyword, status, page, PAGE_SIZE));
            request.setAttribute("movements", dao.getRecentMovements(40));
            request.setAttribute("keyword", keyword);
            request.setAttribute("status", status);
            request.setAttribute("pageNumber", page);
            request.setAttribute("totalPages", pages);
            request.setAttribute("totalItems", total);
            request.setAttribute("csrfToken", csrfToken(request.getSession()));
            request.getRequestDispatcher(JSP).forward(request, response);
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Cannot load inventory", ex);
            throw new ServletException("Không thể tải dữ liệu tồn kho.", ex);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        User user = authorize(request, response);
        if (user == null) {
            return;
        }

        HttpSession session = request.getSession(false);
        String actual = request.getParameter("csrfToken");
        String expected = (String) session.getAttribute("inventoryCsrfToken");
        if (!constantTimeEquals(expected, actual)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "CSRF token không hợp lệ.");
            return;
        }

        String action = trim(request.getParameter("action"));
        String note = trim(request.getParameter("note"));
        int skuId = positiveInt(request.getParameter("skuId"), -1);
        int quantity = nonnegativeInt(request.getParameter("quantity"));
        try {
            if (skuId <= 0 || quantity < 0) {
                throw new IllegalArgumentException("SKU hoặc số lượng không hợp lệ.");
            }
            int newStock = new InventoryDAO().changeStock(
                    skuId, action, quantity, note, user.getUserId());
            session.setAttribute("inventorySuccess",
                    "Cập nhật tồn kho thành công. Số tồn mới: " + newStock + ".");
            session.removeAttribute("inventoryError");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            session.setAttribute("inventoryError", ex.getMessage());
            session.removeAttribute("inventorySuccess");
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Stock update failed", ex);
            session.setAttribute("inventoryError",
                    "Không thể cập nhật tồn kho. Vui lòng kiểm tra log và thử lại.");
            session.removeAttribute("inventorySuccess");
        }
        response.sendRedirect(request.getContextPath() + "/inventory");
    }

    /**
     * Checks both login and actual database role; do not rely on a URL filter
     * alone.
     */
    private User authorize(HttpServletRequest request, HttpServletResponse response)
            throws IOException, ServletException {
        HttpSession session = request.getSession(false);
        Object logged = session == null ? null : session.getAttribute("loggedInUser");
        if (!(logged instanceof User)) {
            response.sendRedirect(request.getContextPath() + "/login");
            return null;
        }
        User user = (User) logged;
        try {
            if (!new InventoryDAO().isAuthorizedStaff(user.getUserId())) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "Chỉ Staff/Admin có thể quản lý tồn kho.");
                return null;
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Cannot check inventory access", ex);
            throw new ServletException("Không thể kiểm tra quyền truy cập kho.", ex);
        }
        return user;
    }

    private static String csrfToken(HttpSession session) {
        String token = (String) session.getAttribute("inventoryCsrfToken");
        if (token == null) {
            token = UUID.randomUUID().toString();
            session.setAttribute("inventoryCsrfToken", token);
        }
        return token;
    }

    private static boolean constantTimeEquals(String first, String second) {
        if (first == null || second == null) {
            return false;
        }
        return MessageDigest.isEqual(
                first.getBytes(StandardCharsets.UTF_8),
                second.getBytes(StandardCharsets.UTF_8));
    }

    private static String normalizeStatus(String status) {
        return "LOW".equals(status) || "OUT".equals(status) ? status : "ALL";
    }

    private static String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private static int positiveInt(String value, int fallback) {
        try {
            int number = Integer.parseInt(trim(value));
            return number > 0 ? number : fallback;
        } catch (NumberFormatException ex) {
            return fallback;
        }
    }

    private static int nonnegativeInt(String value) {
        try {
            return Integer.parseInt(trim(value));
        } catch (NumberFormatException ex) {
            return -1;
        }
    }
}
