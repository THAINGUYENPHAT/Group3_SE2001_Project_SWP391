package service;

import dao.AdminOrderDAO;
import dao.OrderDAO;
import db.CheckoutConnectionFactory;
import db.DBContext;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Integration checks for checkout and order workflow with the finalized OECS schema.
 * Run explicitly from src/test/java. Never run the original database reset script.
 */
public final class CheckoutIntegrationChecks {
    private static final int CUSTOMER = 1;
    private static final int OTHER = 2;
    private static final int STAFF = 3;
    private static final String REASON = "Khong con nhu cau";
    private final String database = "OECS_checkout_test_"
            + UUID.randomUUID().toString().replace("-", "").substring(0, 12);
    private final CheckoutConnectionFactory connections = this::openTestConnection;
    private final OrderService checkout = new OrderService(connections);
    private final OrderWorkflowService workflow = new OrderWorkflowService(connections);
    private int passed;

    public static void main(String[] args) throws Exception {
        if (args.length < 1 || args.length > 2
                || (args.length == 2 && !"--staff-cancel-only".equals(args[1]))) {
            throw new IllegalArgumentException("Usage: CheckoutIntegrationChecks <final DB SQL> [--staff-cancel-only]");
        }
        new CheckoutIntegrationChecks().run(Path.of(args[0]), args.length == 2);
    }

    private Connection openTestConnection() throws SQLException {
        Connection c = new DBContext().getConnection();
        if (c == null) throw new SQLException("SQL Server is unavailable");
        try {
            c.setCatalog(database);
            if (!database.equalsIgnoreCase(c.getCatalog())) {
                throw new SQLException("Not connected to isolated test database");
            }
            return c;
        } catch (SQLException e) {
            c.close();
            throw e;
        }
    }

    private void run(Path file, boolean staffOnly) throws Exception {
        // Read only the DDL batch from the finalized schema, before any database is created.
        String ddl = readSchema(file);
        boolean created = false;
        try (Connection admin = new DBContext().getConnection()) {
            if (admin == null) throw new SQLException("SQL Server is unavailable");
            admin.setCatalog("master");
            try {
                try (Statement s = admin.createStatement()) {
                    s.executeUpdate("CREATE DATABASE [" + database + "]");
                    created = true;
                }
                execute(ddl);
                seed();
                if (!staffOnly) {
                    checkoutChecks(); reset();
                    cancellationPolicyChecks(); reset();
                }
                directCancellationChecks(); reset();
                requestAndReviewChecks(); reset();
                staffCancellationChecks(); reset();
                progressChecks(); reset();
                paidOnlineChecks(); reset();
                rollbackChecks(); reset();
                concurrencyChecks();
                System.out.println("PASS: " + passed + " checkout/order integration assertions");
            } finally {
                // Only drop the exact database created by this run.
                if (created && database.matches("OECS_checkout_test_[a-f0-9]{12}")) {
                    try (Statement s = admin.createStatement()) {
                        s.executeUpdate("ALTER DATABASE [" + database + "] SET SINGLE_USER WITH ROLLBACK IMMEDIATE");
                        s.executeUpdate("DROP DATABASE [" + database + "]");
                    }
                    System.out.println("Removed isolated test database: " + database);
                }
            }
        }
    }

