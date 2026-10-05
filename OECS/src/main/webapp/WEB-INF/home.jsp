<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<style>
    /* =========================================================
       HOME PAGE
       ========================================================= */

    .home-page {
        background: #f5f7fb;
        min-height: 100vh;
        padding-bottom: 60px;
    }

    /* =========================================================
       HERO
       ========================================================= */

    .home-hero {
        position: relative;
        height: 300px;
        border-radius: 18px;
        overflow: hidden;

        background-image:
            linear-gradient(
            90deg,
            rgba(3, 17, 38, 0.94) 0%,
            rgba(3, 17, 38, 0.75) 45%,
            rgba(3, 17, 38, 0.20) 100%
            ),
            url("${pageContext.request.contextPath}/assets/images/home-hero.png");

        background-size: cover;
        background-position: center;

        display: flex;
        align-items: center;
    }

    .home-hero-content {
        position: relative;
        z-index: 2;
        color: white;
        max-width: 560px;
        padding: 30px 45px;
    }

    .home-hero-title {
        font-size: 34px;
        line-height: 1.15;
        font-weight: 800;
        margin-bottom: 12px;
    }

    .home-hero-description {
        font-size: 15px;
        line-height: 1.5;
        color: rgba(255,255,255,0.80);
        max-width: 460px;
        margin-bottom: 18px;
    }

    .home-hero-button {
        display: inline-flex;
        align-items: center;
        gap: 8px;

        background: #0d6efd;
        color: white;

        padding: 11px 20px;
        border-radius: 8px;

        font-size: 15px;
        font-weight: 600;

        text-decoration: none;

        transition: all 0.2s ease;
    }

    .home-hero-button:hover {
        background: #0b5ed7;
        color: white;
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(13, 110, 253, 0.35);
    }

    /* =========================================================
       SERVICE BAR
       ========================================================= */

    .service-bar {
        background: white;
        border-radius: 14px;

        margin-top: -25px;

        position: relative;
        z-index: 5;

        padding: 16px 20px;

        box-shadow: 0 6px 20px rgba(20, 40, 70, 0.07);
    }

    .service-item {
        display: flex;
        align-items: center;
        gap: 12px;

        min-height: 52px;
    }

    .service-icon {
        width: 42px;
        height: 42px;

        display: flex;
        align-items: center;
        justify-content: center;

        border-radius: 50%;

        background: #f0f6ff;
        color: #0d6efd;

        font-size: 19px;
        flex-shrink: 0;
    }

    .service-title {
        font-size: 14px;
        font-weight: 700;
        color: #142b4a;
        margin-bottom: 2px;
    }

    .service-description {
        font-size: 12px;
        color: #8997aa;
        margin: 0;
    }

    .service-divider {
        border-right: 1px solid #edf0f5;
    }

    /* =========================================================
       SECTION
       ========================================================= */

    .home-section {
        margin-top: 55px;
    }

    .section-header {
        display: flex;
        align-items: end;
        justify-content: space-between;

        margin-bottom: 25px;
    }

    .section-title {
        font-size: 30px;
        font-weight: 800;
        color: #142b4a;
        margin-bottom: 5px;
    }

    .section-description {
        color: #8290a5;
        margin: 0;
        font-size: 15px;
    }

    .section-link {
        color: #0d6efd;
        text-decoration: none;
        font-weight: 600;

        display: flex;
        align-items: center;
        gap: 8px;
    }

    .section-link:hover {
        color: #0b5ed7;
    }

    /* =========================================================
       CATEGORY
       ========================================================= */

    .category-card {
        position: relative;
        height: 145px;

        border-radius: 14px;
        overflow: hidden;

        padding: 18px;

        text-decoration: none;
        color: #142b4a;

        display: flex;
        align-items: end;

        transition: all 0.2s ease;
    }
    .category-card:hover {
        transform: translateY(-6px);
        box-shadow: 0 12px 30px rgba(20, 40, 70, 0.12);
        color: #142b4a;
    }

    .category-card::after {
        content: "";

        position: absolute;
        inset: 0;

        background: linear-gradient(
            to top,
            rgba(255,255,255,0.92),
            rgba(255,255,255,0.15)
            );
    }

    .category-content {
        position: relative;
        z-index: 2;
    }

    .category-name {
        font-size: 16px;
        font-weight: 700;
        margin-bottom: 6px;
    }

    .category-arrow {
        width: 34px;
        height: 34px;

        display: flex;
        align-items: center;
        justify-content: center;

        background: white;
        border-radius: 50%;

        color: #0d6efd;

        box-shadow: 0 4px 12px rgba(0,0,0,0.08);
    }

    .category-phone {
        background:
            linear-gradient(rgba(225,239,255,0.88), rgba(225,239,255,0.88)),
            url("https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=700&q=80");
        background-size: cover;
        background-position: center;
    }

    .category-laptop {
        background:
            linear-gradient(rgba(235,232,255,0.88), rgba(235,232,255,0.88)),
            url("https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=700&q=80");
        background-size: cover;
        background-position: center;
    }

    .category-accessory {
        background:
            linear-gradient(rgba(224,248,247,0.88), rgba(224,248,247,0.88)),
            url("https://images.unsplash.com/photo-1606220945770-b5b6c2c55bf1?auto=format&fit=crop&w=700&q=80");
        background-size: cover;
        background-position: center;
    }

    .category-watch {
        background:
            linear-gradient(rgba(255,231,235,0.88), rgba(255,231,235,0.88)),
            url("https://images.unsplash.com/photo-1546868871-7041f2a55e12?auto=format&fit=crop&w=700&q=80");
        background-size: cover;
        background-position: center;
    }

    .category-headphone {
        background:
            linear-gradient(rgba(255,239,225,0.88), rgba(255,239,225,0.88)),
            url("https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=700&q=80");
        background-size: cover;
        background-position: center;
    }

    .category-camera {
        background:
            linear-gradient(rgba(235,232,255,0.88), rgba(235,232,255,0.88)),
            url("https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=700&q=80");
        background-size: cover;
        background-position: center;
    }

    /* =========================================================
       PRODUCT
       ========================================================= */

    .product-card {
        background: white;
        border-radius: 14px;
        overflow: hidden;

        border: 1px solid #e9edf3;

        transition: all 0.2s ease;
        height: 100%;

        display: flex;
        flex-direction: column;
    }

    .product-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 8px 25px rgba(20, 40, 70, 0.10);
    }

    .product-image {
        height: 230px;

        background: #f7f9fc;

        display: flex;
        align-items: center;
        justify-content: center;

        overflow: hidden;

        color: #b7c1d0;
        font-size: 45px;
    }

    .product-image img {
        width: 100%;
        height: 100%;

        object-fit: contain;

        padding: 20px;

        transition: transform 0.25s ease;
    }

    .product-card:hover .product-image img {
        transform: scale(1.04);
    }

    .product-info {
        padding: 16px;

        display: flex;
        flex-direction: column;

        flex: 1;
    }

    .product-brand {
        font-size: 12px;
        color: #0d6efd;
        font-weight: 600;

        margin-bottom: 4px;
    }

    .product-name {
        font-size: 16px;
        font-weight: 700;
        color: #142b4a;

        margin-bottom: 7px;

        line-height: 1.35;

        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }

    .product-description {
        font-size: 13px;
        color: #7d8ca2;

        line-height: 1.45;

        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;

        overflow: hidden;

        min-height: 38px;

        margin-bottom: 14px;
    }

    .product-bottom {
        margin-top: auto;

        display: flex;
        align-items: center;
        justify-content: space-between;

        padding-top: 12px;

        border-top: 1px solid #f0f2f5;
    }

    .product-price {
        font-size: 17px;
        font-weight: 800;

        color: #e53935;
    }

    .product-stock {
        font-size: 12px;

        color: #198754;

        margin-top: 3px;
    }

    .product-stock i {
        margin-right: 3px;
    }

    .product-detail-btn {
        width: 36px;
        height: 36px;

        display: flex;
        align-items: center;
        justify-content: center;

        border-radius: 9px;

        background: #0d6efd;
        color: white;

        text-decoration: none;

        transition: 0.2s ease;
    }

    .product-detail-btn:hover {
        background: #0b5ed7;
        color: white;
    }

    /* =========================================================
       PROMOTION BANNER
       ========================================================= */

    .promo-banner {
        position: relative;

        min-height: 240px;

        border-radius: 25px;
        overflow: hidden;

        background:
            linear-gradient(
            90deg,
            rgba(5, 22, 48, 0.95),
            rgba(5, 22, 48, 0.55),
            rgba(5, 22, 48, 0.20)
            ),
            url("https://images.unsplash.com/photo-1550745165-9bc0b252726f?auto=format&fit=crop&w=1400&q=85");

        background-size: cover;
        background-position: center;

        display: flex;
        align-items: center;

        padding: 45px;
    }

    .promo-content {
        color: white;
        max-width: 600px;
    }

    .promo-content h3 {
        font-size: 30px;
        font-weight: 800;
        margin-bottom: 10px;
    }

    .promo-content p {
        color: rgba(255,255,255,0.78);
        margin-bottom: 20px;
    }
    /* =========================================================
   ADMIN SHORTCUT
   ========================================================= */

    .admin-shortcut {
        margin-top: 28px;
    }

    .admin-voucher-card {
        display: inline-flex;
        align-items: center;
        gap: 14px;

        padding: 15px 20px;

        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 14px;

        text-decoration: none;
        color: #142b4a;

        box-shadow: 0 4px 15px rgba(20, 40, 70, 0.06);

        transition: all 0.2s ease;
    }

    .admin-voucher-card:hover {
        transform: translateY(-3px);
        border-color: #bfdbfe;

        box-shadow:
            0 8px 22px rgba(37, 99, 235, 0.12);

        color: #142b4a;
    }

    .admin-voucher-icon {
        width: 46px;
        height: 46px;

        display: flex;
        align-items: center;
        justify-content: center;

        border-radius: 12px;

        background: #dbeafe;
        color: #2563eb;

        font-size: 21px;
    }

    .admin-voucher-title {
        font-size: 14px;
        font-weight: 700;
        color: #142b4a;
    }

    .admin-voucher-description {
        margin-top: 2px;

        font-size: 12px;
        color: #8997aa;
    }

    .admin-voucher-arrow {
        margin-left: 15px;
        color: #94a3b8;
    }

    /* =========================================================
       RESPONSIVE
       ========================================================= */

    @media (max-width: 992px) {

        .home-hero {
            min-height: 430px;
        }

        .home-hero-content {
            padding: 45px;
        }

        .home-hero-title {
            font-size: 42px;
        }

        .service-divider {
            border-right: none;
        }
    }

    @media (max-width: 768px) {

        .home-hero {
            min-height: 500px;

            background-position: 65% center;
        }

        .home-hero-content {
            padding: 35px 25px;
        }

        .home-hero-title {
            font-size: 36px;
        }

        .home-hero-description {
            font-size: 16px;
        }

        .service-bar {
            margin-top: 20px;
        }

        .section-header {
            align-items: start;
            gap: 15px;
            flex-direction: column;
        }

        .section-title {
            font-size: 26px;
        }
    }
