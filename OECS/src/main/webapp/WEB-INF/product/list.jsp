<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fn" uri="jakarta.tags.functions" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<!-- Page Header -->
<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">

    <div>

        <h3 class="fw-bold text-dark mb-1">
            Quản lý Sản Phẩm
        </h3>

        <p class="text-muted fs-7 mb-0">
            Hiển thị và quản lý toàn bộ sản phẩm trong hệ thống.
        </p>

    </div>

    <a href="${pageContext.request.contextPath}/product?view=create"
       class="btn btn-primary btn-md fw-semibold px-3 py-2 shadow-sm rounded-3">

        <i class="bi bi-plus-lg me-1"></i>

        Thêm sản phẩm

    </a>

</div>


<!-- Statistics -->
<div class="row g-3 mb-4">

    <div class="col-12 col-md-4">

        <div class="stat-card">

            <div class="d-flex justify-content-between align-items-center">

                <span class="text-muted fs-7 fw-medium">
                    Tổng sản phẩm
                </span>

                <span class="badge bg-primary-subtle text-primary rounded-pill">
                    <i class="bi bi-box-seam"></i>
                </span>

            </div>

            <div class="mt-2">

                <span class="fs-3 fw-bold text-dark">
                    ${not empty productList ? fn:length(productList) : 0}
                </span>

                <span class="text-success fs-7 ms-2">
                    Đang hoạt động
                </span>

            </div>

        </div>

    </div>


    <div class="col-12 col-md-4">

        <div class="stat-card">

            <div class="d-flex justify-content-between align-items-center">

                <span class="text-muted fs-7 fw-medium">
                    Danh mục
                </span>

                <span class="badge bg-success-subtle text-success rounded-pill">
                    <i class="bi bi-grid"></i>
                </span>

            </div>

            <div class="mt-2">

                <span class="fs-3 fw-bold text-dark">
                    Product
                </span>

                <span class="text-muted fs-7 ms-2">
                    Category
                </span>

            </div>

        </div>

    </div>


    <div class="col-12 col-md-4">

        <div class="stat-card">

            <div class="d-flex justify-content-between align-items-center">

                <span class="text-muted fs-7 fw-medium">
                    Quản lý
                </span>

                <span class="badge bg-info-subtle text-info rounded-pill">
                    <i class="bi bi-shield-lock"></i>
                </span>

            </div>

            <div class="mt-2">

                <span class="fs-3 fw-bold text-dark">
                    Admin
                </span>

                <span class="text-muted fs-7 ms-2">
                    Toàn quyền
                </span>

            </div>

        </div>

    </div>

</div>


<!-- Main Card -->
<div class="card-custom overflow-hidden">

    <!-- Toolbar -->
    <div class="p-3 border-bottom d-flex justify-content-between align-items-center">

        <div class="search-box"
             style="min-width: 300px;">

            <i class="bi bi-search"></i>

            <input type="text"
                   class="form-control"
                   placeholder="Tìm kiếm sản phẩm...">

        </div>

    </div>


    <!-- Table -->
    <div class="table-responsive">

        <table class="table table-custom align-middle">

            <thead>

                <tr>

                    <th style="width: 50px;">
                        #
                    </th>

                    <th>
                        SẢN PHẨM
                    </th>

                    <th>
                        DANH MỤC
                    </th>

                    <th>
                        THƯƠNG HIỆU
                    </th>

                    <th>
                        MÔ TẢ
                    </th>

                    <th>
                        NGÀY TẠO
                    </th>

                    <th style="width: 120px;"
                        class="text-end">
                        THAO TÁC
                    </th>

                </tr>

            </thead>


            <tbody>

                <c:choose>

                    <c:when test="${not empty productList}">

                        <c:forEach items="${productList}"
                                   var="product">

                            <tr>

                                <!-- ID -->
                                <td>

                                    <span class="badge bg-light text-secondary border">
                                        #${product.productId}
                                    </span>

                                </td>


                                <!-- Product -->
                                <td>

                                    <div class="fw-bold text-dark">
                                        ${product.productName}
                                    </div>

                                </td>


                                <!-- Category -->
                                <td>

                                    <c:choose>

                                        <c:when test="${product.category != null}">

                                            <span class="badge bg-primary-subtle text-primary border border-primary-subtle">

                                                <i class="bi bi-folder me-1"></i>

                                                ${product.category.categoryName}

                                            </span>

                                        </c:when>

                                        <c:otherwise>

                                            <span class="text-muted">
                                                Không có
                                            </span>

                                        </c:otherwise>

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

                                        <c:otherwise>

                                            <span class="text-muted">
                                                Không có
                                            </span>

                                        </c:otherwise>

                                    </c:choose>

                                </td>


                                <!-- Description -->
                                <td>

                                    <c:choose>

                                        <c:when test="${not empty product.description}">

                                            <span class="text-muted">
                                                ${product.description}
                                            </span>

                                        </c:when>

                                        <c:otherwise>

                                            <span class="text-muted">
                                                Không có mô tả
                                            </span>

                                        </c:otherwise>

                                    </c:choose>

                                </td>


                                <!-- Created At -->
                                <td>

                                    <span class="text-muted">

                                        ${product.createdAt}

                                    </span>

                                </td>


                                <!-- Actions -->
                                <td class="text-end">

                                    <div class="d-inline-flex gap-1">

                                        <a href="${pageContext.request.contextPath}/product?view=edit&id=${product.productId}"
                                           class="btn btn-sm btn-light text-primary border rounded-2"
                                           title="Chỉnh sửa">

                                            <i class="bi bi-pencil-square"></i>

                                        </a>


                                        <a href="${pageContext.request.contextPath}/product?view=delete&id=${product.productId}"
                                           class="btn btn-sm btn-light text-danger border rounded-2"
                                           title="Xóa">

                                            <i class="bi bi-trash"></i>

                                        </a>

                                    </div>

                                </td>

                            </tr>

                        </c:forEach>

                    </c:when>


                    <c:otherwise>

                        <tr>

                            <td colspan="7"
                                class="text-center py-5">

                                <i class="bi bi-box-seam fs-1 text-secondary"></i>

                                <p class="fw-medium mt-2 mb-1">
                                    Chưa có sản phẩm nào
                                </p>

                                <small class="text-muted">
                                    Nhấn "Thêm sản phẩm" để bắt đầu.
                                </small>

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

            Hiển thị

            <strong>
                ${not empty productList ? fn:length(productList) : 0}
            </strong>

            sản phẩm

        </span>

    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp" %>