    private String readSchema(Path file) throws Exception {
        byte[] bytes = Files.readAllBytes(file);
        String sql = new String(bytes, bytes.length >= 2 && bytes[0] == (byte) 0xff
                && bytes[1] == (byte) 0xfe ? StandardCharsets.UTF_16LE : StandardCharsets.UTF_8);
        // OECS_DB (8).sql: all tables/indexes are in the first DDL batch.
        Matcher m = Pattern.compile("(?ims)^CREATE TABLE ROLES\\s*\\(.*?(?=^GO\\s*$)").matcher(sql);
        if (!m.find()) throw new IllegalArgumentException("Cannot find finalized OECS DDL batch");
        String ddl = m.group();
        for (String required : new String[]{"reserved_quantity", "cancel_request_status",
            "cancel_reviewed_by", "INVENTORY_MOVEMENT", "UX_Order_CheckoutToken"}) {
            if (!ddl.contains(required)) throw new IllegalArgumentException("Wrong schema: missing " + required);
        }
        if (Pattern.compile("(?im)^\\s*(USE\\b|DROP\\s+DATABASE\\b|ALTER\\s+DATABASE\\b|CREATE\\s+DATABASE\\b|INSERT\\b)").matcher(ddl).find()) {
            throw new IllegalArgumentException("Unsafe schema batch; use the finalized OECS schema");
        }
        return "SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON; "
                + "SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET CONCAT_NULL_YIELDS_NULL ON; "
                + "SET ARITHABORT ON; SET NUMERIC_ROUNDABORT OFF;\n" + ddl;
    }

    private void seed() throws SQLException {
        execute("INSERT INTO dbo.ROLES(role_name) VALUES ('ADMIN'),('Staff'),('CUSTOMER');"
                + "INSERT INTO dbo.[USER](username,email,password_hash,role_id) "
                + "VALUES ('customer','customer@example.invalid','test',3),"
                + "('other','other@example.invalid','test',3),('staff','staff@example.invalid','test',2);"
                + "INSERT INTO dbo.ADDRESSBOOK(user_id,recipient_name,phone_number,address_line) "
                + "VALUES (1,N'Customer','0901234567',N'Test address'),(2,N'Other','0901234568',N'Other address');"
                + "INSERT INTO dbo.CATEGORY(category_name) VALUES ('test');"
                + "INSERT INTO dbo.BRAND(brand_name) VALUES ('test');"
                + "INSERT INTO dbo.PRODUCT(category_id,brand_id,product_name) VALUES (1,1,N'Test product');"
                + "INSERT INTO dbo.PRODUCT_SKU(product_id,sku_code,price,stock_quantity,reserved_quantity) "
                + "VALUES (1,'TEST-SKU',100000,20,0);"
                + "INSERT INTO dbo.CART(user_id) VALUES (1),(2);");
    }

    private void reset() throws SQLException {
        execute("DELETE FROM dbo.NOTIFICATION; DELETE FROM dbo.AUDIT_LOG; "
                + "DELETE FROM dbo.ORDER_STATUS_HISTORY; DELETE FROM dbo.VOUCHER_USAGES; "
                + "DELETE FROM dbo.PAYMENT_TRANSACTION; DELETE FROM dbo.ORDER_ITEM; DELETE FROM dbo.[ORDER]; "
                + "DELETE FROM dbo.ORDER_CUSTOMER_POLICY; DELETE FROM dbo.CART_ITEMS; "
                + "DELETE FROM dbo.INVENTORY_MOVEMENT; "
                + "UPDATE dbo.PRODUCT_SKU SET stock_quantity=20,reserved_quantity=0 WHERE sku_id=1;");
    }

    private int order(int user, int quantity) throws Exception {
        execute("INSERT INTO dbo.CART_ITEMS(cart_id,sku_id,quantity) VALUES (" + user + ",1," + quantity + ")");
        return checkout.placeCodOrder(user, user, UUID.randomUUID().toString(), null);
    }

    private String customerCancel(int id) throws SQLException {
        return workflow.customerCancel(CUSTOMER, id, REASON);
    }

    private String confirm(int id) throws SQLException {
        return workflow.advanceOrder(STAFF, id, "confirm", "PENDING_CONFIRMATION");
    }

    private String pack(int id) throws SQLException {
        return workflow.advanceOrder(STAFF, id, "nextStep", "CONFIRMED");
    }

    private String ship(int id) throws SQLException {
        return workflow.advanceOrder(STAFF, id, "nextStep", "PACKING");
    }

    private String version(int id) throws SQLException {
        return value("SELECT CONVERT(VARCHAR(33),cancel_requested_at,126) FROM dbo.[ORDER] WHERE order_id=" + id);
    }

