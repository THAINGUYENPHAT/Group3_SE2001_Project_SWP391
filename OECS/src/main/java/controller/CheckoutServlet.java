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

import java.math.BigDecimal;
import java.math.RoundingMode;

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

    private static final Logger LOGGER
            = Logger.getLogger(
                    CheckoutServlet.class.getName()
            );

    private final CartDAO cartDAO
            = new CartDAO();

    private final AddressDAO addressDAO
            = new AddressDAO();

    private final VoucherDAO voucherDAO
            = new VoucherDAO();

    private final OrderService orderService
            = new OrderService();


    // =====================================================
    // GET
    // =====================================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        User user
                = getLoggedInUser(request);


        if (user == null) {

            redirectToLogin(
                    request,
                    response
            );

            return;
        }


        HttpSession session
                = request.getSession();


        String[] values
                = request.getParameterValues(
                        "selectedItems"
                );


        /*
         * Có selectedItems từ Cart:
         * lưu selection mới.
         *
         * Không xóa Voucher ở đây.
         * showCheckout sẽ tự revalidate Voucher.
         */
        if (values != null) {

            List<Integer> ids
                    = parseSelectedIds(
                            values
                    );


            if (ids.isEmpty()) {

                session.setAttribute(
                        "errorMessage",
                        "Vui lòng chọn ít nhất một sản phẩm."
                );


                response.sendRedirect(
                        request.getContextPath()
                        + "/cart"
                );

                return;
            }


            session.setAttribute(
                    "checkoutSelectedItemIds",
                    ids
            );
        }


        showCheckout(
                request,
                response,
                user
        );
    }


    // =====================================================
    // POST
    // =====================================================
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding(
                "UTF-8"
        );


        String action
                = request.getParameter(
                        "action"
                );


        User user
                = getLoggedInUser(
                        request
                );


        if (user == null) {

            if ("deleteAddress".equals(action)
                    || "selectAddress".equals(action)) {

                sendJsonError(
                        response,
                        401,
                        "Phiên đăng nhập đã hết hạn. "
                        + "Vui lòng đăng nhập lại."
                );

            } else {

                redirectToLogin(
                        request,
                        response
                );
            }

            return;
        }


        if ("addAddress".equals(action)) {

            addAddress(
                    request,
                    response,
                    user
            );

        } else if ("selectAddress".equals(action)) {

            selectAddress(
                    request,
                    response,
                    user
            );

        } else if ("deleteAddress".equals(action)) {

            deleteAddress(
                    request,
                    response,
                    user
            );

        } else if ("applyVoucher".equals(action)) {

            applyVoucher(
                    request,
                    response,
                    user
            );

        } else if ("removeVoucher".equals(action)) {

            removeVoucher(
                    request,
                    response
            );

        } else if ("placeOrder".equals(action)) {

            placeOrder(
                    request,
                    response,
                    user
            );

        } else {

            response.sendError(
                    400,
                    "Action khong hop le."
            );
        }
    }


    // =====================================================
    // SHOW CHECKOUT
    // =====================================================
    private void showCheckout(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws ServletException, IOException {

        int userId
                = user.getUserId();


        int cartId
                = cartDAO.getCartIdByUserId(
                        userId
                );


        if (cartId <= 0) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/cart"
            );

            return;
        }


        HttpSession session
                = request.getSession();


        List<Integer> selectedIds
                = getSelectedIds(
                        session
                );


        if (selectedIds.isEmpty()) {

            session.setAttribute(
                    "errorMessage",
                    "Vui lòng chọn sản phẩm cần đặt hàng."
            );


            response.sendRedirect(
                    request.getContextPath()
                    + "/cart"
            );

            return;
        }


        List<CartItem> cartItems
                = cartDAO.getCartItemsByIds(
                        cartId,
                        selectedIds
                );


        if (cartItems.isEmpty()
                || cartItems.size()
                != selectedIds.size()) {

            session.removeAttribute(
                    "checkoutSelectedItemIds"
            );


            session.setAttribute(
                    "errorMessage",
                    "Một số sản phẩm đã không còn trong giỏ hàng."
            );


            response.sendRedirect(
                    request.getContextPath()
                    + "/cart"
            );

            return;
        }


        // =================================================
        // STOCK
        // =================================================

        for (CartItem item : cartItems) {

            if (item.getStockQuantity() <= 0
                    || item.getQuantity()
                    > item.getStockQuantity()) {

                session.setAttribute(
                        "errorMessage",
                        "Sản phẩm "
                        + item.getProductName()
                        + " không đủ tồn kho."
                );


                response.sendRedirect(
                        request.getContextPath()
                        + "/cart"
                );

                return;
            }
        }


        // =================================================
        // TOKENS
        // =================================================

        synchronized (session) {

            if (session.getAttribute(
                    "addressAddToken"
            ) == null) {

                session.setAttribute(
                        "addressAddToken",
                        UUID.randomUUID()
                                .toString()
                );
            }


            if (session.getAttribute(
                    "addressActionToken"
            ) == null) {

                session.setAttribute(
                        "addressActionToken",
                        UUID.randomUUID()
                                .toString()
                );
            }
        }


        // =================================================
        // ADDRESS
        // =================================================

        List<Address> addresses
                = addressDAO.getAddressesByUser(
                        userId
                );


        Address selectedAddress
                = null;


        Object savedId
                = session.getAttribute(
                        "selectedAddressId"
                );


        if (savedId instanceof Integer) {

            selectedAddress
                    = addressDAO.getAddressById(
                            (Integer) savedId,
                            userId
                    );
        }


        if (selectedAddress == null
                && !addresses.isEmpty()) {

            selectedAddress
                    = addresses.get(0);
        }


        if (selectedAddress != null) {

            session.setAttribute(
                    "selectedAddressId",
                    selectedAddress.getAddressId()
            );

        } else {

            session.removeAttribute(
                    "selectedAddressId"
            );
        }


        // =================================================
        // MONEY
        // =================================================

        double subtotal
                = calculateSubtotal(
                        cartItems
                );


        double shippingFee = 0;
        double discount = 0;


        Voucher appliedVoucher
                = (Voucher)
                        session.getAttribute(
                                "appliedVoucher"
                        );


        if (appliedVoucher != null) {

            Voucher valid
                    = voucherDAO.getValidVoucher(
                            appliedVoucher.getCode(),
                            subtotal,
                            userId
                    );


            if (valid != null) {

                appliedVoucher
                        = valid;


                discount
                        = voucherDAO.calculateDiscount(
                                valid,
                                subtotal
                        );


                session.setAttribute(
                        "appliedVoucher",
                        valid
                );

            } else {

                appliedVoucher = null;


                session.removeAttribute(
                        "appliedVoucher"
                );


                session.setAttribute(
                        "checkoutError",
                        "Voucher đã chọn không còn phù hợp "
                        + "với đơn hàng này."
                );
            }
        }


        List<Voucher> availableVouchers
                = voucherDAO
                        .getAvailableVouchers(
                                subtotal,
                                userId
                        );


        request.setAttribute(
                "cartItems",
                cartItems
        );

        request.setAttribute(
                "addresses",
                addresses
        );

        request.setAttribute(
                "selectedAddress",
                selectedAddress
        );

        request.setAttribute(
                "availableVouchers",
                availableVouchers
        );

        request.setAttribute(
                "appliedVoucher",
                appliedVoucher
        );

        request.setAttribute(
                "subtotal",
                subtotal
        );

        request.setAttribute(
                "shippingFee",
                shippingFee
        );

        request.setAttribute(
                "discount",
                discount
        );

        request.setAttribute(
                "totalAmount",
                Math.max(
                        0,
                        subtotal
                        + shippingFee
                        - discount
                )
        );


        request.getRequestDispatcher(
                "/WEB-INF/checkout/checkout.jsp"
        ).forward(
                request,
                response
        );
    }


    // =====================================================
    // ADD ADDRESS
    // =====================================================
    private void addAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        HttpSession session
                = request.getSession();


        String submittedToken
                = request.getParameter(
                        "addressAddToken"
                );


        synchronized (session) {

            String expectedToken
                    = (String)
                            session.getAttribute(
                                    "addressAddToken"
                            );


            if (expectedToken == null
                    || submittedToken == null
                    || !expectedToken.equals(
                            submittedToken
                    )) {

                session.setAttribute(
                        "checkoutError",
                        "Yêu cầu thêm địa chỉ đã được xử lý hoặc hết hạn."
                );


                redirectToCheckout(
                        request,
                        response
                );

                return;
            }


            session.removeAttribute(
                    "addressAddToken"
            );
        }


        String name
                = request.getParameter(
                        "recipientName"
                );

        String phone
                = request.getParameter(
                        "phoneNumber"
                );

        String line
                = request.getParameter(
                        "addressLine"
                );


        if (name == null
                || name.trim().isEmpty()
                || name.trim().length() > 100
                || phone == null
                || !phone.trim()
                        .matches("[0-9]{9,11}")
                || line == null
                || line.trim().isEmpty()) {

            session.setAttribute(
                    "checkoutError",
                    "Thông tin địa chỉ không hợp lệ."
            );


            redirectToCheckout(
                    request,
                    response
            );

            return;
        }


        int newId
                = addressDAO.insertAddress(
                        user.getUserId(),
                        name.trim(),
                        phone.trim(),
                        line.trim()
                );


        if (newId > 0) {

            session.setAttribute(
                    "selectedAddressId",
                    newId
            );


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


        redirectToCheckout(
                request,
                response
        );
    }


    // =====================================================
    // SELECT ADDRESS
    // =====================================================
    private void selectAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        HttpSession session
                = request.getSession();


        if (!validAddressActionToken(
                request,
                session
        )) {

            sendJsonError(
                    response,
                    403,
                    "Yêu cầu chọn địa chỉ không hợp lệ."
            );

            return;
        }


        int addressId
                = parsePositiveInt(
                        request.getParameter(
                                "addressId"
                        )
                );


        if (addressId <= 0) {

            sendJsonError(
                    response,
                    400,
                    "ID địa chỉ không hợp lệ."
            );

            return;
        }


        synchronized (session) {

            Address address
                    = addressDAO.getAddressById(
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


            session.setAttribute(
                    "selectedAddressId",
                    addressId
            );


            sendSelectedAddressJson(
                    response,
                    addressId,
                    address
            );
        }
    }


    // =====================================================
    // DELETE ADDRESS
    // =====================================================
    private void deleteAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        HttpSession session
                = request.getSession();


        if (!validAddressActionToken(
                request,
                session
        )) {

            sendJsonError(
                    response,
                    403,
                    "Yêu cầu xóa địa chỉ không hợp lệ."
            );

            return;
        }


        int addressId
                = parsePositiveInt(
                        request.getParameter(
                                "addressId"
                        )
                );


        if (addressId <= 0) {

            sendJsonError(
                    response,
                    400,
                    "ID địa chỉ không hợp lệ."
            );

            return;
        }


        synchronized (session) {

            Object selected
                    = session.getAttribute(
                            "selectedAddressId"
                    );


            if (selected instanceof Integer
                    && ((Integer) selected)
                    == addressId) {

                sendJsonError(
                        response,
                        409,
                        "Không thể xóa địa chỉ đang chọn. "
                        + "Vui lòng chọn địa chỉ khác trước."
                );

                return;
            }


            boolean deleted
                    = addressDAO.deleteAddress(
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
                    "{\"success\":true,"
                    + "\"deletedId\":"
                    + addressId
                    + "}"
            );
        }
    }


    // =====================================================
    // APPLY VOUCHER
    // =====================================================
    private void applyVoucher(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        HttpSession session
                = request.getSession();


        String code
                = request.getParameter(
                        "voucherCode"
                );


        int cartId
                = cartDAO.getCartIdByUserId(
                        user.getUserId()
                );


        List<CartItem> items
                = getSelectedCartItems(
                        session,
                        cartId
                );


        if (items.isEmpty()) {

            session.setAttribute(
                    "checkoutError",
                    "Không tìm thấy sản phẩm đã chọn."
            );


            response.sendRedirect(
                    request.getContextPath()
                    + "/cart"
            );

            return;
        }


        double subtotal
                = calculateSubtotal(
                        items
                );


        Voucher voucher
                = voucherDAO.getValidVoucher(
                        code,
                        subtotal,
                        user.getUserId()
                );


        if (voucher == null) {

            session.setAttribute(
                    "checkoutError",
                    "Voucher không khả dụng."
            );

        } else {

            session.setAttribute(
                    "appliedVoucher",
                    voucher
            );


            session.setAttribute(
                    "checkoutMessage",
                    "Áp dụng Voucher thành công."
            );
        }


        redirectToCheckout(
                request,
                response
        );
    }


    // =====================================================
    // REMOVE VOUCHER
    // =====================================================
    private void removeVoucher(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        HttpSession session
                = request.getSession();


        session.removeAttribute(
                "appliedVoucher"
        );


        session.setAttribute(
                "checkoutMessage",
                "Đã bỏ Voucher."
        );


        redirectToCheckout(
                request,
                response
        );
    }


    // =====================================================
    // PLACE ORDER
    // =====================================================
    private void placeOrder(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws ServletException, IOException {

        HttpSession session
                = request.getSession();


        try {

            if (!"COD".equalsIgnoreCase(
                    request.getParameter(
                            "paymentMethod"
                    )
            )) {

                throw new IllegalArgumentException(
                        "Hiện tại chỉ hỗ trợ thanh toán COD."
                );
            }


            int addressId
                    = parsePositiveInt(
                            request.getParameter(
                                    "addressId"
                            )
                    );


            if (addressId <= 0) {

                throw new IllegalArgumentException(
                        "Vui lòng chọn địa chỉ giao hàng."
                );
            }


            Object selectedAddressId
                    = session.getAttribute(
                            "selectedAddressId"
                    );


            if (!(selectedAddressId
                    instanceof Integer)
                    || ((Integer) selectedAddressId)
                    != addressId) {

                throw new IllegalArgumentException(
                        "Địa chỉ chưa được xác nhận."
                );
            }


            Address address
                    = addressDAO.getAddressById(
                            addressId,
                            user.getUserId()
                    );


            if (address == null) {

                throw new IllegalArgumentException(
                        "Địa chỉ không hợp lệ."
                );
            }


            int cartId
                    = cartDAO.getCartIdByUserId(
                            user.getUserId()
                    );


            List<Integer> selectedIds
                    = getSelectedIds(
                            session
                    );


            if (selectedIds.isEmpty()) {

                throw new IllegalArgumentException(
                        "Không tìm thấy sản phẩm đã chọn."
                );
            }


            List<CartItem> items
                    = cartDAO.getCartItemsByIds(
                            cartId,
                            selectedIds
                    );


            if (items.size()
                    != selectedIds.size()) {

                throw new IllegalArgumentException(
                        "Một số sản phẩm không còn trong giỏ."
                );
            }


            double subtotal
                    = calculateSubtotal(
                            items
                    );


            BigDecimal discountAmount
                    = BigDecimal.ZERO;


            Voucher voucher
                    = (Voucher)
                            session.getAttribute(
                                    "appliedVoucher"
                            );


            if (voucher != null) {

                Voucher valid
                        = voucherDAO.getValidVoucher(
                                voucher.getCode(),
                                subtotal,
                                user.getUserId()
                        );


                if (valid == null) {

                    throw new IllegalArgumentException(
                            "Voucher đã hết hiệu lực "
                            + "hoặc không còn phù hợp."
                    );
                }


                double discount
                        = voucherDAO.calculateDiscount(
                                valid,
                                subtotal
                        );


                discountAmount
                        = BigDecimal.valueOf(
                                discount
                        ).setScale(
                                2,
                                RoundingMode.HALF_UP
                        );


                voucher = valid;
            }


            int orderId
                    = orderService.placeCodOrder(
                            user.getUserId(),

                            addressId,

                            address.getRecipientName(),

                            address.getPhoneNumber(),

                            address.getAddressLine(),

                            BigDecimal.ZERO,

                            discountAmount,

                            selectedIds
                    );


            if (voucher != null) {

                boolean saved
                        = voucherDAO.saveVoucherUsage(
                                voucher.getVoucherId(),
                                orderId,
                                user.getUserId()
                        );


                if (!saved) {

                    LOGGER.warning(
                            "Order "
                            + orderId
                            + " chưa lưu được voucher usage."
                    );
                }
            }


            session.removeAttribute(
                    "appliedVoucher"
            );

            session.removeAttribute(
                    "selectedAddressId"
            );

            session.removeAttribute(
                    "checkoutSelectedItemIds"
            );


            request.setAttribute(
                    "orderId",
                    orderId
            );

            request.setAttribute(
                    "subtotal",
                    subtotal
            );

            request.setAttribute(
                    "discount",
                    discountAmount.doubleValue()
            );

            request.setAttribute(
                    "totalAmount",
                    Math.max(
                            0,
                            subtotal
                            - discountAmount.doubleValue()
                    )
            );


            request.getRequestDispatcher(
                    "/WEB-INF/checkout/order-success.jsp"
            ).forward(
                    request,
                    response
            );


        } catch (IllegalArgumentException e) {

            session.setAttribute(
                    "checkoutError",
                    e.getMessage()
            );


            redirectToCheckout(
                    request,
                    response
            );


        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Loi dat hang COD!",
                    e
            );


            session.setAttribute(
                    "checkoutError",
                    "Có lỗi khi đặt hàng. "
                    + "Vui lòng thử lại."
            );


            redirectToCheckout(
                    request,
                    response
            );
        }
    }


    // =====================================================
    // SELECTED IDS
    // =====================================================
    @SuppressWarnings("unchecked")
    private List<Integer> getSelectedIds(
            HttpSession session) {

        Object value
                = session.getAttribute(
                        "checkoutSelectedItemIds"
                );


        if (value instanceof List<?>) {

            return new ArrayList<>(
                    (List<Integer>) value
            );
        }


        return new ArrayList<>();
    }


    // =====================================================
    // SELECTED CART ITEMS
    // =====================================================
    private List<CartItem> getSelectedCartItems(
            HttpSession session,
            int cartId) {

        if (cartId <= 0) {
            return new ArrayList<>();
        }


        List<Integer> ids
                = getSelectedIds(
                        session
                );


        if (ids.isEmpty()) {
            return new ArrayList<>();
        }


        return cartDAO.getCartItemsByIds(
                cartId,
                ids
        );
    }


    // =====================================================
    // PARSE SELECTED IDS
    // =====================================================
    private List<Integer> parseSelectedIds(
            String[] values) {

        List<Integer> list
                = new ArrayList<>();


        if (values == null) {
            return list;
        }


        for (String value : values) {

            int id
                    = parsePositiveInt(
                            value
                    );


            if (id > 0
                    && !list.contains(id)) {

                list.add(id);
            }
        }


        return list;
    }


    // =====================================================
    // TOTAL
    // =====================================================
    private double calculateSubtotal(
            List<CartItem> items) {

        double total = 0;


        for (CartItem item : items) {

            total += item.getPrice()
                    * item.getQuantity();
        }


        return total;
    }


    // =====================================================
    // ADDRESS TOKEN
    // =====================================================
    private boolean validAddressActionToken(
            HttpServletRequest request,
            HttpSession session) {

        String submitted
                = request.getParameter(
                        "addressActionToken"
                );


        Object expected
                = session.getAttribute(
                        "addressActionToken"
                );


        return submitted != null
                && expected instanceof String
                && submitted.equals(
                        expected
                );
    }


    // =====================================================
    // ADDRESS JSON
    // =====================================================
    private void sendSelectedAddressJson(
            HttpServletResponse response,
            int addressId,
            Address address)
            throws IOException {

        response.setContentType(
                "application/json;charset=UTF-8"
        );


        String json
                = "{\"success\":true,"
                + "\"selectedAddress\":{"
                + "\"addressId\":"
                + addressId
                + ","
                + "\"recipientName\":\""
                + jsonEscape(
                        address.getRecipientName()
                )
                + "\","
                + "\"phoneNumber\":\""
                + jsonEscape(
                        address.getPhoneNumber()
                )
                + "\","
                + "\"addressLine\":\""
                + jsonEscape(
                        address.getAddressLine()
                )
                + "\","
                + "\"defaultAddress\":"
                + address.isDefaultAddress()
                + "}}";


        response.getWriter().write(
                json
        );
    }


    // =====================================================
    // JSON ERROR
    // =====================================================
    private void sendJsonError(
            HttpServletResponse response,
            int status,
            String message)
            throws IOException {

        response.setStatus(
                status
        );


        response.setContentType(
                "application/json;charset=UTF-8"
        );


        response.getWriter().write(
                "{\"success\":false,"
                + "\"message\":\""
                + jsonEscape(message)
                + "\"}"
        );
    }


    // =====================================================
    // JSON ESCAPE
    // =====================================================
    private String jsonEscape(
            String value) {

        if (value == null) {
            return "";
        }


        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }


    // =====================================================
    // PARSE INT
    // =====================================================
    private int parsePositiveInt(
            String value) {

        try {

            int id
                    = Integer.parseInt(
                            value
                    );

            return id > 0
                    ? id
                    : -1;

        } catch (Exception e) {

            return -1;
        }
    }


    // =====================================================
    // USER
    // =====================================================
    private User getLoggedInUser(
            HttpServletRequest request) {

        HttpSession session
                = request.getSession(false);


        if (session == null) {
            return null;
        }


        Object value
                = session.getAttribute(
                        "loggedInUser"
                );


        return value instanceof User
                ? (User) value
                : null;
    }


    // =====================================================
    // LOGIN
    // =====================================================
    private void redirectToLogin(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        request.getSession()
                .setAttribute(
                        "redirectUrl",
                        request.getContextPath()
                        + "/checkout"
                );


        response.sendRedirect(
                request.getContextPath()
                + "/login"
        );
    }


    // =====================================================
    // CHECKOUT
    // =====================================================
    private void redirectToCheckout(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/checkout"
        );
    }
}