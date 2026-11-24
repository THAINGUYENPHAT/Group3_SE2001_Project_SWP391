package service;

import model.SalesReport;

import java.io.IOException;
import java.io.OutputStream;
import java.math.BigDecimal;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import static service.ReportExportSupport.DATE_FORMAT;
import static service.ReportExportSupport.formatDate;
import static service.ReportExportSupport.orderShare;
import static service.ReportExportSupport.paymentStatusName;
import static service.ReportExportSupport.statusName;
import static service.ReportExportSupport.toInt;
import static service.ReportExportSupport.toMoney;

public final class ExcelReportExporter {

    public void write(
            OutputStream output,
            ReportService.Range range,
            SalesReport report,
            BigDecimal averageOrderValue) throws IOException {
        try (Workbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Bao cao kinh doanh");

            Font titleFont = workbook.createFont();

            titleFont.setBold(true);
            titleFont.setFontName("Arial");
            titleFont.setFontHeightInPoints((short) 17);
            titleFont.setColor(
                    IndexedColors.DARK_BLUE.getIndex()
            );

            CellStyle titleStyle = workbook.createCellStyle();

            titleStyle.setFont(titleFont);

            Font headerFont = workbook.createFont();

            headerFont.setBold(true);
            headerFont.setFontName("Arial");
            headerFont.setColor(
                    IndexedColors.WHITE.getIndex()
            );

            CellStyle headerStyle = workbook.createCellStyle();

            headerStyle.setFont(headerFont);

            headerStyle.setFillForegroundColor(
                    IndexedColors.DARK_BLUE.getIndex()
            );

            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            headerStyle.setVerticalAlignment(VerticalAlignment.CENTER);

            CellStyle moneyStyle = workbook.createCellStyle();

            moneyStyle.setDataFormat(
                    workbook.createDataFormat()
                            .getFormat("#,##0.##")
            );

            CellStyle percentStyle = workbook.createCellStyle();

            percentStyle.setDataFormat(
                    workbook.createDataFormat()
                            .getFormat("0.0%")
            );

            int row = 0;

            Row titleRow = sheet.createRow(row++);
            titleRow.setHeightInPoints(32);

            Cell titleCell = titleRow.createCell(0);

            titleCell.setCellValue("OECS - BÁO CÁO KINH DOANH");

            titleCell.setCellStyle(titleStyle);

            row++;

            addTextRow(
                    sheet, row++,
                    "Ngày bắt đầu",
                    range.start.format(DATE_FORMAT)
            );

            addTextRow(
                    sheet, row++,
                    "Ngày kết thúc",
                    range.end.format(DATE_FORMAT)
            );

            row++;

            row = addSection(sheet, row, headerStyle, "TỔNG QUAN KINH DOANH");

            addMoneyRow(
                    sheet, row++,
                    "Tổng doanh thu (VNĐ)",
                    report.getRevenue(),
                    moneyStyle
            );

            addNumberRow(
                    sheet, row++,
                    "Đơn hàng hoàn thành",
                    report.getCompletedOrders()
            );

            addNumberRow(
                    sheet, row++,
                    "Sản phẩm đã bán",
                    report.getProductsSold()
            );

            addMoneyRow(
                    sheet, row++,
                    "Giá trị đơn trung bình (VNĐ)",
                    averageOrderValue,
                    moneyStyle
            );

            row++;

            row = addSection(sheet, row, headerStyle, "THỐNG KÊ TRẠNG THÁI ĐƠN HÀNG");

            row = addTableHeader(sheet, row, headerStyle, "Trạng thái", "Số đơn hàng", "Tỷ lệ");

            if (report.getStatuses().isEmpty()) {
                addTextRow(
                        sheet, row++,
                        "Không có đơn hàng",
                        ""
                );
            } else {
                for (Object[] item : report.getStatuses()) {
                    String status = statusName(String.valueOf(item[0]));

                    int count = toInt(item[1]);

                    double ratio = orderShare(count, report.getTotalOrders());

                    Row excelRow = sheet.createRow(row++);

                    excelRow.createCell(0).setCellValue(status);

                    excelRow.createCell(1).setCellValue(count);

                    Cell cell = excelRow.createCell(2);

                    cell.setCellValue(ratio);
                    cell.setCellStyle(percentStyle);
                }
            }

            row++;

            row = addSection(sheet, row, headerStyle, "TOP 5 SẢN PHẨM BÁN CHẠY");

            row = addTableHeader(sheet, row, headerStyle, "Hạng", "Tên sản phẩm", "Số lượng đã bán");

            if (report.getTopProducts().isEmpty()) {
                addTextRow(
                        sheet, row++,
                        "Không có sản phẩm bán ra",
                        ""
                );
            } else {
                int rank = 1;

                for (Object[] item : report.getTopProducts()) {
                    Row excelRow = sheet.createRow(row++);

                    excelRow.createCell(0).setCellValue(rank++);

                    excelRow.createCell(1)
                            .setCellValue(
                                    String.valueOf(item[0])
                            );

                    excelRow.createCell(2).setCellValue(toInt(item[1]));
                }
            }

            row++;

            row = addSection(sheet, row, headerStyle, "DOANH THU THEO NGÀY");

            row = addTableHeader(sheet, row, headerStyle, "Ngày", "Doanh thu (VNĐ)", "Số đơn đã thu tiền");

            if (report.getRevenueByDate().isEmpty()) {
                addTextRow(
                        sheet, row++,
                        "Không có doanh thu",
                        ""
                );
            } else {
                for (Object[] item : report.getRevenueByDate()) {
                    Row excelRow = sheet.createRow(row++);

                    excelRow.createCell(0).setCellValue(formatDate(item[0]));

                    Cell revenueCell = excelRow.createCell(1);

                    revenueCell.setCellValue(
                            toMoney(item[1]).doubleValue()
                    );

                    revenueCell.setCellStyle(moneyStyle);

                    excelRow.createCell(2).setCellValue(toInt(item[2]));
                }
            }

            row++;

            addMoneyRow(
                    sheet, row++,
                    "TỔNG DOANH THU (VNĐ)",
                    report.getRevenue(),
                    moneyStyle
            );

            row++;

            addTextRow(
                    sheet, row++,
                    "Ghi chú",
                    "Doanh thu từ đơn hoàn thành đã thanh toán."
            );

            addTextRow(
                    sheet, row++,
                    "Số lượng bán",
                    "Doanh số gốc, chưa trừ đổi trả."
            );

            addTextRow(
                    sheet, row++,
                    "Thời gian",
                    "Thống kê theo ngày tạo đơn"
            );

            sheet.setColumnWidth(0, 34 * 256);
            sheet.setColumnWidth(1, 46 * 256);
            sheet.setColumnWidth(2, 25 * 256);

            sheet.setDisplayGridlines(false);
            writeInventorySheet(workbook, report, headerStyle);
            writePaymentsSheet(workbook, report, headerStyle, moneyStyle, range);

            workbook.write(output);
        }
    }

