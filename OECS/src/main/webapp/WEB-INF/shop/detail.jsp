
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>
<%@include file="/WEB-INF/include/header.jsp"%>

<style>
    .detail-page {
        background: #fff;
        min-height: 100vh;
        padding: 30px 0 60px;
    }

    .detail-breadcrumb {
        font-size: 14px;
    }

    .detail-breadcrumb a {
        color: #667085;
        text-decoration: none;
    }

    .detail-breadcrumb a:hover {
        color: #0d6efd;
    }

    .detail-gallery {
        position: sticky;
        top: 100px;
    }

    .gallery-main {
        width: 100%;
        aspect-ratio: 1 / 1;
        background: #f8fafc;
        border: 1px solid #edf0f4;
        border-radius: 18px;
        display: flex;
        align-items: center;
        justify-content: center;
        overflow: hidden;
        position: relative;
    }

    .gallery-main img {
        width: 100%;
        height: 100%;
        object-fit: contain;
        padding: 16px;
    }

    .gallery-placeholder-icon {
        font-size: 90px;
        color: #cbd5e1;
    }

    .gallery-count {
        position: absolute;
        bottom: 14px;
        right: 14px;
        background: rgba(15, 23, 42, 0.75);
        color: #fff;
        border-radius: 30px;
        font-size: 12px;
        padding: 5px 12px;
    }

    .gallery-thumbnails {
        display: flex;
        gap: 10px;
        overflow-x: auto;
        padding: 12px 2px;
        scrollbar-width: thin;
    }

    .gallery-thumb-button {
        width: 78px;
        height: 78px;
        flex-shrink: 0;
        border: 2px solid #e5e7eb;
        background: #fff;
        border-radius: 12px;
        padding: 5px;
        cursor: pointer;
        transition: border-color .2s, box-shadow .2s;
    }

    .gallery-thumb-button:hover {
        border-color: #93c5fd;
    }

    .gallery-thumb-button.active {
        border-color: #0d6efd;
        box-shadow: 0 0 0 2px rgba(13, 110, 253, .08);
    }

    .gallery-thumb-button img {
        width: 100%;
        height: 100%;
        object-fit: contain;
    }

    .product-title {
        font-size: clamp(24px, 3vw, 32px);
        font-weight: 800;
        line-height: 1.3;
        color: #142b4a;
    }

    .product-subtitle {
        color: #667085;
        font-size: 14px;
    }

    .product-price-panel {
        background: #f8fafc;
        border: 1px solid #e8edf4;
        border-radius: 16px;
        padding: 24px;
    }

    .product-price-display {
        font-size: clamp(28px, 3.5vw, 38px);
        font-weight: 800;
        color: #e53935;
        line-height: 1.2;
    }

    .product-original-price {
        font-size: 17px;
        color: #94a3b8;
        text-decoration: line-through;
    }

    .product-discount {
        color: #dc2626;
        background: #fee2e2;
        border-radius: 6px;
        padding: 4px 8px;
        font-size: 12px;
        font-weight: 700;
    }

    .sku-radio {
        position: absolute;
        opacity: 0;
        width: 1px;
        height: 1px;
    }

    .sku-label {
        display: block;
        width: 100%;
        min-height: 88px;
        padding: 13px;
        border: 2px solid #e5e7eb;
        border-radius: 12px;
        cursor: pointer;
        background: #fff;
        transition: border-color .2s, background .2s;
    }

    .sku-label:hover {
        border-color: #93c5fd;
    }

    .sku-radio:checked + .sku-label {
        border-color: #0d6efd;
        background: #eff6ff;
    }

    .sku-radio:focus-visible + .sku-label {
        outline: 3px solid rgba(13, 110, 253, .35);
        outline-offset: 2px;
    }

    .sku-radio:disabled + .sku-label {
        opacity: .5;
        background: #f8fafc;
        cursor: not-allowed;
    }

    .sku-label-name {
        display: block;
        font-size: 14px;
        font-weight: 700;
        color: #1e293b;
        margin-bottom: 5px;
        overflow-wrap: anywhere;
    }

    .sku-label-price {
        display: block;
        font-size: 13px;
        color: #dc2626;
        font-weight: 600;
    }

    .sku-label-stock {
        display: block;
        font-size: 11px;
        color: #64748b;
        margin-top: 4px;
    }

    .variant-selector[hidden],
    #skuFallback[hidden] {
        display: none !important;
    }

    .variant-selector {
        display: flex;
        flex-direction: column;
        gap: 18px;
    }

    .variant-group {
        display: grid;
        grid-template-columns: 126px minmax(0, 1fr);
        gap: 12px;
        align-items: start;
    }

    .variant-group-title {
        margin: 10px 0 0;
        color: #475569;
        font-weight: 650;
        font-size: 14px;
    }

    .variant-options {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
    }

    .variant-option {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        min-height: 49px;
        padding: 10px 15px;
        border: 1.5px solid #d1d5db;
        background: #fff;
        color: #172033;
        border-radius: 10px;
        font-size: 14px;
        font-weight: 650;
        line-height: 1.35;
        transition: background .18s ease, border-color .18s ease;
    }

    .variant-option:hover:not(:disabled) {
        border-color: #93c5fd;
        background: #f8fbff;
    }

    .variant-option[aria-pressed="true"] {
        border-color: #2563eb;
        background: #eff6ff;
        color: #1d4ed8;
        box-shadow: inset 0 0 0 1px #2563eb;
    }

    .variant-option:focus-visible {
        outline: 3px solid #93c5fd;
        outline-offset: 3px;
    }

    .variant-option:disabled {
        opacity: .45;
        cursor: not-allowed;
        text-decoration: line-through;
    }

    .variant-color-thumb {
        display: block;
        flex: 0 0 auto;
        width: 34px;
        height: 34px;
        object-fit: contain;
        border-radius: 6px;
        background: #fff;
    }

    .variant-color-dot {
        display: inline-block;
        flex: 0 0 auto;
        width: 18px;
        height: 18px;
        border-radius: 50%;
        border: 1px solid rgba(15, 23, 42, .18);
    }

    .variant-selection-summary {
        color: #64748b;
        font-size: 13px;
        line-height: 1.6;
    }

    .variant-selection-summary strong {
        color: #1e293b;
        font-weight: 650;
    }

    .variant-change-notice {
        margin: -8px 0 16px;
        color: #475569;
        font-size: 13px;
    }

    @media (max-width: 575.98px) {
        .variant-group {
            grid-template-columns: 1fr;
            gap: 8px;
        }

        .variant-group-title {
            margin-top: 0;
        }

        .variant-option {
            min-height: 44px;
            padding: 9px 12px;
        }
    }

    .purchase-button {
        min-height: 54px;
        border-radius: 12px;
        font-size: 16px;
        font-weight: 700;
    }

    .detail-section-title {
        font-size: 24px;
        font-weight: 800;
        color: #142b4a;
        padding-bottom: 16px;
        border-bottom: 1px solid #edf0f4;
        margin-bottom: 24px;
    }

    .specs-table th {
        width: 38%;
        background: #f8fafc;
        color: #475569;
        font-weight: 600;
    }

    .specs-table td {
        color: #1e293b;
        overflow-wrap: anywhere;
    }

    .specs-table th,
    .specs-table td {
        padding: 14px 16px;
    }

    .description-container {
        position: relative;
    }

    .product-description-content {
        white-space: normal;
        line-height: 1.8;
        color: #334155;
        overflow: hidden;
    }

    .product-description-content.collapsed {
        max-height: 250px;
    }

    .description-overlay {
        position: absolute;
        bottom: 0;
        left: 0;
        right: 0;
        height: 100px;
        background: linear-gradient(
            to bottom,
            rgba(255, 255, 255, 0),
            rgba(255, 255, 255, 1)
            );
        pointer-events: none;
    }

    .description-overlay.hidden {
        display: none;
    }

    .review-card {
        border: 1px solid #e9edf3;
        border-radius: 14px;
        padding: 22px;
        margin-bottom: 16px;
    }

    .review-image {
        width: 90px;
        height: 90px;
        object-fit: cover;
        border-radius: 8px;
        border: 1px solid #dee2e6;
    }

    @media (max-width: 991.98px) {
        .detail-gallery {
            position: static;
        }
    }

    @media (max-width: 575.98px) {
        .sku-label {
            min-height: 78px;
            padding: 10px;
        }

        .gallery-thumb-button {
            width: 65px;
            height: 65px;
        }

        .product-price-panel {
            padding: 18px;
        }
    }

    /* Gallery navigation and lightbox */
    #mainProductImage {
        cursor: zoom-in;
    }

    #mainProductImage:focus-visible,
    .gallery-nav:focus-visible,
    .lightbox-close:focus-visible {
        outline: 3px solid #93c5fd;
        outline-offset: -3px;
    }

    .gallery-nav {
        position: absolute;
        top: 50%;
        transform: translateY(-50%);
        width: 42px;
        height: 42px;
        border: 1px solid #e2e8f0;
        border-radius: 50%;
        background: rgba(255, 255, 255, .95);
        color: #334155;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 20px;
        cursor: pointer;
        z-index: 5;
        box-shadow: 0 2px 10px rgba(0, 0, 0, .1);
    }

    .gallery-nav:hover {
        background: #0d6efd;
        color: #fff;
    }

    .gallery-nav[hidden] {
        display: none !important;
    }

    .gallery-prev {
        left: 10px;
    }
    .gallery-next {
        right: 10px;
    }

    .product-lightbox {
        width: min(94vw, 1100px);
        max-width: none;
        max-height: 95vh;
        margin: auto;
        padding: 16px;
        border: none;
        border-radius: 18px;
        background: #fff;
        color: #334155;
        box-shadow: 0 20px 70px rgba(0, 0, 0, .3);
    }

    .product-lightbox::backdrop {
        background: rgba(0, 0, 0, .85);
    }

    .lightbox-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding-bottom: 12px;
    }

    .lightbox-close {
        width: 38px;
        height: 38px;
        border: none;
        border-radius: 50%;
        background: #f1f5f9;
        color: #334155;
        font-size: 20px;
        cursor: pointer;
    }

    .lightbox-close:hover {
        background: #fee2e2;
        color: #dc2626;
    }

    .lightbox-stage {
        position: relative;
        width: 100%;
        height: min(75vh, 750px);
    }

    .lightbox-stage img {
        width: 100%;
        height: 100%;
        object-fit: contain;
    }

    .lightbox-stage .gallery-nav {
        width: 48px;
        height: 48px;
    }

    .lightbox-counter {
        text-align: center;
        font-size: 14px;
        font-weight: 600;
        color: #64748b;
        padding-top: 12px;
    }

    @media (max-width: 575.98px) {
        .gallery-nav,
        .lightbox-stage .gallery-nav {
            width: 34px;
            height: 34px;
            font-size: 16px;
        }
        .product-lightbox {
            padding: 10px;
        }
        .lightbox-stage {
            height: 65vh;
        }
    }
