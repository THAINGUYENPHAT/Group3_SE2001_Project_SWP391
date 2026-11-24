package controller;

import dao.ShopDAO;
import dao.ProductReviewDAO;
import dao.CategoryDAO;
import org.jsoup.Jsoup;
import org.jsoup.safety.Safelist;

import model.Category;
import model.Product;
import model.ProductSku;
import model.ProductSpec;
import model.ProductReview;
import model.ProductImage;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

import java.text.Normalizer;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "ShopServlet",
        urlPatterns = {"/shop"}
)
public class ShopServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(ShopServlet.class.getName());

    private static final String CATALOG_JSP
            = "/WEB-INF/shop/catalog.jsp";

    private static final String DETAIL_JSP
            = "/WEB-INF/shop/detail.jsp";

    private static final int MAX_FEATURED_SPECS = 6;

    // =========================================
    // 1. ĐIỀU HƯỚNG
    // =========================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        if ("detail".equals(action)) {

            showProductDetail(request, response);

        } else {

            showCatalog(request, response);
        }
    }

    // =========================================
    // 2. CATALOG
    // =========================================
    private void showCatalog(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        ShopDAO shopDAO = new ShopDAO();

        String keyword
                = request.getParameter("keyword");

        String[] categoryIds
                = request.getParameterValues("categoryId");

        String priceRange
                = request.getParameter("priceRange");

        String minRating
                = request.getParameter("minRating");

        String sort
                = request.getParameter("sort");

        // Giữ nguyên hệ thống lọc Catalog V2
        List<Product> catalog
                = shopDAO.getFilteredCatalog(
                        keyword,
                        categoryIds,
                        priceRange,
                        minRating,
                        sort
                );

        List<Category> filterCategories;

        try {
            CategoryDAO categoryDAO = new CategoryDAO();
            filterCategories = categoryDAO.getActiveCategories();

        } catch (RuntimeException ex) {
            LOGGER.log(
                    Level.SEVERE,
                    "Khong the tai danh muc san pham",
                    ex
            );

            throw new ServletException(
                    "Khong the tai danh muc san pham.",
                    ex
            );
        }

        request.setAttribute(
                "catalog",
                catalog == null
                        ? Collections.emptyList()
                        : catalog
        );

        request.setAttribute(
                "filterCategories",
                filterCategories
        );

        request.setAttribute(
                "searchKeyword",
                keyword
        );

        request.setAttribute(
                "selectedCats",
                categoryIds == null
                        ? Collections.emptyList()
                        : Arrays.asList(categoryIds)
        );

        request.setAttribute(
                "selectedPrice",
                priceRange
        );

        request.setAttribute(
                "selectedRating",
                minRating
        );

        request.setAttribute(
                "selectedSort",
                sort
        );

        request.getRequestDispatcher(
                CATALOG_JSP
        ).forward(request, response);
    }

    // =========================================
    // 3. PRODUCT DETAIL
    // =========================================
    private void showProductDetail(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Integer productId
                = parsePositiveInt(
                        request.getParameter("id")
                );

        if (productId == null) {

            response.sendRedirect(
                    request.getContextPath() + "/shop"
            );

            return;
        }

        ShopDAO shopDAO = new ShopDAO();

        // =====================================
        // 3.1. THÔNG TIN SẢN PHẨM
        // =====================================
        Product product
                = shopDAO.getProductDetail(productId);

        if (product == null) {

            response.sendRedirect(
                    request.getContextPath() + "/shop"
            );

            return;
        }

        // =====================================
        // 3.2. GALLERY SẢN PHẨM
        // =====================================
        List<ProductImage> galleryImages
                = shopDAO.getProductImages(productId);

        if (galleryImages == null) {

            galleryImages
                    = Collections.emptyList();
        }

        product.setGalleryImages(galleryImages);

        // =====================================
        // 3.3. DANH SÁCH SKU
        // =====================================
        List<ProductSku> skus
                = shopDAO.getProductSkus(productId);

        if (skus == null) {

            skus = Collections.emptyList();
        }

        // =====================================
        // 3.4. SKU MẶC ĐỊNH
        // =====================================
        ProductSku selectedSku
                = chooseDefaultSku(skus);

        Integer selectedSkuId
                = selectedSku == null
                        ? null
                        : selectedSku.getSkuId();

        boolean hasAvailableSku
                = hasAvailableSku(skus);

        // =====================================
        // 3.5. ẢNH THEO SKU
        // =====================================
        Map<Integer, List<ProductImage>> skuImagesBySkuId
                = shopDAO.getSkuImagesByProduct(productId);

        if (skuImagesBySkuId == null) {

            skuImagesBySkuId
                    = Collections.emptyMap();
        }

        // =====================================
        // 3.6. THÔNG SỐ KỸ THUẬT - OECS V2
        // =====================================

        /*
         * specs:
         * Danh sách thông số cũ từ ShopDAO.
         *
         * specGroups:
         * Các thông số được chia theo group_name.
         *
         * featuredSpecs:
         * Tối đa 6 thông số nổi bật theo danh mục.
         *
         * Không ghi đè thuộc tính của SKU vào
         * thông số chung của PRODUCT.
         */
        List<ProductSpec> specs
                = shopDAO.getProductSpecs(productId);

        if (specs == null) {

            specs = Collections.emptyList();
        }

        Map<String, List<ProductSpec>> specGroups
                = buildSpecGroups(specs);

        List<ProductSpec> featuredSpecs
                = buildFeaturedSpecs(specs);


        // =====================================
        // 3.7. ĐÁNH GIÁ
        // =====================================
        ProductReviewDAO reviewDAO
                = new ProductReviewDAO();

        List<ProductReview> reviews
                = reviewDAO.getReviewsByProductId(
                        productId
                );

        if (reviews == null) {

            reviews = Collections.emptyList();
        }

        int purchaseCount
                = reviewDAO.getPurchaseCountByProductId(
                        productId
                );

        int totalReviews = reviews.size();

        long ratingSum = 0;

        for (ProductReview review : reviews) {

            if (review != null) {

                ratingSum += review.getRating();
            }
        }

        double averageRating
                = totalReviews > 0
                        ? (double) ratingSum / totalReviews
                        : 0.0;

        // =====================================
        // 3.8. SẢN PHẨM TƯƠNG TỰ
        // =====================================
        List<Product> relatedProducts
                = shopDAO.getRelatedProducts(
                        productId,
                        product.getCategoryId()
                );

        if (relatedProducts == null) {

            relatedProducts
                    = Collections.emptyList();
        }

        // =====================================
        // 3.9. CSRF TOKEN BÁO CÁO ĐÁNH GIÁ
        // =====================================
        HttpSession session
                = request.getSession();

        if (session.getAttribute(
                "reviewCsrfToken") == null) {

            session.setAttribute(
                    "reviewCsrfToken",
                    UUID.randomUUID().toString()
            );
        }

        // =====================================
        // 3.10. DỮ LIỆU CHO DETAIL JSP
        // =====================================
        request.setAttribute(
                "product",
                product
        );

// Chỉ cho phép các thẻ HTML định dạng an toàn
        String safeProductDescription = Jsoup.clean(
                product.getDescription() == null
                ? ""
                : product.getDescription(),
                Safelist.basic().addTags(
                        "h2", "h3", "h4"
                )
        );

        request.setAttribute(
                "safeProductDescription",
                safeProductDescription
        );

        request.setAttribute(
                "skus",
                skus
        );

        request.setAttribute(
                "selectedSku",
                selectedSku
        );

        request.setAttribute(
                "selectedSkuId",
                selectedSkuId
        );

        request.setAttribute(
                "hasAvailableSku",
                hasAvailableSku
        );

        request.setAttribute(
                "skuImagesBySkuId",
                skuImagesBySkuId
        );

        // =====================================
        // 3.11. THÔNG SỐ KỸ THUẬT
        // =====================================
        // Giữ dữ liệu cũ
        request.setAttribute(
                "specs",
                specs
        );

        // MỚI: thông số theo nhóm
        request.setAttribute(
                "specGroups",
                specGroups
        );

        // MỚI: tối đa 6 thông số nổi bật
        request.setAttribute(
                "featuredSpecs",
                featuredSpecs
        );

        // =====================================
        // 3.12. ĐÁNH GIÁ VÀ SẢN PHẨM TƯƠNG TỰ
        // =====================================
        request.setAttribute(
                "reviews",
                reviews
        );

        request.setAttribute(
                "purchaseCount",
                purchaseCount
        );

        request.setAttribute(
                "totalReviews",
                totalReviews
        );

        request.setAttribute(
                "averageRating",
                averageRating
        );

        request.setAttribute(
                "relatedProducts",
                relatedProducts
        );

        // =====================================
        // 3.13. FORWARD DETAIL
        // =====================================
        request.getRequestDispatcher(
                DETAIL_JSP
        ).forward(request, response);
    }

    private Map<String, List<ProductSpec>> buildSpecGroups(
            List<ProductSpec> specs) {

        Map<String, List<ProductSpec>> groups
                = new LinkedHashMap<>();

        if (specs == null || specs.isEmpty()) {
            return groups;
        }

        for (ProductSpec spec : specs) {

            if (spec == null) {
                continue;
            }

            String attributeName = spec.getAttributeName();
            String value = spec.getValue();

            if (attributeName == null
                    || attributeName.trim().isEmpty()) {
                continue;
            }

            if (value == null
                    || value.trim().isEmpty()) {
                continue;
            }

            // Group da duoc lay trong ShopDAO bang ID.
            String groupName = spec.getGroupName();

            // Du phong khi chua cau hinh group trong DB.
            if (groupName == null
                    || groupName.trim().isEmpty()) {

                groupName = guessSpecGroup(attributeName);

            } else {
                groupName = groupName.trim();
            }

            groups.computeIfAbsent(
                    groupName,
                    key -> new ArrayList<>()
            ).add(spec);
        }

        return groups;
    }

    // =========================================
    // 5. TỰ PHÂN NHÓM NẾU CHƯA CẤU HÌNH SQL
    // =========================================
    private String guessSpecGroup(
            String attributeName) {

        String name
                = normalizeText(attributeName);

        // Màn hình
        if (containsAny(
                name,
                "man hinh",
                "do phan giai man",
                "tan so quet",
                "kich thuoc man",
                "loai tam nen",
                "oled",
                "ips"
        )) {

            return "Màn hình";
        }

        // CPU, RAM, SSD, GPU
        if (containsAny(
                name,
                "cpu",
                "chip xu ly",
                "bo xu ly",
                "gpu",
                "card do hoa",
                "ram",
                "o cung",
                "ssd",
                "bo nho",
                "luu tru",
                "hieu nang"
        )) {

            return "Hiệu năng và bộ nhớ";
        }

        // Camera
        if (containsAny(
                name,
                "camera",
                "cam bien",
                "lay net",
                "khau do",
                "ong kinh",
                "chup anh",
                "quay video",
                "chong rung"
        )) {

            return "Camera và hình ảnh";
        }

        // Pin, sạc
        if (containsAny(
                name,
                "pin",
                "sac",
                "thoi luong",
                "cong suat",
                "mah",
                "wh"
        )) {

            return "Pin và sạc";
        }

        // Âm thanh
        if (containsAny(
                name,
                "am thanh",
                "chong on",
                "micro",
                "loa",
                "tan so dap ung",
                "driver"
        )) {

            return "Âm thanh";
        }

        // Kết nối
        if (containsAny(
                name,
                "bluetooth",
                "wifi",
                "wi-fi",
                "ket noi",
                "nfc",
                "usb",
                "hdmi",
                "cong giao tiep",
                "gps",
                "sim",
                "mang di dong"
        )) {

            return "Kết nối";
        }

        // Thiết kế
        if (containsAny(
                name,
                "trong luong",
                "kich thuoc",
                "chat lieu",
                "mau sac",
                "thiet ke",
                "chong nuoc",
                "khang nuoc"
        )) {

            return "Thiết kế và trọng lượng";
        }

        // Bảo mật và hệ điều hành
        if (containsAny(
                name,
                "he dieu hanh",
                "bao mat",
                "van tay",
                "face id",
                "nhan dien",
                "phan mem"
        )) {

            return "Phần mềm và bảo mật";
        }

        return "Thông số khác";
    }

    private List<ProductSpec> buildFeaturedSpecs(
            List<ProductSpec> specs) {

        List<ProductSpec> featured = new ArrayList<>();

        if (specs == null || specs.isEmpty()) {
            return featured;
        }

        // Danh sach da duoc DAO sap xep theo display_order.
        for (ProductSpec spec : specs) {

            if (spec == null) {
                continue;
            }

            // Su dung ID de xac dinh thuoc tinh.
            if (spec.getAttributeId() <= 0) {
                continue;
            }

            // Bo qua thong so chua co gia tri.
            String value = spec.getValue();

            if (value == null || value.trim().isEmpty()) {
                continue;
            }

            featured.add(spec);

            // Chi hien thi toi da 6 thong so noi bat.
            if (featured.size() >= MAX_FEATURED_SPECS) {
                break;
            }
        }

        return featured;
    }

    // =========================================
    // 7. CHUẨN HÓA TÊN THUỘC TÍNH
    // =========================================
    private static String normalizeText(
            String input) {

        if (input == null) {
            return "";
        }

        String normalized
                = Normalizer.normalize(
                        input.trim(),
                        Normalizer.Form.NFD
                );

        normalized
                = normalized.replaceAll(
                        "\\p{M}",
                        ""
                );

        normalized
                = normalized.replace('đ', 'd')
                        .replace('Đ', 'D');

        return normalized
                .toLowerCase(Locale.ROOT)
                .replaceAll("\\s+", " ")
                .trim();
    }

    // =========================================
    // 8. KIỂM TRA CỤM TỪ
    // =========================================
    private static boolean containsAny(
            String text,
            String... keywords) {

        if (text == null) {
            return false;
        }

        for (String keyword : keywords) {

            if (text.contains(keyword)) {
                return true;
            }
        }

        return false;
    }

    // =========================================
    // 9. CHỌN SKU MẶC ĐỊNH
    // =========================================
    private ProductSku chooseDefaultSku(
            List<ProductSku> skus) {

        if (skus == null || skus.isEmpty()) {
            return null;
        }

        for (ProductSku sku : skus) {

            if (sku != null
                    && sku.isActive()
                    && sku.getStockQuantity() > 0) {

                return sku;
            }
        }

        // Hết hàng: vẫn lấy SKU đầu tiên để hiển thị giá
        return skus.get(0);
    }

    // =========================================
    // 10. KIỂM TRA SKU CÒN HÀNG
    // =========================================
    private boolean hasAvailableSku(
            List<ProductSku> skus) {

        if (skus == null) {
            return false;
        }

        for (ProductSku sku : skus) {

            if (sku != null
                    && sku.isActive()
                    && sku.getStockQuantity() > 0) {

                return true;
            }
        }

        return false;
    }

    // =========================================
    // 11. PARSE ID
    // =========================================
    private Integer parsePositiveInt(
            String input) {

        if (input == null
                || input.trim().isEmpty()) {

            return null;
        }

        try {

            int id
                    = Integer.parseInt(input.trim());

            return id > 0 ? id : null;

        } catch (NumberFormatException ex) {

            return null;
        }
    }

}
