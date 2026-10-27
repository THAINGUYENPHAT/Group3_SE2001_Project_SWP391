<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/include/header.jsp" %>


<%-- Export URLs --%>
<c:url var="excelReportUrl" value="/admin/report/export">
    <c:param name="startDate" value="${startDate}" />
    <c:param name="endDate" value="${endDate}" />
    <c:param name="format" value="excel" />
</c:url>

<c:url var="pdfReportUrl" value="/admin/report/export">
    <c:param name="startDate" value="${startDate}" />
    <c:param name="endDate" value="${endDate}" />
    <c:param name="format" value="pdf" />
</c:url>

<%-- Flatpickr: display DD/MM/YYYY, submit YYYY-MM-DD --%>
<link rel="stylesheet"
      href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">

<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
<script src="https://cdn.jsdelivr.net/npm/flatpickr/dist/l10n/vn.js"></script>

<style>
    /* =====================================
       OECS REPORT
       Scope CSS to avoid header/footer conflicts
       ===================================== */

    .oecs-report {
        --rp-primary: #2563eb;
        --rp-dark: #0f172a;
        --rp-text: #334155;
        --rp-muted: #64748b;
        --rp-border: #e2e8f0;

        width: 100%;
        padding: 28px 0 44px;
        font-family: "Inter", sans-serif;
        color: var(--rp-text);
    }

    .oecs-report *,
    .oecs-report *::before,
    .oecs-report *::after {
        box-sizing: border-box;
    }

    /* PAGE TITLE */

    .oecs-report .rp-heading {
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 20px;
        margin-bottom: 26px;
    }

    .oecs-report .rp-eyebrow {
        margin-bottom: 9px;
        font-size: 11px;
        font-weight: 800;
        letter-spacing: 1.4px;
        color: #2563eb;
    }

    .oecs-report .rp-heading h1 {
        margin: 0;
        font-size: 30px;
        font-weight: 800;
        letter-spacing: -.7px;
        color: #0f172a;
    }

    .oecs-report .rp-heading p {
        margin: 9px 0 0;
        font-size: 13px;
        color: #64748b;
    }

    .oecs-report .rp-heading-badge {
        display: inline-flex;
        align-items: center;
        gap: 9px;
        padding: 12px 16px;
        background: #eff6ff;
        border: 1px solid #bfdbfe;
        border-radius: 10px;
        color: #1d4ed8;
        font-size: 12px;
        font-weight: 700;
    }

    /* CARD */

    .oecs-report .rp-card {
        background: #fff;
        border: 1px solid var(--rp-border);
        border-radius: 15px;
        box-shadow: 0 4px 15px rgba(15, 23, 42, .035);
        min-width: 0;
    }

    /* SECTION HEADER */

    .oecs-report .rp-section-icon {
        width: 43px;
        height: 43px;
        flex-shrink: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #eff6ff;
        color: #2563eb;
        border-radius: 11px;
        font-size: 19px;
    }

    .oecs-report .rp-section-info h2 {
        margin: 0;
        font-size: 16px;
        font-weight: 750;
        color: #0f172a;
    }

    .oecs-report .rp-section-info p {
        margin: 5px 0 0;
        color: #94a3b8;
        font-size: 12px;
    }

    /* FILTER */

    .oecs-report .rp-filter {
        padding: 25px 28px;
        margin-bottom: 23px;
        position: relative;
        z-index: 20;
        overflow: visible;
    }

    .oecs-report .rp-filter-top {
        display: flex;
        align-items: center;
        gap: 14px;
        margin-bottom: 26px;
    }

    .oecs-report .rp-filter-form {
        display: flex;
        align-items: flex-end;
        gap: 15px;
        flex-wrap: wrap;
    }

    .oecs-report .rp-date-field {
        width: 270px;
        max-width: 100%;
    }

    .oecs-report .rp-date-field label {
        display: block;
        margin-bottom: 9px;
        color: #334155;
        font-weight: 700;
        font-size: 12px;
    }

    .oecs-report .rp-date-input {
        display: block;
        width: 100%;
        height: 49px;
        padding: 0 15px;
        color: #334155;
        background: #fff;
        border: 1px solid #cbd5e1;
        border-radius: 10px;
        font-family: inherit;
        font-size: 13px;
        cursor: pointer;
        transition: .2s;
    }

    .oecs-report .rp-date-input:focus {
        outline: none;
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, .10);
    }

    .oecs-report .rp-filter-actions {
        margin-left: auto;
        display: flex;
        align-items: center;
        gap: 11px;
    }

    .oecs-report .rp-btn {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 9px;
        height: 49px;
        padding: 0 20px;
        border-radius: 10px;
        font-size: 12px;
        font-weight: 750;
        font-family: inherit;
        white-space: nowrap;
        cursor: pointer;
        transition: .2s;
    }

    .oecs-report .rp-btn-primary {
        background: #2563eb;
        border: 1px solid #2563eb;
        color: #fff;
    }

    .oecs-report .rp-btn-primary:hover {
        background: #1d4ed8;
        border-color: #1d4ed8;
        color: #fff;
    }

    .oecs-report .rp-btn-outline {
        background: #fff;
        border: 1px solid #cbd5e1;
        color: #334155;
    }

    .oecs-report .rp-btn-outline:hover {
        background: #f8fafc;
        border-color: #93c5fd;
        color: #1d4ed8;
    }

    /* EXPORT DROPDOWN */

    .oecs-report .rp-export-wrap {
        position: relative;
    }

    .oecs-report .rp-export-menu {
        display: none;
        position: absolute;
        right: 0;
        top: calc(100% + 9px);
        width: 205px;
        padding: 7px;
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 11px;
        box-shadow: 0 16px 35px rgba(15, 23, 42, .13);
        z-index: 100;
    }

    .oecs-report .rp-export-menu.show {
        display: block;
    }

    .oecs-report .rp-export-menu a {
        display: flex;
        align-items: center;
        gap: 11px;
        padding: 12px;
        border-radius: 8px;
        text-decoration: none;
        font-size: 12px;
        font-weight: 650;
        color: #334155;
    }

    .oecs-report .rp-export-menu a:hover {
        background: #f1f5f9;
    }

    .oecs-report .rp-export-menu
    .bi-file-earmark-excel {
        color: #16a34a;
        font-size: 17px;
    }

    .oecs-report .rp-export-menu
    .bi-file-earmark-pdf {
        color: #dc2626;
        font-size: 17px;
    }

    /* FILTER ERROR */

    .oecs-report .rp-error {
        display: flex;
        align-items: center;
        gap: 10px;
        margin-top: 18px;
        padding: 13px 15px;
        background: #fef2f2;
        border: 1px solid #fecaca;
        border-radius: 10px;
        color: #b91c1c;
        font-size: 12px;
        font-weight: 650;
    }

    /* KPI */

    .oecs-report .rp-kpi-grid {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 18px;
        margin-bottom: 23px;
    }

    .oecs-report .rp-kpi {
        min-width: 0;
        padding: 24px 23px;
        position: relative;
        overflow: hidden;
        transition: transform .2s, box-shadow .2s;
    }

    .oecs-report .rp-kpi:hover {
        transform: translateY(-3px);
        box-shadow: 0 10px 24px rgba(15, 23, 42, .07);
    }

    .oecs-report .rp-kpi::before {
        content: "";
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        height: 3px;
        background: var(--kpi-color);
    }

    .oecs-report .rp-kpi-top {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 10px;
        margin-bottom: 22px;
    }

    .oecs-report .rp-kpi-label {
        font-size: 12px;
        font-weight: 650;
        color: #64748b;
    }

    .oecs-report .rp-kpi-icon {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 49px;
        height: 49px;
        flex-shrink: 0;
        border-radius: 12px;
        background: var(--kpi-bg);
        color: var(--kpi-color);
        font-size: 21px;
    }

    .oecs-report .rp-kpi-value {
        color: #0f172a;
        font-size: clamp(20px, 1.9vw, 29px);
        font-weight: 800;
        letter-spacing: -.6px;
        overflow-wrap: anywhere;
    }

    .oecs-report .rp-kpi-unit {
        margin-top: 9px;
        font-size: 11px;
        color: #94a3b8;
    }

    .oecs-report .rp-kpi-revenue {
        --kpi-color: #2563eb;
        --kpi-bg: #eff6ff;
    }

    .oecs-report .rp-kpi-orders {
        --kpi-color: #16a34a;
        --kpi-bg: #f0fdf4;
    }

    .oecs-report .rp-kpi-products {
        --kpi-color: #9333ea;
        --kpi-bg: #faf5ff;
    }

    .oecs-report .rp-kpi-aov {
        --kpi-color: #ea580c;
        --kpi-bg: #fff7ed;
    }

    /* REPORT PANELS */

    .oecs-report .rp-panel {
        margin-bottom: 23px;
        overflow: hidden;
    }

    .oecs-report .rp-panel-header {
        padding: 24px 26px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-wrap: wrap;
        gap: 16px;
        border-bottom: 1px solid #edf2f7;
    }

    .oecs-report .rp-panel-title {
        display: flex;
        align-items: center;
        gap: 14px;
    }

    .oecs-report .rp-period {
        display: inline-flex;
        align-items: center;
        gap: 9px;
        background: #f1f5f9;
        padding: 9px 13px;
        border-radius: 9px;
        color: #64748b;
        font-size: 11px;
        font-weight: 700;
        white-space: nowrap;
    }

    /* DAILY REVENUE TABLE */

    .oecs-report .rp-table-wrap {
        width: 100%;
        overflow-x: auto;
    }

    .oecs-report .rp-table {
        width: 100%;
        border-collapse: collapse;
    }

    .oecs-report .rp-table th {
        padding: 15px 25px;
        background: #f8fafc;
        border-bottom: 1px solid #e2e8f0;
        font-size: 11px;
        font-weight: 750;
        letter-spacing: .4px;
        text-transform: uppercase;
        color: #64748b;
        white-space: nowrap;
    }

    .oecs-report .rp-table td {
        padding: 17px 25px;
        border-bottom: 1px solid #f1f5f9;
        color: #334155;
        font-size: 13px;
    }

    .oecs-report .rp-table tbody tr:hover {
        background: #f8fbff;
    }

    .oecs-report .rp-date {
        font-weight: 700;
        color: #334155;
    }

    .oecs-report .rp-money {
        font-weight: 800;
        color: #0f172a;
        white-space: nowrap;
    }

    .oecs-report .rp-count {
        display: inline-flex;
        justify-content: center;
        min-width: 37px;
        padding: 7px 11px;
        border-radius: 8px;
        background: #eff6ff;
        color: #2563eb;
        font-weight: 800;
        font-size: 12px;
    }

    .oecs-report .rp-table-summary {
        padding: 19px 25px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-wrap: wrap;
        gap: 12px;
        background: #f8fafc;
        border-top: 1px solid #e2e8f0;
    }

    .oecs-report .rp-summary-label {
        color: #64748b;
        font-size: 12px;
        font-weight: 650;
    }

    .oecs-report .rp-summary-value {
        color: #2563eb;
        font-size: 18px;
        font-weight: 800;
    }

    /* STATUS + TOP PRODUCTS */

    .oecs-report .rp-analytics-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 23px;
    }

    .oecs-report .rp-analytics-grid .rp-panel {
        margin-bottom: 0;
    }

    .oecs-report .rp-analytics-body {
        padding: 26px;
        min-height: 235px;
    }

    /* STATUS BARS */

    .oecs-report .rp-status-item {
        margin-bottom: 21px;
    }

    .oecs-report .rp-status-item:last-child {
        margin-bottom: 0;
    }

    .oecs-report .rp-status-top {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 10px;
        margin-bottom: 10px;
    }

    .oecs-report .rp-status-name {
        display: inline-flex;
        align-items: center;
        gap: 9px;
        color: #475569;
        font-size: 12px;
        font-weight: 650;
    }

    .oecs-report .rp-dot {
        display: inline-block;
        width: 9px;
        height: 9px;
        flex-shrink: 0;
        border-radius: 50%;
        background: var(--dot-color, #94a3b8);
    }

    .oecs-report .rp-status-numbers {
        display: flex;
        align-items: center;
        gap: 9px;
        font-size: 12px;
        font-weight: 800;
    }

    .oecs-report .rp-percent {
        color: #94a3b8;
        font-size: 11px;
        font-weight: 650;
    }

    .oecs-report .rp-progress,
    .oecs-report .rp-product-bar {
        width: 100%;
        height: 8px;
        background: #f1f5f9;
        overflow: hidden;
        border-radius: 20px;
    }

    .oecs-report .rp-progress-fill {
        height: 100%;
        width: 0;
        background: var(--bar-color, #2563eb);
        border-radius: inherit;
        transition: width .4s ease;
    }

    /* TOP PRODUCTS */

    .oecs-report .rp-product-item {
        display: flex;
        align-items: flex-start;
        gap: 14px;
        margin-bottom: 22px;
    }

    .oecs-report .rp-product-item:last-child {
        margin-bottom: 0;
    }

    .oecs-report .rp-rank {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 33px;
        height: 33px;
        flex-shrink: 0;
        border-radius: 9px;
        background: #f1f5f9;
        color: #64748b;
        font-size: 12px;
        font-weight: 800;
    }

    .oecs-report .rp-rank-first {
        background: #fef3c7;
        color: #b45309;
    }

    .oecs-report .rp-rank-second {
        background: #e2e8f0;
        color: #475569;
    }

    .oecs-report .rp-rank-third {
        background: #ffedd5;
        color: #9a3412;
    }

    .oecs-report .rp-product-info {
        flex: 1;
        min-width: 0;
    }

    .oecs-report .rp-product-top {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        gap: 12px;
        margin-bottom: 11px;
    }

    .oecs-report .rp-product-name {
        color: #334155;
        font-size: 12px;
        font-weight: 700;
        line-height: 1.5;
        overflow-wrap: anywhere;
    }

    .oecs-report .rp-product-sold {
        color: #2563eb;
        font-size: 12px;
        font-weight: 800;
        white-space: nowrap;
    }

    .oecs-report .rp-product-fill {
        height: 100%;
        width: 0;
        border-radius: 20px;
        background: linear-gradient(90deg, #2563eb, #60a5fa);
        transition: width .4s ease;
    }

    /* EMPTY STATES */

    .oecs-report .rp-empty {
        padding: 55px 18px;
        text-align: center;
        color: #94a3b8;
        font-size: 12px;
        line-height: 1.7;
    }

    .oecs-report .rp-empty i {
        display: block;
        margin-bottom: 13px;
        color: #cbd5e1;
        font-size: 32px;
    }

    /* INFORMATION NOTE */

    .oecs-report .rp-note {
        display: flex;
        gap: 10px;
        align-items: flex-start;
        margin-top: 25px;
        padding: 17px 19px;
        border: 1px solid #dbeafe;
        border-radius: 11px;
        background: #eff6ff;
        color: #64748b;
        font-size: 12px;
        line-height: 1.8;
    }

    .oecs-report .rp-note i {
        color: #2563eb;
        font-size: 16px;
    }

    /* =====================================
       FLATPICKR FIX
       Keep calendar clickable after filtering
       ===================================== */

    .oecs-report .rp-date-input,
    .oecs-report input.flatpickr-input {
        cursor: pointer !important;
        background: #fff !important;
    }

    .flatpickr-calendar {
        z-index: 99999 !important;
        font-family: "Inter", sans-serif;
    }

    .flatpickr-calendar.open {
        visibility: visible;
        pointer-events: auto;
    }

    .flatpickr-day.selected,
    .flatpickr-day.selected:hover {
        background: #2563eb;
        border-color: #2563eb;
    }

    /* RESPONSIVE */

    @media (max-width: 1200px) {
        .oecs-report .rp-kpi-grid {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }
    }

    @media (max-width: 950px) {
        .oecs-report .rp-analytics-grid {
            grid-template-columns: 1fr;
        }

        .oecs-report .rp-filter-actions {
            margin-left: 0;
        }

        .oecs-report .rp-date-field {
            flex: 1 1 200px;
        }
    }

    @media (max-width: 576px) {
        .oecs-report {
            padding-top: 20px;
        }

        .oecs-report .rp-heading h1 {
            font-size: 24px;
        }

        .oecs-report .rp-heading-badge {
            display: none;
        }

        .oecs-report .rp-filter {
            padding: 20px 16px;
        }

        .oecs-report .rp-filter-form {
            flex-direction: column;
            align-items: stretch;
        }

        .oecs-report .rp-date-field {
            flex: none;
            width: 100%;
        }

        .oecs-report .rp-filter-actions {
            width: 100%;
            display: grid;
            grid-template-columns: 1fr 1fr;
        }

        .oecs-report .rp-btn {
            padding: 0 10px;
            width: 100%;
        }

        .oecs-report .rp-kpi-grid {
            grid-template-columns: 1fr;
            gap: 13px;
        }

        .oecs-report .rp-kpi {
            padding: 21px;
        }

        .oecs-report .rp-panel-header {
            padding: 19px 16px;
        }

        .oecs-report .rp-analytics-body {
            padding: 20px 16px;
        }

        .oecs-report .rp-table th,
        .oecs-report .rp-table td {
            padding: 13px 16px;
        }
    }
</style>

<!-- =====================================
     REPORT PAGE
     ===================================== -->

<div class="container-fluid oecs-report px-3 px-lg-4">

    <!-- PAGE HEADING -->

    <div class="rp-heading">
        <div>
            <div class="rp-eyebrow">
                OECS / ADMINISTRATION
            </div>

            <h1>Reporting System</h1>

            <p>
                Tổng hợp doanh thu, hiệu quả bán hàng
                và tình trạng đơn hàng trong hệ thống.
            </p>
        </div>

        <div class="rp-heading-badge">
            <i class="bi bi-bar-chart-line-fill"></i>
            Business Analytics
        </div>
    </div>

    <!-- =====================================
         DATE FILTER
         ===================================== -->

    <section class="rp-card rp-filter">

        <div class="rp-filter-top">
            <div class="rp-section-icon">
                <i class="bi bi-calendar3"></i>
            </div>

            <div class="rp-section-info">
                <h2>Bộ lọc báo cáo</h2>
                <p>
                    Chọn khoảng thời gian để phân tích
                    dữ liệu kinh doanh.
                </p>
            </div>
        </div>

        <form
            id="reportFilterForm"
            class="rp-filter-form"
            method="get"
            action="${pageContext.request.contextPath}/admin/report">

            <!-- START DATE -->

            <div class="rp-date-field">
                <label for="startDate">
                    Ngày bắt đầu
                </label>

                <input
                    id="startDate"
                    name="startDate"
                    class="rp-date-input"
                    type="text"
                    value="<c:out value='${startDate}' />"
                    placeholder="dd/mm/yyyy"
                    autocomplete="off"
                    required>
            </div>

            <!-- END DATE -->

            <div class="rp-date-field">
                <label for="endDate">
                    Ngày kết thúc
                </label>

                <input
                    id="endDate"
                    name="endDate"
                    class="rp-date-input"
                    type="text"
                    value="<c:out value='${endDate}' />"
                    placeholder="dd/mm/yyyy"
                    autocomplete="off"
                    required>
            </div>

            <!-- ACTION BUTTONS -->

            <div class="rp-filter-actions">

                <button
                    type="submit"
                    class="rp-btn rp-btn-primary">

                    <i class="bi bi-funnel-fill"></i>
                    Lọc báo cáo
                </button>

                <div class="rp-export-wrap">

                    <button
                        type="button"
                        id="exportButton"
                        class="rp-btn rp-btn-outline"
                        aria-expanded="false"
                        aria-controls="exportMenu">

                        <i class="bi bi-download"></i>
                        Xuất báo cáo
                        <i class="bi bi-chevron-down"></i>
                    </button>

                    <div
                        id="exportMenu"
                        class="rp-export-menu">

                        <a href="<c:out value='${excelReportUrl}' />">
                            <i class="bi bi-file-earmark-excel"></i>
                            Xuất Excel (.xlsx)
                        </a>

                        <a href="<c:out value='${pdfReportUrl}' />">
                            <i class="bi bi-file-earmark-pdf"></i>
                            Xuất PDF (.pdf)
                        </a>

                    </div>
                </div>

            </div>
        </form>

        <div id="dateRangeError"
             class="rp-error"
             role="alert"
             style="display: none;">
            <i class="bi bi-exclamation-triangle-fill"></i>
            <span id="dateRangeErrorText"></span>
        </div>


        <c:if test="${not empty filterError}">
            <div class="rp-error" role="alert">
                <i class="bi bi-exclamation-triangle-fill"></i>
                <c:out value="${filterError}" />
            </div>
        </c:if>

    </section>

    <!-- =====================================
         KPI CARDS
         ===================================== -->

    <section class="rp-kpi-grid">

        <!-- REVENUE -->

        <div class="rp-card rp-kpi rp-kpi-revenue">

            <div class="rp-kpi-top">
                <span class="rp-kpi-label">
                    Tổng doanh thu
                </span>

                <span class="rp-kpi-icon">
                    <i class="bi bi-currency-dollar"></i>
                </span>
            </div>

            <div class="rp-kpi-value">
                <span class="js-money"
                      data-money="${totalRevenue}">
                    ${totalRevenue}
                </span>
            </div>

            <div class="rp-kpi-unit">
                VNĐ · Đơn hàng hoàn thành
            </div>

        </div>

        <!-- COMPLETED ORDERS -->

        <div class="rp-card rp-kpi rp-kpi-orders">

            <div class="rp-kpi-top">
                <span class="rp-kpi-label">
                    Đơn hàng hoàn thành
                </span>

                <span class="rp-kpi-icon">
                    <i class="bi bi-bag-check"></i>
                </span>
            </div>

            <div class="rp-kpi-value">
                <span class="js-number"
                      data-number="${completedOrders}">
                    ${completedOrders}
                </span>
            </div>

            <div class="rp-kpi-unit">
                Đơn hàng · COMPLETED
            </div>

        </div>

        <!-- PRODUCTS SOLD -->

        <div class="rp-card rp-kpi rp-kpi-products">

            <div class="rp-kpi-top">
                <span class="rp-kpi-label">
                    Sản phẩm đã bán
                </span>

                <span class="rp-kpi-icon">
                    <i class="bi bi-box-seam"></i>
                </span>
            </div>

            <div class="rp-kpi-value">
                <span class="js-number"
                      data-number="${totalProductsSold}">
                    ${totalProductsSold}
                </span>
            </div>

            <div class="rp-kpi-unit">
                Tổng số lượng sản phẩm
            </div>

        </div>

        <!-- AOV -->

        <div class="rp-card rp-kpi rp-kpi-aov">

            <div class="rp-kpi-top">
                <span class="rp-kpi-label">
                    Giá trị đơn trung bình
                </span>

                <span class="rp-kpi-icon">
                    <i class="bi bi-graph-up-arrow"></i>
                </span>
            </div>

            <div class="rp-kpi-value">
                <span class="js-money"
                      data-money="${averageOrderValue}">
                    ${averageOrderValue}
                </span>
            </div>

            <div class="rp-kpi-unit">
                VNĐ / đơn · AOV
            </div>

        </div>

    </section>

    <!-- =====================================
         DAILY REVENUE
         ===================================== -->

    <section class="rp-card rp-panel">

        <div class="rp-panel-header">

            <div class="rp-panel-title">

                <div class="rp-section-icon">
                    <i class="bi bi-calendar2-week"></i>
                </div>

                <div class="rp-section-info">
                    <h2>Doanh thu theo ngày</h2>

                    <p>
                        Chi tiết doanh thu từ đơn hàng
                        đã hoàn thành
                    </p>
                </div>

            </div>

            <div class="rp-period">

                <i class="bi bi-calendar-range"></i>

                <span class="js-display-date">
                    <c:out value="${startDate}" />
                </span>

                <i class="bi bi-arrow-right"></i>

                <span class="js-display-date">
                    <c:out value="${endDate}" />
                </span>

            </div>

        </div>

        <div class="rp-table-wrap">

            <table class="rp-table">

                <thead>
                    <tr>
                    <th>Ngày giao dịch</th>
                    <th class="text-end">Số đơn hàng</th>
                    <th class="text-end">Doanh thu</th>
                    </tr>
                </thead>

                <tbody>

                    <c:choose>

                        <c:when test="${not empty revenueByDate}">

                            <c:forEach
                                var="row"
                                items="${revenueByDate}">

                                <tr>

                                <td>
                                <span class="rp-date">

                                    <i class="bi bi-calendar3 me-2"
                                       style="color:#94a3b8;"></i>

                                    <span class="js-display-date">
                                        <c:out value="${row[0]}" />
                                    </span>

                                </span>
                                </td>

                                <td class="text-end">

                                <span class="rp-count">

                                    <span class="js-number"
                                          data-number="${row[2]}">
                                        ${row[2]}
                                    </span>

                                </span>
                                </td>

                                <td class="text-end">

                                <span class="rp-money">

                                    <span class="js-money"
                                          data-money="${row[1]}">
                                        ${row[1]}
                                    </span>

                                    VNĐ

                                </span>

                                </td>

                                </tr>

                            </c:forEach>

                        </c:when>

                        <c:otherwise>

                            <tr>
                            <td colspan="3">

                                <div class="rp-empty">

                                    <i class="bi bi-inbox"></i>

                                    Không có doanh thu trong
                                    khoảng thời gian đã chọn.

                                </div>

                            </td>
                            </tr>

                        </c:otherwise>

                    </c:choose>

                </tbody>

            </table>

        </div>

        <div class="rp-table-summary">

            <span class="rp-summary-label">

                <i class="bi bi-calculator me-2"></i>

                Tổng doanh thu trong kỳ

            </span>

            <span class="rp-summary-value">

                <span class="js-money"
                      data-money="${totalRevenue}">
                    ${totalRevenue}
                </span>

                VNĐ

            </span>

        </div>

    </section>

    <!-- =====================================
         ANALYTICS
         ===================================== -->

    <div class="rp-analytics-grid">

        <!-- ORDER STATUS -->

        <section class="rp-card rp-panel">

            <div class="rp-panel-header">

                <div class="rp-panel-title">

                    <div class="rp-section-icon">
                        <i class="bi bi-pie-chart"></i>
                    </div>

                    <div class="rp-section-info">

                        <h2>Phân tích trạng thái đơn hàng</h2>

                        <p>
                            Tỷ trọng đơn theo trạng thái hiện tại
                        </p>

                    </div>

                </div>

            </div>

            <div class="rp-analytics-body"
                 id="reportStatusList">

                <c:choose>

                    <c:when test="${not empty orderStatusStats}">

                        <c:forEach
                            var="row"
                            items="${orderStatusStats}">

                            <c:set var="statusColor"
                                   value="#64748b" />

                            <c:set var="statusName"
                                   value="${row[0]}" />

                            <c:choose>

                                <c:when test="${row[0] eq 'COMPLETED'}">

                                    <c:set var="statusColor"
                                           value="#16a34a" />

                                    <c:set var="statusName"
                                           value="Hoàn thành" />

                                </c:when>

                                <c:when test="${row[0] eq 'CANCELLED'}">

                                    <c:set var="statusColor"
                                           value="#ef4444" />

                                    <c:set var="statusName"
                                           value="Đã hủy" />

                                </c:when>

                                <c:when test="${row[0] eq 'PENDING_CONFIRMATION'}">

                                    <c:set var="statusColor"
                                           value="#f59e0b" />

                                    <c:set var="statusName"
                                           value="Chờ xác nhận" />

                                </c:when>

                                <c:when test="${row[0] eq 'CONFIRMED'}">

                                    <c:set var="statusColor"
                                           value="#2563eb" />

                                    <c:set var="statusName"
                                           value="Đã xác nhận" />

                                </c:when>

                                <c:when test="${row[0] eq 'PACKING'}">

                                    <c:set var="statusColor"
                                           value="#8b5cf6" />

                                    <c:set var="statusName"
                                           value="Đang đóng gói" />

                                </c:when>

                                <c:when test="${row[0] eq 'SHIPPING'}">

                                    <c:set var="statusColor"
                                           value="#06b6d4" />

                                    <c:set var="statusName"
                                           value="Đang giao hàng" />

                                </c:when>

                            </c:choose>

                            <div class="rp-status-item"
                                 data-status-count="${row[1]}">

                                <div class="rp-status-top">

                                    <span class="rp-status-name">

                                        <span class="rp-dot"
                                              style="--dot-color:${statusColor};">
                                        </span>

                                        <c:out value="${statusName}" />

                                    </span>

                                    <span class="rp-status-numbers">

                                        <span class="js-number"
                                              data-number="${row[1]}">
                                            ${row[1]}
                                        </span>

                                        <span class="rp-percent">
                                            0%
                                        </span>

                                    </span>

                                </div>

                                <div class="rp-progress">

                                    <div class="rp-progress-fill"
                                         style="--bar-color:${statusColor};">
                                    </div>

                                </div>

                            </div>

                        </c:forEach>

                    </c:when>

                    <c:otherwise>

                        <div class="rp-empty">

                            <i class="bi bi-pie-chart"></i>

                            Chưa có đơn hàng để phân tích
                            trong khoảng thời gian này.

                        </div>

                    </c:otherwise>

                </c:choose>

            </div>

        </section>

        <!-- TOP 5 PRODUCTS -->

        <section class="rp-card rp-panel">

            <div class="rp-panel-header">

                <div class="rp-panel-title">

                    <div class="rp-section-icon">
                        <i class="bi bi-trophy"></i>
                    </div>

                    <div class="rp-section-info">

                        <h2>Top 5 sản phẩm bán chạy</h2>

                        <p>
                            Xếp hạng theo tổng số lượng đã bán
                        </p>

                    </div>

                </div>

            </div>

            <div class="rp-analytics-body"
                 id="reportTopProducts">

                <c:choose>

                    <c:when test="${not empty topSellingProducts}">

                        <c:forEach
                            var="row"
                            items="${topSellingProducts}"
                            varStatus="loop">

                            <div class="rp-product-item"
                                 data-product-sold="${row[1]}">

                                <div class="rp-rank
                                     ${loop.index == 0 ? 'rp-rank-first' : ''}
                                     ${loop.index == 1 ? 'rp-rank-second' : ''}
                                     ${loop.index == 2 ? 'rp-rank-third' : ''}">

                                    ${loop.index + 1}

                                </div>

                                <div class="rp-product-info">

                                    <div class="rp-product-top">

                                        <span class="rp-product-name">
                                            <c:out value="${row[0]}" />
                                        </span>

                                        <span class="rp-product-sold">

                                            <span class="js-number"
                                                  data-number="${row[1]}">
                                                ${row[1]}
                                            </span>

                                            đã bán

                                        </span>

                                    </div>

                                    <div class="rp-product-bar">

                                        <div class="rp-product-fill">
                                        </div>

                                    </div>

                                </div>

                            </div>

                        </c:forEach>

                    </c:when>

                    <c:otherwise>

                        <div class="rp-empty">

                            <i class="bi bi-box-seam"></i>

                            Chưa có sản phẩm bán ra
                            trong khoảng thời gian này.

                        </div>

                    </c:otherwise>

                </c:choose>

            </div>

        </section>

    </div>

    <!-- REPORT NOTE -->

    <div class="rp-note">

        <i class="bi bi-info-circle-fill"></i>

        <span>

            <strong>Thông tin báo cáo:</strong>

            Dữ liệu được lọc theo ngày tạo đơn hàng
            (<strong>created_at</strong>).

            Doanh thu, AOV và sản phẩm bán ra chỉ tính
            các đơn có trạng thái
            <strong>COMPLETED</strong>.

            Thống kê trạng thái bao gồm tất cả đơn hàng
            được tạo trong khoảng thời gian đã chọn.

        </span>

    </div>

</div>

<!-- =====================================
     REPORT JAVASCRIPT
     ===================================== -->

<script>
    (function () {

        function initReportPage() {

            const reportPage =
                    document.querySelector(".oecs-report");

            if (!reportPage || reportPage.dataset.initialized === "true") {
                return;
            }

            reportPage.dataset.initialized = "true";

            const filterForm =
                    document.getElementById("reportFilterForm");

            const startInput =
                    document.getElementById("startDate");

            const endInput =
                    document.getElementById("endDate");

            const exportButton =
                    document.getElementById("exportButton");

            const exportMenu =
                    document.getElementById("exportMenu");

            const hasServerFilterError =
    ${not empty filterError};

            // =====================================
            // 1. INITIALIZE DATE PICKERS
            // =====================================

            if (typeof flatpickr === "function") {

                const datePickerOptions = {

                    // Value sent to Java Servlet
                    dateFormat: "Y-m-d",

                    // Show date as DD/MM/YYYY
                    altInput: true,
                    altInputClass: "rp-date-input",
                    altFormat: "d/m/Y",

                    allowInput: false,
                    clickOpens: true,
                    disableMobile: true,

                    locale: flatpickr.l10ns.vn || "default",

                    // Calendar outside cards to avoid clipping
                    appendTo: document.body,

                    onReady: function (
                            selectedDates,
                            dateStr,
                            instance) {

                        if (instance.altInput) {

                            instance.altInput.style.cursor = "pointer";

                            instance.altInput.addEventListener(
                                    "click",
                                    function () {
                                        instance.open();
                                    }
                            );

                        }
                    }
                };

                // Initialize once per input.
                // On every new GET request, JSP renders new inputs.
                if (!startInput._flatpickr) {
                    flatpickr(startInput, datePickerOptions);
                }

                if (!endInput._flatpickr) {
                    flatpickr(endInput, datePickerOptions);
                }

            } else {
                console.warn(
                        "Flatpickr could not be loaded. Date picker unavailable."
                        );
            }

            // =====================================
            // 2. ORIGINAL FILTERED DATES
            // =====================================

            // Original inputs retain Y-m-d values.
            const loadedStart = startInput.value;
            const loadedEnd = endInput.value;

            // =====================================
            // 3. FORMAT MONEY AND NUMBERS
            // =====================================

            const numberFormatter = new Intl.NumberFormat(
                    "vi-VN",
                    {
                        maximumFractionDigits: 0
                    }
            );

            reportPage.querySelectorAll(".js-money")
                    .forEach(function (element) {

                        const value =
                                Number(element.dataset.money);

                        if (Number.isFinite(value)) {

                            element.textContent =
                                    numberFormatter.format(value);

                        }
                    });

            reportPage.querySelectorAll(".js-number")
                    .forEach(function (element) {

                        const value =
                                Number(element.dataset.number);

                        if (Number.isFinite(value)) {

                            element.textContent =
                                    numberFormatter.format(value);

                        }
                    });

            // =====================================
            // 4. FORMAT DISPLAYED DATES
            // =====================================

            function formatDisplayDate(isoDate) {

                if (!isoDate) {
                    return "";
                }

                const value = isoDate.trim().substring(0, 10);

                const parts = value.split("-");

                if (parts.length !== 3) {
                    return isoDate;
                }

                return parts[2] + "/"
                        + parts[1] + "/"
                        + parts[0];
            }

            reportPage.querySelectorAll(".js-display-date")
                    .forEach(function (element) {

                        element.textContent =
                                formatDisplayDate(element.textContent);

                    });

            // =====================================
            // 5. VALIDATE DATE RANGE
            // =====================================


            function validateDateRange() {

                const startDate = startInput.value;
                const endDate = endInput.value;

                const errorBox =
                        document.getElementById("dateRangeError");

                const errorText =
                        document.getElementById("dateRangeErrorText");

                if (!startDate || !endDate) {
                    errorText.textContent =
                            "Vui lòng chọn đầy đủ ngày bắt đầu và ngày kết thúc.";

                    errorBox.style.display = "flex";
                    return false;
                }

                if (startDate > endDate) {
                    errorText.textContent =
                            "Ngày bắt đầu không được lớn hơn ngày kết thúc. Vui lòng chọn lại.";

                    errorBox.style.display = "flex";
                    return false;
                }

                errorBox.style.display = "none";
                return true;
            }


            function clearDateError() {
                document.getElementById("dateRangeError")
                        .style.display = "none";
            }

            [startInput, endInput].forEach(function (input) {
                input.addEventListener("change", clearDateError);
            });



            // =====================================
            // 6. SUBMIT FILTER
            // =====================================

            filterForm.addEventListener(
                    "submit",
                    function (event) {

                        if (!validateDateRange()) {
                            event.preventDefault();
                        }

                    }
            );

            // =====================================
            // 7. EXPORT MENU
            // =====================================

            function closeExportMenu() {

                exportMenu.classList.remove("show");

                exportButton.setAttribute(
                        "aria-expanded",
                        "false"
                        );
            }

            exportButton.addEventListener(
                    "click",
                    function (event) {

                        event.stopPropagation();

                        if (!validateDateRange()) {
                            closeExportMenu();
                            return;
                        }

                        // Prevent exporting an old filtered range
                        if (
                                hasServerFilterError ||
                                startInput.value !== loadedStart ||
                                endInput.value !== loadedEnd
                                ) {

                            closeExportMenu();

                            alert(
                                    "Vui lòng nhấn Lọc báo cáo trước khi xuất file."
                                    );

                            return;
                        }

                        const isOpen =
                                exportMenu.classList.toggle("show");

                        exportButton.setAttribute(
                                "aria-expanded",
                                String(isOpen)
                                );

                    }
            );

            exportMenu.addEventListener(
                    "click",
                    function (event) {
                        event.stopPropagation();
                    }
            );

            document.addEventListener(
                    "click",
                    closeExportMenu
                    );

            document.addEventListener(
                    "keydown",
                    function (event) {

                        if (event.key === "Escape") {
                            closeExportMenu();
                        }

                    }
            );

            // =====================================
            // 8. ORDER STATUS PROGRESS
            // =====================================

            const statusItems = Array.from(
                    reportPage.querySelectorAll(".rp-status-item")
                    );

            let totalOrders = 0;

            statusItems.forEach(function (item) {

                const count =
                        Number(item.dataset.statusCount) || 0;

                totalOrders += count;

            });

            statusItems.forEach(function (item) {

                const count =
                        Number(item.dataset.statusCount) || 0;

                const percent = totalOrders > 0
                        ? (count / totalOrders) * 100
                        : 0;

                const progress =
                        item.querySelector(".rp-progress-fill");

                const label =
                        item.querySelector(".rp-percent");

                if (progress) {
                    progress.style.width = percent + "%";
                }

                if (label) {
                    label.textContent =
                            percent.toFixed(1) + "%";
                }

            });

            // =====================================
            // 9. TOP PRODUCTS BARS
            // =====================================

            const productItems = Array.from(
                    reportPage.querySelectorAll(".rp-product-item")
                    );

            let maxSold = 0;

            productItems.forEach(function (item) {

                const sold =
                        Number(item.dataset.productSold) || 0;

                if (sold > maxSold) {
                    maxSold = sold;
                }

            });

            productItems.forEach(function (item) {

                const sold =
                        Number(item.dataset.productSold) || 0;

                const percent = maxSold > 0
                        ? (sold / maxSold) * 100
                        : 0;

                const bar =
                        item.querySelector(".rp-product-fill");

                if (bar) {
                    bar.style.width = percent + "%";
                }

            });

        }

        // Works whether the script loads before or after
        // DOMContentLoaded.
        if (document.readyState === "loading") {

            document.addEventListener(
                    "DOMContentLoaded",
                    initReportPage
                    );

        } else {

            initReportPage();

        }

    })();
</script>

<%@ include file="/WEB-INF/include/footer.jsp" %>
