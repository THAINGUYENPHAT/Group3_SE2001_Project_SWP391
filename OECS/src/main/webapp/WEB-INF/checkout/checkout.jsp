<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@include file="/WEB-INF/include/header.jsp" %>


<style>

    body {
        background: #f7f9fc;
    }


    .checkout-card {
        border: 1px solid #e2e8f0 !important;
        border-radius: 16px !important;
        background: #fff;
    }


    .voucher-option {
        width: 100%;

        padding: 14px 16px;

        border: 1px solid #dbe5ef;
        border-radius: 10px;

        background: #fff;

        text-align: left;

        transition:
            border-color .18s,
            background .18s;
    }


    .voucher-option:hover {
        border-color: #86b7fe;
        background: #f8fbff;
    }


    .voucher-option:disabled {
        background: #ecfdf5;
        border-color: #86efac;
        opacity: 1;
    }


    .voucher-code {
        color: #0d6efd;

        font-weight: 750;
    }


    .checkout-total {
        color: #dc3545;

        font-size: 25px;
        font-weight: 800;
    }


    .address-option {
        transition:
            background .18s,
            border-color .18s;
    }


    .address-option:hover {
        background: #f8fbff;
        border-color: #b9d7ff !important;
    }


    .address-option:has(.address-radio:checked) {
        border-color: #0d6efd !important;
        background: #f5f9ff;
    }


    .sticky-summary {

        position: sticky;
        top: 90px;
    }


    @media (max-width: 991px) {

        .sticky-summary {
            position: static;
        }
    }

</style>


<div class="d-flex justify-content-between align-items-center mb-4">

    <div>

        <h3 class="fw-bold mb-1">
            Xác nhận đơn hàng
        </h3>

        <p class="text-muted mb-0">
            Vui lòng kiểm tra thông tin trước khi đặt hàng.
        </p>

    </div>

    <div class="d-flex flex-wrap gap-2">
        <a href="${pageContext.request.contextPath}/my-orders" class="btn btn-outline-primary">Đơn hàng của tôi</a>
        <a href="${pageContext.request.contextPath}/cart"
           class="btn btn-outline-secondary">
            <i class="bi bi-arrow-left me-1"></i>

            Về giỏ hàng

        </a>
    </div>
</div>


<c:if test="${not empty sessionScope.checkoutError}">

    <div class="alert alert-danger">

        <c:out
            value="${sessionScope.checkoutError}"/>

    </div>


    <c:remove
        var="checkoutError"
        scope="session"/>

</c:if>


<c:if test="${not empty sessionScope.checkoutMessage}">

    <div class="alert alert-success">

        <c:out
            value="${sessionScope.checkoutMessage}"/>

    </div>


    <c:remove
        var="checkoutMessage"
        scope="session"/>

</c:if>


