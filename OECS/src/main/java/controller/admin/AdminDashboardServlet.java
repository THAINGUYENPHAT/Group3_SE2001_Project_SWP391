package controller.admin;

import dao.DashboardDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

@WebServlet(
        name = "DashboardServlet",
        urlPatterns = "/admin/dashboard"
)
public class AdminDashboardServlet extends HttpServlet {

    private DashboardDAO dashboardDAO;

    @Override
    public void init() {
        dashboardDAO = new DashboardDAO();
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(29);

        String startParam = request.getParameter("startDate");
        String endParam = request.getParameter("endDate");

        String dateError = null;

        boolean hasStart
                = startParam != null && !startParam.isBlank();

        boolean hasEnd
                = endParam != null && !endParam.isBlank();

       
        if (hasStart || hasEnd) {

            if (!hasStart || !hasEnd) {

                dateError
                        = "Vui lòng chọn đầy đủ ngày bắt đầu "
                        + "và ngày kết thúc.";

            } else {

                try {
                    LocalDate selectedStart
                            = LocalDate.parse(startParam);

                    LocalDate selectedEnd
                            = LocalDate.parse(endParam);

                    if (selectedStart.isAfter(selectedEnd)) {

                        dateError
                                = "Ngày bắt đầu không được lớn hơn "
                                + "ngày kết thúc.";

                    } else {

                        startDate = selectedStart;
                        endDate = selectedEnd;
                    }

                } catch (DateTimeParseException ex) {

                    dateError
                            = "Ngày được chọn không hợp lệ.";
                }
            }
        }

        try {
           
            request.setAttribute(
                    "totalRevenue",
                    dashboardDAO.getTotalRevenueByRange(
                            startDate, endDate
                    )
            );

            request.setAttribute(
                    "totalOrders",
                    dashboardDAO.getTotalOrdersByRange(
                            startDate, endDate
                    )
            );

            request.setAttribute(
                    "completedOrders",
                    dashboardDAO.getCompletedOrdersByRange(
                            startDate, endDate
                    )
            );

            request.setAttribute(
                    "cancelledOrders",
                    dashboardDAO.getCancelledOrdersByRange(
                            startDate, endDate
                    )
            );

            request.setAttribute(
                    "revenueByDate",
                    dashboardDAO.getRevenueByDateRange(
                            startDate, endDate
                    )
            );

            request.setAttribute(
                    "orderStatusStatistics",
                    dashboardDAO.getOrderStatusByRange(
                            startDate, endDate
                    )
            );

            
            request.setAttribute(
                    "topSellingProducts",
                    dashboardDAO.getTopSellingProductsByRange(
                            startDate, endDate
                    )
            );

           
            int[] stock
                    = dashboardDAO.getCurrentStockStatistics();

            request.setAttribute("stockAvailable", stock[0]);
            request.setAttribute("stockLow", stock[1]);
            request.setAttribute("stockOut", stock[2]);

            request.setAttribute(
                    "lowStockProducts",
                    dashboardDAO.getLowStockProducts()
            );

            request.setAttribute(
                    "totalSku",
                    stock[0] + stock[1] + stock[2]
            );

            
            request.setAttribute(
                    "startDate", startDate.toString()
            );

            request.setAttribute(
                    "endDate", endDate.toString()
            );

            request.setAttribute(
                    "dateError", dateError
            );

            request.getRequestDispatcher(
                    "/WEB-INF/admin/dashboard.jsp"
            ).forward(request, response);

        } catch (IllegalStateException ex) {

            throw new ServletException(
                    "Không thể tải thống kê Dashboard "
                    + "từ SQL Server.",
                    ex
            );
        }
    }
}
