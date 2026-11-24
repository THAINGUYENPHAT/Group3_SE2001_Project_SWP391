package service;

import dao.ReportDAO;
import model.SalesReport;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;

public final class ReportService {
    public static final class Range {
        public final LocalDate start;
        public final LocalDate end;

        private Range(LocalDate start, LocalDate end) {
            this.start = start;
            this.end = end;
        }
    }

    public static Range parseRange(String start, String end) {
        boolean hasStart = start != null && !start.isBlank();
        boolean hasEnd = end != null && !end.isBlank();
        if (!hasStart && !hasEnd) {
            LocalDate today = LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
            return new Range(today.minusDays(29), today);
        }
        if (!hasStart || !hasEnd) {
            throw new IllegalArgumentException("Vui lòng chọn đầy đủ ngày bắt đầu và ngày kết thúc.");
        }

        try {
            LocalDate startDate = LocalDate.parse(start);
            LocalDate endDate = LocalDate.parse(end);
            validateDateRange(startDate, endDate);
            return new Range(startDate, endDate);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Ngày được chọn không hợp lệ.", e);
        }
    }

    public SalesReport loadFullReport(LocalDate start, LocalDate end) {
        validateDateRange(start, end);
        return new ReportDAO().loadFullReport(start, end);
    }

    // Kiểm tra ngày lọc.
    public static void validateDateRange(LocalDate start, LocalDate end) {
        if (start == null || end == null || start.isAfter(end)) {
            throw new IllegalArgumentException(
                    "Ngày bắt đầu không được lớn hơn ngày kết thúc.");
        }
        if (start.getYear() < 1 || !end.isBefore(LocalDate.of(9999, 12, 31))) {
            throw new IllegalArgumentException("Khoảng ngày vượt giới hạn SQL Server.");
        }
    }

    // Giá trị trung bình của đơn được ghi nhận doanh thu.
    public static BigDecimal calculateAverageOrderValue(BigDecimal revenue, int revenueOrders) {
        if (revenueOrders <= 0) {
            return BigDecimal.ZERO;
        }
        return revenue.divide(BigDecimal.valueOf(revenueOrders), 2, RoundingMode.HALF_UP);
    }
}
