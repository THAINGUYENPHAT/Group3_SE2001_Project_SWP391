
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<style>
    .review-detail-page {
        max-width: 860px;
        margin: 32px auto 60px;
        padding: 0 16px;
    }

    .review-detail-card {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        overflow: hidden;
        box-shadow: 0 5px 24px rgba(15, 23, 42, .04);
    }

    .review-detail-header {
        padding: 24px;
        border-bottom: 1px solid #e2e8f0;
    }

    .review-detail-header h1 {
        font-size: 23px;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 8px;
    }

    .review-detail-body {
        padding: 26px;
    }

    .review-detail-stars {
        display: flex;
        gap: 8px;
        font-size: 29px;
        margin-bottom: 14px;
    }

    .review-detail-comment {
        background: #f8fafc;
        padding: 20px;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        line-height: 1.8;
        color: #334155;
        white-space: pre-wrap;
        overflow-wrap: anywhere;
    }

    .review-detail-images {
        display: flex;
        flex-wrap: wrap;
        gap: 12px;
        margin-top: 20px;
    }

    .review-detail-images img {
        width: 135px;
        height: 135px;
        object-fit: cover;
        border-radius: 10px;
        border: 1px solid #e2e8f0;
    }

    .review-detail-actions {
        display: flex;
        justify-content: flex-end;
        gap: 12px;
        padding: 20px 24px;
        border-top: 1px solid #e2e8f0;
    }

    .review-detail-btn {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 11px 18px;
        border-radius: 9px;
        font-size: 14px;
        font-weight: 600;
        text-decoration: none;
        background: #2563eb;
        color: white;
    }

    .review-detail-btn:hover {
        background: #1d4ed8;
        color: white;
    }

    .review-detail-back {
        background: #fff;
        border: 1px solid #cbd5e1;
        color: #475569;
    }

    .review-detail-back:hover {
        background: #f8fafc;
        color: #0f172a;
    }
</style>

<main class="review-detail-page">

    <c:if test="${not empty sessionScope.successMessage}">
        <div class="alert alert-success">
            <c:out value="${sessionScope.successMessage}"/>
        </div>
        <c:remove var="successMessage" scope="session"/>
    </c:if>

    <div class="review-detail-card">

        <div class="review-detail-header">

            <h1>
                <i class="bi bi-patch-check-fill text-success me-2"></i>
                Đánh giá của bạn
            </h1>

            <p class="text-muted mb-0">
                Cảm ơn bạn đã chia sẻ trải nghiệm
                mua sắm tại OECS.
            </p>

        </div>

        <div class="review-detail-body">

            <div class="mb-4">

                <span class="badge bg-success-subtle text-success">
                    <i class="bi bi-check-circle me-1"></i>
                    Đã đánh giá
                </span>

                <span class="text-muted small ms-2">
                    <fmt:formatDate
                        value="${review.createdAt}"
                        pattern="dd/MM/yyyy HH:mm"/>
                </span>

            </div>

            <!-- RATING -->
            <h5 class="fw-bold mb-3">
                Chất lượng sản phẩm
            </h5>

            <div class="review-detail-stars"
                 aria-label="${review.rating} trên 5 sao">

                <c:forEach var="star" begin="1" end="5">
                    <i class="bi bi-star-fill
                       ${star le review.rating
                         ? 'text-warning'
                         : 'text-secondary'}"></i>
                </c:forEach>

            </div>

            <p class="text-muted mb-4">
                Bạn đã đánh giá
                <strong>
                    <c:out value="${review.rating}"/>/5 sao
                </strong>
            </p>

            <!-- COMMENT -->
            <h5 class="fw-bold mb-3">
                Nhận xét
            </h5>

            <div class="review-detail-comment"><c:out
                value="${review.comment}"
                default="Không có nhận xét chi tiết."/></div>

            <!-- IMAGES -->
            <c:if test="${not empty review.images}">

                <h5 class="fw-bold mt-4 mb-3">
                    Hình ảnh đánh giá
                </h5>

                <div class="review-detail-images">

                    <c:forEach var="imagePath"
                               items="${review.images}">

                        <c:url var="reviewImageUrl"
                               value="${imagePath}"/>

                        <img src="<c:out value='${reviewImageUrl}'/>"
                             alt="Hình ảnh đánh giá sản phẩm"
                             loading="lazy">

                    </c:forEach>

                </div>

            </c:if>

        </div>

        <!-- BUTTONS -->
        <div class="review-detail-actions">

            <a href="${pageContext.request.contextPath}/my-orders"
               class="review-detail-btn review-detail-back">

                <i class="bi bi-arrow-left"></i>
                Đơn mua

            </a>

            <c:url var="editReviewUrl" value="/review">
                <c:param name="view" value="edit"/>
                <c:param name="id"
                         value="${review.reviewId}"/>
            </c:url>

            <a href="${editReviewUrl}"
               class="review-detail-btn">

                <i class="bi bi-pencil-square"></i>
                Sửa đánh giá

            </a>

        </div>

    </div>

</main>

<%@include file="/WEB-INF/include/footer.jsp"%>
