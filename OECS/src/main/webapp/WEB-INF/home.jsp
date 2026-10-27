<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<script>
    document.querySelector(".page-main")
            ?.classList.add("home-main");
</script>

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
        width: 100%;
        height: 380px;
        min-height: 380px;
        overflow: hidden;

        background-image:
            linear-gradient(
            90deg,
            rgba(3, 17, 38, 0.95) 0%,
            rgba(3, 17, 38, 0.82) 38%,
            rgba(3, 17, 38, 0.40) 70%,
            rgba(3, 17, 38, 0.12) 100%
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
        width: 100%;
        max-width: 680px;

        padding: 40px 60px;
    }

    .home-hero-badge {
        display: inline-flex;
        align-items: center;
        gap: 8px;

        padding: 8px 14px;
        margin-bottom: 18px;

        color: #ffffff;
        background: rgba(255, 255, 255, 0.12);
        border: 1px solid rgba(255, 255, 255, 0.25);
        border-radius: 30px;

        font-size: 12px;
        font-weight: 700;
        letter-spacing: 1px;
    }

    .home-hero-title {
        font-size: clamp(34px, 3.2vw, 46px);
        line-height: 1.2;
        font-weight: 800;

        margin: 0 0 16px;
        letter-spacing: -0.8px;
    }

    .home-hero-description {
        max-width: 480px;

        font-size: 16px;
        line-height: 1.7;
        color: rgba(255, 255, 255, 0.82);

        margin: 0 0 25px;
    }

    .home-hero-button {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 10px;

        background: #0d6efd;
        color: white;

        padding: 13px 22px;
        border: 1px solid rgba(255, 255, 255, 0.15);
        border-radius: 9px;

        font-size: 15px;
        font-weight: 700;
        text-decoration: none;

        box-shadow: 0 8px 22px rgba(13, 110, 253, 0.25);
        transition: all 0.2s ease;
    }

    .home-hero-button:hover {
        background: #0b5ed7;
        color: white;
        transform: translateY(-2px);
        box-shadow: 0 10px 26px rgba(13, 110, 253, 0.38);
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

    /* =========================================================
       HOME SLIDESHOW
       ========================================================= */
    .home-slider {
        position: relative;
        width: 100%;
        aspect-ratio: 3 / 1;
        overflow: hidden;
        border-radius: 18px;
        background: #e9eef5;
        box-shadow: 0 8px 24px rgba(20, 40, 70, 0.08);
    }

    .slider-track {
        position: relative;
        width: 100%;
        height: 100%;
    }

    .home-slider .slide {
        position: absolute;
        inset: 0;
        opacity: 0;
        visibility: hidden;
        transition: opacity 0.6s ease;
    }

    .home-slider .slide.active {
        opacity: 1;
        visibility: visible;
        z-index: 1;
    }

    .home-slider .slide img {
        display: block;
        width: 100%;
        height: 100%;
        object-fit: cover;
    }

    .slider-arrow {
        position: absolute;
        top: 50%;
        transform: translateY(-50%);
        z-index: 2;
        width: 42px;
        height: 42px;
        border: none;
        border-radius: 50%;
        background: rgba(15, 23, 42, 0.65);
        color: white;
        font-size: 18px;
        cursor: pointer;
    }

    .slider-arrow:hover {
        background: #0d6efd;
    }

    .slider-arrow.prev {
        left: 16px;
    }

    .slider-arrow.next {
        right: 16px;
    }

    .slider-dots {
        position: absolute;
        bottom: 15px;
        left: 50%;
        transform: translateX(-50%);
        z-index: 2;
        display: flex;
        gap: 8px;
    }

    .slider-dot {
        width: 9px;
        height: 9px;
        padding: 0;
        border: none;
        border-radius: 10px;
        background: rgba(255, 255, 255, 0.7);
        cursor: pointer;
    }

    .slider-dot.active {
        width: 26px;
        background: white;
    }

    @media (max-width: 768px) {
        .home-slider {
            aspect-ratio: 16 / 9;
            border-radius: 12px;
        }

        .slider-arrow {
            width: 32px;
            height: 32px;
            font-size: 14px;
        }

        .slider-arrow.prev {
            left: 8px;
        }

        .slider-arrow.next {
            right: 8px;
        }
    }
</style>

<div class="home-page">

    <%-- Thông báo --%>
    <div class="container">
        <c:if test="${not empty sessionScope.toastMessage}">
            <div class="alert alert-danger alert-dismissible fade show mt-3" role="alert">
                ${sessionScope.toastMessage}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
            <c:remove var="toastMessage" scope="session"/>
            <c:remove var="toastType" scope="session"/>
        </c:if>
    </div>

    <%-- HERO tràn toàn bộ chiều rộng màn hình --%>
    <section class="home-hero">
        <div class="home-hero-content">
            <div class="home-hero-badge">
                <i class="bi bi-lightning-charge-fill"></i> DEAL CÔNG NGHỆ THÁNG 10
            </div>
            <h1 class="home-hero-title">
                Công nghệ chính hãng.<br>Giá tốt mỗi ngày.
            </h1>
            <p class="home-hero-description">
                Khám phá smartphone, laptop và phụ kiện chính hãng với nhiều lựa chọn phù hợp cho bạn.
            </p>
            <a href="#recommended-products" class="home-hero-button">
                Xem sản phẩm nổi bật
            </a>
        </div>
    </section>

    <%-- Nội dung còn lại nằm trong container --%>
    <div class="container">
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
                            <div class="service-title">Giao hàng nhanh</div>
                            <p class="service-description">Toàn quốc, đúng hẹn</p>
                        </div>
                    </div>
                </div>

                <div class="col-lg-3 col-md-6 px-3 service-divider">
                    <div class="service-item">
                        <div class="service-icon">
                            <i class="bi bi-shield-check"></i>
                        </div>
                        <div>
                            <div class="service-title">Sản phẩm chính hãng</div>
                            <p class="service-description">100% chính hãng</p>
                        </div>
                    </div>
                </div>

                <div class="col-lg-3 col-md-6 px-3 service-divider">
                    <div class="service-item">
                        <div class="service-icon">
                            <i class="bi bi-headset"></i>
                        </div>
                        <div>
                            <div class="service-title">Hỗ trợ 24/7</div>
                            <p class="service-description">Luôn sẵn sàng</p>
                        </div>
                    </div>
                </div>

                <div class="col-lg-3 col-md-6 px-3">
                    <div class="service-item">
                        <div class="service-icon">
                            <i class="bi bi-patch-check"></i>
                        </div>
                        <div>
                            <div class="service-title">Bảo hành uy tín</div>
                            <p class="service-description">Đồng hành cùng bạn</p>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- =====================================================
             PROMOTION SLIDESHOW
             ===================================================== -->
        <section class="home-section">
            <div class="home-slider" id="homeSlider">
                <div class="slider-track">
                    <a href="${pageContext.request.contextPath}/shop" class="slide active">
                        <img src="${pageContext.request.contextPath}/assets/images/banners/banner-1.jpg" alt="Khuyến mãi công nghệ">
                    </a>
                    <a href="${pageContext.request.contextPath}/shop" class="slide">
                        <img src="${pageContext.request.contextPath}/assets/images/banners/banner-2.jpg" alt="Ưu đãi laptop">
                    </a>
                    <a href="${pageContext.request.contextPath}/shop" class="slide">
                        <img src="${pageContext.request.contextPath}/assets/images/banners/banner-3.jpg" alt="Ưu đãi phụ kiện">
                    </a>
                </div>

                <button type="button" class="slider-arrow prev" aria-label="Ảnh trước">&#10094;</button>
                <button type="button" class="slider-arrow next" aria-label="Ảnh tiếp theo">&#10095;</button>

                <div class="slider-dots">
                    <button type="button" class="slider-dot active" aria-label="Ảnh 1"></button>
                    <button type="button" class="slider-dot" aria-label="Ảnh 2"></button>
                    <button type="button" class="slider-dot" aria-label="Ảnh 3"></button>
                </div>
            </div>
        </section>

        <!-- =====================================================
             CATEGORY
             ===================================================== -->
        <section class="home-section">
            <div class="row g-3">
                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?categoryId=1" class="category-card category-phone">
                        <div class="category-content">
                            <div class="category-name">Điện thoại</div>
                            <div class="category-arrow"><i class="bi bi-arrow-right"></i></div>
                        </div>
                    </a>
                </div>

                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?categoryId=2" class="category-card category-laptop">
                        <div class="category-content">
                            <div class="category-name">Laptop</div>
                            <div class="category-arrow"><i class="bi bi-arrow-right"></i></div>
                        </div>
                    </a>
                </div>

                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?categoryId=3" class="category-card category-accessory">
                        <div class="category-content">
                            <div class="category-name">Phụ kiện</div>
                            <div class="category-arrow"><i class="bi bi-arrow-right"></i></div>
                        </div>
                    </a>
                </div>

                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?keyword=Dong%20ho" class="category-card category-watch">
                        <div class="category-content">
                            <div class="category-name">Đồng hồ thông minh</div>
                            <div class="category-arrow"><i class="bi bi-arrow-right"></i></div>
                        </div>
                    </a>
                </div>

                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?keyword=Tai%20nghe" class="category-card category-headphone">
                        <div class="category-content">
                            <div class="category-name">Tai nghe</div>
                            <div class="category-arrow"><i class="bi bi-arrow-right"></i></div>
                        </div>
                    </a>
                </div>

                <div class="col-6 col-lg-2">
                    <a href="${pageContext.request.contextPath}/shop?keyword=May%20anh" class="category-card category-camera">
                        <div class="category-content">
                            <div class="category-name">Máy ảnh</div>
                            <div class="category-arrow"><i class="bi bi-arrow-right"></i></div>
                        </div>
                    </a>
                </div>
            </div>
        </section>
        <!-- =====================================================
             PROMOTION
             ===================================================== -->
        <section class="home-section">
            <div class="promo-banner">
                <div class="promo-content">
                    <h3>Nâng cấp công nghệ của bạn</h3>
                    <p>Khám phá những thiết bị mới và lựa chọn sản phẩm phù hợp với nhu cầu của bạn.</p>
                </div>
            </div>
        </section>

        <!-- =====================================================
             PRODUCT
             ===================================================== -->
        <section class="home-section" id="recommended-products">
            <div class="section-header">
                <div>
                    <h2 class="section-title">Sản phẩm nổi bật</h2>
                    <p class="section-description">Những sản phẩm công nghệ đáng chú ý tại OECS</p>
                </div>
                <a href="${pageContext.request.contextPath}/shop" class="section-link">
                    Xem tất cả <i class="bi bi-arrow-right"></i>
                </a>
            </div>

            <div class="row g-4">
                <c:choose>
                    <c:when test="${not empty productList}">
                        <c:forEach var="product" items="${productList}" begin="0" end="7">
                            <div class="col-12 col-sm-6 col-lg-3">
                                <a href="${pageContext.request.contextPath}/shop?action=detail&id=${product.productId}" class="product-card text-decoration-none">

                                    <!-- HIỂN THỊ HÌNH ẢNH SẢN PHẨM -->
                                    <div class="product-image text-dark">
                                        <c:choose>
                                            <c:when test="${not empty product.imageUrl}">
                                                <img src="${pageContext.request.contextPath}/${product.imageUrl}" alt="${product.productName}">
                                            </c:when>
                                            <c:otherwise>
                                                <i class="bi bi-box-seam"></i>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>

                                    <div class="product-info">
                                        <div class="product-brand">${product.brand.brandName}</div>
                                        <div class="product-name text-dark">${product.productName}</div>
                                        <div class="product-description">${product.description}</div>
                                    </div>
                                </a>
                            </div>
                        </c:forEach>
                    </c:when>

                    <c:otherwise>
                        <div class="col-12">
                            <div class="alert alert-light text-center py-5">
                                <i class="bi bi-box-seam fs-1 d-block mb-3"></i>
                                <h5>Chưa có sản phẩm</h5>
                                <p class="text-muted mb-0">Hiện tại OECS chưa có sản phẩm để hiển thị.</p>
                            </div>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
        </section>
    </div>
</div>

<script>
    (function () {
        const slider = document.getElementById("homeSlider");
        if (!slider)
            return;

        const slides = slider.querySelectorAll(".slide");
        const dots = slider.querySelectorAll(".slider-dot");
        const prevButton = slider.querySelector(".prev");
        const nextButton = slider.querySelector(".next");

        let currentIndex = 0;
        let timer = null;

        function showSlide(index) {
            currentIndex = (index + slides.length) % slides.length;
            slides.forEach(function (slide, i) {
                slide.classList.toggle("active", i === currentIndex);
            });
            dots.forEach(function (dot, i) {
                dot.classList.toggle("active", i === currentIndex);
            });
        }

        function stopAutoPlay() {
            if (timer !== null) {
                clearInterval(timer);
                timer = null;
            }
        }

        function startAutoPlay() {
            stopAutoPlay();
            timer = setInterval(function () {
                showSlide(currentIndex + 1);
            }, 4000);
        }

        prevButton.addEventListener("click", function () {
            showSlide(currentIndex - 1);
            startAutoPlay();
        });

        nextButton.addEventListener("click", function () {
            showSlide(currentIndex + 1);
            startAutoPlay();
        });

        dots.forEach(function (dot, index) {
            dot.addEventListener("click", function () {
                showSlide(index);
                startAutoPlay();
            });
        });

        slider.addEventListener("mouseenter", stopAutoPlay);
        slider.addEventListener("mouseleave", startAutoPlay);

        showSlide(0);
        startAutoPlay();
    })();
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>