package controller;

import dao.CartDAO;
import dao.VoucherDAO;

import model.CartItem;
import model.User;
import model.Voucher;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

import java.util.ArrayList;
import java.util.List;

@WebServlet(
        name = "CartServlet",
        urlPatterns = {"/cart"}
)
public class CartServlet extends HttpServlet {

    private final CartDAO cartDAO
            = new CartDAO();

    private final VoucherDAO voucherDAO
            = new VoucherDAO();


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

            response.sendRedirect(
                    request.getContextPath()
                    + "/login"
            );

            return;
        }


        /*
         * Giữ tương thích với link cũ:
         *
         * /cart?action=remove
         * /cart?action=clear
         */
        String action
                = request.getParameter(
                        "action"
                );


        if ("remove".equals(action)) {

            removeItem(
                    request,
                    response,
                    user
            );

            return;
        }


        if ("clear".equals(action)) {

            clearCart(
                    request,
                    response,
                    user
            );

            return;
        }


        showCart(
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

        User user
                = getLoggedInUser(request);


        if (user == null) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/login"
            );

            return;
        }


        String action
                = request.getParameter(
                        "action"
                );


        if ("add".equals(action)) {

            addItem(
                    request,
                    response,
                    user
            );

        } else if ("update".equals(action)) {

            updateItem(
                    request,
                    response,
                    user
            );

        } else if ("remove".equals(action)) {

            removeItem(
                    request,
                    response,
                    user
            );

        } else if ("clear".equals(action)) {

            clearCart(
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
                    response,
                    user
            );

        } else {

            response.sendRedirect(
                    request.getContextPath()
                    + "/cart"
            );
        }
    }


    // =====================================================
    // SHOW CART
    // =====================================================
    private void showCart(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws ServletException, IOException {

        HttpSession session
                = request.getSession();


        int cartId
                = cartDAO.getCartIdByUserId(
                        user.getUserId()
                );


        List<CartItem> cartItems
                = new ArrayList<>();


        if (cartId > 0) {

            cartItems
                    = cartDAO.getCartItems(
                            cartId
                    );
        }


        double total = 0;

        if (cartId > 0) {

            total
                    = cartDAO.getCartTotal(
                            cartId
                    );
        }


        // =================================================
        // SELECTED ITEMS
        // =================================================

        List<Integer> selectedIds
                = getSelectedIdsFromSession(
                        session
                );


        selectedIds
                = sanitizeSelectedIds(
                        cartItems,
                        selectedIds
                );


        /*
         * Chưa có selection:
         * mặc định tick tất cả item còn hàng.
         */
        if (selectedIds.isEmpty()
                && !cartItems.isEmpty()) {

            for (CartItem item : cartItems) {

                if (item.getStockQuantity() > 0) {

                    selectedIds.add(
                            item.getCartItemId()
                    );
                }
            }
        }


        session.setAttribute(
                "checkoutSelectedItemIds",
                selectedIds
        );


        // =================================================
        // SELECTED TOTAL
        // =================================================

        double selectedTotal = 0;


        if (cartId > 0
                && !selectedIds.isEmpty()) {

            selectedTotal
                    = cartDAO.getCartTotalByIds(
                            cartId,
                            selectedIds
                    );
        }


        // =================================================
        // AVAILABLE VOUCHERS
        // =================================================

        List<Voucher> availableVouchers
                = voucherDAO
                        .getAvailableVouchers(
                                selectedTotal,
                                user.getUserId()
                        );


        // =================================================
        // APPLIED VOUCHER
        // =================================================

        Voucher appliedVoucher
                = (Voucher)
                        session.getAttribute(
                                "appliedVoucher"
                        );


        double discount = 0;


        if (appliedVoucher != null) {

            Voucher valid
                    = voucherDAO.getValidVoucher(
                            appliedVoucher.getCode(),
                            selectedTotal,
                            user.getUserId()
                    );


            if (valid == null) {

                session.removeAttribute(
                        "appliedVoucher"
                );

                appliedVoucher = null;

            } else {

                appliedVoucher
                        = valid;


                session.setAttribute(
                        "appliedVoucher",
                        valid
                );


                discount
                        = voucherDAO
                                .calculateDiscount(
                                        valid,
                                        selectedTotal
                                );
            }
        }


        double finalSelectedTotal
                = Math.max(
                        0,
                        selectedTotal
                        - discount
                );


        // =================================================
        // ATTRIBUTES
        // =================================================

        request.setAttribute(
                "cartItems",
                cartItems
        );

        request.setAttribute(
                "total",
                total
        );

        request.setAttribute(
                "selectedItemIds",
                selectedIds
        );

        request.setAttribute(
                "selectedTotal",
                selectedTotal
        );

        request.setAttribute(
                "availableVouchers",
                availableVouchers
        );

        request.setAttribute(
                "voucher",
                appliedVoucher
        );

        request.setAttribute(
                "appliedVoucher",
                appliedVoucher
        );

        request.setAttribute(
                "discount",
                discount
        );

        request.setAttribute(
                "finalTotal",
                finalSelectedTotal
        );


        request.getRequestDispatcher(
                "/WEB-INF/cart/cart.jsp"
        ).forward(
                request,
                response
        );
    }


    // =====================================================
    // ADD ITEM
    // =====================================================
    private void addItem(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        HttpSession session
                = request.getSession();


        int skuId
                = parsePositiveInt(
                        request.getParameter(
                                "skuId"
                        )
                );


        int quantity
                = parsePositiveInt(
                        request.getParameter(
                                "quantity"
                        )
                );


        if (quantity <= 0) {
            quantity = 1;
        }


        if (skuId <= 0) {

            session.setAttribute(
                    "errorMessage",
                    "Sản phẩm không hợp lệ."
            );

            redirectCart(
                    request,
                    response
            );

            return;
        }


        int cartId
                = cartDAO.getOrCreateCart(
                        user.getUserId()
                );


        boolean success
                = cartDAO.addToCart(
                        cartId,
                        skuId,
                        quantity
                );


        if (success) {

            session.setAttribute(
                    "successMessage",
                    "Đã thêm sản phẩm vào giỏ hàng."
            );

            /*
             * Reset selection để lần vào cart sau
             * mặc định tick tất cả.
             */
            session.removeAttribute(
                    "checkoutSelectedItemIds"
            );

        } else {

            session.setAttribute(
                    "errorMessage",
                    "Không thể thêm sản phẩm. "
                    + "Vui lòng kiểm tra số lượng tồn kho."
            );
        }


        redirectCart(
                request,
                response
        );
    }


    // =====================================================
    // UPDATE ITEM
    // =====================================================
    private void updateItem(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        HttpSession session
                = request.getSession();


        int cartId
                = cartDAO.getCartIdByUserId(
                        user.getUserId()
                );


        int cartItemId
                = parsePositiveInt(
                        request.getParameter(
                                "cartItemId"
                        )
                );


        int quantity
                = parsePositiveInt(
                        request.getParameter(
                                "quantity"
                        )
                );


        if (cartId <= 0
                || cartItemId <= 0
                || quantity <= 0) {

            session.setAttribute(
                    "errorMessage",
                    "Thông tin cập nhật không hợp lệ."
            );

            redirectCart(
                    request,
                    response
            );

            return;
        }


        boolean success
                = cartDAO.updateQuantity(
                        cartItemId,
                        cartId,
                        quantity
                );


        if (success) {

            session.setAttribute(
                    "successMessage",
                    "Đã cập nhật số lượng."
            );

        } else {

            session.setAttribute(
                    "errorMessage",
                    "Không thể cập nhật số lượng. "
                    + "Có thể số lượng vượt quá tồn kho."
            );
        }


        redirectCart(
                request,
                response
        );
    }


    // =====================================================
    // REMOVE
    // =====================================================
    private void removeItem(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        HttpSession session
                = request.getSession();


        int cartId
                = cartDAO.getCartIdByUserId(
                        user.getUserId()
                );


        int cartItemId
                = parsePositiveInt(
                        request.getParameter(
                                "cartItemId"
                        )
                );


        if (cartId <= 0
                || cartItemId <= 0) {

            session.setAttribute(
                    "errorMessage",
                    "Sản phẩm không hợp lệ."
            );

            redirectCart(
                    request,
                    response
            );

            return;
        }


        boolean success
                = cartDAO.deleteCartItem(
                        cartItemId,
                        cartId
                );


        if (success) {

            removeSelectedId(
                    session,
                    cartItemId
            );

            session.setAttribute(
                    "successMessage",
                    "Đã xóa sản phẩm khỏi giỏ hàng."
            );

        } else {

            session.setAttribute(
                    "errorMessage",
                    "Không thể xóa sản phẩm."
            );
        }


        redirectCart(
                request,
                response
        );
    }


    // =====================================================
    // CLEAR
    // =====================================================
    private void clearCart(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        HttpSession session
                = request.getSession();


        int cartId
                = cartDAO.getCartIdByUserId(
                        user.getUserId()
                );


        if (cartId > 0) {

            cartDAO.clearCart(
                    cartId
            );
        }


        session.removeAttribute(
                "checkoutSelectedItemIds"
        );

        session.removeAttribute(
                "appliedVoucher"
        );


        session.setAttribute(
                "successMessage",
                "Đã xóa toàn bộ giỏ hàng."
        );


        redirectCart(
                request,
                response
        );
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


        List<Integer> selectedIds
                = parseSelectedIds(
                        request.getParameterValues(
                                "selectedItems"
                        )
                );


        if (selectedIds.isEmpty()) {

            session.setAttribute(
                    "errorMessage",
                    "Vui lòng chọn ít nhất một sản phẩm."
            );

            redirectCart(
                    request,
                    response
            );

            return;
        }


        int cartId
                = cartDAO.getCartIdByUserId(
                        user.getUserId()
                );


        if (cartId <= 0) {

            redirectCart(
                    request,
                    response
            );

            return;
        }


        List<CartItem> selectedItems
                = cartDAO.getCartItemsByIds(
                        cartId,
                        selectedIds
                );


        if (selectedItems.size()
                != selectedIds.size()) {

            session.setAttribute(
                    "errorMessage",
                    "Danh sách sản phẩm được chọn không hợp lệ."
            );

            redirectCart(
                    request,
                    response
            );

            return;
        }


        double subtotal
                = calculateSubtotal(
                        selectedItems
                );


        Voucher voucher
                = voucherDAO.getValidVoucher(
                        code,
                        subtotal,
                        user.getUserId()
                );


        if (voucher == null) {

            session.removeAttribute(
                    "appliedVoucher"
            );

            session.setAttribute(
                    "errorMessage",
                    "Voucher không khả dụng cho các sản phẩm đã chọn."
            );

        } else {

            session.setAttribute(
                    "checkoutSelectedItemIds",
                    selectedIds
            );


            session.setAttribute(
                    "appliedVoucher",
                    voucher
            );


            session.setAttribute(
                    "successMessage",
                    "Đã áp dụng Voucher "
                    + voucher.getCode()
                    + "."
            );
        }


        redirectCart(
                request,
                response
        );
    }


    // =====================================================
    // REMOVE VOUCHER
    // =====================================================
    private void removeVoucher(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        HttpSession session
                = request.getSession();


        List<Integer> selectedIds
                = parseSelectedIds(
                        request.getParameterValues(
                                "selectedItems"
                        )
                );


        if (!selectedIds.isEmpty()) {

            int cartId
                    = cartDAO.getCartIdByUserId(
                            user.getUserId()
                    );


            if (cartId > 0) {

                List<CartItem> items
                        = cartDAO.getCartItemsByIds(
                                cartId,
                                selectedIds
                        );


                if (items.size()
                        == selectedIds.size()) {

                    session.setAttribute(
                            "checkoutSelectedItemIds",
                            selectedIds
                    );
                }
            }
        }


        session.removeAttribute(
                "appliedVoucher"
        );


        session.setAttribute(
                "successMessage",
                "Đã gỡ Voucher."
        );


        redirectCart(
                request,
                response
        );
    }


    // =====================================================
    // SANITIZE SELECTION
    // =====================================================
    private List<Integer> sanitizeSelectedIds(
            List<CartItem> cartItems,
            List<Integer> selectedIds) {

        List<Integer> result
                = new ArrayList<>();


        if (selectedIds == null) {

            return result;
        }


        for (CartItem item : cartItems) {

            if (item.getStockQuantity() > 0
                    && selectedIds.contains(
                            item.getCartItemId()
                    )) {

                result.add(
                        item.getCartItemId()
                );
            }
        }


        return result;
    }


    // =====================================================
    // SESSION IDS
    // =====================================================
    @SuppressWarnings("unchecked")
    private List<Integer> getSelectedIdsFromSession(
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
    // REMOVE ID FROM SESSION
    // =====================================================
    private void removeSelectedId(
            HttpSession session,
            int cartItemId) {

        List<Integer> selectedIds
                = getSelectedIdsFromSession(
                        session
                );


        selectedIds.remove(
                Integer.valueOf(
                        cartItemId
                )
        );


        session.setAttribute(
                "checkoutSelectedItemIds",
                selectedIds
        );
    }


    // =====================================================
    // PARSE SELECTED IDS
    // =====================================================
    private List<Integer> parseSelectedIds(
            String[] values) {

        List<Integer> ids
                = new ArrayList<>();


        if (values == null) {
            return ids;
        }


        for (String value : values) {

            int id
                    = parsePositiveInt(
                            value
                    );


            if (id > 0
                    && !ids.contains(id)) {

                ids.add(id);
            }
        }


        return ids;
    }


    // =====================================================
    // TOTAL
    // =====================================================
    private double calculateSubtotal(
            List<CartItem> items) {

        double total = 0;


        for (CartItem item : items) {

            total
                    += item.getPrice()
                    * item.getQuantity();
        }


        return total;
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
    // PARSE
    // =====================================================
    private int parsePositiveInt(
            String value) {

        try {

            int result
                    = Integer.parseInt(
                            value
                    );

            return result > 0
                    ? result
                    : -1;

        } catch (Exception e) {

            return -1;
        }
    }


    // =====================================================
    // REDIRECT
    // =====================================================
    private void redirectCart(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/cart"
        );
    }
}