<div class="row g-4">


    <!-- ================================================= -->
    <!-- LEFT -->
    <!-- ================================================= -->

    <div class="col-lg-8">


        <!-- ============================================= -->
        <!-- ADDRESS -->
        <!-- ============================================= -->

        <div class="card checkout-card shadow-sm mb-4">

            <div class="card-body p-4">


                <div class="d-flex justify-content-between align-items-center mb-3">

                    <h5 class="fw-bold mb-0">

                        <i class="bi bi-geo-alt text-primary me-2"></i>

                        Địa chỉ giao hàng

                    </h5>


                    <div class="d-flex gap-2">


                        <button
                            type="button"
                            id="openAddressModalButton"
                            class="btn btn-outline-primary btn-sm"
                            data-bs-toggle="modal"
                            data-bs-target="#addressModal"
                            ${empty addresses ? 'disabled' : ''}>

                            Thay đổi

                        </button>


                        <button
                            type="button"
                            class="btn btn-primary btn-sm"
                            data-bs-toggle="modal"
                            data-bs-target="#addAddressModal">

                            <i class="bi bi-plus-lg"></i>

                            Thêm địa chỉ

                        </button>


                    </div>

                </div>


                <div
                    id="noAddressMessage"
                    class="alert alert-warning mb-0"
                    style="${empty selectedAddress ? '' : 'display:none;'}">

                    Bạn chưa có địa chỉ giao hàng.
                    Hãy thêm địa chỉ để tiếp tục.

                </div>


                <div
                    id="selectedAddressCard"
                    class="border rounded-3 p-3 bg-light"
                    style="${empty selectedAddress ? 'display:none;' : ''}">


                    <div
                        class="fw-semibold"
                        id="selectedAddressName">

                        <c:out
                            value="${selectedAddress.recipientName}"/>

                        |

                        <c:out
                            value="${selectedAddress.phoneNumber}"/>

                    </div>


                    <div
                        class="text-muted mt-1"
                        id="selectedAddressLine">

                        <c:out
                            value="${selectedAddress.addressLine}"/>

                    </div>

                    <span id="selectedDefaultBadge"
                          class="badge bg-primary mt-2"
                          style="${selectedAddress.defaultAddress ? '' : 'display:none;'}">
                        Đã lưu cho lần mua sau
                    </span>

                </div>


            </div>

        </div>


        <!-- ============================================= -->
        <!-- PRODUCTS -->
        <!-- ============================================= -->

        <div class="card checkout-card shadow-sm mb-4">

            <div class="card-body p-4">


                <h5 class="fw-bold mb-3">

                    <i class="bi bi-bag-check text-primary me-2"></i>

                    Sản phẩm đặt mua

                </h5>


                <div class="table-responsive">

                    <table class="table align-middle mb-0">

                        <thead class="table-light">

                            <tr>

                            <th>
                                Sản phẩm
                            </th>

                            <th class="text-end">
                                Đơn giá
                            </th>

                            <th class="text-center">
                                Số lượng
                            </th>

                            <th class="text-end">
                                Thành tiền
                            </th>

                            </tr>

                        </thead>


                        <tbody>

                            <c:forEach
                                var="item"
                                items="${cartItems}">

                                <tr>

                                <td>

                                    <div class="fw-semibold">

                                        <c:out
                                            value="${item.productName}"/>

                                    </div>


                                    <small class="text-muted">

                                        SKU:

                                        <c:out
                                            value="${item.skuCode}"/>

                                    </small>

                                </td>


                                <td class="text-end">

                                <fmt:formatNumber
                                    value="${item.price}"
                                    type="number"
                                    groupingUsed="true"
                                    maxFractionDigits="0"/>

                                đ

                                </td>


                                <td class="text-center">

                                    ${item.quantity}

                                </td>


                                <td class="text-end fw-semibold">

                                <fmt:formatNumber
                                    value="${item.price * item.quantity}"
                                    type="number"
                                    groupingUsed="true"
                                    maxFractionDigits="0"/>

                                đ

                                </td>

                                </tr>

                            </c:forEach>

                        </tbody>

                    </table>

                </div>


                <div class="text-muted small mt-3">

                    <i class="bi bi-info-circle me-1"></i>

                    Chỉ các sản phẩm bạn đã chọn trong giỏ hàng
                    được hiển thị tại đây.

                </div>

            </div>

        </div>


        <!-- ============================================= -->
        <!-- VOUCHER -->
        <!-- ============================================= -->

        <div class="card checkout-card shadow-sm mb-4">

            <div class="card-body p-4">


                <h5 class="fw-bold mb-3">

                    <i class="bi bi-ticket-perforated text-primary me-2"></i>

                    Mã giảm giá

                </h5>


                <!-- APPLIED VOUCHER -->

                <c:if test="${not empty appliedVoucher}">

                    <div class="alert alert-success">

                        <div class="d-flex justify-content-between align-items-start gap-3">

                            <div>

                                <div>

                                    Đang áp dụng:

                                    <strong>

                                        <c:out
                                            value="${appliedVoucher.code}"/>

                                    </strong>

                                </div>


                                <div class="small mt-1">

                                    <c:choose>

                                        <c:when test="${appliedVoucher.discountType == 'PERCENT'}">

                                            Giảm
                                            ${appliedVoucher.discountValue}%

                                            <c:if test="${not empty appliedVoucher.maxDiscount}">

                                                · tối đa

                                                <fmt:formatNumber
                                                    value="${appliedVoucher.maxDiscount}"
                                                    type="number"
                                                    groupingUsed="true"
                                                    maxFractionDigits="0"/>

                                                đ

                                            </c:if>

                                        </c:when>


                                        <c:otherwise>

                                            Giảm

                                            <fmt:formatNumber
                                                value="${appliedVoucher.discountValue}"
                                                type="number"
                                                groupingUsed="true"
                                                maxFractionDigits="0"/>

                                            đ

                                        </c:otherwise>

                                    </c:choose>

                                </div>

                            </div>


                            <form
                                action="${pageContext.request.contextPath}/checkout"
                                method="post"
                                class="mb-0">

                                <input
                                    type="hidden"
                                    name="action"
                                    value="removeVoucher">


                                <button
                                    type="submit"
                                    class="btn btn-outline-danger btn-sm">

                                    Bỏ mã

                                </button>

                            </form>

                        </div>

                    </div>

                </c:if>


                <!-- AVAILABLE VOUCHERS -->

                <c:choose>

                    <c:when test="${not empty availableVouchers}">


                        <div class="fw-semibold mb-2">

                            Voucher khả dụng

                        </div>


                        <div class="d-flex flex-column gap-2">


                            <c:forEach
                                var="voucher"
                                items="${availableVouchers}">


                                <form
                                    action="${pageContext.request.contextPath}/checkout"
                                    method="post"
                                    class="mb-0">


                                    <input
                                        type="hidden"
                                        name="action"
                                        value="applyVoucher">


                                    <input
                                        type="hidden"
                                        name="voucherCode"
                                        value="${voucher.code}">


                                    <button
                                        type="submit"
                                        class="voucher-option"
                                        ${not empty appliedVoucher
                                          && appliedVoucher.voucherId == voucher.voucherId
                                          ? 'disabled' : ''}>


                                        <div class="d-flex justify-content-between align-items-center gap-3">


                                            <strong class="voucher-code">

                                                <i class="bi bi-ticket-perforated me-1"></i>

                                                <c:out
                                                    value="${voucher.code}"/>

                                            </strong>


                                            <strong>

                                                <c:choose>

                                                    <c:when test="${voucher.discountType == 'PERCENT'}">

                                                        Giảm
                                                        ${voucher.discountValue}%

                                                    </c:when>


                                                    <c:otherwise>

                                                        Giảm

                                                        <fmt:formatNumber
                                                            value="${voucher.discountValue}"
                                                            type="number"
                                                            groupingUsed="true"
                                                            maxFractionDigits="0"/>

                                                        đ

                                                    </c:otherwise>

                                                </c:choose>

                                            </strong>

                                        </div>


                                        <small class="text-muted">

                                            Đơn tối thiểu:

                                            <fmt:formatNumber
                                                value="${voucher.minOrderValue}"
                                                type="number"
                                                groupingUsed="true"
                                                maxFractionDigits="0"/>

                                            đ


                                            <c:if test="${voucher.discountType == 'PERCENT'
                                                          && not empty voucher.maxDiscount}">

                                                · Giảm tối đa:

                                                <fmt:formatNumber
                                                    value="${voucher.maxDiscount}"
                                                    type="number"
                                                    groupingUsed="true"
                                                    maxFractionDigits="0"/>

                                                đ

                                            </c:if>

                                        </small>


                                    </button>

                                </form>


                            </c:forEach>


                        </div>


                    </c:when>


                    <c:otherwise>

                        <div class="text-muted small">

                            Hiện không có Voucher khả dụng
                            cho các sản phẩm đã chọn.

                        </div>

                    </c:otherwise>

                </c:choose>


            </div>

        </div>


        <!-- ============================================= -->
        <!-- PAYMENT -->
        <!-- ============================================= -->

        <div class="card checkout-card shadow-sm">

            <div class="card-body p-4">


                <h5 class="fw-bold mb-3">

                    <i class="bi bi-credit-card text-primary me-2"></i>

                    Phương thức thanh toán

                </h5>


                <label class="d-block border rounded-3 p-3 mb-3">
                    <input
                        type="radio"
                        name="paymentMethod"
                        value="COD"
                        form="orderForm"
                        checked>

                    <span class="fw-semibold ms-2">
                        Thanh toán khi nhận hàng (COD)
                    </span>

                    <div class="text-muted small ms-4 mt-1">
                        Thanh toán khi nhận được sản phẩm.
                    </div>
                </label>

                <label class="d-block border rounded-3 p-3 mb-3">
                    <input
                        type="radio"
                        name="paymentMethod"
                        value="VNPAY"
                        form="orderForm"
                        ${vnpayAvailable ? '' : 'disabled'}>

                    <span class="fw-semibold ms-2">
                        VNPay — Thử nghiệm
                    </span>

                    <div class="text-muted small ms-4 mt-1">
                        <c:choose>
                            <c:when test="${vnpayAvailable}">
                                Thanh toán qua VNPay Sandbox.
                                Đơn hàng được giữ trong 15 phút.
                            </c:when>
                            <c:otherwise>
                                Chưa cấu hình tài khoản VNPay Sandbox.
                            </c:otherwise>
                        </c:choose>
                    </div>
                </label>

                <label class="d-block border rounded-3 p-3">
                    <input
                        type="radio"
                        name="paymentMethod"
                        value="MOMO"
                        form="orderForm"
                        ${momoAvailable ? '' : 'disabled'}>

                    <span class="fw-semibold ms-2">
                        MoMo — Thử nghiệm
                    </span>

                    <div class="text-muted small ms-4 mt-1">
                        <c:choose>
                            <c:when test="${momoAvailable}">
                                Thanh toán qua MoMo Test.
                                Đơn hàng được giữ trong 15 phút.
                            </c:when>
                            <c:otherwise>
                                Chưa cấu hình tài khoản MoMo Test.
                            </c:otherwise>
                        </c:choose>
                    </div>
                </label>


            </div>

        </div>


    </div>


    <!-- ================================================= -->
    <!-- RIGHT -->
    <!-- ================================================= -->

    <div class="col-lg-4">

        <div class="card checkout-card shadow-sm sticky-summary">

            <div class="card-body p-4">


                <h5 class="fw-bold mb-4">

                    Thông tin thanh toán

                </h5>


                <div class="d-flex justify-content-between mb-3">

                    <span>
                        Tiền hàng
                    </span>

                    <strong>

                        <fmt:formatNumber
                            value="${subtotal}"
                            type="number"
                            groupingUsed="true"
                            maxFractionDigits="0"/>

                        đ

                    </strong>

                </div>


                <div class="d-flex justify-content-between mb-3">

                    <span>
                        Phí vận chuyển
                    </span>

                    <span>

                        <fmt:formatNumber
                            value="${shippingFee}"
                            type="number"
                            groupingUsed="true"
                            maxFractionDigits="0"/>

                        đ

                    </span>

                </div>


                <div class="d-flex justify-content-between mb-3">

                    <span>
                        Giảm giá
                    </span>

                    <span class="text-success">

                        -

                        <fmt:formatNumber
                            value="${discount}"
                            type="number"
                            groupingUsed="true"
                            maxFractionDigits="0"/>

                        đ

                    </span>

                </div>


                <hr>


                <div class="d-flex justify-content-between align-items-center mb-4">

                    <strong>
                        Tổng thanh toán
                    </strong>


                    <span class="checkout-total">

                        <fmt:formatNumber
                            value="${totalAmount}"
                            type="number"
                            groupingUsed="true"
                            maxFractionDigits="0"/>

                        đ

                    </span>

                </div>


                <form
                    id="orderForm"
                    action="${pageContext.request.contextPath}/checkout"
                    method="post">


                    <input
                        type="hidden"
                        name="action"
                        value="placeOrder">


                    <input
                        type="hidden"
                        name="checkoutToken"
                        value="<c:out value='${sessionScope.checkoutToken}'/>">


                    <input
                        type="hidden"
                        name="addressId"
                        id="orderAddressId"
                        value="${selectedAddress.addressId}">


                    <button
                        type="submit"
                        id="placeOrderButton"
                        class="btn btn-primary w-100 py-3 fw-semibold"
                        ${empty selectedAddress ? 'disabled' : ''}>

                        <i class="bi bi-bag-check me-1"></i>

                        Đặt hàng

                    </button>


                </form>


                <p
                    id="needAddressMessage"
                    class="text-danger small text-center mt-2 mb-0"
                    style="${empty selectedAddress ? '' : 'display:none;'}">

                    Vui lòng thêm địa chỉ trước khi đặt hàng.

                </p>


                <p class="text-muted small text-center mt-3 mb-0">

                    Chỉ các sản phẩm được chọn
                    trong giỏ hàng sẽ được đặt mua.

                </p>


            </div>

        </div>

    </div>


