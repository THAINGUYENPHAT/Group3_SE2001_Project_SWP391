<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-md-8 col-lg-6">
        
        <div class="mb-3">
            <a href="${pageContext.request.contextPath}/brand?view=list" class="text-decoration-none text-muted fw-medium">
                <i class="bi bi-arrow-left me-1"></i> Quay lại danh sách
            </a>
        </div>

        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-body p-4 p-md-5">
                <c:choose>
                    <c:when test="${not empty brand}">
                        
                        <div class="d-flex align-items-center mb-4 pb-3 border-bottom">
                            <div class="bg-primary bg-opacity-10 text-primary rounded d-flex align-items-center justify-content-center me-3" style="width: 48px; height: 48px;">
                                <i class="bi bi-pencil-square fs-4"></i>
                            </div>
                            <div>
                                <h4 class="fw-bold mb-0">Chỉnh Sửa Thương Hiệu</h4>
                                <span class="text-muted fs-7">Cập nhật thông tin chi tiết</span>
                            </div>
                        </div>

                        <form action="${pageContext.request.contextPath}/brand" method="POST">
                            <input type="hidden" name="action" value="edit" />

                            <div class="row mb-4">
                                <div class="col-md-4">
                                    <label for="brand-id" class="form-label fw-semibold text-dark">ID</label>
                                    <input type="text"
                                           name="id"
                                           value="${brand.brandId}"
                                           id="brand-id"
                                           class="form-control form-control-lg fs-6 bg-light text-muted"
                                           readonly />
                                </div>
                                <div class="col-md-8">
                                    <label for="brand-name" class="form-label fw-semibold text-dark">Tên Thương Hiệu <span class="text-danger">*</span></label>
                                    <input type="text"
                                           name="name"
                                           value="<c:out value='${brand.brandName}'/>"
                                           id="brand-name"
                                           class="form-control form-control-lg fs-6"
                                           required />
                                </div>
                            </div>

                            <div class="mb-4">
                                <label for="brand-logo" class="form-label fw-semibold text-dark">Đường Dẫn Logo (URL)</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-light border-end-0"><i class="bi bi-link-45deg"></i></span>
                                    <input type="url"
                                           name="logoUrl"
                                           value="${brand.logoUrl}"
                                           id="brand-logo"
                                           class="form-control form-control-lg fs-6 border-start-0 ps-0" />
                                </div>
                            </div>

                            <c:if test="${not empty brand.logoUrl}">
                                <div class="mb-4 p-3 bg-light rounded-3 d-flex align-items-center">
                                    <span class="me-3 text-muted fw-medium fs-7">Xem trước:</span>
                                    <div class="bg-white border p-1 rounded" style="width: 60px; height: 60px;">
                                        <img src="${brand.logoUrl}" alt="<c:out value='${brand.brandName}'/>" style="width: 100%; height: 100%; object-fit: contain;">
                                    </div>
                                </div>
                            </c:if>

                            <div class="d-flex gap-2 pt-3 mt-4 border-top">
                                <button type="submit" class="btn btn-primary btn-lg fs-6 px-4">
                                    Cập nhật
                                </button>
                                <a href="${pageContext.request.contextPath}/brand?view=list" class="btn btn-light btn-lg fs-6 px-4 border text-muted">
                                    Hủy
                                </a>
                            </div>
                        </form>
                    </c:when>

                    <c:otherwise>
                        <div class="text-center py-5">
                            <div class="bg-warning bg-opacity-10 text-warning rounded-circle d-inline-flex align-items-center justify-content-center mb-3" style="width: 64px; height: 64px;">
                                <i class="bi bi-exclamation-triangle fs-2"></i>
                            </div>
                            <h5 class="fw-bold">Không tìm thấy dữ liệu!</h5>
                            <p class="text-muted">Thương hiệu bạn muốn chỉnh sửa không tồn tại.</p>
                            <a href="${pageContext.request.contextPath}/brand?view=list" class="btn btn-primary mt-2">Quay lại danh sách</a>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>