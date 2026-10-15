<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>

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

        --warning: #d97706;
        --warning-soft: #fef3c7;

        --danger: #dc3545;
    }


    body {
        background: var(--page-bg);
    }


    .usage-page {
        padding: 4px 0 45px;
    }


    /* =====================================================
       HEADER
       ===================================================== */

    .page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;

        gap: 20px;

        margin-bottom: 26px;
    }


    .page-title h1 {
        margin: 0 0 6px;

        color: var(--text-main);

        font-size: 32px;
        font-weight: 800;
    }


    .page-title p {
        margin: 0;

        color: var(--text-muted);

        font-size: 15px;
    }


    .back-btn {
        display: inline-flex;
        align-items: center;

        gap: 8px;

        padding: 10px 16px;

        border: 1px solid #bfdbfe;
        border-radius: 10px;

        background: #fff;
        color: var(--primary);

        text-decoration: none;

        font-size: 14px;
        font-weight: 700;
    }


    .back-btn:hover {
        background: #eff6ff;
        color: #0b5ed7;
    }


    /* =====================================================
       STATS
       ===================================================== */

    .stat-card {
        position: relative;

        min-height: 125px;

        padding: 24px 26px;

        border: 1px solid var(--border);
        border-radius: 17px;

        background: #fff;
    }


    .stat-title {
        margin-bottom: 17px;

        color: #475569;

        font-size: 15px;
    }


    .stat-value {
        display: flex;
        align-items: baseline;

        gap: 10px;
    }


    .stat-value strong {
        color: #111827;

        font-size: 30px;
        font-weight: 800;
    }


    .stat-value span {
        color: #64748b;

        font-size: 13px;
    }


    .stat-icon {
        position: absolute;

        top: 23px;
        right: 23px;

        width: 48px;
        height: 48px;

        display: flex;
        align-items: center;
        justify-content: center;

        border-radius: 14px;

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


    /* =====================================================
       HISTORY CARD
       ===================================================== */

    .history-card {
        margin-top: 28px;

        overflow: hidden;

        border: 1px solid var(--border);
        border-radius: 18px;

        background: #fff;
    }


    .history-header {
        display: flex;
        justify-content: space-between;
        align-items: center;

        gap: 20px;

        padding: 20px 24px;

        border-bottom: 1px solid var(--border);
    }


    .history-header h5 {
        margin: 0 0 4px;

        color: #111827;

        font-size: 19px;
        font-weight: 750;
    }


    .history-header p {
        margin: 0;

        color: #64748b;

        font-size: 13px;
    }


    /* =====================================================
       SEARCH
       ===================================================== */

    .search-box {
        position: relative;

        width: 310px;
    }


    .search-box i {
        position: absolute;

        top: 50%;
        left: 13px;

        color: #94a3b8;

        transform: translateY(-50%);
    }


    .search-box input {
        width: 100%;

        padding: 10px 14px 10px 38px;

        border: 1px solid #dbe3ec;
        border-radius: 9px;

        outline: none;

        background: #f8fafc;

        font-size: 13px;
    }


    .search-box input:focus {
        border-color: #86b7fe;

        background: #fff;

        box-shadow:
            0 0 0 3px rgba(13, 110, 253, .08);
    }


    /* =====================================================
       TABLE
       ===================================================== */

    .usage-table {
        margin: 0;
    }


    .usage-table thead th {
        padding: 14px 17px;

        background: #f7f9fc;

        border-bottom: 1px solid var(--border);

        color: #64748b;

        font-size: 12px;
        font-weight: 750;

        letter-spacing: .3px;

        text-transform: uppercase;

        white-space: nowrap;
    }


    .usage-table tbody td {
        padding: 16px 17px;

        vertical-align: middle;

        border-color: #edf1f5;

        color: #334155;

        font-size: 14px;
    }


    .usage-table tbody tr:hover {
        background: #fbfcfe;
    }


    .usage-number {
        display: inline-flex;
        justify-content: center;
        align-items: center;

        min-width: 35px;
        height: 30px;

        padding: 0 8px;

        border: 1px solid #dbe4ee;
        border-radius: 7px;

        background: #f8fafc;
        color: #64748b;

        font-size: 12px;
        font-weight: 650;
    }


    .voucher-code {
        display: inline-flex;
        align-items: center;

        gap: 7px;

        padding: 7px 10px;

        border-radius: 8px;

        background: #eff6ff;
        color: #0d6efd;

        font-weight: 750;
    }


    .voucher-code i {
        font-size: 14px;
    }


    .order-badge {
        color: #334155;

        font-weight: 700;
    }


    .user-badge {
        display: inline-flex;
        align-items: center;

        gap: 6px;

        color: #475569;

        font-weight: 600;
    }


    .used-date {
        color: #059669;

        font-weight: 650;
    }


    .used-date small {
        display: block;

        margin-top: 2px;

        color: #94a3b8;

        font-size: 11px;
        font-weight: 500;
    }


    /* =====================================================
       EMPTY
       ===================================================== */

    .empty-history {
        padding: 65px 20px;

        text-align: center;
    }


    .empty-history i {
        display: block;

        margin-bottom: 13px;

        color: #94a3b8;

        font-size: 46px;
    }


    .empty-history h5 {
        color: #334155;

        font-weight: 750;
    }


    .empty-history p {
        margin-bottom: 18px;

        color: #64748b;

        font-size: 14px;
    }


    /* =====================================================
       SEARCH EMPTY
       ===================================================== */

    #searchEmpty {
        display: none;

        padding: 40px 20px;

        text-align: center;

        color: #64748b;
    }


    #searchEmpty i {
        display: block;

        margin-bottom: 8px;

        font-size: 35px;

        color: #94a3b8;
    }


    /* =====================================================
       RESPONSIVE
       ===================================================== */

    @media (max-width: 768px) {

        .page-header {
            flex-direction: column;
            align-items: flex-start;
        }


        .history-header {
            flex-direction: column;
            align-items: flex-start;
        }


        .search-box {
            width: 100%;
        }


        .usage-table {
            min-width: 720px;
        }

    }

