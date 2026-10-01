<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fn" uri="jakarta.tags.functions" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
    <div>
        <h3 class="fw-bold text-dark mb-1">Quản lý Thương Hiệu</h3>
        <p class="text-muted fs-7 mb-0">Hiển thị danh sách các nhãn hàng và đối tác kinh doanh trong hệ thống.</p>
    </div>
    <a class="btn btn-primary btn-md fw-semibold px-3 py-2 shadow-sm rounded-3 d-inline-flex align-items-center gap-2" 
       href="${pageContext.request.contextPath}/brand?view=create">
        <i class="bi bi-plus-lg fs-6"></i>
        <span>Thêm thương hiệu</span>
    </a>
</div>

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
                <span class="fs-3 fw-bold text-dark">Administrator</span>
                <span class="text-muted fs-7 ms-2">Toàn quyền</span>
            </div>
        </div>
    </div>
</div>

<div class="card-custom overflow-hidden">
    
    <div class="p-3 border-bottom d-flex flex-column flex-sm-row justify-content-between align-items-center gap-3 bg-white">
        <div class="search-box w-100 w-sm-auto" style="min-width: 300px;">
            <i class="bi bi-search"></i>
            <input type="text" class="form-control" placeholder="Tìm kiếm thương hiệu...">
        </div>
        <div class="d-flex align-items-center gap-2 w-100 w-sm-auto justify-content-end">
            <button class="btn btn-outline-secondary btn-md rounded-2 d-flex align-items-center gap-2 fs-7 fw-medium">
                <i class="bi bi-funnel"></i> Bộ lọc
            </button>
            <button class="btn btn-outline-secondary btn-md rounded-2 d-flex align-items-center gap-2 fs-7 fw-medium">
                <i class="bi bi-download"></i> Xuất dữ liệu
            </button>
        </div>
    </div>

    <div class="table-responsive">
        <table class="table table-custom align-middle">
            <thead>
                <tr>
                    <th style="width: 40px;" class="text-center">
                        <input type="checkbox" class="form-check-input">
                    </th>
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
                                <td class="text-center">
                                    <input type="checkbox" class="form-check-input">
                                </td>
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
                                    <span class="badge bg-success-subtle text-success border border-success-subtle rounded-pill px-3 py-1">
                                        <i class="bi bi-record-fill me-1"></i>Đang hoạt động
                                    </span>
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
            Hiển thị <strong>${not empty brandList ? fn:length(brandList) : 0}</strong> trên tổng số <strong>${not empty brandList ? fn:length(brandList) : 0}</strong> thương hiệu
        </span>
        
        <ul class="pagination pagination-sm mb-0">
            <li class="page-item disabled"><a class="page-link" href="#">Trước</a></li>
            <li class="page-item active"><a class="page-link" href="#">1</a></li>
            <li class="page-item disabled"><a class="page-link" href="#">Sau</a></li>
        </ul>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>