    private void checkoutChecks() throws Exception {
        System.out.println("\n=== CHECKOUT / RESERVATION ===");
        execute("INSERT INTO dbo.CART_ITEMS(cart_id,sku_id,quantity) VALUES (1,1,2)");
        String token = UUID.randomUUID().toString();
        Object[] ids = parallel(() -> checkout.placeCodOrder(1,1,token,null),
                () -> checkout.placeCodOrder(1,1,token,null));
        check(ids[0].equals(ids[1]), "duplicate checkout returns same order");
        int id = (Integer) ids[0];
        check(count("SELECT COUNT(*) FROM dbo.[ORDER]") == 1, "one order inserted");
        inventory(20, 2, "checkout reserves two without deducting stock");
        check(count("SELECT COUNT(*) FROM dbo.CART_ITEMS WHERE cart_id=1") == 0, "cart cleared");
        check(count("SELECT total_amount FROM dbo.[ORDER] WHERE order_id=" + id) == 230000, "total includes shipping");
        check(new OrderDAO(connections).findByIdAndUser(id, OTHER) == null, "detail scoped to customer");
        expectInvalid(() -> workflow.customerCancel(OTHER,id,REASON), "foreign cancellation rejected");
        check("CANCELLED".equals(customerCancel(id)), "pending cancellation succeeds");
        inventory(20, 0, "cancel pending releases reservation only");
        execute("UPDATE dbo.PRODUCT_SKU SET stock_quantity=1 WHERE sku_id=1");
        int last = order(CUSTOMER, 1);
        inventory(1, 1, "last available item is reserved");
        expectInvalid(() -> order(OTHER,1), "second checkout cannot oversell last unit");
        inventory(1, 1, "failed checkout leaves reservation unchanged");
        check("CONFIRMED".equals(confirm(last)), "reserved item can be confirmed");
        inventory(0, 0, "confirmation consumes reservation and stock");
    }

    private void directCancellationChecks() throws Exception {
        System.out.println("\n=== F45 DIRECT CANCELLATION ===");
        int id = order(CUSTOMER, 2);
        expectInvalid(() -> workflow.customerCancel(OTHER,id,null), "ownership verified even without reason");
        check("CANCELLED".equals(workflow.customerCancel(CUSTOMER,id,null)), "unconfirmed COD cancels without reason");
        inventory(20, 0, "unconfirmed order does not restore stock");
        check("UNCHANGED".equals(workflow.customerCancel(CUSTOMER,id,null)), "repeat cancellation unchanged");
        check(count("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id="+id
                + " AND cancellation_source='CUSTOMER' AND cancelled_at IS NOT NULL AND stock_restored_at IS NULL") == 1, "customer cancellation metadata");
        checkCancellationHistory(id, "CUSTOMER", CUSTOMER);
        check(count("SELECT COUNT(*) FROM dbo.NOTIFICATION WHERE order_id="+id) == 1, "one cancellation notification");
        check("Khách hàng tự hủy đơn trước khi xác nhận.".equals(value(
                "SELECT reason FROM dbo.ORDER_STATUS_HISTORY WHERE order_id="+id+" AND status='CANCELLED'")),
                "system generates cancellation history note");
        for (String blank : new String[]{"", "   "}) {
            int blankId = order(CUSTOMER, 1);
            check("CANCELLED".equals(workflow.customerCancel(CUSTOMER,blankId,blank)),
                    "unconfirmed COD accepts blank reason");
            inventory(20,0,"blank reason cancellation releases reservation only");
            checkCancellationHistory(blankId,"CUSTOMER",CUSTOMER);
        }
    }

