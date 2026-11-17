
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@include file="/WEB-INF/include/header.jsp"%>

<style>
    .staff-review-page {
        padding: 22px 0 45px;
    }

    .review-stat {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 15px;
        padding: 20px 23px;
        height: 100%;
    }

    .review-stat span {
        color: #64748b;
        font-size: 13px;
    }

    .review-stat strong {
        display: block;
        font-size: 29px;
        color: #0f172a;
        margin-top: 5px;
    }

    .review-panel {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 15px;
        overflow: hidden;
        margin-top: 24px;
    }

    .review-panel-head {
        padding: 20px 22px;
        border-bottom: 1px solid #e2e8f0;
    }

    .review-panel-head h5 {
        font-weight: 750;
        margin: 0;
    }

    .review-filter-bar {
        display: flex;
        flex-wrap: wrap;
        gap: 9px;
        padding: 14px 22px;
        border-bottom: 1px solid #e2e8f0;
    }

    .review-filter {
        border-radius: 9px;
        border: 1px solid #dbe3ed;
        background: #fff;
        color: #475569;
        text-decoration: none;
        padding: 7px 12px;
        font-size: 13px;
        font-weight: 650;
    }

    .review-filter:hover,
    .review-filter.active {
        color: #0d6efd;
        background: #eaf2ff;
        border-color: #93c5fd;
    }

    .review-compact th {
        background: #f8fafc;
        color: #64748b;
        font-size: 12px;
        text-transform: uppercase;
        font-weight: 700;
        white-space: nowrap;
    }

    .review-compact th,
    .review-compact td {
        padding: 15px 18px;
        vertical-align: middle;
    }

    .review-compact td {
        color: #334155;
    }

    .review-state {
        font-size: 12px;
        font-weight: 700;
        padding: 6px 9px;
        border-radius: 8px;
        white-space: nowrap;
    }

    .review-state.visible,
    .review-state.resolved {
        background: #dcfce7;
        color: #047857;
    }

    .review-state.hidden,
    .review-state.rejected {
        background: #f1f5f9;
        color: #64748b;
    }

    .review-state.pending {
        background: #fef3c7;
        color: #92400e;
    }

    .review-actions {
        display: flex;
        align-items: center;
        gap: 7px;
        justify-content: flex-end;
    }

    .review-icon-button {
        width: 35px;
        height: 35px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border-radius: 9px;
        background: #fff;
        color: #2563eb;
        border: 1px solid #bfdbfe;
    }

    .review-icon-button:hover {
        background: #eff6ff;
    }

    .review-icon-button.danger {
        color: #dc2626;
        border-color: #fecaca;
    }

    .review-icon-button.danger:hover {
        background: #fff1f2;
    }

    .review-icon-button.success {
        color: #047857;
        border-color: #bbf7d0;
    }

    .review-icon-button.success:hover {
        background: #ecfdf5;
    }

    .review-description {
        white-space: pre-wrap;
        overflow-wrap: anywhere;
    }

    .review-photo {
        width: 105px;
        height: 105px;
        object-fit: cover;
        border-radius: 9px;
        border: 1px solid #e2e8f0;
    }

    .review-detail-box {
        background: #f8fafc;
        padding: 13px 15px;
        border-radius: 10px;
        border: 1px solid #e2e8f0;
        height: 100%;
    }

    .review-detail-box small {
        display: block;
        color: #64748b;
        margin-bottom: 4px;
    }

    .review-detail-box strong {
        color: #0f172a;
    }
</style>

