<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .delete-page {
        max-width: 700px;
        margin: 0 auto;
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

    .delete-card {
        background: #ffffff;

        border: 1px solid #e2e8f0;
        border-radius: 14px;

        padding: 30px;

        text-align: center;

        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }

    .delete-icon {
        width: 64px;
        height: 64px;

        display: flex;
        align-items: center;
        justify-content: center;

        margin: 0 auto 18px;

        border-radius: 16px;

        background: #fef2f2;
        color: #dc2626;

        font-size: 1.6rem;
    }

    .voucher-info {
        background: #f8fafc;

        border: 1px solid #e2e8f0;
        border-radius: 10px;

        padding: 18px;

        margin: 25px 0;

        text-align: left;
    }

    .info-row {
        display: flex;
        justify-content: space-between;
        gap: 20px;

        padding: 8px 0;

        font-size: 0.9rem;
    }

    .info-label {
        color: #64748b;
    }

    .info-value {
        color: #0f172a;
        font-weight: 600;
        text-align: right;
    }

    .btn-delete {
        display: inline-flex;
        align-items: center;
        gap: 7px;

        padding: 10px 18px;

        border: none;
        border-radius: 8px;

        background: #dc2626;
        color: #ffffff;

        font-weight: 600;
    }

    .btn-delete:hover {
        background: #b91c1c;
    }

    .btn-cancel {
        display: inline-flex;
        align-items: center;
        gap: 6px;

        padding: 9px 18px;

        background: #ffffff;
        color: #475569;

        border: 1px solid #cbd5e1;
        border-radius: 8px;

        text-decoration: none;
    }

    .btn-cancel:hover {
        background: #f8fafc;
        color: #0f172a;
    }
</style>


<div class="delete-page">

    <div class="mb-4">

        <h1 class="page-title">
            Xóa Voucher
        </h1>

        <div class="page-description">
            Xác nhận trước khi xóa Voucher khỏi hệ thống.
        </div>

    </div>


    <div class="delete-card">

        <div class="delete-icon">

            <i class="bi bi-trash3"></i>

        </div>


        <h4 class="fw-bold">
            Xác nhận xóa Voucher?
        </h4>


        <p class="text-muted">

            Bạn đang chuẩn bị xóa Voucher

            <strong class="text-dark">
                ${voucher.code}
            </strong>.

        </p>


        <div class="voucher-info">


            <div class="info-row">

                <span class="info-label">
                    ID
                </span>

                <span class="info-value">
                    #${voucher.voucherId}
                </span>

            </div>


            <div class="info-row">

                <span class="info-label">
                    Mã Voucher
                </span>

                <span class="info-value">
                    ${voucher.code}
                </span>

            </div>


            <div class="info-row">

                <span class="info-label">
                    Loại giảm giá
                </span>

                <span class="info-value">

                    <c:choose>

                        <c:when test="${voucher.discountType == 'PERCENT'}">
                            Phần trăm
                        </c:when>

                        <c:otherwise>
                            Số tiền
                        </c:otherwise>

                    </c:choose>

                </span>

            </div>


            <div class="info-row">

                <span class="info-label">
                    Giá trị giảm
                </span>

                <span class="info-value">

                    <c:choose>

                        <c:when test="${voucher.discountType == 'PERCENT'}">

                            <fmt:formatNumber
                                value="${voucher.discountValue}"
                                type="number"
                                maxFractionDigits="2"/>

                            %

                        </c:when>

                        <c:otherwise>

                            <fmt:formatNumber
                                value="${voucher.discountValue}"
                                type="number"
                                groupingUsed="true"
                                maxFractionDigits="0"/>

                            đ

                        </c:otherwise>

                    </c:choose>

                </span>

            </div>


            <div class="info-row">

                <span class="info-label">
                    Đơn tối thiểu
                </span>

                <span class="info-value">

                    <fmt:formatNumber
                        value="${voucher.minOrderValue}"
                        type="number"
                        groupingUsed="true"
                        maxFractionDigits="0"/>

                    đ

                </span>

            </div>

        </div>


        <div class="alert alert-warning text-start">

            <i class="bi bi-exclamation-triangle-fill me-2"></i>

            Voucher đã được sử dụng có thể không xóa được
            do ràng buộc dữ liệu của đơn hàng.

        </div>


        <form
            action="${pageContext.request.contextPath}/admin/voucher"
            method="post">

            <input
                type="hidden"
                name="action"
                value="delete">

            <input
                type="hidden"
                name="voucherId"
                value="${voucher.voucherId}">


            <div class="d-flex justify-content-center gap-2 mt-4">

                <button
                    type="submit"
                    class="btn-delete">

                    <i class="bi bi-trash3"></i>

                    Xóa Voucher

                </button>


                <a
                    href="${pageContext.request.contextPath}/admin/voucher"
                    class="btn-cancel">

                    <i class="bi bi-x-lg"></i>

                    Hủy

                </a>

            </div>

        </form>

    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp" %>