    private void requestAndReviewChecks() throws Exception {
        System.out.println("\n=== F45/F48 REQUEST / REVIEW / HISTORY ===");
        for (String state : new String[]{"CONFIRMED", "PACKING"}) {
            int id = order(CUSTOMER, 2);
            confirm(id);
            if ("PACKING".equals(state)) pack(id);
            long before = stock();
            for (String missing : new String[]{null, "", "   "}) {
                expectInvalid(() -> workflow.customerCancel(CUSTOMER,id,missing),
                        "reason required at " + state);
            }
            check(state.equals(status(id)) && requestStatus(id)==null,
                    "missing reason leaves status and request unchanged");
            inventory(before,0,"missing reason does not restore stock");
            check("REQUESTED".equals(customerCancel(id)), "customer requests cancellation at " + state);
            check(state.equals(status(id)), "request does not change order status");
            inventory(before, 0, "request does not restore stock");
            check("PENDING".equals(requestStatus(id)), "request saved as PENDING");
            check(count("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id="+id+" AND cancellation_source IS NULL AND cancelled_at IS NULL") == 1, "pending request is not a cancellation event");
            String v = version(id);
            check("REQUESTED".equals(customerCancel(id)), "duplicate request is unchanged");
            check(v.equals(version(id)), "duplicate request preserves version");
            check(checkout.findHistory(id,CUSTOMER).stream().anyMatch(h -> "Đã gửi yêu cầu hủy".equals(h.get("label"))), "customer history displays request label");
            check(count("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id="+id+" AND old_status=status AND actor_type='CUSTOMER'") == 1, "one request history entry");
            expectInvalid(() -> workflow.advanceOrder(STAFF,id,"nextStep",state), "pending request blocks order progress");
            expectInvalid(() -> workflow.staffCancel(STAFF,id,REASON), "staff must review pending request");
            expectInvalid(() -> workflow.review(STAFF,id,true,REASON,"stale-version"), "stale review rejected");
            String originalVersion = v;
            expectInvalid(() -> workflow.review(OTHER,id,true,REASON,originalVersion), "non-staff cannot review");
            if ("CONFIRMED".equals(state)) {
                check("REJECTED".equals(workflow.review(STAFF,id,false,"Khong du dieu kien",v)), "staff rejects request");
                check("REJECTED".equals(requestStatus(id)) && state.equals(status(id)), "rejection preserves order status");
                inventory(before,0,"rejection does not restore stock");
                check(count("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id="+id+" AND old_status=status AND actor_type='STAFF'") == 1, "rejection recorded in history");
                check("PACKING".equals(pack(id)), "order can progress after rejection");
                check("REQUESTED".equals(customerCancel(id)), "customer can submit a new request");
                v = version(id);
            }
            check("CANCELLED".equals(workflow.review(STAFF,id,true,"Dong y huy",v)), "staff approves and cancels");
            inventory(before+2,0,"approval restores deducted stock exactly once");
            check("APPROVED".equals(requestStatus(id)) && "CANCELLED".equals(status(id)), "approval and cancellation committed");
            check(count("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id="+id+" AND cancellation_source='CUSTOMER' AND cancelled_at IS NOT NULL AND stock_restored_at IS NOT NULL AND cancel_reviewed_by=3") == 1, "approved request retains customer source and reviewer");
            String reviewedVersion = v;
            expectInvalid(() -> workflow.review(STAFF,id,true,REASON,reviewedVersion), "repeated review rejected");
            inventory(before+2,0,"repeat review cannot restore again");
            checkCancellationHistory(id,"STAFF",STAFF);
            AdminOrderDAO dao = adminDAO();
            check(dao.getById(id).getCancelRequestStatus().equals("APPROVED"), "admin detail maps approval");
            check(dao.getList().stream().anyMatch(o -> o.getOrderId()==id), "admin list contains order");
            check(dao.getHistory(id).stream().anyMatch(h -> "CANCELLED".equals(h.get("status")) && "STAFF".equals(h.get("actor")) && h.get("reason") != null), "history DAO exposes actor and reason");
        }
    }

