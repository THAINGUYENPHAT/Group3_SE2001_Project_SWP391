package controller;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;
import payment.PaymentGateway;

/** Run as a Java main after test-compile; no database or gateway account needed. */
public final class PaymentReturnChecks {
    public static void main(String[] args) throws Exception {
        System.setProperty("VNPAY_TMN_CODE", "test-merchant");
        System.setProperty("VNPAY_HASH_SECRET", "test-secret");

        Map<String, String> vnp = new HashMap<>();
        vnp.put("vnp_TmnCode", "test-merchant");
        vnp.put("vnp_TxnRef", "OECS-test");
        vnp.put("vnp_Amount", "10000000");
        vnp.put("vnp_ResponseCode", "00");
        vnp.put("vnp_TransactionStatus", "00");
        signVnp(vnp);
        check(vnp, true, false);
        check(vnp, false, true);
        vnp.put("vnp_ResponseCode", "24");
        signVnp(vnp);
        check(vnp, false, false);
        vnp.put("vnp_ResponseCode", "00"); // Tamper with a signed cancellation.
        check(vnp, false, false);
        vnp.put("vnp_TransactionStatus", "02");
        signVnp(vnp);
        check(vnp, false, false);
        check(new HashMap<>(), false, false);

        System.clearProperty("VNPAY_HASH_SECRET");
        check(vnp, false, false);
        System.out.println("Passed 7 VNPay return checks.");
    }

    private static void signVnp(Map<String, String> params) {
        params.put("vnp_SecureHash", PaymentGateway.hmac("HmacSHA512", "test-secret",
                PaymentGateway.vnpCanonical(params)));
    }

    private static void check(Map<String, String> params,
            boolean expected, boolean duplicate) throws Exception {
        Map<String, String[]> query = new HashMap<>();
        params.forEach((key, value) -> query.put(key, new String[]{value}));
        if (duplicate) query.put("vnp_ResponseCode", new String[]{"00", "24"});
        Map<String, Object> attributes = new HashMap<>();
        boolean[] forwarded = {false};
        RequestDispatcher dispatcher = (RequestDispatcher) Proxy.newProxyInstance(
                PaymentReturnChecks.class.getClassLoader(), new Class<?>[]{RequestDispatcher.class},
                (proxy, method, args) -> { forwarded[0] = true; return null; });
        HttpServletRequest request = (HttpServletRequest) Proxy.newProxyInstance(
                PaymentReturnChecks.class.getClassLoader(), new Class<?>[]{HttpServletRequest.class},
                (proxy, method, args) -> {
                    switch (method.getName()) {
                        case "getServletPath": return "/payment/vnpay/return";
                        case "getParameterMap": return query;
                        case "setAttribute": attributes.put((String) args[0], args[1]); return null;
                        case "getRequestDispatcher":
                            if (!"/WEB-INF/checkout/payment-result.jsp".equals(args[0])) {
                                throw new AssertionError("Wrong result view");
                            }
                            return dispatcher;
                        default: throw new AssertionError("Unexpected request call: " + method.getName());
                    }
                });
        HttpServletResponse response = (HttpServletResponse) Proxy.newProxyInstance(
                PaymentReturnChecks.class.getClassLoader(), new Class<?>[]{HttpServletResponse.class},
                (proxy, method, args) -> {
                    if (!"setHeader".equals(method.getName())) {
                        throw new AssertionError("Unexpected response call: " + method.getName());
                    }
                    return null;
                });
        new PaymentCallbackServlet().doGet(request, response);
        if (!forwarded[0] || !Boolean.valueOf(expected).equals(attributes.get("paymentSuccess"))) {
            throw new AssertionError("VNPay returned incorrect payment result");
        }
    }
}
