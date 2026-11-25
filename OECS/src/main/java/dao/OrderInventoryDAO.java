package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public final class OrderInventoryDAO {

    public void deduct(Connection connection, int orderId) throws SQLException {
        adjust(connection, orderId, true);
    }

    public void restore(Connection connection, int orderId) throws SQLException {
        adjust(connection, orderId, false);
    }

    public void reserve(Connection connection, int orderId) throws SQLException {
        changeReservation(connection, orderId, true);
    }

   
    public void releaseReservation(Connection connection, int orderId) throws SQLException {
        changeReservation(connection, orderId, false);
    }

    private void changeReservation(Connection connection, int orderId, boolean reserve)
            throws SQLException {
        String itemsSql = "SELECT sku_id, SUM(CAST(quantity AS bigint)) AS qty "
                + "FROM dbo.ORDER_ITEM WHERE order_id=? GROUP BY sku_id ORDER BY sku_id";
        String updateSql = reserve
                ? "UPDATE dbo.PRODUCT_SKU SET reserved_quantity=reserved_quantity+? "
                + "WHERE sku_id=? AND stock_quantity-reserved_quantity>=? AND is_active=1 "
                + "AND EXISTS (SELECT 1 FROM dbo.PRODUCT p WITH (HOLDLOCK) "
                + "WHERE p.product_id=PRODUCT_SKU.product_id AND p.is_active=1)"
                : "UPDATE dbo.PRODUCT_SKU SET reserved_quantity=reserved_quantity-? "
                + "WHERE sku_id=? AND reserved_quantity>=?";
        int count = 0;
        try (PreparedStatement items = connection.prepareStatement(itemsSql);
                PreparedStatement update = connection.prepareStatement(updateSql)) {
            items.setInt(1, orderId);
            try (ResultSet rs = items.executeQuery()) {
                while (rs.next()) {
                    int skuId = rs.getInt("sku_id");
                    int quantity = Math.toIntExact(rs.getLong("qty"));
                    if (quantity <= 0) throw new SQLException("Invalid order item quantity.");
                    update.setInt(1, quantity);
                    update.setInt(2, skuId);
                    update.setInt(3, quantity);
                    if (update.executeUpdate() != 1) {
                        throw new IllegalArgumentException("SKU " + skuId
                                + (reserve ? " đã ngừng bán hoặc không đủ hàng khả dụng."
                                        : " không đủ hàng giữ chỗ."));
                    }
                    count++;
                }
            }
        }
        if (count == 0) throw new SQLException("Không có SKU trong đơn hàng.");
    }

    public boolean usesReservations(Connection connection) throws SQLException {
        String sql = "SELECT COL_LENGTH('dbo.PRODUCT_SKU', 'reserved_quantity')";
        try (PreparedStatement statement = connection.prepareStatement(sql);
                ResultSet row = statement.executeQuery()) {
            row.next();
            return row.getObject(1) != null;
        }
    }

    private void adjust(Connection connection, int orderId, boolean deduct) throws SQLException {
        List<long[]> items = new ArrayList<>();
        String itemsSql = "SELECT sku_id, SUM(CAST(quantity AS bigint)) AS quantity "
                + "FROM dbo.ORDER_ITEM WHERE order_id = ? GROUP BY sku_id ORDER BY sku_id";
        try (PreparedStatement statement = connection.prepareStatement(itemsSql)) {
            statement.setInt(1, orderId);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    long quantity = result.getLong("quantity");
                    if (quantity <= 0) {
                        throw new SQLException("Số lượng sản phẩm trong đơn không hợp lệ.");
                    }
                    items.add(new long[]{result.getInt("sku_id"), quantity});
                }
            }
        }
        if (items.isEmpty()) {
            throw new SQLException("Đơn hàng không có sản phẩm.");
        }
        boolean consumeReservation = deduct && usesReservations(connection);
        String updateSql;
        if (consumeReservation) {
            updateSql = "UPDATE dbo.PRODUCT_SKU SET stock_quantity = stock_quantity - ?, "
                    + "reserved_quantity = reserved_quantity - ? "
                    + "WHERE sku_id = ? AND reserved_quantity >= ? AND stock_quantity >= ? AND is_active = 1 "
                    + "AND EXISTS (SELECT 1 FROM dbo.PRODUCT p WITH (HOLDLOCK) "
                    + "WHERE p.product_id=PRODUCT_SKU.product_id AND p.is_active=1)";
        } else if (deduct) {
            updateSql = "UPDATE dbo.PRODUCT_SKU SET stock_quantity = stock_quantity - ? "
                    + "WHERE sku_id = ? AND stock_quantity >= ? AND is_active = 1 "
                    + "AND EXISTS (SELECT 1 FROM dbo.PRODUCT p WITH (HOLDLOCK) "
                    + "WHERE p.product_id=PRODUCT_SKU.product_id AND p.is_active=1)";
        } else {
            updateSql = "UPDATE dbo.PRODUCT_SKU SET stock_quantity = stock_quantity + ? WHERE sku_id = ?";
        }
        try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
            for (long[] item : items) {
                int skuId = Math.toIntExact(item[0]);
                statement.setLong(1, item[1]);
                if (consumeReservation) {
                    statement.setLong(2, item[1]);
                    statement.setInt(3, skuId);
                    statement.setLong(4, item[1]);
                    statement.setLong(5, item[1]);
                } else {
                    statement.setInt(2, skuId);
                    if (deduct) {
                        statement.setLong(3, item[1]);
                    }
                }
                if (statement.executeUpdate() != 1) {
                    if (deduct) {
                        throw new IllegalArgumentException("Không thể xác nhận đơn. "
                                + "Vui lòng kiểm tra tồn kho và trạng thái bán của SKU #" + skuId + ".");
                    }
                    throw new SQLException("Không hoàn được tồn kho SKU " + item[0] + ".");
                }

                int qty = Math.toIntExact(item[1]);

                InventoryMovementHelper.recordAfterDelta(
                        connection,
                        skuId,
                        deduct ? -qty : qty,
                        deduct ? "OUT" : "IN",
                        (deduct
                                ? "Xac nhan don hang #"
                                : "Hoan kho don hang #") + orderId,
                        null
                );
            }
        }
    }
}
