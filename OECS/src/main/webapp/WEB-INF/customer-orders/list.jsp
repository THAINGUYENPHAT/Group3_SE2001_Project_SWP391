<%@ page pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ include file="/WEB-INF/include/header.jsp" %>
<link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/customer-orders.css">

<div class="purchases-root purchase-layout">
    <aside class="purchase-sidebar" aria-label="Tài khoản mua hàng">
        <div class="purchase-account">
            <span class="purchase-avatar"><i class="bi bi-person" aria-hidden="true"></i></span>
            <div><small>Tài khoản của bạn</small><strong><c:out value="${sessionScope.loggedInUser.username}" /></strong></div>
        </div>
        <nav class="purchase-side-links">
            <a href="${pageContext.request.contextPath}/my-orders" class="${activeTab != 'COMPLETED' ? 'is-active' : ''}"><i class="bi bi-bag-check" aria-hidden="true"></i> Đơn mua</a>
            <a href="${pageContext.request.contextPath}/my-orders?status=COMPLETED" class="${activeTab == 'COMPLETED' ? 'is-active' : ''}"><i class="bi bi-clock-history" aria-hidden="true"></i> Lịch sử mua hàng</a>
            <a href="${pageContext.request.contextPath}/shop"><i class="bi bi-shop" aria-hidden="true"></i> Tiếp tục mua sắm</a>
        </nav>
        <p class="purchase-sidebar-note">Mọi đơn hàng, từ lúc đặt đến khi nhận, ở cùng một nơi.</p>
    </aside>
    <section class="purchase-main" aria-labelledby="purchase-title">
        <div class="purchase-heading">
            <div><span class="purchase-eyebrow">OECS / TÀI KHOẢN</span><h1 id="purchase-title">${activeTab == 'COMPLETED' ? 'Lịch sử mua hàng' : 'Đơn mua'}</h1><p>Theo dõi đơn hàng và xem lại những sản phẩm bạn đã mua.</p></div>
            <span class="purchase-heading-icon"><i class="bi bi-bag-check" aria-hidden="true"></i></span>
        </div>
        <nav class="purchase-tabs" aria-label="Lọc đơn hàng theo trạng thái">
            <c:forEach var="tab" items="${tabs}">
                <c:url var="tabUrl" value="/my-orders"><c:param name="status" value="${tab.key}" /><c:param name="q" value="${query}" /></c:url>
                <a href="<c:out value='${tabUrl}' />" class="${activeTab == tab.key ? 'is-active' : ''}" ${activeTab == tab.key ? 'aria-current="page"' : ''}>
                    <c:out value="${tab.value}" /><span class="purchase-tab-count">${tabCounts[tab.key]}</span>
                </a>
            </c:forEach>
        </nav>
        <form class="purchase-search" method="get" action="${pageContext.request.contextPath}/my-orders" role="search">
            <input type="hidden" name="status" value="<c:out value='${activeTab}' />">
            <i class="bi bi-search" aria-hidden="true"></i>
            <label for="purchase-query" class="visually-hidden">Tìm đơn theo mã đơn, tên sản phẩm hoặc mã SKU</label>
            <input id="purchase-query" type="search" name="q" maxlength="100" value="<c:out value='${query}' />" placeholder="Tìm theo mã đơn, tên sản phẩm hoặc mã SKU">
            <button type="submit">Tìm kiếm</button>
        </form>
        <div class="purchase-results">
            <span><strong>${resultCount}</strong> đơn hàng<c:if test="${not empty query}"> cho “<c:out value="${query}" />”</c:if></span>
            <c:choose>
                <c:when test="${not empty query}"><c:url var="clearUrl" value="/my-orders"><c:param name="status" value="${activeTab}" /></c:url><a href="<c:out value='${clearUrl}' />">Xóa tìm kiếm</a></c:when>
                <c:otherwise><span>Mới nhất trước</span></c:otherwise>
            </c:choose>
        </div>
        <c:if test="${empty orders}">
            <div class="purchase-empty">
                <span class="purchase-empty-icon"><i class="bi bi-bag" aria-hidden="true"></i></span>
                <h2>${empty query ? 'Chưa có đơn hàng ở mục này' : 'Không tìm thấy đơn hàng'}</h2>
                <p>${empty query ? 'Khi có đơn hàng phù hợp, bạn sẽ thấy thông tin tại đây.' : 'Thử một mã đơn hoặc tên sản phẩm khác nhé.'}</p>
                <a class="purchase-button" href="${pageContext.request.contextPath}/my-orders">Xem tất cả đơn</a>
                <a class="purchase-text-link" href="${pageContext.request.contextPath}/shop">Khám phá sản phẩm</a>
            </div>
        </c:if>
        <c:forEach var="order" items="${orders}">
            <article class="purchase-card" aria-label="Đơn hàng ${order.orderId}">
                <div class="purchase-card-head">
                    <div class="purchase-order-reference"><strong>OECS STORE</strong><span>Đơn #${order.orderId}</span><time><fmt:formatDate value="${order.createdAt}" pattern="dd/MM/yyyy" /></time></div>
                    <span class="purchase-status ${order.orderStatus == 'CANCELLED' ? 'is-cancelled' : ''}"><c:out value="${statusLabels[order.orderStatus]}" default="Đang cập nhật" /></span>
                </div>
                <div class="purchase-products">
                    <c:forEach var="item" items="${orderItems[order.orderId]}">
                        <div class="purchase-product">
                            <span class="purchase-product-icon"><i class="bi bi-box-seam" aria-hidden="true"></i></span>
                            <div class="purchase-product-info"><h2><c:out value="${item.productName}" default="Sản phẩm đã đặt" /></h2><p>Mã sản phẩm: <c:out value="${item.skuCode}" default="${item.skuId}" /></p><span>x${item.quantity}</span></div>
                            <div class="purchase-product-price"><fmt:formatNumber value="${item.price}" maxFractionDigits="0" />đ<small>Đơn giá lúc đặt</small></div>
                        </div>
                    </c:forEach>
                    <c:if test="${empty orderItems[order.orderId]}"><p class="purchase-muted">Chưa có thông tin sản phẩm cho đơn này.</p></c:if>
                </div>
                <div class="purchase-card-foot">
                    <div class="purchase-card-note"><i class="bi bi-shield-check" aria-hidden="true"></i><span>Giá và thông tin nhận hàng được lưu khi đặt đơn.</span></div>
                    <div class="purchase-card-actions">
                        <div class="purchase-total">Thành tiền: <strong><fmt:formatNumber value="${order.totalAmount}" maxFractionDigits="0" />đ</strong></div>
                        <a class="purchase-button" href="${pageContext.request.contextPath}/my-orders/detail?id=${order.orderId}">${order.orderStatus == 'CANCELLED' || order.orderStatus == 'COMPLETED' || order.orderStatus == 'DELIVERED' ? 'Xem chi tiết' : 'Theo dõi đơn hàng'} <i class="bi bi-arrow-right" aria-hidden="true"></i></a>
                    </div>
                </div>
            </article>
        </c:forEach>
        <c:if test="${pageCount > 1}">
            <nav class="purchase-pagination" aria-label="Phân trang đơn mua">
                <c:if test="${currentPage > 1}"><c:url var="prevUrl" value="/my-orders"><c:param name="status" value="${activeTab}" /><c:param name="q" value="${query}" /><c:param name="page" value="${currentPage - 1}" /></c:url><a href="<c:out value='${prevUrl}' />" class="purchase-button-secondary">← Trang trước</a></c:if>
                <span>Trang ${currentPage} / ${pageCount}</span>
                <c:if test="${currentPage < pageCount}"><c:url var="nextUrl" value="/my-orders"><c:param name="status" value="${activeTab}" /><c:param name="q" value="${query}" /><c:param name="page" value="${currentPage + 1}" /></c:url><a href="<c:out value='${nextUrl}' />" class="purchase-button-secondary">Trang sau →</a></c:if>
            </nav>
        </c:if>
    </section>
</div>
<%@ include file="/WEB-INF/include/footer.jsp" %>