    private void staffCancellationChecks() throws Exception {
        System.out.println("\n=== F48 STAFF CANCELLATION ===");
        for (String state : new String[]{"PENDING_CONFIRMATION","CONFIRMED","PACKING"}) {
            int id = order(CUSTOMER,2);
            if (!"PENDING_CONFIRMATION".equals(state)) confirm(id);
            if ("PACKING".equals(state)) pack(id);
            long before = stock();
            expectInvalid(() -> workflow.staffCancel(OTHER,id,REASON), "non-staff cannot cancel");
            check("CANCELLED".equals(workflow.staffCancel(STAFF,id,REASON)), "staff cancels " + state);
            inventory(before + ("PENDING_CONFIRMATION".equals(state)?0:2),0,"staff cancellation adjusts stock correctly");
            check("UNCHANGED".equals(workflow.staffCancel(STAFF,id,REASON)), "repeat staff cancellation unchanged");
            check(count("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id="+id+" AND cancellation_source='STAFF' AND cancelled_at IS NOT NULL") == 1, "staff cancellation source");
            checkCancellationHistory(id,"STAFF",STAFF);
        }
        check(count("SELECT COUNT(*) FROM dbo.ORDER_CUSTOMER_POLICY") == 0, "staff cancellation does not penalize customer");
    }

    private void progressChecks() throws Exception {
        System.out.println("\n=== F48 ORDER PROGRESS ===");
        int id = order(CUSTOMER,2);
        expectInvalid(() -> workflow.advanceOrder(STAFF,id,"nextStep","PENDING_CONFIRMATION"), "cannot skip confirmation");
        check("CONFIRMED".equals(confirm(id)), "confirm pending order");
        inventory(18,0,"confirm deducts once");
        expectInvalid(() -> confirm(id), "duplicate confirmation rejected");
        check("PACKING".equals(pack(id)), "pack confirmed order");
        check("SHIPPING".equals(ship(id)), "ship packed order");
        expectInvalid(() -> customerCancel(id), "customer cannot cancel shipping order");
        expectInvalid(() -> workflow.staffCancel(STAFF,id,REASON), "staff cannot cancel shipping order");
        check("COMPLETED".equals(workflow.advanceOrder(STAFF,id,"nextStep","SHIPPING")), "complete shipped order");
        expectInvalid(() -> customerCancel(id), "customer cannot cancel completed order");
        expectInvalid(() -> workflow.advanceOrder(STAFF,id,"nextStep","COMPLETED"), "completed order cannot advance");
        inventory(18,0,"progress never deducts twice");
        check(count("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id="+id+" AND payment_status='PAID' AND delivered_at IS NOT NULL") == 1, "COD completion records payment and delivery");
        check(count("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id="+id+" AND status IN ('CONFIRMED','PACKING','SHIPPING','COMPLETED')") == 4, "one history row per transition");
        check(count("SELECT COUNT(*) FROM dbo.INVENTORY_MOVEMENT WHERE movement_type='OUT' AND quantity_delta=-2") == 1, "one inventory deduction movement");
    }

