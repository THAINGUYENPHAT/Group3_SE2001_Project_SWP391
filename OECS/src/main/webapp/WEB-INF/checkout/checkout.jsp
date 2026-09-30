<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Đặt hàng & Thanh toán</title>

        <link
            href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
            rel="stylesheet">
    </head>

    <body class="bg-light">

        <div class="container py-4">

            <h2 class="mb-4">Đặt hàng & Thanh toán</h2>

            <!-- ============================
                 THONG BAO LOI
            ============================= -->
            <c:if test="${not empty sessionScope.checkoutError}">
                <div class="alert alert-danger">
                    ${sessionScope.checkoutError}
                </div>

                <c:remove
                    var="checkoutError"
                    scope="session"/>
            </c:if>


            <!-- ============================
                 DIA CHI NHAN HANG
            ============================= -->
            <div class="card mb-4">

                <div class="card-header">
                    <strong>Địa chỉ nhận hàng</strong>
                </div>

                <div class="card-body">

                    <c:choose>

                        <!-- Chua co dia chi -->
                        <c:when test="${empty addresses}">
                            <div class="alert alert-warning">
                                Bạn chưa có địa chỉ nhận hàng.
                            </div>
                        </c:when>

                        <!-- Co dia chi -->
                        <c:otherwise>

                            <c:forEach
                                var="address"
                                items="${addresses}"
                                varStatus="status">

                                <div class="form-check mb-3">

                                    <input
                                        class="form-check-input"
                                        type="radio"
                                        name="addressId"
                                        form="orderForm"
                                        value="${address.addressId}"
                                        id="address${address.addressId}"

                                        <c:if test="${sessionScope.selectedAddressId == address.addressId}">
                                            checked
                                        </c:if>

                                        <c:if test="${empty sessionScope.selectedAddressId && status.first}">
                                            checked
                                        </c:if>
                                        >

                                    <label
                                        class="form-check-label"
                                        for="address${address.addressId}">

                                        <strong>
                                            ${address.recipientName}
                                        </strong>

                                        <span class="mx-1">|</span>

                                        ${address.phoneNumber}

                                        <br>

                                        ${address.addressLine}

                                        <c:if test="${address.defaultAddress}">
                                            <span class="badge bg-primary ms-2">
                                                Mặc định
                                            </span>
                                        </c:if>

                                    </label>

                                </div>

                            </c:forEach>

                        </c:otherwise>

                    </c:choose>


                    <button
                        type="button"
                        class="btn btn-outline-primary"
                        data-bs-toggle="modal"
                        data-bs-target="#addressModal">

                        + Thêm địa chỉ mới

                    </button>

                </div>
            </div>


            <!-- ============================
                 DANH SACH SAN PHAM
            ============================= -->
            <div class="card mb-4">

                <div class="card-header">
                    <strong>Sản phẩm</strong>
                </div>

                <div class="card-body">

                    <div class="table-responsive">

                        <table class="table align-middle">

                            <thead>
                                <tr>
                                    <th>Sản phẩm</th>
                                    <th>SKU</th>
                                    <th>Đơn giá</th>
                                    <th>Số lượng</th>
                                    <th>Thành tiền</th>
                                </tr>
                            </thead>

                            <tbody>

                                <c:forEach
                                    var="item"
                                    items="${cartItems}">

                                    <tr>

                                        <td>
                                            ${item.productName}
                                        </td>

                                        <td>
                                            ${item.skuCode}
                                        </td>

                                        <td>
                                            <fmt:formatNumber
                                                value="${item.price}"
                                                type="number"
                                                groupingUsed="true"/>
                                            đ
                                        </td>

                                        <td>
                                            ${item.quantity}
                                        </td>

                                        <td>
                                            <fmt:formatNumber
                                                value="${item.subtotal}"
                                                type="number"
                                                groupingUsed="true"/>
                                            đ
                                        </td>

                                    </tr>

                                </c:forEach>

                            </tbody>

                        </table>

                    </div>
                </div>
            </div>


            <!-- ============================
                 VOUCHER
            ============================= -->
            <div class="card mb-4">

                <div class="card-header">
                    <strong>Voucher</strong>
                </div>

                <div class="card-body">

                    <!-- Nhap ma Voucher -->
                    <form
                        action="${pageContext.request.contextPath}/checkout"
                        method="post"
                        class="mb-3">

                        <input
                            type="hidden"
                            name="action"
                            value="applyVoucher">

                        <div class="input-group">

                            <input
                                type="text"
                                name="voucherCode"
                                class="form-control"
                                placeholder="Nhập mã Voucher"
                                required>

                            <button
                                type="submit"
                                class="btn btn-primary">

                                Áp dụng

                            </button>

                        </div>

                    </form>


                    <!-- Voucher kha dung -->
                    <c:if test="${not empty availableVouchers}">

                        <p class="mb-2">
                            <strong>Voucher khả dụng:</strong>
                        </p>

                        <c:forEach
                            var="v"
                            items="${availableVouchers}">

                            <form
                                action="${pageContext.request.contextPath}/checkout"
                                method="post"
                                class="d-inline-block me-2 mb-2">

                                <input
                                    type="hidden"
                                    name="action"
                                    value="applyVoucher">

                                <input
                                    type="hidden"
                                    name="voucherCode"
                                    value="${v.code}">

                                <button
                                    type="submit"
                                    class="btn btn-outline-success">

                                    ${v.code}

                                </button>

                            </form>

                        </c:forEach>

                    </c:if>


                    <!-- Voucher dang su dung -->
                    <c:if test="${not empty voucher}">

                        <div class="alert alert-success mt-3 mb-0">

                            Đang áp dụng:

                            <strong>
                                ${voucher.code}
                            </strong>

                            <form
                                action="${pageContext.request.contextPath}/checkout"
                                method="post"
                                class="d-inline">

                                <input
                                    type="hidden"
                                    name="action"
                                    value="removeVoucher">

                                <button
                                    type="submit"
                                    class="btn btn-sm btn-outline-danger ms-2">

                                    Bỏ mã

                                </button>

                            </form>

                        </div>

                    </c:if>

                </div>
            </div>


            <!-- ============================
                 FORM DAT HANG
            ============================= -->
            <form
                id="orderForm"
                action="${pageContext.request.contextPath}/checkout"
                method="post"
                onsubmit="disableOrderButton()">

                <input
                    type="hidden"
                    name="action"
                    value="placeOrder">


                <!-- ============================
                     PHUONG THUC THANH TOAN
                ============================= -->
                <div class="card mb-4">

                    <div class="card-header">
                        <strong>Phương thức thanh toán</strong>
                    </div>

                    <div class="card-body">

                        <!-- COD -->
                        <div class="form-check">

                            <input
                                class="form-check-input"
                                type="radio"
                                name="paymentMethod"
                                value="COD"
                                id="cod"
                                checked>

                            <label
                                class="form-check-label"
                                for="cod">

                                Thanh toán khi nhận hàng (COD)

                            </label>

                        </div>


                        <!-- VNPay -->
                        <div class="form-check mt-3">

                            <input
                                class="form-check-input"
                                type="radio"
                                id="vnpay"
                                disabled>

                            <label
                                class="form-check-label text-muted"
                                for="vnpay">

                                VNPay
                                <span class="badge bg-secondary">
                                    Đang phát triển
                                </span>

                            </label>

                        </div>


                        <!-- MoMo -->
                        <div class="form-check mt-3">

                            <input
                                class="form-check-input"
                                type="radio"
                                id="momo"
                                disabled>

                            <label
                                class="form-check-label text-muted"
                                for="momo">

                                MoMo
                                <span class="badge bg-secondary">
                                    Đang phát triển
                                </span>

                            </label>

                        </div>

                    </div>
                </div>


                <!-- ============================
                     TONG TIEN
                ============================= -->
                <div class="card mb-4">

                    <div class="card-body">

                        <div class="row justify-content-end">

                            <div class="col-md-5">

                                <!-- Tien hang -->
                                <div class="d-flex justify-content-between mb-2">

                                    <span>Tiền hàng:</span>

                                    <strong>
                                        <fmt:formatNumber
                                            value="${subtotal}"
                                            type="number"
                                            groupingUsed="true"/>
                                        đ
                                    </strong>

                                </div>


                                <!-- Phi ship -->
                                <div class="d-flex justify-content-between mb-2">

                                    <span>Phí vận chuyển:</span>

                                    <strong>
                                        0 đ
                                    </strong>

                                </div>


                                <!-- Voucher -->
                                <c:if test="${discount > 0}">

                                    <div
                                        class="d-flex justify-content-between mb-2 text-success">

                                        <span>Voucher:</span>

                                        <strong>
                                            -
                                            <fmt:formatNumber
                                                value="${discount}"
                                                type="number"
                                                groupingUsed="true"/>
                                            đ
                                        </strong>

                                    </div>

                                </c:if>


                                <hr>


                                <!-- Tong thanh toan -->
                                <div class="d-flex justify-content-between">

                                    <h5>Tổng thanh toán:</h5>

                                    <h4 class="text-danger">

                                        <fmt:formatNumber
                                            value="${finalTotal}"
                                            type="number"
                                            groupingUsed="true"/>
                                        đ

                                    </h4>

                                </div>


                                <!-- Nut dat hang -->
                                <button
                                    id="orderButton"
                                    type="submit"
                                    class="btn btn-danger btn-lg w-100 mt-3"

                                    <c:if test="${empty addresses}">
                                        disabled
                                    </c:if>>

                                    Đặt hàng

                                </button>

                            </div>

                        </div>

                    </div>
                </div>

            </form>

        </div>


        <!-- ============================
             MODAL THEM DIA CHI
        ============================= -->
        <div
            class="modal fade"
            id="addressModal"
            tabindex="-1">

            <div class="modal-dialog">

                <div class="modal-content">

                    <form
                        action="${pageContext.request.contextPath}/checkout"
                        method="post">

                        <input
                            type="hidden"
                            name="action"
                            value="addAddress">


                        <!-- Header -->
                        <div class="modal-header">

                            <h5 class="modal-title">
                                Thêm địa chỉ mới
                            </h5>

                            <button
                                type="button"
                                class="btn-close"
                                data-bs-dismiss="modal">
                            </button>

                        </div>


                        <!-- Body -->
                        <div class="modal-body">

                            <!-- Ten nguoi nhan -->
                            <div class="mb-3">

                                <label class="form-label">
                                    Họ tên người nhận
                                </label>

                                <input
                                    type="text"
                                    name="recipientName"
                                    class="form-control"
                                    maxlength="100"
                                    required>

                            </div>


                            <!-- So dien thoai -->
                            <div class="mb-3">

                                <label class="form-label">
                                    Số điện thoại
                                </label>

                                <input
                                    type="text"
                                    name="phoneNumber"
                                    class="form-control"
                                    maxlength="11"
                                    placeholder="Ví dụ: 0912345678"
                                    required>

                            </div>


                            <!-- Dia chi -->
                            <div class="mb-3">

                                <label class="form-label">
                                    Địa chỉ
                                </label>

                                <textarea
                                    name="addressLine"
                                    class="form-control"
                                    rows="3"
                                    placeholder="Nhập địa chỉ giao hàng"
                                    required></textarea>

                            </div>

                        </div>


                        <!-- Footer -->
                        <div class="modal-footer">

                            <button
                                type="button"
                                class="btn btn-secondary"
                                data-bs-dismiss="modal">

                                Hủy

                            </button>

                            <button
                                type="submit"
                                class="btn btn-primary">

                                Thêm địa chỉ

                            </button>

                        </div>

                    </form>

                </div>
            </div>
        </div>


        <!-- ============================
             CHONG BAM DAT HANG 2 LAN
        ============================= -->
        <script>
            function disableOrderButton() {
                const button =
                        document.getElementById("orderButton");

                button.disabled = true;
                button.innerText = "Đang xử lý...";
            }
        </script>


        <script
            src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js">
        </script>

    </body>
</html>