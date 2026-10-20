<%@ page pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ include file="/WEB-INF/include/header.jsp" %>

<style>
    /* BO CUC TRANG */
    #purchase-history {
        --accent: #b94322;
        --ink: #202938;
        --muted: #64748b;
        --line: #e2e8f0;
        width: calc(100% - 32px);
        max-width: 1100px;
        margin: 28px auto 56px;
        color: var(--ink);
        font-size: 14px;
        line-height: 1.5;
    }

    #purchase-history * { box-sizing: border-box; }
    #purchase-history a { text-decoration: none; }
    #purchase-history a:focus-visible,
    #purchase-history button:focus-visible,
    #purchase-history input:focus-visible {
        outline: 3px solid #e58b6d;
        outline-offset: 3px;
    }

    #purchase-history .ph-topbar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 12px;
        padding-bottom: 16px;
        margin-bottom: 24px;
        border-bottom: 1px solid var(--line);
    }

    #purchase-history .ph-current {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        color: var(--accent);
        font-weight: 600;
    }

    /* NUT MUA SAM KICH THUOC NHO */
    #purchase-history .ph-shop {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 7px;
        min-height: 36px;
        padding: 7px 12px;
        border: 1px solid var(--accent);
        border-radius: 7px;
        background: var(--accent);
        color: #fff;
        font-size: 12px;
        font-weight: 500;
        line-height: 1.4;
        white-space: nowrap;
    }

    #purchase-history .ph-shop .bi-bag-plus { font-size: 16px; }
    #purchase-history .ph-shop .bi-arrow-right { font-size: 13px; }
    #purchase-history .ph-shop:hover { background: #99371c; border-color: #99371c; color: #fff; }

    #purchase-history .ph-heading { margin-bottom: 24px; }
    #purchase-history .ph-heading h1 {
        margin: 0 0 8px;
        font-size: 28px;
        font-weight: 700;
        line-height: 1.3;
        letter-spacing: -.5px;
        color: var(--ink);
    }
    #purchase-history .ph-heading p { margin: 0; color: var(--muted); }

    /* LOC VA TIM KIEM */
    #purchase-history .ph-filters {
        background: #fff;
        border: 1px solid var(--line);
        border-radius: 12px;
        overflow: hidden;
    }
    #purchase-history .ph-tabs {
        display: flex;
        overflow-x: auto;
        border-bottom: 1px solid var(--line);
        scrollbar-width: thin;
    }
    #purchase-history .ph-tab {
        display: flex;
        flex: 1 0 auto;
        align-items: center;
        justify-content: center;
        gap: 7px;
        padding: 16px 14px;
        border-bottom: 3px solid transparent;
        color: var(--muted);
        white-space: nowrap;
        font-size: 13px;
    }
    #purchase-history .ph-tab:hover { background: #fffaf7; color: var(--accent); }
    #purchase-history .ph-tab.is-active {
        color: var(--accent);
        border-bottom-color: var(--accent);
        font-weight: 600;
    }
    #purchase-history .ph-count {
        min-width: 22px;
        padding: 2px 6px;
        border-radius: 20px;
        background: #f1f5f9;
        color: var(--muted);
        font-size: 11px;
        text-align: center;
    }
    #purchase-history .ph-tab.is-active .ph-count {
        background: #fff0e8;
        color: var(--accent);
    }
    #purchase-history .ph-search {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 12px 16px;
        margin: 0;
    }
    #purchase-history .ph-search > i { color: var(--muted); }
    #purchase-history .ph-search input[type="search"] {
        flex: 1;
        min-width: 0;
        padding: 9px 0;
        border: 0;
        background: transparent;
        color: var(--ink);
        font: inherit;
    }
    #purchase-history .ph-search button {
        padding: 8px 15px;
        border: 1px solid #dbe2ea;
        border-radius: 8px;
        background: #f8fafc;
        color: #334155;
        font: inherit;
        font-size: 13px;
        white-space: nowrap;
        cursor: pointer;
    }
    #purchase-history .ph-search button:hover { background: #eef2f6; }
    #purchase-history .ph-results {
        display: flex;
        justify-content: space-between;
        flex-wrap: wrap;
        gap: 10px;
        margin: 20px 0 12px;
        color: var(--muted);
        font-size: 13px;
        overflow-wrap: anywhere;
    }
    #purchase-history .ph-results a { color: var(--accent); }

    /* DON HANG */
    #purchase-history .ph-order {
        margin-bottom: 16px;
        overflow: hidden;
        border: 1px solid var(--line);
        border-radius: 12px;
        background: #fff;
    }
    #purchase-history .ph-order-head {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 12px;
        padding: 13px 20px;
        border-bottom: 1px solid #edf1f5;
        background: #fafbfc;
    }
    #purchase-history .ph-meta {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 4px 14px;
        font-size: 13px;
    }
    #purchase-history .ph-date { color: var(--muted); font-size: 12px; }
    #purchase-history .ph-status {
        padding: 5px 10px;
        border-radius: 6px;
        background: #eff6ff;
        color: #24599a;
        font-size: 12px;
        font-weight: 600;
        white-space: nowrap;
    }
    #purchase-history .ph-status.is-completed { background: #edf7f2; color: #216348; }
    #purchase-history .ph-status.is-cancelled { background: #edf0f4; color: #64748b; }
    #purchase-history .ph-products { padding: 0 20px; }
    #purchase-history .ph-product {
        display: flex;
        align-items: center;
        gap: 14px;
        padding: 20px 0;
    }
    #purchase-history .ph-product + .ph-product { border-top: 1px solid #edf1f5; }
    #purchase-history .ph-icon {
        display: grid;
        flex: 0 0 54px;
        place-items: center;
        height: 54px;
        border: 1px solid #e8edf2;
        border-radius: 10px;
        background: #f5f7fa;
        color: #8492a6;
        font-size: 24px;
    }
    #purchase-history .ph-info { flex: 1; min-width: 0; }
    #purchase-history .ph-info h2 {
        margin: 0 0 4px;
        color: var(--ink);
        font-size: 15px;
        font-weight: 600;
        line-height: 1.5;
        overflow-wrap: anywhere;
    }
    #purchase-history .ph-info p {
        margin: 0 0 5px;
        color: var(--muted);
        font-size: 12px;
        overflow-wrap: anywhere;
    }
    #purchase-history .ph-info > span { color: #475569; font-size: 12px; }
    #purchase-history .ph-price {
        color: #334155;
        text-align: right;
        font-weight: 600;
        white-space: nowrap;
        font-variant-numeric: tabular-nums;
    }
    #purchase-history .ph-price small {
        display: block;
        margin-top: 4px;
        color: var(--muted);
        font-size: 11px;
        font-weight: 400;
    }
    #purchase-history .ph-order-foot {
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 14px;
        padding: 14px 20px;
        border-top: 1px solid #edf1f5;
    }
    #purchase-history .ph-total {
        display: flex;
        align-items: baseline;
        flex-wrap: wrap;
        gap: 4px 10px;
        color: var(--muted);
        font-size: 13px;
    }
    #purchase-history .ph-total strong {
        color: var(--ink);
        font-size: 20px;
        font-weight: 700;
        font-variant-numeric: tabular-nums;
    }
    #purchase-history .ph-button,
    #purchase-history .ph-secondary {
        display: inline-flex;
        justify-content: center;
        align-items: center;
        gap: 8px;
        padding: 9px 14px;
        border: 1px solid var(--accent);
        border-radius: 8px;
        background: var(--accent);
        color: #fff;
        font-size: 13px;
    }
    #purchase-history .ph-button:hover { background: #99371c; color: #fff; }
    #purchase-history .ph-secondary {
        background: #fff;
        border-color: var(--line);
        color: #475569;
    }
    #purchase-history .ph-secondary:hover { background: #f8fafc; }

    /* TRANG THAI RONG VA PHAN TRANG */
    #purchase-history .ph-empty {
        padding: 48px 20px;
        border: 1px solid var(--line);
        border-radius: 12px;
        background: #fff;
        text-align: center;
    }
    #purchase-history .ph-empty > i {
        display: block;
        margin-bottom: 14px;
        color: #94a3b8;
        font-size: 36px;
    }
    #purchase-history .ph-empty h2 { margin: 0 0 8px; font-size: 18px; }
    #purchase-history .ph-empty p { margin: 0 0 22px; color: var(--muted); }
    #purchase-history .ph-empty-actions,
    #purchase-history .ph-pagination {
        display: flex;
        justify-content: center;
        align-items: center;
        flex-wrap: wrap;
        gap: 12px;
    }
    #purchase-history .ph-pagination { margin-top: 24px; color: var(--muted); font-size: 13px; }
    #purchase-history .ph-missing { margin: 0; padding: 18px 0; color: var(--muted); }

    /* DIEN THOAI */
    @media (max-width: 640px) {
        #purchase-history { width: calc(100% - 24px); margin: 18px auto 32px; }
        #purchase-history .ph-heading h1 { font-size: 24px; }
        #purchase-history .ph-heading p { font-size: 13px; }
        #purchase-history .ph-current { font-size: 13px; }
        #purchase-history .ph-tab { padding: 14px 12px; }
        #purchase-history .ph-search { gap: 8px; padding: 10px 12px; }
        #purchase-history .ph-search input[type="search"] { font-size: 16px; }
        #purchase-history .ph-search button { padding: 8px 10px; }
        #purchase-history .ph-order-head,
        #purchase-history .ph-order-foot { padding: 12px 14px; }
        #purchase-history .ph-products { padding: 0 14px; }
        #purchase-history .ph-meta { flex-direction: column; align-items: flex-start; }
        #purchase-history .ph-status { padding: 5px 8px; font-size: 11px; }
        #purchase-history .ph-product {
            display: grid;
            grid-template-columns: 46px minmax(0, 1fr);
            gap: 8px 12px;
            padding: 16px 0;
        }
        #purchase-history .ph-icon { width: 46px; height: 46px; font-size: 22px; }
        #purchase-history .ph-info h2 { font-size: 14px; }
        #purchase-history .ph-price { grid-column: 2; text-align: left; white-space: normal; }
        #purchase-history .ph-total strong { font-size: 18px; }
    }
