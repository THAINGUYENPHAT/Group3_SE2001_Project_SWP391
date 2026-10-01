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

        // Thiết lập header trả về JSON và hỗ trợ tiếng Việt
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String keyword = request.getParameter("q");
        PrintWriter out = response.getWriter();

        if (keyword == null || keyword.trim().isEmpty()) {
            out.write("[]"); // Trả về mảng rỗng nếu không có từ khóa
            return;
        }

        ShopDAO shopDao = new ShopDAO();
        List<Product> products = shopDao.searchProducts(keyword.trim());

        // Build chuỗi JSON thủ công
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < products.size(); i++) {
            Product p = products.get(i);

            String safeName = p.getProductName().replace("\"", "\\\"");

            json.append("{");
            json.append("\"id\":").append(p.getProductId()).append(",");
            json.append("\"name\":\"").append(safeName).append("\",");
            json.append("\"price\":").append(p.getMinPrice()); 
            json.append("}");

            if (i < products.size() - 1) {
                json.append(",");
            }
        }
        json.append("]");

        out.write(json.toString());
        out.flush();
    }
}
