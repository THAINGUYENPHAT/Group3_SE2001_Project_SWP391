<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .order-page {
        width: 100%;
        padding-top: 5px;
    }

    .order-page-heading {
        display: flex;
        align-items: flex-end;
        justify-content: space-between;
        margin-bottom: 24px;
    }

    .heading-title-order h1 {
        margin: 0;
        font-size: 32px;
        line-height: 1.1;
        font-weight: 800;
        letter-spacing: -.6px;
        color: #0f172a;
    }

    .heading-title-order p {
        margin: 8px 0 0;
        color: #64748b;
        font-size: 15px;
    }

    .order-badge-page {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 10px 16px;
        border-radius: 10px;
        background: #eaf3ff;
        color: #1677ff;
        font-size: 13px;
        font-weight: 700;
    }

    .order-card {
        background: white;
        border: 1px solid #e1e8f0;
        border-radius: 14px;
        box-shadow: 0 6px 22px rgba(15, 23, 42, .05);
        overflow: hidden;
    }

    .order-card-header {
        min-height: 76px;
        padding: 0 25px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        border-bottom: 1px solid #e8edf3;
    }

    .order-card-title {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .order-card-icon {
        width: 38px;
        height: 38px;
        border-radius: 10px;
        background: #edf5ff;
        color: #1677ff;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 18px;
    }

    .order-card-title h2 {
        margin: 0;
        font-size: 19px;
        font-weight: 700;
        color: #0f172a;
    }

    .order-card-subtitle {
        color: #94a3b8;
        font-size: 13px;
    }

    .order-table-container {
        width: 100%;
        overflow-x: auto;
    }

    .order-table {
        width: 100%;
        min-width: 1200px;
        border-collapse: separate;
        border-spacing: 0;
        table-layout: fixed;
    }

    .order-table thead {
        background: #f8fafc;
    }

    .order-table th {
        height: 52px;
        padding: 0 12px;
        box-sizing: border-box;
        text-align: left;
        color: #64748b;
        font-size: 12px;
        font-weight: 700;
        letter-spacing: .35px;
        text-transform: uppercase;
        border-bottom: 1px solid #e2e8f0;
        white-space: nowrap;
    }

    .order-table td {
        height: 72px;
        padding: 0 12px;
        box-sizing: border-box;
        border-bottom: 1px solid #edf1f5;
        color: #334155;
        font-size: 14px;
        vertical-align: middle;
    }

    .order-table tbody tr {
        transition: background .15s ease;
    }

    .order-table tbody tr:hover {
        background: #f8fbff;
    }

    .order-table tbody tr:last-child td {
        border-bottom: none;
    }

    .order-table th:nth-child(1), .order-table td:nth-child(1) {
        width: 7%;
    }
    .order-table th:nth-child(2), .order-table td:nth-child(2) {
        width: 6%;
    }
    .order-table th:nth-child(3), .order-table td:nth-child(3) {
        width: 15%;
    }
    .order-table th:nth-child(4), .order-table td:nth-child(4) {
        width: 13%;
    }
    .order-table th:nth-child(5), .order-table td:nth-child(5) {
        width: 11%;
    }
    .order-table th:nth-child(6), .order-table td:nth-child(6) {
        width: 12%;
    }
    .order-table th:nth-child(7), .order-table td:nth-child(7) {
        width: 11%;
    }
    .order-table th:nth-child(8), .order-table td:nth-child(8) {
        width: 13%;
    }
    .order-table th:nth-child(9), .order-table td:nth-child(9) {
        width: 12%;
    }

    /* Giữ cột thao tác bên phải khi bảng cần cuộn ngang. */
    .order-table th:nth-child(9),
    .order-table td:nth-child(9) {
        position: sticky;
        right: 0;
        z-index: 1;
        text-align: center;
        background: #fff;
        box-shadow: -1px 0 0 #e2e8f0;
    }

    .order-table th:nth-child(9) {
        background: #f8fafc;
        z-index: 2;
    }

    .order-table tbody tr:hover td:nth-child(9) {
        background: #f8fbff;
    }

    .order-id-cell .payment-badge-order {
        display: block;
        margin-top: 4px;
        padding: 3px 4px;
        white-space: normal;
        overflow-wrap: break-word;
        font-size: 10px;
    }

    .order-id-cell {
        color: #1677ff;
        font-size: 15px;
        font-weight: 800;
    }

    .user-id-cell {
        font-weight: 600;
        color: #475569;
    }

    .recipient-cell {
        font-weight: 600;
        color: #1e293b;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .muted-order {
        color: #94a3b8;
        font-weight: 400;
        font-size: 13px;
    }

    .amount-cell {
        font-weight: 800;
        color: #0f172a;
        white-space: nowrap;
    }

    .shipping-cell {
        color: #475569;
        white-space: nowrap;
    }

    .date-cell {
        color: #64748b;
        white-space: nowrap;
        font-size: 13px;
    }

    .payment-badge-order {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 7px 11px;
        border-radius: 8px;
        background: #f1f5f9;
        color: #475569;
        font-size: 12px;
        font-weight: 700;
        white-space: normal;
        max-width: 100%;
        box-sizing: border-box;
    }

    .payment-badge-order.is-paid {
        background: #ecfdf3;
        color: #15803d;
    }
    .payment-badge-order.is-unpaid {
        background: #f1f5f9;
        color: #475569;
    }
    .payment-badge-order.is-pending {
        background: #fffbeb;
        color: #92400e;
    }
    .payment-badge-order.is-failed {
        background: #fef2f2;
        color: #b91c1c;
    }
    .payment-badge-order.is-closed {
        background: #f1f5f9;
        color: #64748b;
    }

    .payment-review-order {
        display: block;
        margin-top: 4px;
        color: #92400e;
        font-size: 11px;
        font-weight: 600;
    }

    .payment-dot-order {
        width: 6px;
        height: 6px;
        border-radius: 50%;
        background: currentColor;
        flex-shrink: 0;
    }

    .payment-empty-order {
        display: inline-flex;
        padding: 7px 11px;
        border-radius: 8px;
        background: #f1f5f9;
        color: #64748b;
        font-size: 12px;
        font-weight: 600;
        white-space: nowrap;
    }

    .detail-btn-order {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
        box-sizing: border-box;
        min-width: 112px;
        height: 38px;
        padding: 0 13px;
        border-radius: 9px;
        background: #1677ff;
        color: white;
        text-decoration: none;
        font-size: 12px;
        font-weight: 700;
        white-space: nowrap;
        transition: all .15s ease;
    }

    .detail-btn-order:hover {
        background: #0969e8;
        color: white;
        box-shadow: 0 5px 13px rgba(22, 119, 255, .22);
        transform: translateY(-1px);
    }

    .empty-order-row td {
        height: 180px;
        text-align: center;
        color: #94a3b8;
    }

    .empty-order-icon {
        width: 48px;
        height: 48px;
        margin: 0 auto 10px;
        border-radius: 13px;
        background: #f1f5f9;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 21px;
    }

    @media (max-width: 1250px) {
        .heading-title-order h1 {
            font-size: 28px;
        }
        .order-page-heading {
            align-items: flex-start;
            gap: 15px;
        }
        .order-card-subtitle {
            display: none;
        }
        .order-table th, .order-table td {
            padding-left: 12px;
            padding-right: 12px;
        }
        .date-cell {
            font-size: 12px;
        }
        .detail-btn-order {
            min-width: 100px;
            padding: 0 9px;
        }
    }

    @media (max-width: 800px) {
        .order-page-heading {
            flex-direction: column;
        }
        .order-badge-page {
            align-self: flex-start;
        }

    }

    /* Tìm kiếm và lọc đơn hàng */
    .order-filter {
        display: flex;
        flex-wrap: wrap;
        gap: 12px;
        padding: 16px 25px;
        border-bottom: 1px solid #e8edf3;
    }

    .order-filter input, .order-filter select {
        box-sizing: border-box;
        min-height: 40px;
        padding: 8px 12px;
        border: 1px solid #dbe3ec;
        border-radius: 8px;
        background: #fff;
        color: #334155;
        font-size: 14px;
    }

    .order-filter input {
        flex: 1 1 260px;
        min-width: 0;
    }

    .order-table tr[hidden] {
        display: none;
    }

</style>

<div class="order-page">

    <div class="order-page-heading">
        <div class="heading-title-order">
            <h1>Order Management</h1>
            <p>Quản lý danh sách và trạng thái đơn hàng</p>
        </div>

        <div class="order-badge-page">
            🛒 Đơn hàng
        </div>
    </div>

    <div class="order-card">

        <div class="order-card-header">
            <div class="order-card-title">
                <div class="order-card-icon">🛒</div>
                <h2>Danh sách đơn hàng</h2>
            </div>

            <div class="order-card-subtitle">
                Theo dõi và quản lý đơn hàng
            </div>
        </div>

        <div class="order-filter">
            <input type="search" id="orderSearch"
                   aria-label="Tìm kiếm đơn hàng"
                   placeholder="Tìm mã đơn, tên người nhận..."
                   oninput="filterOrders()">

            <select id="orderStatusFilter"
                    onchange="filterOrders()">

                <option value="">Tất cả trạng thái</option>
                <option value="PENDING_CONFIRMATION">Chờ xác nhận</option>
                <option value="CONFIRMED">Đã xác nhận</option>
                <option value="PACKING">Đang đóng gói</option>
                <option value="SHIPPING">Đang giao hàng</option>
                <option value="COMPLETED">Hoàn tất</option>
                <option value="CANCELLED">Đã hủy</option>

            </select>
        </div>

        <div class="order-table-container">
            <table class="order-table">
                <thead>
                    <tr>
                        <th>Order ID</th>
                        <th>User ID</th>
                        <th>Người nhận</th>
                        <th>Tổng tiền</th>
                        <th>Phí giao hàng</th>
                        <th>Trạng thái</th>
                        <th>Thanh toán</th>
                        <th>Ngày tạo</th>
                        <th>Thao tác</th>
                    </tr>
                </thead>

                <tbody>
                    <c:choose>
                        <c:when test="${not empty orders}">
                            <c:forEach var="order" items="${orders}">
                                <tr class="order-row"
                                    data-order-id="${order.orderId}"
                                    data-recipient="<c:out value='${order.recipientName}'/>"
                                    data-status="<c:out value='${order.orderStatus}'/>">
                                    <td class="order-id-cell">
                                        #${order.orderId}
                                        <c:if test="${order.cancelRequestStatus eq 'PENDING'}">
                                            <span class="payment-badge-order is-pending">Chờ duyệt hủy</span>
                                        </c:if>
                                    </td>

                                    <td class="user-id-cell">
                                        ${order.userId}
                                    </td>

                                    <td class="recipient-cell">
                                        <c:choose>
                                            <c:when test="${not empty order.recipientName}">
                                                <c:out value="${order.recipientName}" />
                                            </c:when>
                                            <c:otherwise>
                                                <span class="muted-order">Chưa cập nhật</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>

                                    <td class="amount-cell">
                                        <fmt:formatNumber value="${order.totalAmount}" type="number" groupingUsed="true" maxFractionDigits="0"/> ₫
                                    </td>

                                    <td class="shipping-cell">
                                        <fmt:formatNumber value="${order.shippingFee}" type="number" groupingUsed="true" maxFractionDigits="0"/> ₫
                                    </td>

                                    <td><c:out value="${statusLabels[order.orderStatus]}" default="${order.orderStatus}" /></td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${order.paymentStatus eq 'PAID'}">
                                                <span class="payment-badge-order is-paid"><span class="payment-dot-order"></span>Đã thanh toán</span>
                                                <c:if test="${(order.orderStatus eq 'CANCELLED' or order.orderStatus eq 'EXPIRED') and order.totalAmount gt 0}">
                                                    <span class="payment-review-order">Cần đối soát</span>
                                                </c:if>
                                            </c:when>
                                            <c:when test="${order.paymentStatus eq 'UNPAID'}">
                                                <span class="payment-badge-order is-unpaid"><span class="payment-dot-order"></span>Chưa thanh toán</span>
                                            </c:when>
                                            <c:when test="${order.paymentStatus eq 'PENDING'}">
                                                <span class="payment-badge-order is-pending"><span class="payment-dot-order"></span>Chờ thanh toán</span>
                                            </c:when>
                                            <c:when test="${order.paymentStatus eq 'FAILED'}">
                                                <span class="payment-badge-order is-failed"><span class="payment-dot-order"></span>Thất bại</span>
                                            </c:when>
                                            <c:when test="${order.paymentStatus eq 'CANCELLED'}">
                                                <span class="payment-badge-order is-closed"><span class="payment-dot-order"></span>Đã hủy thanh toán</span>
                                            </c:when>
                                            <c:when test="${order.paymentStatus eq 'EXPIRED'}">
                                                <span class="payment-badge-order is-closed"><span class="payment-dot-order"></span>Hết hạn</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="payment-empty-order"><c:out value="${order.paymentStatus}" default="Chưa cập nhật" /></span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>

                                    <td class="date-cell">
                                        <fmt:formatDate value="${order.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
                                    </td>

                                    <td>
                                        <a class="detail-btn-order" href="${pageContext.request.contextPath}/admin/orders/detail?id=${order.orderId}">
                                            Xem chi tiết →
                                        </a>
                                    </td>
                                </tr>
                            </c:forEach>
                            <tr id="orderNoResults" class="empty-order-row" hidden>
                                <td colspan="9">Không tìm thấy đơn hàng phù hợp.</td>
                            </tr>
                        </c:when>

                        <c:otherwise>
                            <tr class="empty-order-row">
                                <td colspan="9">
                                    <div class="empty-order-icon">📦</div>
                                    Không có đơn hàng nào.
                                </td>
                            </tr>
                        </c:otherwise>
                    </c:choose>
                </tbody>
            </table>
        </div>

    </div>

</div>

<script>
    function filterOrders() {
        const keyword = document.getElementById('orderSearch').value.trim().toLowerCase();
        const status = document.getElementById('orderStatusFilter').value;
        const rows = document.querySelectorAll('.order-table tbody .order-row');
        let visibleCount = 0;

        rows.forEach(function (row) {
            const orderId = row.dataset.orderId;
            const name = row.dataset.recipient.toLowerCase();

            const matchKeyword = ('#' + orderId).includes(keyword)
                    || name.includes(keyword);
            const matchStatus = status === '' || row.dataset.status === status;

            row.hidden = !(matchKeyword && matchStatus);
            if (!row.hidden) {
                visibleCount++;
            }
        });

        const emptyRow = document.getElementById('orderNoResults');
        if (emptyRow) {
            emptyRow.hidden = visibleCount > 0;
        }
    }
</script>

<%@include file="/WEB-INF/include/footer.jsp" %>