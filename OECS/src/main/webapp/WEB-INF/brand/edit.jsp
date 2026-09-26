<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-md-8 col-lg-6">
        <div class="card shadow-sm">
            <div class="card-header bg-primary text-white">
                <h4 class="mb-0"><i class="bi bi-pencil-square me-2"></i>Chỉnh Sửa Thương Hiệu</h4>
            </div>
            <div class="card-body">
                <c:choose>
                    <%-- Nếu tìm thấy đối tượng Brand trong request --%>
                    <c:when test="${not empty brand}">
                        <form action="${pageContext.request.contextPath}/brand" method="POST">
                            <%-- Action gửi về Servlet --%>
                            <input type="hidden" name="action" value="edit" />

                            <%-- ID (Chỉ đọc) --%>
                            <div class="mb-3">
                                <label for="brand-id" class="form-label fw-bold">ID Thương Hiệu</label>
                                <input type="text"
                                       name="id"
                                       value="${brand.brandId}"
                                       id="brand-id"
                                       class="form-control bg-light"
                                       readonly />
                            </div>

                            <%-- Tên Thương Hiệu --%>
                            <div class="mb-3">
                                <label for="brand-name" class="form-label fw-bold">Tên Thương Hiệu <span class="text-danger">*</span></label>
                                <input type="text"
                                       name="name"
                                       value="${brand.brandName}"
                                       id="brand-name"
                                       class="form-control"
                                       placeholder="Nhập tên thương hiệu..."
                                       required />
                            </div>

                            <%-- Đường dẫn Logo (Logo URL) --%>
                            <div class="mb-3">
                                <label for="brand-logo" class="form-label fw-bold">Đường Dẫn Logo (URL)</label>
                                <input type="url"
                                       name="logoUrl"
                                       value="${brand.logoUrl}"
                                       id="brand-logo"
                                       class="form-control"
                                       placeholder="https://example.com/logo.png" />
                            </div>

                            <%-- Hiển thị xem trước Logo (nếu có) --%>
                            <c:if test="${not empty brand.logoUrl}">
                                <div class="mb-3 text-center">
                                    <label class="form-label d-block text-muted small">Logo hiện tại:</label>
                                    <img src="${brand.logoUrl}" alt="${brand.brandName}" class="img-thumbnail" style="max-height: 80px; object-fit: contain;">
                                </div>
                            </c:if>

                            <%-- Nút bấm thao tác --%>
                            <div class="d-flex justify-content-between pt-2">
                                <a href="${pageContext.request.contextPath}/brand?view=list" class="btn btn-outline-secondary">
                                    <i class="bi bi-arrow-left"></i> Quay lại
                                </a>
                                <div>
                                    <button type="reset" class="btn btn-warning me-2">
                                        <i class="bi bi-arrow-counterclockwise"></i> Khôi phục
                                    </button>
                                    <button type="submit" class="btn btn-success">
                                        <i class="bi bi-save"></i> Lưu Thay Đổi
                                    </button>
                                </div>
                            </div>
                        </form>
                    </c:when>

                    <%-- Trường hợp không tìm thấy thương hiệu --%>
                    <c:otherwise>
                        <div class="alert alert-warning text-center my-3" role="alert">
                            <i class="bi bi-exclamation-triangle-fill fs-3 d-block mb-2"></i>
                             Không tìm thấy thương hiệu cần chỉnh sửa!
                        </div>
                        <div class="text-center">
                            <a href="${pageContext.request.contextPath}/brand?view=list" class="btn btn-secondary">
                                <i class="bi bi-arrow-left"></i> Quay lại danh sách
                            </a>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>