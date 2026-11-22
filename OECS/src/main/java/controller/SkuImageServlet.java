package controller;

import dao.ProductSkuDAO;
import model.ProductSku;
import model.User;
import service.SkuImageService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

import java.io.BufferedInputStream;
import java.io.IOException;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import java.sql.SQLException;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "SkuImageServlet",
        urlPatterns = {"/sku-images"}
)
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024 * 2,
        maxFileSize = 1024 * 1024 * 10,
        maxRequestSize = 1024 * 1024 * 50
)
public class SkuImageServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(SkuImageServlet.class.getName());

    private static final long MAX_IMAGE_SIZE
            = 10L * 1024 * 1024;

    private static final int MAX_FILES_PER_REQUEST = 10;

    private static final String UPLOAD_FOLDER
            = "uploads/products";

    // ========================================
    // 1. CHỈ CHO PHÉP POST
    // ========================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        response.sendError(
                HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                "Chức năng này chỉ hỗ trợ POST."
        );
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

        /*
         * Kiểm tra đăng nhập.
         *
         * Việc kiểm tra quyền ADMIN/STAFF phải
         * được thực hiện bằng filter phân quyền
         * của OECS trước khi đến Servlet này.
         */
        HttpSession session = request.getSession(false);

        if (session == null
                || !(session.getAttribute("loggedInUser") instanceof User)) {

            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Bạn cần đăng nhập."
            );

            return;
        }

        Integer productId = parsePositiveInt(
                request.getParameter("productId")
        );

        Integer skuId = parsePositiveInt(
                request.getParameter("skuId")
        );

        if (productId == null || skuId == null) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Product ID hoặc SKU ID không hợp lệ."
            );

            return;
        }

        /*
         * Kiểm tra SKU thuộc Product.
         *
         * Service vẫn kiểm tra lại bằng
         * Connection và transaction của nó.
         */
        ProductSku sku
                = new ProductSkuDAO().getBySkuId(skuId);

        if (sku == null
                || sku.getProductId() != productId) {

            response.sendError(
                    HttpServletResponse.SC_NOT_FOUND,
                    "Không tìm thấy SKU thuộc sản phẩm."
            );

            return;
        }

        String action = request.getParameter("action");

        try {

            if ("upload".equals(action)) {

                uploadSkuImages(
                        request,
                        productId,
                        skuId
                );

            } else if ("setPrimary".equals(action)) {

                setPrimaryImage(
                        request,
                        productId,
                        skuId
                );

            } else if ("reorder".equals(action)) {

                reorderImages(
                        request,
                        productId,
                        skuId
                );

            } else if ("delete".equals(action)) {

                deleteSkuImage(
                        request,
                        productId,
                        skuId
                );

            } else {

                throw new IllegalArgumentException(
                        "Thao tác quản lý ảnh không hợp lệ."
                );
            }

        } catch (IllegalArgumentException ex) {

            LOGGER.log(
                    Level.WARNING,
                    "Dữ liệu ảnh SKU không hợp lệ",
                    ex
            );

            setError(
                    request,
                    ex.getMessage()
            );

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi SQL khi quản lý ảnh SKU",
                    ex
            );

            setError(
                    request,
                    "Không thể lưu ảnh SKU vào database."
            );

        } catch (IOException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi upload ảnh SKU",
                    ex
            );

            setError(
                    request,
                    "Không thể xử lý file ảnh."
            );

        } catch (Exception ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi không xác định khi quản lý ảnh SKU",
                    ex
            );

            setError(
                    request,
                    "Có lỗi xảy ra khi quản lý ảnh SKU."
            );
        }

        redirectToSkuList(
                request,
                response,
                productId
        );
    }

    // ========================================
    // 3. UPLOAD NHIỀU ẢNH SKU
    // ========================================
    private void uploadSkuImages(
            HttpServletRequest request,
            int productId,
            int skuId)
            throws IOException, ServletException, SQLException {

        List<Path> uploadedFiles = new ArrayList<>();

        boolean saved = false;

        try {

            List<String> imageUrls
                    = saveUploadedImages(
                            request,
                            uploadedFiles
                    );

            if (imageUrls.isEmpty()) {

                throw new IllegalArgumentException(
                        "Vui lòng chọn ít nhất một ảnh."
                );
            }

            SkuImageService service
                    = new SkuImageService();

            int inserted = service.addImages(
                    productId,
                    skuId,
                    imageUrls
            );

            if (inserted != imageUrls.size()) {

                throw new SQLException(
                        "Số lượng ảnh được lưu không khớp."
                );
            }

            saved = true;

            setSuccess(
                    request,
                    "Đã thêm " + inserted
                    + " ảnh cho SKU."
            );

        } finally {

            /*
             * Nếu không lưu thành công,
             * dọn các file mới upload.
             *
             * Lưu ý: đây là best effort.
             * File system không thuộc
             * transaction SQL Server.
             */
            if (!saved) {
                deleteUploadedFiles(uploadedFiles);
            }
        }
    }

    // ========================================
    // 4. ĐẶT ẢNH CHÍNH
    // ========================================
    private void setPrimaryImage(
            HttpServletRequest request,
            int productId,
            int skuId)
            throws SQLException {

        Integer imageId = parsePositiveInt(
                request.getParameter("imageId")
        );

        if (imageId == null) {

            throw new IllegalArgumentException(
                    "Image ID không hợp lệ."
            );
        }

        SkuImageService service
                = new SkuImageService();

        boolean result = service.setPrimaryImage(
                productId,
                skuId,
                imageId
        );

        if (!result) {

            setError(
                    request,
                    "Ảnh không tồn tại hoặc không thuộc SKU."
            );

            return;
        }

        setSuccess(
                request,
                "Đã cập nhật ảnh đại diện SKU."
        );
    }

    // ========================================
    // 5. SẮP XẾP ẢNH
    // ========================================
    private void reorderImages(
            HttpServletRequest request,
            int productId,
            int skuId)
            throws SQLException {

        /*
         * Form gửi:
         *
         * <input name="imageIds" value="25">
         * <input name="imageIds" value="22">
         * <input name="imageIds" value="24">
         *
         * Thứ tự parameter chính là thứ tự ảnh.
         */
        String[] submitted
                = request.getParameterValues("imageIds");

        if (submitted == null) {

            throw new IllegalArgumentException(
                    "Chưa có danh sách ảnh cần sắp xếp."
            );
        }

        List<Integer> imageIds = new ArrayList<>();

        Set<Integer> uniqueIds = new HashSet<>();

        for (String value : submitted) {

            Integer imageId = parsePositiveInt(value);

            if (imageId == null
                    || !uniqueIds.add(imageId)) {

                throw new IllegalArgumentException(
                        "Danh sách ảnh có ID không hợp lệ "
                        + "hoặc bị trùng."
                );
            }

            imageIds.add(imageId);
        }

        SkuImageService service
                = new SkuImageService();

        boolean result = service.reorderImages(
                productId,
                skuId,
                imageIds
        );

        if (!result) {

            setError(
                    request,
                    "Danh sách ảnh không khớp với SKU hiện tại."
            );

            return;
        }

        setSuccess(
                request,
                "Đã cập nhật thứ tự ảnh SKU."
        );
    }

    // ========================================
    // 6. XÓA ẢNH SKU
    // ========================================
    private void deleteSkuImage(
            HttpServletRequest request,
            int productId,
            int skuId)
            throws SQLException {

        Integer imageId = parsePositiveInt(
                request.getParameter("imageId")
        );

        if (imageId == null) {

            throw new IllegalArgumentException(
                    "Image ID không hợp lệ."
            );
        }

        SkuImageService service
                = new SkuImageService();

        boolean result = service.deleteImage(
                productId,
                skuId,
                imageId
        );

        if (!result) {

            setError(
                    request,
                    "Không thể gỡ ảnh khỏi SKU."
            );

            return;
        }

        /*
         * Chỉ xóa bản ghi trong database.
         * Không xóa file vật lý tại đây.
         */
        setSuccess(
                request,
                "Đã gỡ ảnh khỏi SKU."
        );
    }

    // ========================================
    // 7. ĐỌC CÁC FILE ĐƯỢC UPLOAD
    // ========================================
    private List<String> saveUploadedImages(
            HttpServletRequest request,
            List<Path> uploadedFiles)
            throws IOException, ServletException {

        List<String> imageUrls
                = new ArrayList<>();

        int count = 0;

        for (Part part : request.getParts()) {

            if (!"skuImages".equals(part.getName())
                    || part.getSize() == 0) {
                continue;
            }

            count++;

            if (count > MAX_FILES_PER_REQUEST) {

                throw new IllegalArgumentException(
                        "Mỗi lần chỉ được tải tối đa "
                        + MAX_FILES_PER_REQUEST + " ảnh."
                );
            }

            String url = saveUploadedPart(
                    part,
                    request,
                    uploadedFiles
            );

            imageUrls.add(url);
        }

        return imageUrls;
    }

    // ========================================
    // 8. LƯU MỘT FILE ẢNH
    // ========================================
    private String saveUploadedPart(
            Part part,
            HttpServletRequest request,
            List<Path> uploadedFiles)
            throws IOException {

        if (part.getSize() <= 0
                || part.getSize() > MAX_IMAGE_SIZE) {

            throw new IllegalArgumentException(
                    "Ảnh phải có dung lượng từ 1 byte "
                    + "đến tối đa 10MB."
            );
        }

        String extension = getImageExtension(
                part.getContentType()
        );

        String root = request.getServletContext()
                .getRealPath("/");

        if (root == null) {

            throw new IOException(
                    "Không xác định được thư mục upload."
            );
        }

        Path directory = Paths.get(
                root,
                "uploads",
                "products"
        );

        Files.createDirectories(directory);

        String fileName
                = UUID.randomUUID().toString() + extension;

        Path destination
                = directory.resolve(fileName);

        /*
         * Ghi nhận trước khi copy để có thể
         * dọn file nếu quá trình ghi bị lỗi.
         */
        uploadedFiles.add(destination);

        try (BufferedInputStream input
                = new BufferedInputStream(
                        part.getInputStream()
                )) {

            validateImageSignature(input, extension);

            Files.copy(
                    input,
                    destination
            );
        }

        return UPLOAD_FOLDER + "/" + fileName;
    }

    // ========================================
    // 9. KIỂM TRA LOẠI ẢNH
    // ========================================
    private String getImageExtension(
            String contentType) {

        if ("image/jpeg".equalsIgnoreCase(contentType)) {
            return ".jpg";
        }

        if ("image/png".equalsIgnoreCase(contentType)) {
            return ".png";
        }

        if ("image/webp".equalsIgnoreCase(contentType)) {
            return ".webp";
        }

        throw new IllegalArgumentException(
                "Chỉ hỗ trợ ảnh JPG, PNG và WEBP."
        );
    }

    // ========================================
    // 10. KIỂM TRA CHỮ KÝ FILE
    // ========================================
    private void validateImageSignature(
            BufferedInputStream input,
            String extension)
            throws IOException {

        input.mark(16);

        byte[] header = new byte[12];

        int length = 0;

        while (length < header.length) {

            int read = input.read(
                    header,
                    length,
                    header.length - length
            );

            if (read == -1) {
                break;
            }

            length += read;
        }

        input.reset();

        boolean valid = false;

        if (".jpg".equals(extension)
                && length >= 3) {

            valid
                    = (header[0] & 0xFF) == 0xFF
                    && (header[1] & 0xFF) == 0xD8
                    && (header[2] & 0xFF) == 0xFF;

        } else if (".png".equals(extension)
                && length >= 8) {

            int[] pngSignature = {
                137, 80, 78, 71,
                13, 10, 26, 10
            };

            valid = true;

            for (int i = 0; i < pngSignature.length; i++) {

                if ((header[i] & 0xFF)
                        != pngSignature[i]) {

                    valid = false;
                    break;
                }
            }

        } else if (".webp".equals(extension)
                && length >= 12) {

            valid
                    = header[0] == 'R'
                    && header[1] == 'I'
                    && header[2] == 'F'
                    && header[3] == 'F'
                    && header[8] == 'W'
                    && header[9] == 'E'
                    && header[10] == 'B'
                    && header[11] == 'P';
        }

        if (!valid) {

            throw new IllegalArgumentException(
                    "Nội dung file ảnh không hợp lệ."
            );
        }
    }

    // ========================================
    // 11. DỌN FILE UPLOAD KHI THẤT BẠI
    // ========================================
    private void deleteUploadedFiles(
            List<Path> uploadedFiles) {

        for (Path path : uploadedFiles) {

            try {

                Files.deleteIfExists(path);

            } catch (IOException ex) {

                LOGGER.log(
                        Level.WARNING,
                        "Không xóa được file upload: " + path,
                        ex
                );
            }
        }
    }

    // ========================================
    // 12. PARSE ID DƯƠNG
    // ========================================
    private Integer parsePositiveInt(String input) {

        if (input == null || input.trim().isEmpty()) {
            return null;
        }

        try {

            int value = Integer.parseInt(input.trim());

            return value > 0 ? value : null;

        } catch (NumberFormatException ex) {
            return null;
        }
    }

    // ========================================
    // 13. THÔNG BÁO
    // ========================================
    private void setSuccess(
            HttpServletRequest request,
            String message) {

        HttpSession session = request.getSession();

        session.removeAttribute("errorMsg");
        session.setAttribute("successMsg", message);
    }

    private void setError(
            HttpServletRequest request,
            String message) {

        HttpSession session = request.getSession();

        session.removeAttribute("successMsg");
        session.setAttribute("errorMsg", message);
    }

    // ========================================
    // 14. REDIRECT VỀ DANH SÁCH SKU
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
}
