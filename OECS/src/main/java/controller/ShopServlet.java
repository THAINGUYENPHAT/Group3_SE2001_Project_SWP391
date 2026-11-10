package controller;

import dao.ShopDAO;
import dao.ProductReviewDAO;
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

import java.io.IOException;
import java.util.Arrays;
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
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = shopDao.getProductDetail(id);

                if (product != null) {
                    
                    List<ProductImage> galleryImages = shopDao.getProductImages(id);
                    product.setGalleryImages(galleryImages);

                    List<ProductSku> skus = shopDao.getProductSkus(id);
                    List<ProductSpec> specs = shopDao.getProductSpecs(id);

                    ProductReviewDAO reviewDao = new ProductReviewDAO();

                    List<ProductReview> reviews
                            = reviewDao.getReviewsByProductId(id);
                    System.out.println("========== REVIEW DEBUG ==========");
                    System.out.println("Product ID: " + id);
                    System.out.println("Total reviews: " + reviews.size());

                    for (ProductReview review : reviews) {
                        System.out.println(
                                "Review ID: " + review.getReviewId()
                                + " | SKU ID: " + review.getSkuId()
                                + " | Rating: " + review.getRating()
                        );
                    }

                    System.out.println("==================================");

                    int purchaseCount = reviewDao.getPurchaseCountByProductId(id);
                    int totalReviews = reviews.size();
                    int ratingSum = 0;

                    for (ProductReview review : reviews) {
                        ratingSum += review.getRating();
                    }

                    double averageRating = totalReviews > 0
                            ? (double) ratingSum / totalReviews
                            : 0.0;

                    request.setAttribute("product", product);
                    request.setAttribute("skus", skus);
                    request.setAttribute("specs", specs);
                    request.setAttribute("purchaseCount", purchaseCount);

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
           
            String keyword = request.getParameter("keyword");
            String[] categoryIds = request.getParameterValues("categoryId");
            String priceRange = request.getParameter("priceRange");
            String sort = request.getParameter("sort");

            List<Product> catalog = shopDao.getFilteredCatalog(keyword, categoryIds, priceRange, sort);

            request.setAttribute("catalog", catalog);
            request.setAttribute("searchKeyword", keyword);

            if (categoryIds != null) {
                request.setAttribute("selectedCats", Arrays.asList(categoryIds));
            }
            request.setAttribute("selectedPrice", priceRange);
            request.setAttribute("selectedSort", sort);

            request.getRequestDispatcher("/WEB-INF/shop/catalog.jsp").forward(request, response);
        }
    }
}
