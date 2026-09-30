package controller;

import dao.CategoryDAO;
import model.Category;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet(name = "CategoryServlet", urlPatterns = {"/category"})
public class CategoryServlet extends HttpServlet {

    private final CategoryDAO categoryDAO = new CategoryDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        if (action == null) action = "list";

        if (action.equals("delete")) {
            int id = Integer.parseInt(request.getParameter("id"));
            categoryDAO.delete(id);
            response.sendRedirect("category"); // Load lại trang
            return;
        }

        // Mặc định là list hiển thị giao diện
        List<Category> list = categoryDAO.getList();
        request.setAttribute("categories", list);
        request.getRequestDispatcher("category-admin.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        String name = request.getParameter("categoryName");
        String parentIdStr = request.getParameter("parentId");
        String displayOrderStr = request.getParameter("displayOrder");

        Integer parentId = (parentIdStr == null || parentIdStr.trim().isEmpty() || parentIdStr.equals("0")) ? null : Integer.parseInt(parentIdStr);
        int displayOrder = (displayOrderStr == null || displayOrderStr.trim().isEmpty()) ? 0 : Integer.parseInt(displayOrderStr);

        if ("add".equals(action)) {
            Category c = new Category(0, name, parentId, displayOrder);
            categoryDAO.insert(c);
        } else if ("update".equals(action)) {
            int id = Integer.parseInt(request.getParameter("categoryId"));
            Category c = new Category(id, name, parentId, displayOrder);
            categoryDAO.update(c);
        }
        
        response.sendRedirect("category");
    }
}