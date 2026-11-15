<%@ page pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<%@ include file="/WEB-INF/include/header.jsp" %>
<link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/payment.css">

<div class="payment-result">
    <div class="payment-panel" role="status" aria-live="polite">
        <c:choose>
            <c:when test="${paymentSuccess}">
                <svg class="text-success mx-auto" width="88" height="88" viewBox="0 0 88 88" fill="none" aria-hidden="true">
                    <circle cx="44" cy="44" r="40" fill="currentColor" fill-opacity="0.1"/>
                    <circle cx="44" cy="44" r="32" stroke="currentColor" stroke-width="3"/>
                    <path d="M29 44L39 54L59 34" stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                <h1>Thanh toán thành công!</h1>
            </c:when>
            <c:otherwise>
                <i class="bi bi-exclamation-circle text-warning display-3" aria-hidden="true"></i>
                <h1>Thanh toán chưa hoàn tất</h1>
            </c:otherwise>
        </c:choose>

        <p class="payment-result-message"><c:out value="${paymentResultMessage}"/></p>

        <c:if test="${paymentSuccess}">
            <p class="payment-redirect">Tự động về trang chủ sau <strong id="payment-redirect-countdown">3</strong> giây.</p>
        </c:if>

        <div class="payment-result-links">
            <a id="payment-home-link" class="payment-button payment-button-primary" href="${pageContext.request.contextPath}/home">Về trang chủ <i class="bi bi-arrow-right" aria-hidden="true"></i></a>
            <a class="payment-button payment-button-secondary" href="${pageContext.request.contextPath}/my-orders">Xem đơn mua</a>
        </div>
    </div>
</div>

<script src="${pageContext.request.contextPath}/assets/js/payment.js?v=2"></script>

<%@ include file="/WEB-INF/include/footer.jsp" %>
