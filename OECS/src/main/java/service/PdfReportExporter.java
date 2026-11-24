package service;

import model.SalesReport;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType0Font;

import static service.ReportExportSupport.DATE_FORMAT;
import static service.ReportExportSupport.formatDate;
import static service.ReportExportSupport.orderShare;
import static service.ReportExportSupport.paymentStatusName;
import static service.ReportExportSupport.statusName;
import static service.ReportExportSupport.toInt;
import static service.ReportExportSupport.toMoney;

public final class PdfReportExporter {

    public void write(
            OutputStream output,
            ReportService.Range range,
            SalesReport report,
            BigDecimal averageOrderValue,
            InputStream regularStream,
            InputStream boldStream) throws IOException {
        if (regularStream == null || boldStream == null) {
            throw new IOException("Không tìm thấy font Noto Sans trong WEB-INF/fonts.");
        }

        try (PDDocument document = new PDDocument()) {

            PDType0Font regular = PDType0Font.load(document, regularStream, true);
            PDType0Font bold = PDType0Font.load(document, boldStream, true);

            try (PdfWriter pdf = new PdfWriter(document, regular, bold)) {
                pdf.heading("OECS - BÁO CÁO KINH DOANH");
                pdf.paragraph("Thời gian: " + range.start.format(DATE_FORMAT)
                        + " - " + range.end.format(DATE_FORMAT));

                pdf.space(14);
                pdf.section("1. TỔNG QUAN KINH DOANH");
                pdf.paragraph("Tổng doanh thu: " + formatMoney(report.getRevenue()) + " VNĐ");
                pdf.paragraph("Đơn hàng hoàn thành: " + report.getCompletedOrders());
                pdf.paragraph("Sản phẩm đã bán: " + report.getProductsSold());
                pdf.paragraph("Giá trị đơn trung bình: " + formatMoney(averageOrderValue) + " VNĐ");

                pdf.space(14);
                pdf.section("2. THỐNG KÊ TRẠNG THÁI ĐƠN HÀNG");
                if (report.getStatuses().isEmpty()) {
                    pdf.paragraph("Không có đơn hàng trong khoảng thời gian này.");
                } else {
                    pdf.beginTable(new String[]{"Trạng thái", "Số đơn", "Tỷ lệ"},
                            new float[]{220, 140, 140});
                    for (Object[] status : report.getStatuses()) {
                        int count = toInt(status[1]);
                        double percent = orderShare(count, report.getTotalOrders()) * 100;
                        pdf.tableRow(statusName(String.valueOf(status[0])), String.valueOf(count),
                                String.format(Locale.US, "%.1f%%", percent));
                    }
                }

                pdf.space(14);
                pdf.section("3. TOP 5 SẢN PHẨM BÁN CHẠY");
                if (report.getTopProducts().isEmpty()) {
                    pdf.paragraph("Không có sản phẩm bán ra trong kỳ.");
                } else {
                    pdf.beginTable(new String[]{"Hạng", "Tên sản phẩm", "Số lượng"},
                            new float[]{60, 340, 100});
                    int rank = 1;
                    for (Object[] product : report.getTopProducts()) {
                        pdf.tableRow(String.valueOf(rank++), String.valueOf(product[0]),
                                String.valueOf(toInt(product[1])));
                    }
                }

                pdf.space(14);
                pdf.section("4. DOANH THU THEO NGÀY");
                if (report.getRevenueByDate().isEmpty()) {
                    pdf.paragraph("Không có doanh thu trong khoảng thời gian này.");
                } else {
                    pdf.beginTable(new String[]{"Ngày", "Doanh thu (VNĐ)", "Số đơn đã thu tiền"},
                            new float[]{125, 245, 130});
                    for (Object[] day : report.getRevenueByDate()) {
                        pdf.tableRow(formatDate(day[0]), formatMoney(toMoney(day[1])),
                                String.valueOf(toInt(day[2])));
                    }
                }

                pdf.space(14);
                pdf.section("TỔNG DOANH THU: " + formatMoney(report.getRevenue()) + " VNĐ");
                pdf.space(10);
                pdf.paragraph("Ghi chú: Doanh thu và số lượng bán từ đơn hoàn thành đã thanh toán, chưa điều chỉnh đổi trả hoặc hoàn tiền.");
                pdf.paragraph("Thời gian được xác định theo ngày tạo đơn hàng (created_at).");

                pdf.space(14);
                pdf.section("5. BÁO CÁO TỒN KHO HIỆN TẠI");
                pdf.paragraph("Không áp dụng khoảng ngày tạo đơn.");
                if (report.getInventory().isEmpty()) {
                    pdf.paragraph("Không có dữ liệu tồn kho.");
                } else {
                    pdf.beginTable(new String[]{"Mã SKU", "Sản phẩm", "Tồn", "Giữ chỗ", "Khả dụng"},
                            new float[]{110, 210, 55, 65, 60});
                    for (Object[] item : report.getInventory()) {
                        pdf.tableRow(String.valueOf(item[0]), String.valueOf(item[1]),
                                String.valueOf(item[2]), String.valueOf(item[3]), String.valueOf(item[4]));
                    }
                }
                pdf.space(14);
                pdf.section("6. BÁO CÁO THANH TOÁN");
                pdf.paragraph("Theo ngày tạo đơn; giá trị đơn, không phải số tiền hoàn hoặc doanh thu ròng.");
                if (report.getPayments().isEmpty()) {
                    pdf.paragraph("Không có đơn hàng trong kỳ.");
                } else {
                    pdf.beginTable(new String[]{"Phương thức", "Trạng thái", "Số đơn", "Giá trị (VNĐ)"},
                            new float[]{100, 150, 70, 180});
                    for (Object[] item : report.getPayments()) {
                        pdf.tableRow(String.valueOf(item[0]), paymentStatusName(String.valueOf(item[1])),
                                String.valueOf(item[2]), formatMoney(toMoney(item[3])));
                    }
                }
            }

            document.save(output);
        }
    }