</style>

<div class="home-page">

    <div class="container">

        <!-- =====================================================
             HERO
             ===================================================== -->

        <section class="home-hero">

            <div class="home-hero-content">

                <div class="home-hero-badge">
                    <i class="bi bi-lightning-charge-fill"></i>
                    DEAL CÔNG NGHỆ THÁNG 10
                </div>

                <h1 class="home-hero-title">
                    Công nghệ chính hãng.
                    <br>
                    Giá tốt mỗi ngày.
                </h1>

                <p class="home-hero-description">
                    Khám phá smartphone, laptop và phụ kiện chính hãng
                    với nhiều lựa chọn phù hợp cho bạn.
                </p>

                <a href="#recommended-products"
                   class="home-hero-button">

                    Xem sản phẩm

                </a>

            </div>

        </section>


        <!-- =====================================================
             SERVICE BAR
             ===================================================== -->

        <section class="service-bar">

            <div class="row g-0">

                <div class="col-lg-3 col-md-6 px-3 service-divider">
                    <div class="service-item">

                        <div class="service-icon">
                            <i class="bi bi-truck"></i>
                        </div>

                        <div>
                            <div class="service-title">
                                Giao hàng nhanh
                            </div>

                            <p class="service-description">
                                Toàn quốc, đúng hẹn
                            </p>
                        </div>

                    </div>
                </div>


                <div class="col-lg-3 col-md-6 px-3 service-divider">
                    <div class="service-item">

                        <div class="service-icon">
                            <i class="bi bi-shield-check"></i>
                        </div>

                        <div>
                            <div class="service-title">
                                Sản phẩm chính hãng
                            </div>

                            <p class="service-description">
                                100% chính hãng
                            </p>
                        </div>

                    </div>
                </div>


                <div class="col-lg-3 col-md-6 px-3 service-divider">
                    <div class="service-item">

                        <div class="service-icon">
                            <i class="bi bi-headset"></i>
                        </div>

                        <div>
                            <div class="service-title">
                                Hỗ trợ 24/7
                            </div>

                            <p class="service-description">
                                Luôn sẵn sàng
                            </p>
                        </div>

                    </div>
                </div>


                <div class="col-lg-3 col-md-6 px-3">
                    <div class="service-item">

                        <div class="service-icon">
                            <i class="bi bi-patch-check"></i>
                        </div>

                        <div>
                            <div class="service-title">
                                Bảo hành uy tín
                            </div>

                            <p class="service-description">
                                Đồng hành cùng bạn
                            </p>
                        </div>

                    </div>
                </div>

            </div>

        </section>
        <%-- =====================================================
            ADMIN VOUCHER SHORTCUT
            CHỈ HIỂN THỊ VỚI ADMIN
            ===================================================== --%>

        <c:if test="${sessionScope.loggedInUser.admin}">

            <div class="admin-shortcut">

                <a href="${pageContext.request.contextPath}/admin/voucher"
                   class="admin-voucher-card">

                    <div class="admin-voucher-icon">
                        <i class="bi bi-ticket-perforated-fill"></i>
                    </div>

                    <div>

                        <div class="admin-voucher-title">
                            Quản lý Voucher
                        </div>

                        <div class="admin-voucher-description">
                            Tạo và quản lý mã giảm giá
                        </div>

                    </div>

                    <div class="admin-voucher-arrow">
                        <i class="bi bi-chevron-right"></i>
                    </div>

                </a>

            </div>

        </c:if>





        <!-- =====================================================
 PRODUCT
 ===================================================== -->

        <section class="home-section"
                 id="recommended-products">

            <div class="section-header">

                <div>
                    <h2 class="section-title">
                        Sản phẩm nổi bật
                    </h2>

                    <p class="section-description">
                        Những sản phẩm công nghệ đáng chú ý tại OECS
                    </p>
                </div>

                <a href="${pageContext.request.contextPath}/shop"
                   class="section-link">

                    Xem tất cả

                    <i class="bi bi-arrow-right"></i>

                </a>

            </div>


            <div class="row g-4">

                <c:choose>

                    <c:when test="${not empty productList}">

                        <c:forEach var="product"
                                   items="${productList}"
                                   begin="0"
                                   end="7">

                            <div class="col-12 col-sm-6 col-lg-3">
                                <!-- ĐỔI div THÀNH thẻ a VÀ THÊM href, text-decoration-none -->
                                <a href="${pageContext.request.contextPath}/shop?action=detail&id=${product.productId}" class="product-card text-decoration-none">

                                    <div class="product-image text-dark">
                                        <i class="bi bi-box-seam"></i>
                                    </div>

                                    <div class="product-info">
                                        <div class="product-brand">
                                            ${product.brand.brandName}
                                        </div>
                                        <div class="product-name text-dark">
                                            ${product.productName}
                                        </div>
                                        <div class="product-description">
                                            ${product.description}
                                        </div>
                                    </div>

                                </a> <!-- KẾT THÚC THẺ a TẠI ĐÂY -->
                            </div>

                        </c:forEach>

                    </c:when>


                    <c:otherwise>

                        <div class="col-12">

                            <div class="alert alert-light text-center py-5">

                                <i class="bi bi-box-seam fs-1 d-block mb-3"></i>

                                <h5>
                                    Chưa có sản phẩm
                                </h5>

                                <p class="text-muted mb-0">
                                    Hiện tại OECS chưa có sản phẩm để hiển thị.
                                </p>

                            </div>

                        </div>

                    </c:otherwise>

                </c:choose>

            </div>

        </section>
        <!-- =====================================================
             PROMOTION
             ===================================================== -->

        <section class="home-section">

            <div class="promo-banner">

                <div class="promo-content">

                    <h3>
                        Nâng cấp công nghệ của bạn
                    </h3>

                    <p>
                        Khám phá những thiết bị mới và lựa chọn
                        sản phẩm phù hợp với nhu cầu của bạn.
                    </p>

                    <a href="#recommended-products"
                       class="btn btn-primary px-4 py-2">

                        Khám phá sản phẩm

                        <i class="bi bi-arrow-right ms-2"></i>

                    </a>

                </div>

            </div>

        </section>

        <!-- =====================================================
             CATEGORY
             ===================================================== -->

        <section class="home-section">

            <div class="section-header">

                <div>
                    <h2 class="section-title">
                        Danh mục nổi bật
                    </h2>

                    <p class="section-description">
                        Khám phá các danh mục sản phẩm phổ biến nhất tại OECS
                    </p>
                </div>



            </div>


            <div class="row g-3">

                <!-- 1. Điện thoại -->
                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?categoryId=1" class="category-card category-phone">
                        <div class="category-content">
                            <div class="category-name">
                                Điện thoại
                            </div>
                            <div class="category-arrow">
                                <i class="bi bi-arrow-right"></i>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- 2. Laptop -->
                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?categoryId=2" class="category-card category-laptop">
                        <div class="category-content">
                            <div class="category-name">
                                Laptop
                            </div>
                            <div class="category-arrow">
                                <i class="bi bi-arrow-right"></i>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- 3. Phụ kiện -->
                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?categoryId=3" class="category-card category-accessory">
                        <div class="category-content">
                            <div class="category-name">
                                Phụ kiện
                            </div>
                            <div class="category-arrow">
                                <i class="bi bi-arrow-right"></i>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- 4. Đồng hồ thông minh -->
                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?keyword=Đồng hồ" class="category-card category-watch">
                        <div class="category-content">
                            <div class="category-name">
                                Đồng hồ thông minh
                            </div>
                            <div class="category-arrow">
                                <i class="bi bi-arrow-right"></i>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- 5. Tai nghe -->
                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?keyword=Tai nghe" class="category-card category-headphone">
                        <div class="category-content">
                            <div class="category-name">
                                Tai nghe
                            </div>
                            <div class="category-arrow">
                                <i class="bi bi-arrow-right"></i>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- 6. Máy ảnh -->
                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?keyword=Máy ảnh" class="category-card category-camera">
                        <div class="category-content">
                            <div class="category-name">
                                Máy ảnh
                            </div>
                            <div class="category-arrow">
                                <i class="bi bi-arrow-right"></i>
                            </div>
                        </div>
                    </a>
                </div>

            </div>

        </section>


    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp"%>