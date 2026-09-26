<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-md-6 col-lg-5">
        <div class="card border-danger shadow-sm">
            <div class="card-header bg-danger text-white">
                <h4 class="mb-0"><i class="bi bi-exclamation-triangle-fill me-2"></i>Xác Nhận Xóa Thương Hiệu</h4>
            </div>
            <div class="card-body">
                <c:choose>
                    <%-- Nếu tìm thấy đối tượng Brand trong request --%>
                    <c:when test="${not empty brand}">
                        <form action="${pageContext.request.contextPath}/brand" method="POST">
                            <%-- Hidden Fields truyền thông tin sang Servlet --%>
                            <input type="hidden" name="action" value="delete" />
                            <input type="hidden" name="id" value="${brand.brandId}" />

                            <div class="text-center my-3">
                                <%-- Hiển thị Logo nếu có --%>
                                <c:if test="${not empty brand.logoUrl}">
                                    <img src="${brand.logoUrl}" alt="${brand.brandName}" class="img-thumbnail mb-3" style="max-height: 80px; object-fit: contain;">
                                </c:if>
                                
                                <p class="fs-5">
                                    Bạn có chắc chắn muốn xóa thương hiệu <strong class="text-danger">${brand.brandName}</strong> (ID: <code>#${brand.brandId}</code>) không?
                                </p>
                                <p class="text-muted small">
                                    <i class="bi bi-info-circle me-1"></i>Hành động này không thể hoàn tác sau khi xác nhận!
                                </p>
                            </div>

                            <%-- Nút thao tác --%>
                            <div class="d-flex justify-content-between pt-3 border-top">
                                <a href="${pageContext.request.contextPath}/brand?view=list" class="btn btn-secondary">
                                    <i class="bi bi-arrow-left"></i> Hủy / Quay lại
                                </a>
                                <button type="submit" class="btn btn-danger">
                                    <i class="bi bi-trash"></i> Xác Nhận Xóa
                                </button>
                            </div>
                        </form>
                    </c:when>

                    <%-- Trường hợp không tìm thấy thương hiệu --%>
                    <c:otherwise>
                        <div class="alert alert-warning text-center my-3" role="alert">
                            <i class="bi bi-exclamation-circle fs-3 d-block mb-2"></i>
                            Không tìm thấy thương hiệu cần xóa!
                        </div>
                        <div class="text-center">
                            <a href="${pageContext.request.contextPath}/brand?view=list" class="btn btn-secondary">
                                <i class="bi bi-arrow-left"></i> Quay lại danh sách
                            </a>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>