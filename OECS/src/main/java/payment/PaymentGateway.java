package payment;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.math.BigDecimal;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.StringJoiner;
import java.util.TreeMap;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public final class PaymentGateway {

    private PaymentGateway() {
    }

    // Doc cau hinh tu JVM property hoac bien moi truong
    public static String config(String key) {
        String value = System.getProperty(key, System.getenv(key));

        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "Chưa cấu hình " + key
            );
        }

        return value.trim();
    }

    // Kiem tra cau hinh truoc khi tao don thanh toan online
    public static void requireConfigured(String method) {
        if ("COD".equals(method)) {
            return;
        }

        if (!Arrays.asList("VNPAY", "MOMO").contains(method)) {
            throw new IllegalArgumentException(
                    "Phương thức thanh toán không hợp lệ."
            );
        }

        URI base = URI.create(config("PAYMENT_BASE_URL"));

        if (!"https".equals(base.getScheme())
                || base.getHost() == null
                || base.getQuery() != null
                || base.getFragment() != null) {

            throw new IllegalArgumentException(
                    "PAYMENT_BASE_URL phải là HTTPS, "
                    + "có context path và không có query."
            );
        }

        if ("VNPAY".equals(method)) {
            config("VNPAY_TMN_CODE");
            config("VNPAY_HASH_SECRET");
        } else {
            config("MOMO_PARTNER_CODE");
            config("MOMO_ACCESS_KEY");
            config("MOMO_SECRET_KEY");
        }
    }

    // Dung de bat/tat lua chon thanh toan tren giao dien
    public static boolean available(String method) {
        try {
            requireConfigured(method);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    // Tao chu ky HMAC
    public static String hmac(
            String algorithm,
            String secret,
            String data
    ) {
        try {
            Mac mac = Mac.getInstance(algorithm);

            mac.init(new SecretKeySpec(
                    secret.getBytes(StandardCharsets.UTF_8),
                    algorithm
            ));

            byte[] hash = mac.doFinal(
                    data.getBytes(StandardCharsets.UTF_8)
            );

            StringBuilder result = new StringBuilder();

            for (byte b : hash) {
                result.append(
                        String.format("%02x", b & 255)
                );
            }

            return result.toString();

        } catch (Exception e) {
            throw new IllegalStateException(
                    "Không tạo được chữ ký thanh toán.",
                    e
            );
        }
    }

    // So sanh chu ky
    public static boolean equalSignature(
            String expected,
            String actual
    ) {
        return actual != null
                && MessageDigest.isEqual(
                        expected.getBytes(StandardCharsets.US_ASCII),
                        actual.toLowerCase(Locale.ROOT)
                                .getBytes(StandardCharsets.US_ASCII)
                );
    }

    public static String encode(String value) {
        return URLEncoder.encode(
                value,
                StandardCharsets.UTF_8
        );
    }

    // Sap xep va ma hoa tham so theo quy tac VNPay
    public static String vnpCanonical(
            Map<String, String> params
    ) {
        StringJoiner result = new StringJoiner("&");

        new TreeMap<>(params).forEach((key, value) -> {
            if (key.startsWith("vnp_")
                    && !key.equals("vnp_SecureHash")
                    && !key.equals("vnp_SecureHashType")
                    && value != null
                    && !value.isEmpty()) {

                result.add(
                        encode(key) + "=" + encode(value)
                );
            }
        });

        return result.toString();
    }

    private static String base() {
        return config("PAYMENT_BASE_URL")
                .replaceAll("/+$", "");
    }

    // Chi su dung endpoint SANDBOX, khong dung production
    public static String create(
            String method,
            String ref,
            BigDecimal amount,
            long remainingSeconds,
            String ip
    ) throws Exception {

        requireConfigured(method);

        long dong = amount.longValueExact();

        if (dong <= 0 || remainingSeconds <= 0) {
            throw new IllegalArgumentException(
                    "Đơn đã hết hạn hoặc số tiền không hợp lệ."
            );
        }

        if ("VNPAY".equals(method)) {
            ZonedDateTime now = ZonedDateTime.now(
                    ZoneId.of("Asia/Ho_Chi_Minh")
            );

            DateTimeFormatter formatter =
                    DateTimeFormatter.ofPattern(
                            "yyyyMMddHHmmss"
                    );

            Map<String, String> params = new TreeMap<>();

            params.put("vnp_Version", "2.1.0");
            params.put("vnp_Command", "pay");
            params.put(
                    "vnp_TmnCode",
                    config("VNPAY_TMN_CODE")
            );

            // VNPay yeu cau so tien nhan 100
            params.put(
                    "vnp_Amount",
                    Long.toString(
                            Math.multiplyExact(dong, 100)
                    )
            );

            params.put("vnp_CurrCode", "VND");
            params.put("vnp_TxnRef", ref);
            params.put(
                    "vnp_OrderInfo",
                    "Thanh toan OECS " + ref
            );
            params.put("vnp_OrderType", "other");
            params.put("vnp_Locale", "vn");
            params.put("vnp_IpAddr", ip);

            params.put(
                    "vnp_ReturnUrl",
                    base() + "/payment/vnpay/return"
            );

            params.put(
                    "vnp_CreateDate",
                    formatter.format(now)
            );

            params.put(
                    "vnp_ExpireDate",
                    formatter.format(
                            now.plusSeconds(remainingSeconds)
                    )
            );

            String query = vnpCanonical(params);

            String signature = hmac(
                    "HmacSHA512",
                    config("VNPAY_HASH_SECRET"),
                    query
            );

            return "https://sandbox.vnpayment.vn"
                    + "/paymentv2/vpcpay.html?"
                    + query
                    + "&vnp_SecureHash="
                    + signature;
        }

        // Tao yeu cau thanh toan MoMo Test
        Map<String, String> params = new TreeMap<>();

        params.put(
                "accessKey",
                config("MOMO_ACCESS_KEY")
        );
        params.put("amount", Long.toString(dong));
        params.put("extraData", "");
        params.put(
                "ipnUrl",
                base() + "/payment/momo/ipn"
        );
        params.put("orderId", ref);
        params.put(
                "orderInfo",
                "Thanh toan OECS " + ref
        );
        params.put(
                "partnerCode",
                config("MOMO_PARTNER_CODE")
        );
        params.put(
                "redirectUrl",
                base() + "/payment/momo/return"
        );
        params.put("requestId", ref);
        params.put("requestType", "captureWallet");

        String signature = hmac(
                "HmacSHA256",
                config("MOMO_SECRET_KEY"),
                raw(params)
        );

        JsonObject body = new JsonObject();

        params.forEach((key, value) -> {
            if (!key.equals("accessKey")
                    && !key.equals("amount")) {
                body.addProperty(key, value);
            }
        });

        body.addProperty("amount", dong);
        body.addProperty("signature", signature);
        body.addProperty("lang", "vi");
        body.addProperty("autoCapture", true);

        HttpRequest request = HttpRequest.newBuilder(
                URI.create(
                        "https://test-payment.momo.vn"
                        + "/v2/gateway/api/create"
                )
        )
                .timeout(Duration.ofSeconds(20))
                .header(
                        "Content-Type",
                        "application/json"
                )
                .POST(
                        HttpRequest.BodyPublishers.ofString(
                                body.toString()
                        )
                )
                .build();

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();

        HttpResponse<String> response = client.send(
                request,
                HttpResponse.BodyHandlers.ofString()
        );

        if (response.statusCode() != 200) {
            throw new IllegalStateException(
                    "Cổng MoMo chưa phản hồi. "
                    + "Thử lại từ đơn hàng."
            );
        }

        JsonObject result = JsonParser.parseString(
                response.body()
        ).getAsJsonObject();

        if (!result.has("resultCode")
                || result.get("resultCode").getAsInt() != 0) {

            throw new IllegalArgumentException(
                    "MoMo chưa tạo được thanh toán. "
                    + "Kiểm tra tài khoản sandbox hoặc thử lại."
            );
        }

        URI paymentUrl = URI.create(
                result.get("payUrl").getAsString()
        );

        if (!"https".equals(paymentUrl.getScheme())
                || !"test-payment.momo.vn".equals(
                        paymentUrl.getHost()
                )) {

            throw new IllegalArgumentException(
                    "URL MoMo không hợp lệ."
            );
        }

        return paymentUrl.toString();
    }

    // Chuoi ky cua MoMo: sap xep key, khong URL encode
    public static String raw(Map<String, String> params) {
        StringJoiner result = new StringJoiner("&");

        new TreeMap<>(params).forEach(
                (key, value) ->
                        result.add(key + "=" + value)
        );

        return result.toString();
    }

    // Xac minh callback VNPay
    public static boolean verifyVnp(
            Map<String, String> params
    ) {
        return config("VNPAY_TMN_CODE").equals(
                params.get("vnp_TmnCode")
        ) && equalSignature(
                hmac(
                        "HmacSHA512",
                        config("VNPAY_HASH_SECRET"),
                        vnpCanonical(params)
                ),
                params.get("vnp_SecureHash")
        );
    }

    // Xac minh callback MoMo
    public static boolean verifyMomo(
            Map<String, String> params
    ) {
        if (!config("MOMO_PARTNER_CODE").equals(
                params.get("partnerCode")
        ) || !Objects.equals(
                params.get("orderId"),
                params.get("requestId")
        )) {
            return false;
        }

        Map<String, String> signed = new TreeMap<>();

        signed.put(
                "accessKey",
                config("MOMO_ACCESS_KEY")
        );

        for (String key : Arrays.asList(
                "amount",
                "extraData",
                "message",
                "orderId",
                "orderInfo",
                "orderType",
                "partnerCode",
                "payType",
                "requestId",
                "responseTime",
                "resultCode",
                "transId"
        )) {
            if (!params.containsKey(key)) {
                return false;
            }

            signed.put(key, params.get(key));
        }

        return equalSignature(
                hmac(
                        "HmacSHA256",
                        config("MOMO_SECRET_KEY"),
                        raw(signed)
                ),
                params.get("signature")
        );
    }
}