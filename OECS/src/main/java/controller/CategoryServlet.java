package controller;

import dao.CategoryDAO;
import model.Category;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;
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

        // ==================== LIST ====================
        if (view == null || view.equals("list")) {

            List<Category> categoryList = dao.getList();

            request.setAttribute("categoryList", categoryList);

            request.getRequestDispatcher(
                    "/WEB-INF/category/list.jsp"
            ).forward(request, response);

        // ==================== CREATE ====================
        } else if ("create".equals(view)) {

            List<Category> categoryList = dao.getList();

            request.setAttribute("categoryList", categoryList);

            request.getRequestDispatcher(
                    "/WEB-INF/category/create.jsp"
            ).forward(request, response);

        // ==================== EDIT ====================
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

                List<Category> categoryList = dao.getList();

                request.setAttribute("categoryList", categoryList);

                request.getRequestDispatcher(
                        "/WEB-INF/category/edit.jsp"
                ).forward(request, response);

            } catch (NumberFormatException e) {

                LOGGER.log(
                        Level.WARNING,
                        "ID không hợp lệ khi mở Edit Category",
                        e
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/category?view=list"
                );
            }

        // ==================== DELETE ====================
        } else if ("delete".equals(view)) {

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

                request.getRequestDispatcher(
                        "/WEB-INF/category/delete.jsp"
                ).forward(request, response);

            } catch (NumberFormatException e) {

                LOGGER.log(
                        Level.WARNING,
                        "ID không hợp lệ khi mở Delete Category",
                        e
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/category?view=list"
                );
            }

        // ==================== INVALID VIEW ====================
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

        // ==================== CREATE ====================
        if ("create".equals(action)) {

            try {

                String name = request.getParameter("name");

                String parentIdStr =
                        request.getParameter("parentId");

                Integer parentId = null;

                if (parentIdStr != null
                        && !parentIdStr.trim().isEmpty()) {

                    parentId = Integer.parseInt(parentIdStr);
                }

                Category category = new Category();

                category.setCategoryName(name);
                category.setParentId(parentId);

                dao.insert(category);

                response.sendRedirect(
                        request.getContextPath()
                        + "/category?view=list"
                );

            } catch (Exception e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi khi thêm Category!",
                        e
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/category?view=create&error=true"
                );
            }

        // ==================== EDIT ====================
        } else if ("edit".equals(action)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                String name =
                        request.getParameter("name");

                String parentIdStr =
                        request.getParameter("parentId");

                Integer parentId = null;

                if (parentIdStr != null
                        && !parentIdStr.trim().isEmpty()) {

                    parentId = Integer.parseInt(parentIdStr);
                }

                Category category =
                        new Category(id, name, parentId);

                dao.edit(category);

                response.sendRedirect(
                        request.getContextPath()
                        + "/category?view=list"
                );

            } catch (Exception e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi khi cập nhật Category!",
                        e
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/category?view=list"
                );
            }

        // ==================== DELETE ====================
        } else if ("delete".equals(action)) {

            try {

                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                Category category = new Category();

                category.setCategoryId(id);

                dao.delete(category);

                response.sendRedirect(
                        request.getContextPath()
                        + "/category?view=list"
                );

            } catch (Exception e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Lỗi khi xóa Category!",
                        e
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/category?view=list"
                );
            }

        // ==================== INVALID ACTION ====================
        } else {

            response.sendRedirect(
                    request.getContextPath()
                    + "/category?view=list"
            );
        }
    }
}