package controller;

import dao.OrderDAO;
import model.Order;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(
        name = "OrderSuccessServlet",
        urlPatterns = {"/order-success"}
)
public class OrderSuccessServlet extends HttpServlet {

    private static final Logger LOGGER =
            Logger.getLogger(OrderSuccessServlet.class.getName());

    private final OrderDAO orderDAO = new OrderDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        // KHONG LUU CACHE THONG TIN DON HANG
        response.setHeader("Cache-Control", "no-store");

        // KIEM TRA DANG NHAP
        HttpSession session = request.getSession(false);

        Object loggedInUser = session == null
                ? null
                : session.getAttribute("loggedInUser");

        if (!(loggedInUser instanceof User)) {
            response.sendRedirect(
                    request.getContextPath() + "/login"
            );
            return;
        }

        User user = (User) loggedInUser;

        // LAY MA DON TU URL
        int orderId;

        try {
            orderId = Integer.parseInt(
                    request.getParameter("id")
            );

            if (orderId <= 0) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Mã đơn hàng không hợp lệ."
            );
            return;
        }

        try {
            // CHI CHO XEM DON HANG CUA CHINH USER
            Order order = orderDAO.findByIdAndUser(
                    orderId,
                    user.getUserId()
            );

            if (order == null) {
                response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "Không tìm thấy đơn hàng."
                );
                return;
            }

            // GUI DU LIEU SANG JSP
            request.setAttribute("order", order);

            request.getRequestDispatcher(
                    "/WEB-INF/checkout/order-success.jsp"
            ).forward(request, response);

        } catch (SQLException e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Loi tai thong tin don hang!",
                    e
            );

            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Chưa tải được thông tin đơn hàng. Vui lòng thử lại."
            );
        }
    }
}