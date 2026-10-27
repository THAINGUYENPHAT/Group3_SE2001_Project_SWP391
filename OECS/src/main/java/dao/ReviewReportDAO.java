package dao;

import db.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ReviewReportDAO extends DBContext {

    public List<Map<String, Object>> getAllReports()
            throws SQLException {

        List<Map<String, Object>> reports = new ArrayList<>();

        String sql = "SELECT rr.report_id, rr.review_id, "
                + "rr.reported_by, reporter.username AS reporter_name, "
                + "rr.reason, rr.report_status, rr.created_at, "
                + "rr.resolved_by, resolver.username AS resolver_name, "
                + "rr.resolved_at, "
                + "author.username AS review_author, "
                + "pr.rating, pr.comment, pr.is_hidden, "
                + "p.product_name, ps.sku_code "
                + "FROM REVIEW_REPORTS rr "
                + "JOIN PRODUCT_REVIEWS pr "
                + "ON rr.review_id = pr.review_id "
                + "LEFT JOIN [USER] reporter "
                + "ON rr.reported_by = reporter.user_id "
                + "LEFT JOIN [USER] resolver "
                + "ON rr.resolved_by = resolver.user_id "
                + "LEFT JOIN [USER] author "
                + "ON pr.user_id = author.user_id "
                + "LEFT JOIN PRODUCT_SKU ps ON pr.sku_id = ps.sku_id "
                + "LEFT JOIN PRODUCT p ON ps.product_id = p.product_id "
                + "ORDER BY CASE WHEN rr.report_status = 'PENDING' "
                + "THEN 0 ELSE 1 END, rr.created_at DESC";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> report = new HashMap<>();

                report.put("reportId", rs.getInt("report_id"));
                report.put("reviewId", rs.getInt("review_id"));
                report.put("reporterName", rs.getString("reporter_name"));
                report.put("reason", rs.getString("reason"));
                report.put("status", rs.getString("report_status"));
                report.put("createdAt", rs.getTimestamp("created_at"));
                report.put("resolverName", rs.getString("resolver_name"));
                report.put("resolvedAt", rs.getTimestamp("resolved_at"));
                report.put("reviewAuthor", rs.getString("review_author"));
                report.put("rating", rs.getInt("rating"));
                report.put("comment", rs.getString("comment"));
                report.put("isHidden", rs.getBoolean("is_hidden"));
                report.put("productName", rs.getString("product_name"));
                report.put("skuCode", rs.getString("sku_code"));

                reports.add(report);
            }
        }

        return reports;
    }

    public String createReport(int reviewId, int reportedBy, String reason)
            throws SQLException {

        try (Connection conn = getConnection()) {

            // Kiểm tra đánh giá có tồn tại không.
            Integer ownerId = null;

            String findReview = "SELECT user_id "
                    + "FROM PRODUCT_REVIEWS WHERE review_id = ?";

            try (PreparedStatement ps = conn.prepareStatement(findReview)) {
                ps.setInt(1, reviewId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        ownerId = rs.getInt("user_id");
                    }
                }
            }

            if (ownerId == null) {
                return "NOT_FOUND";
            }

            // Không cho khách hàng báo cáo đánh giá của chính mình.
            if (ownerId == reportedBy) {
                return "OWN_REVIEW";
            }

            // Không cho tạo nhiều báo cáo đang chờ trên cùng đánh giá.
            String checkPending = "SELECT COUNT(*) "
                    + "FROM REVIEW_REPORTS "
                    + "WHERE review_id = ? "
                    + "AND reported_by = ? "
                    + "AND report_status = 'PENDING'";

            try (PreparedStatement ps = conn.prepareStatement(checkPending)) {
                ps.setInt(1, reviewId);
                ps.setInt(2, reportedBy);

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        return "DUPLICATE";
                    }
                }
            }

            String insert = "INSERT INTO REVIEW_REPORTS "
                    + "(review_id, reported_by, reason, report_status, "
                    + "created_at) "
                    + "VALUES (?, ?, ?, 'PENDING', GETDATE())";

            try (PreparedStatement ps = conn.prepareStatement(insert)) {
                ps.setInt(1, reviewId);
                ps.setInt(2, reportedBy);
                ps.setString(3, reason);

                return ps.executeUpdate() > 0 ? "SUCCESS" : "FAILED";

            } catch (SQLException e) {
                // SQL Server: 2601/2627 là lỗi trùng khóa duy nhất.
                if (e.getErrorCode() == 2601
                        || e.getErrorCode() == 2627) {
                    return "DUPLICATE";
                }

                throw e;
            }
        }
    }

    public boolean resolveReport(int reportId, int staffId, String decision)
            throws SQLException {

        String newStatus;

        if ("HIDE".equals(decision)) {
            newStatus = "RESOLVED";
        } else if ("DISMISS".equals(decision)) {
            newStatus = "REJECTED";
        } else {
            throw new IllegalArgumentException("Quyết định không hợp lệ.");
        }

        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);

            try {
                int reviewId;

                String findReport = "SELECT review_id "
                        + "FROM REVIEW_REPORTS "
                        + "WHERE report_id = ? "
                        + "AND report_status = 'PENDING'";

                try (PreparedStatement ps =
                        conn.prepareStatement(findReport)) {

                    ps.setInt(1, reportId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return false;
                        }

                        reviewId = rs.getInt("review_id");
                    }
                }

                // Chấp nhận báo cáo: ẩn đánh giá vi phạm.
                if ("HIDE".equals(decision)) {
                    String hideSql = "UPDATE PRODUCT_REVIEWS "
                            + "SET is_hidden = 1 WHERE review_id = ?";

                    try (PreparedStatement ps =
                            conn.prepareStatement(hideSql)) {

                        ps.setInt(1, reviewId);

                        if (ps.executeUpdate() == 0) {
                            conn.rollback();
                            return false;
                        }
                    }
                }

                String updateReport = "UPDATE REVIEW_REPORTS "
                        + "SET report_status = ?, resolved_by = ?, "
                        + "resolved_at = GETDATE() "
                        + "WHERE report_id = ? "
                        + "AND report_status = 'PENDING'";

                try (PreparedStatement ps =
                        conn.prepareStatement(updateReport)) {

                    ps.setString(1, newStatus);
                    ps.setInt(2, staffId);
                    ps.setInt(3, reportId);

                    if (ps.executeUpdate() == 0) {
                        conn.rollback();
                        return false;
                    }
                }

                conn.commit();
                return true;

            } catch (SQLException | RuntimeException e) {
                conn.rollback();
                throw e;
            }
        }
    }
}