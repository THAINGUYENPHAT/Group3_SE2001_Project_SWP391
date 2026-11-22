
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<%-- =========================================
     OECS V2 - PROFESSIONAL CATALOG
     Compatible with current ShopServlet
     ========================================= --%>

<c:url var="resetFilterUrl" value="/shop">
    <c:if test="${not empty searchKeyword}">
        <c:param name="keyword" value="${searchKeyword}"/>
    </c:if>
</c:url>

<c:set var="hasActiveFilters"
       value="${not empty selectedCats
                or not empty selectedPrice
                or not empty selectedRating}"/>

<style>
    /* =========================================
       1. PAGE
       ========================================= */

    .oecs-catalog {
        background: #f6f8fc;
        min-height: 100vh;
        padding: 28px 0 70px;
        color: #1e293b;
    }

    .oecs-catalog a {
        text-decoration: none;
    }

    .oecs-catalog-breadcrumb {
        margin-bottom: 24px;
        font-size: 14px;
    }

    .oecs-catalog-breadcrumb a {
        color: #64748b;
    }

    .oecs-catalog-breadcrumb a:hover {
        color: #2563eb;
    }

    .oecs-catalog-heading {
        margin-bottom: 25px;
    }

    .oecs-catalog-title {
        margin: 0;
        color: #142b4a;
        font-size: clamp(24px, 3vw, 32px);
        font-weight: 800;
        line-height: 1.3;
    }

    .oecs-catalog-description {
        margin: 9px 0 0;
        color: #64748b;
        font-size: 14px;
    }

    /* =========================================
       2. FILTER SIDEBAR
       ========================================= */

    .oecs-filter-sidebar {
        position: sticky;
        top: 96px;
        max-height: calc(100vh - 115px);
        overflow-y: auto;
        scrollbar-width: thin;
        background: #fff;
        border: 1px solid #e5eaf1;
        border-radius: 18px;
        padding: 23px;
    }

    .oecs-filter-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        padding-bottom: 19px;
        border-bottom: 1px solid #edf1f5;
    }

    .oecs-filter-header h2 {
        margin: 0;
        color: #172033;
        font-size: 19px;
        font-weight: 800;
    }

    .oecs-filter-section {
        padding: 21px 0;
        border-bottom: 1px solid #edf1f5;
    }

    .oecs-filter-section:last-of-type {
        border-bottom: 0;
    }

    .oecs-filter-title {
        margin: 0 0 16px;
        color: #1e293b;
        font-size: 15px;
        font-weight: 750;
    }

    .oecs-filter-options {
        display: flex;
        flex-direction: column;
        gap: 11px;
    }

    .oecs-filter-option {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        font-size: 14px;
        line-height: 1.5;
        color: #475569;
        cursor: pointer;
    }

    .oecs-filter-option input {
        flex: 0 0 auto;
        width: 17px;
        height: 17px;
        margin-top: 2px;
        accent-color: #2563eb;
        cursor: pointer;
    }

    .oecs-filter-option span {
        min-width: 0;
    }

    .oecs-filter-option:hover {
        color: #2563eb;
    }

    .oecs-filter-stars {
        color: #f59e0b;
        letter-spacing: 1px;
        white-space: nowrap;
    }

    .oecs-filter-actions {
        display: grid;
        gap: 10px;
        padding-top: 20px;
    }

    .oecs-filter-apply {
        min-height: 45px;
        font-weight: 700;
        border-radius: 11px;
    }

    .oecs-filter-reset {
        min-height: 43px;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 7px;
        border: 1px solid #d7dfe9;
        border-radius: 11px;
        background: #fff;
        color: #475569;
        font-weight: 600;
        font-size: 14px;
    }

    .oecs-filter-reset:hover {
        background: #f8fafc;
        color: #2563eb;
    }

    /* =========================================
       3. TOOLBAR
       ========================================= */

    .oecs-catalog-toolbar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 16px;
        margin-bottom: 19px;
    }

    .oecs-result-title {
        margin: 0 0 5px;
        color: #172033;
        font-size: 21px;
        font-weight: 800;
    }

    .oecs-result-count {
        margin: 0;
        color: #64748b;
        font-size: 13px;
    }

    .oecs-result-count strong {
        color: #172033;
    }

    .oecs-catalog-sort {
        width: auto;
        min-width: 190px;
        min-height: 43px;
        border: 1px solid #dfe6ef;
        border-radius: 11px;
        font-size: 14px;
        background-color: #fff;
    }

    .oecs-catalog-sort:focus {
        border-color: #93c5fd;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, .1);
    }

    /* =========================================
       4. ACTIVE FILTER CHIPS
       ========================================= */

    .oecs-active-filters {
        display: flex;
        align-items: center;
        flex-wrap: wrap;
        gap: 9px;
        margin-bottom: 23px;
    }

    .oecs-active-filters-label {
        font-size: 13px;
        font-weight: 650;
        color: #64748b;
        margin-right: 3px;
    }

    .oecs-filter-chip {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        max-width: 100%;
        border: 1px solid #bfdbfe;
        border-radius: 999px;
        padding: 7px 11px;
        background: #eff6ff;
        color: #1d4ed8;
        font-size: 12px;
        font-weight: 650;
        line-height: 1.2;
        cursor: pointer;
    }

    .oecs-filter-chip:hover {
        border-color: #2563eb;
        background: #dbeafe;
    }

    .oecs-filter-chip span {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    .oecs-clear-all {
        margin-left: 4px;
        font-size: 13px;
        color: #64748b;
        font-weight: 600;
    }

    .oecs-clear-all:hover {
        color: #dc2626;
    }

    /* =========================================
       5. PRODUCT CARD
       ========================================= */

    .oecs-product-card {
        display: flex;
        flex-direction: column;
        height: 100%;
        background: #fff;
        border: 1px solid #e5eaf1;
        border-radius: 17px;
        overflow: hidden;
        text-decoration: none;
        color: inherit;
        transition:
            transform .2s ease,
            border-color .2s ease,
            box-shadow .2s ease;
    }

    .oecs-product-card:hover {
        transform: translateY(-4px);
        border-color: #bfdbfe;
        box-shadow: 0 13px 29px rgba(15, 23, 42, .08);
        color: inherit;
    }

    .oecs-product-card:focus-visible {
        outline: 3px solid #93c5fd;
        outline-offset: 3px;
    }

    .oecs-product-image {
        position: relative;
        width: 100%;
        aspect-ratio: 1 / 1;
        display: flex;
        justify-content: center;
        align-items: center;
        padding: 19px;
        background: #fff;
        overflow: hidden;
    }

    .oecs-product-image img {
        display: block;
        width: 100%;
        height: 100%;
        object-fit: contain;
        transition: transform .25s ease;
    }

    .oecs-product-card:hover .oecs-product-image img {
        transform: scale(1.045);
    }

    .oecs-product-placeholder {
        color: #cbd5e1;
        font-size: 54px;
    }

    .oecs-product-body {
        display: flex;
        flex-direction: column;
        flex: 1;
        min-width: 0;
        padding: 18px;
        border-top: 1px solid #f0f3f7;
    }

    .oecs-product-brand {
        margin-bottom: 9px;
        color: #2563eb;
        font-size: 12px;
        font-weight: 750;
        text-transform: uppercase;
        letter-spacing: .2px;
    }

    .oecs-product-name {
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
        min-height: 47px;
        margin: 0 0 12px;
        color: #172033;
        font-size: 15px;
        font-weight: 700;
        line-height: 1.55;
    }

    .oecs-product-rating {
        display: flex;
        align-items: center;
        flex-wrap: wrap;
        gap: 5px;
        margin-bottom: 14px;
        color: #64748b;
        font-size: 12px;
    }

    .oecs-product-rating strong {
        color: #172033;
    }

    .oecs-product-price-box {
        margin-top: auto;
    }

    .oecs-product-price-label {
        margin-bottom: 3px;
        color: #64748b;
        font-size: 12px;
    }

    .oecs-product-price {
        color: #dc2626;
        font-size: 20px;
        line-height: 1.4;
        font-weight: 800;
        overflow-wrap: anywhere;
    }

    .oecs-product-category {
        margin-top: 10px;
        color: #94a3b8;
        font-size: 12px;
    }

    .oecs-product-footer {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 10px;
        margin-top: 16px;
        padding-top: 13px;
        border-top: 1px solid #edf0f4;
        color: #2563eb;
        font-size: 13px;
        font-weight: 700;
    }

    /* =========================================
       6. EMPTY STATE
       ========================================= */

    .oecs-catalog-empty {
        padding: 70px 22px;
        background: #fff;
        border: 1px dashed #cbd5e1;
        border-radius: 18px;
        text-align: center;
    }

    .oecs-catalog-empty-icon {
        color: #94a3b8;
        font-size: 48px;
    }

    .oecs-catalog-empty h3 {
        color: #172033;
        font-size: 20px;
        font-weight: 750;
        margin: 17px 0 10px;
    }

    .oecs-catalog-empty p {
        max-width: 430px;
        margin: 0 auto 24px;
        font-size: 14px;
        color: #64748b;
    }

    /* =========================================
       7. MOBILE FILTER
       ========================================= */

    .oecs-mobile-filter-button,
    .oecs-filter-close {
        display: none;
    }

    .oecs-filter-backdrop {
        display: none;
    }

    @media (max-width: 991.98px) {

        .oecs-mobile-filter-button {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            min-height: 43px;
        }

        .oecs-filter-close {
            display: inline-flex;
        }

        .oecs-filter-sidebar {
            position: fixed;
            top: 0;
            left: 0;
            bottom: 0;
            width: min(365px, 92vw);
            height: 100dvh;
            max-height: none;
            overflow-y: auto;
            border-radius: 0 18px 18px 0;
            z-index: 1060;
            transform: translateX(-105%);
            visibility: hidden;
            transition:
                transform .25s ease,
                visibility .25s ease;
            box-shadow: 12px 0 38px rgba(15, 23, 42, .15);
        }

        .oecs-filter-sidebar.is-open {
            transform: translateX(0);
            visibility: visible;
        }

        .oecs-filter-backdrop.is-open {
            display: block;
            position: fixed;
            inset: 0;
            z-index: 1055;
            background: rgba(15, 23, 42, .5);
        }
    }

    @media (max-width: 575.98px) {

        .oecs-catalog {
            padding: 19px 0 45px;
        }

        .oecs-result-title {
            font-size: 18px;
        }

        .oecs-catalog-sort {
            min-width: 150px;
            max-width: 190px;
            font-size: 13px;
        }

        .oecs-product-image {
            padding: 11px;
        }

        .oecs-product-body {
            padding: 12px;
        }

        .oecs-product-brand {
            font-size: 11px;
        }

        .oecs-product-name {
            font-size: 13px;
            min-height: 41px;
        }

        .oecs-product-rating {
            font-size: 11px;
        }

        .oecs-product-price {
            font-size: 16px;
        }

        .oecs-product-footer {
            font-size: 12px;
        }

        .oecs-product-category {
            font-size: 11px;
        }
    }

    @media (prefers-reduced-motion: reduce) {

        .oecs-product-card,
        .oecs-product-image img,
        .oecs-filter-sidebar {
            transition: none;
        }
    }
</style>

<div class="oecs-catalog">

    <div class="container">

        <%-- ===================================
             1. BREADCRUMB
             =================================== --%>

        <nav class="oecs-catalog-breadcrumb"
             aria-label="breadcrumb">

            <ol class="breadcrumb mb-0">

                <li class="breadcrumb-item">

                    <a href="${pageContext.request.contextPath}/home">
                        Trang chủ
                    </a>

                </li>

                <li class="breadcrumb-item active"
                    aria-current="page">

                    Sản phẩm

                </li>

            </ol>

        </nav>

        <%-- ===================================
             2. PAGE HEADER
             =================================== --%>

        <div class="oecs-catalog-heading">

            <h1 class="oecs-catalog-title">
                Sản phẩm công nghệ
            </h1>

            <p class="oecs-catalog-description">
                Khám phá các sản phẩm phù hợp với nhu cầu của bạn.
            </p>

        </div>

        <%-- ===================================
             3. FILTER FORM
             =================================== --%>

        <form id="catalogFilterForm"
              action="${pageContext.request.contextPath}/shop"
              method="GET">

            <%-- GIỮ KEYWORD --%>

            <c:if test="${not empty searchKeyword}">

                <input type="hidden"
                       name="keyword"
                       value="${fn:escapeXml(searchKeyword)}">

            </c:if>

            <div class="row g-4">

                <%-- ===========================
                     3.1. FILTER SIDEBAR
                     =========================== --%>

                <div class="col-lg-3">

                    <div id="catalogFilterBackdrop"
                         class="oecs-filter-backdrop"
                         aria-hidden="true">
                    </div>

                    <aside class="oecs-filter-sidebar"
                           id="catalogSidebar"
                           aria-label="Bộ lọc sản phẩm">

                        <div class="oecs-filter-header">

                            <h2>

                                <i class="bi bi-sliders me-2"></i>

                                Bộ lọc

                            </h2>

                            <button type="button"
                                    id="closeCatalogFilter"
                                    class="btn btn-sm btn-outline-secondary oecs-filter-close"
                                    aria-label="Đóng bộ lọc">

                                <i class="bi bi-x-lg"></i>

                            </button>

                        </div>

                        <%-- =======================
                             DANH MỤC
                             ======================= --%>

                        <div class="oecs-filter-section">

                            <h3 class="oecs-filter-title">
                                Danh mục sản phẩm
                            </h3>

                            <div class="oecs-filter-options">

                                <c:choose>

                                    <c:when test="${not empty filterCategories}">

                                        <c:forEach items="${filterCategories}"
                                                   var="category">

                                            <c:set var="catChecked"
                                                   value="${false}"/>

                                            <c:forEach items="${selectedCats}"
                                                       var="selectedCat">

                                                <c:if test="${selectedCat eq category.categoryId}">

                                                    <c:set var="catChecked"
                                                           value="${true}"/>

                                                </c:if>

                                            </c:forEach>

                                            <label class="oecs-filter-option"
                                                   for="filterCat${category.categoryId}">

                                                <input type="checkbox"
                                                       name="categoryId"
                                                       id="filterCat${category.categoryId}"
                                                       value="${category.categoryId}"
                                                       ${catChecked ? 'checked' : ''}>

                                                <span>

                                                    <c:out value="${category.categoryName}"/>

                                                </span>

                                            </label>

                                        </c:forEach>

                                    </c:when>

                                    <c:otherwise>

                                        <p class="text-muted small mb-0">
                                            Chưa có danh mục sản phẩm.
                                        </p>

                                    </c:otherwise>

                                </c:choose>

                            </div>

                        </div>

                        <%-- =======================
                             MỨC GIÁ
                             ======================= --%>

                        <div class="oecs-filter-section">

                            <h3 class="oecs-filter-title">
                                Khoảng giá
                            </h3>

                            <div class="oecs-filter-options">

                                <label class="oecs-filter-option"
                                       for="priceUnder5">

                                    <input type="radio"
                                           name="priceRange"
                                           id="priceUnder5"
                                           value="under5"
                                           ${selectedPrice eq 'under5' ? 'checked' : ''}>

                                    <span>Dưới 5 triệu</span>

                                </label>

                                <label class="oecs-filter-option"
                                       for="price5to15">

                                    <input type="radio"
                                           name="priceRange"
                                           id="price5to15"
                                           value="5to15"
                                           ${selectedPrice eq '5to15' ? 'checked' : ''}>

                                    <span>Từ 5 đến 15 triệu</span>

                                </label>

                                <label class="oecs-filter-option"
                                       for="priceOver15">

                                    <input type="radio"
                                           name="priceRange"
                                           id="priceOver15"
                                           value="over15"
                                           ${selectedPrice eq 'over15' ? 'checked' : ''}>

                                    <span>Trên 15 triệu</span>

                                </label>

                            </div>

                        </div>

                        <%-- =======================
                             ĐÁNH GIÁ
                             ======================= --%>

                        <div class="oecs-filter-section">

                            <h3 class="oecs-filter-title">
                                Mức đánh giá
                            </h3>

                            <div class="oecs-filter-options">

                                <c:forEach begin="1"
                                           end="5"
                                           var="index">

                                    <c:set var="ratingValue"
                                           value="${6 - index}"/>

                                    <label class="oecs-filter-option"
                                           for="rating${ratingValue}">

                                        <input type="radio"
                                               name="minRating"
                                               id="rating${ratingValue}"
                                               value="${ratingValue}"
                                               ${selectedRating eq ratingValue ? 'checked' : ''}>

                                        <span>

                                            <span class="oecs-filter-stars"
                                                  aria-hidden="true">

                                                <c:forEach begin="1"
                                                           end="5"
                                                           var="star">

                                                    <c:choose>

                                                        <c:when test="${star le ratingValue}">
                                                            ★
                                                        </c:when>

                                                        <c:otherwise>
                                                            ☆
                                                        </c:otherwise>

                                                    </c:choose>

                                                </c:forEach>

                                            </span>

                                            <span class="ms-1">
                                                Mức ${ratingValue} sao
                                            </span>

                                        </span>

                                    </label>

                                </c:forEach>

                            </div>

                        </div>

                        <%-- =======================
                             FILTER ACTIONS
                             ======================= --%>

                        <div class="oecs-filter-actions">

                            <button type="submit"
                                    id="applyCatalogFilters"
                                    class="btn btn-primary oecs-filter-apply">

                                <i class="bi bi-funnel me-1"></i>

                                Áp dụng bộ lọc

                            </button>

                            <a href="${fn:escapeXml(resetFilterUrl)}"
                               class="oecs-filter-reset">

                                <i class="bi bi-arrow-counterclockwise"></i>

                                Xóa bộ lọc

                            </a>

                        </div>

                    </aside>

                </div>

                <%-- ===========================
                     3.2. RESULTS
                     =========================== --%>

                <div class="col-lg-9">

                    <%-- TOOLBAR --%>

                    <div class="oecs-catalog-toolbar">

                        <div>

                            <h2 class="oecs-result-title">
                                Danh sách sản phẩm
                            </h2>

                            <p class="oecs-result-count">

                                Hiển thị

                                <strong>
                                    ${fn:length(catalog)}
                                </strong>

                                sản phẩm

                            </p>

                            <c:if test="${not empty searchKeyword}">

                                <p class="small text-muted mt-2 mb-0">

                                    Kết quả tìm kiếm cho:

                                    <strong class="text-dark">
                                        "<c:out value='${searchKeyword}'/>"
                                    </strong>

                                </p>

                            </c:if>

                        </div>

                        <div class="d-flex align-items-center gap-2">

                            <button type="button"
                                    id="openCatalogFilter"
                                    class="btn btn-outline-primary oecs-mobile-filter-button"
                                    aria-controls="catalogSidebar"
                                    aria-expanded="false">

                                <i class="bi bi-funnel"></i>

                                Bộ lọc

                            </button>

                            <select name="sort"
                                    id="catalogSort"
                                    class="form-select oecs-catalog-sort"
                                    aria-label="Sắp xếp sản phẩm">

                                <option value="newest"
                                        ${empty selectedSort or selectedSort eq 'newest' ? 'selected' : ''}>

                                    Mới nhất

                                </option>

                                <option value="priceAsc"
                                        ${selectedSort eq 'priceAsc' ? 'selected' : ''}>

                                    Giá thấp đến cao

                                </option>

                                <option value="priceDesc"
                                        ${selectedSort eq 'priceDesc' ? 'selected' : ''}>

                                    Giá cao đến thấp

                                </option>

                                <option value="ratingDesc"
                                        ${selectedSort eq 'ratingDesc' ? 'selected' : ''}>

                                    Đánh giá cao nhất

                                </option>

                            </select>

                        </div>

                    </div>

                    <%-- ===========================
                         ACTIVE FILTERS
                         =========================== --%>

                    <c:if test="${hasActiveFilters}">

                        <div class="oecs-active-filters"
                             aria-label="Bộ lọc đang áp dụng">

                            <span class="oecs-active-filters-label">
                                Đang lọc:
                            </span>

                            <%-- CATEGORY CHIPS --%>

                            <c:forEach items="${selectedCats}"
                                       var="selectedCat">

                                <c:set var="selectedCategoryName"
                                       value=""/>

                                <c:forEach items="${filterCategories}"
                                           var="category">

                                    <c:if test="${selectedCat eq category.categoryId}">

                                        <c:set var="selectedCategoryName"
                                               value="${category.categoryName}"/>

                                    </c:if>

                                </c:forEach>

                                <c:if test="${not empty selectedCategoryName}">

                                    <button type="button"
                                            class="oecs-filter-chip"
                                            data-filter-remove="categoryId"
                                            data-filter-value="${fn:escapeXml(selectedCat)}"
                                            aria-label="Xóa bộ lọc danh mục">

                                        <span>

                                            <c:out value="${selectedCategoryName}"/>

                                        </span>

                                        <i class="bi bi-x-lg"
                                           aria-hidden="true"></i>

                                    </button>

                                </c:if>

                            </c:forEach>

                            <%-- PRICE CHIP --%>

                            <c:if test="${not empty selectedPrice}">

                                <button type="button"
                                        class="oecs-filter-chip"
                                        data-filter-remove="priceRange"
                                        aria-label="Xóa bộ lọc giá">

                                    <span>

                                        <c:choose>

                                            <c:when test="${selectedPrice eq 'under5'}">
                                                Dưới 5 triệu
                                            </c:when>

                                            <c:when test="${selectedPrice eq '5to15'}">
                                                5–15 triệu
                                            </c:when>

                                            <c:when test="${selectedPrice eq 'over15'}">
                                                Trên 15 triệu
                                            </c:when>

                                            <c:otherwise>
                                                Mức giá đã chọn
                                            </c:otherwise>

                                        </c:choose>

                                    </span>

                                    <i class="bi bi-x-lg"
                                       aria-hidden="true"></i>

                                </button>

                            </c:if>

                            <%-- RATING CHIP --%>

                            <c:if test="${not empty selectedRating}">

                                <button type="button"
                                        class="oecs-filter-chip"
                                        data-filter-remove="minRating"
                                        aria-label="Xóa bộ lọc đánh giá">

                                    <span>
                                        Mức <c:out value="${selectedRating}"/> sao
                                    </span>

                                    <i class="bi bi-x-lg"
                                       aria-hidden="true"></i>

                                </button>

                            </c:if>

                            <a class="oecs-clear-all"
                               href="${fn:escapeXml(resetFilterUrl)}">

                                Xóa tất cả

                            </a>

                        </div>

                    </c:if>

                    <%-- ===========================
                         PRODUCT GRID
                         =========================== --%>

                    <div class="row g-3 g-md-4">

                        <c:choose>

                            <c:when test="${not empty catalog}">

                                <c:forEach items="${catalog}"
                                           var="item">

                                    <div class="col-6 col-md-4">

                                        <%-- DETAIL URL --%>

                                        <c:url var="detailUrl"
                                               value="/shop">

                                            <c:param name="action"
                                                     value="detail"/>

                                            <c:param name="id"
                                                     value="${item.productId}"/>

                                        </c:url>

                                        <%-- IMAGE URL --%>

                                        <c:set var="productImageUrl"
                                               value=""/>

                                        <c:if test="${not empty item.imageUrl}">

                                            <c:choose>

                                                <c:when test="${fn:startsWith(item.imageUrl, 'https://')
                                                                or fn:startsWith(item.imageUrl, 'http://')}">

                                                        <c:set var="productImageUrl"
                                                               value="${item.imageUrl}"/>

                                                </c:when>

                                                <c:otherwise>

                                                    <c:set var="localImagePath"
                                                           value="${item.imageUrl}"/>

                                                    <c:if test="${not fn:startsWith(localImagePath, '/')}">

                                                        <c:set var="localImagePath"
                                                               value="/${localImagePath}"/>

                                                    </c:if>

                                                    <c:url var="productImageUrl"
                                                           value="${localImagePath}"/>

                                                </c:otherwise>

                                            </c:choose>

                                        </c:if>

                                        <%-- PRODUCT CARD --%>

                                        <a class="oecs-product-card"
                                           href="${fn:escapeXml(detailUrl)}">

                                            <div class="oecs-product-image">

                                                <c:choose>

                                                    <c:when test="${not empty productImageUrl}">

                                                        <img src="${fn:escapeXml(productImageUrl)}"
                                                             alt="${fn:escapeXml(item.productName)}"
                                                             loading="lazy"
                                                             onerror="this.style.display='none'; this.nextElementSibling.style.display='block';">

                                                        <i class="bi bi-image oecs-product-placeholder"
                                                           style="display:none;"
                                                           aria-hidden="true"></i>

                                                    </c:when>

                                                    <c:otherwise>

                                                        <i class="bi bi-image oecs-product-placeholder"
                                                           aria-hidden="true"></i>

                                                    </c:otherwise>

                                                </c:choose>

                                            </div>

                                            <%-- CARD BODY --%>

                                            <div class="oecs-product-body">

                                                <div class="oecs-product-brand">

                                                    <c:out value="${item.brand.brandName}"/>

                                                </div>

                                                <h3 class="oecs-product-name">

                                                    <c:out value="${item.productName}"/>

                                                </h3>

                                                <%-- RATING --%>

                                                <div class="oecs-product-rating">

                                                    <c:choose>

                                                        <c:when test="${item.reviewCount gt 0}">

                                                            <i class="bi bi-star-fill text-warning"
                                                               aria-hidden="true"></i>

                                                            <strong>

                                                                <fmt:formatNumber
                                                                    value="${item.averageRating}"
                                                                    minFractionDigits="1"
                                                                    maxFractionDigits="1"/>

                                                            </strong>

                                                            <span>

                                                                (<c:out value="${item.reviewCount}"/> đánh giá)

                                                            </span>

                                                        </c:when>

                                                        <c:otherwise>

                                                            <i class="bi bi-star text-muted"
                                                               aria-hidden="true"></i>

                                                            <span>
                                                                Chưa có đánh giá
                                                            </span>

                                                        </c:otherwise>

                                                    </c:choose>

                                                </div>

                                                <%-- PRICE --%>

                                                <div class="oecs-product-price-box">

                                                    <c:choose>

                                                        <c:when test="${item.minPrice gt 0}">

                                                            <div class="oecs-product-price-label">
                                                                Giá từ
                                                            </div>

                                                            <div class="oecs-product-price">

                                                                <fmt:formatNumber
                                                                    value="${item.minPrice}"
                                                                    pattern="#,##0"/>

                                                                ₫

                                                            </div>

                                                        </c:when>

                                                        <c:otherwise>

                                                            <div class="text-muted small">
                                                                Đang cập nhật giá
                                                            </div>

                                                        </c:otherwise>

                                                    </c:choose>

                                                </div>

                                                <%-- CATEGORY --%>

                                                <div class="oecs-product-category">

                                                    <i class="bi bi-tag me-1"></i>

                                                    <c:out value="${item.category.categoryName}"/>

                                                </div>

                                                <%-- CARD FOOTER --%>

                                                <div class="oecs-product-footer">

                                                    <span>
                                                        Xem chi tiết
                                                    </span>

                                                    <i class="bi bi-arrow-right"
                                                       aria-hidden="true"></i>

                                                </div>

                                            </div>

                                        </a>

                                    </div>

                                </c:forEach>

                            </c:when>

                            <c:otherwise>

                                <%-- EMPTY STATE --%>

                                <div class="col-12">

                                    <div class="oecs-catalog-empty">

                                        <i class="bi bi-search oecs-catalog-empty-icon"
                                           aria-hidden="true"></i>

                                        <h3>
                                            Không tìm thấy sản phẩm phù hợp
                                        </h3>

                                        <p>

                                            Hãy thử thay đổi từ khóa tìm kiếm,
                                            danh mục, khoảng giá hoặc mức đánh giá.

                                        </p>

                                        <a href="${fn:escapeXml(resetFilterUrl)}"
                                           class="btn btn-primary rounded-pill px-4 py-2">

                                            <i class="bi bi-arrow-counterclockwise me-1"></i>

                                            Xóa bộ lọc và thử lại

                                        </a>

                                    </div>

                                </div>

                            </c:otherwise>

                        </c:choose>

                    </div>

                </div>

            </div>

        </form>

    </div>

