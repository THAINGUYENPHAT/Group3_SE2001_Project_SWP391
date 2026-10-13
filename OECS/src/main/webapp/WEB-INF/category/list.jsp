
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fn" uri="jakarta.tags.functions" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
    <div>
        <h3 class="fw-bold text-dark mb-1">Quản lý Danh Mục</h3>
        <p class="text-muted fs-7 mb-0">
            Quản lý danh mục gốc và danh mục con của các sản phẩm trong hệ thống.
        </p>
    </div>
</div>

<!-- Success messages -->
<c:if test="${not empty param.success}">
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        <c:choose>
            <c:when test="${param.success == 'create'}">
                Thêm danh mục thành công.
            </c:when>
            <c:when test="${param.success == 'edit'}">
                Cập nhật danh mục thành công.
            </c:when>
            <c:when test="${param.success == 'delete'}">
                Xóa danh mục thành công.
            </c:when>
        </c:choose>
        <button type="button" class="btn-close"
                data-bs-dismiss="alert" aria-label="Đóng"></button>
    </div>
</c:if>

<!-- Error messages -->
<c:if test="${not empty param.error}">
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <c:choose>
            <c:when test="${param.error == 'hasProducts'}">
                Không thể xóa danh mục vì vẫn còn sản phẩm hoặc danh mục con.
                Hãy xử lý các dữ liệu liên quan trước.
            </c:when>
            <c:when test="${param.error == 'notFound'}">
                Danh mục không tồn tại hoặc đã bị xóa.
            </c:when>
            <c:when test="${param.error == 'invalidId'}">
                ID danh mục không hợp lệ.
            </c:when>
            <c:when test="${param.error == 'name'}">
                Vui lòng nhập tên danh mục hợp lệ.
            </c:when>
            <c:when test="${param.error == 'parent'}">
                Danh mục cha không hợp lệ.
            </c:when>
            <c:when test="${param.error == 'delete'}">
                Không thể xóa danh mục.
            </c:when>
            <c:otherwise>
                Đã xảy ra lỗi khi xử lý danh mục. Vui lòng thử lại.
            </c:otherwise>
        </c:choose>
        <button type="button" class="btn-close"
                data-bs-dismiss="alert" aria-label="Đóng"></button>
    </div>
</c:if>

<!-- Statistics -->
<div class="row g-3 mb-4">
    <div class="col-12 col-sm-6 col-lg-4">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between">
                <span class="text-muted fs-7 fw-medium">Tổng danh mục</span>
                <span class="badge bg-primary-subtle text-primary rounded-pill px-3 py-2">
                    <i class="bi bi-tags-fill"></i>
                </span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">${totalCategories}</span>
                <span class="text-muted fs-7 ms-2">Danh mục</span>
            </div>
        </div>
    </div>

    <div class="col-12 col-sm-6 col-lg-4">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between">
                <span class="text-muted fs-7 fw-medium">Số danh mục mỗi trang</span>
                <span class="badge bg-success-subtle text-success rounded-pill px-3 py-2">
                    <i class="bi bi-list-ul"></i>
                </span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">10</span>
                <span class="text-muted fs-7 ms-2">Danh mục/trang</span>
            </div>
        </div>
    </div>

    <div class="col-12 col-sm-6 col-lg-4">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between">
                <span class="text-muted fs-7 fw-medium">Trang hiện tại</span>
                <span class="badge bg-info-subtle text-info rounded-pill px-3 py-2">
                    <i class="bi bi-file-earmark-text-fill"></i>
                </span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">${currentPage}</span>
                <span class="text-muted fs-7 ms-2">/ ${totalPages} trang</span>
            </div>
        </div>
    </div>
</div>

