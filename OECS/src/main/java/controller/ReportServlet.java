package controller;

import dao.ReportDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "ReportServlet",
        urlPatterns = "/admin/report"
)
public class ReportServlet extends HttpServlet {
    private static final Logger LOGGER =
            Logger.getLogger(ReportServlet.class.getName());

    private static final int DEFAULT_RANGE_DAYS = 30;

    private ReportDAO reportDAO;

    @Override
    public void init() {
        reportDAO = new ReportDAO();
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {
        try {

            String startDateParam =
                    request.getParameter("startDate");

            String endDateParam
                    = request.getParameter("endDate");

            LocalDate defaultEnd = LocalDate.now();

            if (startDateParam == null
                    || startDateParam.trim().isEmpty()) {
                startDateParam = defaultEnd.minusDays(DEFAULT_RANGE_DAYS - 1).toString();
            }

            if (endDateParam == null
                    || endDateParam.trim().isEmpty()) {
                endDateParam = defaultEnd.toString();
            }

            LocalDate startDate = null;
            LocalDate endDate = null;
            String filterError = null;

            try {
                startDate = LocalDate.parse(startDateParam);
                endDate = LocalDate.parse(endDateParam);

                if (startDate.isAfter(endDate)) {
                    filterError
                            = "Start date cannot be after end date.";
                }
            } catch (DateTimeParseException e) {
                filterError
                        = "Invalid date format. Please select valid dates.";
            }

            BigDecimal totalRevenue = BigDecimal.ZERO;
            int completedOrders = 0;
            int totalProductsSold = 0;
            List<Object[]> revenueByDate = Collections.emptyList();
            List<Object[]> orderStatusStats = Collections.emptyList();
            List<Object[]> topSellingProducts = Collections.emptyList();

            if (filterError == null) {
                totalRevenue = reportDAO.getTotalRevenueByRange(startDate, endDate);
                completedOrders = reportDAO.getCompletedOrdersByRange(startDate, endDate);
                totalProductsSold = reportDAO.getTotalProductsSoldByRange(startDate, endDate);
                revenueByDate = reportDAO.getRevenueByDateRange(startDate, endDate);
                orderStatusStats = reportDAO.getOrderStatusByRange(startDate, endDate);
                topSellingProducts = reportDAO.getTopSellingProductsByRange(startDate, endDate);
            }
            BigDecimal averageOrderValue = ReportDAO.calculateAverageOrderValue(totalRevenue, completedOrders);

            request.setAttribute("totalRevenue", totalRevenue);
            request.setAttribute("completedOrders", completedOrders);
            request.setAttribute("totalProductsSold", totalProductsSold);
            request.setAttribute("averageOrderValue", averageOrderValue);
            request.setAttribute("revenueByDate", revenueByDate);
            request.setAttribute("orderStatusStats", orderStatusStats);
            request.setAttribute("topSellingProducts", topSellingProducts);

            request.setAttribute("startDate", startDateParam);

            request.setAttribute("endDate", endDateParam);

            request.setAttribute("filterError", filterError);

            request.getRequestDispatcher("/WEB-INF/admin/report.jsp").forward(request, response);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error loading Report page", e);

            throw new ServletException("Cannot load Report page.", e);
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        doGet(request, response);
    }
}
