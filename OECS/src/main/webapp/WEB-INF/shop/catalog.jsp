<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@include file="/WEB-INF/include/header.jsp"%>

<style>
    body, html, .catalog-page, .container, .row {
        overflow: visible !important;
    }

    .catalog-page {
        background: #f5f7fb;
        min-height: 100vh;
        padding: 40px 0;
    }

    .custom-sticky-sidebar {
        position: -webkit-sticky;
        position: sticky;
        top: 90px;
        z-index: 1020;
        max-height: calc(100vh - 110px);
        overflow-y: auto;
    }

    .custom-sticky-sidebar::-webkit-scrollbar {
        width: 6px;
    }
    .custom-sticky-sidebar::-webkit-scrollbar-thumb {
        background-color: #dee2e6;
        border-radius: 10px;
    }

    .product-card {
        background: white;
        border-radius: 14px;
        border: 1px solid #e9edf3;
        transition: all 0.2s ease;
        height: 100%;
        display: flex;
        flex-direction: column;
        text-decoration: none;
        color: inherit;
        overflow: hidden;
    }
    .product-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 10px 25px rgba(20,40,70,0.1);
        color: inherit;
    }
    .product-image {
        height: 240px;
        background: #fff;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 50px;
        color: #adb5bd;
        padding: 15px;
    }
    .product-info {
        padding: 20px;
        display: flex;
        flex-direction: column;
        flex: 1;
        border-top: 1px solid #f0f2f5;
    }
    .product-brand {
        font-size: 13px;
        color: #0d6efd;
        font-weight: 600;
        margin-bottom: 5px;
        text-transform: uppercase;
    }
    .product-name {
        font-size: 16px;
        font-weight: 700;
        color: #142b4a;
        margin-bottom: 8px;
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }
    .product-rating {
        font-size: 13px;
        margin-bottom: 10px;
        display: flex;
        align-items: center;
        gap: 4px;
    }
    .product-price {
        font-size: 18px;
        font-weight: 800;
        color: #e53935;
        margin-top: auto;
    }
    .rating-filter-label {
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 3px;
        font-size: 14px;
    }
</style>

