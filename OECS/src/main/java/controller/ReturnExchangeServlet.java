package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import model.User;
import service.ReturnExchangeService;

@WebServlet(
        name = "ReturnExchangeServlet",
        urlPatterns = {"/return-exchange"}
)
public class ReturnExchangeServlet extends HttpServlet {

    private final ReturnExchangeService returnExchangeService
            = new ReturnExchangeService();

    // =====================================================
    // 1. HIỂN THỊ BIỂU MẪU TRẢ HÀNG
    // =====================================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        User user = getLoggedInUser(request);

        if (user == null || !user.isCustomer()) {
            response.sendRedirect(
                    request.getContextPath() + "/login");
            return;
        }

        int orderId;

        try {
            orderId = Integer.parseInt(
                    request.getParameter("orderId"));

            if (orderId <= 0) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException ex) {
            response.sendRedirect(
                    request.getContextPath() + "/my-orders");
            return;
        }

        try {
            loadFormData(
                    request,
                    orderId,
                    user.getUserId()
            );

            request.getRequestDispatcher(
                    "/WEB-INF/customer-orders/return-exchange.jsp"
            ).forward(request, response);

        } catch (IllegalArgumentException ex) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/my-orders?message="
                    + URLEncoder.encode(
                            ex.getMessage(),
                            StandardCharsets.UTF_8
                    )
            );

        } catch (SQLException ex) {

            throw new ServletException(
                    "Không thể tải biểu mẫu trả hàng.",
                    ex
            );
        }
    }

    // =====================================================
    // 2. CUSTOMER GỬI YÊU CẦU TRẢ HÀNG
    // =====================================================
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");

        User user = getLoggedInUser(request);

        if (user == null || !user.isCustomer()) {
            response.sendRedirect(
                    request.getContextPath() + "/login");
            return;
        }

        int orderId;

        try {
            orderId = Integer.parseInt(
                    request.getParameter("orderId"));

            if (orderId <= 0) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException ex) {
            response.sendRedirect(
                    request.getContextPath() + "/my-orders");
            return;
        }

        // Chỉ hỗ trợ RETURN.
        // Không nhận requestType từ form để tránh
        // người dùng tự gửi giá trị EXCHANGE.
        final String requestType = "RETURN";

        String reason = request.getParameter("reason");

        String[] selectedItems
                = request.getParameterValues("orderItemId");

        List<Map<String, Integer>> items
                = new ArrayList<>();

        try {

            // Mỗi yêu cầu chỉ được chọn một sản phẩm.
            if (selectedItems == null
                    || selectedItems.length != 1) {

                throw new IllegalArgumentException(
                        "Mỗi yêu cầu trả hàng chỉ được chọn "
                        + "một sản phẩm.");
            }

            // Đọc danh sách sản phẩm và số lượng trả.
            for (String selectedItem : selectedItems) {

                int orderItemId
                        = Integer.parseInt(selectedItem);

                if (orderItemId <= 0) {
                    throw new IllegalArgumentException(
                            "Sản phẩm được chọn không hợp lệ.");
                }

                String quantityParam
                        = request.getParameter(
                                "quantity_" + orderItemId);

                if (quantityParam == null
                        || quantityParam.trim().isEmpty()) {

                    throw new IllegalArgumentException(
                            "Vui lòng nhập số lượng trả hàng.");
                }

                int quantity
                        = Integer.parseInt(quantityParam.trim());

                if (quantity <= 0) {
                    throw new IllegalArgumentException(
                            "Số lượng trả hàng phải lớn hơn 0.");
                }

                Map<String, Integer> item
                        = new HashMap<>();

                item.put("orderItemId", orderItemId);
                item.put("quantity", quantity);

                items.add(item);
            }

            // Tạo yêu cầu thông qua Service.
            // Service và DAO tiếp tục kiểm tra
            // quyền sở hữu, thời hạn và số lượng.
            int requestId
                    = returnExchangeService.createRequest(
                            orderId,
                            user.getUserId(),
                            requestType,
                            reason,
                            items
                    );

            // Thông báo sau khi gửi thành công.
            HttpSession session = request.getSession();

            session.setAttribute(
                    "returnSuccessMessage",
                    "Gửi yêu cầu trả hàng #"
                    + requestId
                    + " thành công! "
                    + "Cửa hàng sẽ xem xét và liên hệ "
                    + "với bạn để hướng dẫn xử lý."
            );

            session.setAttribute(
                    "returnSuccessOrderId",
                    orderId
            );

            // Quay về chi tiết đơn hàng sau khi gửi Return.
            response.sendRedirect(
                    request.getContextPath()
                    + "/my-orders/detail?id="
                    + orderId
            );

        } catch (NumberFormatException ex) {

            showFormError(
                    request,
                    response,
                    orderId,
                    user.getUserId(),
                    "Số lượng hoặc thông tin sản phẩm "
                    + "không hợp lệ."
            );

        } catch (IllegalArgumentException ex) {

            showFormError(
                    request,
                    response,
                    orderId,
                    user.getUserId(),
                    ex.getMessage()
            );

        } catch (SQLException ex) {

            throw new ServletException(
                    "Không thể tạo yêu cầu trả hàng.",
                    ex
            );
        }
    }

    // =====================================================
    // 3. TẢI DỮ LIỆU CHO FORM RETURN
    // =====================================================
    private void loadFormData(
            HttpServletRequest request,
            int orderId,
            int userId) throws SQLException {

        if (!returnExchangeService.canRequest(
                orderId, userId)) {

            throw new IllegalArgumentException(
                    "Đơn hàng chưa giao thành công, "
                    + "đã quá hạn 7 ngày hoặc "
                    + "không đủ điều kiện trả hàng."
            );
        }

        List<Map<String, Object>> orderItems
                = returnExchangeService.getOrderItems(
                        orderId,
                        userId
                );

        request.setAttribute(
                "orderId",
                orderId
        );

        request.setAttribute(
                "orderItems",
                orderItems
        );

        // Không còn exchangeSkus.
        // Không còn danh sách SKU đổi hàng.
    }

    // =====================================================
    // 4. HIỂN THỊ LỖI TRÊN FORM
    // =====================================================
    private void showFormError(
            HttpServletRequest request,
            HttpServletResponse response,
            int orderId,
            int userId,
            String message)
            throws ServletException, IOException {

        try {

            loadFormData(
                    request,
                    orderId,
                    userId
            );

            request.setAttribute(
                    "errorMessage",
                    message
            );

            request.getRequestDispatcher(
                    "/WEB-INF/customer-orders/return-exchange.jsp"
            ).forward(request, response);

        } catch (IllegalArgumentException ex) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/my-orders?message="
                    + URLEncoder.encode(
                            ex.getMessage(),
                            StandardCharsets.UTF_8
                    )
            );

        } catch (SQLException ex) {

            throw new ServletException(
                    "Không thể tải lại biểu mẫu trả hàng.",
                    ex
            );
        }
    }

    // =====================================================
    // 5. LẤY THÔNG TIN CUSTOMER ĐÃ ĐĂNG NHẬP
    // =====================================================
    private User getLoggedInUser(
            HttpServletRequest request) {

        HttpSession session
                = request.getSession(false);

        if (session == null) {
            return null;
        }

        Object loggedInUser
                = session.getAttribute("loggedInUser");

        if (loggedInUser instanceof User) {
            return (User) loggedInUser;
        }

        return null;
    }
}
