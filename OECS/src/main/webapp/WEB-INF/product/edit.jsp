<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="row justify-content-center">
    <div class="col-md-9 col-lg-7">

        <div class="mb-3">
            <a href="${pageContext.request.contextPath}/product?view=list" class="text-decoration-none text-muted fw-medium">
                <i class="bi bi-arrow-left me-1"></i> Quay lại danh sách
            </a>
        </div>

        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-body p-4 p-md-5">

                <div class="d-flex align-items-center mb-4 pb-3 border-bottom">
                    <div class="bg-primary bg-opacity-10 text-primary rounded d-flex align-items-center justify-content-center me-3" style="width: 48px; height: 48px;">
                        <i class="bi bi-pencil-square fs-4"></i>
                    </div>
                    <div>
                        <h4 class="fw-bold mb-0">Chỉnh Sửa Sản Phẩm</h4>
                        <span class="text-muted fs-7">Cập nhật thông tin sản phẩm</span>
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
                    <input type="hidden" name="action" value="edit">

                    <div class="mb-4">
                        <label class="form-label fw-semibold">Mã Sản Phẩm</label>
                        <input type="text" name="id" class="form-control form-control-lg bg-light" value="${product.productId}" readonly>
                    </div>

                    <div class="mb-4">
                        <label class="form-label fw-semibold">Tên Sản Phẩm <span class="text-danger">*</span></label>
                        <input type="text" name="name" class="form-control form-control-lg" value="<c:out value='${product.productName}'/>" required>
                    </div>

                    <div class="mb-4">
                        <label class="form-label fw-semibold">Danh Mục <span class="text-danger">*</span></label>
                        <select name="categoryId" class="form-select form-select-lg" required>
                            <c:forEach items="${categoryList}" var="category">
                                <option value="${category.categoryId}" ${category.categoryId == product.categoryId ? 'selected' : ''}>
                                    <c:out value="${category.categoryName}" />
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="mb-4">
                        <label class="form-label fw-semibold">Thương Hiệu <span class="text-danger">*</span></label>
                        <select name="brandId" class="form-select form-select-lg" required>
                            <c:forEach items="${brandList}" var="brand">
                                <option value="${brand.brandId}" ${brand.brandId == product.brandId ? 'selected' : ''}>
                                    <c:out value="${brand.brandName}" />
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="mb-4">
                        <label class="form-label fw-semibold">Hình ảnh Đại Diện</label>
                        <c:if test="${not empty product.imageUrl}">
                            <div class="mb-2">
                                <img src="${pageContext.request.contextPath}/${product.imageUrl}" alt="Ảnh sản phẩm" class="img-thumbnail" style="height: 100px; width: 100px; object-fit: cover;">
                            </div>
                        </c:if>
                        <input type="file" name="imageFile" class="form-control form-control-lg" accept="image/png, image/jpeg, image/jpg, image/webp">
                        <div class="form-text">Để trống nếu không muốn thay đổi ảnh đại diện.</div>
                    </div>

                    <div class="mb-4 p-3 bg-light border rounded-3">
                        <label class="form-label fw-semibold text-primary mb-3">Hình ảnh Phụ (Gallery)</label>

                        <c:if test="${not empty product.galleryImages}">
                            <div class="d-flex flex-wrap gap-3 mb-3">
                                <c:forEach items="${product.galleryImages}" var="img">
                                    <div class="position-relative border rounded p-2 text-center bg-white shadow-sm" style="width: 110px;">
                                        <img src="${pageContext.request.contextPath}/${img.imageUrl}" 
                                             class="img-thumbnail border-0 p-0 mb-2" 
                                             style="height: 80px; width: 100%; object-fit: cover;">

                                        <div class="form-check d-flex justify-content-center align-items-center m-0">
                                            <input class="form-check-input border-danger" type="checkbox" name="deleteImageIds" value="${img.imageId}" id="delImg_${img.imageId}">
                                            <label class="form-check-label text-danger fw-medium ms-1" style="font-size: 13px;" for="delImg_${img.imageId}">
                                                Xóa ảnh
                                            </label>
                                        </div>
                                    </div>
                                </c:forEach>
                            </div>
                            <div class="form-text text-danger mb-4">
                                <i class="bi bi-exclamation-circle me-1"></i> Tích vào nút "Xóa ảnh" bên dưới nếu bạn muốn gỡ bỏ ảnh đó.
                            </div>
                        </c:if>

                        <label class="form-label fw-semibold text-dark">Tải thêm Hình ảnh Phụ</label>
                        <input type="file" name="galleryFiles" class="form-control" accept="image/png, image/jpeg, image/jpg, image/webp" multiple>
                        <div class="form-text text-muted">
                            <i class="bi bi-info-circle me-1"></i> Giữ phím <b>Ctrl/Cmd</b> để chọn nhiều ảnh bổ sung (Các ảnh cũ không bị tích Xóa sẽ được giữ nguyên).
                        </div>
                    </div>

                    <div class="mb-4">
                        <label class="form-label fw-semibold">Mô Tả</label>
                        <textarea name="description" class="form-control" rows="5"><c:out value="${product.description}"/></textarea>
                    </div>

                    <div class="d-flex gap-2 pt-3 mt-4 border-top">
                        <button type="submit" class="btn btn-primary btn-lg px-4">
                            <i class="bi bi-check-lg me-1"></i> Lưu Thay Đổi
                        </button>
                        <a href="${pageContext.request.contextPath}/product?view=list" class="btn btn-light btn-lg px-4 border">Hủy</a>
                    </div>
                </form>

            </div>
        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp"%>