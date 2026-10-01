<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="row justify-content-center">

    <div class="col-md-8 col-lg-6">

        <div class="mb-3">

            <a href="${pageContext.request.contextPath}/product?view=list"
               class="text-decoration-none text-muted fw-medium">

                <i class="bi bi-arrow-left me-1"></i>

                Quay lại danh sách

            </a>

        </div>


        <div class="card shadow-sm border-0 rounded-4">

            <div class="card-body p-4 p-md-5 text-center">

                <!-- Icon -->
                <div class="bg-danger bg-opacity-10 text-danger rounded-circle d-flex align-items-center justify-content-center mx-auto mb-4"
                     style="width:72px;height:72px;">

                    <i class="bi bi-trash3 fs-2"></i>

                </div>


                <h4 class="fw-bold text-dark mb-2">

                    Xóa Sản Phẩm

                </h4>


                <p class="text-muted mb-4">

                    Bạn có chắc chắn muốn xóa sản phẩm này không?

                </p>


                <!-- Product information -->
                <div class="bg-light rounded-3 p-3 mb-4 text-start">

                    <div class="d-flex justify-content-between mb-2">

                        <span class="text-muted">
                            Mã sản phẩm:
                        </span>

                        <strong>
                            #${product.productId}
                        </strong>

                    </div>


                    <div class="d-flex justify-content-between mb-2">

                        <span class="text-muted">
                            Tên sản phẩm:
                        </span>

                        <strong>
                            ${product.productName}
                        </strong>

                    </div>


                    <div class="d-flex justify-content-between mb-2">

                        <span class="text-muted">
                            Danh mục:
                        </span>

                        <strong>

                            ${product.category.categoryName}

                        </strong>

                    </div>


                    <div class="d-flex justify-content-between">

                        <span class="text-muted">
                            Thương hiệu:
                        </span>

                        <strong>

                            ${product.brand.brandName}

                        </strong>

                    </div>

                </div>


                <!-- Error -->
                <c:if test="${param.error == 'true'}">

                    <div class="alert alert-danger text-start">

                        <i class="bi bi-exclamation-triangle me-2"></i>

                        Không thể xóa sản phẩm.
                        Có thể sản phẩm đang được sử dụng ở bảng khác.

                    </div>

                </c:if>


                <!-- Form -->
                <form action="${pageContext.request.contextPath}/product"
                      method="POST">

                    <input type="hidden"
                           name="action"
                           value="delete">


                    <input type="hidden"
                           name="id"
                           value="${product.productId}">


                    <div class="d-flex justify-content-center gap-2 pt-3">

                        <a href="${pageContext.request.contextPath}/product?view=list"
                           class="btn btn-light btn-lg px-4 border">

                            Hủy

                        </a>


                        <button type="submit"
                                class="btn btn-danger btn-lg px-4">

                            <i class="bi bi-trash3 me-1"></i>

                            Xác Nhận Xóa

                        </button>

                    </div>

                </form>

            </div>

        </div>

    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp" %>