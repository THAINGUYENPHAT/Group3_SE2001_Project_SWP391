package dao;

import db.CheckoutConnectionFactory;
import db.DBContext;
import payment.PaymentGateway;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class PaymentDAO {

    private final CheckoutConnectionFactory connections;

    public PaymentDAO() {
        this(() -> new DBContext().getConnection());
    }

    public PaymentDAO(CheckoutConnectionFactory connections) {
        this.connections = connections;
    }

    // Moi thao tac dung connection rieng
    private Connection open() throws SQLException {
        Connection connection = connections.open();

        if (connection == null) {
            throw new SQLException(
                    "Không kết nối được database."
            );
        }

        return connection;
    }

    // Thong tin mot lan thanh toan
    public static final class Attempt {

        public final String ref;
        public final String method;
        public final String url;
        public final BigDecimal amount;
        public final long seconds;

        public Attempt(
                String ref,
                String method,
                String url,
                BigDecimal amount,
                long seconds
        ) {
            this.ref = ref;
            this.method = method;
            this.url = url;
            this.amount = amount;
            this.seconds = seconds;
        }
    }

    private static final class LockedOrder {

        int id;
        int owner;
        String status;
        String method;
        String payment;
        BigDecimal amount;
        long seconds;
        boolean restored;
    }

    // Khoa ORDER truoc khi thay doi thanh toan hoac ton kho
    private LockedOrder lock(
            Connection connection,
            int orderId
    ) throws SQLException {

        String sql =
                "SELECT *, "
                + "DATEDIFF_BIG(SECOND, SYSUTCDATETIME(), "
                + "payment_expires_at) AS seconds_left "
                + "FROM dbo.[ORDER] WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE order_id = ?";

        try (PreparedStatement ps =
                connection.prepareStatement(sql)) {

            ps.setInt(1, orderId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException(
                            "Không tìm thấy đơn hàng."
                    );
                }

                LockedOrder order = new LockedOrder();

                order.id = orderId;
                order.owner = rs.getInt("user_id");
                order.status = rs.getString("order_status");
                order.method = rs.getString("payment_method");
                order.payment = rs.getString("payment_status");
                order.amount = rs.getBigDecimal("total_amount");
                order.seconds = rs.getLong("seconds_left");
                order.restored =
                        rs.getTimestamp("stock_restored_at") != null;

                return order;
            }
        }
    }

    private static int update(
            Connection connection,
            String sql,
            Object... values
    ) throws SQLException {

        try (PreparedStatement ps =
                connection.prepareStatement(sql)) {

            for (int i = 0; i < values.length; i++) {
                ps.setObject(i + 1, values[i]);
            }

            return ps.executeUpdate();
        }
    }

    private void history(
            Connection connection,
            int orderId,
            String status
    ) throws SQLException {

        update(
                connection,
                "INSERT INTO dbo.ORDER_STATUS_HISTORY "
                + "(order_id, status) VALUES (?, ?)",
                orderId,
                status
        );
    }

    private static void rollback(
            Connection connection,
            Exception original
    ) {
        try {
            connection.rollback();
        } catch (SQLException rollbackError) {
            original.addSuppressed(rollbackError);
        }
    }

    // Chi huy tu dong don dang cho thanh toan da het han
    private boolean expire(
            Connection connection,
            LockedOrder order
    ) throws SQLException {

        if (!"PENDING_PAYMENT".equals(order.status)
                || order.seconds > 0
                || "PAID".equals(order.payment)) {
            return false;
        }

        cancel(connection, order);
        return true;
    }

    // Ham noi bo: ORDER phai duoc khoa truoc khi goi
    private void cancel(
            Connection connection,
            LockedOrder order
    ) throws SQLException {

        if (!order.restored) {
            List<int[]> items = new ArrayList<>();

            String sql =
                    "SELECT sku_id, SUM(quantity) AS qty "
                    + "FROM dbo.ORDER_ITEM "
                    + "WHERE order_id = ? "
                    + "GROUP BY sku_id "
                    + "ORDER BY sku_id";

            try (PreparedStatement ps =
                    connection.prepareStatement(sql)) {

                ps.setInt(1, order.id);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        items.add(new int[]{
                            rs.getInt("sku_id"),
                            rs.getInt("qty")
                        });
                    }
                }
            }

            if (items.isEmpty()) {
                throw new SQLException(
                        "Đơn hàng không có chi tiết."
                );
            }

            for (int[] item : items) {
                if (item[1] <= 0) {
                    throw new SQLException(
                            "Số lượng sản phẩm không hợp lệ."
                    );
                }

                int affected = update(
                        connection,
                        "UPDATE dbo.PRODUCT_SKU "
                        + "SET stock_quantity = stock_quantity + ? "
                        + "WHERE sku_id = ?",
                        item[1],
                        item[0]
                );

                if (affected != 1) {
                    throw new SQLException(
                            "Không hoàn được tồn kho."
                    );
                }
            }
        }

        update(
                connection,
                "UPDATE dbo.[ORDER] "
                + "SET order_status = 'CANCELLED', "
                + "payment_status = 'UNPAID', "
                + "stock_restored_at = COALESCE("
                + "stock_restored_at, SYSUTCDATETIME()) "
                + "WHERE order_id = ?",
                order.id
        );

        update(
                connection,
                "UPDATE dbo.PAYMENT_TRANSACTION "
                + "SET status = 'EXPIRED' "
                + "WHERE order_id = ? AND status = 'PENDING'",
                order.id
        );

        // Giu luot voucher theo nghiep vu huy COD hien tai
        history(connection, order.id, "CANCELLED");

        order.status = "CANCELLED";
        order.restored = true;
    }

    // Bat dau thanh toan hoac mo lai link dang cho
    public Attempt begin(
            int userId,
            int orderId
    ) throws SQLException {

        try (Connection connection = open()) {
            connection.setAutoCommit(false);

            try {
                LockedOrder order = lock(connection, orderId);

                if (order.owner != userId) {
                    throw new IllegalArgumentException(
                            "Không tìm thấy đơn hàng."
                    );
                }

                if (expire(connection, order)) {
                    connection.commit();

                    throw new IllegalArgumentException(
                            "Đơn đã hết 15 phút thanh toán "
                            + "và được hủy."
                    );
                }

                if (!"PENDING_PAYMENT".equals(order.status)
                        || "PAID".equals(order.payment)
                        || order.restored) {

                    throw new IllegalArgumentException(
                            "Đơn không còn chờ thanh toán."
                    );
                }

                PaymentGateway.requireConfigured(order.method);

                String sql =
                        "SELECT TOP 1 transaction_code, pay_url, "
                        + "DATEDIFF(SECOND, created_at, "
                        + "SYSUTCDATETIME()) AS age "
                        + "FROM dbo.PAYMENT_TRANSACTION "
                        + "WHERE order_id = ? "
                        + "AND payment_method = ? "
                        + "AND status = 'PENDING' "
                        + "ORDER BY transaction_id DESC";

                try (PreparedStatement ps =
                        connection.prepareStatement(sql)) {

                    ps.setInt(1, orderId);
                    ps.setString(2, order.method);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            String url = rs.getString("pay_url");

                            // Dung lai link de tranh tao nhieu giao dich
                            if (url != null) {
                                Attempt attempt = new Attempt(
                                        rs.getString("transaction_code"),
                                        order.method,
                                        url,
                                        order.amount,
                                        order.seconds
                                );

                                connection.commit();
                                return attempt;
                            }

                            if (rs.getInt("age") < 30) {
                                throw new IllegalArgumentException(
                                        "Đang tạo thanh toán. "
                                        + "Chờ vài giây rồi thử lại."
                                );
                            }
                        }
                    }
                }

                update(
                        connection,
                        "UPDATE dbo.PAYMENT_TRANSACTION "
                        + "SET status = 'EXPIRED' "
                        + "WHERE order_id = ? AND status = 'PENDING'",
                        orderId
                );

                String ref = "OECS"
                        + orderId
                        + UUID.randomUUID()
                                .toString()
                                .replace("-", "");

                update(
                        connection,
                        "INSERT INTO dbo.PAYMENT_TRANSACTION "
                        + "(order_id, payment_method, amount, "
                        + "transaction_code) VALUES (?, ?, ?, ?)",
                        orderId,
                        order.method,
                        order.amount,
                        ref
                );

                connection.commit();

                return new Attempt(
                        ref,
                        order.method,
                        null,
                        order.amount,
                        order.seconds
                );

            } catch (SQLException | RuntimeException e) {
                rollback(connection, e);
                throw e;
            }
        }
    }

    // Luu link do cong thanh toan tra ve
    public void saveUrl(
            String ref,
            String url
    ) throws SQLException {

        try (Connection connection = open()) {
            update(
                    connection,
                    "UPDATE dbo.PAYMENT_TRANSACTION "
                    + "SET pay_url = ? "
                    + "WHERE transaction_code = ? "
                    + "AND status = 'PENDING'",
                    url,
                    ref
            );
        }
    }

    // toCod = true: doi COD; false: huy don dang cho
    public void changeOrCancel(
            int userId,
            int orderId,
            boolean toCod
    ) throws SQLException {

        try (Connection connection = open()) {
            connection.setAutoCommit(false);

            try {
                LockedOrder order = lock(connection, orderId);

                if (order.owner != userId) {
                    throw new IllegalArgumentException(
                            "Không tìm thấy đơn hàng."
                    );
                }

                if (expire(connection, order)) {
                    connection.commit();
                    return;
                }

                // Gui lap thao tac doi COD
                if (toCod
                        && "COD".equals(order.method)
                        && "PENDING_CONFIRMATION".equals(order.status)) {

                    connection.commit();
                    return;
                }

                // Gui lap thao tac huy
                if (!toCod && "CANCELLED".equals(order.status)) {
                    connection.commit();
                    return;
                }

                if (!"PENDING_PAYMENT".equals(order.status)
                        || "PAID".equals(order.payment)
                        || order.restored) {

                    throw new IllegalArgumentException(
                            "Đơn không còn chờ thanh toán. "
                            + "Hãy tải lại trang."
                    );
                }

                if (toCod) {
                    update(
                            connection,
                            "UPDATE dbo.[ORDER] "
                            + "SET payment_method = 'COD', "
                            + "payment_expires_at = NULL, "
                            + "order_status = 'PENDING_CONFIRMATION', "
                            + "payment_status = 'UNPAID' "
                            + "WHERE order_id = ?",
                            orderId
                    );

                    update(
                            connection,
                            "UPDATE dbo.PAYMENT_TRANSACTION "
                            + "SET status = 'CANCELLED' "
                            + "WHERE order_id = ? "
                            + "AND status = 'PENDING'",
                            orderId
                    );

                    history(
                            connection,
                            orderId,
                            "PENDING_CONFIRMATION"
                    );

                } else {
                    cancel(connection, order);
                }

                connection.commit();

            } catch (SQLException | RuntimeException e) {
                rollback(connection, e);
                throw e;
            }
        }
    }

    // Chi goi sau khi servlet da xac minh chu ky va merchant
    public String settle(
            String method,
            String ref,
            BigDecimal amount,
            String providerId,
            String code,
            boolean success
    ) throws SQLException {

        try (Connection connection = open()) {
            connection.setAutoCommit(false);

            try {
                int orderId;

                String sql =
                        "SELECT order_id "
                        + "FROM dbo.PAYMENT_TRANSACTION "
                        + "WHERE transaction_code = ? "
                        + "AND payment_method = ?";

                try (PreparedStatement ps =
                        connection.prepareStatement(sql)) {

                    ps.setString(1, ref);
                    ps.setString(2, method);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            connection.rollback();
                            return "01";
                        }

                        orderId = rs.getInt("order_id");
                    }
                }

                LockedOrder order = lock(connection, orderId);

                long transactionId;
                String transactionStatus;
                BigDecimal expectedAmount;

                sql =
                        "SELECT transaction_id, status, amount "
                        + "FROM dbo.PAYMENT_TRANSACTION "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE transaction_code = ? "
                        + "AND payment_method = ?";

                try (PreparedStatement ps =
                        connection.prepareStatement(sql)) {

                    ps.setString(1, ref);
                    ps.setString(2, method);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException(
                                    "Không tìm thấy giao dịch."
                            );
                        }

                        transactionId = rs.getLong("transaction_id");
                        transactionStatus = rs.getString("status");
                        expectedAmount = rs.getBigDecimal("amount");
                    }
                }

                if (expectedAmount.compareTo(amount) != 0
                        || order.amount.compareTo(amount) != 0) {

                    connection.rollback();
                    return "04";
                }

                // Callback lap: khong xu ly thanh cong lan nua
                if ("SUCCESS".equals(transactionStatus)) {
                    connection.commit();
                    return "02";
                }

                if (success
                        && (providerId == null
                        || providerId.isEmpty()
                        || "0".equals(providerId))) {

                    connection.rollback();
                    return "99";
                }

                // Kiem tra han ngay ca khi worker chua kip chay
                expire(connection, order);

                if (!success) {
                    update(
                            connection,
                            "UPDATE dbo.PAYMENT_TRANSACTION "
                            + "SET status = 'FAILED', "
                            + "provider_response_code = ?, "
                            + "completed_at = SYSUTCDATETIME() "
                            + "WHERE transaction_id = ? "
                            + "AND status <> 'SUCCESS'",
                            code,
                            transactionId
                    );

                    connection.commit();
                    return "00";
                }

                update(
                        connection,
                        "UPDATE dbo.PAYMENT_TRANSACTION "
                        + "SET status = 'SUCCESS', "
                        + "provider_transaction_id = ?, "
                        + "provider_response_code = ?, "
                        + "completed_at = SYSUTCDATETIME() "
                        + "WHERE transaction_id = ?",
                        providerId,
                        code,
                        transactionId
                );

                boolean canConfirm =
                        "PENDING_PAYMENT".equals(order.status)
                        && !"PAID".equals(order.payment)
                        && !order.restored
                        && method.equals(order.method)
                        && order.seconds > 0;

                if (canConfirm) {
                    update(
                            connection,
                            "UPDATE dbo.[ORDER] "
                            + "SET payment_status = 'PAID', "
                            + "order_status = 'PENDING_CONFIRMATION', "
                            + "payment_expires_at = NULL "
                            + "WHERE order_id = ?",
                            orderId
                    );

                    update(
                            connection,
                            "UPDATE dbo.PAYMENT_TRANSACTION "
                            + "SET status = 'CANCELLED' "
                            + "WHERE order_id = ? "
                            + "AND transaction_id <> ? "
                            + "AND status = 'PENDING'",
                            orderId,
                            transactionId
                    );

                    history(
                            connection,
                            orderId,
                            "PENDING_CONFIRMATION"
                    );

                } else {
                    // Tien ve tre, doi COD hoac thanh toan trung
                    // Chi tao yeu cau hoan tien, khong hoi sinh don
                    update(
                            connection,
                            "INSERT INTO dbo.PAYMENT_REFUND "
                            + "(transaction_id, refund_amount, reason) "
                            + "VALUES (?, ?, ?)",
                            transactionId,
                            amount,
                            "Thanh toán về trễ, đổi COD hoặc "
                            + "thanh toán trùng; cần đối soát "
                            + "và hoàn tiền."
                    );

                    if ("CANCELLED".equals(order.status)) {
                        update(
                                connection,
                                "UPDATE dbo.[ORDER] "
                                + "SET payment_status = 'REFUND_PENDING' "
                                + "WHERE order_id = ?",
                                orderId
                        );
                    }
                }

                connection.commit();
                return "00";

            } catch (SQLException | RuntimeException e) {
                rollback(connection, e);
                throw e;
            }
        }
    }

    // Kiem tra het han cua mot don
    public void expireOrder(
            int userId,
            int orderId
    ) throws SQLException {

        try (Connection connection = open()) {
            connection.setAutoCommit(false);

            try {
                LockedOrder order = lock(connection, orderId);

                if (order.owner != userId) {
                    throw new IllegalArgumentException(
                            "Không tìm thấy đơn hàng."
                    );
                }

                expire(connection, order);
                connection.commit();

            } catch (SQLException | RuntimeException e) {
                rollback(connection, e);
                throw e;
            }
        }
    }

    // Worker goi de quet cac don qua han
    public void expireBatch() throws SQLException {
        List<int[]> orders = new ArrayList<>();

        String sql =
                "SELECT TOP 200 order_id, user_id "
                + "FROM dbo.[ORDER] "
                + "WHERE order_status = 'PENDING_PAYMENT' "
                + "AND payment_expires_at <= SYSUTCDATETIME() "
                + "ORDER BY order_id";

        try (
                Connection connection = open();
                PreparedStatement ps =
                        connection.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()
        ) {
            while (rs.next()) {
                orders.add(new int[]{
                    rs.getInt("order_id"),
                    rs.getInt("user_id")
                });
            }
        }

        for (int[] order : orders) {
            expireOrder(order[1], order[0]);
        }
    }
}