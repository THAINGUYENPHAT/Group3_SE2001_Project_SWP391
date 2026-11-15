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
        border: 1px solid #e9edf3;
        overflow: hidden;
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
    .thumb-scroll::-webkit-scrollbar {
        height: 6px;
    }
    .thumb-scroll::-webkit-scrollbar-thumb {
        background-color: #dee2e6;
        border-radius: 10px;
    }

    .description-container {
        position: relative;
    }

    .product-description-content {
        line-height: 1.6;
        font-size: 16px;
        color: #333;
        overflow: hidden;
        transition: max-height 0.3s ease-out;
    }

    .product-description-content.collapsed {
        max-height: 250px; 
    }

    .description-overlay {
        position: absolute;
        bottom: 0;
        left: 0;
        width: 100%;
        height: 100px; 
        background: linear-gradient(to bottom, rgba(255, 255, 255, 0), rgba(255, 255, 255, 1));
        display: flex;
        align-items: flex-end;
        justify-content: center;
        padding-bottom: 10px;
        transition: opacity 0.3s ease-out;
        pointer-events: none; 
    }

    .description-overlay.hidden {
        opacity: 0;
        pointer-events: none;
    }

    .toggle-description-btn {
        position: relative;
        z-index: 10; 
        pointer-events: auto; 
        margin-top: 15px;
    }

</style>

