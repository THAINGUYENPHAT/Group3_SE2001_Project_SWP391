<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .voucher-page {
        padding-bottom: 30px;
    }

    .page-title {
        font-size: 1.55rem;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 4px;
    }

    .page-description {
        color: #64748b;
        font-size: 0.9rem;
    }

    .btn-create {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        padding: 9px 15px;

        background: #2563eb;
        color: white;

        border-radius: 8px;
        text-decoration: none;

        font-size: 0.88rem;
        font-weight: 600;

        transition: 0.2s;
    }

    .btn-create:hover {
        background: #1d4ed8;
        color: white;
    }

    /* ================= STAT ================= */

    .stat-card {
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 22px;
        height: 100%;
    }

    .stat-label {
        color: #475569;
        font-size: 0.95rem;
    }

    .stat-value {
        margin-top: 12px;
        font-size: 1.6rem;
        font-weight: 700;
        color: #0f172a;
    }

    .stat-note {
        margin-left: 7px;
        font-size: 0.8rem;
        color: #64748b;
        font-weight: 500;
    }

    .stat-icon {
        width: 40px;
        height: 40px;

        border-radius: 12px;

        display: flex;
        align-items: center;
        justify-content: center;

        background: #dbeafe;
        color: #2563eb;
    }

    .stat-green {
        background: #dcfce7;
        color: #16a34a;
    }

    .stat-cyan {
        background: #cffafe;
        color: #0891b2;
    }

    /* ================= TABLE ================= */

    .voucher-card {
        background: white;

        border: 1px solid #e2e8f0;
        border-radius: 14px;

        overflow: hidden;
    }

    .voucher-card-header {
        padding: 18px 20px;
        border-bottom: 1px solid #e2e8f0;

        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .card-title-custom {
        font-size: 1rem;
        font-weight: 700;
        color: #0f172a;
        margin: 0;
    }

    .voucher-table {
        margin: 0;
    }

    .voucher-table thead th {
        background: #f8fafc;

        color: #64748b;

        text-transform: uppercase;
        letter-spacing: 0.04em;

        font-size: 0.72rem;
        font-weight: 600;

        padding: 16px 18px;

        border-bottom: 1px solid #e2e8f0;

        white-space: nowrap;
    }

    .voucher-table tbody td {
        padding: 17px 18px;
        vertical-align: middle;

        font-size: 0.86rem;
        color: #334155;

        border-bottom: 1px solid #f1f5f9;
    }

    .voucher-id {
        background: #f8fafc;

        border: 1px solid #e2e8f0;
        border-radius: 6px;

        padding: 3px 7px;

        color: #64748b;
        font-size: 0.75rem;
    }

    .voucher-code {
        color: #0f172a;
        font-weight: 700;
    }

    .badge-percent {
        display: inline-flex;
        align-items: center;
        gap: 5px;

        padding: 5px 10px;

        border-radius: 999px;

        background: #dbeafe;
        border: 1px solid #bfdbfe;

        color: #1d4ed8;

        font-size: 0.75rem;
        font-weight: 600;
    }

    .badge-amount {
        display: inline-flex;
        align-items: center;
        gap: 5px;

        padding: 5px 10px;

        border-radius: 999px;

        background: #dcfce7;
        border: 1px solid #bbf7d0;

        color: #15803d;

        font-size: 0.75rem;
        font-weight: 600;
    }

    /* ================= ACTION ================= */

    .action-btn {
        width: 36px;
        height: 36px;

        display: inline-flex;
        align-items: center;
        justify-content: center;

        border-radius: 8px;

        text-decoration: none;

        transition: 0.2s;
    }

    .edit-btn {
        color: #2563eb;
        background: white;
        border: 1px solid #dbeafe;
    }

    .edit-btn:hover {
        background: #eff6ff;
        color: #1d4ed8;
    }

    .delete-btn {
        color: #ef4444;
        background: white;
        border: 1px solid #e2e8f0;
    }

    .delete-btn:hover {
        background: #fef2f2;
        color: #dc2626;
        border-color: #fecaca;
    }
</style>


<div class="voucher-page">

    <!-- HEADER -->

    <div class="d-flex justify-content-between align-items-center mb-4">

        <div>

            <h1 class="page-title">
                Quản lý Voucher
            </h1>

            <div class="page-description">
                Quản lý mã giảm giá và chương trình khuyến mãi trong hệ thống.
            </div>

        </div>

        <a href="${pageContext.request.contextPath}/voucher?view=create"
           class="btn-create">

            <i class="bi bi-plus-lg"></i>

            Tạo mới

        </a>

    </div>


    <!-- MESSAGE -->

    <c:if test="${not empty sessionScope.successMessage}">

        <div class="alert alert-success alert-dismissible fade show">

            <i class="bi bi-check-circle-fill me-2"></i>

            ${sessionScope.successMessage}

            <button type="button"
                    class="btn-close"
                    data-bs-dismiss="alert">
            </button>

        </div>

        <c:remove var="successMessage" scope="session"/>

    </c:if>


    <c:if test="${not empty sessionScope.errorMessage}">

        <div class="alert alert-danger alert-dismissible fade show">

            <i class="bi bi-exclamation-circle-fill me-2"></i>

            ${sessionScope.errorMessage}

            <button type="button"
                    class="btn-close"
                    data-bs-dismiss="alert">
            </button>

        </div>

        <c:remove var="errorMessage" scope="session"/>

    </c:if>


    <!-- STAT CARD -->

    <div class="row g-3 mb-4">

        <div class="col-lg-4">

            <div class="stat-card">

                <div class="d-flex justify-content-between">

                    <div>

                        <div class="stat-label">
                            Tổng Voucher
                        </div>

                        <div class="stat-value">

                            ${vouchers.size()}

                            <span class="stat-note">
                                mã giảm giá
                            </span>

                        </div>

                    </div>

                    <div class="stat-icon">

                        <i class="bi bi-ticket-perforated-fill"></i>

                    </div>

                </div>

            </div>

        </div>


        <div class="col-lg-4">

            <div class="stat-card">

                <div class="d-flex justify-content-between">

                    <div>

                        <div class="stat-label">
                            Loại giảm giá
                        </div>

                        <div class="stat-value">

                            2

                            <span class="stat-note">
                                hình thức
                            </span>

                        </div>

                    </div>

                    <div class="stat-icon stat-green">

                        <i class="bi bi-percent"></i>

                    </div>

                </div>

            </div>

        </div>


        <div class="col-lg-4">

            <div class="stat-card">

                <div class="d-flex justify-content-between">

                    <div>

                        <div class="stat-label">
                            Quản lý
                        </div>

                        <div class="stat-value">

                            CRUD

                            <span class="stat-note">
                                Voucher
                            </span>

                        </div>

                    </div>

                    <div class="stat-icon stat-cyan">

                        <i class="bi bi-shield-check"></i>

                    </div>

                </div>

            </div>

        </div>

    </div>


    <!-- TABLE -->

    <div class="voucher-card">

        <div class="voucher-card-header">

            <h5 class="card-title-custom">

                <i class="bi bi-ticket-detailed me-2 text-primary"></i>

                Danh sách Voucher

            </h5>

            <span class="text-muted small">

                Hiển thị

                <strong>${vouchers.size()}</strong>

                Voucher

            </span>

        </div>


        <div class="table-responsive">

            <table class="table voucher-table">

                <thead>

                    <tr>

                        <th>ID</th>

                        <th>Mã Voucher</th>

                        <th>Loại</th>

                        <th>Giá trị</th>

                        <th>Đơn tối thiểu</th>

                        <th>Giảm tối đa</th>

                        <th>Usage</th>

                        <th>Mỗi User</th>

                        <th>Thời gian</th>

                        <th class="text-center">
                            Thao tác
                        </th>

                    </tr>

                </thead>


                <tbody>

                    <c:choose>

                        <c:when test="${empty vouchers}">

                            <tr>

                                <td colspan="10"
                                    class="text-center text-muted py-5">

                                    <i class="bi bi-ticket-perforated fs-3 d-block mb-2"></i>

                                    Chưa có Voucher nào.

                                </td>

                            </tr>

                        </c:when>


                        <c:otherwise>

                            <c:forEach var="v" items="${vouchers}">

                                <tr>

                                    <td>

                                        <span class="voucher-id">
                                            #${v.voucherId}
                                        </span>

                                    </td>


                                    <td>

                                        <span class="voucher-code">
                                            ${v.code}
                                        </span>

                                    </td>


                                    <td>

                                        <c:choose>

                                            <c:when test="${v.discountType == 'PERCENT'}">

                                                <span class="badge-percent">

                                                    <i class="bi bi-percent"></i>

                                                    Phần trăm

                                                </span>

                                            </c:when>

                                            <c:otherwise>

                                                <span class="badge-amount">

                                                    <i class="bi bi-cash"></i>

                                                    Số tiền

                                                </span>

                                            </c:otherwise>

                                        </c:choose>

                                    </td>


                                    <td>

                                        <c:choose>

                                            <c:when test="${v.discountType == 'PERCENT'}">

                                                <strong>
                                                    ${v.discountValue}%
                                                </strong>

                                            </c:when>

                                            <c:otherwise>

                                                <strong>

                                                    <fmt:formatNumber
                                                        value="${v.discountValue}"
                                                        type="number"
                                                        groupingUsed="true"
                                                        maxFractionDigits="0"/>

                                                    đ

                                                </strong>

                                            </c:otherwise>

                                        </c:choose>

                                    </td>


                                    <td>

                                        <fmt:formatNumber
                                            value="${v.minOrderValue}"
                                            type="number"
                                            groupingUsed="true"
                                            maxFractionDigits="0"/>

                                        đ

                                    </td>


                                    <td>

                                        <c:choose>

                                            <c:when test="${empty v.maxDiscount}">

                                                <span class="text-muted">
                                                    —
                                                </span>

                                            </c:when>

                                            <c:otherwise>

                                                <fmt:formatNumber
                                                    value="${v.maxDiscount}"
                                                    type="number"
                                                    groupingUsed="true"
                                                    maxFractionDigits="0"/>

                                                đ

                                            </c:otherwise>

                                        </c:choose>

                                    </td>


                                    <td>

                                        <c:choose>

                                            <c:when test="${empty v.usageLimit}">
                                                ∞
                                            </c:when>

                                            <c:otherwise>
                                                ${v.usageLimit}
                                            </c:otherwise>

                                        </c:choose>

                                    </td>


                                    <td>

                                        <c:choose>

                                            <c:when test="${empty v.perUserLimit}">
                                                ∞
                                            </c:when>

                                            <c:otherwise>
                                                ${v.perUserLimit}
                                            </c:otherwise>

                                        </c:choose>

                                    </td>


                                    <td>

                                        <div class="small">

                                            <div>
                                                <fmt:formatDate
                                                    value="${v.validFrom}"
                                                    pattern="dd/MM/yyyy HH:mm"/>
                                            </div>

                                            <div class="text-muted my-1">
                                                đến
                                            </div>

                                            <div>
                                                <fmt:formatDate
                                                    value="${v.validTo}"
                                                    pattern="dd/MM/yyyy HH:mm"/>
                                            </div>

                                        </div>

                                    </td>


                                    <td class="text-center">

                                        <div class="d-flex justify-content-center gap-1">

                                            <a
                                                href="${pageContext.request.contextPath}/voucher?view=edit&id=${v.voucherId}"
                                                class="action-btn edit-btn"
                                                title="Chỉnh sửa">

                                                <i class="bi bi-pencil-square"></i>

                                            </a>


                                            <a
                                                href="${pageContext.request.contextPath}/voucher?view=delete&id=${v.voucherId}"
                                                class="action-btn delete-btn"
                                                title="Xóa">

                                                <i class="bi bi-trash3"></i>

                                            </a>

                                        </div>

                                    </td>

                                </tr>

                            </c:forEach>

                        </c:otherwise>

                    </c:choose>

                </tbody>

            </table>

        </div>

    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp" %>