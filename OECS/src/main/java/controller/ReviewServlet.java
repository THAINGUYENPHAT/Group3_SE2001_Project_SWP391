
package controller;

import dao.ProductReviewDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import model.ProductReview;
import model.User;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@WebServlet(name = "ReviewServlet", urlPatterns = {"/review"})
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 5L * 1024 * 1024,
        maxRequestSize = 17L * 1024 * 1024
)
public class ReviewServlet extends HttpServlet {

    private ProductReviewDAO reviewDAO;

    @Override
    public void init() throws ServletException {
        reviewDAO = new ProductReviewDAO();
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        User loggedInUser = getLoggedInUser(request);

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        if (!loggedInUser.isCustomer()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        ensureReviewToken(request.getSession());

        String view = request.getParameter("view");

        if (view == null || view.trim().isEmpty()) {
            view = "create";
        }

        if ("create".equals(view)) {
            showCreate(request, response, loggedInUser);
        } else if ("edit".equals(view)) {
            showEdit(request, response, loggedInUser);
        } else if ("delete".equals(view)) {
            showDelete(request, response, loggedInUser);
        } else {
            redirectOrders(request, response);
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        User loggedInUser = getLoggedInUser(request);

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        if (!loggedInUser.isCustomer()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        if (!validReviewToken(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Phiên làm việc không hợp lệ. Vui lòng tải lại trang.");
            return;
        }

        String action = request.getParameter("action");

        if ("create".equals(action)) {
            createReview(request, response, loggedInUser);
        } else if ("update".equals(action)) {
            updateReview(request, response, loggedInUser);
        } else if ("delete".equals(action)) {
            deleteReview(request, response, loggedInUser);
        } else {
            redirectOrders(request, response);
        }
    }

    private User getLoggedInUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        if (session == null) {
            return null;
        }

        Object value = session.getAttribute("loggedInUser");
        return value instanceof User ? (User) value : null;
    }

    private void ensureReviewToken(HttpSession session) {
        if (!(session.getAttribute("reviewCsrfToken") instanceof String)) {
            session.setAttribute("reviewCsrfToken", UUID.randomUUID().toString());
        }
    }

    private boolean validReviewToken(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return false;
        }

        String expected = (String) session.getAttribute("reviewCsrfToken");
        String actual = request.getParameter("csrfToken");

        return expected != null && expected.equals(actual);
    }

    private void showCreate(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws ServletException, IOException {

        try {
            String orderItemIdParam = request.getParameter("orderItemId");

            if (orderItemIdParam == null || orderItemIdParam.trim().isEmpty()) {
                setError(request, "Thiếu Order Item.");
                redirectOrders(request, response);
                return;
            }

            int orderItemId = Integer.parseInt(orderItemIdParam);

            ProductReview existingReview =
                    reviewDAO.getReviewByOrderItemIdAndUserId(
                            orderItemId,
                            user.getUserId()
                    );

            if (existingReview != null) {
                request.setAttribute("review", existingReview);

                request.getRequestDispatcher(
                        "/WEB-INF/review/detail.jsp"
                ).forward(request, response);

                return;
            }

            int skuId = reviewDAO.getSkuIdByOrderItemId(orderItemId);

            if (skuId <= 0) {
                setError(request, "Không tìm thấy sản phẩm.");
                redirectOrders(request, response);
                return;
            }

            boolean canReview = reviewDAO.canReview(
                    user.getUserId(),
                    orderItemId,
                    skuId
            );

            if (!canReview) {
                setError(request, "Bạn không thể đánh giá sản phẩm này.");
                redirectOrders(request, response);
                return;
            }

            request.setAttribute("orderItemId", orderItemId);
            request.setAttribute("skuId", skuId);

            request.getRequestDispatcher(
                    "/WEB-INF/review/create.jsp"
            ).forward(request, response);

        } catch (NumberFormatException e) {
            setError(request, "Order Item không hợp lệ.");
            redirectOrders(request, response);
        }
    }

    private void createReview(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException, ServletException {

        try {
            String orderItemIdParam = request.getParameter("orderItemId");
            String ratingParam = request.getParameter("rating");

            if (orderItemIdParam == null || ratingParam == null) {
                setError(request, "Thiếu thông tin đánh giá.");
                redirectOrders(request, response);
                return;
            }

            int orderItemId = Integer.parseInt(orderItemIdParam);
            int rating = Integer.parseInt(ratingParam);
            String comment = request.getParameter("comment");

            if (rating < 1 || rating > 5) {
                setError(request, "Số sao phải từ 1 đến 5.");
                redirectCreate(request, response, orderItemId);
                return;
            }

            if (comment != null && comment.length() > 2000) {
                setError(request, "Nội dung đánh giá tối đa 2000 ký tự.");
                redirectCreate(request, response, orderItemId);
                return;
            }

            if (containsSpam(comment)) {
                setError(request,
                        "Nội dung đánh giá có dấu hiệu spam hoặc chứa liên kết quảng cáo.");
                redirectCreate(request, response, orderItemId);
                return;
            }

            int skuId = reviewDAO.getSkuIdByOrderItemId(orderItemId);

            if (skuId <= 0) {
                setError(request, "Không tìm thấy sản phẩm.");
                redirectOrders(request, response);
                return;
            }

            // DAO kiểm tra quyền, trùng review và giới hạn 10 phút khi lưu.
            ProductReview review = new ProductReview();
            review.setUserId(user.getUserId());
            review.setOrderItemId(orderItemId);
            review.setSkuId(skuId);
            review.setRating(rating);
            review.setComment(comment);

            int reviewId = reviewDAO.insertReview(review);

            if (reviewId == ProductReviewDAO.ALREADY_REVIEWED) {
                setError(request,
                        "Sản phẩm trong đơn hàng này đã được đánh giá.");
                redirectOrders(request, response);
                return;
            }

            if (reviewId == ProductReviewDAO.RATE_LIMIT_REACHED) {
                setError(request,
                        "Bạn đã gửi tối đa 10 đánh giá trong 10 phút. Vui lòng thử lại sau.");
                redirectCreate(request, response, orderItemId);
                return;
            }

            if (reviewId == ProductReviewDAO.NOT_ELIGIBLE) {
                setError(request,
                        "Đơn hàng chưa hoàn tất hoặc bạn không có quyền đánh giá sản phẩm này.");
                redirectOrders(request, response);
                return;
            }

            if (reviewId <= 0) {
                setError(request, "Không thể tạo đánh giá.");
                redirectCreate(request, response, orderItemId);
                return;
            }

            // Review đã lưu nên ảnh lỗi chỉ báo lỗi tải ảnh.
            String successMessage = "Đánh giá sản phẩm thành công.";

            try {
                saveReviewImages(request, reviewId);
            } catch (IOException | ServletException | IllegalStateException uploadEx) {
                getServletContext().log(
                        "Đã lưu review " + reviewId + " nhưng upload ảnh thất bại",
                        uploadEx
                );

                successMessage =
                        "Đánh giá đã được lưu nhưng không thể tải ảnh lên.";
            }

            request.getSession().removeAttribute("errorMessage");
            setSuccess(request, successMessage);

            response.sendRedirect(
                    request.getContextPath()
                    + "/review?view=create&orderItemId="
                    + orderItemId
            );

        } catch (NumberFormatException e) {
            setError(request, "Dữ liệu đánh giá không hợp lệ.");
            redirectOrders(request, response);

        } catch (Exception e) {
            getServletContext().log("Lỗi tạo đánh giá", e);
            setError(request, "Có lỗi xảy ra khi tạo đánh giá.");
            redirectOrders(request, response);
        }
    }

    private void showEdit(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws ServletException, IOException {

        try {
            int reviewId = Integer.parseInt(request.getParameter("id"));

            ProductReview review =
                    reviewDAO.getReviewByIdAndUserId(
                            reviewId,
                            user.getUserId()
                    );

            if (review == null) {
                setError(request,
                        "Không tìm thấy đánh giá hoặc bạn không có quyền chỉnh sửa.");
                redirectOrders(request, response);
                return;
            }

            request.setAttribute("review", review);

            request.getRequestDispatcher(
                    "/WEB-INF/review/edit.jsp"
            ).forward(request, response);

        } catch (NumberFormatException e) {
            setError(request, "Review ID không hợp lệ.");
            redirectOrders(request, response);
        }
    }

    private void updateReview(
            HttpServletRequest request,
            HttpServletResponse response,
            User user) throws IOException {

        int reviewId;
        int rating;

        try {
            reviewId = Integer.parseInt(request.getParameter("reviewId"));
            rating = Integer.parseInt(request.getParameter("rating"));

        } catch (NumberFormatException e) {
            setError(request, "Dữ liệu đánh giá không hợp lệ.");
            redirectOrders(request, response);
            return;
        }

        ProductReview review =
                reviewDAO.getReviewByIdAndUserId(reviewId, user.getUserId());

        if (review == null) {
            setError(request, "Bạn không có quyền sửa đánh giá này.");
            redirectOrders(request, response);
            return;
        }

        String comment = request.getParameter("comment");

        if (rating < 1 || rating > 5
                || (comment != null && comment.length() > 2000)) {
            setError(request, "Số sao hoặc nội dung đánh giá không hợp lệ.");
            redirectEdit(request, response, reviewId);
            return;
        }

        if (containsSpam(comment)) {
            setError(request,
                    "Nội dung đánh giá có dấu hiệu spam hoặc chứa liên kết quảng cáo.");
            redirectEdit(request, response, reviewId);
            return;
        }

        review.setRating(rating);
        review.setComment(comment);

        String[] removalValues = request.getParameterValues("removeImages");

        List<String> toRemove = removalValues == null
                ? new ArrayList<>() : Arrays.asList(removalValues);

        Set<String> uniqueRemoval = new HashSet<>(toRemove);

        if (uniqueRemoval.size() != toRemove.size()
                || !new HashSet<>(review.getImages()).containsAll(uniqueRemoval)) {
            setError(request, "Danh sách ảnh cần xóa không hợp lệ.");
            redirectEdit(request, response, reviewId);
            return;
        }

        List<Path> uploadedFiles = new ArrayList<>();
        List<String> newImageUrls = new ArrayList<>();
        boolean committed = false;

        try {
            int keptCount = review.getImages().size() - uniqueRemoval.size();

            List<Part> newParts = new ArrayList<>();

            for (Part part : request.getParts()) {
                if ("images".equals(part.getName()) && part.getSize() > 0) {
                    newParts.add(part);
                }
            }

            if (keptCount + newParts.size() > 3) {
                throw new IllegalArgumentException(
                        "Mỗi đánh giá chỉ có tối đa 3 ảnh.");
            }

            // Kiểm tra ảnh mới trước khi ghi dữ liệu.
            for (Part part : newParts) {
                String extension =
                        getFileExtension(part.getSubmittedFileName());

                if (!isAllowedImage(extension)
                        || part.getSize() > 5L * 1024 * 1024
                        || !isRealImage(part, extension)) {
                    throw new IllegalArgumentException(
                            "Ảnh không hợp lệ. Chỉ nhận JPG, PNG, WEBP (tối đa 5MB/ảnh).");
                }
            }

            if (!newParts.isEmpty()) {
                String folder =
                        getServletContext().getRealPath("/uploads/reviews");

                if (folder == null) {
                    throw new IOException(
                            "Không xác định được thư mục lưu ảnh.");
                }

                Path dir = Paths.get(folder).toAbsolutePath().normalize();
                Files.createDirectories(dir);

                for (Part part : newParts) {
                    String fileName =
                            UUID.randomUUID()
                            + getFileExtension(part.getSubmittedFileName());

                    Path file = dir.resolve(fileName);
                    uploadedFiles.add(file);

                    try (InputStream input = part.getInputStream()) {
                        Files.copy(input, file);
                    }

                    newImageUrls.add("/uploads/reviews/" + fileName);
                }
            }

            // Chỉ commit khi rating, nội dung và ảnh đều cập nhật thành công.
            if (!reviewDAO.updateReviewWithImages(
                    review, toRemove, newImageUrls)) {
                throw new IllegalArgumentException(
                        "Đánh giá không còn tồn tại hoặc bạn không có quyền sửa.");
            }

            committed = true;

            // Chỉ xóa file cũ sau khi transaction đã commit.
            for (String oldUrl : toRemove) {
                deleteLocalReviewImage(oldUrl);
            }

            request.getSession().removeAttribute("errorMessage");
            setSuccess(request, "Cập nhật đánh giá và hình ảnh thành công.");

            response.sendRedirect(
                    request.getContextPath()
                    + "/review?view=create&orderItemId="
                    + review.getOrderItemId()
            );

        } catch (IllegalArgumentException e) {
            setError(request, e.getMessage());
            redirectEdit(request, response, reviewId);

        } catch (Exception e) {
            getServletContext().log(
                    "Không thể cập nhật ảnh của review " + reviewId, e);
            setError(request, "Có lỗi khi cập nhật đánh giá hoặc hình ảnh.");
            redirectEdit(request, response, reviewId);

        } finally {
            if (!committed) {
                for (Path file : uploadedFiles) {
                    try {
                        Files.deleteIfExists(file);
                    } catch (IOException cleanupError) {
                        getServletContext().log(
                                "Không thể dọn ảnh upload lỗi", cleanupError);
                    }
                }
            }
        }
    }

    // Kiểm tra chữ ký file, không chỉ dựa vào đuôi ảnh.
    private boolean isRealImage(Part part, String extension)
            throws IOException {

        byte[] header = new byte[12];
        int size = 0;

        try (InputStream in = part.getInputStream()) {
            while (size < header.length) {
                int count =
                        in.read(header, size, header.length - size);

                if (count < 0) {
                    break;
                }

                size += count;
            }
        }

        if ((".jpg".equals(extension) || ".jpeg".equals(extension))
                && size >= 3) {
            return (header[0] & 0xff) == 0xff
                    && (header[1] & 0xff) == 0xd8
                    && (header[2] & 0xff) == 0xff;
        }

        if (".png".equals(extension) && size >= 8) {
            int[] png = {137, 80, 78, 71, 13, 10, 26, 10};

            for (int i = 0; i < png.length; i++) {
                if ((header[i] & 0xff) != png[i]) {
                    return false;
                }
            }

            return true;
        }

        if (".webp".equals(extension) && size >= 12) {
            return header[0] == 'R'
                    && header[1] == 'I'
                    && header[2] == 'F'
                    && header[3] == 'F'
                    && header[8] == 'W'
                    && header[9] == 'E'
                    && header[10] == 'B'
                    && header[11] == 'P';
        }

        return false;
    }

    private void deleteLocalReviewImage(String imageUrl) {
        if (imageUrl == null
                || !imageUrl.startsWith("/uploads/reviews/")) {
            return;
        }

        String fileName =
                imageUrl.substring("/uploads/reviews/".length());

        if (!fileName.matches(
                "[a-fA-F0-9-]{36}\\.(?:jpg|jpeg|png|webp)")) {
            return;
        }

        String folder =
                getServletContext().getRealPath("/uploads/reviews");

        if (folder == null) {
            return;
        }

        try {
            Path dir = Paths.get(folder).toAbsolutePath().normalize();
            Path file = dir.resolve(fileName).normalize();

            if (file.startsWith(dir)) {
                Files.deleteIfExists(file);
            }

        } catch (IOException e) {
            getServletContext().log(
                    "Không thể xóa file ảnh cũ " + fileName, e);
        }
    }

    private void showDelete(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws ServletException, IOException {

        try {
            int reviewId =
                    Integer.parseInt(request.getParameter("id"));

            ProductReview review =
                    reviewDAO.getReviewByIdAndUserId(
                            reviewId, user.getUserId());

            if (review == null) {
                setError(request,
                        "Không tìm thấy đánh giá hoặc bạn không có quyền xóa.");
                redirectOrders(request, response);
                return;
            }

            request.setAttribute("review", review);

            request.getRequestDispatcher(
                    "/WEB-INF/review/delete.jsp"
            ).forward(request, response);

        } catch (NumberFormatException e) {
            setError(request, "Review ID không hợp lệ.");
            redirectOrders(request, response);
        }
    }

    private void deleteReview(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        try {
            int reviewId =
                    Integer.parseInt(request.getParameter("reviewId"));

            ProductReview review =
                    reviewDAO.getReviewByIdAndUserId(
                            reviewId, user.getUserId());

            if (review == null) {
                setError(request, "Bạn không có quyền xóa đánh giá này.");
                redirectOrders(request, response);
                return;
            }

            boolean success =
                    reviewDAO.deleteReview(reviewId, user.getUserId());

            if (success) {
                // Chỉ xóa file sau khi dữ liệu đã xóa thành công.
                for (String oldImage : review.getImages()) {
                    deleteLocalReviewImage(oldImage);
                }

                setSuccess(request, "Xóa đánh giá thành công.");
            } else {
                setError(request, "Không thể xóa đánh giá.");
            }

            redirectOrders(request, response);

        } catch (Exception e) {
            getServletContext().log("Lỗi xóa đánh giá", e);
            setError(request, "Có lỗi xảy ra khi xóa đánh giá.");
            redirectOrders(request, response);
        }
    }

    private void saveReviewImages(
            HttpServletRequest request,
            int reviewId)
            throws IOException, ServletException {

        int imageCount = 0;

        for (Part part : request.getParts()) {
            if (!"images".equals(part.getName())
                    || part.getSize() <= 0) {
                continue;
            }

            if (++imageCount > 3) {
                throw new IOException(
                        "Mỗi đánh giá chỉ được tải lên tối đa 3 ảnh.");
            }

            String extension =
                    getFileExtension(part.getSubmittedFileName());

            if (!isAllowedImage(extension)
                    || part.getSize() > 5L * 1024 * 1024
                    || !isRealImage(part, extension)) {
                throw new IOException(
                        "Ảnh không hợp lệ (JPG, PNG, WEBP; tối đa 5MB/ảnh).");
            }

            String uploadPath =
                    getServletContext().getRealPath("/uploads/reviews");

            if (uploadPath == null) {
                throw new IOException(
                        "Không xác định được thư mục upload.");
            }

            Path directory =
                    Paths.get(uploadPath).toAbsolutePath().normalize();

            Files.createDirectories(directory);

            String fileName = UUID.randomUUID() + extension;
            Path savedFile = directory.resolve(fileName);

            try (InputStream input = part.getInputStream()) {
                Files.copy(input, savedFile);
            }

            boolean saved = reviewDAO.insertReviewImage(
                    reviewId, "/uploads/reviews/" + fileName);

            if (!saved) {
                Files.deleteIfExists(savedFile);
                throw new IOException(
                        "Không lưu được thông tin ảnh đánh giá.");
            }
        }
    }

    private String getFileExtension(String fileName) {
        if (fileName == null) {
            return "";
        }

        int dot = fileName.lastIndexOf('.');

        if (dot < 0) {
            return "";
        }

        return fileName.substring(dot).toLowerCase();
    }

    private boolean isAllowedImage(String extension) {
        return ".jpg".equals(extension)
                || ".jpeg".equals(extension)
                || ".png".equals(extension)
                || ".webp".equals(extension);
    }

    private void setSuccess(
            HttpServletRequest request, String message) {
        request.getSession().setAttribute("successMessage", message);
    }

    private void setError(
            HttpServletRequest request, String message) {
        request.getSession().setAttribute("errorMessage", message);
    }

    private void redirectCreate(
            HttpServletRequest request,
            HttpServletResponse response,
            int orderItemId)
            throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/review?view=create&orderItemId="
                + orderItemId
        );
    }

    private void redirectEdit(
            HttpServletRequest request,
            HttpServletResponse response,
            int reviewId)
            throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/review?view=edit&id="
                + reviewId
        );
    }

    private void redirectOrders(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        response.sendRedirect(
                request.getContextPath() + "/my-orders"
        );
    }

    private boolean containsSpam(String comment) {
        if (comment == null || comment.trim().isEmpty()) {
            return false;
        }

        String text = comment.trim();

        if (text.matches(
                "(?is).*\\b(?:https?://|www\\.).*")) {
            return true;
        }

        if (text.matches(
                "(?s).*(.)\\1{29,}.*")) {
            return true;
        }

        return false;
    }
}
