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

        // =====================================================
        // VIEW: LIST & SEARCH
        // =====================================================
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
        } // =====================================================
        // VIEW: CREATE
        // =====================================================
        else if ("create".equals(view)) {
            BrandDAO brandDao = new BrandDAO();
            CategoryDAO categoryDao = new CategoryDAO();

            request.setAttribute("brandList", brandDao.getList());
            request.setAttribute("categoryList", categoryDao.getList());

            request.getRequestDispatcher("/WEB-INF/product/create.jsp").forward(request, response);
        } // =====================================================
        // VIEW: EDIT
        // =====================================================
        else if ("edit".equals(view)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = productDao.getById(id);

                if (product == null) {
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                    return;
                }

                BrandDAO brandDao = new BrandDAO();
                CategoryDAO categoryDao = new CategoryDAO();

                request.setAttribute("product", product);
                request.setAttribute("brandList", brandDao.getList());
                request.setAttribute("categoryList", categoryDao.getList());

                request.getRequestDispatcher("/WEB-INF/product/edit.jsp").forward(request, response);

            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/product?view=list");
            }
        } // =====================================================
        // VIEW: DELETE
        // =====================================================
        else if ("delete".equals(view)) {
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
        } // =====================================================
        // VIEW KHÔNG HỢP LỆ
        // =====================================================
        else {
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

        try {
            // =====================================================
            // ACTION: CREATE
            // =====================================================
            if ("create".equals(action)) {
                String name = request.getParameter("name");
                int categoryId = Integer.parseInt(request.getParameter("categoryId"));
                int brandId = Integer.parseInt(request.getParameter("brandId"));
                String description = request.getParameter("description");

                // Xử lý upload ảnh
                String imageUrl = uploadImage(request);

                Product newProduct = new Product(categoryId, brandId, name, description, imageUrl);
                int result = productDao.insert(newProduct);

                if (result > 0) {
                    response.sendRedirect(request.getContextPath() + "/product?view=list");
                } else {
                    response.sendRedirect(request.getContextPath() + "/product?view=create&error=true");
                }
            } // =====================================================
            // ACTION: EDIT
            // =====================================================
            else if ("edit".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                String name = request.getParameter("name");
                int categoryId = Integer.parseInt(request.getParameter("categoryId"));
                int brandId = Integer.parseInt(request.getParameter("brandId"));
                String description = request.getParameter("description");

                // Xử lý upload ảnh (Sẽ trả về null nếu không chọn ảnh mới)
                String imageUrl = uploadImage(request);

                Product product = new Product();
                product.setProductId(id);
                product.setProductName(name);
                product.setCategoryId(categoryId);
                product.setBrandId(brandId);
                product.setDescription(description);
                product.setImageUrl(imageUrl); // DAO sẽ tự giữ nguyên ảnh cũ nếu imageUrl = null do dùng COALESCE

                int result = productDao.update(product);

                if (result > 0) {
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
            } // =====================================================
            // ACTION KHÔNG HỢP LỆ
            // =====================================================
            else {
                response.sendRedirect(request.getContextPath() + "/product?view=list");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/product?view=list");
        }
    }

    // =========================================================
    // HÀM HỖ TRỢ UPLOAD ẢNH
    // =========================================================
    private String uploadImage(HttpServletRequest request) throws IOException, ServletException {
        Part filePart = request.getPart("imageFile"); // Phải khớp với name="imageFile" trong form JSP

        if (filePart != null && filePart.getSize() > 0) {
            String fileName = filePart.getSubmittedFileName();

            if (fileName != null && !fileName.trim().isEmpty()) {
                // Thêm UUID để tránh trùng lặp tên file
                String uniqueFileName = UUID.randomUUID().toString() + "_" + fileName;

                // Đường dẫn thư mục lưu ảnh (nằm trong root project)
                String uploadPath = request.getServletContext().getRealPath("") + File.separator + "uploads" + File.separator + "products";
                File uploadDir = new File(uploadPath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs(); // Tạo thư mục nếu chưa tồn tại
                }

                // Lưu file vật lý
                filePart.write(uploadPath + File.separator + uniqueFileName);

                // Trả về đường dẫn tương đối để lưu vào CSDL
                return "uploads/products/" + uniqueFileName;
            }
        }
        return null; // Trả về null nếu người dùng không chọn file ảnh nào
    }
}
