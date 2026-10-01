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

    // =========================================================
    // GET
    // =========================================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String view = request.getParameter("view");

        ProductDAO productDao = new ProductDAO();

        // =====================================================
        // LIST
        // =====================================================
        if (view == null || view.equals("list")) {

            List<Product> productList = productDao.getList();

            request.setAttribute("productList", productList);

            request.getRequestDispatcher(
                    "/WEB-INF/product/list.jsp"
            ).forward(request, response);
        }

        // =====================================================
        // CREATE
        // =====================================================
        else if ("create".equals(view)) {

            BrandDAO brandDao = new BrandDAO();
            CategoryDAO categoryDao = new CategoryDAO();

            List<Brand> brandList = brandDao.getList();
            List<Category> categoryList = categoryDao.getList();

            request.setAttribute("brandList", brandList);
            request.setAttribute("categoryList", categoryList);

            request.getRequestDispatcher(
                    "/WEB-INF/product/create.jsp"
            ).forward(request, response);
        }

        // =====================================================
        // EDIT
        // =====================================================
        else if ("edit".equals(view)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                Product product = productDao.getById(id);

                if (product == null) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/product?view=list"
                    );

                    return;
                }

                BrandDAO brandDao = new BrandDAO();
                CategoryDAO categoryDao = new CategoryDAO();

                request.setAttribute("product", product);
                request.setAttribute(
                        "brandList",
                        brandDao.getList()
                );
                request.setAttribute(
                        "categoryList",
                        categoryDao.getList()
                );

                request.getRequestDispatcher(
                        "/WEB-INF/product/edit.jsp"
                ).forward(request, response);

            } catch (NumberFormatException e) {

                response.sendRedirect(
                        request.getContextPath()
                        + "/product?view=list"
                );
            }
        }

        // =====================================================
        // DELETE
        // =====================================================
        else if ("delete".equals(view)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                Product product = productDao.getById(id);

                if (product == null) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/product?view=list"
                    );

                    return;
                }

                request.setAttribute("product", product);

                request.getRequestDispatcher(
                        "/WEB-INF/product/delete.jsp"
                ).forward(request, response);

            } catch (NumberFormatException e) {

                response.sendRedirect(
                        request.getContextPath()
                        + "/product?view=list"
                );
            }
        }

        // =====================================================
        // VIEW KHÔNG HỢP LỆ
        // =====================================================
        else {

            response.sendRedirect(
                    request.getContextPath()
                    + "/product?view=list"
            );
        }
    }

    // =========================================================
    // POST
    // =========================================================
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        ProductDAO productDao = new ProductDAO();

        // =====================================================
        // CREATE
        // =====================================================
        if ("create".equals(action)) {

            try {

                String name = request.getParameter("name");
                String description =
                        request.getParameter("description");

                int categoryId = Integer.parseInt(
                        request.getParameter("categoryId")
                );

                int brandId = Integer.parseInt(
                        request.getParameter("brandId")
                );

                Product product = new Product(
                        0,
                        categoryId,
                        brandId,
                        name,
                        description,
                        null
                );

                int result = productDao.insert(product);

                if (result > 0) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/product?view=list"
                    );

                } else {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/product?view=create&error=true"
                    );
                }

            } catch (NumberFormatException e) {

                response.sendRedirect(
                        request.getContextPath()
                        + "/product?view=create&error=true"
                );
            }
        }

        // =====================================================
        // EDIT
        // =====================================================
        else if ("edit".equals(action)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                String name = request.getParameter("name");

                String description =
                        request.getParameter("description");

                int categoryId = Integer.parseInt(
                        request.getParameter("categoryId")
                );

                int brandId = Integer.parseInt(
                        request.getParameter("brandId")
                );

                Product product = new Product(
                        id,
                        categoryId,
                        brandId,
                        name,
                        description,
                        null
                );

                int result = productDao.update(product);

                if (result > 0) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/product?view=list"
                    );

                } else {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/product?view=edit&id="
                            + id
                            + "&error=true"
                    );
                }

            } catch (NumberFormatException e) {

                response.sendRedirect(
                        request.getContextPath()
                        + "/product?view=list"
                );
            }
        }

        // =====================================================
        // DELETE
        // =====================================================
        else if ("delete".equals(action)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                int result = productDao.delete(id);

                if (result > 0) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/product?view=list"
                    );

                } else {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/product?view=delete&id="
                            + id
                            + "&error=true"
                    );
                }

            } catch (NumberFormatException e) {

                response.sendRedirect(
                        request.getContextPath()
                        + "/product?view=list"
                );
            }
        }

        // =====================================================
        // ACTION KHÔNG HỢP LỆ
        // =====================================================
        else {

            response.sendRedirect(
                    request.getContextPath()
                    + "/product?view=list"
            );
        }
    }
}