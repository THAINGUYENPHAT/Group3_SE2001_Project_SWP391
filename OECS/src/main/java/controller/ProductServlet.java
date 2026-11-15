package controller;

import dao.BrandDAO;
import dao.CategoryDAO;
import dao.ProductDAO;
import model.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@WebServlet(name = "ProductServlet", urlPatterns = {"/product"})
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024 * 2,
        maxFileSize = 1024 * 1024 * 10,
        maxRequestSize = 1024 * 1024 * 50
)
public class ProductServlet extends HttpServlet {

    private static final String NAME_REGEX = "^[\\p{L}\\p{N}\\s\\-]+$";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String view = request.getParameter("view");
        ProductDAO productDao = new ProductDAO();

        if (view == null || view.equals("list")) {
            String searchKeyword = request.getParameter("search");
            List<Product> productList = (searchKeyword != null && !searchKeyword.trim().isEmpty())
                    ? productDao.searchProducts(searchKeyword.trim())
                    : productDao.getList();

            request.setAttribute("productList", productList);
            request.getRequestDispatcher("/WEB-INF/product/list.jsp").forward(request, response);

        } else if ("create".equals(view)) {
            loadFormCommonAttributes(request, productDao);
            request.getRequestDispatcher("/WEB-INF/product/create.jsp").forward(request, response);

        } else if ("edit".equals(view)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = productDao.getById(id);

                if (product == null) {
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                    return;
                }

                product.setGalleryImages(productDao.getProductImages(id));

                request.setAttribute("product", product);
                request.setAttribute("productSpecs", productDao.getProductSpecsForAdmin(id));
                loadFormCommonAttributes(request, productDao);

                request.getRequestDispatcher("/WEB-INF/product/edit.jsp").forward(request, response);

            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/product?view=list");
            }
        } else if ("delete".equals(view)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = productDao.getById(id);

                if (product == null) {
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                    return;
                }

                request.setAttribute("product", product);
                request.getRequestDispatcher("/WEB-INF/product/delete.jsp").forward(request, response);

            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/product?view=list");
            }
        } else {
            response.sendRedirect(request.getContextPath() + "/product?view=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");
        ProductDAO productDao = new ProductDAO();

        try {
            if ("create".equals(action)) {
                String name = request.getParameter("name").trim();
                int categoryId = Integer.parseInt(request.getParameter("categoryId"));
                int brandId = Integer.parseInt(request.getParameter("brandId"));
                String description = request.getParameter("description");

                if (!name.matches(NAME_REGEX)) {
                    request.getSession().setAttribute("errorMsg", "Tên sản phẩm không hợp lệ! Chỉ được dùng chữ cái, số, khoảng trắng và dấu gạch ngang (-).");
                    response.sendRedirect(request.getContextPath() + "/product?view=create");
                    return;
                }

                if (productDao.checkProductNameExists(name)) {
                    request.getSession().setAttribute("errorMsg", "Tên sản phẩm '" + name + "' đã tồn tại! Vui lòng chọn tên khác.");
                    response.sendRedirect(request.getContextPath() + "/product?view=create");
                    return;
                }

                String imageUrl = saveUploadedPart(request.getPart("imageFile"), request);
                List<String> galleryUrls = uploadMultipleImages(request, "galleryFiles");

                Product newProduct = new Product(categoryId, brandId, name, description, imageUrl);
                int newProductId = productDao.insertReturnId(newProduct);

                if (newProductId > 0) {
                    if (!galleryUrls.isEmpty()) {
                        productDao.insertGalleryImages(newProductId, galleryUrls);
                    }
                    productDao.saveProductSpecs(
                            newProductId,
                            request.getParameterValues("attributeIds"),
                            request.getParameterValues("specValues")
                    );
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                } else {
                    response.sendRedirect(request.getContextPath() + "/product?view=create&error=true");
                }

            } else if ("edit".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                String name = request.getParameter("name").trim();
                int categoryId = Integer.parseInt(request.getParameter("categoryId"));
                int brandId = Integer.parseInt(request.getParameter("brandId"));
                String description = request.getParameter("description");

                String[] deleteImageIds = request.getParameterValues("deleteImageIds");
                if (deleteImageIds != null) {
                    for (String imageIdStr : deleteImageIds) {
                        try {
                            productDao.deleteGalleryImageById(Integer.parseInt(imageIdStr));
                        } catch (NumberFormatException ignored) {
                        }
                    }
                }

                if (!name.matches(NAME_REGEX)) {
                    request.getSession().setAttribute("errorMsg", "Tên sản phẩm không hợp lệ! Chỉ được dùng chữ cái, số, khoảng trắng và dấu gạch ngang (-).");
                    response.sendRedirect(request.getContextPath() + "/product?view=edit&id=" + id);
                    return;
                }

                if (productDao.checkProductNameExistsForUpdate(name, id)) {
                    request.getSession().setAttribute("errorMsg", "Tên sản phẩm '" + name + "' đã bị trùng với một sản phẩm khác!");
                    response.sendRedirect(request.getContextPath() + "/product?view=edit&id=" + id);
                    return;
                }

                String imageUrl = saveUploadedPart(request.getPart("imageFile"), request);
                List<String> galleryUrls = uploadMultipleImages(request, "galleryFiles");

                Product product = new Product(categoryId, brandId, name, description, imageUrl);
                product.setProductId(id);

                if (productDao.update(product) > 0) {
                    if (!galleryUrls.isEmpty()) {
                        productDao.insertGalleryImages(id, galleryUrls);
                    }
                    productDao.saveProductSpecs(
                            id,
                            request.getParameterValues("attributeIds"),
                            request.getParameterValues("specValues")
                    );
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                } else {
                    response.sendRedirect(request.getContextPath() + "/product?view=edit&id=" + id + "&error=true");
                }

            } else if ("delete".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                if (productDao.delete(id) > 0) {
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                } else {
                    response.sendRedirect(request.getContextPath() + "/product?view=delete&id=" + id + "&error=true");
                }
            } else {
                response.sendRedirect(request.getContextPath() + "/product?view=list");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/product?view=list");
        }
    }

    private void loadFormCommonAttributes(HttpServletRequest request, ProductDAO productDao) {
        request.setAttribute("brandList", new BrandDAO().getList());
        request.setAttribute("categoryList", new CategoryDAO().getList());
        request.setAttribute("attributeList", productDao.getAllAttributes());
    }

    private String saveUploadedPart(Part part, HttpServletRequest request) throws IOException {
        if (part != null && part.getSize() > 0) {
            String fileName = part.getSubmittedFileName();
            if (fileName != null && !fileName.trim().isEmpty()) {
                String uploadPath = request.getServletContext().getRealPath("")
                        + File.separator + "uploads" + File.separator + "products";
                File uploadDir = new File(uploadPath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }

                String uniqueFileName = UUID.randomUUID() + "_" + fileName.trim();
                part.write(uploadPath + File.separator + uniqueFileName);
                return "uploads/products/" + uniqueFileName;
            }
        }
        return null;
    }

    private List<String> uploadMultipleImages(HttpServletRequest request, String partName)
            throws IOException, ServletException {
        List<String> imageUrls = new ArrayList<>();
        for (Part part : request.getParts()) {
            if (partName.equals(part.getName())) {
                String url = saveUploadedPart(part, request);
                if (url != null) {
                    imageUrls.add(url);
                }
            }
        }
        return imageUrls;
    }
}