</div>


<!-- ===================================================== -->
<!-- ADDRESS MODAL -->
<!-- ===================================================== -->

<div
    class="modal fade"
    id="addressModal"
    tabindex="-1"
    aria-hidden="true">


    <div class="modal-dialog modal-dialog-centered modal-lg">

        <div class="modal-content rounded-4">


            <div class="modal-header">

                <h5 class="modal-title fw-bold">

                    Chọn địa chỉ giao hàng

                </h5>


                <button
                    type="button"
                    class="btn-close"
                    data-bs-dismiss="modal"
                    aria-label="Đóng">
                </button>

            </div>


            <div
                id="addressModalMessage"
                class="alert mx-3 mt-3 mb-0 d-none"
                role="alert">
            </div>


            <!-- ADDRESS LIST -->

            <div
                id="addressList"
                class="modal-body"
                style="max-height:400px;overflow-y:auto;">


                <c:forEach
                    var="address"
                    items="${addresses}">


                    <div
                        class="border rounded-3 p-3 mb-2 address-option"
                        data-address-id="${address.addressId}"
                        data-default="${address.defaultAddress}">


                        <div class="d-flex flex-wrap gap-3 align-items-start">


                            <input
                                type="radio"
                                class="form-check-input mt-1 address-radio"
                                name="modalAddressId"
                                value="${address.addressId}"
                                ${not empty selectedAddress
                                  && selectedAddress.addressId == address.addressId
                                  ? 'checked' : ''}>


                            <div class="flex-grow-1">


                                <label class="fw-semibold d-block address-name">

                                    <span class="address-recipient">

                                        <c:out
                                            value="${address.recipientName}"/>

                                    </span>

                                    |

                                    <span class="address-phone">

                                        <c:out
                                            value="${address.phoneNumber}"/>

                                    </span>

                                </label>


                                <div class="text-muted small address-line">

                                    <c:out
                                        value="${address.addressLine}"/>

                                </div>


                                <span
                                    class="badge bg-primary mt-2 default-address-badge"
                                    style="${address.defaultAddress ? '' : 'display:none;'}">

                                    Mặc định

                                </span>


                            </div>


                            <div class="d-flex align-items-center gap-2 ms-auto flex-shrink-0">


                                <button
                                    type="button"
                                    class="btn btn-link btn-sm px-1 py-0 text-decoration-none text-secondary edit-address-button">

                                    Sửa

                                </button>


                                <form
                                    action="${pageContext.request.contextPath}/checkout"
                                    method="post"
                                    class="delete-address-form mb-0">


                                    <input
                                        type="hidden"
                                        name="action"
                                        value="deleteAddress">


                                    <input
                                        type="hidden"
                                        name="addressId"
                                        value="${address.addressId}">


                                    <input
                                        type="hidden"
                                        name="addressActionToken"
                                        value="<c:out value='${sessionScope.addressActionToken}'/>">


                                    <button
                                        type="submit"
                                        class="btn btn-link btn-sm px-1 py-0 text-decoration-none text-danger delete-address-button">

                                        Xóa

                                    </button>


                                </form>


                            </div>


                        </div>

                    </div>


                </c:forEach>


                <p
                    id="addressListEmpty"
                    class="text-muted mb-0"
                    style="${empty addresses ? '' : 'display:none;'}">

                    Chưa có địa chỉ giao hàng.

                </p>


            </div>


            <!-- EDIT ADDRESS -->

            <form
                id="editAddressForm"
                class="d-none"
                method="post"
                action="${pageContext.request.contextPath}/checkout">


                <div class="modal-body">


                    <h6 class="fw-bold">

                        Chỉnh sửa địa chỉ

                    </h6>


                    <input
                        type="hidden"
                        id="editAddressId"
                        name="addressId">


                    <input
                        type="hidden"
                        name="action"
                        value="editAddress">


                    <input
                        type="hidden"
                        name="addressActionToken"
                        value="<c:out value='${sessionScope.addressActionToken}'/>">


                    <div class="mb-3">

                        <label
                            for="editRecipientName"
                            class="form-label">

                            Tên người nhận

                        </label>


                        <input
                            id="editRecipientName"
                            name="recipientName"
                            class="form-control"
                            type="text"
                            maxlength="100"
                            required>

                    </div>


                    <div class="mb-3">

                        <label
                            for="editPhoneNumber"
                            class="form-label">

                            Số điện thoại

                        </label>


                        <input
                            id="editPhoneNumber"
                            name="phoneNumber"
                            class="form-control"
                            type="tel"
                            pattern="[0-9]{9,11}"
                            maxlength="11"
                            required>

                    </div>


                    <div class="mb-3">

                        <label
                            for="editAddressLine"
                            class="form-label">

                            Địa chỉ chi tiết

                        </label>


                        <textarea
                            id="editAddressLine"
                            name="addressLine"
                            class="form-control"
                            rows="3"
                            required></textarea>

                    </div>


                </div>


                <div class="modal-footer">

                    <button
                        id="cancelEditAddressButton"
                        type="button"
                        class="btn btn-outline-secondary">

                        Hủy chỉnh sửa

                    </button>


                    <button
                        id="saveEditAddressButton"
                        type="submit"
                        class="btn btn-primary">

                        Lưu thay đổi

                    </button>

                </div>


            </form>


            <!-- LIST FOOTER -->

            <div
                class="modal-footer"
                id="addressListFooter">


                <button
                    type="button"
                    class="btn btn-outline-secondary"
                    data-bs-dismiss="modal">

                    Đóng

                </button>


                <button
                    type="button"
                    id="confirmAddressButton"
                    class="btn btn-primary"
                    ${empty addresses ? 'disabled' : ''}>

                    Xác nhận địa chỉ

                </button>


            </div>


        </div>

    </div>

