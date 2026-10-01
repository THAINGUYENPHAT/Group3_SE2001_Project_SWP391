<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@include file="/WEB-INF/include/header.jsp"%>

<style>
    .catalog-page {
        background: #f5f7fb;
        min-height: 100vh;
        padding: 40px 0;
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
        background: #f8f9fa;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 50px;
        color: #adb5bd;
    }
    .product-info {
        padding: 20px;
        display: flex;
        flex-direction: column;
        flex: 1;
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
        margin-bottom: 10px;
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }
    .product-price {
        font-size: 18px;
        font-weight: 800;
        color: #e53935;
        margin-top: auto;
    }
</style>

<div class="catalog-page">
    <div class="container">
        <!-- Breadcrumb -->
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="${pageContext.request.contextPath}/home" class="text-decoration-none">Trang chủ</a></li>
                <li class="breadcrumb-item active" aria-current="page">Tất cả sản phẩm</li>
            </ol>
        </nav>

        <div class="row">
            <!-- Sidebar Lọc (UI tham khảo) -->
            <div class="col-lg-3 d-none d-lg-block">
                <div class="card border-0 shadow-sm rounded-4 p-4 sticky-top" style="top: 20px;">
                    <h5 class="fw-bold mb-3">Danh mục</h5>
                    <div class="form-check mb-2"><input class="form-check-input" type="checkbox"><label class="form-check-label">Điện thoại</label></div>
                    <div class="form-check mb-2"><input class="form-check-input" type="checkbox"><label class="form-check-label">Laptop</label></div>
                    <div class="form-check mb-4"><input class="form-check-input" type="checkbox"><label class="form-check-label">Phụ kiện</label></div>

                    <h5 class="fw-bold mb-3">Mức giá</h5>
                    <div class="form-check mb-2"><input class="form-check-input" type="radio" name="price"><label class="form-check-label">Dưới 5 triệu</label></div>
                    <div class="form-check mb-2"><input class="form-check-input" type="radio" name="price"><label class="form-check-label">5 - 15 triệu</label></div>
                    <div class="form-check mb-2"><input class="form-check-input" type="radio" name="price"><label class="form-check-label">Trên 15 triệu</label></div>

                    <button class="btn btn-primary w-100 mt-3">Lọc sản phẩm</button>
                </div>
            </div>

            <!-- Main Product Grid -->
            <div class="col-lg-9">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h4 class="fw-bold m-0">Sản Phẩm Công Nghệ</h4>
                    <select class="form-select w-auto border-0 shadow-sm">
                        <option>Mới nhất</option>
                        <option>Giá thấp đến cao</option>
                        <option>Giá cao xuống thấp</option>
                    </select>
                </div>

                <div class="row g-4">
                    <c:choose>
                        <c:when test="${not empty catalog}">
                            <c:forEach items="${catalog}" var="item">
                                <div class="col-6 col-md-4">
                                    <a href="${pageContext.request.contextPath}/shop?action=detail&id=${item.productId}" class="product-card">
                                        <div class="product-image">
                                            <i class="bi bi-laptop"></i> <!-- Placeholder hình ảnh -->
                                        </div>
                                        <div class="product-info">
                                            <div class="product-brand">${item.brand.brandName}</div>
                                            <div class="product-name">${item.productName}</div>
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
                                <h5 class="mt-3 text-muted">Chưa có sản phẩm nào</h5>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp"%>