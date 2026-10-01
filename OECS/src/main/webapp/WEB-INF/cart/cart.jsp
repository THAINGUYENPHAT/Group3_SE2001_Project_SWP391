<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .cart-page {
        padding-bottom: 30px;
    }

    .page-title {
        font-size: 1.55rem;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 4px;
    }

    .page-description {
        color: #64748b;
        font-size: 0.9rem;
    }

    .stat-card-cart {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 1.35rem;
        height: 100%;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }

    .stat-label {
        color: #475569;
        font-size: 0.95rem;
        font-weight: 500;
    }

    .stat-value {
        color: #0f172a;
        font-size: 1.55rem;
        font-weight: 700;
        margin-top: 12px;
    }

    .stat-icon {
        width: 38px;
        height: 38px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #dbeafe;
        color: #2563eb;
        font-size: 1rem;
    }

    .stat-icon-green {
        background: #dcfce7;
        color: #16a34a;
    }

    .stat-icon-cyan {
        background: #cffafe;
        color: #0891b2;
    }

    .content-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        overflow: hidden;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }

    .content-card-header {
        padding: 18px 20px;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 15px;
    }

    .content-card-title {
        margin: 0;
        font-size: 1rem;
        font-weight: 700;
        color: #0f172a;
    }

    .cart-table {
        margin: 0;
    }

    .cart-table thead th {
        background: #f8fafc;
        color: #64748b;
        font-size: 0.75rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        font-weight: 600;
        padding: 16px 18px;
        border-bottom: 1px solid #e2e8f0;
        white-space: nowrap;
    }

    .cart-table tbody td {
        padding: 18px;
        vertical-align: middle;
        color: #334155;
        font-size: 0.9rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .cart-table tbody tr:last-child td {
        border-bottom: none;
    }

    .product-box {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .product-icon {
        width: 46px;
        height: 46px;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        background: #ffffff;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #2563eb;
        flex-shrink: 0;
    }

    .product-name {
        color: #0f172a;
        font-weight: 700;
        margin-bottom: 3px;
    }

    .sku-text {
        font-family: monospace;
        color: #e11d48;
        font-size: 0.85rem;
    }

    .price-text {
        color: #0f172a;
        font-weight: 600;
        white-space: nowrap;
    }

    .subtotal-text {
        color: #2563eb;
        font-weight: 700;
        white-space: nowrap;
    }

    .quantity-input {
        width: 72px;
        height: 38px;
        border: 1px solid #cbd5e1;
        border-radius: 8px;
        text-align: center;
        color: #0f172a;
        font-weight: 600;
        background: #ffffff;
        transition: 0.2s;
    }

    .quantity-input:hover {
        border-color: #94a3b8;
    }

    .quantity-input:focus {
        border-color: #2563eb;
        outline: none;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
    }

    .stock-badge {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: #dcfce7;
        color: #15803d;
        border: 1px solid #bbf7d0;
        padding: 5px 10px;
        border-radius: 999px;
        font-size: 0.78rem;
        font-weight: 600;
    }

    .stock-badge::before {
        content: "";
        width: 6px;
        height: 6px;
        background: #16a34a;
        border-radius: 50%;
    }

    .action-btn {
        width: 36px;
        height: 36px;
        border-radius: 8px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        text-decoration: none;
        transition: 0.2s;
    }

    .delete-btn {
        color: #ef4444;
        background: #ffffff;
        border: 1px solid #e2e8f0;
    }

    .delete-btn:hover {
        color: #dc2626;
        background: #fef2f2;
        border-color: #fecaca;
    }

    .btn-clear {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        border: 1px solid #cbd5e1;
        background: #ffffff;
        color: #475569;
        border-radius: 8px;
        padding: 8px 12px;
        font-size: 0.85rem;
        font-weight: 500;
        text-decoration: none;
        transition: 0.2s;
    }

    .btn-clear:hover {
        color: #dc2626;
        background: #fef2f2;
        border-color: #fecaca;
    }

    .bottom-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        height: 100%;
        padding: 22px;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }

    .bottom-title {
        color: #0f172a;
        font-weight: 700;
        font-size: 1rem;
        margin-bottom: 18px;
        display: flex;
        align-items: center;
        gap: 8px;
    }

    .voucher-input {
        height: 42px;
        border: 1px solid #cbd5e1;
        border-radius: 8px 0 0 8px;
        font-size: 0.88rem;
    }

    .voucher-input:focus {
        border-color: #2563eb;
        box-shadow: none;
    }

    .btn-voucher {
        border: none;
        background: #2563eb;
        color: white;
        font-weight: 600;
        padding: 0 18px;
        border-radius: 0 8px 8px 0;
    }

    .btn-voucher:hover {
        background: #1d4ed8;
    }

    .voucher-applied {
        border: 1px solid #bfdbfe;
        background: #eff6ff;
        border-radius: 10px;
        padding: 15px;
    }

    .voucher-code {
        color: #1d4ed8;
        font-weight: 700;
    }

    .voucher-info {
        color: #64748b;
        font-size: 0.85rem;
        margin-top: 5px;
    }

    .remove-voucher {
        color: #dc2626;
        font-size: 0.82rem;
        font-weight: 600;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 5px;
        margin-top: 10px;
    }

    .remove-voucher:hover {
        text-decoration: underline;
    }

    .summary-row {
        display: flex;
        justify-content: space-between;
        margin-bottom: 13px;
        color: #64748b;
        font-size: 0.9rem;
    }

    .summary-row strong {
        color: #0f172a;
    }

    .discount-row,
    .discount-row strong {
        color: #16a34a;
    }

    .summary-divider {
        border-top: 1px dashed #cbd5e1;
        margin: 18px 0;
    }

    .final-text {
        color: #64748b;
        font-size: 0.85rem;
    }

    .final-price {
        color: #0f172a;
        font-size: 1.65rem;
        font-weight: 800;
    }

    .checkout-btn {
        margin-top: 18px;
        width: 100%;
        height: 44px;
        background: #2563eb;
        color: white;
        border: none;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        font-weight: 600;
        text-decoration: none;
        transition: 0.2s;
    }

    .checkout-btn:hover {
        background: #1d4ed8;
        color: white;
        box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);
    }

    .empty-box {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        text-align: center;
        padding: 70px 20px;
    }

    .empty-icon {
        width: 60px;
        height: 60px;
        margin: auto;
        margin-bottom: 15px;
        border-radius: 16px;
        background: #dbeafe;
        color: #2563eb;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.6rem;
    }
