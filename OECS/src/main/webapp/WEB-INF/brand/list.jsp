<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fn" uri="jakarta.tags.functions" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
    <div>
        <h3 class="fw-bold text-dark mb-1">Quản lý Thương Hiệu</h3>
        <p class="text-muted fs-7 mb-0">Hiển thị danh sách các nhãn hàng và đối tác kinh doanh trong hệ thống.</p>
    </div>

</div>


<c:if test="${not empty param.success}">
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        <c:choose>
            <c:when test="${param.success == 'create'}">
                Thêm thương hiệu thành công.
            </c:when>
            <c:when test="${param.success == 'edit'}">
                Cập nhật thương hiệu thành công.
            </c:when>
            <c:when test="${param.success == 'delete'}">
                Xóa thương hiệu thành công.
            </c:when>
        </c:choose>
        <button type="button" class="btn-close"
                data-bs-dismiss="alert" aria-label="Đóng"></button>
    </div>
</c:if>

<c:if test="${not empty param.error}">
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <c:choose>
            <c:when test="${param.error == 'hasProducts'}">
                Không thể xóa thương hiệu vì vẫn còn sản phẩm liên kết.
                Hãy chuyển các sản phẩm sang thương hiệu khác trước.
            </c:when>
            <c:when test="${param.error == 'notFound'}">
                Thương hiệu không tồn tại hoặc đã bị xóa.
            </c:when>
            <c:when test="${param.error == 'invalidId'}">
                ID thương hiệu không hợp lệ.
            </c:when>
            <c:when test="${param.error == 'delete'}">
                Không thể xóa thương hiệu.
            </c:when>
            <c:otherwise>
                Đã xảy ra lỗi khi xử lý thương hiệu. Vui lòng thử lại.
            </c:otherwise>
        </c:choose>
        <button type="button" class="btn-close"
                data-bs-dismiss="alert" aria-label="Đóng"></button>
    </div>
</c:if>


<div class="row g-3 mb-4">
    <div class="col-12 col-sm-6 col-lg-4">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between">
                <span class="text-muted fs-7 fw-medium">Tổng thương hiệu</span>
                <span class="badge bg-primary-subtle text-primary rounded-pill px-3 py-2"><i class="bi bi-tags-fill"></i></span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">${not empty brandList ? fn:length(brandList) : 0}</span>
                <span class="text-success fs-7 ms-2 fw-medium"><i class="bi bi-arrow-up-short"></i> Hoạt động tốt</span>
            </div>
        </div>
    </div>

    <div class="col-12 col-sm-6 col-lg-4">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between">
                <span class="text-muted fs-7 fw-medium">Trạng thái dữ liệu</span>
                <span class="badge bg-success-subtle text-success rounded-pill px-3 py-2"><i class="bi bi-check-circle-fill"></i></span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">100%</span>
                <span class="text-muted fs-7 ms-2">Đã đồng bộ</span>
            </div>
        </div>
    </div>

    <div class="col-12 col-sm-6 col-lg-4">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between">
                <span class="text-muted fs-7 fw-medium">Quyền hạn</span>
                <span class="badge bg-info-subtle text-info rounded-pill px-3 py-2"><i class="bi bi-shield-lock-fill"></i></span>
            </div>
            <div class="mt-2">
                <span class="fs-3 fw-bold text-dark">Staff</span>
            </div>
        </div>
    </div>
</div>

