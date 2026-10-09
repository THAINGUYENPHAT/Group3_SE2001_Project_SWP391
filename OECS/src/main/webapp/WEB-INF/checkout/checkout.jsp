<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@ include file="/WEB-INF/include/header.jsp" %>

<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
/* Let the shared header scroll with the page on checkout only. */
.app-header { position: static; }
/* Scoped to checkout so other store pages retain their existing presentation. */
.checkout-page {
    max-width: 1144px;
    margin: 0 auto;
    padding: 4px 0 32px;
    --checkout-ink: #0f1b2d;
    --checkout-muted: #64748b;
    --checkout-line: #e5e9f0;
    --checkout-bg: #f4f6fa;
    --checkout-brand: #1d5bff;
    --checkout-soft: #eaf0ff;
    font-family: "Be Vietnam Pro", system-ui, -apple-system, "Segoe UI", sans-serif;
    color: var(--checkout-ink);
    font-size: 15px;
    line-height: 1.55;
    -webkit-font-smoothing: antialiased;
}
.checkout-page :focus-visible { outline: 3px solid #1d5bff66; outline-offset: 3px; }
.checkout-steps { display: flex; align-items: center; justify-content: center; gap: 16px; margin-bottom: 24px; color: var(--checkout-muted); font-size: 15px; }
.checkout-step { display: flex; align-items: center; gap: 10px; color: inherit; text-decoration: none; }
.checkout-step-dot { width: 32px; height: 32px; border-radius: 50%; display: grid; place-items: center; flex: none; background: var(--checkout-line); font-size: 15px; font-weight: 600; }
.checkout-step.is-done, .checkout-step.is-current { color: var(--checkout-ink); }
.checkout-step.is-done .checkout-step-dot, .checkout-step-bar.is-done { background: #0f9d6b; color: #fff; }
.checkout-step.is-current { font-weight: 600; }
.checkout-step.is-current .checkout-step-dot { background: var(--checkout-brand); color: #fff; }
.checkout-step-bar { width: 100px; height: 3px; border-radius: 2px; background: var(--checkout-line); }
.checkout-heading { align-items: flex-end !important; gap: 16px; margin-bottom: 24px !important; }
.checkout-heading h1 { font-size: 30px; letter-spacing: -.02em; line-height: 1.2; }
.checkout-heading p { margin-top: 6px; }
.checkout-heading > a { flex-shrink: 0; }
.checkout-layout { display: grid; grid-template-columns: minmax(0, 1fr) 390px; gap: 24px; align-items: start; }
.checkout-details { display: grid; gap: 16px; min-width: 0; }
.checkout-details > .card { margin: 0 !important; }
.checkout-page .card { border: 1px solid var(--checkout-line) !important; border-radius: 14px !important; background: #fff; box-shadow: none !important; min-width: 0; }
.checkout-page .card-body { padding: 24px !important; }
.checkout-page h5 { font-size: 18px; font-weight: 600 !important; line-height: 1.4; margin-bottom: 16px !important; }
.checkout-details h5 { display: flex; align-items: center; gap: 12px; }
.checkout-details h5 > i { display: grid; place-items: center; width: 34px; height: 34px; border-radius: 9px; flex: none; background: var(--checkout-soft); color: var(--checkout-brand) !important; margin: 0 !important; font-size: 18px; }
.checkout-address-heading { flex-wrap: wrap; gap: 12px; margin-bottom: 16px !important; }
.checkout-address-heading h5 { margin: 0 !important; }
.checkout-page .text-muted { color: var(--checkout-muted) !important; }
.checkout-page .btn { padding: 9px 16px; border-radius: 10px; font-size: 14px; font-weight: 500; }
.checkout-page .btn-sm { padding: 8px 12px; border-radius: 9px; font-size: 14px; }
.checkout-page .btn-primary {
    --bs-btn-bg: var(--checkout-brand); --bs-btn-border-color: var(--checkout-brand);
    --bs-btn-hover-bg: #134be0; --bs-btn-hover-border-color: #134be0;
    --bs-btn-active-bg: #134be0; --bs-btn-active-border-color: #134be0;
    --bs-btn-disabled-bg: var(--checkout-brand); --bs-btn-disabled-border-color: var(--checkout-brand);
    --bs-btn-focus-shadow-rgb: 29, 91, 255;
}
.checkout-page .btn-outline-primary {
    --bs-btn-color: var(--checkout-brand); --bs-btn-border-color: var(--checkout-brand);
    --bs-btn-hover-color: var(--checkout-brand); --bs-btn-hover-bg: var(--checkout-soft); --bs-btn-hover-border-color: var(--checkout-brand);
    --bs-btn-active-bg: var(--checkout-brand); --bs-btn-active-border-color: var(--checkout-brand);
    --bs-btn-focus-shadow-rgb: 29, 91, 255;
}
.checkout-page .btn-outline-secondary, .checkout-page #openAddressModalButton { color: var(--checkout-ink); border-color: var(--checkout-line); background: #fff; }
.checkout-page .btn-outline-secondary:hover, .checkout-page #openAddressModalButton:hover { border-color: #c5cddb; background: #f8fafc; }
.checkout-page .form-control { font-size: 16px; padding: 10px 14px; border-color: var(--checkout-line); border-radius: 10px; }
.checkout-page .form-control:focus { border-color: var(--checkout-brand); box-shadow: 0 0 0 3px #1d5bff26; }
.checkout-page #selectedAddressCard { border: 1.5px solid var(--checkout-brand) !important; background: #f7f9ff !important; border-radius: 12px !important; padding: 16px 18px !important; }
.checkout-address-person { display: flex; align-items: center; flex-wrap: wrap; gap: 8px 12px; }
.checkout-page #selectedAddressName { font-size: 16px; overflow-wrap: anywhere; }
.checkout-page #selectedAddressLine { margin-top: 6px !important; overflow-wrap: anywhere; font-size: 15px; }
.checkout-page #selectedDefaultBadge { margin: 0 !important; padding: 4px 9px; border-radius: 999px; font-size: 13px; color: var(--checkout-brand); background: var(--checkout-soft) !important; }
.checkout-product { display: grid; grid-template-columns: 72px minmax(0, 1fr) auto; align-items: center; gap: 16px; padding: 4px 0; }
.checkout-product + .checkout-product { margin-top: 20px; padding-top: 20px; border-top: 1px solid var(--checkout-line); }
.checkout-product-icon { width: 72px; height: 72px; border-radius: 14px; background: linear-gradient(135deg, #eef2f9, #dde5f2); display: grid; place-items: center; color: #8a98b4; font-size: 30px; }
.checkout-product-info { font-size: 16px; overflow-wrap: anywhere; min-width: 0; }
.checkout-product-info small { display: block; font-size: 14px; margin-top: 2px; }
.checkout-product-quantity { display: inline-block; font-size: 14px; margin-top: 10px; padding: 2px 10px; border-radius: 999px; background: var(--checkout-bg); font-weight: 500; }
.checkout-product-price { text-align: right; font-variant-numeric: tabular-nums; }
.checkout-product-unit { font-size: 14px; color: var(--checkout-muted); }
.checkout-product-total { font-size: 18px; font-weight: 700; margin-top: 2px; }
.checkout-product-note { margin: 18px 0 0; padding-top: 18px; border-top: 1px dashed var(--checkout-line); color: var(--checkout-muted); font-size: 14.5px; }
.checkout-product-note a { color: var(--checkout-brand); text-decoration: none; font-weight: 500; }
.checkout-product-note a:hover { text-decoration: underline; }
.checkout-voucher-input { display: flex; gap: 10px; margin-bottom: 12px; }
.checkout-voucher-input input { min-width: 0; flex: 1; padding: 11px 14px !important; }
.checkout-voucher-input input::placeholder { color: #9aa6ba; }
.checkout-voucher-input button { flex: none; padding: 0 22px !important; font-weight: 600 !important; }
.checkout-payment-options { display: grid; gap: 12px; }
.checkout-payment { display: flex; align-items: center; gap: 12px; padding: 16px 18px; border: 1.5px solid var(--checkout-line); border-radius: 12px; cursor: pointer; }
.checkout-payment-selected { border-color: var(--checkout-brand); background: #f7f9ff; }
.checkout-payment input { width: 21px; height: 21px; margin: 0; flex: none; accent-color: var(--checkout-brand); }
.checkout-payment-copy { flex: 1; min-width: 0; font-size: 16px; font-weight: 600; }
.checkout-payment-description { display: block; color: var(--checkout-muted); font-size: 14.5px; font-weight: 400; }
.checkout-payment-disabled { background: #fafbfd; color: #8a98b4; cursor: not-allowed; }
.checkout-soon { flex: none; font-size: 13px; color: var(--checkout-muted); background: var(--checkout-bg); padding: 3px 10px; border-radius: 999px; }
.checkout-summary-column { position: sticky; top: 20px; min-width: 0; }
.checkout-page .checkout-summary { background: var(--checkout-ink); color: #fff; border: 0 !important; border-radius: 20px !important; }
.checkout-summary .card-body { padding: 28px !important; }
.checkout-summary h5 { margin-bottom: 18px !important; }
.checkout-summary .card-body > .d-flex { gap: 16px; padding: 9px 0; margin: 0 !important; color: #b8c3d6; }
.checkout-summary .card-body > .d-flex strong { color: #fff; font-weight: 500; text-align: right; }
.checkout-summary .checkout-free, .checkout-summary .text-success { color: #5be0ac !important; }
.checkout-summary hr { margin: 16px 0 22px; border-color: #ffffff24; opacity: 1; }
.checkout-grand-total { display: flex; flex-wrap: wrap; justify-content: space-between; gap: 8px 16px; align-items: baseline; }
.checkout-grand-total > strong { color: #b8c3d6; font-weight: 400; }
.checkout-summary h4 { font-size: 34px; letter-spacing: -.02em; color: #fff !important; overflow-wrap: anywhere; max-width: 100%; margin-left: auto; text-align: right; }
.checkout-summary #placeOrderButton { margin-top: 20px; padding: 15px !important; border: 0; border-radius: 14px; font-size: 16px; min-height: 54px; }
.checkout-summary-note { font-size: 13.5px; color: #8a98b4; text-align: center; margin: 12px 0 0; }
.checkout-summary #needAddressMessage { color: #ffb4bf !important; }
.checkout-trust { display: grid; gap: 12px; font-size: 14px; color: #b8c3d6; margin-top: 18px; }
.checkout-trust > div { display: flex; align-items: flex-start; gap: 9px; }
.checkout-trust i { flex: none; color: #5be0ac; font-size: 18px; }
.checkout-page .modal-content { border: 1px solid var(--checkout-line); border-radius: 14px !important; }
@media (max-width: 1100px) and (min-width: 901px) {
    .checkout-product { grid-template-columns: 64px minmax(0, 1fr); gap: 14px; }
    .checkout-product-icon { width: 64px; height: 64px; }
    .checkout-product-price { grid-column: 2; text-align: left; }
}
@media (max-width: 900px) {
    .checkout-layout { grid-template-columns: minmax(0, 1fr); }
    .checkout-summary-column { position: static; }
    .checkout-steps { font-size: 14px; gap: 10px; }
    .checkout-step-bar { width: 40px; }
}
@media (max-width: 560px) {
    .checkout-steps { gap: 8px; font-size: 12px; align-items: flex-start; }
    .checkout-step { flex-direction: column; gap: 6px; text-align: center; }
    .checkout-step-dot { width: 28px; height: 28px; font-size: 14px; }
    .checkout-step-bar { flex: 1; min-width: 12px; margin-top: 13px; }
    .checkout-heading { flex-direction: column; align-items: flex-start !important; }
    .checkout-heading h1 { font-size: 28px; }
    .checkout-page .card-body { padding: 18px !important; }
    .checkout-page h5 { font-size: 18px; }
    .checkout-product { grid-template-columns: 56px minmax(0, 1fr); gap: 14px; }
    .checkout-product-icon { width: 56px; height: 56px; font-size: 28px; }
    .checkout-product-price { grid-column: 2; text-align: left; display: flex; flex-wrap: wrap; gap: 4px 10px; align-items: baseline; }
    .checkout-voucher-input button { padding: 0 14px !important; }
    .checkout-payment { padding: 16px 12px; gap: 10px; }
    .checkout-payment-copy { font-size: 15px; }
    .checkout-page #selectedAddressCard { padding: 16px !important; }
    .checkout-summary h4 { font-size: 34px; }
}
</style>

<div class="checkout-page">
<nav class="checkout-steps" aria-label="Các bước đặt hàng">
    <a class="checkout-step is-done" href="${pageContext.request.contextPath}/cart"><span class="checkout-step-dot" aria-hidden="true">✓</span>Giỏ hàng</a>
    <span class="checkout-step-bar is-done" aria-hidden="true"></span>
    <span class="checkout-step is-current" aria-current="step"><span class="checkout-step-dot">2</span>Xác nhận đơn hàng</span>
    <span class="checkout-step-bar" aria-hidden="true"></span>
    <span class="checkout-step"><span class="checkout-step-dot">3</span>Hoàn tất</span>
</nav>
<!-- TIEU DE CHECKOUT -->
<div class="checkout-heading d-flex justify-content-between align-items-center mb-4">
    <div>
        <h1 class="fw-bold mb-1">Xác nhận đơn hàng</h1>
        <p class="text-muted mb-0">
            Vui lòng kiểm tra thông tin trước khi đặt hàng.
        </p>
    </div>

    <a href="${pageContext.request.contextPath}/cart"
       class="btn btn-outline-secondary">
        <i class="bi bi-arrow-left me-1"></i>
        Về giỏ hàng
    </a>
</div>

<!-- THONG BAO TU SERVER -->
<c:if test="${not empty sessionScope.checkoutError}">
    <div class="alert alert-danger">
        <c:out value="${sessionScope.checkoutError}" />
    </div>
    <c:remove var="checkoutError" scope="session" />
</c:if>

<c:if test="${not empty sessionScope.checkoutMessage}">
    <div class="alert alert-success">
        <c:out value="${sessionScope.checkoutMessage}" />
    </div>
    <c:remove var="checkoutMessage" scope="session" />
</c:if>

<div class="checkout-layout">

    <!-- COT TRAI -->
    <div class="checkout-details">

        <!-- DIA CHI GIAO HANG -->
        <div class="card shadow-sm border-0 rounded-4 mb-4">
            <div class="card-body p-4">

                <div class="checkout-address-heading d-flex justify-content-between align-items-center mb-3">
                    <h5 class="fw-bold mb-0">
                        <i class="bi bi-geo-alt text-primary me-2"></i>
                        Địa chỉ giao hàng
                    </h5>

                    <div class="d-flex gap-2">
                        <button type="button"
                                id="openAddressModalButton"
                                class="btn btn-outline-primary btn-sm"
                                data-bs-toggle="modal"
                                data-bs-target="#addressModal"
                                ${empty addresses ? 'disabled' : ''}>
                            Thay đổi
                        </button>

                        <button type="button"
                                class="btn btn-primary btn-sm"
                                data-bs-toggle="modal"
                                data-bs-target="#addAddressModal">
                            <i class="bi bi-plus-lg"></i>
                            Thêm địa chỉ
                        </button>
                    </div>
                </div>

                <!-- THONG BAO CHUA CO DIA CHI -->
                <div id="noAddressMessage"
                     class="alert alert-warning mb-0"
                     style="${empty selectedAddress ? '' : 'display:none;'}">
                    Bạn chưa có địa chỉ giao hàng.
                    Hãy thêm địa chỉ để tiếp tục.
                </div>

                <!-- DIA CHI DANG SU DUNG -->
                <div id="selectedAddressCard"
                     class="border rounded-3 p-3 bg-light"
                     style="${empty selectedAddress ? 'display:none;' : ''}">

                    <div class="checkout-address-person">
                    <div class="fw-semibold" id="selectedAddressName">
                        <c:out value="${selectedAddress.recipientName}" />
                        |
                        <c:out value="${selectedAddress.phoneNumber}" />
                    </div>

                    <span id="selectedDefaultBadge"
                          class="badge bg-primary mt-2"
                          style="${selectedAddress.defaultAddress ? '' : 'display:none;'}">
                        Mặc định
                    </span>
                    </div>
                    <div class="text-muted mt-1" id="selectedAddressLine">
                        <c:out value="${selectedAddress.addressLine}" />
                    </div>
                </div>

            </div>
        </div>

        <!-- DANH SACH SAN PHAM -->
        <div class="card shadow-sm border-0 rounded-4 mb-4">
            <div class="card-body p-4">

                <h5 class="fw-bold mb-3">
                    <i class="bi bi-bag-check text-primary me-2"></i>
                    Sản phẩm đặt mua
                </h5>

                <div class="checkout-products" role="list" aria-label="Sản phẩm đặt mua">
                            <c:forEach var="item" items="${cartItems}">
                                        <div class="checkout-product" role="listitem">
                                            <span class="checkout-product-icon" aria-hidden="true">
                                                <i class="bi bi-box-seam"></i>
                                            </span>
                                            <div class="checkout-product-info">
                                        <div class="fw-semibold">
                                            <c:out value="${item.productName}" />
                                        </div>

                                        <small class="text-muted">
                                            SKU:
                                            <c:out value="${item.skuCode}" />
                                        </small>
                                        <span class="checkout-product-quantity">Số lượng: ${item.quantity}</span>
                                            </div>
                                    <div class="checkout-product-price">
                                    <div class="checkout-product-unit">
                                        <span class="visually-hidden">Đơn giá: </span>
                                        <fmt:formatNumber
                                            value="${item.price}"
                                            type="number"
                                            maxFractionDigits="0" />đ
                                    </div>
                                    <div class="checkout-product-total">
                                        <span class="visually-hidden">Thành tiền: </span>
                                        <fmt:formatNumber
                                            value="${item.price * item.quantity}"
                                            type="number"
                                            maxFractionDigits="0" />đ
                                    </div>
                                    </div>
                                        </div>
                            </c:forEach>
                </div>

                <p class="checkout-product-note">Muốn thay đổi số lượng?
                    <a href="${pageContext.request.contextPath}/cart">Quay lại giỏ hàng</a>
                </p>

            </div>
        </div>

        <!-- MA GIAM GIA -->
        <div class="card shadow-sm border-0 rounded-4 mb-4">
            <div class="card-body p-4">

                <h5 class="fw-bold mb-3">
                    <i class="bi bi-ticket-perforated text-primary me-2"></i>
                    Mã giảm giá
                </h5>

                <!-- VOUCHER DANG AP DUNG -->
                <c:if test="${not empty appliedVoucher}">
                    <div class="alert alert-success">
                        Đang áp dụng:
                        <strong>
                            <c:out value="${appliedVoucher.code}" />
                        </strong>

                        <form action="${pageContext.request.contextPath}/checkout"
                              method="post"
                              class="mt-2">

                            <input type="hidden"
                                   name="action"
                                   value="removeVoucher">

                            <button type="submit"
                                    class="btn btn-outline-danger btn-sm">
                                Bỏ mã
                            </button>
                        </form>
                    </div>
                </c:if>

                <!-- NHAP VOUCHER -->
                <form action="${pageContext.request.contextPath}/checkout"
                      method="post">

                    <input type="hidden"
                           name="action"
                           value="applyVoucher">

                    <div class="checkout-voucher-input">
                        <input type="text"
                               name="voucherCode"
                               class="form-control"
                               placeholder="Nhập mã giảm giá"
                               aria-label="Mã giảm giá"
                               maxlength="50"
                               required>

                        <button type="submit"
                                class="btn btn-outline-primary">
                            Áp dụng
                        </button>
                    </div>
                </form>

                <!-- VOUCHER KHA DUNG -->
                <c:if test="${not empty availableVouchers}">
                    <div class="fw-semibold mb-2">
                        Voucher khả dụng
                    </div>

                    <div class="d-flex flex-wrap gap-2">
                        <c:forEach var="voucher" items="${availableVouchers}">

                            <form action="${pageContext.request.contextPath}/checkout"
                                  method="post">

                                <input type="hidden"
                                       name="action"
                                       value="applyVoucher">

                                <input type="hidden"
                                       name="voucherCode"
                                       value="<c:out value='${voucher.code}' />">

                                <button type="submit"
                                        class="btn btn-outline-success btn-sm">
                                    <i class="bi bi-ticket-perforated me-1"></i>
                                    <c:out value="${voucher.code}" />
                                </button>
                            </form>

                        </c:forEach>
                    </div>
                </c:if>

                <c:if test="${empty availableVouchers}">
                    <p class="text-muted small mb-0">
                        Hiện không có voucher khả dụng.
                    </p>
                </c:if>

            </div>
        </div>

        <!-- PHUONG THUC THANH TOAN -->
        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-body p-4">

                <h5 class="fw-bold mb-3">
                    <i class="bi bi-credit-card text-primary me-2"></i>
                    Phương thức thanh toán
                </h5>

                <div class="checkout-payment-options" role="radiogroup" aria-label="Phương thức thanh toán">
                <label class="checkout-payment checkout-payment-selected">
                    <input type="radio"
                           name="paymentMethod"
                           value="COD"
                           form="orderForm"
                           checked>

                    <span class="checkout-payment-copy"><span class="fw-semibold">
                        Thanh toán khi nhận hàng (COD)
                    </span>

                    <span class="checkout-payment-description">
                        Thanh toán khi nhận được sản phẩm.
                    </span></span>
                </label>

                <label class="checkout-payment checkout-payment-disabled">
                    <input type="radio" disabled>
                    <span class="checkout-payment-copy">VNPay</span>
                    <span class="checkout-soon">Sắp ra mắt</span>
                </label>

                <label class="checkout-payment checkout-payment-disabled">
                    <input type="radio" disabled>
                    <span class="checkout-payment-copy">MoMo</span>
                    <span class="checkout-soon">Sắp ra mắt</span>
                </label>
                </div>

            </div>
        </div>
    </div>

    <!-- COT PHAI: TONG KET -->
    <aside class="checkout-summary-column" aria-label="Thông tin thanh toán">
        <div class="card shadow-sm border-0 rounded-4 checkout-summary">
            <div class="card-body p-4">

                <h5 class="fw-bold mb-4">
                    Thông tin thanh toán
                </h5>

                <div class="d-flex justify-content-between mb-3">
                    <span>Tiền hàng</span>
                    <strong>
                        <fmt:formatNumber
                            value="${subtotal}"
                            type="number"
                            maxFractionDigits="0" />đ
                    </strong>
                </div>

                <div class="d-flex justify-content-between mb-3">
                    <span>Phí vận chuyển</span>
                    <span class="checkout-free">Miễn phí</span>
                </div>

                <div class="d-flex justify-content-between mb-3">
                    <span>Giảm giá</span>
                    <span class="text-success">
                        -<fmt:formatNumber
                            value="${discount}"
                            type="number"
                            maxFractionDigits="0" />đ
                    </span>
                </div>

                <hr>

                <div class="checkout-grand-total">
                    <strong>Tổng thanh toán</strong>
                    <h4 class="text-danger fw-bold mb-0">
                        <fmt:formatNumber
                            value="${totalAmount}"
                            type="number"
                            maxFractionDigits="0" />đ
                    </h4>
                </div>

                <!-- FORM DAT HANG -->
                <form id="orderForm"
                      action="${pageContext.request.contextPath}/checkout"
                      method="post">

                    <input type="hidden"
                           name="action"
                           value="placeOrder">
                    <input type="hidden"
                           name="checkoutToken"
                           value="<c:out value='${sessionScope.checkoutToken}' />">

                    <input type="hidden"
                           name="addressId"
                           id="orderAddressId"
                           value="${selectedAddress.addressId}">

                    <button type="submit"
                            id="placeOrderButton"
                            class="btn btn-primary w-100 py-3 fw-semibold"
                            ${empty selectedAddress ? 'disabled' : ''}>
                        <i class="bi bi-bag-check me-1"></i>
                        Đặt hàng COD
                    </button>
                </form>

                <p id="needAddressMessage"
                   class="text-danger small text-center mt-2"
                   style="${empty selectedAddress ? '' : 'display:none;'}">
                    Vui lòng thêm địa chỉ trước khi đặt hàng.
                </p>

                <p class="checkout-summary-note">
                    Vui lòng kiểm tra đơn hàng trước khi xác nhận.
                </p>
                <div class="checkout-trust">
                    <div><i class="bi bi-shield-check" aria-hidden="true"></i><span>Hàng chính hãng, bảo hành đầy đủ</span></div>
                    <div><i class="bi bi-arrow-counterclockwise" aria-hidden="true"></i><span>Đổi trả trong 7 ngày nếu lỗi do nhà sản xuất</span></div>
                </div>

            </div>
        </div>
    </aside>
</div>

<!-- MODAL CHON VA SUA DIA CHI -->
<div class="modal fade"
     id="addressModal"
     tabindex="-1"
     aria-hidden="true">

    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content rounded-4">

            <div class="modal-header">
                <h5 class="modal-title fw-bold">
                    Chọn địa chỉ giao hàng
                </h5>

                <button type="button"
                        class="btn-close"
                        data-bs-dismiss="modal"
                        aria-label="Đóng"></button>
            </div>

            <!-- THONG BAO AJAX -->
            <div id="addressModalMessage"
                 class="alert mx-3 mt-3 mb-0 d-none"
                 role="alert"></div>

            <!-- DANH SACH DIA CHI -->
            <div id="addressList"
                 class="modal-body"
                 style="max-height: 400px; overflow-y: auto;">

                <c:forEach var="address" items="${addresses}">
                    <div class="border rounded-3 p-3 mb-2 address-option"
                         data-address-id="${address.addressId}"
                         data-default="${address.defaultAddress}">

                        <div class="d-flex flex-wrap gap-3 align-items-start">

                            <input type="radio"
                                   class="form-check-input mt-1 address-radio"
                                   name="modalAddressId"
                                   value="${address.addressId}"
                                   ${selectedAddress.addressId == address.addressId ? 'checked' : ''}>

                            <!-- THONG TIN DIA CHI -->
                            <div class="flex-grow-1">
                                <label class="fw-semibold d-block address-name">
                                    <span class="address-recipient"><c:out value="${address.recipientName}" /></span>
                                    |
                                    <span class="address-phone"><c:out value="${address.phoneNumber}" /></span>
                                </label>

                                <div class="text-muted small address-line">
                                    <c:out value="${address.addressLine}" />
                                </div>

                                <span class="badge bg-primary mt-2 default-address-badge"
                                      style="${address.defaultAddress ? '' : 'display:none;'}">
                                    Mặc định
                                </span>
                            </div>

                            <div class="d-flex align-items-center gap-2 ms-auto flex-shrink-0">
                                <button type="button"
                                        class="btn btn-link btn-sm px-1 py-0 text-decoration-none text-secondary edit-address-button">
                                    Sửa
                                </button>

                                <form action="${pageContext.request.contextPath}/checkout"
                                      method="post"
                                      class="delete-address-form mb-0">

                                    <input type="hidden"
                                           name="action"
                                           value="deleteAddress">

                                    <input type="hidden"
                                           name="addressId"
                                           value="${address.addressId}">

                                    <input type="hidden"
                                           name="addressActionToken"
                                           value="<c:out value='${sessionScope.addressActionToken}' />">

                                    <button type="submit"
                                            class="btn btn-link btn-sm px-1 py-0 text-decoration-none text-danger delete-address-button">
                                        Xóa
                                    </button>
                                </form>
                            </div>

                        </div>
                    </div>
                </c:forEach>

                <p id="addressListEmpty"
                   class="text-muted mb-0"
                   style="${empty addresses ? '' : 'display:none;'}">
                    Chưa có địa chỉ giao hàng.
                </p>
            </div>

            <!-- FORM SUA NGAY TRONG POPUP -->
            <form id="editAddressForm"
                  class="d-none"
                  method="post"
                  action="${pageContext.request.contextPath}/checkout">

                <div class="modal-body">
                    <h6 class="fw-bold">Chỉnh sửa địa chỉ</h6>

                    <input type="hidden"
                           id="editAddressId"
                           name="addressId">

                    <input type="hidden"
                           name="action"
                           value="editAddress">

                    <input type="hidden"
                           name="addressActionToken"
                           value="<c:out value='${sessionScope.addressActionToken}' />">

                    <div class="mb-3">
                        <label for="editRecipientName" class="form-label">
                            Tên người nhận
                        </label>

                        <input id="editRecipientName"
                               name="recipientName"
                               class="form-control"
                               type="text"
                               maxlength="100"
                               required>
                    </div>

                    <div class="mb-3">
                        <label for="editPhoneNumber" class="form-label">
                            Số điện thoại
                        </label>

                        <input id="editPhoneNumber"
                               name="phoneNumber"
                               class="form-control"
                               type="tel"
                               pattern="[0-9]{9,11}"
                               maxlength="11"
                               required>
                    </div>

                    <div class="mb-3">
                        <label for="editAddressLine" class="form-label">
                            Địa chỉ chi tiết
                        </label>

                        <textarea id="editAddressLine"
                                  name="addressLine"
                                  class="form-control"
                                  rows="3"
                                  required></textarea>
                    </div>
                </div>

                <div class="modal-footer">
                    <button id="cancelEditAddressButton"
                            type="button"
                            class="btn btn-outline-secondary">
                        Hủy chỉnh sửa
                    </button>

                    <button id="saveEditAddressButton"
                            type="submit"
                            class="btn btn-primary">
                        Lưu thay đổi
                    </button>
                </div>
            </form>

            <!-- NUT CUA DANH SACH DIA CHI -->
            <div class="modal-footer" id="addressListFooter">
                <button type="button"
                        class="btn btn-outline-secondary"
                        data-bs-dismiss="modal">
                    Đóng
                </button>

                <button type="button"
                        id="confirmAddressButton"
                        class="btn btn-primary"
                        ${empty addresses ? 'disabled' : ''}>
                    Xác nhận địa chỉ
                </button>
            </div>

        </div>
    </div>
</div>

<!-- MODAL THEM DIA CHI -->
<div class="modal fade"
     id="addAddressModal"
     tabindex="-1"
     aria-hidden="true">

    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4">

            <div class="modal-header">
                <h5 class="modal-title fw-bold">
                    Thêm địa chỉ giao hàng
                </h5>

                <button type="button"
                        class="btn-close"
                        data-bs-dismiss="modal"
                        aria-label="Đóng"></button>
            </div>

            <form id="addAddressForm"
                  action="${pageContext.request.contextPath}/checkout"
                  method="post">

                <input type="hidden"
                       name="action"
                       value="addAddress">

                <input type="hidden"
                       name="addressAddToken"
                       value="<c:out value='${sessionScope.addressAddToken}' />">

                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            Tên người nhận
                        </label>

                        <input type="text"
                               name="recipientName"
                               class="form-control"
                               maxlength="100"
                               required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            Số điện thoại
                        </label>

                        <input type="tel"
                               name="phoneNumber"
                               class="form-control"
                               pattern="[0-9]{9,11}"
                               maxlength="11"
                               required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            Địa chỉ chi tiết
                        </label>

                        <textarea name="addressLine"
                                  class="form-control"
                                  rows="3"
                                  placeholder="Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành phố"
                                  required></textarea>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button"
                            class="btn btn-light border"
                            data-bs-dismiss="modal">
                        Hủy
                    </button>

                    <button type="submit"
                            id="saveAddressButton"
                            class="btn btn-primary">
                        Lưu địa chỉ
                    </button>
                </div>
            </form>

        </div>
    </div>
</div>

</div>

<script>
    document.addEventListener("DOMContentLoaded", function () {

        const checkoutUrl =
                "${pageContext.request.contextPath}/checkout";

        const addressActionToken =
                "${sessionScope.addressActionToken}";

        // CAC THANH PHAN CHECKOUT
        const addressInput =
                document.getElementById("orderAddressId");
        const selectedCard =
                document.getElementById("selectedAddressCard");
        const selectedName =
                document.getElementById("selectedAddressName");
        const selectedLine =
                document.getElementById("selectedAddressLine");
        const selectedDefaultBadge =
                document.getElementById("selectedDefaultBadge");
        const noAddressMessage =
                document.getElementById("noAddressMessage");
        const needAddressMessage =
                document.getElementById("needAddressMessage");
        const addressList =
                document.getElementById("addressList");
        const addressListEmpty =
                document.getElementById("addressListEmpty");
        const openAddressModalButton =
                document.getElementById("openAddressModalButton");
        const confirmAddressButton =
                document.getElementById("confirmAddressButton");
        const placeOrderButton =
                document.getElementById("placeOrderButton");
        const modalMessage =
                document.getElementById("addressModalMessage");
        const addressModal =
                document.getElementById("addressModal");

        // CAC THANH PHAN FORM SUA
        const editAddressForm =
                document.getElementById("editAddressForm");
        const editAddressId =
                document.getElementById("editAddressId");
        const editRecipientName =
                document.getElementById("editRecipientName");
        const editPhoneNumber =
                document.getElementById("editPhoneNumber");
        const editAddressLine =
                document.getElementById("editAddressLine");
        const saveEditAddressButton =
                document.getElementById("saveEditAddressButton");
        const cancelEditAddressButton =
                document.getElementById("cancelEditAddressButton");
        const addressListFooter =
                document.getElementById("addressListFooter");

        let committedAddressId = addressInput.value;
        let addressRequestBusy = false;
        let editingOption = null;

        // HIEN THONG BAO TRONG POPUP
        function showModalMessage(message, success) {
            modalMessage.textContent = message;
            modalMessage.className = success
                    ? "alert alert-success mx-3 mt-3 mb-0"
                    : "alert alert-danger mx-3 mt-3 mb-0";
        }

        // GUI AJAX
        async function postAddressAction(data) {
            const response = await fetch(checkoutUrl, {
                method: "POST",
                credentials: "same-origin",
                headers: {
                    "Accept": "application/json",
                    "Content-Type":
                            "application/x-www-form-urlencoded;charset=UTF-8"
                },
                body: new URLSearchParams(data).toString()
            });

            const contentType =
                    response.headers.get("content-type") || "";

            if (!contentType.includes("application/json")) {
                throw new Error(
                        "Server không trả JSON. Vui lòng tải lại trang."
                        );
            }

            const result = await response.json();

            if (!response.ok || !result.success) {
                throw new Error(
                        result.message || "Thao tác không thành công."
                        );
            }

            return result;
        }

        // CAP NHAT DIA CHI DANG SU DUNG
        function updateSelectedAddress(address, isDefault) {
            if (!address) {
                addressInput.value = "";
                committedAddressId = "";
                selectedName.textContent = "";
                selectedLine.textContent = "";
                selectedCard.style.display = "none";
                noAddressMessage.style.display = "";
                needAddressMessage.style.display = "";
                selectedDefaultBadge.style.display = "none";
                placeOrderButton.disabled = true;
                return;
            }

            const id = String(address.addressId);

            committedAddressId = id;
            addressInput.value = id;

            selectedName.textContent =
                    address.recipientName + " | " + address.phoneNumber;

            selectedLine.textContent = address.addressLine;

            selectedDefaultBadge.style.display =
                    isDefault ? "" : "none";

            selectedCard.style.display = "";
            noAddressMessage.style.display = "none";
            needAddressMessage.style.display = "none";
            placeOrderButton.disabled = false;
        }

        // CAP NHAT CAC NUT SUA, XOA VA CHON
        function updateDeleteButtons() {
            addressList.querySelectorAll(
                    ".edit-address-button, .address-radio"
                    ).forEach(function (control) {
                control.disabled = addressRequestBusy;
            });

            addressList.querySelectorAll(
                    ".address-option"
                    ).forEach(function (option) {
                const button =
                        option.querySelector(".delete-address-button");

                if (!button) {
                    return;
                }

                const isSelected =
                        option.dataset.addressId === committedAddressId;

                button.disabled = isSelected || addressRequestBusy;
                button.closest(".delete-address-form").style.display =
                        isSelected ? "none" : "";
            });

            confirmAddressButton.disabled =
                    addressRequestBusy
                    || !addressList.querySelector(
                            'input[name="modalAddressId"]:checked'
                            );
        }

        // CAP NHAT DANH SACH SAU KHI XOA
        function updateAddressListState() {
            const options =
                    addressList.querySelectorAll(".address-option");

            const hasAddress = options.length > 0;

            addressListEmpty.style.display = hasAddress ? "none" : "";
            openAddressModalButton.disabled = !hasAddress;

            if (!hasAddress) {
                updateSelectedAddress(null, false);
            }

            updateDeleteButtons();
        }

        // DONG FORM SUA VA QUAY LAI DANH SACH
        function closeAddressEditor() {
            editingOption = null;
            editAddressForm.reset();
            editAddressForm.classList.add("d-none");
            addressList.classList.remove("d-none");
            addressListFooter.classList.remove("d-none");
        }

        // MO FORM SUA VA DIEN SAN DU LIEU
        addressList.addEventListener("click", function (event) {
            const button =
                    event.target.closest(".edit-address-button");

            if (!button || addressRequestBusy) {
                return;
            }

            editingOption = button.closest(".address-option");

            editAddressId.value = editingOption.dataset.addressId;

            editRecipientName.value = editingOption
                    .querySelector(".address-recipient")
                    .textContent.trim();

            editPhoneNumber.value = editingOption
                    .querySelector(".address-phone")
                    .textContent.trim();

            editAddressLine.value = editingOption
                    .querySelector(".address-line")
                    .textContent.trim();

            modalMessage.className =
                    "alert mx-3 mt-3 mb-0 d-none";

            addressList.classList.add("d-none");
            addressListFooter.classList.add("d-none");
            editAddressForm.classList.remove("d-none");

            editRecipientName.focus();
        });

        // HUY CHINH SUA
        cancelEditAddressButton.addEventListener("click", function () {
            if (!addressRequestBusy) {
                closeAddressEditor();

                modalMessage.className =
                        "alert mx-3 mt-3 mb-0 d-none";
            }
        });

        // KHONG DONG POPUP KHI DANG LUU DIA CHI
        addressModal.addEventListener("hide.bs.modal", function (event) {
            if (addressRequestBusy && editingOption) {
                event.preventDefault();
            }
        });

        addressModal.addEventListener(
                "hidden.bs.modal",
                closeAddressEditor
                );

        // LUU CHINH SUA DIA CHI
        editAddressForm.addEventListener("submit", async function (event) {
            event.preventDefault();

            if (addressRequestBusy || !editingOption) {
                return;
            }

            editRecipientName.value = editRecipientName.value.trim();
            editPhoneNumber.value = editPhoneNumber.value.trim();
            editAddressLine.value = editAddressLine.value.trim();

            if (!editAddressForm.reportValidity()) {
                return;
            }

            addressRequestBusy = true;
            saveEditAddressButton.disabled = true;
            cancelEditAddressButton.disabled = true;
            saveEditAddressButton.textContent = "Đang lưu...";

            updateDeleteButtons();

            try {
                const result = await postAddressAction({
                    action: "editAddress",
                    addressId: editAddressId.value,
                    recipientName: editRecipientName.value,
                    phoneNumber: editPhoneNumber.value,
                    addressLine: editAddressLine.value,
                    addressActionToken: addressActionToken
                });

                const address = result.address;

                editingOption.querySelector(
                        ".address-recipient"
                        ).textContent = address.recipientName;

                editingOption.querySelector(
                        ".address-phone"
                        ).textContent = address.phoneNumber;

                editingOption.querySelector(
                        ".address-line"
                        ).textContent = address.addressLine;

                // NEU SUA DIA CHI DANG CHON THI CAP NHAT CHECKOUT
                if (String(address.addressId) === committedAddressId) {
                    updateSelectedAddress(
                            address,
                            editingOption.dataset.default === "true"
                            );
                }

                closeAddressEditor();

                showModalMessage(
                        "Đã cập nhật địa chỉ thành công.",
                        true
                        );

            } catch (error) {
                // GIU NOI DUNG FORM KHI LUU THAT BAI
                showModalMessage(error.message, false);

            } finally {
                addressRequestBusy = false;
                saveEditAddressButton.disabled = false;
                cancelEditAddressButton.disabled = false;
                saveEditAddressButton.textContent = "Lưu thay đổi";

                updateDeleteButtons();
            }
        });

        // TICH DUNG DIA CHI DANG DUNG KHI MO POPUP
        addressModal.addEventListener("show.bs.modal", function () {
            addressList.querySelectorAll(
                    'input[name="modalAddressId"]'
                    ).forEach(function (radio) {
                radio.checked = radio.value === committedAddressId;
            });

            const currentOption = Array.from(
                    addressList.querySelectorAll(".address-option")
                    ).find(function (option) {
                return option.dataset.addressId === committedAddressId;
            });
            if (currentOption) {
                addressList.prepend(currentOption);
            }

            modalMessage.className =
                    "alert mx-3 mt-3 mb-0 d-none";

            updateDeleteButtons();
        });

        addressList.addEventListener("change", function (event) {
            if (event.target.matches('input[name="modalAddressId"]')) {
                updateDeleteButtons();
            }
        });

        // XAC NHAN DOI DIA CHI
        confirmAddressButton.addEventListener("click", async function () {
            if (addressRequestBusy) {
                return;
            }

            const selectedRadio = addressList.querySelector(
                    'input[name="modalAddressId"]:checked'
                    );

            if (!selectedRadio) {
                showModalMessage(
                        "Vui lòng chọn địa chỉ giao hàng.",
                        false
                        );
                return;
            }

            const id = selectedRadio.value;

            addressRequestBusy = true;
            updateDeleteButtons();

            try {
                const result = await postAddressAction({
                    action: "selectAddress",
                    addressId: id,
                    addressActionToken: addressActionToken
                });

                const option =
                        selectedRadio.closest(".address-option");

                addressList.querySelectorAll(".address-option").forEach(
                        function (item) {
                            const isDefault = item === option;
                            item.dataset.default = String(isDefault);
                            item.querySelector(".default-address-badge").style.display =
                                    isDefault ? "" : "none";
                        });

                updateSelectedAddress(
                        result.selectedAddress,
                        true
                        );

                addressList.prepend(option);

                updateDeleteButtons();

                bootstrap.Modal.getOrCreateInstance(addressModal).hide();

            } catch (error) {
                showModalMessage(error.message, false);

            } finally {
                addressRequestBusy = false;
                updateDeleteButtons();
            }
        });

        // XOA DIA CHI BANG AJAX
        addressList.addEventListener("submit", async function (event) {
            const form =
                    event.target.closest(".delete-address-form");

            if (!form) {
                return;
            }

            event.preventDefault();

            if (addressRequestBusy) {
                return;
            }

            const option = form.closest(".address-option");
            const id = option.dataset.addressId;

            if (id === committedAddressId) {
                showModalMessage(
                        "Không thể xóa địa chỉ đang sử dụng. "
                        + "Vui lòng xác nhận địa chỉ khác trước.",
                        false
                        );
                return;
            }

            if (!window.confirm("Bạn chắc chắn muốn xóa địa chỉ này?")) {
                return;
            }

            addressRequestBusy = true;
            updateDeleteButtons();

            try {
                await postAddressAction({
                    action: "deleteAddress",
                    addressId: id,
                    addressActionToken: addressActionToken
                });

                // XOA O DIA CHI, GIU NGUYEN POPUP
                option.remove();
                updateAddressListState();

                showModalMessage(
                        "Đã xóa địa chỉ thành công.",
                        true
                        );

            } catch (error) {
                showModalMessage(error.message, false);

            } finally {
                addressRequestBusy = false;
                updateDeleteButtons();
            }
        });

        // CHAN BAM LUU DIA CHI MOI NHIEU LAN
        const addAddressForm =
                document.getElementById("addAddressForm");

        const saveAddressButton =
                document.getElementById("saveAddressButton");

        addAddressForm.addEventListener("submit", function (event) {
            if (addAddressForm.dataset.submitting === "true") {
                event.preventDefault();
                return;
            }

            if (!addAddressForm.checkValidity()) {
                return;
            }

            addAddressForm.dataset.submitting = "true";
            saveAddressButton.disabled = true;
            saveAddressButton.textContent = "Đang lưu...";
        });

        // CHAN BAM DAT HANG NHIEU LAN TREN GIAO DIEN
        const orderForm =
                document.getElementById("orderForm");

        orderForm.addEventListener("submit", function (event) {
            if (orderForm.dataset.submitting === "true") {
                event.preventDefault();
                return;
            }

            if (!orderForm.checkValidity()) {
                return;
            }

            orderForm.dataset.submitting = "true";
            placeOrderButton.disabled = true;
            placeOrderButton.textContent = "Đang xử lý đơn hàng...";
        });

        updateAddressListState();
    });
</script>

<%@ include file="/WEB-INF/include/footer.jsp" %>
