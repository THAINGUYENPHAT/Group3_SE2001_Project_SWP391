package controller;

import dao.BrandDAO;
import dao.CategoryDAO;
import dao.ProductDAO;
import model.Brand;
import model.Category;
import model.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

@WebServlet(name = "ProductServlet", urlPatterns = {"/product"})
public class ProductServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String view = request.getParameter("view");
        ProductDAO productDao = new ProductDAO();

        if (view == null || view.equals("list")) {
            List<Product> productList = productDao.getList();
            request.setAttribute("productList", productList);
            request.getRequestDispatcher("/WEB-INF/product/list.jsp").forward(request, response);
        } 
        else if ("create".equals(view)) {
            // Lấy danh sách Brand và Category để hiển thị trên Dropdown/Select box
            BrandDAO brandDao = new BrandDAO();
            CategoryDAO categoryDao = new CategoryDAO();

            List<Brand> brandList = brandDao.getList();
            List<Category> categoryList = categoryDao.getList();

            request.setAttribute("brandList", brandList);
            request.setAttribute("categoryList", categoryList);

            // Hỗ trợ chọn sẵn Brand hoặc Category nếu có param truyền trên URL
            String brandIdRaw = request.getParameter("brandId");
            String categoryIdRaw = request.getParameter("categoryId");

            if (brandIdRaw != null && !brandIdRaw.trim().isEmpty()) {
                try {
                    request.setAttribute("preSelectedBrandId", Integer.parseInt(brandIdRaw));
                } catch (NumberFormatException ignored) {}
            }
            if (categoryIdRaw != null && !categoryIdRaw.trim().isEmpty()) {
                try {
                    request.setAttribute("preSelectedCategoryId", Integer.parseInt(categoryIdRaw));
                } catch (NumberFormatException ignored) {}
            }

            request.getRequestDispatcher("/WEB-INF/product/create.jsp").forward(request, response);
        } 
        else if ("edit".equals(view)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = productDao.getById(id);

                if (product != null) {
                    BrandDAO brandDao = new BrandDAO();
                    CategoryDAO categoryDao = new CategoryDAO();

                    request.setAttribute("product", product);
                    request.setAttribute("brandList", brandDao.getList());
                    request.setAttribute("categoryList", categoryDao.getList());

                    request.getRequestDispatcher("/WEB-INF/product/edit.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                }
            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/product?view=list");
            }
        } 
        else if ("delete".equals(view)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = productDao.getById(id);

                if (product != null) {
                    request.setAttribute("product", product);
                    request.getRequestDispatcher("/WEB-INF/product/delete.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                }
            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/product?view=list");
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");
        ProductDAO productDao = new ProductDAO();

        if ("create".equals(action)) {
            String name = request.getParameter("name");
            String description = request.getParameter("description");
            int categoryId = Integer.parseInt(request.getParameter("categoryId"));
            int brandId = Integer.parseInt(request.getParameter("brandId"));

            Category category = new Category();
            category.setCategoryId(categoryId);

            Brand brand = new Brand();
            brand.setBrandId(brandId);

            Product newProduct = new Product(0, name, description, category, brand, null);
            productDao.insert(newProduct);

            response.sendRedirect(request.getContextPath() + "/product?view=list");
        } 
        else if ("update".equals(action) || "edit".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            String name = request.getParameter("name");
            String description = request.getParameter("description");
            int categoryId = Integer.parseInt(request.getParameter("categoryId"));
            int brandId = Integer.parseInt(request.getParameter("brandId"));

            Category category = new Category();
            category.setCategoryId(categoryId);

            Brand brand = new Brand();
            brand.setBrandId(brandId);

            Product product = new Product(id, name, description, category, brand, null);
            productDao.update(product);

            response.sendRedirect(request.getContextPath() + "/product?view=list");
        } 
        else if ("delete".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            productDao.delete(id);

            response.sendRedirect(request.getContextPath() + "/product?view=list");
        }
    }
}