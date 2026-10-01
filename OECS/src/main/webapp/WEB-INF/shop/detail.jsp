<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@include file="/WEB-INF/include/header.jsp"%>

<style>
    .detail-page {
        background: #fff;
        min-height: 100vh;
        padding: 30px 0 60px;
    }
    .gallery-placeholder {
        background: #f8f9fa;
        border-radius: 16px;
        min-height: 450px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 100px;
        color: #dee2e6;
    }
    .product-title {
        font-size: 28px;
        font-weight: 800;
        color: #142b4a;
        line-height: 1.3;
    }
    .product-price-display {
        font-size: 32px;
        font-weight: 800;
        color: #e53935;
    }
    .sku-radio {
        display: none;
    }
    .sku-label {
        display: block;
        padding: 12px 20px;
        border: 2px solid #e9edf3;
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.2s;
        font-weight: 600;
        text-align: center;
    }
    .sku-radio:checked + .sku-label {
        border-color: #0d6efd;
        background: #f0f6ff;
        color: #0d6efd;
    }
    .sku-radio:disabled + .sku-label {
        opacity: 0.5;
        cursor: not-allowed;
        background: #f8f9fa;
    }
    .specs-table th {
        background: #f8f9fa;
        width: 35%;
        color: #495057;
        font-weight: 600;
    }
</style>

<div class="detail-page">
    <div class="container">
        <!-- Breadcrumb -->
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="${pageContext.request.contextPath}/shop" class="text-decoration-none">Sản phẩm</a></li>
                <li class="breadcrumb-item"><a href="#" class="text-decoration-none">${product.category.categoryName}</a></li>
                <li class="breadcrumb-item active" aria-current="page">${product.productName}</li>
            </ol>
        </nav>

        <div class="row g-5 mb-5">
            <!-- Left: Hình ảnh -->
            <div class="col-lg-5">
                <div class="gallery-placeholder sticky-top" style="top: 20px;">
                    <i class="bi bi-display"></i>
                </div>
            </div>

            <!-- Right: Thông tin & Đặt hàng -->
            <div class="col-lg-7">
                <div class="badge bg-primary-subtle text-primary rounded-pill px-3 py-2 mb-3 fw-bold">
                    <i class="bi bi-patch-check-fill me-1"></i> Chính hãng ${product.brand.brandName}
                </div>

                <h1 class="product-title mb-3">${product.productName}</h1>
                <p class="text-muted fs-6 mb-4">${product.description}</p>

                <div class="p-4 bg-light rounded-4 mb-4">
                    <div class="product-price-display" id="displayPrice">
                        <c:choose>
                            <c:when test="${not empty skus}">
                                <fmt:formatNumber value="${skus[0].price}" type="number" maxFractionDigits="0"/> ₫
                            </c:when>
                            <c:otherwise>Liên hệ</c:otherwise>
                        </c:choose>
                    </div>
                    <div class="text-success fw-medium mt-1" id="displayStock">
                        <c:if test="${not empty skus}"><i class="bi bi-box-seam me-1"></i>Còn ${skus[0].stockQuantity} sản phẩm</c:if>
                    </div>
                </div>

                <!-- Lựa chọn phiên bản (SKU) -->
                <form action="${pageContext.request.contextPath}/cart" method="POST">
                    <input type="hidden" name="action" value="add">
                    <input type="hidden" name="productId" value="${product.productId}">

                    <h5 class="fw-bold mb-3">Chọn phiên bản:</h5>
                    <div class="row g-2 mb-4">
                        <c:forEach items="${skus}" var="sku" varStatus="loop">
                            <div class="col-6 col-md-4">
                                <input type="radio" name="skuId" id="sku_${sku.skuId}" value="${sku.skuId}" 
                                       class="sku-radio" 
                                       data-price="${sku.price}" 
                                       data-stock="${sku.stockQuantity}"
                                       ${loop.first ? 'checked' : ''}
                                       ${sku.stockQuantity == 0 ? 'disabled' : ''}>
                                <label class="sku-label" for="sku_${sku.skuId}">
                                    ${sku.skuCode}
                                </label>
                            </div>
                        </c:forEach>
                    </div>

                    <!-- Nút mua hàng -->
                    <div class="d-flex gap-3">
                        <button type="submit" class="btn btn-primary btn-lg flex-grow-1 fw-bold" id="btnAddToCart" ${empty skus ? 'disabled' : ''}>
                            <i class="bi bi-cart-plus me-2"></i>THÊM VÀO GIỎ
                        </button>
                        <button type="button" class="btn btn-outline-danger btn-lg px-4" title="Thêm vào yêu thích">
                            <i class="bi bi-heart"></i>
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Section: Thông số kỹ thuật -->
        <div class="row">
            <div class="col-lg-8 mx-auto">
                <h3 class="fw-bold mb-4 border-bottom pb-3">Thông số kỹ thuật</h3>
                <c:choose>
                    <c:when test="${not empty specs}">
                        <table class="table table-bordered specs-table align-middle">
                            <tbody>
                            <c:forEach items="${specs}" var="spec">
                                <tr>
                                    <th>${spec.attributeName}</th>
                                    <td>${spec.value}</td>
                                </tr>
                            </c:forEach>
                            </tbody>
                        </table>
                    </c:when>
                    <c:otherwise>
                        <p class="text-muted fst-italic">Thông số đang được cập nhật.</p>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>
</div>

<!-- Javascript xử lý đổi giá khi click SKU -->
<script>
    document.addEventListener("DOMContentLoaded", function () {
        const skuRadios = document.querySelectorAll('.sku-radio');
        const displayPrice = document.getElementById('displayPrice');
        const displayStock = document.getElementById('displayStock');
        const btnAddToCart = document.getElementById('btnAddToCart');

        skuRadios.forEach(radio => {
            radio.addEventListener('change', function () {
                // Lấy giá trị data
                const price = parseFloat(this.getAttribute('data-price'));
                const stock = parseInt(this.getAttribute('data-stock'));

                // Format tiền tệ VNĐ
                const formattedPrice = price.toLocaleString('vi-VN') + ' ₫';
                displayPrice.innerHTML = formattedPrice;

                // Cập nhật tồn kho
                if (stock > 0) {
                    displayStock.innerHTML = `<i class="bi bi-box-seam me-1"></i>Còn \${stock} sản phẩm`;
                    displayStock.className = "text-success fw-medium mt-1";
                    btnAddToCart.disabled = false;
                } else {
                    displayStock.innerHTML = `<i class="bi bi-x-circle me-1"></i>Hết hàng`;
                    displayStock.className = "text-danger fw-medium mt-1";
                    btnAddToCart.disabled = true;
                }
            });
        });
    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>