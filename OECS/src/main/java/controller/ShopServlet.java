package controller;

import dao.ShopDAO;
import dao.ProductReviewDAO;
import model.Product;
import model.ProductSku;
import model.ProductSpec;
import model.ProductReview;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@WebServlet(name = "ShopServlet", urlPatterns = {"/shop"})
public class ShopServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        ShopDAO shopDao = new ShopDAO();

        if ("detail".equals(action)) {
            // (Aganay a code para iti panid a Detail - saan a nasukatan)
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = shopDao.getProductDetail(id);

                if (product != null) {
                    List<ProductSku> skus = shopDao.getProductSkus(id);
                    List<ProductSpec> specs = shopDao.getProductSpecs(id);

                    // Lấy đánh giá của tất cả phiên bản thuộc sản phẩm
                    ProductReviewDAO reviewDao = new ProductReviewDAO();
                    List<ProductReview> reviews = new ArrayList<>();

                    if (skus != null) {
                        for (ProductSku sku : skus) {
                            List<ProductReview> skuReviews
                                    = reviewDao.getReviewsBySkuId(sku.getSkuId());

                            if (skuReviews != null) {
                                reviews.addAll(skuReviews);
                            }
                        }
                    }

                    // Sắp xếp đánh giá mới nhất lên đầu
                    reviews.sort(
                            Comparator.comparing(
                                    ProductReview::getCreatedAt,
                                    Comparator.nullsLast(Comparator.reverseOrder())
                            )
                    );

                    // Tính điểm trung bình
                    int totalReviews = reviews.size();
                    int ratingSum = 0;

                    for (ProductReview review : reviews) {
                        ratingSum += review.getRating();
                    }

                    double averageRating = totalReviews > 0
                            ? (double) ratingSum / totalReviews
                            : 0.0;

                    // Dữ liệu sản phẩm
                    request.setAttribute("product", product);
                    request.setAttribute("skus", skus);
                    request.setAttribute("specs", specs);

                    // Dữ liệu đánh giá
                    request.setAttribute("reviews", reviews);
                    request.setAttribute("totalReviews", totalReviews);
                    request.setAttribute("averageRating", averageRating);

                    if (request.getSession().getAttribute("reviewCsrfToken") == null) {
                        request.getSession().setAttribute(
                                "reviewCsrfToken",
                                UUID.randomUUID().toString()
                        );
                    }

                    request.getRequestDispatcher("/WEB-INF/shop/detail.jsp").forward(request, response);

                } else {
                    response.sendRedirect(request.getContextPath() + "/shop");
                }

            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/shop");
            }

        } else {
            // ==========================================
            // XỬ LÝ LỌC & HIỂN THỊ DANH SÁCH (CATALOG)
            // ==========================================
            String keyword = request.getParameter("keyword");
            String[] categoryIds = request.getParameterValues("categoryId");
            String priceRange = request.getParameter("priceRange");
            String sort = request.getParameter("sort");

            // Alaen dagiti data babaen ti baro a function iti DAO
            List<Product> catalog = shopDao.getFilteredCatalog(keyword, categoryIds, priceRange, sort);

            // Ipatulod dagiti data iti JSP
            request.setAttribute("catalog", catalog);
            request.setAttribute("searchKeyword", keyword);

            // Ipatulod dagiti state ti filter tapno agtalinaed a "checked" iti UI
            if (categoryIds != null) {
                request.setAttribute("selectedCats", Arrays.asList(categoryIds));
            }
            request.setAttribute("selectedPrice", priceRange);
            request.setAttribute("selectedSort", sort);

            request.getRequestDispatcher("/WEB-INF/shop/catalog.jsp").forward(request, response);
        }
    }
}
