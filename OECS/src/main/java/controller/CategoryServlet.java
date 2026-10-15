
package controller;

import dao.CategoryDAO;
import model.Category;

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

    private static final Logger LOGGER =
            Logger.getLogger(CategoryServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        String view = request.getParameter("view");
        CategoryDAO dao = new CategoryDAO();

        // LIST
        if (view == null || view.equals("list")) {

            String keyword = request.getParameter("keyword");
            keyword = keyword == null ? "" : keyword.trim();

            int page = 1;

            try {
                String pageText = request.getParameter("page");

                if (pageText != null) {
                    page = Integer.parseInt(pageText);
                }

                if (page < 1) {
                    page = 1;
                }
            } catch (NumberFormatException e) {
                page = 1;
            }

            // Lay tat ca danh muc va sap xep theo cay thu muc
            List<Category> allCategories = dao.getList();

            Map<Integer, Integer> categoryDepths = new HashMap<>();

            List<Category> treeList = buildCategoryTree(
                    allCategories, categoryDepths
            );

            // Tim cac danh muc goc
            Set<Integer> allCategoryIds = new HashSet<>();

            for (Category category : allCategories) {
                allCategoryIds.add(category.getCategoryId());
            }

            List<Category> rootCategories = new ArrayList<>();

            for (Category category : treeList) {
                Integer parentId = category.getParentId();

                if (parentId == null
                        || !allCategoryIds.contains(parentId)
                        || parentId == category.getCategoryId()) {
                    rootCategories.add(category);
                }
            }

            // Tim cac danh muc can hien thi
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

                        // Them danh muc dang khop
                        matchedIds.add(category.getCategoryId());

                        // Them cac danh muc cha
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

            // Gom danh muc theo tung danh muc goc
            Map<Integer, List<Category>> categoryGroups =
                    new HashMap<>();

            for (Category root : rootCategories) {
                List<Category> group = new ArrayList<>();

                for (Category category : treeList) {
                    if (isInCategoryTree(
                            category,
                            root.getCategoryId(),
                            allCategories)
                            && matchedIds.contains(
                                    category.getCategoryId())) {

                        group.add(category);
                    }
                }

                if (!group.isEmpty()) {
                    categoryGroups.put(
                            root.getCategoryId(), group
                    );
                }
            }

            // Sap xep cac nhom theo ten danh muc goc
            List<Integer> rootIds = new ArrayList<>(
                    categoryGroups.keySet()
            );

            rootIds.sort((id1, id2) -> {
                String name1 = "";
                String name2 = "";

                for (Category category : rootCategories) {
                    if (category.getCategoryId() == id1) {
                        name1 = category.getCategoryName();
                    }

                    if (category.getCategoryId() == id2) {
                        name2 = category.getCategoryName();
                    }
                }

                return name1.compareToIgnoreCase(name2);
            });

            // Tinh tong so danh muc phu hop voi tu khoa
            int totalCategories = matchedIds.size();

            // Phan trang theo nhom danh muc goc
            int pageSize = 10;

            int totalPages = Math.max(
                    1,
                    (int) Math.ceil(
                            (double) rootIds.size() / pageSize
                    )
            );

            if (page > totalPages) {
                page = totalPages;
            }

            int fromIndex = Math.min(
                    (page - 1) * pageSize,
                    rootIds.size()
            );

            int toIndex = Math.min(
                    fromIndex + pageSize,
                    rootIds.size()
            );

            // Lay cac nhom danh muc cua trang hien tai
            List<Category> categoryList = new ArrayList<>();

            for (int i = fromIndex; i < toIndex; i++) {
                categoryList.addAll(
                        categoryGroups.get(rootIds.get(i))
                );
            }

            // Lay so san pham va so danh muc con
            Map<Integer, Integer> productCounts =
                    dao.getProductCounts(categoryList);

            Map<Integer, Integer> childCounts =
                    dao.getChildCounts(categoryList);

            // Lay ten danh muc de hien thi danh muc cha
            Map<Integer, String> categoryNames =
                    dao.getCategoryNames();

            // Tinh vi tri danh muc hien thi
            int startItem = categoryList.isEmpty()
                    ? 0
                    : countDisplayedBeforePage(
                            rootIds,
                            categoryGroups,
                            fromIndex
                    ) + 1;

            int endItem = startItem == 0
                    ? 0
                    : startItem + categoryList.size() - 1;

            request.setAttribute("categoryList", categoryList);
            request.setAttribute("categoryDepths", categoryDepths);
            request.setAttribute("keyword", keyword);
            request.setAttribute("productCounts", productCounts);
            request.setAttribute("childCounts", childCounts);
            request.setAttribute("categoryNames", categoryNames);
            request.setAttribute("currentPage", page);
            request.setAttribute("totalPages", totalPages);
            request.setAttribute("totalCategories", totalCategories);
            request.setAttribute("startItem", startItem);
            request.setAttribute("endItem", endItem);

            request.getRequestDispatcher(
                    "/WEB-INF/category/list.jsp"
            ).forward(request, response);

        // CREATE
        } else if ("create".equals(view)) {

            request.setAttribute("categoryList", dao.getList());

            request.getRequestDispatcher(
                    "/WEB-INF/category/create.jsp"
            ).forward(request, response);

        // EDIT
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

        // DELETE
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

                int productCount =
                        dao.countProductsByCategoryId(id);

                int childCount =
                        dao.countChildCategories(id);

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

        // CREATE
        if ("create".equals(action)) {

            try {
                String name = request.getParameter("name");
                String parentIdText =
                        request.getParameter("parentId");

                // Kiem tra ten danh muc rong
                if (name == null || name.trim().isEmpty()) {
                    request.setAttribute(
                            "errorMessage",
                            "Vui lòng nhập tên danh mục."
                    );
                    request.setAttribute(
                            "categoryList", dao.getList()
                    );

                    request.getRequestDispatcher(
                            "/WEB-INF/category/create.jsp"
                    ).forward(request, response);
                    return;
                }

                name = name.trim();

                // Kiem tra ten danh muc trung
                if (dao.isCategoryNameExists(name)) {
                    request.setAttribute(
                            "errorMessage",
                            "Tên danh mục đã tồn tại. Vui lòng nhập tên khác."
                    );
                    request.setAttribute(
                            "categoryList", dao.getList()
                    );

                    request.getRequestDispatcher(
                            "/WEB-INF/category/create.jsp"
                    ).forward(request, response);
                    return;
                }

                // Lay danh muc cha
                Integer parentId = null;

                if (parentIdText != null
                        && !parentIdText.trim().isEmpty()) {
                    parentId = Integer.parseInt(parentIdText);
                }

                // Kiem tra danh muc cha ton tai
                if (parentId != null
                        && dao.getById(parentId) == null) {

                    request.setAttribute(
                            "errorMessage",
                            "Danh mục cha không tồn tại."
                    );
                    request.setAttribute(
                            "categoryList", dao.getList()
                    );

                    request.getRequestDispatcher(
                            "/WEB-INF/category/create.jsp"
                    ).forward(request, response);
                    return;
                }

                Category category = new Category(
                        0, name, parentId
                );

                int result = dao.insert(category);

                if (result > 0) {
                    response.sendRedirect(
                            request.getContextPath()
                            + "/category?view=list"
                    );
                } else {
                    request.setAttribute(
                            "errorMessage",
                            "Không thể thêm danh mục. Vui lòng thử lại."
                    );
                    request.setAttribute(
                            "categoryList", dao.getList()
                    );

                    request.getRequestDispatcher(
                            "/WEB-INF/category/create.jsp"
                    ).forward(request, response);
                }

            } catch (Exception e) {
                LOGGER.log(
                        Level.SEVERE,
                        "Cannot create category",
                        e
                );

                request.setAttribute(
                        "errorMessage",
                        "Đã xảy ra lỗi khi thêm danh mục."
                );
                request.setAttribute(
                        "categoryList", dao.getList()
                );

                request.getRequestDispatcher(
                        "/WEB-INF/category/create.jsp"
                ).forward(request, response);
            }

        // EDIT
        } else if ("edit".equals(action)) {

            int id = 0;

            try {
                id = Integer.parseInt(
                        request.getParameter("id")
                );

                String name = request.getParameter("name");
                String parentIdText =
                        request.getParameter("parentId");

                Category currentCategory = dao.getById(id);

                if (currentCategory == null) {
                    response.sendRedirect(
                            request.getContextPath()
                            + "/category?view=list"
                    );
                    return;
                }

                // Kiem tra ten danh muc rong
                if (name == null || name.trim().isEmpty()) {
                    request.setAttribute(
                            "errorMessage",
                            "Vui lòng nhập tên danh mục."
                    );
                    request.setAttribute(
                            "category", currentCategory
                    );
                    request.setAttribute(
                            "categoryList", dao.getList()
                    );

                    request.getRequestDispatcher(
                            "/WEB-INF/category/edit.jsp"
                    ).forward(request, response);
                    return;
                }

                name = name.trim();

                // Kiem tra ten trung, bo qua danh muc dang sua
                if (dao.isCategoryNameExists(name, id)) {
                    request.setAttribute(
                            "errorMessage",
                            "Tên danh mục đã tồn tại. Vui lòng nhập tên khác."
                    );
                    request.setAttribute(
                            "category", currentCategory
                    );
                    request.setAttribute(
                            "categoryList", dao.getList()
                    );

                    request.getRequestDispatcher(
                            "/WEB-INF/category/edit.jsp"
                    ).forward(request, response);
                    return;
                }

                // Lay danh muc cha
                Integer parentId = null;

                if (parentIdText != null
                        && !parentIdText.trim().isEmpty()) {
                    parentId = Integer.parseInt(parentIdText);
                }

                // Kiem tra danh muc cha hop le
                if (parentId != null) {
                    if (parentId == id
                            || dao.getById(parentId) == null) {

                        request.setAttribute(
                                "errorMessage",
                                "Danh mục cha không hợp lệ."
                        );
                        request.setAttribute(
                                "category", currentCategory
                        );
                        request.setAttribute(
                                "categoryList", dao.getList()
                        );

                        request.getRequestDispatcher(
                                "/WEB-INF/category/edit.jsp"
                        ).forward(request, response);
                        return;
                    }

                    // Kiem tra tranh tao vong lap danh muc cha/con
                    if (isDescendant(dao, parentId, id)) {
                        request.setAttribute(
                                "errorMessage",
                                "Không thể chọn danh mục con làm danh mục cha."
                        );
                        request.setAttribute(
                                "category", currentCategory
                        );
                        request.setAttribute(
                                "categoryList", dao.getList()
                        );

                        request.getRequestDispatcher(
                                "/WEB-INF/category/edit.jsp"
                        ).forward(request, response);
                        return;
                    }
                }

                Category category = new Category(
                        id, name, parentId
                );

                int result = dao.edit(category);

                if (result > 0) {
                    response.sendRedirect(
                            request.getContextPath()
                            + "/category?view=list"
                    );
                } else {
                    request.setAttribute(
                            "errorMessage",
                            "Không thể cập nhật danh mục. Vui lòng thử lại."
                    );
                    request.setAttribute(
                            "category", currentCategory
                    );
                    request.setAttribute(
                            "categoryList", dao.getList()
                    );

                    request.getRequestDispatcher(
                            "/WEB-INF/category/edit.jsp"
                    ).forward(request, response);
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
                                request.getContextPath()
                                + "/category?view=list"
                        );
                        return;
                    }

                    request.setAttribute(
                            "category", currentCategory
                    );
                    request.setAttribute(
                            "categoryList", dao.getList()
                    );
                    request.setAttribute(
                            "errorMessage",
                            "Đã xảy ra lỗi khi cập nhật danh mục."
                    );

                    request.getRequestDispatcher(
                            "/WEB-INF/category/edit.jsp"
                    ).forward(request, response);
                } else {
                    response.sendRedirect(
                            request.getContextPath()
                            + "/category?view=list"
                    );
                }
            }

        // DELETE
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

                int productCount =
                        dao.countProductsByCategoryId(id);

                int childCount =
                        dao.countChildCategories(id);

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
                    request.getContextPath()
                    + "/category?view=list"
            );
        }
    }

    // Kiem tra parentId co phai la hau due cua categoryId khong
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

    // Sap xep danh muc theo thu tu cay thu muc
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

        // Gom danh muc theo danh muc cha
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

        // Sap xep cac danh muc cung cap theo ten
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

        // Duyet tu danh muc goc xuong cac cap con
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

        // Du phong du lieu loi co chu trinh hoac khong co goc
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

    // Them danh muc va cac cap con theo thu tu duyet cay
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

    // Kiem tra danh muc co nam trong cay cua danh muc goc khong
    private boolean isInCategoryTree(
            Category category,
            int rootId,
            List<Category> allCategories) {

        Category current = category;
        Set<Integer> visited = new HashSet<>();

        while (current != null
                && visited.add(current.getCategoryId())) {

            if (current.getCategoryId() == rootId) {
                return true;
            }

            Integer parentId = current.getParentId();

            if (parentId == null) {
                return false;
            }

            Category parent = null;

            for (Category item : allCategories) {
                if (item.getCategoryId() == parentId) {
                    parent = item;
                    break;
                }
            }

            current = parent;
        }

        return false;
    }

    // Dem so danh muc cua cac trang truoc
    private int countDisplayedBeforePage(
            List<Integer> rootIds,
            Map<Integer, List<Category>> categoryGroups,
            int endIndex) {

        int count = 0;

        for (int i = 0; i < endIndex; i++) {
            List<Category> group =
                    categoryGroups.get(rootIds.get(i));

            if (group != null) {
                count += group.size();
            }
        }

        return count;
    }
}