</style>

<div class="detail-page">
    <div class="container">



        <nav aria-label="breadcrumb"
             class="detail-breadcrumb mb-4">

            <ol class="breadcrumb">

                <li class="breadcrumb-item">
                    <a href="${pageContext.request.contextPath}/shop">
                        Sản phẩm
                    </a>
                </li>

                <li class="breadcrumb-item">
                    <a href="${pageContext.request.contextPath}/shop?categoryId=${product.categoryId}">
                        <c:out value="${product.category.categoryName}"/>
                    </a>
                </li>

                <li class="breadcrumb-item active"
                    aria-current="page">

                    <c:out value="${product.productName}"/>
                </li>

            </ol>
        </nav>


        <div class="row g-4 g-lg-5 mb-5">


            <div class="col-lg-5">

                <div class="detail-gallery">

                    <div class="gallery-main mb-2">

                        <img id="mainProductImage"
                             alt="Ảnh sản phẩm"
                             role="button"
                             tabindex="0"
                             aria-label="Phóng to ảnh sản phẩm"
                             aria-haspopup="dialog"
                             style="display:none;">

                        <i id="galleryPlaceholder"
                           class="bi bi-image gallery-placeholder-icon"></i>

                        <button type="button" id="galleryPrev"
                                class="gallery-nav gallery-prev"
                                aria-label="Ảnh trước" hidden>
                            <i class="bi bi-chevron-left" aria-hidden="true"></i>
                        </button>

                        <button type="button" id="galleryNext"
                                class="gallery-nav gallery-next"
                                aria-label="Ảnh tiếp theo" hidden>
                            <i class="bi bi-chevron-right" aria-hidden="true"></i>
                        </button>

                        <span id="galleryCount"
                              class="gallery-count"
                              style="display:none;"></span>

                    </div>

                    <div id="galleryThumbnails"
                         class="gallery-thumbnails"
                         aria-label="Danh sách ảnh sản phẩm">
                    </div>

                    <p id="gallerySourceLabel"
                       class="small text-muted mb-0">
                    </p>

                </div>

            </div>


            <div class="col-lg-7">

                <div class="mb-3">

                    <span class="badge bg-primary-subtle
                          text-primary rounded-pill
                          px-3 py-2">

                        <i class="bi bi-patch-check-fill me-1"></i>
                        <c:out value="${product.brand.brandName}"/>
                    </span>

                    <c:if test="${not empty product.modelCode}">

                        <span class="badge bg-light text-secondary
                              border rounded-pill px-3 py-2 ms-1">

                            Model:
                            <c:out value="${product.modelCode}"/>
                        </span>

                    </c:if>
                </div>

                <h1 class="product-title mb-3">
                    <c:out value="${product.productName}"/>
                </h1>

                <div class="d-flex flex-wrap align-items-center
                     gap-3 product-subtitle mb-4">

                    <span>
                        <i class="bi bi-tag me-1"></i>
                        <c:out value="${product.category.categoryName}"/>
                    </span>

                    <span>
                        <i class="bi bi-star-fill text-warning me-1"></i>

                        <c:choose>
                            <c:when test="${totalReviews > 0}">

                                <strong>
                                    <fmt:formatNumber
                                        value="${averageRating}"
                                        minFractionDigits="1"
                                        maxFractionDigits="1"/>
                                </strong>

                                (${totalReviews} đánh giá)

                            </c:when>

                            <c:otherwise>
                                Chưa có đánh giá
                            </c:otherwise>
                        </c:choose>
                    </span>

                    <span>
                        <i class="bi bi-bag-check me-1"></i>
                        <fmt:formatNumber value="${purchaseCount}"
                                          pattern="#,##0"/>
                        lượt mua
                    </span>

                </div>


                <div class="product-price-panel mb-4">

                    <div class="small text-muted mb-2">
                        Giá bán
                    </div>

                    <div id="displayPrice"
                         class="product-price-display">

                        <c:choose>
                            <c:when test="${not empty selectedSku and not selectedSku.active}">
                                Ngừng kinh doanh
                            </c:when>

                            <c:when test="${not empty selectedSku}">

                                <fmt:formatNumber
                                    value="${selectedSku.price}"
                                    pattern="#,##0"/>
                                ₫

                            </c:when>

                            <c:otherwise>
                                Liên hệ
                            </c:otherwise>
                        </c:choose>

                    </div>

                    <div class="d-flex flex-wrap
                         align-items-center gap-2 mt-2">

                        <span id="displayOriginalPrice"
                              class="product-original-price"
                              style="${not empty selectedSku and selectedSku.active and selectedSku.originalPrice ne null and selectedSku.originalPrice > selectedSku.price ? '' : 'display:none;'}">

                            <c:if test="${not empty selectedSku and selectedSku.active and selectedSku.originalPrice ne null and selectedSku.originalPrice > selectedSku.price}">
                                <fmt:formatNumber
                                    value="${selectedSku.originalPrice}"
                                    pattern="#,##0"/>
                                ₫
                            </c:if>
                        </span>

                        <span id="displayDiscount"
                              class="product-discount"
                              style="display:none;">
                        </span>

                    </div>

                    <div id="displayStock"
                         class="mt-3 fw-medium">

                        <c:choose>
                            <c:when test="${empty skus}">

                                <span class="text-muted">
                                    Chưa có phiên bản kinh doanh
                                </span>

                            </c:when>

                            <c:when test="${not empty selectedSku and not selectedSku.active}">
                                <span class="text-secondary">
                                    <i class="bi bi-pause-circle me-1"></i>
                                    Phiên bản này đã ngừng kinh doanh
                                </span>
                            </c:when>

                            <c:when test="${selectedSku.stockQuantity > 0}">

                                <span class="text-success">
                                    <i class="bi bi-box-seam me-1"></i>
                                    Còn ${selectedSku.stockQuantity} sản phẩm
                                </span>

                            </c:when>

                            <c:otherwise>

                                <span class="text-danger">
                                    <i class="bi bi-x-circle me-1"></i>
                                    Hết hàng
                                </span>

                            </c:otherwise>
                        </c:choose>

                    </div>

                </div>


                <form id="addToCartForm"
                      action="${pageContext.request.contextPath}/cart"
                      method="POST">

                    <input type="hidden"
                           name="action"
                           value="add">

                    <input type="hidden"
                           name="productId"
                           value="${product.productId}">

                    <c:choose>

                        <c:when test="${not empty skus}">

                            <div class="d-flex justify-content-between
                                 align-items-center gap-2 mb-3">

                                <h5 class="fw-bold mb-0">
                                    Chọn phiên bản
                                </h5>

                                <small class="text-muted">
                                    ${fn:length(skus)} phiên bản
                                </small>

                            </div>

                            <div id="skuVariantGroups"
                                 class="variant-selector mb-3"
                                 aria-label="Chọn cấu hình và màu sắc"
                                 hidden></div>

                            <p id="skuVariantNotice"
                               class="variant-change-notice"
                               role="status"
                               aria-live="polite"
                               hidden></p>

                            <div id="skuFallback" class="row g-2 mb-4">

                                <c:forEach items="${skus}"
                                           var="sku">

                                    <div class="col-6 col-md-4">

                                        <input type="radio"
                                               name="skuId"
                                               id="sku_${sku.skuId}"
                                               value="${sku.skuId}"
                                               class="sku-radio"

                                               data-price="${sku.price}"
                                               data-original-price="${sku.originalPrice}"
                                               data-stock="${sku.stockQuantity}"
                                               data-active="${sku.active}"

                                               ${sku.skuId eq selectedSkuId and sku.active and sku.stockQuantity > 0 ? 'checked' : ''}
                                               ${not sku.active or sku.stockQuantity <= 0 ? 'disabled' : ''}>

                                        <label class="sku-label"
                                               for="sku_${sku.skuId}">

                                            <span class="sku-label-name">

                                                <c:choose>

                                                    <c:when test="${not empty sku.attributeValues}">

                                                        <c:forEach items="${sku.attributeValues}"
                                                                   var="attr"
                                                                   varStatus="st">

                                                            <c:if test="${not st.first}">
                                                                ·
                                                            </c:if>

                                                            <c:choose>
                                                                <c:when test="${attr.textValue ne null}">
                                                                    <c:out value="${attr.textValue}"/>
                                                                </c:when>

                                                                <c:when test="${attr.numericValue ne null}">
                                                                    <fmt:formatNumber value="${attr.numericValue}"
                                                                                      pattern="0.####"
                                                                                      groupingUsed="false"/><c:if test="${attr.attributeName eq 'Dung lượng lưu trữ' or attr.attributeName eq 'RAM'}">GB</c:if>
                                                                </c:when>

                                                                <c:when test="${attr.booleanValue ne null}">
                                                                    <c:out value="${attr.booleanValue ? 'Có' : 'Không'}"/>
                                                                </c:when>
                                                            </c:choose>

                                                        </c:forEach>

                                                    </c:when>

                                                    <c:otherwise>
                                                        <c:out value="${sku.skuCode}"/>
                                                    </c:otherwise>

                                                </c:choose>

                                            </span>

                                            <span class="sku-label-price">
                                                <c:choose>
                                                    <c:when test="${not sku.active}">
                                                        Ngừng kinh doanh
                                                    </c:when>
                                                    <c:otherwise>
                                                        <fmt:formatNumber
                                                            value="${sku.price}"
                                                            pattern="#,##0"/>
                                                        ₫
                                                    </c:otherwise>
                                                </c:choose>
                                            </span>

                                            <span class="sku-label-stock">

                                                <c:choose>
                                                    <c:when test="${not sku.active}">
                                                        Ngừng kinh doanh
                                                    </c:when>
                                                    <c:when test="${sku.stockQuantity > 0}">
                                                        Còn ${sku.stockQuantity}
                                                    </c:when>

                                                    <c:otherwise>
                                                        Hết hàng
                                                    </c:otherwise>
                                                </c:choose>

                                            </span>

                                        </label>
                                    </div>

                                </c:forEach>

                            </div>

                        </c:when>

                        <c:otherwise>

                            <div class="alert alert-warning">
                                Sản phẩm này hiện chưa có
                                phiên bản để đặt mua.
                            </div>

                        </c:otherwise>

                    </c:choose>

                    <div class="d-grid">

                        <button type="submit"
                                class="btn btn-primary btn-lg
                                purchase-button"
                                id="btnAddToCart"
                                ${not hasAvailableSku ? 'disabled' : ''}>

                            <i class="bi bi-cart-plus me-2"></i>

                            <span id="addToCartText">
                                ${hasAvailableSku ? 'THÊM VÀO GIỎ HÀNG' : (not empty skus and not hasActiveSku ? 'NGỪNG KINH DOANH' : 'TẠM HẾT HÀNG')}
                            </span>

                        </button>

                    </div>

                </form>

                <div id="skuVariantData" hidden>
                    <c:forEach items="${skus}" var="sku">
                        <div class="sku-variant-record"
                             data-sku-id="${sku.skuId}">
                            <c:forEach items="${sku.attributeValues}" var="attr">
                                <span class="sku-attribute-record"
                                      data-attribute-id="${attr.attributeId}"
                                      data-name="<c:out value='${attr.attributeName}'/>"
                                      data-text="<c:out value='${attr.textValue}'/>"
                                      data-number="<c:out value='${attr.numericValue}'/>"
                                      data-boolean="<c:out value='${attr.booleanValue}'/>"></span>
                            </c:forEach>
                        </div>
                    </c:forEach>
                </div>

                <div class="d-flex flex-wrap gap-3
                     text-muted small mt-4">

                    <span>
                        <i class="bi bi-shield-check me-1"></i>
                        Thông tin theo từng phiên bản
                    </span>

                    <span>
                        <i class="bi bi-images me-1"></i>
                        Hình ảnh thay đổi khi chọn SKU
                    </span>

                </div>

            </div>

        </div>

        <div class="row mt-5">
            <div class="col-12">
                <jsp:include page="/WEB-INF/shop/specifications.jsp"/>
            </div>
        </div>



        <style>
            .product-description-section {
                margin-top: 48px;
            }

            .product-description-box {
                background: #fff;
                border: 1px solid #e8edf3;
                border-radius: 18px;
                padding: 28px;
            }

            .product-description-intro {
                color: #475569;
                line-height: 1.9;
                font-size: 15px;
                white-space: pre-line;
            }

            .product-description-item {
                padding: 24px 0;
                border-top: 1px solid #edf0f4;
            }

            .product-description-item:first-child {
                border-top: none;
            }

            .product-description-item h4 {
                font-size: 20px;
                font-weight: 750;
                color: #172033;
                margin-bottom: 14px;
            }

            .product-description-item p {
                color: #475569;
                font-size: 15px;
                line-height: 1.9;
                white-space: pre-line;
                margin-bottom: 0;
            }

            .product-description-image {
                display: block;
                width: 100%;
                max-height: 420px;
                object-fit: contain;
                border-radius: 14px;
                margin-top: 20px;
                background: #f8fafc;
            }

            @media (max-width: 575.98px) {
                .product-description-box {
                    padding: 18px;
                }

                .product-description-item h4 {
                    font-size: 18px;
                }
            }
            .product-description-intro {
                line-height: 1.9;
                color: #475569;
            }
            .product-description-intro h2,
            .product-description-intro h3,
            .product-description-intro h4 {
                color: #172033;
                font-weight: 750;
                line-height: 1.45;
                margin: 24px 0 12px;
            }
            .product-description-intro h2 {
                font-size: 23px;
            }
            .product-description-intro h3 {
                font-size: 19px;
            }
            .product-description-intro h4 {
                font-size: 16px;
            }
            .product-description-intro p {
                margin: 0 0 13px;
            }
            .product-description-intro ul,
            .product-description-intro ol {
                padding-left: 28px;
                margin: 0 0 18px;
            }
            .product-description-intro li {
                margin-bottom: 6px;
            }
        </style>

        <div class="row mt-5 product-description-section">

            <div class="col-lg-10 mx-auto">

                <h3 class="detail-section-title">
                    Mô tả sản phẩm
                </h3>

                <div class="product-description-box">

                    <c:choose>

                        <c:when test="${not empty product.description}">

                            <div id="descContainer"
                                 class="description-container">

                                <div id="descContent"
                                     class="product-description-content collapsed">


                                    <c:if test="${not empty product.description}">

                                        <div class="product-description-intro">

                                            <c:out value="${productDescriptionHtml}" escapeXml="false"/>

                                        </div>

                                    </c:if>

                                </div>


                                <div id="descOverlay"
                                     class="description-overlay">
                                </div>

                            </div>


                            <div class="text-center mt-4">

                                <button type="button"
                                        class="btn btn-outline-primary rounded-pill px-4"
                                        id="btnToggleDesc"
                                        style="display:none;">

                                    Xem thêm mô tả

                                    <i class="bi bi-chevron-down ms-1"></i>

                                </button>

                            </div>

                        </c:when>

                        <c:otherwise>

                            <p class="text-muted mb-0">

                                Mô tả sản phẩm đang được cập nhật.

                            </p>

                        </c:otherwise>

                    </c:choose>

                </div>

            </div>

        </div>



        <div class="row mt-5">

            <div class="col-lg-9 mx-auto">

                <h3 class="detail-section-title">
                    Đánh giá &amp; bình luận
                </h3>

                <div class="border rounded-4 p-4 mb-4">

                    <div class="row g-4 text-center">

                        <div class="col-4">

                            <div class="fs-3 fw-bold text-primary">

                                <fmt:formatNumber
                                    value="${purchaseCount}"
                                    pattern="#,##0"/>

                            </div>

                            <div class="small text-muted">
                                Lượt mua
                            </div>

                        </div>

                        <div class="col-4">

                            <div class="fs-3 fw-bold text-primary">
                                ${totalReviews}
                            </div>

                            <div class="small text-muted">
                                Đánh giá
                            </div>

                        </div>

                        <div class="col-4">

                            <div class="fs-3 fw-bold text-warning">

                                <fmt:formatNumber
                                    value="${averageRating}"
                                    minFractionDigits="1"
                                    maxFractionDigits="1"/>
                                /5

                            </div>

                            <div class="small text-muted">
                                Điểm trung bình
                            </div>

                        </div>

                    </div>

                    <c:if test="${totalReviews == 0}">

                        <p class="text-center text-muted mt-3 mb-0">
                            Sản phẩm chưa có đánh giá.
                        </p>

                    </c:if>

                </div>


                <c:choose>

                    <c:when test="${param.report eq 'SUCCESS'}">

                        <div class="alert alert-success">
                            Báo cáo của bạn đã được gửi
                            để nhân viên xem xét.
                        </div>

                    </c:when>

                    <c:when test="${param.report eq 'RATE_LIMIT'}">

                        <div class="alert alert-warning">
                            Bạn đã gửi quá 5 báo cáo trong 24 giờ.
                            Vui lòng thử lại sau.
                        </div>

                    </c:when>

                    <c:when test="${param.report eq 'NOT_FOUND'}">

                        <div class="alert alert-warning">
                            Đánh giá không tồn tại hoặc đã bị ẩn.
                        </div>

                    </c:when>

                    <c:when test="${param.report eq 'FAILED'}">

                        <div class="alert alert-danger">
                            Không thể gửi báo cáo.
                            Vui lòng thử lại.
                        </div>

                    </c:when>

                    <c:when test="${param.report eq 'DUPLICATE'}">

                        <div class="alert alert-warning">
                            Bạn đã có báo cáo đang chờ xử lý
                            cho đánh giá này.
                        </div>

                    </c:when>

                    <c:when test="${param.report eq 'OWN_REVIEW'}">

                        <div class="alert alert-warning">
                            Bạn không thể báo cáo đánh giá
                            của chính mình.
                        </div>

                    </c:when>

                    <c:when test="${param.report eq 'INVALID'}">

                        <div class="alert alert-danger">
                            Vui lòng nhập lý do báo cáo hợp lệ.
                        </div>

                    </c:when>

                </c:choose>



                <c:choose>

                    <c:when test="${not empty reviews}">

                        <c:forEach items="${reviews}"
                                   var="review">

                            <div class="review-card">

                                <div class="d-flex
                                     justify-content-between
                                     align-items-start
                                     flex-wrap gap-2 mb-3">

                                    <div>

                                        <div class="fw-bold mb-1">
                                            Khách hàng
                                        </div>

                                        <div class="text-warning">

                                            <c:forEach begin="1"
                                                       end="5"
                                                       var="star">

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

                                        <fmt:formatDate
                                            value="${review.createdAt}"
                                            pattern="dd/MM/yyyy HH:mm"/>

                                    </small>

                                </div>

                                <p class="mb-3"
                                   style="white-space:pre-line;">
                                    <c:out value="${review.comment}"/>
                                </p>

                                <%-- ẢNH ĐÁNH GIÁ --%>

                                <c:if test="${not empty review.images}">

                                    <div class="d-flex flex-wrap
                                         gap-2 mb-3">

                                        <c:forEach items="${review.images}"
                                                   var="image">

                                            <img src="${pageContext.request.contextPath}<c:out value='${image}'/>"
                                                 alt="Ảnh đánh giá sản phẩm"
                                                 class="review-image"
                                                 loading="lazy">

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
                                                 value="<c:out value='${sessionScope.reviewCsrfToken}'/>">

                                          <input type="hidden"
                                                 name="reviewId"
                                                 value="${review.reviewId}">

                                          <input type="hidden"
                                                 name="productId"
                                                 value="${product.productId}">

                                          <label class="form-label
                                                 small fw-semibold">
                                              Báo cáo đánh giá
                                          </label>

                                          <div class="input-group">

                                              <input type="text"
                                                     name="reason"
                                                     class="form-control"
                                                     maxlength="500"
                                                     placeholder="Nhập lý do báo cáo..."
                                                     required>

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
                                Chưa có bình luận nào
                                cho sản phẩm này.
                            </p>

                        </div>

                    </c:otherwise>

                </c:choose>

            </div>

        </div>


        <c:if test="${not empty relatedProducts}">

            <style>
                .related-section {
                    margin-top: 55px;
                    margin-bottom: 45px;
                }

                .related-section-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    flex-wrap: wrap;
                    gap: 15px;
                    margin-bottom: 24px;
                }

                .related-section-title {
                    font-size: 25px;
                    font-weight: 800;
                    color: #142b4a;
                    margin: 0;
                }

                .related-section-subtitle {
                    color: #64748b;
                    font-size: 14px;
                    margin-top: 8px;
                    margin-bottom: 0;
                }

                .related-card {
                    display: flex;
                    flex-direction: column;
                    height: 100%;
                    border: 1px solid #e5eaf0;
                    border-radius: 15px;
                    overflow: hidden;
                    background: #fff;
                    color: inherit;
                    text-decoration: none;
                    transition: box-shadow .2s, transform .2s;
                }

                .related-card:hover {
                    color: inherit;
                    transform: translateY(-4px);
                    box-shadow: 0 10px 28px rgba(15, 23, 42, .09);
                    border-color: #bfdbfe;
                }

                .related-card-image {
                    width: 100%;
                    aspect-ratio: 1 / 1;
                    background: #f8fafc;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    overflow: hidden;
                    padding: 15px;
                }

                .related-card-image img {
                    width: 100%;
                    height: 100%;
                    object-fit: contain;
                }

                .related-card-no-image {
                    color: #cbd5e1;
                    font-size: 48px;
                }

                .related-card-body {
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                    padding: 16px;
                }

                .related-card-brand {
                    font-size: 12px;
                    font-weight: 700;
                    color: #2563eb;
                    margin-bottom: 7px;
                }

                .related-card-name {
                    font-size: 15px;
                    font-weight: 700;
                    color: #1e293b;
                    line-height: 1.5;
                    min-height: 45px;
                    margin-bottom: 14px;
                    display: -webkit-box;
                    -webkit-line-clamp: 2;
                    -webkit-box-orient: vertical;
                    overflow: hidden;
                }

                .related-card-price-box {
                    margin-top: auto;
                }

                .related-card-price-label {
                    font-size: 12px;
                    color: #64748b;
                    margin-bottom: 4px;
                }

                .related-card-price {
                    font-size: 19px;
                    font-weight: 800;
                    color: #dc2626;
                }

                .related-card-footer {
                    border-top: 1px solid #edf0f4;
                    margin-top: 14px;
                    padding-top: 12px;
                    color: #2563eb;
                    font-size: 13px;
                    font-weight: 600;
                }

                @media (max-width: 575.98px) {
                    .related-section-title {
                        font-size: 21px;
                    }

                    .related-card-body {
                        padding: 12px;
                    }

                    .related-card-name {
                        font-size: 13px;
                    }

                    .related-card-price {
                        font-size: 16px;
                    }
                }

                @media (prefers-reduced-motion: reduce) {
                    .related-card {
                        transition: none;
                    }
                }
            </style>

            <section class="related-section"
                     id="relatedProducts">

                <%-- HEADER --%>

                <div class="related-section-header">

                    <div>

                        <h2 class="related-section-title">

                            <i class="bi bi-grid-3x3-gap
                               text-primary me-2"></i>

                            Sản phẩm tương tự

                        </h2>

                        <p class="related-section-subtitle">

                            Các sản phẩm khác thuộc danh mục

                            <strong>
                                <c:out value="${product.category.categoryName}"/>
                            </strong>

                        </p>

                    </div>


                    <c:url var="categoryUrl" value="/shop">
                        <c:param name="categoryId"
                                 value="${product.categoryId}"/>
                    </c:url>

                    <a href="${fn:escapeXml(categoryUrl)}"
                       class="btn btn-outline-primary rounded-pill">

                        Xem thêm sản phẩm

                        <i class="bi bi-arrow-right ms-1"></i>

                    </a>

                </div>


                <div class="row g-3 g-lg-4">

                    <c:forEach items="${relatedProducts}"
                               var="related"
                               varStatus="st">

                        <c:if test="${st.index lt 8}">

                            <div class="col-6 col-lg-3">

                                <c:url var="relatedUrl" value="/shop">
                                    <c:param name="action" value="detail"/>
                                    <c:param name="id"
                                             value="${related.productId}"/>
                                </c:url>

                                <c:set var="relatedImageUrl" value=""/>

                                <c:if test="${not empty related.imageUrl}">

                                    <c:choose>

                                        <c:when test="${fn:startsWith(related.imageUrl, 'http://')
                                                        or fn:startsWith(related.imageUrl, 'https://')}">

                                                <c:set var="relatedImageUrl"
                                                       value="${related.imageUrl}"/>

                                        </c:when>

                                        <c:otherwise>

                                            <c:set var="imagePath"
                                                   value="${related.imageUrl}"/>

                                            <c:if test="${not fn:startsWith(imagePath, '/')}">
                                                <c:set var="imagePath"
                                                       value="/${imagePath}"/>
                                            </c:if>

                                            <c:url var="relatedImageUrl"
                                                   value="${imagePath}"/>

                                        </c:otherwise>

                                    </c:choose>

                                </c:if>

                                <a class="related-card"
                                   href="${fn:escapeXml(relatedUrl)}">

                                    <div class="related-card-image">

                                        <c:choose>

                                            <c:when test="${not empty relatedImageUrl}">

                                                <img src="${fn:escapeXml(relatedImageUrl)}"
                                                     alt="${fn:escapeXml(related.productName)}"
                                                     loading="lazy"
                                                     onerror="this.style.display='none';">

                                            </c:when>

                                            <c:otherwise>

                                                <i class="bi bi-image related-card-no-image"></i>

                                            </c:otherwise>

                                        </c:choose>

                                    </div>


                                    <div class="related-card-body">

                                        <div class="related-card-brand">

                                            <c:out value="${related.brand.brandName}"/>

                                        </div>

                                        <h3 class="related-card-name">

                                            <c:out value="${related.productName}"/>

                                        </h3>

                                        <div class="related-card-price-box">

                                            <c:choose>

                                                <c:when test="${related.minPrice gt 0}">

                                                    <div class="related-card-price-label">
                                                        Giá từ
                                                    </div>

                                                    <div class="related-card-price">

                                                        <fmt:formatNumber
                                                            value="${related.minPrice}"
                                                            pattern="#,##0"/>

                                                        ₫

                                                    </div>

                                                </c:when>

                                                <c:otherwise>

                                                    <span class="text-muted small">
                                                        Đang cập nhật giá
                                                    </span>

                                                </c:otherwise>

                                            </c:choose>

                                        </div>

                                        <div class="related-card-footer">

                                            Xem chi tiết

                                            <i class="bi bi-arrow-right ms-1"></i>

                                        </div>

                                    </div>

                                </a>

                            </div>

                        </c:if>

                    </c:forEach>

                </div>

            </section>

        </c:if>


    </div>
