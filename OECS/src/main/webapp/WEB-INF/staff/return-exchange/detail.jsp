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

    .validation-error {
        display: none;
        color: #dc2626;
        font-size: 13px;
        margin-top: 8px;
        align-items: center;
        gap: 6px;
    }

    .validation-error.show {
        display: flex;
    }

    .return-detail .action-card {
        border-top: 3px solid #2563eb;
    }

    @media (max-width: 576px) {
        .return-detail .detail-card {
            padding: 16px;
        }
    }


    .success-message,
    .error-message {
        display: flex;
        align-items: center;
        gap: 12px;
        position: fixed;
        top: 90px;
        right: 28px;
        z-index: 9999;
        width: max-content;
        max-width: min(450px, calc(100vw - 32px));
        padding: 16px 20px;
        border-radius: 12px;
        font-size: 14px;
        font-weight: 600;
        line-height: 1.5;
        box-shadow: 0 10px 30px rgba(15, 23, 42, 0.15);
        animation: notification-in 0.3s ease-out;
    }

    .success-message {
        color: #166534;
        background: #f0fdf4;
        border: 1px solid #86efac;
        border-left: 5px solid #22c55e;
    }

    .error-message {
        color: #b91c1c;
        background: #fef2f2;
        border: 1px solid #fca5a5;
        border-left: 5px solid #ef4444;
    }

    .notification-icon {
        flex-shrink: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 32px;
        height: 32px;
        border-radius: 50%;
        font-size: 18px;
        font-weight: 700;
    }

    .success-message .notification-icon {
        background: #dcfce7;
        color: #15803d;
    }

    .error-message .notification-icon {
        background: #fee2e2;
        color: #dc2626;
    }

    @keyframes notification-in {
        from {
            opacity: 0;
            transform: translateX(20px);
        }
        to {
            opacity: 1;
            transform: translateX(0);
        }
    }

    @keyframes notification-out {
        to {
            opacity: 0;
            transform: translateX(20px);
        }
    }

    .notification-hide {
        animation: notification-out 0.25s ease-in forwards;
        pointer-events: none;
    }

    @media (max-width: 600px) {
        .success-message,
        .error-message {
            top: 82px;
            right: 12px;
            max-width: calc(100vw - 24px);
            padding: 12px 14px;
        }
    }


    .review-modal-overlay {
        position: fixed;
        inset: 0;
        z-index: 10000;
        display: none;
        align-items: center;
        justify-content: center;
        padding: 20px;
        background: rgba(15, 23, 42, 0.55);
        backdrop-filter: blur(3px);
    }

    .review-modal-overlay.show {
        display: flex;
    }

    .review-modal-box {
        width: 100%;
        max-width: 420px;
        padding: 28px;
        background: #ffffff;
        border: 1px solid #e5eaf1;
        border-radius: 18px;
        box-shadow: 0 24px 60px rgba(15, 23, 42, 0.22);
        text-align: center;
        animation: review-modal-in 0.2s ease-out;
    }

    .review-modal-icon {
        width: 58px;
        height: 58px;
        margin: 0 auto 18px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 50%;
        background: #e7f2ff;
        color: #1677ff;
        font-size: 27px;
    }

    .review-modal-icon.reject {
        background: #fff1f2;
        color: #e53935;
    }

    .review-modal-box h2 {
        margin: 0 0 10px;
        color: #10213b;
        font-size: 21px;
        font-weight: 700;
    }

    .review-modal-box p {
        margin: 0;
        color: #71819a;
        font-size: 14px;
        line-height: 1.7;
    }

    .review-modal-actions {
        display: flex;
        justify-content: center;
        gap: 12px;
        margin-top: 26px;
    }

    .review-modal-btn {
        min-width: 120px;
        padding: 11px 18px;
        border-radius: 9px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        transition: background 0.2s;
    }

    .review-modal-btn:disabled {
        opacity: 0.65;
        cursor: not-allowed;
    }

    .review-modal-btn-secondary {
        background: #f1f5f9;
        color: #334155;
        border: 1px solid #e2e8f0;
    }

    .review-modal-btn-secondary:hover {
        background: #e2e8f0;
    }

    .review-modal-btn-approve {
        background: #1677ff;
        color: white;
        border: 1px solid #1677ff;
    }

    .review-modal-btn-approve:hover {
        background: #0867e8;
    }

    .review-modal-btn-reject {
        background: #e53935;
        color: white;
        border: 1px solid #e53935;
    }

    .review-modal-btn-reject:hover {
        background: #c62828;
    }

    @keyframes review-modal-in {
        from {
            opacity: 0;
            transform: translateY(8px) scale(0.98);
        }
        to {
            opacity: 1;
            transform: translateY(0) scale(1);
        }
    }

    @media (max-width: 480px) {
        .review-modal-box {
            padding: 24px 18px;
        }

        .review-modal-actions {
            flex-direction: column-reverse;
        }

        .review-modal-btn {
            width: 100%;
        }
    }