<div class="catalog-page">
    <div class="container">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="${pageContext.request.contextPath}/home" class="text-decoration-none">Trang chủ</a></li>
                <li class="breadcrumb-item active" aria-current="page">Tất cả sản phẩm</li>
            </ol>
        </nav>

        <form action="${pageContext.request.contextPath}/shop" method="GET" class="row">

            <c:if test="${not empty searchKeyword}">
                <input type="hidden" name="keyword" value="<c:out value='${searchKeyword}'/>">
            </c:if>

            <div class="col-lg-3 d-none d-lg-block">
                <div class="card border-0 shadow-sm rounded-4 p-4 custom-sticky-sidebar">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h5 class="fw-bold mb-0">Danh mục</h5>
                        <c:if test="${not empty selectedCats or not empty selectedPrice or not empty selectedRating}">
                            <a href="${pageContext.request.contextPath}/shop${not empty searchKeyword ? '?keyword='.concat(searchKeyword) : ''}" class="text-decoration-none small text-danger fw-medium">
                                Xóa lọc
                            </a>
                        </c:if>
                    </div>

                    <div class="form-check mb-2">
                        <input class="form-check-input" type="checkbox" name="categoryId" value="4" id="cat4" ${not empty selectedCats and selectedCats.contains("4") ? 'checked' : ''}>
                        <label class="form-check-label" for="cat4">Điện thoại</label>
                    </div>
                    <div class="form-check mb-2">
                        <input class="form-check-input" type="checkbox" name="categoryId" value="2" id="cat2" ${not empty selectedCats and selectedCats.contains("2") ? 'checked' : ''}>
                        <label class="form-check-label" for="cat2">Laptop</label>
                    </div>
                    <div class="form-check mb-2">
                        <input class="form-check-input" type="checkbox" name="categoryId" value="7" id="cat7" ${not empty selectedCats and selectedCats.contains("7") ? 'checked' : ''}>
                        <label class="form-check-label" for="cat7">Dây sạc</label>
                    </div> 
                    <div class="form-check mb-2">
                        <input class="form-check-input" type="checkbox" name="categoryId" value="6" id="cat6" ${not empty selectedCats and selectedCats.contains("6") ? 'checked' : ''}>
                        <label class="form-check-label" for="cat6">Cục sạc</label>
                    </div> 
                    <div class="form-check mb-2">
                        <input class="form-check-input" type="checkbox" name="categoryId" value="14" id="cat14" ${not empty selectedCats and selectedCats.contains("14") ? 'checked' : ''}>
                        <label class="form-check-label" for="cat14">Smartwatch</label>
                    </div>
                    <div class="form-check mb-2">
                        <input class="form-check-input" type="checkbox" name="categoryId" value="3" id="cat3" ${not empty selectedCats and selectedCats.contains("3") ? 'checked' : ''}>
                        <label class="form-check-label" for="cat3">Phụ kiện</label>
                    </div>
                    <div class="form-check mb-2">
                        <input class="form-check-input" type="checkbox" name="categoryId" value="16" id="cat16" ${not empty selectedCats and selectedCats.contains("16") ? 'checked' : ''}>
                        <label class="form-check-label" for="cat16">Máy ảnh</label>
                    </div>
                    <div class="form-check mb-2">
                        <input class="form-check-input" type="checkbox" name="categoryId" value="5" id="cat5" ${not empty selectedCats and selectedCats.contains("5") ? 'checked' : ''}>
                        <label class="form-check-label" for="cat5">Tai nghe</label>
                    </div>
                    <div class="form-check mb-4">
                        <input class="form-check-input" type="checkbox" name="categoryId" value="11" id="cat11" ${not empty selectedCats and selectedCats.contains("11") ? 'checked' : ''}>
                        <label class="form-check-label" for="cat11">Bàn phím</label>
                    </div>

                    <h5 class="fw-bold mb-3">Mức giá</h5>
                    <div class="form-check mb-2">
                        <input class="form-check-input single-check-price" type="checkbox" name="priceRange" value="under5" id="price1" ${selectedPrice == 'under5' ? 'checked' : ''}>
                        <label class="form-check-label" for="price1">Dưới 5 triệu</label>
                    </div>
                    <div class="form-check mb-2">
                        <input class="form-check-input single-check-price" type="checkbox" name="priceRange" value="5to15" id="price2" ${selectedPrice == '5to15' ? 'checked' : ''}>
                        <label class="form-check-label" for="price2">5 - 15 triệu</label>
                    </div>
                    <div class="form-check mb-4">
                        <input class="form-check-input single-check-price" type="checkbox" name="priceRange" value="over15" id="price3" ${selectedPrice == 'over15' ? 'checked' : ''}>
                        <label class="form-check-label" for="price3">Trên 15 triệu</label>
                    </div>

                    <!-- BỘ LỌC THEO ĐÁNH GIÁ -->
                    <h5 class="fw-bold mb-3">Đánh giá</h5>
                    <div class="form-check mb-2">
                        <input class="form-check-input single-check-rating" type="checkbox" name="minRating" value="5" id="rate5" ${selectedRating == '5' ? 'checked' : ''}>
                        <label class="form-check-label rating-filter-label" for="rate5">
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star-fill text-warning"></i>
                            <span class="ms-1 text-dark">5 sao</span>
                        </label>
                    </div>
                    <div class="form-check mb-2">
                        <input class="form-check-input single-check-rating" type="checkbox" name="minRating" value="4" id="rate4" ${selectedRating == '4' ? 'checked' : ''}>
                        <label class="form-check-label rating-filter-label" for="rate4">
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <span class="ms-1 text-dark">4 sao</span>
                        </label>
                    </div>
                    <div class="form-check mb-2">
                        <input class="form-check-input single-check-rating" type="checkbox" name="minRating" value="3" id="rate3" ${selectedRating == '3' ? 'checked' : ''}>
                        <label class="form-check-label rating-filter-label" for="rate3">
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <span class="ms-1 text-dark">3 sao</span>
                        </label>
                    </div>
                    <div class="form-check mb-2">
                        <input class="form-check-input single-check-rating" type="checkbox" name="minRating" value="2" id="rate2" ${selectedRating == '2' ? 'checked' : ''}>
                        <label class="form-check-label rating-filter-label" for="rate2">
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <span class="ms-1 text-dark">2 sao</span>
                        </label>
                    </div>
                    <div class="form-check mb-3">
                        <input class="form-check-input single-check-rating" type="checkbox" name="minRating" value="1" id="rate1" ${selectedRating == '1' ? 'checked' : ''}>
                        <label class="form-check-label rating-filter-label" for="rate1">
                            <i class="bi bi-star-fill text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <span class="ms-1 text-dark">1 sao</span>
                        </label>
                    </div>

                    <button type="submit" class="btn btn-primary w-100 mt-2">Lọc sản phẩm</button>
                </div>
            </div>

            <div class="col-lg-9">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h4 class="fw-bold m-0">Sản Phẩm Công Nghệ</h4>
                        <c:if test="${not empty searchKeyword}">
                            <div class="text-muted mt-1 fs-6">
                                Kết quả tìm kiếm cho: <strong class="text-dark">"<c:out value='${searchKeyword}'/>"</strong>
                            </div>
                        </c:if>
                    </div>

                    <select name="sort" class="form-select w-auto border-0 shadow-sm" onchange="this.form.submit()">
                        <option value="newest" ${selectedSort == 'newest' ? 'selected' : ''}>Mới nhất</option>
                        <option value="priceAsc" ${selectedSort == 'priceAsc' ? 'selected' : ''}>Giá thấp đến cao</option>
                        <option value="priceDesc" ${selectedSort == 'priceDesc' ? 'selected' : ''}>Giá cao xuống thấp</option>
                        <option value="ratingDesc" ${selectedSort == 'ratingDesc' ? 'selected' : ''}>Đánh giá cao nhất</option>
                    </select>
                </div>

                <div class="row g-4">
                    <c:choose>
                        <c:when test="${not empty catalog}">
                            <c:forEach items="${catalog}" var="item">
                                <div class="col-6 col-md-4">
                                    <a href="${pageContext.request.contextPath}/shop?action=detail&id=${item.productId}" class="product-card">
                                        <div class="product-image">
                                            <c:choose>
                                                <c:when test="${not empty item.imageUrl}">
                                                    <img src="${pageContext.request.contextPath}/${item.imageUrl}" alt="<c:out value='${item.productName}'/>" class="img-fluid" style="max-height: 100%; object-fit: contain;">
                                                </c:when>
                                                <c:otherwise>
                                                    <i class="bi bi-image text-muted"></i>
                                                </c:otherwise>
                                            </c:choose>
                                        </div>
                                        <div class="product-info">
                                            <div class="product-brand"><c:out value="${item.brand.brandName}"/></div>
                                            <div class="product-name"><c:out value="${item.productName}"/></div>

                                            <div class="product-rating">
                                                <c:choose>
                                                    <c:when test="${item.reviewCount > 0}">
                                                        <i class="bi bi-star-fill text-warning"></i>
                                                        <span class="fw-bold text-dark">
                                                            <fmt:formatNumber value="${item.averageRating}" maxFractionDigits="1" minFractionDigits="1"/>
                                                        </span>
                                                        <span class="text-muted">(${item.reviewCount} đánh giá)</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <i class="bi bi-star text-muted"></i>
                                                        <span class="text-muted">Chưa có đánh giá</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </div>

                                            <div class="product-price">
                                                <c:choose>
                                                    <c:when test="${item.minPrice > 0}">
                                                        Từ <fmt:formatNumber value="${item.minPrice}" type="number" maxFractionDigits="0"/> đ
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="text-muted fs-6">Đang cập nhật giá</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </div>
                                        </div>
                                    </a>
                                </div>
                            </c:forEach>
                        </c:when>
                        <c:otherwise>
                            <div class="col-12 text-center py-5">
                                <i class="bi bi-box-seam fs-1 text-muted"></i>
                                <h5 class="mt-3 text-muted">Không tìm thấy sản phẩm phù hợp</h5>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </form> 
    </div>
</div>

<script>
    document.addEventListener("DOMContentLoaded", function () {
        function setupSingleCheck(selector) {
            const checkboxes = document.querySelectorAll(selector);
            checkboxes.forEach(cb => {
                cb.addEventListener('change', function () {
                    if (this.checked) {
                        checkboxes.forEach(other => {
                            if (other !== this)
                                other.checked = false;
                        });
                    }
                });
            });
        }
        setupSingleCheck('.single-check-price');
        setupSingleCheck('.single-check-rating');
    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>