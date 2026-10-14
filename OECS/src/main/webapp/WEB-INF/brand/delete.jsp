<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="container py-4 py-md-5">
    <div class="row justify-content-center">
        <div class="col-md-7 col-lg-6">

            <div class="card shadow-sm border-0 rounded-4 overflow-hidden">
                <div class="bg-danger" style="height: 4px;"></div>

                <div class="card-body p-4 p-md-5 text-center">

                    <c:choose>
                        <c:when test="${not empty brand}">

                            <div class="bg-danger bg-opacity-10 text-danger rounded-circle d-inline-flex align-items-center justify-content-center mb-4"
                                 style="width: 80px; height: 80px;">
                                <i class="bi bi-trash3 fs-1"></i>
                            </div>

                            <h4 class="fw-bold text-dark mb-2">
                                Bạn chắc chắn chứ?
                            </h4>

                            <p class="text-muted mb-4">
                                Bạn đang chuẩn bị xóa thương hiệu
                                <strong class="text-dark fs-5">
                                    <c:out value="${brand.brandName}"/>
                                </strong>.
                                Vui lòng kiểm tra thông tin trước khi tiếp tục.
                            </p>

                            <c:if test="${not empty brand.logoUrl}">
                                <div class="mb-4">
                                    <div class="bg-light border rounded d-inline-flex align-items-center justify-content-center p-2"
                                         style="width: 80px; height: 80px;">
                                        <img src="<c:out value='${brand.logoUrl}'/>"
                                             alt="Logo thương hiệu"
                                             style="max-height: 100%; max-width: 100%; object-fit: contain;">
                                    </div>
                                </div>
                            </c:if>

                            <div class="bg-light border rounded-3 p-3 mb-4 text-start">
                                <div class="d-flex justify-content-between align-items-center gap-3 py-2">
                                    <span class="text-muted">Mã thương hiệu</span>
                                    <strong><c:out value="${brand.brandId}"/></strong>
                                </div>

                                <div class="d-flex justify-content-between align-items-center gap-3 py-2">
                                    <span class="text-muted">Số sản phẩm</span>
                                    <strong><c:out value="${productCount}"/></strong>
                                </div>
                            </div>

                            <c:choose>
                                <c:when test="${productCount > 0}">
                                    <div class="alert alert-danger text-start mb-4">
                                        <div class="fw-bold mb-2">
                                            <i class="bi bi-exclamation-triangle me-1"></i>
                                            Không thể xóa thương hiệu này
                                        </div>

                                        Thương hiệu đang có
                                        <strong><c:out value="${productCount}"/></strong>
                                        sản phẩm.

                                        <p class="mb-0 mt-2">
                                            Vui lòng xử lý các sản phẩm liên quan
                                            trước khi xóa thương hiệu.
                                        </p>
                                    </div>
                                </c:when>

                                <c:otherwise>
                                    <div class="alert alert-warning text-start mb-4">
                                        <i class="bi bi-exclamation-circle me-1"></i>
                                        Thương hiệu này chưa có sản phẩm.
                                        Hành động xóa không thể hoàn tác.
                                    </div>
                                </c:otherwise>
                            </c:choose>

                            <c:if test="${not empty param.error}">
                                <div class="alert alert-danger text-start mb-4"
                                     role="alert">
                                    <c:choose>
                                        <c:when test="${param.error == 'hasProducts'}">
                                            Không thể xóa thương hiệu vì vẫn còn sản phẩm.
                                            Vui lòng xử lý dữ liệu liên quan trước.
                                        </c:when>

                                        <c:when test="${param.error == 'delete'}">
                                            Không thể xóa thương hiệu.
                                            Vui lòng thử lại.
                                        </c:when>

                                        <c:when test="${param.error == 'server'}">
                                            Đã xảy ra lỗi hệ thống khi xóa thương hiệu.
                                            Vui lòng thử lại sau.
                                        </c:when>

                                        <c:otherwise>
                                            Đã xảy ra lỗi khi xử lý thương hiệu.
                                            Vui lòng thử lại.
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </c:if>

                            <div class="d-flex gap-2 justify-content-center flex-wrap mt-3">

                                <a href="${pageContext.request.contextPath}/brand?view=list"
                                   class="btn btn-light btn-lg border text-dark fs-6 px-4">
                                    Hủy bỏ
                                </a>

                                <c:if test="${productCount == 0}">
                                    <form action="${pageContext.request.contextPath}/brand"
                                          method="post">

                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="id" value="${brand.brandId}">

                                        <button type="submit"
                                                class="btn btn-danger btn-lg fs-6 px-4 shadow-sm">
                                            <i class="bi bi-trash3 me-1"></i>
                                            Đúng, xóa nó!
                                        </button>
                                    </form>
                                </c:if>

                            </div>

                        </c:when>

                        <c:otherwise>
                            <div class="py-4">
                                <i class="bi bi-exclamation-circle text-warning fs-1 mb-3 d-block"></i>

                                <h5 class="fw-bold">Lỗi truy xuất!</h5>

                                <p class="text-muted mb-4">
                                    Không tìm thấy thương hiệu cần xóa.
                                </p>

                                <a href="${pageContext.request.contextPath}/brand?view=list"
                                   class="btn btn-primary">
                                    Quay lại danh sách
                                </a>
                            </div>
                        </c:otherwise>
                    </c:choose>

                </div>
            </div>

        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>