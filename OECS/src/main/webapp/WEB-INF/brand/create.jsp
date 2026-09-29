<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-md-8 col-lg-6">
        
        <!-- Nút Back tinh tế -->
        <div class="mb-3">
            <a href="${pageContext.request.contextPath}/brand?view=list" class="text-decoration-none text-muted fw-medium">
                <i class="bi bi-arrow-left me-1"></i> Quay lại danh sách
            </a>
        </div>

        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-body p-4 p-md-5">
                <div class="d-flex align-items-center mb-4 pb-3 border-bottom">
                    <div class="bg-primary bg-opacity-10 text-primary rounded d-flex align-items-center justify-content-center me-3" style="width: 48px; height: 48px;">
                        <i class="bi bi-plus-circle fs-4"></i>
                    </div>
                    <div>
                        <h4 class="fw-bold mb-0">Thêm Thương Hiệu</h4>
                        <span class="text-muted fs-7">Nhập thông tin cho thương hiệu mới</span>
                    </div>
                </div>

                <form action="${pageContext.request.contextPath}/brand" method="POST">
                    <input type="hidden" name="action" value="create" />

                    <div class="mb-4">
                        <label for="brand-name" class="form-label fw-semibold text-dark">Tên Thương Hiệu <span class="text-danger">*</span></label>
                        <input type="text"
                               name="name"
                               id="brand-name"
                               class="form-control form-control-lg fs-6"
                               placeholder="VD: Samsung, Apple, Nike..."
                               required />
                    </div>

                    <div class="mb-4">
                        <label for="brand-logo" class="form-label fw-semibold text-dark">Đường Dẫn Logo (URL)</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light border-end-0"><i class="bi bi-link-45deg"></i></span>
                            <input type="url"
                                   name="logoUrl"
                                   id="brand-logo"
                                   class="form-control form-control-lg fs-6 border-start-0 ps-0"
                                   placeholder="https://..." />
                        </div>
                        <div class="form-text mt-2"><i class="bi bi-info-circle me-1"></i>Copy URL hình ảnh và dán vào đây.</div>
                    </div>

                    <div class="d-flex gap-2 pt-3 mt-4 border-top">
                        <button type="submit" class="btn btn-primary btn-lg fs-6 px-4">
                            Lưu Thương Hiệu
                        </button>
                        <button type="reset" class="btn btn-light btn-lg fs-6 px-4 border text-muted">
                            Hủy
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>