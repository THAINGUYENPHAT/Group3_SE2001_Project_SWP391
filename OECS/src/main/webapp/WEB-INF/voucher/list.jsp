
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<style>
    :root {
        --voucher-primary: #0d6efd;
        --voucher-border: #dde5ef;
        --voucher-bg: #f7f9fc;
        --voucher-muted: #64748b;
    }

    body {
        background: var(--voucher-bg);
    }

    .voucher-page {
        padding: 10px 0 40px;
    }

    .page-heading {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 20px;
        margin-bottom: 25px;
    }

    .page-heading h1 {
        color: #111827;
        font-size: 32px;
        font-weight: 800;
        margin-bottom: 5px;
    }

    .page-heading p {
        color: var(--voucher-muted);
        margin-bottom: 0;
    }

    .create-voucher-btn {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 11px 18px;
        background: var(--voucher-primary);
        color: white;
        border-radius: 10px;
        font-weight: 700;
        text-decoration: none;
        white-space: nowrap;
    }

    .create-voucher-btn:hover {
        background: #0b5ed7;
        color: white;
    }

    .stat-card {
        position: relative;
        min-height: 145px;
        height: 100%;
        padding: 25px 27px;
        background: white;
        border: 1px solid var(--voucher-border);
        border-radius: 17px;
    }

    .stat-title {
        color: #334155;
        font-size: 16px;
        margin-bottom: 18px;
    }

    .stat-value {
        display: flex;
        align-items: baseline;
        gap: 12px;
    }

    .stat-value strong {
        font-size: 32px;
        font-weight: 800;
        line-height: 1;
        color: #111827;
    }

    .stat-value span {
        color: var(--voucher-muted);
        font-size: 13px;
    }

    .stat-icon {
        position: absolute;
        top: 25px;
        right: 25px;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 48px;
        height: 48px;
        border-radius: 14px;
        font-size: 21px;
    }

    .stat-icon.blue {
        color: #0d6efd;
        background: #e7f0ff;
    }

    .stat-icon.green {
        color: #059669;
        background: #dcfce7;
    }

    .stat-icon.cyan {
        color: #0891b2;
        background: #cffafe;
    }

    .stat-link {
        display: inline-block;
        margin-top: 13px;
        color: #0d6efd;
        font-size: 13px;
        font-weight: 600;
        text-decoration: none;
    }

    .stat-link:hover {
        text-decoration: underline;
    }

    .voucher-card {
        margin-top: 28px;
        background: white;
        border: 1px solid var(--voucher-border);
        border-radius: 17px;
        overflow: hidden;
    }

    .voucher-card-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 15px;
        padding: 20px 24px;
        border-bottom: 1px solid var(--voucher-border);
    }

    .voucher-card-header h5 {
        margin: 0;
        font-size: 19px;
        font-weight: 750;
        color: #111827;
    }

    .voucher-count {
        font-size: 13px;
        color: var(--voucher-muted);
    }

    .voucher-filters {
        display: flex;
        flex-wrap: wrap;
        gap: 9px;
        padding: 17px 24px;
        border-bottom: 1px solid var(--voucher-border);
    }

    .voucher-filter-link {
        display: inline-block;
        padding: 8px 13px;
        border: 1px solid var(--voucher-border);
        border-radius: 8px;
        color: #475569;
        background: white;
        text-decoration: none;
        font-size: 13px;
        font-weight: 650;
        transition: 0.15s;
    }

    .voucher-filter-link:hover,
    .voucher-filter-link.active {
        color: #0d6efd;
        background: #e7f0ff;
        border-color: #93c5fd;
    }

    .voucher-filter-note {
        padding: 12px 24px;
        margin: 0;
        color: var(--voucher-muted);
        font-size: 12px;
    }

    .voucher-table {
        margin: 0;
        width: 100%;
    }

    .voucher-table thead th {
        padding: 15px 16px;
        color: #5e708d;
        background: #f7f9fc;
        border-bottom: 1px solid var(--voucher-border);
        font-size: 12px;
        font-weight: 750;
        text-transform: uppercase;
        white-space: nowrap;
        vertical-align: middle;
    }

    .voucher-table tbody td {
        padding: 19px 16px;
        border-color: #edf1f5;
        vertical-align: middle;
        color: #334155;
        font-size: 14px;
    }

    .voucher-table tbody tr:hover {
        background: #fbfcfe;
    }

    .id-badge {
        display: inline-block;
        padding: 5px 9px;
        border: 1px solid #dbe4ee;
        border-radius: 7px;
        color: #64748b;
        background: #f8fafc;
        font-size: 13px;
    }

    .voucher-code {
        font-size: 15px;
        font-weight: 800;
        color: #111827;
    }

    .voucher-value {
        font-size: 14px;
        font-weight: 750;
        white-space: nowrap;
    }

    .value-percent {
        color: #0d6efd;
    }

    .value-amount {
        color: #059669;
    }

    .voucher-state {
        display: inline-block;
        padding: 6px 10px;
        border-radius: 8px;
        font-size: 12px;
        font-weight: 700;
        white-space: nowrap;
    }

    .voucher-state.available {
        color: #047857;
        background: #dcfce7;
    }

    .voucher-state.exhausted {
        color: #b91c1c;
        background: #fee2e2;
    }

    .voucher-state.upcoming {
        color: #1d4ed8;
        background: #dbeafe;
    }

    .voucher-state.expired {
        color: #64748b;
        background: #f1f5f9;
    }

    .voucher-time {
        min-width: 170px;
        font-size: 13px;
    }

    .time-start {
        color: #059669;
    }

    .time-end {
        color: #ef4444;
    }

    .time-separator {
        color: var(--voucher-muted);
        font-size: 12px;
        margin: 3px 0;
    }

    .action-group {
        display: flex;
        justify-content: flex-end;
        gap: 7px;
    }

    .action-btn {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 37px;
        height: 37px;
        background: white;
        border-radius: 9px;
        font-size: 15px;
        text-decoration: none;
        cursor: pointer;
        transition: 0.15s;
    }

    .view-btn {
        color: #6366f1;
        border: 1px solid #c7d2fe;
    }

    .view-btn:hover {
        color: #4338ca;
        background: #eef2ff;
    }

    .edit-btn {
        color: #0d6efd;
        border: 1px solid #bfdbfe;
    }

    .edit-btn:hover {
        color: #0b5ed7;
        background: #eff6ff;
    }

    .delete-btn {
        color: #ef4444;
        border: 1px solid #fecaca;
    }

    .delete-btn:hover {
        color: #dc2626;
        background: #fff1f2;
    }

    .empty-voucher {
        padding: 55px 20px;
        text-align: center;
        color: var(--voucher-muted);
    }

    .voucher-detail-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 12px;
    }

    .voucher-detail-item {
        padding: 13px 15px;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
    }

    .voucher-detail-label {
        margin-bottom: 5px;
        color: #64748b;
        font-size: 12px;
    }

    .voucher-detail-value {
        color: #0f172a;
        font-size: 15px;
        font-weight: 650;
        overflow-wrap: anywhere;
    }

    .usage-card {
        margin-top: 28px;
        background: white;
        border: 1px solid var(--voucher-border);
        border-radius: 17px;
        overflow: hidden;
    }

    .usage-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 15px;
        padding: 20px 24px;
        border-bottom: 1px solid var(--voucher-border);
    }

    .usage-header h5 {
        margin: 0 0 4px;
        font-size: 19px;
        font-weight: 750;
    }

    .usage-header small {
        color: var(--voucher-muted);
    }

    .view-history-btn {
        display: inline-block;
        padding: 8px 13px;
        color: #0d6efd;
        border: 1px solid #bfdbfe;
        border-radius: 8px;
        font-size: 13px;
        font-weight: 650;
        text-decoration: none;
    }

    .view-history-btn:hover {
        color: #0b5ed7;
        background: #eff6ff;
    }

    .usage-table {
        margin: 0;
    }

    .usage-table th {
        padding: 14px 18px;
        color: #64748b;
        background: #f8fafc;
        font-size: 12px;
        text-transform: uppercase;
    }

    .usage-table td {
        padding: 14px 18px;
        border-color: #edf1f5;
        vertical-align: middle;
    }

    @media (max-width: 992px) {
        .voucher-table {
            min-width: 780px;
        }

        .usage-table {
            min-width: 650px;
        }
    }

    @media (max-width: 768px) {
        .page-heading,
        .voucher-card-header,
        .usage-header {
            flex-direction: column;
            align-items: flex-start;
        }

        .page-heading h1 {
            font-size: 27px;
        }
    }

    @media (max-width: 575px) {
        .voucher-detail-grid {
            grid-template-columns: 1fr;
        }
    }
