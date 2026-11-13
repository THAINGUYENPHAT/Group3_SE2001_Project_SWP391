# Hủy đơn phía Staff

Không cần tạo bảng hoặc chạy migration mới.

- Staff mở chi tiết đơn, bấm Hủy đơn hàng và xác nhận; không nhập lý do.
- Cho phép PENDING_PAYMENT, PENDING_CONFIRMATION (kể cả PENDING cũ), CONFIRMED và PACKING.
- Chặn SHIPPING, COMPLETED, DELIVERED; đơn CANCELLED không hoàn kho lần nữa.
- Hoàn kho theo SKU, cập nhật trạng thái, lịch sử và khoản chờ hoàn tiền trong cùng transaction.
- Hủy đơn gọi NotificationDAO.createOrderStatusNotification(connection, orderId, "CANCELLED") trong cùng transaction. Dùng chung mẫu SQL, không ghi thông báo riêng ở service. Lỗi thông báo sẽ rollback hủy/hoàn kho/hoàn tiền; không tạo thông báo trùng trong servlet.
- Đơn đã thanh toán online tạo PAYMENT_REFUND chờ đối soát; không coi là đã chuyển tiền.
- Nếu PAID nhưng thiếu giao dịch thành công để hoàn, yêu cầu đối soát trước khi hủy.
- Giữ luồng hủy Customer và hủy online chưa thanh toán như trước thay đổi này.
- Không còn luồng gửi yêu cầu/duyệt/từ chối hủy, nhãn chờ duyệt hoặc phụ thuộc bảng yêu cầu mới.

OrderCancellationService chỉ xử lý Staff hủy trực tiếp. PaymentRefundDAO dùng các bảng thanh toán có sẵn để đồng bộ REFUNDED khi đối soát hoàn tất. Bảng từng tạo thử đã được xóa khỏi máy; code không phụ thuộc bảng đó.

Kiểm tra: scripts/check-checkout.ps1 chạy toàn bộ kiểm tra trên database tạm. Có thể chạy CheckoutIntegrationChecks với tham số --staff-cancel-only sau đường dẫn schema để chỉ kiểm tra phần Staff mới.
