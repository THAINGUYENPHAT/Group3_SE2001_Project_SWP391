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
            // 1. LẤY NGÀY BẮT ĐẦU VÀ NGÀY KẾT THÚC
            // =====================================================
            String startDateParam
                    = request.getParameter("startDate");

            String endDateParam
                    = request.getParameter("endDate");

            // =====================================================
            // 2. GIÁ TRỊ MẶC ĐỊNH
            // =====================================================
            if (startDateParam == null
                    || startDateParam.trim().isEmpty()) {

                startDateParam
                        = LocalDate.now().toString();
            }

            if (endDateParam == null
                    || endDateParam.trim().isEmpty()) {

                endDateParam
                        = LocalDate.now().toString();
            }

            // =====================================================
            // 3. PARSE DATE
            // =====================================================
            LocalDate startDate;
            LocalDate endDate;

            try {

                startDate
                        = LocalDate.parse(startDateParam);

                endDate
                        = LocalDate.parse(endDateParam);

            } catch (Exception e) {

                startDate
                        = LocalDate.now();

                endDate
                        = LocalDate.now();

                startDateParam
                        = startDate.toString();

                endDateParam
                        = endDate.toString();
            }

            // =====================================================
            // 4. KIỂM TRA KHOẢNG NGÀY
            // =====================================================
            if (endDate.isBefore(startDate)) {

                LocalDate temp
                        = startDate;

                startDate
                        = endDate;

                endDate
                        = temp;

                // Đổi lại giá trị hiển thị
                startDateParam
                        = startDate.toString();

                endDateParam
                        = endDate.toString();
            }

            // =====================================================
            // 5. LẤY DỮ LIỆU REPORT
            // =====================================================
            BigDecimal totalRevenue
                    = reportDAO.getTotalRevenueByRange(
                            startDate,
                            endDate
                    );

            int completedOrders
                    = reportDAO.getCompletedOrdersByRange(
                            startDate,
                            endDate
                    );

            int totalProductsSold
                    = reportDAO.getTotalProductsSoldByRange(
                            startDate,
                            endDate
                    );

            List<Object[]> revenueByDate
                    = reportDAO.getRevenueByDateRange(
                            startDate,
                            endDate
                    );

            // =====================================================
            // 6. GỬI DỮ LIỆU SANG JSP
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

            // Ngày bắt đầu
            request.setAttribute(
                    "startDate",
                    startDateParam
            );

            // Ngày kết thúc
            request.setAttribute(
                    "endDate",
                    endDateParam
            );

            // =====================================================
            // 7. FORWARD SANG JSP
            // =====================================================
            request.getRequestDispatcher(
                    "/WEB-INF/admin/report.jsp"
            ).forward(
                    request,
                    response
            );

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
