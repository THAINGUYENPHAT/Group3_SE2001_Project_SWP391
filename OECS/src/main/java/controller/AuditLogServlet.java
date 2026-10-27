package controller;

import dao.AuditLogDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.AuditLog;

import java.io.IOException;
import java.util.List;

@WebServlet(name = "AuditLogServlet",
        urlPatterns = {"/admin/audit-log"})
public class AuditLogServlet extends HttpServlet {

    private final AuditLogDAO auditLogDAO
            = new AuditLogDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String keyword
                = request.getParameter("keyword");

        String action
                = request.getParameter("action");

        String entityType
                = request.getParameter("entityType");

        List<AuditLog> logs
                = auditLogDAO.search(
                        keyword,
                        action,
                        entityType
                );

        request.setAttribute("auditLogs", logs);
        request.setAttribute("keyword", keyword);
        request.setAttribute("selectedAction", action);
        request.setAttribute("selectedEntityType", entityType);

        request.getRequestDispatcher(
                "/WEB-INF/admin/audit-log.jsp"
        ).forward(request, response);
    }
}