</style>

<main id="purchase-history" aria-labelledby="ph-title">

    <%-- DIEU HUONG --%>
    <div class="ph-topbar">
        <span class="ph-current">
            <i class="bi bi-clock-history" aria-hidden="true"></i>
            Lịch sử mua hàng
        </span>

        <a class="ph-shop"
           href="${pageContext.request.contextPath}/shop">
            <i class="bi bi-bag-plus" aria-hidden="true"></i>
            <span>Tiếp tục mua sắm</span>
            <i class="bi bi-arrow-right" aria-hidden="true"></i>
        </a>
    </div>

    <div class="ph-heading">
        <h1 id="ph-title">Lịch sử mua hàng</h1>
        <p>Theo dõi đơn hàng và xem lại sản phẩm đã mua.</p>
    </div>

    <%-- LOC TRANG THAI --%>
    <div class="ph-filters">
        <nav class="ph-tabs" aria-label="Lọc đơn hàng theo trạng thái">
            <c:forEach var="tab" items="${tabs}">
                <c:url var="tabUrl" value="/my-orders">
                    <c:param name="status" value="${tab.key}" />
                    <c:param name="q" value="${query}" />
                </c:url>

                <a href="<c:out value='${tabUrl}' />"
                   class="ph-tab ${activeTab == tab.key ? 'is-active' : ''}"
                   ${activeTab == tab.key ? 'aria-current="page"' : ''}>
                    <c:out value="${tab.value}" />
                    <span class="ph-count">
                        <c:out value="${tabCounts[tab.key]}" />
                    </span>
                </a>
            </c:forEach>
        </nav>

        <form class="ph-search"
              method="get"
              action="${pageContext.request.contextPath}/my-orders"
              role="search">
            <input type="hidden"
                   name="status"
                   value="<c:out value='${activeTab}' />">

            <i class="bi bi-search" aria-hidden="true"></i>

            <input type="search"
                   name="q"
                   maxlength="100"
                   aria-label="Tìm theo mã đơn, tên sản phẩm hoặc mã SKU"
                   value="<c:out value='${query}' />"
                   placeholder="Tìm mã đơn, tên sản phẩm hoặc mã SKU">

            <button type="submit">Tìm kiếm</button>
        </form>
    </div>

    <%-- SO KET QUA --%>
    <div class="ph-results">
        <span>
            <strong><c:out value="${resultCount}" /></strong> đơn hàng
            <c:if test="${not empty query}">
                cho “<c:out value="${query}" />”
            </c:if>
        </span>

        <c:choose>
            <c:when test="${not empty query}">
                <c:url var="clearUrl" value="/my-orders">
                    <c:param name="status" value="${activeTab}" />
                </c:url>
                <a href="<c:out value='${clearUrl}' />">Xóa tìm kiếm</a>
            </c:when>
            <c:otherwise>
                <span>Mới nhất trước</span>
            </c:otherwise>
        </c:choose>
    </div>

    <%-- KHONG CO DON HANG --%>
    <c:if test="${empty orders}">
        <section class="ph-empty">
            <i class="bi bi-bag" aria-hidden="true"></i>

            <h2>
                ${empty query
                    ? 'Chưa có đơn hàng ở mục này'
                    : 'Không tìm thấy đơn hàng'}
            </h2>

            <p>
                ${empty query
                    ? 'Các đơn hàng phù hợp sẽ xuất hiện tại đây.'
                    : 'Thử tìm bằng mã đơn hoặc tên sản phẩm khác.'}
            </p>

            <div class="ph-empty-actions">
                <a class="ph-button"
                   href="${pageContext.request.contextPath}/my-orders">
                    Xem tất cả đơn
                </a>
                <a class="ph-secondary"
                   href="${pageContext.request.contextPath}/shop">
                    <i class="bi bi-bag-plus" aria-hidden="true"></i>
                    Tiếp tục mua sắm
                </a>
            </div>
        </section>
    </c:if>

    <%-- DANH SACH DON HANG --%>
    <c:forEach var="order" items="${orders}">
        <article class="ph-order"
                 aria-label="Đơn hàng ${order.orderId}">

            <div class="ph-order-head">
                <div class="ph-meta">
                    <strong>
                        Đơn #<c:out value="${order.orderId}" />
                    </strong>
                    <span class="ph-date">
                        <fmt:formatDate value="${order.createdAt}"
                                        pattern="dd/MM/yyyy" />
                    </span>
                </div>

                <span class="ph-status
                      ${order.orderStatus == 'CANCELLED'
                          ? 'is-cancelled'
                          : (order.orderStatus == 'COMPLETED'
                              || order.orderStatus == 'DELIVERED'
                              ? 'is-completed' : '')}">
                    <c:out value="${statusLabels[order.orderStatus]}"
                           default="Đang cập nhật" />
                </span>
            </div>

            <div class="ph-products">
                <c:forEach var="item"
                           items="${orderItems[order.orderId]}">
                    <div class="ph-product">
                        <span class="ph-icon">
                            <i class="bi bi-box-seam" aria-hidden="true"></i>
                        </span>

                        <div class="ph-info">
                            <h2>
                                <c:out value="${item.productName}"
                                       default="Sản phẩm đã đặt" />
                            </h2>
                            <p>
                                Mã sản phẩm:
                                <c:out value="${item.skuCode}"
                                       default="${item.skuId}" />
                            </p>
                            <span>
                                Số lượng:
                                <c:out value="${item.quantity}" />
                            </span>
                        </div>

                        <div class="ph-price">
                            <fmt:formatNumber value="${item.price}"
                                              pattern="#,##0" />đ
                            <small>Đơn giá lúc đặt</small>
                        </div>
                    </div>
                </c:forEach>

                <c:if test="${empty orderItems[order.orderId]}">
                    <p class="ph-missing">
                        Chưa có thông tin sản phẩm cho đơn này.
                    </p>
                </c:if>
            </div>

            <div class="ph-order-foot">
                <div class="ph-total">
                    <span>Thành tiền</span>
                    <strong>
                        <fmt:formatNumber value="${order.totalAmount}"
                                          pattern="#,##0" />đ
                    </strong>
                </div>

                <c:url var="detailUrl" value="/my-orders/detail">
                    <c:param name="id" value="${order.orderId}" />
                </c:url>

                <a class="ph-button"
                   href="<c:out value='${detailUrl}' />">
                    <c:choose>
                        <c:when test="${order.orderStatus == 'CANCELLED'
                                        || order.orderStatus == 'COMPLETED'
                                        || order.orderStatus == 'DELIVERED'}">
                            Xem chi tiết
                        </c:when>
                        <c:otherwise>
                            Theo dõi đơn hàng
                        </c:otherwise>
                    </c:choose>
                    <i class="bi bi-arrow-right" aria-hidden="true"></i>
                </a>
            </div>
        </article>
    </c:forEach>

    <%-- PHAN TRANG --%>
    <c:if test="${pageCount > 1}">
        <nav class="ph-pagination"
             aria-label="Phân trang lịch sử mua hàng">

            <c:if test="${currentPage > 1}">
                <c:url var="prevUrl" value="/my-orders">
                    <c:param name="status" value="${activeTab}" />
                    <c:param name="q" value="${query}" />
                    <c:param name="page" value="${currentPage - 1}" />
                </c:url>

                <a class="ph-secondary"
                   href="<c:out value='${prevUrl}' />">
                    <i class="bi bi-arrow-left" aria-hidden="true"></i>
                    Trang trước
                </a>
            </c:if>

            <span>
                Trang <c:out value="${currentPage}" />
                / <c:out value="${pageCount}" />
            </span>

            <c:if test="${currentPage < pageCount}">
                <c:url var="nextUrl" value="/my-orders">
                    <c:param name="status" value="${activeTab}" />
                    <c:param name="q" value="${query}" />
                    <c:param name="page" value="${currentPage + 1}" />
                </c:url>

                <a class="ph-secondary"
                   href="<c:out value='${nextUrl}' />">
                    Trang sau
                    <i class="bi bi-arrow-right" aria-hidden="true"></i>
                </a>
            </c:if>
        </nav>
    </c:if>

</main>

<%@ include file="/WEB-INF/include/footer.jsp" %>