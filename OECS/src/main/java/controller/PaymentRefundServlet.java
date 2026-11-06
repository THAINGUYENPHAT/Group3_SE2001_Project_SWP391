package controller;

import dao.PaymentRefundDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.User;

@WebServlet(name = "PaymentRefundServlet", urlPatterns = "/staff/payment-refunds")
public class PaymentRefundServlet extends HttpServlet {
    private final PaymentRefundDAO refunds = new PaymentRefundDAO();
    private static final Logger LOG = Logger.getLogger(PaymentRefundServlet.class.getName());

    private User staff(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("loggedInUser");
        if (user == null || !user.isStaff()) {
            response.sendError(403);
            return null;
        }
        return user;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (staff(request, response) == null) return;
        response.setHeader("Cache-Control", "no-store");
        HttpSession session = request.getSession();
        synchronized (session) {
            if (session.getAttribute("refundToken") == null) {
                session.setAttribute("refundToken", UUID.randomUUID().toString());
            }
        }
        try {
            int page = 1;
            if (request.getParameter("page") != null) {
                page = Integer.parseInt(request.getParameter("page"));
            }
            if (page < 1 || page > 1000000) throw new IllegalArgumentException();
            request.setAttribute("refunds", refunds.findPage(page));
            request.setAttribute("currentPage", page);
            request.getRequestDispatcher("/WEB-INF/staff/payment-refunds.jsp").forward(request, response);
        } catch (IllegalArgumentException e) {
            response.sendError(400);
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Cannot load payment refunds", e);
            response.sendError(500, "Không tải được yêu cầu hoàn tiền.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");
        User user = staff(request, response);
        if (user == null) return;
        HttpSession session = request.getSession();
        String token = request.getParameter("csrfToken");
        if (token == null || !token.equals(session.getAttribute("refundToken"))) {
            response.sendError(403);
            return;
        }
        try {
            refunds.updateStatus(Long.parseLong(request.getParameter("id")),
                    request.getParameter("expectedStatus"), request.getParameter("status"),
                    request.getParameter("reference"), user.getUserId());
            session.setAttribute("refundMessage", "Đã cập nhật yêu cầu hoàn tiền.");
        } catch (IllegalArgumentException e) {
            session.setAttribute("refundMessage", "Không cập nhật được. " + e.getMessage());
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Cannot update payment refund", e);
            session.setAttribute("refundMessage", "Không cập nhật được. Vui lòng thử lại.");
        }
        response.sendRedirect(request.getContextPath() + "/staff/payment-refunds");
    }
}
