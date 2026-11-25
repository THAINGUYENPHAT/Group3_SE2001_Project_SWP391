<%@page contentType="text/html" pageEncoding="UTF-8" %>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@include file="/WEB-INF/include/header.jsp" %>



<style>
    * {
        box-sizing: border-box;
    }

    html,
    body {
        width: 100%;
        min-height: 100vh;
        margin: 0;
    }

    body {
        font-family: Arial, sans-serif;
        background: #f4f7fb;
        color: #10213b;
        overflow-x: hidden;
        overflow-y: auto;
    }

    .topbar {
        height: 70px;
        background: #0d162b;
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 40px;
        color: white;
    }

    .brand {
        display: flex;
        align-items: center;
        gap: 14px;
    }

    .brand-icon {
        width: 42px;
        height: 42px;
        border-radius: 10px;
        background: #1677ff;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 22px;
        font-weight: bold;
    }

    .brand-name {
        font-size: 23px;
        font-weight: 700;
        letter-spacing: .3px;
    }

    .brand-sub {
        display: block;
        font-size: 12px;
        letter-spacing: 1px;
        color: #9eacc3;
        margin-top: 2px;
    }

    .system-status {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 14px;
    }

    .status-dot {
        width: 9px;
        height: 9px;
        border-radius: 50%;
        background: #20c878;
    }

    .page {
        min-height: calc(100vh - 70px);
        padding: 22px 38px 28px;
        display: flex;
        flex-direction: column;
        gap: 18px;
    }

    .page-title {
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .page-title h1 {
        margin: 0;
        font-size: 28px;
        color: #10213b;
    }

    .page-title p {
        margin: 5px 0 0;
        color: #71819a;
        font-size: 14px;
    }

    .back-btn {
        background: #eaf3ff;
        color: #0878ff;
        text-decoration: none;
        padding: 11px 17px;
        border-radius: 10px;
        font-size: 14px;
        font-weight: 600;
        transition: background 0.2s;
    }

    .back-btn:hover {
        background: #dcecff;
    }

    .main-grid {
        display: grid;
        align-items: start;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 18px;
    }

    .card {
        background: white;
        border: 1px solid #dfe7f1;
        border-radius: 15px;
        box-shadow: 0 5px 18px rgba(27, 61, 99, .06);
        overflow: hidden;
        display: flex;
        flex-direction: column;
    }

    .card-header {
        height: 54px;
        padding: 0 20px;
        border-bottom: 1px solid #e8edf4;
        display: flex;
        align-items: center;
        background: #fafbfc;
    }

    .card-header h2 {
        margin: 0;
        font-size: 17px;
        color: #10213b;
    }

    .card-body {
        padding: 18px;
        flex: 1;
    }

    .info-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 10px;
    }

    .info-item {
        background: #f7f9fc;
        border-radius: 10px;
        padding: 11px 13px;
        min-height: 56px;
    }

    .label {
        display: block;
        color: #8292aa;
        font-size: 10px;
        text-transform: uppercase;
        margin-bottom: 5px;
        letter-spacing: .4px;
    }

    .value {
        display: block;
        font-size: 14px;
        font-weight: 600;
        color: #10213b;
    }

    .order-price-summary {
        padding: 14px 16px;
        border-top: 1px solid #e5eaf1;
    }

    .order-price-row {
        display: flex;
        justify-content: space-between;
        align-items: baseline;
        gap: 12px;
        padding: 6px 0;
        font-size: 13px;
        color: #52647d;
    }

    .order-price-row strong {
        color: #10213b;
        text-align: right;
        white-space: nowrap;
    }

    .order-price-row .discount-value {
        color: #16803d;
    }

    .total-box {
        margin-top: 12px;
        padding: 14px 16px;
        border-radius: 10px;
        background: #edf6ff;
        border: 1px solid #cfe5ff;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .total-label {
        color: #66809e;
        font-size: 13px;
        font-weight: 500;
    }

    .total-value {
        color: #0878ff;
        font-size: 19px;
        font-weight: 700;
    }

    .current-status {
        background: #f5f9ff;
        border: 1px solid #e1ecfa;
        border-radius: 10px;
        padding: 12px 14px;
        margin-bottom: 12px;
    }

    .status-label {
        display: block;
        font-size: 12px;
        color: #71819a;
        margin-bottom: 7px;
    }

    .status-badge {
        display: inline-block;
        padding: 7px 12px;
        border-radius: 8px;
        background: #e7f2ff;
        color: #0878ff;
        font-size: 13px;
        font-weight: 700;
    }

    .action-box {
        background: #f7f9fc;
        border-radius: 10px;
        padding: 12px;
        margin-bottom: 12px;
    }

    .action-box p {
        margin: 0 0 9px;
        color: #71819a;
        font-size: 13px;
    }

    form {
        margin: 0;
    }

    .btn {
        border: none;
        border-radius: 8px;
        padding: 10px 16px;
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
        transition: background 0.2s;
    }

    .btn-primary {
        background: #1677ff;
        color: white;
    }

    .btn-primary:hover {
        background: #0867e8;
    }

    .btn-danger {
        background: #fff1f2;
        color: #e53935;
        border: 1px solid #ffc9cd;
    }

    .btn-danger:hover {
        background: #ffe5e7;
    }

    .status-form {
        display: flex;
        gap: 9px;
        align-items: center;
    }

    select {
        flex: 1;
        height: 38px;
        padding: 0 11px;
        border: 1px solid #d5dfeb;
        border-radius: 8px;
        background: white;
        color: #24364d;
        font-size: 13px;
        outline: none;
    }

    select:focus {
        border-color: #1677ff;
    }

    .cancel-area {
        margin-top: 5px;
    }

    .order-detail-section {
        border-top: 1px solid #e5eaf1;
    }

    .products-body {
        overflow: auto;
        max-height: 320px;
    }

    .products-table {
        min-width: 460px;
        width: 100%;
        border-collapse: collapse;
        font-size: 13px;
    }

    .products-table th {
        height: 38px;
        background: #f7f9fc;
        color: #71819a;
        text-align: left;
        padding: 0 12px;
        font-size: 11px;
        text-transform: uppercase;
        position: sticky;
        top: 0;
        z-index: 1;
        border-bottom: 1px solid #edf1f5;
    }

    .products-table td {
        height: 42px;
        padding: 8px 12px;
        border-bottom: 1px solid #edf1f5;
        color: #26384f;
    }

    .products-table tbody tr:last-child td {
        border-bottom: none;
    }

    .products-table .price {
        text-align: right;
        white-space: nowrap;
    }

    .products-table small,
    .order-history-meta {
        display: block;
        color: #60738e;
        font-size: 12px;
    }

    .order-history {
        list-style: none;
        margin: 0;
        padding: 0 20px;
    }

    .order-history li {
        padding: 12px 0;
        overflow-wrap: anywhere;
    }

    .order-history li + li {
        border-top: 1px solid #edf1f5;
    }

    .order-history p {
        margin: 6px 0 0;
    }


    .empty {
        text-align: center;
        color: #8a98aa;
        padding: 25px !important;
    }

    .price {
        font-weight: 600;
    }

    @media (max-width: 900px) {
        .page {
            padding: 16px;
        }

        .main-grid {
            grid-template-columns: 1fr;
        }
    }

    .success-message,
    .error-message {
        display: flex;
        align-items: center;
        gap: 12px;

        position: fixed;
        top: 90px;
        right: 28px;
        z-index: 9999;

        width: max-content;
        max-width: min(450px, calc(100vw - 32px));
        padding: 16px 20px;

        border-radius: 12px;
        font-size: 14px;
        font-weight: 600;
        line-height: 1.5;

        box-shadow: 0 10px 30px rgba(15, 23, 42, 0.15);

        animation: notification-in 0.3s ease-out;
    }

    .success-message {
        color: #166534;
        background: #f0fdf4;
        border: 1px solid #86efac;
        border-left: 5px solid #22c55e;
    }

    .error-message {
        color: #b91c1c;
        background: #fef2f2;
        border: 1px solid #fca5a5;
        border-left: 5px solid #ef4444;
    }

    .notification-icon {
        flex-shrink: 0;

        display: flex;
        align-items: center;
        justify-content: center;

        width: 32px;
        height: 32px;
        border-radius: 50%;

        font-size: 18px;
        font-weight: 700;
    }

    .success-message .notification-icon {
        background: #dcfce7;
        color: #15803d;
    }

    .error-message .notification-icon {
        background: #fee2e2;
        color: #dc2626;
    }

    @keyframes notification-in {
        from {
            opacity: 0;
            transform: translateX(20px);
        }

        to {
            opacity: 1;
            transform: translateX(0);
        }
    }

    @keyframes notification-out {
        to {
            opacity: 0;
            transform: translateX(20px);
        }
    }

    .notification-hide {
        animation: notification-out 0.25s ease-in forwards;
        pointer-events: none;
    }

    @media (max-width: 600px) {
        .success-message,
        .error-message {
            top: 82px;
            right: 12px;
            max-width: calc(100vw - 24px);
            padding: 12px 14px;
        }
    }

    .success-message {
        color: #166534;
        background: #f0fdf4;
        border: 1px solid #86efac;
        border-left: 5px solid #22c55e;
    }

    .error-message {
        color: #b91c1c;
        background: #fef2f2;
        border: 1px solid #fca5a5;
        border-left: 5px solid #ef4444;
    }

    .notification-icon {
        flex-shrink: 0;
        display: flex;
        align-items: center;
        justify-content: center;

        width: 32px;
        height: 32px;
        border-radius: 50%;

        font-size: 18px;
        font-weight: 700;
    }

    .success-message .notification-icon {
        background: #dcfce7;
        color: #15803d;
    }

    .error-message .notification-icon {
        background: #fee2e2;
        color: #dc2626;
    }

    @keyframes notification-in {
        from {
            opacity: 0;
            transform: translateX(20px);
        }

        to {
            opacity: 1;
            transform: translateX(0);
        }
    }

    @keyframes notification-out {
        to {
            opacity: 0;
            transform: translateX(20px);
        }
    }

    .notification-hide {
        animation: notification-out 0.25s ease-in forwards;
        pointer-events: none;
    }

    @media (max-width: 600px) {

        .success-message,
        .error-message {
            top: 82px;
            right: 12px;
            max-width: calc(100vw - 24px);
            padding: 12px 14px;
        }
    }

    .modal-overlay {
        position: fixed;
        inset: 0;
        z-index: 10000;

        display: none;
        align-items: center;
        justify-content: center;

        padding: 20px;
        background: rgba(15, 23, 42, 0.55);
        backdrop-filter: blur(3px);
        width: 100%;
        height: 100%;
        max-width: none;
        max-height: none;
        margin: 0;
        border: 0;
        box-sizing: border-box;
    }

    .modal-overlay::backdrop {
        background: transparent;
    }

    .modal-box label {
        display: block;
        text-align: left;
    }

    .modal-box textarea {
        display: block;
        width: 100%;
        box-sizing: border-box;
        margin: 6px 0 16px;
        padding: 8px;
        font: inherit;
        resize: vertical;
    }

    .modal-overlay[open] {
        display: flex;
    }

    .modal-box {
        width: 100%;
        max-width: 420px;
        padding: 28px;

        background: #ffffff;
        border: 1px solid #e5eaf1;
        border-radius: 18px;
        box-shadow: 0 24px 60px rgba(15, 23, 42, 0.22);

        text-align: center;
        animation: modal-in 0.2s ease-out;
    }

    .modal-box h2 {
        margin: 0 0 10px;
        color: #10213b;
        font-size: 21px;
    }

    .modal-box p {
        margin: 0;
        color: #71819a;
        font-size: 14px;
        line-height: 1.7;
    }

    .modal-actions {
        display: flex;
        justify-content: center;
        gap: 12px;
        margin-top: 26px;
    }

    .modal-btn {
        min-width: 120px;
        padding: 11px 18px;

        border-radius: 9px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        transition: background 0.2s;
    }

    .modal-btn-secondary {
        background: #f1f5f9;
        color: #334155;
        border: 1px solid #e2e8f0;
    }

    .modal-btn-secondary:hover {
        background: #e2e8f0;
    }

    .modal-btn-danger {
        background: #e53935;
        color: white;
        border: 1px solid #e53935;
    }

    .modal-btn-danger:hover {
        background: #c62828;
    }

    @keyframes modal-in {
        from {
            opacity: 0;
            transform: translateY(8px) scale(0.98);
        }

        to {
            opacity: 1;
            transform: translateY(0) scale(1);
        }
    }

    .modal-btn:disabled {
        opacity: 0.65;
        cursor: not-allowed;
    }

    .order-action-row {
        display:flex;
        flex-wrap:wrap;
        align-items:center;
        gap:12px;
    }
    .order-action-row form {
        margin:0;
    }
    .order-action-row .btn {
        display:inline-flex;
        align-items:center;
        justify-content:center;
        gap:8px;
        min-height:44px;
        padding:10px 16px;
        border:1px solid transparent;
        border-radius:8px;
        line-height:1.4;
    }
    .order-action-row .btn-danger {
        background:#fff;
        color:#dc2626;
        border-color:#fca5a5;
    }
    .order-action-row .btn-danger:hover {
        background:#fff1f2;
        border-color:#ef4444;
    }
    .order-action-row .btn:focus-visible {
        outline:3px solid #93c5fd;
        outline-offset:3px;
    }
    .order-action-row .cancel-request-note {
        flex-basis:100%;
        margin:0;
    }
    @media (max-width:600px) {
        .order-action-row {
            flex-direction:column;
            align-items:stretch;
        }
        .order-action-row form,.order-action-row .btn {
            width:100%;
        }
    }
