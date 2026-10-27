package controller;

import dao.ReportDAO;
import model.User;
import service.AuditLogService;

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
import org.apache.pdfbox.pdmodel.font.PDType0Font;

import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.sql.Date;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "ReportExportServlet",
        urlPatterns = "/admin/report/export"
)
public class ReportExportServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(ReportExportServlet.class.getName());

    private static final DateTimeFormatter DATE_FORMAT
            = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private static final String FONT_REGULAR
            = "/WEB-INF/fonts/NotoSans-Regular.ttf";

    private static final String FONT_BOLD
            = "/WEB-INF/fonts/NotoSans-Bold.ttf";

    private ReportDAO reportDAO;

    private final AuditLogService auditLogService
            = new AuditLogService();

    @Override
    public void init() {
        reportDAO = new ReportDAO();
    }

    // =====================================================
    // 1. XỬ LÝ YÊU CẦU XUẤT BÁO CÁO
    // =====================================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String startParam
                = request.getParameter("startDate");

        String endParam
                = request.getParameter("endDate");

        String format
                = request.getParameter("format");

        if (format == null || format.trim().isEmpty()) {
            format = "excel";
        }

        if (!format.equalsIgnoreCase("excel")
                && !format.equalsIgnoreCase("pdf")) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Định dạng báo cáo không hợp lệ."
            );
            return;
        }

        String today = LocalDate.now().toString();

        if (startParam == null
                || startParam.trim().isEmpty()) {
            startParam = today;
        }

        if (endParam == null
                || endParam.trim().isEmpty()) {
            endParam = today;
        }

        LocalDate startDate;
        LocalDate endDate;

        try {
            startDate = LocalDate.parse(startParam);
            endDate = LocalDate.parse(endParam);

        } catch (DateTimeParseException e) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Ngày không hợp lệ."
            );
            return;
        }

        if (startDate.isAfter(endDate)) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Ngày bắt đầu không được lớn hơn ngày kết thúc."
            );
            return;
        }

        try {
            ReportData data = loadReportData(
                    startDate, endDate
            );
            String exportFormat;
            if (format.equalsIgnoreCase("pdf")) {

                exportPdf(
                        response,
                        startDate,
                        endDate,
                        data
                );
                exportFormat = "PDF";

            } else {

                exportExcel(
                        response,
                        startDate,
                        endDate,
                        data
                );
                exportFormat = "EXCEL";
            }
            User loggedInUser
                    = (User) request.getSession()
                            .getAttribute("loggedInUser");

            auditLogService.log(
                    loggedInUser,
                    "EXPORT_REPORT",
                    "REPORT",
                    null,
                    "Exported revenue report as "
                    + exportFormat
                    + " from "
                    + startDate
                    + " to "
                    + endDate,
                    request
            );

        } catch (Exception e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi xuất báo cáo OECS",
                    e
            );

            if (!response.isCommitted()) {
                response.reset();
                throw new ServletException(
                        "Không thể xuất báo cáo.", e
                );
            }

            throw new IOException(
                    "Lỗi khi xuất báo cáo.", e
            );

        }

    }

    // =====================================================
    // 2. LẤY DỮ LIỆU TỪ REPORT DAO
    // =====================================================
    private static class ReportData {

        BigDecimal totalRevenue;
        int completedOrders;
        int totalProductsSold;
        BigDecimal averageOrderValue;

        List<Object[]> revenueByDate;
        List<Object[]> orderStatusStats;
        List<Object[]> topSellingProducts;
    }

    private ReportData loadReportData(
            LocalDate startDate,
            LocalDate endDate) {

        ReportData data = new ReportData();

        data.totalRevenue
                = reportDAO.getTotalRevenueByRange(
                        startDate, endDate
                );

        data.completedOrders
                = reportDAO.getCompletedOrdersByRange(
                        startDate, endDate
                );

        data.totalProductsSold
                = reportDAO.getTotalProductsSoldByRange(
                        startDate, endDate
                );

        data.averageOrderValue
                = reportDAO.getAverageOrderValueByRange(
                        startDate, endDate
                );

        data.revenueByDate
                = reportDAO.getRevenueByDateRange(
                        startDate, endDate
                );

        data.orderStatusStats
                = reportDAO.getOrderStatusByRange(
                        startDate, endDate
                );

        data.topSellingProducts
                = reportDAO.getTopSellingProductsByRange(
                        startDate, endDate
                );

        return data;
    }

    // =====================================================
    // 3. XUẤT EXCEL TIẾNG VIỆT
    // =====================================================
    private void exportExcel(
            HttpServletResponse response,
            LocalDate startDate,
            LocalDate endDate,
            ReportData data) throws IOException {

        try (Workbook workbook = new XSSFWorkbook()) {

            Sheet sheet
                    = workbook.createSheet("Bao cao kinh doanh");

            // ---------- FONT TIẾNG VIỆT ----------
            org.apache.poi.ss.usermodel.Font titleFont
                    = workbook.createFont();

            titleFont.setBold(true);
            titleFont.setFontName("Arial");
            titleFont.setFontHeightInPoints((short) 17);
            titleFont.setColor(
                    IndexedColors.DARK_BLUE.getIndex()
            );

            CellStyle titleStyle
                    = workbook.createCellStyle();

            titleStyle.setFont(titleFont);

            org.apache.poi.ss.usermodel.Font headerFont
                    = workbook.createFont();

            headerFont.setBold(true);
            headerFont.setFontName("Arial");
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

            headerStyle.setVerticalAlignment(
                    VerticalAlignment.CENTER
            );

            CellStyle moneyStyle
                    = workbook.createCellStyle();

            moneyStyle.setDataFormat(
                    workbook.createDataFormat()
                            .getFormat("#,##0.##")
            );

            CellStyle percentStyle
                    = workbook.createCellStyle();

            percentStyle.setDataFormat(
                    workbook.createDataFormat()
                            .getFormat("0.0%")
            );

            int row = 0;

            // ---------- TIÊU ĐỀ ----------
            Row titleRow = sheet.createRow(row++);
            titleRow.setHeightInPoints(32);

            Cell titleCell = titleRow.createCell(0);

            titleCell.setCellValue(
                    "OECS - BÁO CÁO KINH DOANH"
            );

            titleCell.setCellStyle(titleStyle);

            row++;

            addTextRow(
                    sheet, row++,
                    "Ngày bắt đầu",
                    startDate.format(DATE_FORMAT)
            );

            addTextRow(
                    sheet, row++,
                    "Ngày kết thúc",
                    endDate.format(DATE_FORMAT)
            );

            row++;

            // ---------- TỔNG QUAN ----------
            row = addSection(
                    sheet, row, headerStyle,
                    "TỔNG QUAN KINH DOANH"
            );

            addMoneyRow(
                    sheet, row++,
                    "Tổng doanh thu (VNĐ)",
                    data.totalRevenue,
                    moneyStyle
            );

            addNumberRow(
                    sheet, row++,
                    "Đơn hàng hoàn thành",
                    data.completedOrders
            );

            addNumberRow(
                    sheet, row++,
                    "Sản phẩm đã bán",
                    data.totalProductsSold
            );

            addMoneyRow(
                    sheet, row++,
                    "Giá trị đơn trung bình (VNĐ)",
                    data.averageOrderValue,
                    moneyStyle
            );

            row++;

            // ---------- TRẠNG THÁI ĐƠN ----------
            row = addSection(
                    sheet, row, headerStyle,
                    "THỐNG KÊ TRẠNG THÁI ĐƠN HÀNG"
            );

            row = addTableHeader(
                    sheet, row, headerStyle,
                    "Trạng thái",
                    "Số đơn hàng",
                    "Tỷ lệ"
            );

            int totalOrders = 0;

            for (Object[] item : data.orderStatusStats) {
                totalOrders += toInt(item[1]);
            }

            if (data.orderStatusStats.isEmpty()) {

                addTextRow(
                        sheet, row++,
                        "Không có đơn hàng",
                        ""
                );

            } else {

                for (Object[] item : data.orderStatusStats) {

                    String status
                            = statusName(String.valueOf(item[0]));

                    int count = toInt(item[1]);

                    double ratio = totalOrders > 0
                            ? (double) count / totalOrders
                            : 0;

                    Row excelRow = sheet.createRow(row++);

                    excelRow.createCell(0)
                            .setCellValue(status);

                    excelRow.createCell(1)
                            .setCellValue(count);

                    Cell cell = excelRow.createCell(2);

                    cell.setCellValue(ratio);
                    cell.setCellStyle(percentStyle);
                }
            }

            row++;

            // ---------- TOP 5 SẢN PHẨM ----------
            row = addSection(
                    sheet, row, headerStyle,
                    "TOP 5 SẢN PHẨM BÁN CHẠY"
            );

            row = addTableHeader(
                    sheet, row, headerStyle,
                    "Hạng",
                    "Tên sản phẩm",
                    "Số lượng đã bán"
            );

            if (data.topSellingProducts.isEmpty()) {

                addTextRow(
                        sheet, row++,
                        "Không có sản phẩm bán ra",
                        ""
                );

            } else {

                int rank = 1;

                for (Object[] item : data.topSellingProducts) {

                    Row excelRow = sheet.createRow(row++);

                    excelRow.createCell(0)
                            .setCellValue(rank++);

                    excelRow.createCell(1)
                            .setCellValue(
                                    String.valueOf(item[0])
                            );

                    excelRow.createCell(2)
                            .setCellValue(toInt(item[1]));
                }
            }

            row++;

            // ---------- DOANH THU THEO NGÀY ----------
            row = addSection(
                    sheet, row, headerStyle,
                    "DOANH THU THEO NGÀY"
            );

            row = addTableHeader(
                    sheet, row, headerStyle,
                    "Ngày",
                    "Doanh thu (VNĐ)",
                    "Số đơn hoàn thành"
            );

            if (data.revenueByDate.isEmpty()) {

                addTextRow(
                        sheet, row++,
                        "Không có doanh thu",
                        ""
                );

            } else {

                for (Object[] item : data.revenueByDate) {

                    Row excelRow = sheet.createRow(row++);

                    excelRow.createCell(0)
                            .setCellValue(formatDate(item[0]));

                    Cell revenueCell
                            = excelRow.createCell(1);

                    revenueCell.setCellValue(
                            toMoney(item[1]).doubleValue()
                    );

                    revenueCell.setCellStyle(moneyStyle);

                    excelRow.createCell(2)
                            .setCellValue(toInt(item[2]));
                }
            }

            row++;

            addMoneyRow(
                    sheet, row++,
                    "TỔNG DOANH THU (VNĐ)",
                    data.totalRevenue,
                    moneyStyle
            );

            row++;

            addTextRow(
                    sheet, row++,
                    "Ghi chú",
                    "Doanh thu chỉ tính đơn COMPLETED"
            );

            addTextRow(
                    sheet, row++,
                    "Thời gian",
                    "Thống kê theo ngày tạo đơn"
            );

            // ---------- ĐỊNH DẠNG CỘT ----------
            sheet.setColumnWidth(0, 34 * 256);
            sheet.setColumnWidth(1, 46 * 256);
            sheet.setColumnWidth(2, 25 * 256);

            sheet.setDisplayGridlines(false);

            // ---------- GỬI FILE ----------
            response.setContentType(
                    "application/vnd.openxmlformats-officedocument."
                    + "spreadsheetml.sheet"
            );

            response.setHeader(
                    "Content-Disposition",
                    "attachment; filename=\"OECS_BaoCaoKinhDoanh.xlsx\""
            );

            workbook.write(response.getOutputStream());
        }
    }

    // =====================================================
    // 4. CÁC HÀM HỖ TRỢ EXCEL
    // =====================================================
    private int addSection(
            Sheet sheet,
            int rowIndex,
            CellStyle style,
            String title) {

        Row row = sheet.createRow(rowIndex++);
        row.setHeightInPoints(24);

        for (int i = 0; i < 3; i++) {

            Cell cell = row.createCell(i);
            cell.setCellStyle(style);

            if (i == 0) {
                cell.setCellValue(title);
            }
        }

        return rowIndex;
    }

    private int addTableHeader(
            Sheet sheet,
            int rowIndex,
            CellStyle style,
            String... headers) {

        Row row = sheet.createRow(rowIndex++);
        row.setHeightInPoints(23);

        for (int i = 0; i < headers.length; i++) {

            Cell cell = row.createCell(i);

            cell.setCellValue(headers[i]);
            cell.setCellStyle(style);
        }

        return rowIndex;
    }

    private void addTextRow(
            Sheet sheet,
            int rowIndex,
            String label,
            String value) {

        Row row = sheet.createRow(rowIndex);

        row.createCell(0).setCellValue(label);
        row.createCell(1).setCellValue(value);
    }

    private void addNumberRow(
            Sheet sheet,
            int rowIndex,
            String label,
            int value) {

        Row row = sheet.createRow(rowIndex);

        row.createCell(0).setCellValue(label);
        row.createCell(1).setCellValue(value);
    }

    private void addMoneyRow(
            Sheet sheet,
            int rowIndex,
            String label,
            BigDecimal value,
            CellStyle style) {

        Row row = sheet.createRow(rowIndex);

        row.createCell(0).setCellValue(label);

        Cell cell = row.createCell(1);

        cell.setCellValue(
                value == null ? 0 : value.doubleValue()
        );

        cell.setCellStyle(style);
    }

    // =====================================================
    // 5. XUẤT PDF TIẾNG VIỆT CÓ DẤU
    // =====================================================
    private void exportPdf(
            HttpServletResponse response,
            LocalDate startDate,
            LocalDate endDate,
            ReportData data) throws IOException {

        try (
                InputStream regularStream
                = getServletContext().getResourceAsStream(
                        FONT_REGULAR
                ); InputStream boldStream
                = getServletContext().getResourceAsStream(
                        FONT_BOLD
                )) {

                    if (regularStream == null || boldStream == null) {
                        throw new IOException(
                                "Không tìm thấy NotoSans-Regular.ttf hoặc "
                                + "NotoSans-Bold.ttf trong WEB-INF/fonts."
                        );
                    }

                    try (PDDocument document = new PDDocument()) {

                        // Font Unicode được nhúng vào PDF
                        PDType0Font regular
                                = PDType0Font.load(
                                        document,
                                        regularStream,
                                        true
                                );

                        PDType0Font bold
                                = PDType0Font.load(
                                        document,
                                        boldStream,
                                        true
                                );

                        try (PdfWriter pdf = new PdfWriter(
                                document, regular, bold
                        )) {

                            // ---------- TIÊU ĐỀ ----------
                            pdf.heading(
                                    "OECS - BÁO CÁO KINH DOANH"
                            );

                            pdf.paragraph(
                                    "Thời gian: "
                                    + startDate.format(DATE_FORMAT)
                                    + " - "
                                    + endDate.format(DATE_FORMAT)
                            );

                            pdf.space(14);

                            // ---------- TỔNG QUAN ----------
                            pdf.section("1. TỔNG QUAN KINH DOANH");

                            pdf.paragraph(
                                    "Tổng doanh thu: "
                                    + formatMoney(data.totalRevenue)
                                    + " VNĐ"
                            );

                            pdf.paragraph(
                                    "Đơn hàng hoàn thành: "
                                    + data.completedOrders
                            );

                            pdf.paragraph(
                                    "Sản phẩm đã bán: "
                                    + data.totalProductsSold
                            );

                            pdf.paragraph(
                                    "Giá trị đơn trung bình: "
                                    + formatMoney(data.averageOrderValue)
                                    + " VNĐ"
                            );

                            pdf.space(14);

                            // ---------- TRẠNG THÁI ĐƠN ----------
                            pdf.section(
                                    "2. THỐNG KÊ TRẠNG THÁI ĐƠN HÀNG"
                            );

                            int totalOrders = 0;

                            for (Object[] item : data.orderStatusStats) {
                                totalOrders += toInt(item[1]);
                            }

                            if (data.orderStatusStats.isEmpty()) {

                                pdf.paragraph(
                                        "Không có đơn hàng trong khoảng thời gian này."
                                );

                            } else {

                                pdf.beginTable(
                                        new String[]{
                                            "Trạng thái",
                                            "Số đơn",
                                            "Tỷ lệ"
                                        },
                                        new float[]{220, 140, 140}
                                );

                                for (Object[] item : data.orderStatusStats) {

                                    int count = toInt(item[1]);

                                    double percent = totalOrders > 0
                                            ? count * 100.0 / totalOrders
                                            : 0;

                                    pdf.tableRow(
                                            statusName(
                                                    String.valueOf(item[0])
                                            ),
                                            String.valueOf(count),
                                            String.format(
                                                    Locale.US,
                                                    "%.1f%%",
                                                    percent
                                            )
                                    );
                                }
                            }

                            pdf.space(14);

                            // ---------- TOP 5 ----------
                            pdf.section(
                                    "3. TOP 5 SẢN PHẨM BÁN CHẠY"
                            );

                            if (data.topSellingProducts.isEmpty()) {

                                pdf.paragraph(
                                        "Không có sản phẩm bán ra trong kỳ."
                                );

                            } else {

                                pdf.beginTable(
                                        new String[]{
                                            "Hạng",
                                            "Tên sản phẩm",
                                            "Số lượng"
                                        },
                                        new float[]{60, 340, 100}
                                );

                                int rank = 1;

                                for (Object[] item : data.topSellingProducts) {

                                    pdf.tableRow(
                                            String.valueOf(rank++),
                                            String.valueOf(item[0]),
                                            String.valueOf(toInt(item[1]))
                                    );
                                }
                            }

                            pdf.space(14);

                            // ---------- DOANH THU ----------
                            pdf.section(
                                    "4. DOANH THU THEO NGÀY"
                            );

                            if (data.revenueByDate.isEmpty()) {

                                pdf.paragraph(
                                        "Không có doanh thu trong khoảng thời gian này."
                                );

                            } else {

                                pdf.beginTable(
                                        new String[]{
                                            "Ngày",
                                            "Doanh thu (VNĐ)",
                                            "Số đơn"
                                        },
                                        new float[]{125, 245, 130}
                                );

                                for (Object[] item : data.revenueByDate) {

                                    pdf.tableRow(
                                            formatDate(item[0]),
                                            formatMoney(toMoney(item[1])),
                                            String.valueOf(toInt(item[2]))
                                    );
                                }
                            }

                            pdf.space(14);

                            pdf.section(
                                    "TỔNG DOANH THU: "
                                    + formatMoney(data.totalRevenue)
                                    + " VNĐ"
                            );

                            pdf.space(10);

                            pdf.paragraph(
                                    "Ghi chú: Doanh thu và sản phẩm bán ra "
                                    + "chỉ tính đơn hàng COMPLETED."
                            );

                            pdf.paragraph(
                                    "Thời gian được xác định theo ngày tạo "
                                    + "đơn hàng (created_at)."
                            );
                        }

                        // ---------- GỬI PDF ----------
                        response.setContentType("application/pdf");

                        response.setHeader(
                                "Content-Disposition",
                                "attachment; filename=\"OECS_BaoCaoKinhDoanh.pdf\""
                        );

                        document.save(
                                response.getOutputStream()
                        );
                    }
                }
    }

    // =====================================================
    // 6. PDF WRITER - HỖ TRỢ UNICODE VÀ NHIỀU TRANG
    // =====================================================
    private static class PdfWriter implements AutoCloseable {

        private static final float PAGE_TOP = 780;
        private static final float PAGE_BOTTOM = 48;
        private static final float LEFT = 47;

        private final PDDocument document;
        private final PDType0Font regularFont;
        private final PDType0Font boldFont;

        private PDPageContentStream content;
        private float y;

        private String[] tableHeaders;
        private float[] tableWidths;
        private boolean tableActive = false;
        private int pageNumber = 0;

        PdfWriter(
                PDDocument document,
                PDType0Font regularFont,
                PDType0Font boldFont) throws IOException {

            this.document = document;
            this.regularFont = regularFont;
            this.boldFont = boldFont;

            newPage();
        }

        // ---------- TẠO TRANG ----------
        private void newPage() throws IOException {

            if (content != null) {
                content.close();
            }

            PDPage page
                    = new PDPage(PDRectangle.A4);

            document.addPage(page);

            content = new PDPageContentStream(
                    document, page
            );

            y = PAGE_TOP;
            pageNumber++;

            // Header khi PDF có nhiều trang
            if (pageNumber > 1) {

                drawText(
                        "OECS - Báo cáo kinh doanh (tiếp)",
                        LEFT, y, 10, true
                );

                y -= 29;
            }
        }

        // ---------- KIỂM TRA CHỖ TRỐNG ----------
        private void ensureSpace(float height)
                throws IOException {

            if (y - height < PAGE_BOTTOM) {

                newPage();

                // Lặp lại tiêu đề bảng ở trang mới
                if (tableActive && tableHeaders != null) {
                    drawTableHeader();
                }
            }
        }

        // ---------- TIÊU ĐỀ ----------
        void heading(String text) throws IOException {

            tableActive = false;
            ensureSpace(38);

            drawText(
                    text, LEFT, y, 16, true
            );

            y -= 36;
        }

        // ---------- TIÊU ĐỀ PHẦN ----------
        void section(String text) throws IOException {

            tableActive = false;
            ensureSpace(35);

            drawText(
                    text, LEFT, y, 11, true
            );

            y -= 26;
        }

        // ---------- ĐOẠN VĂN ----------
        void paragraph(String text) throws IOException {

            tableActive = false;

            List<String> lines = wrapText(
                    text,
                    regularFont,
                    10,
                    500
            );

            for (String line : lines) {

                ensureSpace(18);

                drawText(
                        line, LEFT, y, 10, false
                );

                y -= 18;
            }
        }

        // ---------- KHOẢNG CÁCH ----------
        void space(float height) throws IOException {

            tableActive = false;
            ensureSpace(height);

            y -= height;
        }

        // ---------- BẮT ĐẦU BẢNG ----------
        void beginTable(
                String[] headers,
                float[] widths) throws IOException {

            tableActive = false;

            // Kiểm tra trang trước khi vẽ tiêu đề bảng
            ensureSpace(25);

            tableHeaders = headers;
            tableWidths = widths;
            tableActive = true;

            drawTableHeader();
        }

        // ---------- TIÊU ĐỀ CỘT ----------
        private void drawTableHeader() throws IOException {

            float x = LEFT;

            for (int i = 0; i < tableHeaders.length; i++) {

                drawText(
                        tableHeaders[i],
                        x, y, 9, true
                );

                x += tableWidths[i];
            }

            y -= 22;
        }

        // ---------- DÒNG DỮ LIỆU ----------
        void tableRow(String... cells) throws IOException {

            if (!tableActive) {
                throw new IOException(
                        "Chưa khởi tạo bảng PDF."
                );
            }

            List<List<String>> wrapped
                    = new ArrayList<>();

            int maxLines = 1;

            for (int i = 0; i < cells.length; i++) {

                List<String> lines = wrapText(
                        cells[i],
                        regularFont,
                        9,
                        tableWidths[i] - 12
                );

                wrapped.add(lines);

                maxLines = Math.max(
                        maxLines,
                        lines.size()
                );
            }

            float rowHeight
                    = maxLines * 15 + 6;

            ensureSpace(rowHeight);

            float x = LEFT;

            for (int i = 0; i < wrapped.size(); i++) {

                List<String> lines = wrapped.get(i);

                for (int j = 0; j < lines.size(); j++) {

                    drawText(
                            lines.get(j),
                            x,
                            y - (j * 15),
                            9,
                            false
                    );
                }

                x += tableWidths[i];
            }

            y -= rowHeight;
        }

        // ---------- GHI CHỮ UNICODE ----------
        private void drawText(
                String text,
                float x,
                float positionY,
                int fontSize,
                boolean bold) throws IOException {

            PDType0Font font
                    = bold ? boldFont : regularFont;

            String safeText
                    = text == null ? "" : text;

            if (safeText.isEmpty()) {
                return;
            }

            content.beginText();

            content.setFont(font, fontSize);

            content.newLineAtOffset(
                    x, positionY
            );

            content.showText(safeText);

            content.endText();
        }

        // ---------- TỰ ĐỘNG XUỐNG DÒNG ----------
        private List<String> wrapText(
                String text,
                PDType0Font font,
                int fontSize,
                float maxWidth) throws IOException {

            List<String> result = new ArrayList<>();

            if (text == null || text.trim().isEmpty()) {
                result.add("");
                return result;
            }

            StringBuilder current = new StringBuilder();

            for (String word : text.trim().split("\\s+")) {

                String candidate
                        = current.length() == 0
                        ? word
                        : current + " " + word;

                if (textWidth(
                        candidate, font, fontSize
                ) <= maxWidth) {

                    current.setLength(0);
                    current.append(candidate);

                } else {

                    if (current.length() > 0) {
                        result.add(current.toString());
                        current.setLength(0);
                    }

                    // Trường hợp một từ dài hơn cả cột
                    StringBuilder part = new StringBuilder();

                    for (int offset = 0;
                            offset < word.length();) {

                        int cp = word.codePointAt(offset);

                        String ch = new String(
                                Character.toChars(cp)
                        );

                        String test = part.toString() + ch;

                        if (part.length() > 0
                                && textWidth(
                                        test, font, fontSize
                                ) > maxWidth) {

                            result.add(part.toString());
                            part.setLength(0);
                        }

                        part.append(ch);

                        offset += Character.charCount(cp);
                    }

                    current.append(part);
                }
            }

            if (current.length() > 0) {
                result.add(current.toString());
            }

            return result;
        }

        // ---------- ĐO ĐỘ DÀI CHỮ ----------
        private float textWidth(
                String text,
                PDType0Font font,
                int fontSize) throws IOException {

            return font.getStringWidth(text)
                    / 1000f * fontSize;
        }

        // ---------- ĐÓNG PDF STREAM ----------
        @Override
        public void close() throws IOException {

            if (content != null) {
                content.close();
                content = null;
            }
        }
    }

    // =====================================================
    // 7. HÀM HỖ TRỢ DỮ LIỆU
    // =====================================================
    private static int toInt(Object value) {

        if (value instanceof Number) {
            return ((Number) value).intValue();
        }

        return 0;
    }

    private static BigDecimal toMoney(Object value) {

        if (value instanceof BigDecimal) {
            return (BigDecimal) value;
        }

        if (value instanceof Number) {

            return BigDecimal.valueOf(
                    ((Number) value).doubleValue()
            );
        }

        return BigDecimal.ZERO;
    }

    // ---------- FORMAT TIỀN VNĐ ----------
    private static String formatMoney(BigDecimal value) {

        DecimalFormatSymbols symbols
                = new DecimalFormatSymbols(
                        new Locale("vi", "VN")
                );

        symbols.setGroupingSeparator('.');

        DecimalFormat formatter
                = new DecimalFormat("#,##0.##", symbols);

        return formatter.format(
                value == null
                        ? BigDecimal.ZERO
                        : value
        );
    }

    // ---------- FORMAT NGÀY ----------
    private static String formatDate(Object value) {

        if (value == null) {
            return "";
        }

        if (value instanceof LocalDate) {

            return ((LocalDate) value)
                    .format(DATE_FORMAT);
        }

        if (value instanceof Date) {

            return ((Date) value)
                    .toLocalDate()
                    .format(DATE_FORMAT);
        }

        String text = value.toString();

        try {

            return LocalDate.parse(
                    text.substring(0, 10)
            ).format(DATE_FORMAT);

        } catch (Exception e) {

            return text;
        }
    }

    // ---------- DỊCH TRẠNG THÁI ----------
    private static String statusName(String status) {

        if (status == null) {
            return "Không xác định";
        }

        switch (status) {

            case "PENDING_CONFIRMATION":
                return "Chờ xác nhận";

            case "CONFIRMED":
                return "Đã xác nhận";

            case "PACKING":
                return "Đang đóng gói";

            case "SHIPPING":
                return "Đang giao hàng";

            case "COMPLETED":
                return "Hoàn thành";

            case "CANCELLED":
                return "Đã hủy";

            default:
                return status;
        }
    }
}
