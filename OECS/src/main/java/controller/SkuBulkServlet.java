package controller;

import dao.CategoryAttributeDAO;
import dao.ProductDAO;

import model.CategoryAttribute;
import model.Product;
import model.ProductSku;
import model.SkuAttributeValue;
import model.User;

import service.AuditLogService;
import service.SkuBulkService;
import service.SkuGenerationService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "SkuBulkServlet",
        urlPatterns = {"/sku-bulk"}
)
public class SkuBulkServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(SkuBulkServlet.class.getName());

    private static final String BULK_JSP
            = "/WEB-INF/sku/bulk.jsp";

    private static final String DRAFT_SESSION_KEY
            = "skuBulkDraft";

    private static final int MAX_SKUS = 200;

    private final AuditLogService auditLogService
            = new AuditLogService();

    // ========================================
    // 1. HIỂN THỊ TRANG TẠO SKU HÀNG LOẠT
    // ========================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        if (!requireLogin(request, response)) {
            return;
        }

        Integer productId = parsePositiveInt(
                request.getParameter("productId")
        );

        if (productId == null) {
            redirectToProductList(request, response);
            return;
        }

        Product product
                = new ProductDAO().getById(productId);

        if (product == null) {
            redirectToProductList(request, response);
            return;
        }

        HttpSession session
                = request.getSession(false);

        BulkDraft draft = session == null
                ? null
                : (BulkDraft) session.getAttribute(
                        DRAFT_SESSION_KEY
                );

        /*
         * Nếu session có preview của đúng
         * sản phẩm này, tiếp tục hiển thị.
         */
        if (draft != null
                && draft.productId == productId) {

            request.setAttribute(
                    "previewSkuList",
                    draft.skuList
            );

            request.setAttribute(
                    "previewToken",
                    draft.token
            );
        }

        renderPage(request, response, product);
    }

    // ========================================
    // 2. XỬ LÝ POST
    // ========================================
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        if (!requireLogin(request, response)) {
            return;
        }

        Integer productId = parsePositiveInt(
                request.getParameter("productId")
        );

        if (productId == null) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Product ID không hợp lệ."
            );

            return;
        }

        Product product
                = new ProductDAO().getById(productId);

        if (product == null) {

            response.sendError(
                    HttpServletResponse.SC_NOT_FOUND,
                    "Không tìm thấy sản phẩm."
            );

            return;
        }

        String action = request.getParameter("action");

        try {

            if ("preview".equals(action)) {

                generatePreview(
                        request,
                        product
                );

            } else if ("commit".equals(action)) {

                commitBulk(
                        request,
                        response,
                        product
                );

                /*
                 * commitBulk() tự redirect
                 * khi lưu thành công.
                 */
                if (response.isCommitted()) {
                    return;
                }

            } else if ("clear".equals(action)) {

                clearPreview(request);

                setSuccess(
                        request,
                        "Đã xóa danh sách xem trước."
                );

            } else {

                throw new IllegalArgumentException(
                        "Thao tác tạo SKU hàng loạt "
                        + "không hợp lệ."
                );
            }

        } catch (IllegalArgumentException ex) {

            LOGGER.log(
                    Level.WARNING,
                    "Dữ liệu SKU hàng loạt không hợp lệ",
                    ex
            );

            setError(
                    request,
                    ex.getMessage()
            );

        } catch (Exception ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi tạo SKU hàng loạt",
                    ex
            );

            setError(
                    request,
                    "Không thể tạo SKU hàng loạt. "
                    + "Vui lòng kiểm tra dữ liệu "
                    + "và nhật ký hệ thống."
            );
        }

        /*
         * Nếu preview hoặc commit thất bại,
         * hiển thị lại form cùng bản preview
         * đang lưu trong session.
         */
        restoreDraftToRequest(
                request,
                product.getProductId()
        );

        renderPage(request, response, product);
    }

    // ========================================
    // 3. SINH BẢN XEM TRƯỚC
    // ========================================
    private void generatePreview(
            HttpServletRequest request,
            Product product)
            throws Exception {

        List<CategoryAttribute> configs
                = new CategoryAttributeDAO()
                        .getVariantAttributes(
                                product.getCategoryId()
                        );

        if (configs == null || configs.isEmpty()) {

            throw new IllegalArgumentException(
                    "Danh mục chưa cấu hình "
                    + "thuộc tính biến thể."
            );
        }

        Map<Integer, List<String>> options
                = readGenerationOptions(
                        request,
                        configs
                );

        String skuPrefix = trimToNull(
                request.getParameter("skuPrefix")
        );

        double price = parseMoney(
                request.getParameter("priceStr"),
                "Giá bán"
        );

        Double originalPrice = parseOptionalMoney(
                request.getParameter("originalPriceStr"),
                "Giá niêm yết"
        );

        int stock = parseNonNegativeInt(
                request.getParameter("stock"),
                "Tồn kho"
        );

        boolean active = parseBoolean(
                request.getParameter("isActive"),
                "Trạng thái SKU"
        );

        SkuGenerationService generationService
                = new SkuGenerationService();

        List<ProductSku> preview
                = generationService.generatePreview(
                        product.getProductId(),
                        options,
                        skuPrefix,
                        price,
                        originalPrice,
                        stock,
                        active
                );

        if (preview.size() > MAX_SKUS) {

            throw new IllegalArgumentException(
                    "Số SKU vượt giới hạn cho phép."
            );
        }

        /*
         * Không tạo bản nháp rỗng.
         *
         * Các tổ hợp đã có SKU được loại
         * khỏi danh sách bởi GenerationService.
         */
        if (preview.isEmpty()) {

            throw new IllegalArgumentException(
                    "Không có SKU mới để tạo. "
                    + "Các tổ hợp có thể đã tồn tại."
            );
        }

        /*
         * Mã token dùng để xác định đúng
         * phiên xem trước trong session.
         *
         * Token này không thay thế cơ chế
         * chống CSRF của ứng dụng.
         */
        String token
                = UUID.randomUUID().toString();

        BulkDraft draft = new BulkDraft(
                product.getProductId(),
                token,
                preview
        );

        request.getSession().setAttribute(
                DRAFT_SESSION_KEY,
                draft
        );

        request.setAttribute(
                "previewSkuList",
                preview
        );

        request.setAttribute(
                "previewToken",
                token
        );

        request.setAttribute(
                "previewCount",
                preview.size()
        );

        setSuccess(
                request,
                "Đã tạo bản xem trước gồm "
                + preview.size()
                + " SKU. Hãy kiểm tra trước khi lưu."
        );
    }

    // ========================================
    // 4. ĐỌC CÁC LỰA CHỌN BIẾN THỂ
    // ========================================

    /*
     * Quy ước form:
     *
     * option_3  = 128GB
     * option_3  = 256GB
     *
     * Hoặc một textarea:
     *
     * name="option_3"
     * 128GB
     * 256GB
     *
     * Có thể phân tách bằng dấu xuống dòng
     * hoặc dấu phẩy.
     *
     * Không cho gửi attribute ID nằm ngoài
     * cấu hình CATEGORY_ATTRIBUTE.
     */
    private Map<Integer, List<String>> readGenerationOptions(
            HttpServletRequest request,
            List<CategoryAttribute> configs) {

        Map<Integer, List<String>> result
                = new HashMap<>();

        for (CategoryAttribute config : configs) {

            int attributeId
                    = config.getAttributeId();

            String parameterName
                    = "option_" + attributeId;

            String[] submitted
                    = request.getParameterValues(
                            parameterName
                    );

            if (submitted == null) {
                continue;
            }

            List<String> values
                    = new ArrayList<>();

            for (String raw : submitted) {

                if (raw == null) {
                    continue;
                }

                /*
                 * Dấu phẩy và xuống dòng
                 * được xem là dấu phân cách.
                 */
                String[] tokens
                        = raw.split("[,\\r\\n]+");

                for (String token : tokens) {

                    String value = token.trim();

                    if (!value.isEmpty()) {
                        values.add(value);
                    }
                }
            }

            if (!values.isEmpty()) {

                result.put(
                        attributeId,
                        values
                );
            }
        }

        /*
         * GenerationService sẽ kiểm tra
         * các thuộc tính bắt buộc và
         * chuẩn hóa theo data_type.
         */
        if (result.isEmpty()) {

            throw new IllegalArgumentException(
                    "Vui lòng nhập ít nhất một "
                    + "nhóm giá trị biến thể."
            );
        }

        return result;
    }

    // ========================================
    // 5. XÁC NHẬN LƯU SKU HÀNG LOẠT
    // ========================================
    private void commitBulk(
            HttpServletRequest request,
            HttpServletResponse response,
            Product product)
            throws Exception {

        HttpSession session
                = request.getSession(false);

        if (session == null) {

            throw new IllegalArgumentException(
                    "Phiên xem trước không còn tồn tại."
            );
        }

        BulkDraft draft
                = (BulkDraft) session.getAttribute(
                        DRAFT_SESSION_KEY
                );

        String submittedToken
                = request.getParameter("previewToken");

        /*
         * Bắt buộc khớp:
         * - productId
         * - previewToken
         * - danh sách preview trong session
         */
        if (draft == null
                || draft.productId
                != product.getProductId()
                || submittedToken == null
                || !draft.token.equals(
                        submittedToken
                )) {

            throw new IllegalArgumentException(
                    "Bản xem trước không hợp lệ "
                    + "hoặc đã bị thay thế. "
                    + "Vui lòng tạo preview mới."
            );
        }

        /*
         * Chỉ đọc các trường quản trị viên
         * được phép chỉnh sửa.
         *
         * Không đọc attributeIds hoặc
         * attributeValues từ request commit.
         *
         * Các tổ hợp thuộc tính được lấy
         * từ draft trong session.
         */
        List<ProductSku> approvedSkus
                = readApprovedSkus(
                        request,
                        draft
                );

        SkuBulkService bulkService
                = new SkuBulkService();

        List<Integer> createdIds
                = bulkService.insertBulk(
                        product.getProductId(),
                        approvedSkus
                );

        if (createdIds.size()
                != approvedSkus.size()) {

            throw new IllegalStateException(
                    "Số SKU đã lưu không khớp "
                    + "với danh sách xác nhận."
            );
        }

        /*
         * Chỉ xóa preview sau khi đã được
         * xác nhận lưu thành công.
         */
        session.removeAttribute(
                DRAFT_SESSION_KEY
        );

        setSuccess(
                request,
                "Đã tạo thành công "
                + createdIds.size()
                + " SKU."
        );

        writeAuditLog(
                request,
                product.getProductId(),
                createdIds.size()
        );

        response.sendRedirect(
                request.getContextPath()
                + "/product-sku?productId="
                + product.getProductId()
        );
    }

    // ========================================
    // 6. ĐỌC SKU ĐÃ ĐƯỢC CHỈNH SỬA
    // ========================================

    /*
     * Quy ước form xác nhận:
     *
     * name="skuCode"
     * name="priceStr"
     * name="originalPriceStr"
     * name="stock"
     * name="isActive"
     *
     * Mỗi tên xuất hiện một lần cho
     * từng SKU, theo đúng thứ tự
     * trong previewSkuList.
     *
     * isActive phải dùng SELECT hoặc
     * hidden input có giá trị rõ ràng,
     * không dùng checkbox đơn thuần.
     */
    private List<ProductSku> readApprovedSkus(
            HttpServletRequest request,
            BulkDraft draft) {

        String[] skuCodes
                = request.getParameterValues("skuCode");

        String[] prices
                = request.getParameterValues("priceStr");

        String[] originalPrices
                = request.getParameterValues(
                        "originalPriceStr"
                );

        String[] stocks
                = request.getParameterValues("stock");

        String[] activeValues
                = request.getParameterValues("isActive");

        int expectedCount
                = draft.skuList.size();

        if (!hasExactLength(
                skuCodes, expectedCount)
                || !hasExactLength(
                        prices, expectedCount)
                || !hasExactLength(
                        originalPrices, expectedCount)
                || !hasExactLength(
                        stocks, expectedCount)
                || !hasExactLength(
                        activeValues, expectedCount)) {

            throw new IllegalArgumentException(
                    "Dữ liệu xác nhận SKU không đồng bộ "
                    + "với danh sách xem trước."
            );
        }

        List<ProductSku> approved
                = new ArrayList<>();

        for (int i = 0; i < expectedCount; i++) {

            ProductSku previewSku
                    = draft.skuList.get(i);

            String skuCode
                    = trimToNull(skuCodes[i]);

            if (skuCode == null
                    || skuCode.length() > 100) {

                throw new IllegalArgumentException(
                        "Mã SKU ở dòng "
                        + (i + 1)
                        + " không hợp lệ."
                );
            }

            double price = parseMoney(
                    prices[i],
                    "Giá bán dòng " + (i + 1)
            );

            Double originalPrice
                    = parseOptionalMoney(
                            originalPrices[i],
                            "Giá niêm yết dòng " + (i + 1)
                    );

            int stock = parseNonNegativeInt(
                    stocks[i],
                    "Tồn kho dòng " + (i + 1)
            );

            boolean active = parseBoolean(
                    activeValues[i],
                    "Trạng thái dòng " + (i + 1)
            );

            ProductSku sku = new ProductSku(
                    0,
                    draft.productId,
                    skuCode,
                    price,
                    stock
            );

            sku.setOriginalPrice(
                    originalPrice
            );

            sku.setActive(active);

            /*
             * Sao chép thuộc tính typed từ preview
             * đã sinh và lưu ở server.
             *
             * Không lấy thuộc tính do client
             * gửi trong bước xác nhận.
             */
            for (SkuAttributeValue oldAttr
                    : previewSku.getAttributeValues()) {

                SkuAttributeValue attr
                        = new SkuAttributeValue();

                attr.setAttributeId(
                        oldAttr.getAttributeId()
                );

                attr.setTextValue(
                        oldAttr.getTextValue()
                );

                attr.setNumericValue(
                        oldAttr.getNumericValue()
                );

                attr.setBooleanValue(
                        oldAttr.getBooleanValue()
                );

                sku.getAttributeValues().add(
                        attr
                );
            }

            approved.add(sku);
        }

        return approved;
    }

    // ========================================
    // 7. KIỂM TRA KÍCH THƯỚC MẢNG
    // ========================================
    private boolean hasExactLength(
            String[] values,
            int expected) {

        return values != null
                && values.length == expected;
    }

    // ========================================
    // 8. XÓA PREVIEW
    // ========================================
    private void clearPreview(
            HttpServletRequest request) {

        HttpSession session
                = request.getSession(false);

        if (session != null) {

            session.removeAttribute(
                    DRAFT_SESSION_KEY
            );
        }
    }

    // ========================================
    // 9. KHÔI PHỤC PREVIEW CHO JSP
    // ========================================
    private void restoreDraftToRequest(
            HttpServletRequest request,
            int productId) {

        HttpSession session
                = request.getSession(false);

        if (session == null) {
            return;
        }

        BulkDraft draft
                = (BulkDraft) session.getAttribute(
                        DRAFT_SESSION_KEY
                );

        if (draft == null
                || draft.productId != productId) {
            return;
        }

        request.setAttribute(
                "previewSkuList",
                draft.skuList
        );

        request.setAttribute(
                "previewToken",
                draft.token
        );

        request.setAttribute(
                "previewCount",
                draft.skuList.size()
        );
    }

    // ========================================
    // 10. LOAD FORM JSP
    // ========================================
    private void renderPage(
            HttpServletRequest request,
            HttpServletResponse response,
            Product product)
            throws ServletException, IOException {

        CategoryAttributeDAO categoryDAO
                = new CategoryAttributeDAO();

        List<CategoryAttribute> variantAttributes
                = categoryDAO.getVariantAttributes(
                        product.getCategoryId()
                );

        request.setAttribute(
                "product",
                product
        );

        request.setAttribute(
                "variantAttributes",
                variantAttributes
        );

        request.getRequestDispatcher(
                BULK_JSP
        ).forward(request, response);
    }

    // ========================================
    // 11. KIỂM TRA ĐĂNG NHẬP
    // ========================================
    private boolean requireLogin(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        HttpSession session
                = request.getSession(false);

        if (session == null
                || !(session.getAttribute("loggedInUser") instanceof User)) {

            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Bạn cần đăng nhập."
            );

            return false;
        }

        /*
         * Bộ lọc phân quyền OECS phải bảo vệ
         * /sku-bulk theo quyền quản trị.
         *
         * Đăng nhập không đồng nghĩa với
         * được phép tạo SKU.
         */
        return true;
    }

    // ========================================
    // 12. PARSE GIÁ VNĐ
    // ========================================
    private double parseMoney(
            String input,
            String fieldName) {

        if (input == null
                || input.trim().isEmpty()) {

            throw new IllegalArgumentException(
                    fieldName + " không được để trống."
            );
        }

        String value = input.trim();

        /*
         * Chấp nhận:
         * 27990000
         * 27.990.000
         * 27,990,000
         *
         * Chỉ chấp nhận VNĐ nguyên.
         */
        if (value.matches(
                "\\d{1,3}([.,]\\d{3})+")) {

            value = value.replace(".", "")
                    .replace(",", "");

        } else if (!value.matches("\\d+")) {

            throw new IllegalArgumentException(
                    fieldName
                    + " phải là số VNĐ nguyên không âm."
            );
        }

        BigDecimal amount;

        try {

            amount = new BigDecimal(value);

        } catch (NumberFormatException ex) {

            throw new IllegalArgumentException(
                    fieldName + " không hợp lệ."
            );
        }

        /*
         * DECIMAL(18,2):
         * Tối đa 16 chữ số phần nguyên.
         */
        if (amount.signum() < 0
                || amount.precision() > 16) {

            throw new IllegalArgumentException(
                    fieldName
                    + " vượt giới hạn cho phép."
            );
        }

        return amount.doubleValue();
    }

    // ========================================
    // 13. PARSE GIÁ TÙY CHỌN
    // ========================================
    private Double parseOptionalMoney(
            String input,
            String fieldName) {

        if (input == null
                || input.trim().isEmpty()) {

            return null;
        }

        return parseMoney(
                input,
                fieldName
        );
    }

    // ========================================
    // 14. PARSE TỒN KHO
    // ========================================
    private int parseNonNegativeInt(
            String input,
            String fieldName) {

        if (input == null
                || input.trim().isEmpty()) {

            throw new IllegalArgumentException(
                    fieldName + " không được để trống."
            );
        }

        try {

            int stock
                    = Integer.parseInt(input.trim());

            if (stock < 0) {
                throw new NumberFormatException();
            }

            return stock;

        } catch (NumberFormatException ex) {

            throw new IllegalArgumentException(
                    fieldName
                    + " phải là số nguyên không âm."
            );
        }
    }

    // ========================================
    // 15. PARSE BOOLEAN
    // ========================================
    private boolean parseBoolean(
            String input,
            String fieldName) {

        String value = input == null
                ? ""
                : input.trim();

        if ("true".equalsIgnoreCase(value)
                || "1".equals(value)) {

            return true;
        }

        if ("false".equalsIgnoreCase(value)
                || "0".equals(value)) {

            return false;
        }

        throw new IllegalArgumentException(
                fieldName + " không hợp lệ."
        );
    }

    // ========================================
    // 16. PARSE ID DƯƠNG
    // ========================================
    private Integer parsePositiveInt(
            String input) {

        if (input == null
                || input.trim().isEmpty()) {

            return null;
        }

        try {

            int value
                    = Integer.parseInt(input.trim());

            return value > 0 ? value : null;

        } catch (NumberFormatException ex) {

            return null;
        }
    }

    // ========================================
    // 17. CHUẨN HÓA STRING
    // ========================================
    private String trimToNull(
            String input) {

        if (input == null
                || input.trim().isEmpty()) {

            return null;
        }

        return input.trim();
    }

    // ========================================
    // 18. GHI AUDIT LOG
    // ========================================
    private void writeAuditLog(
            HttpServletRequest request,
            int productId,
            int createdCount) {

        HttpSession session
                = request.getSession(false);

        if (session == null) {
            return;
        }

        User user
                = (User) session.getAttribute(
                        "loggedInUser"
                );

        if (user == null) {
            return;
        }

        try {

            auditLogService.log(
                    user,
                    "CREATE_SKU_BULK",
                    "PRODUCT_SKU",
                    null,
                    "Bulk created "
                    + createdCount
                    + " SKUs for product ID "
                    + productId,
                    request
            );

        } catch (Exception ex) {

            /*
             * Transaction SQL đã commit.
             * Không báo lưu thất bại chỉ vì
             * audit log gặp lỗi.
             */
            LOGGER.log(
                    Level.SEVERE,
                    "Không thể ghi audit log SKU bulk",
                    ex
            );
        }
    }

    // ========================================
    // 19. THÔNG BÁO
    // ========================================
    private void setSuccess(
            HttpServletRequest request,
            String message) {

        HttpSession session
                = request.getSession();

        session.removeAttribute(
                "errorMsg"
        );

        session.setAttribute(
                "successMsg",
                message
        );
    }

    private void setError(
            HttpServletRequest request,
            String message) {

        HttpSession session
                = request.getSession();

        session.removeAttribute(
                "successMsg"
        );

        session.setAttribute(
                "errorMsg",
                message
        );
    }

    // ========================================
    // 20. REDIRECT VỀ DANH SÁCH PRODUCT
    // ========================================
    private void redirectToProductList(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/product?view=list"
        );
    }

    // ========================================
    // 21. CLASS LƯU BẢN PREVIEW TRONG SESSION
    // ========================================
    private static class BulkDraft
            implements java.io.Serializable {

        private static final long serialVersionUID = 1L;

        private final int productId;
        private final String token;
        private final List<ProductSku> skuList;

        private BulkDraft(
                int productId,
                String token,
                List<ProductSku> skuList) {

            this.productId = productId;
            this.token = token;
            this.skuList = skuList;
        }
    }
}
