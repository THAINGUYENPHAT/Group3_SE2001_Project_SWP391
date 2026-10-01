<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .delete-page {
        max-width: 700px;
        margin: auto;
        padding-bottom: 30px;
    }

    .page-title {
        font-size: 1.55rem;
        font-weight: 700;
        color: #0f172a;
    }

    .page-description {
        color: #64748b;
        font-size: 0.9rem;
    }

    .delete-card {
        background: white;

        border: 1px solid #e2e8f0;
        border-radius: 14px;

        padding: 30px;
    }

    .delete-icon {
        width: 65px;
        height: 65px;

        margin: 0 auto 18px;

        display: flex;
        align-items: center;
        justify-content: center;

        background: #fef2f2;
        color: #dc2626;

        border-radius: 16px;

        font-size: 1.6rem;
    }

    .voucher-info {
        background: #f8fafc;

        border: 1px solid #e2e8f0;
        border-radius: 10px;

        padding: 18px;

        margin: 25px 0;
    }

    .info-row {
        display: flex;
        justify-content: space-between;

        padding: 7px 0;

        font-size: 0.9rem;
    }

    .info-label {
        color: #64748b;
    }

    .info-value {
        color: #0f172a;
        font-weight: 600;
    }

    .btn-delete {
        background: #dc2626;
        color: white;

        border: none;
        border-radius: 8px;

        padding: 10px 18px;

        font-weight: 600;
    }

    .btn-delete:hover {
        background: #b91c1c;
    }

    .btn-cancel {
        padding: 9px 18px;

        background: white;
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


    <div class="delete-card text-center">

        <div class="delete-icon">

            <i class="bi bi-trash3"></i>

        </div>


        <h4 class="fw-bold">
            Xác nhận xóa Voucher?
        </h4>


        <p class="text-muted">

            Bạn đang chuẩn bị xóa

            <strong class="text-dark">
                ${voucher.code}
            </strong>.

        </p>


        <div class="voucher-info text-start">

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
                    Loại giảm
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

                            ${voucher.discountValue}%

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

        </div>


        <div class="alert alert-warning text-start">

            <i class="bi bi-exclamation-triangle-fill me-2"></i>

            Voucher đã được sử dụng trong đơn hàng có thể không xóa được
            do ràng buộc dữ liệu.

        </div>


        <form
            action="${pageContext.request.contextPath}/voucher"
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

                    <i class="bi bi-trash3 me-1"></i>

                    Xóa Voucher

                </button>


                <a
                    href="${pageContext.request.contextPath}/voucher"
                    class="btn-cancel">

                    Hủy

                </a>

            </div>

        </form>

    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp" %>