<!-- Category table -->
<div class="card-custom overflow-hidden">

    <!-- Search and create -->
    <div class="p-3 border-bottom d-flex flex-column flex-sm-row justify-content-between align-items-center gap-3 bg-white">
        <form action="${pageContext.request.contextPath}/category"
              method="get"
              class="search-box w-100 w-sm-auto d-flex align-items-center gap-2"
              style="min-width: 300px;">

            <input type="hidden" name="view" value="list">
            <i class="bi bi-search"></i>

            <input type="text"
                   name="keyword"
                   class="form-control"
                   placeholder="Tìm kiếm danh mục..."
                   value="<c:out value='${keyword}'/>">

            <button type="submit" class="btn btn-primary" title="Tìm kiếm">
                Tìm
            </button>

            <c:if test="${not empty keyword}">
                <a href="${pageContext.request.contextPath}/category?view=list"
                   class="btn btn-outline-secondary"
                   title="Xóa tìm kiếm">
                    <i class="bi bi-x-lg"></i>
                </a>
            </c:if>
        </form>

        <div class="d-flex align-items-center gap-2 w-100 w-sm-auto justify-content-end">
            <a class="btn btn-primary btn-md fw-semibold px-3 py-2 shadow-sm rounded-3 d-inline-flex align-items-center gap-2"
               href="${pageContext.request.contextPath}/category?view=create">
                <i class="bi bi-plus-lg fs-6"></i>
                <span>Thêm danh mục</span>
            </a>
        </div>
    </div>

    <!-- Table -->
    <div class="table-responsive">
        <table class="table table-custom align-middle">
            <thead>
                <tr>
                    <th style="width: 90px;">MÃ ID</th>
                    <th>TÊN DANH MỤC</th>
                    <th>DANH MỤC CHA</th>
                    <th>SẢN PHẨM</th>
                    <th>DANH MỤC CON</th>
                    <th>TRẠNG THÁI</th>
                    <th style="width: 140px;" class="text-end">THAO TÁC</th>
                </tr>
            </thead>

            <tbody>
                <c:choose>
                    <c:when test="${not empty categoryList}">
                        <c:forEach items="${categoryList}" var="category">
                            <tr>
                                <!-- Category ID -->
                                <td>
                                    <span class="badge bg-light text-secondary border fw-semibold">
                                        #${category.categoryId}
                                    </span>
                                </td>

                                <!-- Category name and hierarchy -->
                                <td>
                                    <div class="d-flex align-items-center gap-3"
                                         style="padding-left: ${categoryDepths[category.categoryId] * 24}px;">

                                        <div class="brand-logo-box">
                                            <div class="avatar-initial ${empty category.parentId ? '' : 'bg-light text-secondary'}">
                                                <c:choose>
                                                    <c:when test="${empty category.parentId}">
                                                        <i class="bi bi-folder-fill"></i>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <i class="bi bi-folder2-open"></i>
                                                    </c:otherwise>
                                                </c:choose>
                                            </div>
                                        </div>

                                        <div>
                                            <div class="fw-bold text-dark fs-6">
                                                <c:if test="${not empty category.parentId}">
                                                    <i class="bi bi-arrow-return-right text-muted me-1"></i>
                                                </c:if>

                                                <c:out value="${category.categoryName}"/>
                                            </div>

                                            <div class="text-muted fs-7">
                                                <c:choose>
                                                    <c:when test="${empty category.parentId}">
                                                        <i class="bi bi-diagram-3 me-1"></i>
                                                        Danh mục gốc
                                                    </c:when>
                                                    <c:otherwise>
                                                        <i class="bi bi-node-plus me-1"></i>
                                                        Danh mục con
                                                    </c:otherwise>
                                                </c:choose>
                                            </div>
                                        </div>
                                    </div>
                                </td>

                                <!-- Parent category -->
                                <td>
                                    <c:choose>
                                        <c:when test="${empty category.parentId}">
                                            <span class="badge bg-primary-subtle text-primary rounded-pill px-3 py-1">
                                                <i class="bi bi-diagram-3 me-1"></i>
                                                Danh mục gốc
                                            </span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-dark">
                                                <i class="bi bi-arrow-return-right text-muted me-1"></i>
                                                <c:choose>
                                                    <c:when test="${not empty categoryNames[category.parentId]}">
                                                        <c:out value="${categoryNames[category.parentId]}"/>
                                                    </c:when>
                                                    <c:otherwise>
                                                        ID #${category.parentId}
                                                    </c:otherwise>
                                                </c:choose>
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>

                                <!-- Product count -->
                                <td>
                                    <span class="badge bg-light text-secondary border fw-semibold">
                                        ${productCounts[category.categoryId]}
                                    </span>
                                </td>

                                <!-- Child category count -->
                                <td>
                                    <span class="badge bg-light text-secondary border fw-semibold">
                                        ${childCounts[category.categoryId]}
                                    </span>
                                </td>

                                <!-- Status -->
                                <td>
                                    <c:choose>
                                        <c:when test="${productCounts[category.categoryId] > 0
                                                        or childCounts[category.categoryId] > 0}">
                                            <span class="badge bg-success-subtle text-success border border-success-subtle rounded-pill px-3 py-1">
                                                <i class="bi bi-check-circle-fill me-1"></i>
                                                Đang sử dụng
                                            </span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle rounded-pill px-3 py-1">
                                                <i class="bi bi-folder2-open me-1"></i>
                                                Chưa sử dụng
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>

                                <!-- Actions -->
                                <td class="text-end">
                                    <div class="d-inline-flex gap-1">
                                        <a href="${pageContext.request.contextPath}/category?view=edit&id=${category.categoryId}"
                                           class="btn btn-sm btn-light text-primary border rounded-2 px-2 py-1"
                                           title="Chỉnh sửa">
                                            <i class="bi bi-pencil-square"></i>
                                        </a>

                                        <a href="${pageContext.request.contextPath}/category?view=delete&id=${category.categoryId}"
                                           class="btn btn-sm btn-light text-danger border rounded-2 px-2 py-1"
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
                            <td colspan="7" class="text-center py-5">
                                <div class="text-muted py-3">
                                    <i class="bi bi-inbox fs-1 d-block mb-2 text-secondary"></i>
                                    <p class="mb-0 fw-medium">
                                        <c:choose>
                                            <c:when test="${not empty keyword}">
                                                Không tìm thấy danh mục phù hợp.
                                            </c:when>
                                            <c:otherwise>
                                                Chưa có danh mục nào.
                                            </c:otherwise>
                                        </c:choose>
                                    </p>
                                    <small class="text-muted">
                                        <c:choose>
                                            <c:when test="${not empty keyword}">
                                                Thử tìm kiếm bằng từ khóa khác.
                                            </c:when>
                                            <c:otherwise>
                                                Nhấn "Thêm danh mục" để bắt đầu tạo dữ liệu.
                                            </c:otherwise>
                                        </c:choose>
                                    </small>
                                </div>
                            </td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </tbody>
        </table>
    </div>

    <!-- Pagination -->
    <div class="p-3 border-top d-flex flex-column flex-sm-row justify-content-between align-items-center gap-3 bg-white">
        <span class="text-muted fs-7">
            Hiển thị
            <strong>${startItem}</strong> - <strong>${endItem}</strong>
            trên tổng số <strong>${totalCategories}</strong> danh mục
        </span>

        <c:if test="${totalPages > 1}">
            <c:url var="prevUrl" value="/category">
                <c:param name="view" value="list"/>
                <c:param name="page" value="${currentPage - 1}"/>
                <c:if test="${not empty keyword}">
                    <c:param name="keyword" value="${keyword}"/>
                </c:if>
            </c:url>

            <c:url var="nextUrl" value="/category">
                <c:param name="view" value="list"/>
                <c:param name="page" value="${currentPage + 1}"/>
                <c:if test="${not empty keyword}">
                    <c:param name="keyword" value="${keyword}"/>
                </c:if>
            </c:url>

            <ul class="pagination pagination-sm mb-0">
                <li class="page-item ${currentPage == 1 ? 'disabled' : ''}">
                    <a class="page-link"
                       href="${currentPage > 1 ? prevUrl : '#'}">
                        Trước
                    </a>
                </li>

                <c:forEach begin="1" end="${totalPages}" var="p">
                    <c:url var="pageUrl" value="/category">
                        <c:param name="view" value="list"/>
                        <c:param name="page" value="${p}"/>
                        <c:if test="${not empty keyword}">
                            <c:param name="keyword" value="${keyword}"/>
                        </c:if>
                    </c:url>

                    <li class="page-item ${p == currentPage ? 'active' : ''}">
                        <a class="page-link" href="${pageUrl}">${p}</a>
                    </li>
                </c:forEach>

                <li class="page-item ${currentPage == totalPages ? 'disabled' : ''}">
                    <a class="page-link"
                       href="${currentPage < totalPages ? nextUrl : '#'}">
                        Sau
                    </a>
                </li>
            </ul>
        </c:if>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>
