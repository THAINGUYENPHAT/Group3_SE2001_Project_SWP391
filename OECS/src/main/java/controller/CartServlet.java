package controller;

import dao.CartDAO;
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

@WebServlet(name = "CartServlet", urlPatterns = {"/cart"})
public class CartServlet extends HttpServlet {

    private CartDAO cartDAO;

    @Override
    public void init() throws ServletException {
        cartDAO = new CartDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        processRequest(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        processRequest(request, response);
    }

    private void processRequest(HttpServletRequest request,
                                HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession();

        // Chỗ này phải sửa theo session login của project bạn
        User user = (User) session.getAttribute("loggedInUser");

        if (user == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login"
            );
            return;
        }

        int userId = user.getUserId();

        int cartId = cartDAO.getOrCreateCart(userId);

        String action = request.getParameter("action");

        if (action == null || action.trim().isEmpty()) {
            action = "view";
        }

        switch (action) {

            case "add":
                addToCart(request, response, cartId);
                break;

            case "update":
                updateCart(request, response);
                break;

            case "remove":
                removeItem(request, response);
                break;

            case "clear":
                clearCart(request, response, cartId);
                break;

            default:
                showCart(request, response, cartId);
                break;
        }
    }

    // =========================
    // VIEW CART
    // =========================
    private void showCart(HttpServletRequest request,
                          HttpServletResponse response,
                          int cartId)
            throws ServletException, IOException {

        List<CartItem> cartItems =
                cartDAO.getCartItems(cartId);

        double total =
                cartDAO.getCartTotal(cartId);

        request.setAttribute(
                "cartItems",
                cartItems
        );

        request.setAttribute(
                "total",
                total
        );

        request.getRequestDispatcher(
                "/WEB-INF/cart/cart.jsp"
        ).forward(request, response);
    }

    // =========================
    // ADD
    // =========================
    private void addToCart(HttpServletRequest request,
                           HttpServletResponse response,
                           int cartId)
            throws IOException {

        try {

            int skuId = Integer.parseInt(
                    request.getParameter("skuId")
            );

            int quantity = 1;

            String quantityRaw =
                    request.getParameter("quantity");

            if (quantityRaw != null
                    && !quantityRaw.trim().isEmpty()) {

                quantity =
                        Integer.parseInt(quantityRaw);
            }

            if (quantity <= 0) {
                quantity = 1;
            }

            boolean success =
                    cartDAO.addToCart(
                            cartId,
                            skuId,
                            quantity
                    );

            if (success) {

                request.getSession()
                        .setAttribute(
                                "successMessage",
                                "Đã thêm sản phẩm vào giỏ hàng."
                        );

            } else {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Không thể thêm sản phẩm hoặc vượt quá tồn kho."
                        );
            }

        } catch (NumberFormatException e) {

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Dữ liệu sản phẩm không hợp lệ."
                    );
        }

        response.sendRedirect(
                request.getContextPath() + "/cart"
        );
    }

    // =========================
    // UPDATE
    // =========================
    private void updateCart(HttpServletRequest request,
                            HttpServletResponse response)
            throws IOException {

        try {

            int cartItemId =
                    Integer.parseInt(
                            request.getParameter(
                                    "cartItemId"
                            )
                    );

            int quantity =
                    Integer.parseInt(
                            request.getParameter(
                                    "quantity"
                            )
                    );

            boolean success =
                    cartDAO.updateQuantity(
                            cartItemId,
                            quantity
                    );

            if (success) {

                request.getSession()
                        .setAttribute(
                                "successMessage",
                                "Cập nhật giỏ hàng thành công."
                        );

            } else {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Số lượng không hợp lệ hoặc vượt quá tồn kho."
                        );
            }

        } catch (NumberFormatException e) {

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Dữ liệu không hợp lệ."
                    );
        }

        response.sendRedirect(
                request.getContextPath() + "/cart"
        );
    }

    // =========================
    // REMOVE
    // =========================
    private void removeItem(HttpServletRequest request,
                            HttpServletResponse response)
            throws IOException {

        try {

            int cartItemId =
                    Integer.parseInt(
                            request.getParameter(
                                    "cartItemId"
                            )
                    );

            boolean success =
                    cartDAO.deleteCartItem(
                            cartItemId
                    );

            if (success) {

                request.getSession()
                        .setAttribute(
                                "successMessage",
                                "Đã xóa sản phẩm khỏi giỏ hàng."
                        );

            } else {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Không thể xóa sản phẩm."
                        );
            }

        } catch (NumberFormatException e) {

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Dữ liệu không hợp lệ."
                    );
        }

        response.sendRedirect(
                request.getContextPath() + "/cart"
        );
    }

    // =========================
    // CLEAR
    // =========================
    private void clearCart(HttpServletRequest request,
                           HttpServletResponse response,
                           int cartId)
            throws IOException {

        cartDAO.clearCart(cartId);

        request.getSession()
                .setAttribute(
                        "successMessage",
                        "Đã xóa toàn bộ giỏ hàng."
                );

        response.sendRedirect(
                request.getContextPath() + "/cart"
        );
    }
}