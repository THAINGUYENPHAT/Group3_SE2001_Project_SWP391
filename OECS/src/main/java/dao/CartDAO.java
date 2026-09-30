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
import java.util.logging.Level;
import java.util.logging.Logger;

public class CartDAO extends DBContext {

    private static final Logger LOGGER = Logger.getLogger(CartDAO.class.getName());

    // =====================================================
    // 1. LẤY CART ID THEO USER ID
    // =====================================================
    public int getCartIdByUserId(int userId) {
        String sql = "SELECT cart_id FROM CART WHERE user_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("cart_id");
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy Cart ID theo User ID!", e);
        }

        return -1;
    }

    // =====================================================
    // 2. TẠO GIỎ HÀNG MỚI
    // =====================================================
    public int createCart(int userId) {
        String sql = "INSERT INTO CART (user_id, created_at) VALUES (?, GETDATE())";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, userId);

            if (ps.executeUpdate() > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi tạo giỏ hàng mới!", e);
        }

        return -1;
    }

    // =====================================================
    // 3. LẤY HOẶC TẠO MỚI GIỎ HÀNG
    // =====================================================
    public int getOrCreateCart(int userId) {
        int cartId = getCartIdByUserId(userId);
        if (cartId == -1) {
            cartId = createCart(userId);
        }
        return cartId;
    }

    // =====================================================
    // 4. LẤY DANH SÁCH SẢN PHẨM TRONG GIỎ HÀNG
    // =====================================================
    public List<CartItem> getCartItems(int cartId) {
        List<CartItem> list = new ArrayList<>();
        String sql = "SELECT ci.cart_item_id, ci.cart_id, ci.sku_id, ci.quantity, "
                + "ps.sku_code, ps.price, ps.stock_quantity, p.product_name "
                + "FROM CART_ITEMS ci "
                + "JOIN PRODUCT_SKU ps ON ci.sku_id = ps.sku_id "
                + "JOIN PRODUCT p ON ps.product_id = p.product_id "
                + "WHERE ci.cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    CartItem item = new CartItem();
                    item.setCartItemId(rs.getInt("cart_item_id"));
                    item.setCartId(rs.getInt("cart_id"));
                    item.setSkuId(rs.getInt("sku_id"));
                    item.setQuantity(rs.getInt("quantity"));
                    item.setSkuCode(rs.getString("sku_code"));
                    item.setPrice(rs.getDouble("price"));
                    item.setStockQuantity(rs.getInt("stock_quantity"));
                    item.setProductName(rs.getString("product_name"));

                    list.add(item);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy danh sách sản phẩm giỏ hàng!", e);
        }

        return list;
    }

    // =====================================================
    // 5. LẤY SỐ LƯỢNG TỒN KHO CỦA SKU
    // =====================================================
    public int getStockQuantity(int skuId) {
        String sql = "SELECT stock_quantity FROM PRODUCT_SKU WHERE sku_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, skuId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("stock_quantity");
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy số lượng tồn kho!", e);
        }

        return 0;
    }

    // =====================================================
    // 6. LẤY SỐ LƯỢNG SẢN PHẨM HIỆN TẠI TRONG GIỎ HÀNG
    // =====================================================
    public int getCurrentQuantity(int cartId, int skuId) {
        String sql = "SELECT quantity FROM CART_ITEMS WHERE cart_id = ? AND sku_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);
            ps.setInt(2, skuId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("quantity");
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi lấy số lượng hiện tại trong giỏ hàng!", e);
        }

        return 0;
    }

    // =====================================================
    // 7. KIỂM TRA SẢN PHẨM ĐÃ CÓ TRONG GIỎ HÀNG CHƯA
    // =====================================================
    public boolean exists(int cartId, int skuId) {
        String sql = "SELECT 1 FROM CART_ITEMS WHERE cart_id = ? AND sku_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);
            ps.setInt(2, skuId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi kiểm tra sản phẩm tồn tại trong giỏ!", e);
        }

        return false;
    }

    // =====================================================
    // 8. THÊM SẢN PHẨM VÀO GIỎ HÀNG
    // =====================================================
    public boolean addToCart(int cartId, int skuId, int quantity) {
        if (quantity <= 0) {
            return false;
        }

        int stock = getStockQuantity(skuId);
        if (stock <= 0) {
            return false;
        }

        if (exists(cartId, skuId)) {
            int current = getCurrentQuantity(cartId, skuId);
            int newQuantity = current + quantity;

            if (newQuantity > stock) {
                return false;
            }

            String sql = "UPDATE CART_ITEMS SET quantity = ? WHERE cart_id = ? AND sku_id = ?";

            try (Connection conn = getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {

                ps.setInt(1, newQuantity);
                ps.setInt(2, cartId);
                ps.setInt(3, skuId);

                return ps.executeUpdate() > 0;

            } catch (SQLException e) {
                LOGGER.log(Level.SEVERE, "Lỗi cập nhật số lượng khi thêm vào giỏ!", e);
            }
        } else {
            if (quantity > stock) {
                return false;
            }

            String sql = "INSERT INTO CART_ITEMS (cart_id, sku_id, quantity) VALUES (?, ?, ?)";

            try (Connection conn = getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {

                ps.setInt(1, cartId);
                ps.setInt(2, skuId);
                ps.setInt(3, quantity);

                return ps.executeUpdate() > 0;

            } catch (SQLException e) {
                LOGGER.log(Level.SEVERE, "Lỗi thêm sản phẩm mới vào giỏ hàng!", e);
            }
        }

        return false;
    }

    // =====================================================
    // 9. CẬP NHẬT SỐ LƯỢNG SẢN PHẨM TRONG GIỎ
    // =====================================================
    public boolean updateQuantity(int cartItemId, int quantity) {
        if (quantity <= 0) {
            return false;
        }

        String checkSql = "SELECT ps.stock_quantity "
                + "FROM CART_ITEMS ci "
                + "JOIN PRODUCT_SKU ps ON ci.sku_id = ps.sku_id "
                + "WHERE ci.cart_item_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(checkSql)) {

            ps.setInt(1, cartItemId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }

                int stock = rs.getInt("stock_quantity");
                if (quantity > stock) {
                    return false;
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi kiểm tra tồn kho khi cập nhật số lượng!", e);
            return false;
        }

        String sql = "UPDATE CART_ITEMS SET quantity = ? WHERE cart_item_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, quantity);
            ps.setInt(2, cartItemId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi cập nhật số lượng sản phẩm trong giỏ!", e);
        }

        return false;
    }

    // =====================================================
    // 10. XÓA MỘT SẢN PHẨM KHỎI GIỎ HÀNG
    // =====================================================
    public boolean deleteCartItem(int cartItemId) {
        String sql = "DELETE FROM CART_ITEMS WHERE cart_item_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, cartItemId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi xóa sản phẩm khỏi giỏ hàng!", e);
        }

        return false;
    }

    // =====================================================
    // 11. XÓA TOÀN BỘ GIỎ HÀNG
    // =====================================================
    public boolean clearCart(int cartId) {
        String sql = "DELETE FROM CART_ITEMS WHERE cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);
            ps.executeUpdate();

            return true;

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi xóa toàn bộ giỏ hàng!", e);
        }

        return false;
    }

    // =====================================================
    // 12. TÍNH TỔNG TIỀN GIỎ HÀNG
    // =====================================================
    public double getCartTotal(int cartId) {
        String sql = "SELECT SUM(ci.quantity * ps.price) AS total "
                + "FROM CART_ITEMS ci "
                + "JOIN PRODUCT_SKU ps ON ci.sku_id = ps.sku_id "
                + "WHERE ci.cart_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, cartId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getDouble("total");
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi tính tổng tiền giỏ hàng!", e);
        }

        return 0;
    }
}