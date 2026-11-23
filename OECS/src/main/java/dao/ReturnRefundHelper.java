package dao;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public final class ReturnRefundHelper {
    private ReturnRefundHelper() { }

    private static final class Line {
        int id;
        int quantity;
        BigDecimal gross;
        BigDecimal amount;
    }

    public static void createPendingOnlineRefund(Connection conn, int orderId, int requestId)
            throws SQLException {
        String orderSql = "SELECT payment_method, payment_status, discount_amount, total_amount "
                + "FROM dbo.[ORDER] WITH (UPDLOCK,HOLDLOCK) WHERE order_id=?";
        String paymentMethod;
        String paymentStatus;
        BigDecimal discount;
        BigDecimal orderTotal;
        try (PreparedStatement ps = conn.prepareStatement(orderSql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new SQLException("Order not found for return refund.");
                paymentMethod = rs.getString("payment_method");
                paymentStatus = rs.getString("payment_status");
                discount = rs.getBigDecimal("discount_amount");
                orderTotal = rs.getBigDecimal("total_amount");
            }
        }
        if ("COD".equalsIgnoreCase(paymentMethod) || orderTotal.signum() == 0) {
            // No cash-refund transaction model is available in this DB.
            return;
        }
        if (!"PAID".equals(paymentStatus)) {
            throw new SQLException("Chỉ tạo yêu cầu hoàn tiền online cho đơn đã thanh toán.");
        }
        long transactionId;
        BigDecimal paid;
        String paySql = "SELECT TOP 1 transaction_id, amount FROM dbo.PAYMENT_TRANSACTION "
                + "WITH (UPDLOCK,HOLDLOCK) WHERE order_id=? AND status='SUCCESS' "
                + "ORDER BY transaction_id DESC";
        try (PreparedStatement ps = conn.prepareStatement(paySql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new SQLException("Không tìm thấy giao dịch online đã thu tiền.");
                transactionId = rs.getLong("transaction_id");
                paid = rs.getBigDecimal("amount");
            }
        }
        BigDecimal subtotal = BigDecimal.ZERO;
        String subtotalSql = "SELECT COALESCE(SUM(price*quantity),0) FROM dbo.ORDER_ITEM WHERE order_id=?";
        try (PreparedStatement ps = conn.prepareStatement(subtotalSql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) subtotal = rs.getBigDecimal(1);
            }
        }
        if (subtotal.signum() <= 0) return;
        BigDecimal ratio = subtotal.subtract(discount == null ? BigDecimal.ZERO : discount)
                .max(BigDecimal.ZERO).divide(subtotal, 12, RoundingMode.HALF_UP);
        List<Line> lines = new ArrayList<>();
        BigDecimal refundTotal = BigDecimal.ZERO;
        String detailSql = "SELECT ri.request_item_id,ri.quantity,oi.price "
                + "FROM dbo.RETURN_REQUEST_ITEM ri "
                + "JOIN dbo.ORDER_ITEM oi ON oi.order_item_id=ri.order_item_id "
                + "WHERE ri.request_id=? AND oi.order_id=? ORDER BY ri.request_item_id";
        try (PreparedStatement ps = conn.prepareStatement(detailSql)) {
            ps.setInt(1, requestId);
            ps.setInt(2, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Line line = new Line();
                    line.id = rs.getInt("request_item_id");
                    line.quantity = rs.getInt("quantity");
                    line.gross = rs.getBigDecimal("price").multiply(BigDecimal.valueOf(line.quantity));
                    line.amount = line.gross.multiply(ratio).setScale(2, RoundingMode.HALF_UP);
                    if (line.amount.signum() > 0) {
                        lines.add(line);
                        refundTotal = refundTotal.add(line.amount);
                    }
                }
            }
        }
        if (refundTotal.signum() == 0) return; // Fully discounted items: no money to refund.
        String bookedSql = "SELECT COALESCE(SUM(refund_amount),0) FROM dbo.PAYMENT_REFUND "
                + "WHERE transaction_id=? AND refund_status IN ('PENDING','PROCESSING','SUCCESS')";
        BigDecimal booked = BigDecimal.ZERO;
        try (PreparedStatement ps = conn.prepareStatement(bookedSql)) {
            ps.setLong(1, transactionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) booked = rs.getBigDecimal(1);
            }
        }
        if (refundTotal.compareTo(paid.subtract(booked)) > 0) {
            throw new SQLException("Số tiền yêu cầu hoàn vượt số đã thu chưa được hoàn.");
        }
        long refundId;
        String refundSql = "INSERT INTO dbo.PAYMENT_REFUND "
                + "(transaction_id,refund_amount,refund_type,reason) VALUES (?,?,'RETURN',?)";
        try (PreparedStatement ps = conn.prepareStatement(refundSql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, transactionId);
            ps.setBigDecimal(2, refundTotal);
            ps.setNString(3, "Hoàn tiền hàng trả theo yêu cầu #" + requestId);
            if (ps.executeUpdate() != 1) throw new SQLException("Không tạo được yêu cầu hoàn tiền.");
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (!keys.next()) throw new SQLException("Không đọc được refund ID.");
                refundId = keys.getLong(1);
            }
        }
        String allocationSql = "INSERT INTO dbo.REFUND_ALLOCATION "
                + "(refund_id,request_item_id,quantity,allocated_amount) VALUES (?,?,?,?)";
        try (PreparedStatement ps = conn.prepareStatement(allocationSql)) {
            for (Line line : lines) {
                ps.setLong(1, refundId);
                ps.setInt(2, line.id);
                ps.setInt(3, line.quantity);
                ps.setBigDecimal(4, line.amount);
                if (ps.executeUpdate() != 1) throw new SQLException("Không tạo được phân bổ hoàn tiền.");
            }
        }
    }
}
