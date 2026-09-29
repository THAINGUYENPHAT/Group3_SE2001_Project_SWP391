package service;

import dao.OrderDAO;
import db.DBContext;
import java.math.BigDecimal;
import java.sql.*;
import java.util.*;
import model.Order;

/**
 * First vertical slice: COD only. Online payments require verified gateway
 * integration.
 */
public class OrderService {

    private final OrderDAO orderDAO = new OrderDAO();

    private static final class CartLine {

        final int id, skuId, quantity;
        final BigDecimal price;

        CartLine(int id, int skuId, int quantity, BigDecimal price) {
            this.id = id;
            this.skuId = skuId;
            this.quantity = quantity;
            this.price = price;
        }
    }

    /**
     * shippingFee is resolved by trusted server configuration; never take it
     * from a browser request.
     */
    public int placeCodOrder(int userId, int addressId, String name, String phone, String address, BigDecimal shippingFee) throws SQLException {
        if (userId <= 0 || addressId <= 0) {
            throw new IllegalArgumentException("Invalid user/address");
        }
        if (isBlank(name) || isBlank(phone) || isBlank(address)) {
            throw new IllegalArgumentException("Recipient information is required");
        }
        if (name.length() > 100 || phone.length() > 20) {
            throw new IllegalArgumentException("Recipient information is too long");
        }
        if (shippingFee == null || shippingFee.signum() < 0) {
            throw new IllegalArgumentException("Shipping fee is not configured");
        }
        Connection c = new DBContext().getConnection();
        if (c == null) {
            throw new SQLException("No database connection");
        }
        try (Connection closeMe = c) {
            c.setAutoCommit(false);
            try {
                int cartId;
                // Lock the customer's cart while checkout is in progress (includes double-submit protection).
                try (PreparedStatement p = c.prepareStatement("SELECT cart_id FROM dbo.CART WITH (UPDLOCK,HOLDLOCK) WHERE user_id=?")) {
                    p.setInt(1, userId);
                    try (ResultSet r = p.executeQuery()) {
                        if (!r.next()) {
                            throw new IllegalArgumentException("Cart does not exist");
                        }
                        cartId = r.getInt(1);
                    }
                }
                // Ensure selected address belongs to this user (snapshot text may be edited at checkout).
                try (PreparedStatement p = c.prepareStatement("SELECT address_id FROM dbo.ADDRESSBOOK WHERE address_id=? AND user_id=?")) {
                    p.setInt(1, addressId);
                    p.setInt(2, userId);
                    try (ResultSet r = p.executeQuery()) {
                        if (!r.next()) {
                            throw new IllegalArgumentException("Address does not belong to customer");
                        }
                    }
                }
                List<CartLine> lines = new ArrayList<>();
                BigDecimal subtotal = BigDecimal.ZERO;
                String q = "SELECT ci.cart_item_id,ci.sku_id,ci.quantity,s.price FROM dbo.CART_ITEMS ci WITH (UPDLOCK,HOLDLOCK) JOIN dbo.PRODUCT_SKU s ON s.sku_id=ci.sku_id WHERE ci.cart_id=? ORDER BY ci.cart_item_id";
                try (PreparedStatement p = c.prepareStatement(q)) {
                    p.setInt(1, cartId);
                    try (ResultSet r = p.executeQuery()) {
                        while (r.next()) {
                            int qty = r.getInt("quantity");
                            BigDecimal price = r.getBigDecimal("price");
                            if (qty <= 0 || price == null || price.signum() < 0) {
                                throw new IllegalArgumentException("Invalid cart item");
                            }
                            lines.add(new CartLine(r.getInt("cart_item_id"), r.getInt("sku_id"), qty, price));
                            subtotal = subtotal.add(price.multiply(BigDecimal.valueOf(qty)));
                        }
                    }
                }
                if (lines.isEmpty()) {
                    throw new IllegalArgumentException("Cart is empty");
                }
                // Conditional update prevents overselling under concurrent checkouts.
                for (CartLine line : lines) {
                    try (PreparedStatement p = c.prepareStatement("UPDATE dbo.PRODUCT_SKU SET stock_quantity=stock_quantity-? WHERE sku_id=? AND stock_quantity>=?")) {
                        p.setInt(1, line.quantity);
                        p.setInt(2, line.skuId);
                        p.setInt(3, line.quantity);
                        if (p.executeUpdate() != 1) {
                            throw new IllegalArgumentException("Insufficient stock for SKU " + line.skuId);
                        }
                    }
                }
                Order order = new Order();
                order.setUserId(userId);
                order.setAddressId(addressId);
                order.setRecipientName(name.trim());
                order.setRecipientPhone(phone.trim());
                order.setShippingAddress(address.trim());
                order.setShippingFee(shippingFee);
                order.setDiscountAmount(BigDecimal.ZERO);
                order.setTotalAmount(subtotal.add(shippingFee));
                order.setOrderStatus("PENDING_CONFIRMATION");
                order.setPaymentStatus("UNPAID");
                order.setPaymentMethod("COD");
                int orderId = orderDAO.insert(c, order);
                for (CartLine line : lines) {
                    orderDAO.insertItem(c, orderId, line.skuId, line.price, line.quantity);
                }
                orderDAO.addHistory(c, orderId, "PENDING_CONFIRMATION");
                try (PreparedStatement p = c.prepareStatement("DELETE FROM dbo.CART_ITEMS WHERE cart_id=?")) {
                    p.setInt(1, cartId);
                    p.executeUpdate();
                }
                c.commit();
                return orderId;
            } catch (SQLException | RuntimeException ex) {
                c.rollback();
                throw ex;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    private static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}