<div class="container-fluid px-4 staff-review-page">

    <h2 class="fw-bold mb-1">
        Quản lý đánh giá &amp; bình luận
    </h2>

    <p class="text-muted mb-4">
        Kiểm duyệt đánh giá và xử lý báo cáo của khách hàng.
    </p>

    <c:if test="${not empty sessionScope.successMessage}">
        <div class="alert alert-success">
            <c:out value="${sessionScope.successMessage}"/>
        </div>
        <c:remove var="successMessage" scope="session"/>
    </c:if>

    <c:if test="${not empty sessionScope.errorMessage}">
        <div class="alert alert-danger">
            <c:out value="${sessionScope.errorMessage}"/>
        </div>
        <c:remove var="errorMessage" scope="session"/>
    </c:if>

    <div class="row g-3">

        <div class="col-md-4">
            <div class="review-stat">
                <span>Tổng đánh giá</span>
                <strong>
                    <c:out value="${allReviewCount}" default="0"/>
                </strong>
            </div>
        </div>

        <div class="col-md-4">
            <div class="review-stat">
                <span>Đánh giá đang hiển thị</span>
                <strong>
                    <c:out value="${visibleReviewCount}" default="0"/>
                </strong>
            </div>
        </div>

        <div class="col-md-4">
            <div class="review-stat">
                <span>Báo cáo đang chờ</span>
                <strong>
                    <c:out value="${pendingReportCount}" default="0"/>
                </strong>
            </div>
        </div>

    </div>

    <section class="review-panel" id="reviews">

        <div class="review-panel-head d-flex justify-content-between align-items-center gap-2">
            <h5>
                <i class="bi bi-star me-2 text-warning"></i>
                Danh sách đánh giá
            </h5>
            <small class="text-muted">
                Hiển thị <c:out value="${reviews.size()}"/> đánh giá
            </small>
        </div>

        <div class="review-filter-bar">

            <a class="review-filter ${reviewStatusFilter eq 'all' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/reviews?reviewStatus=all&amp;reportStatus=${reportStatusFilter}#reviews">
                Tất cả (<c:out value="${allReviewCount}"/>)
            </a>

            <a class="review-filter ${reviewStatusFilter eq 'visible' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/reviews?reviewStatus=visible&amp;reportStatus=${reportStatusFilter}#reviews">
                Đang hiển thị (<c:out value="${visibleReviewCount}"/>)
            </a>

            <a class="review-filter ${reviewStatusFilter eq 'hidden' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/reviews?reviewStatus=hidden&amp;reportStatus=${reportStatusFilter}#reviews">
                Đã ẩn (<c:out value="${hiddenReviewCount}"/>)
            </a>

        </div>

        <div class="table-responsive">
            <table class="table table-hover review-compact mb-0">

                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Sản phẩm</th>
                        <th>Rating</th>
                        <th>Trạng thái</th>
                        <th>Ngày đánh giá</th>
                        <th class="text-end">Thao tác</th>
                    </tr>
                </thead>

                <tbody>
                    <c:forEach items="${reviews}" var="review">
                        <tr>

                            <td>
                                #<c:out value="${review.reviewId}"/>
                            </td>

                            <td class="fw-semibold">
                                <c:out value="${review.productName}"/>
                            </td>

                            <td class="text-warning fw-bold text-nowrap">
                                <c:out value="${review.rating}"/>/5
                                <i class="bi bi-star-fill"></i>
                            </td>

                            <td>
                                <c:choose>
                                    <c:when test="${review.isHidden}">
                                        <span class="review-state hidden">
                                            Đã ẩn
                                        </span>
                                    </c:when>

                                    <c:otherwise>
                                        <span class="review-state visible">
                                            Đang hiển thị
                                        </span>
                                    </c:otherwise>
                                </c:choose>
                            </td>

                            <td class="text-nowrap">
                                <fmt:formatDate
                                    value="${review.createdAt}"
                                    pattern="dd/MM/yyyy HH:mm"/>
                            </td>

                            <td>
                                <div class="review-actions">

                                    <button class="review-icon-button"
                                            type="button"
                                            title="Xem chi tiết"
                                            data-bs-toggle="modal"
                                            data-bs-target="#reviewDetail${review.reviewId}">
                                        <i class="bi bi-eye"></i>
                                    </button>

                                    <form method="post"
                                          action="${pageContext.request.contextPath}/staff/reviews"
                                          class="m-0">

                                        <input type="hidden"
                                               name="csrfToken"
                                               value="${sessionScope.reviewCsrfToken}">
                                        <input type="hidden"
                                               name="action"
                                               value="visibility">
                                        <input type="hidden"
                                               name="reviewId"
                                               value="${review.reviewId}">
                                        <input type="hidden"
                                               name="hidden"
                                               value="${not review.isHidden}">
                                        <input type="hidden"
                                               name="reviewStatus"
                                               value="${reviewStatusFilter}">
                                        <input type="hidden"
                                               name="reportStatus"
                                               value="${reportStatusFilter}">

                                        <c:choose>
                                            <c:when test="${review.isHidden}">
                                                <button type="submit"
                                                        title="Hiện lại"
                                                        class="review-icon-button success">
                                                    <i class="bi bi-eye-fill"></i>
                                                </button>
                                            </c:when>

                                            <c:otherwise>
                                                <button type="submit"
                                                        title="Ẩn đánh giá"
                                                        class="review-icon-button danger">
                                                    <i class="bi bi-eye-slash"></i>
                                                </button>
                                            </c:otherwise>
                                        </c:choose>
                                    </form>

                                </div>
                            </td>

                        </tr>
                    </c:forEach>

                    <c:if test="${empty reviews}">
                        <tr>
                            <td colspan="6"
                                class="text-center text-muted py-5">
                                Không có đánh giá phù hợp với bộ lọc.
                            </td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </section>

    <c:forEach items="${reviews}" var="review">

        <div class="modal fade"
             id="reviewDetail${review.reviewId}"
             tabindex="-1"
             aria-labelledby="reviewTitle${review.reviewId}"
             aria-hidden="true">

            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
                <div class="modal-content">

                    <div class="modal-header">
                        <h5 class="modal-title fw-bold"
                            id="reviewTitle${review.reviewId}">
                            Đánh giá #<c:out value="${review.reviewId}"/>
                            –
                            <c:out value="${review.productName}"/>
                        </h5>

                        <button type="button"
                                class="btn-close"
                                data-bs-dismiss="modal"
                                aria-label="Đóng">
                        </button>
                    </div>

                    <div class="modal-body">

                        <div class="row g-3 mb-3">

                            <div class="col-md-6">
                                <div class="review-detail-box">
                                    <small>Người đánh giá</small>
                                    <strong>
                                        <c:out value="${review.reviewerName}"/>
                                    </strong>
                                </div>
                            </div>

                            <div class="col-md-6">
                                <div class="review-detail-box">
                                    <small>SKU / Mục hàng</small>
                                    <strong>
                                        <c:out value="${review.skuCode}"/>
                                        /
                                        #<c:out value="${review.orderItemId}"/>
                                    </strong>
                                </div>
                            </div>

                            <div class="col-md-6">
                                <div class="review-detail-box">
                                    <small>Rating</small>
                                    <strong class="text-warning">
                                        <c:out value="${review.rating}"/>/5 sao
                                    </strong>
                                </div>
                            </div>

                            <div class="col-md-6">
                                <div class="review-detail-box">
                                    <small>Ngày tạo</small>
                                    <strong>
                                        <fmt:formatDate
                                            value="${review.createdAt}"
                                            pattern="dd/MM/yyyy HH:mm"/>
                                    </strong>
                                </div>
                            </div>

                        </div>

                        <h6 class="fw-bold">Nội dung đánh giá</h6>

                        <div class="review-detail-box review-description mb-3">
                            <c:out value="${review.comment}"
                                   default="Không có bình luận."/>
                        </div>

                        <c:if test="${not empty review.images}">
                            <h6 class="fw-bold">Ảnh đánh giá</h6>

                            <div class="d-flex flex-wrap gap-2">
                                <c:forEach var="photo"
                                           items="${review.images}">

                                    <c:url var="photoUrl"
                                           value="${photo}"/>

                                    <a href="${photoUrl}"
                                       target="_blank"
                                       rel="noopener noreferrer">

                                        <img class="review-photo"
                                             src="${photoUrl}"
                                             alt="Ảnh đánh giá"
                                             loading="lazy"/>
                                    </a>

                                </c:forEach>
                            </div>
                        </c:if>

                    </div>

                    <div class="modal-footer">

                        <button type="button"
                                class="btn btn-outline-secondary"
                                data-bs-dismiss="modal">
                            Đóng
                        </button>

                        <form method="post"
                              action="${pageContext.request.contextPath}/staff/reviews"
                              class="m-0">

                            <input type="hidden"
                                   name="csrfToken"
                                   value="${sessionScope.reviewCsrfToken}">
                            <input type="hidden"
                                   name="action"
                                   value="visibility">
                            <input type="hidden"
                                   name="reviewId"
                                   value="${review.reviewId}">
                            <input type="hidden"
                                   name="hidden"
                                   value="${not review.isHidden}">
                            <input type="hidden"
                                   name="reviewStatus"
                                   value="${reviewStatusFilter}">
                            <input type="hidden"
                                   name="reportStatus"
                                   value="${reportStatusFilter}">

                            <c:choose>
                                <c:when test="${review.isHidden}">
                                    <button class="btn btn-outline-success"
                                            type="submit">
                                        Hiện lại
                                    </button>
                                </c:when>

                                <c:otherwise>
                                    <button class="btn btn-outline-danger"
                                            type="submit">
                                        Ẩn đánh giá
                                    </button>
                                </c:otherwise>
                            </c:choose>

                        </form>
                    </div>

                </div>
            </div>
        </div>

    </c:forEach>

    <section class="review-panel" id="reports">

        <div class="review-panel-head d-flex justify-content-between align-items-center gap-2">
            <h5>
                <i class="bi bi-flag me-2 text-danger"></i>
                Báo cáo đánh giá
            </h5>

            <small class="text-muted">
                Hiển thị <c:out value="${reports.size()}"/> báo cáo
            </small>
        </div>

        <div class="review-filter-bar">

            <a class="review-filter ${reportStatusFilter eq 'all' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/reviews?reviewStatus=${reviewStatusFilter}&amp;reportStatus=all#reports">
                Tất cả (<c:out value="${allReportCount}"/>)
            </a>

            <a class="review-filter ${reportStatusFilter eq 'pending' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/reviews?reviewStatus=${reviewStatusFilter}&amp;reportStatus=pending#reports">
                Đang chờ (<c:out value="${pendingReportCount}"/>)
            </a>

            <a class="review-filter ${reportStatusFilter eq 'resolved' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/reviews?reviewStatus=${reviewStatusFilter}&amp;reportStatus=resolved#reports">
                Đã xử lý (<c:out value="${resolvedReportCount}"/>)
            </a>

            <a class="review-filter ${reportStatusFilter eq 'rejected' ? 'active' : ''}"
               href="${pageContext.request.contextPath}/staff/reviews?reviewStatus=${reviewStatusFilter}&amp;reportStatus=rejected#reports">
                Đã từ chối (<c:out value="${rejectedReportCount}"/>)
            </a>

        </div>

        <div class="table-responsive">
            <table class="table table-hover review-compact mb-0">

                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Sản phẩm</th>
                        <th>Trạng thái</th>
                        <th>Ngày báo cáo</th>
                        <th class="text-end">Thao tác</th>
                    </tr>
                </thead>

                <tbody>
                    <c:forEach items="${reports}" var="report">
                        <tr>

                            <td>
                                #<c:out value="${report.reportId}"/>
                            </td>

                            <td class="fw-semibold">
                                <c:out value="${report.productName}"/>
                            </td>

                            <td>
                                <c:choose>
                                    <c:when test="${report.status eq 'PENDING'}">
                                        <span class="review-state pending">
                                            Đang chờ
                                        </span>
                                    </c:when>

                                    <c:when test="${report.status eq 'RESOLVED'}">
                                        <span class="review-state resolved">
                                            Đã xử lý
                                        </span>
                                    </c:when>

                                    <c:otherwise>
                                        <span class="review-state rejected">
                                            Đã từ chối
                                        </span>
                                    </c:otherwise>
                                </c:choose>
                            </td>

                            <td class="text-nowrap">
                                <fmt:formatDate
                                    value="${report.createdAt}"
                                    pattern="dd/MM/yyyy HH:mm"/>
                            </td>

                            <td>
                                <div class="review-actions">

                                    <button type="button"
                                            title="Xem chi tiết báo cáo"
                                            class="review-icon-button"
                                            data-bs-toggle="modal"
                                            data-bs-target="#reportDetail${report.reportId}">
                                        <i class="bi bi-eye"></i>
                                    </button>

                                    <c:if test="${report.status eq 'PENDING'}">

                                        <form method="post"
                                              action="${pageContext.request.contextPath}/staff/reviews"
                                              class="d-flex gap-2 m-0">

                                            <input type="hidden"
                                                   name="csrfToken"
                                                   value="${sessionScope.reviewCsrfToken}">
                                            <input type="hidden"
                                                   name="action"
                                                   value="resolveReport">
                                            <input type="hidden"
                                                   name="reportId"
                                                   value="${report.reportId}">
                                            <input type="hidden"
                                                   name="reviewStatus"
                                                   value="${reviewStatusFilter}">
                                            <input type="hidden"
                                                   name="reportStatus"
                                                   value="${reportStatusFilter}">

                                            <button type="submit"
                                                    name="decision"
                                                    value="HIDE"
                                                    title="Chấp nhận và ẩn"
                                                    class="review-icon-button danger">
                                                <i class="bi bi-eye-slash"></i>
                                            </button>

                                            <button type="submit"
                                                    name="decision"
                                                    value="DISMISS"
                                                    title="Từ chối báo cáo"
                                                    class="review-icon-button">
                                                <i class="bi bi-x-lg"></i>
                                            </button>

                                        </form>
                                    </c:if>
                                </div>
                            </td>

                        </tr>
                    </c:forEach>

                    <c:if test="${empty reports}">
                        <tr>
                            <td colspan="5"
                                class="text-center text-muted py-5">
                                Không có báo cáo phù hợp với bộ lọc.
                            </td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>

    </section>

    <c:forEach items="${reports}" var="report">

        <div class="modal fade"
             id="reportDetail${report.reportId}"
             tabindex="-1"
             aria-labelledby="reportTitle${report.reportId}"
             aria-hidden="true">

            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
                <div class="modal-content">

                    <div class="modal-header">
                        <h5 class="modal-title fw-bold"
                            id="reportTitle${report.reportId}">
                            Báo cáo #<c:out value="${report.reportId}"/>
                            –
                            <c:out value="${report.productName}"/>
                        </h5>

                        <button type="button"
                                class="btn-close"
                                data-bs-dismiss="modal"
                                aria-label="Đóng">
                        </button>
                    </div>

                    <div class="modal-body">

                        <div class="row g-3 mb-3">

                            <div class="col-md-6">
                                <div class="review-detail-box">
                                    <small>Người báo cáo</small>
                                    <strong>
                                        <c:out value="${report.reporterName}"/>
                                    </strong>
                                </div>
                            </div>

                            <div class="col-md-6">
                                <div class="review-detail-box">
                                    <small>Người đánh giá</small>
                                    <strong>
                                        <c:out value="${report.reviewAuthor}"/>
                                    </strong>
                                </div>
                            </div>

                            <div class="col-md-6">
                                <div class="review-detail-box">
                                    <small>Rating / SKU</small>
                                    <strong>
                                        <c:out value="${report.rating}"/>/5
                                        –
                                        <c:out value="${report.skuCode}"/>
                                    </strong>
                                </div>
                            </div>

                            <div class="col-md-6">
                                <div class="review-detail-box">
                                    <small>Ngày báo cáo</small>
                                    <strong>
                                        <fmt:formatDate
                                            value="${report.createdAt}"
                                            pattern="dd/MM/yyyy HH:mm"/>
                                    </strong>
                                </div>
                            </div>

                        </div>

                        <h6 class="fw-bold">Lý do báo cáo</h6>

                        <div class="review-detail-box review-description mb-3">
                            <c:out value="${report.reason}"/>
                        </div>

                        <h6 class="fw-bold">
                            Nội dung đánh giá bị báo cáo
                        </h6>

                        <div class="review-detail-box review-description mb-3">
                            <c:out value="${report.comment}"/>
                        </div>

                        <c:if test="${not empty report.resolverName}">
                            <p class="text-muted small">
                                Người xử lý:
                                <c:out value="${report.resolverName}"/>
                                –
                                <fmt:formatDate
                                    value="${report.resolvedAt}"
                                    pattern="dd/MM/yyyy HH:mm"/>
                            </p>
                        </c:if>

                    </div>

                    <div class="modal-footer">

                        <button type="button"
                                class="btn btn-outline-secondary"
                                data-bs-dismiss="modal">
                            Đóng
                        </button>

                        <c:if test="${report.status eq 'PENDING'}">

                            <form method="post"
                                  action="${pageContext.request.contextPath}/staff/reviews"
                                  class="d-flex gap-2 m-0">

                                <input type="hidden"
                                       name="csrfToken"
                                       value="${sessionScope.reviewCsrfToken}">
                                <input type="hidden"
                                       name="action"
                                       value="resolveReport">
                                <input type="hidden"
                                       name="reportId"
                                       value="${report.reportId}">
                                <input type="hidden"
                                       name="reviewStatus"
                                       value="${reviewStatusFilter}">
                                <input type="hidden"
                                       name="reportStatus"
                                       value="${reportStatusFilter}">

                                <button type="submit"
                                        name="decision"
                                        value="HIDE"
                                        class="btn btn-danger">
                                    Chấp nhận &amp; ẩn
                                </button>

                                <button type="submit"
                                        name="decision"
                                        value="DISMISS"
                                        class="btn btn-outline-secondary">
                                    Từ chối
                                </button>

                            </form>
                        </c:if>
                    </div>

                </div>
            </div>
        </div>

    </c:forEach>
</div>

<%@include file="/WEB-INF/include/footer.jsp"%>
