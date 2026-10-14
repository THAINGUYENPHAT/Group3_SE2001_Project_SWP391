package service;

import dao.OrderDAO;
import db.DBContext;

import model.Order;

import java.math.BigDecimal;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.List;

public class OrderService {

    private final OrderDAO orderDAO
            = new OrderDAO();


    // =====================================================
    // CART LINE
    // =====================================================
    private static final class CartLine {

        final int id;
        final int skuId;
        final int quantity;
        final BigDecimal price;


        CartLine(
                int id,
                int skuId,
                int quantity,
                BigDecimal price) {

            this.id = id;
            this.skuId = skuId;
            this.quantity = quantity;
            this.price = price;
        }
    }


    // =====================================================
    // OLD METHOD
    // =====================================================
    public int placeCodOrder(
            int userId,
            int addressId,
            String name,
            String phone,
            String address,
            BigDecimal shippingFee)
            throws SQLException {

        return placeCodOrder(
                userId,
                addressId,
                name,
                phone,
                address,
                shippingFee,
                BigDecimal.ZERO
        );
    }


    // =====================================================
    // OLD METHOD WITH DISCOUNT
    // =====================================================
    public int placeCodOrder(
            int userId,
            int addressId,
            String name,
            String phone,
            String address,
            BigDecimal shippingFee,
            BigDecimal discountAmount)
            throws SQLException {

        return placeCodOrder(
                userId,
                addressId,
                name,
                phone,
                address,
                shippingFee,
                discountAmount,
                null
        );
    }


