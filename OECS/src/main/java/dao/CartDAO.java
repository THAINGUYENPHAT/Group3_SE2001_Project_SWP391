package dao;

import db.DBContext;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.List;

import model.CartItem;

public class CartDAO extends DBContext {

    public int getCartIdByUserId(int userId) {

        String sql = "SELECT cart_id "
                + "FROM CART "
                + "WHERE user_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

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


    public int createCart(int userId) {

        String sql = "INSERT INTO CART(user_id, created_at) "
                + "VALUES (?, GETDATE())";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(
                        sql,
                        Statement.RETURN_GENERATED_KEYS)
        ) {

            ps.setInt(1, userId);

            if (ps.executeUpdate() > 0) {

                try (ResultSet rs = ps.getGeneratedKeys()) {

                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return -1;
    }


    public int getOrCreateCart(int userId) {

        int cartId =
                getCartIdByUserId(userId);

        if (cartId == -1) {
            cartId = createCart(userId);
        }

        return cartId;
    }


    public List<CartItem> getCartItems(int cartId) {

        List<CartItem> list =
                new ArrayList<>();

        String sql = "SELECT "
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
                + "ON ci.sku_id = ps.sku_id "
                + "JOIN PRODUCT p "
                + "ON ps.product_id = p.product_id "
                + "WHERE ci.cart_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

            ps.setInt(1, cartId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    CartItem item =
                            new CartItem();

                    item.setCartItemId(
                            rs.getInt("cart_item_id"));

                    item.setCartId(
                            rs.getInt("cart_id"));

                    item.setSkuId(
                            rs.getInt("sku_id"));

                    item.setQuantity(
                            rs.getInt("quantity"));

                    item.setSkuCode(
                            rs.getString("sku_code"));

                    item.setPrice(
                            rs.getDouble("price"));

                    item.setStockQuantity(
                            rs.getInt("stock_quantity"));

                    item.setProductName(
                            rs.getString("product_name"));

                    list.add(item);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }


    public int getStockQuantity(int skuId) {

        String sql = "SELECT stock_quantity "
                + "FROM PRODUCT_SKU "
                + "WHERE sku_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

            ps.setInt(1, skuId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt("stock_quantity");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }


    public int getCurrentQuantity(
            int cartId,
            int skuId) {

        String sql = "SELECT quantity "
                + "FROM CART_ITEMS "
                + "WHERE cart_id = ? "
                + "AND sku_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

            ps.setInt(1, cartId);
            ps.setInt(2, skuId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt("quantity");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }


    public boolean exists(
            int cartId,
            int skuId) {

        String sql = "SELECT 1 "
                + "FROM CART_ITEMS "
                + "WHERE cart_id = ? "
                + "AND sku_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

            ps.setInt(1, cartId);
            ps.setInt(2, skuId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    public boolean addToCart(
            int cartId,
            int skuId,
            int quantity) {

        if (quantity <= 0) {
            return false;
        }

        int stock =
                getStockQuantity(skuId);

        if (stock <= 0) {
            return false;
        }

        if (exists(cartId, skuId)) {

            int current =
                    getCurrentQuantity(
                            cartId,
                            skuId);

            int newQuantity =
                    current + quantity;

            if (newQuantity > stock) {
                return false;
            }

            String sql = "UPDATE CART_ITEMS "
                    + "SET quantity = ? "
                    + "WHERE cart_id = ? "
                    + "AND sku_id = ?";

            try (
                    Connection conn = getConnection();
                    PreparedStatement ps = conn.prepareStatement(sql)
            ) {

                ps.setInt(1, newQuantity);
                ps.setInt(2, cartId);
                ps.setInt(3, skuId);

                return ps.executeUpdate() > 0;

            } catch (SQLException e) {
                e.printStackTrace();
            }

        } else {

            if (quantity > stock) {
                return false;
            }

            String sql = "INSERT INTO CART_ITEMS "
                    + "(cart_id, sku_id, quantity) "
                    + "VALUES (?, ?, ?)";

            try (
                    Connection conn = getConnection();
                    PreparedStatement ps = conn.prepareStatement(sql)
            ) {

                ps.setInt(1, cartId);
                ps.setInt(2, skuId);
                ps.setInt(3, quantity);

                return ps.executeUpdate() > 0;

            } catch (SQLException e) {
                e.printStackTrace();
            }
        }

        return false;
    }


    public boolean updateQuantity(
            int cartItemId,
            int quantity) {

        if (quantity <= 0) {
            return false;
        }

        String checkSql =
                "SELECT ps.stock_quantity "
                + "FROM CART_ITEMS ci "
                + "JOIN PRODUCT_SKU ps "
                + "ON ci.sku_id = ps.sku_id "
                + "WHERE ci.cart_item_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(checkSql)
        ) {

            ps.setInt(1, cartItemId);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    return false;
                }

                int stock =
                        rs.getInt("stock_quantity");

                if (quantity > stock) {
                    return false;
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }

        String sql =
                "UPDATE CART_ITEMS "
                + "SET quantity = ? "
                + "WHERE cart_item_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

            ps.setInt(1, quantity);
            ps.setInt(2, cartItemId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    public boolean deleteCartItem(
            int cartItemId) {

        String sql =
                "DELETE FROM CART_ITEMS "
                + "WHERE cart_item_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

            ps.setInt(1, cartItemId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    public boolean clearCart(
            int cartId) {

        String sql =
                "DELETE FROM CART_ITEMS "
                + "WHERE cart_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

            ps.setInt(1, cartId);
            ps.executeUpdate();

            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    public double getCartTotal(
            int cartId) {

        String sql =
                "SELECT "
                + "SUM(ci.quantity * ps.price) AS total "
                + "FROM CART_ITEMS ci "
                + "JOIN PRODUCT_SKU ps "
                + "ON ci.sku_id = ps.sku_id "
                + "WHERE ci.cart_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

            ps.setInt(1, cartId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getDouble("total");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }
}