package dao;

import db.DBContext;
import model.CartItem;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CheckoutDAO extends DBContext {

    // =====================================================
    // ADDRESS CỦA USER
    // =====================================================
    public List<Map<String, Object>> getAddressesByUser(
            int userId) {

        List<Map<String, Object>> list
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "address_id, "
                + "recipient_name, "
                + "phone_number, "
                + "address_line, "
                + "is_default "
                + "FROM ADDRESSBOOK "
                + "WHERE user_id = ? "
                + "AND is_deleted = 0 "
                + "ORDER BY is_default DESC, address_id DESC";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Map<String, Object> address
                            = new HashMap<>();

                    address.put(
                            "addressId",
                            rs.getInt("address_id"));

                    address.put(
                            "recipientName",
                            rs.getString("recipient_name"));

                    address.put(
                            "phoneNumber",
                            rs.getString("phone_number"));

                    address.put(
                            "addressLine",
                            rs.getString("address_line"));

                    address.put(
                            "defaultAddress",
                            rs.getBoolean("is_default"));

                    list.add(address);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }

    // =====================================================
    // SHIPPING PARTNER
    // =====================================================
    public List<Map<String, Object>> getShippingPartners() {

        List<Map<String, Object>> list
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "partner_id, "
                + "partner_name, "
                + "contact_phone "
                + "FROM SHIPPING_PARTNER "
                + "ORDER BY partner_id";

        try (Connection conn = getConnection();
             PreparedStatement ps
                     = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Map<String, Object> partner
                        = new HashMap<>();

                partner.put(
                        "partnerId",
                        rs.getInt("partner_id"));

                partner.put(
                        "partnerName",
                        rs.getString("partner_name"));

                partner.put(
                        "contactPhone",
                        rs.getString("contact_phone"));

                list.add(partner);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }

    // =====================================================
    // CREATE ORDER
    // =====================================================
    public int createOrder(
            int userId,
            int addressId,
            Integer shippingPartnerId,
            List<CartItem> items,
            double subtotal,
            double shippingFee,
            double discount,
            Integer voucherId,
            String paymentMethod,
            String checkoutToken) {

        Connection conn = null;

        try {

            conn = getConnection();

            conn.setAutoCommit(false);


            // =================================================
            // 1. KIỂM TRA ADDRESS CỦA USER
            // =================================================

            String addressSql
                    = "SELECT "
                    + "recipient_name, "
                    + "phone_number, "
                    + "address_line "
                    + "FROM ADDRESSBOOK "
                    + "WHERE address_id = ? "
                    + "AND user_id = ? "
                    + "AND is_deleted = 0";

            String recipientName;
            String recipientPhone;
            String shippingAddress;

            try (PreparedStatement ps
                    = conn.prepareStatement(
                            addressSql)) {

                ps.setInt(1, addressId);
                ps.setInt(2, userId);

                try (ResultSet rs
                        = ps.executeQuery()) {

                    if (!rs.next()) {

                        conn.rollback();

                        return -1;
                    }

                    recipientName
                            = rs.getString(
                                    "recipient_name");

                    recipientPhone
                            = rs.getString(
                                    "phone_number");

                    shippingAddress
                            = rs.getString(
                                    "address_line");
                }
            }


            // =================================================
            // 2. KIỂM TRA SẢN PHẨM + STOCK
            // =================================================

            for (CartItem item : items) {

                String stockSql
                        = "SELECT stock_quantity "
                        + "FROM PRODUCT_SKU "
                        + "WITH (UPDLOCK, ROWLOCK) "
                        + "WHERE sku_id = ?";

                try (PreparedStatement ps
                        = conn.prepareStatement(
                                stockSql)) {

                    ps.setInt(
                            1,
                            item.getSkuId());

                    try (ResultSet rs
                            = ps.executeQuery()) {

                        if (!rs.next()) {

                            conn.rollback();

                            return -1;
                        }

                        int stock
                                = rs.getInt(
                                        "stock_quantity");

                        if (stock
                                < item.getQuantity()) {

                            conn.rollback();

                            return -2;
                        }
                    }
                }
            }


            // =================================================
            // 3. TỔNG THANH TOÁN
            // =================================================

            double totalAmount
                    = subtotal
                    - discount
                    + shippingFee;

            if (totalAmount < 0) {
                totalAmount = 0;
            }


            // =================================================
            // 4. CREATE ORDER
            // =================================================

            String orderSql
                    = "INSERT INTO [ORDER] ("
                    + "user_id, "
                    + "address_id, "
                    + "shipping_partner_id, "
                    + "total_amount, "
                    + "shipping_fee, "
                    + "order_status, "
                    + "payment_method, "
                    + "payment_status, "
                    + "recipient_name, "
                    + "recipient_phone, "
                    + "shipping_address, "
                    + "discount_amount, "
                    + "checkout_token"
                    + ") "
                    + "VALUES ("
                    + "?, ?, ?, ?, ?, "
                    + "?, ?, ?, ?, ?, ?, ?, ?"
                    + ")";

            int orderId;

            try (PreparedStatement ps
                    = conn.prepareStatement(
                            orderSql,
                            Statement.RETURN_GENERATED_KEYS)) {

                ps.setInt(
                        1,
                        userId);

                ps.setInt(
                        2,
                        addressId);

                if (shippingPartnerId == null) {

                    ps.setNull(
                            3,
                            java.sql.Types.INTEGER);

                } else {

                    ps.setInt(
                            3,
                            shippingPartnerId);
                }

                ps.setDouble(
                        4,
                        totalAmount);

                ps.setDouble(
                        5,
                        shippingFee);

                ps.setString(
                        6,
                        "PENDING_CONFIRMATION");

                ps.setString(
                        7,
                        paymentMethod);

                ps.setString(
                        8,
                        "PENDING");

                ps.setString(
                        9,
                        recipientName);

                ps.setString(
                        10,
                        recipientPhone);

                ps.setString(
                        11,
                        shippingAddress);

                ps.setDouble(
                        12,
                        discount);

                ps.setString(
                        13,
                        checkoutToken);

                int affected
                        = ps.executeUpdate();

                if (affected == 0) {

                    conn.rollback();

                    return -1;
                }

                try (ResultSet rs
                        = ps.getGeneratedKeys()) {

                    if (!rs.next()) {

                        conn.rollback();

                        return -1;
                    }

                    orderId
                            = rs.getInt(1);
                }
            }


            // =================================================
            // 5. ORDER ITEM
            // =================================================

            String itemSql
                    = "INSERT INTO ORDER_ITEM "
                    + "(order_id, sku_id, price, quantity) "
                    + "VALUES (?, ?, ?, ?)";

            String stockSql
                    = "UPDATE PRODUCT_SKU "
                    + "SET stock_quantity = "
                    + "stock_quantity - ? "
                    + "WHERE sku_id = ? "
                    + "AND stock_quantity >= ?";

            String removeCartSql
                    = "DELETE FROM CART_ITEMS "
                    + "WHERE cart_item_id = ? "
                    + "AND cart_id IN ("
                    + "    SELECT cart_id "
                    + "    FROM CART "
                    + "    WHERE user_id = ?"
                    + ")";


            for (CartItem item : items) {

                // ORDER ITEM
                try (PreparedStatement ps
                        = conn.prepareStatement(
                                itemSql)) {

                    ps.setInt(
                            1,
                            orderId);

                    ps.setInt(
                            2,
                            item.getSkuId());

                    ps.setDouble(
                            3,
                            item.getPrice());

                    ps.setInt(
                            4,
                            item.getQuantity());

                    ps.executeUpdate();
                }


                // TRỪ STOCK
                try (PreparedStatement ps
                        = conn.prepareStatement(
                                stockSql)) {

                    ps.setInt(
                            1,
                            item.getQuantity());

                    ps.setInt(
                            2,
                            item.getSkuId());

                    ps.setInt(
                            3,
                            item.getQuantity());

                    int updated
                            = ps.executeUpdate();

                    if (updated == 0) {

                        conn.rollback();

                        return -2;
                    }
                }


                // CHỈ XÓA ITEM ĐÃ ORDER
                try (PreparedStatement ps
                        = conn.prepareStatement(
                                removeCartSql)) {

                    ps.setInt(
                            1,
                            item.getCartItemId());

                    ps.setInt(
                            2,
                            userId);

                    ps.executeUpdate();
                }
            }


            // =================================================
            // 6. ORDER STATUS HISTORY
            // =================================================

            String statusSql
                    = "INSERT INTO "
                    + "ORDER_STATUS_HISTORY "
                    + "(order_id, status) "
                    + "VALUES (?, ?)";

            try (PreparedStatement ps
                    = conn.prepareStatement(
                            statusSql)) {

                ps.setInt(
                        1,
                        orderId);

                ps.setString(
                        2,
                        "Pending");

                ps.executeUpdate();
            }


            // =================================================
            // 7. VOUCHER USAGE
            // =================================================

            if (voucherId != null) {

                String voucherSql
                        = "INSERT INTO "
                        + "VOUCHER_USAGES "
                        + "(voucher_id, order_id, user_id) "
                        + "VALUES (?, ?, ?)";

                try (PreparedStatement ps
                        = conn.prepareStatement(
                                voucherSql)) {

                    ps.setInt(
                            1,
                            voucherId);

                    ps.setInt(
                            2,
                            orderId);

                    ps.setInt(
                            3,
                            userId);

                    ps.executeUpdate();
                }
            }


            // =================================================
            // COMMIT
            // =================================================

            conn.commit();

            return orderId;

        } catch (Exception e) {

            e.printStackTrace();

            if (conn != null) {

                try {
                    conn.rollback();
                } catch (Exception ignored) {
                }
            }

            return -1;

        } finally {

            if (conn != null) {

                try {

                    conn.setAutoCommit(true);
                    conn.close();

                } catch (Exception ignored) {
                }
            }
        }
    }
}