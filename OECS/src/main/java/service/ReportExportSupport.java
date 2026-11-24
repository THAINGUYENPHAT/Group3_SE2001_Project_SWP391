package service;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

final class ReportExportSupport {

    static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private ReportExportSupport() {
    }

    static double orderShare(int count, int totalOrders) {
        return totalOrders > 0 ? (double) count / totalOrders : 0;
    }

    static int toInt(Object value) {
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }

        return 0;
    }

    static BigDecimal toMoney(Object value) {
        if (value instanceof BigDecimal) {
            return (BigDecimal) value;
        }

        if (value instanceof Number) {
            return BigDecimal.valueOf(
                    ((Number) value).doubleValue()
            );
        }

        return BigDecimal.ZERO;
    }

    static String formatDate(Object value) {
        if (value == null) {
            return "";
        }

        if (value instanceof LocalDate) {
            return ((LocalDate) value)
                    .format(DATE_FORMAT);
        }

        if (value instanceof Date) {
            return ((Date) value)
                    .toLocalDate()
                    .format(DATE_FORMAT);
        }

        String text = value.toString();

        try {
            return LocalDate.parse(
                    text.substring(0, 10)
            ).format(DATE_FORMAT);
        } catch (Exception e) {
            return text;
        }
    }

    static String paymentStatusName(String status) {
        switch (status) {
            case "PAID": return "Đã thanh toán";
            case "UNPAID": return "Chưa thanh toán";
            case "PENDING": return "Chờ thanh toán";
            case "FAILED": return "Thất bại";
            case "CANCELLED": return "Đã hủy thanh toán";
            case "EXPIRED": return "Hết hạn";
            default: return status;
        }
    }

    static String statusName(String status) {
        if (status == null) {
            return "Không xác định";
        }

        switch (status) {
            case "PENDING_PAYMENT":
                return "Chờ thanh toán";

            case "EXPIRED":
                return "Hết hạn";

            case "RETURNED":
                return "Đã trả hàng";

            case "PENDING_CONFIRMATION":
                return "Chờ xác nhận";

            case "CONFIRMED":
                return "Đã xác nhận";

            case "PACKING":
                return "Đang đóng gói";

            case "SHIPPING":
                return "Đang giao hàng";

            case "COMPLETED":
                return "Hoàn thành";

            case "CANCELLED":
                return "Đã hủy";

            default:
                return status;
        }
    }
}
