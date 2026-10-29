
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
    <div>
        <h3 class="fw-bold text-dark mb-1">Quản lý Banner</h3>
        <p class="text-muted fs-7 mb-0">
            Quản lý hình ảnh hiển thị trong slideshow trang chủ.
        </p>
    </div>
</div>

<c:if test="${not empty param.success}">
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        <c:choose>
            <c:when test="${param.success == 'create'}">
                Thêm banner thành công.
            </c:when>
            <c:when test="${param.success == 'toggle'}">
                Cập nhật trạng thái banner thành công.
            </c:when>
            <c:when test="${param.success == 'delete'}">
                Xóa banner thành công.
            </c:when>
        </c:choose>
        <button type="button" class="btn-close" data-bs-dismiss="alert"
                aria-label="Đóng"></button>
    </div>
</c:if>

<c:if test="${not empty param.error}">
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <c:choose>
            <c:when test="${param.error == 'upload'}">
                Không thể tải ảnh lên. Vui lòng thử lại.
            </c:when>
            <c:when test="${param.error == 'database'}">
                Không thể lưu dữ liệu banner vào cơ sở dữ liệu.
            </c:when>
            <c:otherwise>
                Có lỗi xảy ra khi xử lý banner.
            </c:otherwise>
        </c:choose>
        <button type="button" class="btn-close" data-bs-dismiss="alert"
                aria-label="Đóng"></button>
    </div>
</c:if>

<div class="row g-3 mb-4">
    <div class="col-12 col-sm-6 col-lg-4">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between">
                <span class="text-muted fs-7 fw-medium">Tổng banner</span>
                <span class="badge bg-primary-subtle text-primary rounded-pill px-3 py-2">
                    <i class="bi bi-images"></i>
                </span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">${banners.size()}</span>
                <span class="text-muted fs-7 ms-2">Banner</span>
            </div>
        </div>
    </div>

    <div class="col-12 col-sm-6 col-lg-4">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between">
                <span class="text-muted fs-7 fw-medium">Banner đang bật</span>
                <span class="badge bg-success-subtle text-success rounded-pill px-3 py-2">
                    <i class="bi bi-check-circle-fill"></i>
                </span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">${activeCount}</span>
                <span class="text-muted fs-7 ms-2">Banner</span>
            </div>
        </div>
    </div>

    <div class="col-12 col-sm-6 col-lg-4">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between">
                <span class="text-muted fs-7 fw-medium">Chức năng</span>
                <span class="badge bg-info-subtle text-info rounded-pill px-3 py-2">
                    <i class="bi bi-cloud-arrow-up-fill"></i>
                </span>
            </div>
            <div class="mt-2">
                <span class="fs-5 fw-bold text-dark">Tải ảnh lên</span>
                <div class="text-muted fs-7">JPG, PNG, GIF, WEBP</div>
            </div>
        </div>
    </div>
</div>

<div class="card-custom overflow-hidden mb-4">
    <div class="p-3 border-bottom bg-white">
        <h5 class="fw-bold text-dark mb-1">
            <i class="bi bi-plus-circle me-2"></i>Thêm banner mới
        </h5>
        <p class="text-muted fs-7 mb-0">
            Chọn ảnh để thêm vào slideshow trang chủ.
        </p>
    </div>

    <form action="${pageContext.request.contextPath}/staff/banner"
          method="post"
          enctype="multipart/form-data"
          class="p-3">

        <div class="row g-3">
            <div class="col-12 col-lg-6">
                <label for="imageFile" class="form-label fw-semibold">
                    Hình ảnh <span class="text-danger">*</span>
                </label>
                <input type="file"
                       id="imageFile"
                       name="imageFile"
                       class="form-control"
                       accept=".jpg,.jpeg,.png,.gif,.webp"
                       required>
                <div class="form-text">
                    Dung lượng tối đa 10 MB.
                </div>
            </div>

            <div class="col-12 col-lg-6">
                <label for="altText" class="form-label fw-semibold">
                    Mô tả hình ảnh
                </label>
                <input type="text"
                       id="altText"
                       name="altText"
                       class="form-control"
                       maxlength="255"
                       placeholder="Ví dụ: Bộ sưu tập mùa hè">
            </div>

            <div class="col-12 col-md-8">
                <label for="targetUrl" class="form-label fw-semibold">
                    Liên kết khi nhấn vào banner
                </label>
                <input type="text"
                       id="targetUrl"
                       name="targetUrl"
                       class="form-control"
                       maxlength="2048"
                       placeholder="/shop hoặc để trống">
                <div class="form-text">
                    Có thể để trống nếu banner không dẫn đến trang khác.
                </div>
            </div>

            <div class="col-12 col-md-4">
                <label for="displayOrder" class="form-label fw-semibold">
                    Thứ tự hiển thị
                </label>
                <input type="number"
                       id="displayOrder"
                       name="displayOrder"
                       class="form-control"
                       min="0"
                       value="0"
                       required>
                <div class="form-text">
                    Số nhỏ hơn sẽ hiển thị trước.
                </div>
            </div>
        </div>

        <div class="mt-3 d-flex justify-content-end">
            <button type="submit" class="btn btn-primary fw-semibold px-4">
                <i class="bi bi-cloud-arrow-up me-2"></i>Tải banner lên
            </button>
        </div>
    </form>
