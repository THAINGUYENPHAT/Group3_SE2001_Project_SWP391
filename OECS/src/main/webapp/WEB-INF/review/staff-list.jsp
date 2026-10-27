<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="container-fluid px-4 py-4">

    <div class="mb-4">
        <h2 class="fw-bold">Quản lý đánh giá &amp; bình luận</h2>
        <p class="text-muted">
            Kiểm duyệt đánh giá và xử lý báo cáo từ khách hàng.
        </p>
    </div>

    <c:if test="${param.error eq '1'}">
        <div class="alert alert-danger">
            Không thể thực hiện thao tác. Vui lòng thử lại.
        </div>
    </c:if>

    <!-- BẢNG ĐÁNH GIÁ -->
    <div class="card border-0 shadow-sm mb-5">
        <div class="card-header bg-white py-3">
            <h5 class="fw-bold mb-0">Danh sách đánh giá</h5>
        </div>

        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Sản phẩm</th>
                        <th>Người đánh giá</th>
                        <th>Điểm</th>
                        <th>Bình luận</th>
                        <th>Ngày tạo</th>
                        <th>Trạng thái</th>
                        <th>Thao tác</th>
                    </tr>
                </thead>

                <tbody>
                    <c:forEach items="${reviews}" var="review">
                        <tr>
                            <td>
                                <div class="fw-semibold">
                                    <c:out value="${review.productName}"/>
                                </div>
                                <small class="text-muted">
                                    SKU:
                                    <c:out value="${review.skuCode}"/>
                                </small>
                            </td>

                            <td>
                                <c:out value="${review.reviewerName}"/>
                            </td>

                            <td class="text-warning text-nowrap">
                                <strong>${review.rating}/5</strong>
                                <i class="bi bi-star-fill"></i>
                            </td>

                            <td style="min-width: 220px; max-width: 350px;">
                                <div style="white-space: pre-line;">
                                    <c:out value="${review.comment}"/>
                                </div>
                            </td>

                            <td class="text-nowrap">
                                <fmt:formatDate
                                    value="${review.createdAt}"
                                    pattern="dd/MM/yyyy HH:mm"/>
                            </td>

                            <td>
                                <c:choose>
                                    <c:when test="${review.isHidden}">
                                        <span class="badge bg-secondary">
                                            Đã ẩn
                                        </span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge bg-success">
                                            Đang hiển thị
                                        </span>
                                    </c:otherwise>
                                </c:choose>
                            </td>

                            <td>
                                <form method="POST"
                                      action="${pageContext.request.contextPath}/staff/reviews">

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

                                    <c:choose>
                                        <c:when test="${review.isHidden}">
                                            <button type="submit"
                                                    class="btn btn-sm btn-outline-success">
                                                <i class="bi bi-eye me-1"></i>
                                                Hiện lại
                                            </button>
                                        </c:when>

                                        <c:otherwise>
                                            <button type="submit"
                                                    class="btn btn-sm btn-outline-danger">
                                                <i class="bi bi-eye-slash me-1"></i>
                                                Ẩn
                                            </button>
                                        </c:otherwise>
                                    </c:choose>
                                </form>
                            </td>
                        </tr>
                    </c:forEach>

                    <c:if test="${empty reviews}">
                        <tr>
                            <td colspan="7"
                                class="text-center text-muted py-4">
                                Chưa có đánh giá nào.
                            </td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </div>

    <!-- BẢNG BÁO CÁO -->
    <div class="card border-0 shadow-sm">
        <div class="card-header bg-white py-3">
            <h5 class="fw-bold mb-0">Báo cáo đánh giá</h5>
        </div>

        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Sản phẩm</th>
                        <th>Đánh giá bị báo cáo</th>
                        <th>Người báo cáo</th>
                        <th>Lý do</th>
                        <th>Ngày báo cáo</th>
                        <th>Trạng thái</th>
                        <th>Xử lý</th>
                    </tr>
                </thead>

                <tbody>
                    <c:forEach items="${reports}" var="report">
                        <tr>
                            <td>
                                <div class="fw-semibold">
                                    <c:out value="${report.productName}"/>
                                </div>
                                <small class="text-muted">
                                    SKU: <c:out value="${report.skuCode}"/>
                                </small>
                            </td>

                            <td style="min-width: 220px;">
                                <div class="fw-semibold">
                                    <c:out value="${report.reviewAuthor}"/>
                                </div>
                                <div class="text-warning">
                                    ${report.rating}/5
                                    <i class="bi bi-star-fill"></i>
                                </div>
                                <div style="white-space: pre-line;">
                                    <c:out value="${report.comment}"/>
                                </div>
                            </td>

                            <td>
                                <c:out value="${report.reporterName}"/>
                            </td>

                            <td style="min-width: 180px;">
                                <c:out value="${report.reason}"/>
                            </td>

                            <td class="text-nowrap">
                                <fmt:formatDate
                                    value="${report.createdAt}"
                                    pattern="dd/MM/yyyy HH:mm"/>
                            </td>

                            <td>
                                <c:choose>
                                    <c:when test="${report.status eq 'PENDING'}">
                                        <span class="badge bg-warning text-dark">
                                            Đang chờ
                                        </span>
                                    </c:when>
                                    <c:when test="${report.status eq 'RESOLVED'}">
                                        <span class="badge bg-success">
                                            Đã xử lý
                                        </span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge bg-secondary">
                                            Đã từ chối
                                        </span>
                                    </c:otherwise>
                                </c:choose>
                            </td>

                            <td>
                                <c:if test="${report.status eq 'PENDING'}">
                                    <form method="POST"
                                          action="${pageContext.request.contextPath}/staff/reviews"
                                          class="d-flex flex-column gap-2">

                                        <input type="hidden"
                                               name="csrfToken"
                                               value="${sessionScope.reviewCsrfToken}">

                                        <input type="hidden"
                                               name="action"
                                               value="resolveReport">

                                        <input type="hidden"
                                               name="reportId"
                                               value="${report.reportId}">

                                        <button type="submit"
                                                name="decision"
                                                value="HIDE"
                                                class="btn btn-sm btn-danger">
                                            Chấp nhận &amp; ẩn
                                        </button>

                                        <button type="submit"
                                                name="decision"
                                                value="DISMISS"
                                                class="btn btn-sm btn-outline-secondary">
                                            Từ chối báo cáo
                                        </button>
                                    </form>
                                </c:if>
                            </td>
                        </tr>
                    </c:forEach>

                    <c:if test="${empty reports}">
                        <tr>
                            <td colspan="7"
                                class="text-center text-muted py-4">
                                Chưa có báo cáo nào.
                            </td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp"%>