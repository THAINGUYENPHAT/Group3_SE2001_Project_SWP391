package controller;

import dao.ShopDAO;
import dao.ProductReviewDAO;
import db.DBContext;

import model.Category;
import model.ProductOverviewSection;
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

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

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

            filterCategories
                    = new CategoryFilterReader()
                            .getActiveCategories();

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Không thể tải danh mục sản phẩm",
                    ex
            );

            throw new ServletException(
                    "Không thể tải danh mục sản phẩm.",
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
                = buildSpecGroups(
                        product.getCategoryId(),
                        specs
                );

        List<ProductSpec> featuredSpecs
                = buildFeaturedSpecs(
                        product,
                        specs
                );
        // =====================================
// TỔNG QUAN SẢN PHẨM
// =====================================

        List<ProductOverviewSection> overviewSections
                = shopDAO.getProductOverviewSections(productId);

        request.setAttribute(
                "overviewSections",
                overviewSections
        );

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

    // =========================================
    // 4. CHIA NHÓM THÔNG SỐ KỸ THUẬT
    // =========================================
    private Map<String, List<ProductSpec>> buildSpecGroups(
            int categoryId,
            List<ProductSpec> specs) {

        Map<String, List<ProductSpec>> groups
                = new LinkedHashMap<>();

        if (specs == null || specs.isEmpty()) {

            return groups;
        }

        Map<String, String> groupNames
                = Collections.emptyMap();

        try {

            groupNames
                    = new SpecGroupReader()
                            .getGroupNames(categoryId);

        } catch (SQLException ex) {

            /*
             * Không làm hỏng trang Detail
             * nếu không tải được cấu hình nhóm.
             *
             * Sử dụng nhóm dự phòng theo tên
             * thuộc tính.
             */
            LOGGER.log(
                    Level.WARNING,
                    "Không thể tải CATEGORY_ATTRIBUTE.group_name",
                    ex
            );
        }

        for (ProductSpec spec : specs) {

            if (spec == null) {
                continue;
            }

            String attributeName
                    = spec.getAttributeName();

            if (attributeName == null
                    || attributeName.trim().isEmpty()) {

                continue;
            }

            String value = spec.getValue();

            if (value == null
                    || value.trim().isEmpty()) {

                continue;
            }

            String groupName
                    = groupNames.get(
                            normalizeText(attributeName)
                    );

            // Nếu chưa cấu hình nhóm trong SQL
            if (groupName == null
                    || groupName.trim().isEmpty()) {

                groupName
                        = guessSpecGroup(attributeName);
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

    // =========================================
    // 6. CHỌN THÔNG SỐ NỔI BẬT
    // =========================================
    private List<ProductSpec> buildFeaturedSpecs(
            Product product,
            List<ProductSpec> specs) {

        List<ProductSpec> featured
                = new ArrayList<>();

        if (product == null
                || specs == null
                || specs.isEmpty()) {

            return featured;
        }

        String categoryName = "";

        if (product.getCategory() != null
                && product.getCategory().getCategoryName() != null) {

            categoryName
                    = normalizeText(
                            product.getCategory()
                                    .getCategoryName()
                    );
        }

        List<String> preferred;

        // =====================================
        // SMARTPHONE
        // =====================================
        if (categoryName.contains("smartphone")
                || categoryName.contains("dien thoai")) {

            preferred = Arrays.asList(
                    "Chip xử lý (CPU)",
                    "Kích thước màn hình",
                    "Màn hình",
                    "Tần số quét",
                    "Camera sau",
                    "Camera chính",
                    "Dung lượng pin",
                    "Công suất sạc",
                    "Kết nối NFC"
            );

            // =====================================
            // LAPTOP
            // =====================================
        } else if (categoryName.contains("laptop")) {

            preferred = Arrays.asList(
                    "Chip xử lý (CPU)",
                    "Card đồ họa (GPU)",
                    "Kích thước màn hình",
                    "Màn hình",
                    "Tần số quét",
                    "Trọng lượng",
                    "Kết nối không dây",
                    "Cổng kết nối"
            );

            // =====================================
            // TAI NGHE
            // =====================================
        } else if (categoryName.contains("tai nghe")) {

            preferred = Arrays.asList(
                    "Chống ồn chủ động",
                    "Chống ồn",
                    "Bluetooth",
                    "Kiểu tai nghe",
                    "Thời lượng pin",
                    "Thời gian sử dụng",
                    "Công nghệ âm thanh",
                    "Chuẩn kháng nước"
            );

            // =====================================
            // ĐỒNG HỒ THÔNG MINH
            // =====================================
        } else if (categoryName.contains("dong ho")) {

            preferred = Arrays.asList(
                    "Kích thước màn hình",
                    "Công nghệ màn hình",
                    "Màn hình",
                    "GPS",
                    "Cảm biến sức khỏe",
                    "Thời lượng pin",
                    "Chống nước",
                    "Bluetooth"
            );

            // =====================================
            // MÁY ẢNH
            // =====================================
        } else if (categoryName.contains("may anh")
                || categoryName.contains("camera")) {

            preferred = Arrays.asList(
                    "Độ phân giải hữu dụng",
                    "Cảm biến máy ảnh",
                    "Kích thước cảm biến",
                    "Độ phân giải video",
                    "Chống rung",
                    "Lấy nét tự động",
                    "Màn hình",
                    "Trọng lượng"
            );

            // =====================================
            // SẠC, CÁP
            // =====================================
        } else if (categoryName.contains("sac")
                || categoryName.contains("cap")) {

            preferred = Arrays.asList(
                    "Công suất tối đa",
                    "Công suất sạc",
                    "Cổng kết nối",
                    "Chuẩn sạc",
                    "Chiều dài",
                    "Khả năng tương thích"
            );

            // =====================================
            // CHUỘT, BÀN PHÍM
            // =====================================
        } else if (categoryName.contains("chuot")
                || categoryName.contains("ban phim")) {

            preferred = Arrays.asList(
                    "Kiểu kết nối",
                    "Công nghệ kết nối",
                    "DPI",
                    "Loại switch",
                    "Số phím",
                    "Đèn nền",
                    "Trọng lượng",
                    "Tương thích"
            );

            // =====================================
            // CÁC DANH MỤC KHÁC
            // =====================================
        } else {

            preferred = Arrays.asList(
                    "Màn hình",
                    "Độ phân giải",
                    "Công suất",
                    "Kết nối",
                    "Chất liệu",
                    "Kích thước",
                    "Trọng lượng",
                    "Tính năng"
            );
        }

        // =====================================
        // ƯU TIÊN THÔNG SỐ THEO DANH MỤC
        // =====================================
        for (String preferredName : preferred) {

            String expected
                    = normalizeText(preferredName);

            for (ProductSpec spec : specs) {

                if (spec == null
                        || spec.getAttributeName() == null
                        || spec.getValue() == null
                        || spec.getValue().trim().isEmpty()) {

                    continue;
                }

                if (featured.contains(spec)) {
                    continue;
                }

                String actual
                        = normalizeText(
                                spec.getAttributeName()
                        );

                if (actual.equals(expected)) {

                    featured.add(spec);
                    break;
                }
            }

            if (featured.size() >= MAX_FEATURED_SPECS) {
                break;
            }
        }

        // =====================================
        // BỔ SUNG NẾU CHƯA ĐỦ 6 THÔNG SỐ
        // =====================================
        for (ProductSpec spec : specs) {

            if (featured.size() >= MAX_FEATURED_SPECS) {
                break;
            }

            if (spec == null
                    || spec.getAttributeName() == null
                    || spec.getValue() == null
                    || spec.getValue().trim().isEmpty()) {

                continue;
            }

            if (!featured.contains(spec)) {

                featured.add(spec);
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

    // =========================================
    // 12. LẤY DANH MỤC ACTIVE
    // =========================================
    private static class CategoryFilterReader
            extends DBContext {

        public List<Category> getActiveCategories()
                throws SQLException {

            List<Category> categories
                    = new ArrayList<>();

            String sql
                    = "SELECT category_id, category_name "
                    + "FROM dbo.CATEGORY "
                    + "WHERE is_active = 1 "
                    + "ORDER BY category_name ASC, "
                    + "category_id ASC";

            try (Connection conn = getConnection(); PreparedStatement ps
                    = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Category category
                            = new Category(
                                    rs.getInt("category_id"),
                                    rs.getString("category_name"),
                                    null
                            );

                    categories.add(category);
                }
            }

            return categories;
        }
    }

    // =========================================
    // 13. ĐỌC GROUP_NAME TỪ DATABASE
    // =========================================
    private static class SpecGroupReader
            extends DBContext {

        public Map<String, String> getGroupNames(
                int categoryId)
                throws SQLException {

            Map<String, String> names
                    = new LinkedHashMap<>();

            /*
             * CATEGORY_ATTRIBUTE:
             *
             * category_id
             * attribute_id
             * group_name
             * attribute_type
             * is_filterable
             * display_order
             */
            String sql
                    = "SELECT "
                    + "a.attribute_name, "
                    + "ca.group_name "
                    + "FROM dbo.CATEGORY_ATTRIBUTE ca "
                    + "INNER JOIN dbo.ATTRIBUTE a "
                    + "ON a.attribute_id = ca.attribute_id "
                    + "WHERE ca.category_id = ? "
                    + "ORDER BY ca.display_order ASC, "
                    + "a.attribute_name ASC";

            try (Connection conn = getConnection(); PreparedStatement ps
                    = conn.prepareStatement(sql)) {

                ps.setInt(1, categoryId);

                try (ResultSet rs = ps.executeQuery()) {

                    while (rs.next()) {

                        String attributeName
                                = rs.getString("attribute_name");

                        String groupName
                                = rs.getString("group_name");

                        if (attributeName == null
                                || attributeName.trim().isEmpty()) {

                            continue;
                        }

                        if (groupName == null
                                || groupName.trim().isEmpty()) {

                            continue;
                        }

                        names.put(
                                normalizeText(attributeName),
                                groupName.trim()
                        );
                    }
                }
            }

            return names;
        }
    }
}
