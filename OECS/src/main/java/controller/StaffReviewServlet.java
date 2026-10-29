package controller;

import dao.StaffReviewDAO;
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
import java.util.UUID;

@WebServlet(name = "StaffReviewServlet", urlPatterns = {"/staff/reviews"})
public class StaffReviewServlet extends HttpServlet {

    private User getStaff(HttpServletRequest request,
                          HttpServletResponse response)
            throws IOException {

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

        String expected =
                (String) session.getAttribute("reviewCsrfToken");
        String actual = request.getParameter("csrfToken");

        return expected != null && expected.equals(actual);
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        User user = getStaff(request, response);

        if (user == null) {
            return;
        }

        HttpSession session = request.getSession();
        ensureToken(session);

        try {
            StaffReviewDAO reviewDAO = new StaffReviewDAO();
            ReviewReportDAO reportDAO = new ReviewReportDAO();

            request.setAttribute(
                    "reviews", reviewDAO.getAllReviewsForStaff()
            );

            request.setAttribute(
                    "reports", reportDAO.getAllReports()
            );

            request.getRequestDispatcher(
                    "/WEB-INF/review/staff-list.jsp"
            ).forward(request, response);

        } catch (SQLException e) {
            throw new ServletException(
                    "Không thể tải dữ liệu đánh giá.", e
            );
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
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Phiên làm việc không hợp lệ. Vui lòng tải lại trang.");
            return;
        }

        String action = request.getParameter("action");

        try {
            if ("visibility".equals(action)) {
                int reviewId = Integer.parseInt(
                        request.getParameter("reviewId")
                );

                boolean hidden = Boolean.parseBoolean(
                        request.getParameter("hidden")
                );

                new StaffReviewDAO().setReviewHidden(reviewId, hidden);

            } else if ("resolveReport".equals(action)) {
                int reportId = Integer.parseInt(
                        request.getParameter("reportId")
                );

                String decision = request.getParameter("decision");

                new ReviewReportDAO().resolveReport(
                        reportId, user.getUserId(), decision
                );

            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }

            response.sendRedirect(
                    request.getContextPath() + "/staff/reviews"
            );

        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "ID không hợp lệ.");

        } catch (SQLException e) {
            throw new ServletException(
                    "Không thể cập nhật đánh giá hoặc báo cáo.", e
            );
        }
    }
}