<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<!DOCTYPE html>
<html>
    <head>

        <meta charset="UTF-8">
        <title>OECS - Order Management</title>

        <style>

            * {
                box-sizing: border-box;
            }

            html,
            body {
                margin: 0;
                padding: 0;
                width: 100%;
                min-height: 100%;
            }

            body {
                font-family: Arial, Helvetica, sans-serif;
                background: #f4f7fb;
                color: #0f172a;
            }

            /* ================= TOP HEADER ================= */

            .top-header {
                height: 82px;
                background: #0f172a;
                display: flex;
                align-items: center;
                justify-content: space-between;
                padding: 0 50px;
                color: white;
                box-shadow: 0 4px 16px rgba(15, 23, 42, 0.12);
            }

            .brand {
                display: flex;
                align-items: center;
                gap: 15px;
            }

            .brand-icon {
                width: 52px;
                height: 52px;
                border-radius: 13px;
                background: #1677ff;
                display: flex;
                align-items: center;
                justify-content: center;
                color: white;
                font-size: 23px;
                font-weight: bold;
                box-shadow: 0 5px 15px rgba(22, 119, 255, .25);
            }

            .brand-name {
                font-size: 23px;
                font-weight: 800;
                line-height: 1;
                letter-spacing: .3px;
            }

            .brand-sub {
                margin-top: 5px;
                color: #94a3b8;
                font-size: 11px;
                letter-spacing: 1.5px;
            }

            .system-status {
                display: flex;
                align-items: center;
                gap: 9px;
                font-size: 14px;
                color: #e2e8f0;
            }

            .status-dot {
                width: 9px;
                height: 9px;
                background: #22c55e;
                border-radius: 50%;
                box-shadow: 0 0 0 4px rgba(34, 197, 94, .12);
            }

            /* ================= PAGE ================= */

            .page {
                padding: 30px 50px 35px;
            }

            .page-heading {
                display: flex;
                align-items: flex-end;
                justify-content: space-between;
                margin-bottom: 24px;
            }

            .heading-title h1 {
                margin: 0;
                font-size: 32px;
                line-height: 1.1;
                font-weight: 800;
                letter-spacing: -.6px;
            }

            .heading-title p {
                margin: 8px 0 0;
                color: #64748b;
                font-size: 15px;
            }

            .order-badge {
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

            /* ================= MAIN CARD ================= */

            .card {
                background: white;
                border: 1px solid #e1e8f0;
                border-radius: 17px;
                box-shadow: 0 8px 28px rgba(15, 23, 42, .06);
                overflow: hidden;
            }

            .card-header {
                min-height: 76px;
                padding: 0 25px;
                display: flex;
                align-items: center;
                justify-content: space-between;
                border-bottom: 1px solid #e8edf3;
            }

            .card-title {
                display: flex;
                align-items: center;
                gap: 12px;
            }

            .card-icon {
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

            .card-title h2 {
                margin: 0;
                font-size: 19px;
                font-weight: 750;
            }

            .card-subtitle {
                color: #94a3b8;
                font-size: 13px;
            }

            /* ================= TABLE ================= */

            .table-container {
                width: 100%;
                overflow: hidden;
            }

            table {
                width: 100%;
                border-collapse: collapse;
                table-layout: fixed;
            }

            thead {
                background: #f8fafc;
            }

            th {
                height: 52px;
                padding: 0 18px;
                text-align: left;
                color: #64748b;
                font-size: 12px;
                font-weight: 700;
                letter-spacing: .35px;
                text-transform: uppercase;
                border-bottom: 1px solid #e2e8f0;
                white-space: nowrap;
            }

            td {
                height: 72px;
                padding: 0 18px;
                border-bottom: 1px solid #edf1f5;
                color: #334155;
                font-size: 14px;
                vertical-align: middle;
            }

            tbody tr {
                transition: background .15s ease;
            }

            tbody tr:hover {
                background: #f8fbff;
            }

            tbody tr:last-child td {
                border-bottom: none;
            }

            /* column sizing */

            th:nth-child(1),
            td:nth-child(1) {
                width: 9%;
            }

            th:nth-child(2),
            td:nth-child(2) {
                width: 8%;
            }

            th:nth-child(3),
            td:nth-child(3) {
                width: 16%;
            }

            th:nth-child(4),
            td:nth-child(4) {
                width: 16%;
            }

            th:nth-child(5),
            td:nth-child(5) {
                width: 13%;
            }

            th:nth-child(6),
            td:nth-child(6) {
                width: 13%;
            }

            th:nth-child(7),
            td:nth-child(7) {
                width: 15%;
            }

            th:nth-child(8),
            td:nth-child(8) {
                width: 10%;
            }

            /* ================= CELLS ================= */

            .order-id {
                color: #1677ff;
                font-size: 15px;
                font-weight: 800;
            }

            .user-id {
                font-weight: 600;
                color: #475569;
            }

            .recipient {
                font-weight: 600;
                color: #1e293b;
                white-space: nowrap;
                overflow: hidden;
                text-overflow: ellipsis;
            }

            .muted {
                color: #94a3b8;
                font-weight: 400;
                font-size: 13px;
            }

            .amount {
                font-weight: 800;
                color: #0f172a;
                white-space: nowrap;
            }

            .shipping {
                color: #475569;
                white-space: nowrap;
            }

            .date {
                color: #64748b;
                white-space: nowrap;
                font-size: 13px;
            }

            /* ================= PAYMENT ================= */

            .payment-badge {
                display: inline-flex;
                align-items: center;
                gap: 6px;
                padding: 7px 11px;
                border-radius: 8px;
                background: #ecfdf3;
                color: #15803d;
                font-size: 12px;
                font-weight: 700;
                white-space: nowrap;
            }

            .payment-dot {
                width: 6px;
                height: 6px;
                border-radius: 50%;
                background: #22c55e;
            }

            .payment-empty {
                display: inline-flex;
                padding: 7px 11px;
                border-radius: 8px;
                background: #f1f5f9;
                color: #64748b;
                font-size: 12px;
                font-weight: 600;
                white-space: nowrap;
            }

            /* ================= BUTTON ================= */

            .detail-btn {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                gap: 6px;

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

            .detail-btn:hover {
                background: #0969e8;
                box-shadow: 0 5px 13px rgba(22, 119, 255, .22);
                transform: translateY(-1px);
            }

            /* ================= EMPTY ================= */

            .empty-row td {
                height: 180px;
                text-align: center;
                color: #94a3b8;
            }

            .empty-icon {
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

            /* ================= FOOTER ================= */

            .card-footer {
                min-height: 48px;
                padding: 0 25px;
                background: #fbfcfe;
                border-top: 1px solid #edf1f5;

                display: flex;
                align-items: center;
                justify-content: space-between;

                color: #94a3b8;
                font-size: 12px;
            }

            .footer-status {
                display: flex;
                align-items: center;
                gap: 7px;
            }

            .footer-status-dot {
                width: 7px;
                height: 7px;
                background: #22c55e;
                border-radius: 50%;
            }

            /* ================= RESPONSIVE ================= */

            @media (max-width: 1250px) {

                .page {
                    padding-left: 30px;
                    padding-right: 30px;
                }

                .top-header {
                    padding-left: 30px;
                    padding-right: 30px;
                }

                th,
                td {
                    padding-left: 12px;
                    padding-right: 12px;
                }

                .card-subtitle {
                    display: none;
                }

                .date {
                    font-size: 12px;
                }

                .detail-btn {
                    min-width: 100px;
                    padding: 0 9px;
                }
            }

        </style>

    </head>

    <body>


        <!-- ================= TOP HEADER ================= -->

        <header class="top-header">

            <div class="brand">

                <div class="brand-icon">
                    ◆
                </div>

                <div>

                    <div class="brand-name">
                        OECS
                    </div>

                    <div class="brand-sub">
                        MANAGEMENT
                    </div>

                </div>

            </div>


            <div class="system-status">

                <span class="status-dot"></span>

                Hệ thống hoạt động ổn định

            </div>

        </header>


        <!-- ================= PAGE ================= -->

        <main class="page">


            <!-- PAGE TITLE -->

            <div class="page-heading">

                <div class="heading-title">

                    <h1>
                        Order Management
                    </h1>

                    <p>
                        Quản lý danh sách và trạng thái đơn hàng
                    </p>

                </div>


                <div class="order-badge">

                    🛒

                    Đơn hàng

                </div>

            </div>


            <!-- ================= ORDER CARD ================= -->

            <div class="card">


                <!-- CARD HEADER -->

                <div class="card-header">

                    <div class="card-title">

                        <div class="card-icon">
                            🛒
                        </div>

                        <h2>
                            Danh sách đơn hàng
                        </h2>

                    </div>


                    <div class="card-subtitle">

                        Theo dõi và quản lý đơn hàng

                    </div>

                </div>


                <!-- ================= TABLE ================= -->

                <div class="table-container">

                    <table>

                        <thead>

                            <tr>

                                <th>
                                    Order ID
                                </th>

                                <th>
                                    User ID
                                </th>

                                <th>
                                    Người nhận
                                </th>

                                <th>
                                    Tổng tiền
                                </th>

                                <th>
                                    Phí giao hàng
                                </th>

                                <th>
                                    Thanh toán
                                </th>

                                <th>
                                    Ngày tạo
                                </th>

                                <th>
                                    Thao tác
                                </th>

                            </tr>

                        </thead>


                        <tbody>


                            <c:choose>


                                <c:when test="${not empty orders}">


                                    <c:forEach
                                        var="order"
                                        items="${orders}">


                                        <tr>


                                            <!-- ORDER ID -->

                                            <td class="order-id">

                                                #${order.orderId}

                                            </td>


                                            <!-- USER ID -->

                                            <td class="user-id">

                                                ${order.userId}

                                            </td>


                                            <!-- RECIPIENT -->

                                            <td class="recipient">

                                                <c:choose>

                                                    <c:when test="${not empty order.recipientName}">

                                                        ${order.recipientName}

                                                    </c:when>

                                                    <c:otherwise>

                                                        <span class="muted">
                                                            Chưa cập nhật
                                                        </span>

                                                    </c:otherwise>

                                                </c:choose>

                                            </td>


                                            <!-- TOTAL -->

                                            <td class="amount">

                                    <fmt:formatNumber
                                        value="${order.totalAmount}"
                                        type="number"
                                        groupingUsed="true"
                                        maxFractionDigits="0"/>

                                    ₫

                                    </td>


                                    <!-- SHIPPING -->

                                    <td class="shipping">

                                    <fmt:formatNumber
                                        value="${order.shippingFee}"
                                        type="number"
                                        groupingUsed="true"
                                        maxFractionDigits="0"/>

                                    ₫

                                    </td>


                                    <!-- PAYMENT -->

                                    <td>

                                        <c:choose>

                                            <c:when test="${not empty order.paymentStatus}">

                                                <span class="payment-badge">

                                                    <span class="payment-dot"></span>

                                                    ${order.paymentStatus}

                                                </span>

                                            </c:when>

                                            <c:otherwise>

                                                <span class="payment-empty">

                                                    Chưa cập nhật

                                                </span>

                                            </c:otherwise>

                                        </c:choose>

                                    </td>


                                    <!-- DATE -->

                                    <td class="date">

                                    <fmt:formatDate
                                        value="${order.createdAt}"
                                        pattern="dd/MM/yyyy HH:mm"/>

                                    </td>


                                    <!-- ACTION -->

                                    <td>

                                        <a
                                            class="detail-btn"
                                            href="${pageContext.request.contextPath}/admin/orders/detail?id=${order.orderId}">

                                            Xem chi tiết →

                                        </a>

                                    </td>


                                    </tr>


                                </c:forEach>


                            </c:when>


                            <c:otherwise>


                                <tr class="empty-row">

                                    <td colspan="8">

                                        <div class="empty-icon">
                                            📦
                                        </div>

                                        Không có đơn hàng nào.

                                    </td>

                                </tr>


                            </c:otherwise>


                        </c:choose>


                        </tbody>

                    </table>

                </div>


                <!-- ================= FOOTER ================= -->

                <div class="card-footer">

                    <span>
                        Quản lý đơn hàng OECS
                    </span>


                    <span class="footer-status">

                        <span class="footer-status-dot"></span>

                        Hệ thống đang hoạt động

                    </span>

                </div>


            </div>


        </main>


    </body>
</html>
