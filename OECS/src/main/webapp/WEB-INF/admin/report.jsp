<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>

<html>
    <head>
        <meta charset="UTF-8">
        <title>OECS - Reporting System</title>


        <style>
            * {
                box-sizing: border-box;
            }

            body {
                margin: 0;
                font-family: Arial, Helvetica, sans-serif;
                background: #f4f6f9;
                color: #172033;
            }

            /* ================= HEADER ================= */

            .top-header {
                height: 76px;
                background: #111827;
                color: white;
                display: flex;
                align-items: center;
                justify-content: space-between;
                padding: 0 42px;
            }

            .brand {
                display: flex;
                align-items: center;
                gap: 13px;
            }

            .brand-icon {
                width: 42px;
                height: 42px;
                border-radius: 10px;
                background: #1677ff;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 20px;
                font-weight: bold;
            }

            .brand-name {
                font-size: 21px;
                font-weight: 700;
                letter-spacing: .5px;
            }

            .brand-sub {
                margin-top: 2px;
                font-size: 11px;
                color: #9ca9bd;
                letter-spacing: 1.5px;
            }

            .system-status {
                display: flex;
                align-items: center;
                gap: 8px;
                color: #cbd5e1;
                font-size: 13px;
            }

            .status-dot {
                width: 8px;
                height: 8px;
                border-radius: 50%;
                background: #22c55e;
            }

            /* ================= PAGE ================= */

            .page {
                max-width: 1450px;
                margin: 0 auto;
                padding: 28px 35px 40px;
            }

            .page-title {
                display: flex;
                align-items: center;
                justify-content: space-between;
                margin-bottom: 22px;
            }

            .page-title h1 {
                margin: 0;
                font-size: 28px;
                color: #172033;
            }

            .page-title p {
                margin: 6px 0 0;
                color: #748198;
                font-size: 14px;
            }

            .page-badge {
                background: #eaf2ff;
                color: #1677ff;
                padding: 9px 15px;
                border-radius: 9px;
                font-size: 13px;
                font-weight: 700;
            }

            /* ================= COMMON CARD ================= */

            .card {
                background: white;
                border: 1px solid #e3e8ef;
                border-radius: 12px;
                box-shadow: 0 2px 8px rgba(15, 23, 42, .035);
            }

            /* ================= FILTER ================= */

            .filter-card {
                padding: 20px 22px;
                margin-bottom: 20px;
            }

            .section-heading {
                display: flex;
                align-items: center;
                gap: 10px;
                margin-bottom: 16px;
            }

            .section-icon {
                width: 34px;
                height: 34px;
                border-radius: 8px;
                background: #edf4ff;
                color: #1677ff;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 16px;
            }

            .section-heading h2 {
                margin: 0;
                font-size: 16px;
                color: #172033;
            }

            .section-heading span {
                color: #8490a3;
                font-size: 12px;
            }

            .filter-form {
                display: flex;
                align-items: flex-end;
                gap: 14px;
                flex-wrap: wrap;
            }

            .filter-group {
                display: flex;
                flex-direction: column;
                gap: 6px;
            }

            .filter-group label {
                color: #64748b;
                font-size: 12px;
                font-weight: 600;
            }

            select,
            input[type="date"] {
                width: 100%;
                height: 40px;
                border: 1px solid #d8dee8;
                border-radius: 7px;
                background: #fff;
                color: #263449;
                padding: 0 11px;
                font-size: 13px;
            }

            select:focus,
            input[type="date"]:focus {
                outline: none;
                border-color: #1677ff;
                box-shadow: 0 0 0 2px rgba(22,119,255,.08);
            }

            .btn-filter {
                height: 40px;
                padding: 0 19px;
                border: 0;
                border-radius: 7px;
                background: #1677ff;
                color: white;
                font-size: 13px;
                font-weight: 600;
                cursor: pointer;
            }

            .btn-filter:hover {
                background: #0969e8;
            }

            .btn-filter:hover {
                background: #0969e8;
            }

            /* ================= KPI ================= */

            .kpi-grid {
                display: grid;
                grid-template-columns: repeat(3, 1fr);
                gap: 18px;
                margin-bottom: 20px;
            }

            .kpi-card {
                min-height: 108px;
                padding: 20px;
                display: flex;
                align-items: center;
                gap: 15px;
            }

            .kpi-icon {
                width: 48px;
                height: 48px;
                flex-shrink: 0;
                border-radius: 10px;
                background: #edf4ff;
                color: #1677ff;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 20px;
                font-weight: bold;
            }

            .kpi-label {
                color: #748198;
                font-size: 12px;
                margin-bottom: 5px;
            }

            .kpi-value {
                color: #172033;
                font-size: 22px;
                font-weight: 700;
            }

            .kpi-unit {
                font-size: 12px;
                color: #7b8799;
                margin-left: 3px;
            }

            /* ================= REPORT ================= */

            .report-card {
                overflow: hidden;
            }

            .report-header {
                padding: 19px 22px;
                border-bottom: 1px solid #e7ebf1;
                display: flex;
                align-items: center;
                justify-content: space-between;
            }

            .report-title {
                display: flex;
                align-items: center;
                gap: 10px;
            }

            .report-icon {
                width: 36px;
                height: 36px;
                border-radius: 8px;
                background: #edf4ff;
                color: #1677ff;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 17px;
            }

            .report-title h2 {
                margin: 0;
                font-size: 17px;
            }

            .report-title p {
                margin: 3px 0 0;
                color: #8a96a8;
                font-size: 12px;
            }

            .report-period {
                background: #f5f7fa;
                color: #66748a;
                padding: 7px 11px;
                border-radius: 7px;
                font-size: 12px;
            }

            /* ================= TABLE ================= */

            .table-wrapper {
                width: 100%;
            }

            table {
                width: 100%;
                border-collapse: collapse;
            }

            th {
                background: #f8fafc;
                color: #68768b;
                font-size: 11px;
                font-weight: 700;
                text-align: left;
                padding: 13px 22px;
                border-bottom: 1px solid #e4e9f0;
                text-transform: uppercase;
            }

            td {
                padding: 14px 22px;
                border-bottom: 1px solid #edf0f4;
                font-size: 13px;
                color: #334155;
            }

            tbody tr:hover {
                background: #fafcff;
            }

            .date {
                font-weight: 600;
                color: #263b5a;
            }

            .revenue {
                font-weight: 700;
                color: #172033;
            }

            .order-count {
                color: #64748b;
            }

            .order-badge {
                display: inline-flex;
                min-width: 30px;
                justify-content: center;
                padding: 4px 8px;
                border-radius: 6px;
                background: #f1f5f9;
                color: #475569;
                font-weight: 600;
                font-size: 12px;
            }

            /* ================= FOOTER TOTAL ================= */

            .report-footer {
                display: flex;
                align-items: center;
                justify-content: flex-end;
                gap: 8px;
                padding: 17px 22px;
                background: #fafbfd;
                border-top: 1px solid #e9edf2;
            }

            .total-label {
                color: #718096;
                font-size: 13px;
            }

            .total-value {
                color: #1677ff;
                font-size: 18px;
                font-weight: 700;
            }

            /* ================= EMPTY ================= */

            .empty {
                text-align: center;
                padding: 42px 20px !important;
                color: #8a96a8;
            }

            .empty-icon {
                font-size: 25px;
                margin-bottom: 8px;
            }

            /* ================= BOTTOM ================= */

            .footer {
                display: flex;
                align-items: center;
                justify-content: space-between;
                padding: 16px 2px 0;
                color: #8a96a8;
                font-size: 12px;
            }

            .footer-status {
                display: flex;
                align-items: center;
                gap: 7px;
            }

            .footer-dot {
                width: 7px;
                height: 7px;
                border-radius: 50%;
                background: #22c55e;
            }
            .export-buttons {
                display: flex;
                align-items: center;
                gap: 10px;
                margin-top: 14px;
            }

            .btn-excel, .btn-pdf {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                height: 40px;
                padding: 0 16px;
                border-radius: 7px;
                color: white;
                text-decoration: none;
                font-size: 13px;
                font-weight: 600;
                transition: .2s ease;
            }
            .btn-excel {
                background: #198754;
            }
            .btn-excel:hover {
                background: #157347;
            }
            .btn-pdf {
                background: #dc3545;
            }
            .btn-pdf:hover {
                background: #bb2d3b;
            }

            /* ================= RESPONSIVE ================= */

            @media (max-width: 900px) {

                .top-header {
                    padding: 0 20px;
                }

                .system-status {
                    display: none;
                }

                .page {
                    padding: 22px 18px 30px;
                }

                .page-title {
                    align-items: flex-start;
                }

                .page-title h1 {
                    font-size: 24px;
                }

                .kpi-grid {
                    grid-template-columns: 1fr;
                }

                .filter-form {
                    grid-template-columns: 1fr;
                }

                .btn-filter {
                    width: 100%;
                }

                .report-header {
                    align-items: flex-start;
                    gap: 10px;
                    flex-direction: column;
                }

                .table-wrapper {
                    overflow-x: auto;
                }

                table {
                    min-width: 650px;
                }
            }
        </style>


    </head>

    <body>

        <!-- ================= HEADER ================= -->

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
                        MANAGEMENT SYSTEM
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

            <div class="page-title">

                <div>
                    <h1>Reporting System</h1>

                    <p>
                        Theo dõi doanh thu và hiệu quả hoạt động bán hàng
                    </p>
                </div>

                <div class="page-badge">
                    📊 Báo cáo
                </div>

            </div>


            <!-- ================= FILTER ================= -->

            <section class="card filter-card">

                <div class="section-heading">

                    <div class="section-icon">
                        ⚙
                    </div>

                    <div>
                        <h2>Bộ lọc báo cáo</h2>
                        <span>Chọn khoảng thời gian cần xem</span>
                    </div>

                </div>


                <form
                    class="filter-form"
                    method="get"
                    action="${pageContext.request.contextPath}/admin/report">

                    <div class="filter-group">

                        <label for="type">
                            Loại báo cáo
                        </label>

                        <select id="type" name="type">

                            <option value="day"
                                    ${selectedType == 'day' ? 'selected' : ''}>
                                Theo ngày
                            </option>

                            <option value="week"
                                    ${selectedType == 'week' ? 'selected' : ''}>
                                Theo tuần
                            </option>

                            <option value="month"
                                    ${selectedType == 'month' ? 'selected' : ''}>
                                Theo tháng
                            </option>

                            <option value="year"
                                    ${selectedType == 'year' ? 'selected' : ''}>
                                Theo năm
                            </option>

                        </select>

                    </div>


                    <div class="filter-group">

                        <label for="date">
                            Ngày tham chiếu
                        </label>

                        <input
                            id="date"
                            type="date"
                            name="date"
                            value="${selectedDate}"
                            required>

                    </div>



                    <button
                        type="submit"
                        class="btn-filter">
                        🔍 Lọc báo cáo
                    </button>

                    <div class="export-buttons">

                        <a
                            href="${pageContext.request.contextPath}/admin/report/export?type=${selectedType}&date=${selectedDate}&format=excel"
                            class="btn-excel">
                            📥 Xuất Excel
                        </a>

                        <a
                            href="${pageContext.request.contextPath}/admin/report/export?type=${selectedType}&date=${selectedDate}&format=pdf"
                            class="btn-pdf">
                            📄 Xuất PDF
                        </a>

                    </div>


            </section>


            <!-- ================= KPI ================= -->

            <section class="kpi-grid">

                <!-- REVENUE -->

                <div class="card kpi-card">

                    <div class="kpi-icon">
                        ₫
                    </div>

                    <div>

                        <div class="kpi-label">
                            Tổng doanh thu
                        </div>

                        <div class="kpi-value">
                            ${totalRevenue}
                            <span class="kpi-unit">VNĐ</span>
                        </div>

                    </div>

                </div>


                <!-- ORDERS -->

                <div class="card kpi-card">

                    <div class="kpi-icon">
                        🛒
                    </div>

                    <div>

                        <div class="kpi-label">
                            Đơn hàng hoàn thành
                        </div>

                        <div class="kpi-value">
                            ${completedOrders}
                            <span class="kpi-unit">đơn</span>
                        </div>

                    </div>

                </div>


                <!-- PRODUCTS -->

                <div class="card kpi-card">

                    <div class="kpi-icon">
                        📦
                    </div>

                    <div>

                        <div class="kpi-label">
                            Sản phẩm đã bán
                        </div>

                        <div class="kpi-value">
                            ${totalProductsSold}
                            <span class="kpi-unit">sản phẩm</span>
                        </div>

                    </div>

                </div>

            </section>


            <!-- ================= REPORT TABLE ================= -->

            <section class="card report-card">

                <div class="report-header">

                    <div class="report-title">

                        <div class="report-icon">
                            📈
                        </div>

                        <div>

                            <h2>Báo cáo doanh thu</h2>

                            <p>
                                Dữ liệu được tính từ các đơn hàng đã hoàn thành
                            </p>

                        </div>

                    </div>


                    <div class="report-period">

                        <c:choose>

                            <c:when test="${selectedType == 'day'}">
                                Theo ngày
                            </c:when>

                            <c:when test="${selectedType == 'week'}">
                                Theo tuần
                            </c:when>

                            <c:when test="${selectedType == 'month'}">
                                Theo tháng
                            </c:when>

                            <c:when test="${selectedType == 'year'}">
                                Theo năm
                            </c:when>

                            <c:otherwise>
                                Theo ngày
                            </c:otherwise>

                        </c:choose>

                        &nbsp;•&nbsp; ${selectedDate}

                    </div>

                </div>


                <div class="table-wrapper">

                    <table>

                        <thead>

                            <tr>

                                <th>
                                    Ngày
                                </th>

                                <th>
                                    Doanh thu
                                </th>

                                <th>
                                    Số đơn hàng
                                </th>

                            </tr>

                        </thead>


                        <tbody>

                            <c:choose>

                                <c:when test="${not empty revenueByDate}">

                                    <c:forEach
                                        var="row"
                                        items="${revenueByDate}">

                                        <tr>

                                            <td class="date">
                                                ${row[0]}
                                            </td>

                                            <td class="revenue">
                                                ${row[1]} VNĐ
                                            </td>

                                            <td class="order-count">

                                                <span class="order-badge">
                                                    ${row[2]}
                                                </span>

                                            </td>

                                        </tr>

                                    </c:forEach>

                                </c:when>


                                <c:otherwise>

                                    <tr>

                                        <td
                                            colspan="3"
                                            class="empty">

                                            <div class="empty-icon">
                                                📭
                                            </div>

                                            Không có dữ liệu trong khoảng thời gian này.

                                        </td>

                                    </tr>

                                </c:otherwise>

                            </c:choose>

                        </tbody>

                    </table>

                </div>


                <!-- TOTAL -->

                <div class="report-footer">

                    <span class="total-label">
                        Tổng doanh thu:
                    </span>

                    <span class="total-value">
                        ${totalRevenue} VNĐ
                    </span>

                </div>

            </section>


            <!-- ================= FOOTER ================= -->

            <footer class="footer">

                <span>
                    OECS Reporting System
                </span>

                <span class="footer-status">

                    <span class="footer-dot"></span>

                    Hệ thống đang hoạt động

                </span>

            </footer>


        </main>

    </body>
</html>
