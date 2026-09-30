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

    private static final Logger LOGGER = Logger.getLogger(CategoryServlet.class.getName());
    private final CategoryDAO categoryDAO = new CategoryDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        if ("delete".equals(action)) {
            // =====================================================
            // 1. XÓA DANH MỤC
            // =====================================================
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                categoryDAO.delete(id);
            } catch (NumberFormatException e) {
                LOGGER.log(Level.WARNING, "ID không hợp lệ khi xóa Category!", e);
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi khi xóa Category!", e);
            }
            response.sendRedirect(request.getContextPath() + "/category");
            return;
        }

        // =====================================================
        // 2. DANH SÁCH DANH MỤC (MẶC ĐỊNH)
        // =====================================================
        try {
            List<Category> list = categoryDAO.getList();
            request.setAttribute("categories", list);
            request.getRequestDispatcher("category-admin.jsp").forward(request, response);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi lấy danh sách Category!", e);
            response.sendRedirect(request.getContextPath() + "/category");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            String name = request.getParameter("categoryName");
            String parentIdStr = request.getParameter("parentId");
            String displayOrderStr = request.getParameter("displayOrder");

            Integer parentId = (parentIdStr == null || parentIdStr.trim().isEmpty() || "0".equals(parentIdStr.trim()))
                    ? null
                    : Integer.parseInt(parentIdStr.trim());

            int displayOrder = (displayOrderStr == null || displayOrderStr.trim().isEmpty())
                    ? 0
                    : Integer.parseInt(displayOrderStr.trim());

            if ("add".equals(action)) {
                // =====================================================
                // 1. THÊM DANH MỤC MỚI
                // =====================================================
                Category c = new Category(0, name, parentId, displayOrder);
                categoryDAO.insert(c);

            } else if ("update".equals(action)) {
                // =====================================================
                // 2. CẬP NHẬT DANH MỤC
                // =====================================================
                int id = Integer.parseInt(request.getParameter("categoryId"));
                Category c = new Category(id, name, parentId, displayOrder);
                categoryDAO.update(c);
            }

        } catch (NumberFormatException e) {
            LOGGER.log(Level.WARNING, "Dữ liệu định dạng số không hợp lệ trong form Category!", e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi thực hiện thêm/sửa Category!", e);
        }

        response.sendRedirect(request.getContextPath() + "/category");
    }
}