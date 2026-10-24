package controller.admin;

import dao.DashboardDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

@WebServlet(name = "DashboardServlet", urlPatterns = "/admin/dashboard")
public class AdminDashboardServlet extends HttpServlet {

    private DashboardDAO dashboardDAO;

    @Override
    public void init() {
        dashboardDAO = new DashboardDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("totalRevenue",
                dashboardDAO.getTotalRevenue());

        request.setAttribute("totalOrders",
                dashboardDAO.getTotalOrders());

        request.setAttribute("completedOrders",
                dashboardDAO.getCompletedOrders());

        request.setAttribute("totalProductsSold",
                dashboardDAO.getTotalProductsSold());

        // Top 5 sản phẩm bán chạy
        request.setAttribute("topSellingProducts",
                dashboardDAO.getTopSellingProducts());

        // Thống kê trạng thái đơn hàng
        List<Object[]> statistics
                = dashboardDAO.getOrderStatusStatistics();

        request.setAttribute("orderStatusStatistics", statistics);

        int pendingOrders = 0;
        int cancelledOrders = 0;

        for (Object[] row : statistics) {
            String status = row[0] == null
                    ? ""
                    : row[0].toString().trim().toUpperCase();

            int count = ((Number) row[1]).intValue();

            if ("PENDING_CONFIRMATION".equals(status)) {
                pendingOrders += count;
            } else if ("CANCELLED".equals(status)) {
                cancelledOrders += count;
            }
        }

        request.setAttribute("pendingOrders", pendingOrders);
        request.setAttribute("cancelledOrders", cancelledOrders);

        // Biểu đồ doanh thu
        String startDateText = request.getParameter("startDate");
        String endDateText = request.getParameter("endDate");

        java.time.LocalDate startDate = null;
        java.time.LocalDate endDate = null;

        String dateError = null;

        if (startDateText != null && !startDateText.isBlank()
                && endDateText != null && !endDateText.isBlank()) {

            try {
                startDate = java.time.LocalDate.parse(startDateText);
                endDate = java.time.LocalDate.parse(endDateText);

                if (startDate.isAfter(endDate)) {
                    dateError = "Ngày bắt đầu không được lớn hơn ngày kết thúc.";
                }

            } catch (java.time.format.DateTimeParseException ex) {
                dateError = "Ngày được chọn không hợp lệ.";
            }

        } else if ((startDateText != null && !startDateText.isBlank())
                || (endDateText != null && !endDateText.isBlank())) {

            dateError = "Vui lòng chọn đầy đủ cả hai ngày.";
        }

        request.setAttribute("startDate", startDateText);
        request.setAttribute("endDate", endDateText);
        request.setAttribute("dateError", dateError);

        if (dateError == null && startDate != null) {
            request.setAttribute("revenueByDate",
                    dashboardDAO.getRevenueByDateRange(startDate, endDate));
        } else {
            request.setAttribute("revenueByDate",
                    dashboardDAO.getRevenueByDate());
        }

        request.getRequestDispatcher(
                "/WEB-INF/admin/dashboard.jsp"
        ).forward(request, response);
    }

}
