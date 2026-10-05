<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<% User loggedInUser = (User) session.getAttribute("loggedInUser");%>

<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>OECS - Brand & Enterprise Management</title>

        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

        <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/bootstrap.css">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

        <style>
            :root {
                --bg-main: #f8fafc;
                --border-color: #e2e8f0;
                --text-main: #0f172a;
                --text-muted: #64748b;
                --header-bg: #0f172a;
                --header-sub-bg: #090d16;
            }

            body {
                font-family: 'Inter', sans-serif;
                background-color: var(--bg-main) !important;
                color: var(--text-main);
                -webkit-font-smoothing: antialiased;
            }

            .top-subbar {
                background-color: var(--header-sub-bg);
                border-bottom: 1px solid rgba(255, 255, 255, 0.08);
                font-size: 0.8rem;
                color: #94a3b8;
                padding: 5px 0;
            }
            .top-subbar a {
                color: #cbd5e1;
                text-decoration: none;
                transition: color 0.2s;
            }
            .top-subbar a:hover {
                color: #38bdf8;
            }

            .app-header {
                background-color: var(--header-bg);
                border-bottom: 1px solid #1e293b;
                padding-top: 1rem;
                padding-bottom: 0.85rem;
                box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.2);
                position: sticky;
                top: 0;
                z-index: 1030;
            }

            .brand-logo-header {
                font-size: 1.4rem;
                font-weight: 800;
                letter-spacing: -0.5px;
                color: #ffffff !important;
            }

            .btn-menu-category {
                background: rgba(255, 255, 255, 0.1);
                color: #ffffff;
                border: 1px solid rgba(255, 255, 255, 0.15);
                font-weight: 600;
                font-size: 0.88rem;
                padding: 0.55rem 1rem;
                border-radius: 8px;
                transition: all 0.2s ease;
            }
            .btn-menu-category:hover {
                background: rgba(255, 255, 255, 0.2);
                color: #ffffff;
            }

            .header-search-wrapper {
                max-width: 580px;
                width: 100%;
            }
            .header-search-input {
                background-color: #1e293b;
                border: 1px solid #334155;
                color: #ffffff !important;
                font-size: 0.9rem;
                padding-left: 42px;
                padding-right: 70px;
                height: 42px;
                border-radius: 10px;
                transition: all 0.2s ease;
            }
            .header-search-input::placeholder {
                color: #64748b;
            }
            .header-search-input:focus {
                background-color: #0f172a;
                border-color: #3b82f6;
                box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.25);
            }
            .search-shortcut-badge {
                position: absolute;
                right: 12px;
                top: 50%;
                transform: translateY(-50%);
                background: #334155;
                color: #94a3b8;
                font-size: 0.7rem;
                padding: 2px 6px;
                border-radius: 4px;
                font-weight: 600;
            }

            .search-quick-tags {
                margin-top: 6px;
                display: flex;
                gap: 12px;
                font-size: 0.78rem;
                overflow-x: auto;
                white-space: nowrap;
            }
            .search-quick-tags a {
                color: #94a3b8;
                text-decoration: none;
                transition: color 0.15s;
            }
            .search-quick-tags a:hover {
                color: #38bdf8;
            }

            .nav-link-header {
                color: #94a3b8;
                font-size: 0.9rem;
                font-weight: 500;
                padding: 0.55rem 0.9rem;
                border-radius: 8px;
                transition: all 0.2s ease;
                text-decoration: none;
                display: inline-flex;
                align-items: center;
                gap: 7px;
            }
            .nav-link-header:hover {
                color: #ffffff;
                background-color: rgba(255, 255, 255, 0.08);
            }
            .nav-link-header.active {
                color: #ffffff !important;
                background-color: #2563eb !important;
                font-weight: 600;
                box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
            }

            .header-icon-btn {
                width: 40px;
                height: 40px;
                border-radius: 10px;
                background: #1e293b;
                color: #cbd5e1;
                display: flex;
                align-items: center;
                justify-content: center;
                border: 1px solid #334155;
                position: relative;
                transition: all 0.2s;
                text-decoration: none;
            }
            .header-icon-btn:hover {
                background: #334155;
                color: #ffffff;
            }
            .header-icon-badge {
                position: absolute;
                top: -3px;
                right: -3px;
                width: 18px;
                height: 18px;
                background-color: #ef4444;
                color: #fff;
                font-size: 0.68rem;
                font-weight: 700;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                border: 2px solid #0f172a;
            }

            .card-custom {
                background: #ffffff;
                border: 1px solid var(--border-color);
                border-radius: 14px;
                box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);
            }
            .stat-card {
                padding: 1.35rem;
                border-radius: 14px;
                background: #ffffff;
                border: 1px solid var(--border-color);
                box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
            }
            .table-custom thead th {
                background-color: #f8fafc;
                color: var(--text-muted);
                font-size: 0.75rem;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 0.06em;
                padding: 1rem 1.25rem;
                border-bottom: 1px solid var(--border-color);
            }
            .table-custom tbody td {
                padding: 1.1rem 1.25rem;
                vertical-align: middle;
                border-bottom: 1px solid #f1f5f9;
                font-size: 0.9rem;
            }
            .brand-logo-box {
                width: 46px;
                height: 46px;
                border-radius: 10px;
                background: #ffffff;
                border: 1px solid #e2e8f0;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 6px;
                flex-shrink: 0;
                box-shadow: 0 1px 2px rgba(0,0,0,0.05);
            }
            .brand-logo-img {
                max-width: 100%;
                max-height: 100%;
                object-fit: contain;
            }
            .avatar-initial {
                width: 100%;
                height: 100%;
                border-radius: 6px;
                background: #f1f5f9;
                color: #334155;
                font-weight: 700;
                font-size: 1.1rem;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            /* --- CSS CHO SEARCH SUGGESTION --- */
            .search-suggestions {
                position: absolute;
                top: 110%;
                left: 0;
                right: 0;
                background: #1e293b;
                border: 1px solid #334155;
                border-radius: 10px;
                box-shadow: 0 10px 25px rgba(0,0,0,0.5);
                z-index: 1050;
                overflow: hidden;
            }
            .suggestion-item {
                display: flex;
                align-items: center;
                gap: 12px;
                padding: 10px 15px;
                border-bottom: 1px solid #334155;
                text-decoration: none;
                transition: background 0.2s;
            }
            .suggestion-item:last-child {
                border-bottom: none;
            }
            .suggestion-item:hover {
                background: #334155;
            }
            .suggestion-img {
                width: 40px;
                height: 40px;
                border-radius: 6px;
                background: #fff;
                object-fit: contain;
                padding: 2px;
            }
            .suggestion-info {
                display: flex;
                flex-direction: column;
            }
            .suggestion-name {
                color: #f8fafc;
                font-size: 0.9rem;
                font-weight: 500;
                display: -webkit-box;
                -webkit-line-clamp: 1;
                -webkit-box-orient: vertical;
                overflow: hidden;
            }
            .suggestion-price {
                color: #38bdf8;
                font-size: 0.85rem;
                font-weight: 700;
            }
            .suggestion-empty {
                padding: 15px;
                text-align: center;
                color: #94a3b8;
                font-size: 0.9rem;
            }
        </style>
    </head>
    <body>

        <div class="top-subbar d-none d-md-block">
            <div class="container-fluid px-4 px-lg-5">
                <div class="d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center gap-3">
                        <span class="d-inline-flex align-items-center gap-1.5 text-success fw-medium">
                            <span class="spinner-grow spinner-grow-sm text-success" style="width: 8px; height: 8px;" role="status"></span>
                            Hệ thống hoạt động ổn định
                        </span>
                        <span class="text-secondary">|</span>
                        <i class="bi bi-hdd-network text-secondary"></i> Server Node: <strong class="text-light">VN-SGN-01</strong>
                    </div>
                    <div class="d-flex align-items-center gap-3">
                        <a href="#"><i class="bi bi-geo-alt-fill text-primary me-1"></i>Khu vực: <strong>Cần Thơ HQ</strong></a>
                        <span class="text-secondary">|</span>
                        <a href="#"><i class="bi bi-question-circle me-1"></i>Trợ giúp API</a>
                    </div>
                </div>
            </div>
        </div>

        <header class="app-header">
            <div class="container-fluid px-4 px-lg-5">
                <div class="d-flex align-items-center justify-content-between gap-3">

                    <div class="d-flex align-items-center gap-3">
                        <a class="brand-logo-header d-flex align-items-center gap-3 text-decoration-none" href="${pageContext.request.contextPath}/home">
                            <div class="d-flex align-items-center justify-content-center shadow-sm flex-shrink-0" 
                                 style="width: 40px; height: 40px; border-radius: 10px; background: rgba(37, 99, 235, 0.18); border: 1px solid rgba(59, 130, 246, 0.35);">
                                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                <path d="M12 2L2 7L12 12L22 7L12 2Z" fill="#3B82F6"/>
                                <path d="M2 17L12 22L22 17" stroke="#60A5FA" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                                <path d="M2 12L12 17L22 12" stroke="#93C5FD" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                                </svg>
                            </div>

                            <div class="d-flex flex-column justify-content-center">
                                <span class="fw-bold text-white lh-1" style="font-size: 1.25rem; letter-spacing: 0.2px;">OECS</span>
                                <span class="fw-semibold" style="font-size: 0.6rem; letter-spacing: 1.2px; margin-top: 4px; color: #94a3b8;">MANAGEMENT</span>
                            </div>
                        </a>

                        <div class="dropdown d-none d-lg-block ms-2">
                            <button class="btn btn-menu-category d-flex align-items-center gap-2" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="bi bi-grid-3x3-gap-fill text-primary"></i>
                                <span>Phân hệ Quản trị</span>
                                <i class="bi bi-chevron-down fs-8 text-secondary"></i>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-dark shadow-lg border-secondary mt-2 p-2" style="min-width: 270px;">
                                <!-- Nhóm Tổng quan & Báo cáo -->
                                <li><h6 class="dropdown-header text-uppercase text-muted fw-bold" style="font-size: 0.7rem;">Tổng quan</h6></li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/admin/dashboard">
                                        <i class="bi bi-speedometer2 text-primary me-2"></i>Dashboard Báo cáo
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/admin/report">
                                        <i class="bi bi-file-earmark-bar-graph text-info me-2"></i>Thống kê & Báo cáo
                                    </a>
                                </li>

                                <li><hr class="dropdown-divider border-secondary my-1"></li>

                                <!-- Nhóm Bán hàng & Khuyến mãi -->
                                <li><h6 class="dropdown-header text-uppercase text-muted fw-bold" style="font-size: 0.7rem;">Kinh doanh</h6></li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/admin/orders">
                                        <i class="bi bi-receipt text-danger me-2"></i>Quản lý Đơn hàng
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/admin/voucher">
                                        <i class="bi bi-ticket-perforated text-warning me-2"></i>Quản lý Voucher / Mã giảm giá
                                    </a>
                                </li>

                                <li><hr class="dropdown-divider border-secondary my-1"></li>

                                <!-- Nhóm Catalog & Người dùng -->
                                <li><h6 class="dropdown-header text-uppercase text-muted fw-bold" style="font-size: 0.7rem;">Sản phẩm & Khách hàng</h6></li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/product">
                                        <i class="bi bi-box-seam text-success me-2"></i>Quản lý Sản phẩm
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/category">
                                        <i class="bi bi-diagram-3 text-warning me-2"></i>Quản lý Danh mục
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/brand">
                                        <i class="bi bi-tags text-primary me-2"></i>Quản lý Thương hiệu
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/review">
                                        <i class="bi bi-star text-warning me-2"></i>Quản lý Đánh giá
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/user">
                                        <i class="bi bi-people text-info me-2"></i>Quản lý Người dùng
                                    </a>
                                </li>

                                <li><hr class="dropdown-divider border-secondary my-1"></li>

                                <!-- Nhóm Lối tắt Cửa hàng Client -->
                                <li><h6 class="dropdown-header text-uppercase text-muted fw-bold" style="font-size: 0.7rem;">Xem giao diện Web</h6></li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/shop">
                                        <i class="bi bi-shop text-light me-2"></i>Cửa hàng (Shop)
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item rounded-2 py-2" href="${pageContext.request.contextPath}/cart">
                                        <i class="bi bi-cart3 text-light me-2"></i>Giỏ hàng (Cart)
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </div>

                    <div class="header-search-wrapper d-none d-md-block flex-grow-1 px-3">
                        <form action="${pageContext.request.contextPath}/shop" method="GET" class="position-relative mb-0">
                            <i class="bi bi-search position-absolute text-secondary" style="left: 14px; top: 50%; transform: translateY(-50%);"></i>
                            <!-- Đổi placeholder và thêm thuộc tính name="keyword" -->
                            <input type="text" name="keyword" id="headerSearchInput" class="form-control header-search-input" placeholder="Tìm kiếm tên, danh mục..." autocomplete="off">
                            <span class="search-shortcut-badge">Enter ↵</span>

                            <!-- Khu vực hiển thị kết quả AJAX -->
                            <div id="searchSuggestions" class="search-suggestions d-none"></div>
                        </form>
                        <div class="search-quick-tags">
                            <span class="text-secondary me-1"><i class="bi bi-lightning-charge-fill text-warning"></i> Nhanh:</span>
                            <a href="#">Apple</a>
                            <a href="#">Samsung</a>
                            <a href="#">Lenovo</a>
                        </div>
                    </div>

                    <div class="d-flex align-items-center gap-2.5">
                        <a href="#" class="header-icon-btn d-none d-sm-flex" title="Thông báo hệ thống">
                            <i class="bi bi-bell-fill fs-6"></i>
                            <span class="header-icon-badge">3</span>
                        </a>


                        <div class="vr bg-secondary opacity-25 mx-1" style="height: 28px;"></div>

                        <c:choose>
                            <c:when test="${empty loggedInUser}">
                                <a class="text-white text-decoration-none fs-6 fw-medium me-1 ms-1" href="${pageContext.request.contextPath}/login">Đăng nhập</a>
                            </c:when>
                            <c:otherwise>
                                <div class="dropdown">
                                    <a href="#" class="d-flex align-items-center gap-2.5 text-decoration-none text-white p-1 rounded-3" data-bs-toggle="dropdown">
                                        <div class="position-relative">
                                            <div class="bg-primary text-white fw-bold rounded-circle d-flex align-items-center justify-content-center shadow-sm" style="width: 38px; height: 38px; font-size: 0.95rem;">
                                                ${loggedInUser.username.substring(0, 1).toUpperCase()}
                                            </div>
                                            <span class="position-absolute bottom-0 end-0 p-1 bg-success border border-2 border-dark rounded-circle"></span>
                                        </div>
                                        <div class="d-none d-sm-block text-start" style="line-height: 1.2;">
                                            <div class="fw-semibold fs-7">${loggedInUser.username}</div>
                                            <div class="text-secondary" style="font-size: 0.72rem;">Administrator</div>
                                        </div>
                                        <i class="bi bi-chevron-down text-secondary fs-8 d-none d-sm-inline ms-1"></i>
                                    </a>
                                    <ul class="dropdown-menu dropdown-menu-end dropdown-menu-dark shadow-lg border-secondary mt-2">
                                        <li><a class="dropdown-item py-2" href="${pageContext.request.contextPath}/profile"><i class="bi bi-person me-2"></i>Hồ sơ cá nhân</a></li>
                                        <li><a class="dropdown-item py-2" href="${pageContext.request.contextPath}/cart"><i class="bi bi-box-seam"></i>Giỏ hàng</a></li>
                                        <li><a class="dropdown-item py-2" href="#"><i class="bi bi-gear me-2"></i>Cài đặt hệ thống</a></li>
                                        <li><hr class="dropdown-divider border-secondary"></li>
                                        <li><a class="dropdown-item py-2 text-danger" href="${pageContext.request.contextPath}/logout"><i class="bi bi-box-arrow-right me-2"></i>Đăng xuất</a></li>
                                    </ul>
                                </div>
                            </c:otherwise>
                        </c:choose>
                    </div>

                </div>
            </div>
        </header>
        <!-- AJAX SEARCH SCRIPT -->
        <script>
            document.addEventListener("DOMContentLoaded", function () {
                const searchInput = document.getElementById('headerSearchInput');
                const searchSuggestions = document.getElementById('searchSuggestions');
                let timeoutId = null;

                searchInput.addEventListener('input', function () {
                    const keyword = this.value.trim();
                    clearTimeout(timeoutId);

                    if (keyword.length < 2) {
                        searchSuggestions.classList.add('d-none');
                        return;
                    }

                    timeoutId = setTimeout(() => {
                        fetch(`${pageContext.request.contextPath}/api/search?q=` + encodeURIComponent(keyword))
                                .then(response => response.json())
                                .then(data => {
                                    searchSuggestions.innerHTML = '';

                                    if (data.length === 0) {
                                        searchSuggestions.innerHTML = '<div class="suggestion-empty">Không tìm thấy sản phẩm nào!</div>';
                                    } else {
                                        data.forEach(item => {
                                            const priceStr = item.price > 0
                                                    ? new Intl.NumberFormat('vi-VN').format(item.price) + ' ₫'
                                                    : 'Liên hệ';

                                            // Build HTML không dùng thẻ <img> mà dùng Icon hộp quà
                                            const html = `
                                            <a href="${pageContext.request.contextPath}/shop?action=detail&id=\${item.id}" class="suggestion-item">
                                                <div class="suggestion-img d-flex align-items-center justify-content-center bg-light text-secondary border">
                                                    <i class="bi bi-box-seam fs-5"></i>
                                                </div>
                                                <div class="suggestion-info">
                                                    <span class="suggestion-name">\${item.name}</span>
                                                    <span class="suggestion-price">\${priceStr}</span>
                                                </div>
                                            </a>
                                            `;
                                            searchSuggestions.insertAdjacentHTML('beforeend', html);
                                        });
                                    }
                                    searchSuggestions.classList.remove('d-none');
                                })
                                .catch(err => console.error("Lỗi search API:", err));
                    }, 300);
                });

                // Ẩn hộp thoại khi click ra ngoài
                document.addEventListener('click', function (e) {
                    if (!searchInput.contains(e.target) && !searchSuggestions.contains(e.target)) {
                        searchSuggestions.classList.add('d-none');
                    }
                });

                // Phím tắt Ctrl + K
                document.addEventListener('keydown', function (e) {
                    if (e.ctrlKey && e.key === 'k') {
                        e.preventDefault();
                        searchInput.focus();
                    }
                });
            });
        </script>
        <main class="container-fluid px-4 px-lg-5 py-4" style="max-width: 1440px;">
