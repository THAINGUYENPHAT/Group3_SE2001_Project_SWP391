package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/** The caller must hold the order lock and commit inventory with the order status. */
public final class OrderInventoryDAO {
    public void deduct(Connection connection, int orderId) throws SQLException {
        adjust(connection, orderId, true);
    }

    public void restore(Connection connection, int orderId) throws SQLException {
        adjust(connection, orderId, false);
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
        String updateSql = deduct
                ? "UPDATE dbo.PRODUCT_SKU SET stock_quantity = stock_quantity - ? "
                    + "WHERE sku_id = ? AND stock_quantity >= ?"
                : "UPDATE dbo.PRODUCT_SKU SET stock_quantity = stock_quantity + ? WHERE sku_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
            for (long[] item : items) {
                statement.setLong(1, item[1]);
                statement.setInt(2, (int) item[0]);
                if (deduct) {
                    statement.setLong(3, item[1]);
                }
                if (statement.executeUpdate() != 1) {
                    if (deduct) {
                        throw new IllegalArgumentException("SKU " + item[0]
                                + " không đủ tồn kho để xác nhận đơn hàng. Vui lòng kiểm tra hoặc hủy đơn.");
                    }
                    throw new SQLException("Không hoàn được tồn kho SKU " + item[0] + ".");
                }
            }
        }
    }
}
