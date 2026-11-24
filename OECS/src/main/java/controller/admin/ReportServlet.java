package controller.admin;

import model.SalesReport;
import service.ReportService;
import service.ReportService.Range;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "ReportServlet", urlPatterns = "/admin/report")
public class ReportServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ReportServlet.class.getName());
    private final ReportService reportService = new ReportService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String start = request.getParameter("startDate");
        String end = request.getParameter("endDate");
        String filterError = null;
        Range range = null;
        try {
            range = ReportService.parseRange(start, end);
            start = range.start.toString();
            end = range.end.toString();
        } catch (IllegalArgumentException e) {
            filterError = e.getMessage();
        }

        try {
            SalesReport data = range == null ? new SalesReport()
                    : reportService.loadFullReport(range.start, range.end);
            request.setAttribute("totalRevenue", data.getRevenue());
            request.setAttribute("totalOrders", data.getTotalOrders());
            request.setAttribute("revenueOrders", data.getRevenueOrders());
            request.setAttribute("totalProductsSold", data.getProductsSold());
            request.setAttribute("averageOrderValue",
                    ReportService.calculateAverageOrderValue(data.getRevenue(), data.getRevenueOrders()));
            request.setAttribute("revenueByDate", data.getRevenueByDate());
            request.setAttribute("orderStatusStats", data.getStatuses());
            request.setAttribute("topSellingProducts", data.getTopProducts());
            request.setAttribute("inventory", data.getInventory());
            request.setAttribute("payments", data.getPayments());
            request.setAttribute("startDate", start);
            request.setAttribute("endDate", end);
            request.setAttribute("filterError", filterError);
            request.getRequestDispatcher("/WEB-INF/admin/report.jsp").forward(request, response);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error loading Report page", e);
            throw new ServletException("Cannot load Report page.", e);
        }
    }
}