</style>
</head>

<body>

    <main class="page">


        <c:if test="${not empty sessionScope.successMessage}">
            <div class="success-message notification" role="status">
                <span class="notification-icon">
                    <i class="bi bi-check-lg"></i>
                </span>
                <span>
                    <c:out value="${sessionScope.successMessage}" />
                </span>
            </div>
            <c:remove var="successMessage" scope="session" />
        </c:if>

        <c:if test="${not empty sessionScope.errorMessage}">
            <div class="error-message notification" role="alert">
                <span class="notification-icon">
                    <i class="bi bi-exclamation-lg"></i>
                </span>
                <span>
                    <c:out value="${sessionScope.errorMessage}" />
                </span>
            </div>
            <c:remove var="errorMessage" scope="session" />
        </c:if>



        <div class="page-title">
            <div>
                <h1>Order #${order.orderId}</h1>
                <p>Chi tiết và quản lý trạng thái đơn hàng</p>
            </div>

            <a class="back-btn" href="${pageContext.request.contextPath}/admin/orders">
                ← Danh sách đơn hàng
            </a>
        </div>

        <div class="main-grid">

            <div class="card">
                <div class="card-header">
                    <h2>Thông tin đơn hàng</h2>
                </div>

                <div class="card-body">
                    <div class="info-grid">
                        <div class="info-item">
                            <span class="label">Order ID</span>
                            <span class="value">#${order.orderId}</span>
                        </div>

                        <div class="info-item">
                            <span class="label">User ID</span>
                            <span class="value">${order.userId}</span>
                        </div>

                        <div class="info-item">
                            <span class="label">User Name</span>
                            <span class="value">
                                <c:out value="${order.recipientName}" default="Chưa cập nhật" />
                            </span>
                        </div>

                        <div class="info-item">
                            <span class="label">Phone</span>
                            <span class="value">
                                <c:out value="${order.recipientPhone}" default="Chưa cập nhật" />
                            </span>
                        </div>

                        <div class="info-item" style="grid-column: 1 / -1;">
                            <span class="label">Address</span>
                            <span class="value">
                                <c:out value="${order.shippingAddress}" default="Chưa cập nhật" />
                            </span>
                        </div>

                        <div class="info-item">
                            <span class="label">Ngày tạo</span>
                            <span class="value">
                                <fmt:formatDate value="${order.createdAt}"
                                                pattern="dd/MM/yyyy HH:mm:ss" />
                            </span>
                        </div>

                    </div>
                </div>
                <section class="order-detail-section" aria-labelledby="orderProductsTitle">
                    <div class="card-header"><h2 id="orderProductsTitle">Sản phẩm trong đơn hàng</h2></div>
                    <div class="products-body">
                        <table class="products-table">
                            <thead>
                                <tr>
                                    <th scope="col">Sản phẩm</th>
                                    <th scope="col">Mã SKU</th>
                                    <th scope="col">SL</th>
                                    <th scope="col" class="price">Đơn giá</th>
                                    <th scope="col" class="price">Thành tiền</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="item" items="${items}">
                                    <tr>
                                        <td>
                                            <strong><c:out value="${item.productName}" /></strong>
                                            <small>Dòng đơn #${item.orderItemId}</small>
                                        </td>
                                        <td>
                                            <c:out value="${item.skuCode}" />
                                            <small>SKU #${item.skuId}</small>
                                        </td>
                                        <td>${item.quantity}</td>
                                        <td class="price"><fmt:formatNumber value="${item.price}" type="number" /> ₫</td>
                                        <td class="price"><fmt:formatNumber value="${item.price * item.quantity}" type="number" /> ₫</td>
                                    </tr>
                                </c:forEach>
                                <c:if test="${empty items}">
                                    <tr><td colspan="5" class="empty">Không có sản phẩm trong đơn hàng.</td></tr>
                                </c:if>
                            </tbody>
                        </table>
                    </div>

                    <%-- Tổng tiền hàng lấy từ giá và số lượng đã lưu trong ORDER_ITEM. --%>
                    <c:set var="subtotal" value="${0}" />
                    <c:forEach var="item" items="${items}">
                        <c:set var="subtotal" value="${subtotal + item.price * item.quantity}" />
                    </c:forEach>

                    <div class="order-price-summary">
                        <div class="order-price-row">
                            <span>Tiền sản phẩm</span>
                            <strong><fmt:formatNumber value="${subtotal}" type="number" maxFractionDigits="2" /> ₫</strong>
                        </div>
                        <div class="order-price-row">
                            <span>Phí giao hàng</span>
                            <strong><fmt:formatNumber value="${order.shippingFee}" type="number" maxFractionDigits="2" /> ₫</strong>
                        </div>
                        <div class="order-price-row">
                            <span>Giảm giá</span>
                            <strong class="discount-value"><c:if test="${order.discountAmount gt 0}">−</c:if><fmt:formatNumber value="${order.discountAmount}" type="number" maxFractionDigits="2" /> ₫</strong>
                        </div>
                        <%-- Tổng thanh toán là giá trị đã lưu của đơn, không tính lại để cập nhật DB. --%>
                        <div class="total-box">
                            <span class="total-label">Tổng tiền đơn hàng</span>
                            <span class="total-value"><fmt:formatNumber value="${order.totalAmount}" type="number" maxFractionDigits="2" /> ₫</span>
                        </div>
                    </div>
                </section>
            </div>

            <div class="card">
                <div class="card-header">
                    <h2>Quản lý đơn hàng</h2>
                </div>

                <div class="card-body">
                    <div class="current-status">
                        <span class="status-label">Trạng thái hiện tại</span>
                        <span class="status-badge">
                            <c:out value="${statusLabels[status]}" default="${status}" />
                        </span>
                    </div>

                    <c:if test="${canAdvanceOrder or canStaffCancel or pendingCancel or needsManualRefund}">
                        <div class="action-box">
                            <c:if test="${needsManualRefund}">
                                <p>Đối chiếu khoản đã thu và lịch sử hoàn tiền trên cổng thanh toán trước khi hoàn thủ công.</p>
                                <c:if test="${empty successfulPayments}">
                                    <p>Chưa tìm thấy giao dịch online đã thu tiền cho đơn này.</p>
                                </c:if>
                                <c:if test="${not empty successfulPayments}">
                                    <ul>
                                        <c:forEach var="payment" items="${successfulPayments}">
                                            <li>
                                                <c:out value="${payment.method}"/> ·
                                                <fmt:formatNumber value="${payment.amount}" maxFractionDigits="0"/> đ ·
                                                Mã giao dịch <c:out value="${payment.reference}"/>
                                                <c:if test="${not empty payment.providerReference}">
                                                    · Mã tại cổng <c:out value="${payment.providerReference}"/>
                                                </c:if>
                                            </li>
                                        </c:forEach>
                                    </ul>
                                </c:if>
                            </c:if>
                            <c:if test="${canAdvanceOrder and status eq 'SHIPPING' and order.paymentMethod eq 'COD' and order.totalAmount gt 0}">
                                <p>Xác nhận sau khi đã giao hàng và thu đủ tiền COD.</p>
                            </c:if>
                            <c:if test="${pendingCancel}">
                                <p>Lý do khách yêu cầu hủy: <c:out value="${order.cancelRequestReason}" /></p>
                            </c:if>
                            <div class="order-action-row">
                                <c:if test="${pendingCancel}">
                                    <button type="button" class="btn btn-danger"
                                            onclick="openCancelDialog('approveCancel', 'Duyệt hủy đơn', 'Nội dung duyệt')">
                                        Duyệt hủy đơn
                                    </button>
                                    <button type="button" class="btn btn-secondary"
                                            onclick="openCancelDialog('rejectCancel', 'Từ chối yêu cầu', 'Lý do từ chối')">
                                        Từ chối yêu cầu
                                    </button>
                                </c:if>
                                <c:if test="${canAdvanceOrder}">
                                    <form method="post" action="${pageContext.request.contextPath}/admin/orders">
                                        <input type="hidden" name="csrfToken" value="${sessionScope.staffOrderToken}">
                                        <input type="hidden" name="orderId" value="${order.orderId}">
                                        <input type="hidden" name="action" value="${status eq 'PENDING_CONFIRMATION' ? 'confirm' : 'nextStep'}">
                                        <input type="hidden" name="expectedStatus" value="<c:out value='${status}' />">
                                        <button type="submit" class="btn btn-primary">
                                            <c:choose>
                                                <c:when test="${status eq 'PENDING_CONFIRMATION'}"><i class="bi bi-check-circle" aria-hidden="true"></i> Xác nhận đơn hàng</c:when>
                                                <c:when test="${status eq 'CONFIRMED'}"><i class="bi bi-box-seam" aria-hidden="true"></i> Chuyển sang đóng gói</c:when>
                                                <c:when test="${status eq 'PACKING'}"><i class="bi bi-truck" aria-hidden="true"></i> Chuyển sang giao hàng</c:when>
                                                <c:otherwise><i class="bi bi-check2-circle" aria-hidden="true"></i> Xác nhận giao thành công</c:otherwise>
                                            </c:choose>
                                        </button>
                                    </form>
                                </c:if>
                                <c:if test="${canStaffCancel}">
                                    <button type="button" class="btn btn-danger"
                                            onclick="openCancelDialog('cancel', 'Xác nhận hủy đơn hàng', 'Lý do hủy đơn')">
                                        <i class="bi bi-x-circle me-1" aria-hidden="true"></i> Hủy đơn hàng
                                    </button>
                                </c:if>
                            </div>
                        </div>
                    </c:if>
                </div>
                <section class="order-detail-section" aria-labelledby="orderHistoryTitle">
                    <div class="card-header"><h2 id="orderHistoryTitle">Lịch sử xử lý đơn</h2></div>
                    <c:choose>
                        <c:when test="${not empty history}">
                            <ul class="order-history">
                                <c:forEach var="entry" items="${history}">
                                    <li>
                                        <c:set var="approvedCancellation"
                                               value="${entry.status eq 'CANCELLED' and entry.actor eq 'STAFF' and order.cancelRequestStatus eq 'APPROVED'}" />
                                        <strong>
                                            <c:choose>
                                                <c:when test="${approvedCancellation}">Đã duyệt hủy đơn</c:when>
                                                <c:when test="${entry.status eq entry.oldStatus and entry.actor eq 'CUSTOMER'}">Đã gửi yêu cầu hủy</c:when>
                                                <c:when test="${entry.status eq entry.oldStatus and entry.actor eq 'STAFF'}">Đã từ chối yêu cầu hủy</c:when>
                                                <c:otherwise><c:out value="${statusLabels[entry.status]}" default="${entry.status}" /></c:otherwise>
                                            </c:choose>
                                        </strong>
                                        <span class="order-history-meta">
                                            <fmt:formatDate value="${entry.updatedAt}" pattern="dd/MM/yyyy HH:mm:ss" />
                                            <c:if test="${not empty entry.actor}">
                                                · <c:choose>
                                                    <c:when test="${entry.actor eq 'STAFF'}">Nhân viên</c:when>
                                                    <c:when test="${entry.actor eq 'CUSTOMER'}">Khách hàng</c:when>
                                                    <c:when test="${entry.actor eq 'SYSTEM'}">Hệ thống</c:when>
                                                    <c:otherwise><c:out value="${entry.actor}" /></c:otherwise>
                                                </c:choose><c:if test="${not empty entry.changedBy}"> #<c:out value="${entry.changedBy}" /></c:if>
                                            </c:if>
                                        </span>
                                        <c:set var="historyNote" value="${approvedCancellation ? order.cancelReviewNote : entry.reason}" />
                                        <c:if test="${not empty historyNote}">
                                            <p><c:out value="${historyNote}" /></p>
                                        </c:if>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:when>
                        <c:otherwise><p class="empty">Chưa có lịch sử xử lý.</p></c:otherwise>
                    </c:choose>
                </section>
            </div>
        </div>
    </main>



                    <dialog id="cancelModal" class="modal-overlay" aria-labelledby="cancelModalTitle">
                        <form class="modal-box" method="post"
                              action="${pageContext.request.contextPath}/admin/orders">
                            <input type="hidden" name="csrfToken" value="${sessionScope.staffOrderToken}">
                            <input type="hidden" name="orderId" value="${order.orderId}">
                            <input type="hidden" name="action" id="cancelAction">
                            <input type="hidden" name="cancelRequestVersion" value="<c:out value='${order.cancelRequestVersion}' />">

                            <h2 id="cancelModalTitle">Xác nhận hủy đơn hàng</h2>
                            <p>Đơn hàng <strong>#${order.orderId}</strong></p>

                            <label id="cancelReasonLabel" for="staffCancelReason">Lý do hủy đơn</label>
                            <textarea id="staffCancelReason" name="reason" rows="3"
                                      maxlength="500" required autofocus></textarea>

                            <div class="modal-actions">
                                <button type="button" class="modal-btn modal-btn-secondary"
                                        onclick="document.getElementById('cancelModal').close()">Quay lại</button>
                                <button type="submit" id="confirmCancelButton" class="modal-btn modal-btn-danger">
                                    Xác nhận
                                </button>
                            </div>
                        </form>
                    </dialog>

                    <script>
                        document.querySelectorAll(".notification").forEach(function (message) {
                            setTimeout(function () {
                                message.classList.add("notification-hide");

                                setTimeout(function () {
                                    message.remove();
                                }, 300);
                            }, 3500);
                        });


                        const cancelDialog = document.getElementById("cancelModal");
                        const cancelReason = document.getElementById("staffCancelReason");

                        function openCancelDialog(action, title, label) {
                            const actionInput = document.getElementById("cancelAction");
                            if (actionInput.value !== action) {
                                cancelReason.value = "";
                            }
                            actionInput.value = action;
                            document.getElementById("cancelModalTitle").textContent = title;
                            document.getElementById("cancelReasonLabel").textContent = label;
                            cancelDialog.showModal();
                        }

                        cancelDialog.addEventListener("click", function (event) {
                            if (event.target === cancelDialog) {
                                cancelDialog.close();
                            }
                        });

                        cancelDialog.querySelector("form").addEventListener("submit", function () {
                            document.getElementById("confirmCancelButton").disabled = true;
                        });
                    </script>


                    </body>

                    </html>

                    <%@include file="/WEB-INF/include/footer.jsp" %>
