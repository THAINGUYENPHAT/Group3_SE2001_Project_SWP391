package dao;

import db.DBContext;
import model.Order;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class AdminOrderDAO extends DBContext {

    public List<Order> getList() {
        List<Order> list = new ArrayList<>();

        String sql = "SELECT order_id, user_id, address_id, "
            + "shipping_partner_id, total_amount, shipping_fee, created_at "
            + "FROM [ORDER] "
            + "ORDER BY created_at DESC";


        try (Connection conn = this.getConnection();
             PreparedStatement statement = conn.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {

                Order order = new Order(
                        rs.getInt("order_id"),
                        rs.getInt("user_id"),
                        rs.getInt("address_id"),
                        (Integer) rs.getObject("shipping_partner_id"),
                        rs.getBigDecimal("total_amount"),
                        rs.getBigDecimal("shipping_fee"),
                        rs.getTimestamp("created_at")
                );

                list.add(order);
            }

        } catch (SQLException ex) {
            Logger.getLogger(AdminOrderDAO.class.getName())
                    .log(Level.SEVERE, "Lỗi lấy danh sách Order!", ex);
        }

        return list;
    }
}