</div>


<!-- ===================================================== -->
<!-- ADD ADDRESS -->
<!-- ===================================================== -->

<div
    class="modal fade"
    id="addAddressModal"
    tabindex="-1"
    aria-hidden="true">


    <div class="modal-dialog modal-dialog-centered">

        <div class="modal-content rounded-4">


            <form
                id="addAddressForm"
                action="${pageContext.request.contextPath}/checkout"
                method="post">


                <div class="modal-header">

                    <h5 class="modal-title fw-bold">

                        Thêm địa chỉ giao hàng

                    </h5>


                    <button
                        type="button"
                        class="btn-close"
                        data-bs-dismiss="modal">
                    </button>

                </div>


                <div class="modal-body">


                    <input
                        type="hidden"
                        name="action"
                        value="addAddress">


                    <input
                        type="hidden"
                        name="addressAddToken"
                        value="<c:out value='${sessionScope.addressAddToken}'/>">


                    <div class="mb-3">

                        <label class="form-label">

                            Tên người nhận

                        </label>


                        <input
                            type="text"
                            name="recipientName"
                            class="form-control"
                            maxlength="100"
                            required>

                    </div>


                    <div class="mb-3">

                        <label class="form-label">

                            Số điện thoại

                        </label>


                        <input
                            type="tel"
                            name="phoneNumber"
                            class="form-control"
                            pattern="[0-9]{9,11}"
                            maxlength="11"
                            required>

                    </div>


                    <div class="mb-3">

                        <label class="form-label">

                            Địa chỉ chi tiết

                        </label>


                        <textarea
                            name="addressLine"
                            class="form-control"
                            rows="3"
                            required></textarea>

                    </div>


                </div>


                <div class="modal-footer">


                    <button
                        type="button"
                        class="btn btn-outline-secondary"
                        data-bs-dismiss="modal">

                        Hủy

                    </button>


                    <button
                        type="submit"
                        id="saveAddressButton"
                        class="btn btn-primary">

                        Lưu địa chỉ

                    </button>


                </div>


            </form>


        </div>

    </div>