    // =====================================================
    // NEW METHOD - SELECTED CART ITEMS
    // =====================================================
    public int placeCodOrder(
            int userId,
            int addressId,
            String name,
            String phone,
            String address,
            BigDecimal shippingFee,
            BigDecimal discountAmount,
            List<Integer> selectedCartItemIds)
            throws SQLException {

        // =================================================
        // VALIDATE
        // =================================================

        if (userId <= 0
                || addressId <= 0) {

            throw new IllegalArgumentException(
                    "Thông tin tài khoản hoặc địa chỉ không hợp lệ."
            );
        }


        if (isBlank(name)
                || isBlank(phone)
                || isBlank(address)) {

            throw new IllegalArgumentException(
                    "Vui lòng nhập đầy đủ thông tin người nhận."
            );
        }


        if (name.trim().length() > 100
                || !phone.trim()
                        .matches("[0-9]{9,11}")) {

            throw new IllegalArgumentException(
                    "Tên hoặc số điện thoại không hợp lệ."
            );
        }


        if (shippingFee == null
                || shippingFee.signum() < 0) {

            throw new IllegalArgumentException(
                    "Phí vận chuyển không hợp lệ."
            );
        }


        if (discountAmount == null
                || discountAmount.signum() < 0) {

            throw new IllegalArgumentException(
                    "Số tiền giảm giá không hợp lệ."
            );
        }


        boolean selectedMode
                = selectedCartItemIds != null;


        List<Integer> selectedIds
                = new ArrayList<>();


        if (selectedMode) {

            for (Integer id
                    : selectedCartItemIds) {

                if (id != null
                        && id > 0
                        && !selectedIds.contains(id)) {

                    selectedIds.add(id);
                }
            }


            if (selectedIds.isEmpty()) {

                throw new IllegalArgumentException(
                        "Vui lòng chọn sản phẩm để đặt hàng."
                );
            }
        }


        Connection conn
                = new DBContext()
                        .getConnection();


        if (conn == null) {

            throw new SQLException(
                    "Không thể kết nối database."
            );
        }


        try (Connection closeMe = conn) {

            conn.setAutoCommit(false);


            try {

                // =========================================
                // LOCK CART
                // =========================================

                int cartId;


                String cartSql
                        = "SELECT cart_id "
                        + "FROM dbo.CART "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE user_id = ?";


                try (PreparedStatement ps
                        = conn.prepareStatement(
                                cartSql)) {

                    ps.setInt(
                            1,
                            userId
                    );


                    try (ResultSet rs
                            = ps.executeQuery()) {

                        if (!rs.next()) {

                            throw new IllegalArgumentException(
                                    "Giỏ hàng không tồn tại."
                            );
                        }


                        cartId
                                = rs.getInt(
                                        "cart_id"
                                );
                    }
                }


                // =========================================
                // ADDRESS
                // =========================================

                String addressSql
                        = "SELECT "
                        + "recipient_name, "
                        + "phone_number, "
                        + "address_line "
                        + "FROM dbo.ADDRESSBOOK "
                        + "WHERE address_id = ? "
                        + "AND user_id = ? "
                        + "AND is_deleted = 0";


                String recipientName;
                String recipientPhone;
                String shippingAddress;


                try (PreparedStatement ps
                        = conn.prepareStatement(
                                addressSql)) {

                    ps.setInt(
                            1,
                            addressId
                    );

                    ps.setInt(
                            2,
                            userId
                    );


                    try (ResultSet rs
                            = ps.executeQuery()) {

                        if (!rs.next()) {

                            throw new IllegalArgumentException(
                                    "Địa chỉ không tồn tại hoặc đã bị xóa."
                            );
                        }


                        recipientName
                                = rs.getString(
                                        "recipient_name"
                                );

                        recipientPhone
                                = rs.getString(
                                        "phone_number"
                                );

                        shippingAddress
                                = rs.getString(
                                        "address_line"
                                );
                    }
                }


                // =========================================
                // CART ITEMS
                // =========================================

                List<CartLine> lines
                        = new ArrayList<>();


                BigDecimal subtotal
                        = BigDecimal.ZERO;


                StringBuilder itemsSql
                        = new StringBuilder();


                itemsSql.append(
                        "SELECT "
                );

                itemsSql.append(
                        "ci.cart_item_id, "
                );

                itemsSql.append(
                        "ci.sku_id, "
                );

                itemsSql.append(
                        "ci.quantity, "
                );

                itemsSql.append(
                        "s.price "
                );

                itemsSql.append(
                        "FROM dbo.CART_ITEMS ci "
                );

                itemsSql.append(
                        "WITH (UPDLOCK, HOLDLOCK) "
                );

                itemsSql.append(
                        "JOIN dbo.PRODUCT_SKU s "
                );

                itemsSql.append(
                        "ON s.sku_id = ci.sku_id "
                );

                itemsSql.append(
                        "WHERE ci.cart_id = ? "
                );


                if (selectedMode) {

                    itemsSql.append(
                            "AND ci.cart_item_id IN ("
                    );


                    for (int i = 0;
                         i < selectedIds.size();
                         i++) {

                        if (i > 0) {
                            itemsSql.append(",");
                        }

                        itemsSql.append("?");
                    }


                    itemsSql.append(") ");
                }


                itemsSql.append(
                        "ORDER BY ci.cart_item_id"
                );


                try (PreparedStatement ps
                        = conn.prepareStatement(
                                itemsSql.toString())) {

                    int index = 1;


                    ps.setInt(
                            index++,
                            cartId
                    );


                    if (selectedMode) {

                        for (Integer id
                                : selectedIds) {

                            ps.setInt(
                                    index++,
                                    id
                            );
                        }
                    }


                    try (ResultSet rs
                            = ps.executeQuery()) {

                        while (rs.next()) {

                            int itemId
                                    = rs.getInt(
                                            "cart_item_id"
                                    );


                            int skuId
                                    = rs.getInt(
                                            "sku_id"
                                    );


                            int quantity
                                    = rs.getInt(
                                            "quantity"
                                    );


                            BigDecimal price
                                    = rs.getBigDecimal(
                                            "price"
                                    );


                            if (quantity <= 0
                                    || price == null
                                    || price.signum() < 0) {

                                throw new IllegalArgumentException(
                                        "Sản phẩm trong giỏ hàng không hợp lệ."
                                );
                            }


                            lines.add(
                                    new CartLine(
                                            itemId,
                                            skuId,
                                            quantity,
                                            price
                                    )
                            );


                            subtotal
                                    = subtotal.add(
                                            price.multiply(
                                                    BigDecimal.valueOf(
                                                            quantity
                                                    )
                                            )
                                    );
                        }
                    }
                }


                if (lines.isEmpty()) {

                    throw new IllegalArgumentException(
                            "Giỏ hàng đang trống."
                    );
                }


                if (selectedMode
                        && lines.size()
                        != selectedIds.size()) {

                    throw new IllegalArgumentException(
                            "Một số sản phẩm đã chọn "
                            + "không còn trong giỏ hàng."
                    );
                }


                // =========================================
                // DISCOUNT
                // =========================================

                if (discountAmount
                        .compareTo(
                                subtotal
                        ) > 0) {

                    throw new IllegalArgumentException(
                            "Số tiền giảm giá vượt quá giá trị đơn hàng."
                    );
                }


                // =========================================
                // TOTAL
                // =========================================

                BigDecimal totalAmount
                        = subtotal
                                .add(
                                        shippingFee
                                )
                                .subtract(
                                        discountAmount
                                );


                if (totalAmount.signum() < 0) {

                    totalAmount
                            = BigDecimal.ZERO;
                }


                // =========================================
                // STOCK
                // =========================================

                for (CartLine line : lines) {

                    String stockSql
                            = "UPDATE dbo.PRODUCT_SKU "
                            + "SET stock_quantity = "
                            + "stock_quantity - ? "
                            + "WHERE sku_id = ? "
                            + "AND stock_quantity >= ?";


                    try (PreparedStatement ps
                            = conn.prepareStatement(
                                    stockSql)) {

                        ps.setInt(
                                1,
                                line.quantity
                        );

                        ps.setInt(
                                2,
                                line.skuId
                        );

                        ps.setInt(
                                3,
                                line.quantity
                        );


                        if (ps.executeUpdate()
                                != 1) {

                            throw new IllegalArgumentException(
                                    "Sản phẩm SKU "
                                    + line.skuId
                                    + " không đủ tồn kho."
                            );
                        }
                    }
                }


                // =========================================
                // ORDER
                // =========================================

                Order order
                        = new Order();


                order.setUserId(
                        userId
                );

                order.setAddressId(
                        addressId
                );

                order.setRecipientName(
                        recipientName
                );

                order.setRecipientPhone(
                        recipientPhone
                );

                order.setShippingAddress(
                        shippingAddress
                );

                order.setShippingFee(
                        shippingFee
                );

                order.setDiscountAmount(
                        discountAmount
                );

                order.setTotalAmount(
                        totalAmount
                );

                order.setOrderStatus(
                        "PENDING_CONFIRMATION"
                );

                order.setPaymentMethod(
                        "COD"
                );


                if (totalAmount.signum() == 0) {

                    order.setPaymentStatus(
                            "PAID"
                    );

                } else {

                    order.setPaymentStatus(
                            "UNPAID"
                    );
                }


                int orderId
                        = orderDAO.insert(
                                conn,
                                order
                        );


                if (orderId <= 0) {

                    throw new SQLException(
                            "Không thể tạo đơn hàng."
                    );
                }


                // =========================================
                // ORDER ITEMS
                // =========================================

                for (CartLine line : lines) {

                    orderDAO.insertItem(
                            conn,
                            orderId,
                            line.skuId,
                            line.price,
                            line.quantity
                    );
                }


                // =========================================
                // HISTORY
                // =========================================

                orderDAO.addHistory(
                        conn,
                        orderId,
                        "PENDING_CONFIRMATION"
                );


                // =========================================
                // DELETE CART ITEMS
                // =========================================

                if (selectedMode) {

                    StringBuilder deleteSql
                            = new StringBuilder();


                    deleteSql.append(
                            "DELETE FROM dbo.CART_ITEMS "
                    );

                    deleteSql.append(
                            "WHERE cart_id = ? "
                    );

                    deleteSql.append(
                            "AND cart_item_id IN ("
                    );


                    for (int i = 0;
                         i < selectedIds.size();
                         i++) {

                        if (i > 0) {
                            deleteSql.append(",");
                        }

                        deleteSql.append("?");
                    }


                    deleteSql.append(")");


                    try (PreparedStatement ps
                            = conn.prepareStatement(
                                    deleteSql.toString())) {

                        int index = 1;


                        ps.setInt(
                                index++,
                                cartId
                        );


                        for (Integer id
                                : selectedIds) {

                            ps.setInt(
                                    index++,
                                    id
                            );
                        }


                        int deleted
                                = ps.executeUpdate();


                        if (deleted
                                != selectedIds.size()) {

                            throw new SQLException(
                                    "Không thể cập nhật giỏ hàng."
                            );
                        }
                    }

                } else {

                    String deleteSql
                            = "DELETE FROM dbo.CART_ITEMS "
                            + "WHERE cart_id = ?";


                    try (PreparedStatement ps
                            = conn.prepareStatement(
                                    deleteSql)) {

                        ps.setInt(
                                1,
                                cartId
                        );


                        ps.executeUpdate();
                    }
                }


                // =========================================
                // COMMIT
                // =========================================

                conn.commit();


                return orderId;


            } catch (SQLException
                    | RuntimeException e) {

                conn.rollback();

                throw e;

            } finally {

                conn.setAutoCommit(
                        true
                );
            }
        }
    }


    // =====================================================
    // BLANK
    // =====================================================
    private static boolean isBlank(
            String value) {

        return value == null
                || value.trim()
                        .isEmpty();
    }
}