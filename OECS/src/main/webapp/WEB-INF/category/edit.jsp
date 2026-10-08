<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-md-9 col-lg-7">
        <!-- Nút Back -->
        <div class="mb-3">
            <a href="${pageContext.request.contextPath}/category?view=list"
               class="text-decoration-none text-muted fw-medium">
                <i class="bi bi-arrow-left me-1"></i>
                Quay lại danh sách
            </a>
        </div>

        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-body p-4 p-md-5">
                <!-- Header -->
                <div class="d-flex align-items-center mb-4 pb-3 border-bottom">
                    <div class="bg-primary bg-opacity-10 text-primary rounded d-flex align-items-center justify-content-center me-3"
                         style="width: 48px; height: 48px;">
                        <i class="bi bi-pencil-square fs-4"></i>
                    </div>

                    <div>
                        <h4 class="fw-bold mb-0">Chỉnh Sửa Danh Mục</h4>
                        <span class="text-muted fs-7">Cập nhật thông tin danh mục</span>
                    </div>
                </div>

                <!-- Form -->
                <form action="${pageContext.request.contextPath}/category" method="POST">
                    <input type="hidden" name="action" value="edit" />

                    <!-- ID -->
                    <div class="mb-4">
                        <label for="category-id" class="form-label fw-semibold text-dark">
                            Mã Danh Mục
                        </label>
                        <input type="text"
                               name="id"
                               id="category-id"
                               class="form-control form-control-lg fs-6 bg-light"
                               value="${category.categoryId}"
                               readonly />
                    </div>

                    <!-- Tên -->
                    <div class="mb-4">
                        <label for="category-name" class="form-label fw-semibold text-dark">
                            Tên Danh Mục
                            <span class="text-danger">*</span>
                        </label>
                        <input type="text"
                               name="name"
                               id="category-name"
                               class="form-control form-control-lg fs-6"
                               value="${category.categoryName}"
                               required />
                    </div>

                    <!-- Danh mục cha -->
                    <div class="mb-4">
                        <label for="parent-id" class="form-label fw-semibold text-dark">
                            Danh Mục Cha
                        </label>
                        <select name="parentId"
                                id="parent-id"
                                class="form-select form-select-lg fs-6">
                            <option value="" ${category.parentId == null ? 'selected' : ''}>
                                -- Danh mục gốc --
                            </option>

                            <c:forEach items="${categoryList}" var="item">
                                <c:if test="${item.categoryId != category.categoryId}">
                                    <option value="${item.categoryId}"
                                            ${item.categoryId == category.parentId ? 'selected' : ''}>
                                        ${item.categoryName}
                                    </option>
                                </c:if>
                            </c:forEach>
                        </select>

                        <div class="form-text mt-2">
                            <i class="bi bi-info-circle me-1"></i>
                            Không thể chọn chính danh mục hiện tại làm danh mục cha.
                        </div>
                    </div>

                    <!-- Buttons -->
                    <div class="d-flex gap-2 pt-3 mt-4 border-top">
                        <button type="submit" class="btn btn-primary btn-lg fs-6 px-4">
                            <i class="bi bi-check-lg me-1"></i>
                            Lưu Thay Đổi
                        </button>

                        <a href="${pageContext.request.contextPath}/category?view=list"
                           class="btn btn-light btn-lg fs-6 px-4 border text-muted">
                            Hủy
                        </a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>