    private void paidOnlineChecks() throws Exception {
        System.out.println("\n=== ONLINE CANCELLATION (LOCAL FIXTURES, NOT GATEWAY) ===");
        // Fixtures emulate payment states; no call to VNPAY/MOMO or real money.
        for (String method : new String[]{"VNPAY","MOMO"}) {
            int pending = order(CUSTOMER,1);
            execute("UPDATE dbo.[ORDER] SET payment_method='"+method+"',order_status='PENDING_PAYMENT',payment_expires_at=DATEADD(MINUTE,15,SYSUTCDATETIME()) WHERE order_id="+pending);
            execute("INSERT INTO dbo.PAYMENT_TRANSACTION(order_id,payment_method,amount,transaction_code) SELECT order_id,'"+method+"',total_amount,'PENDING-"+pending+"' FROM dbo.[ORDER] WHERE order_id="+pending);
            expectInvalid(() -> workflow.advanceOrder(STAFF,pending,"confirm","PENDING_PAYMENT"), "unpaid online cannot confirm");
            check("CANCELLED".equals(workflow.customerCancel(CUSTOMER,pending,null)), "customer cancels unpaid " + method + " without reason");
            checkCancellationHistory(pending,"CUSTOMER",CUSTOMER);
            inventory(20,0,"unpaid online cancellation releases reservation");
            check(count("SELECT COUNT(*) FROM dbo.PAYMENT_TRANSACTION WHERE order_id="+pending+" AND status='CANCELLED'") == 1,"pending payment attempt closed");
            int paid = order(CUSTOMER,1);
            execute("UPDATE dbo.[ORDER] SET payment_method='"+method+"',payment_status='PAID' WHERE order_id="+paid);
            execute("INSERT INTO dbo.PAYMENT_TRANSACTION(order_id,payment_method,amount,transaction_code,status) SELECT order_id,'"+method+"',total_amount,'PAID-"+paid+"','SUCCESS' FROM dbo.[ORDER] WHERE order_id="+paid);
            expectInvalid(() -> workflow.customerCancel(CUSTOMER,paid,null), "paid online customer must contact staff even without reason");
            check("CONFIRMED".equals(confirm(paid)), "paid online may be confirmed");
            expectInvalid(() -> customerCancel(paid), "paid online customer cannot request cancellation");
            check("CANCELLED".equals(workflow.staffCancel(STAFF,paid,REASON)), "staff can cancel paid online order");
            inventory(20,0,"staff cancellation restores confirmed paid order");
            check(count("SELECT COUNT(*) FROM dbo.[ORDER] WHERE order_id="+paid+" AND payment_status='PAID'") == 1,"captured payment status retained; not a refund");
            check(count("SELECT COUNT(*) FROM dbo.PAYMENT_TRANSACTION WHERE order_id="+paid+" AND status='SUCCESS'") == 1,"successful transaction retained");
        }
    }

    private void cancellationPolicyChecks() throws Exception {
        System.out.println("\n=== CUSTOMER CANCELLATION POLICY ===");
        expectInvalid(() -> order(CUSTOMER,6), "max five products per order");
        execute("DELETE FROM dbo.CART_ITEMS WHERE cart_id=1");
        int five = order(CUSTOMER,5), one = order(CUSTOMER,1);
        workflow.customerCancel(CUSTOMER,five,null);
        check(checkout.orderingRestriction(CUSTOMER)==null,"five cancelled items do not block ordering");
        workflow.customerCancel(CUSTOMER,one,null);
        check(count("SELECT violation_count FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=1") == 1,"six cancelled items trigger first strike");
        check(count("SELECT DATEDIFF(HOUR,SYSUTCDATETIME(),blocked_until) FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=1") >= 71,"first strike lasts three days");
        expectInvalid(() -> order(CUSTOMER,1),"blocked customer cannot checkout");
        check("UNCHANGED".equals(customerCancel(one)),"duplicate cancellation ignored");
        check(count("SELECT violation_count FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=1") == 1,"duplicate cancellation does not escalate policy");
        execute("DELETE FROM dbo.CART_ITEMS WHERE cart_id=1");
        for (int strike = 2; strike <= 3; strike++) {
            execute("UPDATE dbo.[ORDER] SET cancelled_at=DATEADD(DAY,-10,SYSUTCDATETIME()) WHERE cancellation_source='CUSTOMER' AND user_id=1; "
                    + "UPDATE dbo.ORDER_CUSTOMER_POLICY SET blocked_until=DATEADD(SECOND,-1,SYSUTCDATETIME()) WHERE user_id=1;");
            check(checkout.orderingRestriction(CUSTOMER)==null,"expired block permits checkout");
            int a = order(CUSTOMER,3), b = order(CUSTOMER,3);
            parallel(() -> customerCancel(a), () -> customerCancel(b));
            check(count("SELECT violation_count FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=1")==strike,"concurrent cancellation escalates to strike " + strike + " once");
            if (strike == 2) {
                check(count("SELECT DATEDIFF(HOUR,SYSUTCDATETIME(),blocked_until) FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=1")>=167,"second strike lasts seven days");
            } else {
                check(checkout.orderingRestriction(CUSTOMER)!=null,"third strike blocks ordering permanently");
                check(count("SELECT COUNT(*) FROM dbo.ORDER_CUSTOMER_POLICY WHERE user_id=1 AND violation_count=3 AND blocked_until IS NULL")==1,"third strike has no expiry");
            }
        }
    }