</style>

<div class="voucher-page">

    <div class="page-heading">
        <div>
            <h1>Quản lý Voucher</h1>
            <p>Tạo và quản lý các chương trình giảm giá.</p>
        </div>

        <a href="${pageContext.request.contextPath}/staff/voucher?view=create"
           class="create-voucher-btn">
            <i class="bi bi-plus-lg"></i>
            Thêm Voucher
        </a>
    </div>

    <c:if test="${not empty sessionScope.successMessage}">
        <div class="alert alert-success alert-dismissible fade show"
             role="alert">
            <c:out value="${sessionScope.successMessage}"/>
            <button type="button"
                    class="btn-close"
                    data-bs-dismiss="alert"
                    aria-label="Đóng">
            </button>
        </div>
        <c:remove var="successMessage" scope="session"/>
    </c:if>

    <c:if test="${not empty sessionScope.errorMessage}">
        <div class="alert alert-danger alert-dismissible fade show"
             role="alert">
            <c:out value="${sessionScope.errorMessage}"/>
            <button type="button"
                    class="btn-close"
                    data-bs-dismiss="alert"
                    aria-label="Đóng">
            </button>
        </div>
        <c:remove var="errorMessage" scope="session"/>
    </c:if>

    <div class="row g-4">

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
                        <c:out value="${totalVoucherCount}" default="0"/>
                    </strong>
                    <span>mã giảm giá</span>
                </div>
            </div>
        </div>

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
                        <c:out value="${usedVoucherCount}" default="0"/>
                    </strong>
                    <span>mã Voucher</span>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="stat-card">
                <div class="stat-title">
                    Chức năng
                </div>

                <div class="stat-icon cyan">
                    <i class="bi bi-shield-check"></i>
                </div>

                <div class="stat-value">
                    <strong>CRUD</strong>
                    <span>Voucher</span>
                </div>
            </div>
        </div>

    </div>

    <div class="voucher-card">

        <div class="voucher-card-header">
            <h5>
                <i class="bi bi-ticket-perforated me-2 text-primary"></i>
                Danh sách Voucher
            </h5>

            <div class="voucher-count">
                Hiển thị
                <strong>
                    <c:out value="${vouchers.size()}" default="0"/>
                </strong>
                Voucher
            </div>
        </div>

        <div class="voucher-filters">

            <a class="voucher-filter-link ${voucherStatusFilter eq 'all' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/voucher?view=list&amp;status=all">
                Tất cả (<c:out value="${totalVoucherCount}" default="0"/>)
            </a>

            <a class="voucher-filter-link ${voucherStatusFilter eq 'available' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/voucher?view=list&amp;status=available">
                Còn sử dụng (<c:out value="${availableVoucherCount}" default="0"/>)
            </a>

            <a class="voucher-filter-link ${voucherStatusFilter eq 'exhausted' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/voucher?view=list&amp;status=exhausted">
                Đã hết lượt (<c:out value="${exhaustedVoucherCount}" default="0"/>)
            </a>

            <a class="voucher-filter-link ${voucherStatusFilter eq 'upcoming' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/voucher?view=list&amp;status=upcoming">
                Chưa bắt đầu (<c:out value="${upcomingVoucherCount}" default="0"/>)
            </a>

            <a class="voucher-filter-link ${voucherStatusFilter eq 'expired' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/voucher?view=list&amp;status=expired">
                Hết hạn (<c:out value="${expiredVoucherCount}" default="0"/>)
            </a>

        </div>

        <p class="voucher-filter-note">
            Trạng thái được tính theo thời hạn và tổng lượt sử dụng.
            Giới hạn từng khách hàng và giá trị đơn được kiểm tra
            khi áp dụng Voucher.
        </p>

        <c:choose>
            <c:when test="${empty vouchers}">

                <div class="empty-voucher">
                    <i class="bi bi-ticket-perforated"
                       style="font-size:45px;"></i>

                    <h5 class="mt-3">
                        <c:choose>
                            <c:when test="${totalVoucherCount == 0}">
                                Chưa có Voucher
                            </c:when>
                            <c:otherwise>
                                Không có Voucher phù hợp
                            </c:otherwise>
                        </c:choose>
                    </h5>

                    <p>
                        <c:choose>
                            <c:when test="${totalVoucherCount == 0}">
                                Hãy tạo Voucher đầu tiên.
                            </c:when>
                            <c:otherwise>
                                Hãy chọn trạng thái khác để xem Voucher.
                            </c:otherwise>
                        </c:choose>
                    </p>
                </div>

            </c:when>

            <c:otherwise>

                <div class="table-responsive">
                    <table class="table voucher-table">

                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Mã Voucher</th>
                                <th>Giá trị</th>
                                <th>Trạng thái</th>
                                <th>Thời gian</th>
                                <th class="text-end">Thao tác</th>
                            </tr>
                        </thead>

                        <tbody>
                            <c:forEach var="v" items="${vouchers}">

                                <tr>

                                    <td>
                                        <span class="id-badge">
                                            #<c:out value="${v.voucherId}"/>
                                        </span>
                                    </td>

                                    <td>
                                        <span class="voucher-code">
                                            <c:out value="${v.code}"/>
                                        </span>
                                    </td>

                                    <td>
                                        <c:choose>
                                            <c:when test="${v.discountType eq 'PERCENT'}">
                                                <span class="voucher-value value-percent">
                                                    <fmt:formatNumber
                                                        value="${v.discountValue}"
                                                        type="number"
                                                        maxFractionDigits="2"/>%
                                                </span>
                                            </c:when>

                                            <c:otherwise>
                                                <span class="voucher-value value-amount">
                                                    <fmt:formatNumber
                                                        value="${v.discountValue}"
                                                        type="number"
                                                        groupingUsed="true"
                                                        maxFractionDigits="0"/> đ
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>

                                    <td>
                                        <c:choose>

                                            <c:when test="${v.availabilityStatus eq 'AVAILABLE'}">
                                                <span class="voucher-state available">
                                                    Còn sử dụng
                                                </span>
                                            </c:when>

                                            <c:when test="${v.availabilityStatus eq 'EXHAUSTED'}">
                                                <span class="voucher-state exhausted">
                                                    Đã hết lượt
                                                </span>
                                            </c:when>

                                            <c:when test="${v.availabilityStatus eq 'UPCOMING'}">
                                                <span class="voucher-state upcoming">
                                                    Chưa bắt đầu
                                                </span>
                                            </c:when>

                                            <c:otherwise>
                                                <span class="voucher-state expired">
                                                    Hết hạn
                                                </span>
                                            </c:otherwise>

                                        </c:choose>
                                    </td>

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

                                    <td>
                                        <div class="action-group">

                                            <button type="button"
                                                    class="action-btn view-btn"
                                                    data-bs-toggle="modal"
                                                    data-bs-target="#voucherDetail${v.voucherId}"
                                                    title="Xem chi tiết">
                                                <i class="bi bi-eye"></i>
                                            </button>

                                            <a href="${pageContext.request.contextPath}/staff/voucher?view=edit&amp;id=${v.voucherId}"
                                               class="action-btn edit-btn"
                                               title="Chỉnh sửa">
                                                <i class="bi bi-pencil-square"></i>
                                            </a>

                                            <a href="${pageContext.request.contextPath}/staff/voucher?view=delete&amp;id=${v.voucherId}"
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

            </c:otherwise>
        </c:choose>

    </div>

    <%-- Popup chi tiết được đặt ngoài bảng để không bị cắt nội dung. --%>
    <c:forEach var="v" items="${vouchers}">

        <div class="modal fade"
             id="voucherDetail${v.voucherId}"
             tabindex="-1"
             aria-labelledby="voucherDetailTitle${v.voucherId}"
             aria-hidden="true">

            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">

                <div class="modal-content border-0 rounded-4 shadow">

                    <div class="modal-header">

                        <div>
                            <div class="text-muted small">
                                Chi tiết Voucher #<c:out value="${v.voucherId}"/>
                            </div>

                            <h5 class="modal-title fw-bold"
                                id="voucherDetailTitle${v.voucherId}">
                                <c:out value="${v.code}"/>
                            </h5>
                        </div>

                        <button type="button"
                                class="btn-close"
                                data-bs-dismiss="modal"
                                aria-label="Đóng">
                        </button>

                    </div>

                    <div class="modal-body">

                        <div class="mb-3">
                            <c:choose>

                                <c:when test="${v.availabilityStatus eq 'AVAILABLE'}">
                                    <span class="voucher-state available">
                                        Còn sử dụng
                                    </span>
                                </c:when>

                                <c:when test="${v.availabilityStatus eq 'EXHAUSTED'}">
                                    <span class="voucher-state exhausted">
                                        Đã hết lượt
                                    </span>
                                </c:when>

                                <c:when test="${v.availabilityStatus eq 'UPCOMING'}">
                                    <span class="voucher-state upcoming">
                                        Chưa bắt đầu
                                    </span>
                                </c:when>

                                <c:otherwise>
                                    <span class="voucher-state expired">
                                        Hết hạn
                                    </span>
                                </c:otherwise>

                            </c:choose>
                        </div>

                        <div class="voucher-detail-grid">

                            <div class="voucher-detail-item">
                                <div class="voucher-detail-label">
                                    Loại giảm giá
                                </div>

                                <div class="voucher-detail-value">
                                    <c:choose>
                                        <c:when test="${v.discountType eq 'PERCENT'}">
                                            Phần trăm
                                        </c:when>
                                        <c:otherwise>
                                            Số tiền cố định
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </div>

                            <div class="voucher-detail-item">
                                <div class="voucher-detail-label">
                                    Giá trị giảm
                                </div>

                                <div class="voucher-detail-value">
                                    <fmt:formatNumber
                                        value="${v.discountValue}"
                                        type="number"
                                        maxFractionDigits="2"/>

                                    <c:choose>
                                        <c:when test="${v.discountType eq 'PERCENT'}">
                                            %
                                        </c:when>
                                        <c:otherwise>
                                            đ
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </div>

                            <div class="voucher-detail-item">
                                <div class="voucher-detail-label">
                                    Đơn hàng tối thiểu
                                </div>

                                <div class="voucher-detail-value">
                                    <fmt:formatNumber
                                        value="${v.minOrderValue}"
                                        type="number"
                                        groupingUsed="true"
                                        maxFractionDigits="0"/> đ
                                </div>
                            </div>

                            <div class="voucher-detail-item">
                                <div class="voucher-detail-label">
                                    Giảm tối đa
                                </div>

                                <div class="voucher-detail-value">
                                    <c:choose>
                                        <c:when test="${not empty v.maxDiscount}">
                                            <fmt:formatNumber
                                                value="${v.maxDiscount}"
                                                type="number"
                                                groupingUsed="true"
                                                maxFractionDigits="0"/> đ
                                        </c:when>

                                        <c:otherwise>
                                            Không áp dụng
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </div>

                            <div class="voucher-detail-item">
                                <div class="voucher-detail-label">
                                    Tổng lượt đã dùng / giới hạn
                                </div>

                                <div class="voucher-detail-value">
                                    <c:out value="${v.usedCount}"/> /

                                    <c:choose>
                                        <c:when test="${not empty v.usageLimit}">
                                            <c:out value="${v.usageLimit}"/>
                                        </c:when>

                                        <c:otherwise>
                                            &infin; (Không giới hạn)
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </div>

                            <div class="voucher-detail-item">
                                <div class="voucher-detail-label">
                                    Giới hạn mỗi khách hàng
                                </div>

                                <div class="voucher-detail-value">
                                    <c:choose>
                                        <c:when test="${not empty v.perUserLimit}">
                                            <c:out value="${v.perUserLimit}"/> lượt
                                        </c:when>

                                        <c:otherwise>
                                            Không giới hạn
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </div>

                            <div class="voucher-detail-item">
                                <div class="voucher-detail-label">
                                    Ngày bắt đầu
                                </div>

                                <div class="voucher-detail-value">
                                    <fmt:formatDate
                                        value="${v.validFrom}"
                                        pattern="dd/MM/yyyy HH:mm"/>
                                </div>
                            </div>

                            <div class="voucher-detail-item">
                                <div class="voucher-detail-label">
                                    Ngày kết thúc
                                </div>

                                <div class="voucher-detail-value">
                                    <fmt:formatDate
                                        value="${v.validTo}"
                                        pattern="dd/MM/yyyy HH:mm"/>
                                </div>
                            </div>

                        </div>

                        <p class="text-muted small mt-3 mb-0">
                            Trạng thái dựa trên thời hạn và tổng lượt sử dụng.
                            Điều kiện theo khách hàng và giá trị đơn hàng
                            sẽ được kiểm tra khi áp dụng Voucher.
                        </p>

                    </div>

                    <div class="modal-footer">

                        <button type="button"
                                class="btn btn-outline-secondary"
                                data-bs-dismiss="modal">
                            Đóng
                        </button>

                        <a href="${pageContext.request.contextPath}/staff/voucher?view=edit&amp;id=${v.voucherId}"
                           class="btn btn-primary">
                            <i class="bi bi-pencil-square me-1"></i>
                            Chỉnh sửa
                        </a>

                    </div>

                </div>
            </div>
        </div>

    </c:forEach>

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

                <a href="${pageContext.request.contextPath}/staff/voucher?view=usage"
                   class="view-history-btn">
                    Xem tất cả lịch sử
                    <i class="bi bi-chevron-right ms-1"></i>
                </a>

            </div>

            <div class="table-responsive">

                <table class="table usage-table">

                    <thead>
                        <tr>
                            <th>Voucher</th>
                            <th>User</th>
                            <th>Đơn hàng</th>
                            <th>Thời gian sử dụng</th>
                        </tr>
                    </thead>

                    <tbody>
                        <c:forEach var="usage"
                                   items="${recentVoucherUsages}">

                            <tr>

                                <td>
                                    <strong class="text-primary">
                                        <c:out value="${usage.voucherCode}"/>
                                    </strong>
                                </td>

                                <td>
                                    #<c:out value="${usage.userId}"/>
                                </td>

                                <td>
                                    #<c:out value="${usage.orderId}"/>
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

<%@include file="/WEB-INF/include/footer.jsp"%>
