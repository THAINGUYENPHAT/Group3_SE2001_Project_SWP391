
package controller;

import dao.BannerDAO;
import dao.ProductDAO;
import model.Banner;
import model.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

@WebServlet(name = "HomeServlet", urlPatterns = {"/home", ""})
public class HomeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        ProductDAO productDao = new ProductDAO();
        List<Product> productList = productDao.getList();

        BannerDAO bannerDAO = new BannerDAO();
        List<Banner> bannerList = bannerDAO.getActive();

        request.setAttribute("productList", productList);
        request.setAttribute("bannerList", bannerList);

        request.getRequestDispatcher("/WEB-INF/home.jsp")
                .forward(request, response);
    }
}
