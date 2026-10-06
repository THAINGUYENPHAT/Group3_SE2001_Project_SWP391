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

import java.io.File;
import java.io.IOException;
import java.util.UUID;

@WebServlet(name = "ReviewServlet", urlPatterns = {"/review"})
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 5 * 1024 * 1024,
        maxRequestSize = 20 * 1024 * 1024
)
public class ReviewServlet extends HttpServlet {

    private ProductReviewDAO reviewDAO;

    @Override
    public void init() throws ServletException {
        reviewDAO = new ProductReviewDAO();
    }

    // =====================================================
    // GET
    // =====================================================
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

    // =====================================================
    // POST
    // =====================================================
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

    // =====================================================
    // SESSION USER
    // =====================================================
    private User getLoggedInUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        if (session == null) {
            return null;
        }

        return (User) session.getAttribute("loggedInUser");
    }

    // =====================================================
    // SHOW CREATE
    // /review?view=create&orderItemId=1
    // =====================================================
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
            int skuId = reviewDAO.getSkuIdByOrderItemId(orderItemId);

            if (skuId <= 0) {
                setError(request, "Không tìm thấy sản phẩm.");
                redirectOrders(request, response);
                return;
            }

            boolean canReview = reviewDAO.canReview(user.getUserId(), orderItemId, skuId);

            if (!canReview) {
                setError(request, "Bạn không thể đánh giá sản phẩm này.");
                redirectOrders(request, response);
                return;
            }

            request.setAttribute("orderItemId", orderItemId);
            request.setAttribute("skuId", skuId);

            request.getRequestDispatcher("/WEB-INF/review/create.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            setError(request, "Order Item không hợp lệ.");
            redirectOrders(request, response);
        }
    }

    // =====================================================
    // CREATE REVIEW
    // =====================================================
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

            int skuId = reviewDAO.getSkuIdByOrderItemId(orderItemId);

            if (skuId <= 0) {
                setError(request, "Không tìm thấy sản phẩm.");
                redirectOrders(request, response);
                return;
            }

            boolean canReview = reviewDAO.canReview(user.getUserId(), orderItemId, skuId);

            if (!canReview) {
                setError(request, "Bạn không có quyền đánh giá sản phẩm này hoặc sản phẩm đã được đánh giá.");
                redirectOrders(request, response);
                return;
            }

            ProductReview review = new ProductReview();
            review.setUserId(user.getUserId());
            review.setOrderItemId(orderItemId);
            review.setSkuId(skuId);
            review.setRating(rating);
            review.setComment(comment);

            int reviewId = reviewDAO.insertReview(review);

            if (reviewId <= 0) {
                setError(request, "Không thể tạo đánh giá.");
                redirectCreate(request, response, orderItemId);
                return;
            }

            saveReviewImages(request, reviewId);
            setSuccess(request, "Đánh giá sản phẩm thành công.");
            redirectOrders(request, response);

        } catch (NumberFormatException e) {
            setError(request, "Dữ liệu đánh giá không hợp lệ.");
            redirectOrders(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            setError(request, "Có lỗi xảy ra khi tạo đánh giá.");
            redirectOrders(request, response);
        }
    }

    // =====================================================
    // SHOW EDIT
    // /review?view=edit&id=1
    // =====================================================
    private void showEdit(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws ServletException, IOException {

        try {
            int reviewId = Integer.parseInt(request.getParameter("id"));
            ProductReview review = reviewDAO.getReviewByIdAndUserId(reviewId, user.getUserId());

            if (review == null) {
                setError(request, "Không tìm thấy đánh giá hoặc bạn không có quyền chỉnh sửa.");
                redirectOrders(request, response);
                return;
            }

            request.setAttribute("review", review);
            request.getRequestDispatcher("/WEB-INF/review/edit.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            setError(request, "Review ID không hợp lệ.");
            redirectOrders(request, response);
        }
    }

    // =====================================================
    // UPDATE REVIEW
    // =====================================================
    private void updateReview(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        try {
            int reviewId = Integer.parseInt(request.getParameter("reviewId"));
            int rating = Integer.parseInt(request.getParameter("rating"));
            String comment = request.getParameter("comment");

            if (rating < 1 || rating > 5) {
                setError(request, "Số sao phải từ 1 đến 5.");
                redirectEdit(request, response, reviewId);
                return;
            }

            if (comment != null && comment.length() > 2000) {
                setError(request, "Nội dung đánh giá tối đa 2000 ký tự.");
                redirectEdit(request, response, reviewId);
                return;
            }

            ProductReview oldReview = reviewDAO.getReviewByIdAndUserId(reviewId, user.getUserId());

            if (oldReview == null) {
                setError(request, "Bạn không có quyền sửa đánh giá này.");
                redirectOrders(request, response);
                return;
            }

            oldReview.setRating(rating);
            oldReview.setComment(comment);

            boolean success = reviewDAO.updateReview(oldReview);

            if (success) {
                setSuccess(request, "Cập nhật đánh giá thành công.");
            } else {
                setError(request, "Cập nhật đánh giá thất bại.");
            }

            redirectOrders(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            setError(request, "Có lỗi xảy ra khi cập nhật đánh giá.");
            redirectOrders(request, response);
        }
    }

    // =====================================================
    // SHOW DELETE
    // /review?view=delete&id=1
    // =====================================================
    private void showDelete(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws ServletException, IOException {

        try {
            int reviewId = Integer.parseInt(request.getParameter("id"));
            ProductReview review = reviewDAO.getReviewByIdAndUserId(reviewId, user.getUserId());

            if (review == null) {
                setError(request, "Không tìm thấy đánh giá hoặc bạn không có quyền xóa.");
                redirectOrders(request, response);
                return;
            }

            request.setAttribute("review", review);
            request.getRequestDispatcher("/WEB-INF/review/delete.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            setError(request, "Review ID không hợp lệ.");
            redirectOrders(request, response);
        }
    }

    // =====================================================
    // DELETE REVIEW
    // =====================================================
    private void deleteReview(
            HttpServletRequest request,
            HttpServletResponse response,
            User user)
            throws IOException {

        try {
            int reviewId = Integer.parseInt(request.getParameter("reviewId"));
            ProductReview review = reviewDAO.getReviewByIdAndUserId(reviewId, user.getUserId());

            if (review == null) {
                setError(request, "Bạn không có quyền xóa đánh giá này.");
                redirectOrders(request, response);
                return;
            }

            boolean success = reviewDAO.deleteReview(reviewId, user.getUserId());

            if (success) {
                setSuccess(request, "Xóa đánh giá thành công.");
            } else {
                setError(request, "Không thể xóa đánh giá.");
            }

            redirectOrders(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            setError(request, "Có lỗi xảy ra khi xóa đánh giá.");
            redirectOrders(request, response);
        }
    }

    // =====================================================
    // SAVE REVIEW IMAGES
    // =====================================================
    private void saveReviewImages(
            HttpServletRequest request,
            int reviewId)
            throws IOException, ServletException {

        int imageCount = 0;

        for (Part part : request.getParts()) {

            if (!"images".equals(part.getName())) {
                continue;
            }

            if (part.getSize() <= 0) {
                continue;
            }

            if (imageCount >= 3) {
                break;
            }

            String originalName = part.getSubmittedFileName();

            if (originalName == null || originalName.trim().isEmpty()) {
                continue;
            }

            String extension = getFileExtension(originalName);

            if (!isAllowedImage(extension)) {
                continue;
            }

            String fileName = UUID.randomUUID().toString() + extension;
            String uploadPath = getServletContext().getRealPath("/uploads/reviews");

            if (uploadPath == null) {
                throw new IOException("Không xác định được thư mục upload.");
            }

            File uploadFolder = new File(uploadPath);

            if (!uploadFolder.exists() && !uploadFolder.mkdirs()) {
                throw new IOException("Không thể tạo thư mục upload.");
            }

            File savedFile = new File(uploadFolder, fileName);
            part.write(savedFile.getAbsolutePath());

            String imageUrl = "/uploads/reviews/" + fileName;
            reviewDAO.insertReviewImage(reviewId, imageUrl);

            imageCount++;
        }
    }

    // =====================================================
    // FILE EXTENSION
    // =====================================================
    private String getFileExtension(String fileName) {
        int dot = fileName.lastIndexOf('.');

        if (dot < 0) {
            return "";
        }

        return fileName.substring(dot).toLowerCase();
    }

    // =====================================================
    // ALLOWED IMAGE
    // =====================================================
    private boolean isAllowedImage(String extension) {
        return ".jpg".equals(extension)
                || ".jpeg".equals(extension)
                || ".png".equals(extension)
                || ".webp".equals(extension);
    }

    // =====================================================
    // SUCCESS MESSAGE
    // =====================================================
    private void setSuccess(HttpServletRequest request, String message) {
        request.getSession().setAttribute("successMessage", message);
    }

    // =====================================================
    // ERROR MESSAGE
    // =====================================================
    private void setError(HttpServletRequest request, String message) {
        request.getSession().setAttribute("errorMessage", message);
    }

    // =====================================================
    // REDIRECT CREATE
    // =====================================================
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

    // =====================================================
    // REDIRECT EDIT
    // =====================================================
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

    // =====================================================
    // REDIRECT ORDERS
    // =====================================================
    private void redirectOrders(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        response.sendRedirect(request.getContextPath() + "/orders");
    }
}