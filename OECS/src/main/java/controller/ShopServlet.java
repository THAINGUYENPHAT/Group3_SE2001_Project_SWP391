package controller;

import dao.ShopDAO;
import model.Product;
import model.ProductSku;
import model.ProductSpec;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

@WebServlet(name = "ShopServlet", urlPatterns = {"/shop"})
public class ShopServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        ShopDAO shopDao = new ShopDAO();

        if ("detail".equals(action)) {
            // Xử lý xem chi tiết sản phẩm
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = shopDao.getProductDetail(id);

                if (product != null) {
                    List<ProductSku> skus = shopDao.getProductSkus(id);
                    List<ProductSpec> specs = shopDao.getProductSpecs(id);

                    request.setAttribute("product", product);
                    request.setAttribute("skus", skus);
                    request.setAttribute("specs", specs);

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

            // Lấy dữ liệu qua hàm tìm kiếm / lọc trong DAO
            List<Product> catalog = shopDao.getFilteredCatalog(keyword, categoryIds, priceRange, sort);

            // Gửi dữ liệu danh sách sản phẩm sang JSP
            request.setAttribute("catalog", catalog);
            request.setAttribute("searchKeyword", keyword);

            // Gửi trạng thái filter để giữ nguyên nút "checked" trên UI
            if (categoryIds != null) {
                request.setAttribute("selectedCats", Arrays.asList(categoryIds));
            }
            request.setAttribute("selectedPrice", priceRange);
            request.setAttribute("selectedSort", sort);

            request.getRequestDispatcher("/WEB-INF/shop/catalog.jsp").forward(request, response);
        }
    }
}
