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

    private static final int MAX_REPORTS_PER_DAY = 5;

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
                + "FROM dbo.REVIEW_REPORTS rr "
                + "JOIN dbo.PRODUCT_REVIEWS pr "
                + "ON rr.review_id = pr.review_id "
                + "LEFT JOIN dbo.[USER] reporter "
                + "ON rr.reported_by = reporter.user_id "
                + "LEFT JOIN dbo.[USER] resolver "
                + "ON rr.resolved_by = resolver.user_id "
                + "LEFT JOIN dbo.[USER] author "
                + "ON pr.user_id = author.user_id "
                + "LEFT JOIN dbo.PRODUCT_SKU ps "
                + "ON pr.sku_id = ps.sku_id "
                + "LEFT JOIN dbo.PRODUCT p "
                + "ON ps.product_id = p.product_id "
                + "ORDER BY CASE WHEN rr.report_status = 'PENDING' "
                + "THEN 0 ELSE 1 END, rr.created_at DESC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Map<String, Object> report = new HashMap<>();

                report.put("reportId", rs.getInt("report_id"));
                report.put("reviewId", rs.getInt("review_id"));
                report.put("reporterName",
                        rs.getString("reporter_name"));
                report.put("reason", rs.getString("reason"));
                report.put("status", rs.getString("report_status"));
                report.put("createdAt",
                        rs.getTimestamp("created_at"));
                report.put("resolverName",
                        rs.getString("resolver_name"));
                report.put("resolvedAt",
                        rs.getTimestamp("resolved_at"));
                report.put("reviewAuthor",
                        rs.getString("review_author"));
                report.put("rating", rs.getInt("rating"));
                report.put("comment", rs.getString("comment"));
                report.put("isHidden", rs.getBoolean("is_hidden"));
                report.put("productName",
                        rs.getString("product_name"));
                report.put("skuCode", rs.getString("sku_code"));

                reports.add(report);
            }
        }

        return reports;
    }

   
    public String createReport(
            int reviewId,
            int productId,
            int reportedBy,
            String reason) throws SQLException {

        if (reviewId <= 0
                || productId <= 0
                || reportedBy <= 0
                || reason == null
                || reason.trim().isEmpty()
                || reason.trim().length() > 500) {

            return "INVALID";
        }

        try (Connection conn = getConnection()) {

            conn.setAutoCommit(false);

            try {

                
                String lockUserSql
                        = "SELECT user_id "
                        + "FROM dbo.[USER] WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE user_id = ?";

                try (PreparedStatement ps
                        = conn.prepareStatement(lockUserSql)) {

                    ps.setInt(1, reportedBy);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {
                            conn.rollback();
                            return "INVALID";
                        }
                    }
                }

                
                String findReview
                        = "SELECT pr.user_id, pr.is_hidden "
                        + "FROM dbo.PRODUCT_REVIEWS pr "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "JOIN dbo.PRODUCT_SKU ps "
                        + "ON pr.sku_id = ps.sku_id "
                        + "WHERE pr.review_id = ? "
                        + "AND ps.product_id = ?";

                Integer ownerId = null;
                boolean isHidden = false;

                try (PreparedStatement ps
                        = conn.prepareStatement(findReview)) {

                    ps.setInt(1, reviewId);
                    ps.setInt(2, productId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (rs.next()) {
                            ownerId = rs.getInt("user_id");
                            isHidden = rs.getBoolean("is_hidden");
                        }
                    }
                }

              
                if (ownerId == null || isHidden) {
                    conn.rollback();
                    return "NOT_FOUND";
                }

                
                if (ownerId == reportedBy) {
                    conn.rollback();
                    return "OWN_REVIEW";
                }

                
                String checkPending
                        = "SELECT COUNT(*) AS total "
                        + "FROM dbo.REVIEW_REPORTS "
                        + "WHERE review_id = ? "
                        + "AND reported_by = ? "
                        + "AND report_status = 'PENDING'";

                try (PreparedStatement ps
                        = conn.prepareStatement(checkPending)) {

                    ps.setInt(1, reviewId);
                    ps.setInt(2, reportedBy);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (rs.next()
                                && rs.getInt("total") > 0) {

                            conn.rollback();
                            return "DUPLICATE";
                        }
                    }
                }

                
                String countReportsSql
                        = "SELECT COUNT(*) AS total "
                        + "FROM dbo.REVIEW_REPORTS "
                        + "WHERE reported_by = ? "
                        + "AND created_at >= "
                        + "DATEADD(HOUR, -24, GETDATE())";

                try (PreparedStatement ps
                        = conn.prepareStatement(countReportsSql)) {

                    ps.setInt(1, reportedBy);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (rs.next()) {

                            int totalReports
                                    = rs.getInt("total");

                            if (totalReports
                                    >= MAX_REPORTS_PER_DAY) {

                                conn.rollback();
                                return "RATE_LIMIT";
                            }
                        }
                    }
                }

                
                String insertSql
                        = "INSERT INTO dbo.REVIEW_REPORTS "
                        + "(review_id, reported_by, reason, "
                        + "report_status, created_at) "
                        + "VALUES (?, ?, ?, 'PENDING', GETDATE())";

                try (PreparedStatement ps
                        = conn.prepareStatement(insertSql)) {

                    ps.setInt(1, reviewId);
                    ps.setInt(2, reportedBy);
                    ps.setString(3, reason.trim());

                    if (ps.executeUpdate() != 1) {
                        conn.rollback();
                        return "FAILED";
                    }
                }

                conn.commit();
                return "SUCCESS";

            } catch (SQLException e) {

                conn.rollback();

                if (e.getErrorCode() == 2601
                        || e.getErrorCode() == 2627) {

                    return "DUPLICATE";
                }

                throw e;

            } catch (RuntimeException e) {

                conn.rollback();
                throw e;
            }
        }
    }

    
    public boolean resolveReport(
            int reportId,
            int staffId,
            String decision) throws SQLException {

        String newStatus;

        if ("HIDE".equals(decision)) {
            newStatus = "RESOLVED";

        } else if ("DISMISS".equals(decision)) {
            newStatus = "REJECTED";

        } else {
            throw new IllegalArgumentException(
                    "Quyết định không hợp lệ.");
        }

        try (Connection conn = getConnection()) {

            conn.setAutoCommit(false);

            try {

                int reviewId;

                String findReport
                        = "SELECT review_id "
                        + "FROM dbo.REVIEW_REPORTS "
                        + "WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE report_id = ? "
                        + "AND report_status = 'PENDING'";

                try (PreparedStatement ps
                        = conn.prepareStatement(findReport)) {

                    ps.setInt(1, reportId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {
                            conn.rollback();
                            return false;
                        }

                        reviewId = rs.getInt("review_id");
                    }
                }

               
                if ("HIDE".equals(decision)) {

                    String hideSql
                            = "UPDATE dbo.PRODUCT_REVIEWS "
                            + "SET is_hidden = 1 "
                            + "WHERE review_id = ?";

                    try (PreparedStatement ps
                            = conn.prepareStatement(hideSql)) {

                        ps.setInt(1, reviewId);

                        if (ps.executeUpdate() == 0) {
                            conn.rollback();
                            return false;
                        }
                    }
                }

               
                String updateReport
                        = "UPDATE dbo.REVIEW_REPORTS "
                        + "SET report_status = ?, "
                        + "resolved_by = ?, "
                        + "resolved_at = GETDATE() "
                        + "WHERE report_id = ? "
                        + "AND report_status = 'PENDING'";

                try (PreparedStatement ps
                        = conn.prepareStatement(updateReport)) {

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
