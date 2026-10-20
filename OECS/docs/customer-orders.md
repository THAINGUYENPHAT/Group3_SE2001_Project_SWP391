# Hoàn thiện checkout và đơn hàng khách hàng

Phạm vi nhánh `feature/hoanthien`: phần checkout/đơn hàng của khách. Chưa làm thanh toán online, API vận chuyển, phí ship hoặc freeship theo yêu cầu. Không sửa quản trị, thông báo, `DBContext`, `pom.xml` hay script tạo database chung. Header dùng chung chỉ thêm mục “Đơn mua” cho Customer trong menu tài khoản, đã được người dùng đồng ý.

## Chức năng

- `/my-orders`: trang Đơn mua dạng thẻ sản phẩm, mới nhất trước; 10 đơn/trang. Các tab: Tất cả, Chờ xác nhận, Chờ lấy hàng (CONFIRMED/PACKING), Đang giao, Hoàn thành (DELIVERED/COMPLETED), Đã hủy. Tìm theo mã đơn (có thể thêm #), tên sản phẩm hoặc SKU. Truy vấn lọc, đếm và phân trang đều giới hạn theo tài khoản đăng nhập.
- `/my-orders?status=COMPLETED`: lối vào “Lịch sử mua hàng” để xem đơn đã giao/hoàn thành. Tất cả các đơn khác vẫn xem được ở tab tương ứng hoặc Tất cả.
- `/my-orders/detail?id=...`: địa chỉ và đơn giá đã lưu khi mua, chi tiết tiền, thanh tiến trình năm bước và lịch sử mới nhất trước. Chỉ hiển thị thời gian đã có trong dữ liệu; đơn hủy không hiển thị thanh giao thành công. Nút Cập nhật tải lại trạng thái từ hệ thống; chưa theo dõi qua hãng vận chuyển.
- `/my-orders/cancel`: chỉ nhận POST có CSRF token. Kiểm tra chủ đơn và chỉ hủy COD đang chờ xác nhận. Đơn có khoản tiền đã thanh toán cần xử lý riêng, không tự hủy/hoàn tiền ở luồng này.
- Hủy đơn khóa bản ghi đơn, cộng lại tồn kho, đặt `stock_restored_at`, ghi lịch sử và commit cùng transaction. Request hủy lặp không cộng kho thêm. Lỗi ở bất kỳ bước nào rollback toàn bộ.
- Voucher đã dùng vẫn giữ lịch sử và lượt dùng sau khi khách hủy; không tự thay đổi chính sách voucher của nhóm.
- Chọn địa chỉ lưu vào `ADDRESSBOOK.is_default`. Đăng nhập phiên mới lấy lại địa chỉ mặc định; các yêu cầu chọn đồng thời được tuần tự hóa theo tài khoản.
- Đăng nhập Customer → bấm tên/avatar tài khoản ở header → Đơn mua → Theo dõi đơn hàng/Xem chi tiết. Checkout vẫn có đường dẫn “Đơn hàng của tôi”. Hai nút trên trang đặt thành công vẫn được bỏ theo yêu cầu.

## Tổ chức code

- `OrderDAO`: đọc đơn, sản phẩm và lịch sử theo chủ đơn; ghi đơn và lịch sử trong transaction.
- `OrderService`: đặt COD, khách hủy/hoàn kho và chuyển trạng thái sang nhãn hiển thị.
- `CustomerOrderServlet`: nhận request danh sách/chi tiết/hủy, kiểm tra đăng nhập và CSRF, trả JSP hoặc redirect.
- `customer-orders/list.jsp`, `detail.jsp` và `assets/css/customer-orders.css`: giao diện Đơn mua/lịch sử và theo dõi, có bố cục desktop/điện thoại; CSS chỉ tác động phần đơn mua. Không thêm class Java cho thay đổi giao diện này.
- `CheckoutConnectionFactory`: interface nhỏ để mỗi thao tác mở connection riêng và kiểm thử được trên database tạm.

Đã gộp `CustomerOrderDAO`, `CustomerOrderService`, `CustomerOrderStatus` vào hai lớp đơn hàng có sẵn; không còn ba file riêng này.

Không cần migration mới nếu database đang có đúng schema trong `DB_OECS.sql` (đặc biệt `checkout_token`, index `UX_Order_CheckoutToken`, `stock_restored_at`, `is_deleted`, `is_default`). **Không chạy lại toàn bộ `DB_OECS.sql` trên dữ liệu hiện có**: script gốc có lệnh xóa và tạo lại database.

## Kiểm tra đã thực hiện

- Maven build/package thành công.
- Tomcat Jasper biên dịch bốn JSP liên quan: không lỗi.
- 66 kiểm tra tích hợp trên SQL Server bằng database tạm, lấy định nghĩa các bảng liên quan từ schema của dự án. Database tạm được xóa sau kiểm tra; dữ liệu OECS không bị sửa.
- Bao gồm đặt cùng token đồng thời, replay sau khi giỏ trống, voucher chỉ dùng một lần, không đủ tồn kho, địa chỉ sai chủ, snapshot giá/địa chỉ, quyền đọc đơn/chi tiết/lịch sử, hai lần hủy đồng thời, rollback đặt/hủy khi ghi lịch sử lỗi, chặn hủy sau xác nhận và kiểm tra CSRF/phân quyền tại servlet.
- Bổ sung kiểm tra gom trạng thái cũ/mới, tìm kiếm Unicode/ký tự đặc biệt/SQL injection, phân trang không trùng/bỏ sót, đọc sản phẩm hàng loạt đúng chủ đơn và tiến trình không bịa mốc thời gian hay coi đơn hủy là giao thành công.
- Đã mở JSP thực trên Tomcat tạm bằng dữ liệu mẫu, kiểm tra menu tài khoản, danh sách, tab hoàn thành/đã hủy, tìm kiếm không có kết quả và chi tiết theo dõi ở desktop 1280px và điện thoại 390px. Preview không dùng dữ liệu đơn hàng OECS thật.

Chạy lại từ thư mục repository (cần SQL Server local và quyền tạo database kiểm thử):

```powershell
./OECS/scripts/check-checkout.ps1 -Maven 'C:/Program Files/NetBeans-25/netbeans/java/maven/bin/mvn.cmd'
```

Script dùng Maven offline, sau đó chạy `CheckoutIntegrationChecks` trực tiếp; đây không phải các test được Maven Surefire tự phát hiện. Có thể truyền đường dẫn Maven khác qua `-Maven`.

## Điểm tích hợp cần người phụ trách quản trị xử lý

`AdminOrderDAO.updateStatus` hiện UPDATE chỉ theo `order_id`; việc kiểm tra trạng thái ở `AdminOrderServlet` diễn ra trước transaction cập nhật. Nếu nhân viên đã đọc trạng thái chờ, khách hủy xong rồi nhân viên ghi lại, phía quản trị có thể ghi đè `CANCELLED` thành `CONFIRMED` trong khi kho đã hoàn. Luồng khách tự nó đã chống hoàn kho lặp, nhưng chưa thể bảo đảm toàn bộ cuộc đua với code quản trị hiện có.

Chưa sửa file này vì giới hạn không chạm phần người khác. Người phụ trách cần cập nhật trạng thái có điều kiện ngay trong SQL, ít nhất chặn cập nhật đơn `CANCELLED`/đã hoàn kho và kiểm tra đúng trạng thái nguồn khi xác nhận. Kết quả 66 kiểm tra ở trên không bao gồm bảo đảm cho luồng quản trị này. Việc nhân viên hủy đơn và thông báo cũng giữ nguyên hành vi hiện tại.

## Kiểm tra giao diện khi chạy ứng dụng

1. Đăng nhập Customer, bấm tên/avatar góc phải → Đơn mua. Chọn tab, tìm mã đơn hoặc sản phẩm; bấm “Theo dõi đơn hàng”/“Xem chi tiết”.
2. Kiểm tra địa chỉ, đơn giá đã đặt, tổng tiền và lịch sử; mở “Đơn hàng của tôi”.
3. Hủy một đơn đang chờ và tải lại: chỉ có một mốc hủy, tồn kho chỉ tăng một lần.
4. Thử đơn đã xác nhận: không có nút tự hủy.
5. Chọn địa chỉ khác ở checkout, đăng xuất/đăng nhập và quay lại checkout với giỏ có hàng: địa chỉ đã chọn được nhớ.

Khi chạy lại bằng NetBeans, redeploy bản build mới để menu và CSS mới có hiệu lực. Kiểm tra trình duyệt dùng dữ liệu mẫu riêng; nghiệp vụ SQL chạy trên database kiểm thử riêng.
