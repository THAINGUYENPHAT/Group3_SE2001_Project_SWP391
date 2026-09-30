package controller;

import dao.CartDAO;
import dao.VoucherDAO;

import java.io.IOException;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import model.CartItem;
import model.User;
import model.Voucher;

@WebServlet(
        name = "CartServlet",
        urlPatterns = {"/cart"}
)
public class CartServlet extends HttpServlet {

    private CartDAO cartDAO;
    private VoucherDAO voucherDAO;

    @Override
    public void init()
            throws ServletException {

        cartDAO =
                new CartDAO();

        voucherDAO =
                new VoucherDAO();
    }


    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException,
            IOException {

        processRequest(
                request,
                response);
    }


    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException,
            IOException {

        processRequest(
                request,
                response);
    }


    private void processRequest(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException,
            IOException {

        request.setCharacterEncoding(
                "UTF-8");

        HttpSession session =
                request.getSession();


        User loggedInUser =
                (User)
                session.getAttribute(
                        "loggedInUser");


        if (loggedInUser == null) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/login");

            return;
        }


        int userId =
                loggedInUser.getUserId();


        int cartId =
                cartDAO.getOrCreateCart(
                        userId);


        String action =
                request.getParameter(
                        "action");


        if (action == null
                || action.trim().isEmpty()) {

            action = "view";
        }


        switch (action) {

            case "add":

                addToCart(
                        request,
                        response,
                        cartId);

                break;


            case "update":

                updateCart(
                        request,
                        response);

                break;


            case "remove":

                removeItem(
                        request,
                        response);

                break;


            case "clear":

                clearCart(
                        request,
                        response,
                        cartId);

                break;


            case "applyVoucher":

                applyVoucher(
                        request,
                        response,
                        cartId,
                        userId);

                break;


            case "removeVoucher":

                removeVoucher(
                        request,
                        response);

                break;


            default:

                showCart(
                        request,
                        response,
                        cartId,
                        userId);

                break;
        }
    }


    private void showCart(
            HttpServletRequest request,
            HttpServletResponse response,
            int cartId,
            int userId)
            throws ServletException,
            IOException {

        List<CartItem> cartItems =
                cartDAO.getCartItems(
                        cartId);


        double total =
                cartDAO.getCartTotal(
                        cartId);


        Voucher voucher =
                (Voucher)
                request.getSession()
                .getAttribute(
                        "appliedVoucher");


        double discount = 0;


        if (voucher != null) {

            Voucher validVoucher =
                    voucherDAO.getValidVoucher(
                            voucher.getCode(),
                            total,
                            userId);


            if (validVoucher != null) {

                voucher =
                        validVoucher;

                discount =
                        voucherDAO
                        .calculateDiscount(
                                voucher,
                                total);


                request.getSession()
                        .setAttribute(
                                "appliedVoucher",
                                voucher);

            } else {

                request.getSession()
                        .removeAttribute(
                                "appliedVoucher");

                voucher = null;
            }
        }


        double finalTotal =
                total - discount;


        if (finalTotal < 0) {
            finalTotal = 0;
        }


        request.setAttribute(
                "cartItems",
                cartItems);

        request.setAttribute(
                "total",
                total);

        request.setAttribute(
                "discount",
                discount);

        request.setAttribute(
                "finalTotal",
                finalTotal);

        request.setAttribute(
                "voucher",
                voucher);


        request.getRequestDispatcher(
                "/WEB-INF/cart/cart.jsp"
        ).forward(
                request,
                response);
    }


