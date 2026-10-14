<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    /* ================= ORDER DETAIL PAGE ================= */
    .order-detail-page {
        width: 100%;
        padding: 20px 0 30px;
        background: #f4f7fb;
        color: #10213b;
        box-sizing: border-box;
    }

    .order-detail-page *,
    .order-detail-page *::before,
    .order-detail-page *::after {
        box-sizing: border-box;
    }

    .order-detail-page .page {
        width: 100%;
        padding: 0 24px;
        display: flex;
        flex-direction: column;
        gap: 18px;
    }

    /* ================= PAGE TITLE ================= */
    .order-detail-page .page-title {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 15px;
    }

    .order-detail-page .page-title h1 {
        margin: 0;
        font-size: 28px;
        line-height: 1.2;
        font-weight: 800;
        color: #10213b;
    }

    .order-detail-page .page-title p {
        margin: 7px 0 0;
        color: #71819a;
        font-size: 14px;
    }

    .order-detail-page .back-btn {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        background: #eaf3ff;
        color: #0878ff;
        text-decoration: none;
        padding: 11px 17px;
        border-radius: 10px;
        font-size: 14px;
        font-weight: 600;
        white-space: nowrap;
        transition: background .2s;
    }

    .order-detail-page .back-btn:hover {
        background: #dcecff;
        color: #0878ff;
    }

    /* ================= MAIN GRID ================= */
    .order-detail-page .main-grid {
        display: grid;
        grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
        gap: 18px;
        align-items: stretch;
    }

    /* ================= CARD ================= */
    .order-detail-page .card {
        min-width: 0;
        background: white;
        border: 1px solid #dfe7f1;
        border-radius: 15px;
        box-shadow: 0 5px 18px rgba(27, 61, 99, .06);
        overflow: hidden;
        display: flex;
        flex-direction: column;
    }

    .order-detail-page .card-header {
        min-height: 58px;
        padding: 12px 20px;
        border-bottom: 1px solid #e8edf4;
        display: flex;
        align-items: center;
        background: #fafbfc;
    }

    .order-detail-page .card-header h2 {
        margin: 0;
        font-size: 17px;
        font-weight: 700;
        color: #10213b;
    }

    .order-detail-page .card-body {
        padding: 18px;
        flex: 1;
    }

    /* ================= ORDER INFORMATION ================= */
    .order-detail-page .info-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 10px;
    }

    .order-detail-page .info-item {
        min-width: 0;
        min-height: 60px;
        background: #f7f9fc;
        border-radius: 10px;
        padding: 11px 13px;
        overflow-wrap: anywhere;
    }

    .order-detail-page .label {
        display: block;
        color: #8292aa;
        font-size: 10px;
        text-transform: uppercase;
        margin-bottom: 6px;
        letter-spacing: .4px;
    }

    .order-detail-page .value {
        display: block;
        font-size: 14px;
        font-weight: 600;
        color: #10213b;
    }

    /* ================= TOTAL ================= */
    .order-detail-page .total-box {
        margin-top: 12px;
        padding: 14px 16px;
        border-radius: 10px;
        background: #edf6ff;
        border: 1px solid #cfe5ff;
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 12px;
    }

    .order-detail-page .total-label {
        color: #66809e;
        font-size: 13px;
        font-weight: 500;
    }

    .order-detail-page .total-value {
        color: #0878ff;
        font-size: 19px;
        font-weight: 800;
        white-space: nowrap;
    }

    /* ================= CURRENT STATUS ================= */
    .order-detail-page .current-status {
        background: #f5f9ff;
        border: 1px solid #e1ecfa;
        border-radius: 10px;
        padding: 12px 14px;
        margin-bottom: 12px;
    }

    .order-detail-page .status-label {
        display: block;
        font-size: 12px;
        color: #71819a;
        margin-bottom: 7px;
    }

    .order-detail-page .status-badge {
        display: inline-block;
        padding: 7px 12px;
        border-radius: 8px;
        background: #e7f2ff;
        color: #0878ff;
        font-size: 13px;
        font-weight: 700;
    }

    /* ================= ACTION BOX ================= */
    .order-detail-page .action-box {
        background: #f7f9fc;
        border-radius: 10px;
        padding: 12px;
        margin-bottom: 12px;
    }

    .order-detail-page .action-box p {
        margin: 0 0 10px;
        color: #71819a;
        font-size: 13px;
        line-height: 1.5;
    }

    .order-detail-page form {
        margin: 0;
    }

    /* ================= BUTTONS ================= */
    .order-detail-page .btn {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border: none;
        border-radius: 8px;
        padding: 10px 16px;
        min-height: 38px;
        font-size: 13px;
        font-weight: 700;
        cursor: pointer;
        transition: background .2s, transform .2s;
    }

    .order-detail-page .btn-primary {
        background: #1677ff;
        color: white;
    }

    .order-detail-page .btn-primary:hover {
        background: #0867e8;
        color: white;
    }

    .order-detail-page .btn-danger {
        background: #fff1f2;
        color: #e53935;
        border: 1px solid #ffc9cd;
    }

    .order-detail-page .btn-danger:hover {
        background: #ffe5e7;
        color: #d92d20;
    }

    /* ================= STATUS FORM ================= */
    .order-detail-page .status-form {
        display: flex;
        gap: 9px;
        align-items: center;
    }

    .order-detail-page .status-form select {
        flex: 1;
        min-width: 0;
        height: 38px;
        padding: 0 11px;
        border: 1px solid #d5dfeb;
        border-radius: 8px;
        background: white;
        color: #24364d;
        font-size: 13px;
        outline: none;
    }

    .order-detail-page .status-form select:focus {
        border-color: #1677ff;
    }

    .order-detail-page .cancel-area {
        margin-top: 5px;
    }

    /* ================= PRODUCTS ================= */
    .order-detail-page .products-card {
        min-height: 220px;
    }

    .order-detail-page .products-body {
        width: 100%;
        padding: 0;
        overflow-x: auto;
        overflow-y: auto;
        max-height: 320px;
    }

    .order-detail-page .products-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 13px;
    }

    .order-detail-page .products-table thead {
        background: #f7f9fc;
    }

    .order-detail-page .products-table th {
        height: 42px;
        background: #f7f9fc;
        color: #71819a;
        text-align: left;
        padding: 0 18px;
        font-size: 11px;
        font-weight: 700;
        text-transform: uppercase;
        white-space: nowrap;
        position: sticky;
        top: 0;
        z-index: 1;
        border-bottom: 1px solid #edf1f5;
    }

    .order-detail-page .products-table td {
        height: 46px;
        padding: 8px 18px;
        border-bottom: 1px solid #edf1f5;
        color: #26384f;
        white-space: nowrap;
    }

    .order-detail-page .products-table tbody tr:hover {
        background: #f8fbff;
    }

    .order-detail-page .products-table tbody tr:last-child td {
        border-bottom: none;
    }

    .order-detail-page .price {
        font-weight: 700;
        color: #10213b;
    }

    .order-detail-page .empty {
        text-align: center;
        color: #8a98aa;
        padding: 25px !important;
    }

    /* ================= RESPONSIVE ================= */
    @media (max-width: 1100px) {
        .order-detail-page .main-grid {
            grid-template-columns: 1fr;
        }
    }

    @media (max-width: 700px) {
        .order-detail-page {
            padding-top: 15px;
        }

        .order-detail-page .page {
            padding: 0 12px;
            gap: 14px;
        }

        .order-detail-page .page-title {
            align-items: flex-start;
            flex-direction: column;
        }

        .order-detail-page .page-title h1 {
            font-size: 24px;
        }

        .order-detail-page .card-body {
            padding: 14px;
        }

        .order-detail-page .card-header {
            padding: 12px 14px;
        }

        .order-detail-page .total-box {
            align-items: flex-start;
            flex-direction: column;
            gap: 6px;
        }

        .order-detail-page .status-form {
            align-items: stretch;
            flex-direction: column;
        }

        .order-detail-page .status-form .btn {
            width: 100%;
        }

        .order-detail-page .products-table {
            min-width: 650px;
        }
    }

    @media (max-width: 420px) {
        .order-detail-page .info-grid {
            grid-template-columns: 1fr;
        }

        .order-detail-page .btn-danger {
            width: 100%;
        }
    }
