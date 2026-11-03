
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
import java.io.InputStream;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.regex.Pattern;

@WebServlet(name = "BannerServlet", urlPatterns = {"/staff/banner"})
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 10 * 1024 * 1024,
        maxRequestSize = 20 * 1024 * 1024
)
public class BannerServlet extends HttpServlet {

    private final BannerDAO bannerDAO = new BannerDAO();

    // Cho phep chu tieng Viet, chu cai, so, khoang trang va dau cau thong dung.
    private static final Pattern ALT_TEXT_PATTERN = Pattern.compile(
            "^[\\p{L}\\p{M}\\p{N}\\s.,!?()'’:;-]*$"
    );

    private Path getUploadDirectory() throws IOException {
        Path uploadDirectory = Paths.get(
                System.getProperty("user.home"),
                "OECS-uploads",
                "banners"
        ).toAbsolutePath().normalize();

        Files.createDirectories(uploadDirectory);

        return uploadDirectory;
    }

    // Kiem tra mo ta banner
    private boolean isValidAltText(String altText) {
        if (altText == null) {
            return true;
        }

        altText = altText.trim();

        return altText.length() <= 255
                && ALT_TEXT_PATTERN.matcher(altText).matches();
    }

    // Kiem tra lien ket banner
    private boolean isValidTargetUrl(String targetUrl) {
        if (targetUrl == null || targetUrl.trim().isEmpty()) {
            return true;
        }

        targetUrl = targetUrl.trim();

        if (targetUrl.length() > 2048
                || targetUrl.startsWith("//")
                || targetUrl.contains("\\")
                || targetUrl.matches("(?i).*%(0[0-9a-f]|1[0-9a-f]|7f).*")) {
            return false;
        }

        // Khong cho phep khoang trang va ky tu dieu khien
        if (targetUrl.chars().anyMatch(
                c -> Character.isWhitespace(c)
                || Character.isISOControl(c))) {
            return false;
        }

        try {
            URI uri = URI.create(targetUrl);

            // Chi chap nhan duong dan noi bo bat dau bang /
            if (targetUrl.startsWith("/")) {
                return !uri.isAbsolute()
                        && uri.getRawAuthority() == null
                        && uri.getRawPath() != null
                        && uri.getRawPath().startsWith("/");
            }

            // URL ben ngoai chi chap nhan HTTPS
            return "https".equalsIgnoreCase(uri.getScheme())
                    && uri.getHost() != null
                    && !uri.getHost().isEmpty()
                    && uri.getUserInfo() == null;

        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    // Chuyen huong khi du lieu khong hop le
    private void redirectError(
            HttpServletRequest request,
            HttpServletResponse response,
            String error
    ) throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/staff/banner?error="
                + error
        );
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            String idValue = request.getParameter("id");

            try {
                int bannerId = Integer.parseInt(idValue);

                if (bannerId <= 0) {
                    throw new NumberFormatException();
                }

                bannerDAO.delete(bannerId);

            } catch (NumberFormatException e) {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "ID banner không hợp lệ."
                );
                return;
            }

            response.sendRedirect(
                    request.getContextPath() + "/staff/banner"
            );
            return;
        }

        if ("toggle".equals(action)) {
            String idValue = request.getParameter("id");

            try {
                int bannerId = Integer.parseInt(idValue);

                if (bannerId <= 0) {
                    throw new NumberFormatException();
                }

                boolean active = "1".equals(
                        request.getParameter("active")
                );

                bannerDAO.updateActive(bannerId, active);

            } catch (NumberFormatException e) {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "ID banner không hợp lệ."
                );
                return;
            }

            response.sendRedirect(
                    request.getContextPath() + "/staff/banner"
            );
            return;
        }

        List<Banner> banners = bannerDAO.getAll();
        request.setAttribute("banners", banners);

        request.getRequestDispatcher(
                "/WEB-INF/banner/list.jsp"
        ).forward(request, response);
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String altText = request.getParameter("altText");
        String targetUrl = request.getParameter("targetUrl");
        String orderValue = request.getParameter("displayOrder");

        // 1. Kiem tra mo ta
        if (!isValidAltText(altText)) {
            redirectError(request, response, "invalidAlt");
            return;
        }

        // 2. Kiem tra lien ket
        if (!isValidTargetUrl(targetUrl)) {
            redirectError(request, response, "invalidUrl");
            return;
        }

        // 3. Kiem tra thu tu hien thi
        int displayOrder = 0;

        try {
            if (orderValue == null
                    || orderValue.trim().isEmpty()) {
                redirectError(request, response, "invalidOrder");
                return;
            }

            displayOrder = Integer.parseInt(orderValue.trim());

            if (displayOrder < 0) {
                redirectError(request, response, "invalidOrder");
                return;
            }

        } catch (NumberFormatException e) {
            redirectError(request, response, "invalidOrder");
            return;
        }

        // 4. Kiem tra file anh
        Part imagePart = request.getPart("imageFile");

        if (imagePart == null || imagePart.getSize() == 0) {
            redirectError(request, response, "upload");
            return;
        }

        String contentType = imagePart.getContentType();

        if (contentType == null
                || !(contentType.equals("image/jpeg")
                || contentType.equals("image/png")
                || contentType.equals("image/gif")
                || contentType.equals("image/webp"))) {

            redirectError(request, response, "upload");
            return;
        }

        String originalName = imagePart.getSubmittedFileName();

        if (originalName == null || originalName.trim().isEmpty()) {
            redirectError(request, response, "upload");
            return;
        }

        originalName = Paths.get(originalName)
                .getFileName()
                .toString();

        int dotIndex = originalName.lastIndexOf('.');

        if (dotIndex < 0) {
            redirectError(request, response, "upload");
            return;
        }

        String extension = originalName.substring(dotIndex)
                .toLowerCase(Locale.ROOT);

        if (!(extension.equals(".jpg")
                || extension.equals(".jpeg")
                || extension.equals(".png")
                || extension.equals(".gif")
                || extension.equals(".webp"))) {

            redirectError(request, response, "upload");
            return;
        }

        // 5. Luu file anh
        String fileName = UUID.randomUUID() + extension;

        Path uploadDirectory = getUploadDirectory();

        Path destination = uploadDirectory.resolve(fileName)
                .normalize();

        if (!destination.startsWith(uploadDirectory)) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Đường dẫn file không hợp lệ."
            );
            return;
        }

        try (InputStream input = imagePart.getInputStream()) {
            Files.copy(
                    input,
                    destination,
                    StandardCopyOption.REPLACE_EXISTING
            );
        }

        // 6. Luu thong tin banner vao database
        Banner banner = new Banner();

        banner.setImageUrl("uploads/banners/" + fileName);
        banner.setAltText(
                altText == null || altText.trim().isEmpty()
                ? null : altText.trim()
        );
        banner.setTargetUrl(
                targetUrl == null || targetUrl.trim().isEmpty()
                ? null : targetUrl.trim()
        );
        banner.setActive(true);
        banner.setDisplayOrder(displayOrder);

        if (!bannerDAO.insert(banner)) {
            Files.deleteIfExists(destination);

            redirectError(request, response, "database");
            return;
        }

        response.sendRedirect(
                request.getContextPath() + "/staff/banner?success=create"
        );
    }
}
