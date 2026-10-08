package controller;

import dao.AddressDAO;
import dao.CartDAO;
import dao.OrderDAO;
import dao.VoucherDAO;

import model.Address;
import model.CartItem;
import model.User;
import model.Voucher;

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

@WebServlet(name = "CheckoutServlet", urlPatterns = {"/checkout"})
public class CheckoutServlet extends HttpServlet {

    private static final Logger LOGGER =
            Logger.getLogger(CheckoutServlet.class.getName());

    private final CartDAO cartDAO = new CartDAO();
    private final AddressDAO addressDAO = new AddressDAO();
    private final OrderDAO orderDAO = new OrderDAO();
    private final VoucherDAO voucherDAO = new VoucherDAO();
    private final OrderService orderService = new OrderService();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        User user = getLoggedInUser(request);

        if (user == null) {
            redirectToLogin(request, response);
            return;
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
                        "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
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
            response.sendError(400, "Action khong hop le.");
        }
    }

    // HIEN THI CHECKOUT
    private void showCheckout(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws ServletException, IOException {

        int userId = user.getUserId();
        int cartId = cartDAO.getCartIdByUserId(userId);

        if (cartId <= 0) {
            response.sendRedirect(request.getContextPath() + "/cart");
            return;
        }

        List<CartItem> cartItems = cartDAO.getCartItems(cartId);

        if (cartItems == null || cartItems.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/cart");
            return;
        }

        HttpSession session = request.getSession();

        // TAO TOKEN CHO DIA CHI VA DAT HANG
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

        // LAY DIA CHI DA CHON TRONG SESSION
        if (savedId instanceof Integer) {
            selectedAddress = addressDAO.getAddressById(
                    (Integer) savedId,
                    userId
            );
        }

        // CHUA CHON THI LAY DIA CHI DAU TIEN
        if (selectedAddress == null && !addresses.isEmpty()) {
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

        double subtotal = cartDAO.getCartTotal(cartId);
        double shippingFee = 0;
        double discount = 0;

        Voucher appliedVoucher =
                (Voucher) session.getAttribute("appliedVoucher");

        // KIEM TRA VOUCHER DE HIEN THI TREN GIAO DIEN
        if (appliedVoucher != null) {
            Voucher valid = voucherDAO.getValidVoucher(
                    appliedVoucher.getCode(),
                    subtotal,
                    userId
            );

            if (valid != null) {
                appliedVoucher = valid;
                discount = voucherDAO.calculateDiscount(valid, subtotal);
                session.setAttribute("appliedVoucher", valid);

            } else {
                appliedVoucher = null;
                session.removeAttribute("appliedVoucher");
                session.setAttribute(
                        "checkoutError",
                        "Voucher đã chọn không còn hợp lệ."
                );
            }
        }

        List<Voucher> availableVouchers = new ArrayList<>();

        for (Voucher voucher : voucherDAO.getAllVouchers()) {
            Voucher valid = voucherDAO.getValidVoucher(
                    voucher.getCode(),
                    subtotal,
                    userId
            );

            if (valid != null) {
                availableVouchers.add(valid);
            }
        }

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

        request.getRequestDispatcher(
                "/WEB-INF/checkout/checkout.jsp"
        ).forward(request, response);
    }

    // THEM DIA CHI VA CHAN REQUEST LAP
    private void addAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws IOException {

        HttpSession session = request.getSession();

        String submittedToken =
                request.getParameter("addressAddToken");

        synchronized (session) {
            String expectedToken =
                    (String) session.getAttribute("addressAddToken");

            if (expectedToken == null
                    || submittedToken == null
                    || !expectedToken.equals(submittedToken)) {

                session.setAttribute(
                        "checkoutError",
                        "Yêu cầu thêm địa chỉ đã được xử lý hoặc hết hạn."
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

    // CHON DIA CHI GIAO HANG
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

            session.setAttribute("selectedAddressId", addressId);

            sendSelectedAddressJson(response, addressId, address);
        }
    }

    // CHINH SUA DIA CHI
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
                    "Yêu cầu sửa địa chỉ không hợp lệ. Vui lòng tải lại trang."
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
                        name,
                        phone,
                        line
                );

                if (!updated) {
                    sendJsonError(
                            response,
                            404,
                            "Địa chỉ không tồn tại hoặc đã bị xóa."
                    );
                    return;
                }

                response.setContentType("application/json;charset=UTF-8");

                String json = "{\"success\":true,\"address\":{"
                        + "\"addressId\":" + addressId + ","
                        + "\"recipientName\":\""
                        + jsonEscape(name.trim()) + "\","
                        + "\"phoneNumber\":\""
                        + jsonEscape(phone.trim()) + "\","
                        + "\"addressLine\":\""
                        + jsonEscape(line.trim()) + "\"}}";

                response.getWriter().write(json);

            } catch (SQLException e) {
                LOGGER.log(Level.SEVERE, "Loi sua dia chi!", e);

                sendJsonError(
                        response,
                        500,
                        "Không thể lưu địa chỉ. Vui lòng thử lại."
                );
            }
        }
    }

    // XOA MEM DIA CHI, KHONG XOA DIA CHI DANG CHON
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
            Object selected =
                    session.getAttribute("selectedAddressId");

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

            response.setContentType("application/json;charset=UTF-8");

            response.getWriter().write(
                    "{\"success\":true,\"deletedId\":" + addressId + "}"
            );
        }
    }

    // KIEM TRA NOI DUNG DIA CHI
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

    // KIEM TRA TOKEN THAO TAC DIA CHI
    private boolean validAddressActionToken(
            HttpServletRequest request,
            HttpSession session
    ) {
        String submitted =
                request.getParameter("addressActionToken");

        Object expected =
                session.getAttribute("addressActionToken");

        return submitted != null
                && expected instanceof String
                && submitted.equals(expected);
    }

    // GUI DIA CHI VUA CHON VE GIAO DIEN
    private void sendSelectedAddressJson(
            HttpServletResponse response,
            int addressId,
            Address address
    ) throws IOException {

        response.setContentType("application/json;charset=UTF-8");

        String json = "{\"success\":true,\"selectedAddress\":{"
                + "\"addressId\":" + addressId + ","
                + "\"recipientName\":\""
                + jsonEscape(address.getRecipientName()) + "\","
                + "\"phoneNumber\":\""
                + jsonEscape(address.getPhoneNumber()) + "\","
                + "\"addressLine\":\""
                + jsonEscape(address.getAddressLine()) + "\","
                + "\"defaultAddress\":" + address.isDefaultAddress()
                + "}}";

        response.getWriter().write(json);
    }

    // CHON VOUCHER DE HIEN THI TREN CHECKOUT
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
                    "Vui lòng nhập mã voucher."
            );

            redirectToCheckout(request, response);
            return;
        }

        int cartId = cartDAO.getCartIdByUserId(user.getUserId());

        if (cartId <= 0) {
            session.setAttribute("checkoutError", "Giỏ hàng đang trống.");
            response.sendRedirect(request.getContextPath() + "/cart");
            return;
        }

        List<CartItem> items = cartDAO.getCartItems(cartId);

        if (items == null || items.isEmpty()) {
            session.setAttribute("checkoutError", "Giỏ hàng đang trống.");
            response.sendRedirect(request.getContextPath() + "/cart");
            return;
        }

        double subtotal = cartDAO.getCartTotal(cartId);

        Voucher voucher = voucherDAO.getValidVoucher(
                code.trim(),
                subtotal,
                user.getUserId()
        );

        if (voucher == null) {
            session.setAttribute(
                    "checkoutError",
                    "Voucher không hợp lệ hoặc đã hết lượt."
            );
        } else {
            session.setAttribute("appliedVoucher", voucher);
            session.setAttribute(
                    "checkoutMessage",
                    "Áp dụng voucher thành công."
            );
        }

        redirectToCheckout(request, response);
    }

    // BO VOUCHER DANG CHON
    private void removeVoucher(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        HttpSession session = request.getSession();

        session.removeAttribute("appliedVoucher");
        session.setAttribute("checkoutMessage", "Đã bỏ voucher.");

        redirectToCheckout(request, response);
    }

    // DAT HANG COD BANG SERVICE MOI
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
                // REQUEST LAP THI DOC LAI DON DA TAO
                Integer existingOrderId = orderDAO.findIdByToken(
                        user.getUserId(),
                        checkoutToken
                );

                if (existingOrderId != null) {
                    orderId = existingOrderId;

                } else {
                    // TOKEN PHAI KHOP VOI TOKEN SERVER DA CAP
                    if (!checkoutToken.equals(
                            session.getAttribute("checkoutToken"))) {

                        throw new IllegalArgumentException(
                                "Phiên đặt hàng đã hết hạn. "
                                        + "Vui lòng tải lại Checkout."
                        );
                    }

                    if (!"COD".equalsIgnoreCase(
                            request.getParameter("paymentMethod"))) {

                        throw new IllegalArgumentException(
                                "Hiện tại chỉ hỗ trợ thanh toán COD."
                        );
                    }

                    int addressId = parsePositiveInt(
                            request.getParameter("addressId")
                    );

                    Object selectedId =
                            session.getAttribute("selectedAddressId");

                    if (addressId <= 0
                            || !(selectedId instanceof Integer)
                            || ((Integer) selectedId) != addressId) {

                        throw new IllegalArgumentException(
                                "Vui lòng chọn và xác nhận địa chỉ giao hàng."
                        );
                    }

                    Voucher voucher =
                            (Voucher) session.getAttribute("appliedVoucher");

                    String voucherCode =
                            voucher == null ? null : voucher.getCode();

                    // SERVICE TU KIEM TRA GIA, KHO, DIA CHI VA VOUCHER
                    orderId = orderService.placeCodOrder(
                            user.getUserId(),
                            addressId,
                            checkoutToken,
                            voucherCode
                    );
                }

                // CHI XOA TOKEN CUA LAN DAT HANG VUA XU LY
                if (checkoutToken.equals(
                        session.getAttribute("checkoutToken"))) {

                    session.removeAttribute("checkoutToken");
                    session.removeAttribute("appliedVoucher");
                }

                // GIU selectedAddressId DE DUNG LAI TRONG SESSION
            }

            // POST -> REDIRECT -> GET
            response.setStatus(HttpServletResponse.SC_SEE_OTHER);

            response.setHeader(
                    "Location",
                    response.encodeRedirectURL(
                            request.getContextPath()
                                    + "/order-success?id=" + orderId
                    )
            );

        } catch (IllegalArgumentException e) {
            session.setAttribute("checkoutError", e.getMessage());
            redirectToCheckout(request, response);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Loi dat hang COD!", e);

            session.setAttribute(
                    "checkoutError",
                    "Chưa xác nhận được kết quả đặt hàng. Vui lòng thử lại."
            );

            redirectToCheckout(request, response);
        }
    }

    // CHUYEN CHUOI THANH ID DUONG
    private int parsePositiveInt(String value) {
        try {
            int id = Integer.parseInt(value);
            return id > 0 ? id : -1;
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    // TRA THONG BAO LOI JSON
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

    // ESCAPE CHUOI DE TAO JSON HOP LE
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
            }
        }

        return result.toString();
    }

    // LAY USER TU SESSION
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

        response.sendRedirect(request.getContextPath() + "/login");
    }

    private void redirectToCheckout(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        response.sendRedirect(request.getContextPath() + "/checkout");
    }
}