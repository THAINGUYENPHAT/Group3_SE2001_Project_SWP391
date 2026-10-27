package dao;

import db.DBContext;
import model.AuditLog;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AuditLogDAO extends DBContext {

    // Ghi một audit log mới
    public boolean insert(AuditLog log) {

        String sql = "INSERT INTO AUDIT_LOG"
                + "(actor_user_id, "
                + "actor_identifier,"
                + "action,"
                + "entity_type, "
                + "entity_id,"
                + "description,"
                + "ip_address)"
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            if (log.getActorUserId() != null) {
                ps.setInt(1, log.getActorUserId());
            } else {
                ps.setNull(1, Types.INTEGER);
            }

            ps.setString(2, log.getActorIdentifier());
            ps.setString(3, log.getAction());
            ps.setString(4, log.getEntityType());

            if (log.getEntityId() != null) {
                ps.setLong(5, log.getEntityId());
            } else {
                ps.setNull(5, Types.BIGINT);
            }

            ps.setString(6, log.getDescription());
            ps.setString(7, log.getIpAddress());

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    // Lấy toàn bộ audit log, log mới nhất trước
    public List<AuditLog> getAll() {

        List<AuditLog> logs = new ArrayList<>();

        String sql = "SELECT "
                + "log_id, "
                + "actor_user_id, "
                + "actor_identifier, "
                + "action, "
                + "entity_type, "
                + "entity_id, "
                + "description, "
                + "ip_address, "
                + "created_at "
                + "FROM AUDIT_LOG "
                + "ORDER BY created_at DESC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                AuditLog log = new AuditLog();

                log.setLogId(rs.getLong("log_id"));

                int actorUserId = rs.getInt("actor_user_id");
                if (!rs.wasNull()) {
                    log.setActorUserId(actorUserId);
                }

                log.setActorIdentifier(
                        rs.getString("actor_identifier"));

                log.setAction(
                        rs.getString("action"));

                log.setEntityType(
                        rs.getString("entity_type"));

                long entityId = rs.getLong("entity_id");
                if (!rs.wasNull()) {
                    log.setEntityId(entityId);
                }

                log.setDescription(
                        rs.getString("description"));

                log.setIpAddress(
                        rs.getString("ip_address"));

                log.setCreatedAt(
                        rs.getTimestamp("created_at"));

                logs.add(log);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return logs;
    }

    public List<AuditLog> search(
            String keyword,
            String action,
            String entityType) {

        List<AuditLog> logs = new ArrayList<>();

        String sql = "SELECT log_id, actor_user_id, actor_identifier, action, "
                + "entity_type, entity_id, description, ip_address, created_at "
                + "FROM AUDIT_LOG "
                + "WHERE (? IS NULL OR actor_identifier LIKE ? "
                + "OR description LIKE ?) "
                + "AND (? IS NULL OR action = ?) "
                + "AND (? IS NULL OR entity_type = ?) "
                + "ORDER BY created_at DESC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            String searchKeyword = null;

            if (keyword != null && !keyword.trim().isEmpty()) {
                searchKeyword = "%" + keyword.trim() + "%";
            }

            String actionValue
                    = action == null || action.trim().isEmpty()
                    ? null
                    : action.trim();

            String entityValue
                    = entityType == null || entityType.trim().isEmpty()
                    ? null
                    : entityType.trim();

            ps.setString(1, searchKeyword);
            ps.setString(2, searchKeyword);
            ps.setString(3, searchKeyword);

            ps.setString(4, actionValue);
            ps.setString(5, actionValue);

            ps.setString(6, entityValue);
            ps.setString(7, entityValue);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    AuditLog log = new AuditLog();

                    log.setLogId(rs.getLong("log_id"));

                    int actorUserId
                            = rs.getInt("actor_user_id");

                    if (!rs.wasNull()) {
                        log.setActorUserId(actorUserId);
                    }

                    log.setActorIdentifier(
                            rs.getString("actor_identifier"));

                    log.setAction(
                            rs.getString("action"));

                    log.setEntityType(
                            rs.getString("entity_type"));

                    long entityId
                            = rs.getLong("entity_id");

                    if (!rs.wasNull()) {
                        log.setEntityId(entityId);
                    }

                    log.setDescription(
                            rs.getString("description"));

                    log.setIpAddress(
                            rs.getString("ip_address"));

                    log.setCreatedAt(
                            rs.getTimestamp("created_at"));

                    logs.add(log);
                }

            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return logs;
    }
}
