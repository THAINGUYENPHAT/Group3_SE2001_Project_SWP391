package service;

import dao.AuditLogDAO;
import jakarta.servlet.http.HttpServletRequest;
import model.AuditLog;
import model.User;

public class AuditLogService {

    private final AuditLogDAO auditLogDAO;

    public AuditLogService() {
        auditLogDAO = new AuditLogDAO();
    }

    public boolean log(User actor,
            String action,
            String entityType,
            Long entityId,
            String description,
            HttpServletRequest request) {

        Integer actorUserId = null;
        String actorIdentifier = null;

        if (actor != null) {
            actorUserId = actor.getUserId();

            if (actor.getEmail() != null && !actor.getEmail().isEmpty()) {
                actorIdentifier = actor.getEmail();
            } else {
                actorIdentifier = actor.getUsername();
            }
        }

        String ipAddress = getClientIp(request);

        AuditLog auditLog = new AuditLog(
                actorUserId,
                actorIdentifier,
                action,
                entityType,
                entityId,
                description,
                ipAddress
        );

        return auditLogDAO.insert(auditLog);
    }

    public boolean log(String actorIdentifier,
            String action,
            String entityType,
            Long entityId,
            String description,
            HttpServletRequest request) {

        String ipAddress = getClientIp(request);

        AuditLog auditLog = new AuditLog(
                null,
                actorIdentifier,
                action,
                entityType,
                entityId,
                description,
                ipAddress
        );

        return auditLogDAO.insert(auditLog);
    }

    private String getClientIp(HttpServletRequest request) {

        if (request == null) {
            return null;
        }

        String ip = request.getHeader("X-Forwarded-For");

        if (ip == null || ip.isEmpty()) {
            ip = request.getRemoteAddr();
        }

        return ip;
    }
}
