package dao;

import db.DBContext;
import model.ProductSku;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class ProductSkuDAO extends DBContext {

    public List<ProductSku> getByProductId(int productId) {
        List<ProductSku> list = new ArrayList<>();
        String sql = "SELECT sku_id, product_id, sku_code, price, stock_quantity "
                + "FROM PRODUCT_SKU WHERE product_id = ? ORDER BY sku_id DESC";

        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new ProductSku(
                            rs.getInt("sku_id"),
                            rs.getInt("product_id"),
                            rs.getString("sku_code"),
                            rs.getDouble("price"),
                            rs.getInt("stock_quantity")
                    ));
                }
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductSkuDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return list;
    }

    public int insert(ProductSku sku) {
        String sql = "INSERT INTO PRODUCT_SKU (product_id, sku_code, price, stock_quantity) VALUES (?, ?, ?, ?)";
        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, sku.getProductId());
            ps.setString(2, sku.getSkuCode());
            ps.setDouble(3, sku.getPrice());
            ps.setInt(4, sku.getStockQuantity());

            return ps.executeUpdate();
        } catch (SQLException ex) {
            Logger.getLogger(ProductSkuDAO.class.getName()).log(Level.SEVERE, null, ex);
            return 0;
        }
    }

    public int delete(int skuId) {
        String sql = "DELETE FROM PRODUCT_SKU WHERE sku_id = ?";
        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, skuId);
            return ps.executeUpdate();
        } catch (SQLException ex) {
            Logger.getLogger(ProductSkuDAO.class.getName()).log(Level.SEVERE, null, ex);
            return 0;
        }
    }

    public boolean checkSkuCodeExists(String skuCode) {
        String sql = "SELECT 1 FROM PRODUCT_SKU WHERE sku_code = ?";
        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, skuCode);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next(); 
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductSkuDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return false;
    }

    public boolean checkSkuCodeExistsForUpdate(String skuCode, int excludeSkuId) {
        String sql = "SELECT 1 FROM PRODUCT_SKU WHERE sku_code = ? AND sku_id != ?";
        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, skuCode);
            ps.setInt(2, excludeSkuId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductSkuDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return false;
    }

    public int update(ProductSku sku) {
        String sql = "UPDATE PRODUCT_SKU SET sku_code = ?, price = ?, stock_quantity = ? WHERE sku_id = ?";
        try (Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, sku.getSkuCode());
            ps.setDouble(2, sku.getPrice());
            ps.setInt(3, sku.getStockQuantity());
            ps.setInt(4, sku.getSkuId());
            return ps.executeUpdate();
        } catch (SQLException ex) {
            Logger.getLogger(ProductSkuDAO.class.getName()).log(Level.SEVERE, null, ex);
            return 0;
        }
    }
}