</style>


<div class="cart-page">

    <div class="d-flex align-items-center justify-content-between mb-4">

        <div>
            <h1 class="page-title">
                Giỏ hàng
            </h1>

            <div class="page-description">
                Quản lý sản phẩm, số lượng và mã giảm giá trong giỏ hàng.
            </div>
        </div>

    </div>


    <c:if test="${not empty sessionScope.successMessage}">

        <div class="alert alert-success alert-dismissible fade show">

            <i class="bi bi-check-circle-fill me-2"></i>

            ${sessionScope.successMessage}

            <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert">
            </button>

        </div>

        <c:remove var="successMessage" scope="session"/>

    </c:if>


    <c:if test="${not empty sessionScope.errorMessage}">

        <div class="alert alert-danger alert-dismissible fade show">

            <i class="bi bi-exclamation-circle-fill me-2"></i>

            ${sessionScope.errorMessage}

            <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert">
            </button>

        </div>

        <c:remove var="errorMessage" scope="session"/>

    </c:if>


    <c:if test="${not empty cartItems}">

        <div class="row g-3 mb-4">


            <div class="col-lg-4">

                <div class="stat-card-cart">

                    <div class="d-flex justify-content-between align-items-start">

                        <div>

                            <div class="stat-label">
                                Sản phẩm trong giỏ
                            </div>

                            <div class="stat-value">
                                ${cartItems.size()}
                            </div>

                        </div>

                        <div class="stat-icon">
                            <i class="bi bi-cart3"></i>
                        </div>

                    </div>

                </div>

            </div>


            <div class="col-lg-4">

                <div class="stat-card-cart">

                    <div class="d-flex justify-content-between align-items-start">

                        <div>

                            <div class="stat-label">
                                Tạm tính
                            </div>

                            <div class="stat-value">

                                <fmt:formatNumber
                                    value="${total}"
                                    type="number"
                                    groupingUsed="true"
                                    maxFractionDigits="0"/>

                                đ

                            </div>

                        </div>

                        <div class="stat-icon stat-icon-green">
                            <i class="bi bi-cash-stack"></i>
                        </div>

                    </div>

                </div>

            </div>


            <div class="col-lg-4">

                <div class="stat-card-cart">

                    <div class="d-flex justify-content-between align-items-start">

                        <div>

                            <div class="stat-label">
                                Tổng thanh toán
                            </div>

                            <div class="stat-value">

                                <fmt:formatNumber
                                    value="${finalTotal}"
                                    type="number"
                                    groupingUsed="true"
                                    maxFractionDigits="0"/>

                                đ

                            </div>

                        </div>

                        <div class="stat-icon stat-icon-cyan">
                            <i class="bi bi-credit-card"></i>
                        </div>

                    </div>

                </div>

            </div>

        </div>

    </c:if>


    <c:if test="${empty cartItems}">

        <div class="empty-box">

            <div class="empty-icon">
                <i class="bi bi-cart-x"></i>
            </div>

            <h4 class="fw-bold">
                Giỏ hàng đang trống
            </h4>

            <p class="text-muted mb-0">
                Chưa có sản phẩm nào được thêm vào giỏ hàng.
            </p>

        </div>

    </c:if>


    <c:if test="${not empty cartItems}">


        <div class="content-card mb-4">


            <div class="content-card-header">

                <h5 class="content-card-title">

                    <i class="bi bi-bag me-2 text-primary"></i>

                    Danh sách sản phẩm

                </h5>


                <a
                    href="${pageContext.request.contextPath}/cart?action=clear"
                    class="btn-clear"
                    onclick="return confirm('Bạn có chắc chắn muốn xóa toàn bộ giỏ hàng?')">

                    <i class="bi bi-trash3"></i>

                    Xóa tất cả

                </a>

            </div>


            <div class="table-responsive">

                <table class="table cart-table">

                    <thead>

                        <tr>

                            <th>STT</th>

                            <th>Sản phẩm</th>

                            <th>SKU</th>

                            <th>Giá</th>

                            <th>Số lượng</th>

                            <th>Tồn kho</th>

                            <th>Thành tiền</th>

                            <th class="text-center">
                                Thao tác
                            </th>

                        </tr>

                    </thead>


                    <tbody>


                        <c:forEach
                            var="item"
                            items="${cartItems}"
                            varStatus="status">


                            <tr>


                                <td>

                                    <span class="badge bg-light text-secondary border">
                                        #${status.index + 1}
                                    </span>

                                </td>


                                <td>

                                    <div class="product-box">

                                        <div class="product-icon">
                                            <i class="bi bi-phone"></i>
                                        </div>

                                        <div>

                                            <div class="product-name">
                                                ${item.productName}
                                            </div>

                                            <small class="text-muted">
                                                Sản phẩm trong giỏ hàng
                                            </small>

                                        </div>

                                    </div>

                                </td>


                                <td>

                                    <span class="sku-text">
                                        ${item.skuCode}
                                    </span>

                                </td>


                                <td>

                                    <span class="price-text">

                                        <fmt:formatNumber
                                            value="${item.price}"
                                            type="number"
                                            groupingUsed="true"
                                            maxFractionDigits="0"/>

                                        đ

                                    </span>

                                </td>


                                <td>

                                    <c:choose>

                                        <c:when test="${item.stockQuantity > 0}">

                                            <form
                                                action="${pageContext.request.contextPath}/cart"
                                                method="post">

                                                <input
                                                    type="hidden"
                                                    name="action"
                                                    value="update">

                                                <input
                                                    type="hidden"
                                                    name="cartItemId"
                                                    value="${item.cartItemId}">

                                                <input
                                                    type="number"
                                                    name="quantity"
                                                    value="${item.quantity}"
                                                    min="1"
                                                    max="${item.stockQuantity}"
                                                    class="quantity-input"
                                                    onchange="this.form.submit()">

                                            </form>

                                        </c:when>


                                        <c:otherwise>

                                            <span class="badge bg-danger">
                                                Hết hàng
                                            </span>

                                        </c:otherwise>

                                    </c:choose>

                                </td>


                                <td>

                                    <c:choose>

                                        <c:when test="${item.stockQuantity > 0}">

                                            <span class="stock-badge">
                                                ${item.stockQuantity}
                                            </span>

                                        </c:when>

                                        <c:otherwise>

                                            <span class="badge bg-danger">
                                                0
                                            </span>

                                        </c:otherwise>

                                    </c:choose>

                                </td>


                                <td>

                                    <span class="subtotal-text">

                                        <fmt:formatNumber
                                            value="${item.subtotal}"
                                            type="number"
                                            groupingUsed="true"
                                            maxFractionDigits="0"/>

                                        đ

                                    </span>

                                </td>


                                <td class="text-center">

                                    <a
                                        href="${pageContext.request.contextPath}/cart?action=remove&cartItemId=${item.cartItemId}"
                                        class="action-btn delete-btn"
                                        title="Xóa sản phẩm"
                                        onclick="return confirm('Bạn có chắc muốn xóa sản phẩm này?')">

                                        <i class="bi bi-trash3"></i>

                                    </a>

                                </td>


                            </tr>


                        </c:forEach>


                    </tbody>

                </table>

            </div>

        </div>


        <div class="row g-4">


            <div class="col-lg-6">

                <div class="bottom-card">


                    <div class="bottom-title">

                        <i class="bi bi-ticket-perforated text-primary"></i>

                        Voucher

                    </div>


                    <c:choose>


                        <c:when test="${empty voucher}">

                            <p class="text-muted small mb-3">
                                Nhập mã giảm giá để áp dụng cho đơn hàng.
                            </p>


                            <form
                                action="${pageContext.request.contextPath}/cart"
                                method="post">


                                <input
                                    type="hidden"
                                    name="action"
                                    value="applyVoucher">


                                <div class="input-group">


                                    <input
                                        type="text"
                                        name="voucherCode"
                                        class="form-control voucher-input"
                                        placeholder="Nhập mã Voucher..."
                                        required>


                                    <button
                                        type="submit"
                                        class="btn-voucher">

                                        Áp dụng

                                    </button>


                                </div>


                            </form>

                        </c:when>


                        <c:otherwise>


                            <div class="voucher-applied">


                                <div>

                                    <i class="bi bi-check-circle-fill text-primary me-1"></i>

                                    Đang sử dụng:

                                    <span class="voucher-code">
                                        ${voucher.code}
                                    </span>

                                </div>


                                <div class="voucher-info">


                                    <c:choose>


                                        <c:when test="${voucher.discountType == 'PERCENT'}">

                                            Giảm

                                            <strong>
                                                ${voucher.discountValue}%
                                            </strong>

                                            <c:if test="${not empty voucher.maxDiscount}">

                                                , tối đa

                                                <strong>

                                                    <fmt:formatNumber
                                                        value="${voucher.maxDiscount}"
                                                        type="number"
                                                        groupingUsed="true"
                                                        maxFractionDigits="0"/>

                                                    đ

                                                </strong>

                                            </c:if>

                                        </c:when>


                                        <c:otherwise>

                                            Giảm trực tiếp

                                            <strong>

                                                <fmt:formatNumber
                                                    value="${voucher.discountValue}"
                                                    type="number"
                                                    groupingUsed="true"
                                                    maxFractionDigits="0"/>

                                                đ

                                            </strong>

                                        </c:otherwise>


                                    </c:choose>


                                </div>


                                <a
                                    href="${pageContext.request.contextPath}/cart?action=removeVoucher"
                                    class="remove-voucher">

                                    <i class="bi bi-x-circle"></i>

                                    Gỡ Voucher

                                </a>


                            </div>


                        </c:otherwise>


                    </c:choose>


                </div>

            </div>


            <div class="col-lg-6">

                <div class="bottom-card">


                    <div class="bottom-title">

                        <i class="bi bi-receipt text-primary"></i>

                        Tổng đơn hàng

                    </div>


                    <div class="summary-row">

                        <span>
                            Tạm tính
                        </span>

                        <strong>

                            <fmt:formatNumber
                                value="${total}"
                                type="number"
                                groupingUsed="true"
                                maxFractionDigits="0"/>

                            đ

                        </strong>

                    </div>


                    <c:if test="${discount > 0}">

                        <div class="summary-row discount-row">

                            <span>
                                Giảm giá
                            </span>

                            <strong>

                                -

                                <fmt:formatNumber
                                    value="${discount}"
                                    type="number"
                                    groupingUsed="true"
                                    maxFractionDigits="0"/>

                                đ

                            </strong>

                        </div>

                    </c:if>


                    <div class="summary-divider"></div>


                    <div class="d-flex justify-content-between align-items-end">

                        <div class="final-text">
                            Tổng thanh toán
                        </div>


                        <div class="final-price">

                            <fmt:formatNumber
                                value="${finalTotal}"
                                type="number"
                                groupingUsed="true"
                                maxFractionDigits="0"/>

                            đ

                        </div>

                    </div>


                    <a
                        href="${pageContext.request.contextPath}/checkout"
                        class="checkout-btn">

                        <i class="bi bi-credit-card"></i>

                        Tiến hành thanh toán

                    </a>


                </div>

            </div>


        </div>


    </c:if>


</div>

<%@include file="/WEB-INF/include/footer.jsp" %>