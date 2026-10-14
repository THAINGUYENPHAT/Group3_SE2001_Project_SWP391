package controller;

import dao.NotificationDAO;
import model.Notification;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.List;

@WebServlet(name = "NotificationServlet", urlPatterns = "/notification")
public class NotificationServlet extends HttpServlet {

    private final NotificationDAO notificationDAO =
            new NotificationDAO();

    private User getLoggedInUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        if (session == null) {
            return null;
        }

        Object user = session.getAttribute("loggedInUser");

        if (user instanceof User) {
            return (User) user;
        }

        return null;
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        User user = getLoggedInUser(request);

        if (user == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        // Đổi getUserId() nếu model.User của bạn dùng tên getter khác.
        int userId = user.getUserId();
        String action = request.getParameter("action");

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            if ("count".equals(action)) {
                int count = notificationDAO.countUnread(userId);
                response.getWriter().write(
                        "{\"count\":" + count + "}");
            } else if ("list".equals(action)) {
                List<Notification> list =
                        notificationDAO.findLatest(userId);

                StringBuilder json = new StringBuilder("[");
                boolean first = true;

                for (Notification n : list) {
                    if (!first) {
                        json.append(",");
                    }
                    first = false;

                    json.append("{")
                        .append("\"id\":").append(n.getNotificationId())
                        .append(",\"orderId\":")
                        .append(n.getOrderId() == null
                                ? "null" : n.getOrderId())
                        .append(",\"title\":\"")
                        .append(escapeJson(n.getTitle()))
                        .append("\",\"message\":\"")
                        .append(escapeJson(n.getMessage()))
                        .append("\",\"read\":")
                        .append(n.isRead())
                        .append(",\"createdAt\":\"")
                        .append(escapeJson(
                                n.getCreatedAt() == null
                                ? "" : n.getCreatedAt().toString()))
                        .append("\"}");
                }

                json.append("]");
                response.getWriter().write(json.toString());
            } else {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST);
            }
                } catch (Exception e) {
            throw new ServletException(
                    "Cannot load notifications.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        User user = getLoggedInUser(request);

        if (user == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        String action = request.getParameter("action");

        if (!"read".equals(action)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            int id = Integer.parseInt(request.getParameter("id"));

            boolean updated = notificationDAO.markAsRead(
                    id, user.getUserId());

            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write(
                    "{\"success\":" + updated + "}");

        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                } catch (Exception e) {
            throw new ServletException(
                    "Cannot update notification.", e);
        }
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }

        return value.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\n", "\\n")
                    .replace("\r", "\\r")
                    .replace("\t", "\\t");
    }
}