    private void rollbackChecks() throws Exception {
        System.out.println("\n=== TRANSACTION ROLLBACK ===");
        int id = order(CUSTOMER,2);
        execute("CREATE TRIGGER dbo.fail_test_history ON dbo.ORDER_STATUS_HISTORY AFTER INSERT AS THROW 51001,'test rollback',1;");
        try {
            expectSql(() -> confirm(id), "confirmation history failure rolls back");
            inventory(20,2,"rollback restores stock and reservation");
            check("PENDING_CONFIRMATION".equals(status(id)),"failed confirmation preserves status");
        } finally { execute("DROP TRIGGER dbo.fail_test_history"); }
        confirm(id); pack(id); customerCancel(id);
        String v = version(id);
        long histories = count("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id="+id);
        long notifications = count("SELECT COUNT(*) FROM dbo.NOTIFICATION WHERE order_id="+id);
        execute("CREATE TRIGGER dbo.fail_test_history ON dbo.ORDER_STATUS_HISTORY AFTER INSERT AS THROW 51001,'test rollback',1;");
        try {
            expectSql(() -> workflow.review(STAFF,id,true,REASON,v), "approval history failure rolls back");
            inventory(18,0,"approval rollback undoes stock restoration");
            check("PACKING".equals(status(id)) && "PENDING".equals(requestStatus(id)),"rollback preserves pending request and order");
            check(count("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id="+id)==histories,"no extra history on rollback");
            check(count("SELECT COUNT(*) FROM dbo.NOTIFICATION WHERE order_id="+id)==notifications,"no extra notification on rollback");
            check(count("SELECT COUNT(*) FROM dbo.INVENTORY_MOVEMENT WHERE movement_type='IN'")==0,"no restoration movement on rollback");
        } finally { execute("DROP TRIGGER dbo.fail_test_history"); }
    }

    private void concurrencyChecks() throws Exception {
        System.out.println("\n=== CONCURRENT ORDER ACTIONS ===");
        int id = order(CUSTOMER,2);
        Object[] result = parallel(() -> attempt(() -> confirm(id)), () -> attempt(() -> confirm(id)));
        check(!result[0].equals(result[1]) && ("CONFIRMED".equals(result[0]) || "CONFIRMED".equals(result[1])), "two staff confirmations succeed only once");
        inventory(18,0,"concurrent confirmation deducts once");
        pack(id);
        parallel(() -> attempt(() -> customerCancel(id)), () -> attempt(() -> ship(id)));
        String state = status(id);
        check(("PACKING".equals(state) && "PENDING".equals(requestStatus(id))) || ("SHIPPING".equals(state) && requestStatus(id)==null), "shipping versus request has one consistent winner");
        inventory(18,0,"request versus shipment does not restore stock");
        if ("SHIPPING".equals(state)) {
            idForConcurrentReview(order(OTHER,2));
        } else {
            concurrentReview(id,18);
        }
    }

    private void idForConcurrentReview(int id) throws Exception {
        confirm(id); pack(id);
        check("REQUESTED".equals(workflow.customerCancel(OTHER,id,REASON)),"prepare independent request for concurrent review");
        concurrentReview(id,stock());
    }

    private void concurrentReview(int id,long before) throws Exception {
        String v = version(id);
        Object[] result = parallel(() -> attempt(() -> workflow.review(STAFF,id,true,REASON,v)),
                () -> attempt(() -> workflow.review(STAFF,id,true,REASON,v)));
        check(!result[0].equals(result[1]) && ("CANCELLED".equals(result[0]) || "CANCELLED".equals(result[1])),"two approvals commit only once");
        inventory(before+2,0,"concurrent approval restores stock once");
        checkCancellationHistory(id,"STAFF",STAFF);
    }

