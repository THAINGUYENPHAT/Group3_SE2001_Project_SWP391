<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<!-- Page Header -->
<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
    <div>
        <h3 class="fw-bold text-dark mb-1">Quản lý Sản Phẩm</h3>
        <p class="text-muted fs-7 mb-0">Hiển thị và quản lý toàn bộ sản phẩm trong hệ thống.</p>
    </div>

    <a href="${pageContext.request.contextPath}/product?view=create" class="btn btn-primary btn-md fw-semibold px-3 py-2 shadow-sm rounded-3">
        <i class="bi bi-plus-lg me-1"></i> Thêm sản phẩm
    </a>
</div>

<!-- Statistics -->
<div class="row g-3 mb-4">
    <div class="col-12 col-md-4">
        <div class="stat-card">
            <div class="d-flex justify-content-between align-items-center">
                <span class="text-muted fs-7 fw-medium">Tổng sản phẩm</span>
                <span class="badge bg-primary-subtle text-primary rounded-pill">
                    <i class="bi bi-box-seam"></i>
                </span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">${not empty productList ? fn:length(productList) : 0}</span>
                <span class="text-success fs-7 ms-2">Đang hoạt động</span>
            </div>
        </div>
    </div>

    <div class="col-12 col-md-4">
        <div class="stat-card">
            <div class="d-flex justify-content-between align-items-center">
                <span class="text-muted fs-7 fw-medium">Danh mục</span>
                <span class="badge bg-success-subtle text-success rounded-pill">
                    <i class="bi bi-grid"></i>
                </span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">Product</span>
                <span class="text-muted fs-7 ms-2">Category</span>
            </div>
        </div>
    </div>

    <div class="col-12 col-md-4">
        <div class="stat-card">
            <div class="d-flex justify-content-between align-items-center">
                <span class="text-muted fs-7 fw-medium">Quản lý</span>
                <span class="badge bg-info-subtle text-info rounded-pill">
                    <i class="bi bi-shield-lock"></i>
                </span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">Admin</span>
                <span class="text-muted fs-7 ms-2">Toàn quyền</span>
            </div>
        </div>
    </div>
</div>

<!-- Main Card -->
<div class="card-custom overflow-hidden">

    <!-- Toolbar: Đã sửa thành Form GET cho phép tìm kiếm -->
    <div class="p-3 border-bottom d-flex justify-content-between align-items-center">
        <form action="${pageContext.request.contextPath}/product" method="GET" class="search-box mb-0 d-flex gap-2" style="min-width: 350px;">
            <input type="hidden" name="view" value="list">
            <div class="position-relative flex-grow-1">
                <i class="bi bi-search position-absolute top-50 start-0 translate-middle-y ms-3 text-muted"></i>
                <input type="text" name="search" value="${param.search}" class="form-control ps-5" placeholder="Tìm tên sản phẩm, danh mục, hãng...">
            </div>
            <button type="submit" class="btn btn-primary">Tìm kiếm</button>
            <c:if test="${not empty param.search}">
                <a href="${pageContext.request.contextPath}/product?view=list" class="btn btn-light border" title="Xóa tìm kiếm">
                    <i class="bi bi-x-lg"></i>
                </a>
            </c:if>
        </form>
    </div>

    <!-- Table -->
    <div class="table-responsive">
        <table class="table table-custom align-middle">
            <thead>
                <tr>
                <th style="width: 50px;">#</th>
                <th>HÌNH ẢNH</th>
                <th>SẢN PHẨM</th>
                <th>DANH MỤC</th>
                <th>THƯƠNG HIỆU</th>
                <th>MÔ TẢ</th>
                <th style="width: 130px;" class="text-end">THAO TÁC</th>
                </tr>
            </thead>

            <tbody>
                <c:choose>
                    <c:when test="${not empty productList}">
                        <c:forEach items="${productList}" var="product">
                            <tr>
                                <!-- ID -->
                            <td>
                            <span class="badge bg-light text-secondary border">#${product.productId}</span>
                            </td>

                            <!-- HÌNH ẢNH -->
                            <td>
                                <c:choose>
                                    <c:when test="${not empty product.imageUrl}">
                                        <img src="${pageContext.request.contextPath}/${product.imageUrl}" class="img-thumbnail rounded" style="width: 50px; height: 50px; object-fit: cover;">
                                    </c:when>
                                    <c:otherwise>
                                        <div class="bg-light text-secondary d-flex align-items-center justify-content-center rounded border" style="width: 50px; height: 50px;">
                                            <i class="bi bi-image fs-5"></i>
                                        </div>
                                    </c:otherwise>
                                </c:choose>
                            </td>

                            <!-- Product Name -->
                            <td>
                                <div class="fw-bold text-dark">${product.productName}</div>
                                <small class="text-muted">Ngày: ${product.createdAt}</small>
                            </td>

                            <!-- Category -->
                            <td>
                                <c:choose>
                                    <c:when test="${product.category != null}">
                                    <span class="badge bg-primary-subtle text-primary border border-primary-subtle">
                                        <i class="bi bi-folder me-1"></i> ${product.category.categoryName}
                                    </span>
                                </c:when>
                                <c:otherwise><span class="text-muted">Không có</span></c:otherwise>
                            </c:choose>
                            </td>

                            <!-- Brand -->
                            <td>
                                <c:choose>
                                    <c:when test="${product.brand != null}">
                                    <span class="badge bg-info-subtle text-info border border-info-subtle">
                                        ${product.brand.brandName}
                                    </span>
                                </c:when>
                                <c:otherwise><span class="text-muted">Không có</span></c:otherwise>
                            </c:choose>
                            </td>

                            <!-- Description -->
                            <td>
                                <c:choose>
                                    <c:when test="${not empty product.description}">
                                    <span class="text-muted" style="display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">
                                        ${product.description}
                                    </span>
                                </c:when>
                                <c:otherwise><span class="text-muted">Không có</span></c:otherwise>
                            </c:choose>
                            </td>

                            <!-- Actions -->
                            <td class="text-end">
                                <div class="d-inline-flex gap-1">
                                    <a href="${pageContext.request.contextPath}/product-sku?productId=${product.productId}" class="btn btn-sm btn-light text-success border rounded-2" title="Quản lý SKU (Giá & Tồn kho)">
                                        <i class="bi bi-tags"></i>
                                    </a>
                                    <a href="${pageContext.request.contextPath}/product?view=edit&id=${product.productId}" class="btn btn-sm btn-light text-primary border rounded-2" title="Chỉnh sửa">
                                        <i class="bi bi-pencil-square"></i>
                                    </a>
                                    <a href="${pageContext.request.contextPath}/product?view=delete&id=${product.productId}" class="btn btn-sm btn-light text-danger border rounded-2" title="Xóa">
                                        <i class="bi bi-trash"></i>
                                    </a>
                                </div>
                            </td>
                            </tr>
                        </c:forEach>
                    </c:when>

                    <c:otherwise>
                        <tr>
                        <td colspan="7" class="text-center py-5">
                            <i class="bi bi-box-seam fs-1 text-secondary"></i>
                            <p class="fw-medium mt-2 mb-1">Chưa có sản phẩm nào</p>
                            <small class="text-muted">Nhấn "Thêm sản phẩm" để bắt đầu.</small>
                        </td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </tbody>
        </table>
    </div>

    <!-- Footer -->
    <div class="p-3 border-top bg-white">
        <span class="text-muted fs-7">
            Hiển thị <strong>${not empty productList ? fn:length(productList) : 0}</strong> sản phẩm
        </span>
    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp"%>