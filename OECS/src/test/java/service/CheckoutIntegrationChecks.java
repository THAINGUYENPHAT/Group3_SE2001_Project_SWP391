package service;

import dao.AddressDAO;
import dao.OrderDAO;
import db.CheckoutConnectionFactory;
import db.DBContext;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Run explicitly with scripts/check-checkout.ps1; creates and removes its own
 * isolated SQL Server database.
 */
public final class CheckoutIntegrationChecks {

    private final String database = "OECS_checkout_test_" + UUID.randomUUID().toString().replace("-", "").substring(0, 12);
    private final CheckoutConnectionFactory connections = () -> {
        Connection connection = new DBContext().getConnection();
        if (connection == null) {
            throw new SQLException("SQL Server is unavailable");
        }
        connection.setCatalog(database);
        return connection;
    };
    private final OrderService checkout = new OrderService(connections);
    private int passed;

    public static void main(String[] args) throws Exception {
        if (args.length < 1 || args.length > 2) {
            throw new IllegalArgumentException("Pass the path to DB_OECS.sql");
        }
        new CheckoutIntegrationChecks().run(Path.of(args[0]), args.length == 2 && "--staff-cancel-only".equals(args[1]));
    }

    private void run(Path schemaFile, boolean staffOnly) throws Exception {
        boolean created = false;
        try (Connection admin = new DBContext().getConnection()) {
            if (admin == null) {
                throw new SQLException("SQL Server is unavailable");
            }
            admin.setCatalog("master");
            try {
                try (Statement statement = admin.createStatement()) {
                    statement.executeUpdate("CREATE DATABASE [" + database + "]");
                    created = true;
                }
                createSchema(schemaFile);
                seed();
                migrationChecks(schemaFile);
                if (staffOnly) {
                    staffCancellationChecks();
                    customerCancellationChecks();
                } else {
                    rememberAddress();
                    int orderId = duplicateCheckout();
                    ownershipAndSnapshots(orderId);
                    cancelTwice(orderId);
                    invalidAndRollback();
                    purchaseHistoryChecks();
                    selectedCheckoutChecks();
                    servletGuards();
                    cancellationPolicyChecks();
                    paymentReviewChecks();
                    shippingFeeChecks();
                    staffCancellationChecks();
                    stockConfirmationChecks();
                    customerCancellationChecks();
                }
                System.out.println("PASS: " + passed + " checkout/order integration assertions");
            } finally {
                // Only the exact database created above is eligible for cleanup.
                if (created && database.matches("OECS_checkout_test_[a-f0-9]{12}")) {
                    try (Statement statement = admin.createStatement()) {
                        statement.executeUpdate("ALTER DATABASE [" + database + "] SET SINGLE_USER WITH ROLLBACK IMMEDIATE");
                        statement.executeUpdate("DROP DATABASE [" + database + "]");
                        System.out.println("Removed isolated test database: " + database);
                    }
                }
            }
        }
    }

    private void createSchema(Path schemaFile) throws Exception {

        byte[] bytes = Files.readAllBytes(schemaFile);

        String schema = new String(
                bytes,
                bytes.length > 1
                && bytes[0] == (byte) 0xff
                && bytes[1] == (byte) 0xfe
                        ? StandardCharsets.UTF_16LE
                        : StandardCharsets.UTF_8
        );

        String[] tables = {
            "ROLES",
            "USER",
            "ADDRESSBOOK",
            "CATEGORY",
            "BRAND",
            "PRODUCT",
            "PRODUCT_SKU",
            "CART",
            "CART_ITEMS",
            "VOUCHER",
            "ORDER",
            "ORDER_ITEM",
            "ORDER_STATUS_HISTORY",
            "VOUCHER_USAGES",
            "ORDER_CUSTOMER_POLICY",
            "PAYMENT_TRANSACTION",
            "NOTIFICATION",
            "AUDIT_LOG"
        };

        for (String table : tables) {

            Matcher match = Pattern.compile(
                    "^CREATE TABLE \\[?" + table
                    + "\\]? \\([\\s\\S]*?^\\);",
                    Pattern.MULTILINE
            ).matcher(schema);

            if (!match.find()) {
                throw new IllegalStateException(
                        "Cannot find schema for " + table);
            }

            execute(match.group());
        }

        execute(
                "CREATE UNIQUE INDEX UX_Order_CheckoutToken "
                + "ON dbo.[ORDER](checkout_token) "
                + "WHERE checkout_token IS NOT NULL"
        );
    }

    private void seed() throws SQLException {

        execute(
                "INSERT INTO dbo.ROLES (role_name, description) VALUES "
                + "(N'ADMIN', N'Quản trị viên hệ thống'), "
                + "(N'STAFF', N'Nhân viên'), "
                + "(N'CUSTOMER', N'Khách hàng')"
        );

        execute(
                "INSERT INTO dbo.[USER] "
                + "(username, email, password_hash, role_id) "
                + "SELECT v.username, v.email, v.password_hash, r.role_id "
                + "FROM (VALUES "
                + "('checkout-test', 'test@example.invalid', 'test'), "
                + "('other-test', 'other@example.invalid', 'test') "
                + ") AS v(username, email, password_hash) "
                + "CROSS JOIN dbo.ROLES r "
                + "WHERE r.role_name = N'CUSTOMER'"
        );

        execute(
                "INSERT INTO dbo.ADDRESSBOOK "
                + "(user_id, recipient_name, phone_number, address_line) VALUES "
                + "(1, N'Người nhận', '0901234567', N'Địa chỉ đã đặt'), "
                + "(1, N'Địa chỉ 2', '0901234568', N'Địa chỉ thứ hai'), "
                + "(2, N'Khách khác', '0901234569', N'Địa chỉ khác')"
        );

        execute("INSERT INTO dbo.CATEGORY(category_name) VALUES ('test')");
        execute("INSERT INTO dbo.BRAND(brand_name) VALUES ('test')");

        execute(
                "INSERT INTO dbo.PRODUCT(category_id, brand_id, product_name) "
                + "VALUES (1, 1, N'Sản phẩm kiểm thử')"
        );

        execute(
                "INSERT INTO dbo.PRODUCT_SKU "
                + "(product_id, sku_code, price, stock_quantity) "
                + "VALUES (1, 'TEST-SKU', 100000, 20)"
        );

        execute("INSERT INTO dbo.CART(user_id) VALUES (1), (2)");

        execute(
                "INSERT INTO dbo.VOUCHER "
                + "(code, valid_from, valid_to, discount_type, discount_value, usage_limit, per_user_limit) "
                + "VALUES ('TEST10', DATEADD(day,-1,GETDATE()), "
                + "DATEADD(day,1,GETDATE()), 'AMOUNT', 10000, 10, 10)"
        );
    }

    private void rememberAddress() throws Exception {
        AddressDAO addresses = new AddressDAO(connections);
        check(addresses.setDefaultAddress(2, 1), "remember selected address");
        check(new AddressDAO(connections).getAddressesByUser(1).get(0).getAddressId() == 2, "selection survives new DAO/session");
        check(!addresses.setDefaultAddress(3, 1), "cannot select another customer's address");
        check(scalar("SELECT COUNT(*) FROM dbo.ADDRESSBOOK WHERE user_id=1 AND is_default=1") == 1, "one default remains after invalid selection");
        parallel(() -> new AddressDAO(connections).setDefaultAddress(1, 1),
                () -> new AddressDAO(connections).setDefaultAddress(2, 1));
        check(scalar("SELECT COUNT(*) FROM dbo.ADDRESSBOOK WHERE user_id=1 AND is_default=1") == 1, "concurrent selections keep one default");
    }

