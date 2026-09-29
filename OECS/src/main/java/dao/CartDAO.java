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

    // =========================================
    // 1. Lấy cart_id của user
    // =========================================
    public int getCartIdByUserId(int userId) {

        String sql = "SELECT cart_id "
                   + "FROM CART "
                   + "WHERE user_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getInt("cart_id");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return -1;
    }


    // =========================================
    // 2. Tạo cart mới
    // =========================================
    public int createCart(int userId) {

        String sql = "INSERT INTO CART(user_id, created_at) "
                   + "VALUES (?, GETDATE())";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     sql,
                     Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, userId);

            int result = ps.executeUpdate();

            if (result > 0) {

                ResultSet rs = ps.getGeneratedKeys();

                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return -1;
    }


    // =========================================
    // 3. Có cart rồi thì lấy, chưa có thì tạo
    // =========================================
    public int getOrCreateCart(int userId) {

        int cartId = getCartIdByUserId(userId);

        if (cartId == -1) {
            cartId = createCart(userId);
        }

        return cartId;
    }


    // =========================================
    // 4. Lấy danh sách sản phẩm trong cart
    // =========================================
    public List<CartItem> getCartItems(int cartId) {

        List<CartItem> list = new ArrayList<>();

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

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {

                CartItem item = new CartItem();

                item.setCartItemId(
                        rs.getInt("cart_item_id")
                );

                item.setCartId(
                        rs.getInt("cart_id")
                );

                item.setSkuId(
                        rs.getInt("sku_id")
                );

                item.setQuantity(
                        rs.getInt("quantity")
                );

                item.setSkuCode(
                        rs.getString("sku_code")
                );

                item.setPrice(
                        rs.getDouble("price")
                );

                item.setStockQuantity(
                        rs.getInt("stock_quantity")
                );

                item.setProductName(
                        rs.getString("product_name")
                );

                list.add(item);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }


    // =========================================
    // 5. Kiểm tra SKU đã có trong giỏ chưa
    // =========================================
    public boolean exists(int cartId, int skuId) {

        String sql = "SELECT cart_item_id "
                   + "FROM CART_ITEMS "
                   + "WHERE cart_id = ? "
                   + "AND sku_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);
            ps.setInt(2, skuId);

            ResultSet rs = ps.executeQuery();

            return rs.next();

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =========================================
    // 6. Lấy số lượng tồn kho
    // =========================================
    public int getStockQuantity(int skuId) {

        String sql = "SELECT stock_quantity "
                   + "FROM PRODUCT_SKU "
                   + "WHERE sku_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getInt("stock_quantity");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }


    // =========================================
    // 7. Lấy quantity hiện tại trong cart
    // =========================================
    public int getCurrentQuantity(int cartId, int skuId) {

        String sql = "SELECT quantity "
                   + "FROM CART_ITEMS "
                   + "WHERE cart_id = ? "
                   + "AND sku_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);
            ps.setInt(2, skuId);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getInt("quantity");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }


    // =========================================
    // 8. Thêm sản phẩm vào cart
    // =========================================
    public boolean addToCart(int cartId,
                             int skuId,
                             int quantity) {

        if (quantity <= 0) {
            return false;
        }

        int stock = getStockQuantity(skuId);

        if (stock <= 0) {
            return false;
        }

        if (exists(cartId, skuId)) {

            int currentQuantity =
                    getCurrentQuantity(cartId, skuId);

            int newQuantity =
                    currentQuantity + quantity;

            if (newQuantity > stock) {
                return false;
            }

            String sql = "UPDATE CART_ITEMS "
                       + "SET quantity = ? "
                       + "WHERE cart_id = ? "
                       + "AND sku_id = ?";

            try (Connection conn = getConnection();
                 PreparedStatement ps =
                         conn.prepareStatement(sql)) {

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

            try (Connection conn = getConnection();
                 PreparedStatement ps =
                         conn.prepareStatement(sql)) {

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


    // =========================================
    // 9. Update quantity
    // =========================================
    public boolean updateQuantity(int cartItemId,
                                  int quantity) {

        if (quantity <= 0) {
            return false;
        }

        String checkSql = "SELECT ps.stock_quantity "
                        + "FROM CART_ITEMS ci "
                        + "JOIN PRODUCT_SKU ps "
                        + "ON ci.sku_id = ps.sku_id "
                        + "WHERE ci.cart_item_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement checkPs =
                     conn.prepareStatement(checkSql)) {

            checkPs.setInt(1, cartItemId);

            ResultSet rs =
                    checkPs.executeQuery();

            if (!rs.next()) {
                return false;
            }

            int stock =
                    rs.getInt("stock_quantity");

            if (quantity > stock) {
                return false;
            }

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }


        String updateSql =
                "UPDATE CART_ITEMS "
              + "SET quantity = ? "
              + "WHERE cart_item_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps =
                     conn.prepareStatement(updateSql)) {

            ps.setInt(1, quantity);
            ps.setInt(2, cartItemId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =========================================
    // 10. Xóa một sản phẩm
    // =========================================
    public boolean deleteCartItem(int cartItemId) {

        String sql = "DELETE FROM CART_ITEMS "
                   + "WHERE cart_item_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setInt(1, cartItemId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =========================================
    // 11. Xóa toàn bộ cart
    // =========================================
    public boolean clearCart(int cartId) {

        String sql = "DELETE FROM CART_ITEMS "
                   + "WHERE cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);

            ps.executeUpdate();

            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =========================================
    // 12. Tổng tiền cart
    // =========================================
    public double getCartTotal(int cartId) {

        String sql = "SELECT "
                   + "SUM(ci.quantity * ps.price) AS total "
                   + "FROM CART_ITEMS ci "
                   + "JOIN PRODUCT_SKU ps "
                   + "ON ci.sku_id = ps.sku_id "
                   + "WHERE ci.cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);

            ResultSet rs =
                    ps.executeQuery();

            if (rs.next()) {
                return rs.getDouble("total");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }


    // =========================================
    // 13. Đếm số item trong cart
    // =========================================
    public int countCartItems(int cartId) {

        String sql = "SELECT SUM(quantity) AS total_quantity "
                   + "FROM CART_ITEMS "
                   + "WHERE cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps =
                     conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);

            ResultSet rs =
                    ps.executeQuery();

            if (rs.next()) {
                return rs.getInt("total_quantity");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }
}