</div>

<dialog id="productLightbox" class="product-lightbox"
        aria-labelledby="lightboxTitle">
    <div class="lightbox-header">
        <strong id="lightboxTitle">Hình ảnh sản phẩm</strong>
        <button type="button" id="lightboxClose" class="lightbox-close"
                aria-label="Đóng cửa sổ xem ảnh" autofocus>
            <i class="bi bi-x-lg" aria-hidden="true"></i>
        </button>
    </div>
    <div class="lightbox-stage">
        <img id="lightboxImage" alt="Ảnh sản phẩm phóng to">
        <button type="button" id="lightboxPrev"
                class="gallery-nav gallery-prev" aria-label="Ảnh trước" hidden>
            <i class="bi bi-chevron-left" aria-hidden="true"></i>
        </button>
        <button type="button" id="lightboxNext"
                class="gallery-nav gallery-next" aria-label="Ảnh tiếp theo" hidden>
            <i class="bi bi-chevron-right" aria-hidden="true"></i>
        </button>
    </div>
    <div id="lightboxCounter" class="lightbox-counter" aria-live="polite"></div>
</dialog>

<div id="productGalleryData" hidden>

    <c:if test="${not empty product.imageUrl}">

        <span class="gallery-data-item"
              data-url="<c:out value='${product.imageUrl}'/>"
              data-alt="Ảnh đại diện sản phẩm">
        </span>

    </c:if>

    <c:forEach items="${product.galleryImages}"
               var="img">

        <span class="gallery-data-item"
              data-url="<c:out value='${img.imageUrl}'/>"
              data-alt="<c:out value='${img.altText}'/>">
        </span>

    </c:forEach>