</style>

<!-- ================= ORDER DETAIL PAGE ================= -->
<div class="order-detail-page">

    <main class="page">

        <!-- ================= PAGE TITLE ================= -->
        <div class="page-title">
            <div>
                <h1>Order #${order.orderId}</h1>
                <p>Chi tiết và quản lý trạng thái đơn hàng</p>
            </div>

            <a class="back-btn"
               href="${pageContext.request.contextPath}/admin/orders">
                ← Danh sách đơn hàng
            </a>
        </div>

        <!-- ================= ORDER INFORMATION + MANAGEMENT ================= -->
        <div class="main-grid">

            <!-- ================= ORDER INFORMATION ================= -->
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
                            <span class="label">Address ID</span>
                            <span class="value">
                                <c:choose>
                                    <c:when test="${not empty order.addressId}">
                                        ${order.addressId}
                                    </c:when>
                                    <c:otherwise>
                                        Chưa cập nhật
                                    </c:otherwise>
                                </c:choose>
                            </span>
                        </div>

                        <div class="info-item">
                            <span class="label">Shipping Partner</span>
                            <span class="value">
                                <c:choose>
                                    <c:when test="${not empty order.shippingPartnerId}">
                                        #${order.shippingPartnerId}
                                    </c:when>
                                    <c:otherwise>
                                        Chưa phân công
                                    </c:otherwise>
                                </c:choose>
                            </span>
                        </div>

                        <div class="info-item">
                            <span class="label">Phí giao hàng</span>
                            <span class="value">
                                <fmt:formatNumber
                                    value="${order.shippingFee}"
                                    type="number"
                                    groupingUsed="true"
                                    maxFractionDigits="0"/> ₫
                            </span>
                        </div>

                        <div class="info-item">
                            <span class="label">Ngày tạo</span>
                            <span class="value">
                                <fmt:formatDate
                                    value="${order.createdAt}"
                                    pattern="dd/MM/yyyy HH:mm"/>
                            </span>
                        </div>

                    </div>

                    <div class="total-box">
                        <span class="total-label">Tổng tiền đơn hàng</span>

                        <span class="total-value">
                            <fmt:formatNumber
                                value="${order.totalAmount}"
                                type="number"
                                groupingUsed="true"
                                maxFractionDigits="0"/> ₫
                        </span>
                    </div>

                </div>
            </div>

            <!-- ================= ORDER MANAGEMENT ================= -->
            <div class="card">

                <div class="card-header">
                    <h2>Quản lý đơn hàng</h2>
                </div>

                <div class="card-body">

                    <!-- CURRENT STATUS -->
                    <div class="current-status">
                        <span class="status-label">Trạng thái hiện tại</span>

                        <span class="status-badge">
                            <c:choose>
                                <c:when test="${not empty status}">
                                    <c:out value="${status}"/>
                                </c:when>
                                <c:otherwise>
                                    Chưa có trạng thái
                                </c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <!-- CONFIRM ORDER -->
                    <c:if test="${status == 'Pending'}">
                        <div class="action-box">
                            <p>
                                Xác nhận đơn hàng để chuyển sang bước xử lý tiếp theo.
                            </p>

                            <form method="post"
                                  action="${pageContext.request.contextPath}/admin/orders">

                                <input type="hidden" name="action" value="confirm">
                                <input type="hidden" name="orderId" value="${order.orderId}">

                                <button type="submit" class="btn btn-primary">
                                    ✓ Xác nhận đơn hàng
                                </button>
                            </form>
                        </div>
                    </c:if>

                    <!-- CHANGE STATUS -->
                    <div class="action-box">
                        <p>Cập nhật trạng thái đơn hàng</p>

                        <form method="post"
                              action="${pageContext.request.contextPath}/admin/orders"
                              class="status-form">

                            <input type="hidden" name="action" value="changeStatus">
                            <input type="hidden" name="orderId" value="${order.orderId}">

                            <select name="status" required>
                                <option value="Confirmed"
                                    ${status == 'Confirmed' ? 'selected' : ''}>
                                    Confirmed
                                </option>

                                <option value="Packing"
                                    ${status == 'Packing' ? 'selected' : ''}>
                                    Packing
                                </option>

                                <option value="Shipping"
                                    ${status == 'Shipping' ? 'selected' : ''}>
                                    Shipping
                                </option>

                                <option value="Completed"
                                    ${status == 'Completed' ? 'selected' : ''}>
                                    Completed
                                </option>
                            </select>

                            <button type="submit" class="btn btn-primary">
                                Cập nhật
                            </button>
                        </form>
                    </div>

                    <!-- CANCEL ORDER -->
                    <div class="cancel-area">
                        <form method="post"
                              action="${pageContext.request.contextPath}/admin/orders"
                              onsubmit="return confirm('Bạn có chắc chắn muốn hủy đơn hàng này không?');">

                            <input type="hidden" name="action" value="cancel">
                            <input type="hidden" name="orderId" value="${order.orderId}">

                            <button type="submit" class="btn btn-danger">
                                ✕ Hủy đơn hàng
                            </button>
                        </form>
                    </div>

                </div>
            </div>

        </div>

        <!-- ================= PRODUCTS ================= -->
        <div class="card products-card">

            <div class="card-header">
                <h2>Sản phẩm trong đơn hàng</h2>
            </div>

            <div class="products-body">
                <table class="products-table">

                    <thead>
                        <tr>
                            <th>Order Item</th>
                            <th>SKU ID</th>
                            <th>Số lượng</th>
                            <th>Đơn giá</th>
                            <th>Thành tiền</th>
                        </tr>
                    </thead>

                    <tbody>
                        <c:choose>
                            <c:when test="${not empty items}">
                                <c:forEach var="item" items="${items}">
                                    <tr>
                                        <td>#${item.orderItemId}</td>

                                        <td>${item.skuId}</td>

                                        <td>${item.quantity}</td>

                                        <td class="price">
                                            <fmt:formatNumber
                                                value="${item.price}"
                                                type="number"
                                                groupingUsed="true"
                                                maxFractionDigits="0"/> ₫
                                        </td>

                                        <td class="price">
                                            <fmt:formatNumber
                                                value="${item.price * item.quantity}"
                                                type="number"
                                                groupingUsed="true"
                                                maxFractionDigits="0"/> ₫
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>

                            <c:otherwise>
                                <tr>
                                    <td colspan="5" class="empty">
                                        Không có sản phẩm trong đơn hàng.
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>

                </table>
            </div>

        </div>

    </main>

</div>

<%@include file="/WEB-INF/include/footer.jsp" %>