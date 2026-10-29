
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

    public ReturnExchangeService(ReturnExchangeDAO returnExchangeDAO) {
        this.returnExchangeDAO = returnExchangeDAO;
    }

    public boolean canRequest(int orderId, int userId) throws SQLException {
        return returnExchangeDAO.canRequest(orderId, userId);
    }

    public List<Map<String, Object>> getOrderItems(
            int orderId, int userId) throws SQLException {

        if (!canRequest(orderId, userId)) {
            throw new IllegalArgumentException(
                    "Đơn hàng không đủ điều kiện đổi/trả hoặc đã quá hạn 7 ngày.");
        }

        return returnExchangeDAO.getOrderItems(orderId, userId);
    }

    public List<Map<String, Object>> getExchangeSkus(
            int orderId, int orderItemId, int userId) throws SQLException {

        if (!canRequest(orderId, userId)) {
            throw new IllegalArgumentException(
                    "Đơn hàng không đủ điều kiện đổi/trả hoặc đã quá hạn 7 ngày.");
        }

        List<Map<String, Object>> orderItems =
                returnExchangeDAO.getOrderItems(orderId, userId);

        boolean itemBelongsToOrder = false;

        for (Map<String, Object> item : orderItems) {
            int currentOrderItemId = (Integer) item.get("orderItemId");

            if (currentOrderItemId == orderItemId) {
                itemBelongsToOrder = true;
                break;
            }
        }

        if (!itemBelongsToOrder) {
            throw new IllegalArgumentException(
                    "Sản phẩm không thuộc đơn hàng này.");
        }

        return returnExchangeDAO.getExchangeSkus(orderItemId, userId);
    }

    public int createRequest(
            int orderId,
            int userId,
            String requestType,
            String reason,
            List<Map<String, Integer>> items) throws SQLException {

        if (!canRequest(orderId, userId)) {
            throw new IllegalArgumentException(
                    "Đơn hàng không đủ điều kiện đổi/trả hoặc đã quá hạn 7 ngày.");
        }

        if (requestType == null
                || (!requestType.equals("RETURN")
                && !requestType.equals("EXCHANGE"))) {
            throw new IllegalArgumentException(
                    "Loại yêu cầu không hợp lệ.");
        }

        if (reason == null || reason.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "Vui lòng nhập lý do đổi/trả hàng.");
        }

        if (items == null || items.isEmpty()) {
            throw new IllegalArgumentException(
                    "Vui lòng chọn ít nhất một sản phẩm.");
        }

        return returnExchangeDAO.createRequest(
                orderId,
                userId,
                requestType,
                reason.trim(),
                items
        );
    }
    
    
    public List<Map<String, Object>> getAllRequests() throws SQLException {
        return returnExchangeDAO.getAllRequests();
    }

    public List<Map<String, Object>> getRequestItems(int requestId) throws SQLException {
        if (requestId <= 0) {
            throw new IllegalArgumentException("Mã yêu cầu không hợp lệ.");
        }

        return returnExchangeDAO.getRequestItems(requestId);
    }

    public boolean reviewRequest(
            int requestId,
            int staffId,
            String newStatus,
            String staffNote) throws SQLException {

        if (requestId <= 0 || staffId <= 0) {
            throw new IllegalArgumentException("Mã yêu cầu hoặc mã nhân viên không hợp lệ.");
        }

        if (!"APPROVED".equals(newStatus)
                && !"REJECTED".equals(newStatus)) {
            throw new IllegalArgumentException("Trạng thái xử lý không hợp lệ.");
        }

        return returnExchangeDAO.reviewRequest(
                requestId, staffId, newStatus, staffNote);
    }

}
