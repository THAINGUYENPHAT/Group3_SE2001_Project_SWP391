package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import model.User;
import service.ReturnExchangeService;

@WebServlet(name = "ReturnExchangeServlet", urlPatterns = {"/return-exchange"})
public class ReturnExchangeServlet extends HttpServlet {

    private final ReturnExchangeService returnExchangeService =
            new ReturnExchangeService();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        User user = getLoggedInUser(request);

        if (user == null || !user.isCustomer()) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String orderIdParam = request.getParameter("orderId");
        int orderId;

        try {
            orderId = Integer.parseInt(orderIdParam);

            if (orderId <= 0) {
                throw new NumberFormatException();
            }
        } catch (NumberFormatException ex) {
            response.sendRedirect(
                    request.getContextPath() + "/my-orders");
            return;
        }

        try {
            loadFormData(request, orderId, user.getUserId());

            request.getRequestDispatcher(
                    "/WEB-INF/customer-orders/return-exchange.jsp")
                    .forward(request, response);

        } catch (IllegalArgumentException ex) {
            response.sendRedirect(
                    request.getContextPath()
                    + "/my-orders?message="
                    + java.net.URLEncoder.encode(
                            ex.getMessage(),
                            java.nio.charset.StandardCharsets.UTF_8));

        } catch (SQLException ex) {
            throw new ServletException(
                    "Không thể tải dữ liệu đổi/trả hàng.", ex);
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        User user = getLoggedInUser(request);

        if (user == null || !user.isCustomer()) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        int orderId;

        try {
            orderId = Integer.parseInt(request.getParameter("orderId"));

            if (orderId <= 0) {
                throw new NumberFormatException();
            }
        } catch (NumberFormatException ex) {
            response.sendRedirect(
                    request.getContextPath() + "/my-orders");
            return;
        }

        String requestType = request.getParameter("requestType");
        String reason = request.getParameter("reason");
        String[] selectedItems = request.getParameterValues("orderItemId");

        List<Map<String, Integer>> items = new ArrayList<>();

        try {
            if (selectedItems == null || selectedItems.length == 0) {
                throw new IllegalArgumentException(
                        "Vui lòng chọn ít nhất một sản phẩm.");
            }

            for (String selectedItem : selectedItems) {
                int orderItemId = Integer.parseInt(selectedItem);

                if (orderItemId <= 0) {
                    throw new IllegalArgumentException(
                            "Sản phẩm được chọn không hợp lệ.");
                }

                String quantityParam =
                        request.getParameter("quantity_" + orderItemId);

                int quantity = Integer.parseInt(quantityParam);

                Map<String, Integer> item = new HashMap<>();
                item.put("orderItemId", orderItemId);
                item.put("quantity", quantity);

                String exchangeSkuParam =
                        request.getParameter("exchangeSkuId_" + orderItemId);

                if ("EXCHANGE".equals(requestType)) {
                    if (exchangeSkuParam == null
                            || exchangeSkuParam.trim().isEmpty()) {
                        throw new IllegalArgumentException(
                                "Vui lòng chọn SKU muốn đổi cho mỗi sản phẩm.");
                    }

                    int exchangeSkuId = Integer.parseInt(exchangeSkuParam);

                    if (exchangeSkuId <= 0) {
                        throw new IllegalArgumentException(
                                "SKU thay thế không hợp lệ.");
                    }

                    item.put("exchangeSkuId", exchangeSkuId);

                } else if ("RETURN".equals(requestType)) {
                    item.put("exchangeSkuId", null);

                } else {
                    throw new IllegalArgumentException(
                            "Loại yêu cầu không hợp lệ.");
                }

                items.add(item);
            }

            int requestId = returnExchangeService.createRequest(
                    orderId,
                    user.getUserId(),
                    requestType,
                    reason,
                    items
            );

            response.sendRedirect(
                    request.getContextPath()
                    + "/my-orders?message="
                    + java.net.URLEncoder.encode(
                            "Đã gửi yêu cầu đổi/trả hàng #" + requestId,
                            java.nio.charset.StandardCharsets.UTF_8));

        } catch (NumberFormatException ex) {
            showFormError(
                    request,
                    response,
                    orderId,
                    user.getUserId(),
                    "Số lượng hoặc thông tin sản phẩm không hợp lệ.");

        } catch (IllegalArgumentException ex) {
            showFormError(
                    request,
                    response,
                    orderId,
                    user.getUserId(),
                    ex.getMessage());

        } catch (SQLException ex) {
            throw new ServletException(
                    "Không thể tạo yêu cầu đổi/trả hàng.", ex);
        }
    }

    private void loadFormData(
            HttpServletRequest request,
            int orderId,
            int userId) throws SQLException {

        if (!returnExchangeService.canRequest(orderId, userId)) {
            throw new IllegalArgumentException(
                    "Đơn hàng chưa giao thành công hoặc đã quá hạn 7 ngày.");
        }

        List<Map<String, Object>> orderItems =
                returnExchangeService.getOrderItems(orderId, userId);

        Map<Integer, List<Map<String, Object>>> exchangeSkus =
                new HashMap<>();

        for (Map<String, Object> item : orderItems) {
            int orderItemId = (Integer) item.get("orderItemId");

            exchangeSkus.put(
                    orderItemId,
                    returnExchangeService.getExchangeSkus(
                            orderId,
                            orderItemId,
                            userId));
        }

        request.setAttribute("orderId", orderId);
        request.setAttribute("orderItems", orderItems);
        request.setAttribute("exchangeSkus", exchangeSkus);
    }

    private void showFormError(
            HttpServletRequest request,
            HttpServletResponse response,
            int orderId,
            int userId,
            String message)
            throws ServletException, IOException {

        try {
            loadFormData(request, orderId, userId);
            request.setAttribute("errorMessage", message);

            request.getRequestDispatcher(
                    "/WEB-INF/customer-orders/return-exchange.jsp")
                    .forward(request, response);

        } catch (IllegalArgumentException ex) {
            response.sendRedirect(
                    request.getContextPath() + "/my-orders");

        } catch (SQLException ex) {
            throw new ServletException(
                    "Không thể tải lại biểu mẫu đổi/trả hàng.", ex);
        }
    }

    private User getLoggedInUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        if (session == null) {
            return null;
        }

        Object loggedInUser = session.getAttribute("loggedInUser");

        if (loggedInUser instanceof User) {
            return (User) loggedInUser;
        }

        return null;
    }
}