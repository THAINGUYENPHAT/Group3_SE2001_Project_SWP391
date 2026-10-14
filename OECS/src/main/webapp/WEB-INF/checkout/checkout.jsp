<%@ page pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@ include file="/WEB-INF/include/header.jsp" %>


<!-- ===================================================== -->
<!-- HEADER -->
<!-- ===================================================== -->

<div class="d-flex justify-content-between align-items-center mb-4">

    <div>

        <h3 class="fw-bold mb-1">
            Xác nhận đơn hàng
        </h3>

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


<!-- ===================================================== -->
<!-- SERVER MESSAGE -->
<!-- ===================================================== -->

<c:if test="${not empty sessionScope.checkoutError}">

    <div class="alert alert-danger">

        <c:out value="${sessionScope.checkoutError}"/>

    </div>

    <c:remove
        var="checkoutError"
        scope="session"/>

</c:if>


<c:if test="${not empty sessionScope.checkoutMessage}">

    <div class="alert alert-success">

        <c:out value="${sessionScope.checkoutMessage}"/>

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

        <div class="card shadow-sm border-0 rounded-4 mb-4">

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

                        <c:out value="${selectedAddress.recipientName}"/>

                        |

                        <c:out value="${selectedAddress.phoneNumber}"/>

                    </div>


                    <div
                        class="text-muted mt-1"
                        id="selectedAddressLine">

                        <c:out value="${selectedAddress.addressLine}"/>

                    </div>


                    <span
                        id="selectedDefaultBadge"
                        class="badge bg-primary mt-2"
                        style="${selectedAddress.defaultAddress ? '' : 'display:none;'}">

                        Mặc định

                    </span>

                </div>

            </div>

        </div>


        <!-- ============================================= -->
        <!-- PRODUCTS -->
        <!-- ============================================= -->

        <div class="card shadow-sm border-0 rounded-4 mb-4">

            <div class="card-body p-4">


                <h5 class="fw-bold mb-3">

                    <i class="bi bi-bag-check text-primary me-2"></i>

                    Sản phẩm đặt mua

                </h5>


                <div class="table-responsive">

                    <table class="table align-middle">

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

                                            <c:out value="${item.productName}"/>

                                        </div>


                                        <small class="text-muted">

                                            SKU:

                                            <c:out value="${item.skuCode}"/>

                                        </small>

                                    </td>


                                    <td class="text-end">

                                        <fmt:formatNumber
                                            value="${item.price}"
                                            type="number"
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
                                            maxFractionDigits="0"/>

                                        đ

                                    </td>

                                </tr>

                            </c:forEach>

                        </tbody>

                    </table>

                </div>


                <small class="text-muted">

                    Muốn thay đổi số lượng,
                    vui lòng quay lại giỏ hàng.

                </small>

            </div>

        </div>


        <!-- ============================================= -->
        <!-- VOUCHER -->
        <!-- ============================================= -->

        <div class="card shadow-sm border-0 rounded-4 mb-4">

            <div class="card-body p-4">


                <h5 class="fw-bold mb-3">

                    <i class="bi bi-ticket-perforated text-primary me-2"></i>

                    Mã giảm giá

                </h5>


                <!-- APPLIED -->

                <c:if test="${not empty appliedVoucher}">

                    <div class="alert alert-success">

                        Đang áp dụng:

                        <strong>

                            <c:out value="${appliedVoucher.code}"/>

                        </strong>


                        <div class="small mt-1">

                            <c:choose>

                                <c:when test="${appliedVoucher.discountType == 'PERCENT'}">

                                    Giảm
                                    ${appliedVoucher.discountValue}%

                                    <c:if test="${not empty appliedVoucher.maxDiscount}">

                                        - tối đa

                                        <fmt:formatNumber
                                            value="${appliedVoucher.maxDiscount}"
                                            type="number"
                                            maxFractionDigits="0"/>

                                        đ

                                    </c:if>

                                </c:when>


                                <c:otherwise>

                                    Giảm

                                    <fmt:formatNumber
                                        value="${appliedVoucher.discountValue}"
                                        type="number"
                                        maxFractionDigits="0"/>

                                    đ

                                </c:otherwise>

                            </c:choose>

                        </div>


                        <form
                            action="${pageContext.request.contextPath}/checkout"
                            method="post"
                            class="mt-2">

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
                                    method="post">


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
                                        class="btn btn-outline-success w-100 text-start"
                                        ${not empty appliedVoucher
                                          && appliedVoucher.voucherId == voucher.voucherId
                                          ? 'disabled' : ''}>


                                        <div class="d-flex justify-content-between align-items-center">


                                            <strong>

                                                <i class="bi bi-ticket-perforated me-1"></i>

                                                <c:out value="${voucher.code}"/>

                                            </strong>


                                            <span>

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
                                                            maxFractionDigits="0"/>

                                                        đ

                                                    </c:otherwise>


                                                </c:choose>

                                            </span>

                                        </div>


                                        <small class="text-muted">

                                            Đơn tối thiểu:

                                            <fmt:formatNumber
                                                value="${voucher.minOrderValue}"
                                                type="number"
                                                maxFractionDigits="0"/>

                                            đ


                                            <c:if test="${voucher.discountType == 'PERCENT'
                                                        && not empty voucher.maxDiscount}">

                                                · Tối đa:

                                                <fmt:formatNumber
                                                    value="${voucher.maxDiscount}"
                                                    type="number"
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

                        <p class="text-muted small mb-0">

                            Hiện không có Voucher khả dụng
                            cho đơn hàng này.

                        </p>

                    </c:otherwise>


                </c:choose>

            </div>

        </div>


        <!-- ============================================= -->
        <!-- PAYMENT -->
        <!-- ============================================= -->

        <div class="card shadow-sm border-0 rounded-4">

            <div class="card-body p-4">


                <h5 class="fw-bold mb-3">

                    <i class="bi bi-credit-card text-primary me-2"></i>

                    Phương thức thanh toán

                </h5>


                <label class="d-block border border-primary rounded-3 p-3 mb-3">


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


                <label class="d-block border rounded-3 p-3 mb-3 text-muted">

                    <input type="radio" disabled>

                    <span class="ms-2">
                        VNPay — Đang phát triển
                    </span>

                </label>


                <label class="d-block border rounded-3 p-3 text-muted">

                    <input type="radio" disabled>

                    <span class="ms-2">
                        MoMo — Đang phát triển
                    </span>

                </label>

            </div>

        </div>

    </div>


    <!-- ================================================= -->
    <!-- RIGHT SUMMARY -->
    <!-- ================================================= -->

    <div class="col-lg-4">


        <div class="card shadow-sm border-0 rounded-4">

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
                            maxFractionDigits="0"/>

                        đ

                    </strong>

                </div>


                <div class="d-flex justify-content-between mb-3">

                    <span>
                        Phí vận chuyển
                    </span>

                    <span>
                        0đ
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
                            maxFractionDigits="0"/>

                        đ

                    </span>

                </div>


                <hr>


                <div class="d-flex justify-content-between align-items-center mb-4">

                    <strong>
                        Tổng thanh toán
                    </strong>


                    <h4 class="text-danger fw-bold mb-0">

                        <fmt:formatNumber
                            value="${totalAmount}"
                            type="number"
                            maxFractionDigits="0"/>

                        đ

                    </h4>

                </div>


                <!-- ORDER FORM -->

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
                        name="addressId"
                        id="orderAddressId"
                        value="${selectedAddress.addressId}">


                    <input
                        type="hidden"
                        name="checkoutToken"
                        value="${checkoutToken}">


                    <button
                        type="submit"
                        id="placeOrderButton"
                        class="btn btn-primary w-100 py-3 fw-semibold"
                        ${empty selectedAddress ? 'disabled' : ''}>

                        <i class="bi bi-bag-check me-1"></i>

                        Đặt hàng COD

                    </button>

                </form>


                <p
                    id="needAddressMessage"
                    class="text-danger small text-center mt-2"
                    style="${empty selectedAddress ? '' : 'display:none;'}">

                    Vui lòng thêm địa chỉ trước khi đặt hàng.

                </p>


                <p class="text-muted small text-center mt-3 mb-0">

                    Vui lòng kiểm tra đơn hàng trước khi xác nhận.

                </p>

            </div>

        </div>

    </div>

