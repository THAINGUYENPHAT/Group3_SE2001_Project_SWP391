package controller;

import dao.BrandDAO;
import model.Brand;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "BrandServlet", urlPatterns = {"/brand"})
public class BrandServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(BrandServlet.class.getName());

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
            // =====================================================
            // 1. DANH SÁCH BRAND
            // =====================================================
            List<Brand> brandList = dao.getList();
            request.setAttribute("brandList", brandList);
            request.getRequestDispatcher("/WEB-INF/brand/list.jsp").forward(request, response);

        } else if ("create".equals(view)) {
            // =====================================================
            // 2. TRANG THÊM BRAND
            // =====================================================
            request.getRequestDispatcher("/WEB-INF/brand/create.jsp").forward(request, response);

        } else if ("edit".equals(view)) {
            // =====================================================
            // 3. TRANG SỬA BRAND
            // =====================================================
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Brand selectedBrand = dao.getById(id);

                request.setAttribute("brand", selectedBrand);
                request.getRequestDispatcher("/WEB-INF/brand/edit.jsp").forward(request, response);
            } catch (NumberFormatException e) {
                LOGGER.log(Level.WARNING, "ID không hợp lệ khi mở trang Edit Brand", e);
                response.sendRedirect(request.getContextPath() + "/brand?view=list");
            }

        } else if ("delete".equals(view)) {
            // =====================================================
            // 4. TRANG XÁC NHẬN XÓA BRAND
            // =====================================================
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Brand selectedBrand = dao.getById(id);

                request.setAttribute("brand", selectedBrand);
                request.getRequestDispatcher("/WEB-INF/brand/delete.jsp").forward(request, response);
            } catch (NumberFormatException e) {
                LOGGER.log(Level.WARNING, "ID không hợp lệ khi mở trang Delete Brand", e);
                response.sendRedirect(request.getContextPath() + "/brand?view=list");
            }
        } else {
            response.sendRedirect(request.getContextPath() + "/brand?view=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");
        BrandDAO dao = new BrandDAO();

        if ("create".equals(action)) {
            // =====================================================
            // 1. THỰC THI THÊM BRAND
            // =====================================================
            String name = request.getParameter("name");
            String logoUrl = request.getParameter("logoUrl");

            try {
                Brand newBrand = new Brand();
                newBrand.setBrandName(name);
                newBrand.setLogoUrl(logoUrl);

                dao.insert(newBrand);
                response.sendRedirect(request.getContextPath() + "/brand?view=list");
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi khi thêm mới Brand!", e);
                response.sendRedirect(request.getContextPath() + "/brand?view=create&error=true");
            }

        } else if ("edit".equals(action)) {
            // =====================================================
            // 2. THỰC THI SỬA BRAND
            // =====================================================
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                String name = request.getParameter("name");
                String logoUrl = request.getParameter("logoUrl");

                Brand brand = new Brand(id, name, logoUrl);
                dao.edit(brand);

                response.sendRedirect(request.getContextPath() + "/brand?view=list");
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi khi cập nhật Brand!", e);
                response.sendRedirect(request.getContextPath() + "/brand?view=list");
            }

        } else if ("delete".equals(action)) {
            // =====================================================
            // 3. THỰC THI XÓA BRAND
            // =====================================================
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Brand brand = new Brand();
                brand.setBrandId(id);

                dao.delete(brand);

                response.sendRedirect(request.getContextPath() + "/brand?view=list");
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Lỗi khi xóa Brand!", e);
                response.sendRedirect(request.getContextPath() + "/brand?view=list");
            }
        } else {
            response.sendRedirect(request.getContextPath() + "/brand?view=list");
        }
    }
}