</div>

<script>
    document.addEventListener("DOMContentLoaded", function () {

        // =========================================
        // 1. ELEMENT REFERENCES
        // =========================================

        const form =
                document.getElementById("catalogFilterForm");

        const sidebar =
                document.getElementById("catalogSidebar");

        const backdrop =
                document.getElementById("catalogFilterBackdrop");

        const openButton =
                document.getElementById("openCatalogFilter");

        const closeButton =
                document.getElementById("closeCatalogFilter");

        const sortSelect =
                document.getElementById("catalogSort");

        const applyButton =
                document.getElementById("applyCatalogFilters");

        let previousFocus = null;

        // =========================================
        // 2. OPEN MOBILE FILTER
        // =========================================

        function openFilter() {

            if (!sidebar || !backdrop) {
                return;
            }

            previousFocus = document.activeElement;

            sidebar.classList.add("is-open");
            backdrop.classList.add("is-open");

            if (openButton) {

                openButton.setAttribute(
                        "aria-expanded",
                        "true"
                        );
            }

            document.body.style.overflow = "hidden";

            if (closeButton) {
                closeButton.focus();
            }
        }

        // =========================================
        // 3. CLOSE MOBILE FILTER
        // =========================================

        function closeFilter() {

            if (!sidebar || !backdrop) {
                return;
            }

            sidebar.classList.remove("is-open");
            backdrop.classList.remove("is-open");

            if (openButton) {

                openButton.setAttribute(
                        "aria-expanded",
                        "false"
                        );
            }

            document.body.style.overflow = "";

            if (previousFocus &&
                    typeof previousFocus.focus === "function") {

                previousFocus.focus();
            }
        }

        if (openButton) {

            openButton.addEventListener(
                    "click",
                    openFilter
                    );
        }

        if (closeButton) {

            closeButton.addEventListener(
                    "click",
                    closeFilter
                    );
        }

        if (backdrop) {

            backdrop.addEventListener(
                    "click",
                    closeFilter
                    );
        }

        document.addEventListener(
                "keydown",
                function (event) {

                    if (event.key === "Escape"
                            && sidebar
                            && sidebar.classList.contains("is-open")) {

                        closeFilter();
                    }
                }
        );

        window.addEventListener(
                "resize",
                function () {

                    if (window.innerWidth >= 992
                            && sidebar
                            && sidebar.classList.contains("is-open")) {

                        closeFilter();
                    }
                }
        );

        // =========================================
        // 4. SORT: KEEP FILTERS
        // =========================================

        if (sortSelect && form) {

            sortSelect.addEventListener(
                    "change",
                    function () {

                        form.requestSubmit();
                    }
            );
        }

        // =========================================
        // 5. REMOVE ONE FILTER CHIP
        // =========================================

        document.querySelectorAll(
                "[data-filter-remove]"
                ).forEach(function (button) {

            button.addEventListener(
                    "click",
                    function () {

                        const key =
                                this.dataset.filterRemove;

                        if (!key) {
                            return;
                        }

                        const params =
                                new URLSearchParams(
                                        window.location.search
                                        );

                        if (key === "categoryId") {

                            const removedValue =
                                    this.dataset.filterValue;

                            const values =
                                    params.getAll("categoryId");

                            params.delete("categoryId");

                            values.forEach(function (value) {

                                if (value !== removedValue) {

                                    params.append(
                                            "categoryId",
                                            value
                                            );
                                }
                            });

                        } else {

                            params.delete(key);
                        }

                        const query =
                                params.toString();

                        window.location.href =
                                window.location.pathname
                                + (query ? "?" + query : "");
                    }
            );
        });

        // =========================================
        // 6. PREVENT DOUBLE SUBMIT
        // =========================================

        if (form) {

            form.addEventListener(
                    "submit",
                    function () {

                        if (!form.checkValidity()) {
                            return;
                        }

                        if (applyButton) {

                            applyButton.disabled = true;

                            applyButton.innerHTML =
                                    '<span class="spinner-border '
                                    + 'spinner-border-sm me-2" '
                                    + 'aria-hidden="true"></span>'
                                    + 'Đang lọc...';
                        }
                    }
            );
        }
    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>
