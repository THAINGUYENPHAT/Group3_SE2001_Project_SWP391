<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="d-flex justify-content-between align-items-center mb-4">
    <h2 class="fw-bold text-primary">Danh Sách Thương Hiệu</h2>
    <a class="btn btn-success" href="${pageContext.request.contextPath}/brand?view=create">
        <i class="bi bi-plus-circle me-1"></i> Thêm Thương Hiệu
    </a>
</div>

<div class="card shadow-sm">
    <div class="card-body p-0">
        <table class="table table-hover table-striped align-middle mb-0">
            <thead class="table-dark">
                <tr>
                    <th scope="col" style="width: 80px;" class="text-center">ID</th>
                    <th scope="col" style="width: 120px;" class="text-center">Logo</th>
                    <th scope="col">Tên Thương Hiệu</th>
                    <th scope="col" style="width: 180px;" class="text-center">Thao Tác</th>
                </tr>
            </thead>
            <tbody>
                <c:choose>
                    <%-- Kiểm tra nếu danh sách brandList không rỗng --%>
                    <c:when test="${not empty brandList}">
                        <c:forEach items="${brandList}" var="brand">
                            <tr>
                                <td class="text-center font-monospace">${brand.brandId}</td>
                                <td class="text-center">
                                    <c:choose>
                                        <c:when test="${not empty brand.logoUrl}">
                                            <img src="${brand.logoUrl}" alt="${brand.brandName}" class="img-thumbnail" style="max-height: 40px; max-width: 80px; object-fit: contain;">
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-secondary">No Logo</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="fw-bold">${brand.brandName}</td>
                                <td class="text-center">
                                    <a href="${pageContext.request.contextPath}/brand?view=edit&id=${brand.brandId}" class="btn btn-primary btn-sm me-1">
                                        <i class="bi bi-pencil-square"></i> Sửa
                                    </a>
                                    <a href="${pageContext.request.contextPath}/brand?view=delete&id=${brand.brandId}" class="btn btn-danger btn-sm">
                                        <i class="bi bi-trash"></i> Xóa
                                    </a>
                                </td>
                            </tr>
                        </c:forEach>
                    </c:when>
                    
                    <%-- Trường hợp danh sách rỗng --%>
                    <c:otherwise>
                        <tr>
                            <td colspan="4" class="text-center text-muted py-4">
                                <i class="bi bi-inbox fs-3 d-block mb-2"></i>
                                Chưa có thương hiệu nào trong hệ thống.
                            </td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </tbody>
        </table>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>