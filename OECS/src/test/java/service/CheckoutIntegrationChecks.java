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

/** Run explicitly with scripts/check-checkout.ps1; creates and removes its own isolated SQL Server database. */
public final class CheckoutIntegrationChecks {
    private final String database = "OECS_checkout_test_" + UUID.randomUUID().toString().replace("-", "").substring(0, 12);
    private final CheckoutConnectionFactory connections = () -> {
        Connection connection = new DBContext().getConnection();
        if (connection == null) throw new SQLException("SQL Server is unavailable");
        connection.setCatalog(database);
        return connection;
    };
    private final OrderService checkout = new OrderService(connections);
    private int passed;

    public static void main(String[] args) throws Exception {
        if (args.length != 1) throw new IllegalArgumentException("Pass the path to DB_OECS.sql");
        new CheckoutIntegrationChecks().run(Path.of(args[0]));
    }

    private void run(Path schemaFile) throws Exception {
        boolean created = false;
        try (Connection admin = new DBContext().getConnection()) {
            if (admin == null) throw new SQLException("SQL Server is unavailable");
            admin.setCatalog("master");
            try {
                try (Statement statement = admin.createStatement()) {
                    statement.executeUpdate("CREATE DATABASE [" + database + "]");
                    created = true;
                }
                createSchema(schemaFile);
                seed();
                rememberAddress();
                int orderId = duplicateCheckout();
                ownershipAndSnapshots(orderId);
                cancelTwice(orderId);
                invalidAndRollback();
                purchaseHistoryChecks();
                servletGuards();
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

    private void createSchema(Path file) throws Exception {
        byte[] bytes = Files.readAllBytes(file);
        String schema = new String(bytes, bytes.length > 1 && bytes[0] == (byte) 0xff
                && bytes[1] == (byte) 0xfe ? StandardCharsets.UTF_16LE : StandardCharsets.UTF_8);
        String[] tables = {"USER", "ADDRESSBOOK", "CATEGORY", "BRAND", "PRODUCT", "PRODUCT_SKU",
            "CART", "CART_ITEMS", "SHIPPING_PARTNER", "VOUCHER", "ORDER", "ORDER_ITEM", "ORDER_STATUS_HISTORY", "VOUCHER_USAGES"};
        for (String table : tables) {
            Matcher match = Pattern.compile("^CREATE TABLE \\[?" + table + "\\]? \\([\\s\\S]*?^\\);", Pattern.MULTILINE).matcher(schema);
            if (!match.find()) throw new IllegalStateException("Cannot find schema for " + table);
            execute(match.group());
        }
        execute("CREATE UNIQUE INDEX UX_Order_CheckoutToken ON dbo.[ORDER](checkout_token) WHERE checkout_token IS NOT NULL");
    }

    private void seed() throws SQLException {
        execute("INSERT INTO dbo.[USER](username,email,password_hash) VALUES ('checkout-test','test@example.invalid','test'),('other-test','other@example.invalid','test')");
        execute("INSERT INTO dbo.ADDRESSBOOK(user_id,recipient_name,phone_number,address_line) VALUES (1,N'Người nhận','0901234567',N'Địa chỉ đã đặt'),(1,N'Địa chỉ 2','0901234568',N'Địa chỉ thứ hai'),(2,N'Khách khác','0901234569',N'Địa chỉ khác')");
        execute("INSERT INTO dbo.CATEGORY(category_name) VALUES ('test')");
        execute("INSERT INTO dbo.BRAND(brand_name) VALUES ('test')");
        execute("INSERT INTO dbo.PRODUCT(category_id,brand_id,product_name) VALUES (1,1,N'Sản phẩm kiểm thử')");
        execute("INSERT INTO dbo.PRODUCT_SKU(product_id,sku_code,price,stock_quantity) VALUES (1,'TEST-SKU',100000,20)");
        execute("INSERT INTO dbo.CART(user_id) VALUES (1),(2)");
        execute("INSERT INTO dbo.VOUCHER(code,valid_from,valid_to,discount_type,discount_value,usage_limit,per_user_limit) VALUES ('TEST10',DATEADD(day,-1,GETDATE()),DATEADD(day,1,GETDATE()),'AMOUNT',10000,10,10)");
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
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 18, "stock deducted once");
        check(scalar("SELECT COUNT(*) FROM dbo.CART_ITEMS WHERE cart_id=1") == 0, "cart cleared after success");
        check(scalar("SELECT COUNT(*) FROM dbo.VOUCHER_USAGES") == 1, "voucher consumed once");
        check(scalar("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY") == 1, "one initial history entry");
        check(scalar("SELECT total_amount FROM dbo.[ORDER] WHERE order_id=" + orderId) == 190000, "server total includes voucher");
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
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 18, "unauthorized cancellation leaves stock unchanged");
    }

    private void cancelTwice(int id) throws Exception {
        Object[] changed = parallel(() -> checkout.cancelOrderByCustomer(1, id), () -> checkout.cancelOrderByCustomer(1, id));
        check(!changed[0].equals(changed[1]), "only one simultaneous cancellation changes state");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 20, "stock restored exactly once");
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id=" + id + " AND order_status='CANCELLED' AND stock_restored_at IS NOT NULL") == 1, "cancel status and restoration marker committed");
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
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 19, "cancellation rollback undoes stock restoration");
        check(scalar("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id=" + id + " AND order_status='PENDING_CONFIRMATION' AND stock_restored_at IS NULL") == 1, "cancellation rollback preserves status and marker");
        execute("ALTER TABLE dbo.ORDER_STATUS_HISTORY DROP CONSTRAINT CK_Test_FailCancel");
        execute("UPDATE dbo.[ORDER] SET order_status='CONFIRMED' WHERE order_id=" + id);
        expectInvalid(() -> checkout.cancelOrderByCustomer(1, id), "cannot cancel confirmed order");
        execute("UPDATE dbo.[ORDER] SET order_status='PENDING_CONFIRMATION',payment_method='VNPAY',payment_status='PAID' WHERE order_id=" + id);
        expectInvalid(() -> checkout.cancelOrderByCustomer(1, id), "online payment excluded from customer cancellation");
        check(scalar("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1") == 19, "rejected cancellations preserve stock");
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
        for (model.Order order : first) ids.add(order.getOrderId());
        for (model.Order order : second) ids.add(order.getOrderId());
        for (model.Order order : last) ids.add(order.getOrderId());
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

