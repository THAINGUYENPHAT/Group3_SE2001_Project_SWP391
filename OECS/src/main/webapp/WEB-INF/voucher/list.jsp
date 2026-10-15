<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>

    :root {
        --page-bg: #f7f9fc;
        --border: #dde5ef;
        --text-main: #111827;
        --text-muted: #64748b;

        --primary: #0d6efd;
        --primary-soft: #e7f0ff;

        --success: #059669;
        --success-soft: #dcfce7;

        --cyan: #0891b2;
        --cyan-soft: #cffafe;

        --danger: #ef4444;
    }


    body {
        background: var(--page-bg);
    }


    .voucher-page {
        padding: 5px 0 40px;
    }


    /* =====================================================
       PAGE HEADER
       ===================================================== */

    .page-heading {
        display: flex;
        justify-content: space-between;
        align-items: center;

        gap: 20px;

        margin-bottom: 28px;
    }


    .page-heading h1 {
        margin: 0 0 5px;

        color: var(--text-main);

        font-size: 34px;
        font-weight: 800;
    }


    .page-heading p {
        margin: 0;

        color: var(--text-muted);

        font-size: 16px;
    }


    .create-voucher-btn {
        display: inline-flex;
        align-items: center;

        gap: 8px;

        padding: 12px 19px;

        border: none;
        border-radius: 10px;

        background: var(--primary);
        color: #fff;

        text-decoration: none;

        font-size: 15px;
        font-weight: 700;

        box-shadow:
            0 4px 10px rgba(13, 110, 253, .18);
    }


    .create-voucher-btn:hover {
        background: #0b5ed7;
        color: #fff;
    }


    /* =====================================================
       STAT CARDS
       ===================================================== */

    .stat-card {
        position: relative;

        min-height: 145px;

        padding: 26px 28px;

        border: 1px solid var(--border);
        border-radius: 18px;

        background: #fff;
    }


    .stat-title {
        margin-bottom: 20px;

        color: #334155;

        font-size: 17px;
    }


    .stat-value {
        display: flex;
        align-items: baseline;

        gap: 14px;
    }


    .stat-value strong {
        color: #111827;

        font-size: 32px;
        font-weight: 800;

        line-height: 1;
    }


    .stat-value span {
        color: #64748b;

        font-size: 14px;
    }


    .stat-icon {
        position: absolute;

        top: 27px;
        right: 27px;

        width: 50px;
        height: 50px;

        display: flex;
        align-items: center;
        justify-content: center;

        border-radius: 15px;

        font-size: 20px;
    }


    .stat-icon.blue {
        background: var(--primary-soft);
        color: var(--primary);
    }


    .stat-icon.green {
        background: var(--success-soft);
        color: var(--success);
    }


    .stat-icon.cyan {
        background: var(--cyan-soft);
        color: var(--cyan);
    }


    .stat-link {
        position: absolute;

        left: 28px;
        bottom: 18px;

        color: var(--primary);

        font-size: 13px;
        font-weight: 600;

        text-decoration: none;
    }


    .stat-link:hover {
        text-decoration: underline;
    }


    /* =====================================================
       MESSAGE
       ===================================================== */

    .page-message {
        margin-top: 24px;
    }


    /* =====================================================
       MAIN CARD
       ===================================================== */

    .voucher-card {
        margin-top: 30px;

        overflow: hidden;

        border: 1px solid var(--border);
        border-radius: 18px;

        background: #fff;
    }


    .voucher-card-header {
        display: flex;
        align-items: center;
        justify-content: space-between;

        gap: 20px;

        padding: 20px 24px;

        border-bottom: 1px solid var(--border);
    }


    .voucher-card-header h5 {
        margin: 0;

        color: #111827;

        font-size: 20px;
        font-weight: 750;
    }


    .voucher-count {
        color: #64748b;

        font-size: 14px;
    }


    /* =====================================================
       TABLE
       ===================================================== */

    .voucher-table {
        margin: 0;
    }


    .voucher-table thead th {
        padding: 15px 16px;

        vertical-align: middle;

        border-bottom: 1px solid var(--border);

        background: #f7f9fc;
        color: #5e708d;

        font-size: 12px;
        font-weight: 750;

        letter-spacing: .4px;

        text-transform: uppercase;

        white-space: nowrap;
    }


    .voucher-table tbody td {
        padding: 17px 16px;

        vertical-align: middle;

        border-color: #edf1f5;

        color: #334155;

        font-size: 14px;
    }


    .voucher-table tbody tr:hover {
        background: #fbfcfe;
    }


    /* =====================================================
       ID
       ===================================================== */

    .id-badge {
        display: inline-block;

        padding: 5px 9px;

        border: 1px solid #dbe4ee;
        border-radius: 7px;

        background: #f8fafc;
        color: #64748b;

        font-size: 13px;
    }


    /* =====================================================
       VOUCHER CODE
       ===================================================== */

    .voucher-code {
        color: #111827;

        font-size: 15px;
        font-weight: 800;
    }


    /* =====================================================
       VALUE
       ===================================================== */

    .voucher-value {
        font-weight: 750;
        color: #1e293b;
    }


    .value-percent {
        color: #0d6efd;
    }


    .value-amount {
        color: #059669;
    }


    /* =====================================================
       LIMIT BADGE
       ===================================================== */

    .limit-badge {
        display: inline-block;

        min-width: 40px;

        padding: 6px 9px;

        border-radius: 7px;

        background: #f1f5f9;
        color: #334155;

        text-align: center;

        font-weight: 650;
    }


    /* =====================================================
       DATE
       ===================================================== */

    .voucher-time {
        min-width: 180px;

        font-size: 13px;
    }


    .time-start {
        color: #059669;
    }


    .time-end {
        color: #ef4444;
    }


    .time-separator {
        margin: 3px 0;

        color: #64748b;

        font-size: 12px;
    }


    /* =====================================================
       ACTION
       ===================================================== */

    .action-group {
        display: flex;
        justify-content: center;

        gap: 7px;
    }


    .action-btn {
        width: 38px;
        height: 38px;

        display: inline-flex;
        align-items: center;
        justify-content: center;

        border-radius: 9px;

        background: #fff;

        text-decoration: none;
    }


    .edit-btn {
        border: 1px solid #bfdbfe;

        color: #0d6efd;
    }


    .edit-btn:hover {
        background: #eff6ff;
        color: #0b5ed7;
    }


    .delete-btn {
        border: 1px solid #fecaca;

        color: #ef4444;
    }


    .delete-btn:hover {
        background: #fff1f2;
        color: #dc2626;
    }


    /* =====================================================
       EMPTY
       ===================================================== */

    .empty-voucher {
        padding: 60px 20px;

        text-align: center;

        color: #64748b;
    }


    /* =====================================================
       RECENT USAGE
       ===================================================== */

    .usage-card {
        margin-top: 28px;

        overflow: hidden;

        border: 1px solid var(--border);
        border-radius: 18px;

        background: #fff;
    }


    .usage-header {
        display: flex;
        justify-content: space-between;
        align-items: center;

        gap: 20px;

        padding: 20px 24px;

        border-bottom: 1px solid var(--border);
    }


    .usage-header h5 {
        margin: 0 0 4px;

        font-size: 19px;
        font-weight: 750;
    }


    .usage-header small {
        color: #64748b;
    }


    .view-history-btn {
        padding: 8px 13px;

        border: 1px solid #bfdbfe;
        border-radius: 8px;

        color: #0d6efd;
        background: #fff;

        text-decoration: none;

        font-size: 13px;
        font-weight: 650;
    }


    .view-history-btn:hover {
        background: #eff6ff;
        color: #0b5ed7;
    }


    .usage-table {
        margin: 0;
    }


    .usage-table th {
        padding: 14px 18px;

        background: #f8fafc;

        color: #64748b;

        font-size: 12px;

        text-transform: uppercase;
    }


    .usage-table td {
        padding: 14px 18px;

        vertical-align: middle;

        border-color: #edf1f5;
    }


    /* =====================================================
       RESPONSIVE
       ===================================================== */

    @media (max-width: 992px) {

        .voucher-table {
            min-width: 1250px;
        }


        .usage-table {
            min-width: 700px;
        }

    }


    @media (max-width: 768px) {

        .page-heading {
            flex-direction: column;
            align-items: flex-start;
        }


        .page-heading h1 {
            font-size: 28px;
        }


        .voucher-card-header,
        .usage-header {
            align-items: flex-start;
            flex-direction: column;
        }

    }

