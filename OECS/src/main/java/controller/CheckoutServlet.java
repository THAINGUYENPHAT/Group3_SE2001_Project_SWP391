package controller;

import dao.AddressDAO;
import dao.CartDAO;
import dao.OrderDAO;
import dao.VoucherDAO;

import model.Address;
import model.CartItem;
import model.Order;
import model.User;
import model.Voucher;

import payment.PaymentGateway;
import service.OrderService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "CheckoutServlet",
        urlPatterns = {"/checkout"}
)
public class CheckoutServlet extends HttpServlet {

    private static final Logger LOGGER =
            Logger.getLogger(CheckoutServlet.class.getName());

    private final CartDAO cartDAO = new CartDAO();
    private final AddressDAO addressDAO = new AddressDAO();
    private final OrderDAO orderDAO = new OrderDAO();
    private final VoucherDAO voucherDAO = new VoucherDAO();
    private final OrderService orderService = new OrderService();

    // Hien thi checkout voi cac san pham da chon
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        User user = getLoggedInUser(request);

        if (user == null) {
            redirectToLogin(request, response);
            return;
        }

        HttpSession session = request.getSession();

        String[] values = request.getParameterValues("selectedItems");

        if (values != null) {
            List<Integer> ids = parseSelectedIds(values);

            if (ids.isEmpty()) {
                session.setAttribute(
                        "errorMessage",
                        "Vui lòng chọn ít nhất một sản phẩm."
                );

                response.sendRedirect(
                        request.getContextPath() + "/cart"
                );
                return;
            }

            session.setAttribute("checkoutSelectedItemIds", ids);
        }

        showCheckout(request, response, user);
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        User user = getLoggedInUser(request);

        if (user == null) {
            if ("selectAddress".equals(action)
                    || "editAddress".equals(action)
                    || "deleteAddress".equals(action)) {

                sendJsonError(
                        response,
                        401,
                        "Phiên đăng nhập đã hết hạn. "
                        + "Vui lòng đăng nhập lại."
                );
            } else {
                redirectToLogin(request, response);
            }
            return;
        }