</div>


<script>

    document.addEventListener(
            "DOMContentLoaded",
            function () {

                const checkoutUrl =
                        "${pageContext.request.contextPath}/checkout";


                const addressActionToken =
                        "${sessionScope.addressActionToken}";


                // =================================================
                // MAIN ELEMENTS
                // =================================================

                const addressInput =
                        document.getElementById(
                                "orderAddressId"
                                );


                const selectedCard =
                        document.getElementById(
                                "selectedAddressCard"
                                );


                const selectedName =
                        document.getElementById(
                                "selectedAddressName"
                                );


                const selectedLine =
                        document.getElementById(
                                "selectedAddressLine"
                                );


                const selectedDefaultBadge =
                        document.getElementById(
                                "selectedDefaultBadge"
                                );


                const noAddressMessage =
                        document.getElementById(
                                "noAddressMessage"
                                );


                const needAddressMessage =
                        document.getElementById(
                                "needAddressMessage"
                                );


                const addressList =
                        document.getElementById(
                                "addressList"
                                );


                const addressListEmpty =
                        document.getElementById(
                                "addressListEmpty"
                                );


                const openAddressModalButton =
                        document.getElementById(
                                "openAddressModalButton"
                                );


                const confirmAddressButton =
                        document.getElementById(
                                "confirmAddressButton"
                                );


                const placeOrderButton =
                        document.getElementById(
                                "placeOrderButton"
                                );


                const modalMessage =
                        document.getElementById(
                                "addressModalMessage"
                                );


                const addressModal =
                        document.getElementById(
                                "addressModal"
                                );


                const addressListFooter =
                        document.getElementById(
                                "addressListFooter"
                                );


                // =================================================
                // EDIT ELEMENTS
                // =================================================

                const editAddressForm =
                        document.getElementById(
                                "editAddressForm"
                                );


                const editAddressId =
                        document.getElementById(
                                "editAddressId"
                                );


                const editRecipientName =
                        document.getElementById(
                                "editRecipientName"
                                );


                const editPhoneNumber =
                        document.getElementById(
                                "editPhoneNumber"
                                );


                const editAddressLine =
                        document.getElementById(
                                "editAddressLine"
                                );


                const saveEditAddressButton =
                        document.getElementById(
                                "saveEditAddressButton"
                                );


                const cancelEditAddressButton =
                        document.getElementById(
                                "cancelEditAddressButton"
                                );


                let committedAddressId =
                        addressInput
                        ? addressInput.value
                        : "";


                let addressRequestBusy =
                        false;


                let editingOption =
                        null;


                // =================================================
                // MESSAGE
                // =================================================

                function showModalMessage(
                        message,
                        success
                        ) {

                    if (!modalMessage) {
                        return;
                    }


                    modalMessage.textContent =
                            message;


                    modalMessage.className =
                            success
                            ? "alert alert-success mx-3 mt-3 mb-0"
                            : "alert alert-danger mx-3 mt-3 mb-0";
                }


                // =================================================
                // POST AJAX
                // =================================================

                async function postAddressAction(
                        data
                        ) {

                    const response =
                            await fetch(
                                    checkoutUrl,
                                    {
                                        method: "POST",

                                        credentials:
                                                "same-origin",

                                        headers: {

                                            "Accept":
                                                    "application/json",

                                            "Content-Type":
                                                    "application/x-www-form-urlencoded;charset=UTF-8"
                                        },

                                        body:
                                                new URLSearchParams(
                                                        data
                                                        ).toString()
                                    }
                            );


                    let result;


                    try {

                        result =
                                await response.json();

                    } catch (e) {

                        throw new Error(
                                "Phản hồi từ server không hợp lệ."
                                );
                    }


                    if (!response.ok
                            || !result.success) {

                        throw new Error(
                                result.message
                                || "Không thể thực hiện thao tác."
                                );
                    }


                    return result;
                }


                // =================================================
                // ADDRESS LIST STATE
                // =================================================

                function getOptions() {

                    if (!addressList) {
                        return [];
                    }


                    return Array.from(
                            addressList.querySelectorAll(
                                    ".address-option"
                                    )
                            );
                }


                function updateAddressListState() {

                    const options =
                            getOptions();


                    if (addressListEmpty) {

                        addressListEmpty.style.display =
                                options.length === 0
                                ? ""
                                : "none";
                    }


                    if (openAddressModalButton) {

                        openAddressModalButton.disabled =
                                options.length === 0;
                    }


                    if (confirmAddressButton) {

                        confirmAddressButton.disabled =
                                options.length === 0;
                    }
                }


                // =================================================
                // DELETE BUTTON STATE
                // =================================================

                function updateDeleteButtons() {

                    getOptions().forEach(
                            function (option) {

                                const id =
                                        option.dataset
                                        .addressId;


                                const button =
                                        option.querySelector(
                                                ".delete-address-button"
                                                );


                                if (!button) {
                                    return;
                                }


                                button.disabled =
                                        addressRequestBusy
                                        || id === committedAddressId;
                            }
                    );
                }


                // =================================================
                // UPDATE CURRENT ADDRESS CARD
                // =================================================

                function updateSelectedAddress(
                        address,
                        setDefaultBadge
                        ) {

                    if (!address) {
                        return;
                    }


                    committedAddressId =
                            String(
                                    address.addressId
                                    );


                    if (addressInput) {

                        addressInput.value =
                                committedAddressId;
                    }


                    if (selectedName) {

                        selectedName.textContent =
                                address.recipientName
                                + " | "
                                + address.phoneNumber;
                    }


                    if (selectedLine) {

                        selectedLine.textContent =
                                address.addressLine;
                    }


                    if (selectedCard) {

                        selectedCard.style.display =
                                "";
                    }


                    if (noAddressMessage) {

                        noAddressMessage.style.display =
                                "none";
                    }


                    if (needAddressMessage) {

                        needAddressMessage.style.display =
                                "none";
                    }


                    if (placeOrderButton) {

                        placeOrderButton.disabled =
                                false;
                    }


                    if (selectedDefaultBadge) {

                        selectedDefaultBadge.style.display =
                                setDefaultBadge
                                && address.defaultAddress
                                ? ""
                                : "none";
                    }


                    updateDeleteButtons();
                }


                // =================================================
                // CANCEL EDIT
                // =================================================

                function closeEditMode() {

                    editingOption =
                            null;


                    if (editAddressForm) {

                        editAddressForm.reset();

                        editAddressForm.classList.add(
                                "d-none"
                                );
                    }


                    if (addressList) {

                        addressList.classList.remove(
                                "d-none"
                                );
                    }


                    if (addressListFooter) {

                        addressListFooter.classList.remove(
                                "d-none"
                                );
                    }


                    if (modalMessage) {

                        modalMessage.className =
                                "alert mx-3 mt-3 mb-0 d-none";
                    }
                }


                // =================================================
                // OPEN EDIT
                // =================================================

                if (addressList) {

                    addressList.addEventListener(
                            "click",
                            function (event) {

                                const button =
                                        event.target.closest(
                                                ".edit-address-button"
                                                );


                                if (!button
                                        || addressRequestBusy) {

                                    return;
                                }


                                editingOption =
                                        button.closest(
                                                ".address-option"
                                                );


                                if (!editingOption) {

                                    return;
                                }


                                editAddressId.value =
                                        editingOption.dataset
                                        .addressId;


                                editRecipientName.value =
                                        editingOption
                                        .querySelector(
                                                ".address-recipient"
                                                )
                                        .textContent
                                        .trim();


                                editPhoneNumber.value =
                                        editingOption
                                        .querySelector(
                                                ".address-phone"
                                                )
                                        .textContent
                                        .trim();


                                editAddressLine.value =
                                        editingOption
                                        .querySelector(
                                                ".address-line"
                                                )
                                        .textContent
                                        .trim();


                                addressList.classList.add(
                                        "d-none"
                                        );


                                addressListFooter.classList.add(
                                        "d-none"
                                        );


                                editAddressForm.classList.remove(
                                        "d-none"
                                        );
                            }
                    );
                }


                // =================================================
                // CANCEL EDIT BUTTON
                // =================================================

                if (cancelEditAddressButton) {

                    cancelEditAddressButton.addEventListener(
                            "click",
                            function () {

                                closeEditMode();
                            }
                    );
                }


                // =================================================
                // SAVE EDIT AJAX
                // =================================================

                if (editAddressForm) {

                    editAddressForm.addEventListener(
                            "submit",
                            async function (event) {

                                event.preventDefault();


                                if (addressRequestBusy) {
                                    return;
                                }


                                editRecipientName.value =
                                        editRecipientName.value
                                        .trim();


                                editPhoneNumber.value =
                                        editPhoneNumber.value
                                        .trim();


                                editAddressLine.value =
                                        editAddressLine.value
                                        .trim();


                                if (!editAddressForm
                                        .reportValidity()) {

                                    return;
                                }


                                addressRequestBusy =
                                        true;


                                saveEditAddressButton.disabled =
                                        true;


                                saveEditAddressButton.textContent =
                                        "Đang lưu...";


                                updateDeleteButtons();


                                try {

                                    const result =
                                            await postAddressAction(
                                                    {
                                                        action:
                                                                "editAddress",

                                                        addressId:
                                                                editAddressId.value,

                                                        recipientName:
                                                                editRecipientName.value,

                                                        phoneNumber:
                                                                editPhoneNumber.value,

                                                        addressLine:
                                                                editAddressLine.value,

                                                        addressActionToken:
                                                                addressActionToken
                                                    }
                                            );


                                    const address =
                                            result.address;


                                    editingOption
                                            .querySelector(
                                                    ".address-recipient"
                                                    )
                                            .textContent =
                                            address.recipientName;


                                    editingOption
                                            .querySelector(
                                                    ".address-phone"
                                                    )
                                            .textContent =
                                            address.phoneNumber;


                                    editingOption
                                            .querySelector(
                                                    ".address-line"
                                                    )
                                            .textContent =
                                            address.addressLine;


                                    /*
                                     * Nếu đang sửa chính địa chỉ Checkout
                                     * hiện tại thì cập nhật luôn card phía ngoài.
                                     */
                                    if (String(
                                            address.addressId
                                            ) === committedAddressId) {

                                        updateSelectedAddress(
                                                address,
                                                false
                                                );
                                    }


                                    closeEditMode();


                                    showModalMessage(
                                            "Đã cập nhật địa chỉ.",
                                            true
                                            );


                                } catch (error) {

                                    showModalMessage(
                                            error.message,
                                            false
                                            );


                                } finally {

                                    addressRequestBusy =
                                            false;


                                    saveEditAddressButton.disabled =
                                            false;


                                    saveEditAddressButton.textContent =
                                            "Lưu thay đổi";


                                    updateDeleteButtons();
                                }
                            }
                    );
                }


                // =================================================
                // RESET MODAL
                // =================================================

                if (addressModal) {

                    addressModal.addEventListener(
                            "show.bs.modal",
                            function () {

                                closeEditMode();


                                if (addressList) {

                                    addressList
                                            .querySelectorAll(
                                                    'input[name="modalAddressId"]'
                                                    )
                                            .forEach(
                                                    function (radio) {

                                                        radio.checked =
                                                                radio.value
                                                                === committedAddressId;
                                                    }
                                            );


                                    const currentOption =
                                            getOptions()
                                            .find(
                                                    function (option) {

                                                        return option.dataset
                                                                .addressId
                                                                === committedAddressId;
                                                    }
                                            );


                                    if (currentOption) {

                                        addressList.prepend(
                                                currentOption
                                                );
                                    }
                                }


                                updateDeleteButtons();
                            }
                    );
                }


                // =================================================
                // SELECT RADIO
                // =================================================

                if (addressList) {

                    addressList.addEventListener(
                            "change",
                            function (event) {

                                if (event.target.matches(
                                        'input[name="modalAddressId"]'
                                        )) {

                                    updateDeleteButtons();
                                }
                            }
                    );
                }


                // =================================================
                // CONFIRM ADDRESS
                // =================================================

                if (confirmAddressButton) {

                    confirmAddressButton.addEventListener(
                            "click",
                            async function () {

                                if (addressRequestBusy
                                        || !addressList) {

                                    return;
                                }


                                const selectedRadio =
                                        addressList
                                        .querySelector(
                                                'input[name="modalAddressId"]:checked'
                                                );


                                if (!selectedRadio) {

                                    showModalMessage(
                                            "Vui lòng chọn địa chỉ giao hàng.",
                                            false
                                            );

                                    return;
                                }


                                const id =
                                        selectedRadio.value;


                                addressRequestBusy =
                                        true;


                                updateDeleteButtons();


                                try {

                                    const result =
                                            await postAddressAction(
                                                    {
                                                        action:
                                                                "selectAddress",

                                                        addressId:
                                                                id,

                                                        addressActionToken:
                                                                addressActionToken
                                                    }
                                            );


                                    const option =
                                            selectedRadio
                                            .closest(
                                                    ".address-option"
                                                    );


                                    updateSelectedAddress(
                                            result.selectedAddress,
                                            true
                                            );


                                    if (option) {

                                        addressList.prepend(
                                                option
                                                );
                                    }


                                    bootstrap.Modal
                                            .getOrCreateInstance(
                                                    addressModal
                                                    )
                                            .hide();


                                } catch (error) {

                                    showModalMessage(
                                            error.message,
                                            false
                                            );


                                } finally {

                                    addressRequestBusy =
                                            false;


                                    updateDeleteButtons();
                                }
                            }
                    );
                }


                // =================================================
                // DELETE ADDRESS AJAX
                // =================================================

                if (addressList) {

                    addressList.addEventListener(
                            "submit",
                            async function (event) {

                                const form =
                                        event.target.closest(
                                                ".delete-address-form"
                                                );


                                if (!form) {
                                    return;
                                }


                                event.preventDefault();


                                if (addressRequestBusy) {
                                    return;
                                }


                                const option =
                                        form.closest(
                                                ".address-option"
                                                );


                                if (!option) {
                                    return;
                                }


                                const id =
                                        option.dataset
                                        .addressId;


                                if (id === committedAddressId) {

                                    showModalMessage(
                                            "Không thể xóa địa chỉ đang sử dụng. "
                                            + "Vui lòng xác nhận địa chỉ khác trước.",
                                            false
                                            );

                                    return;
                                }


                                if (!window.confirm(
                                        "Bạn chắc chắn muốn xóa địa chỉ này?"
                                        )) {

                                    return;
                                }


                                addressRequestBusy =
                                        true;


                                updateDeleteButtons();


                                try {

                                    await postAddressAction(
                                            {
                                                action:
                                                        "deleteAddress",

                                                addressId:
                                                        id,

                                                addressActionToken:
                                                        addressActionToken
                                            }
                                    );


                                    option.remove();


                                    updateAddressListState();


                                    showModalMessage(
                                            "Đã xóa địa chỉ thành công.",
                                            true
                                            );


                                } catch (error) {

                                    showModalMessage(
                                            error.message,
                                            false
                                            );


                                } finally {

                                    addressRequestBusy =
                                            false;


                                    updateDeleteButtons();
                                }
                            }
                    );
                }


                // =================================================
                // ADD ADDRESS ANTI DOUBLE SUBMIT
                // =================================================

                const addAddressForm =
                        document.getElementById(
                                "addAddressForm"
                                );


                const saveAddressButton =
                        document.getElementById(
                                "saveAddressButton"
                                );


                if (addAddressForm) {

                    addAddressForm.addEventListener(
                            "submit",
                            function (event) {

                                if (addAddressForm
                                        .dataset
                                        .submitting
                                        === "true") {

                                    event.preventDefault();

                                    return;
                                }


                                if (!addAddressForm
                                        .checkValidity()) {

                                    return;
                                }


                                addAddressForm
                                        .dataset
                                        .submitting =
                                        "true";


                                if (saveAddressButton) {

                                    saveAddressButton.disabled =
                                            true;


                                    saveAddressButton.textContent =
                                            "Đang lưu...";
                                }
                            }
                    );
                }


                // =================================================
                // PLACE ORDER ANTI DOUBLE SUBMIT
                // =================================================

                const orderForm =
                        document.getElementById(
                                "orderForm"
                                );


                if (orderForm) {

                    orderForm.addEventListener(
                            "submit",
                            function (event) {

                                if (orderForm
                                        .dataset
                                        .submitting
                                        === "true") {

                                    event.preventDefault();

                                    return;
                                }


                                if (!orderForm
                                        .checkValidity()) {

                                    return;
                                }


                                orderForm
                                        .dataset
                                        .submitting =
                                        "true";


                                if (placeOrderButton) {

                                    placeOrderButton.disabled =
                                            true;


                                    placeOrderButton.textContent =
                                            "Đang xử lý đơn hàng...";
                                }
                            }
                    );
                }


                updateAddressListState();

                updateDeleteButtons();

            }
    );

</script>


<%@include file="/WEB-INF/include/footer.jsp" %>
