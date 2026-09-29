package controller;

import dao.BrandDAO;
import model.Brand;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;

@WebServlet(name = "BrandServlet", urlPatterns = {"/brand"})
public class BrandServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Kiểm tra trạng thái đăng nhập (Có thể mở comment khi ghép với phân quyền)
        /*
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("loggedInUser");
        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        */

        String view = request.getParameter("view");
        BrandDAO dao = new BrandDAO();

        if (view == null || view.equals("list")) {
            List<Brand> brandList = dao.getList();
            request.setAttribute("brandList", brandList);
            request.getRequestDispatcher("/WEB-INF/brand/list.jsp").forward(request, response);
        } 
        else if (view.equals("create")) {
            request.getRequestDispatcher("/WEB-INF/brand/create.jsp").forward(request, response);
        } 
        else if (view.equals("edit")) {
            int id = Integer.parseInt(request.getParameter("id"));
            Brand selectedBrand = dao.getById(id);

            request.setAttribute("brand", selectedBrand);
            request.getRequestDispatcher("/WEB-INF/brand/edit.jsp").forward(request, response);
        } 
        else if (view.equals("delete")) {
            int id = Integer.parseInt(request.getParameter("id"));
            Brand selectedBrand = dao.getById(id);

            request.setAttribute("brand", selectedBrand);
            request.getRequestDispatcher("/WEB-INF/brand/delete.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");
        BrandDAO dao = new BrandDAO();

        if ("create".equals(action)) {
            String name = request.getParameter("name");
            String logoUrl = request.getParameter("logoUrl");

            try {
                Brand newBrand = new Brand();
                newBrand.setBrandName(name);
                newBrand.setLogoUrl(logoUrl);

                dao.insert(newBrand);
                response.sendRedirect(request.getContextPath() + "/brand?view=list");
            } catch (Exception e) {
                System.out.println("Lỗi khi thêm mới Brand: " + e.getMessage());
            }
        } 
        else if ("edit".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            String name = request.getParameter("name");
            String logoUrl = request.getParameter("logoUrl");

            Brand brand = new Brand(id, name, logoUrl);
            dao.edit(brand);

            response.sendRedirect(request.getContextPath() + "/brand?view=list");
        } 
        else if ("delete".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            Brand brand = new Brand();
            brand.setBrandId(id);

            dao.delete(brand);

            response.sendRedirect(request.getContextPath() + "/brand?view=list");
        }
    }
}