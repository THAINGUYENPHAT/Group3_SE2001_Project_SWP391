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
            // 1. Láº¤Y NGÃ€Y Báº®T Äáº¦U VÃ€ NGÃ€Y Káº¾T THÃšC
            // =====================================================
            String startDateParam
                    = request.getParameter("startDate");

            String endDateParam
                    = request.getParameter("endDate");

            // =====================================================
            // 2. GIÃ TRá»Š Máº¶C Äá»ŠNH
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
            // 4. KIá»‚M TRA KHOáº¢NG NGÃ€Y
            // =====================================================
            if (endDate.isBefore(startDate)) {

                LocalDate temp
                        = startDate;

                startDate
                        = endDate;

                endDate
                        = temp;

                // Äá»•i láº¡i giÃ¡ trá»‹ hiá»ƒn thá»‹
                startDateParam
                        = startDate.toString();

                endDateParam
                        = endDate.toString();
            }

            // =====================================================
            // 5. Láº¤Y Dá»® LIá»†U REPORT
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
            // 6. Gá»¬I Dá»® LIá»†U SANG JSP
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

            // NgÃ y báº¯t Ä‘áº§u
            request.setAttribute(
                    "startDate",
                    startDateParam
            );

            // NgÃ y káº¿t thÃºc
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
                    "Lá»—i khi táº£i Reporting System!",
                    e
            );

            response.sendRedirect(
                    request.getContextPath()
                    + "/admin/dashboard"
            );
        }
    }
}