        if ("addAddress".equals(action)) {
            addAddress(request, response, user);

        } else if ("selectAddress".equals(action)) {
            selectAddress(request, response, user);

        } else if ("editAddress".equals(action)) {
            editAddress(request, response, user);

        } else if ("deleteAddress".equals(action)) {
            deleteAddress(request, response, user);

        } else if ("applyVoucher".equals(action)) {
            applyVoucher(request, response, user);

        } else if ("removeVoucher".equals(action)) {
            removeVoucher(request, response);

        } else if ("placeOrder".equals(action)) {
            placeOrder(request, response, user);

        } else {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Action không hợp lệ."
            );
        }
    }

    // Tai du lieu trang checkout
    private void showCheckout(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws ServletException, IOException {

        int userId = user.getUserId();
        int cartId = cartDAO.getCartIdByUserId(userId);

        if (cartId <= 0) {
            response.sendRedirect(
                    request.getContextPath() + "/cart"
            );
            return;
        }

        HttpSession session = request.getSession();
        List<Integer> selectedIds = getSelectedIds(session);

        if (selectedIds.isEmpty()) {
            session.setAttribute(
                    "errorMessage",
                    "Vui lòng chọn sản phẩm cần đặt hàng."
            );

            response.sendRedirect(
                    request.getContextPath() + "/cart"
            );
            return;
        }

        List<CartItem> cartItems = cartDAO.getCartItemsByIds(
                cartId,
                selectedIds
        );

        if (cartItems == null
                || cartItems.isEmpty()
                || cartItems.size() != selectedIds.size()) {

            session.removeAttribute("checkoutSelectedItemIds");
            session.removeAttribute("appliedVoucher");

            session.setAttribute(
                    "errorMessage",
                    "Một số sản phẩm đã không còn trong giỏ hàng."
            );

            response.sendRedirect(
                    request.getContextPath() + "/cart"
            );
            return;
        }

        for (CartItem item : cartItems) {
            if (item.getStockQuantity() <= 0
                    || item.getQuantity() > item.getStockQuantity()) {

                session.setAttribute(
                        "errorMessage",
                        "Sản phẩm " + item.getProductName()
                        + " không đủ số lượng tồn kho."
                );

                response.sendRedirect(
                        request.getContextPath() + "/cart"
                );
                return;
            }
        }

        // Tao token cho cac thao tac checkout
        synchronized (session) {
            if (session.getAttribute("addressAddToken") == null) {
                session.setAttribute(
                        "addressAddToken",
                        UUID.randomUUID().toString()
                );
            }

            if (session.getAttribute("addressActionToken") == null) {
                session.setAttribute(
                        "addressActionToken",
                        UUID.randomUUID().toString()
                );
            }

            if (session.getAttribute("checkoutToken") == null) {
                session.setAttribute(
                        "checkoutToken",
                        UUID.randomUUID().toString()
                );
            }
        }

        List<Address> addresses =
                addressDAO.getAddressesByUser(userId);

        Address selectedAddress = null;
        Object savedId = session.getAttribute("selectedAddressId");

        if (savedId instanceof Integer) {
            selectedAddress = addressDAO.getAddressById(
                    (Integer) savedId,
                    userId
            );
        }

        if (selectedAddress == null
                && addresses != null
                && !addresses.isEmpty()) {

            selectedAddress = addresses.get(0);
        }

        if (selectedAddress != null) {
            session.setAttribute(
                    "selectedAddressId",
                    selectedAddress.getAddressId()
            );
        } else {
            session.removeAttribute("selectedAddressId");
        }

        double subtotal = calculateSubtotal(cartItems);
        double shippingFee = 0;
        double discount = 0;

        Voucher appliedVoucher =
                (Voucher) session.getAttribute("appliedVoucher");

        // Kiem tra lai voucher theo cac san pham dang checkout
        if (appliedVoucher != null) {
            Voucher valid = voucherDAO.getValidVoucher(
                    appliedVoucher.getCode(),
                    subtotal,
                    userId
            );

            if (valid != null) {
                appliedVoucher = valid;

                discount = voucherDAO.calculateDiscount(
                        valid,
                        subtotal
                );

                session.setAttribute("appliedVoucher", valid);
            } else {
                appliedVoucher = null;
                session.removeAttribute("appliedVoucher");

                session.setAttribute(
                        "checkoutError",
                        "Voucher đã chọn không còn phù hợp "
                        + "với đơn hàng này."
                );
            }
        }

        List<Voucher> availableVouchers =
                voucherDAO.getAvailableVouchers(subtotal, userId);

        request.setAttribute("cartItems", cartItems);
        request.setAttribute("addresses", addresses);
        request.setAttribute("selectedAddress", selectedAddress);
        request.setAttribute("availableVouchers", availableVouchers);
        request.setAttribute("appliedVoucher", appliedVoucher);
        request.setAttribute("subtotal", subtotal);
        request.setAttribute("shippingFee", shippingFee);
        request.setAttribute("discount", discount);

        request.setAttribute(
                "totalAmount",
                Math.max(0, subtotal + shippingFee - discount)
        );

        // Chi bat cong sandbox khi da co cau hinh
        request.setAttribute(
                "vnpayAvailable",
                PaymentGateway.available("VNPAY")
        );

        request.setAttribute(
                "momoAvailable",
                PaymentGateway.available("MOMO")
        );

        request.getRequestDispatcher(
                "/WEB-INF/checkout/checkout.jsp"
        ).forward(request, response);
    }

    // Them dia chi va chon lam dia chi mac dinh
    private void addAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws IOException {

        HttpSession session = request.getSession();
        String submittedToken = request.getParameter("addressAddToken");

        synchronized (session) {
            String expectedToken =
                    (String) session.getAttribute("addressAddToken");

            if (expectedToken == null
                    || submittedToken == null
                    || !expectedToken.equals(submittedToken)) {

                session.setAttribute(
                        "checkoutError",
                        "Yêu cầu thêm địa chỉ đã được xử lý "
                        + "hoặc hết hạn."
                );

                redirectToCheckout(request, response);
                return;
            }

            session.removeAttribute("addressAddToken");
        }

        String name = request.getParameter("recipientName");
        String phone = request.getParameter("phoneNumber");
        String line = request.getParameter("addressLine");

        if (!validAddressInput(name, phone, line)) {
            session.setAttribute(
                    "checkoutError",
                    "Thông tin địa chỉ không hợp lệ."
            );

            redirectToCheckout(request, response);
            return;
        }

        int newId = addressDAO.insertAddress(
                user.getUserId(),
                name.trim(),
                phone.trim(),
                line.trim()
        );

        if (newId > 0) {
            session.setAttribute("selectedAddressId", newId);

            try {
                if (!addressDAO.setDefaultAddress(
                        newId,
                        user.getUserId()
                )) {
                    throw new SQLException(
                            "Không lưu được địa chỉ mặc định."
                    );
                }

            } catch (SQLException e) {
                LOGGER.log(
                        Level.SEVERE,
                        "Không lưu được địa chỉ mặc định mới.",
                        e
                );

                session.setAttribute(
                        "checkoutError",
                        "Đã thêm địa chỉ nhưng chưa lưu được "
                        + "địa chỉ mặc định. Vui lòng chọn lại địa chỉ."
                );

                redirectToCheckout(request, response);
                return;
            }

            session.setAttribute(
                    "checkoutMessage",
                    "Đã thêm địa chỉ thành công."
            );

        } else {
            session.setAttribute(
                    "checkoutError",
                    "Không thể thêm địa chỉ."
            );
        }

        redirectToCheckout(request, response);
    }

    // Chon dia chi bang AJAX
    private void selectAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws IOException {

        HttpSession session = request.getSession();

        if (!validAddressActionToken(request, session)) {
            sendJsonError(
                    response,
                    403,
                    "Yêu cầu chọn địa chỉ không hợp lệ."
            );
            return;
        }

        int addressId = parsePositiveInt(
                request.getParameter("addressId")
        );

        if (addressId <= 0) {
            sendJsonError(response, 400, "ID địa chỉ không hợp lệ.");
            return;
        }

        synchronized (session) {
            Address address = addressDAO.getAddressById(
                    addressId,
                    user.getUserId()
            );

            if (address == null) {
                sendJsonError(
                        response,
                        404,
                        "Địa chỉ không tồn tại hoặc đã bị xóa."
                );
                return;
            }

            try {
                if (!addressDAO.setDefaultAddress(
                        addressId,
                        user.getUserId()
                )) {
                    sendJsonError(
                            response,
                            404,
                            "Địa chỉ không còn khả dụng."
                    );
                    return;
                }

                session.setAttribute("selectedAddressId", addressId);
                address.setDefaultAddress(true);

                sendSelectedAddressJson(
                        response,
                        addressId,
                        address
                );

            } catch (SQLException e) {
                LOGGER.log(
                        Level.SEVERE,
                        "Không lưu được địa chỉ checkout.",
                        e
                );

                sendJsonError(
                        response,
                        500,
                        "Chưa lưu được địa chỉ đã chọn. "
                        + "Vui lòng thử lại."
                );
            }
        }
    }

    // Sua dia chi bang AJAX
    private void editAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws IOException {

        HttpSession session = request.getSession();

        if (!validAddressActionToken(request, session)) {
            sendJsonError(
                    response,
                    403,
                    "Yêu cầu sửa địa chỉ không hợp lệ. "
                    + "Vui lòng tải lại trang."
            );
            return;
        }

        int addressId = parsePositiveInt(
                request.getParameter("addressId")
        );

        String name = request.getParameter("recipientName");
        String phone = request.getParameter("phoneNumber");
        String line = request.getParameter("addressLine");

        if (addressId <= 0 || !validAddressInput(name, phone, line)) {
            sendJsonError(
                    response,
                    400,
                    "Nhập đủ tên (tối đa 100 ký tự), "
                    + "số điện thoại 9–11 chữ số và địa chỉ."
            );
            return;
        }

        synchronized (session) {
            try {
                boolean updated = addressDAO.updateAddress(
                        addressId,
                        user.getUserId(),
                        name.trim(),
                        phone.trim(),
                        line.trim()
                );

                if (!updated) {
                    sendJsonError(
                            response,
                            404,
                            "Địa chỉ không tồn tại hoặc đã bị xóa."
                    );
                    return;
                }

                response.setContentType(
                        "application/json;charset=UTF-8"
                );

                String json =
                        "{\"success\":true,"
                        + "\"address\":{"
                        + "\"addressId\":" + addressId + ","
                        + "\"recipientName\":\""
                        + jsonEscape(name.trim()) + "\","
                        + "\"phoneNumber\":\""
                        + jsonEscape(phone.trim()) + "\","
                        + "\"addressLine\":\""
                        + jsonEscape(line.trim()) + "\"}}";

                response.getWriter().write(json);

            } catch (SQLException e) {
                LOGGER.log(Level.SEVERE, "Lỗi sửa địa chỉ.", e);

                sendJsonError(
                        response,
                        500,
                        "Không thể lưu địa chỉ. Vui lòng thử lại."
                );
            }
        }
    }

    // Xoa dia chi khong duoc chon
    private void deleteAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws IOException {

        HttpSession session = request.getSession();

        if (!validAddressActionToken(request, session)) {
            sendJsonError(
                    response,
                    403,
                    "Yêu cầu xóa địa chỉ không hợp lệ."
            );
            return;
        }

        int addressId = parsePositiveInt(
                request.getParameter("addressId")
        );

        if (addressId <= 0) {
            sendJsonError(response, 400, "ID địa chỉ không hợp lệ.");
            return;
        }

        synchronized (session) {
            Object selected = session.getAttribute("selectedAddressId");

            if (selected instanceof Integer
                    && ((Integer) selected) == addressId) {

                sendJsonError(
                        response,
                        409,
                        "Không thể xóa địa chỉ đang chọn. "
                        + "Vui lòng chọn và xác nhận địa chỉ khác trước."
                );
                return;
            }

            boolean deleted = addressDAO.deleteAddress(
                    addressId,
                    user.getUserId()
            );

            if (!deleted) {
                sendJsonError(
                        response,
                        400,
                        "Không thể xóa địa chỉ này."
                );
                return;
            }

            response.setContentType(
                    "application/json;charset=UTF-8"
            );

            response.getWriter().write(
                    "{\"success\":true,\"deletedId\":"
                    + addressId + "}"
            );
        }
    }

    // Ap dung voucher cho cac san pham duoc chon
    private void applyVoucher(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws IOException {

        HttpSession session = request.getSession();
        String code = request.getParameter("voucherCode");

        if (code == null || code.trim().isEmpty()) {
            session.setAttribute(
                    "checkoutError",
                    "Vui lòng chọn Voucher."
            );

            redirectToCheckout(request, response);
            return;
        }

        int cartId = cartDAO.getCartIdByUserId(user.getUserId());

        if (cartId <= 0) {
            session.setAttribute(
                    "checkoutError",
                    "Giỏ hàng đang trống."
            );

            response.sendRedirect(
                    request.getContextPath() + "/cart"
            );
            return;
        }

        List<CartItem> items = getSelectedCartItems(session, cartId);
        List<Integer> selectedIds = getSelectedIds(session);

        if (items.isEmpty() || items.size() != selectedIds.size()) {
            session.setAttribute(
                    "checkoutError",
                    "Không tìm thấy đầy đủ các sản phẩm đang Checkout."
            );

            response.sendRedirect(
                    request.getContextPath() + "/cart"
            );
            return;
        }

        double subtotal = calculateSubtotal(items);

        Voucher voucher = voucherDAO.getValidVoucher(
                code.trim(),
                subtotal,
                user.getUserId()
        );

        if (voucher == null) {
            session.setAttribute(
                    "checkoutError",
                    "Voucher không hợp lệ, chưa đủ điều kiện "
                    + "hoặc đã hết lượt."
            );

        } else {
            session.setAttribute("appliedVoucher", voucher);

            session.setAttribute(
                    "checkoutMessage",
                    "Áp dụng Voucher " + voucher.getCode()
                    + " thành công."
            );
        }

        redirectToCheckout(request, response);
    }

    private void removeVoucher(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        HttpSession session = request.getSession();

        session.removeAttribute("appliedVoucher");
        session.setAttribute("checkoutMessage", "Đã bỏ Voucher.");

        redirectToCheckout(request, response);
    }

    // Dat hang COD hoac online
    private void placeOrder(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws IOException {

        HttpSession session = request.getSession();
        String checkoutToken = request.getParameter("checkoutToken");

        try {
            if (checkoutToken == null
                    || !checkoutToken.matches("[0-9a-fA-F-]{36}")) {

                throw new IllegalArgumentException(
                        "Phiên đặt hàng không hợp lệ. "
                        + "Vui lòng tải lại Checkout."
                );
            }

            int orderId;

            synchronized (session) {
                // Neu request lap lai thi tra ve don da tao
                Integer existingOrderId = orderDAO.findIdByToken(
                        user.getUserId(),
                        checkoutToken
                );

                if (existingOrderId != null) {
                    orderId = existingOrderId;

                } else {
                    Object expectedToken =
                            session.getAttribute("checkoutToken");

                    if (!(expectedToken instanceof String)
                            || !checkoutToken.equals(expectedToken)) {

                        throw new IllegalArgumentException(
                                "Phiên đặt hàng đã hết hạn. "
                                + "Vui lòng tải lại Checkout."
                        );
                    }

                    // Kiem tra phuong thuc va cau hinh sandbox
                    String method = request.getParameter("paymentMethod");
                    PaymentGateway.requireConfigured(method);

                    int addressId = parsePositiveInt(
                            request.getParameter("addressId")
                    );

                    Object selectedAddressId =
                            session.getAttribute("selectedAddressId");

                    if (addressId <= 0
                            || !(selectedAddressId instanceof Integer)
                            || ((Integer) selectedAddressId) != addressId) {

                        throw new IllegalArgumentException(
                                "Vui lòng chọn và xác nhận "
                                + "địa chỉ giao hàng."
                        );
                    }

                    List<Integer> selectedIds = getSelectedIds(session);

                    if (selectedIds.isEmpty()) {
                        throw new IllegalArgumentException(
                                "Không tìm thấy sản phẩm đã chọn."
                        );
                    }

                    Voucher voucher =
                            (Voucher) session.getAttribute("appliedVoucher");

                    String voucherCode = voucher == null
                            ? null
                            : voucher.getCode();

                    // Service tu kiem tra va luu trong transaction
                    orderId = orderService.placeOrder(
                            user.getUserId(),
                            addressId,
                            checkoutToken,
                            voucherCode,
                            selectedIds,
                            method
                    );
                }

                // Chi xoa state cua dung phien checkout vua xu ly
                if (checkoutToken.equals(
                        session.getAttribute("checkoutToken")
                )) {
                    session.removeAttribute("checkoutToken");
                    session.removeAttribute("appliedVoucher");
                    session.removeAttribute("checkoutSelectedItemIds");
                }
            }

            Order savedOrder = orderDAO.findByIdAndUser(
                    orderId,
                    user.getUserId()
            );

            // Don online chua tra tien di den trang thanh toan
            // COD hoac don 0 dong giu trang dat hang thanh cong
            String nextPage =
                    savedOrder != null
                    && "PENDING_PAYMENT".equals(savedOrder.getOrderStatus())
                            ? "/payment?id="
                            : "/order-success?id=";

            response.setStatus(HttpServletResponse.SC_SEE_OTHER);

            response.setHeader(
                    "Location",
                    response.encodeRedirectURL(
                            request.getContextPath() + nextPage + orderId
                    )
            );

        } catch (IllegalArgumentException e) {
            session.setAttribute("checkoutError", e.getMessage());
            redirectToCheckout(request, response);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi đặt hàng.", e);

            session.setAttribute(
                    "checkoutError",
                    "Chưa xác nhận được kết quả đặt hàng. "
                    + "Vui lòng thử lại."
            );

            redirectToCheckout(request, response);
        }
    }

    // Lay danh sach cart_item_id da chon trong session
    private List<Integer> getSelectedIds(HttpSession session) {
        Object value = session.getAttribute("checkoutSelectedItemIds");

        if (!(value instanceof List<?>)) {
            return new ArrayList<>();
        }

        List<Integer> result = new ArrayList<>();

        for (Object item : (List<?>) value) {
            if (item instanceof Integer) {
                Integer id = (Integer) item;

                if (id > 0 && !result.contains(id)) {
                    result.add(id);
                }
            }
        }

        return result;
    }

    private List<CartItem> getSelectedCartItems(
            HttpSession session,
            int cartId
    ) {
        if (cartId <= 0) {
            return new ArrayList<>();
        }

        List<Integer> ids = getSelectedIds(session);

        if (ids.isEmpty()) {
            return new ArrayList<>();
        }

        List<CartItem> items = cartDAO.getCartItemsByIds(cartId, ids);

        return items == null ? new ArrayList<>() : items;
    }

    private List<Integer> parseSelectedIds(String[] values) {
        List<Integer> list = new ArrayList<>();

        if (values == null) {
            return list;
        }

        for (String value : values) {
            int id = parsePositiveInt(value);

            if (id > 0 && !list.contains(id)) {
                list.add(id);
            }
        }

        return list;
    }

    private double calculateSubtotal(List<CartItem> items) {
        double total = 0;

        if (items == null) {
            return total;
        }

        for (CartItem item : items) {
            total += item.getPrice() * item.getQuantity();
        }

        return total;
    }

    private boolean validAddressInput(
            String name,
            String phone,
            String line
    ) {
        return name != null
                && !name.trim().isEmpty()
                && name.trim().length() <= 100
                && phone != null
                && phone.trim().matches("[0-9]{9,11}")
                && line != null
                && !line.trim().isEmpty();
    }

    private boolean validAddressActionToken(
            HttpServletRequest request,
            HttpSession session
    ) {
        String submitted = request.getParameter("addressActionToken");
        Object expected = session.getAttribute("addressActionToken");

        return submitted != null
                && expected instanceof String
                && submitted.equals(expected);
    }

    private void sendSelectedAddressJson(
            HttpServletResponse response,
            int addressId,
            Address address
    ) throws IOException {

        response.setContentType("application/json;charset=UTF-8");

        String json =
                "{\"success\":true,"
                + "\"selectedAddress\":{"
                + "\"addressId\":" + addressId + ","
                + "\"recipientName\":\""
                + jsonEscape(address.getRecipientName()) + "\","
                + "\"phoneNumber\":\""
                + jsonEscape(address.getPhoneNumber()) + "\","
                + "\"addressLine\":\""
                + jsonEscape(address.getAddressLine()) + "\","
                + "\"defaultAddress\":"
                + address.isDefaultAddress() + "}}";

        response.getWriter().write(json);
    }

    private void sendJsonError(
            HttpServletResponse response,
            int status,
            String message
    ) throws IOException {

        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");

        response.getWriter().write(
                "{\"success\":false,\"message\":\""
                + jsonEscape(message) + "\"}"
        );
    }

    private String jsonEscape(String value) {
        if (value == null) {
            return "";
        }

        StringBuilder result = new StringBuilder();

        for (char c : value.toCharArray()) {
            switch (c) {
                case '"':
                    result.append("\\\"");
                    break;

                case '\\':
                    result.append("\\\\");
                    break;

                case '\n':
                    result.append("\\n");
                    break;

                case '\r':
                    result.append("\\r");
                    break;

                case '\t':
                    result.append("\\t");
                    break;

                default:
                    if (c < 0x20) {
                        result.append(
                                String.format("\\u%04x", (int) c)
                        );
                    } else {
                        result.append(c);
                    }
                    break;
            }
        }

        return result.toString();
    }

    private int parsePositiveInt(String value) {
        try {
            int id = Integer.parseInt(value);
            return id > 0 ? id : -1;

        } catch (NumberFormatException e) {
            return -1;
        }
    }

    private User getLoggedInUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        if (session == null) {
            return null;
        }

        Object value = session.getAttribute("loggedInUser");

        return value instanceof User ? (User) value : null;
    }

    private void redirectToLogin(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        request.getSession().setAttribute(
                "redirectUrl",
                request.getContextPath() + "/checkout"
        );

        response.sendRedirect(
                request.getContextPath() + "/login"
        );
    }

    private void redirectToCheckout(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        response.sendRedirect(
                request.getContextPath() + "/checkout"
        );
    }
}