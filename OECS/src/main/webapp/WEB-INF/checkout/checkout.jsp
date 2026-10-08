<%@ page pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@ include file="/WEB-INF/include/header.jsp" %>

<!-- TIEU DE CHECKOUT -->
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h3 class="fw-bold mb-1">Xác nhận đơn hàng</h3>
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

<div class="row g-4">

    <!-- COT TRAI -->
    <div class="col-lg-8">

        <!-- DIA CHI GIAO HANG -->
        <div class="card shadow-sm border-0 rounded-4 mb-4">
            <div class="card-body p-4">

                <div class="d-flex justify-content-between align-items-center mb-3">
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

                    <div class="fw-semibold" id="selectedAddressName">
                        <c:out value="${selectedAddress.recipientName}" />
                        |
                        <c:out value="${selectedAddress.phoneNumber}" />
                    </div>

                    <div class="text-muted mt-1" id="selectedAddressLine">
                        <c:out value="${selectedAddress.addressLine}" />
                    </div>

                    <span id="selectedDefaultBadge"
                          class="badge bg-primary mt-2"
                          style="${selectedAddress.defaultAddress ? '' : 'display:none;'}">
                        Mặc định
                    </span>
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

                <div class="table-responsive">
                    <table class="table align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Sản phẩm</th>
                                <th class="text-end">Đơn giá</th>
                                <th class="text-center">Số lượng</th>
                                <th class="text-end">Thành tiền</th>
                            </tr>
                        </thead>

                        <tbody>
                            <c:forEach var="item" items="${cartItems}">
                                <tr>
                                    <td>
                                        <div class="fw-semibold">
                                            <c:out value="${item.productName}" />
                                        </div>

                                        <small class="text-muted">
                                            SKU:
                                            <c:out value="${item.skuCode}" />
                                        </small>
                                    </td>

                                    <td class="text-end">
                                        <fmt:formatNumber
                                            value="${item.price}"
                                            type="number"
                                            maxFractionDigits="0" />đ
                                    </td>

                                    <td class="text-center">
                                        ${item.quantity}
                                    </td>

                                    <td class="text-end fw-semibold">
                                        <fmt:formatNumber
                                            value="${item.price * item.quantity}"
                                            type="number"
                                            maxFractionDigits="0" />đ
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>

                <small class="text-muted">
                    Muốn thay đổi số lượng, vui lòng quay lại giỏ hàng.
                </small>

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

                    <div class="input-group mb-3">
                        <input type="text"
                               name="voucherCode"
                               class="form-control"
                               placeholder="Nhập mã giảm giá"
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

                <label class="d-block border border-primary rounded-3 p-3 mb-3">
                    <input type="radio"
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
                    <span class="ms-2">VNPay — Đang phát triển</span>
                </label>

                <label class="d-block border rounded-3 p-3 text-muted">
                    <input type="radio" disabled>
                    <span class="ms-2">MoMo — Đang phát triển</span>
                </label>

            </div>
        </div>
    </div>

    <!-- COT PHAI: TONG KET -->
    <div class="col-lg-4">
        <div class="card shadow-sm border-0 rounded-4">
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
                    <span>0đ</span>
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

                <div class="d-flex justify-content-between align-items-center mb-4">
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

                <p class="text-muted small text-center mt-3 mb-0">
                    Vui lòng kiểm tra đơn hàng trước khi xác nhận.
                </p>

            </div>
        </div>
    </div>
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