<div class="card-custom overflow-hidden">

    <div class="p-3 border-bottom d-flex flex-column flex-sm-row justify-content-between align-items-center gap-3 bg-white">
        <form action="${pageContext.request.contextPath}/brand"
              method="get"
              class="search-box w-100 w-sm-auto d-flex align-items-center gap-2"
              style="min-width: 300px;">

            <input type="hidden" name="view" value="list">

            <i class="bi bi-search"></i>

            <input type="text"
                   name="keyword"
                   class="form-control"
                   placeholder="Tìm kiếm thương hiệu..."
                   value="<c:out value='${keyword}'/>">

            <button type="submit"
                    class="btn btn-primary"
                    title="Tìm kiếm">
                Tìm
            </button>

            <c:if test="${not empty keyword}">
                <a href="${pageContext.request.contextPath}/brand?view=list"
                   class="btn btn-outline-secondary"
                   title="Xóa tìm kiếm">
                    <i class="bi bi-x-lg"></i>
                </a>
            </c:if>
        </form>
        <div class="d-flex align-items-center gap-2 w-100 w-sm-auto justify-content-end">
            <a class="btn btn-primary btn-md fw-semibold px-3 py-2 shadow-sm rounded-3 d-inline-flex align-items-center gap-2" 
               href="${pageContext.request.contextPath}/brand?view=create">
                <i class="bi bi-plus-lg fs-6"></i>
                <span>Thêm thương hiệu</span>
            </a>
        </div>
    </div>

    <div class="table-responsive">
        <table class="table table-custom align-middle">
            <thead>
                <tr>
                    <th style="width: 90px;">MÃ ID</th>
                    <th>THƯƠNG HIỆU</th>
                    <th>TRẠNG THÁI</th>
                    <th style="width: 140px;" class="text-end">THAO TÁC</th>
                </tr>
            </thead>
            <tbody>
                <c:choose>
                    <c:when test="${not empty brandList}">
                        <c:forEach items="${brandList}" var="brand">
                            <c:set var="brandSlug" value="${fn:toLowerCase(fn:replace(brand.brandName, ' ', ''))}" />
                            <tr>
                                <td>
                                    <span class="badge bg-light text-secondary border fw-semibold">#${brand.brandId}</span>
                                </td>
                                <td>
                                    <div class="d-flex align-items-center gap-3">
                                        <div class="brand-logo-box">
                                            <c:choose>
                                                <c:when test="${not empty brand.logoUrl}">
                                                    <img src="${brand.logoUrl}" 
                                                         alt="<c:out value='${brand.brandName}'/>" 
                                                         class="brand-logo-img"
                                                         onerror="this.onerror=null; this.src='https://cdn.simpleicons.org/${brandSlug}'; this.onerror=function(){ this.style.display='none'; this.nextElementSibling.style.display='flex'; };">
                                                    <div class="avatar-initial" style="display: none;">
                                                        ${brand.brandName.substring(0, 1).toUpperCase()}
                                                    </div>
                                                </c:when>
                                                <c:otherwise>
                                                    <img src="https://cdn.simpleicons.org/${brandSlug}" 
                                                         alt="<c:out value='${brand.brandName}'/>" 
                                                         class="brand-logo-img"
                                                         onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                                    <div class="avatar-initial" style="display: none;">
                                                        ${brand.brandName.substring(0, 1).toUpperCase()}
                                                    </div>
                                                </c:otherwise>
                                            </c:choose>
                                        </div>

                                        <div>
                                            <div class="fw-bold text-dark fs-6"><c:out value="${brand.brandName}"/></div>
                                            <div class="text-muted fs-7">Hệ thống phân phối chính hãng</div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <c:choose>
                                        <c:when test="${productCounts[brand.brandId] > 0}">
                                            <span class="badge bg-success-subtle text-success border border-success-subtle rounded-pill px-3 py-1">
                                                <i class="bi bi-check-circle-fill me-1"></i>
                                                Đang kinh doanh
                                            </span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle rounded-pill px-3 py-1">
                                                <i class="bi bi-box-seam me-1"></i>
                                                Chưa có sản phẩm
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-end">
                                    <div class="d-inline-flex gap-1">
                                        <a href="${pageContext.request.contextPath}/brand?view=edit&id=${brand.brandId}" 
                                           class="btn btn-sm btn-light text-primary border rounded-2 px-2 py-1" 
                                           title="Chỉnh sửa">
                                            <i class="bi bi-pencil-square"></i>
                                        </a>
                                        <a href="${pageContext.request.contextPath}/brand?view=delete&id=${brand.brandId}" 
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
                            <td colspan="5" class="text-center py-5">
                                <div class="text-muted py-3">
                                    <i class="bi bi-inbox fs-1 d-block mb-2 text-secondary"></i>
                                    <p class="mb-0 fw-medium">Chưa có thương hiệu nào</p>
                                    <small class="text-muted">Nhấn "Thêm thương hiệu" để bắt đầu nhập dữ liệu.</small>
                                </div>
                            </td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </tbody>
        </table>
    </div>


    <div class="p-3 border-top d-flex flex-column flex-sm-row justify-content-between align-items-center gap-3 bg-white">

        <span class="text-muted fs-7">
            Hiển thị
            <strong>${startItem}</strong> - <strong>${endItem}</strong>
            trên tổng số <strong>${totalBrands}</strong> thương hiệu
        </span>

        <c:if test="${totalPages > 1}">
            <c:url var="prevUrl" value="/brand">
                <c:param name="view" value="list"/>
                <c:param name="page" value="${currentPage - 1}"/>
                <c:if test="${not empty keyword}">
                    <c:param name="keyword" value="${keyword}"/>
                </c:if>
            </c:url>

            <c:url var="nextUrl" value="/brand">
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
                    <c:url var="pageUrl" value="/brand">
                        <c:param name="view" value="list"/>
                        <c:param name="page" value="${p}"/>
                        <c:if test="${not empty keyword}">
                            <c:param name="keyword" value="${keyword}"/>
                        </c:if>
                    </c:url>

                    <li class="page-item ${p == currentPage ? 'active' : ''}">
                        <a class="page-link" href="${pageUrl}">
                            ${p}
                        </a>
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