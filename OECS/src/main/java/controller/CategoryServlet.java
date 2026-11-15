
package controller;

import dao.CategoryDAO;
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

        if (view == null || view.equals("list")) {

            String keyword = request.getParameter("keyword");
            keyword = keyword == null ? "" : keyword.trim();

            List<Category> allCategories = dao.getList();
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

                            Category parent = null;

                            for (Category item : allCategories) {
                                if (item.getCategoryId() == parentId) {
                                    parent = item;
                                    break;
                                }
                            }

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

            Map<Integer, String> categoryNames
                    = dao.getCategoryNames();

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

                request.setAttribute("category", category);
                request.setAttribute("categoryList", dao.getList());

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
        request.setAttribute("category", category);
        request.setAttribute("categoryList", dao.getList());

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
