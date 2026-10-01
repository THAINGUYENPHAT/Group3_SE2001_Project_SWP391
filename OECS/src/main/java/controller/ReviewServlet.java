package controller;

import dao.ProductReviewDAO;

import java.io.File;
import java.io.IOException;
import java.util.Collection;
import java.util.UUID;

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

@WebServlet(
        name = "ReviewServlet",
        urlPatterns = {"/review"}
)

@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 5 * 1024 * 1024,
        maxRequestSize = 20 * 1024 * 1024
)

public class ReviewServlet
        extends HttpServlet {

    private ProductReviewDAO reviewDAO;

    @Override
    public void init()
            throws ServletException {

        reviewDAO
                = new ProductReviewDAO();
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException,
            IOException {

        HttpSession session
                = request.getSession();

        User loggedInUser
                = (User) session.getAttribute(
                        "loggedInUser"
                );

        if (loggedInUser == null) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/login"
            );

            return;
        }

        try {

            int orderItemId
                    = Integer.parseInt(
                            request.getParameter(
                                    "orderItemId"
                            )
                    );

            int skuId
                    = reviewDAO
                            .getSkuIdByOrderItemId(
                                    orderItemId
                            );

            if (skuId == -1) {

                session.setAttribute(
                        "errorMessage",
                        "Sản phẩm trong đơn hàng không tồn tại."
                );

                redirectOrders(
                        request,
                        response
                );

                return;
            }

            boolean canReview
                    = reviewDAO.canReview(
                            loggedInUser.getUserId(),
                            orderItemId,
                            skuId
                    );

            if (!canReview) {

                session.setAttribute(
                        "errorMessage",
                        "Bạn không thể đánh giá sản phẩm này. "
                        + "Đơn hàng có thể chưa hoàn tất hoặc sản phẩm đã được đánh giá."
                );

                redirectOrders(
                        request,
                        response
                );

                return;
            }

            request.setAttribute(
                    "orderItemId",
                    orderItemId
            );

            request.setAttribute(
                    "skuId",
                    skuId
            );

            request.getRequestDispatcher(
                    "/WEB-INF/review/review.jsp"
            ).forward(
                    request,
                    response
            );

        } catch (NumberFormatException e) {

            session.setAttribute(
                    "errorMessage",
                    "Dữ liệu đánh giá không hợp lệ."
            );

            redirectOrders(
                    request,
                    response
            );
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException,
            IOException {

        request.setCharacterEncoding(
                "UTF-8"
        );

        HttpSession session
                = request.getSession();

        User loggedInUser
                = (User) session.getAttribute(
                        "loggedInUser"
                );

        if (loggedInUser == null) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/login"
            );

            return;
        }

        try {

            int orderItemId
                    = Integer.parseInt(
                            request.getParameter(
                                    "orderItemId"
                            )
                    );

            int rating
                    = Integer.parseInt(
                            request.getParameter(
                                    "rating"
                            )
                    );

            String comment
                    = request.getParameter(
                            "comment"
                    );

            if (rating < 1 || rating > 5) {

                session.setAttribute(
                        "errorMessage",
                        "Số sao phải từ 1 đến 5."
                );

                redirectBack(
                        request,
                        response,
                        orderItemId
                );

                return;
            }

            if (comment == null) {
                comment = "";
            }

            comment
                    = comment.trim();

            if (comment.length() > 2000) {

                session.setAttribute(
                        "errorMessage",
                        "Bình luận không được vượt quá 2000 ký tự."
                );

                redirectBack(
                        request,
                        response,
                        orderItemId
                );

                return;
            }

            int skuId
                    = reviewDAO
                            .getSkuIdByOrderItemId(
                                    orderItemId
                            );

            if (skuId == -1) {

                session.setAttribute(
                        "errorMessage",
                        "Không tìm thấy sản phẩm."
                );

                redirectOrders(
                        request,
                        response
                );

                return;
            }

            boolean canReview
                    = reviewDAO.canReview(
                            loggedInUser.getUserId(),
                            orderItemId,
                            skuId
                    );

            if (!canReview) {

                session.setAttribute(
                        "errorMessage",
                        "Bạn không đủ điều kiện đánh giá sản phẩm này."
                );

                redirectOrders(
                        request,
                        response
                );

                return;
            }

            ProductReview review
                    = new ProductReview();

            review.setUserId(
                    loggedInUser.getUserId()
            );

            review.setOrderItemId(
                    orderItemId
            );

            review.setSkuId(
                    skuId
            );

            review.setRating(
                    rating
            );

            review.setComment(
                    comment
            );

            int reviewId
                    = reviewDAO.insertReview(
                            review
                    );

            if (reviewId == -1) {

                session.setAttribute(
                        "errorMessage",
                        "Không thể tạo đánh giá."
                );

                redirectBack(
                        request,
                        response,
                        orderItemId
                );

                return;
            }

            saveImages(
                    request,
                    reviewId
            );

            session.setAttribute(
                    "successMessage",
                    "Đánh giá sản phẩm thành công."
            );

            redirectOrders(
                    request,
                    response
            );

        } catch (NumberFormatException e) {

            session.setAttribute(
                    "errorMessage",
                    "Dữ liệu đánh giá không hợp lệ."
            );

            redirectOrders(
                    request,
                    response
            );
        }
    }

    private void saveImages(
            HttpServletRequest request,
            int reviewId)
            throws IOException,
            ServletException {

        Collection<Part> parts
                = request.getParts();

        int imageCount = 0;

        for (Part part : parts) {

            if (!"images".equals(
                    part.getName())) {

                continue;
            }

            String originalName
                    = part.getSubmittedFileName();

            if (originalName == null
                    || originalName.trim().isEmpty()
                    || part.getSize() == 0) {

                continue;
            }

            if (imageCount >= 3) {
                break;
            }

            String extension
                    = getExtension(
                            originalName
                    );

            if (!isAllowedImage(
                    extension)) {

                continue;
            }

            String fileName
                    = UUID.randomUUID()
                            .toString()
                    + extension;


            String uploadDirectory
                    = getServletContext()
                            .getRealPath(
                                    "/uploads/reviews"
                            );

            File directory
                    = new File(
                            uploadDirectory
                    );

            if (!directory.exists()) {
                directory.mkdirs();
            }

            String filePath
                    = uploadDirectory
                    + File.separator
                    + fileName;

            part.write(
                    filePath
            );

            String imageUrl
                    = "/uploads/reviews/"
                    + fileName;

            reviewDAO
                    .insertReviewImage(
                            reviewId,
                            imageUrl
                    );

            imageCount++;
        }
    }

    private String getExtension(
            String fileName) {

        int index
                = fileName.lastIndexOf(".");

        if (index == -1) {
            return "";
        }

        return fileName
                .substring(index)
                .toLowerCase();
    }

    private boolean isAllowedImage(
            String extension) {

        return ".jpg".equals(extension)
                || ".jpeg".equals(extension)
                || ".png".equals(extension)
                || ".webp".equals(extension);
    }

    private void redirectBack(
            HttpServletRequest request,
            HttpServletResponse response,
            int orderItemId)
            throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/review?orderItemId="
                + orderItemId
        );
    }

    private void redirectOrders(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {


        response.sendRedirect(
                request.getContextPath()
                + "/orders"
        );
    }
}
