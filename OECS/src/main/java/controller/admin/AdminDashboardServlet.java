package controller.admin;

import dao.DashboardDAO;
import model.OrderStatistics;
import service.ReportService;
import service.ReportService.Range;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;

@WebServlet(name = "DashboardServlet", urlPatterns = "/admin/dashboard")
public class AdminDashboardServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        Range range;
        String dateError = null;
        try {
            range = ReportService.parseRange(request.getParameter("startDate"),
                    request.getParameter("endDate"));
        } catch (IllegalArgumentException e) {
            dateError = e.getMessage();
            range = ReportService.parseRange(null, null);
        }

        try {
            boolean byMonth = "month".equals(request.getParameter("groupBy"));
            DashboardDAO dashboardDAO = new DashboardDAO();
            OrderStatistics data = dashboardDAO.getOrderStatistics(range.start, range.end, byMonth);
            Map<String, Integer> stock = dashboardDAO.getCurrentStockStatistics();
            Map<String, Integer> processing = dashboardDAO.getProcessingOrderStatistics();

            request.setAttribute("totalRevenue", data.getRevenue());
            request.setAttribute("totalOrders", data.getTotalOrders());
            request.setAttribute("completedOrders", data.getCompletedOrders());
            request.setAttribute("cancelledOrders", data.getCancelledOrders());
            request.setAttribute("groupBy", byMonth ? "month" : "day");
            request.setAttribute("revenueByDate", data.getRevenueByPeriod());
            processing.forEach(request::setAttribute);
            stock.forEach(request::setAttribute);
            request.setAttribute("topSellingProducts", data.getTopProducts());
            request.setAttribute("lowStockProducts", dashboardDAO.getLowStockProducts());
            request.setAttribute("startDate", range.start.toString());
            request.setAttribute("endDate", range.end.toString());
            request.setAttribute("dateError", dateError);
            request.getRequestDispatcher("/WEB-INF/admin/dashboard.jsp").forward(request, response);
        } catch (IllegalStateException e) {
            throw new ServletException("Không thể tải thống kê Dashboard từ SQL Server.", e);
        }
    }
}
