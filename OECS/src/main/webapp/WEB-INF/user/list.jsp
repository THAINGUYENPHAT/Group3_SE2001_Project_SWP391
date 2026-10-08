<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<!-- Page Header -->
<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
    <div>
        <h3 class="fw-bold text-dark mb-1">
            Quản lý Người Dùng
        </h3>
        <p class="text-muted fs-7 mb-0">
            Hiển thị và quản lý toàn bộ người dùng trong hệ thống.
        </p>
    </div>

    <a href="${pageContext.request.contextPath}/user?view=create"
       class="btn btn-primary btn-md fw-semibold px-3 py-2 shadow-sm rounded-3">
        <i class="bi bi-person-plus me-1"></i>
        Thêm người dùng
    </a>
</div>

<!-- Statistics -->
<div class="row g-3 mb-4">
    <div class="col-12 col-md-4">
        <div class="stat-card">
            <div class="d-flex justify-content-between align-items-center">
                <span class="text-muted fs-7 fw-medium">
                    Tổng người dùng
                </span>
                <span class="badge bg-primary-subtle text-primary rounded-pill">
                    <i class="bi bi-people"></i>
                </span>
            </div>

            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">
                    ${not empty userList ? fn:length(userList) : 0}
                </span>
                <span class="text-success fs-7 ms-2">
                    Tài khoản
                </span>
            </div>
        </div>
    </div>

    <div class="col-12 col-md-4">
        <div class="stat-card">
            <div class="d-flex justify-content-between align-items-center">
                <span class="text-muted fs-7 fw-medium">
                    Phân quyền
                </span>
                <span class="badge bg-success-subtle text-success rounded-pill">
                    <i class="bi bi-person-badge"></i>
                </span>
            </div>

            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">
                    User / Admin
                </span>
                <span class="text-muted fs-7 ms-2">
                    Role
                </span>
            </div>
        </div>
    </div>

    <div class="col-12 col-md-4">
        <div class="stat-card">
            <div class="d-flex justify-content-between align-items-center">
                <span class="text-muted fs-7 fw-medium">
                    Quản lý
                </span>
                <span class="badge bg-info-subtle text-info rounded-pill">
                    <i class="bi bi-shield-lock"></i>
                </span>
            </div>

            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">
                    Admin
                </span>
                <span class="text-muted fs-7 ms-2">
                    Toàn quyền
                </span>
            </div>
        </div>
    </div>
</div>

<!-- Alerts -->
<c:if test="${not empty message}">
    <div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
        <i class="bi bi-check-circle me-2"></i>${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
</c:if>

<c:if test="${not empty error}">
    <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
        <i class="bi bi-exclamation-triangle me-2"></i>${error}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
</c:if>

<!-- Main Card -->
<div class="card-custom overflow-hidden">

    <!-- Toolbar & Search -->
    <div class="p-3 border-bottom d-flex justify-content-between align-items-center">
        <form action="${pageContext.request.contextPath}/user"
              method="get"
              class="search-box w-100"
              style="max-width: 350px;">
            <input type="hidden" name="view" value="list">
            <i class="bi bi-search"></i>
            <input type="text"
                   name="keyword"
                   value="${keyword}"
                   class="form-control"
                   placeholder="Tìm kiếm username, email, SĐT...">
        </form>
    </div>

    <!-- Table -->
    <div class="table-responsive">
        <table class="table table-custom align-middle">
            <thead>
                <tr>
                    <th style="width: 50px;">#</th>
                    <th>TÀI KHOẢN</th>
                    <th>EMAIL</th>
                    <th>SỐ ĐIỆN THOẠI</th>
                    <th>VAI TRÒ</th>
                    <th>TRẠNG THÁI</th>
                    <th>NGÀY TẠO</th>
                    <th style="width: 120px;" class="text-end">THAO TÁC</th>
                </tr>
            </thead>

            <tbody>
                <c:choose>
                    <c:when test="${not empty userList}">
                        <c:forEach items="${userList}" var="user">
                            <tr>
                                <!-- ID -->
                                <td>
                                    <span class="badge bg-light text-secondary border">
                                        #${user.userId}
                                    </span>
                                </td>

                                <!-- Username -->
                                <td>
                                    <div class="fw-bold text-dark">
                                        ${user.username}
                                    </div>
                                </td>

                                <!-- Email -->
                                <td>
                                    <span class="text-muted">
                                        ${user.email}
                                    </span>
                                </td>

                                <!-- Phone -->
                                <td>
                                    <c:choose>
                                        <c:when test="${not empty user.phone}">
                                            <span class="text-muted">
                                                ${user.phone}
                                            </span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-muted">
                                                Chưa cập nhật
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>

                                <!-- Role -->
                                <td>
                                    <span class="badge bg-info-subtle text-info border border-info-subtle">
                                        <i class="bi bi-person-badge me-1"></i>
                                        ${user.roleName}
                                    </span>
                                </td>

                                <!-- Status -->
                                <td>
                                    <c:choose>
                                        <c:when test="${user.active}">
                                            <span class="badge bg-success-subtle text-success border border-success-subtle">
                                                Active
                                            </span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-danger-subtle text-danger border border-danger-subtle">
                                                Locked
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>

                                <!-- Created At -->
                                <td>
                                    <span class="text-muted">
                                        ${user.createdAt}
                                    </span>
                                </td>

                                <!-- Actions -->
                                <td class="text-end">
                                    <div class="d-inline-flex gap-1">
                                        <a href="${pageContext.request.contextPath}/user?view=edit&id=${user.userId}"
                                           class="btn btn-sm btn-light text-primary border rounded-2"
                                           title="Chỉnh sửa">
                                            <i class="bi bi-pencil-square"></i>
                                        </a>

                                        <a href="${pageContext.request.contextPath}/user?view=delete&id=${user.userId}"
                                           class="btn btn-sm btn-light text-danger border rounded-2"
                                           title="Xóa">
                                            <i class="bi bi-trash"></i>
                                        </a>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                    </c:when>

                    <c:otherwise>
                        <tr>
                            <td colspan="8" class="text-center py-5">
                                <i class="bi bi-people fs-1 text-secondary"></i>
                                <p class="fw-medium mt-2 mb-1">
                                    Không tìm thấy người dùng nào
                                </p>
                                <small class="text-muted">
                                    Nhấn "Thêm người dùng" để tạo mới.
                                </small>
                            </td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </tbody>
        </table>
    </div>

    <!-- Footer -->
    <div class="p-3 border-top bg-white">
        <span class="text-muted fs-7">
            Hiển thị <strong>${not empty userList ? fn:length(userList) : 0}</strong> người dùng
        </span>
    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp"%>