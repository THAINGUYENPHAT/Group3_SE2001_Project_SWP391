package controller;

import dao.ReportDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@WebServlet(
        name = "ReportExportServlet",
        urlPatterns = "/admin/report/export"
)
public class ReportExportServlet extends HttpServlet {

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

        String type = request.getParameter("type");
        String dateParam = request.getParameter("date");
        String format = request.getParameter("format");

        // ==============================
        // DEFAULT
        // ==============================
        if (type == null || type.trim().isEmpty()) {
            type = "day";
        }

        if (format == null || format.trim().isEmpty()) {
            format = "excel";
        }

        // ==============================
        // PARSE DATE
        // ==============================
        LocalDate selectedDate;

        try {
            selectedDate = LocalDate.parse(dateParam);
        } catch (Exception e) {
            selectedDate = LocalDate.now();
        }

        // ==============================
        // VARIABLES
        // ==============================
        BigDecimal totalRevenue;
        int completedOrders;
        int totalProductsSold;
        List<Object[]> revenueByDate;

        // ==============================
        // GET REPORT DATA
        // ==============================
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

        // ==============================
        // EXPORT
        // ==============================
        if ("pdf".equalsIgnoreCase(format)) {

            exportPdf(
                    response,
                    type,
                    selectedDate,
                    totalRevenue,
                    completedOrders,
                    totalProductsSold,
                    revenueByDate
            );

        } else {

            exportExcel(
                    response,
                    type,
                    selectedDate,
                    totalRevenue,
                    completedOrders,
                    totalProductsSold,
                    revenueByDate
            );
        }
    }

    // ============================================================
    // EXPORT EXCEL
    // ============================================================
    private void exportExcel(
            HttpServletResponse response,
            String type,
            LocalDate selectedDate,
            BigDecimal totalRevenue,
            int completedOrders,
            int totalProductsSold,
            List<Object[]> revenueByDate)
            throws IOException {

        response.setContentType(
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        );

        response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"OECS_Report.xlsx\""
        );

        try (Workbook workbook = new XSSFWorkbook()) {

            Sheet sheet
                    = workbook.createSheet("Revenue Report");

            // ==============================
            // TITLE STYLE
            // ==============================
            Font titleFont
                    = workbook.createFont();

            titleFont.setBold(true);
            titleFont.setFontHeightInPoints((short) 16);

            CellStyle titleStyle
                    = workbook.createCellStyle();

            titleStyle.setFont(titleFont);

            // ==============================
            // HEADER STYLE
            // ==============================
            Font headerFont
                    = workbook.createFont();

            headerFont.setBold(true);
            headerFont.setColor(
                    IndexedColors.WHITE.getIndex()
            );

            CellStyle headerStyle
                    = workbook.createCellStyle();

            headerStyle.setFont(headerFont);

            headerStyle.setFillForegroundColor(
                    IndexedColors.DARK_BLUE.getIndex()
            );

            headerStyle.setFillPattern(
                    FillPatternType.SOLID_FOREGROUND
            );

            // ==============================
            // TITLE
            // ==============================
            Row titleRow
                    = sheet.createRow(0);

            Cell titleCell
                    = titleRow.createCell(0);

            titleCell.setCellValue(
                    "OECS - REVENUE REPORT"
            );

            titleCell.setCellStyle(titleStyle);

            // ==============================
            // REPORT INFORMATION
            // ==============================
            Row typeRow
                    = sheet.createRow(2);

            typeRow.createCell(0)
                    .setCellValue("Report Type");

            typeRow.createCell(1)
                    .setCellValue(
                            getReportTypeName(type)
                    );

            Row dateRow
                    = sheet.createRow(3);

            dateRow.createCell(0)
                    .setCellValue("Reference Date");

            dateRow.createCell(1)
                    .setCellValue(
                            selectedDate.toString()
                    );

            // ==============================
            // KPI
            // ==============================
            Row revenueRow
                    = sheet.createRow(5);

            revenueRow.createCell(0)
                    .setCellValue("Total Revenue");

            revenueRow.createCell(1)
                    .setCellValue(
                            totalRevenue.doubleValue()
                    );

            Row orderRow
                    = sheet.createRow(6);

            orderRow.createCell(0)
                    .setCellValue("Completed Orders");

            orderRow.createCell(1)
                    .setCellValue(
                            completedOrders
                    );

            Row productRow
                    = sheet.createRow(7);

            productRow.createCell(0)
                    .setCellValue("Products Sold");

            productRow.createCell(1)
                    .setCellValue(
                            totalProductsSold
                    );

            // ==============================
            // TABLE HEADER
            // ==============================
            Row headerRow
                    = sheet.createRow(9);

            String[] headers = {
                "Date",
                "Revenue",
                "Order Count"
            };

            for (int i = 0;
                    i < headers.length;
                    i++) {

                Cell cell
                        = headerRow.createCell(i);

                cell.setCellValue(
                        headers[i]
                );

                cell.setCellStyle(
                        headerStyle
                );
            }

            // ==============================
            // TABLE DATA
            // ==============================
            int rowIndex = 10;

            for (Object[] row : revenueByDate) {

                Row excelRow
                        = sheet.createRow(rowIndex++);

                // Date
                excelRow.createCell(0)
                        .setCellValue(
                                row[0] == null
                                        ? ""
                                        : row[0].toString()
                        );

                // Revenue
                BigDecimal revenue
                        = row[1] == null
                                ? BigDecimal.ZERO
                                : (BigDecimal) row[1];

                excelRow.createCell(1)
                        .setCellValue(
                                revenue.doubleValue()
                        );

                // Orders
                int orders
                        = row[2] == null
                                ? 0
                                : ((Number) row[2])
                                        .intValue();

                excelRow.createCell(2)
                        .setCellValue(
                                orders
                        );
            }

            // ==============================
            // AUTO SIZE
            // ==============================
            sheet.autoSizeColumn(0);
            sheet.autoSizeColumn(1);
            sheet.autoSizeColumn(2);

            // ==============================
            // WRITE FILE
            // ==============================
            workbook.write(
                    response.getOutputStream()
            );
        }
    }

    // ============================================================
    // EXPORT PDF
    // ============================================================
    private void exportPdf(
            HttpServletResponse response,
            String type,
            LocalDate selectedDate,
            BigDecimal totalRevenue,
            int completedOrders,
            int totalProductsSold,
            List<Object[]> revenueByDate)
            throws IOException {

        response.setContentType(
                "application/pdf"
        );

        response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"OECS_Report.pdf\""
        );

        try (PDDocument document
                = new PDDocument()) {

            // ==============================
            // FONT
            // ==============================
            PDType1Font boldFont
                    = new PDType1Font(
                            Standard14Fonts.FontName.HELVETICA_BOLD
                    );

            PDType1Font normalFont
                    = new PDType1Font(
                            Standard14Fonts.FontName.HELVETICA
                    );

            // ==============================
            // DATA INDEX
            // ==============================
            int rowIndex = 0;

            boolean firstPage = true;

            // ==============================
            // CREATE PAGES
            // ==============================
            do {

                PDPage page
                        = new PDPage(
                                PDRectangle.A4
                        );

                document.addPage(page);

                try (PDPageContentStream content
                        = new PDPageContentStream(
                                document,
                                page
                        )) {

                    float y = 770;

                    // ==========================================
                    // FIRST PAGE INFORMATION
                    // ==========================================
                    if (firstPage) {

                        // ---------- TITLE ----------
                        content.beginText();

                        content.setFont(
                                boldFont,
                                18
                        );

                        content.newLineAtOffset(
                                50,
                                y
                        );

                        content.showText(
                                "OECS - REVENUE REPORT"
                        );

                        content.endText();

                        y -= 35;

                        // ---------- REPORT TYPE ----------
                        content.beginText();

                        content.setFont(
                                normalFont,
                                11
                        );

                        content.newLineAtOffset(
                                50,
                                y
                        );

                        content.showText(
                                "Report Type: "
                                + getReportTypeName(type)
                        );

                        content.newLineAtOffset(
                                0,
                                -18
                        );

                        content.showText(
                                "Reference Date: "
                                + selectedDate.toString()
                        );

                        content.endText();

                        y -= 55;

                        // ---------- SUMMARY ----------
                        content.beginText();

                        content.setFont(
                                boldFont,
                                12
                        );

                        content.newLineAtOffset(
                                50,
                                y
                        );

                        content.showText(
                                "SUMMARY"
                        );

                        content.endText();

                        y -= 22;

                        // ---------- KPI ----------
                        content.beginText();

                        content.setFont(
                                normalFont,
                                11
                        );

                        content.newLineAtOffset(
                                50,
                                y
                        );

                        content.showText(
                                "Total Revenue: "
                                + totalRevenue.toPlainString()
                                + " VND"
                        );

                        content.newLineAtOffset(
                                0,
                                -18
                        );

                        content.showText(
                                "Completed Orders: "
                                + completedOrders
                        );

                        content.newLineAtOffset(
                                0,
                                -18
                        );

                        content.showText(
                                "Products Sold: "
                                + totalProductsSold
                        );

                        content.endText();

                        y -= 65;

                        firstPage = false;

                    } else {

                        // Trang tiếp theo
                        y = 770;
                    }

                    // ==========================================
                    // TABLE HEADER
                    // ==========================================
                    content.beginText();

                    content.setFont(
                            boldFont,
                            11
                    );

                    content.newLineAtOffset(
                            50,
                            y
                    );

                    content.showText(
                            "Date"
                    );

                    content.newLineAtOffset(
                            180,
                            0
                    );

                    content.showText(
                            "Revenue"
                    );

                    content.newLineAtOffset(
                            180,
                            0
                    );

                    content.showText(
                            "Orders"
                    );

                    content.endText();

                    y -= 20;

                    // ==========================================
                    // TABLE DATA
                    // ==========================================
                    while (rowIndex < revenueByDate.size()
                            && y > 50) {

                        Object[] row
                                = revenueByDate.get(
                                        rowIndex
                                );

                        String date
                                = row[0] == null
                                        ? ""
                                        : row[0].toString();

                        BigDecimal revenue
                                = row[1] == null
                                        ? BigDecimal.ZERO
                                        : (BigDecimal) row[1];

                        int orders
                                = row[2] == null
                                        ? 0
                                        : ((Number) row[2])
                                                .intValue();

                        content.beginText();

                        content.setFont(
                                normalFont,
                                10
                        );

                        content.newLineAtOffset(
                                50,
                                y
                        );

                        content.showText(
                                date
                        );

                        content.newLineAtOffset(
                                180,
                                0
                        );

                        content.showText(
                                revenue.toPlainString()
                        );

                        content.newLineAtOffset(
                                180,
                                0
                        );

                        content.showText(
                                String.valueOf(
                                        orders
                                )
                        );

                        content.endText();

                        y -= 18;

                        rowIndex++;
                    }
                }

            } while (rowIndex < revenueByDate.size());

            // ==============================
            // SAVE PDF
            // ==============================
            document.save(
                    response.getOutputStream()
            );
        }
    }

    // ============================================================
    // REPORT TYPE NAME
    // ============================================================
    private String getReportTypeName(
            String type) {

        switch (type) {

            case "week":
                return "By Week";

            case "month":
                return "By Month";

            case "year":
                return "By Year";

            default:
                return "By Day";
        }
    }
}
