<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>OECS - Order Detail</title>

        <style>
            * {
                box-sizing: border-box;
            }

            html, body {
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

            /* ================= HEADER ================= */

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

            /* ================= PAGE ================= */

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

            /* ================= MAIN GRID ================= */

            .main-grid {
                display: grid;
                grid-template-columns: 1fr 1fr;
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

            /* ================= ORDER INFO ================= */

            .info-grid {
                display: grid;
                grid-template-columns: 1fr 1fr;
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

            /* ================= MANAGEMENT ================= */

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

            /* ================= PRODUCTS ================= */

            .products-card {
                min-height: 220px;
            }

            .products-body {
                padding: 0;
                overflow-y: auto;
                max-height: 320px;
            }

            .products-table {
                width: 100%;
                border-collapse: collapse;
                font-size: 13px;
            }

            .products-table th {
                height: 38px;
                background: #f7f9fc;
                color: #71819a;
                text-align: left;
                padding: 0 18px;
                font-size: 11px;
                text-transform: uppercase;
                position: sticky;
                top: 0;
                z-index: 1;
                border-bottom: 1px solid #edf1f5;
            }

            .products-table td {
                height: 42px;
                padding: 8px 18px;
                border-bottom: 1px solid #edf1f5;
                color: #26384f;
            }

            .products-table tbody tr:last-child td {
                border-bottom: none;
            }

            .empty {
                text-align: center;
                color: #8a98aa;
                padding: 25px !important;
            }

            .price {
                font-weight: 600;
            }

            /* ================= RESPONSIVE ================= */

            @media (max-width: 900px) {
                .page {
                    padding: 16px;
                }

                .main-grid {
                    grid-template-columns: 1fr;
                }
            }
        </style>
    </head>

    <body>

        <!-- ================= HEADER ================= -->

        <header class="topbar">
            <div class="brand">
                <div class="brand-icon">◆</div>
                <div>
                    <div class="brand-name">OECS</div>
                    <span class="brand-sub">MANAGEMENT</span>
                </div>
            </div>

            <div class="system-status">
                <span class="status-dot"></span>
                Hệ thống hoạt động ổn định
            </div>
        </header>

        <!-- ================= PAGE ================= -->

        <main class="page">

            <!-- TITLE -->

            <div class="page-title">
                <div>
                    <h1>Order #${order.orderId}</h1>
                    <p>Chi tiết và quản lý trạng thái đơn hàng</p>
                </div>

                <a class="back-btn" href="${pageContext.request.contextPath}/admin/orders">
                    ← Danh sách đơn hàng
                </a>
            </div>

            <!-- ================= TOP ================= -->

            <div class="main-grid">

                <!-- ================= ORDER INFO ================= -->

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
                                <span class="value">${order.addressId}</span>
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
                                    <fmt:formatNumber value="${order.shippingFee}" type="number" groupingUsed="true"/> ₫
                                </span>
                            </div>

                            <div class="info-item">
                                <span class="label">Ngày tạo</span>
                                <span class="value">${order.createdAt}</span>
                            </div>
                        </div>

                        <div class="total-box">
                            <span class="total-label">Tổng tiền đơn hàng</span>
                            <span class="total-value">
                                <fmt:formatNumber value="${order.totalAmount}" type="number" groupingUsed="true"/> ₫
                            </span>
                        </div>
                    </div>
                </div>

                <!-- ================= MANAGEMENT ================= -->

                <div class="card">
                    <div class="card-header">
                        <h2>Quản lý đơn hàng</h2>
                    </div>

                    <div class="card-body">
                        <div class="current-status">
                            <span class="status-label">Trạng thái hiện tại</span>
                            <span class="status-badge">
                                <c:choose>
                                    <c:when test="${not empty status}">
                                        ${status}
                                    </c:when>
                                    <c:otherwise>
                                        Chưa có trạng thái
                                    </c:otherwise>
                                </c:choose>
                            </span>
                        </div>

                        <!-- CONFIRM -->
                        <c:if test="${status == 'Pending'}">
                            <div class="action-box">
                                <p>Xác nhận đơn hàng để chuyển sang bước xử lý tiếp theo.</p>
                                <form method="post" action="${pageContext.request.contextPath}/admin/orders">
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
                            <p>Cập nhật trạng thái</p>
                            <form method="post" action="${pageContext.request.contextPath}/admin/orders" class="status-form">
                                <input type="hidden" name="action" value="changeStatus">
                                <input type="hidden" name="orderId" value="${order.orderId}">
                                <select name="status">
                                    <option value="Confirmed" ${status == 'Confirmed' ? 'selected' : ''}>Confirmed</option>
                                    <option value="Packing" ${status == 'Packing' ? 'selected' : ''}>Packing</option>
                                    <option value="Shipping" ${status == 'Shipping' ? 'selected' : ''}>Shipping</option>
                                    <option value="Completed" ${status == 'Completed' ? 'selected' : ''}>Completed</option>
                                </select>
                                <button type="submit" class="btn btn-primary">
                                    Cập nhật
                                </button>
                            </form>
                        </div>

                        <!-- CANCEL -->
                        <div class="cancel-area">
                            <form method="post" action="${pageContext.request.contextPath}/admin/orders" onsubmit="return confirm('Bạn có chắc chắn muốn hủy đơn hàng này không?');">
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
                                                <fmt:formatNumber value="${item.price}" type="number" groupingUsed="true"/> ₫
                                            </td>
                                            <td class="price">
                                                <fmt:formatNumber value="${item.price * item.quantity}" type="number" groupingUsed="true"/> ₫
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

    </body>
</html>