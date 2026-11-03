<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .return-detail {
        color: #263238;
    }

    .return-detail .page-description {
        color: #64748b;
        font-size: 14px;
    }

    .return-detail .detail-card {
        background: #fff;
        border: 1px solid #edf0f5;
        border-radius: 12px;
        padding: 24px;
        margin-bottom: 20px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, .03);
    }

    .return-detail .section-title {
        font-size: 17px;
        font-weight: 700;
        margin-bottom: 20px;
        color: #263238;
    }

    .return-detail .info-item {
        background: #f8fafc;
        border: 1px solid #edf0f5;
        border-radius: 9px;
        padding: 14px;
        height: 100%;
        min-width: 0;
    }

    .return-detail .info-label {
        display: block;
        color: #64748b;
        font-size: 12px;
        font-weight: 600;
        margin-bottom: 8px;
    }

    .return-detail .info-value {
        font-size: 14px;
        font-weight: 600;
        overflow-wrap: anywhere;
    }

    .return-detail .status-badge {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 7px 12px;
        border-radius: 30px;
        font-size: 12px;
        font-weight: 600;
    }

    .return-detail .status-pending {
        background: #fff7df;
        color: #946200;
    }

    .return-detail .status-approved {
        background: #e4f8ec;
        color: #187744;
    }

    .return-detail .status-rejected {
        background: #ffebeb;
        color: #b42318;
    }

    .return-detail .table-custom {
        margin-bottom: 0;
    }

    .return-detail .table-custom thead th {
        background: #f8fafc;
        color: #64748b;
        font-size: 12px;
        font-weight: 700;
        padding: 14px;
        white-space: nowrap;
    }

    .return-detail .table-custom tbody td {
        padding: 14px;
        vertical-align: middle;
    }

    .return-detail .note-box {
        background: #f8fafc;
        border: 1px solid #edf0f5;
        border-radius: 9px;
        padding: 16px;
        overflow-wrap: anywhere;
    }

    .return-detail .note-label {
        font-size: 12px;
        font-weight: 700;
        color: #64748b;
        margin-bottom: 8px;
    }

    .return-detail textarea {
        min-height: 120px;
        resize: vertical;
    }

    .return-detail .action-card {
        border-top: 3px solid #2563eb;
    }

    @media (max-width: 576px) {
        .return-detail .detail-card {
            padding: 16px;
        }
    }
</style>

