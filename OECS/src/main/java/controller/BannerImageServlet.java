
package controller;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

@WebServlet(name = "BannerImageServlet",
        urlPatterns = {"/uploads/banners/*"})
public class BannerImageServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();

        if (pathInfo == null || pathInfo.length() < 2) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        String fileName = pathInfo.substring(1);

        if (fileName.contains("/")
                || fileName.contains("\\")
                || fileName.contains("..")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        Path webappPath = findWebappPath();
        Path imagePath = webappPath.resolve("uploads")
                .resolve("banners")
                .resolve(fileName)
                .normalize();

        Path uploadPath = webappPath.resolve("uploads")
                .resolve("banners")
                .normalize();

        if (!imagePath.startsWith(uploadPath)
                || !Files.isRegularFile(imagePath)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        String contentType = Files.probeContentType(imagePath);

        if (contentType == null
                || !contentType.startsWith("image/")) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        response.setContentType(contentType);
        response.setContentLengthLong(Files.size(imagePath));
        response.setHeader("X-Content-Type-Options", "nosniff");

        try (java.io.OutputStream output = response.getOutputStream()) {
            Files.copy(imagePath, output);
        }
    }

    private Path findWebappPath() throws ServletException {
    String projectPath = getServletContext()
            .getInitParameter("projectWebappPath");

    if (projectPath == null || projectPath.trim().isEmpty()) {
        throw new ServletException(
                "Chưa cấu hình projectWebappPath trong web.xml.");
    }

    Path webappPath = Paths.get(projectPath)
            .toAbsolutePath()
            .normalize();

    if (!Files.isDirectory(webappPath)) {
        throw new ServletException(
                "Thư mục webapp không tồn tại: " + webappPath);
    }

    return webappPath;
}
}
