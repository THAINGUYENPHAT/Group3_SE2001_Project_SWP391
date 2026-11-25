package payment;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Map;
import java.util.StringJoiner;
import java.util.TreeMap;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public final class PaymentGateway {

    private PaymentGateway() {
    }

    public static String config(String key) {
        String value = System.getProperty(key, System.getenv(key));

        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "Chưa cấu hình " + key
            );
        }

        return value.trim();
    }

    public static void requireConfigured(String method) {
        if ("COD".equals(method)) {
            return;
        }

        if (!"VNPAY".equals(method)) {
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

        config("VNPAY_TMN_CODE");
        config("VNPAY_HASH_SECRET");
    }

    public static boolean available(String method) {
        try {
            requireConfigured(method);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

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

    public static BigDecimal roundVnd(BigDecimal amount) {
        return amount.setScale(0, RoundingMode.HALF_UP);
    }

    public static String create(
            String method,
            String ref,
            BigDecimal amount,
            long remainingSeconds,
            String ip
    ) {

        if ("COD".equals(method)) {
            throw new IllegalArgumentException("COD không dùng cổng thanh toán.");
        }
        requireConfigured(method);

        long dong = amount.longValueExact();

        if (dong <= 0 || remainingSeconds <= 0) {
            throw new IllegalArgumentException(
                    "Đơn đã hết hạn hoặc số tiền không hợp lệ."
            );
        }

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
}
