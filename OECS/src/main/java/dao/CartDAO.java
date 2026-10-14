package dao;

import db.DBContext;
import model.CartItem;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.List;

public class CartDAO extends DBContext {

    // =====================================================
    // GET CART ID
    // =====================================================
    public int getCartIdByUserId(int userId) {

        if (userId <= 0) {
            return -1;
        }

        String sql
                = "SELECT cart_id "
                + "FROM CART "
                + "WHERE user_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt("cart_id");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return -1;
    }


    // =====================================================
    // CREATE CART
    // =====================================================
    public int createCart(int userId) {

        if (userId <= 0) {
            return -1;
        }

        String sql
                = "INSERT INTO CART "
                + "(user_id, created_at) "
                + "VALUES (?, GETDATE())";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(
                             sql,
                             Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, userId);

            int affected = ps.executeUpdate();

            if (affected <= 0) {
                return -1;
            }

            try (ResultSet rs
                    = ps.getGeneratedKeys()) {

                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException e) {

            e.printStackTrace();

            int existing
                    = getCartIdByUserId(userId);

            if (existing > 0) {
                return existing;
            }
        }

        return -1;
    }


    // =====================================================
    // GET OR CREATE
    // =====================================================
    public int getOrCreateCart(int userId) {

        int cartId
                = getCartIdByUserId(userId);

        if (cartId > 0) {
            return cartId;
        }

        return createCart(userId);
    }


    // =====================================================
    // GET ALL ITEMS
    // =====================================================
    public List<CartItem> getCartItems(int cartId) {

        List<CartItem> list
                = new ArrayList<>();

        if (cartId <= 0) {
            return list;
        }

        String sql
                = "SELECT "
                + "ci.cart_item_id, "
                + "ci.cart_id, "
                + "ci.sku_id, "
                + "ci.quantity, "
                + "ps.sku_code, "
                + "ps.price, "
                + "ps.stock_quantity, "
                + "p.product_name "
                + "FROM CART_ITEMS ci "
                + "JOIN PRODUCT_SKU ps "
                + "ON ps.sku_id = ci.sku_id "
                + "JOIN PRODUCT p "
                + "ON p.product_id = ps.product_id "
                + "WHERE ci.cart_id = ? "
                + "ORDER BY ci.cart_item_id DESC";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);

