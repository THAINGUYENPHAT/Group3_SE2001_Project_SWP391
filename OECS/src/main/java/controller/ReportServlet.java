package controller;

import dao.ReportDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "ReportServlet",
        urlPatterns = "/admin/report"
)
public class ReportServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(ReportServlet.class.getName());

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

            // =====================================================
            // 1. LẤY FILTER
            // =====================================================
            String type = request.getParameter("type");
            String dateParam = request.getParameter("date");

            // Mặc định
            if (type == null || type.trim().isEmpty()) {
                type = "day";
            }

            if (dateParam == null || dateParam.trim().isEmpty()) {
                dateParam = LocalDate.now().toString();
            }

            LocalDate selectedDate;

            try {
                selectedDate = LocalDate.parse(dateParam);
            } catch (Exception e) {
                selectedDate = LocalDate.now();
                dateParam = selectedDate.toString();
            }

            // =====================================================
            // 2. BIẾN KẾT QUẢ
            // =====================================================
            BigDecimal totalRevenue;
            int completedOrders;
            int totalProductsSold;
            List<Object[]> revenueByDate;

            // =====================================================
            // 3. FILTER THEO TYPE
            // =====================================================
            switch (type) {

                case "week":

                    totalRevenue
                            = reportDAO.getTotalRevenueByWeek(selectedDate);

                    completedOrders
                            = reportDAO.getCompletedOrdersByWeek(selectedDate);

                    totalProductsSold
                            = reportDAO.getTotalProductsSoldByWeek(selectedDate);

                    revenueByDate
                            = reportDAO.getRevenueByWeek(selectedDate);

                    break;

                case "month":

                    totalRevenue
                            = reportDAO.getTotalRevenueByMonth(selectedDate);

                    completedOrders
                            = reportDAO.getCompletedOrdersByMonth(selectedDate);

                    totalProductsSold
                            = reportDAO.getTotalProductsSoldByMonth(selectedDate);

                    revenueByDate
                            = reportDAO.getRevenueByMonth(selectedDate);

                    break;

                case "year":

                    totalRevenue
                            = reportDAO.getTotalRevenueByYear(selectedDate);

                    completedOrders
                            = reportDAO.getCompletedOrdersByYear(selectedDate);

                    totalProductsSold
                            = reportDAO.getTotalProductsSoldByYear(selectedDate);

                    revenueByDate
                            = reportDAO.getRevenueByYear(selectedDate);

                    break;

                case "day":

                default:

                    type = "day";

                    totalRevenue
                            = reportDAO.getTotalRevenueByDay(selectedDate);

                    completedOrders
                            = reportDAO.getCompletedOrdersByDay(selectedDate);

                    totalProductsSold
                            = reportDAO.getTotalProductsSoldByDay(selectedDate);

                    revenueByDate
                            = reportDAO.getRevenueByDay(selectedDate);

                    break;
            }

            // =====================================================
            // 4. GỬI DỮ LIỆU SANG JSP
            // =====================================================
            request.setAttribute(
                    "totalRevenue",
                    totalRevenue
            );

            request.setAttribute(
                    "completedOrders",
                    completedOrders
            );

            request.setAttribute(
                    "totalProductsSold",
                    totalProductsSold
            );

            request.setAttribute(
                    "revenueByDate",
                    revenueByDate
            );

            // Filter hiện tại
            request.setAttribute(
                    "selectedType",
                    type
            );

            request.setAttribute(
                    "selectedDate",
                    dateParam
            );

            // =====================================================
            // 5. FORWARD SANG JSP
            // =====================================================
            request.getRequestDispatcher(
                    "/WEB-INF/admin/report.jsp"
            ).forward(request, response);

        } catch (Exception e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi khi tải Reporting System!",
                    e
            );

            response.sendRedirect(
                    request.getContextPath()
                    + "/admin/dashboard"
            );
        }
    }
}
