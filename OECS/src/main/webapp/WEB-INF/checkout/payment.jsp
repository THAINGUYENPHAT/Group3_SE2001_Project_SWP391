<%@ page pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ include file="/WEB-INF/include/header.jsp" %>
<%-- Keep the server clock in the view so a reloaded JSP also works with an older servlet. --%>
<jsp:useBean id="paymentClock" class="java.util.Date" scope="page"/>
<link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/payment.css">

<div class="payment-page">
    <a class="payment-back" href="${pageContext.request.contextPath}/my-orders/detail?id=${order.orderId}">
        <i class="bi bi-arrow-left" aria-hidden="true"></i> Chi tiết đơn hàng
    </a>
    <div class="payment-heading">
        <span class="payment-eyebrow">HOÀN TẤT ĐƠN HÀNG</span>
        <h1>Chỉ còn một bước thanh toán</h1>
        <p>Hoàn tất thanh toán để đơn hàng của bạn được chuyển sang bước xác nhận.</p>
    </div>
    <div class="payment-layout">
        <section class="payment-panel payment-summary" aria-labelledby="payment-summary-title">
            <div class="payment-summary-top">
                <span class="payment-icon"><i class="bi bi-bag-check" aria-hidden="true"></i></span>
                <span class="payment-status"><span></span> Chờ thanh toán</span>
            </div>
            <h2 id="payment-summary-title">Đơn hàng #${order.orderId}</h2>
            <p class="payment-muted">Thông tin thanh toán của bạn</p>
            <div class="payment-total">
                <span>Tổng thanh toán</span>
                <strong><fmt:formatNumber value="${order.totalAmount}" type="number" maxFractionDigits="0"/><small>đ</small></strong>
            </div>
            <dl class="payment-details">
                <div>
                    <dt>Phương thức</dt>
                    <dd class="payment-provider"><i class="bi bi-credit-card" aria-hidden="true"></i> <c:out value="${order.paymentMethod}"/></dd>
                </div>
                <div>
                    <dt>Hạn thanh toán</dt>
                    <dd><fmt:formatDate value="${order.paymentExpiresAt}" pattern="HH:mm:ss · dd/MM/yyyy" timeZone="Asia/Ho_Chi_Minh"/><small>Giờ Việt Nam</small></dd>
                </div>
            </dl>
            <div class="payment-timer-box">
                <i class="bi bi-clock" aria-hidden="true"></i>
                <div>
                    <span id="payment-timer-label">Thời gian thanh toán còn lại</span>
                    <strong id="payment-expiry" role="timer" aria-labelledby="payment-timer-label"
                            data-remaining-ms="${empty order.paymentExpiresAt ? '' : order.paymentExpiresAt.time - paymentClock.time}">--:--</strong>
                </div>
            </div>
            <p class="payment-reservation">Sản phẩm được giữ trong 15 phút từ lúc đặt đơn. Thử lại không gia hạn thời gian giữ hàng.</p>
        </section>
        <section class="payment-panel payment-actions" aria-labelledby="payment-action-title">
            <span class="payment-step">BƯỚC TIẾP THEO</span>
            <h2 id="payment-action-title">Thanh toán đơn hàng</h2>
            <p class="payment-muted">Bạn sẽ được chuyển đến cổng <strong><c:out value="${order.paymentMethod}"/></strong> để hoàn tất giao dịch.</p>
            <c:if test="${not empty sessionScope.paymentError}">
                <div class="alert alert-warning" role="alert"><c:out value="${sessionScope.paymentError}"/></div>
                <c:remove var="paymentError" scope="session"/>
            </c:if>
            <p id="payment-expired-message" class="alert alert-warning" role="status" hidden>Thời gian giữ hàng đã hết. Vui lòng xem trạng thái đơn hàng trước khi đặt lại.</p>
            <form method="post" action="${pageContext.request.contextPath}/payment/action">
                <input type="hidden" name="id" value="${order.orderId}">
                <input type="hidden" name="csrfToken" value="<c:out value='${sessionScope.paymentCsrf}'/>">
                <button id="payment-pay-button" type="submit" class="payment-button payment-button-primary" name="action" value="pay">
                    Thanh toán ngay <i class="bi bi-arrow-right" aria-hidden="true"></i>
                </button>
                <p class="payment-retry-hint">Nếu giao dịch trước chưa hoàn tất, bạn có thể thử lại bằng nút này.</p>
                <div class="payment-divider"><span>Hoặc thanh toán khi nhận hàng</span></div>
                <button id="payment-cod-button" type="submit" class="payment-button payment-button-secondary" name="action" value="cod">
                    <i class="bi bi-truck" aria-hidden="true"></i> Chuyển sang COD
                </button>
                <div class="payment-notice">
                    <i class="bi bi-info-circle" aria-hidden="true"></i>
                    <div><strong>Bạn đã bị trừ tiền?</strong><p>Hãy kiểm tra trạng thái đơn và chờ xác nhận trước khi thử lại. Khoản thanh toán sau khi hủy hoặc đổi COD sẽ được đối soát hoàn tiền.</p></div>
                </div>
                <div class="payment-bottom-actions">
                    <a href="${pageContext.request.contextPath}/my-orders/detail?id=${order.orderId}">Xem trạng thái đơn <i class="bi bi-arrow-up-right" aria-hidden="true"></i></a>
                    <button type="submit" class="payment-cancel" name="action" value="cancel">Hủy đơn hàng</button>
                </div>
            </form>
        </section>
    </div>
</div>
<script src="${pageContext.request.contextPath}/assets/js/payment.js?v=2"></script>
<%@ include file="/WEB-INF/include/footer.jsp" %>