<div class="detail-page">
    <div class="container">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="${pageContext.request.contextPath}/shop" class="text-decoration-none">Sản phẩm</a></li>
                <li class="breadcrumb-item">
                    <a href="${pageContext.request.contextPath}/shop?categoryId=${product.category.categoryId}" class="text-decoration-none">
                        ${product.category.categoryName}
                    </a>
                </li>
                <li class="breadcrumb-item active" aria-current="page">${product.productName}</li>
            </ol>
        </nav>

        <div class="row g-5 mb-5">
            <div class="col-lg-5">
                <div class="sticky-top" style="top: 20px;">
                    <div class="gallery-placeholder mb-3">
                        <c:choose>
                            <c:when test="${not empty product.imageUrl}">
                                <img id="mainProductImage" src="${pageContext.request.contextPath}/${product.imageUrl}" alt="${product.productName}" class="img-fluid w-100 h-100" style="object-fit: cover; border-radius: 16px;">
                            </c:when>
                            <c:otherwise>
                                <i class="bi bi-image text-muted"></i>
                            </c:otherwise>
                        </c:choose>
                    </div>

                    <c:if test="${not empty product.imageUrl}">
                        <div class="d-flex gap-2 thumb-scroll" style="overflow-x: auto; padding-bottom: 8px;">

                            <img src="${pageContext.request.contextPath}/${product.imageUrl}" 
                                 class="img-thumbnail flex-shrink-0 gallery-thumb" 
                                 style="width: 80px; height: 80px; object-fit: cover; cursor: pointer; border: 2px solid #0d6efd;"
                                 onclick="changeMainImage(this)"
                                 alt="Ảnh chính">

                            <c:if test="${not empty product.galleryImages}">
                                <c:forEach items="${product.galleryImages}" var="img">
                                    <img src="${pageContext.request.contextPath}/${img.imageUrl}" 
                                         class="img-thumbnail flex-shrink-0 gallery-thumb opacity-50" 
                                         style="width: 80px; height: 80px; object-fit: cover; cursor: pointer; transition: 0.2s;"
                                         onclick="changeMainImage(this)"
                                         onmouseover="this.classList.remove('opacity-50')"
                                         onmouseout="if (document.getElementById('mainProductImage').src !== this.src)
                                                     this.classList.add('opacity-50')"
                                         alt="Ảnh phụ">
                                </c:forEach>
                            </c:if>

                        </div>
                    </c:if>
                </div>
            </div>

            <div class="col-lg-7">
                <div class="badge bg-primary-subtle text-primary rounded-pill px-3 py-2 mb-3 fw-bold">
                    <i class="bi bi-patch-check-fill me-1"></i> Chính hãng ${product.brand.brandName}
                </div>

                <h1 class="product-title mb-4">${product.productName}</h1>

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

                    <div class="d-flex gap-3">
                        <button type="submit" class="btn btn-primary btn-lg flex-grow-1 fw-bold" id="btnAddToCart" ${empty skus ? 'disabled' : ''}>
                            <i class="bi bi-cart-plus me-2"></i>THÊM VÀO GIỎ
                        </button>
                    </div>
                </form>
            </div>
        </div>

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

        <div class="row mt-5">
            <div class="col-lg-8 mx-auto">
                <h3 class="fw-bold mb-4 border-bottom pb-3">Tổng quan sản phẩm</h3>

                <div class="description-container" id="descContainer">
                    <div class="product-description-content collapsed" id="descContent">
                        ${product.description}
                    </div>

                    <div class="description-overlay" id="descOverlay"></div>
                </div>

                <div class="text-center mt-3">
                    <button class="btn btn-outline-primary toggle-description-btn" id="btnToggleDesc" style="display: none;">
                        Xem thêm <i class="bi bi-chevron-down ms-1"></i>
                    </button>
                </div>
            </div>
        </div>

        <div class="row mt-5">
            <div class="col-lg-8 mx-auto">
                <div class="border-bottom pb-3 mb-4">
                    <h3 class="fw-bold mb-3">Đánh giá &amp; bình luận</h3>

                    <div class="d-flex flex-wrap gap-4 mb-3">

                        <div>
                            <strong class="fs-4 text-primary">
                                <fmt:formatNumber value="${purchaseCount}" type="number"/>
                            </strong>
                            <div class="text-muted small">Lượt mua</div>
                        </div>

                        <div>
                            <strong class="fs-4 text-primary">
                                <fmt:formatNumber value="${totalReviews}" type="number"/>
                            </strong>
                            <div class="text-muted small">Đánh giá</div>
                        </div>

                        <div>
                            <strong class="fs-4 text-warning">
                                <c:choose>
                                    <c:when test="${totalReviews > 0}">
                                        <fmt:formatNumber value="${averageRating}"
                                                          minFractionDigits="1"
                                                          maxFractionDigits="1"/>/5
                                    </c:when>
                                    <c:otherwise>0.0/5</c:otherwise>
                                </c:choose>
                            </strong>
                            <div class="text-muted small">Điểm trung bình</div>
                        </div>

                    </div>

                    <c:if test="${totalReviews == 0}">
                        <p class="text-muted mb-0">
                            Sản phẩm chưa có đánh giá.
                        </p>
                    </c:if>
                </div>
            </div>

            <c:choose>
                <c:when test="${not empty reviews}">
                    <c:forEach items="${reviews}" var="review">
                        <div class="border rounded-3 p-4 mb-3">
                            <div class="d-flex justify-content-between
                                 align-items-start flex-wrap gap-2 mb-3">
                                <div>
                                    <div class="fw-bold">Khách hàng</div>

                                    <div class="text-warning">
                                        <c:forEach begin="1" end="5" var="star">
                                            <c:choose>
                                                <c:when test="${star <= review.rating}">
                                                    <i class="bi bi-star-fill"></i>
                                                </c:when>
                                                <c:otherwise>
                                                    <i class="bi bi-star"></i>
                                                </c:otherwise>
                                            </c:choose>
                                        </c:forEach>
                                        <span class="text-muted ms-1">
                                            (${review.rating}/5)
                                        </span>
                                    </div>
                                </div>

                                <small class="text-muted">
                                    <fmt:formatDate value="${review.createdAt}"
                                                    pattern="dd/MM/yyyy HH:mm"/>
                                </small>
                            </div>

                            <p class="mb-3" style="white-space: pre-line;"><c:out value="${review.comment}"/></p>

                            <c:if test="${not empty review.images}">
                                <div class="d-flex flex-wrap gap-2">
                                    <c:forEach items="${review.images}" var="image">
                                        <img src="${pageContext.request.contextPath}${image}"
                                             alt="Ảnh đánh giá sản phẩm"
                                             loading="lazy"
                                             style="width: 90px; height: 90px;
                                             object-fit: cover;
                                             border-radius: 8px;
                                             border: 1px solid #dee2e6;">
                                    </c:forEach>
                                </div>
                            </c:if>
                            <c:if test="${sessionScope.loggedInUser.customer
                                          and sessionScope.loggedInUser.userId ne review.userId}">

                                  <form action="${pageContext.request.contextPath}/review/report"
                                        method="POST"
                                        class="mt-3">

                                      <input type="hidden"
                                             name="csrfToken"
                                             value="${sessionScope.reviewCsrfToken}">

                                      <input type="hidden"
                                             name="reviewId"
                                             value="${review.reviewId}">

                                      <input type="hidden"
                                             name="productId"
                                             value="${product.productId}">

                                      <div class="input-group">
                                          <input type="text"
                                                 name="reason"
                                                 class="form-control"
                                                 maxlength="500"
                                                 required
                                                 placeholder="Nhập lý do báo cáo...">

                                          <button type="submit"
                                                  class="btn btn-outline-danger">
                                              <i class="bi bi-flag me-1"></i>
                                              Báo cáo
                                          </button>
                                      </div>
                                  </form>
                            </c:if>
                        </div>
                    </c:forEach>
                </c:when>

                <c:otherwise>
                    <div class="text-center text-muted py-4">
                        <i class="bi bi-chat-square-text fs-1"></i>
                        <p class="mt-2 mb-0">
                            Chưa có bình luận nào cho sản phẩm này.
                        </p>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>
    </div>
    <c:if test="${param.report eq 'SUCCESS'}">
        <div class="alert alert-success">
            Báo cáo của bạn đã được gửi để nhân viên xem xét.
        </div>
    </c:if>
                            
    <c:if test="${param.report eq 'RATE_LIMIT'}">
        <div class="alert alert-warning">
            Bạn đã gửi quá 5 báo cáo trong 24 giờ.
            Vui lòng thử lại sau.
        </div>
    </c:if>

    <c:if test="${param.report eq 'NOT_FOUND'}">
        <div class="alert alert-warning">
            Đánh giá không tồn tại hoặc đã bị ẩn.
        </div>
    </c:if>

    <c:if test="${param.report eq 'FAILED'}">
        <div class="alert alert-danger">
            Không thể gửi báo cáo. Vui lòng thử lại.
        </div>
    </c:if>

    <c:if test="${param.report eq 'DUPLICATE'}">
        <div class="alert alert-warning">
            Bạn đã có báo cáo đang chờ xử lý cho đánh giá này.
        </div>
    </c:if>

    <c:if test="${param.report eq 'OWN_REVIEW'}">
        <div class="alert alert-warning">
            Bạn không thể báo cáo đánh giá của chính mình.
        </div>
    </c:if>

    <c:if test="${param.report eq 'INVALID'}">
        <div class="alert alert-danger">
            Vui lòng nhập lý do báo cáo hợp lệ.
        </div>
    </c:if>
