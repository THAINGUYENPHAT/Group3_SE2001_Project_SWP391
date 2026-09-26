<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-md-8 col-lg-6">
        <div class="card shadow-sm">
            <div class="card-header bg-success text-white">
                <h4 class="mb-0"><i class="bi bi-plus-circle me-2"></i>Thêm Thương Hiệu Mới</h4>
            </div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/brand" method="POST">
                    <%-- Action gửi về BrandServlet --%>
                    <input type="hidden" name="action" value="create" />

                    <%-- Tên Thương Hiệu --%>
                    <div class="mb-3">
                        <label for="brand-name" class="form-label fw-bold">Tên Thương Hiệu <span class="text-danger">*</span></label>
                        <input type="text"
                               name="name"
                               id="brand-name"
                               class="form-control"
                               placeholder="Nhập tên thương hiệu..."
                               required />
                    </div>

                    <%-- Đường Dẫn Logo --%>
                    <div class="mb-3">
                        <label for="brand-logo" class="form-label fw-bold">Đường Dẫn Logo (URL)</label>
                        <input type="url"
                               name="logoUrl"
                               id="brand-logo"
                               class="form-control"
                               placeholder="https://example.com/logo.png" />
                    </div>

                    <%-- Nút bấm thao tác --%>
                    <div class="d-flex justify-content-between pt-2">
                        <a href="${pageContext.request.contextPath}/brand?view=list" class="btn btn-outline-secondary">
                            <i class="bi bi-arrow-left"></i> Quay lại
                        </a>
                        <div>
                            <button type="reset" class="btn btn-warning me-2">
                                <i class="bi bi-eraser"></i> Nhập lại
                            </button>
                            <button type="submit" class="btn btn-success">
                                <i class="bi bi-save"></i> Thêm Mới
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>