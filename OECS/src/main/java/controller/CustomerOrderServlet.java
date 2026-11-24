package controller;

import dao.OrderDAO;
import dao.OrderWorkflowDAO.OrderNotFoundException;
import dao.ReturnExchangeDAO;

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
import service.OrderWorkflowService;

@WebServlet(
        name = "CustomerOrderServlet",
        urlPatterns = {
            "/my-orders",
            "/my-orders/detail",
            "/my-orders/cancel"
        }
)
public class CustomerOrderServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(CustomerOrderServlet.class.getName());

    private static final int PAGE_SIZE = 10;

    private final OrderDAO orders = new OrderDAO();
    private final OrderService service = new OrderService();
    private final OrderWorkflowService orderWorkflow = new OrderWorkflowService();

    private final ReturnExchangeDAO returnExchangeDAO
            = new ReturnExchangeDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        User user = customer(request, response);

        if (user == null) {
            return;
        }

        if ("/my-orders/cancel".equals(request.getServletPath())) {
            response.setHeader("Allow", "POST");
            response.sendError(405);
            return;
        }

        HttpSession session = request.getSession();

        synchronized (session) {
            if (session.getAttribute("customerOrderToken") == null) {
                session.setAttribute(
                        "customerOrderToken",
                        UUID.randomUUID().toString()
                );
            }
        }

        request.setAttribute(
                "statusLabels",
                OrderService.statusLabels()
        );

        try {
            if ("/my-orders".equals(request.getServletPath())) {
                showOrderList(request, response, user.getUserId());
            } else {
                showOrderDetail(request, response, user.getUserId());
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Cannot load customer orders", ex);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Chưa tải được đơn hàng. Vui lòng thử lại.");
        }
    }

    private void showOrderList(HttpServletRequest request, HttpServletResponse response, int userId)
            throws SQLException, ServletException, IOException {
        Map<String, String> tabs = OrderService.purchaseTabs();
        String tab = request.getParameter("status");
        tab = tab == null ? "ALL" : tab.toUpperCase(Locale.ROOT);
        if (!tabs.containsKey(tab)) {
            tab = "ALL";
        }

        String query = request.getParameter("q");
        query = query == null ? "" : query.trim();
        if (query.length() > 100) {
            query = query.substring(0, 100);
        }

        Map<String, Long> counts = OrderService.purchaseTabCounts(orders.countPurchasesByStatus(userId, query));
        long total = counts.getOrDefault(tab, 0L);
        long pageCount = Math.max(1L, (total + PAGE_SIZE - 1) / PAGE_SIZE);
        long page = Math.min(pageCount, Math.max(1L, positiveId(request.getParameter("page"))));
        List<Order> list = orders.findPurchasePage(userId, query, OrderService.statusesForTab(tab),
                (page - 1) * PAGE_SIZE, PAGE_SIZE);

        List<Integer> ids = new ArrayList<>();
        for (Order order : list) {
            order.setOrderStatus(OrderService.normalizeStatus(order.getOrderStatus()));
            ids.add(order.getOrderId());
        }

        request.setAttribute("orderItems", orders.findItemsForOrders(userId, ids));
        request.setAttribute("tabs", tabs);
        request.setAttribute("tabCounts", counts);
        request.setAttribute("activeTab", tab);
        request.setAttribute("query", query);
        request.setAttribute("currentPage", page);
        request.setAttribute("pageCount", pageCount);
        request.setAttribute("resultCount", total);
        request.setAttribute("orders", list);
        request.getRequestDispatcher("/WEB-INF/customer-orders/list.jsp").forward(request, response);
    }

    private void showOrderDetail(HttpServletRequest request, HttpServletResponse response, int userId)
            throws SQLException, ServletException, IOException {
        int id = positiveId(request.getParameter("id"));
        if (id < 1) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Mã đơn hàng không hợp lệ.");
            return;
        }

        Order order = orders.findByIdAndUser(id, userId);
        if (order == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy đơn hàng.");
            return;
        }

        order.setOrderStatus(OrderService.normalizeStatus(order.getOrderStatus()));
        request.setAttribute("order", order);

        boolean paidOnline = OrderWorkflowService.isPaidOnline(
                order.getPaymentMethod(), order.getPaymentStatus(), order.getTotalAmount());
        boolean cancellableStatus = OrderWorkflowService.canCancel(order.getOrderStatus());
        boolean waitingForReview = "PENDING".equals(order.getCancelRequestStatus());
        request.setAttribute("canCancelOrder", cancellableStatus && !waitingForReview && !paidOnline);
        request.setAttribute("contactStoreToCancel", cancellableStatus && !waitingForReview && paidOnline);

        request.setAttribute("canRequestReturnExchange", returnExchangeDAO.canRequest(id, userId));
        request.setAttribute("latestReturnExchangeRequest", returnExchangeDAO.getLatestRequestByOrder(id, userId));
        request.setAttribute("items", orders.findItems(id, userId));

        List<Map<String, Object>> history = service.findHistory(id, userId);
        request.setAttribute("trackingSteps", OrderService.trackingSteps(order, history));
        Collections.reverse(history);
        request.setAttribute("history", history);

        request.getRequestDispatcher("/WEB-INF/customer-orders/detail.jsp").forward(request, response);
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        request.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");

        User user = customer(request, response);

        if (user == null) {
            return;
        }

        if (!"/my-orders/cancel"
                .equals(request.getServletPath())) {

            response.setHeader("Allow", "GET");
            response.sendError(405);
            return;
        }

        HttpSession session = request.getSession();

        String token = request.getParameter("csrfToken");

        if (token == null
                || !token.equals(
                        session.getAttribute("customerOrderToken")
                )) {

            response.sendError(
                    403,
                    "Yêu cầu không hợp lệ. Vui lòng tải lại trang."
            );
            return;
        }

        int id = positiveId(request.getParameter("id"));

        if (id < 1) {
            response.sendError(
                    400,
                    "Mã đơn hàng không hợp lệ."
            );
            return;
        }

        try {

            // Form hủy trực tiếp không gửi reason. Service kiểm tra
            // lý do dựa trên trạng thái mới nhất của đơn trong transaction.
            String reason = request.getParameter("reason");
            String result = orderWorkflow.customerCancel(
                    user.getUserId(), id, reason);
            session.setAttribute("customerOrderMessage",
                    "REQUESTED".equals(result) ? "Đã gửi yêu cầu hủy, vui lòng chờ nhân viên duyệt."
                    : "UNCHANGED".equals(result) ? "Đơn hàng đã được hủy trước đó."
                    : "Đã hủy đơn hàng thành công.");

        } catch (OrderNotFoundException ex) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, ex.getMessage());
            return;
        } catch (IllegalArgumentException ex) {

            session.setAttribute(
                    "customerOrderError",
                    ex.getMessage()
            );

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Cannot cancel customer order",
                    ex
            );

            session.setAttribute(
                    "customerOrderError",
                    "Chưa xác nhận được kết quả hủy. "
                    + "Vui lòng tải lại đơn hàng và thử lại."
            );
        }

        response.setStatus(
                HttpServletResponse.SC_SEE_OTHER
        );

        response.setHeader(
                "Location",
                response.encodeRedirectURL(
                        request.getContextPath()
                        + "/my-orders/detail?id="
                        + id
                )
        );
    }

    private User customer(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        HttpSession session
                = request.getSession(false);

        Object value = session == null
                ? null
                : session.getAttribute("loggedInUser");

        if (!(value instanceof User)) {

            request.getSession().setAttribute(
                    "redirectUrl",
                    request.getContextPath() + "/my-orders"
            );

            response.sendRedirect(
                    request.getContextPath() + "/login"
            );

            return null;
        }

        User user = (User) value;

        if (!user.isCustomer()) {
            response.sendError(403);
            return null;
        }

        return user;
    }

    private int positiveId(String value) {

        try {
            return Math.max(
                    -1,
                    Integer.parseInt(value)
            );
        } catch (NumberFormatException ex) {
            return -1;
        }
    }
}
