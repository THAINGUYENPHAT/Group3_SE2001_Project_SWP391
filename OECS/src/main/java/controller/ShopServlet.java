package controller;

import dao.ProductDAO;
import model.Product;
import model.ProductSKU;
import model.ProductSpecification;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

@WebServlet(name = "ShopServlet", urlPatterns = {"/shop"})
public class ShopServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        ProductDAO productDao = new ProductDAO();

        if (action == null || action.equals("catalog")) {
            // Hiển thị danh sách sản phẩm trang chủ cửa hàng
            List<Product> products = productDao.getList();
            request.setAttribute("products", products);
            request.getRequestDispatcher("/WEB-INF/shop/catalog.jsp").forward(request, response);

        } else if (action.equals("detail")) {
            // Xem chi tiết sản phẩm
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = productDao.getById(id);

                if (product != null) {
                    // Lấy Biến thể và Thông số kỹ thuật
                    List<ProductSKU> skus = productDao.getSkusByProductId(id);
                    List<ProductSpecification> specs = productDao.getSpecsByProductId(id);

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
        }
    }
}
