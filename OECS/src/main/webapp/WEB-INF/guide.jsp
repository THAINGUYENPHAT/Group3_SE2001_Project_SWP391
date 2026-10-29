
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .guide-page {
        padding-bottom: 40px;
    }

    .guide-hero {
        position: relative;
        overflow: hidden;
        padding: 32px;
        border-radius: 18px;
        background: linear-gradient(120deg, #0f172a, #1e3a8a);
        color: #ffffff;
        margin-bottom: 28px;
    }

    .guide-hero-icon {
        width: 58px;
        height: 58px;
        border-radius: 15px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: rgba(255, 255, 255, 0.12);
        border: 1px solid rgba(255, 255, 255, 0.2);
        font-size: 1.7rem;
        flex-shrink: 0;
    }

    .guide-hero p {
        color: #cbd5e1;
        max-width: 650px;
        margin-bottom: 0;
        line-height: 1.7;
    }

    .guide-section-title {
        font-size: 1.05rem;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 16px;
    }

    .guide-card {
        height: 100%;
        padding: 22px;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        background: #ffffff;
        transition: transform 0.2s, box-shadow 0.2s;
    }

    .guide-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 8px 22px rgba(15, 23, 42, 0.07);
    }

    .guide-card-icon {
        width: 44px;
        height: 44px;
        border-radius: 11px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #eff6ff;
        color: #2563eb;
        font-size: 1.25rem;
        margin-bottom: 16px;
    }

    .guide-card h3 {
        font-size: 0.98rem;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 10px;
    }

    .guide-card p {
        font-size: 0.88rem;
        color: #64748b;
        line-height: 1.7;
        margin-bottom: 14px;
    }

    .guide-card a {
        font-size: 0.85rem;
        font-weight: 600;
        color: #2563eb;
        text-decoration: none;
    }

    .guide-card a:hover {
        color: #1d4ed8;
    }

    .guide-step {
        display: flex;
        gap: 14px;
        padding: 16px 0;
        border-bottom: 1px solid #f1f5f9;
    }

    .guide-step:last-child {
        border-bottom: none;
        padding-bottom: 0;
    }

    .guide-step-number {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        background: #eff6ff;
        color: #2563eb;
        font-weight: 700;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .guide-step h4 {
        font-size: 0.92rem;
        font-weight: 700;
        margin-bottom: 5px;
        color: #0f172a;
    }

    .guide-step p {
        color: #64748b;
        font-size: 0.86rem;
        line-height: 1.65;
        margin-bottom: 0;
    }

    .guide-note {
        padding: 18px;
        background: #eff6ff;
        border: 1px solid #dbeafe;
        border-radius: 12px;
        color: #1e40af;
        font-size: 0.88rem;
        line-height: 1.7;
    }

    .guide-badge {
        display: inline-block;
        padding: 5px 10px;
        border-radius: 20px;
        background: #dbeafe;
        color: #1d4ed8;
        font-size: 0.75rem;
        font-weight: 700;
        margin-bottom: 12px;
    }

    @media (max-width: 767.98px) {
        .guide-hero {
            padding: 24px 20px;
        }

        .guide-hero h1 {
            font-size: 1.5rem;
        }

        .guide-card {
            padding: 18px;
        }
    }
</style>

<div class="guide-page">

    <!-- PAGE HEADING -->
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
        <div>
            <div class="text-secondary small mb-2">
                <i class="bi bi-house-door me-1"></i>
                Trang chủ
                <i class="bi bi-chevron-right mx-2"></i>
                Hướng dẫn
            </div>
            <h2 class="fw-bold mb-1">Trung tâm hướng dẫn</h2>
            <p class="text-secondary mb-0">
                Tìm hiểu cách sử dụng các chức năng trong hệ thống OECS.
            </p>
        </div>

        <a href="${pageContext.request.contextPath}/home"
           class="btn btn-outline-secondary rounded-3">
            <i class="bi bi-arrow-left me-2"></i>Về trang chủ
        </a>
    </div>

    <!-- HERO -->
    <div class="guide-hero">
        <div class="d-flex align-items-center gap-3 mb-3">
            <div class="guide-hero-icon">
                <i class="bi bi-journal-text"></i>
            </div>
            <div>
                <div class="small text-uppercase fw-semibold mb-1"
                     style="letter-spacing: 1.5px; color: #93c5fd;">
                    OECS Knowledge Center
                </div>
                <h1 class="h3 fw-bold mb-0">Hướng dẫn sử dụng hệ thống</h1>
            </div>
        </div>

        <p>
            Khám phá các chức năng của OECS thông qua hướng dẫn dành cho từng
            nhóm người dùng. Chọn nội dung phù hợp để bắt đầu.
        </p>
    </div>

    <!-- QUICK ACCESS -->
    <h3 class="guide-section-title">
        <i class="bi bi-grid me-2 text-primary"></i>Danh mục hướng dẫn
    </h3>

    <div class="row g-3 mb-4">

        <!-- CUSTOMER / GUEST -->
        <c:if test="${empty sessionScope.loggedInUser
                      or sessionScope.loggedInUser.customer}">

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-search"></i>
                    </div>
                    <h3>Tìm kiếm sản phẩm</h3>
                    <p>
                        Tìm sản phẩm theo tên, danh mục hoặc từ khóa.
                        Chọn sản phẩm để xem thông tin chi tiết.
                    </p>
                    <a href="${pageContext.request.contextPath}/shop">
                        Khám phá cửa hàng
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-cart3"></i>
                    </div>
                    <h3>Giỏ hàng và đặt hàng</h3>
                    <p>
                        Tìm hiểu cách thêm sản phẩm vào giỏ hàng, kiểm tra
                        số lượng và thực hiện các bước đặt hàng.(Lưu ý: bắt buộc đăng nhập trước khi dùng tính năng)
                    </p>
                    <a href="${pageContext.request.contextPath}/cart">
                        Mở giỏ hàng
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-person-circle"></i>
                    </div>
                    <h3>Tài khoản cá nhân</h3>
                    <p>
                        Đăng nhập để sử dụng các chức năng dành cho khách
                        hàng và quản lý thông tin tài khoản.
                    </p>
                    <a href="${pageContext.request.contextPath}/login">
                        Đăng nhập
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

        </c:if>

        <!-- STAFF -->
        <c:if test="${sessionScope.loggedInUser.staff}">

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-box-seam"></i>
                    </div>
                    <h3>Quản lý sản phẩm</h3>
                    <p>
                        Theo dõi danh sách sản phẩm và sử dụng các chức năng
                        quản lý sản phẩm theo quyền được cấp.
                    </p>
                    <a href="${pageContext.request.contextPath}/product">
                        Quản lý sản phẩm
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-diagram-3"></i>
                    </div>
                    <h3>Quản lý danh mục</h3>
                    <p>
                        Quản lý danh mục và hỗ trợ sắp xếp sản phẩm
                        theo nhóm phù hợp.
                    </p>
                    <a href="${pageContext.request.contextPath}/category">
                        Quản lý danh mục
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-tags"></i>
                    </div>
                    <h3>Quản lý thương hiệu</h3>
                    <p>
                        Xem và quản lý thông tin thương hiệu được sử dụng
                        trong danh mục sản phẩm.
                    </p>
                    <a href="${pageContext.request.contextPath}/brand">
                        Quản lý thương hiệu
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-receipt"></i>
                    </div>
                    <h3>Quản lý đơn hàng</h3>
                    <p>
                        Truy cập khu vực quản lý để theo dõi và xử lý
                        các đơn hàng theo quy trình của hệ thống.
                    </p>
                    <a href="${pageContext.request.contextPath}/admin/orders">
                        Quản lý đơn hàng
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-ticket-perforated"></i>
                    </div>
                    <h3>Quản lý voucher</h3>
                    <p>
                        Truy cập chức năng quản lý mã giảm giá và kiểm tra
                        thông tin voucher hiện có.
                    </p>
                    <a href="${pageContext.request.contextPath}/admin/voucher">
                        Quản lý voucher
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

        </c:if>

        <!-- ADMIN -->
        <c:if test="${sessionScope.loggedInUser.admin}">

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-speedometer2"></i>
                    </div>
                    <h3>Dashboard hệ thống</h3>
                    <p>
                        Truy cập dashboard để xem thông tin tổng quan
                        và các số liệu được hệ thống cung cấp.
                    </p>
                    <a href="${pageContext.request.contextPath}/admin/dashboard">
                        Mở dashboard
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-file-earmark-bar-graph"></i>
                    </div>
                    <h3>Thống kê và báo cáo</h3>
                    <p>
                        Xem các báo cáo phục vụ việc theo dõi hoạt động
                        và hỗ trợ quản lý hệ thống.
                    </p>
                    <a href="${pageContext.request.contextPath}/admin/report">
                        Xem báo cáo
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

            <div class="col-12 col-md-6 col-xl-4">
                <div class="guide-card">
                    <div class="guide-card-icon">
                        <i class="bi bi-people"></i>
                    </div>
                    <h3>Quản lý người dùng</h3>
                    <p>
                        Truy cập khu vực quản lý tài khoản người dùng
                        theo quyền quản trị được cấp.
                    </p>
                    <a href="${pageContext.request.contextPath}/user">
                        Quản lý người dùng
                        <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>

        </c:if>

    </div>

    <!-- BASIC INSTRUCTIONS -->
    <div class="row g-4">

        <div class="col-12 col-lg-7">
            <div class="card-custom p-4 h-100">
                <h3 class="guide-section-title mb-3">
                    <i class="bi bi-list-check me-2 text-primary"></i>
                    Bắt đầu sử dụng
                </h3>

                <div class="guide-step">
                    <div class="guide-step-number">1</div>
                    <div>
                        <h4>Truy cập hệ thống</h4>
                        <p>
                            Mở trang chủ OECS và sử dụng thanh tìm kiếm
                            hoặc các danh mục để truy cập chức năng mong muốn.
                        </p>
                    </div>
                </div>

                <div class="guide-step">
                    <div class="guide-step-number">2</div>
                    <div>
                        <h4>Đăng nhập khi cần thiết</h4>
                        <p>
                            Đăng nhập bằng tài khoản được cấp để sử dụng
                            những chức năng tương ứng với vai trò của bạn.
                        </p>
                    </div>
                </div>

                <div class="guide-step">
                    <div class="guide-step-number">3</div>
                    <div>
                        <h4>Chọn chức năng phù hợp</h4>
                        <p>
                            Sử dụng menu trên header hoặc các liên kết
                            trong trang hướng dẫn để đi đến từng phân hệ.
                        </p>
                    </div>
                </div>

                <div class="guide-step">
                    <div class="guide-step-number">4</div>
                    <div>
                        <h4>Thao tác theo hướng dẫn của từng trang</h4>
                        <p>
                            Kiểm tra thông tin trước khi lưu hoặc xác nhận
                            thao tác để hạn chế sai sót.
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-12 col-lg-5">
            <div class="card-custom p-4 mb-4">
                <h3 class="guide-section-title">
                    <i class="bi bi-shield-check me-2 text-primary"></i>
                    Lưu ý khi sử dụng
                </h3>

                <div class="guide-note mb-3">
                    <i class="bi bi-info-circle-fill me-2"></i>
                    Các chức năng được hiển thị tùy theo vai trò và quyền
                    truy cập của tài khoản.
                </div>

                <ul class="text-secondary small ps-3 mb-0"
                    style="line-height: 2;">
                    <li>Không chia sẻ thông tin đăng nhập cho người khác.</li>
                    <li>Kiểm tra dữ liệu trước khi xác nhận thao tác.</li>
                    <li>Đăng xuất sau khi hoàn tất sử dụng hệ thống.</li>
                    <li>Liên hệ người quản trị nếu gặp lỗi truy cập.</li>
                </ul>
            </div>

            <div class="card-custom p-4">
                <div class="d-flex align-items-start gap-3">
                    <div class="guide-card-icon mb-0">
                        <i class="bi bi-question-circle"></i>
                    </div>
                    <div>
                        <h3 class="guide-section-title mb-2">
                            Bạn cần hỗ trợ?
                        </h3>
                        <p class="text-secondary small mb-0"
                           style="line-height: 1.7;">
                            Nếu chức năng không hiển thị hoặc không thể
                            truy cập, hãy kiểm tra tài khoản và quyền sử dụng
                            hoặc liên hệ quản trị viên hệ thống.<br>
                            Zalo: 0343323747
                        </p>
                    </div>
                </div>
            </div>
        </div>

    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp" %>
