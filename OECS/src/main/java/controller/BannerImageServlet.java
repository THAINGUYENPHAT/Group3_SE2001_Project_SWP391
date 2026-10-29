
package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@WebServlet(
        name = "BannerImageServlet",
        urlPatterns = {"/uploads/banners/*"}
)
public class BannerImageServlet extends HttpServlet {

    private Path getUploadDirectory() {
        return Paths.get(
                System.getProperty("user.home"),
                "OECS-uploads",
                "banners"
        ).toAbsolutePath().normalize();
    }

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

        Path uploadDirectory = getUploadDirectory();
        Path imagePath = uploadDirectory.resolve(fileName)
                .normalize();

        if (!imagePath.startsWith(uploadDirectory)
                || !Files.isRegularFile(imagePath)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        String extension = fileName.substring(
                fileName.lastIndexOf('.') + 1
        ).toLowerCase();

        String contentType;

        if (extension.equals("jpg") || extension.equals("jpeg")) {
            contentType = "image/jpeg";
        } else if (extension.equals("png")) {
            contentType = "image/png";
        } else if (extension.equals("gif")) {
            contentType = "image/gif";
        } else if (extension.equals("webp")) {
            contentType = "image/webp";
        } else {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        response.setContentType(contentType);
        response.setContentLengthLong(Files.size(imagePath));
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("Cache-Control", "no-cache");

        try (OutputStream output = response.getOutputStream()) {
            Files.copy(imagePath, output);
        }
    }
}
