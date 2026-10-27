<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<!-- Page Header -->
<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
    <div>
        <h3 class="fw-bold text-dark mb-1">
            Audit Log
        </h3>
        <p class="text-muted fs-7 mb-0">
            Theo dõi các hoạt động quan trọng được thực hiện trong hệ thống.
        </p>
    </div>
</div>

<!-- Statistics -->
<div class="row g-3 mb-4">

    <!-- Total Logs -->
    <div class="col-12 col-md-4">
        <div class="stat-card">
            <div class="d-flex justify-content-between align-items-center">
                <span class="text-muted fs-7 fw-medium">
                    Tổng nhật ký
                </span>

                <span class="badge bg-primary-subtle text-primary rounded-pill">
                    <i class="bi bi-journal-text"></i>
                </span>
            </div>

            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">
                    ${not empty auditLogs ? fn:length(auditLogs) : 0}
                </span>

                <span class="text-muted fs-7 ms-2">
                    Logs
                </span>
            </div>
        </div>
    </div>

    <!-- Security -->
    <div class="col-12 col-md-4">
        <div class="stat-card">
            <div class="d-flex justify-content-between align-items-center">
                <span class="text-muted fs-7 fw-medium">
                    Theo dõi bảo mật
                </span>

                <span class="badge bg-danger-subtle text-danger rounded-pill">
                    <i class="bi bi-shield-lock"></i>
                </span>
            </div>

            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">
                    Security
                </span>

                <span class="text-muted fs-7 ms-2">
                    Monitoring
                </span>
            </div>
        </div>
    </div>

    <!-- Administration -->
    <div class="col-12 col-md-4">
        <div class="stat-card">
            <div class="d-flex justify-content-between align-items-center">
                <span class="text-muted fs-7 fw-medium">
                    Phạm vi theo dõi
                </span>

                <span class="badge bg-success-subtle text-success rounded-pill">
                    <i class="bi bi-activity"></i>
                </span>
            </div>

            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">
                    Admin / Staff
                </span>

                <span class="text-muted fs-7 ms-2">
                    Actions
                </span>
            </div>
        </div>
    </div>

</div>