<div class="return-detail">

    <div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
        <div>
            <h3 class="fw-bold text-dark mb-1">
                <i class="bi bi-file-earmark-text text-primary me-2"></i>
                Chi tiết yêu cầu
            </h3>
            <p class="page-description mb-0">
                Xem thông tin yêu cầu và thực hiện xử lý nếu yêu cầu đang chờ duyệt.
            </p>
        </div>

        <a href="${pageContext.request.contextPath}/staff/return-exchange"
           class="btn btn-outline-secondary rounded-3 px-3 py-2">
            <i class="bi bi-arrow-left me-1"></i>
            Quay lại danh sách
        </a>
    </div>

    <!-- SUCCESS MESSAGE -->
    <c:if test="${not empty param.message}">
        <div class="alert alert-success alert-dismissible fade show rounded-3" role="alert">
            <i class="bi bi-check-circle-fill me-2"></i>
            <c:choose>
                <c:when test="${param.message == 'approved'}">
                    Yêu cầu đã được chấp nhận thành công. Khách hàng có thể theo dõi kết quả xử lý.
                </c:when>
                <c:when test="${param.message == 'rejected'}">
                    Yêu cầu đã được từ chối thành công. Lý do từ chối đã được lưu lại.
                </c:when>
                <c:otherwise>
                    Thao tác đã được thực hiện thành công.
                </c:otherwise>
            </c:choose>
            <button type="button" class="btn-close"
                    data-bs-dismiss="alert" aria-label="Đóng"></button>
        </div>
    </c:if>

    <!-- ERROR MESSAGE -->
    <c:if test="${not empty param.error}">
        <div class="alert alert-danger alert-dismissible fade show rounded-3" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-2"></i>
            <c:choose>
                <c:when test="${param.error == 'noteRequired'}">
                    <strong>Chưa thể từ chối yêu cầu.</strong>
                    Vui lòng nhập lý do từ chối để khách hàng hiểu quyết định của Staff.
                </c:when>
                <c:when test="${param.error == 'alreadyReviewed'}">
                    <strong>Yêu cầu đã được xử lý.</strong>
                    Trạng thái yêu cầu có thể đã được một nhân viên khác cập nhật. Vui lòng tải lại trang để xem kết quả mới nhất.
                </c:when>
                <c:when test="${param.error == 'invalidId'}">
                    Mã yêu cầu không hợp lệ. Vui lòng kiểm tra lại.
                </c:when>
                <c:when test="${param.error == 'invalidAction'}">
                    Thao tác không hợp lệ. Vui lòng chọn Chấp nhận hoặc Từ chối.
                </c:when>
                <c:when test="${param.error == 'invalid'}">
                    Không thể cập nhật yêu cầu vì dữ liệu không hợp lệ. Vui lòng tải lại trang và thử lại.
                </c:when>
                <c:when test="${param.error == 'system'}">
                    Hệ thống đang gặp sự cố khi xử lý yêu cầu. Dữ liệu có thể chưa được cập nhật. Vui lòng thử lại sau.
                </c:when>
                <c:otherwise>
                    Đã xảy ra lỗi khi xử lý yêu cầu. Vui lòng tải lại trang hoặc liên hệ quản trị viên.
                </c:otherwise>
            </c:choose>
            <button type="button" class="btn-close"
                    data-bs-dismiss="alert" aria-label="Đóng"></button>
        </div>
    </c:if>

    <c:choose>
        <c:when test="${not empty selectedRequest}">

            <div class="detail-card">
                <div class="d-flex flex-column flex-sm-row justify-content-between align-items-sm-center gap-3 mb-4">
                    <div>
                        <h5 class="fw-bold mb-1">Thông tin yêu cầu</h5>
                        <span class="text-muted small">
                            Mã yêu cầu:
                            <strong class="text-primary">
                                #<c:out value="${selectedRequest.requestId}"/>
                            </strong>
                        </span>
                    </div>

                    <c:choose>
                        <c:when test="${selectedRequest.requestStatus == 'PENDING'}">
                            <span class="status-badge status-pending">
                                <i class="bi bi-clock-history"></i>
                                Chờ xử lý
                            </span>
                        </c:when>
                        <c:when test="${selectedRequest.requestStatus == 'APPROVED'}">
                            <span class="status-badge status-approved">
                                <i class="bi bi-check-circle-fill"></i>
                                Đã chấp nhận
                            </span>
                        </c:when>
                        <c:otherwise>
                            <span class="status-badge status-rejected">
                                <i class="bi bi-x-circle-fill"></i>
                                Đã từ chối
                            </span>
                        </c:otherwise>
                    </c:choose>
                </div>

                <div class="row g-3">
                    <div class="col-12 col-sm-6 col-lg-4">
                        <div class="info-item">
                            <span class="info-label">MÃ ĐƠN HÀNG</span>
                            <div class="info-value">
                                #<c:out value="${selectedRequest.orderId}"/>
                            </div>
                        </div>
                    </div>

                    <div class="col-12 col-sm-6 col-lg-4">
                        <div class="info-item">
                            <span class="info-label">KHÁCH HÀNG</span>
                            <div class="info-value">
                                <i class="bi bi-person-circle text-secondary me-1"></i>
                                <c:out value="${selectedRequest.username}"/>
                            </div>
                        </div>
                    </div>

                    <div class="col-12 col-sm-6 col-lg-4">
                        <div class="info-item">
                            <span class="info-label">LOẠI YÊU CẦU</span>
                            <div class="info-value">
                                <c:choose>
                                    <c:when test="${selectedRequest.requestType == 'RETURN'}">
                                        <span class="text-primary">
                                            <i class="bi bi-box-arrow-left me-1"></i>
                                            Trả hàng
                                        </span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="text-info">
                                            <i class="bi bi-arrow-left-right me-1"></i>
                                            Đổi hàng
                                        </span>
                                    </c:otherwise>
                                </c:choose>
                            </div>
                        </div>
                    </div>

                    <div class="col-12 col-sm-6 col-lg-4">
                        <div class="info-item">
                            <span class="info-label">NGÀY GỬI</span>
                            <div class="info-value">
                                <i class="bi bi-calendar3 text-secondary me-1"></i>
                                <fmt:formatDate value="${selectedRequest.createdAt}"
                                                pattern="dd/MM/yyyy HH:mm"/>
                            </div>
                        </div>
                    </div>

                    <c:if test="${not empty selectedRequest.reviewedAt}">
                        <div class="col-12 col-sm-6 col-lg-4">
                            <div class="info-item">
                                <span class="info-label">THỜI GIAN XỬ LÝ</span>
                                <div class="info-value">
                                    <i class="bi bi-calendar-check text-secondary me-1"></i>
                                    <fmt:formatDate value="${selectedRequest.reviewedAt}"
                                                    pattern="dd/MM/yyyy HH:mm"/>
                                </div>
                            </div>
                        </div>
                    </c:if>
                </div>

                <hr class="my-4">

                <div class="mb-3">
                    <div class="note-label">
                        <i class="bi bi-chat-left-text me-1"></i>
                        LÝ DO KHÁCH HÀNG
                    </div>
                    <div class="note-box">
                        <c:choose>
                            <c:when test="${not empty selectedRequest.reason}">
                                <c:out value="${selectedRequest.reason}"/>
                            </c:when>
                            <c:otherwise>
                                <span class="text-muted">Khách hàng không cung cấp lý do.</span>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>

                <c:if test="${not empty selectedRequest.staffNote}">
                    <div>
                        <div class="note-label">
                            <i class="bi bi-person-check me-1"></i>
                            GHI CHÚ CỦA STAFF
                        </div>
                        <div class="note-box">
                            <c:out value="${selectedRequest.staffNote}"/>
                        </div>
                    </div>
                </c:if>
            </div>

            <div class="detail-card">
                <div class="d-flex align-items-center justify-content-between gap-3 mb-3">
                    <h5 class="fw-bold mb-0">Sản phẩm trong yêu cầu</h5>
                    <span class="badge bg-light text-secondary border rounded-pill px-3 py-2">
                        <i class="bi bi-box-seam me-1"></i>
                        Danh sách sản phẩm
                    </span>
                </div>

                <div class="table-responsive">
                    <table class="table table-custom align-middle">
                        <thead>
                            <tr>
                                <th>SẢN PHẨM</th>
                                <th>SKU</th>
                                <th class="text-center">SỐ LƯỢNG</th>
                            </tr>
                        </thead>

                        <tbody>
                            <c:forEach var="item" items="${requestItems}">
                                <tr>
                                    <td>
                                        <div class="fw-semibold text-dark">
                                            <c:out value="${item.productName}"/>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="badge bg-light text-secondary border">
                                            <c:out value="${item.originalSkuCode}"/>
                                        </span>
                                    </td>
                                    <td class="text-center">
                                        <span class="badge bg-primary-subtle text-primary rounded-pill px-3 py-2">
                                            <c:out value="${item.quantity}"/>
                                        </span>
                                    </td>
                                </tr>
                            </c:forEach>

                            <c:if test="${empty requestItems}">
                                <tr>
                                    <td colspan="3" class="text-center text-muted py-4">
                                        <i class="bi bi-inbox fs-3 d-block mb-2"></i>
                                        Không có sản phẩm trong yêu cầu.
                                    </td>
                                </tr>
                            </c:if>
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="detail-card action-card">
                <h5 class="section-title">
                    <i class="bi bi-clipboard-check text-primary me-2"></i>
                    Xử lý yêu cầu
                </h5>

                <c:choose>
                    <c:when test="${selectedRequest.requestStatus == 'PENDING'}">
                        <div class="alert alert-info border-0 rounded-3 small">
                            <i class="bi bi-info-circle-fill me-2"></i>
                            Kiểm tra thông tin trước khi chấp nhận hoặc từ chối yêu cầu.
                        </div>

                        <form method="post"
                              action="${pageContext.request.contextPath}/staff/return-exchange"
                              id="reviewForm">

                            <input type="hidden" name="id"
                                   value="<c:out value='${selectedRequest.requestId}'/>"/>

                            <div class="mb-3">
                                <label for="staffNote" class="form-label fw-semibold">
                                    Ghi chú của Staff
                                </label>
                                <textarea id="staffNote"
                                          name="staffNote"
                                          class="form-control rounded-3"
                                          maxlength="1000"
                                          placeholder="Nhập ghi chú xử lý hoặc lý do từ chối..."></textarea>
                                <div class="form-text">
                                    Khi từ chối, bạn cần nhập lý do cụ thể.
                                </div>
                            </div>

                            <div class="d-flex flex-column flex-sm-row flex-wrap gap-2">
                                <button class="btn btn-success rounded-3 px-4 py-2"
                                        type="submit"
                                        name="action"
                                        value="approve"
                                        onclick="return confirm('Bạn có chắc muốn chấp nhận yêu cầu này?');">
                                    <i class="bi bi-check-circle me-1"></i>
                                    Chấp nhận
                                </button>

                                <button class="btn btn-danger rounded-3 px-4 py-2"
                                        type="submit"
                                        name="action"
                                        value="reject"
                                        onclick="return rejectRequest();">
                                    <i class="bi bi-x-circle me-1"></i>
                                    Từ chối
                                </button>

                                <a class="btn btn-outline-secondary rounded-3 px-4 py-2"
                                   href="${pageContext.request.contextPath}/staff/return-exchange">
                                    <i class="bi bi-arrow-left me-1"></i>
                                    Quay lại danh sách
                                </a>
                            </div>
                        </form>

                        <script>
                            function rejectRequest() {
                                const note = document.getElementById("staffNote").value.trim();

                                if (note === "") {
                                    alert("Vui lòng nhập lý do từ chối.");
                                    document.getElementById("staffNote").focus();
                                    return false;
                                }

                                return confirm("Bạn có chắc muốn từ chối yêu cầu này?");
                            }
                        </script>
                    </c:when>

                    <c:otherwise>
                        <c:choose>
                            <c:when test="${selectedRequest.requestStatus == 'APPROVED'}">
                                <div class="alert alert-success border-0 rounded-3 mb-3">
                                    <div class="fw-bold mb-1">
                                        <i class="bi bi-check-circle-fill me-2"></i>
                                        Yêu cầu đã được chấp nhận
                                    </div>
                                    Yêu cầu này đã được Staff chấp nhận trước đó.
                                    Khách hàng có thể xem trạng thái và ghi chú xử lý.
                                    Bạn không cần thực hiện thêm thao tác duyệt.
                                </div>
                            </c:when>

                            <c:when test="${selectedRequest.requestStatus == 'REJECTED'}">
                                <div class="alert alert-danger border-0 rounded-3 mb-3">
                                    <div class="fw-bold mb-1">
                                        <i class="bi bi-x-circle-fill me-2"></i>
                                        Yêu cầu đã bị từ chối
                                    </div>
                                    Yêu cầu này đã được Staff từ chối trước đó.
                                    Vui lòng xem ghi chú của Staff ở phần thông tin yêu cầu
                                    nếu cần kiểm tra lý do.
                                </div>
                            </c:when>

                            <c:otherwise>
                                <div class="alert alert-secondary border-0 rounded-3 mb-3">
                                    <i class="bi bi-lock-fill me-2"></i>
                                    Yêu cầu hiện không ở trạng thái có thể xử lý.
                                    Vui lòng tải lại trang hoặc liên hệ quản trị viên.
                                </div>
                            </c:otherwise>
                        </c:choose>

                        <a class="btn btn-outline-secondary rounded-3 px-4 py-2"
                           href="${pageContext.request.contextPath}/staff/return-exchange">
                            <i class="bi bi-arrow-left me-1"></i>
                            Quay lại danh sách
                        </a>
                    </c:otherwise>
                </c:choose>
            </div>

        </c:when>

        <c:otherwise>
            <div class="detail-card text-center py-5">
                <i class="bi bi-file-earmark-x display-4 text-secondary d-block mb-3"></i>
                <h5 class="fw-bold">Không tìm thấy yêu cầu</h5>
                <p class="text-muted mb-4">
                    Yêu cầu không tồn tại hoặc đã bị xóa.
                </p>
                <a class="btn btn-primary rounded-3 px-4"
                   href="${pageContext.request.contextPath}/staff/return-exchange">
                    <i class="bi bi-arrow-left me-1"></i>
                    Quay lại danh sách
                </a>
            </div>
        </c:otherwise>
    </c:choose>

</div>

<%@include file="/WEB-INF/include/footer.jsp" %>