    private void writeInventorySheet(Workbook workbook, SalesReport report, CellStyle headerStyle) {
        Sheet sheet = workbook.createSheet("Ton kho hien tai");
        int row = addTableHeader(sheet, 0, headerStyle,
                "Mã SKU", "Sản phẩm", "Tồn thực tế", "Giữ chỗ", "Khả dụng");
        for (Object[] item : report.getInventory()) {
            Row line = sheet.createRow(row++);
            line.createCell(0).setCellValue(String.valueOf(item[0]));
            line.createCell(1).setCellValue(String.valueOf(item[1]));
            for (int i = 2; i < 5; i++) {
                line.createCell(i).setCellValue(toInt(item[i]));
            }
        }
        if (report.getInventory().isEmpty()) {
            addTextRow(sheet, row, "Không có dữ liệu tồn kho", "");
        }
        sheet.setColumnWidth(0, 28 * 256);
        sheet.setColumnWidth(1, 50 * 256);
        for (int i = 2; i < 5; i++) sheet.setColumnWidth(i, 18 * 256);
    }

    private void writePaymentsSheet(Workbook workbook, SalesReport report,
            CellStyle headerStyle, CellStyle moneyStyle, ReportService.Range range) {
        Sheet sheet = workbook.createSheet("Thanh toan");
        addTextRow(sheet, 0, "Khoảng ngày tạo đơn", range.start + " - " + range.end);
        int row = addTableHeader(sheet, 2, headerStyle,
                "Phương thức", "Trạng thái", "Số đơn", "Giá trị đơn (VNĐ)");
        for (Object[] item : report.getPayments()) {
            Row line = sheet.createRow(row++);
            line.createCell(0).setCellValue(String.valueOf(item[0]));
            line.createCell(1).setCellValue(paymentStatusName(String.valueOf(item[1])));
            line.createCell(2).setCellValue(toInt(item[2]));
            Cell value = line.createCell(3);
            value.setCellValue(toMoney(item[3]).doubleValue());
            value.setCellStyle(moneyStyle);
        }
        if (report.getPayments().isEmpty()) addTextRow(sheet, row++, "Không có đơn hàng", "");
        addTextRow(sheet, row, "Ghi chú", "Giá trị đơn, không phải số tiền hoàn hoặc doanh thu ròng.");
        sheet.setColumnWidth(0, 26 * 256);
        sheet.setColumnWidth(1, 54 * 256);
        sheet.setColumnWidth(2, 15 * 256);
        sheet.setColumnWidth(3, 25 * 256);
    }

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
}
