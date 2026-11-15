package service;

import java.math.BigDecimal;
import java.util.Locale;
import java.util.Objects;
import dao.ReportDAO;

/** Run with scripts/check-admin-cleanup.ps1; no database needed. */
public final class AdminCleanupChecks {
    private static int passed;

    public static void main(String[] args) {
        equal("CONFIRMED", OrderStatusPolicy.requestedStatus(" pending ", "confirm"));
        equal("CONFIRMED", OrderStatusPolicy.requestedStatus("PENDING_CONFIRMATION", "confirm"));
        equal(null, OrderStatusPolicy.requestedStatus("PENDING_CONFIRMATION", "nextStep"));
        equal(null, OrderStatusPolicy.requestedStatus("CONFIRMED", "confirm"));
        equal("PACKING", OrderStatusPolicy.requestedStatus("CONFIRMED", "nextStep"));
        equal("SHIPPING", OrderStatusPolicy.requestedStatus("PACKING", "nextStep"));
        equal("COMPLETED", OrderStatusPolicy.requestedStatus("SHIPPING", "nextStep"));
        for (String state : new String[]{null, "", "invalid", "PENDING_PAYMENT", "CANCELLED", "COMPLETED"}) {
            equal(null, OrderStatusPolicy.requestedStatus(state, "confirm"));
            equal(null, OrderStatusPolicy.requestedStatus(state, "nextStep"));
        }
        equal(null, OrderStatusPolicy.requestedStatus("CONFIRMED", "cancel"));
        equal(null, OrderStatusPolicy.requestedStatus("CONFIRMED", null));
        equal(null, OrderStatusPolicy.requestedStatus("PACKING", "unknown"));

        Locale previous = Locale.getDefault();
        try {
            Locale.setDefault(Locale.forLanguageTag("tr-TR"));
            equal("SHIPPING", OrderStatusPolicy.normalize("shipping"));
        } finally {
            Locale.setDefault(previous);
        }

        equal(BigDecimal.ZERO, ReportDAO.calculateAverageOrderValue(BigDecimal.ZERO, 0));
        equal(new BigDecimal("33.33"), ReportDAO.calculateAverageOrderValue(new BigDecimal("100"), 3));
        equal(new BigDecimal("1.01"), ReportDAO.calculateAverageOrderValue(new BigDecimal("2.01"), 2));
        equal(new BigDecimal("0.00"), ReportDAO.calculateAverageOrderValue(BigDecimal.ZERO, 2));
        equal(BigDecimal.ZERO, ReportDAO.calculateAverageOrderValue(new BigDecimal("100"), 0));
        System.out.println("PASS: " + passed + " admin cleanup assertions");
    }

    private static void equal(Object expected, Object actual) {
        if (!Objects.equals(expected, actual)) {
            throw new AssertionError("Expected " + expected + " but got " + actual);
        }
        passed++;
    }
}
