package controller;

import dao.AddressDAO;
import dao.CartDAO;
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
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "CheckoutServlet", urlPatterns = {"/checkout"})
public class CheckoutServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(CheckoutServlet.class.getName());

    private final CartDAO cartDAO = new CartDAO();
    private final AddressDAO addressDAO = new AddressDAO();
    private final VoucherDAO voucherDAO = new VoucherDAO();
    private final OrderService orderService = new OrderService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User user = getLoggedInUser(request);

        if (user == null) {
            redirectToLogin(request, response);
            return;
        }

        showCheckout(request, response, user);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        User user = getLoggedInUser(request);

        if (user == null) {
            if ("deleteAddress".equals(action) || "selectAddress".equals(action)) {
                sendJsonError(response, 401, "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.");
            } else {
                redirectToLogin(request, response);
            }
            return;
        }

        if ("addAddress".equals(action)) {
            addAddress(request, response, user);

        } else if ("selectAddress".equals(action)) {
            selectAddress(request, response, user);

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

    // HIEN THI TRANG CHECKOUT
    private void showCheckout(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException {

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

        synchronized (session) {
            if (session.getAttribute("addressAddToken") == null) {
                session.setAttribute("addressAddToken", UUID.randomUUID().toString());
            }

            if (session.getAttribute("addressActionToken") == null) {
                session.setAttribute("addressActionToken", UUID.randomUUID().toString());
            }
        }

        List<Address> addresses = addressDAO.getAddressesByUser(userId);

        // LAY DIA CHI DANG CHON TU SESSION
        Address selectedAddress = null;
        Object savedId = session.getAttribute("selectedAddressId");

        if (savedId instanceof Integer) {
            selectedAddress = addressDAO.getAddressById((Integer) savedId, userId);
        }

        // NEU CHUA CHON THI TU DONG CHON DIA CHI DAU TIEN
        if (selectedAddress == null && !addresses.isEmpty()) {
            selectedAddress = addresses.get(0);
        }

        if (selectedAddress != null) {
            session.setAttribute("selectedAddressId", selectedAddress.getAddressId());
        } else {
            session.removeAttribute("selectedAddressId");
        }

        double subtotal = cartDAO.getCartTotal(cartId);
        double shippingFee = 0;
        double discount = 0;

        Voucher appliedVoucher = (Voucher) session.getAttribute("appliedVoucher");

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
                session.setAttribute("checkoutError", "Voucher đã chọn không còn hợp lệ.");
            }
        }

        List<Voucher> availableVouchers = new ArrayList<>();

        for (Voucher voucher : voucherDAO.getAllVouchers()) {
            Voucher valid = voucherDAO.getValidVoucher(voucher.getCode(), subtotal, userId);

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
        request.setAttribute("totalAmount", Math.max(0, subtotal + shippingFee - discount));

        request.getRequestDispatcher("/WEB-INF/checkout/checkout.jsp").forward(request, response);
    }

    // THEM DIA CHI - CHAN REQUEST LAP BANG TOKEN
    private void addAddress(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {

        HttpSession session = request.getSession();
        String submittedToken = request.getParameter("addressAddToken");

        synchronized (session) {
            String expectedToken = (String) session.getAttribute("addressAddToken");

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

            // TOKEN CHI SU DUNG DUOC MOT LAN
            session.removeAttribute("addressAddToken");
        }

        String name = request.getParameter("recipientName");
        String phone = request.getParameter("phoneNumber");
        String line = request.getParameter("addressLine");

        if (name == null
                || name.trim().isEmpty()
                || name.trim().length() > 100
                || phone == null
                || !phone.trim().matches("[0-9]{9,11}")
                || line == null
                || line.trim().isEmpty()) {

            session.setAttribute("checkoutError", "Thông tin địa chỉ không hợp lệ.");

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
            session.setAttribute("checkoutMessage", "Đã thêm địa chỉ thành công.");
        } else {
            session.setAttribute("checkoutError", "Không thể thêm địa chỉ.");
        }

        redirectToCheckout(request, response);
    }

    // CHON DIA CHI MOI VA LUU VAO SESSION
    private void selectAddress(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {

        HttpSession session = request.getSession();

        if (!validAddressActionToken(request, session)) {
            sendJsonError(response, 403, "Yêu cầu chọn địa chỉ không hợp lệ.");
            return;
        }

        int addressId = parsePositiveInt(request.getParameter("addressId"));

        if (addressId <= 0) {
            sendJsonError(response, 400, "ID địa chỉ không hợp lệ.");
            return;
        }

        synchronized (session) {
            Address address = addressDAO.getAddressById(addressId, user.getUserId());

            if (address == null) {
                sendJsonError(response, 404, "Địa chỉ không tồn tại hoặc đã bị xóa.");
                return;
            }

            session.setAttribute("selectedAddressId", addressId);

            sendSelectedAddressJson(response, addressId, address);
        }
    }

    // XOA DIA CHI KHAC, KHONG CHO XOA DIA CHI DANG CHON
    private void deleteAddress(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {

        HttpSession session = request.getSession();

        if (!validAddressActionToken(request, session)) {
            sendJsonError(response, 403, "Yêu cầu xóa địa chỉ không hợp lệ.");
            return;
        }

        int addressId = parsePositiveInt(request.getParameter("addressId"));

        if (addressId <= 0) {
            sendJsonError(response, 400, "ID địa chỉ không hợp lệ.");
            return;
        }

        synchronized (session) {
            Object selected = session.getAttribute("selectedAddressId");

            // CHAN XOA DIA CHI DANG DUOC SU DUNG
            if (selected instanceof Integer && ((Integer) selected) == addressId) {
                sendJsonError(
                        response,
                        409,
                        "Không thể xóa địa chỉ đang chọn. Vui lòng chọn và xác nhận địa chỉ khác trước."
                );
                return;
            }

            // KIEM TRA DIA CHI SO HUU VA XOA MEM
            boolean deleted = addressDAO.deleteAddress(addressId, user.getUserId());

            if (!deleted) {
                sendJsonError(response, 400, "Không thể xóa địa chỉ này.");
                return;
            }

            // DIA CHI DANG CHON DUOC GIU NGUYEN
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"success\":true,\"deletedId\":" + addressId + "}");
        }
    }

    // KIEM TRA TOKEN CHO AJAX
    private boolean validAddressActionToken(HttpServletRequest request, HttpSession session) {
        String submitted = request.getParameter("addressActionToken");
        Object expected = session.getAttribute("addressActionToken");

        return submitted != null
                && expected instanceof String
                && submitted.equals(expected);
    }

    // PARSE ID AN TOAN
    private int parsePositiveInt(String value) {
        try {
            int id = Integer.parseInt(value);
            return id > 0 ? id : -1;
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    // GUI THONG TIN DIA CHI VUA CHON
    private void sendSelectedAddressJson(HttpServletResponse response, int addressId, Address address)
            throws IOException {

        response.setContentType("application/json;charset=UTF-8");

        String json = "{\"success\":true,"
                + "\"selectedAddress\":{"
                + "\"addressId\":" + addressId + ","
                + "\"recipientName\":\"" + jsonEscape(address.getRecipientName()) + "\","
                + "\"phoneNumber\":\"" + jsonEscape(address.getPhoneNumber()) + "\","
                + "\"addressLine\":\"" + jsonEscape(address.getAddressLine()) + "\","
                + "\"defaultAddress\":" + address.isDefaultAddress()
                + "}}";

        response.getWriter().write(json);
    }

    // AP DUNG VOUCHER
    private void applyVoucher(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {

        HttpSession session = request.getSession();
        String code = request.getParameter("voucherCode");

        if (code == null || code.trim().isEmpty()) {
            session.setAttribute("checkoutError", "Vui lòng nhập mã voucher.");
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

        Voucher voucher = voucherDAO.getValidVoucher(code.trim(), subtotal, user.getUserId());

        if (voucher == null) {
            session.setAttribute("checkoutError", "Voucher không hợp lệ hoặc đã hết lượt.");
        } else {
            session.setAttribute("appliedVoucher", voucher);
            session.setAttribute("checkoutMessage", "Áp dụng voucher thành công.");
        }

        redirectToCheckout(request, response);
    }

    // BO VOUCHER
    private void removeVoucher(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        HttpSession session = request.getSession();

        session.removeAttribute("appliedVoucher");
        session.setAttribute("checkoutMessage", "Đã bỏ voucher.");

        redirectToCheckout(request, response);
    }

    // DAT HANG COD - GIU LUONG ORDER HIEN TAI
    private void placeOrder(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        try {
            if (!"COD".equalsIgnoreCase(request.getParameter("paymentMethod"))) {
                throw new IllegalArgumentException("Hiện tại chỉ hỗ trợ thanh toán COD.");
            }

            int addressId = parsePositiveInt(request.getParameter("addressId"));

            if (addressId <= 0) {
                throw new IllegalArgumentException("Vui lòng chọn địa chỉ giao hàng.");
            }

            // DIA CHI GUI LEN PHAI KHOP VOI SESSION
            Object selectedId = session.getAttribute("selectedAddressId");

            if (!(selectedId instanceof Integer) || ((Integer) selectedId) != addressId) {
                throw new IllegalArgumentException(
                        "Địa chỉ chưa được xác nhận. Vui lòng chọn lại địa chỉ giao hàng."
                );
            }

            Address address = addressDAO.getAddressById(addressId, user.getUserId());

            if (address == null) {
                throw new IllegalArgumentException("Địa chỉ không hợp lệ hoặc đã bị xóa.");
            }

            int cartId = cartDAO.getCartIdByUserId(user.getUserId());

            if (cartId <= 0) {
                throw new IllegalArgumentException("Giỏ hàng đang trống.");
            }

            List<CartItem> items = cartDAO.getCartItems(cartId);

            if (items == null || items.isEmpty()) {
                throw new IllegalArgumentException("Giỏ hàng đang trống.");
            }

            double subtotal = cartDAO.getCartTotal(cartId);
            BigDecimal discountAmount = BigDecimal.ZERO;

            Voucher voucher = (Voucher) session.getAttribute("appliedVoucher");

            if (voucher != null) {
                Voucher valid = voucherDAO.getValidVoucher(
                        voucher.getCode(),
                        subtotal,
                        user.getUserId()
                );

                if (valid == null) {
                    throw new IllegalArgumentException("Voucher đã hết hiệu lực. Vui lòng chọn lại.");
                }

                double discount = voucherDAO.calculateDiscount(valid, subtotal);

                discountAmount = BigDecimal.valueOf(discount)
                        .setScale(2, RoundingMode.HALF_UP);

                voucher = valid;
            }

            int orderId = orderService.placeCodOrder(
                    user.getUserId(),
                    addressId,
                    address.getRecipientName(),
                    address.getPhoneNumber(),
                    address.getAddressLine(),
                    BigDecimal.ZERO,
                    discountAmount
            );

            // GIU NGUYEN LUONG VOUCHER CU
            // CHUA CHUYEN VOUCHER VAO CUNG TRANSACTION
            if (voucher != null) {
                boolean saved = voucherDAO.saveVoucherUsage(
                        voucher.getVoucherId(),
                        orderId,
                        user.getUserId()
                );

                if (!saved) {
                    LOGGER.warning("Order " + orderId + " chua luu duoc voucher usage.");
                }
            }

            session.removeAttribute("appliedVoucher");
            session.removeAttribute("selectedAddressId");

            request.setAttribute("orderId", orderId);

            request.getRequestDispatcher("/WEB-INF/checkout/order-success.jsp").forward(request, response);

        } catch (IllegalArgumentException e) {
            session.setAttribute("checkoutError", e.getMessage());
            redirectToCheckout(request, response);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Loi dat hang COD!", e);

            session.setAttribute("checkoutError", "Có lỗi khi đặt hàng. Vui lòng thử lại.");

            redirectToCheckout(request, response);
        }
    }

    // TRA LOI JSON KHI CO LOI
    private void sendJsonError(HttpServletResponse response, int status, String message)
            throws IOException {

        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");

        response.getWriter().write(
                "{\"success\":false,\"message\":\"" + jsonEscape(message) + "\"}"
        );
    }

    // ESCAPE DU LIEU KHI GHI JSON
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
                        result.append(String.format("\\u%04x", (int) c));
                    } else {
                        result.append(c);
                    }
            }
        }

        return result.toString();
    }

    // LAY USER DANG DANG NHAP
    private User getLoggedInUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        if (session == null) {
            return null;
        }

        Object value = session.getAttribute("loggedInUser");

        return value instanceof User ? (User) value : null;
    }

    private void redirectToLogin(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        request.getSession().setAttribute(
                "redirectUrl",
                request.getContextPath() + "/checkout"
        );

        response.sendRedirect(request.getContextPath() + "/login");
    }

    private void redirectToCheckout(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        response.sendRedirect(request.getContextPath() + "/checkout");
    }
}