<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html>
    <head>
        <title>Cửa hàng OECS</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
            .product-card {
                transition: transform 0.2s;
            }
            .product-card:hover {
                transform: translateY(-5px);
                box-shadow: 0 .5rem 1rem rgba(0,0,0,.15)!important;
            }
            .product-image {
                height: 200px;
                object-fit: contain;
                padding: 10px;
            }
        </style>
    </head>
    <body class="bg-light">

        <!-- Navbar Đơn Giản -->
        <nav class="navbar navbar-dark bg-dark mb-4">
            <div class="container">
                <a class="navbar-brand fw-bold" href="${pageContext.request.contextPath}/shop">OECS STORE</a>
            </div>
        </nav>

        <div class="container mb-5">
            <h3 class="fw-bold mb-4">Sản Phẩm Nổi Bật</h3>

            <div class="row row-cols-1 row-cols-md-3 row-cols-lg-4 g-4">
                <c:forEach items="${products}" var="p">
                    <div class="col">
                        <div class="card h-100 shadow-sm border-0 product-card">
                            <!-- Ảnh sản phẩm -->
                            <c:choose>
                                <c:when test="${not empty p.imageUrl}">
                                    <img src="${p.imageUrl}" class="card-img-top product-image" alt="${p.productName}">
                                </c:when>
                                <c:otherwise>
                                    <img src="https://via.placeholder.com/300x200?text=No+Image" class="card-img-top product-image" alt="No image">
                                </c:otherwise>
                            </c:choose>

                            <div class="card-body d-flex flex-column">
                                <div class="small text-muted mb-1">${p.brand.brandName} - ${p.category.categoryName}</div>
                                <h5 class="card-title text-dark fw-bold">${p.productName}</h5>
                                <!-- Giá -->
                                <div class="mt-auto">
                                    <h5 class="text-danger fw-bold mb-3">
                                        <fmt:formatNumber value="${p.price}" pattern="#,##0"/> đ
                                    </h5>
                                    <a href="${pageContext.request.contextPath}/shop?action=detail&id=${p.productId}" class="btn btn-primary w-100">
                                        Xem chi tiết
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </c:forEach>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>