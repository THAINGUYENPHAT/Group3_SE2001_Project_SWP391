package controller;

import dao.CategoryAttributeDAO;
import dao.ProductDAO;
import dao.ProductSkuDAO;

import model.CategoryAttribute;
import model.Product;
import model.ProductImage;
import model.ProductSku;
import model.SkuAttributeValue;
import model.User;

import dao.SkuHardDeleteDAO;

import jakarta.servlet.http.HttpSession;

import java.util.UUID;

import service.AuditLogService;
import service.SkuImageService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "ProductSkuServlet",
        urlPatterns = {"/product-sku"}
)
public class ProductSkuServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(ProductSkuServlet.class.getName());

    private final AuditLogService auditLogService
            = new AuditLogService();

    // ========================================
    // 1. HIỂN THỊ TRANG QUẢN LÝ SKU
    // ========================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Integer productId = parsePositiveInt(
                request.getParameter("productId")
        );

        if (productId == null) {
            redirectToProductList(request, response);
            return;
        }

        ProductDAO productDAO = new ProductDAO();

        Product product = productDAO.getById(productId);

        if (product == null) {
            redirectToProductList(request, response);
            return;
        }

        ProductSkuDAO skuDAO = new ProductSkuDAO();

        List<ProductSku> skuList
                = skuDAO.getByProductId(productId);

        CategoryAttributeDAO categoryAttributeDAO
                = new CategoryAttributeDAO();

        List<CategoryAttribute> variantAttributes
                = categoryAttributeDAO.getVariantAttributes(
                        product.getCategoryId()
                );

        /*
         * Lấy ảnh riêng của từng SKU.
         *
         * Key   = skuId
         * Value = danh sách ProductImage
         *
         * JSP sẽ truy cập:
         * ${skuImagesBySkuId[sku.skuId]}
         */
        Map<Integer, List<ProductImage>> skuImagesBySkuId
                = new HashMap<>();

        SkuImageService imageService
                = new SkuImageService();

        try {

            for (ProductSku sku : skuList) {

                List<ProductImage> images
                        = imageService.getImagesBySkuId(
                                productId,
                                sku.getSkuId()
                        );

                skuImagesBySkuId.put(
                        sku.getSkuId(),
                        images
                );
            }

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Không tải được ảnh SKU của Product ID "
                    + productId,
                    ex
            );

            request.getSession().setAttribute(
                    "errorMsg",
                    "Không thể tải danh sách ảnh SKU."
            );

            redirectToProductList(request, response);
            return;
        }

        // Giữ các attribute cũ.
        request.setAttribute("product", product);
        request.setAttribute("skuList", skuList);

        // Cấu hình thuộc tính biến thể.
        request.setAttribute(
                "variantAttributes",
                variantAttributes
        );

        // Dữ liệu ảnh SKU mới.
        request.setAttribute(
                "skuImagesBySkuId",
                skuImagesBySkuId
        );

        // Token xác nhận xóa vĩnh viễn SKU (giữ ổn định trong phiên).
        HttpSession session = request.getSession();
        if (session.getAttribute("skuHardDeleteToken") == null) {
            session.setAttribute(
                    "skuHardDeleteToken",
                    UUID.randomUUID().toString()
            );
        }

        request.getRequestDispatcher(
                "/WEB-INF/sku/list.jsp"
        ).forward(request, response);
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

        Integer productId = parsePositiveInt(
                request.getParameter("productId")
        );

        if (productId == null) {
            setError(request, "Product ID không hợp lệ.");
            redirectToProductList(request, response);
            return;
        }

        Product product
                = new ProductDAO().getById(productId);

        if (product == null) {
            setError(request, "Không tìm thấy sản phẩm.");
            redirectToProductList(request, response);
            return;
        }

        String action = request.getParameter("action");

        try {

            switch (action == null ? "" : action) {

                case "create":
                    createSku(request, product);
                    break;

                case "update":
                    updateSku(request, product);
                    break;

                case "delete":
                    deactivateSku(request, product);
                    break;

                case "hardDelete":
                    hardDeleteSku(request, product);
                    break;

                default:
                    throw new IllegalArgumentException(
                            "Thao tác SKU không hợp lệ."
                    );
            }

        } catch (IllegalArgumentException ex) {

            LOGGER.log(
                    Level.WARNING,
                    "Dữ liệu SKU không hợp lệ",
                    ex
            );

            setError(request, ex.getMessage());

        } catch (Exception ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Không thể xử lý SKU",
                    ex
            );

            setError(
                    request,
                    "Không thể lưu SKU. "
                    + "Vui lòng kiểm tra dữ liệu hoặc nhật ký hệ thống."
            );
        }

        redirectToSkuList(
                request,
                response,
                productId
        );
    }

    // ========================================
    // 3. THÊM SKU
    // ========================================
    private void createSku(
            HttpServletRequest request,
            Product product) {

        ProductSkuDAO skuDAO = new ProductSkuDAO();

        ProductSku sku = readSkuFromRequest(
                request,
                product.getProductId(),
                null
        );

        if (skuDAO.checkSkuCodeExists(
                sku.getSkuCode())) {

            throw new IllegalArgumentException(
                    "Mã SKU đã tồn tại: "
                    + sku.getSkuCode()
            );
        }

        List<CategoryAttribute> configs
                = new CategoryAttributeDAO()
                        .getVariantAttributes(
                                product.getCategoryId()
                        );

        int result;
        Long createdSkuId = null;

        if (hasVariantInput(request)) {

            List<SkuAttributeValue> values
                    = readVariantAttributes(
                            request,
                            configs
                    );

            /*
             * insertWithAttributes() trả về
             * ID SKU mới nếu thành công.
             *
             * DAO xử lý SKU, attribute values
             * và usp_OECS_RefreshSkuVariantKey
             * trong một transaction.
             */
            int newSkuId
                    = skuDAO.insertWithAttributes(
                            sku,
                            values
                    );

            result = newSkuId;

            if (newSkuId > 0) {
                createdSkuId = (long) newSkuId;
            }

        } else {

            /*
             * Nếu danh mục có thuộc tính biến thể,
             * không cho tạo SKU thiếu toàn bộ
             * thuộc tính bằng form cũ.
             */
            if (!configs.isEmpty()) {

                throw new IllegalArgumentException(
                        "Danh mục này có thuộc tính biến thể. "
                        + "Vui lòng nhập các thuộc tính SKU."
                );
            }

            // Tương thích danh mục không có biến thể.
            result = skuDAO.insert(sku);
        }

        if (result <= 0) {

            throw new IllegalStateException(
                    "Không thể thêm SKU."
            );
        }

        setSuccess(
                request,
                "Thêm phiên bản SKU thành công."
        );

        writeAuditLog(
                request,
                "CREATE_SKU",
                createdSkuId,
                "Created SKU: " + sku.getSkuCode()
        );
    }

    // ========================================
    // 4. CẬP NHẬT SKU
    // ========================================
    private void updateSku(
            HttpServletRequest request,
            Product product) {

        Integer skuId = parsePositiveInt(
                request.getParameter("skuId")
        );

        if (skuId == null) {

            throw new IllegalArgumentException(
                    "SKU ID không hợp lệ."
            );
        }

        ProductSkuDAO skuDAO = new ProductSkuDAO();

        ProductSku existing
                = skuDAO.getBySkuId(skuId);

        if (existing == null
                || existing.getProductId()
                != product.getProductId()) {

            throw new IllegalArgumentException(
                    "SKU không thuộc sản phẩm này."
            );
        }

        ProductSku updated = readSkuFromRequest(
                request,
                product.getProductId(),
                existing
        );

        updated.setSkuId(skuId);

        if (skuDAO.checkSkuCodeExistsForUpdate(
                updated.getSkuCode(),
                skuId)) {

            throw new IllegalArgumentException(
                    "Mã SKU bị trùng với phiên bản khác."
            );
        }

        int result;

        if (hasVariantInput(request)) {

            List<CategoryAttribute> configs
                    = new CategoryAttributeDAO()
                            .getVariantAttributes(
                                    product.getCategoryId()
                            );

            List<SkuAttributeValue> values
                    = readVariantAttributes(
                            request,
                            configs
                    );

            /*
             * Form V2 gửi đầy đủ danh sách
             * thuộc tính cần giữ lại.
             */
            result = skuDAO.updateWithAttributes(
                    updated,
                    values
            );

        } else {

            /*
             * Tương thích form cũ:
             * sửa thông tin SKU nhưng không
             * xóa các attribute values đã lưu.
             */
            result = skuDAO.update(updated);
        }

        if (result <= 0) {

            throw new IllegalStateException(
                    "Không thể cập nhật SKU."
            );
        }

        setSuccess(
                request,
                "Cập nhật SKU thành công."
        );

        writeAuditLog(
                request,
                "UPDATE_SKU",
                skuId.longValue(),
                "Updated SKU: " + updated.getSkuCode()
        );
    }

    // ========================================
    // 5A. XÓA VĨNH VIỄN SKU CHƯA CÓ GIAO DỊCH
    // ========================================
    private void hardDeleteSku(
            HttpServletRequest request,
            Product product) throws SQLException {

        // Token kiểm tra phải được tạo từ trang GET quản lý SKU.
        HttpSession session = request.getSession(false);
        String expectedToken = session == null
                ? null
                : (String) session.getAttribute("skuHardDeleteToken");
        String submittedToken = request.getParameter("deleteToken");

        if (expectedToken == null
                || submittedToken == null
                || !expectedToken.equals(submittedToken)) {
            throw new IllegalArgumentException(
                    "Phiên xác nhận xóa không hợp lệ. Vui lòng tải lại trang."
            );
        }

        Integer skuId = parsePositiveInt(request.getParameter("skuId"));
        if (skuId == null) {
            throw new IllegalArgumentException("SKU ID không hợp lệ.");
        }

        ProductSku existing = new ProductSkuDAO().getBySkuId(skuId);
        if (existing == null
                || existing.getProductId() != product.getProductId()) {
            throw new IllegalArgumentException(
                    "SKU không thuộc sản phẩm này."
            );
        }

        String deletedCode = new SkuHardDeleteDAO().deletePermanently(
                product.getProductId(), skuId
        );

        // Không xóa lịch sử audit: ghi nhận ID và mã SKU đã bị xóa.
        writeAuditLog(
                request,
                "HARD_DELETE_SKU",
                skuId.longValue(),
                "Permanently deleted SKU: " + deletedCode
        );

        setSuccess(request, "Đã xóa vĩnh viễn SKU: " + deletedCode);
    }

    // ========================================
    // 5. NGỪNG BÁN SKU
    // ========================================
    private void deactivateSku(
            HttpServletRequest request,
            Product product) {

        Integer skuId = parsePositiveInt(
                request.getParameter("skuId")
        );

        if (skuId == null) {

            throw new IllegalArgumentException(
                    "SKU ID không hợp lệ."
            );
        }

        ProductSkuDAO skuDAO = new ProductSkuDAO();

        ProductSku existing
                = skuDAO.getBySkuId(skuId);

        if (existing == null
                || existing.getProductId()
                != product.getProductId()) {

            throw new IllegalArgumentException(
                    "SKU không thuộc sản phẩm này."
            );
        }

        if (!existing.isActive()) {

            throw new IllegalArgumentException(
                    "SKU này đã ngừng kinh doanh."
            );
        }

        /*
         * delete() của ProductSkuDAO V2
         * thực hiện soft delete:
         * is_active = 0.
         *
         * Ảnh SKU vẫn được giữ nguyên.
         */
        int result = skuDAO.delete(skuId);

        if (result <= 0) {

            throw new IllegalStateException(
                    "Không thể ngừng bán SKU."
            );
        }

        setSuccess(
                request,
                "Đã ngừng kinh doanh SKU."
        );

        writeAuditLog(
                request,
                "DEACTIVATE_SKU",
                skuId.longValue(),
                "Deactivated SKU: "
                + existing.getSkuCode()
        );
    }

    // ========================================
    // 6. ĐỌC DỮ LIỆU SKU
    // ========================================
    private ProductSku readSkuFromRequest(
            HttpServletRequest request,
            int productId,
            ProductSku existing) {

        String skuCode = trimToNull(
                request.getParameter("skuCode")
        );

        if (skuCode == null
                || skuCode.length() > 100) {

            throw new IllegalArgumentException(
                    "Mã SKU phải có từ 1 đến 100 ký tự."
            );
        }

        double price = parseMoney(
                request.getParameter("priceStr"),
                "Giá bán"
        );

        int stock = parseNonNegativeInt(
                request.getParameter("stock"),
                "Tồn kho"
        );

        ProductSku sku = new ProductSku(
                existing == null
                        ? 0
                        : existing.getSkuId(),
                productId,
                skuCode,
                price,
                stock
        );

        // Giá niêm yết tùy chọn.
        String originalPriceInput
                = request.getParameter("originalPriceStr");

        if (originalPriceInput == null) {

            sku.setOriginalPrice(
                    existing == null
                            ? null
                            : existing.getOriginalPrice()
            );

        } else if (originalPriceInput.trim().isEmpty()) {

            sku.setOriginalPrice(null);

        } else {

            sku.setOriginalPrice(
                    parseMoney(
                            originalPriceInput,
                            "Giá niêm yết"
                    )
            );
        }

        // Trạng thái.
        String activeInput
                = request.getParameter("isActive");

        if (activeInput == null) {

            sku.setActive(
                    existing == null
                    || existing.isActive()
            );

        } else {

            sku.setActive(
                    parseBoolean(
                            activeInput,
                            "Trạng thái SKU"
                    )
            );
        }

        return sku;
    }

    // ========================================
    // 7. KIỂM TRA FORM BIẾN THỂ
    // ========================================
    private boolean hasVariantInput(
            HttpServletRequest request) {

        return request.getParameterValues(
                "attributeIds"
        ) != null
                || request.getParameterValues(
                        "attributeValues"
                ) != null;
    }

    // ========================================
    // 8. ĐỌC THUỘC TÍNH BIẾN THỂ
    // ========================================
    private List<SkuAttributeValue> readVariantAttributes(
            HttpServletRequest request,
            List<CategoryAttribute> configs) {

        String[] ids
                = request.getParameterValues("attributeIds");

        String[] values
                = request.getParameterValues("attributeValues");

        if (ids == null
                || values == null
                || ids.length != values.length) {

            throw new IllegalArgumentException(
                    "Danh sách thuộc tính SKU không đồng bộ."
            );
        }

        Map<Integer, CategoryAttribute> allowed
                = new HashMap<>();

        for (CategoryAttribute config : configs) {

            allowed.put(
                    config.getAttributeId(),
                    config
            );
        }

        Set<Integer> submittedIds
                = new HashSet<>();

        Set<Integer> savedIds
                = new HashSet<>();

        List<SkuAttributeValue> result
                = new ArrayList<>();

        for (int i = 0; i < ids.length; i++) {

            Integer attributeId
                    = parsePositiveInt(ids[i]);

            if (attributeId == null
                    || !allowed.containsKey(attributeId)) {

                throw new IllegalArgumentException(
                        "Thuộc tính SKU không thuộc danh mục."
                );
            }

            if (!submittedIds.add(attributeId)) {

                throw new IllegalArgumentException(
                        "Thuộc tính SKU bị trùng."
                );
            }

            CategoryAttribute config
                    = allowed.get(attributeId);

            String value = values[i] == null
                    ? ""
                    : values[i].trim();

            if (value.isEmpty()) {

                if (config.isRequired()) {

                    throw new IllegalArgumentException(
                            "Thiếu thuộc tính bắt buộc: "
                            + config.getAttributeName()
                    );
                }

                continue;
            }

            SkuAttributeValue item
                    = new SkuAttributeValue();

            item.setAttributeId(attributeId);

            String type = config.getDataType();

            if ("TEXT".equals(type)) {

                if (value.length() > 255) {

                    throw new IllegalArgumentException(
                            "Giá trị vượt quá 255 ký tự: "
                            + config.getAttributeName()
                    );
                }

                item.setTextValue(value);

            } else if ("NUMBER".equals(type)) {

                BigDecimal number;

                try {

                    number = new BigDecimal(value)
                            .setScale(
                                    4,
                                    RoundingMode.UNNECESSARY
                            );

                } catch (NumberFormatException
                        | ArithmeticException ex) {

                    throw new IllegalArgumentException(
                            "Giá trị NUMBER không hợp lệ: "
                            + config.getAttributeName(),
                            ex
                    );
                }

                if (number.precision() > 18) {

                    throw new IllegalArgumentException(
                            "Giá trị NUMBER vượt DECIMAL(18,4): "
                            + config.getAttributeName()
                    );
                }

                item.setNumericValue(number);

            } else if ("BOOLEAN".equals(type)) {

                item.setBooleanValue(
                        parseBoolean(
                                value,
                                config.getAttributeName()
                        )
                );

            } else {

                throw new IllegalArgumentException(
                        "Kiểu thuộc tính SKU không hợp lệ."
                );
            }

            result.add(item);
            savedIds.add(attributeId);
        }

        /*
         * Kiểm tra các thuộc tính bắt buộc.
         *
         * Dùng savedIds để tránh trường hợp
         * form gửi attributeId nhưng giá trị rỗng.
         */
        for (CategoryAttribute config : configs) {

            if (config.isRequired()
                    && !savedIds.contains(
                            config.getAttributeId())) {

                throw new IllegalArgumentException(
                        "Thiếu thuộc tính bắt buộc: "
                        + config.getAttributeName()
                );
            }
        }

        return result;
    }

    // ========================================
    // 9. PARSE GIÁ TIỀN
    // ========================================
    private double parseMoney(
            String input,
            String fieldName) {

        if (input == null || input.trim().isEmpty()) {

            throw new IllegalArgumentException(
                    fieldName + " không được để trống."
            );
        }

        String value = input.trim();

        /*
         * Form JSP hiện tại định dạng VNĐ:
         *
         * 27.990.000 -> 27990000
         * 27990000   -> 27990000
         *
         * Hỗ trợ cả dấu phẩy ngăn cách
         * hàng nghìn từ formatNumber cũ.
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
         * PRODUCT_SKU.price:
         * DECIMAL(18,2)
         */
        if (amount.signum() < 0
                || amount.precision() > 16) {

            throw new IllegalArgumentException(
                    fieldName
                    + " vượt giới hạn DECIMAL(18,2)."
            );
        }

        return amount.doubleValue();
    }

    // ========================================
    // 10. PARSE TỒN KHO
    // ========================================
    private int parseNonNegativeInt(
            String input,
            String fieldName) {

        if (input == null || input.trim().isEmpty()) {

            throw new IllegalArgumentException(
                    fieldName + " không được để trống."
            );
        }

        try {

            int value
                    = Integer.parseInt(input.trim());

            if (value < 0) {
                throw new NumberFormatException();
            }

            return value;

        } catch (NumberFormatException ex) {

            throw new IllegalArgumentException(
                    fieldName
                    + " phải là số nguyên không âm."
            );
        }
    }

    // ========================================
    // 11. PARSE BOOLEAN
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
    // 12. PARSE ID DƯƠNG
    // ========================================
    private Integer parsePositiveInt(String input) {

        if (input == null || input.trim().isEmpty()) {
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
    // 13. CHUẨN HÓA CHUỖI
    // ========================================
    private String trimToNull(String input) {

        if (input == null || input.trim().isEmpty()) {
            return null;
        }

        return input.trim();
    }

    // ========================================
    // 14. GHI AUDIT LOG
    // ========================================
    private void writeAuditLog(
            HttpServletRequest request,
            String action,
            Long recordId,
            String description) {

        User user = (User) request.getSession()
                .getAttribute("loggedInUser");

        if (user == null) {

            LOGGER.warning(
                    "Không tìm thấy user để ghi audit log SKU."
            );

            return;
        }

        try {

            auditLogService.log(
                    user,
                    action,
                    "PRODUCT_SKU",
                    recordId,
                    description,
                    request
            );

        } catch (Exception ex) {

            /*
             * SKU đã lưu thành công.
             * Lỗi audit log không làm đảo ngược
             * transaction đã commit.
             */
            LOGGER.log(
                    Level.SEVERE,
                    "Không thể ghi audit log SKU",
                    ex
            );
        }
    }

    // ========================================
    // 15. THÔNG BÁO
    // ========================================
    private void setSuccess(
            HttpServletRequest request,
            String message) {

        request.getSession().removeAttribute(
                "errorMsg"
        );

        request.getSession().setAttribute(
                "successMsg",
                message
        );
    }

    private void setError(
            HttpServletRequest request,
            String message) {

        request.getSession().removeAttribute(
                "successMsg"
        );

        request.getSession().setAttribute(
                "errorMsg",
                message
        );
    }

    // ========================================
    // 16. REDIRECT VỀ SKU
    // ========================================
    private void redirectToSkuList(
            HttpServletRequest request,
            HttpServletResponse response,
            int productId)
            throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/product-sku?productId="
                + productId
        );
    }

    // ========================================
    // 17. REDIRECT VỀ PRODUCT
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
}