    private void servletGuards() throws Exception {
        controller.CustomerOrderServlet servlet = new controller.CustomerOrderServlet();
        checkServlet(servlet, "doGet", null, "/my-orders", null, 302, "anonymous visitor redirects to login");
        model.User staff = new model.User(); staff.setRoleName("Staff");
        checkServlet(servlet, "doGet", staff, "/my-orders", null, 403, "staff blocked from customer endpoint");
        model.User customer = new model.User(); customer.setRoleName("Customer"); customer.setUserId(1);
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
                    if ("getAttribute".equals(method.getName())) return attributes.get(args[0]);
                    if ("setAttribute".equals(method.getName())) attributes.put((String) args[0], args[1]);
                    return null;
                });
        jakarta.servlet.http.HttpServletRequest request = (jakarta.servlet.http.HttpServletRequest) java.lang.reflect.Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[]{jakarta.servlet.http.HttpServletRequest.class}, (proxy, method, args) -> {
                    switch (method.getName()) {
                        case "getSession": return session;
                        case "getServletPath": return path;
                        case "getContextPath": return "/OECS";
                        case "getParameter": return "csrfToken".equals(args[0]) ? token : "1";
                        default: return null;
                    }
                });
        int[] status = {200};
        jakarta.servlet.http.HttpServletResponse response = (jakarta.servlet.http.HttpServletResponse) java.lang.reflect.Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[]{jakarta.servlet.http.HttpServletResponse.class}, (proxy, method, args) -> {
                    if ("sendError".equals(method.getName()) || "setStatus".equals(method.getName())) status[0] = (Integer) args[0];
                    if ("sendRedirect".equals(method.getName())) status[0] = 302;
                    return null;
                });
        java.lang.reflect.Method method = servlet.getClass().getDeclaredMethod(methodName,
                jakarta.servlet.http.HttpServletRequest.class, jakarta.servlet.http.HttpServletResponse.class);
        method.setAccessible(true);
        method.invoke(servlet, request, response);
        check(status[0] == expected, message);
    }

    private Object[] parallel(java.util.concurrent.Callable<?> first, java.util.concurrent.Callable<?> second) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            Future<?> a = pool.submit(() -> { start.await(); return first.call(); });
            Future<?> b = pool.submit(() -> { start.await(); return second.call(); });
            start.countDown();
            return new Object[]{a.get(30, TimeUnit.SECONDS), b.get(30, TimeUnit.SECONDS)};
        } finally { pool.shutdownNow(); pool.awaitTermination(5, TimeUnit.SECONDS); }
    }

    private void execute(String sql) throws SQLException {
        try (Connection conn = connections.open(); Statement statement = conn.createStatement()) { statement.execute(sql); }
    }

    private long scalar(String sql) throws SQLException {
        try (Connection conn = connections.open(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) throw new SQLException("Expected one result");
            return rs.getLong(1);
        }
    }

    private void check(boolean value, String message) {
        if (!value) throw new AssertionError(message);
        passed++;
        System.out.println("PASS " + message);
    }

    private void expectInvalid(java.util.concurrent.Callable<?> action, String message) throws Exception {
        try { action.call(); } catch (IllegalArgumentException expected) { check(true, message); return; }
        throw new AssertionError(message);
    }

    private void expectSql(java.util.concurrent.Callable<?> action, String message) throws Exception {
        try { action.call(); } catch (SQLException expected) { check(true, message); return; }
        throw new AssertionError(message);
    }
}
