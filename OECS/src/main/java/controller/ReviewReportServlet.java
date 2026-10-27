package controller;

import dao.ReviewReportDAO;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "ReviewReportServlet", urlPatterns = {"/review/report"})
public class ReviewReportServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        String contextPath = request.getContextPath();
        HttpSession session = request.getSession(false);

        if (session == null
                || !(session.getAttribute("loggedInUser") instanceof User)) {
            response.sendRedirect(contextPath + "/login");
            return;
        }

        User user = (User) session.getAttribute("loggedInUser");

        if (!user.isCustomer()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String expected =
                (String) session.getAttribute("reviewCsrfToken");
        String actual = request.getParameter("csrfToken");

        if (expected == null || !expected.equals(actual)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Phiên làm việc không hợp lệ.");
            return;
        }

        int reviewId;
        int productId;

        try {
            reviewId = Integer.parseInt(request.getParameter("reviewId"));
            productId = Integer.parseInt(request.getParameter("productId"));
        } catch (NumberFormatException e) {
            response.sendRedirect(contextPath + "/shop");
            return;
        }

        String reason = request.getParameter("reason");

        if (reason == null
                || reason.trim().isEmpty()
                || reason.trim().length() > 500) {
            response.sendRedirect(contextPath
                    + "/shop?action=detail&id=" + productId
                    + "&report=INVALID#reviews");
            return;
        }

        try {
            String result = new ReviewReportDAO().createReport(
                    reviewId,
                    user.getUserId(),
                    reason.trim()
            );

            response.sendRedirect(contextPath
                    + "/shop?action=detail&id=" + productId
                    + "&report=" + result + "#reviews");

        } catch (SQLException e) {
            throw new ServletException(
                    "Không thể gửi báo cáo đánh giá.", e
            );
        }
    }
}