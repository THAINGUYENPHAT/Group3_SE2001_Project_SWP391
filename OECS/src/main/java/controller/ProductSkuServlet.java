package controller;

import dao.ProductDAO;
import dao.ProductSkuDAO;
import model.Product;
import model.ProductSku;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

@WebServlet(name = "ProductSkuServlet", urlPatterns = {"/product-sku"})
public class ProductSkuServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            int productId = Integer.parseInt(request.getParameter("productId"));

            ProductDAO productDao = new ProductDAO();
            Product product = productDao.getById(productId);

            if (product == null) {
                response.sendRedirect(request.getContextPath() + "/product?view=list");
                return;
            }

            ProductSkuDAO skuDao = new ProductSkuDAO();
            List<ProductSku> skuList = skuDao.getByProductId(productId);

            request.setAttribute("product", product);
            request.setAttribute("skuList", skuList);

            request.getRequestDispatcher("/WEB-INF/sku/list.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/product?view=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");
        ProductSkuDAO skuDao = new ProductSkuDAO();

        try {
            int productId = Integer.parseInt(request.getParameter("productId"));

            if ("create".equals(action)) {
                String skuCode = request.getParameter("skuCode");
                double price = Double.parseDouble(request.getParameter("price"));
                int stock = Integer.parseInt(request.getParameter("stock"));

                ProductSku sku = new ProductSku(0, productId, skuCode, price, stock);
                skuDao.insert(sku);

                response.sendRedirect(request.getContextPath() + "/product-sku?productId=" + productId);

            } else if ("delete".equals(action)) {
                int skuId = Integer.parseInt(request.getParameter("skuId"));
                skuDao.delete(skuId);

                response.sendRedirect(request.getContextPath() + "/product-sku?productId=" + productId);
            }
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/product?view=list");
        }
    }
}
