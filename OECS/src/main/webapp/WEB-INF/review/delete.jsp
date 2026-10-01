<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

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
    }

    .delete-icon {
        width: 64px;
        height: 64px;

        margin: 0 auto 18px;

        display: flex;
        align-items: center;
        justify-content: center;

        border-radius: 16px;

        background: #fef2f2;
        color: #dc2626;

        font-size: 1.6rem;
    }

    .review-info {
        background: #f8fafc;

        border: 1px solid #e2e8f0;
        border-radius: 10px;

        margin: 25px 0;
        padding: 18px;

        text-align: left;
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

    .star-display {
        color: #f59e0b;
        letter-spacing: 2px;
    }

    .comment-box {
        margin-top: 15px;

        padding-top: 15px;

        border-top: 1px solid #e2e8f0;

        color: #475569;

        font-size: 0.9rem;
        line-height: 1.6;
    }

    .btn-delete {
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
            Xóa đánh giá
        </h1>

        <div class="page-description">
            Xác nhận trước khi xóa đánh giá của bạn.
        </div>

    </div>


    <div class="delete-card">

        <div class="delete-icon">

            <i class="bi bi-trash3"></i>

        </div>


        <h4 class="fw-bold">
            Bạn có chắc muốn xóa đánh giá?
        </h4>


        <p class="text-muted">
            Đánh giá này sẽ bị xóa khỏi hệ thống.
        </p>


        <div class="review-info">

            <div class="info-row">

                <span class="info-label">
                    Review ID
                </span>

                <span class="info-value">
                    #${review.reviewId}
                </span>

            </div>


            <div class="info-row">

                <span class="info-label">
                    Đánh giá
                </span>

                <span class="info-value star-display">

                    <c:forEach
                        begin="1"
                        end="${review.rating}">
                        ★
                    </c:forEach>

                </span>

            </div>


            <div class="info-row">

                <span class="info-label">
                    Số sao
                </span>

                <span class="info-value">
                    ${review.rating}/5
                </span>

            </div>


            <c:if test="${not empty review.comment}">

                <div class="comment-box">

                    ${review.comment}

                </div>

            </c:if>

        </div>


        <div class="alert alert-warning text-start">

            <i class="bi bi-exclamation-triangle-fill me-2"></i>

            Khi xóa đánh giá, các hình ảnh liên quan đến đánh giá
            cũng sẽ bị xóa khỏi cơ sở dữ liệu.

        </div>


        <form
            action="${pageContext.request.contextPath}/review"
            method="post">

            <input
                type="hidden"
                name="action"
                value="delete">

            <input
                type="hidden"
                name="reviewId"
                value="${review.reviewId}">


            <div class="d-flex justify-content-center gap-2 mt-4">

                <button
                    type="submit"
                    class="btn-delete">

                    <i class="bi bi-trash3 me-1"></i>

                    Xóa đánh giá

                </button>


                <a
                    href="${pageContext.request.contextPath}/orders"
                    class="btn-cancel">

                    Hủy

                </a>

            </div>

        </form>

    </div>

</div>


<%@include file="/WEB-INF/include/footer.jsp" %>