    private static String formatMoney(BigDecimal value) {
        DecimalFormatSymbols symbols = new DecimalFormatSymbols(
                        new Locale("vi", "VN")
                );

        symbols.setGroupingSeparator('.');

        DecimalFormat formatter = new DecimalFormat("#,##0.##", symbols);

        return formatter.format(
                value == null
                        ? BigDecimal.ZERO
                        : value
        );
    }

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

        private void newPage() throws IOException {
            if (content != null) {
                content.close();
            }

            PDPage page = new PDPage(PDRectangle.A4);

            document.addPage(page);

            content = new PDPageContentStream(document, page);

            y = PAGE_TOP;
            pageNumber++;

            if (pageNumber > 1) {
                drawText("OECS - Báo cáo kinh doanh (tiếp)", LEFT, y, 10, true);

                y -= 29;
            }
        }

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

        void heading(String text) throws IOException {
            tableActive = false;
            ensureSpace(38);

            drawText(text, LEFT, y, 16, true);

            y -= 36;
        }

        void section(String text) throws IOException {
            tableActive = false;
            ensureSpace(35);

            drawText(text, LEFT, y, 11, true);

            y -= 26;
        }

        void paragraph(String text) throws IOException {
            tableActive = false;

            List<String> lines = wrapText(text, regularFont, 10, 500);

            for (String line : lines) {
                ensureSpace(18);

                drawText(line, LEFT, y, 10, false);

                y -= 18;
            }
        }

        void space(float height) throws IOException {
            tableActive = false;
            ensureSpace(height);

            y -= height;
        }

        void beginTable(
                String[] headers,
                float[] widths) throws IOException {
            tableActive = false;

            ensureSpace(25);

            tableHeaders = headers;
            tableWidths = widths;
            tableActive = true;

            drawTableHeader();
        }

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

        void tableRow(String... cells) throws IOException {
            if (!tableActive) {
                throw new IOException("Chưa khởi tạo bảng PDF.");
            }

            List<List<String>> wrapped = new ArrayList<>();

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

            float rowHeight = maxLines * 15 + 6;

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

        private void drawText(
                String text,
                float x,
                float positionY,
                int fontSize,
                boolean bold) throws IOException {
            PDType0Font font = bold ? boldFont : regularFont;

            String safeText = text == null ? "" : text;

            if (safeText.isEmpty()) {
                return;
            }

            content.beginText();

            content.setFont(font, fontSize);

            content.newLineAtOffset(x, positionY);

            content.showText(safeText);

            content.endText();
        }

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
                String candidate = current.length() == 0
                        ? word
                        : current + " " + word;

                if (textWidth(candidate, font, fontSize) <= maxWidth) {
                    current.setLength(0);
                    current.append(candidate);
                } else {
                    if (current.length() > 0) {
                        result.add(current.toString());
                        current.setLength(0);
                    }

                    StringBuilder part = new StringBuilder();

                    for (int offset = 0;
                            offset < word.length();) {
                        int cp = word.codePointAt(offset);

                        String ch = new String(
                                Character.toChars(cp)
                        );

                        String test = part.toString() + ch;

                        if (part.length() > 0
                                && textWidth(test, font, fontSize) > maxWidth) {
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

        private float textWidth(
                String text,
                PDType0Font font,
                int fontSize) throws IOException {
            return font.getStringWidth(text)
                    / 1000f * fontSize;
        }

        @Override
        public void close() throws IOException {
            if (content != null) {
                content.close();
                content = null;
            }
        }
    }
}
