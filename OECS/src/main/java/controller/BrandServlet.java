package controller;

import dao.BrandDAO;
import model.Brand;
import service.AuditLogService;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "BrandServlet", urlPatterns = {"/brand"})
public class BrandServlet extends HttpServlet {

    private static final Logger LOGGER
            = Logger.getLogger(BrandServlet.class.getName());

    private final AuditLogService auditLogService
            = new AuditLogService();

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String view = request.getParameter("view");
        BrandDAO dao = new BrandDAO();
        String contextPath = request.getContextPath();

        if (view == null || view.equals("list")) {

            final int pageSize = 10;

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

            int totalBrands;

            if (keyword.isEmpty()) {
                totalBrands = dao.countBrands();
            } else {
                totalBrands = dao.countSearchResults(keyword);
            }

            int totalPages = Math.max(
                    1,
                    (int) Math.ceil((double) totalBrands / pageSize)
            );

            if (page > totalPages) {
                page = totalPages;
            }

            List<Brand> brandList;

            if (keyword.isEmpty()) {
                brandList = dao.getListByPage(page, pageSize);
            } else {
                brandList = dao.searchByNameAndPage(
                        keyword, page, pageSize
                );
            }

            Map<Integer, Integer> productCounts
                    = dao.getProductCounts(brandList);

            int startItem = totalBrands == 0
                    ? 0
                    : (page - 1) * pageSize + 1;

            int endItem = Math.min(page * pageSize, totalBrands);

            request.setAttribute("brandList", brandList);
            request.setAttribute("keyword", keyword);
            request.setAttribute("productCounts", productCounts);
            request.setAttribute("currentPage", page);
            request.setAttribute("totalPages", totalPages);
            request.setAttribute("totalBrands", totalBrands);
            request.setAttribute("startItem", startItem);
            request.setAttribute("endItem", endItem);

            request.getRequestDispatcher("/WEB-INF/brand/list.jsp")
                    .forward(request, response);

        } else if ("create".equals(view)) {

            request.getRequestDispatcher("/WEB-INF/brand/create.jsp")
                    .forward(request, response);

        } else if ("edit".equals(view)) {

            try {
                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                if (id <= 0) {
                    throw new NumberFormatException();
                }

                Brand selectedBrand = dao.getById(id);

                if (selectedBrand == null) {
                    response.sendRedirect(contextPath
                            + "/brand?view=list&error=notFound");
                    return;
                }

                request.setAttribute("brand", selectedBrand);

                request.getRequestDispatcher("/WEB-INF/brand/edit.jsp")
                        .forward(request, response);

            } catch (NumberFormatException e) {
                LOGGER.log(
                        Level.WARNING,
                        "Invalid ID when opening Edit Brand",
                        e
                );

                response.sendRedirect(contextPath
                        + "/brand?view=list&error=invalidId");
            }

        } else if ("delete".equals(view)) {

            try {
                int id = Integer.parseInt(
                        request.getParameter("id")
                );

                if (id <= 0) {
                    throw new NumberFormatException();
                }

                Brand selectedBrand = dao.getById(id);

                if (selectedBrand == null) {
                    response.sendRedirect(contextPath
                            + "/brand?view=list&error=notFound");
                    return;
                }

                // Dem so san pham cua thuong hieu
                int productCount = dao.countProductsByBrandId(id);

                request.setAttribute("brand", selectedBrand);
                request.setAttribute("productCount", productCount);

                request.getRequestDispatcher("/WEB-INF/brand/delete.jsp")
                        .forward(request, response);

            } catch (NumberFormatException e) {
                LOGGER.log(
                        Level.WARNING,
                        "Invalid ID when opening Delete Brand",
                        e
                );

                response.sendRedirect(contextPath
                        + "/brand?view=list&error=invalidId");

            } catch (Exception e) {
                LOGGER.log(
                        Level.SEVERE,
                        "Cannot open Delete Brand page",
                        e
                );

                response.sendRedirect(contextPath
                        + "/brand?view=list&error=server");
            }

        } else {
            response.sendRedirect(contextPath + "/brand?view=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        BrandDAO dao = new BrandDAO();
        String contextPath = request.getContextPath();

        if ("create".equals(action)) {

            String name = request.getParameter("name");
            String logoUrl = request.getParameter("logoUrl");

            name = name == null ? "" : name.trim();
            logoUrl = logoUrl == null ? "" : logoUrl.trim();

            if (name.isEmpty()) {
                response.sendRedirect(contextPath
                        + "/brand?view=create&error=empty");
                return;
            }

            if (name.length() > 100) {
                response.sendRedirect(contextPath
                        + "/brand?view=create&error=length");
                return;
            }

            if (logoUrl.isEmpty()) {
                logoUrl = null;
            } else if (logoUrl.length() > 2048
                    || !logoUrl.matches("(?i)^https?://.+")) {
                response.sendRedirect(contextPath
                        + "/brand?view=create&error=logo");
                return;
            }

            try {
                if (dao.isNameExists(name, 0)) {
                    response.sendRedirect(contextPath
                            + "/brand?view=create&error=duplicate");
                    return;
                }

                Brand brand = new Brand(0, name, logoUrl);
                int result = dao.insert(brand);

                if (result == 1) {
                    User loggedInUser
                            = (User) request.getSession()
                                    .getAttribute("loggedInUser");

                    auditLogService.log(
                            loggedInUser,
                            "CREATE_BRAND",
                            "BRAND",
                            null,
                            "Created brand: " + name,
                            request
                    );

                    response.sendRedirect(contextPath
                            + "/brand?view=list&success=create");
                } else {
                    response.sendRedirect(contextPath
                            + "/brand?view=create&error=save");
                }

            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Cannot create brand", e);

                response.sendRedirect(contextPath
                        + "/brand?view=create&error=server");
            }

        } else if ("edit".equals(action)) {

            String idText = request.getParameter("id");
            String name = request.getParameter("name");
            String logoUrl = request.getParameter("logoUrl");

            name = name == null ? "" : name.trim();
            logoUrl = logoUrl == null ? "" : logoUrl.trim();

            int id;

            try {
                id = Integer.parseInt(idText);

                if (id <= 0) {
                    throw new NumberFormatException();
                }
            } catch (NumberFormatException e) {
                response.sendRedirect(contextPath
                        + "/brand?view=list&error=invalidId");
                return;
            }

            if (name.isEmpty()) {
                response.sendRedirect(contextPath
                        + "/brand?view=edit&id=" + id + "&error=empty");
                return;
            }

            if (name.length() > 100) {
                response.sendRedirect(contextPath
                        + "/brand?view=edit&id=" + id + "&error=length");
                return;
            }

            if (logoUrl.isEmpty()) {
                logoUrl = null;
            } else if (logoUrl.length() > 2048
                    || !logoUrl.matches("(?i)^https?://.+")) {
                response.sendRedirect(contextPath
                        + "/brand?view=edit&id=" + id + "&error=logo");
                return;
            }

            try {
                Brand existing = dao.getById(id);

                if (existing == null) {
                    response.sendRedirect(contextPath
                            + "/brand?view=list&error=notFound");
                    return;
                }

                if (dao.isNameExists(name, id)) {
                    response.sendRedirect(contextPath
                            + "/brand?view=edit&id=" + id
                            + "&error=duplicate");
                    return;
                }

                Brand brand = new Brand(id, name, logoUrl);
                int result = dao.edit(brand);

                if (result == 1) {
                    User loggedInUser
                            = (User) request.getSession()
                                    .getAttribute("loggedInUser");

                    auditLogService.log(
                            loggedInUser,
                            "UPDATE_BRAND",
                            "BRAND",
                            null,
                            "Updated brand: " + name,
                            request
                    );
                    
                    response.sendRedirect(contextPath
                            + "/brand?view=list&success=edit");
                } else {
                    response.sendRedirect(contextPath
                            + "/brand?view=edit&id=" + id
                            + "&error=save");
                }

            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Cannot edit brand", e);

                response.sendRedirect(contextPath
                        + "/brand?view=edit&id=" + id
                        + "&error=server");
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
                response.sendRedirect(contextPath
                        + "/brand?view=list&error=invalidId");
                return;
            }

            try {
                Brand existing = dao.getById(id);

                if (existing == null) {
                    response.sendRedirect(contextPath
                            + "/brand?view=list&error=notFound");
                    return;
                }

                // Kiem tra lai truoc khi xoa
                int productCount = dao.countProductsByBrandId(id);

                if (productCount > 0) {
                    response.sendRedirect(contextPath
                            + "/brand?view=delete&id=" + id
                            + "&error=hasProducts");
                    return;
                }

                int result = dao.delete(existing);

                if (result == 1) {
                    
                    User loggedInUser
                            = (User) request.getSession()
                                    .getAttribute("loggedInUser");

                    auditLogService.log(
                            loggedInUser,
                            "DELETE_BRAND",
                            "BRAND",
                            null,
                            "Deleted brand: " + existing.getBrandName(),
                            request
                    );
                    
                    response.sendRedirect(contextPath
                            + "/brand?view=list&success=delete");
                } else {
                    response.sendRedirect(contextPath
                            + "/brand?view=delete&id=" + id
                            + "&error=delete");
                }

            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Cannot delete brand", e);

                response.sendRedirect(contextPath
                        + "/brand?view=delete&id=" + id
                        + "&error=server");
            }

        } else {
            response.sendRedirect(contextPath + "/brand?view=list");
        }
    }
}