</style>


<div class="usage-page">


    <%-- =====================================================
         PAGE HEADER
         ===================================================== --%>

    <div class="page-header">


        <div class="page-title">

            <h1>
                Lịch sử Voucher
            </h1>

            <p>
                Xem toàn bộ các Voucher đã được khách hàng sử dụng.
            </p>

        </div>


        <a
            href="${pageContext.request.contextPath}/staff/voucher"
            class="back-btn">

            <i class="bi bi-arrow-left"></i>

            Quay lại Voucher

        </a>


    </div>


    <%-- =====================================================
         STAT CARDS
         ===================================================== --%>

    <div class="row g-4">


        <div class="col-md-6">


            <div class="stat-card">


                <div class="stat-title">
                    Tổng lượt sử dụng
                </div>


                <div class="stat-icon blue">

                    <i class="bi bi-ticket-perforated"></i>

                </div>


                <div class="stat-value">

                    <strong>

                        <c:choose>

                            <c:when test="${not empty voucherUsages}">
                                ${voucherUsages.size()}
                            </c:when>

                            <c:otherwise>
                                0
                            </c:otherwise>

                        </c:choose>

                    </strong>


                    <span>
                        lượt sử dụng
                    </span>

                </div>


            </div>


        </div>


        <div class="col-md-6">


            <div class="stat-card">


                <div class="stat-title">
                    Trạng thái
                </div>


                <div class="stat-icon green">

                    <i class="bi bi-check2-circle"></i>

                </div>


                <div class="stat-value">

                    <strong style="font-size: 23px;">
                        Đã ghi nhận
                    </strong>

                    <span>
                        lịch sử Voucher
                    </span>

                </div>


            </div>


        </div>


    </div>


    <%-- =====================================================
         HISTORY
         ===================================================== --%>

    <div class="history-card">


        <div class="history-header">


            <div>

                <h5>

                    <i class="bi bi-clock-history me-2 text-primary"></i>

                    Toàn bộ lịch sử sử dụng

                </h5>


                <p>

                    Dữ liệu được sắp xếp từ mới nhất đến cũ nhất.

                </p>

            </div>


            <div class="search-box">

                <i class="bi bi-search"></i>


                <input
                    type="text"
                    id="usageSearch"
                    placeholder="Tìm Voucher, User, Order...">

            </div>


        </div>


        <c:choose>


            <c:when test="${not empty voucherUsages}">


                <div class="table-responsive">


                    <table
                        class="table usage-table"
                        id="usageTable">


                        <thead>

                            <tr>

                                <th>
                                    #
                                </th>

                                <th>
                                    Mã Voucher
                                </th>

                                <th>
                                    Đơn hàng
                                </th>

                                <th>
                                    User
                                </th>

                                <th>
                                    Thời gian sử dụng
                                </th>

                            </tr>

                        </thead>


                        <tbody>


                            <c:forEach
                                var="usage"
                                items="${voucherUsages}"
                                varStatus="status">


                                <tr class="usage-row">


                                    <%-- STT --%>

                                    <td>

                                        <span class="usage-number">

                                            ${status.index + 1}

                                        </span>

                                    </td>


                                    <%-- VOUCHER CODE --%>

                                    <td>

                                        <span class="voucher-code">

                                            <i class="bi bi-ticket-perforated"></i>

                                            <c:out
                                                value="${usage.voucherCode}"/>

                                        </span>

                                    </td>


                                    <%-- ORDER --%>

                                    <td>

                                        <span class="order-badge">

                                            #${usage.orderId}

                                        </span>

                                    </td>


                                    <%-- USER --%>

                                    <td>

                                        <span class="user-badge">

                                            <i class="bi bi-person"></i>

                                            User #${usage.userId}

                                        </span>

                                    </td>


                                    <%-- USED TIME --%>

                                    <td>

                                        <div class="used-date">

                                            <i class="bi bi-check-circle me-1"></i>


                                            <fmt:formatDate
                                                value="${usage.usedAt}"
                                                pattern="dd/MM/yyyy"/>


                                            <small>

                                                <fmt:formatDate
                                                    value="${usage.usedAt}"
                                                    pattern="HH:mm:ss"/>

                                            </small>

                                        </div>

                                    </td>


                                </tr>


                            </c:forEach>


                        </tbody>


                    </table>


                    <div id="searchEmpty">

                        <i class="bi bi-search"></i>

                        Không tìm thấy lịch sử phù hợp.

                    </div>


                </div>


            </c:when>


            <c:otherwise>


                <div class="empty-history">


                    <i class="bi bi-clock-history"></i>


                    <h5>
                        Chưa có lịch sử sử dụng
                    </h5>


                    <p>

                        Chưa có khách hàng nào sử dụng Voucher.

                    </p>


                    <a
                        href="${pageContext.request.contextPath}/staff/voucher"
                        class="btn btn-primary">

                        <i class="bi bi-arrow-left me-1"></i>

                        Quay lại Voucher

                    </a>


                </div>


            </c:otherwise>


        </c:choose>


    </div>


</div>


<script>

    document.addEventListener(
        "DOMContentLoaded",
        function () {

            const searchInput =
                document.getElementById(
                    "usageSearch"
                );


            const rows =
                document.querySelectorAll(
                    ".usage-row"
                );


            const searchEmpty =
                document.getElementById(
                    "searchEmpty"
                );


            if (!searchInput) {
                return;
            }


            searchInput.addEventListener(
                "input",
                function () {

                    const keyword =
                        this.value
                            .trim()
                            .toLowerCase();


                    let visibleCount = 0;


                    rows.forEach(
                        function (row) {

                            const text =
                                row.textContent
                                    .toLowerCase();


                            const matched =
                                text.includes(
                                    keyword
                                );


                            row.style.display =
                                matched
                                ? ""
                                : "none";


                            if (matched) {

                                visibleCount++;
                            }

                        }
                    );


                    if (searchEmpty) {

                        searchEmpty.style.display =
                            visibleCount === 0
                            ? "block"
                            : "none";
                    }

                }
            );

        }
    );

</script>


<%@include file="/WEB-INF/include/footer.jsp" %>