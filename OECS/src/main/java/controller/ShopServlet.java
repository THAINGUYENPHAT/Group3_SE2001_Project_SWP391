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
import java.util.List;

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
            // Mặc định hiển thị danh sách (Catalog)
            List<Product> catalog = shopDao.getCatalogProducts();
            request.setAttribute("catalog", catalog);
            request.getRequestDispatcher("/WEB-INF/shop/catalog.jsp").forward(request, response);
        }
    }
}