</div>
</div>

<script>
    function changeMainImage(thumbElement) {
        document.getElementById('mainProductImage').src = thumbElement.src;

        let allThumbs = document.querySelectorAll('.gallery-thumb');
        allThumbs.forEach(t => {
            t.style.border = '1px solid #dee2e6';
            t.classList.add('opacity-50');
        });

        thumbElement.style.border = '2px solid #0d6efd';
        thumbElement.classList.remove('opacity-50');
    }

    document.addEventListener("DOMContentLoaded", function () {
        const skuRadios = document.querySelectorAll('.sku-radio');
        const displayPrice = document.getElementById('displayPrice');
        const displayStock = document.getElementById('displayStock');
        const btnAddToCart = document.getElementById('btnAddToCart');

        skuRadios.forEach(radio => {
            radio.addEventListener('change', function () {
                const price = parseFloat(this.getAttribute('data-price'));
                const stock = parseInt(this.getAttribute('data-stock'));

                const formattedPrice = price.toLocaleString('vi-VN') + ' ₫';
                displayPrice.innerHTML = formattedPrice;

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

        const descContent = document.getElementById('descContent');
        const descOverlay = document.getElementById('descOverlay');
        const btnToggleDesc = document.getElementById('btnToggleDesc');

        if (descContent.scrollHeight > descContent.clientHeight) {
            btnToggleDesc.style.display = 'inline-block'; 
        } else {
            descOverlay.classList.add('hidden'); 
        }

        btnToggleDesc.addEventListener('click', function () {
            if (descContent.classList.contains('collapsed')) {
                descContent.classList.remove('collapsed');
                descContent.style.maxHeight = descContent.scrollHeight + "px";
                descOverlay.classList.add('hidden');
                btnToggleDesc.innerHTML = 'Ẩn bớt <i class="bi bi-chevron-up ms-1"></i>';
            } else {
                descContent.classList.add('collapsed');
                descContent.style.maxHeight = "250px"; 
                descOverlay.classList.remove('hidden');
                btnToggleDesc.innerHTML = 'Xem thêm <i class="bi bi-chevron-down ms-1"></i>';

                document.getElementById('descContainer').scrollIntoView({behavior: 'smooth', block: 'start'});
            }
        });
    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>