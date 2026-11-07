package controller;

import dao.BrandDAO;
import dao.CategoryDAO;
import dao.ProductDAO;
import model.Brand;
import model.Category;
import model.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import service.AuditLogService;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@WebServlet(name = "ProductServlet", urlPatterns = {"/product"})
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024 * 2, // 2MB
        maxFileSize = 1024 * 1024 * 10, // 10MB
        maxRequestSize = 1024 * 1024 * 50 // 50MB
)
public class ProductServlet extends HttpServlet {

    private final AuditLogService auditLogService
            = new AuditLogService();

    // =========================================================
    // GET (Hiển thị giao diện)
    // =========================================================
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String view = request.getParameter("view");
        ProductDAO productDao = new ProductDAO();

        if (view == null || view.equals("list")) {
            String searchKeyword = request.getParameter("search");
            List<Product> productList;

            if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
                productList = productDao.searchProducts(searchKeyword.trim());
            } else {
                productList = productDao.getList();
            }

            request.setAttribute("productList", productList);
            request.getRequestDispatcher("/WEB-INF/product/list.jsp").forward(request, response);
        } else if ("create".equals(view)) {
            BrandDAO brandDao = new BrandDAO();
            CategoryDAO categoryDao = new CategoryDAO();

            request.setAttribute("brandList", brandDao.getList());
            request.setAttribute("categoryList", categoryDao.getList());

            request.getRequestDispatcher("/WEB-INF/product/create.jsp").forward(request, response);
        } else if ("edit".equals(view)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = productDao.getById(id);

                if (product == null) {
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                    return;
                }

                // ===============================================
                // LẤY DANH SÁCH ẢNH PHỤ HIỂN THỊ LÊN FORM EDIT
                // ===============================================
                List<model.ProductImage> galleryImages = productDao.getProductImages(id);
                product.setGalleryImages(galleryImages);
                // ===============================================

                BrandDAO brandDao = new BrandDAO();
                CategoryDAO categoryDao = new CategoryDAO();

                request.setAttribute("product", product);
                request.setAttribute("brandList", brandDao.getList());
                request.setAttribute("categoryList", categoryDao.getList());

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

    // =========================================================
    // POST (Xử lý dữ liệu form)
    // =========================================================
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");
        ProductDAO productDao = new ProductDAO();

        String nameRegex = "^[\\p{L}\\p{N}\\s\\-]+$";

        try {
            // =====================================================
            // ACTION: CREATE
            // =====================================================
            if ("create".equals(action)) {
                String name = request.getParameter("name").trim();
                int categoryId = Integer.parseInt(request.getParameter("categoryId"));
                int brandId = Integer.parseInt(request.getParameter("brandId"));
                String description = request.getParameter("description");

                if (!name.matches(nameRegex)) {
                    request.getSession().setAttribute("errorMsg", "Tên sản phẩm không hợp lệ! Chỉ được dùng chữ cái, số, khoảng trắng và dấu gạch ngang (-).");
                    response.sendRedirect(request.getContextPath() + "/product?view=create");
                    return;
                }

                if (productDao.checkProductNameExists(name)) {
                    request.getSession().setAttribute("errorMsg", "Tên sản phẩm '" + name + "' đã tồn tại! Vui lòng chọn tên khác.");
                    response.sendRedirect(request.getContextPath() + "/product?view=create");
                    return;
                }

                // Xử lý upload ảnh chính (Ảnh nền)
                String imageUrl = uploadImage(request);

                // Xử lý upload ảnh phụ (Nhiều ảnh)
                List<String> galleryUrls = uploadMultipleImages(request, "galleryFiles");

                Product newProduct = new Product(categoryId, brandId, name, description, imageUrl);

                // GỌI HÀM insertReturnId ĐỂ LẤY ID SẢN PHẨM VỪA TẠO
                int newProductId = productDao.insertReturnId(newProduct);

                if (newProductId > 0) {
                    // Nếu có ảnh phụ, lưu vào bảng PRODUCT_IMAGES
                    if (!galleryUrls.isEmpty()) {
                        productDao.insertGalleryImages(newProductId, galleryUrls);
                    }
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                } else {
                    response.sendRedirect(request.getContextPath() + "/product?view=create&error=true");
                }
            } // =====================================================
            // ACTION: EDIT
            // =====================================================
            else if ("edit".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                String name = request.getParameter("name").trim();
                int categoryId = Integer.parseInt(request.getParameter("categoryId"));
                int brandId = Integer.parseInt(request.getParameter("brandId"));
                String description = request.getParameter("description");

                // ========================================================
                // Lấy danh sách ID các ảnh phụ cần xóa và gọi DAO xóa chúng
                // ========================================================
                String[] deleteImageIds = request.getParameterValues("deleteImageIds");
                if (deleteImageIds != null) {
                    for (String imageIdStr : deleteImageIds) {
                        try {
                            int imageId = Integer.parseInt(imageIdStr);
                            productDao.deleteGalleryImageById(imageId);
                        } catch (NumberFormatException ignored) {
                        }
                    }
                }
                // ========================================================

                if (!name.matches(nameRegex)) {
                    request.getSession().setAttribute("errorMsg", "Tên sản phẩm không hợp lệ! Chỉ được dùng chữ cái, số, khoảng trắng và dấu gạch ngang (-).");
                    response.sendRedirect(request.getContextPath() + "/product?view=edit&id=" + id);
                    return;
                }

                if (productDao.checkProductNameExistsForUpdate(name, id)) {
                    request.getSession().setAttribute("errorMsg", "Tên sản phẩm '" + name + "' đã bị trùng với một sản phẩm khác!");
                    response.sendRedirect(request.getContextPath() + "/product?view=edit&id=" + id);
                    return;
                }

                // Upload ảnh chính mới (nếu có thay đổi)
                String imageUrl = uploadImage(request);

                // Upload các ảnh phụ MỚI TẢI THÊM (nếu có)
                List<String> galleryUrls = uploadMultipleImages(request, "galleryFiles");

                Product product = new Product();
                product.setProductId(id);
                product.setProductName(name);
                product.setCategoryId(categoryId);
                product.setBrandId(brandId);
                product.setDescription(description);
                product.setImageUrl(imageUrl);

                int result = productDao.update(product);

                if (result > 0) {
                    // Nếu có upload ảnh phụ mới, thêm nó vào bảng PRODUCT_IMAGES
                    if (!galleryUrls.isEmpty()) {
                        productDao.insertGalleryImages(id, galleryUrls);
                    }
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                } else {
                    response.sendRedirect(request.getContextPath() + "/product?view=edit&id=" + id + "&error=true");
                }
            } // =====================================================
            // ACTION: DELETE
            // =====================================================
            else if ("delete".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                int result = productDao.delete(id);

                if (result > 0) {
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

    // =========================================================
    // 1. HÀM HỖ TRỢ UPLOAD 1 ẢNH (Ảnh đại diện chính)
    // =========================================================
    private String uploadImage(HttpServletRequest request) throws IOException, ServletException {
        Part filePart = request.getPart("imageFile");

        if (filePart != null && filePart.getSize() > 0) {
            String fileName = filePart.getSubmittedFileName();
            if (fileName != null && !fileName.trim().isEmpty()) {
                String uniqueFileName = UUID.randomUUID().toString() + "_" + fileName;
                String uploadPath = request.getServletContext().getRealPath("") + File.separator + "uploads" + File.separator + "products";
                File uploadDir = new File(uploadPath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }

                filePart.write(uploadPath + File.separator + uniqueFileName);
                return "uploads/products/" + uniqueFileName;
            }
        }
        return null;
    }

    // =========================================================
    // 2. HÀM HỖ TRỢ UPLOAD NHIỀU ẢNH (Ảnh phụ / Gallery)
    // =========================================================
    private List<String> uploadMultipleImages(HttpServletRequest request, String partName) throws IOException, ServletException {
        List<String> imageUrls = new ArrayList<>();
        String uploadPath = request.getServletContext().getRealPath("") + File.separator + "uploads" + File.separator + "products";
        File uploadDir = new File(uploadPath);

        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        // Lấy tất cả các file từ request
        for (Part part : request.getParts()) {
            if (part.getName().equals(partName) && part.getSize() > 0) {
                String fileName = part.getSubmittedFileName();
                if (fileName != null && !fileName.trim().isEmpty()) {
                    String uniqueFileName = UUID.randomUUID().toString() + "_" + fileName;
                    part.write(uploadPath + File.separator + uniqueFileName);
                    imageUrls.add("uploads/products/" + uniqueFileName);
                }
            }
        }
        return imageUrls;
    }
}
