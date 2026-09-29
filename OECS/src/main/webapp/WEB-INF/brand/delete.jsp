<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-md-6 col-lg-5">
        <div class="card shadow-sm border-0 rounded-4 overflow-hidden">
            <!-- Dải màu đỏ cảnh báo trên cùng của Card -->
            <div class="bg-danger" style="height: 4px;"></div>
            
            <div class="card-body p-4 p-md-5 text-center">
                <c:choose>
                    <c:when test="${not empty brand}">
                        <form action="${pageContext.request.contextPath}/brand" method="POST">
                            <input type="hidden" name="action" value="delete" />
                            <input type="hidden" name="id" value="${brand.brandId}" />

                            <div class="bg-danger bg-opacity-10 text-danger rounded-circle d-inline-flex align-items-center justify-content-center mb-4" style="width: 80px; height: 80px;">
                                <i class="bi bi-trash3 fs-1"></i>
                            </div>
                            
                            <h4 class="fw-bold text-dark mb-2">Bạn chắc chắn chứ?</h4>
                            <p class="text-muted mb-4">
                                Bạn đang chuẩn bị xóa thương hiệu <strong class="text-dark fs-5">${brand.brandName}</strong>. Hành động này không thể hoàn tác.
                            </p>

                            <c:if test="${not empty brand.logoUrl}">
                                <div class="mb-4">
                                    <div class="bg-light border rounded d-inline-flex align-items-center justify-content-center p-2" style="width: 80px; height: 80px;">
                                        <img src="${brand.logoUrl}" alt="${brand.brandName}" style="max-height: 100%; max-width: 100%; object-fit: contain;">
                                    </div>
                                </div>
                            </c:if>

                            <div class="d-flex gap-2 justify-content-center mt-2">
                                <a href="${pageContext.request.contextPath}/brand?view=list" class="btn btn-light btn-lg border text-dark fs-6 px-4">
                                    Hủy bỏ
                                </a>
                                <button type="submit" class="btn btn-danger btn-lg fs-6 px-4 shadow-sm">
                                    Đúng, xóa nó!
                                </button>
                            </div>
                        </form>
                    </c:when>

                    <c:otherwise>
                        <div class="py-4">
                            <i class="bi bi-exclamation-circle text-warning fs-1 mb-3 d-block"></i>
                            <h5 class="fw-bold">Lỗi truy xuất!</h5>
                            <p class="text-muted mb-4">Không tìm thấy thương hiệu cần xóa.</p>
                            <a href="${pageContext.request.contextPath}/brand?view=list" class="btn btn-primary">Quay lại danh sách</a>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>