    private void checkCancellationHistory(int id,String actor,int user) throws SQLException {
        check(count("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id="+id+" AND status='CANCELLED'")==1,"exactly one cancellation history row");
        check(count("SELECT COUNT(*) FROM dbo.ORDER_STATUS_HISTORY WHERE order_id="+id+" AND status='CANCELLED' AND actor_type='"+actor+"' AND changed_by="+user+" AND LEN(LTRIM(RTRIM(reason)))>0")==1,"history retains actor, ID and reason");
    }

    private AdminOrderDAO adminDAO() {
        return new AdminOrderDAO() {
            { try (Connection c = super.getConnection()) { /* close bootstrap connection */ }
              catch (SQLException e) { throw new IllegalStateException(e); } }
            @Override public Connection getConnection() {
                try { return connections.open(); }
                catch (SQLException e) { throw new IllegalStateException(e); }
            }
        };
    }

    private String status(int id) throws SQLException { return value("SELECT order_status FROM dbo.[ORDER] WHERE order_id="+id); }
    private String requestStatus(int id) throws SQLException { return value("SELECT cancel_request_status FROM dbo.[ORDER] WHERE order_id="+id); }
    private long stock() throws SQLException { return count("SELECT stock_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1"); }
    private void inventory(long expectedStock,long expectedReserved,String message) throws SQLException {
        try (Connection c=connections.open(); Statement s=c.createStatement(); ResultSet r=s.executeQuery("SELECT stock_quantity,reserved_quantity FROM dbo.PRODUCT_SKU WHERE sku_id=1")) {
            check(r.next() && r.getLong(1)==expectedStock && r.getLong(2)==expectedReserved,message);
        }
    }
    private void execute(String sql) throws SQLException {
        try (Connection c=connections.open(); Statement s=c.createStatement()) { s.execute(sql); }
    }
    private long count(String sql) throws SQLException {
        try (Connection c=connections.open(); PreparedStatement p=c.prepareStatement(sql); ResultSet r=p.executeQuery()) {
            if (!r.next()) throw new SQLException("Expected one result: "+sql);
            return r.getLong(1);
        }
    }
    private String value(String sql) throws SQLException {
        try (Connection c=connections.open(); PreparedStatement p=c.prepareStatement(sql); ResultSet r=p.executeQuery()) {
            if (!r.next()) throw new SQLException("Expected one result: "+sql);
            return r.getString(1);
        }
    }
    private Object[] parallel(Callable<?> a,Callable<?> b) throws Exception {
        ExecutorService pool=Executors.newFixedThreadPool(2);
        CountDownLatch start=new CountDownLatch(1);
        try {
            Future<?> first=pool.submit(() -> {start.await(); return a.call();});
            Future<?> second=pool.submit(() -> {start.await(); return b.call();});
            start.countDown();
            return new Object[]{first.get(30,TimeUnit.SECONDS),second.get(30,TimeUnit.SECONDS)};
        } finally { pool.shutdownNow(); pool.awaitTermination(5,TimeUnit.SECONDS); }
    }
    private String attempt(Callable<String> task) throws Exception {
        try { return task.call(); } catch (IllegalArgumentException expected) { return "REJECTED_ACTION"; }
    }
    private void check(boolean ok,String message) {
        if (!ok) throw new AssertionError("FAIL: "+message);
        passed++; System.out.println("PASS: "+message);
    }
    private void expectInvalid(Callable<?> task,String message) throws Exception {
        try { task.call(); } catch (IllegalArgumentException expected) { check(true,message); return; }
        throw new AssertionError("FAIL: "+message);
    }
    private void expectSql(Callable<?> task,String message) throws Exception {
        try { task.call(); } catch (SQLException expected) { check(true,message); return; }
        throw new AssertionError("FAIL: "+message);
    }
}
