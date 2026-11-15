package service;

import java.util.Locale;

/** Forward progress only; cancellations belong to OrderCancellationService. */
public final class OrderStatusPolicy {
    private OrderStatusPolicy() {
    }

    public static String normalize(String status) {
        if (status == null) {
            return null;
        }
        switch (status.trim().toUpperCase(Locale.ROOT)) {
            case "PENDING":
            case "PENDING_CONFIRMATION":
                return "PENDING_CONFIRMATION";
            case "CONFIRMED":
                return "CONFIRMED";
            case "PACKING":
                return "PACKING";
            case "SHIPPING":
                return "SHIPPING";
            case "COMPLETED":
                return "COMPLETED";
            case "CANCELLED":
                return "CANCELLED";
            default:
                return null;
        }
    }

    public static String nextStatus(String currentStatus) {
        String current = normalize(currentStatus);
        if (current == null) {
            return null;
        }
        switch (current) {
            case "PENDING_CONFIRMATION":
                return "CONFIRMED";
            case "CONFIRMED":
                return "PACKING";
            case "PACKING":
                return "SHIPPING";
            case "SHIPPING":
                return "COMPLETED";
            default:
                return null;
        }
    }

    public static String requestedStatus(String currentStatus, String action) {
        String next = nextStatus(currentStatus);
        if ("confirm".equals(action)) {
            return "CONFIRMED".equals(next) ? next : null;
        }
        if ("nextStep".equals(action) && !"CONFIRMED".equals(next)) {
            return next;
        }
        return null;
    }
}