<!-- Main Card -->
<div class="card-custom overflow-hidden">

    <!-- Toolbar -->
    <div class="p-3 border-bottom">

        <form action="${pageContext.request.contextPath}/admin/audit-log"
              method="get"
              class="row g-2 align-items-center">

            <!-- Search -->
            <div class="col-12 col-md-4">
                <div class="search-box w-100">

                    <input type="text"
                           name="keyword"
                           value="${keyword}"
                           class="form-control"
                           placeholder="Tìm actor hoặc mô tả...">
                </div>
            </div>

            <!-- Action -->
            <div class="col-12 col-md-3">

                <select name="action"
                        class="form-select">

                    <option value="">
                        Tất cả hành động
                    </option>

                    <option value="LOGIN_SUCCESS"
                            ${selectedAction eq 'LOGIN_SUCCESS' ? 'selected' : ''}>
                        Login Success
                    </option>

                    <option value="LOGIN_FAILED"
                            ${selectedAction eq 'LOGIN_FAILED' ? 'selected' : ''}>
                        Login Failed
                    </option>

                    <option value="CREATE_USER"
                            ${selectedAction eq 'CREATE_USER' ? 'selected' : ''}>
                        Create User
                    </option>

                    <option value="LOCK_USER"
                            ${selectedAction eq 'LOCK_USER' ? 'selected' : ''}>
                        Lock User
                    </option>

                    <option value="UNLOCK_USER"
                            ${selectedAction eq 'UNLOCK_USER' ? 'selected' : ''}>
                        Unlock User
                    </option>

                    <option value="CHANGE_PASSWORD"
                            ${selectedAction eq 'CHANGE_PASSWORD' ? 'selected' : ''}>
                        Change Password
                    </option>

                    <option value="RESET_PASSWORD"
                            ${selectedAction eq 'RESET_PASSWORD' ? 'selected' : ''}>
                        Reset Password
                    </option>

                    <option value="CREATE_BRAND"
                            ${selectedAction eq 'CREATE_BRAND' ? 'selected' : ''}>
                        Create Brand
                    </option>

                    <option value="UPDATE_BRAND"
                            ${selectedAction eq 'UPDATE_BRAND' ? 'selected' : ''}>
                        Update Brand
                    </option>

                    <option value="DELETE_BRAND"
                            ${selectedAction eq 'DELETE_BRAND' ? 'selected' : ''}>
                        Delete Brand
                    </option>

                    <option value="CREATE_CATEGORY"
                            ${selectedAction eq 'CREATE_CATEGORY' ? 'selected' : ''}>
                        Create Category
                    </option>

                    <option value="UPDATE_CATEGORY"
                            ${selectedAction eq 'UPDATE_CATEGORY' ? 'selected' : ''}>
                        Update Category
                    </option>

                    <option value="DELETE_CATEGORY"
                            ${selectedAction eq 'DELETE_CATEGORY' ? 'selected' : ''}>
                        Delete Category
                    </option>

                    <option value="CREATE_PRODUCT"
                            ${selectedAction eq 'CREATE_PRODUCT' ? 'selected' : ''}>
                        Create Product
                    </option>

                    <option value="UPDATE_PRODUCT"
                            ${selectedAction eq 'UPDATE_PRODUCT' ? 'selected' : ''}>
                        Update Product
                    </option>

                    <option value="DELETE_PRODUCT"
                            ${selectedAction eq 'DELETE_PRODUCT' ? 'selected' : ''}>
                        Delete Product
                    </option>

                    <option value="CREATE_SKU"
                            ${selectedAction eq 'CREATE_SKU' ? 'selected' : ''}>
                        Create SKU
                    </option>

                    <option value="DELETE_SKU"
                            ${selectedAction eq 'DELETE_SKU' ? 'selected' : ''}>
                        Delete SKU
                    </option>

                    <option value="CREATE_VOUCHER"
                            ${selectedAction eq 'CREATE_VOUCHER' ? 'selected' : ''}>
                        Create Voucher
                    </option>

                    <option value="UPDATE_VOUCHER"
                            ${selectedAction eq 'UPDATE_VOUCHER' ? 'selected' : ''}>
                        Update Voucher
                    </option>

                    <option value="DELETE_VOUCHER"
                            ${selectedAction eq 'DELETE_VOUCHER' ? 'selected' : ''}>
                        Delete Voucher
                    </option>

                    <option value="UPDATE_ORDER_STATUS"
                            ${selectedAction eq 'UPDATE_ORDER_STATUS' ? 'selected' : ''}>
                        Update Order Status
                    </option>

                    <option value="CANCEL_ORDER"
                            ${selectedAction eq 'CANCEL_ORDER' ? 'selected' : ''}>
                        Cancel Order
                    </option>

                    <option value="EXPORT_REPORT"
                            ${selectedAction eq 'EXPORT_REPORT' ? 'selected' : ''}>
                        Export Report
                    </option>

                </select>

            </div>

            <!-- Entity -->
            <div class="col-12 col-md-3">

                <select name="entityType"
                        class="form-select">

                    <option value="">
                        Tất cả đối tượng
                    </option>

                    <option value="USER"
                            ${selectedEntityType eq 'USER' ? 'selected' : ''}>
                        User
                    </option>

                    <option value="PRODUCT"
                            ${selectedEntityType eq 'PRODUCT' ? 'selected' : ''}>
                        Product
                    </option>

                    <option value="PRODUCT_SKU"
                            ${selectedEntityType eq 'PRODUCT_SKU' ? 'selected' : ''}>
                        Product SKU
                    </option>

                    <option value="BRAND"
                            ${selectedEntityType eq 'BRAND' ? 'selected' : ''}>
                        Brand
                    </option>

                    <option value="CATEGORY"
                            ${selectedEntityType eq 'CATEGORY' ? 'selected' : ''}>
                        Category
                    </option>

                    <option value="VOUCHER"
                            ${selectedEntityType eq 'VOUCHER' ? 'selected' : ''}>
                        Voucher
                    </option>

                    <option value="ORDER"
                            ${selectedEntityType eq 'ORDER' ? 'selected' : ''}>
                        Order
                    </option>

                    <option value="REPORT"
                            ${selectedEntityType eq 'REPORT' ? 'selected' : ''}>
                        Report
                    </option>

                </select>

            </div>

            <!-- Buttons -->
            <div class="col-12 col-md-2 d-flex gap-2">

                <button type="submit"
                        class="btn btn-primary flex-grow-1">
                    <i class="bi bi-funnel me-1"></i>
                    Lọc
                </button>

                <a href="${pageContext.request.contextPath}/admin/audit-log"
                   class="btn btn-light border"
                   title="Xóa bộ lọc">

                    <i class="bi bi-arrow-counterclockwise"></i>

                </a>

            </div>

        </form>

    </div>

    <!-- Table -->
    <div class="table-responsive">

        <table class="table table-custom align-middle">

            <thead>
                <tr>
                <th style="width: 70px;">#</th>
                <th>THỜI GIAN</th>
                <th>NGƯỜI THỰC HIỆN</th>
                <th>HÀNH ĐỘNG</th>
                <th>ĐỐI TƯỢNG</th>
                <th>MÔ TẢ</th>
                <th>IP</th>
                </tr>
            </thead>

            <tbody>

                <c:choose>

                    <c:when test="${not empty auditLogs}">

                        <c:forEach items="${auditLogs}" var="log">

                            <tr>

                                <!-- Log ID -->
                            <td>
                            <span class="badge bg-light text-secondary border">
                                #${log.logId}
                            </span>
                            </td>

                            <!-- Created At -->
                            <td>
                                <div class="text-dark">
                                    <fmt:formatDate
                                        value="${log.createdAt}"
                                        pattern="dd/MM/yyyy"/>
                                </div>

                                <small class="text-muted">
                                    <fmt:formatDate
                                        value="${log.createdAt}"
                                        pattern="HH:mm:ss"/>
                                </small>
                            </td>

                            <!-- Actor -->
                            <td>
                                <c:choose>

                                    <c:when test="${not empty log.actorIdentifier}">
                                        <div class="fw-semibold text-dark">
                                            ${log.actorIdentifier}
                                        </div>

                                        <c:if test="${not empty log.actorUserId}">
                                            <small class="text-muted">
                                                User #${log.actorUserId}
                                            </small>
                                        </c:if>
                                    </c:when>

                                    <c:otherwise>
                                    <span class="text-muted">
                                        Unknown
                                    </span>
                                </c:otherwise>

                            </c:choose>
                            </td>

                            <!-- Action -->
                            <td>
                                <c:choose>

                                    <c:when test="${log.action eq 'LOGIN_SUCCESS'}">
                                    <span class="badge bg-success-subtle text-success border border-success-subtle">
                                        <i class="bi bi-box-arrow-in-right me-1"></i>
                                        LOGIN SUCCESS
                                    </span>
                                </c:when>

                                <c:when test="${log.action eq 'LOGIN_FAILED'}">
                                    <span class="badge bg-danger-subtle text-danger border border-danger-subtle">
                                        <i class="bi bi-x-circle me-1"></i>
                                        LOGIN FAILED
                                    </span>
                                </c:when>

                                <c:when test="${log.action eq 'LOCK_USER'}">
                                    <span class="badge bg-danger-subtle text-danger border border-danger-subtle">
                                        <i class="bi bi-lock me-1"></i>
                                        LOCK USER
                                    </span>
                                </c:when>

                                <c:when test="${log.action eq 'UNLOCK_USER'}">
                                    <span class="badge bg-success-subtle text-success border border-success-subtle">
                                        <i class="bi bi-unlock me-1"></i>
                                        UNLOCK USER
                                    </span>
                                </c:when>

                                <c:when test="${fn:startsWith(log.action, 'CREATE_')}">
                                    <span class="badge bg-primary-subtle text-primary border border-primary-subtle">
                                        <i class="bi bi-plus-circle me-1"></i>
                                        ${fn:replace(log.action, '_', ' ')}
                                    </span>
                                </c:when>

                                <c:when test="${fn:startsWith(log.action, 'DELETE_')}">
                                    <span class="badge bg-danger-subtle text-danger border border-danger-subtle">
                                        <i class="bi bi-trash me-1"></i>
                                        ${fn:replace(log.action, '_', ' ')}
                                    </span>
                                </c:when>

                                <c:when test="${fn:startsWith(log.action, 'UPDATE_')}">
                                    <span class="badge bg-warning-subtle text-warning-emphasis border border-warning-subtle">
                                        <i class="bi bi-pencil-square me-1"></i>
                                        ${fn:replace(log.action, '_', ' ')}
                                    </span>
                                </c:when>

                                <c:otherwise>
                                    <span class="badge bg-secondary-subtle text-secondary border">
                                        ${fn:replace(log.action, '_', ' ')}
                                    </span>
                                </c:otherwise>

                            </c:choose>
                            </td>

                            <!-- Entity -->
                            <td>

                            <span class="badge bg-info-subtle text-info border border-info-subtle">
                                ${log.entityType}
                            </span>

                            <c:if test="${not empty log.entityId}">
                                <div class="small text-muted mt-1">
                                    #${log.entityId}
                                </div>
                            </c:if>

                            </td>

                            <!-- Description -->
                            <td style="min-width: 220px;">

                                <c:choose>

                                    <c:when test="${not empty log.description}">
                                    <span class="text-muted">
                                        ${log.description}
                                    </span>
                                </c:when>

                                <c:otherwise>
                                    <span class="text-muted">
                                        -
                                    </span>
                                </c:otherwise>

                            </c:choose>

                            </td>

                            <!-- IP -->
                            <td>

                                <c:choose>

                                    <c:when test="${not empty log.ipAddress}">
                                    <span class="text-muted">
                                        ${log.ipAddress}
                                    </span>
                                </c:when>

                                <c:otherwise>
                                    <span class="text-muted">
                                        -
                                    </span>
                                </c:otherwise>

                            </c:choose>

                            </td>

                            </tr>

                        </c:forEach>

                    </c:when>

                    <c:otherwise>

                        <tr>
                        <td colspan="7"
                            class="text-center py-5">

                            <i class="bi bi-journal-x fs-1 text-secondary"></i>

                            <p class="fw-medium mt-2 mb-1">
                                Chưa có Audit Log
                            </p>

                            <small class="text-muted">
                                Các hoạt động quan trọng sẽ được ghi lại tại đây.
                            </small>

                        </td>
                        </tr>

                    </c:otherwise>

                </c:choose>

            </tbody>

        </table>

    </div>

    <!-- Card Footer -->
    <div class="p-3 border-top bg-white">

        <span class="text-muted fs-7">
            Hiển thị
            <strong>
                ${not empty auditLogs ? fn:length(auditLogs) : 0}
            </strong>
            bản ghi
        </span>

    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp"%>