            try (ResultSet rs
                    = ps.executeQuery()) {

                while (rs.next()) {

                    list.add(
                            mapCartItem(rs)
                    );
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }


    // =====================================================
    // GET SELECTED ITEMS
    // =====================================================
    public List<CartItem> getCartItemsByIds(
            int cartId,
            List<Integer> cartItemIds) {

        List<CartItem> list
                = new ArrayList<>();

        if (cartId <= 0
                || cartItemIds == null
                || cartItemIds.isEmpty()) {

            return list;
        }

        List<Integer> validIds
                = new ArrayList<>();

        for (Integer id : cartItemIds) {

            if (id != null
                    && id > 0
                    && !validIds.contains(id)) {

                validIds.add(id);
            }
        }

        if (validIds.isEmpty()) {
            return list;
        }

        StringBuilder placeholders
                = new StringBuilder();

        for (int i = 0;
             i < validIds.size();
             i++) {

            if (i > 0) {
                placeholders.append(",");
            }

            placeholders.append("?");
        }

        String sql
                = "SELECT "
                + "ci.cart_item_id, "
                + "ci.cart_id, "
                + "ci.sku_id, "
                + "ci.quantity, "
                + "ps.sku_code, "
                + "ps.price, "
                + "ps.stock_quantity, "
                + "p.product_name "
                + "FROM CART_ITEMS ci "
                + "JOIN PRODUCT_SKU ps "
                + "ON ps.sku_id = ci.sku_id "
                + "JOIN PRODUCT p "
                + "ON p.product_id = ps.product_id "
                + "WHERE ci.cart_id = ? "
                + "AND ci.cart_item_id IN ("
                + placeholders
                + ") "
                + "ORDER BY ci.cart_item_id DESC";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            int index = 1;

            ps.setInt(
                    index++,
                    cartId
            );

            for (Integer id : validIds) {

                ps.setInt(
                        index++,
                        id
                );
            }

            try (ResultSet rs
                    = ps.executeQuery()) {

                while (rs.next()) {

                    list.add(
                            mapCartItem(rs)
                    );
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }


    // =====================================================
    // EXISTS
    // =====================================================
    public boolean exists(
            int cartId,
            int skuId) {

        if (cartId <= 0 || skuId <= 0) {
            return false;
        }

        String sql
                = "SELECT 1 "
                + "FROM CART_ITEMS "
                + "WHERE cart_id = ? "
                + "AND sku_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);
            ps.setInt(2, skuId);

            try (ResultSet rs
                    = ps.executeQuery()) {

                return rs.next();
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =====================================================
    // STOCK
    // =====================================================
    public int getStockQuantity(int skuId) {

        if (skuId <= 0) {
            return 0;
        }

        String sql
                = "SELECT stock_quantity "
                + "FROM PRODUCT_SKU "
                + "WHERE sku_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            try (ResultSet rs
                    = ps.executeQuery()) {

                if (rs.next()) {

                    return rs.getInt(
                            "stock_quantity"
                    );
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }


    // =====================================================
    // CURRENT QUANTITY
    // =====================================================
    public int getCurrentQuantity(
            int cartId,
            int skuId) {

        String sql
                = "SELECT quantity "
                + "FROM CART_ITEMS "
                + "WHERE cart_id = ? "
                + "AND sku_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);
            ps.setInt(2, skuId);

            try (ResultSet rs
                    = ps.executeQuery()) {

                if (rs.next()) {

                    return rs.getInt(
                            "quantity"
                    );
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }


    // =====================================================
    // ADD TO CART
    // =====================================================
    public boolean addToCart(
            int cartId,
            int skuId,
            int quantity) {

        if (cartId <= 0
                || skuId <= 0
                || quantity <= 0) {

            return false;
        }

        int stock
                = getStockQuantity(skuId);

        if (stock <= 0) {
            return false;
        }

        int current
                = getCurrentQuantity(
                        cartId,
                        skuId
                );

        if (current + quantity > stock) {

            return false;
        }

        if (current > 0) {

            String sql
                    = "UPDATE CART_ITEMS "
                    + "SET quantity = quantity + ? "
                    + "WHERE cart_id = ? "
                    + "AND sku_id = ?";

            try (Connection conn = getConnection();
                 PreparedStatement ps
                         = conn.prepareStatement(sql)) {

                ps.setInt(1, quantity);
                ps.setInt(2, cartId);
                ps.setInt(3, skuId);

                return ps.executeUpdate() > 0;

            } catch (SQLException e) {
                e.printStackTrace();
            }

            return false;
        }

        String sql
                = "INSERT INTO CART_ITEMS "
                + "(cart_id, sku_id, quantity) "
                + "VALUES (?, ?, ?)";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);
            ps.setInt(2, skuId);
            ps.setInt(3, quantity);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =====================================================
    // GET SKU FROM CART ITEM
    // =====================================================
    public int getSkuIdByCartItemId(
            int cartItemId,
            int cartId) {

        String sql
                = "SELECT sku_id "
                + "FROM CART_ITEMS "
                + "WHERE cart_item_id = ? "
                + "AND cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, cartItemId);
            ps.setInt(2, cartId);

            try (ResultSet rs
                    = ps.executeQuery()) {

                if (rs.next()) {

                    return rs.getInt(
                            "sku_id"
                    );
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return -1;
    }


    // =====================================================
    // UPDATE QUANTITY
    // =====================================================
    public boolean updateQuantity(
            int cartItemId,
            int cartId,
            int quantity) {

        if (quantity <= 0) {
            return false;
        }

        int skuId
                = getSkuIdByCartItemId(
                        cartItemId,
                        cartId
                );

        if (skuId <= 0) {
            return false;
        }

        int stock
                = getStockQuantity(skuId);

        if (quantity > stock) {
            return false;
        }

        String sql
                = "UPDATE CART_ITEMS "
                + "SET quantity = ? "
                + "WHERE cart_item_id = ? "
                + "AND cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, quantity);
            ps.setInt(2, cartItemId);
            ps.setInt(3, cartId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =====================================================
    // LEGACY UPDATE
    // =====================================================
    public boolean updateQuantity(
            int cartItemId,
            int quantity) {

        if (quantity <= 0) {
            return false;
        }

        String sql
                = "SELECT ci.cart_id "
                + "FROM CART_ITEMS ci "
                + "WHERE ci.cart_item_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, cartItemId);

            try (ResultSet rs
                    = ps.executeQuery()) {

                if (rs.next()) {

                    return updateQuantity(
                            cartItemId,
                            rs.getInt("cart_id"),
                            quantity
                    );
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =====================================================
    // DELETE
    // =====================================================
    public boolean deleteCartItem(
            int cartItemId,
            int cartId) {

        String sql
                = "DELETE FROM CART_ITEMS "
                + "WHERE cart_item_id = ? "
                + "AND cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, cartItemId);
            ps.setInt(2, cartId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =====================================================
    // LEGACY DELETE
    // =====================================================
    public boolean deleteCartItem(
            int cartItemId) {

        String sql
                = "DELETE FROM CART_ITEMS "
                + "WHERE cart_item_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, cartItemId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =====================================================
    // CLEAR
    // =====================================================
    public boolean clearCart(int cartId) {

        if (cartId <= 0) {
            return false;
        }

        String sql
                = "DELETE FROM CART_ITEMS "
                + "WHERE cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);

            ps.executeUpdate();

            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =====================================================
    // TOTAL CART
    // =====================================================
    public double getCartTotal(int cartId) {

        if (cartId <= 0) {
            return 0;
        }

        String sql
                = "SELECT COALESCE("
                + "SUM(ps.price * ci.quantity), 0"
                + ") AS total "
                + "FROM CART_ITEMS ci "
                + "JOIN PRODUCT_SKU ps "
                + "ON ps.sku_id = ci.sku_id "
                + "WHERE ci.cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);

            try (ResultSet rs
                    = ps.executeQuery()) {

                if (rs.next()) {

                    return rs.getDouble(
                            "total"
                    );
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }


    // =====================================================
    // TOTAL SELECTED ITEMS
    // =====================================================
    public double getCartTotalByIds(
            int cartId,
            List<Integer> cartItemIds) {

        List<CartItem> items
                = getCartItemsByIds(
                        cartId,
                        cartItemIds
                );

        double total = 0;

        for (CartItem item : items) {

            total += item.getPrice()
                    * item.getQuantity();
        }

        return total;
    }


    // =====================================================
    // DELETE SELECTED ITEMS
    // =====================================================
    public boolean deleteCartItemsByIds(
            int cartId,
            List<Integer> cartItemIds) {

        if (cartId <= 0
                || cartItemIds == null
                || cartItemIds.isEmpty()) {

            return false;
        }

        StringBuilder placeholders
                = new StringBuilder();

        for (int i = 0;
             i < cartItemIds.size();
             i++) {

            if (i > 0) {
                placeholders.append(",");
            }

            placeholders.append("?");
        }

        String sql
                = "DELETE FROM CART_ITEMS "
                + "WHERE cart_id = ? "
                + "AND cart_item_id IN ("
                + placeholders
                + ")";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            int index = 1;

            ps.setInt(
                    index++,
                    cartId
            );

            for (Integer id : cartItemIds) {

                ps.setInt(
                        index++,
                        id
                );
            }

            int deleted
                    = ps.executeUpdate();

            return deleted
                    == cartItemIds.size();

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =====================================================
    // MAP
    // =====================================================
    private CartItem mapCartItem(
            ResultSet rs)
            throws SQLException {

        CartItem item
                = new CartItem();

        item.setCartItemId(
                rs.getInt(
                        "cart_item_id"
                )
        );

        item.setCartId(
                rs.getInt(
                        "cart_id"
                )
        );

        item.setSkuId(
                rs.getInt(
                        "sku_id"
                )
        );

        item.setQuantity(
                rs.getInt(
                        "quantity"
                )
        );

        item.setSkuCode(
                rs.getString(
                        "sku_code"
                )
        );

        item.setPrice(
                rs.getDouble(
                        "price"
                )
        );

        item.setStockQuantity(
                rs.getInt(
                        "stock_quantity"
                )
        );

        item.setProductName(
                rs.getString(
                        "product_name"
                )
        );

        return item;
    }
}