</div>


<!-- ===================================================== -->
<!-- ADDRESS SELECT MODAL -->
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
                    data-bs-dismiss="modal">
                </button>

            </div>


            <div
                id="addressModalMessage"
                class="alert mx-3 mt-3 mb-0 d-none">
            </div>


            <div
                id="addressList"
                class="modal-body"
                style="max-height:400px;overflow-y:auto;">


                <c:forEach
                    var="address"
                    items="${addresses}">


                    <div
                        class="border rounded-3 p-3 mb-2 address-option"
                        data-address-id="${address.addressId}">


                        <div class="d-flex gap-3 align-items-start">


                            <input
                                type="radio"
                                class="form-check-input mt-1 address-radio"
                                name="modalAddressId"
                                value="${address.addressId}"
                                ${selectedAddress.addressId == address.addressId
                                  ? 'checked' : ''}>


                            <div class="flex-grow-1">


                                <label class="fw-semibold d-block address-name">

                                    <c:out value="${address.recipientName}"/>

                                    |

                                    <c:out value="${address.phoneNumber}"/>

                                </label>


                                <div class="text-muted small address-line">

                                    <c:out value="${address.addressLine}"/>

                                </div>


                                <c:if test="${address.defaultAddress}">

                                    <span class="badge bg-primary mt-2">

                                        Mặc định

                                    </span>

                                </c:if>

                            </div>


                            <form
                                action="${pageContext.request.contextPath}/checkout"
                                method="post"
                                class="delete-address-form">


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
                                    value="${sessionScope.addressActionToken}">


                                <button
                                    type="submit"
                                    class="btn btn-outline-danger btn-sm delete-address-button">

                                    <i class="bi bi-trash me-1"></i>

                                    Xóa

                                </button>

                            </form>

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


            <div class="modal-footer">


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
<!-- ADD ADDRESS MODAL -->
<!-- ===================================================== -->

