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

        // =====================================================
        // 1. GET PARAMETERS
        // =====================================================
        String startDateParam
                = request.getParameter("startDate");

        String endDateParam
                = request.getParameter("endDate");

        String format
                = request.getParameter("format");

        // =====================================================
        // 2. DEFAULT FORMAT
        // =====================================================
        if (format == null
                || format.trim().isEmpty()) {

            format = "excel";
        }

        // =====================================================
        // 3. DEFAULT DATE
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
        // 4. PARSE DATE
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
        }

        // =====================================================
        // 5. FIX INVALID RANGE
        // =====================================================
        if (endDate.isBefore(startDate)) {

            LocalDate temp
                    = startDate;

            startDate
                    = endDate;

            endDate
                    = temp;
        }

        // =====================================================
        // 6. GET REPORT DATA
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
        // 7. EXPORT
        // =====================================================
        if ("pdf".equalsIgnoreCase(format)) {

            exportPdf(
                    response,
                    startDate,
                    endDate,
                    totalRevenue,
                    completedOrders,
                    totalProductsSold,
                    revenueByDate
            );

        } else {

            exportExcel(
                    response,
                    startDate,
                    endDate,
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
            LocalDate startDate,
            LocalDate endDate,
            BigDecimal totalRevenue,
            int completedOrders,
            int totalProductsSold,
            List<Object[]> revenueByDate)
            throws IOException {

        // =====================================================
        // RESPONSE
        // =====================================================
        response.setContentType(
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        );

        response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"OECS_Report.xlsx\""
        );

        // =====================================================
        // CREATE WORKBOOK
        // =====================================================
        try (Workbook workbook
                = new XSSFWorkbook()) {

            Sheet sheet
                    = workbook.createSheet(
                            "Revenue Report"
                    );

            // =================================================
            // TITLE STYLE
            // =================================================
            Font titleFont
                    = workbook.createFont();

            titleFont.setBold(true);

            titleFont.setFontHeightInPoints(
                    (short) 16
            );

            CellStyle titleStyle
                    = workbook.createCellStyle();

            titleStyle.setFont(
                    titleFont
            );

            // =================================================
            // HEADER STYLE
            // =================================================
            Font headerFont
                    = workbook.createFont();

            headerFont.setBold(true);

            headerFont.setColor(
                    IndexedColors.WHITE.getIndex()
            );

            CellStyle headerStyle
                    = workbook.createCellStyle();

            headerStyle.setFont(
                    headerFont
            );

            headerStyle.setFillForegroundColor(
                    IndexedColors.DARK_BLUE.getIndex()
            );

            headerStyle.setFillPattern(
                    FillPatternType.SOLID_FOREGROUND
            );

            // =================================================
            // TITLE
            // =================================================
            Row titleRow
                    = sheet.createRow(0);

            Cell titleCell
                    = titleRow.createCell(0);

            titleCell.setCellValue(
                    "OECS - REVENUE REPORT"
            );

            titleCell.setCellStyle(
                    titleStyle
            );

            // =================================================
            // DATE RANGE
            // =================================================
            Row startRow
                    = sheet.createRow(2);

            startRow.createCell(0)
                    .setCellValue(
                            "Start Date"
                    );

            startRow.createCell(1)
                    .setCellValue(
                            startDate.toString()
                    );

            Row endRow
                    = sheet.createRow(3);

            endRow.createCell(0)
                    .setCellValue(
                            "End Date"
                    );

            endRow.createCell(1)
                    .setCellValue(
                            endDate.toString()
                    );

            // =================================================
            // KPI
            // =================================================
            Row revenueRow
                    = sheet.createRow(5);

            revenueRow.createCell(0)
                    .setCellValue(
                            "Total Revenue"
                    );

            revenueRow.createCell(1)
                    .setCellValue(
                            totalRevenue.doubleValue()
                    );

            Row orderRow
                    = sheet.createRow(6);

            orderRow.createCell(0)
                    .setCellValue(
                            "Completed Orders"
                    );

            orderRow.createCell(1)
                    .setCellValue(
                            completedOrders
                    );

            Row productRow
                    = sheet.createRow(7);

            productRow.createCell(0)
                    .setCellValue(
                            "Products Sold"
                    );

            productRow.createCell(1)
                    .setCellValue(
                            totalProductsSold
                    );

            // =================================================
            // TABLE HEADER
            // =================================================
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

            // =================================================
            // TABLE DATA
            // =================================================
            int rowIndex = 10;

            for (Object[] row
                    : revenueByDate) {

                Row excelRow
                        = sheet.createRow(
                                rowIndex++
                        );

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

            // =================================================
            // AUTO SIZE
            // =================================================
            sheet.autoSizeColumn(0);
            sheet.autoSizeColumn(1);
            sheet.autoSizeColumn(2);

            // =================================================
            // WRITE
            // =================================================
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
            LocalDate startDate,
            LocalDate endDate,
            BigDecimal totalRevenue,
            int completedOrders,
            int totalProductsSold,
            List<Object[]> revenueByDate)
            throws IOException {

        // =====================================================
        // RESPONSE
        // =====================================================
        response.setContentType(
                "application/pdf"
        );

        response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"OECS_Report.pdf\""
        );

        // =====================================================
        // CREATE PDF
        // =====================================================
        try (PDDocument document
                = new PDDocument()) {

            PDType1Font boldFont
                    = new PDType1Font(
                            Standard14Fonts.FontName.HELVETICA_BOLD
                    );

            PDType1Font normalFont
                    = new PDType1Font(
                            Standard14Fonts.FontName.HELVETICA
                    );

            int rowIndex = 0;

            boolean firstPage = true;

            // =================================================
            // CREATE PAGE
            // =================================================
            do {

                PDPage page
                        = new PDPage(
                                PDRectangle.A4
                        );

                document.addPage(
                        page
                );

                try (
                        PDPageContentStream content
                        = new PDPageContentStream(
                                document,
                                page
                        )) {

                    float y = 770;

                    // =========================================
                    // FIRST PAGE
                    // =========================================
                    if (firstPage) {

                        // TITLE
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

                        // DATE RANGE
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
                                "Start Date: "
                                + startDate.toString()
                        );

                        content.newLineAtOffset(
                                0,
                                -18
                        );

                        content.showText(
                                "End Date: "
                                + endDate.toString()
                        );

                        content.endText();

                        y -= 55;

                        // SUMMARY
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

                        // KPI
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

                        y = 770;
                    }

                    // =========================================
                    // TABLE HEADER
                    // =========================================
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

                    // =========================================
                    // TABLE DATA
                    // =========================================
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

            // =================================================
            // SAVE PDF
            // =================================================
            document.save(
                    response.getOutputStream()
            );
        }
    }
}
