<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="row justify-content-center">
    <div class="col-md-9 col-lg-7">

        <div class="mb-3">
            <a href="${pageContext.request.contextPath}/product?view=list" class="text-decoration-none text-muted fw-medium">
                <i class="bi bi-arrow-left me-1"></i>
                Quay lại danh sách
            </a>
        </div>

        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-body p-4 p-md-5">

                <div class="d-flex align-items-center mb-4 pb-3 border-bottom">
                    <div class="bg-primary bg-opacity-10 text-primary rounded d-flex align-items-center justify-content-center me-3" style="width: 48px; height: 48px;">
                        <i class="bi bi-box-seam fs-4"></i>
                    </div>
                    <div>
                        <h4 class="fw-bold mb-0">Thêm Sản Phẩm Mới</h4>
                        <span class="text-muted fs-7">Nhập thông tin sản phẩm</span>
                    </div>
                </div>

                <c:if test="${not empty sessionScope.errorMsg}">
                    <div class="alert alert-danger">
                        <i class="bi bi-exclamation-triangle me-2"></i>
                        <c:out value="${sessionScope.errorMsg}" />
                    </div>
                    <c:remove var="errorMsg" scope="session"/>
                </c:if>

                <c:if test="${param.error == 'true'}">
                    <div class="alert alert-danger">
                        <i class="bi bi-exclamation-triangle me-2"></i>
                        Lỗi hệ thống! Không thể thực hiện thao tác. Vui lòng kiểm tra lại dữ liệu.
                    </div>
                </c:if>

                <form action="${pageContext.request.contextPath}/product" method="POST" enctype="multipart/form-data">
                    <input type="hidden" name="action" value="create">

                    <div class="mb-4">
                        <label class="form-label fw-semibold">
                            Tên Sản Phẩm <span class="text-danger">*</span>
                        </label>
                        <input type="text" name="name" class="form-control form-control-lg" 
                               placeholder="VD: iPhone 17 Pro Max" 
                               value="<c:out value='${param.name}' />" required>
                    </div>

                    <div class="mb-4">
                        <label class="form-label fw-semibold">
                            Danh Mục <span class="text-danger">*</span>
                        </label>
                        <select name="categoryId" class="form-select form-select-lg" required>
                            <option value="">-- Chọn danh mục --</option>
                            <c:forEach items="${categoryList}" var="category">
                                <option value="${category.categoryId}" ${param.categoryId == category.categoryId ? 'selected' : ''}>
                                    <c:out value="${category.categoryName}" />
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="mb-4">
                        <label class="form-label fw-semibold">
                            Thương Hiệu <span class="text-danger">*</span>
                        </label>
                        <select name="brandId" class="form-select form-select-lg" required>
                            <option value="">-- Chọn thương hiệu --</option>
                            <c:forEach items="${brandList}" var="brand">
                                <option value="${brand.brandId}" ${param.brandId == brand.brandId ? 'selected' : ''}>
                                    <c:out value="${brand.brandName}" />
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="mb-4">
                        <label class="form-label fw-semibold">Hình ảnh Đại diện <span class="text-danger">*</span></label>
                        <input type="file" name="imageFile" class="form-control form-control-lg" accept="image/png, image/jpeg, image/jpg, image/webp" required>
                        <div class="form-text">Ảnh hiển thị bên ngoài danh sách sản phẩm. Tối đa 10MB.</div>
                    </div>

                    <div class="mb-4 p-3 bg-light border rounded-3">
                        <label class="form-label fw-semibold text-primary">Các Hình ảnh Phụ (Xem chi tiết)</label>
                        <input type="file" name="galleryFiles" class="form-control" accept="image/png, image/jpeg, image/jpg, image/webp" multiple>
                        <div class="form-text text-muted">
                            <i class="bi bi-info-circle me-1"></i> Giữ phím <b>Ctrl</b> (Windows) hoặc <b>Cmd</b> (Mac) để chọn nhiều ảnh cùng lúc.
                        </div>
                    </div>

                    <div class="mb-4">
                        <label class="form-label fw-semibold">Mô Tả</label>
                        <textarea name="description" class="form-control" rows="5" placeholder="Nhập mô tả sản phẩm..."><c:out value="${param.description}" /></textarea>
                    </div>

                    <div class="d-flex gap-2 pt-3 mt-4 border-top">
                        <button type="submit" class="btn btn-primary btn-lg px-4">
                            <i class="bi bi-check-lg me-1"></i> Lưu Sản Phẩm
                        </button>
                        <a href="${pageContext.request.contextPath}/product?view=list" class="btn btn-light btn-lg px-4 border">
                            Hủy
                        </a>
                    </div>
                </form>

            </div>
        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp"%>