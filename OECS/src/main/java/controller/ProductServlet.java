package controller;

import dao.AttributeDAO;
import dao.BrandDAO;
import dao.CategoryAttributeDAO;
import dao.CategoryDAO;
import dao.ProductDAO;

import model.Category;
import model.CategoryAttribute;
import model.Product;
import model.ProductImage;
import model.ProductSpec;

import service.ProductCatalogService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "ProductServlet",
        urlPatterns = {"/product"}
)
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024 * 2,
        maxFileSize = 1024 * 1024 * 10,
        maxRequestSize = 1024 * 1024 * 50
)
public class ProductServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(ProductServlet.class.getName());

    private static final String LIST_URL
            = "/product?view=list";

    private static final String UPLOAD_FOLDER
            = "uploads/products";

    private static final long MAX_IMAGE_SIZE
            = 10L * 1024 * 1024;

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String view = request.getParameter("view");

        if (view == null || "list".equals(view)) {
            showList(request, response);
            return;
        }

        switch (view) {

            case "create":
                showCreate(request, response);
                break;

            case "edit":
                showEdit(request, response);
                break;

            case "delete":
                showDelete(request, response);
                break;

            default:
                redirectToList(request, response);
                break;
        }
    }

    private void showList(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        ProductDAO productDAO = new ProductDAO();

        String keyword = request.getParameter("search");

        List<Product> productList;

        if (keyword != null && !keyword.trim().isEmpty()) {

            productList = productDAO.searchProducts(
                    keyword.trim()
            );

        } else {

            productList = productDAO.getList();
        }

        request.setAttribute(
                "productList",
                productList
        );

        request.getRequestDispatcher(
                "/WEB-INF/product/list.jsp"
        ).forward(request, response);
    }

    private void showCreate(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Integer categoryId = parseOptionalPositiveInt(
                request.getParameter("categoryId")
        );

        loadFormCommonAttributes(request, true);

        if (categoryId != null
                && isCategoryListedInForm(request, categoryId)) {

            loadCategoryAttributes(
                    request,
                    categoryId
            );

        } else {

            setEmptyCategoryAttributes(request);
        }

        request.getRequestDispatcher(
                "/WEB-INF/product/create.jsp"
        ).forward(request, response);
    }

    private void showEdit(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Integer productId = parseOptionalPositiveInt(
                request.getParameter("id")
        );

        if (productId == null) {
            redirectToList(request, response);
            return;
        }

        ProductDAO productDAO = new ProductDAO();

        Product product = productDAO.getById(productId);

        if (product == null) {
            redirectToList(request, response);
            return;
        }

        product.setGalleryImages(
                productDAO.getProductImages(productId)
        );

        request.setAttribute(
                "product",
                product
        );

        request.setAttribute(
                "productSpecs",
                productDAO.getProductSpecsForAdmin(productId)
        );

        loadFormCommonAttributes(request, false);

        loadCategoryAttributes(
                request,
                product.getCategoryId()
        );

        request.getRequestDispatcher(
                "/WEB-INF/product/edit.jsp"
        ).forward(request, response);
    }

    private void showDelete(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Integer productId = parseOptionalPositiveInt(
                request.getParameter("id")
        );

        if (productId == null) {
            redirectToList(request, response);
            return;
        }

        Product product
                = new ProductDAO().getById(productId);

        if (product == null) {
            redirectToList(request, response);
            return;
        }

        request.setAttribute(
                "product",
                product
        );

        request.getRequestDispatcher(
                "/WEB-INF/product/delete.jsp"
        ).forward(request, response);
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        try {

            if ("create".equals(action)) {

                createProduct(request, response);

            } else if ("edit".equals(action)) {

                updateProduct(request, response);

            } else if ("delete".equals(action)) {

                deleteProduct(request, response);

            } else {

                setError(
                        request,
                        "Thao tác không hợp lệ."
                );

                redirectToList(request, response);
            }

        } catch (IllegalArgumentException ex) {

            LOGGER.log(
                    Level.WARNING,
                    "Dữ liệu sản phẩm không hợp lệ",
                    ex
            );

            setError(
                    request,
                    ex.getMessage()
            );

            redirectToForm(
                    request,
                    response,
                    action
            );

        } catch (Exception ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Lỗi ProductServlet",
                    ex
            );

            setError(
                    request,
                    "Không thể lưu sản phẩm. "
                    + "Vui lòng kiểm tra lại dữ liệu."
            );

            redirectToForm(
                    request,
                    response,
                    action
            );
        }
    }

    private void createProduct(
            HttpServletRequest request,
            HttpServletResponse response)
            throws Exception {

        ProductDAO productDAO = new ProductDAO();

        Product product
                = readProductFromRequest(request);

        if (productDAO.checkProductNameExists(
                product.getProductName())) {

            throw new IllegalArgumentException(
                    "Tên sản phẩm đã tồn tại."
            );
        }

        List<ProductSpec> specifications
                = readSpecifications(request);

        List<Path> uploadedFiles
                = new ArrayList<>();

        boolean committed = false;

        try {

            String imageUrl = saveUploadedPart(
                    request.getPart("imageFile"),
                    request,
                    uploadedFiles
            );

            if (imageUrl == null) {

                throw new IllegalArgumentException(
                        "Vui lòng chọn ảnh đại diện."
                );
            }

            product.setImageUrl(imageUrl);

            List<String> galleryUrls
                    = uploadMultipleImages(
                            request,
                            "galleryFiles",
                            uploadedFiles
                    );

            ProductCatalogService service
                    = new ProductCatalogService();

            int productId = service.createProduct(
                    product,
                    specifications,
                    galleryUrls
            );

            if (productId <= 0) {

                throw new IllegalStateException(
                        "Không thể tạo sản phẩm."
                );
            }

            committed = true;

        } finally {

            if (!committed) {
                deleteUploadedFiles(uploadedFiles);
            }
        }

        setSuccess(
                request,
                "Thêm sản phẩm thành công."
        );

        redirectToList(request, response);
    }

    private void updateProduct(
            HttpServletRequest request,
            HttpServletResponse response)
            throws Exception {

        Integer productId = parseOptionalPositiveInt(
                request.getParameter("id")
        );

        if (productId == null) {

            throw new IllegalArgumentException(
                    "ID sản phẩm không hợp lệ."
            );
        }

        ProductDAO productDAO = new ProductDAO();

        Product oldProduct
                = productDAO.getById(productId);

        if (oldProduct == null) {

            throw new IllegalArgumentException(
                    "Sản phẩm không tồn tại."
            );
        }

        Product product
                = readProductFromRequest(request);

        product.setProductId(productId);

        if (product.getCategoryId()
                != oldProduct.getCategoryId()) {

            throw new IllegalArgumentException(
                    "Không thể đổi danh mục sản phẩm "
                    + "trong form chỉnh sửa."
            );
        }

        if (productDAO.checkProductNameExistsForUpdate(
                product.getProductName(),
                productId)) {

            throw new IllegalArgumentException(
                    "Tên sản phẩm đã tồn tại."
            );
        }

        List<ProductSpec> specifications
                = readSpecifications(request);

        List<Integer> deleteImageIds
                = readDeleteImageIds(request);

        List<Path> uploadedFiles
                = new ArrayList<>();

        boolean committed = false;

        try {

            String imageUrl = saveUploadedPart(
                    request.getPart("imageFile"),
                    request,
                    uploadedFiles
            );

            product.setImageUrl(imageUrl);

            List<String> galleryUrls
                    = uploadMultipleImages(
                            request,
                            "galleryFiles",
                            uploadedFiles
                    );

            ProductCatalogService service
                    = new ProductCatalogService();

            boolean success = service.updateProduct(
                    product,
                    specifications,
                    galleryUrls,
                    deleteImageIds
            );

            if (!success) {

                throw new IllegalStateException(
                        "Không thể cập nhật sản phẩm."
                );
            }

            committed = true;

        } finally {

            if (!committed) {
                deleteUploadedFiles(uploadedFiles);
            }
        }

        setSuccess(
                request,
                "Cập nhật sản phẩm thành công."
        );

        redirectToList(request, response);
    }

    private void deleteProduct(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        Integer productId = parseOptionalPositiveInt(
                request.getParameter("id")
        );

        if (productId == null) {
            throw new IllegalArgumentException(
                    "ID sản phẩm không hợp lệ."
            );
        }

        ProductDAO productDAO = new ProductDAO();

        int result = productDAO.delete(productId);

        if (result <= 0) {
            throw new IllegalStateException(
                    "Không thể xóa sản phẩm."
            );
        }

        setSuccess(
                request,
                "Đã xóa vĩnh viễn sản phẩm."
        );

        redirectToList(request, response);
    }

    private Product readProductFromRequest(
            HttpServletRequest request) {

        String name = trimToNull(
                request.getParameter("name")
        );

        Integer categoryId = parseOptionalPositiveInt(
                request.getParameter("categoryId")
        );

        Integer brandId = parseOptionalPositiveInt(
                request.getParameter("brandId")
        );

        if (name == null || name.length() > 255) {

            throw new IllegalArgumentException(
                    "Tên sản phẩm phải có từ 1 "
                    + "đến 255 ký tự."
            );
        }

        if (categoryId == null || brandId == null) {

            throw new IllegalArgumentException(
                    "Vui lòng chọn danh mục "
                    + "và thương hiệu."
            );
        }

        Category selectedCategory = new CategoryDAO().getById(categoryId);
        if (selectedCategory == null
                || selectedCategory.getParentId() == null) {

            throw new IllegalArgumentException(
                    "Vui lòng chọn danh mục con, không chọn danh mục cha."
            );
        }

        String modelCode = trimToNull(
                request.getParameter("modelCode")
        );

        if (modelCode != null
                && modelCode.length() > 100) {

            throw new IllegalArgumentException(
                    "Mã model vượt quá 100 ký tự."
            );
        }

        String description
                = request.getParameter("description");

        Product product = new Product(
                categoryId,
                brandId,
                name,
                description,
                null
        );

        product.setModelCode(modelCode);

        return product;
    }

    private List<ProductSpec> readSpecifications(
            HttpServletRequest request) {

        List<ProductSpec> specifications
                = new ArrayList<>();

        String[] attributeIds
                = request.getParameterValues("attributeIds");

        String[] specValues
                = request.getParameterValues("specValues");

        if (attributeIds == null
                && specValues == null) {

            return specifications;
        }

        if (attributeIds == null
                || specValues == null
                || attributeIds.length != specValues.length) {

            throw new IllegalArgumentException(
                    "Danh sách thông số không đồng bộ."
            );
        }

        Set<Integer> usedIds = new HashSet<>();

        for (int i = 0; i < attributeIds.length; i++) {

            String idText = attributeIds[i];

            String value = specValues[i] == null
                    ? ""
                    : specValues[i].trim();

            if ((idText == null || idText.trim().isEmpty())
                    && value.isEmpty()) {

                continue;
            }

            Integer attributeId
                    = parseOptionalPositiveInt(idText);

            if (attributeId == null) {

                throw new IllegalArgumentException(
                        "Attribute ID không hợp lệ."
                );
            }

            if (!usedIds.add(attributeId)) {

                throw new IllegalArgumentException(
                        "Thông số kỹ thuật bị trùng."
                );
            }

            if (value.length() > 255) {

                throw new IllegalArgumentException(
                        "Giá trị thông số vượt quá 255 ký tự."
                );
            }

            ProductSpec spec = new ProductSpec(
                    attributeId,
                    null,
                    value
            );

            specifications.add(spec);
        }

        return specifications;
    }

    private List<Integer> readDeleteImageIds(
            HttpServletRequest request) {

        List<Integer> imageIds
                = new ArrayList<>();

        String[] values
                = request.getParameterValues("deleteImageIds");

        if (values == null) {
            return imageIds;
        }

        Set<Integer> uniqueIds
                = new HashSet<>();

        for (String value : values) {

            Integer imageId
                    = parseOptionalPositiveInt(value);

            if (imageId == null) {

                throw new IllegalArgumentException(
                        "Image ID không hợp lệ."
                );
            }

            if (uniqueIds.add(imageId)) {
                imageIds.add(imageId);
            }
        }

        return imageIds;
    }

    private void loadFormCommonAttributes(
            HttpServletRequest request,
            boolean onlyActive) {

        BrandDAO brandDAO = new BrandDAO();
        CategoryDAO categoryDAO = new CategoryDAO();

        request.setAttribute(
                "brandList",
                onlyActive
                        ? brandDAO.getActiveBrands()
                        : brandDAO.getList()
        );

        List<Category> allCategories = onlyActive
                ? categoryDAO.getActiveCategories()
                : categoryDAO.getList();

        List<Category> childCategories = new ArrayList<>();
        for (Category category : allCategories) {
            if (category != null && category.getParentId() != null) {
                childCategories.add(category);
            }
        }

        request.setAttribute(
                "categoryList",
                childCategories
        );

        request.setAttribute(
                "attributeList",
                new AttributeDAO().getActiveAttributes()
        );
    }

    private boolean isCategoryListedInForm(
            HttpServletRequest request,
            int categoryId) {

        Object value = request.getAttribute("categoryList");
        if (!(value instanceof List<?>)) {
            return false;
        }

        for (Object item : (List<?>) value) {
            if (item instanceof Category) {
                Category category = (Category) item;
                if (category.getCategoryId() == categoryId) {
                    return true;
                }
            }
        }

        return false;
    }

    private void loadCategoryAttributes(
            HttpServletRequest request,
            int categoryId) {

        CategoryAttributeDAO dao
                = new CategoryAttributeDAO();

        List<CategoryAttribute> specificationAttributes
                = dao.getSpecificationAttributes(categoryId);

        List<CategoryAttribute> variantAttributes
                = dao.getVariantAttributes(categoryId);

        request.setAttribute(
                "specificationAttributes",
                specificationAttributes
        );

        request.setAttribute(
                "variantAttributes",
                variantAttributes
        );

        request.setAttribute(
                "selectedCategoryId",
                categoryId
        );
    }

    private void setEmptyCategoryAttributes(
            HttpServletRequest request) {

        request.setAttribute(
                "specificationAttributes",
                new ArrayList<CategoryAttribute>()
        );

        request.setAttribute(
                "variantAttributes",
                new ArrayList<CategoryAttribute>()
        );

        request.setAttribute(
                "selectedCategoryId",
                null
        );
    }

    private String saveUploadedPart(
            Part part,
            HttpServletRequest request,
            List<Path> uploadedFiles)
            throws IOException {

        if (part == null || part.getSize() == 0) {
            return null;
        }

        if (part.getSize() > MAX_IMAGE_SIZE) {

            throw new IllegalArgumentException(
                    "Mỗi ảnh không được vượt quá 10 MB."
            );
        }

        String contentType = part.getContentType();

        String extension;

        if ("image/jpeg".equalsIgnoreCase(contentType)) {

            extension = ".jpg";

        } else if ("image/png".equalsIgnoreCase(contentType)) {

            extension = ".png";

        } else if ("image/webp".equalsIgnoreCase(contentType)) {

            extension = ".webp";

        } else {

            throw new IllegalArgumentException(
                    "Chỉ hỗ trợ ảnh JPG, PNG và WEBP."
            );
        }

        String root
                = request.getServletContext().getRealPath("/");

        if (root == null) {

            throw new IOException(
                    "Không xác định được thư mục upload."
            );
        }

        Path uploadDirectory = Paths.get(
                root,
                "uploads",
                "products"
        );

        Files.createDirectories(uploadDirectory);

        String fileName
                = UUID.randomUUID().toString() + extension;

        Path destination
                = uploadDirectory.resolve(fileName);

        try (BufferedInputStream input
                = new BufferedInputStream(
                        part.getInputStream()
                )) {

            validateImageSignature(
                    input,
                    extension
            );

            uploadedFiles.add(destination);

            Files.copy(input, destination);
        }

        return UPLOAD_FOLDER + "/" + fileName;
    }

    private void validateImageSignature(
            BufferedInputStream input,
            String extension) throws IOException {

        input.mark(16);

        byte[] header = new byte[12];

        int length = 0;

        while (length < header.length) {

            int read = input.read(
                    header,
                    length,
                    header.length - length
            );

            if (read == -1) {
                break;
            }

            length += read;
        }

        input.reset();

        boolean valid = false;

        if (".jpg".equals(extension) && length >= 3) {

            valid
                    = (header[0] & 0xFF) == 0xFF
                    && (header[1] & 0xFF) == 0xD8
                    && (header[2] & 0xFF) == 0xFF;

        } else if (".png".equals(extension)
                && length >= 8) {

            int[] signature = {
                137, 80, 78, 71,
                13, 10, 26, 10
            };

            valid = true;

            for (int i = 0; i < signature.length; i++) {

                if ((header[i] & 0xFF) != signature[i]) {
                    valid = false;
                    break;
                }
            }

        } else if (".webp".equals(extension)
                && length >= 12) {

            valid
                    = header[0] == 'R'
                    && header[1] == 'I'
                    && header[2] == 'F'
                    && header[3] == 'F'
                    && header[8] == 'W'
                    && header[9] == 'E'
                    && header[10] == 'B'
                    && header[11] == 'P';
        }

        if (!valid) {

            throw new IllegalArgumentException(
                    "Nội dung file ảnh không hợp lệ."
            );
        }
    }

    private List<String> uploadMultipleImages(
            HttpServletRequest request,
            String partName,
            List<Path> uploadedFiles)
            throws IOException, ServletException {

        List<String> galleryUrls
                = new ArrayList<>();

        for (Part part : request.getParts()) {

            if (!partName.equals(part.getName())) {
                continue;
            }

            String url = saveUploadedPart(
                    part,
                    request,
                    uploadedFiles
            );

            if (url != null) {
                galleryUrls.add(url);
            }
        }

        return galleryUrls;
    }

    private void deleteUploadedFiles(
            List<Path> uploadedFiles) {

        for (Path path : uploadedFiles) {

            try {

                Files.deleteIfExists(path);

            } catch (IOException ex) {

                LOGGER.log(
                        Level.WARNING,
                        "Không xóa được file upload: " + path,
                        ex
                );
            }
        }
    }

    private Integer parseOptionalPositiveInt(
            String value) {

        if (value == null || value.trim().isEmpty()) {
            return null;
        }

        try {

            int result
                    = Integer.parseInt(value.trim());

            return result > 0 ? result : null;

        } catch (NumberFormatException ex) {

            return null;
        }
    }

    private String trimToNull(String value) {

        if (value == null || value.trim().isEmpty()) {
            return null;
        }

        return value.trim();
    }

    private void setError(
            HttpServletRequest request,
            String message) {

        request.getSession().setAttribute(
                "errorMsg",
                message
        );
    }

    private void setSuccess(
            HttpServletRequest request,
            String message) {

        request.getSession().setAttribute(
                "successMsg",
                message
        );
    }

    private void redirectToList(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        response.sendRedirect(
                request.getContextPath() + LIST_URL
        );
    }

    private void redirectToForm(
            HttpServletRequest request,
            HttpServletResponse response,
            String action)
            throws IOException {

        if ("create".equals(action)) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/product?view=create"
            );

            return;
        }

        if ("edit".equals(action)) {

            Integer productId = parseOptionalPositiveInt(
                    request.getParameter("id")
            );

            if (productId != null) {

                response.sendRedirect(
                        request.getContextPath()
                        + "/product?view=edit&id="
                        + productId
                );

                return;
            }
        }

        if ("delete".equals(action)) {

            Integer productId = parseOptionalPositiveInt(
                    request.getParameter("id")
            );

            if (productId != null) {

                response.sendRedirect(
                        request.getContextPath()
                        + "/product?view=delete&id="
                        + productId
                );

                return;
            }
        }

        redirectToList(request, response);
    }
}
