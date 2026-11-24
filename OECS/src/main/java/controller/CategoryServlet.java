package controller;

import dao.CategoryDAO;
import dao.CategoryRoleConfigDAO;
import model.Category;
import model.User;
import service.AuditLogService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "CategoryServlet", urlPatterns = {"/category"})
public class CategoryServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(CategoryServlet.class.getName());

    private final AuditLogService auditLogService
            = new AuditLogService();

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String view = request.getParameter("view");
        CategoryDAO dao = new CategoryDAO();

        // Hai khu vực quản lý thuộc tính theo danh mục (DB6, không tạo UC mới).
        if ("variantAttributes".equals(view) || "specificationAttributes".equals(view)) {
            showRoleAttributes(request, response, dao,
                    "variantAttributes".equals(view) ? "VARIANT" : "SPECIFICATION");
            return;
        }
        if ("attributes".equals(view) || "attributeForm".equals(view)) {
            // Tương thích liên kết cũ; không dùng CRUD global trước đây nữa.
            response.sendRedirect(request.getContextPath()
                    + "/category?view=specificationAttributes");
            return;
        }

        if (view == null || view.equals("list")) {

            String keyword = request.getParameter("keyword");
            keyword = keyword == null ? "" : keyword.trim();

            List<Category> allCategories = dao.getList();

// Tra cuu danh muc bang ID, khong can query DB lan nua.
            Map<Integer, Category> categoriesById = new HashMap<>();
            Map<Integer, String> categoryNames = new HashMap<>();

            for (Category category : allCategories) {

                int categoryId = category.getCategoryId();

                categoriesById.put(categoryId, category);

                // Ten chi dung de hien thi tren JSP.
                categoryNames.put(
                        categoryId,
                        category.getCategoryName()
                );
            }

            Map<Integer, Integer> categoryDepths = new HashMap<>();

            List<Category> treeList = buildCategoryTree(
                    allCategories, categoryDepths
            );

            Set<Integer> matchedIds = new HashSet<>();

            if (keyword.isEmpty()) {
                for (Category category : treeList) {
                    matchedIds.add(category.getCategoryId());
                }
            } else {
                String searchKeyword = keyword.toLowerCase();

                for (Category category : treeList) {
                    String name = category.getCategoryName();

                    if (name != null
                            && name.toLowerCase().contains(searchKeyword)) {

                        matchedIds.add(category.getCategoryId());

                        Integer parentId = category.getParentId();
                        Set<Integer> visitedParents = new HashSet<>();

                        while (parentId != null
                                && visitedParents.add(parentId)) {

                            matchedIds.add(parentId);

                            Category parent = categoriesById.get(parentId);

                            if (parent == null) {
                                break;
                            }

                            parentId = parent.getParentId();
                        }
                    }
                }
            }

            List<Category> categoryList = new ArrayList<>();

            for (Category category : treeList) {
                if (matchedIds.contains(category.getCategoryId())) {
                    categoryList.add(category);
                }
            }

            int totalCategories = categoryList.size();

            Map<Integer, Integer> productCounts
                    = dao.getProductCounts(categoryList);

            Map<Integer, Integer> childCounts
                    = dao.getChildCounts(categoryList);

            request.setAttribute("categoryList", categoryList);
            request.setAttribute("categoryDepths", categoryDepths);
            request.setAttribute("keyword", keyword);
            request.setAttribute("productCounts", productCounts);
            request.setAttribute("childCounts", childCounts);
            request.setAttribute("categoryNames", categoryNames);
            request.setAttribute("totalCategories", totalCategories);

            request.getRequestDispatcher(
                    "/WEB-INF/category/list.jsp"
            ).forward(request, response);

        } else if ("create".equals(view)) {

            request.setAttribute("categoryList", dao.getList());

            request.getRequestDispatcher(
                    "/WEB-INF/category/create.jsp"
            ).forward(request, response);

        } else if ("edit".equals(view)) {

            try {
                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                Category category = dao.getById(id);

                if (category == null) {
                    response.sendRedirect(
                            request.getContextPath()
                            + "/category?view=list"
                    );
                    return;
                }

                prepareSpecificationEditor(request, category, dao);

                request.getRequestDispatcher(
                        "/WEB-INF/category/edit.jsp"
                ).forward(request, response);

            } catch (NumberFormatException e) {
                response.sendRedirect(
                        request.getContextPath()
                        + "/category?view=list"
                );
            }

        } else if ("delete".equals(view)) {

            try {
                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                if (id <= 0) {
                    throw new NumberFormatException();
                }

                Category category = dao.getById(id);

                if (category == null) {
                    response.sendRedirect(
                            request.getContextPath()
                            + "/category?view=list&error=notFound"
                    );
                    return;
                }

                int productCount
                        = dao.countProductsByCategoryId(id);

                int childCount
                        = dao.countChildCategories(id);

                request.setAttribute("category", category);
                request.setAttribute("productCount", productCount);
                request.setAttribute("childCount", childCount);

                request.getRequestDispatcher(
                        "/WEB-INF/category/delete.jsp"
                ).forward(request, response);

            } catch (NumberFormatException e) {
                LOGGER.log(
                        Level.WARNING,
                        "Invalid ID when opening Delete Category",
                        e
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/category?view=list&error=invalidId"
                );
            }

        } else {
            response.sendRedirect(
                    request.getContextPath()
                    + "/category?view=list"
            );
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        CategoryDAO dao = new CategoryDAO();
        String contextPath = request.getContextPath();

        if ("saveRoleMapping".equals(action)
                || "removeRoleMapping".equals(action)
                || "updateRoleDefinition".equals(action)
                || "hardDeleteAttribute".equals(action)) {
            handleRoleAction(request, response, dao, action);
            return;
        }
        if ("saveAttribute".equals(action)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "Form thuộc tính cũ đã ngừng sử dụng. Hãy mở lại Quản lý danh mục.");
            return;
        }

        if ("create".equals(action)) {

            try {
                String name = request.getParameter("name");
                String parentIdText
                        = request.getParameter("parentId");

                if (name == null || name.trim().isEmpty()) {
                    forwardCreateWithError(
                            request, response, dao,
                            "Vui lòng nhập tên danh mục.",
                            name
                    );
                    return;
                }

                name = name.trim();

                if (!isValidCategoryName(name)) {
                    forwardCreateWithError(
                            request, response, dao,
                            "Tên danh mục chỉ được chứa chữ cái, chữ số và khoảng trắng.",
                            name
                    );
                    return;
                }

                if (dao.isCategoryNameExists(name)) {
                    forwardCreateWithError(
                            request, response, dao,
                            "Tên danh mục đã tồn tại. Vui lòng nhập tên khác.",
                            name
                    );
                    return;
                }

                Integer parentId = null;

                if (parentIdText != null
                        && !parentIdText.trim().isEmpty()) {
                    parentId = Integer.parseInt(parentIdText);
                }

                if (parentId != null
                        && dao.getById(parentId) == null) {

                    forwardCreateWithError(
                            request, response, dao,
                            "Danh mục cha không tồn tại.",
                            name
                    );
                    return;
                }

                Category category = new Category(
                        0, name, parentId
                );

                int result = dao.insert(category);

                if (result > 0) {

                    User loggedInUser
                            = (User) request.getSession()
                                    .getAttribute("loggedInUser");

                    auditLogService.log(
                            loggedInUser,
                            "CREATE_CATEGORY",
                            "CATEGORY",
                            null,
                            "Created category: " + name,
                            request
                    );

                    response.sendRedirect(
                            contextPath + "/category?view=list"
                    );
                } else {
                    forwardCreateWithError(
                            request, response, dao,
                            "Không thể thêm danh mục. Vui lòng thử lại.",
                            name
                    );
                }

            } catch (Exception e) {
                LOGGER.log(
                        Level.SEVERE,
                        "Cannot create category",
                        e
                );

                forwardCreateWithError(
                        request, response, dao,
                        "Đã xảy ra lỗi khi thêm danh mục.",
                        request.getParameter("name")
                );
            }

        } else if ("saveSpecifications".equals(action)) {

            saveSpecificationConfiguration(request, response, dao);

        } else if ("edit".equals(action)) {

            int id = 0;

            try {
                id = Integer.parseInt(
                        request.getParameter("id")
                );

                String name = request.getParameter("name");
                String parentIdText
                        = request.getParameter("parentId");

                Category currentCategory = dao.getById(id);

                if (currentCategory == null) {
                    response.sendRedirect(
                            contextPath + "/category?view=list"
                    );
                    return;
                }

                if (name == null || name.trim().isEmpty()) {
                    forwardEditWithError(
                            request, response, dao, currentCategory,
                            "Vui lòng nhập tên danh mục.",
                            name
                    );
                    return;
                }

                name = name.trim();

                if (!isValidCategoryName(name)) {
                    forwardEditWithError(
                            request, response, dao, currentCategory,
                            "Tên danh mục chỉ được chứa chữ cái, chữ số và khoảng trắng.",
                            name
                    );
                    return;
                }

                if (dao.isCategoryNameExists(name, id)) {
                    forwardEditWithError(
                            request, response, dao, currentCategory,
                            "Tên danh mục đã tồn tại. Vui lòng nhập tên khác.",
                            name
                    );
                    return;
                }

                Integer parentId = null;

                if (parentIdText != null
                        && !parentIdText.trim().isEmpty()) {
                    parentId = Integer.parseInt(parentIdText);
                }

                if (parentId != null) {
                    if (parentId == id
                            || dao.getById(parentId) == null) {

                        forwardEditWithError(
                                request, response, dao, currentCategory,
                                "Danh mục cha không hợp lệ.",
                                name
                        );
                        return;
                    }

                    if (isDescendant(dao, parentId, id)) {
                        forwardEditWithError(
                                request, response, dao, currentCategory,
                                "Không thể chọn danh mục con làm danh mục cha.",
                                name
                        );
                        return;
                    }
                }

                Category category = new Category(
                        id, name, parentId
                );

                int result = dao.edit(category);

                if (result > 0) {

                    User loggedInUser
                            = (User) request.getSession()
                                    .getAttribute("loggedInUser");

                    auditLogService.log(
                            loggedInUser,
                            "UPDATE_CATEGORY",
                            "CATEGORY",
                            null,
                            "Updated category: " + name,
                            request
                    );

                    response.sendRedirect(
                            contextPath + "/category?view=list"
                    );
                } else {
                    forwardEditWithError(
                            request, response, dao, currentCategory,
                            "Không thể cập nhật danh mục. Vui lòng thử lại.",
                            name
                    );
                }

            } catch (Exception e) {
                LOGGER.log(
                        Level.SEVERE,
                        "Cannot edit category",
                        e
                );

                if (id > 0) {
                    Category currentCategory = dao.getById(id);

                    if (currentCategory == null) {
                        response.sendRedirect(
                                contextPath + "/category?view=list"
                        );
                        return;
                    }

                    forwardEditWithError(
                            request, response, dao, currentCategory,
                            "Đã xảy ra lỗi khi cập nhật danh mục.",
                            request.getParameter("name")
                    );
                } else {
                    response.sendRedirect(
                            contextPath + "/category?view=list"
                    );
                }
            }

        } else if ("delete".equals(action)) {

            String idText = request.getParameter("id");
            int id;

            try {
                id = Integer.parseInt(idText);

                if (id <= 0) {
                    throw new NumberFormatException();
                }
            } catch (NumberFormatException e) {
                response.sendRedirect(
                        contextPath
                        + "/category?view=list&error=invalidId"
                );
                return;
            }

            try {
                Category existing = dao.getById(id);

                if (existing == null) {
                    response.sendRedirect(
                            contextPath
                            + "/category?view=list&error=notFound"
                    );
                    return;
                }

                int productCount
                        = dao.countProductsByCategoryId(id);

                int childCount
                        = dao.countChildCategories(id);

                if (productCount > 0 || childCount > 0) {
                    response.sendRedirect(
                            contextPath
                            + "/category?view=delete&id=" + id
                            + "&error=hasProducts"
                    );
                    return;
                }

                int result = dao.delete(existing);

                if (result == 1) {

                    User loggedInUser
                            = (User) request.getSession()
                                    .getAttribute("loggedInUser");

                    auditLogService.log(
                            loggedInUser,
                            "DELETE_CATEGORY",
                            "CATEGORY",
                            null,
                            "Deleted category: " + existing.getCategoryName(),
                            request
                    );

                    response.sendRedirect(
                            contextPath
                            + "/category?view=list&success=delete"
                    );
                } else {
                    response.sendRedirect(
                            contextPath
                            + "/category?view=delete&id=" + id
                            + "&error=delete"
                    );
                }

            } catch (Exception e) {
                LOGGER.log(
                        Level.SEVERE,
                        "Cannot delete category",
                        e
                );

                response.sendRedirect(
                        contextPath
                        + "/category?view=delete&id=" + id
                        + "&error=server"
                );
            }

        } else {
            response.sendRedirect(
                    contextPath + "/category?view=list"
            );
        }
    }

    // ======================================================
    // CONFIG THÔNG SỐ KỸ THUẬT TẠI EDIT CATEGORY
    // Lưu độc lập với form cập nhật tên/danh mục cha.
    // ======================================================
    private void prepareSpecificationEditor(HttpServletRequest request,
            Category category, CategoryDAO categoryDAO) {
        request.setAttribute("category", category);
        request.setAttribute("categoryList", categoryDAO.getList());

        if (category.getParentId() == null) {
            return; // Chỉ cấu hình cho danh mục con.
        }

        List<model.Attribute> attributes
                = new dao.AttributeDAO().getActiveAttributes();
        List<model.CategoryAttribute> configs
                = new dao.CategoryAttributeDAO()
                        .getByCategoryId(category.getCategoryId());

        Map<Integer, model.CategoryAttribute> byId = new HashMap<>();
        for (model.CategoryAttribute config : configs) {
            byId.put(config.getAttributeId(), config);
        }

        request.setAttribute("specAttributeList", attributes);
        request.setAttribute("specConfigById", byId);

        jakarta.servlet.http.HttpSession session = request.getSession();
        String token = (String) session.getAttribute("categorySpecCsrfToken");
        if (token == null) {
            token = java.util.UUID.randomUUID().toString();
            session.setAttribute("categorySpecCsrfToken", token);
        }
        request.setAttribute("categorySpecCsrfToken", token);
    }

    private void saveSpecificationConfiguration(HttpServletRequest request,
            HttpServletResponse response, CategoryDAO categoryDAO)
            throws ServletException, IOException {

        Integer categoryId = null;
        try {
            categoryId = Integer.valueOf(request.getParameter("id"));
            if (categoryId <= 0) {
                throw new IllegalArgumentException("Danh mục không hợp lệ.");
            }
        } catch (NumberFormatException ex) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "Mã danh mục không hợp lệ.");
            return;
        }

        Category category = categoryDAO.getById(categoryId);
        if (category == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        try {
            jakarta.servlet.http.HttpSession session
                    = request.getSession(false);
            String expected = session == null ? null
                    : (String) session.getAttribute("categorySpecCsrfToken");
            String submitted = request.getParameter("categorySpecCsrfToken");

            if (session == null
                    || !(session.getAttribute("loggedInUser") instanceof User)
                    || expected == null || !expected.equals(submitted)) {
                throw new IllegalArgumentException(
                        "Phiên lưu cấu hình không hợp lệ. Hãy tải lại trang Edit Category.");
            }
            if (category.getParentId() == null) {
                throw new IllegalArgumentException(
                        "Chỉ cấu hình thông số cho danh mục con.");
            }
            if (!"1".equals(request.getParameter("specFormMarker"))) {
                throw new IllegalArgumentException("Dữ liệu form không hợp lệ.");
            }

            List<model.Attribute> active
                    = new dao.AttributeDAO().getActiveAttributes();
            Set<Integer> allowed = new HashSet<>();
            for (model.Attribute attribute : active) {
                allowed.add(attribute.getAttributeId());
            }

            // Chỉ cập nhật các dòng thật sự hiển thị trên form.
            // Tránh xóa một cấu hình mới mà Staff khác vừa thêm.
            Set<Integer> visible = new HashSet<>();
            String[] visibleIds
                    = request.getParameterValues("visibleSpecAttributeIds");
            if (visibleIds == null || visibleIds.length != active.size()) {
                throw new IllegalArgumentException(
                        "Danh sách thuộc tính đã thay đổi. Hãy tải lại trang.");
            }
            for (String raw : visibleIds) {
                Integer id;
                try {
                    id = Integer.valueOf(raw);
                } catch (NumberFormatException ex) {
                    throw new IllegalArgumentException(
                            "Mã thuộc tính hiển thị không hợp lệ.");
                }
                if (!allowed.contains(id) || !visible.add(id)) {
                    throw new IllegalArgumentException(
                            "Danh sách thuộc tính không hợp lệ.");
                }
            }

            Set<Integer> selected = new HashSet<>();
            String[] submittedIds
                    = request.getParameterValues("selectedSpecAttributeIds");
            if (submittedIds != null) {
                for (String raw : submittedIds) {
                    Integer id;
                    try {
                        id = Integer.valueOf(raw);
                    } catch (NumberFormatException ex) {
                        throw new IllegalArgumentException(
                                "ID thuộc tính không hợp lệ.");
                    }
                    if (!visible.contains(id) || !selected.add(id)) {
                        throw new IllegalArgumentException(
                                "Thuộc tính bị trùng hoặc không còn hoạt động.");
                    }
                }
            }

            // Khi bị lỗi validate, giữ các checkbox và input đã nhập.
            request.setAttribute("specFormSubmitted", true);
            Map<Integer, Boolean> checkedMap = new HashMap<>();
            for (Integer selectedId : selected) {
                checkedMap.put(selectedId, Boolean.TRUE);
            }
            request.setAttribute("submittedSpecChecked", checkedMap);
            Map<Integer, String> draftGroups = new HashMap<>();
            Map<Integer, String> draftOrders = new HashMap<>();
            Set<Integer> draftRequired = new HashSet<>();
            Set<Integer> draftFilterable = new HashSet<>();
            Map<Integer, Boolean> draftRequiredMap = new HashMap<>();
            Map<Integer, Boolean> draftFilterableMap = new HashMap<>();
            List<dao.CategoryAttributeDAO.SpecificationSelection> selections
                    = new ArrayList<>();

            for (model.Attribute attr : active) {
                int id = attr.getAttributeId();
                String group = request.getParameter("specGroup_" + id);
                String order = request.getParameter("specOrder_" + id);
                if (group != null) {
                    draftGroups.put(id, group);
                }
                if (order != null) {
                    draftOrders.put(id, order);
                }
                if (request.getParameter("specRequired_" + id) != null) {
                    draftRequired.add(id);
                    draftRequiredMap.put(id, Boolean.TRUE);
                }
                if (request.getParameter("specFilterable_" + id) != null) {
                    draftFilterable.add(id);
                    draftFilterableMap.put(id, Boolean.TRUE);
                }
            }
            request.setAttribute("submittedSpecGroups", draftGroups);
            request.setAttribute("submittedSpecOrders", draftOrders);
            request.setAttribute("submittedSpecRequired", draftRequiredMap);
            request.setAttribute("submittedSpecFilterable", draftFilterableMap);

            for (Integer id : selected) {
                String group = request.getParameter("specGroup_" + id);
                if (group == null || group.trim().isEmpty()) {
                    group = "Thông số khác";
                }
                String orderText = request.getParameter("specOrder_" + id);
                int order = 0;
                if (orderText != null && !orderText.trim().isEmpty()) {
                    try {
                        order = Integer.parseInt(orderText.trim());
                    } catch (NumberFormatException ex) {
                        throw new IllegalArgumentException(
                                "Thứ tự hiển thị phải là số nguyên.");
                    }
                }
                if (group.trim().length() > 100 || order < 0) {
                    throw new IllegalArgumentException(
                            "Nhóm thông số tối đa 100 ký tự; thứ tự phải >= 0.");
                }

                selections.add(
                        new dao.CategoryAttributeDAO.SpecificationSelection(
                                id, group,
                                draftRequired.contains(id),
                                draftFilterable.contains(id), order));
            }

            new dao.CategoryAttributeDAO()
                    .saveSpecificationSelections(categoryId, visible, selections);

            // Ghi audit sau commit. Lỗi audit không biến một giao dịch
            // đã commit thành lỗi lưu cấu hình.
            try {
                User loggedInUser = (User) session.getAttribute("loggedInUser");
                auditLogService.log(
                        loggedInUser, "UPDATE_CATEGORY_SPECIFICATIONS",
                        "CATEGORY", null,
                        "Updated specifications for category: "
                        + category.getCategoryName(), request);
            } catch (RuntimeException auditEx) {
                LOGGER.log(Level.WARNING,
                        "Đã lưu cấu hình nhưng không ghi được Audit Log.", auditEx);
            }

            response.sendRedirect(request.getContextPath()
                    + "/category?view=edit&id=" + categoryId
                    + "&specSaved=1");

        } catch (IllegalArgumentException | IllegalStateException ex) {
            request.setAttribute("specErrorMessage", ex.getMessage());
            prepareSpecificationEditor(request, category, categoryDAO);
            request.getRequestDispatcher("/WEB-INF/category/edit.jsp")
                    .forward(request, response);
        } catch (java.sql.SQLException ex) {
            LOGGER.log(Level.SEVERE, "Không lưu được thông số danh mục.", ex);
            request.setAttribute("specErrorMessage",
                    "Lỗi database khi lưu cấu hình. Không có thay đổi nào được commit.");
            prepareSpecificationEditor(request, category, categoryDAO);
            request.getRequestDispatcher("/WEB-INF/category/edit.jsp")
                    .forward(request, response);
        }
    }

    // ======================================================
    // HAI KHU VỰC THUỘC TÍNH: SPECIFICATION / VARIANT
    // Chỉ thay đổi ATTRIBUTE khi tạo mới hoặc chỉnh định nghĩa an toàn.
    // Còn lại thao tác trên CATEGORY_ATTRIBUTE theo đúng role.
    // ======================================================
    private int parseRoleInt(String raw, String name, boolean allowZero) {
        try {
            int value = Integer.parseInt(raw == null ? "" : raw.trim());
            if (value < 0 || (!allowZero && value == 0)) {
                throw new NumberFormatException();
            }
            return value;
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException(name + " không hợp lệ.");
        }
    }

    private List<Category> getChildCategories(CategoryDAO categoryDAO) {
        List<Category> categories = new ArrayList<>();
        for (Category item : categoryDAO.getList()) {
            if (item.getParentId() != null) {
                categories.add(item);
            }
        }
        return categories;
    }

    private String roleCsrfToken(HttpServletRequest request) {
        jakarta.servlet.http.HttpSession session = request.getSession();
        String token = (String) session.getAttribute("categoryRoleCsrfToken");
        if (token == null) {
            token = java.util.UUID.randomUUID().toString();
            session.setAttribute("categoryRoleCsrfToken", token);
        }
        return token;
    }

    private void showRoleAttributes(HttpServletRequest request,
            HttpServletResponse response, CategoryDAO categoryDAO, String role)
            throws ServletException, IOException {
        if (!CategoryRoleConfigDAO.validRole(role)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        // Filter phân quyền /category hiện tại vẫn phải được giữ ở project.
        if (request.getSession(false) == null
                || !(request.getSession(false).getAttribute("loggedInUser") instanceof User)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        List<Category> children = getChildCategories(categoryDAO);
        int categoryId;
        try {
            String requestedId = request.getParameter("categoryId");
            categoryId = (requestedId == null || requestedId.trim().isEmpty())
                    ? (children.isEmpty() ? 0 : children.get(0).getCategoryId())
                    : parseRoleInt(requestedId, "Mã danh mục", false);
            if (categoryId != 0) {
                boolean allowed = false;
                for (Category cat : children) {
                    if (cat.getCategoryId() == categoryId) {
                        allowed = true;
                        break;
                    }
                }
                if (!allowed) {
                    throw new IllegalArgumentException(
                            "Danh mục không tồn tại hoặc không phải danh mục con.");
                }
            }
        } catch (IllegalArgumentException ex) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, ex.getMessage());
            return;
        }
        Map<Integer, model.CategoryAttribute> byId = new HashMap<>();
        if (categoryId > 0) {
            for (model.CategoryAttribute item
                    : new dao.CategoryAttributeDAO().getByCategoryId(categoryId)) {
                byId.put(item.getAttributeId(), item);
            }
        }
        String keyword = request.getParameter("keyword");
        keyword = keyword == null ? "" : keyword.trim();
        final String filter = keyword.toLowerCase(java.util.Locale.ROOT);
        List<model.Attribute> attrs = new dao.AttributeDAO().getList();
        attrs.removeIf(a -> !filter.isEmpty()
                && (a.getAttributeName() == null
                || !a.getAttributeName().toLowerCase(java.util.Locale.ROOT).contains(filter)));
        attrs.sort(Comparator
                .comparingInt((model.Attribute a) -> {
                    model.CategoryAttribute c = byId.get(a.getAttributeId());
                    return c != null && CategoryRoleConfigDAO.includesRole(
                            c.getAttributeType(), role) ? 0 : 1;
                })
                .thenComparingInt(a -> {
                    model.CategoryAttribute c = byId.get(a.getAttributeId());
                    return c == null ? Integer.MAX_VALUE : c.getDisplayOrder();
                })
                .thenComparing(model.Attribute::getAttributeName,
                        Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER)));
        Map<Integer, String> signatures = new HashMap<>();
        for (model.Attribute attr : attrs) {
            signatures.put(attr.getAttributeId(),
                    CategoryRoleConfigDAO.signature(byId.get(attr.getAttributeId())));
        }
        request.setAttribute("roleCategoryList", children);
        request.setAttribute("selectedCategoryId", categoryId);
        request.setAttribute("managedRole", role);
        request.setAttribute("managedRoleView", "VARIANT".equals(role)
                ? "variantAttributes" : "specificationAttributes");
        request.setAttribute("roleAttributeList", attrs);
        request.setAttribute("roleMappingById", byId);
        request.setAttribute("roleSignatureById", signatures);
        request.setAttribute("roleKeyword", keyword);
        request.setAttribute("roleCsrfToken", roleCsrfToken(request));
        request.getRequestDispatcher("/WEB-INF/category/role-attributes.jsp")
                .forward(request, response);
    }

    private void handleRoleAction(HttpServletRequest request,
            HttpServletResponse response, CategoryDAO dao, String action)
            throws ServletException, IOException {
        jakarta.servlet.http.HttpSession session = request.getSession(false);
        if (session == null || !(session.getAttribute("loggedInUser") instanceof User)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        String role = request.getParameter("role");
        if (!CategoryRoleConfigDAO.validRole(role)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Vai trò không hợp lệ.");
            return;
        }
        String expectedToken = (String) session.getAttribute("categoryRoleCsrfToken");
        if (expectedToken == null
                || !expectedToken.equals(request.getParameter("roleCsrfToken"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Phiên thao tác không hợp lệ. Tải lại trang quản lý.");
            return;
        }
        String view = "VARIANT".equals(role)
                ? "variantAttributes" : "specificationAttributes";
        int categoryId;
        try {
            categoryId = parseRoleInt(request.getParameter("categoryId"),
                    "Mã danh mục", false);
        } catch (IllegalArgumentException ex) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, ex.getMessage());
            return;
        }
        try {
            CategoryRoleConfigDAO roleDao = new CategoryRoleConfigDAO();
            int id = parseRoleInt(request.getParameter("attributeId"),
                    "Mã thuộc tính", "saveRoleMapping".equals(action));
            if ("saveRoleMapping".equals(action)
                    && "definitionOnly".equals(request.getParameter("saveMode"))) {
                // Chỉ tạo ATTRIBUTE; chưa bật VARIANT/SPECIFICATION trong danh mục.
                id = roleDao.createDefinitionOnly(
                        request.getParameter("attributeName"),
                        request.getParameter("dataType"),
                        request.getParameter("unit"));
            } else if ("saveRoleMapping".equals(action)) {
                CategoryRoleConfigDAO.ConfigInput input
                        = new CategoryRoleConfigDAO.ConfigInput();
                input.categoryId = categoryId;
                input.attributeId = id;
                input.role = role;
                input.attributeName = request.getParameter("attributeName");
                input.dataType = request.getParameter("dataType");
                input.unit = request.getParameter("unit");
                input.groupName = request.getParameter("groupName");
                input.required = "1".equals(request.getParameter("isRequired"));
                input.filterable = "1".equals(request.getParameter("isFilterable"));
                input.displayOrder = parseRoleInt(request.getParameter("displayOrder"),
                        "Thứ tự hiển thị", true);
                input.expectedSignature = request.getParameter("expectedSignature");
                id = roleDao.save(input);
            } else if ("removeRoleMapping".equals(action)) {
                roleDao.removeRole(categoryId, id, role,
                        request.getParameter("expectedSignature"));
            } else if ("updateRoleDefinition".equals(action)) {
                roleDao.updateDefinition(categoryId, id, role,
                        request.getParameter("attributeName"),
                        request.getParameter("dataType"),
                        request.getParameter("unit"));
            } else if ("hardDeleteAttribute".equals(action)) {
                roleDao.hardDeleteAttribute(id,
                        request.getParameter("confirmedAttributeName"));
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                        "Thao tác thuộc tính không được hỗ trợ.");
                return;
            }
            try {
                auditLogService.log((User) session.getAttribute("loggedInUser"),
                        action,
                        "hardDeleteAttribute".equals(action) ? "ATTRIBUTE" : "CATEGORY_ATTRIBUTE",
                        null,
                        "Category #" + categoryId + ", Attribute #" + id
                        + ", Role " + role, request);
            } catch (RuntimeException auditEx) {
                LOGGER.log(Level.WARNING,
                        "Đã lưu cấu hình nhưng chưa ghi được Audit Log.", auditEx);
            }
            response.sendRedirect(request.getContextPath()
                    + "/category?view=" + view + "&categoryId=" + categoryId
                    + "&roleSaved=1"
                    + ("hardDeleteAttribute".equals(action) ? "&hardDeleted=1" : "")
                    + ("saveRoleMapping".equals(action)
                    && "definitionOnly".equals(request.getParameter("saveMode"))
                    ? "&definitionOnly=1" : ""));
        } catch (IllegalArgumentException | IllegalStateException ex) {
            request.setAttribute("roleErrorMessage", ex.getMessage());
            showRoleAttributes(request, response, dao, role);
        } catch (java.sql.SQLException ex) {
            LOGGER.log(Level.SEVERE, "Không lưu được cấu hình thuộc tính.", ex);
            request.setAttribute("roleErrorMessage",
                    "Lỗi database, toàn bộ thay đổi đã rollback. Kiểm tra log Tomcat.");
            showRoleAttributes(request, response, dao, role);
        }
    }

    private boolean isValidCategoryName(String name) {
        return name != null
                && name.matches("^[\\p{L}\\p{M}\\p{N} ]+$");
    }

    private void forwardCreateWithError(
            HttpServletRequest request,
            HttpServletResponse response,
            CategoryDAO dao,
            String errorMessage,
            String name)
            throws ServletException, IOException {

        request.setAttribute("errorMessage", errorMessage);
        request.setAttribute("submittedName", name);
        request.setAttribute("categoryList", dao.getList());

        request.getRequestDispatcher(
                "/WEB-INF/category/create.jsp"
        ).forward(request, response);
    }

    private void forwardEditWithError(
            HttpServletRequest request,
            HttpServletResponse response,
            CategoryDAO dao,
            Category category,
            String errorMessage,
            String name)
            throws ServletException, IOException {

        category.setCategoryName(name);

        request.setAttribute("errorMessage", errorMessage);
        prepareSpecificationEditor(request, category, dao);

        request.getRequestDispatcher(
                "/WEB-INF/category/edit.jsp"
        ).forward(request, response);
    }

    private boolean isDescendant(
            CategoryDAO dao, int parentId, int categoryId) {

        Category current = dao.getById(parentId);
        Set<Integer> visited = new HashSet<>();

        while (current != null
                && visited.add(current.getCategoryId())
                && current.getParentId() != null) {

            int currentParentId = current.getParentId();

            if (currentParentId == categoryId) {
                return true;
            }

            current = dao.getById(currentParentId);
        }

        return false;
    }

    private List<Category> buildCategoryTree(
            List<Category> categories,
            Map<Integer, Integer> categoryDepths) {

        Map<Integer, List<Category>> children = new HashMap<>();
        List<Category> roots = new ArrayList<>();
        Set<Integer> categoryIds = new HashSet<>();
        Set<Integer> visited = new HashSet<>();

        for (Category category : categories) {
            categoryIds.add(category.getCategoryId());

            children.put(
                    category.getCategoryId(),
                    new ArrayList<>()
            );
        }

        for (Category category : categories) {
            Integer parentId = category.getParentId();

            if (parentId == null
                    || !categoryIds.contains(parentId)
                    || parentId == category.getCategoryId()) {
                roots.add(category);
            } else {
                children.get(parentId).add(category);
            }
        }

        Comparator<Category> byName = Comparator.comparing(
                Category::getCategoryName,
                Comparator.nullsLast(
                        String.CASE_INSENSITIVE_ORDER
                )
        );

        roots.sort(byName);

        for (List<Category> childList : children.values()) {
            childList.sort(byName);
        }

        List<Category> result = new ArrayList<>();

        for (Category root : roots) {
            appendCategoryTree(
                    root,
                    0,
                    children,
                    result,
                    categoryDepths,
                    visited
            );
        }

        for (Category category : categories) {
            if (!visited.contains(category.getCategoryId())) {
                appendCategoryTree(
                        category,
                        0,
                        children,
                        result,
                        categoryDepths,
                        visited
                );
            }
        }

        return result;
    }

    private void appendCategoryTree(
            Category category,
            int depth,
            Map<Integer, List<Category>> children,
            List<Category> result,
            Map<Integer, Integer> categoryDepths,
            Set<Integer> visited) {

        int categoryId = category.getCategoryId();

        if (!visited.add(categoryId)) {
            return;
        }

        result.add(category);
        categoryDepths.put(categoryId, depth);

        List<Category> childList = children.get(categoryId);

        if (childList != null) {
            for (Category child : childList) {
                appendCategoryTree(
                        child,
                        depth + 1,
                        children,
                        result,
                        categoryDepths,
                        visited
                );
            }
        }
    }
}