<div
    class="modal fade"
    id="addAddressModal"
    tabindex="-1"
    aria-hidden="true">


    <div class="modal-dialog modal-dialog-centered">


        <div class="modal-content rounded-4">


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


            <form
                id="addAddressForm"
                action="${pageContext.request.contextPath}/checkout"
                method="post">


                <input
                    type="hidden"
                    name="action"
                    value="addAddress">


                <input
                    type="hidden"
                    name="addressAddToken"
                    value="${sessionScope.addressAddToken}">


                <div class="modal-body">


                    <div class="mb-3">

                        <label class="form-label fw-semibold">

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

                        <label class="form-label fw-semibold">

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

                        <label class="form-label fw-semibold">

                            Địa chỉ chi tiết

                        </label>


                        <textarea
                            name="addressLine"
                            class="form-control"
                            rows="3"
                            placeholder="Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành phố"
                            required></textarea>

                    </div>

                </div>


                <div class="modal-footer">


                    <button
                        type="button"
                        class="btn btn-light border"
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


<!-- ===================================================== -->
<!-- JAVASCRIPT ADDRESS -->
<!-- ===================================================== -->

<script>
    document.addEventListener(
            "DOMContentLoaded",
            function () {

                const checkoutUrl =
                        "${pageContext.request.contextPath}/checkout";

                const addressActionToken =
                        "${sessionScope.addressActionToken}";

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


                let committedAddressId =
                        addressInput
                        ? addressInput.value
                        : "";

                let addressRequestBusy = false;


                function showModalMessage(
                        message,
                        success) {

                    modalMessage.textContent =
                            message;

                    modalMessage.className =
                            success
                            ? "alert alert-success mx-3 mt-3 mb-0"
                            : "alert alert-danger mx-3 mt-3 mb-0";
                }


                async function postAddressAction(
                        data) {

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


                    const contentType =
                            response.headers
                                    .get(
                                        "content-type"
                                    ) || "";


                    if (!contentType.includes(
                            "application/json")) {

                        throw new Error(
                            "Server không trả JSON. Vui lòng tải lại trang."
                        );
                    }


                    const result =
                            await response.json();


                    if (!response.ok
                            || !result.success) {

                        throw new Error(
                            result.message
                            || "Thao tác không thành công."
                        );
                    }


                    return result;
                }


                function updateSelectedAddress(
                        address,
                        isDefault) {

                    if (!address) {

                        addressInput.value = "";

                        committedAddressId = "";

                        selectedName.textContent = "";

                        selectedLine.textContent = "";

                        selectedCard.style.display =
                                "none";

                        noAddressMessage.style.display =
                                "";

                        needAddressMessage.style.display =
                                "";

                        selectedDefaultBadge.style.display =
                                "none";

                        placeOrderButton.disabled =
                                true;

                        return;
                    }


                    const id =
                            String(
                                address.addressId
                            );


                    committedAddressId =
                            id;

                    addressInput.value =
                            id;


                    selectedName.textContent =
                            address.recipientName
                            + " | "
                            + address.phoneNumber;


                    selectedLine.textContent =
                            address.addressLine;


                    selectedDefaultBadge.style.display =
                            isDefault
                            ? ""
                            : "none";


                    selectedCard.style.display =
                            "";

                    noAddressMessage.style.display =
                            "none";

                    needAddressMessage.style.display =
                            "none";

                    placeOrderButton.disabled =
                            false;
                }


                function updateDeleteButtons() {

                    if (!addressList) {
                        return;
                    }


                    addressList
                            .querySelectorAll(
                                ".address-option"
                            )
                            .forEach(
                                function (option) {

                                    const button =
                                            option.querySelector(
                                                ".delete-address-button"
                                            );

                                    if (!button) {
                                        return;
                                    }


                                    const isSelected =
                                            option.dataset.addressId
                                            === committedAddressId;


                                    button.disabled =
                                            isSelected
                                            || addressRequestBusy;


                                    button.title =
                                            isSelected
                                            ? "Không thể xóa địa chỉ đang sử dụng"
                                            : "Xóa địa chỉ";


                                    button.innerHTML =
                                            isSelected
                                            ? '<i class="bi bi-check-circle me-1"></i>Đang dùng'
                                            : '<i class="bi bi-trash me-1"></i>Xóa';
                                });


                    confirmAddressButton.disabled =
                            addressRequestBusy
                            || !addressList.querySelector(
                                ".address-option"
                            );
                }


                function updateAddressListState() {

                    if (!addressList) {
                        return;
                    }


                    const options =
                            addressList.querySelectorAll(
                                ".address-option"
                            );


                    const hasAddress =
                            options.length > 0;


                    addressListEmpty.style.display =
                            hasAddress
                            ? "none"
                            : "";


                    openAddressModalButton.disabled =
                            !hasAddress;


                    if (!hasAddress) {

                        updateSelectedAddress(
                            null,
                            false
                        );
                    }


                    updateDeleteButtons();
                }


                if (addressModal) {

                    addressModal.addEventListener(
                            "show.bs.modal",
                            function () {

                                addressList
                                        .querySelectorAll(
                                            'input[name="modalAddressId"]'
                                        )
                                        .forEach(
                                            function (radio) {

                                                radio.checked =
                                                        radio.value
                                                        === committedAddressId;
                                            });


                                modalMessage.className =
                                        "alert mx-3 mt-3 mb-0 d-none";


                                updateDeleteButtons();
                            });
                }


                if (confirmAddressButton) {

                    confirmAddressButton.addEventListener(
                            "click",
                            async function () {

                                if (addressRequestBusy) {
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


                                if (id
                                        === committedAddressId) {

                                    bootstrap.Modal
                                            .getOrCreateInstance(
                                                addressModal
                                            )
                                            .hide();

                                    return;
                                }


                                addressRequestBusy =
                                        true;

                                updateDeleteButtons();


                                try {

                                    const result =
                                            await postAddressAction({
                                                action:
                                                    "selectAddress",

                                                addressId:
                                                    id,

                                                addressActionToken:
                                                    addressActionToken
                                            });


                                    const option =
                                            selectedRadio
                                            .closest(
                                                ".address-option"
                                            );


                                    const isDefault =
                                            !!option
                                            .querySelector(
                                                ".badge"
                                            );


                                    updateSelectedAddress(
                                        result.selectedAddress,
                                        isDefault
                                    );


                                    updateDeleteButtons();


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
                            });
                }


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


                                const id =
                                        option.dataset.addressId;


                                if (id
                                        === committedAddressId) {

                                    showModalMessage(
                                        "Không thể xóa địa chỉ đang sử dụng. "
                                        + "Vui lòng chọn địa chỉ khác trước.",
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

                                    await postAddressAction({
                                        action:
                                            "deleteAddress",

                                        addressId:
                                            id,

                                        addressActionToken:
                                            addressActionToken
                                    });


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
                            });
                }


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


                                saveAddressButton.disabled =
                                        true;


                                saveAddressButton.textContent =
                                        "Đang lưu...";
                            });
                }


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


                                placeOrderButton.disabled =
                                        true;


                                placeOrderButton.textContent =
                                        "Đang xử lý đơn hàng...";
                            });
                }


                updateAddressListState();
            });
</script>

<%@ include file="/WEB-INF/include/footer.jsp" %>