    private int duplicateCheckout() throws Exception {
        execute("INSERT INTO dbo.CART_ITEMS(cart_id,sku_id,quantity) VALUES (1,1,2)");
        String token = UUID.randomUUID().toString();
        Object[] ids = parallel(() -> checkout.placeCodOrder(1, 1, token, "TEST10"),
                () -> checkout.placeCodOrder(1, 1, token, "TEST10"));
        int orderId = (Integer) ids[0];
        check(ids[0].equals(ids[1]), "concurrent duplicate checkout returns same order");
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER]") == 1, "only one order inserted");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 20, "checkout does not deduct stock");
        check(scalar("SELECT COUNT(*) FROM dbo.CART_ITEMS WHERE cart_id=1") == 0, "cart cleared after success");
        check(scalar("SELECT COUNT(*) FROM dbo.VOUCHER_USAGES") == 1, "voucher consumed once");
        check(scalar("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY") == 1, "one initial history entry");
        check(scalar("SELECT total_amount FROM dbo.[ORDER] WHERE order_id=" + orderId) == 220000, "server total includes voucher and shipping");
        check(checkout.placeCodOrder(1, 1, token, null) == orderId, "replay works after cart emptied");
        return orderId;
    }

    private void ownershipAndSnapshots(int id) throws Exception {
        OrderDAO orders = new OrderDAO(connections);
        check(orders.findByUser(1).size() == 1 && orders.findByUser(2).isEmpty(), "list scoped to owner");
        check(orders.findByIdAndUser(id, 2) == null, "detail scoped to owner");
        check(orders.findItems(id, 2).isEmpty() && checkout.findHistory(id, 2).isEmpty(), "items/history scoped to owner");
        execute("UPDATE dbo.PRODUCT_SKU SET price=200000 WHERE sku_id=1");
        execute("UPDATE dbo.ADDRESSBOOK SET address_line=N'Địa chỉ đã sửa' WHERE address_id=1");
        check(new BigDecimal("100000").compareTo((BigDecimal) orders.findItems(id, 1).get(0).get("price")) == 0, "item price is original purchase price");
        check("Địa chỉ đã đặt".equals(orders.findByIdAndUser(id, 1).getShippingAddress()), "delivery address is original snapshot");
        check("Chờ xác nhận".equals(checkout.findHistory(id, 1).get(0).get("label")), "history has customer status label");
        expectInvalid(() -> checkout.cancelOrderByCustomer(2, id), "cannot cancel another customer's order");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 20, "unauthorized cancellation leaves stock unchanged");
    }

    private void cancelTwice(int id) throws Exception {
        Object[] changed = parallel(() -> checkout.cancelOrderByCustomer(1, id), () -> checkout.cancelOrderByCustomer(1, id));
        check(!changed[0].equals(changed[1]), "only one simultaneous cancellation changes state");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 20, "cancelling unconfirmed order leaves stock unchanged");
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id=" + id + " AND order_status='CANCELLED' AND stock_restored_at IS NULL") == 1, "unconfirmed cancellation does not mark stock as restored");
        check(scalar("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id=" + id + " AND status='CANCELLED'") == 1, "one cancellation history entry");
        check(!checkout.cancelOrderByCustomer(1, id), "repeated cancellation is idempotent");
        check(scalar("SELECT COUNT(*) FROM dbo.VOUCHER_USAGES") == 1, "cancellation retains recorded voucher use");
    }

    private void invalidAndRollback() throws Exception {
        execute("INSERT INTO dbo.CART_ITEMS(cart_id,sku_id,quantity) VALUES (1,1,50)");
        expectInvalid(() -> checkout.placeCodOrder(1, 1, UUID.randomUUID().toString(), null), "reject insufficient stock");
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER]") == 1, "failed checkout creates no order");
        check(scalar("SELECT quantity FROM dbo.CART_ITEMS WHERE cart_id=1") == 50, "failed checkout preserves cart");
        execute("UPDATE dbo.CART_ITEMS SET quantity=1 WHERE cart_id=1");
        expectInvalid(() -> checkout.placeCodOrder(1, 3, UUID.randomUUID().toString(), null), "reject foreign checkout address");
        expectInvalid(() -> checkout.placeCodOrder(1, 1, UUID.randomUUID().toString(), "MISSING"), "reject invalid voucher");

        // Real SQL constraint failure after inventory, order and item writes tests full rollback.
        execute("ALTER TABLE dbo.ORDER_STATUS_HISTORY WITH NOCHECK ADD CONSTRAINT CK_Test_FailPending CHECK (status <> 'PENDING_CONFIRMATION')");
        expectSql(() -> checkout.placeCodOrder(1, 1, UUID.randomUUID().toString(), "TEST10"), "checkout failure rolls back");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 20, "checkout rollback restores stock");
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER]") == 1 && scalar("SELECT COUNT(*) FROM dbo.VOUCHER_USAGES") == 1, "checkout rollback removes order and voucher changes");
        execute("ALTER TABLE dbo.ORDER_STATUS_HISTORY DROP CONSTRAINT CK_Test_FailPending");
        int id = checkout.placeCodOrder(1, 1, UUID.randomUUID().toString(), null);
        execute("ALTER TABLE dbo.ORDER_STATUS_HISTORY WITH NOCHECK ADD CONSTRAINT CK_Test_FailCancel CHECK (status <> 'CANCELLED')");
        expectSql(() -> checkout.cancelOrderByCustomer(1, id), "cancellation history failure rolls back");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 20, "cancellation rollback preserves untouched stock");
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id=" + id + " AND order_status='PENDING_CONFIRMATION' AND stock_restored_at IS NULL") == 1, "cancellation rollback preserves status and marker");
        execute("ALTER TABLE dbo.ORDER_STATUS_HISTORY DROP CONSTRAINT CK_Test_FailCancel");
        execute("UPDATE dbo.[ORDER] SET order_status='SHIPPING' WHERE order_id=" + id);
        expectInvalid(() -> checkout.cancelOrderByCustomer(1, id), "cannot cancel shipped order");
        execute("UPDATE dbo.[ORDER] SET order_status='PENDING_CONFIRMATION',payment_method='VNPAY',payment_status='PAID' WHERE order_id=" + id);
        expectInvalid(() -> checkout.cancelOrderByCustomer(1, id), "paid order without successful transaction needs reconciliation");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 20, "rejected cancellations preserve stock");
        check("Chờ xác nhận".equals(OrderService.statusLabel("Pending"))
                && "Đã xác nhận".equals(OrderService.statusLabel("Confirmed")), "staff history formats supported");
    }

    private void purchaseHistoryChecks() throws Exception {
        OrderDAO orders = new OrderDAO(connections);
        for (String status : new String[]{"PENDING", "CONFIRMED", "PACKING", "SHIPPING", "DELIVERED", "COMPLETED", "CANCELLED", "CUSTOM_STATE"}) {
            execute("INSERT INTO dbo.[ORDER](user_id,address_id,total_amount,shipping_fee,discount_amount,order_status,payment_method,payment_status) "
                    + "VALUES(1,1,200000,0,0,'" + status + "','COD','UNPAID')");
        }
        for (int i = 0; i < 11; i++) {
            execute("INSERT INTO dbo.[ORDER](user_id,address_id,total_amount,order_status,payment_method,payment_status) VALUES(1,1,200000,'PENDING_CONFIRMATION','COD','UNPAID')");
        }
        execute("INSERT INTO dbo.[ORDER](user_id,address_id,total_amount,order_status) VALUES(2,3,200000,'COMPLETED')");
        execute("INSERT INTO dbo.ORDER_ITEM(order_id,sku_id,price,quantity) SELECT order_id,1,200000,1 FROM dbo.[ORDER] o WHERE NOT EXISTS (SELECT 1 FROM dbo.ORDER_ITEM i WHERE i.order_id=o.order_id)");

        java.util.Map<String, Long> counts = OrderService.purchaseTabCounts(orders.countPurchasesByStatus(1, ""));
        check(counts.get("ALL") == 21 && counts.get("PENDING") == 13, "tab counts include legacy pending and stay scoped to customer");
        check(counts.get("PREPARING") == 2 && counts.get("COMPLETED") == 2 && counts.get("CANCELLED") == 2,
                "confirmed/packing and delivered/completed grouped into purchase tabs");
        java.util.List<model.Order> first = orders.findPurchasePage(1, "", OrderService.statusesForTab("ALL"), 0, 10);
        java.util.List<model.Order> second = orders.findPurchasePage(1, "", OrderService.statusesForTab("ALL"), 10, 10);
        java.util.List<model.Order> last = orders.findPurchasePage(1, "", OrderService.statusesForTab("ALL"), 20, 10);
        java.util.Set<Integer> ids = new java.util.HashSet<>();
        for (model.Order order : first) {
            ids.add(order.getOrderId());
        }
        for (model.Order order : second) {
            ids.add(order.getOrderId());
        }
        for (model.Order order : last) {
            ids.add(order.getOrderId());
        }
        check(first.size() == 10 && second.size() == 10 && last.size() == 1 && ids.size() == 21,
                "purchase pagination has no duplicates or missing orders");
        check(first.get(0).getOrderId() > second.get(0).getOrderId(), "newest purchases displayed first");
        check(orders.findPurchasePage(1, "", OrderService.statusesForTab("SHIPPING"), 0, 10).size() == 1,
                "shipping tab filters in database");
        check(orders.findPurchasePage(1, "", OrderService.statusesForTab("COMPLETED"), 0, 10).size() == 2,
                "purchase history contains delivered and completed orders");
        int id = first.get(0).getOrderId();
        check(orders.findPurchasePage(1, "#" + id, java.util.Collections.emptyList(), 0, 10).size() == 1,
                "search accepts a visible order number");
        check(orders.findPurchasePage(1, "Sản phẩm", java.util.Collections.emptyList(), 0, 10).size() == 10,
                "search supports Vietnamese product names");
        check(OrderService.purchaseTabCounts(orders.countPurchasesByStatus(1, "TEST-SKU")).get("ALL") == 21,
                "SKU search counts orders rather than item rows");
        check(orders.findPurchasePage(1, "%", java.util.Collections.emptyList(), 0, 10).isEmpty()
                && orders.findPurchasePage(1, "_", java.util.Collections.emptyList(), 0, 10).isEmpty(), "search treats wildcard characters literally");
        check(orders.findPurchasePage(1, "' OR 1=1 --", java.util.Collections.emptyList(), 0, 10).isEmpty(), "search parameters cannot change SQL");
        check(orders.findPurchasePage(2, "#" + id, java.util.Collections.emptyList(), 0, 10).isEmpty(), "search cannot reveal another customer's order");
        check(orders.findItemsForOrders(2, java.util.Arrays.asList(id)).isEmpty(), "bulk card items verify owner");
        check(orders.findItemsForOrders(1, java.util.Arrays.asList(id)).get(id).size() == 1, "bulk card items populate selected page");

        model.Order shipping = orders.findPurchasePage(1, "", OrderService.statusesForTab("SHIPPING"), 0, 10).get(0);
        java.util.List<java.util.Map<String, Object>> steps = OrderService.trackingSteps(shipping, java.util.Collections.emptyList());
        check(steps.size() == 5 && Boolean.TRUE.equals(steps.get(3).get("current"))
                && Boolean.FALSE.equals(steps.get(4).get("done")), "tracking highlights shipping without claiming delivery");
        check(steps.get(1).get("at") == null, "tracking never invents timestamps for missing history");
        shipping.setOrderStatus("CANCELLED");
        check(OrderService.trackingSteps(shipping, java.util.Collections.emptyList()).isEmpty(), "cancelled order does not render a delivery success path");
        shipping.setOrderStatus("CUSTOM_STATE");
        check(OrderService.trackingSteps(shipping, java.util.Collections.emptyList()).isEmpty(), "unknown status does not fabricate progress");
        shipping.setOrderStatus("DELIVERED");
        check(Boolean.TRUE.equals(OrderService.trackingSteps(shipping, java.util.Collections.emptyList()).get(4).get("current")), "delivered order reaches final tracking step");
    }

    private void selectedCheckoutChecks() throws Exception {
        execute("INSERT INTO dbo.PRODUCT_SKU(product_id,sku_code,price,stock_quantity) VALUES (1,'UNSELECTED-SKU',50000,10)");
        execute("INSERT INTO dbo.CART_ITEMS(cart_id,sku_id,quantity) VALUES (1,1,2),(1,2,3),(2,1,1)");
        int selectedId = (int) scalar("SELECT cart_item_id FROM dbo.CART_ITEMS WHERE cart_id=1 AND sku_id=1");
        int foreignId = (int) scalar("SELECT cart_item_id FROM dbo.CART_ITEMS WHERE cart_id=2");
        long ordersBefore = scalar("SELECT COUNT(*) FROM dbo.[ORDER]");
        long stockBefore = scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1");
        expectInvalid(() -> checkout.placeCodOrder(1, 1, UUID.randomUUID().toString(), null,
                java.util.Collections.emptyList()), "empty selection cannot checkout the whole cart");
        expectInvalid(() -> checkout.placeCodOrder(1, 1, UUID.randomUUID().toString(), null,
                java.util.Arrays.asList(selectedId, foreignId)), "selection cannot include another customer's cart item");
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER]") == ordersBefore
                && scalar("SELECT COUNT(*) FROM dbo.CART_ITEMS WHERE cart_id=1") == 2,
                "invalid selection preserves orders and cart");
        String token = UUID.randomUUID().toString();
        int orderId = checkout.placeCodOrder(1, 1, token, "TEST10",
                java.util.Arrays.asList(selectedId, selectedId));
        check(scalar("SELECT COUNT(*) FROM dbo.ORDER_ITEM WHERE order_id=" + orderId) == 1
                && scalar("SELECT quantity FROM dbo.ORDER_ITEM WHERE order_id=" + orderId) == 2,
                "selected checkout deduplicates item IDs");
        check(scalar("SELECT total_amount FROM dbo.[ORDER] WHERE order_id=" + orderId) == 420000,
                "selected checkout applies voucher and shipping only to purchased items");
        check(scalar("SELECT COUNT(*) FROM dbo.CART_ITEMS WHERE cart_id=1") == 1
                && scalar("SELECT quantity FROM dbo.CART_ITEMS WHERE cart_id=1 AND sku_id=2") == 3,
                "unselected items stay in cart");
        check(checkout.placeCodOrder(1, 1, token, "TEST10", java.util.Arrays.asList(selectedId)) == orderId
                && scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == stockBefore,
                "selected checkout replay does not deduct stock again");
        check(checkout.cancelOrderByCustomer(1, orderId)
                && scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == stockBefore
                && scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=2") == 10,
                "cancelling selected checkout leaves all SKU stock unchanged");
    }

    private void shippingFeeChecks() throws Exception {
        check(OrderService.calculateShippingFee(new BigDecimal("4999999")).intValueExact() == 30000,
                "shipping costs 30000 below five million");
        check(OrderService.calculateShippingFee(new BigDecimal("5000000")).signum() == 0,
                "shipping is free at exactly five million");
        check(OrderService.calculateShippingFee(new BigDecimal("5000001")).signum() == 0,
                "shipping is free above five million");
        execute("UPDATE dbo.PRODUCT_SKU SET price=4999999 WHERE sku_id=1");
        int below = policyOrder(1);
        check(scalar("SELECT shipping_fee FROM dbo.[ORDER] WHERE order_id=" + below) == 30000
                && scalar("SELECT total_amount FROM dbo.[ORDER] WHERE order_id=" + below) == 5029999,
                "order stores shipping and charges it even when final total crosses five million");
        execute("UPDATE dbo.PRODUCT_SKU SET price=5000000 WHERE sku_id=1");
        execute("INSERT INTO dbo.CART_ITEMS(cart_id,sku_id,quantity) VALUES (" + policyCart + ",1,1)");
        int threshold = checkout.placeCodOrder(policyUser, policyAddress, UUID.randomUUID().toString(), "TEST10");
        check(scalar("SELECT shipping_fee FROM dbo.[ORDER] WHERE order_id=" + threshold) == 0
                && scalar("SELECT total_amount FROM dbo.[ORDER] WHERE order_id=" + threshold) == 4990000,
                "voucher reducing total below threshold keeps free shipping");
        execute("UPDATE dbo.PRODUCT_SKU SET price=5000001 WHERE sku_id=1");
        int above = policyOrder(1);
        check(scalar("SELECT shipping_fee FROM dbo.[ORDER] WHERE order_id=" + above) == 0
                && scalar("SELECT total_amount FROM dbo.[ORDER] WHERE order_id=" + above) == 5000001,
                "above-threshold order stores free shipping");
        execute("UPDATE dbo.PRODUCT_SKU SET price=10000 WHERE sku_id=1");
        execute("INSERT INTO dbo.CART_ITEMS(cart_id,sku_id,quantity) VALUES (" + policyCart + ",1,1)");
        int discounted = checkout.placeCodOrder(policyUser, policyAddress, UUID.randomUUID().toString(), "TEST10");
        check(scalar("SELECT shipping_fee FROM dbo.[ORDER] WHERE order_id=" + discounted) == 30000
                && scalar("SELECT total_amount FROM dbo.[ORDER] WHERE order_id=" + discounted) == 30000,
                "full merchandise discount still charges shipping");
        check(scalar("SELECT shipping_fee FROM dbo.[ORDER] WHERE order_id=" + below) == 30000,
                "existing order keeps its shipping snapshot after prices change");
    }

    private int policyUser;
    private int policyAddress;
    private int policyCart;

    private int policyOrder(int quantity) throws Exception {
        execute("INSERT INTO dbo.CART_ITEMS(cart_id,sku_id,quantity) VALUES (" + policyCart + ",1," + quantity + ")");
        return checkout.placeCodOrder(policyUser, policyAddress, UUID.randomUUID().toString(), null);
    }

    private void cancellationPolicyChecks() throws Exception {
        execute(
                "INSERT INTO dbo.[USER] "
                + "(username, email, password_hash, role_id) "
                + "SELECT 'policy-test', 'policy@example.invalid', 'test', role_id "
                + "FROM dbo.ROLES "
                + "WHERE role_name = N'CUSTOMER'"
        );
        policyUser = (int) scalar("SELECT user_id FROM dbo.[USER] WHERE username='policy-test'");
        execute("INSERT INTO dbo.ADDRESSBOOK(user_id,recipient_name,phone_number,address_line) VALUES (" + policyUser + ",N'Policy','0901234567',N'Test')");
        policyAddress = (int) scalar("SELECT address_id FROM dbo.ADDRESSBOOK WHERE user_id=" + policyUser);
        execute("INSERT INTO dbo.CART(user_id) VALUES (" + policyUser + ")");
        policyCart = (int) scalar("SELECT cart_id FROM dbo.CART WHERE user_id=" + policyUser);
        execute("UPDATE dbo.PRODUCT_SKU SET stock_quantity=1000 WHERE sku_id=1");

        expectInvalid(() -> policyOrder(6), "six units rejected before creating order");
        execute("DELETE FROM dbo.CART_ITEMS WHERE cart_id=" + policyCart);
        int five = policyOrder(5);
        int one = policyOrder(1);
        int duringBlock = policyOrder(1);
        checkout.cancelOrderByCustomer(policyUser, five);
        check(checkout.orderingRestriction(policyUser) == null, "exactly five cancelled units allowed");
        checkout.cancelOrderByCustomer(policyUser, one);
        check(scalar("SELECT violation_count FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=" + policyUser) == 1,
                "six cancelled units trigger first strike");
        check(scalar("SELECT DATEDIFF(HOUR,SYSUTCDATETIME(),blocked_until) FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=" + policyUser) >= 71,
                "first strike blocks three days");
        expectInvalid(() -> policyOrder(1), "blocked customer cannot place an order");
        execute("DELETE FROM dbo.CART_ITEMS WHERE cart_id=" + policyCart);
        checkout.cancelOrderByCustomer(policyUser, duringBlock);
        check(scalar("SELECT violation_count FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=" + policyUser) == 1,
                "cancelling existing order during block does not escalate");
        check(!checkout.cancelOrderByCustomer(policyUser, duringBlock), "repeated cancellation does not add an event");

        expirePolicyBlock();
        check(checkout.orderingRestriction(policyUser) == null, "ordering resumes after block ends");
        final int firstConcurrent = policyOrder(3);
        final int secondConcurrent = policyOrder(3);
        parallel(() -> checkout.cancelOrderByCustomer(policyUser, firstConcurrent),
                () -> checkout.cancelOrderByCustomer(policyUser, secondConcurrent));
        check(scalar("SELECT violation_count FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=" + policyUser) == 2,
                "concurrent cancellations escalate once in new period");
        check(scalar("SELECT DATEDIFF(HOUR,SYSUTCDATETIME(),blocked_until) FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=" + policyUser) >= 167,
                "second strike blocks seven days");
        expirePolicyBlock();
        int first = policyOrder(5);
        int second = policyOrder(1);
        checkout.cancelOrderByCustomer(policyUser, first);
        checkout.cancelOrderByCustomer(policyUser, second);
        check(scalar("SELECT violation_count FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=" + policyUser) == 3,
                "third strike is permanent");
        check(checkout.orderingRestriction(policyUser).contains("vĩnh viễn"), "permanent block explained to customer");
        expectInvalid(() -> policyOrder(1), "permanent block enforced");
        execute("DELETE FROM dbo.CART_ITEMS WHERE cart_id=" + policyCart);

        // Reset only this isolated fixture to exercise the online cancellation entry point.
        execute("UPDATE dbo.[ORDER] "
                + "SET cancellation_source=NULL, cancelled_at=NULL "
                + "WHERE user_id=" + policyUser
                + " AND cancellation_source='CUSTOMER'");

        execute("DELETE FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=" + policyUser);
        int expired = policyOrder(5);
        execute("UPDATE dbo.[ORDER] SET payment_method='VNPAY',order_status='PENDING_PAYMENT',payment_expires_at=DATEADD(MINUTE,-1,SYSUTCDATETIME()) WHERE order_id=" + expired);
        dao.PaymentDAO payments = new dao.PaymentDAO(connections);
        payments.changeOrCancel(policyUser, expired, false);
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER] "
                + "WHERE order_id=" + expired
                + " AND cancellation_source='SYSTEM'") == 1,
                "automatic payment expiry is marked as system cancellation");
        int online = policyOrder(5);
        execute("UPDATE dbo.[ORDER] SET payment_method='VNPAY',order_status='PENDING_PAYMENT',payment_expires_at=DATEADD(MINUTE,15,SYSUTCDATETIME()) WHERE order_id=" + online);
        payments.changeOrCancel(policyUser, online, false);
        payments.changeOrCancel(policyUser, online, false);
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER] "
                + "WHERE order_id=" + online
                + " AND cancellation_source='CUSTOMER'") == 1,
                "explicit online cancellation recorded exactly once");

        check(scalar("SELECT COALESCE(SUM(CAST(i.quantity AS BIGINT)),0) "
                + "FROM dbo.ORDER_ITEM i "
                + "WHERE i.order_id=" + online) == 5,
                "explicit online cancellation quantity calculated from order items");
        // Old cancellation outside rolling seven days must not combine with a new one.
        execute("UPDATE dbo.[ORDER] "
                + "SET cancelled_at=DATEADD(DAY,-8,SYSUTCDATETIME()) "
                + "WHERE user_id=" + policyUser
                + " AND cancellation_source='CUSTOMER'");
        checkout.cancelOrderByCustomer(policyUser, policyOrder(1));
        check(checkout.orderingRestriction(policyUser) == null, "events older than seven days excluded");
    }

    private void expirePolicyBlock() throws SQLException {

        execute("UPDATE dbo.[ORDER] "
                + "SET cancelled_at=DATEADD(DAY,-10,SYSUTCDATETIME()) "
                + "WHERE user_id=" + policyUser
                + " AND cancellation_source='CUSTOMER'");

        execute("UPDATE dbo.ORDER_CUSTOMER_POLICY "
                + "SET blocked_until=DATEADD(SECOND,-1,SYSUTCDATETIME()) "
                + "WHERE user_id=" + policyUser);
    }

    private void paymentReviewChecks() throws Exception {

        int id = policyOrder(1);

        execute(
                "UPDATE dbo.[ORDER] "
                + "SET payment_method='VNPAY', "
                + "order_status='PENDING_PAYMENT', "
                + "payment_expires_at="
                + "DATEADD(MINUTE,15,SYSUTCDATETIME()) "
                + "WHERE order_id=" + id
        );

        execute(
                "INSERT INTO dbo.PAYMENT_TRANSACTION "
                + "(order_id,payment_method,amount,transaction_code) "
                + "SELECT order_id,'VNPAY',total_amount,'REVIEW-A' "
                + "FROM dbo.[ORDER] WHERE order_id=" + id
        );

        execute(
                "INSERT INTO dbo.PAYMENT_TRANSACTION "
                + "(order_id,payment_method,amount,transaction_code) "
                + "SELECT order_id,'VNPAY',total_amount,'REVIEW-B' "
                + "FROM dbo.[ORDER] WHERE order_id=" + id
        );

        BigDecimal amount = BigDecimal.valueOf(
                scalar(
                        "SELECT total_amount "
                        + "FROM dbo.[ORDER] "
                        + "WHERE order_id=" + id
                )
        );

        dao.PaymentDAO payments
                = new dao.PaymentDAO(connections);

        // 1. Giao dich sai so tien phai bi tu choi.
        check(
                "04".equals(
                        payments.settle(
                                "VNPAY",
                                "REVIEW-A",
                                amount.add(BigDecimal.ONE),
                                "PROVIDER-A",
                                "00",
                                true
                        )
                ),
                "incorrect callback amount rejected"
        );

        // 2. Giao dich dau tien thanh cong.
        check(
                "00".equals(
                        payments.settle(
                                "VNPAY",
                                "REVIEW-A",
                                amount,
                                "PROVIDER-A",
                                "00",
                                true
                        )
                ),
                "first payment confirms order"
        );

        // 3. Kiem tra callback trung lap.
        Object[] results = parallel(
                () -> payments.settle(
                        "VNPAY",
                        "REVIEW-B",
                        amount,
                        "PROVIDER-B",
                        "00",
                        true
                ),
                () -> payments.settle(
                        "VNPAY",
                        "REVIEW-B",
                        amount,
                        "PROVIDER-B",
                        "00",
                        true
                )
        );

        boolean validCallbacks
                = ("00".equals(results[0])
                || "02".equals(results[0]))
                && ("00".equals(results[1])
                || "02".equals(results[1]));

        check(
                validCallbacks,
                "callbacks are idempotent"
        );

        // 4. Khong xoa giao dich tien da nhan.
        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.PAYMENT_TRANSACTION "
                        + "WHERE order_id=" + id
                        + " AND status='SUCCESS'"
                ) == 2,
                "successful transactions are retained"
        );

        // 5. Ghi nhat ky de Staff doi soat thu cong.
        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.AUDIT_LOG "
                        + "WHERE entity_type='ORDER' "
                        + "AND entity_id=" + id
                        + " AND action='PAYMENT_REVIEW'"
                ) == 1,
                "surplus payment flagged for manual review"
        );

        // 6. Don hang van ghi nhan da thanh toan.
        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.[ORDER] "
                        + "WHERE order_id=" + id
                        + " AND payment_status='PAID'"
                ) == 1,
                "original payment status preserved"
        );
    }

    private void migrationChecks(Path schemaFile) throws Exception {
        String migration = Files.readString(schemaFile.getParent()
                .resolve("OECS/scripts/migrate-stock-on-confirmation.sql"));
        int cod = cancellationOrder("PENDING_CONFIRMATION", "COD", false);
        int online = cancellationOrder("PENDING_PAYMENT", "VNPAY", false);
        int confirmed = cancellationOrder("CONFIRMED", "COD", false);
        int sample = cancellationOrder("PENDING_CONFIRMATION", "COD", false);
        execute("UPDATE dbo.[ORDER] SET checkout_token=CONVERT(varchar(36),NEWID()) WHERE order_id IN (" + cod + "," + online + "," + confirmed + ")");
        execute("UPDATE dbo.PRODUCT_SKU SET stock_quantity=stock_quantity-4 WHERE sku_id=1");
        long columns = scalar("SELECT COUNT(*) FROM sys.columns");
        execute(migration);
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 18,
                "migration releases only legacy pending checkout stock");
        execute(migration);
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 18,
                "migration replay does not release inventory twice");
        check(scalar("SELECT COUNT(*) FROM sys.columns") == columns, "migration adds no database columns");
        check(cancellationStaffDAO().transitionStatus(cod, "CONFIRMED"), "migrated pending order can be confirmed");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 16,
                "migrated order deducts stock on confirmation");
        OrderCancellationService cancel = new OrderCancellationService(connections);
        cancel.staffCancel(1, cod);
        new dao.PaymentDAO(connections).expireOrder(1, online);
        // Explicit cancellation before its deadline is also inventory-neutral.
        new dao.PaymentDAO(connections).changeOrCancel(1, online, false);
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 18,
                "migrated online cancellation leaves inventory unchanged");
        cancel.staffCancel(1, confirmed);
        cancel.staffCancel(1, sample);
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 20,
                "legacy confirmed cancellation restores once while sample pending does not");
        execute("DELETE FROM dbo.NOTIFICATION");
        execute("DELETE FROM dbo.ORDER_STATUS_HISTORY");
        execute("DELETE FROM dbo.ORDER_CUSTOMER_POLICY");
        execute("DELETE FROM dbo.ORDER_ITEM");
        execute("DELETE FROM dbo.[ORDER]");
        execute("DBCC CHECKIDENT ('dbo.[ORDER]', RESEED, 0)");
    }

    private int confirmationOrder(String method, int quantity) throws Exception {
        execute("DELETE FROM dbo.CART_ITEMS WHERE cart_id=2");
        execute("INSERT INTO dbo.CART_ITEMS(cart_id,sku_id,quantity) VALUES (2,1," + quantity + ")");
        return checkout.placeOrder(2, 3, UUID.randomUUID().toString(), null, null, method);
    }

    private boolean tryConfirm(int orderId) throws Exception {
        try {
            return cancellationStaffDAO().transitionStatus(orderId, "CONFIRMED");
        } catch (IllegalArgumentException insufficientStock) {
            return false;
        }
    }

    private void stockConfirmationChecks() throws Exception {
        System.setProperty("PAYMENT_BASE_URL", "https://example.invalid/OECS");
        System.setProperty("VNPAY_TMN_CODE", "test-merchant");
        System.setProperty("VNPAY_HASH_SECRET", "test-secret");
        dao.AdminOrderDAO staff = cancellationStaffDAO();
        dao.PaymentDAO payments = new dao.PaymentDAO(connections);
        OrderCancellationService cancel = new OrderCancellationService(connections);
        execute("UPDATE dbo.PRODUCT_SKU SET stock_quantity=10 WHERE sku_id=1");
        int cod = confirmationOrder("COD", 2);
        int online = confirmationOrder("VNPAY", 2);
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 10,
                "COD and sandbox checkout leave stock unchanged");
        check(!staff.transitionStatus(online, "CONFIRMED"), "unpaid online order cannot be confirmed");
        execute("INSERT INTO dbo.PAYMENT_TRANSACTION(order_id,payment_method,amount,transaction_code) "
                + "SELECT order_id,'VNPAY',total_amount,'CONFIRM-ONLINE' FROM dbo.[ORDER] WHERE order_id=" + online);
        BigDecimal amount = BigDecimal.valueOf(scalar("SELECT total_amount FROM dbo.[ORDER] WHERE order_id=" + online));
        check("00".equals(payments.settle("VNPAY", "CONFIRM-ONLINE", amount, "CONFIRM-PROVIDER", "00", true)),
                "sandbox callback moves order to awaiting staff");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 10,
                "successful sandbox payment does not deduct stock");
        check(staff.transitionStatus(cod, "CONFIRMED") && staff.transitionStatus(online, "CONFIRMED"),
                "staff confirms both COD and paid sandbox");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 6,
                "staff confirmation deducts exact quantities for both methods");
        check(!staff.transitionStatus(cod, "CONFIRMED"), "duplicate staff confirmation rejected");
        cancel.staffCancel(1, cod);
        cancel.staffCancel(1, online);
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 10,
                "cancelling confirmed COD and paid sandbox restores their quantities");

        int expired = confirmationOrder("VNPAY", 1);
        execute("UPDATE dbo.[ORDER] SET payment_expires_at=DATEADD(MINUTE,-1,SYSUTCDATETIME()) WHERE order_id=" + expired);
        payments.expireOrder(2, expired);
        payments.expireOrder(2, expired);
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 10,
                "expiry and repeated expiry never increase unconfirmed stock");
        int switchCod = confirmationOrder("VNPAY", 1);
        payments.changeOrCancel(2, switchCod, true);
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 10,
                "switching online to COD leaves stock untouched");
        staff.transitionStatus(switchCod, "CONFIRMED");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 9,
                "switched COD deducts only when staff confirms");

        int concurrent = confirmationOrder("COD", 1);
        Object[] same = parallel(() -> tryConfirm(concurrent), () -> tryConfirm(concurrent));
        check(!same[0].equals(same[1]), "concurrent confirmation of one order succeeds once");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 8,
                "concurrent confirmation deducts stock once");

        execute("UPDATE dbo.PRODUCT_SKU SET stock_quantity=1 WHERE sku_id=1");
        int first = confirmationOrder("COD", 1);
        int second = confirmationOrder("VNPAY", 1);
        execute("UPDATE dbo.[ORDER] SET order_status='PENDING_CONFIRMATION',payment_status='PAID' WHERE order_id=" + second);
        execute("INSERT INTO dbo.PAYMENT_TRANSACTION(order_id,payment_method,amount,transaction_code,status) "
                + "SELECT order_id,'VNPAY',total_amount,'LAST-UNIT-'+CAST(order_id AS varchar),'SUCCESS' FROM dbo.[ORDER] WHERE order_id=" + second);
        Object[] last = parallel(() -> tryConfirm(first), () -> tryConfirm(second));
        check(!last[0].equals(last[1]), "only one of two orders can confirm the final SKU unit");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 0,
                "last-unit confirmation cannot make stock negative");
        int rejected = Boolean.TRUE.equals(last[0]) ? second : first;
        check("PENDING_CONFIRMATION".equals(staff.getCurrentStatus(rejected)),
                "insufficient-stock order stays pending");
        cancel.staffCancel(1, rejected);
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 0,
                "cancelling rejected confirmation does not create inventory");

        execute("UPDATE dbo.PRODUCT_SKU SET stock_quantity=10 WHERE sku_id=1");
        execute("UPDATE dbo.PRODUCT_SKU SET stock_quantity=10 WHERE sku_id=2");
        int multi = confirmationOrder("COD", 1);
        execute("INSERT INTO dbo.ORDER_ITEM(order_id,sku_id,quantity,price) VALUES (" + multi + ",2,1,100000)");
        execute("UPDATE dbo.PRODUCT_SKU SET stock_quantity=0 WHERE sku_id=2");
        expectInvalid(() -> staff.transitionStatus(multi, "CONFIRMED"), "multi-SKU confirmation rejects shortage");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 10,
                "multi-SKU shortage rolls back earlier deductions");
        check("PENDING_CONFIRMATION".equals(staff.getCurrentStatus(multi)),
                "multi-SKU shortage rolls back order status");

        int rollback = confirmationOrder("COD", 1);
        execute("CREATE TRIGGER dbo.fail_confirm_history ON dbo.ORDER_STATUS_HISTORY AFTER INSERT AS THROW 51001, 'confirmation rollback', 1");
        try {
            expectSql(() -> staff.transitionStatus(rollback, "CONFIRMED"), "confirmation history failure rolls back transaction");
        } finally {
            execute("DROP TRIGGER dbo.fail_confirm_history");
        }
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 10,
                "confirmation history failure restores deducted stock");
        check("PENDING_CONFIRMATION".equals(staff.getCurrentStatus(rollback)),
                "confirmation history failure preserves pending state");

        int race = confirmationOrder("COD", 1);
        parallel(() -> tryConfirm(race), () -> {
            try {
                return checkout.cancelOrderByCustomer(2, race);
            } catch (IllegalArgumentException alreadyConfirmed) {
                return false;
            }
        });
        String state = staff.getCurrentStatus(race);
        check(("CANCELLED".equals(state) && scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 10)
                || ("CONFIRMED".equals(state) && scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 9),
                "customer cancellation racing confirmation keeps inventory consistent");
    }

    private void servletGuards() throws Exception {
        controller.CustomerOrderServlet servlet = new controller.CustomerOrderServlet();
        checkServlet(servlet, "doGet", null, "/my-orders", null, 302, "anonymous visitor redirects to login");
        model.User staff = new model.User();
        staff.setRoleName("Staff");
        checkServlet(servlet, "doGet", staff, "/my-orders", null, 403, "staff blocked from customer endpoint");
        model.User customer = new model.User();
        customer.setRoleName("Customer");
        customer.setUserId(1);
        checkServlet(servlet, "doGet", customer, "/my-orders/cancel", null, 405, "GET cannot cancel an order");
        checkServlet(servlet, "doPost", customer, "/my-orders/cancel", null, 403, "missing CSRF token rejected");
        checkServlet(servlet, "doPost", customer, "/my-orders/cancel", "wrong-token", 403, "incorrect CSRF token rejected");
    }

    private void checkServlet(Object servlet, String methodName, model.User user, String path, String token, int expected, String message) throws Exception {
        java.util.Map<String, Object> attributes = new java.util.HashMap<>();
        attributes.put("loggedInUser", user);
        attributes.put("customerOrderToken", "expected-token");
        jakarta.servlet.http.HttpSession session = (jakarta.servlet.http.HttpSession) java.lang.reflect.Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[]{jakarta.servlet.http.HttpSession.class}, (proxy, method, args) -> {
            if ("getAttribute".equals(method.getName())) {
                return attributes.get(args[0]);
            }
            if ("setAttribute".equals(method.getName())) {
                attributes.put((String) args[0], args[1]);
            }
            return null;
        });
        jakarta.servlet.http.HttpServletRequest request = (jakarta.servlet.http.HttpServletRequest) java.lang.reflect.Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[]{jakarta.servlet.http.HttpServletRequest.class}, (proxy, method, args) -> {
            switch (method.getName()) {
                case "getSession":
                    return session;
                case "getServletPath":
                    return path;
                case "getContextPath":
                    return "/OECS";
                case "getParameter":
                    return "csrfToken".equals(args[0]) ? token : "1";
                default:
                    return null;
            }
        });
        int[] status = {200};
        jakarta.servlet.http.HttpServletResponse response = (jakarta.servlet.http.HttpServletResponse) java.lang.reflect.Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[]{jakarta.servlet.http.HttpServletResponse.class}, (proxy, method, args) -> {
            if ("sendError".equals(method.getName()) || "setStatus".equals(method.getName())) {
                status[0] = (Integer) args[0];
            }
            if ("sendRedirect".equals(method.getName())) {
                status[0] = 302;
            }
            return null;
        });
        java.lang.reflect.Method method = servlet.getClass().getDeclaredMethod(methodName,
                jakarta.servlet.http.HttpServletRequest.class, jakarta.servlet.http.HttpServletResponse.class);
        method.setAccessible(true);
        method.invoke(servlet, request, response);
        check(status[0] == expected, message);
    }

    private int cancellationOrder(String status, String method, boolean paid) throws Exception {
        execute("INSERT INTO dbo.[ORDER](user_id,address_id,total_amount,order_status,payment_method,payment_status,payment_expires_at) "
                + "VALUES (1,1,200000,'" + status + "','" + method + "','" + (paid ? "PAID" : "UNPAID") + "',DATEADD(MINUTE,15,SYSUTCDATETIME()))");
        int id = (int) scalar("SELECT MAX(order_id) FROM dbo.[ORDER]");
        execute("INSERT INTO dbo.ORDER_ITEM(order_id,sku_id,quantity,price) VALUES (" + id + ",1,2,100000)");
        if (java.util.Arrays.asList("CONFIRMED", "PACKING", "SHIPPING", "COMPLETED", "DELIVERED").contains(status)) {
            execute("UPDATE dbo.PRODUCT_SKU SET stock_quantity=stock_quantity-2 WHERE sku_id=1");
        }
        if (paid) {
            execute("INSERT INTO dbo.PAYMENT_TRANSACTION(order_id,payment_method,amount,transaction_code,status) VALUES ("
                    + id + ",'VNPAY',200000,'CANCEL-" + id + "','SUCCESS')");
        }
        return id;
    }

    private dao.AdminOrderDAO cancellationStaffDAO() {
        return new dao.AdminOrderDAO() {
            @Override
            public Connection getConnection() {
                try {
                    return connections.open();
                } catch (SQLException e) {
                    throw new IllegalStateException(e);
                }
            }
        };
    }

    private void adminOrderProgressChecks() throws Exception {
        dao.AdminOrderDAO orders = cancellationStaffDAO();
        int id = cancellationOrder("PENDING_CONFIRMATION", "COD", false);
        long stock = scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1");
        model.Order detail = orders.getById(id);
        check(detail != null && detail.getOrderId() == id, "admin detail maps the requested order");
        model.Order listed = orders.getList().stream()
                .filter(order -> order.getOrderId() == id).findFirst().orElseThrow();
        check(java.util.Objects.equals(detail.getRecipientName(), listed.getRecipientName())
                && java.util.Objects.equals(detail.getRecipientPhone(), listed.getRecipientPhone())
                && java.util.Objects.equals(detail.getShippingAddress(), listed.getShippingAddress())
                && detail.getTotalAmount().compareTo(listed.getTotalAmount()) == 0,
                "admin list and detail preserve common order fields");
        check("COD".equals(detail.getPaymentMethod()), "admin detail keeps payment fields");
        check(!orders.transitionStatus(id, "SHIPPING"), "cannot skip order progress stages");
        check(!orders.transitionStatus(id, "CANCELLED"), "progress DAO leaves cancellation to its service");
        check(!orders.transitionStatus(id, "unknown"), "unknown requested status rejected");
        check(orders.transitionStatus(id, "CONFIRMED"), "pending order can be confirmed");
        check(!orders.transitionStatus(id, "CONFIRMED"), "repeated confirmation is rejected");
        check(orders.transitionStatus(id, "PACKING"), "confirmed order can be packed");

        execute("CREATE TRIGGER dbo.fail_admin_progress ON dbo.ORDER_STATUS_HISTORY AFTER INSERT AS THROW 51001, 'rollback order progress', 1");
        try {
            expectSql(() -> orders.transitionStatus(id, "SHIPPING"), "history failure rolls back progress");
        } finally {
            execute("DROP TRIGGER dbo.fail_admin_progress");
        }
        check("PACKING".equals(orders.getCurrentStatus(id)), "failed history preserves the previous status");
        check(scalar("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id=" + id + " AND status='SHIPPING'") == 0,
                "failed progress leaves no history row");
        check(orders.transitionStatus(id, "SHIPPING"), "packed order can be shipped");
        check(orders.transitionStatus(id, "COMPLETED"), "shipped order can be completed");
        check(!orders.transitionStatus(id, "PACKING"), "completed order cannot move backwards");
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id=" + id
                + " AND delivered_at IS NOT NULL AND stock_restored_at IS NULL") == 1,
                "completion records delivery without restoring stock");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == stock - 2,
                "confirmation deducts stock once across all forward stages");
        check(scalar("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id=" + id
                + " AND status IN ('CONFIRMED','PACKING','SHIPPING','COMPLETED')") == 4,
                "each successful progress stage writes exactly one history row");

        int duplicate = cancellationOrder("PACKING", "COD", false);
        parallel(() -> cancellationStaffDAO().transitionStatus(duplicate, "SHIPPING"),
                () -> cancellationStaffDAO().transitionStatus(duplicate, "SHIPPING"));
        check(scalar("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id=" + duplicate + " AND status='SHIPPING'") == 1,
                "concurrent progress writes one committed shipping history");
    }

    private void customerCancellationChecks() throws Exception {

        // =====================================================
        // 1. CUSTOMER CANCEL: COD / VNPAY / MOMO
        // =====================================================
        for (String method : new String[]{"COD", "VNPAY", "MOMO"}) {

            for (String state : new String[]{
                "PENDING_PAYMENT",
                "PENDING_CONFIRMATION",
                "CONFIRMED",
                "PACKING"
            }) {

                boolean paid = !"COD".equals(method)
                        && !"PENDING_PAYMENT".equals(state);

                int id = cancellationOrder(state, method, paid);

                long stock = scalar(
                        "SELECT stock_quantity "
                        + "FROM dbo.PRODUCT_SKU "
                        + "WHERE sku_id=1"
                );

                // Customer khac khong duoc huy don.
                expectInvalid(
                        () -> checkout.cancelOrderByCustomer(2, id),
                        "customer ownership checked for " + state
                );

                // Customer huy don cua chinh minh.
                check(
                        checkout.cancelOrderByCustomer(1, id),
                        "customer cancels " + method + " " + state
                );

                long restored
                        = "CONFIRMED".equals(state)
                        || "PACKING".equals(state)
                        ? 2 : 0;

                check(
                        scalar(
                                "SELECT stock_quantity "
                                + "FROM dbo.PRODUCT_SKU "
                                + "WHERE sku_id=1"
                        ) == stock + restored,
                        "customer restores only deducted stock for "
                        + method + " " + state
                );

                // Khong huy / hoan kho lan thu hai.
                check(
                        !checkout.cancelOrderByCustomer(1, id),
                        "repeat cancellation is unchanged"
                );

                check(
                        scalar(
                                "SELECT stock_quantity "
                                + "FROM dbo.PRODUCT_SKU "
                                + "WHERE sku_id=1"
                        ) == stock + restored,
                        "repeat cancellation does not restore again"
                );

                // Ghi nhan huy don boi Customer.
                check(
                        scalar(
                                "SELECT COUNT(*) "
                                + "FROM dbo.[ORDER] "
                                + "WHERE order_id=" + id
                                + " AND cancellation_source='CUSTOMER' "
                                + "AND cancelled_at IS NOT NULL"
                        ) == 1,
                        "customer policy records cancellation once"
                );

                // Chi tao mot thong bao.
                check(
                        scalar(
                                "SELECT COUNT(*) "
                                + "FROM dbo.NOTIFICATION "
                                + "WHERE order_id=" + id
                        ) == 1,
                        "one cancellation notification"
                );

                // Neu da thu tien, ghi nhat ky doi soat.
                // Khong tao PAYMENT_REFUND.
                check(
                        scalar(
                                "SELECT COUNT(*) "
                                + "FROM dbo.AUDIT_LOG "
                                + "WHERE action='PAYMENT_REVIEW' "
                                + "AND entity_type='ORDER' "
                                + "AND entity_id=" + id
                        ) == (paid ? 1 : 0),
                        "paid cancellation flagged for manual reconciliation"
                );

                if (paid) {

                    // Tien thuc te da thu van phai duoc ghi nhan.
                    check(
                            scalar(
                                    "SELECT COUNT(*) "
                                    + "FROM dbo.[ORDER] "
                                    + "WHERE order_id=" + id
                                    + " AND payment_status='PAID'"
                            ) == 1,
                            "paid cancellation preserves captured-payment status"
                    );
                }
            }
        }

        // =====================================================
        // 2. KHONG DUOC HUY DON DA VAN CHUYEN / HOAN TAT
        // =====================================================
        for (String state : new String[]{
            "SHIPPING",
            "DELIVERED",
            "COMPLETED",
            "UNKNOWN"
        }) {

            int id = cancellationOrder("PACKING", "COD", false);

            check(
                    !OrderCancellationService.canCancel(state),
                    "policy rejects " + state
            );

            // Khong luu UNKNOWN vao DB.
            if ("UNKNOWN".equals(state)) {
                continue;
            }

            execute(
                    "UPDATE dbo.[ORDER] "
                    + "SET order_status='" + state + "' "
                    + "WHERE order_id=" + id
            );

            long stock = scalar(
                    "SELECT stock_quantity "
                    + "FROM dbo.PRODUCT_SKU "
                    + "WHERE sku_id=1"
            );

            expectInvalid(
                    () -> checkout.cancelOrderByCustomer(1, id),
                    "customer cannot cancel " + state
            );

            check(
                    scalar(
                            "SELECT stock_quantity "
                            + "FROM dbo.PRODUCT_SKU "
                            + "WHERE sku_id=1"
                    ) == stock,
                    "rejected cancellation preserves stock"
            );
        }

        // =====================================================
        // 3. DONG GIAO DICH THANH TOAN CHO
        // =====================================================
        int pending
                = cancellationOrder("PENDING_PAYMENT", "MOMO", false);

        execute(
                "INSERT INTO dbo.PAYMENT_TRANSACTION "
                + "(order_id,payment_method,amount,"
                + "transaction_code,status) "
                + "VALUES ("
                + pending
                + ",'MOMO',200000,'CUSTOMER-PENDING-"
                + pending
                + "','PENDING')"
        );

        checkout.cancelOrderByCustomer(1, pending);

        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.PAYMENT_TRANSACTION "
                        + "WHERE order_id=" + pending
                        + " AND status='CANCELLED'"
                ) == 1,
                "pending payment closed on customer cancellation"
        );

        // =====================================================
        // 4. HUY DON DONG THOI: KHONG GHI LOG TRUNG
        // =====================================================
        int duplicate
                = cancellationOrder("PACKING", "VNPAY", true);

        long stock = scalar(
                "SELECT stock_quantity "
                + "FROM dbo.PRODUCT_SKU "
                + "WHERE sku_id=1"
        );

        parallel(
                () -> checkout.cancelOrderByCustomer(1, duplicate),
                () -> checkout.cancelOrderByCustomer(1, duplicate)
        );

        check(
                scalar(
                        "SELECT stock_quantity "
                        + "FROM dbo.PRODUCT_SKU "
                        + "WHERE sku_id=1"
                ) == stock + 2,
                "concurrent customer cancellation restores once"
        );

        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.AUDIT_LOG "
                        + "WHERE action='PAYMENT_REVIEW' "
                        + "AND entity_type='ORDER' "
                        + "AND entity_id=" + duplicate
                ) == 1,
                "concurrent customer cancellation logs once"
        );

        // =====================================================
        // 5. ROLLBACK KHI LOI CAP NHAT DON
        // =====================================================
        int rollback
                = cancellationOrder("PACKING", "VNPAY", true);

        stock = scalar(
                "SELECT stock_quantity "
                + "FROM dbo.PRODUCT_SKU "
                + "WHERE sku_id=1"
        );

        execute(
                "CREATE TRIGGER dbo.fail_customer_policy "
                + "ON dbo.[ORDER] AFTER UPDATE "
                + "AS "
                + "BEGIN "
                + "IF EXISTS ("
                + "SELECT 1 FROM inserted "
                + "WHERE cancellation_source='CUSTOMER'"
                + ") "
                + "THROW 51001, "
                + "'rollback customer cancellation', 1; "
                + "END"
        );

        try {

            expectSql(
                    () -> checkout.cancelOrderByCustomer(1, rollback),
                    "policy failure rolls back cancellation"
            );

        } finally {

            execute("DROP TRIGGER dbo.fail_customer_policy");
        }

        check(
                scalar(
                        "SELECT stock_quantity "
                        + "FROM dbo.PRODUCT_SKU "
                        + "WHERE sku_id=1"
                ) == stock,
                "customer rollback preserves stock"
        );

        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.[ORDER] "
                        + "WHERE order_id=" + rollback
                        + " AND order_status='PACKING' "
                        + "AND payment_status='PAID' "
                        + "AND stock_restored_at IS NULL"
                ) == 1,
                "customer rollback preserves order and payment"
        );

        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.AUDIT_LOG "
                        + "WHERE action='PAYMENT_REVIEW' "
                        + "AND entity_type='ORDER' "
                        + "AND entity_id=" + rollback
                ) == 0,
                "customer rollback removes payment-review log"
        );

        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.NOTIFICATION "
                        + "WHERE order_id=" + rollback
                ) == 0,
                "customer rollback removes notification"
        );

        // =====================================================
        // 6. HUY DON DONG THOI VOI SHIPPING
        // =====================================================
        int race
                = cancellationOrder("PACKING", "COD", false);

        stock = scalar(
                "SELECT stock_quantity "
                + "FROM dbo.PRODUCT_SKU "
                + "WHERE sku_id=1"
        );

        parallel(
                () -> {

                    try {
                        return checkout.cancelOrderByCustomer(1, race);
                    } catch (IllegalArgumentException shipped) {
                        return false;
                    }
                },
                () -> cancellationStaffDAO()
                        .transitionStatus(race, "SHIPPING")
        );

        boolean cancelled
                = "CANCELLED".equals(
                        cancellationStaffDAO().getCurrentStatus(race)
                );

        check(
                scalar(
                        "SELECT stock_quantity "
                        + "FROM dbo.PRODUCT_SKU "
                        + "WHERE sku_id=1"
                ) == stock + (cancelled ? 2 : 0),
                "customer cancellation racing shipment keeps stock consistent"
        );
    }

    private void staffCancellationChecks() throws Exception {

        // =====================================================
        // 1. KIEM TRA CAC BUOC XU LY DON HANG
        // =====================================================
        adminOrderProgressChecks();

        OrderCancellationService cancel
                = new OrderCancellationService(connections);

        // =====================================================
        // 2. STAFF HUY DON COD THEO TUNG TRANG THAI
        // =====================================================
        for (String state : new String[]{
            "PENDING_PAYMENT",
            "PENDING_CONFIRMATION",
            "CONFIRMED",
            "PACKING"
        }) {

            int id = cancellationOrder(state, "COD", false);

            long stock = scalar(
                    "SELECT stock_quantity "
                    + "FROM dbo.PRODUCT_SKU "
                    + "WHERE sku_id=1"
            );

            check(
                    "CANCELLED".equals(cancel.staffCancel(2, id)),
                    "Staff cancels " + state
                    + " without reason or request table"
            );

            long restored
                    = "CONFIRMED".equals(state)
                    || "PACKING".equals(state)
                    ? 2 : 0;

            check(
                    scalar(
                            "SELECT stock_quantity "
                            + "FROM dbo.PRODUCT_SKU "
                            + "WHERE sku_id=1"
                    ) == stock + restored,
                    "restore only confirmed SKU for " + state
            );

            check(
                    "UNCHANGED".equals(cancel.staffCancel(2, id)),
                    "repeated " + state
                    + " cancellation is idempotent"
            );

            check(
                    scalar(
                            "SELECT COUNT(*) "
                            + "FROM dbo.ORDER_STATUS_HISTORY "
                            + "WHERE order_id=" + id
                            + " AND status='CANCELLED'"
                    ) == 1,
                    "one committed cancellation history for " + state
            );

            check(
                    scalar(
                            "SELECT COUNT(*) "
                            + "FROM dbo.NOTIFICATION "
                            + "WHERE order_id=" + id
                    ) == 1,
                    "shared DAO sends cancellation once for " + state
            );
        }

        // =====================================================
        // 3. KHONG CHO HUY DON DA SHIPPING / COMPLETED
        // =====================================================
        for (String state : new String[]{
            "SHIPPING",
            "COMPLETED",
            "DELIVERED"
        }) {

            int id = cancellationOrder(state, "COD", false);

            long stock = scalar(
                    "SELECT stock_quantity "
                    + "FROM dbo.PRODUCT_SKU "
                    + "WHERE sku_id=1"
            );

            expectInvalid(
                    () -> cancel.staffCancel(2, id),
                    "cannot cancel " + state
            );

            check(
                    scalar(
                            "SELECT stock_quantity "
                            + "FROM dbo.PRODUCT_SKU "
                            + "WHERE sku_id=1"
                    ) == stock,
                    "blocked " + state + " preserves stock"
            );
        }

        // =====================================================
        // 4. STAFF HUY DON VNPAY DA THANH TOAN
        // =====================================================
        int paid
                = cancellationOrder("CONFIRMED", "VNPAY", true);

        check(
                "CANCELLED".equals(cancel.staffCancel(2, paid)),
                "paid order cancellation accepted"
        );

        // Khong tao Refund.
        // Phai ghi nhat ky de Staff doi soat tien.
        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.AUDIT_LOG "
                        + "WHERE action='PAYMENT_REVIEW' "
                        + "AND entity_type='ORDER' "
                        + "AND entity_id=" + paid
                ) == 1,
                "paid staff cancellation requires manual reconciliation"
        );

        // Tien da thu van duoc ghi nhan la PAID.
        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.[ORDER] "
                        + "WHERE order_id=" + paid
                        + " AND order_status='CANCELLED' "
                        + "AND payment_status='PAID'"
                ) == 1,
                "paid cancellation preserves captured-payment status"
        );

        // =====================================================
        // 5. STAFF HUY DON DONG THOI
        // =====================================================
        int duplicate
                = cancellationOrder("PACKING", "COD", false);

        long stock = scalar(
                "SELECT stock_quantity "
                + "FROM dbo.PRODUCT_SKU "
                + "WHERE sku_id=1"
        );

        parallel(
                () -> cancel.staffCancel(2, duplicate),
                () -> cancel.staffCancel(2, duplicate)
        );

        check(
                scalar(
                        "SELECT stock_quantity "
                        + "FROM dbo.PRODUCT_SKU "
                        + "WHERE sku_id=1"
                ) == stock + 2,
                "concurrent staff cancellation restores once"
        );

        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.ORDER_STATUS_HISTORY "
                        + "WHERE order_id=" + duplicate
                        + " AND status='CANCELLED'"
                ) == 1,
                "concurrent staff cancellation writes one history"
        );

        // =====================================================
        // 6. ROLLBACK KHI GHI LICH SU THAT BAI
        // =====================================================
        int rollback
                = cancellationOrder("PACKING", "VNPAY", true);

        long before = scalar(
                "SELECT stock_quantity "
                + "FROM dbo.PRODUCT_SKU "
                + "WHERE sku_id=1"
        );

        execute(
                "CREATE TRIGGER dbo.fail_cancel_notice "
                + "ON dbo.ORDER_STATUS_HISTORY "
                + "AFTER INSERT "
                + "AS THROW 51001, "
                + "'rollback staff cancellation', 1"
        );

        try {

            expectSql(
                    () -> cancel.staffCancel(2, rollback),
                    "failed order history rolls back paid cancellation"
            );

        } finally {

            execute("DROP TRIGGER dbo.fail_cancel_notice");
        }

        check(
                scalar(
                        "SELECT stock_quantity "
                        + "FROM dbo.PRODUCT_SKU "
                        + "WHERE sku_id=1"
                ) == before,
                "rollback preserves stock"
        );

        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.[ORDER] "
                        + "WHERE order_id=" + rollback
                        + " AND order_status='PACKING' "
                        + "AND payment_status='PAID' "
                        + "AND stock_restored_at IS NULL"
                ) == 1,
                "rollback preserves order"
        );

        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.AUDIT_LOG "
                        + "WHERE action='PAYMENT_REVIEW' "
                        + "AND entity_type='ORDER' "
                        + "AND entity_id=" + rollback
                ) == 0,
                "rollback removes payment-review log"
        );

        // =====================================================
        // 7. ROLLBACK KHI TAO NOTIFICATION THAT BAI
        // =====================================================
        execute(
                "CREATE TRIGGER dbo.fail_notification "
                + "ON dbo.NOTIFICATION "
                + "AFTER INSERT "
                + "AS THROW 51001, "
                + "'notification rollback', 1"
        );

        try {

            expectSql(
                    () -> cancel.staffCancel(2, rollback),
                    "notification failure rolls back paid cancellation"
            );

        } finally {

            execute("DROP TRIGGER dbo.fail_notification");
        }

        check(
                scalar(
                        "SELECT stock_quantity "
                        + "FROM dbo.PRODUCT_SKU "
                        + "WHERE sku_id=1"
                ) == before,
                "notification failure preserves stock"
        );

        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.AUDIT_LOG "
                        + "WHERE action='PAYMENT_REVIEW' "
                        + "AND entity_type='ORDER' "
                        + "AND entity_id=" + rollback
                ) == 0,
                "notification failure rolls back payment-review log"
        );

        // =====================================================
        // 8. STAFF CANCEL DONG THOI VOI SHIPPING
        // =====================================================
        int race
                = cancellationOrder("PACKING", "COD", false);

        parallel(
                () -> {

                    try {
                        return cancel.staffCancel(2, race);
                    } catch (IllegalArgumentException ex) {
                        return "SHIPPED";
                    }
                },
                () -> cancellationStaffDAO()
                        .transitionStatus(race, "SHIPPING")
        );

        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM dbo.[ORDER] "
                        + "WHERE order_id=" + race
                        + " AND ("
                        + " (order_status='CANCELLED' "
                        + "AND stock_restored_at IS NOT NULL) "
                        + "OR "
                        + " (order_status='SHIPPING' "
                        + "AND stock_restored_at IS NULL)"
                        + " )"
                ) == 1,
                "shipment versus cancellation preserves consistent state"
        );

        // =====================================================
        // 9. KHONG CO BANG YEU CAU HUY DON RIENG
        // =====================================================
        check(
                scalar(
                        "SELECT COUNT(*) "
                        + "FROM sys.tables "
                        + "WHERE name='ORDER_CANCELLATION_REQUEST'"
                ) == 0,
                "all Staff checks pass without new request table"
        );

        // =====================================================
        // 10. KIEM TRA NOTIFICATION
        // =====================================================
        notificationIntegrationChecks();
    }

    private void notificationIntegrationChecks() throws Exception {
        dao.NotificationDAO notifications = new dao.NotificationDAO() {
            { // Dispose the inherited default connection; all test operations use the isolated database.
                Connection bootstrap = super.getConnection();
                if (bootstrap != null) {
                    bootstrap.close();
                }
            }

            @Override
            public Connection getConnection() {
                try {
                    return connections.open();
                } catch (SQLException e) {
                    throw new IllegalStateException(e);
                }
            }
        };
        int id = cancellationOrder("PACKING", "COD", false);
        String[] states = {"CONFIRMED", "PACKING", "SHIPPING", "COMPLETED", "CANCELLED"};
        String[] titles = {"Đơn hàng đã được xác nhận", "Đơn hàng đang được đóng gói", "Đơn hàng đang được vận chuyển", "Đơn hàng đã hoàn tất", "Đơn hàng đã bị hủy"};
        String[] messages = {
            "Đơn hàng #" + id + " của bạn đã được xác nhận và đang được chuẩn bị.",
            "Đơn hàng #" + id + " đã được xác nhận và đang trong quá trình đóng gói.",
            "Đơn hàng #" + id + " đã được bàn giao cho đơn vị vận chuyển. Vui lòng chú ý điện thoại để nhận hàng.",
            "Đơn hàng #" + id + " đã hoàn tất. Hy vọng bạn hài lòng với sản phẩm!",
            "Đơn hàng #" + id + " của bạn đã bị hủy. Nếu cần hỗ trợ, vui lòng liên hệ nhân viên OECS."};
        for (int i = 0; i < states.length; i++) {
            check(notifications.createOrderStatusNotification(id, states[i]), "create shared SQL template " + states[i]);
            final String expectedTitle = titles[i], expectedMessage = messages[i];
            model.Notification n = notifications.findLatest(1).get(0);
            check(expectedTitle.equals(n.getTitle()) && expectedMessage.equals(n.getMessage()), "exact SQL wording for " + states[i]);
            check(n.getOrderId() == id && n.getUserId() == 1, "notification keeps order link and owner for " + states[i]);
        }
        check(notifications.findLatest(2).stream().noneMatch(n -> n.getOrderId() != null && n.getOrderId() == id), "other customer does not receive order notification");
        model.Notification newest = notifications.findLatest(1).get(0);
        check(!notifications.markAsRead(newest.getNotificationId(), 2), "other customer cannot mark notification read");
        check(notifications.markAsRead(newest.getNotificationId(), 1), "owner can mark own notification read");
        execute("INSERT INTO dbo.NOTIFICATION(user_id,order_id,title,message) VALUES (1," + id + ",'Cap nhat don hang #" + id + "','Don hang #" + id + " da duoc cap nhat trang thai: SHIPPING.')");
        model.Notification old = notifications.findLatest(1).get(0);
        check(("Cap nhat don hang #" + id).equals(old.getTitle()), "reading preserves original legacy notification text");
        check(scalar("SELECT COUNT(*) FROM dbo.NOTIFICATION WHERE notification_id=" + old.getNotificationId() + " AND title LIKE 'Cap nhat%'") == 1, "reading does not rewrite existing database rows");
        execute("INSERT INTO dbo.NOTIFICATION(user_id,order_id,title,message) VALUES (1," + id + ",N'Xử lý hủy đơn hàng',N'Đơn đã hủy: Nhân viên hủy đơn hàng')");
        check("Xử lý hủy đơn hàng".equals(notifications.findLatest(1).get(0).getTitle()), "old cancellation text remains unchanged");
        execute("INSERT INTO dbo.NOTIFICATION(user_id,order_id,title,message) VALUES (1," + id + ",N'Cập nhật yêu cầu đổi/trả hàng',N'Đã duyệt trả hàng')");
        check("Đã duyệt trả hàng".equals(notifications.findLatest(1).get(0).getMessage()), "unrelated return notifications are preserved");
        long before = scalar("SELECT COUNT(*) FROM dbo.NOTIFICATION");
        try (Connection c = connections.open()) {
            c.setAutoCommit(false);
            check(dao.NotificationDAO.createOrderStatusNotification(c, id, "CANCELLED"), "shared connection overload inserts notification");
            check(!c.isClosed() && !c.getAutoCommit(), "DAO does not close connection or change caller transaction");
            c.rollback();
        }
        check(scalar("SELECT COUNT(*) FROM dbo.NOTIFICATION") == before, "caller rollback removes notification");
        model.Notification dated = new model.Notification();
        check("".equals(dated.getFormattedCreatedAt()), "null notification date displays blank");
        dated.setCreatedAt(java.sql.Timestamp.valueOf("2026-11-13 17:05:52.9933333"));
        check("13/11/2026 17:05".equals(dated.getFormattedCreatedAt()), "notification date has Vietnamese format without fractional seconds");
        check(notifications.countUnread(1) == scalar("SELECT COUNT(*) FROM dbo.NOTIFICATION WHERE user_id=1 AND is_read=0"), "unread count includes all notifications rather than latest twenty");
    }

    private Object[] parallel(java.util.concurrent.Callable<?> first, java.util.concurrent.Callable<?> second) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            Future<?> a = pool.submit(() -> {
                start.await();
                return first.call();
            });
            Future<?> b = pool.submit(() -> {
                start.await();
                return second.call();
            });
            start.countDown();
            return new Object[]{a.get(30, TimeUnit.SECONDS), b.get(30, TimeUnit.SECONDS)};
        } finally {
            pool.shutdownNow();
            pool.awaitTermination(5, TimeUnit.SECONDS);
        }
    }

    private void execute(String sql) throws SQLException {
        try (Connection conn = connections.open(); Statement statement = conn.createStatement()) {
            statement.execute(sql);
        }
    }

    private long scalar(String sql) throws SQLException {
        try (Connection conn = connections.open(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                throw new SQLException("Expected one result");
            }
            return rs.getLong(1);
        }
    }

    private void check(boolean value, String message) {
        if (!value) {
            throw new AssertionError(message);
        }
        passed++;
        System.out.println("PASS " + message);
    }

    private void expectInvalid(java.util.concurrent.Callable<?> action, String message) throws Exception {
        try {
            action.call();
        } catch (IllegalArgumentException expected) {
            check(true, message);
            return;
        }
        throw new AssertionError(message);
    }

    private void expectSql(java.util.concurrent.Callable<?> action, String message) throws Exception {
        try {
            action.call();
        } catch (SQLException expected) {
            check(true, message);
            return;
        }
        throw new AssertionError(message);
    }
}