</div>

<div id="skuGalleryData" hidden>

    <c:forEach items="${skus}" var="sku">

        <div class="sku-gallery-data"
             data-sku-id="${sku.skuId}">

            <c:forEach items="${skuImagesBySkuId[sku.skuId]}"
                       var="img">

                <span class="gallery-data-item"
                      data-url="<c:out value='${img.imageUrl}'/>"
                      data-alt="<c:out value='${img.altText}'/>">
                </span>

            </c:forEach>

        </div>

    </c:forEach>

</div>

<script>
    document.addEventListener("DOMContentLoaded", function () {

        const mainImage =
                document.getElementById("mainProductImage");
        const galleryPlaceholder =
                document.getElementById("galleryPlaceholder");

        const galleryCount =
                document.getElementById("galleryCount");

        const galleryThumbnails =
                document.getElementById("galleryThumbnails");

        const gallerySourceLabel =
                document.getElementById("gallerySourceLabel");

        const skuRadios =
                document.querySelectorAll(".sku-radio");

        const displayPrice =
                document.getElementById("displayPrice");

        const displayOriginalPrice =
                document.getElementById("displayOriginalPrice");

        const displayDiscount =
                document.getElementById("displayDiscount");

        const displayStock =
                document.getElementById("displayStock");

        const btnAddToCart =
                document.getElementById("btnAddToCart");

        const addToCartText =
                document.getElementById("addToCartText");

        const addToCartForm =
                document.getElementById("addToCartForm");

        const contextPath =
                "<c:out value='${pageContext.request.contextPath}'/>";

        function resolveImageUrl(path) {

            if (!path) {
                return "";
            }

            const value = path.trim();

            if (/^https?:\/\//i.test(value)) {
                return value;
            }

            if (value.startsWith("//")) {
                return "";
            }

            const normalized = value.replace(/^\/+/, "");

            return contextPath + "/" + normalized;
        }

        function readGallery(container) {

            if (!container) {
                return [];
            }

            const images = [];

            container.querySelectorAll(".gallery-data-item")
                    .forEach(function (item) {

                        const url =
                                resolveImageUrl(item.dataset.url);

                        if (!url) {
                            return;
                        }

                        const alreadyExists =
                                images.some(function (image) {
                                    return image.url === url;
                                });

                        if (alreadyExists) {
                            return;
                        }

                        images.push({
                            url: url,
                            alt: item.dataset.alt || "Ảnh sản phẩm"
                        });
                    });

            return images;
        }

        const productGallery =
                readGallery(
                        document.getElementById(
                                "productGalleryData"
                                )
                        );



        const skuGalleries = new Map();

        document.querySelectorAll(".sku-gallery-data")
                .forEach(function (container) {

                    skuGalleries.set(
                            container.dataset.skuId,
                            readGallery(container)
                            );
                });



        function showMainImage(image, index, total) {

            if (!image) {

                mainImage.style.display = "none";
                mainImage.removeAttribute("src");

                galleryPlaceholder.style.display = "";

                galleryCount.style.display = "none";

                return;
            }

            mainImage.src = image.url;
            mainImage.alt = image.alt;
            mainImage.style.display = "block";

            galleryPlaceholder.style.display = "none";

            galleryCount.textContent =
                    (index + 1) + " / " + total;

            galleryCount.style.display = "";
        }



        // ========================================
        // GALLERY NAVIGATION & LIGHTBOX
        // ========================================
        const galleryPrev = document.getElementById("galleryPrev");
        const galleryNext = document.getElementById("galleryNext");
        const lightbox = document.getElementById("productLightbox");
        const lightboxImage = document.getElementById("lightboxImage");
        const lightboxPrev = document.getElementById("lightboxPrev");
        const lightboxNext = document.getElementById("lightboxNext");
        const lightboxClose = document.getElementById("lightboxClose");
        const lightboxCounter = document.getElementById("lightboxCounter");
        const galleryElement = mainImage.closest(".detail-gallery");

        let currentGallery = [];
        let currentImageIndex = 0;

        function updateGalleryControls() {
            const hide = currentGallery.length <= 1;
            galleryPrev.hidden = hide;
            galleryNext.hidden = hide;
            lightboxPrev.hidden = hide;
            lightboxNext.hidden = hide;
        }

        function updateLightbox() {
            const image = currentGallery[currentImageIndex];
            if (!image) {
                return;
            }
            lightboxImage.src = image.url;
            lightboxImage.alt = image.alt;
            lightboxCounter.textContent = (currentImageIndex + 1)
                    + " / " + currentGallery.length;
        }

        function selectGalleryImage(index) {
            const total = currentGallery.length;
            if (total === 0) {
                return;
            }

            // Quay vòng từ ảnh cuối về ảnh đầu và ngược lại.
            currentImageIndex = ((index % total) + total) % total;
            showMainImage(currentGallery[currentImageIndex], currentImageIndex, total);

            galleryThumbnails.querySelectorAll(".gallery-thumb-button")
                    .forEach(function (button, buttonIndex) {
                        const selected = buttonIndex === currentImageIndex;
                        button.classList.toggle("active", selected);
                        button.setAttribute("aria-pressed", String(selected));

                        if (selected) {
                            const thumbRect = button.getBoundingClientRect();
                            const galleryRect = galleryThumbnails.getBoundingClientRect();
                            if (thumbRect.left < galleryRect.left) {
                                galleryThumbnails.scrollLeft -= galleryRect.left - thumbRect.left;
                            } else if (thumbRect.right > galleryRect.right) {
                                galleryThumbnails.scrollLeft += thumbRect.right - galleryRect.right;
                            }
                        }
                    });

            if (lightbox.open) {
                updateLightbox();
            }
        }

        function moveGalleryImage(direction) {
            selectGalleryImage(currentImageIndex + direction);
        }

        function openLightbox() {
            if (currentGallery.length === 0 || lightbox.open) {
                return;
            }
            updateLightbox();
            lightbox.showModal();
        }

        function closeLightbox() {
            if (lightbox.open) {
                lightbox.close();
            }
        }

        function renderGallery(images, isSkuGallery) {
            currentGallery = images || [];
            currentImageIndex = 0;
            galleryThumbnails.replaceChildren();
            galleryThumbnails.scrollLeft = 0;
            gallerySourceLabel.textContent = isSkuGallery
                    ? "Hình ảnh của phiên bản đang chọn"
                    : "Hình ảnh chung của sản phẩm";
            updateGalleryControls();

            if (currentGallery.length === 0) {
                showMainImage(null, 0, 0);
                closeLightbox();
                gallerySourceLabel.textContent = "Sản phẩm chưa có hình ảnh.";
                return;
            }

            currentGallery.forEach(function (image, index) {
                const button = document.createElement("button");
                button.type = "button";
                button.className = "gallery-thumb-button";
                button.setAttribute("aria-label", "Xem ảnh " + (index + 1));

                const thumb = document.createElement("img");
                thumb.src = image.url;
                thumb.alt = image.alt;
                thumb.loading = "lazy";
                button.appendChild(thumb);
                button.addEventListener("click", function () {
                    selectGalleryImage(index);
                });
                galleryThumbnails.appendChild(button);
            });

            selectGalleryImage(0);
        }

        galleryPrev.addEventListener("click", function () {
            moveGalleryImage(-1);
        });
        galleryNext.addEventListener("click", function () {
            moveGalleryImage(1);
        });
        lightboxPrev.addEventListener("click", function () {
            moveGalleryImage(-1);
        });
        lightboxNext.addEventListener("click", function () {
            moveGalleryImage(1);
        });
        mainImage.addEventListener("click", openLightbox);
        mainImage.addEventListener("keydown", function (event) {
            if (event.key === "Enter" || event.key === " ") {
                event.preventDefault();
                openLightbox();
            }
        });
        lightboxClose.addEventListener("click", closeLightbox);

        // Nhấp vào nền bên ngoài dialog để đóng.
        lightbox.addEventListener("click", function (event) {
            if (event.target !== lightbox) {
                return;
            }
            const rect = lightbox.getBoundingClientRect();
            if (event.clientX < rect.left || event.clientX > rect.right
                    || event.clientY < rect.top || event.clientY > rect.bottom) {
                closeLightbox();
            }
        });

        // Esc được dialog hỗ trợ sẵn. Không chiếm phím của form chọn SKU.
        document.addEventListener("keydown", function (event) {
            if (event.defaultPrevented || event.altKey || event.ctrlKey
                    || event.metaKey || event.shiftKey || currentGallery.length <= 1) {
                return;
            }
            const focused = document.activeElement;
            if (!lightbox.open && focused !== document.body
                    && !galleryElement.contains(focused)) {
                return;
            }
            if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
                event.preventDefault();
                moveGalleryImage(event.key === "ArrowLeft" ? -1 : 1);
            }
        });

        function formatPrice(value) {

            if (!Number.isFinite(value)) {
                return "Liên hệ";
            }

            return value.toLocaleString("vi-VN", {
                maximumFractionDigits: 0
            }) + " ₫";
        }

        function parseOptionalPrice(value) {

            if (value === null
                    || value === undefined
                    || value.trim() === "") {
                return null;
            }

            const number = Number(value);

            return Number.isFinite(number)
                    ? number
                    : null;
        }

        // ========================================
        // 8. CẬP NHẬT GIÁ VÀ TỒN KHO
        // ========================================

        function updateSkuInfo(radio) {

            if (!radio) {

                displayPrice.textContent = "Liên hệ";

                displayOriginalPrice.style.display = "none";
                displayDiscount.style.display = "none";

                displayStock.textContent =
                        "Chưa có phiên bản để đặt mua";

                btnAddToCart.disabled = true;
                addToCartText.textContent = "TẠM HẾT HÀNG";

                return;
            }

            // SKU ngừng bán vẫn hiện trong Detail, tuyệt đối không cho đặt mua.
            if (radio.dataset.active !== "true") {
                displayPrice.textContent = "Ngừng kinh doanh";
                displayOriginalPrice.style.display = "none";
                displayDiscount.style.display = "none";
                displayStock.className = "mt-3 fw-medium text-secondary";
                displayStock.textContent = "Phiên bản này đã ngừng kinh doanh";
                btnAddToCart.disabled = true;
                addToCartText.textContent = "NGỪNG KINH DOANH";
                return;
            }

            const price =
                    Number(radio.dataset.price);

            const originalPrice =
                    parseOptionalPrice(
                            radio.dataset.originalPrice
                            );

            const stock =
                    Number(radio.dataset.stock);

            displayPrice.textContent =
                    formatPrice(price);

            if (originalPrice !== null
                    && originalPrice > price) {

                displayOriginalPrice.textContent =
                        formatPrice(originalPrice);

                displayOriginalPrice.style.display = "";

                const discount =
                        Math.round(
                                (originalPrice - price)
                                / originalPrice * 100
                                );

                displayDiscount.textContent =
                        "-" + discount + "%";

                displayDiscount.style.display = "";

            } else {

                displayOriginalPrice.style.display = "none";
                displayDiscount.style.display = "none";
            }

            if (stock > 0) {

                displayStock.className =
                        "mt-3 fw-medium text-success";

                displayStock.textContent =
                        "Còn " + stock + " sản phẩm";

                btnAddToCart.disabled = false;
                addToCartText.textContent =
                        "THÊM VÀO GIỎ HÀNG";

            } else {

                displayStock.className =
                        "mt-3 fw-medium text-danger";

                displayStock.textContent =
                        "Hết hàng";

                btnAddToCart.disabled = true;
                addToCartText.textContent =
                        "TẠM HẾT HÀNG";
            }
        }

        // ========================================
        // 9. CẬP NHẬT ẢNH THEO SKU
        // ========================================


        function updateSkuGallery(skuId) {

            // Ảnh riêng của SKU được chọn
            const skuImages =
                    skuGalleries.get(String(skuId)) || [];

            // Ảnh chung và ảnh phụ của sản phẩm
            const commonImages = productGallery || [];

            // Ưu tiên ảnh SKU trước, ảnh chung sau
            const combinedImages = [
                ...skuImages,
                ...commonImages
            ];

            // Loại bỏ ảnh trùng URL
            const uniqueImages = [];
            const seenUrls = new Set();

            combinedImages.forEach(function (image) {

                if (!image || !image.url) {
                    return;
                }

                if (seenUrls.has(image.url)) {
                    return;
                }

                seenUrls.add(image.url);
                uniqueImages.push(image);
            });

            // Hiển thị toàn bộ ảnh đã kết hợp
            renderGallery(
                    uniqueImages,
                    skuImages.length > 0
                    );

            // Cập nhật nhãn gallery
            if (gallerySourceLabel) {

                gallerySourceLabel.textContent =
                        skuImages.length > 0
                        ? "Ảnh phiên bản và ảnh chung của sản phẩm"
                        : "Hình ảnh chung của sản phẩm";
            }
        }


        // ========================================
        // 10. SỰ KIỆN ĐỔI SKU
        // ========================================

        skuRadios.forEach(function (radio) {

            radio.addEventListener("change", function () {

                if (!this.checked || this.disabled) {
                    return;
                }

                updateSkuInfo(this);
                updateSkuGallery(this.value);
            });
        });

        // ========================================
        // 11. KHỞI TẠO SKU MẶC ĐỊNH
        // ========================================

        const selectedRadio =
                document.querySelector(
                        ".sku-radio:checked:not(:disabled)"
                        )
                || Array.from(skuRadios).find(function (radio) {
            return !radio.disabled && Number(radio.dataset.stock) > 0;
        });

        if (selectedRadio) {

            selectedRadio.checked = true;
            updateSkuInfo(selectedRadio);

            updateSkuGallery(
                    selectedRadio.value
                    );

        } else {

            /*
             * Không có SKU còn hàng.
             *
             * Vẫn hiển thị thông tin SKU đầu tiên
             * nếu danh sách có SKU.
             */

            const firstSku =
                    Array.from(skuRadios).find(function (radio) {
                return radio.dataset.active === "true";
            }) || skuRadios[0] || null;

            updateSkuInfo(firstSku);

            if (firstSku) {

                updateSkuGallery(firstSku.value);

            } else {

                renderGallery(
                        productGallery,
                        false
                        );
            }

            btnAddToCart.disabled = true;
            // Giữ nguyên nhãn do updateSkuInfo() đã xác định:
            // hết hàng khác với ngừng kinh doanh.
        }

        // ========================================
        // 12. CHỌN SKU THEO NHÓM THUỘC TÍNH
        // Dùng SKU thật làm nguồn dữ liệu duy nhất.
        // Nếu thuộc tính không đồng nhất -> giữ radio dự phòng.
        // ========================================

        function setupGroupedSkuSelector() {
            const container = document.getElementById("skuVariantGroups");
            const fallback = document.getElementById("skuFallback");
            const dataBox = document.getElementById("skuVariantData");
            const notice = document.getElementById("skuVariantNotice");

            if (!container || !fallback || !dataBox || !skuRadios.length) {
                return;
            }

            function foldText(value) {
                return String(value || "").trim().normalize("NFD")
                        .replace(/[\u0300-\u036f]/g, "")
                        .replace(/đ/g, "d").replace(/Đ/g, "D")
                        .toLowerCase().replace(/\s+/g, " ");
            }

            function simpleNumber(raw) {
                const value = Number(String(raw).trim().replace(",", "."));
                if (!Number.isFinite(value)) {
                    return null;
                }
                return String(value);
            }

            function getAttributeValue(node) {
                const name = node.dataset.name || ("Thuộc tính " + node.dataset.attributeId);
                const foldedName = foldText(name);
                const isGb = foldedName === "ram"
                        || foldedName.includes("dung luong luu tru")
                        || foldedName.includes("bo nho trong");
                const text = String(node.dataset.text || "").trim();
                const numberText = String(node.dataset.number || "").trim();
                const booleanText = String(node.dataset.boolean || "").trim();

                if (text) {
                    if (isGb) {
                        const memory = text.match(/^(\d+(?:[.,]\d+)?)\s*(GB|TB)$/i);
                        if (memory) {
                            const num = simpleNumber(memory[1]);
                            const unit = memory[2].toUpperCase();
                            if (num !== null) {
                                return {key: num + unit, label: num + unit};
                            }
                        }
                    }
                    return {key: "t:" + foldText(text), label: text};
                }
                if (numberText) {
                    const num = simpleNumber(numberText);
                    if (num === null) {
                        return null;
                    }
                    if (isGb) {
                        return {key: num + "GB", label: num + "GB"};
                    }
                    return {key: "n:" + num, label: num};
                }
                if (booleanText) {
                    const isTrue = booleanText.toLowerCase() === "true"
                            || booleanText === "1";
                    return {key: "b:" + isTrue, label: isTrue ? "Có" : "Không"};
                }
                return null;
            }

            const radioById = new Map();
            skuRadios.forEach(function (radio) {
                radioById.set(radio.value, radio);
            });

            const variants = [];
            let invalidData = false;
            dataBox.querySelectorAll(".sku-variant-record").forEach(function (node) {
                const radio = radioById.get(node.dataset.skuId);
                if (!radio) {
                    invalidData = true;
                    return;
                }
                const attrs = new Map();
                node.querySelectorAll(".sku-attribute-record").forEach(function (attr) {
                    const id = String(attr.dataset.attributeId || "");
                    const parsed = getAttributeValue(attr);
                    if (!id || !parsed || attrs.has(id)) {
                        invalidData = true;
                        return;
                    }
                    attrs.set(id, {
                        id: id,
                        name: attr.dataset.name || ("Thuộc tính " + id),
                        key: parsed.key,
                        label: parsed.label
                    });
                });
                variants.push({
                    id: node.dataset.skuId,
                    radio: radio,
                    stock: Number(radio.dataset.stock) || 0,
                    active: radio.dataset.active === "true",
                    attrs: attrs
                });
            });

            // Không hiện nhóm nếu SKU không có thuộc tính, thiếu thuộc tính,
            // hoặc có nhiều SKU cùng một tổ hợp (không xác định SKU nào).
            if (invalidData || variants.length !== skuRadios.length || !variants.length
                    || variants.some(function (v) {
                        return v.attrs.size === 0;
                    })) {
                return;
            }

            const ids = Array.from(variants[0].attrs.keys());
            if (variants.some(function (v) {
                return v.attrs.size !== ids.length
                        || ids.some(function (id) {
                            return !v.attrs.has(id);
                        });
            })) {
                return;
            }

            const signatures = new Set();
            for (const variant of variants) {
                const signature = ids.map(function (id) {
                    return id + ":" + variant.attrs.get(id).key;
                }).join("|");
                if (signatures.has(signature)) {
                    return;
                }
                signatures.add(signature);
            }

            function priority(id) {
                const name = foldText(variants[0].attrs.get(id).name);
                if (name.includes("dung luong") || name === "ram") {
                    return 1;
                }
                if (name.includes("ssd") || name.includes("o cung")) {
                    return 2;
                }
                if (name.includes("kich thuoc") || name.includes("phien ban")) {
                    return 3;
                }
                if (name.includes("mau sac")) {
                    return 20;
                }
                return 10;
            }
            ids.sort(function (a, b) {
                return priority(a) - priority(b);
            });

            function displayName(id) {
                const raw = variants[0].attrs.get(id).name;
                const name = foldText(raw);
                if (name === "dung luong luu tru") {
                    return "Dung lượng";
                }
                return raw;
            }

            const swatches = {
                "den": "#24252a", "bac": "#c9cdd1", "trang": "#f5f5f3",
                "xam": "#8c919b", "xanh": "#3283bd", "xanh duong": "#3283bd",
                "xanh la": "#49966e", "do": "#be4850", "vang": "#e2c36e",
                "hong": "#dfa5b4", "tim": "#9277b6", "nau": "#976f55",
                "titan tu nhien": "#b2a99a", "titan sa mac": "#bd9b7e"
            };

            const buttons = [];
            ids.forEach(function (id) {
                const group = document.createElement("div");
                group.className = "variant-group";

                const label = document.createElement("div");
                label.className = "variant-group-title";
                label.textContent = displayName(id);
                group.appendChild(label);

                const optionsBox = document.createElement("div");
                optionsBox.className = "variant-options";
                optionsBox.setAttribute("role", "group");
                optionsBox.setAttribute("aria-label", displayName(id));

                const seen = new Set();
                variants.forEach(function (variant) {
                    const attr = variant.attrs.get(id);
                    if (seen.has(attr.key)) {
                        return;
                    }
                    seen.add(attr.key);
                    const matching = variants.filter(function (item) {
                        return item.attrs.get(id).key === attr.key;
                    });
                    const matchingActive = matching.filter(function (item) {
                        return item.active;
                    });
                    const available = matchingActive.some(function (item) {
                        return item.stock > 0;
                    });
                    const unavailableReason = matchingActive.length === 0
                            ? "Ngừng kinh doanh" : "Hết hàng";

                    const button = document.createElement("button");
                    button.type = "button";
                    button.className = "variant-option";
                    button.dataset.attributeId = id;
                    button.dataset.valueKey = attr.key;
                    button.disabled = !available;
                    button.setAttribute("aria-pressed", "false");
                    button.title = available ? "Chọn " + attr.label : unavailableReason;

                    if (foldText(displayName(id)).includes("mau sac")) {
                        // Chỉ dùng ảnh thực sự gắn với một SKU mang màu này.
                        const withImage = matching.find(function (item) {
                            const photos = skuGalleries.get(item.id) || [];
                            return photos.length > 0;
                        });
                        const color = swatches[foldText(attr.label)];
                        const dot = document.createElement("span");
                        dot.className = "variant-color-dot";
                        dot.style.backgroundColor = color || "#e2e8f0";
                        dot.setAttribute("aria-hidden", "true");
                        if (withImage) {
                            const photo = skuGalleries.get(withImage.id)[0];
                            const thumb = document.createElement("img");
                            thumb.className = "variant-color-thumb";
                            thumb.src = photo.url;
                            thumb.alt = "";
                            thumb.loading = "lazy";
                            thumb.addEventListener("error", function () {
                                thumb.replaceWith(dot);
                            });
                            button.appendChild(thumb);
                        } else if (color) {
                            button.appendChild(dot);
                        }
                    }
                    const caption = document.createElement("span");
                    caption.textContent = attr.label;
                    button.appendChild(caption);

                    if (!available) {
                        const soldOut = document.createElement("small");
                        soldOut.textContent = "(" + unavailableReason + ")";
                        button.appendChild(soldOut);
                    }

                    button.addEventListener("click", function () {
                        const current = variants.find(function (item) {
                            return item.radio.checked;
                        }) || variants[0];
                        const candidates = matching.filter(function (item) {
                            return item.active && item.stock > 0;
                        });
                        if (!candidates.length) {
                            return;
                        }

                        // Ưu tiên giữ các lựa chọn khác; nếu không có tổ hợp đó,
                        // chuyển tới một SKU thực sự tồn tại và còn hàng.
                        function score(item) {
                            return ids.reduce(function (total, otherId) {
                                return total + (otherId !== id
                                        && item.attrs.get(otherId).key === current.attrs.get(otherId).key
                                        ? 1 : 0);
                            }, 0);
                        }
                        candidates.sort(function (a, b) {
                            return score(b) - score(a);
                        });
                        const chosen = candidates[0];
                        const changedOthers = ids.some(function (otherId) {
                            return otherId !== id
                                    && current.attrs.get(otherId).key !== chosen.attrs.get(otherId).key;
                        });

                        chosen.radio.checked = true;
                        chosen.radio.dispatchEvent(new Event("change", {bubbles: true}));
                        updateButtonState();

                        if (notice) {
                            notice.hidden = !changedOthers;
                            notice.textContent = changedOthers
                                    ? "Hệ thống đã chọn tổ hợp có sẵn: "
                                    + ids.map(function (otherId) {
                                        return chosen.attrs.get(otherId).label;
                                    }).join(" · ")
                                    : "";
                        }
                    });
                    optionsBox.appendChild(button);
                    buttons.push(button);
                });
                group.appendChild(optionsBox);
                container.appendChild(group);
            });

            const summary = document.createElement("p");
            summary.className = "variant-selection-summary mb-0";
            container.appendChild(summary);

            function updateButtonState() {
                const current = variants.find(function (v) {
                    return v.radio.checked;
                }) || variants[0];
                buttons.forEach(function (button) {
                    const selected = current.attrs.get(button.dataset.attributeId).key
                            === button.dataset.valueKey;
                    button.setAttribute("aria-pressed", String(selected));
                });
                summary.replaceChildren();
                const label = document.createElement("span");
                label.textContent = "Phiên bản: ";
                const strong = document.createElement("strong");
                strong.textContent = ids.map(function (id) {
                    return current.attrs.get(id).label;
                }).join(" · ");
                summary.appendChild(label);
                summary.appendChild(strong);
            }

            skuRadios.forEach(function (radio) {
                radio.addEventListener("change", updateButtonState);
            });

            // Chỉ ẩn radio dự phòng khi UI nhóm đã dựng hoàn chỉnh.
            fallback.hidden = true;
            container.hidden = false;
            updateButtonState();
        }

        setupGroupedSkuSelector();

        // ========================================
        // 13. BẢO VỆ FORM GIỎ HÀNG
        // ========================================

        if (addToCartForm) {

            addToCartForm.addEventListener(
                    "submit",
                    function (event) {

                        const checked =
                                document.querySelector(
                                        ".sku-radio:checked:not(:disabled)"
                                        );

                        if (!checked
                                || checked.dataset.active !== "true"
                                || Number(checked.dataset.stock) <= 0) {

                            event.preventDefault();

                            alert(
                                    "Vui lòng chọn phiên bản "
                                    + "còn hàng trước khi thêm vào giỏ."
                                    );
                        }

                        /*
                         * Servlet /cart vẫn phải kiểm tra
                         * giá, trạng thái và tồn kho ở server.
                         */
                    });
        }

        // ========================================
        // 13. XEM THÊM MÔ TẢ
        // ========================================

        const descContent =
                document.getElementById("descContent");

        const descOverlay =
                document.getElementById("descOverlay");

        const btnToggleDesc =
                document.getElementById("btnToggleDesc");

        if (descContent && descOverlay && btnToggleDesc) {

            function shouldCollapse() {

                descContent.classList.remove("collapsed");

                const fullHeight =
                        descContent.scrollHeight;

                if (fullHeight > 250) {

                    descContent.classList.add("collapsed");
                    descOverlay.classList.remove("hidden");
                    btnToggleDesc.style.display = "";

                } else {

                    descOverlay.classList.add("hidden");
                    btnToggleDesc.style.display = "none";
                }
            }

            shouldCollapse();

            btnToggleDesc.addEventListener(
                    "click",
                    function () {

                        const collapsed =
                                descContent.classList.contains(
                                        "collapsed"
                                        );

                        if (collapsed) {

                            descContent.classList.remove("collapsed");

                            descOverlay.classList.add("hidden");

                            btnToggleDesc.innerHTML =
                                    'Thu gọn <i class="bi bi-chevron-up ms-1"></i>';

                        } else {

                            descContent.classList.add("collapsed");

                            descOverlay.classList.remove("hidden");

                            btnToggleDesc.innerHTML =
                                    'Xem thêm <i class="bi bi-chevron-down ms-1"></i>';

                            document.getElementById(
                                    "descContainer"
                                    ).scrollIntoView({
                                behavior: "smooth",
                                block: "start"
                            });
                        }
                    });
        }
    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>
