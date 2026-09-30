package controller;

import dao.AddressDAO;
import dao.CartDAO;
import dao.VoucherDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import model.Address;
import model.CartItem;
import model.User;
import model.Voucher;

import service.OrderService;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@WebServlet(name = "CheckoutServlet", urlPatterns = {"/checkout"})
public class CheckoutServlet extends HttpServlet {

    private CartDAO cartDAO;
    private AddressDAO addressDAO;
    private VoucherDAO voucherDAO;
    private OrderService orderService;

    @Override
    public void init() throws ServletException {
        cartDAO = new CartDAO();
        addressDAO = new AddressDAO();
        voucherDAO = new VoucherDAO();
        orderService = new OrderService();
    }

    // ================================
    // HIEN THI TRANG CHECKOUT
    // ================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        showCheckout(request, response);
    }

    // ================================
    // XU LY CAC ACTION
    // ================================
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        User user = session == null
                ? null
                : (User) session.getAttribute("loggedInUser");

        // Kiem tra dang nhap
        if (user == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login"
            );
            return;
        }

        String action = request.getParameter("action");

        if (action == null) {
            action = "placeOrder";
        }

        switch (action) {

            case "addAddress":
                addAddress(request, response, user);
                break;

            case "applyVoucher":
                applyVoucher(request, response, user);
                break;

            case "removeVoucher":
                removeVoucher(request, response);
                break;

            default:
                placeOrder(request, response, user);
                break;
        }
    }

    // ================================
    // LOAD TRANG CHECKOUT
    // ================================
    private void showCheckout(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        User user = session == null
                ? null
                : (User) session.getAttribute("loggedInUser");

        if (user == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login"
            );
            return;
        }

        int userId = user.getUserId();

        // Lay cart cua user
        int cartId = cartDAO.getCartIdByUserId(userId);

        if (cartId == -1) {
            response.sendRedirect(
                    request.getContextPath() + "/cart"
            );
            return;
        }

        // Lay san pham trong cart
        List<CartItem> cartItems
                = cartDAO.getCartItems(cartId);

        if (cartItems.isEmpty()) {

            session.setAttribute(
                    "errorMessage",
                    "Giỏ hàng đang trống."
            );

            response.sendRedirect(
                    request.getContextPath() + "/cart"
            );

            return;
        }

        // Tinh tien hang
        double subtotal
                = cartDAO.getCartTotal(cartId);

        // Lay voucher dang ap dung
        Voucher voucher
                = (Voucher) session.getAttribute("appliedVoucher");

        double discount = 0;

        // Kiem tra lai voucher
        if (voucher != null) {

            Voucher validVoucher
                    = voucherDAO.getValidVoucher(
                            voucher.getCode(),
                            subtotal,
                            userId
                    );

            if (validVoucher != null) {

                voucher = validVoucher;

                discount
                        = voucherDAO.calculateDiscount(
                                voucher,
                                subtotal
                        );

                session.setAttribute(
                        "appliedVoucher",
                        voucher
                );

            } else {

                session.removeAttribute(
                        "appliedVoucher"
                );

                voucher = null;
            }
        }

        // Phi ship tam thoi = 0
        double shippingFee = 0;

        // Tinh tong thanh toan
        double finalTotal
                = subtotal
                + shippingFee
                - discount;

        if (finalTotal < 0) {
            finalTotal = 0;
        }

        // Lay danh sach dia chi
        List<Address> addresses
                = addressDAO.getAddressesByUser(userId);

        // Lay danh sach voucher kha dung
        List<Voucher> availableVouchers
                = new ArrayList<>();

        List<Voucher> allVouchers
                = voucherDAO.getAllVouchers();

        for (Voucher v : allVouchers) {

            Voucher validVoucher
                    = voucherDAO.getValidVoucher(
                            v.getCode(),
                            subtotal,
                            userId
                    );

            if (validVoucher != null) {
                availableVouchers.add(validVoucher);
            }
        }

        // Gui du lieu sang JSP
        request.setAttribute(
                "cartItems",
                cartItems
        );

        request.setAttribute(
                "addresses",
                addresses
        );

        request.setAttribute(
                "availableVouchers",
                availableVouchers
        );

        request.setAttribute(
                "voucher",
                voucher
        );

        request.setAttribute(
                "subtotal",
                subtotal
        );

        request.setAttribute(
                "discount",
                discount
        );

        request.setAttribute(
                "shippingFee",
                shippingFee
        );

        request.setAttribute(
                "finalTotal",
                finalTotal
        );

        request.getRequestDispatcher(
                "/WEB-INF/checkout/checkout.jsp"
        ).forward(
                request,
                response
        );
    }

    // ================================
    // THEM DIA CHI MOI
    // ================================
    private void addAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws IOException {

        String recipientName
                = request.getParameter("recipientName");

        String phoneNumber
                = request.getParameter("phoneNumber");

        String addressLine
                = request.getParameter("addressLine");

        // Kiem tra du lieu rong
        if (recipientName == null
                || recipientName.trim().isEmpty()
                || phoneNumber == null
                || phoneNumber.trim().isEmpty()
                || addressLine == null
                || addressLine.trim().isEmpty()) {

            request.getSession().setAttribute(
                    "checkoutError",
                    "Vui lòng nhập đầy đủ thông tin địa chỉ."
            );

            response.sendRedirect(
                    request.getContextPath() + "/checkout"
            );

            return;
        }

        // Kiem tra so dien thoai
        if (!phoneNumber.matches("^[0-9]{9,11}$")) {

            request.getSession().setAttribute(
                    "checkoutError",
                    "Số điện thoại không hợp lệ."
            );

            response.sendRedirect(
                    request.getContextPath() + "/checkout"
            );

            return;
        }

        // Them dia chi vao database
        int newAddressId
                = addressDAO.insertAddress(
                        user.getUserId(),
                        recipientName.trim(),
                        phoneNumber.trim(),
                        addressLine.trim()
                );

        if (newAddressId == -1) {

            request.getSession().setAttribute(
                    "checkoutError",
                    "Không thể thêm địa chỉ."
            );

        } else {

            // Tu dong chon dia chi vua them
            request.getSession().setAttribute(
                    "selectedAddressId",
                    newAddressId
            );
        }

        response.sendRedirect(
                request.getContextPath() + "/checkout"
        );
    }

    // ================================
    // AP DUNG VOUCHER
    // ================================
    private void applyVoucher(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws IOException {

        String voucherCode
                = request.getParameter("voucherCode");

        if (voucherCode == null
                || voucherCode.trim().isEmpty()) {

            request.getSession().setAttribute(
                    "checkoutError",
                    "Vui lòng nhập mã Voucher."
            );

            response.sendRedirect(
                    request.getContextPath() + "/checkout"
            );

            return;
        }

        int cartId
                = cartDAO.getCartIdByUserId(
                        user.getUserId()
                );

        double cartTotal
                = cartDAO.getCartTotal(cartId);

        Voucher voucher
                = voucherDAO.getValidVoucher(
                        voucherCode.trim(),
                        cartTotal,
                        user.getUserId()
                );

        if (voucher == null) {

            request.getSession().setAttribute(
                    "checkoutError",
                    "Voucher không hợp lệ hoặc không đủ điều kiện."
            );

        } else {

            request.getSession().setAttribute(
                    "appliedVoucher",
                    voucher
            );
        }

        response.sendRedirect(
                request.getContextPath() + "/checkout"
        );
    }

    // ================================
    // BO VOUCHER
    // ================================
    private void removeVoucher(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        request.getSession()
                .removeAttribute("appliedVoucher");

        response.sendRedirect(
                request.getContextPath() + "/checkout"
        );
    }

    // ================================
    // DAT HANG
    // ================================
    private void placeOrder(
            HttpServletRequest request,
            HttpServletResponse response,
            User user
    ) throws ServletException, IOException {

        try {

            // Lay addressId
            String addressIdRaw
                    = request.getParameter("addressId");

            if (addressIdRaw == null
                    || addressIdRaw.trim().isEmpty()) {

                throw new IllegalArgumentException(
                        "Vui lòng chọn địa chỉ nhận hàng."
                );
            }

            int addressId
                    = Integer.parseInt(addressIdRaw);

            // Kiem tra dia chi thuoc user
            Address address
                    = addressDAO.getAddressById(
                            addressId,
                            user.getUserId()
                    );

            if (address == null) {

                throw new IllegalArgumentException(
                        "Địa chỉ nhận hàng không hợp lệ."
                );
            }

            // Lay phuong thuc thanh toan
            String paymentMethod
                    = request.getParameter("paymentMethod");

            if (paymentMethod == null) {

                throw new IllegalArgumentException(
                        "Vui lòng chọn phương thức thanh toán."
                );
            }

            // Tam thoi chi lam COD
            if (!"COD".equalsIgnoreCase(paymentMethod)) {

                throw new IllegalArgumentException(
                        "VNPay và MoMo đang được phát triển."
                );
            }

            // Lay cart
            int cartId
                    = cartDAO.getCartIdByUserId(
                            user.getUserId()
                    );

            if (cartId == -1) {

                throw new IllegalArgumentException(
                        "Giỏ hàng không tồn tại."
                );
            }

            double subtotal
                    = cartDAO.getCartTotal(cartId);

            // Lay voucher trong session
            Voucher voucher
                    = (Voucher) request
                            .getSession()
                            .getAttribute(
                                    "appliedVoucher"
                            );

            double discount = 0;

            // Kiem tra voucher lan cuoi
            if (voucher != null) {

                Voucher validVoucher
                        = voucherDAO.getValidVoucher(
                                voucher.getCode(),
                                subtotal,
                                user.getUserId()
                        );

                if (validVoucher == null) {

                    throw new IllegalArgumentException(
                            "Voucher không còn hợp lệ. Vui lòng chọn lại."
                    );
                }

                voucher = validVoucher;

                discount
                        = voucherDAO.calculateDiscount(
                                voucher,
                                subtotal
                        );
            }

            // ================================
            // GOI ORDER SERVICE
            // ================================
            int orderId
                    = orderService.placeCodOrder(
                            user.getUserId(),
                            address.getAddressId(),
                            address.getRecipientName(),
                            address.getPhoneNumber(),
                            address.getAddressLine(),
                            BigDecimal.ZERO,
                            BigDecimal.valueOf(discount)
                    );

            // ================================
            // LUU VOUCHER USAGE
            // ================================
            if (voucher != null) {

                voucherDAO.saveVoucherUsage(
                        voucher.getVoucherId(),
                        orderId,
                        user.getUserId()
                );
            }

            // Xoa voucher cu khoi session
            request.getSession()
                    .removeAttribute(
                            "appliedVoucher"
                    );

            // Xoa dia chi dang duoc chon
            request.getSession()
                    .removeAttribute(
                            "selectedAddressId"
                    );

            // ================================
            // DAT HANG THANH CONG
            // ================================
            request.setAttribute(
                    "orderId",
                    orderId
            );

            request.getRequestDispatcher(
                    "/WEB-INF/checkout/order-success.jsp"
            ).forward(
                    request,
                    response
            );

        } catch (NumberFormatException e) {

            request.getSession().setAttribute(
                    "checkoutError",
                    "Địa chỉ không hợp lệ."
            );

            response.sendRedirect(
                    request.getContextPath() + "/checkout"
            );

        } catch (Exception e) {

            request.getSession().setAttribute(
                    "checkoutError",
                    e.getMessage()
            );

            response.sendRedirect(
                    request.getContextPath() + "/checkout"
            );
        }
    }
}
