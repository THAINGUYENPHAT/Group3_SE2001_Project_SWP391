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
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // KPI
        request.setAttribute("totalRevenue", dashboardDAO.getTotalRevenue());
        request.setAttribute("totalOrders", dashboardDAO.getTotalOrders());
        request.setAttribute("completedOrders", dashboardDAO.getCompletedOrders());
        request.setAttribute("topSellingProducts", dashboardDAO.getTopSellingProducts());
        request.setAttribute("orderStatusStatistics", dashboardDAO.getOrderStatusStatistics());

        // Revenue by date
        List<Object[]> revenueByDate = dashboardDAO.getRevenueByDate();
        request.setAttribute("revenueByDate", revenueByDate);

        // Chuyển sang JSP
        request.getRequestDispatcher("/WEB-INF/admin/dashboard.jsp").forward(request, response);
    }
}