    private void addToCart(
            HttpServletRequest request,
            HttpServletResponse response,
            int cartId)
            throws IOException {

        try {

            int skuId =
                    Integer.parseInt(
                            request.getParameter(
                                    "skuId"));


            int quantity = 1;

            String raw =
                    request.getParameter(
                            "quantity");


            if (raw != null
                    && !raw.trim().isEmpty()) {

                quantity =
                        Integer.parseInt(raw);
            }


            if (quantity <= 0) {
                quantity = 1;
            }


            boolean success =
                    cartDAO.addToCart(
                            cartId,
                            skuId,
                            quantity);


            if (success) {

                request.getSession()
                        .setAttribute(
                                "successMessage",
                                "Đã thêm sản phẩm vào giỏ hàng.");

            } else {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Không thể thêm sản phẩm hoặc vượt quá tồn kho.");
            }


        } catch (NumberFormatException e) {

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Dữ liệu sản phẩm không hợp lệ.");
        }


        response.sendRedirect(
                request.getContextPath()
                + "/cart");
    }


    private void updateCart(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        try {

            int cartItemId =
                    Integer.parseInt(
                            request.getParameter(
                                    "cartItemId"));


            int quantity =
                    Integer.parseInt(
                            request.getParameter(
                                    "quantity"));


            boolean success =
                    cartDAO.updateQuantity(
                            cartItemId,
                            quantity);


            if (success) {

                request.getSession()
                        .setAttribute(
                                "successMessage",
                                "Cập nhật giỏ hàng thành công.");

            } else {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Số lượng không hợp lệ hoặc vượt quá tồn kho.");
            }


        } catch (NumberFormatException e) {

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Dữ liệu không hợp lệ.");
        }


        response.sendRedirect(
                request.getContextPath()
                + "/cart");
    }


    private void removeItem(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        try {

            int cartItemId =
                    Integer.parseInt(
                            request.getParameter(
                                    "cartItemId"));


            cartDAO.deleteCartItem(
                    cartItemId);


        } catch (NumberFormatException e) {

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Dữ liệu không hợp lệ.");
        }


        response.sendRedirect(
                request.getContextPath()
                + "/cart");
    }


    private void clearCart(
            HttpServletRequest request,
            HttpServletResponse response,
            int cartId)
            throws IOException {

        cartDAO.clearCart(
                cartId);


        request.getSession()
                .removeAttribute(
                        "appliedVoucher");


        request.getSession()
                .setAttribute(
                        "successMessage",
                        "Đã xóa toàn bộ giỏ hàng.");


        response.sendRedirect(
                request.getContextPath()
                + "/cart");
    }


    private void applyVoucher(
            HttpServletRequest request,
            HttpServletResponse response,
            int cartId,
            int userId)
            throws IOException {

        String code =
                request.getParameter(
                        "voucherCode");


        if (code == null
                || code.trim().isEmpty()) {

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Vui lòng nhập mã Voucher.");

            response.sendRedirect(
                    request.getContextPath()
                    + "/cart");

            return;
        }


        code =
                code.trim()
                    .toUpperCase();


        double total =
                cartDAO.getCartTotal(
                        cartId);


        if (total <= 0) {

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Giỏ hàng đang trống.");

            response.sendRedirect(
                    request.getContextPath()
                    + "/cart");

            return;
        }


        Voucher voucher =
                voucherDAO.getValidVoucher(
                        code,
                        total,
                        userId);


        if (voucher == null) {

            request.getSession()
                    .removeAttribute(
                            "appliedVoucher");

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Voucher không hợp lệ, hết hạn, chưa đủ điều kiện hoặc đã hết lượt.");

        } else {

            request.getSession()
                    .setAttribute(
                            "appliedVoucher",
                            voucher);

            request.getSession()
                    .setAttribute(
                            "successMessage",
                            "Áp dụng Voucher "
                            + voucher.getCode()
                            + " thành công.");
        }


        response.sendRedirect(
                request.getContextPath()
                + "/cart");
    }


    private void removeVoucher(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        request.getSession()
                .removeAttribute(
                        "appliedVoucher");


        request.getSession()
                .setAttribute(
                        "successMessage",
                        "Đã bỏ Voucher.");


        response.sendRedirect(
                request.getContextPath()
                + "/cart");
    }
}