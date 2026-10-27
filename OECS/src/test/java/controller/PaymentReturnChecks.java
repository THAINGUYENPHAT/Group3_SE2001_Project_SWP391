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
        System.setProperty("MOMO_PARTNER_CODE", "test-partner");
        System.setProperty("MOMO_ACCESS_KEY", "test-access");
        System.setProperty("MOMO_SECRET_KEY", "test-secret");

        Map<String, String> vnp = new HashMap<>();
        vnp.put("vnp_TmnCode", "test-merchant");
        vnp.put("vnp_TxnRef", "OECS-test");
        vnp.put("vnp_Amount", "10000000");
        vnp.put("vnp_ResponseCode", "00");
        vnp.put("vnp_TransactionStatus", "00");
        signVnp(vnp);
        check("vnpay", vnp, true, false);
        check("vnpay", vnp, false, true);
        vnp.put("vnp_ResponseCode", "24");
        signVnp(vnp);
        check("vnpay", vnp, false, false);
        vnp.put("vnp_ResponseCode", "00"); // Tamper with a signed cancellation.
        check("vnpay", vnp, false, false);
        vnp.put("vnp_TransactionStatus", "02");
        signVnp(vnp);
        check("vnpay", vnp, false, false);
        check("vnpay", new HashMap<>(), false, false);

        Map<String, String> momo = new HashMap<>();
        for (String key : new String[]{"amount", "extraData", "message", "orderInfo",
            "orderType", "payType", "responseTime", "transId"}) {
            momo.put(key, "test");
        }
        momo.put("amount", "100000");
        momo.put("partnerCode", "test-partner");
        momo.put("orderId", "OECS-test");
        momo.put("requestId", "OECS-test");
        momo.put("resultCode", "0");
        signMomo(momo);
        check("momo", momo, true, false);
        check("momo", momo, false, true);
        momo.put("resultCode", "1006");
        signMomo(momo);
        check("momo", momo, false, false);
        momo.put("resultCode", "0");
        check("momo", momo, false, false);
        check("momo", new HashMap<>(), false, false);
        System.clearProperty("VNPAY_HASH_SECRET");
        check("vnpay", vnp, false, false);
        System.out.println("Passed 12 payment return checks.");
    }

    private static void signVnp(Map<String, String> params) {
        params.put("vnp_SecureHash", PaymentGateway.hmac("HmacSHA512", "test-secret",
                PaymentGateway.vnpCanonical(params)));
    }

    private static void signMomo(Map<String, String> params) {
        Map<String, String> signed = new HashMap<>(params);
        signed.remove("signature");
        signed.put("accessKey", "test-access");
        params.put("signature", PaymentGateway.hmac("HmacSHA256", "test-secret",
                PaymentGateway.raw(signed)));
    }

    private static void check(String provider, Map<String, String> params,
            boolean expected, boolean duplicate) throws Exception {
        Map<String, String[]> query = new HashMap<>();
        params.forEach((key, value) -> query.put(key, new String[]{value}));
        if (duplicate) query.put("resultCode", new String[]{"0", "1006"});
        Map<String, Object> attributes = new HashMap<>();
        boolean[] forwarded = {false};
        RequestDispatcher dispatcher = (RequestDispatcher) Proxy.newProxyInstance(
                PaymentReturnChecks.class.getClassLoader(), new Class<?>[]{RequestDispatcher.class},
                (proxy, method, args) -> { forwarded[0] = true; return null; });
        HttpServletRequest request = (HttpServletRequest) Proxy.newProxyInstance(
                PaymentReturnChecks.class.getClassLoader(), new Class<?>[]{HttpServletRequest.class},
                (proxy, method, args) -> {
                    switch (method.getName()) {
                        case "getServletPath": return "/payment/" + provider + "/return";
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
            throw new AssertionError(provider + " returned incorrect payment result");
        }
    }
}
