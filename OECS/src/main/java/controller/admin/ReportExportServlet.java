package controller.admin;

import model.SalesReport;
import model.User;
import service.AuditLogService;
import service.ReportService;
import service.ReportService.Range;
import service.ExcelReportExporter;
import service.PdfReportExporter;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.util.Locale;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "ReportExportServlet",
        urlPatterns = "/admin/report/export"
)
public class ReportExportServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ReportExportServlet.class.getName());

    private static final String FONT_REGULAR = "/WEB-INF/fonts/NotoSans-Regular.ttf";
    private static final String FONT_BOLD = "/WEB-INF/fonts/NotoSans-Bold.ttf";

    private final AuditLogService auditLogService = new AuditLogService();
    private final ReportService reportService = new ReportService();
    private final ExcelReportExporter excelExporter = new ExcelReportExporter();
    private final PdfReportExporter pdfExporter = new PdfReportExporter();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {
        String format = request.getParameter("format");
        format = format == null || format.trim().isEmpty()
                ? "excel"
                : format.trim().toLowerCase(Locale.ROOT);

        if (!"excel".equals(format) && !"pdf".equals(format)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Định dạng xuất không hợp lệ.");
            return;
        }

        Range range;
        try {
            range = ReportService.parseRange(
                    request.getParameter("startDate"), request.getParameter("endDate"));
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
            return;
        }

        try {
            SalesReport report = reportService.loadFullReport(range.start, range.end);
            BigDecimal averageOrderValue = ReportService.calculateAverageOrderValue(
                    report.getRevenue(), report.getRevenueOrders());

            boolean pdf = "pdf".equals(format);
            response.setContentType(pdf ? "application/pdf"
                    : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"OECS_BaoCaoKinhDoanh." + (pdf ? "pdf" : "xlsx") + "\"");

            if (pdf) {
                try (InputStream regular = getServletContext().getResourceAsStream(FONT_REGULAR);
                        InputStream bold = getServletContext().getResourceAsStream(FONT_BOLD)) {
                    pdfExporter.write(response.getOutputStream(), range, report, averageOrderValue, regular, bold);
                }
            } else {
                excelExporter.write(response.getOutputStream(), range, report, averageOrderValue);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi xuất báo cáo OECS", e);

            if (!response.isCommitted()) {
                response.reset();
                throw new ServletException("Không thể xuất báo cáo.", e);
            }

            throw new IOException("Lỗi khi xuất báo cáo.", e);
        }
        auditExport(request, format, range);
    }

    private void auditExport(HttpServletRequest request, String format, Range range) {
        try {
            User user = (User) request.getSession().getAttribute("loggedInUser");
            String description = "Exported revenue report as " + format.toUpperCase(Locale.ROOT)
                    + " from " + range.start + " to " + range.end;
            if (!auditLogService.log(user, "EXPORT_REPORT", "REPORT", null, description, request)) {
                LOGGER.log(Level.WARNING, "Không ghi được nhật ký xuất báo cáo.");
            }
        } catch (RuntimeException e) {
            LOGGER.log(Level.WARNING, "Không ghi được nhật ký xuất báo cáo.", e);
        }
    }
}
