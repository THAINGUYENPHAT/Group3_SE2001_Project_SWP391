
package controller;

import dao.ReviewReportDAO;
import dao.StaffReviewDAO;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@WebServlet(name = "StaffReviewServlet", urlPatterns = {"/staff/reviews"})
public class StaffReviewServlet extends HttpServlet {

    private User getStaff(HttpServletRequest request,
            HttpServletResponse response) throws IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || !(session.getAttribute("loggedInUser") instanceof User)) {
            response.sendRedirect(request.getContextPath() + "/login");
            return null;
        }

        User user = (User) session.getAttribute("loggedInUser");

        if (!user.isStaff()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return null;
        }

        return user;
    }

    private String ensureToken(HttpSession session) {
        String token = (String) session.getAttribute("reviewCsrfToken");

        if (token == null) {
            token = UUID.randomUUID().toString();
            session.setAttribute("reviewCsrfToken", token);
        }

        return token;
    }

    private boolean validToken(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        if (session == null) {
            return false;
        }

        String expected = (String) session.getAttribute("reviewCsrfToken");
        String actual = request.getParameter("csrfToken");

        return expected != null && expected.equals(actual);
    }

    private String reviewFilter(String raw) {
        if (raw == null) {
            return "all";
        }

        String value = raw.trim().toLowerCase(Locale.ROOT);

        return "visible".equals(value) || "hidden".equals(value)
                ? value : "all";
    }

    private String reportFilter(String raw) {
        if (raw == null) {
            return "all";
        }

        String value = raw.trim().toLowerCase(Locale.ROOT);

        return "pending".equals(value)
                || "resolved".equals(value)
                || "rejected".equals(value)
                ? value : "all";
    }

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        if (getStaff(request, response) == null) {
            return;
        }

        ensureToken(request.getSession());

        String reviewStatus =
                reviewFilter(request.getParameter("reviewStatus"));

        String reportStatus =
                reportFilter(request.getParameter("reportStatus"));

        try {
            List<Map<String, Object>> allReviews =
                    new StaffReviewDAO().getAllReviewsForStaff();

            List<Map<String, Object>> allReports =
                    new ReviewReportDAO().getAllReports();

            List<Map<String, Object>> filteredReviews = new ArrayList<>();
            List<Map<String, Object>> filteredReports = new ArrayList<>();

            int visibleCount = 0;
            int hiddenCount = 0;

            for (Map<String, Object> review : allReviews) {
                boolean hidden =
                        Boolean.TRUE.equals(review.get("isHidden"));

                if (hidden) {
                    hiddenCount++;
                } else {
                    visibleCount++;
                }

                if ("all".equals(reviewStatus)
                        || (hidden && "hidden".equals(reviewStatus))
                        || (!hidden && "visible".equals(reviewStatus))) {
                    filteredReviews.add(review);
                }
            }

            int pendingCount = 0;
            int resolvedCount = 0;
            int rejectedCount = 0;

            for (Map<String, Object> report : allReports) {
                String status = String.valueOf(report.get("status"));

                if ("PENDING".equals(status)) {
                    pendingCount++;
                } else if ("RESOLVED".equals(status)) {
                    resolvedCount++;
                } else if ("REJECTED".equals(status)) {
                    rejectedCount++;
                }

                if ("all".equals(reportStatus)
                        || reportStatus.equalsIgnoreCase(status)) {
                    filteredReports.add(report);
                }
            }

            request.setAttribute("reviews", filteredReviews);
            request.setAttribute("reports", filteredReports);

            request.setAttribute("allReviewCount", allReviews.size());
            request.setAttribute("visibleReviewCount", visibleCount);
            request.setAttribute("hiddenReviewCount", hiddenCount);

            request.setAttribute("allReportCount", allReports.size());
            request.setAttribute("pendingReportCount", pendingCount);
            request.setAttribute("resolvedReportCount", resolvedCount);
            request.setAttribute("rejectedReportCount", rejectedCount);

            request.setAttribute("reviewStatusFilter", reviewStatus);
            request.setAttribute("reportStatusFilter", reportStatus);

            request.getRequestDispatcher("/WEB-INF/review/staff-list.jsp")
                    .forward(request, response);

        } catch (SQLException e) {
            throw new ServletException("Không thể tải dữ liệu đánh giá.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        User user = getStaff(request, response);

        if (user == null) {
            return;
        }

        if (!validToken(request)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Phiên làm việc không hợp lệ. Vui lòng tải lại trang.");
            return;
        }

        String action = request.getParameter("action");
        boolean success;

        try {
            if ("visibility".equals(action)) {
                int reviewId =
                        Integer.parseInt(request.getParameter("reviewId"));

                String hiddenParam = request.getParameter("hidden");

                if (!"true".equals(hiddenParam)
                        && !"false".equals(hiddenParam)) {
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                    return;
                }

                success = new StaffReviewDAO().setReviewHidden(
                        reviewId,
                        Boolean.parseBoolean(hiddenParam));

            } else if ("resolveReport".equals(action)) {
                int reportId =
                        Integer.parseInt(request.getParameter("reportId"));

                String decision = request.getParameter("decision");

                if (!"HIDE".equals(decision)
                        && !"DISMISS".equals(decision)) {
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                    return;
                }

                success = new ReviewReportDAO().resolveReport(
                        reportId,
                        user.getUserId(),
                        decision);

            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }

            request.getSession().setAttribute(
                    success ? "successMessage" : "errorMessage",
                    success
                            ? "Thao tác kiểm duyệt thành công."
                            : "Không thể thực hiện thao tác; dữ liệu có thể đã thay đổi.");

            String url = request.getContextPath()
                    + "/staff/reviews?reviewStatus="
                    + reviewFilter(request.getParameter("reviewStatus"))
                    + "&reportStatus="
                    + reportFilter(request.getParameter("reportStatus"));

            response.sendRedirect(url);

        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "ID không hợp lệ.");

        } catch (SQLException e) {
            throw new ServletException(
                    "Không thể cập nhật đánh giá hoặc báo cáo.", e);
        }
    }
}