</div>

<div class="card-custom overflow-hidden">
    <div class="p-3 border-bottom bg-white">
        <h5 class="fw-bold text-dark mb-0">Danh sách banner</h5>
    </div>

    <div class="table-responsive">
        <table class="table table-custom align-middle mb-0">
            <thead>
                <tr>
                    <th style="width: 80px;">MÃ ID</th>
                    <th style="min-width: 220px;">HÌNH ẢNH</th>
                    <th>MÔ TẢ</th>
                    <th>THỨ TỰ</th>
                    <th>TRẠNG THÁI</th>
                    <th style="width: 170px;" class="text-end">THAO TÁC</th>
                </tr>
            </thead>

            <tbody>
                <c:choose>
                    <c:when test="${not empty banners}">
                        <c:forEach items="${banners}" var="banner">
                            <tr>
                                <td>
                                    <span class="badge bg-light text-secondary border">
                                        #${banner.bannerId}
                                    </span>
                                </td>

                                <td>
                                    <img
                                        src="${pageContext.request.contextPath}/${banner.imageUrl}"
                                        alt="<c:out value='${banner.altText}'/>"
                                        style="width: 200px; height: 85px; object-fit: cover;"
                                        class="rounded-3 border"
                                        onerror="this.style.display='none'">
                                </td>

                                <td>
                                    <div class="fw-semibold text-dark">
                                        <c:choose>
                                            <c:when test="${not empty banner.altText}">
                                                <c:out value="${banner.altText}"/>
                                            </c:when>
                                            <c:otherwise>
                                                Chưa có mô tả
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                    <c:if test="${not empty banner.targetUrl}">
                                        <small class="text-muted">
                                            Liên kết:
                                            <c:out value="${banner.targetUrl}"/>
                                        </small>
                                    </c:if>
                                </td>

                                <td>
                                    <span class="badge bg-light text-secondary border">
                                        ${banner.displayOrder}
                                    </span>
                                </td>

                                <td>
                                    <c:choose>
                                        <c:when test="${banner.active}">
                                            <span class="badge bg-success-subtle text-success rounded-pill px-3 py-2">
                                                Đang bật
                                            </span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-secondary-subtle text-secondary rounded-pill px-3 py-2">
                                                Đang tắt
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>

                                <td class="text-end">
                                    <div class="d-inline-flex flex-wrap justify-content-end gap-1">
                                        <a href="${pageContext.request.contextPath}/staff/banner?action=toggle&id=${banner.bannerId}&active=${banner.active ? 0 : 1}"
                                           class="btn btn-sm btn-light border rounded-2 ${banner.active ? 'text-warning' : 'text-success'}"
                                           title="${banner.active ? 'Tắt banner' : 'Bật banner'}">
                                            <i class="bi ${banner.active ? 'bi-eye-slash' : 'bi-eye'}"></i>
                                        </a>

                                        <a href="${pageContext.request.contextPath}/staff/banner?action=delete&id=${banner.bannerId}"
                                           class="btn btn-sm btn-light text-danger border rounded-2"
                                           title="Xóa"
                                           onclick="return confirm('Bạn có chắc muốn xóa banner này không?');">
                                            <i class="bi bi-trash"></i>
                                        </a>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                    </c:when>

                    <c:otherwise>
                        <tr>
                            <td colspan="6" class="text-center py-5">
                                <i class="bi bi-images fs-1 d-block mb-2 text-secondary"></i>
                                <div class="fw-semibold">Chưa có banner nào.</div>
                                <small class="text-muted">
                                    Tải ảnh lên bằng biểu mẫu phía trên để bắt đầu.
                                </small>
                            </td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </tbody>
        </table>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>