</style>

<div class="return-detail">

    <c:if test="${not empty param.message}">
        <div class="success-message notification" role="status">
            <span class="notification-icon">✓</span>
            <span>
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
            </span>
        </div>
    </c:if>

    <c:if test="${not empty param.error}">
        <div class="error-message notification" role="alert">
            <span class="notification-icon">!</span>
            <span>
                <c:choose>
                    <c:when test="${param.error == 'noteRequired'}">
                        Chưa thể từ chối yêu cầu. Vui lòng nhập lý do từ chối.
                    </c:when>
                    <c:when test="${param.error == 'alreadyReviewed'}">
                        Yêu cầu đã được xử lý. Vui lòng tải lại trang để xem kết quả mới nhất.
                    </c:when>
                    <c:when test="${param.error == 'invalidId'}">
                        Mã yêu cầu không hợp lệ. Vui lòng kiểm tra lại.
                    </c:when>
                    <c:when test="${param.error == 'invalidAction'}">
                        Thao tác không hợp lệ. Vui lòng chọn Chấp nhận hoặc Từ chối.
                    </c:when>
                    <c:when test="${param.error == 'invalid'}">
                        Không thể cập nhật yêu cầu vì dữ liệu không hợp lệ.
                    </c:when>
                    <c:when test="${param.error == 'system'}">
                        Hệ thống đang gặp sự cố. Vui lòng thử lại sau.
                    </c:when>
                    <c:otherwise>
                        Đã xảy ra lỗi khi xử lý yêu cầu. Vui lòng thử lại.
                    </c:otherwise>
                </c:choose>
            </span>
        </div>
    </c:if>

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
                                <th class="text-end">ĐƠN GIÁ</th>
                                <th class="text-end">THÀNH TIỀN</th>
                            </tr>
                        </thead>

                        <c:set var="requestTotal" value="${0}" />

                        <tbody>
                            <c:forEach var="item" items="${requestItems}">
                                <c:set var="lineTotal"
                                       value="${item.price * item.quantity}" />

                                <c:set var="requestTotal"
                                       value="${requestTotal + lineTotal}" />

                                <tr>
                                    <td>
                                        <div class="fw-semibold text-dark">
                                            <c:out value="${item.productName}"/>
                                        </div>

                                        <c:if test="${not empty item.exchangeSkuCode}">
                                            <small class="text-info">
                                                <i class="bi bi-arrow-left-right me-1"></i>
                                                SKU đổi:
                                                <c:out value="${item.exchangeSkuCode}"/>
                                            </small>
                                        </c:if>
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

                                    <td class="text-end text-nowrap">
                                        <fmt:formatNumber value="${item.price}"
                                                          maxFractionDigits="0"/>đ
                                    </td>

                                    <td class="text-end fw-semibold text-nowrap">
                                        <fmt:formatNumber value="${lineTotal}"
                                                          maxFractionDigits="0"/>đ
                                    </td>
                                </tr>
                            </c:forEach>

                            <c:if test="${empty requestItems}">
                                <tr>
                                    <td colspan="5" class="text-center text-muted py-4">
                                        <i class="bi bi-inbox fs-3 d-block mb-2"></i>
                                        Không có sản phẩm trong yêu cầu.
                                    </td>
                                </tr>
                            </c:if>
                        </tbody>

                        <c:if test="${not empty requestItems}">
                            <tfoot>
                                <tr>
                                    <td colspan="4" class="text-end fw-bold py-3">
                                        Tổng giá trị sản phẩm yêu cầu:
                                    </td>

                                    <td class="text-end fw-bold text-primary fs-5 text-nowrap py-3">
                                        <fmt:formatNumber value="${requestTotal}"
                                                          maxFractionDigits="0"/>đ
                                    </td>
                                </tr>
                            </tfoot>
                        </c:if>
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

                            <input type="hidden"
                                   name="id"
                                   value="<c:out value='${selectedRequest.requestId}'/>"/>

                            <input type="hidden"
                                   name="action"
                                   id="reviewAction"/>

                            <div class="mb-3">
                                <label for="staffNote" class="form-label fw-semibold">
                                    Ghi chú của Staff
                                </label>

                                <textarea id="staffNote"
                                          name="staffNote"
                                          class="form-control rounded-3"
                                          maxlength="1000"
                                          placeholder="Nhập ghi chú xử lý hoặc lý do từ chối..."></textarea>

                                <div id="noteError" class="validation-error">
                                    <i class="bi bi-exclamation-circle-fill"></i>
                                    Vui lòng nhập lý do từ chối.
                                </div>

                                <div class="form-text">
                                    Khi từ chối, bạn cần nhập lý do cụ thể.
                                </div>
                            </div>

                            <div class="d-flex flex-column flex-sm-row flex-wrap gap-2">

                                <button class="btn btn-success rounded-3 px-4 py-2"
                                        type="button"
                                        onclick="showReviewModal('approve')">
                                    <i class="bi bi-check-circle me-1"></i>
                                    Chấp nhận
                                </button>

                                <button class="btn btn-danger rounded-3 px-4 py-2"
                                        type="button"
                                        onclick="showReviewModal('reject')">
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

    <div id="reviewModal"
         class="review-modal-overlay"
         role="dialog"
         aria-modal="true"
         aria-labelledby="reviewModalTitle">

        <div class="review-modal-box">

            <div id="reviewModalIcon" class="review-modal-icon">
                <i class="bi bi-check-circle-fill"></i>
            </div>

            <h2 id="reviewModalTitle">
                Xác nhận xử lý yêu cầu
            </h2>

            <p id="reviewModalMessage">
                Bạn có chắc chắn muốn thực hiện thao tác này không?
            </p>

            <div class="review-modal-actions">

                <button type="button"
                        class="review-modal-btn review-modal-btn-secondary"
                        onclick="closeReviewModal()">
                    Hủy bỏ
                </button>

                <button type="button"
                        id="confirmReviewButton"
                        class="review-modal-btn review-modal-btn-approve"
                        onclick="confirmReview()">
                    Xác nhận
                </button>

            </div>
        </div>
    </div>

