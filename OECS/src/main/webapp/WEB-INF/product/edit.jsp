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

                <!-- Header -->
                <div class="d-flex align-items-center mb-4 pb-3 border-bottom">
                    <div class="bg-primary bg-opacity-10 text-primary rounded d-flex align-items-center justify-content-center me-3" style="width: 48px; height: 48px;">
                        <i class="bi bi-pencil-square fs-4"></i>
                    </div>
                    <div>
                        <h4 class="fw-bold mb-0">
                            Chỉnh Sửa Sản Phẩm
                        </h4>
                        <span class="text-muted fs-7">
                            Cập nhật thông tin sản phẩm
                        </span>
                    </div>
                </div>

                <!-- Error -->
                <c:if test="${param.error == 'true'}">
                    <div class="alert alert-danger">
                        Không thể cập nhật sản phẩm.
                    </div>
                </c:if>

                <form action="${pageContext.request.contextPath}/product" method="POST">

                    <input type="hidden" name="action" value="edit">

                    <!-- ID -->
                    <div class="mb-4">
                        <label class="form-label fw-semibold">
                            Mã Sản Phẩm
                        </label>
                        <input type="text" name="id" class="form-control form-control-lg bg-light" value="${product.productId}" readonly>
                    </div>

                    <!-- Name -->
                    <div class="mb-4">
                        <label class="form-label fw-semibold">
                            Tên Sản Phẩm <span class="text-danger">*</span>
                        </label>
                        <input type="text" name="name" class="form-control form-control-lg" value="${product.productName}" required>
                    </div>

                    <!-- Category -->
                    <div class="mb-4">
                        <label class="form-label fw-semibold">
                            Danh Mục <span class="text-danger">*</span>
                        </label>
                        <select name="categoryId" class="form-select form-select-lg" required>
                            <c:forEach items="${categoryList}" var="category">
                                <option value="${category.categoryId}" ${category.categoryId == product.categoryId ? 'selected' : ''}>
                                    ${category.categoryName}
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <!-- Brand -->
                    <div class="mb-4">
                        <label class="form-label fw-semibold">
                            Thương Hiệu <span class="text-danger">*</span>
                        </label>
                        <select name="brandId" class="form-select form-select-lg" required>
                            <c:forEach items="${brandList}" var="brand">
                                <option value="${brand.brandId}" ${brand.brandId == product.brandId ? 'selected' : ''}>
                                    ${brand.brandName}
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <!-- Description -->
                    <div class="mb-4">
                        <label class="form-label fw-semibold">
                            Mô Tả
                        </label>
                        <textarea name="description" class="form-control" rows="5">${product.description}</textarea>
                    </div>

                    <!-- Buttons -->
                    <div class="d-flex gap-2 pt-3 mt-4 border-top">
                        <button type="submit" class="btn btn-primary btn-lg px-4">
                            <i class="bi bi-check-lg me-1"></i>
                            Lưu Thay Đổi
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