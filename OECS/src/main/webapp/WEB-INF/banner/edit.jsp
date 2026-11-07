
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h3 class="fw-bold text-dark mb-1">Chỉnh sửa Banner</h3>
        <p class="text-muted fs-7 mb-0">
            Cập nhật thông tin banner hiển thị trên trang chủ.
        </p>
    </div>

    <a href="${pageContext.request.contextPath}/staff/banner"
       class="btn btn-light border">
        <i class="bi bi-arrow-left me-2"></i>Quay lại
    </a>
</div>

<div class="card-custom overflow-hidden">
    <div class="p-3 border-bottom bg-white">
        <h5 class="fw-bold mb-0">
            <i class="bi bi-pencil-square me-2"></i>
            Banner #${banner.bannerId}
        </h5>
    </div>

    <form action="${pageContext.request.contextPath}/staff/banner"
          method="post"
          enctype="multipart/form-data"
          class="p-3">

        <input type="hidden" name="action" value="update">
        <input type="hidden" name="bannerId" value="${banner.bannerId}">

        <div class="mb-3">
            <label class="form-label fw-semibold">Ảnh hiện tại</label>
            <div>
                <img src="${pageContext.request.contextPath}/${banner.imageUrl}"
                     alt="<c:out value='${banner.altText}'/>"
                     class="rounded-3 border"
                     style="width: 300px; max-width: 100%; height: 140px; object-fit: cover;"
                     onerror="this.style.display='none'">
            </div>
        </div>

        <div class="mb-3">
            <label for="imageFile" class="form-label fw-semibold">
                Thay đổi hình ảnh
            </label>
            <input type="file"
                   id="imageFile"
                   name="imageFile"
                   class="form-control"
                   accept=".jpg,.jpeg,.png,.gif,.webp">

            <div class="form-text">
                Để trống nếu muốn giữ ảnh hiện tại. Tối đa 10 MB.
            </div>
        </div>

        <div class="mb-3">
            <label for="altText" class="form-label fw-semibold">
                Mô tả hình ảnh
            </label>
            <input type="text"
                   id="altText"
                   name="altText"
                   class="form-control"
                   maxlength="255"
                   value="<c:out value='${banner.altText}'/>"
                   pattern="[\p{L}\p{M}\p{N}\s.,!?()'’:;-]*"
                   title="Chỉ nhập chữ, số, khoảng trắng và dấu câu thông dụng.">
        </div>

        <div class="mb-3">
            <label for="targetUrl" class="form-label fw-semibold">
                Liên kết khi nhấn vào banner
            </label>
            <input type="text"
                   id="targetUrl"
                   name="targetUrl"
                   class="form-control"
                   maxlength="2048"
                   value="<c:out value='${banner.targetUrl}'/>"
                   placeholder="/shop hoặc để trống">
        </div>

        <div class="mb-3">
            <label for="displayOrder" class="form-label fw-semibold">
                Thứ tự hiển thị
            </label>
            <input type="number"
                   id="displayOrder"
                   name="displayOrder"
                   class="form-control"
                   min="0"
                   max="2147483647"
                   step="1"
                   value="${banner.displayOrder}"
                   required>
        </div>

        <div class="mb-3">
            <label class="form-label fw-semibold">Trạng thái</label>
            <div>
                <c:choose>
                    <c:when test="${banner.active}">
                        <span class="badge bg-success-subtle text-success px-3 py-2">
                            Đang bật
                        </span>
                    </c:when>
                    <c:otherwise>
                        <span class="badge bg-secondary-subtle text-secondary px-3 py-2">
                            Đang tắt
                        </span>
                    </c:otherwise>
                </c:choose>
                <small class="text-muted ms-2">
                    Trạng thái được giữ nguyên khi cập nhật.
                </small>
            </div>
        </div>

        <div class="d-flex justify-content-end gap-2">
            <a href="${pageContext.request.contextPath}/staff/banner"
               class="btn btn-light border">
                Hủy
            </a>

            <button type="submit" class="btn btn-primary fw-semibold px-4">
                <i class="bi bi-save me-2"></i>Lưu thay đổi
            </button>
        </div>
    </form>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>