</div>

<script>
    let reviewAction = null;

    function showReviewModal(action) {
        const note = document.getElementById("staffNote");
        const error = document.getElementById("noteError");

        if (action === "reject" && note.value.trim() === "") {
            if (error) {
                error.classList.add("show");
            }

            note.focus();
            return;
        }

        if (error) {
            error.classList.remove("show");
        }

        reviewAction = action;

        const modal = document.getElementById("reviewModal");
        const icon = document.getElementById("reviewModalIcon");
        const title = document.getElementById("reviewModalTitle");
        const message = document.getElementById("reviewModalMessage");
        const confirmButton = document.getElementById("confirmReviewButton");

        confirmButton.disabled = false;

        if (action === "approve") {
            icon.className = "review-modal-icon";
            icon.innerHTML = '<i class="bi bi-check-circle-fill"></i>';

            title.textContent = "Xác nhận chấp nhận";
            message.textContent =
                    "Bạn có chắc chắn muốn chấp nhận yêu cầu này không?";

            confirmButton.className =
                    "review-modal-btn review-modal-btn-approve";

            confirmButton.textContent = "Chấp nhận";

        } else {
            icon.className = "review-modal-icon reject";
            icon.innerHTML = '<i class="bi bi-exclamation-triangle-fill"></i>';

            title.textContent = "Xác nhận từ chối";
            message.textContent =
                    "Bạn có chắc chắn muốn từ chối yêu cầu này không? Vui lòng kiểm tra lý do trước khi tiếp tục.";

            confirmButton.className =
                    "review-modal-btn review-modal-btn-reject";

            confirmButton.textContent = "Từ chối";
        }

        modal.classList.add("show");
        confirmButton.focus();
    }

    function closeReviewModal() {
        const modal = document.getElementById("reviewModal");

        modal.classList.remove("show");
        reviewAction = null;
    }

    function confirmReview() {
        if (reviewAction === null) {
            return;
        }

        const note = document.getElementById("staffNote");
        const error = document.getElementById("noteError");

        if (reviewAction === "reject" && note.value.trim() === "") {
            closeReviewModal();

            if (error) {
                error.classList.add("show");
            }

            note.focus();
            return;
        }

        const form = document.getElementById("reviewForm");
        const actionInput = document.getElementById("reviewAction");
        const confirmButton = document.getElementById("confirmReviewButton");

        actionInput.value = reviewAction;

        confirmButton.disabled = true;
        confirmButton.textContent = "Đang xử lý...";

        form.submit();
    }

    document.addEventListener("DOMContentLoaded", function () {

        const note = document.getElementById("staffNote");
        const error = document.getElementById("noteError");

        if (note && error) {
            note.addEventListener("input", function () {
                if (this.value.trim() !== "") {
                    error.classList.remove("show");
                }
            });
        }

        document.querySelectorAll(".notification").forEach(function (message) {
            setTimeout(function () {
                message.classList.add("notification-hide");

                setTimeout(function () {
                    message.remove();
                }, 300);

            }, 3500);
        });

    });

    const reviewModal = document.getElementById("reviewModal");

    if (reviewModal) {
        reviewModal.addEventListener("click", function (event) {
            if (event.target === this) {
                closeReviewModal();
            }
        });
    }

    document.addEventListener("keydown", function (event) {
        if (event.key === "Escape") {
            closeReviewModal();
        }
    });
</script>

<%@include file="/WEB-INF/include/footer.jsp" %>