package service;

import dao.ReturnExchangeDAO;

import java.sql.SQLException;
import java.util.List;
import java.util.Map;

public class ReturnExchangeService {

    private final ReturnExchangeDAO returnExchangeDAO;

    public ReturnExchangeService() {
        this.returnExchangeDAO = new ReturnExchangeDAO();
    }

    public ReturnExchangeService(
            ReturnExchangeDAO returnExchangeDAO) {

        if (returnExchangeDAO == null) {
            throw new IllegalArgumentException(
                    "ReturnExchangeDAO không được null.");
        }

        this.returnExchangeDAO = returnExchangeDAO;
    }

    public boolean canRequest(
            int orderId,
            int userId) throws SQLException {

        if (orderId <= 0 || userId <= 0) {
            return false;
        }

        return returnExchangeDAO.canRequest(orderId, userId);
    }

    public List<Map<String, Object>> getOrderItems(
            int orderId,
            int userId) throws SQLException {

        if (!canRequest(orderId, userId)) {
            throw new IllegalArgumentException(
                    "Đơn hàng không đủ điều kiện trả hàng "
                    + "hoặc đã quá hạn 7 ngày.");
        }

        return returnExchangeDAO.getOrderItems(
                orderId,
                userId
        );
    }

    public int createRequest(
            int orderId,
            int userId,
            String requestType,
            String reason,
            List<Map<String, Integer>> items)
            throws SQLException {

        if (!"RETURN".equals(requestType)) {
            throw new IllegalArgumentException(
                    "Hệ thống chỉ hỗ trợ yêu cầu trả hàng.");
        }

        if (!canRequest(orderId, userId)) {
            throw new IllegalArgumentException(
                    "Đơn hàng không đủ điều kiện trả hàng "
                    + "hoặc đã quá hạn 7 ngày.");
        }

        if (reason == null || reason.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "Vui lòng nhập lý do trả hàng.");
        }

        String normalizedReason = reason.trim();

        if (normalizedReason.length() > 1000) {
            throw new IllegalArgumentException(
                    "Lý do trả hàng không được vượt quá "
                    + "1000 ký tự.");
        }

        if (items == null || items.isEmpty()) {
            throw new IllegalArgumentException(
                    "Vui lòng chọn ít nhất một sản phẩm "
                    + "muốn trả.");
        }

        for (Map<String, Integer> item : items) {

            if (item == null
                    || item.get("orderItemId") == null
                    || item.get("quantity") == null) {

                throw new IllegalArgumentException(
                        "Thông tin sản phẩm trả hàng "
                        + "không hợp lệ.");
            }

            int orderItemId = item.get("orderItemId");
            int quantity = item.get("quantity");

            if (orderItemId <= 0) {
                throw new IllegalArgumentException(
                        "Mã sản phẩm trong đơn hàng "
                        + "không hợp lệ.");
            }

            if (quantity <= 0) {
                throw new IllegalArgumentException(
                        "Số lượng trả hàng phải lớn hơn 0.");
            }
        }

        return returnExchangeDAO.createRequest(
                orderId,
                userId,
                "RETURN",
                normalizedReason,
                items
        );
    }

    public List<Map<String, Object>> getAllRequests()
            throws SQLException {

        return returnExchangeDAO.getAllRequests();
    }

    public List<Map<String, Object>> getRequestItems(
            int requestId) throws SQLException {

        if (requestId <= 0) {
            throw new IllegalArgumentException(
                    "Mã yêu cầu trả hàng không hợp lệ.");
        }

        return returnExchangeDAO.getRequestItems(requestId);
    }

    public boolean reviewRequest(
            int requestId,
            int staffId,
            String newStatus,
            String staffNote) throws SQLException {

        if (requestId <= 0 || staffId <= 0) {
            throw new IllegalArgumentException(
                    "Mã yêu cầu hoặc mã nhân viên "
                    + "không hợp lệ.");
        }

        if (!"APPROVED".equals(newStatus)
                && !"REJECTED".equals(newStatus)) {

            throw new IllegalArgumentException(
                    "Trạng thái xử lý trả hàng "
                    + "không hợp lệ.");
        }

        String normalizedNote
                = staffNote == null ? "" : staffNote.trim();

        if (normalizedNote.length() > 1000) {
            throw new IllegalArgumentException(
                    "Ghi chú không được vượt quá "
                    + "1000 ký tự.");
        }

        if ("REJECTED".equals(newStatus)
                && normalizedNote.isEmpty()) {

            throw new IllegalArgumentException(
                    "Vui lòng nhập lý do từ chối "
                    + "yêu cầu trả hàng.");
        }

        return returnExchangeDAO.reviewRequest(
                requestId,
                staffId,
                newStatus,
                normalizedNote
        );
    }
}