</style>


<div class="voucher-page">


    <!-- =====================================================
         PAGE HEADER
         ===================================================== -->

    <div class="page-heading">

        <div>

            <h1>
                Quản lý Voucher
            </h1>

            <p>
                Tạo và quản lý các chương trình giảm giá.
            </p>

        </div>


        <a
            href="${pageContext.request.contextPath}/staff/voucher?view=create"
            class="create-voucher-btn">

            <i class="bi bi-plus-lg"></i>

            Thêm Voucher

        </a>

    </div>


    <!-- =====================================================
         MESSAGES
         ===================================================== -->

    <div class="page-message">


        <c:if test="${not empty sessionScope.successMessage}">

            <div
                class="alert alert-success alert-dismissible fade show">

                ${sessionScope.successMessage}

                <button
                    type="button"
                    class="btn-close"
                    data-bs-dismiss="alert">
                </button>

            </div>


            <c:remove
                var="successMessage"
                scope="session"/>

        </c:if>


        <c:if test="${not empty sessionScope.errorMessage}">

            <div
                class="alert alert-danger alert-dismissible fade show">

                ${sessionScope.errorMessage}

                <button
                    type="button"
                    class="btn-close"
                    data-bs-dismiss="alert">
                </button>

            </div>


            <c:remove
                var="errorMessage"
                scope="session"/>

        </c:if>


    </div>


    <!-- =====================================================
         STATISTICS
         ===================================================== -->

    <div class="row g-4">


        <!-- TOTAL VOUCHERS -->

        <div class="col-lg-4">

            <div class="stat-card">

                <div class="stat-title">
                    Tổng Voucher
                </div>


                <div class="stat-icon blue">

                    <i class="bi bi-ticket-perforated-fill"></i>

                </div>


                <div class="stat-value">

                    <strong>

                        <c:choose>

                            <c:when test="${not empty vouchers}">
                                ${vouchers.size()}
                            </c:when>

                            <c:otherwise>
                                0
                            </c:otherwise>

                        </c:choose>

                    </strong>


                    <span>
                        mã giảm giá
                    </span>

                </div>

            </div>

        </div>


        <!-- USED VOUCHERS -->

        <div class="col-lg-4">

            <div class="stat-card">

                <div class="stat-title">
                    Mã đã sử dụng
                </div>


                <div class="stat-icon green">

                    <i class="bi bi-check2-circle"></i>

                </div>


                <div class="stat-value">

                    <strong>

                        <c:out
                            value="${usedVoucherCount}"
                            default="0"/>

                    </strong>


                    <span>
                        mã Voucher
                    </span>

                </div>


                <a
                    href="${pageContext.request.contextPath}/staff/voucher?view=usage"
                    class="stat-link">

                    Xem lịch sử

                    <i class="bi bi-chevron-right"></i>

                </a>

            </div>

        </div>


        <!-- CRUD -->

        <div class="col-lg-4">

            <div class="stat-card">

                <div class="stat-title">
                    Chức năng
                </div>


                <div class="stat-icon cyan">

                    <i class="bi bi-shield-check"></i>

                </div>


                <div class="stat-value">

                    <strong>
                        CRUD
                    </strong>


                    <span>
                        Voucher
                    </span>

                </div>

            </div>

        </div>


    </div>


    <!-- =====================================================
         VOUCHER LIST
         ===================================================== -->

    <div class="voucher-card">


        <!-- HEADER -->

        <div class="voucher-card-header">

            <h5>

                <i class="bi bi-ticket-perforated me-2 text-primary"></i>

                Danh sách Voucher

            </h5>


            <div class="voucher-count">

                Hiển thị

                <strong>

                    <c:choose>

                        <c:when test="${not empty vouchers}">
                            ${vouchers.size()}
                        </c:when>

                        <c:otherwise>
                            0
                        </c:otherwise>

                    </c:choose>

                </strong>

                Voucher

            </div>

        </div>


        <!-- EMPTY -->

        <c:if test="${empty vouchers}">

            <div class="empty-voucher">

                <i
                    class="bi bi-ticket-perforated"
                    style="font-size:48px;">
                </i>


                <h5 class="mt-3">
                    Chưa có Voucher
                </h5>


                <p>
                    Hãy tạo Voucher đầu tiên.
                </p>


                <a
                    href="${pageContext.request.contextPath}/staff/voucher?view=create"
                    class="btn btn-primary">

                    <i class="bi bi-plus-lg me-1"></i>

                    Thêm Voucher

                </a>

            </div>

        </c:if>


        <!-- TABLE -->

        <c:if test="${not empty vouchers}">

            <div class="table-responsive">

                <table class="table voucher-table">


                    <thead>

                        <tr>

                            <th>
                                ID
                            </th>


                            <th>
                                Mã Voucher
                            </th>


                            <%-- KHÔNG CÒN CỘT LOẠI --%>


                            <th>
                                Giá trị
                            </th>


                            <th>
                                Đơn tối thiểu
                            </th>


                            <th>
                                Giảm tối đa
                            </th>


                            <th>
                                Usage
                            </th>


                            <th>
                                Mỗi User
                            </th>


                            <th>
                                Thời gian
                            </th>


                            <th class="text-center">
                                Thao tác
                            </th>

                        </tr>

                    </thead>


                    <tbody>


                        <c:forEach
                            var="v"
                            items="${vouchers}">


                            <tr>


                                <!-- ID -->

                                <td>

                                    <span class="id-badge">

                                        #${v.voucherId}

                                    </span>

                                </td>


                                <!-- CODE -->

                                <td>

                                    <span class="voucher-code">

                                        ${v.code}

                                    </span>

                                </td>


                                <!-- VALUE -->

                                <td>

                                    <c:choose>


                                        <%-- PERCENT --%>

                                        <c:when test="${v.discountType == 'PERCENT'}">

                                            <span
                                                class="
                                                    voucher-value
                                                    value-percent
                                                ">

                                                <fmt:formatNumber
                                                    value="${v.discountValue}"
                                                    type="number"
                                                    maxFractionDigits="2"/>

                                                %

                                            </span>

                                        </c:when>


                                        <%-- AMOUNT --%>

                                        <c:otherwise>

                                            <span
                                                class="
                                                    voucher-value
                                                    value-amount
                                                ">

                                                <fmt:formatNumber
                                                    value="${v.discountValue}"
                                                    type="number"
                                                    groupingUsed="true"
                                                    maxFractionDigits="0"/>

                                                đ

                                            </span>

                                        </c:otherwise>


                                    </c:choose>

                                </td>


                                <!-- MIN ORDER -->

                                <td>

                                    <fmt:formatNumber
                                        value="${v.minOrderValue}"
                                        type="number"
                                        groupingUsed="true"
                                        maxFractionDigits="0"/>

                                    đ

                                </td>


                                <!-- MAX DISCOUNT -->

                                <td>

                                    <c:choose>


                                        <c:when test="${not empty v.maxDiscount}">

                                            <fmt:formatNumber
                                                value="${v.maxDiscount}"
                                                type="number"
                                                groupingUsed="true"
                                                maxFractionDigits="0"/>

                                            đ

                                        </c:when>


                                        <c:otherwise>

                                            <span class="text-muted">
                                                —
                                            </span>

                                        </c:otherwise>


                                    </c:choose>

                                </td>


                                <!-- USAGE LIMIT -->

                                <td>

                                    <span class="limit-badge">

                                        <c:choose>

                                            <c:when test="${not empty v.usageLimit}">

                                                ${v.usageLimit}

                                            </c:when>

                                            <c:otherwise>

                                                &infin;

                                            </c:otherwise>

                                        </c:choose>

                                    </span>

                                </td>


                                <!-- PER USER -->

                                <td>

                                    <span class="limit-badge">

                                        <c:choose>

                                            <c:when test="${not empty v.perUserLimit}">

                                                ${v.perUserLimit}

                                            </c:when>

                                            <c:otherwise>

                                                &infin;

                                            </c:otherwise>

                                        </c:choose>

                                    </span>

                                </td>


                                <!-- TIME -->

                                <td class="voucher-time">


                                    <div class="time-start">

                                        <i class="bi bi-calendar-check me-1"></i>

                                        <fmt:formatDate
                                            value="${v.validFrom}"
                                            pattern="dd/MM/yyyy HH:mm"/>

                                    </div>


                                    <div class="time-separator">

                                        đến

                                    </div>


                                    <div class="time-end">

                                        <i class="bi bi-calendar-x me-1"></i>

                                        <fmt:formatDate
                                            value="${v.validTo}"
                                            pattern="dd/MM/yyyy HH:mm"/>

                                    </div>


                                </td>


                                <!-- ACTION -->

                                <td>

                                    <div class="action-group">


                                        <!-- EDIT -->

                                        <a
                                            href="${pageContext.request.contextPath}/staff/voucher?view=edit&id=${v.voucherId}"
                                            class="action-btn edit-btn"
                                            title="Chỉnh sửa">

                                            <i class="bi bi-pencil-square"></i>

                                        </a>


                                        <!-- DELETE -->

                                        <a
                                            href="${pageContext.request.contextPath}/staff/voucher?view=delete&id=${v.voucherId}"
                                            class="action-btn delete-btn"
                                            title="Xóa">

                                            <i class="bi bi-trash"></i>

                                        </a>


                                    </div>

                                </td>


                            </tr>


                        </c:forEach>


                    </tbody>

                </table>

            </div>

        </c:if>


    </div>


    <!-- =====================================================
         RECENT USED VOUCHERS - LAST 7 DAYS
         Chỉ hiện khi Servlet có truyền recentVoucherUsages
         ===================================================== -->

    <c:if test="${not empty recentVoucherUsages}">

        <div class="usage-card">


            <div class="usage-header">


                <div>

                    <h5>

                        <i class="bi bi-clock-history me-2 text-success"></i>

                        Mã Voucher đã sử dụng gần đây

                    </h5>


                    <small>

                        Các lượt sử dụng trong 7 ngày gần nhất

                    </small>

                </div>


                <a
                    href="${pageContext.request.contextPath}/staff/voucher?view=usage"
                    class="view-history-btn">

                    Xem tất cả lịch sử

                    <i class="bi bi-chevron-right ms-1"></i>

                </a>


            </div>


            <div class="table-responsive">

                <table class="table usage-table">


                    <thead>

                        <tr>

                            <th>
                                Voucher
                            </th>


                            <th>
                                User
                            </th>


                            <th>
                                Đơn hàng
                            </th>


                            <th>
                                Thời gian sử dụng
                            </th>

                        </tr>

                    </thead>


                    <tbody>


                        <c:forEach
                            var="usage"
                            items="${recentVoucherUsages}">


                            <tr>


                                <td>

                                    <strong class="text-primary">

                                        ${usage.voucherCode}

                                    </strong>

                                </td>


                                <td>

                                    #${usage.userId}

                                </td>


                                <td>

                                    #${usage.orderId}

                                </td>


                                <td>

                                    <i class="bi bi-clock me-1 text-muted"></i>

                                    <fmt:formatDate
                                        value="${usage.usedAt}"
                                        pattern="dd/MM/yyyy HH:mm"/>

                                </td>


                            </tr>


                        </c:forEach>


                    </tbody>

                </table>

            </div>


        </div>

    </c:if>


</div>


<%@include file="/WEB-INF/include/footer.jsp" %>