package controller;

import dao.ShopDAO;
import model.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

@WebServlet(name = "SearchApiServlet", urlPatterns = {"/api/search"})
public class SearchApiServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String keyword = request.getParameter("q");
        PrintWriter out = response.getWriter();

        if (keyword == null || keyword.trim().isEmpty()) {
            out.write("[]");
            return;
        }

        ShopDAO shopDao = new ShopDAO();
        List<Product> products = shopDao.searchProducts(keyword.trim());

        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < products.size(); i++) {
            Product p = products.get(i);

            String safeName = escapeJson(p.getProductName());
            String safeImageUrl = escapeJson(p.getImageUrl());

            json.append("{");
            json.append("\"id\":").append(p.getProductId()).append(",");
            json.append("\"name\":\"").append(safeName).append("\",");
            json.append("\"price\":").append(p.getMinPrice()).append(",");
            json.append("\"imageUrl\":\"").append(safeImageUrl).append("\"");
            json.append("}");

            if (i < products.size() - 1) {
                json.append(",");
            }
        }
        json.append("]");

        out.write(json.toString());
        out.flush();
    }

    /**
     * Correct JSON string escaping without adding an external dependency.
     */
    private static String escapeJson(String raw) {
        if (raw == null) {
            return "";
        }
        StringBuilder safe = new StringBuilder(raw.length() + 8);
        for (int i = 0; i < raw.length(); i++) {
            char c = raw.charAt(i);
            switch (c) {
                case '"':
                    safe.append("\\\"");
                    break;
                case '\\':
                    safe.append("\\\\");
                    break;
                case '\b':
                    safe.append("\\b");
                    break;
                case '\f':
                    safe.append("\\f");
                    break;
                case '\n':
                    safe.append("\\n");
                    break;
                case '\r':
                    safe.append("\\r");
                    break;
                case '\t':
                    safe.append("\\t");
                    break;
                default:
                    if (c < 0x20) {
                        safe.append(String.format("\\u%04x", (int) c));
                    } else {
                        safe.append(c);
                    }
            }
        }
        return safe.toString();
    }
}
