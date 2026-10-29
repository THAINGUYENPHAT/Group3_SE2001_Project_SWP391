
package controller;

import dao.BannerDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import model.Banner;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;

@WebServlet(name = "BannerServlet", urlPatterns = {"/staff/banner"})
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 10 * 1024 * 1024,
        maxRequestSize = 20 * 1024 * 1024
)
public class BannerServlet extends HttpServlet {

    private final BannerDAO bannerDAO = new BannerDAO();

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            int bannerId = Integer.parseInt(
                    request.getParameter("id"));

            bannerDAO.delete(bannerId);

            response.sendRedirect(
                    request.getContextPath() + "/staff/banner");
            return;
        }

        if ("toggle".equals(action)) {
            int bannerId = Integer.parseInt(
                    request.getParameter("id"));

            boolean active = "1".equals(
                    request.getParameter("active"));

            bannerDAO.updateActive(bannerId, active);

            response.sendRedirect(
                    request.getContextPath() + "/staff/banner");
            return;
        }

        List<Banner> banners = bannerDAO.getAll();

        request.setAttribute("banners", banners);

        request.getRequestDispatcher(
                "/WEB-INF/banner/list.jsp")
                .forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String altText = request.getParameter("altText");
        String targetUrl = request.getParameter("targetUrl");
        String orderValue = request.getParameter("displayOrder");

        int displayOrder = 0;

        try {
            if (orderValue != null
                    && !orderValue.trim().isEmpty()) {
                displayOrder = Integer.parseInt(orderValue);
            }
        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Thứ tự banner không hợp lệ.");
            return;
        }

        Part imagePart = request.getPart("imageFile");

        if (imagePart == null || imagePart.getSize() == 0) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Vui lòng chọn ảnh banner.");
            return;
        }

        String contentType = imagePart.getContentType();

        if (contentType == null
                || !(contentType.equals("image/jpeg")
                || contentType.equals("image/png")
                || contentType.equals("image/gif")
                || contentType.equals("image/webp"))) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Chỉ chấp nhận ảnh JPG, PNG, GIF hoặc WEBP.");
            return;
        }

        String originalName = imagePart.getSubmittedFileName();

        if (originalName == null) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Tên file ảnh không hợp lệ.");
            return;
        }

        originalName = Paths.get(originalName)
                .getFileName().toString();

        int dotIndex = originalName.lastIndexOf('.');

        if (dotIndex < 0) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "File ảnh không có phần mở rộng.");
            return;
        }

        String extension = originalName.substring(dotIndex)
                .toLowerCase();

        if (!(extension.equals(".jpg")
                || extension.equals(".jpeg")
                || extension.equals(".png")
                || extension.equals(".gif")
                || extension.equals(".webp"))) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Định dạng file ảnh không hợp lệ.");
            return;
        }

        String fileName = UUID.randomUUID().toString()
                + extension;

        Path webappPath = findWebappPath();
        Path uploadDirectory = webappPath
                .resolve("uploads")
                .resolve("banners");

        Files.createDirectories(uploadDirectory);

        Path destination = uploadDirectory.resolve(fileName);

        try (java.io.InputStream input = imagePart.getInputStream()) {
            Files.copy(input, destination,
                    StandardCopyOption.REPLACE_EXISTING);
        }

        Banner banner = new Banner();
        banner.setImageUrl("uploads/banners/" + fileName);
        banner.setAltText(altText);
        banner.setTargetUrl(targetUrl);
        banner.setActive(true);
        banner.setDisplayOrder(displayOrder);

        if (!bannerDAO.insert(banner)) {
            Files.deleteIfExists(destination);

            throw new ServletException(
                    "Không thể lưu banner vào database.");
        }

        response.sendRedirect(
                request.getContextPath() + "/staff/banner");
    }

    
private Path findWebappPath() throws ServletException {
    String projectPath = getServletContext()
            .getInitParameter("projectWebappPath");

    if (projectPath == null || projectPath.trim().isEmpty()) {
        throw new ServletException(
                "Chưa cấu hình projectWebappPath trong web.xml.");
    }

    Path webappPath = Paths.get(projectPath)
            .toAbsolutePath().normalize();

    if (!Files.isDirectory(webappPath)) {
        throw new ServletException(
                "Thư mục webapp không tồn tại: " + webappPath);
    }

    return webappPath;
}

}
