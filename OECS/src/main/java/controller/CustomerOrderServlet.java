package controller;

import dao.OrderDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.Locale;
import java.util.Collections;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.Order;
import model.User;
import service.OrderService;

@WebServlet(name = "CustomerOrderServlet", urlPatterns = {"/my-orders", "/my-orders/detail", "/my-orders/cancel"})
public class CustomerOrderServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(CustomerOrderServlet.class.getName());
    private final OrderDAO orders = new OrderDAO();
    private final OrderService service = new OrderService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setHeader("Cache-Control", "no-store");
        User user = customer(request, response);
        if (user == null) return;
        if ("/my-orders/cancel".equals(request.getServletPath())) {
            response.setHeader("Allow", "POST");
            response.sendError(405);
            return;
        }
        HttpSession session = request.getSession();
        synchronized (session) {
            if (session.getAttribute("customerOrderToken") == null) {
                session.setAttribute("customerOrderToken", UUID.randomUUID().toString());
            }
        }
        request.setAttribute("statusLabels", OrderService.statusLabels());
        try {
            if ("/my-orders".equals(request.getServletPath())) {
                Map<String, String> tabs = OrderService.purchaseTabs();
                String tab = request.getParameter("status");
                tab = tab == null ? "ALL" : tab.toUpperCase(Locale.ROOT);
                if (!tabs.containsKey(tab)) tab = "ALL";
                String query = request.getParameter("q");
                query = query == null ? "" : query.trim();
                if (query.length() > 100) query = query.substring(0, 100);
                Map<String, Long> counts = OrderService.purchaseTabCounts(orders.countPurchasesByStatus(user.getUserId(), query));
                long total = counts.get(tab);
                long pageCount = Math.max(1L, (total + 9) / 10);
                long page = Math.min(pageCount, Math.max(1, positiveId(request.getParameter("page"))));
                List<Order> list = orders.findPurchasePage(user.getUserId(), query,
                        OrderService.statusesForTab(tab), (page - 1) * 10, 10);
                for (Order order : list) order.setOrderStatus(OrderService.normalizeStatus(order.getOrderStatus()));
                List<Integer> ids = new ArrayList<>();
                for (Order order : list) ids.add(order.getOrderId());
                request.setAttribute("orderItems", orders.findItemsForOrders(user.getUserId(), ids));
                request.setAttribute("tabs", tabs);
                request.setAttribute("tabCounts", counts);
                request.setAttribute("activeTab", tab);
                request.setAttribute("query", query);
                request.setAttribute("currentPage", page);
                request.setAttribute("pageCount", pageCount);
                request.setAttribute("resultCount", total);
                request.setAttribute("orders", list);
                request.getRequestDispatcher("/WEB-INF/customer-orders/list.jsp").forward(request, response);
            } else {
                int id = positiveId(request.getParameter("id"));
                if (id < 1) { response.sendError(400, "Mã đơn hàng không hợp lệ."); return; }
                Order order = orders.findByIdAndUser(id, user.getUserId());
                if (order == null) { response.sendError(404, "Không tìm thấy đơn hàng."); return; }
                order.setOrderStatus(OrderService.normalizeStatus(order.getOrderStatus()));
                request.setAttribute("order", order);
                request.setAttribute("items", orders.findItems(id, user.getUserId()));
                List<Map<String, Object>> history = service.findHistory(id, user.getUserId());
                request.setAttribute("trackingSteps", OrderService.trackingSteps(order, history));
                Collections.reverse(history);
                request.setAttribute("history", history);
                request.getRequestDispatcher("/WEB-INF/customer-orders/detail.jsp").forward(request, response);
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Cannot load customer orders", ex);
            response.sendError(500, "Chưa tải được đơn hàng. Vui lòng thử lại.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");
        User user = customer(request, response);
        if (user == null) return;
        if (!"/my-orders/cancel".equals(request.getServletPath())) {
            response.setHeader("Allow", "GET");
            response.sendError(405);
            return;
        }
        HttpSession session = request.getSession();
        String token = request.getParameter("csrfToken");
        if (token == null || !token.equals(session.getAttribute("customerOrderToken"))) {
            response.sendError(403, "Yêu cầu không hợp lệ. Vui lòng tải lại trang.");
            return;
        }
        int id = positiveId(request.getParameter("id"));
        if (id < 1) { response.sendError(400, "Mã đơn hàng không hợp lệ."); return; }
        try {
            // Do not reveal whether another customer's order exists.
            if (orders.findByIdAndUser(id, user.getUserId()) == null) {
                response.sendError(404, "Không tìm thấy đơn hàng.");
                return;
            }
            boolean changed = service.cancelOrderByCustomer(user.getUserId(), id);
            session.setAttribute("customerOrderMessage", changed
                    ? "Đã hủy đơn hàng và hoàn lại số lượng tồn kho."
                    : "Đơn hàng đã được hủy trước đó.");
        } catch (IllegalArgumentException ex) {
            session.setAttribute("customerOrderError", ex.getMessage());
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Cannot cancel customer order", ex);
            session.setAttribute("customerOrderError", "Chưa xác nhận được kết quả hủy. Vui lòng tải lại đơn hàng và thử lại.");
        }
        response.setStatus(HttpServletResponse.SC_SEE_OTHER);
        response.setHeader("Location", response.encodeRedirectURL(request.getContextPath() + "/my-orders/detail?id=" + id));
    }

    private User customer(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        Object value = session == null ? null : session.getAttribute("loggedInUser");
        if (!(value instanceof User)) {
            request.getSession().setAttribute("redirectUrl", request.getContextPath() + "/my-orders");
            response.sendRedirect(request.getContextPath() + "/login");
            return null;
        }
        User user = (User) value;
        if (!user.isCustomer()) { response.sendError(403); return null; }
        return user;
    }

    private int positiveId(String value) {
        try { return Math.max(-1, Integer.parseInt(value)); }
        catch (NumberFormatException ex) { return -1; }
    }
}
