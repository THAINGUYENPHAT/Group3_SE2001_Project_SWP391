<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>

    :root {
        --page-bg: #f7f9fc;
        --border-color: #dde5ef;
        --text-main: #111827;
        --text-muted: #64748b;

        --primary: #0d6efd;
        --primary-hover: #0b5ed7;

        --success: #009b6b;

        --danger: #ff4d5a;
    }


    body {
        background: var(--page-bg);
    }


    .cart-page {
        padding: 4px 0 125px;
    }


    .page-heading {
        display: flex;
        align-items: center;
        justify-content: space-between;

        gap: 20px;

        margin-bottom: 30px;
    }


    .page-heading h1 {
        margin: 0 0 4px;

        color: var(--text-main);

        font-size: 34px;
        font-weight: 800;
    }


    .page-heading p {
        margin: 0;

        color: #4b5563;

        font-size: 17px;
    }


    .continue-btn {
        display: inline-flex;
        align-items: center;

        padding: 13px 20px;

        border: none;
        border-radius: 10px;

        background: var(--primary);
        color: #ffffff;

        text-decoration: none;

        font-size: 16px;
        font-weight: 700;

        box-shadow:
            0 4px 10px rgba(13, 110, 253, .18);
    }


    .continue-btn:hover {
        background: var(--primary-hover);
        color: #ffffff;
    }

    .stat-card {
        position: relative;

        min-height: 145px;

        padding: 26px 28px;

        border: 1px solid var(--border-color);
        border-radius: 18px;

        background: #ffffff;
    }


    .stat-title {
        margin-bottom: 17px;

        color: #475569;

        font-size: 17px;
    }


    .stat-value {
        display: flex;
        align-items: baseline;

        gap: 14px;
    }


    .stat-value strong {
        color: #111827;

        font-size: 34px;
        font-weight: 800;

        line-height: 1;
    }


    .stat-value span {
        color: #008d63;

        font-size: 15px;
    }


    .stat-icon {
        position: absolute;

        top: 27px;
        right: 26px;

        width: 34px;
        height: 34px;

        display: flex;
        align-items: center;
        justify-content: center;

        border-radius: 50%;
    }


    .stat-icon.blue {
        color: #0d6efd;
        background: #dceaff;
    }


    .stat-icon.green {
        color: #07875f;
        background: #daf1e8;
    }


    .stat-icon.cyan {
        color: #00a7cc;
        background: #daf6fc;
    }


    .content-card {
        margin-top: 30px;

        overflow: hidden;

        border: 1px solid var(--border-color);
        border-radius: 18px;

        background: #ffffff;
    }


    .content-toolbar {
        display: flex;
        align-items: center;
        justify-content: space-between;

        gap: 20px;

        padding: 22px 24px;

        border-bottom:
            1px solid var(--border-color);
    }


    .content-toolbar h5 {
        margin: 0;

        color: #111827;

        font-size: 20px;
        font-weight: 750;
    }


    .clear-cart-btn {
        padding: 9px 14px;

        border: 1px solid #ffb9c0;
        border-radius: 8px;

        background: #ffffff;
        color: var(--danger);

        font-weight: 600;
    }


    .clear-cart-btn:hover {
        background: #fff2f3;
        color: #dc3545;
    }


    .cart-table {
        margin-bottom: 0;
    }


    .cart-table thead th {
        padding: 18px;

        vertical-align: middle;

        border-bottom:
            1px solid var(--border-color);

        background: #f7f9fc;
        color: #5e708d;

        font-size: 13px;
        font-weight: 750;

        letter-spacing: .45px;

        text-transform: uppercase;

        white-space: nowrap;
    }


    .cart-table tbody td {
        padding: 20px 18px;

        vertical-align: middle;

        border-color: #edf1f5;

        color: #334155;
    }


    .cart-table tbody tr:hover {
        background: #fbfcfe;
    }

    .cart-check {
        width: 19px;
        height: 19px;

        cursor: pointer;
    }


    .product-name {
        color: #111827;

        font-weight: 750;
    }


    .sku-text {
        color: #ec4899;

        font-family: monospace;
        font-size: 14px;
    }


    .quantity-wrapper {
        display: inline-flex;
        align-items: center;

        margin: 0;
    }


    .quantity-input {
        width: 90px;
        height: 42px;

        border-radius: 8px;

        text-align: center;

        font-weight: 600;
    }


    .quantity-input:focus {
        border-color: #86b7fe;

        box-shadow:
            0 0 0 .2rem rgba(13, 110, 253, .12);
    }


    .stock-badge {
        display: inline-block;

        padding: 6px 10px;

        border: 1px solid #aadccb;
        border-radius: 7px;

        background: #def3ea;
        color: #07875f;

        font-weight: 700;
    }


    .subtotal-text {
        color: var(--primary);

        font-size: 17px;
        font-weight: 800;
    }

    .delete-btn {
        width: 39px;
        height: 39px;

        display: inline-flex;
        align-items: center;
        justify-content: center;

        border: 1px solid #dbe2ea;
        border-radius: 8px;

        background: #ffffff;
        color: #ff4655;
    }


    .delete-btn:hover {
        border-color: #ffb7bd;

        background: #fff1f2;
    }


    .empty-cart {
        padding: 60px 20px;

        text-align: center;

        color: #64748b;
    }


    .cart-fixed-bar {
        position: fixed;

        left: 0;
        right: 0;
        bottom: 0;

        z-index: 1050;

        border-top: 1px solid #dde5ef;

        background: #ffffff;

        box-shadow:
            0 -5px 20px rgba(15, 23, 42, .10);
    }


    .cart-fixed-inner {
        max-width: 1440px;

        min-height: 82px;

        margin: 0 auto;

        padding: 14px 28px;

        display: flex;
        align-items: center;
        justify-content: space-between;

        gap: 25px;
    }


    .cart-fixed-left {
        display: flex;
        align-items: center;

        gap: 22px;
    }


    .cart-fixed-check {
        display: flex;
        align-items: center;

        gap: 10px;

        margin: 0;

        color: #111827;

        font-size: 16px;
        font-weight: 600;

        cursor: pointer;
    }


    .cart-fixed-check input {
        width: 20px;
        height: 20px;

        cursor: pointer;
    }


    .cart-fixed-action {
        padding: 5px 7px;

        border: none;

        background: transparent;
        color: #475569;

        font-size: 15px;
        font-weight: 600;
    }


    .cart-fixed-action:hover {
        color: #dc3545;
    }


    .cart-fixed-right {
        display: flex;
        align-items: center;

        gap: 25px;
    }


    .cart-fixed-summary {
        display: flex;
        align-items: baseline;

        gap: 8px;

        white-space: nowrap;
    }


    .cart-fixed-summary-label {
        color: #334155;

        font-size: 16px;
    }


    .cart-fixed-summary-price {
        color: #dc3545;

        font-size: 29px;
        font-weight: 850;
    }


    .cart-fixed-buy {
        min-width: 230px;
        height: 52px;

        padding: 0 25px;

        border: none;
        border-radius: 8px;

        background: #0d6efd;
        color: #ffffff;

        font-size: 17px;
        font-weight: 700;

        transition:
            background .18s,
            transform .18s;
    }


    .cart-fixed-buy:hover {
        background: #0b5ed7;
    }


    .cart-fixed-buy:active {
        transform: scale(.98);
    }


    .cart-fixed-buy:disabled {
        background: #94a3b8;

        cursor: not-allowed;

        transform: none;
    }


    @media (max-width: 992px) {

        .cart-table {
            min-width: 1000px;
        }


        .cart-fixed-inner {
            flex-wrap: wrap;

            padding: 12px 16px;
        }


        .cart-fixed-left,
        .cart-fixed-right {
            width: 100%;

            justify-content: space-between;
        }


        .cart-fixed-buy {
            min-width: 170px;
        }
    }


    @media (max-width: 768px) {

        .cart-page {
            padding-bottom: 160px;
        }


        .page-heading {
            flex-direction: column;

            align-items: flex-start;
        }


        .page-heading h1 {
            font-size: 27px;
        }


        .content-toolbar {
            flex-direction: column;

            align-items: flex-start;
        }


        .cart-fixed-left {
            gap: 12px;
        }


        .cart-fixed-right {
            gap: 12px;
        }


        .cart-fixed-summary {
            flex-direction: column;
            align-items: flex-start;

            gap: 2px;
        }


        .cart-fixed-summary-label {
            font-size: 13px;
        }


        .cart-fixed-summary-price {
            font-size: 21px;
        }


        .cart-fixed-buy {
            min-width: 135px;
            height: 47px;

            padding: 0 15px;

            font-size: 15px;
        }
    }

</style>


<div class="cart-page">


    <div class="page-heading">

        <div>

            <h1>
                Giỏ Hàng
            </h1>

            <p>
                Xem và quản lý các sản phẩm bạn muốn đặt hàng.
            </p>

        </div>


        <a
            href="${pageContext.request.contextPath}/home"
            class="continue-btn">

            <i class="bi bi-plus-lg me-1"></i>

            Tiếp tục mua sắm

        </a>

    </div>


    <c:if test="${not empty sessionScope.successMessage}">

        <div
            class="alert alert-success alert-dismissible fade show">

            ${sessionScope.successMessage}


            <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert">
            </button>

        </div>


        <c:remove
            var="successMessage"
            scope="session"/>

    </c:if>


    <c:if test="${not empty sessionScope.errorMessage}">

        <div
            class="alert alert-danger alert-dismissible fade show">

            ${sessionScope.errorMessage}


            <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert">
            </button>

        </div>


        <c:remove
            var="errorMessage"
            scope="session"/>

    </c:if>



    <c:if test="${not empty cartItems}">


        <div class="row g-4">


            <div class="col-lg-4">

                <div class="stat-card">

                    <div class="stat-title">
                        Tổng sản phẩm
                    </div>


                    <div class="stat-icon blue">

                        <i class="bi bi-bag"></i>

                    </div>


                    <div class="stat-value">

                        <strong>
                            ${cartItems.size()}
                        </strong>

                        <span>
                            Sản phẩm
                        </span>

                    </div>

                </div>

            </div>



            <div class="col-lg-4">

                <div class="stat-card">

                    <div class="stat-title">
                        Sản phẩm đã chọn
                    </div>


                    <div class="stat-icon green">

                        <i class="bi bi-check2-square"></i>

                    </div>


                    <div class="stat-value">

                        <strong id="topSelectedCount">
                            0
                        </strong>

                        <span>
                            Đang chọn
                        </span>

                    </div>

                </div>

            </div>


            <div class="col-lg-4">

                <div class="stat-card">

                    <div class="stat-title">
                        Tổng giá trị giỏ hàng
                    </div>


                    <div class="stat-icon cyan">

                        <i class="bi bi-wallet2"></i>

                    </div>


                    <div class="stat-value">

                        <strong style="font-size:26px;">

                            <fmt:formatNumber
                                value="${total}"
                                type="number"
                                groupingUsed="true"
                                maxFractionDigits="0"/>

                            đ

                        </strong>

                    </div>

                </div>

            </div>

        </div>


        <div class="content-card">


            <div class="content-toolbar">

                <h5>

                    <i class="bi bi-cart3 me-2"></i>

                    Danh sách sản phẩm

                </h5>


                <form
                    action="${pageContext.request.contextPath}/cart"
                    method="post"
                    onsubmit="return confirm('Bạn có chắc muốn xóa toàn bộ giỏ hàng?')">


                    <input
                        type="hidden"
                        name="action"
                        value="clear">


                    <button
                        type="submit"
                        class="clear-cart-btn">

                        <i class="bi bi-trash me-1"></i>

                        Xóa toàn bộ

                    </button>

                </form>

            </div>

            <div class="table-responsive">

                <table class="table cart-table">


                    <thead>

                        <tr>

                            <th style="width:55px;">

                                <input
                                    type="checkbox"
                                    id="selectAll"
                                    class="
                                        form-check-input
                                        cart-check
                                    ">

                            </th>


                            <th>
                                #
                            </th>


                            <th>
                                Sản phẩm
                            </th>


                            <th>
                                SKU
                            </th>


                            <th>
                                Giá
                            </th>


                            <th>
                                Số lượng
                            </th>


                            <th>
                                Tồn kho
                            </th>


                            <th>
                                Thành tiền
                            </th>


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

                                    <input
                                        type="checkbox"
                                        class="
                                            form-check-input
                                            cart-check
                                            cart-checkbox
                                        "
                                        name="selectedItems"
                                        value="${item.cartItemId}"
                                        data-subtotal="${item.subtotal}"
                                        ${selectedItemIds.contains(item.cartItemId) ? 'checked' : ''}
                                        ${item.stockQuantity <= 0 ? 'disabled' : ''}>

                                </td>

                                <td>

                                    <span
                                        class="
                                            badge
                                            bg-light
                                            text-secondary
                                            border
                                        ">

                                        #${status.index + 1}

                                    </span>

                                </td>


                                <td>

                                    <div class="product-name">

                                        ${item.productName}

                                    </div>

                                </td>


                                <td>

                                    <span class="sku-text">

                                        ${item.skuCode}

                                    </span>

                                </td>


                                <td>

                                    <fmt:formatNumber
                                        value="${item.price}"
                                        type="number"
                                        groupingUsed="true"
                                        maxFractionDigits="0"/>

                                    đ

                                </td>


                               
                                <td>


                                    <c:choose>


                                        <c:when test="${item.stockQuantity > 0}">

                                            <form
                                                action="${pageContext.request.contextPath}/cart"
                                                method="post"
                                                class="
                                                    quantity-wrapper
                                                    quantity-form
                                                ">


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
                                                    data-old-value="${item.quantity}"
                                                    class="
                                                        form-control
                                                        quantity-input
                                                        auto-quantity
                                                    ">

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


                                    <form
                                        action="${pageContext.request.contextPath}/cart"
                                        method="post"
                                        onsubmit="return confirm('Bạn có chắc muốn xóa sản phẩm này?')">


                                        <input
                                            type="hidden"
                                            name="action"
                                            value="remove">


                                        <input
                                            type="hidden"
                                            name="cartItemId"
                                            value="${item.cartItemId}">


                                        <button
                                            type="submit"
                                            class="delete-btn"
                                            title="Xóa">

                                            <i class="bi bi-trash"></i>

                                        </button>


                                    </form>

                                </td>


                            </tr>


                        </c:forEach>


                    </tbody>

                </table>

            </div>

        </div>


       

        <div class="cart-fixed-bar">

            <div class="cart-fixed-inner">



                <div class="cart-fixed-left">


                    <label class="cart-fixed-check">


                        <input
                            type="checkbox"
                            id="bottomSelectAll"
                            class="form-check-input">


                        <span>

                            Chọn Tất Cả

                            (<span id="bottomSelectedCount">0</span>)

                        </span>


                    </label>


                    <button
                        type="button"
                        class="cart-fixed-action"
                        id="bottomDeleteSelected">

                        Xóa

                    </button>


                </div>



                <div class="cart-fixed-right">


                    <div class="cart-fixed-summary">


                        <span class="cart-fixed-summary-label">

                            Tổng cộng

                            (<span id="bottomProductCount">0</span> sản phẩm):

                        </span>


                        <span
                            class="cart-fixed-summary-price"
                            id="bottomTotalPrice">

                            0 đ

                        </span>


                    </div>



                    <form
                        id="bottomCheckoutForm"
                        action="${pageContext.request.contextPath}/checkout"
                        method="get">


                        <button
                            type="submit"
                            class="cart-fixed-buy"
                            id="bottomCheckoutBtn">

                            Mua Hàng

                        </button>


                    </form>


                </div>

            </div>

        </div>


    </c:if>


   

    <c:if test="${empty cartItems}">

        <div class="content-card">

            <div class="empty-cart">


                <i
                    class="bi bi-cart-x"
                    style="font-size:52px;">
                </i>


                <h4 class="mt-3">

                    Giỏ hàng đang trống

                </h4>


                <p>

                    Hãy thêm sản phẩm để bắt đầu mua sắm.

                </p>


                <a
                    href="${pageContext.request.contextPath}/home"
                    class="btn btn-primary">

                    Tiếp tục mua sắm

                </a>


            </div>

        </div>

    </c:if>


</div>




<script>

document.addEventListener(
    "DOMContentLoaded",
    function () {



        const selectAll =
            document.getElementById(
                "selectAll"
            );


        const bottomSelectAll =
            document.getElementById(
                "bottomSelectAll"
            );


        const checkboxes =
            document.querySelectorAll(
                ".cart-checkbox:not(:disabled)"
            );


        const topSelectedCount =
            document.getElementById(
                "topSelectedCount"
            );


        const bottomSelectedCount =
            document.getElementById(
                "bottomSelectedCount"
            );


        const bottomProductCount =
            document.getElementById(
                "bottomProductCount"
            );


        const bottomTotalPrice =
            document.getElementById(
                "bottomTotalPrice"
            );


        const bottomCheckoutForm =
            document.getElementById(
                "bottomCheckoutForm"
            );


        const bottomCheckoutBtn =
            document.getElementById(
                "bottomCheckoutBtn"
            );


        const bottomDeleteSelected =
            document.getElementById(
                "bottomDeleteSelected"
            );


        const quantityInputs =
            document.querySelectorAll(
                ".auto-quantity"
            );


        

        function money(value) {

            return new Intl.NumberFormat(
                "vi-VN"
            ).format(
                Math.round(value)
            ) + " đ";
        }



        function getSelectedCount() {

            let count = 0;


            checkboxes.forEach(
                function (checkbox) {

                    if (checkbox.checked) {

                        count++;
                    }
                }
            );


            return count;
        }


       

        function getSelectedTotal() {

            let total = 0;


            checkboxes.forEach(
                function (checkbox) {

                    if (checkbox.checked) {

                        total += Number(
                            checkbox.dataset.subtotal
                            || 0
                        );
                    }
                }
            );


            return total;
        }



        function updateSummary() {


            const count =
                getSelectedCount();


            const total =
                getSelectedTotal();


            
            if (topSelectedCount) {

                topSelectedCount.textContent =
                    count;
            }


            if (bottomSelectedCount) {

                bottomSelectedCount.textContent =
                    count;
            }


            if (bottomProductCount) {

                bottomProductCount.textContent =
                    count;
            }


           
            if (bottomTotalPrice) {

                bottomTotalPrice.textContent =
                    money(total);
            }


           
            if (bottomCheckoutBtn) {

                bottomCheckoutBtn.disabled =
                    count === 0;
            }


          
            if (selectAll) {


                selectAll.checked =
                    checkboxes.length > 0
                    && count === checkboxes.length;


                selectAll.indeterminate =
                    count > 0
                    && count < checkboxes.length;
            }


          
            if (bottomSelectAll) {


                bottomSelectAll.checked =
                    checkboxes.length > 0
                    && count === checkboxes.length;


                bottomSelectAll.indeterminate =
                    count > 0
                    && count < checkboxes.length;
            }
        }



        if (selectAll) {


            selectAll.addEventListener(
                "change",
                function () {


                    checkboxes.forEach(
                        function (checkbox) {

                            checkbox.checked =
                                selectAll.checked;
                        }
                    );


                    updateSummary();
                }
            );
        }



        if (bottomSelectAll) {


            bottomSelectAll.addEventListener(
                "change",
                function () {


                    checkboxes.forEach(
                        function (checkbox) {

                            checkbox.checked =
                                bottomSelectAll.checked;
                        }
                    );


                    updateSummary();
                }
            );
        }


        checkboxes.forEach(
            function (checkbox) {


                checkbox.addEventListener(
                    "change",
                    function () {

                        updateSummary();
                    }
                );
            }
        );



        quantityInputs.forEach(
            function (input) {


                let timer = null;


                input.addEventListener(
                    "input",
                    function () {


                        clearTimeout(timer);


                        const value =
                            Number(
                                input.value
                            );


                        const min =
                            Number(
                                input.min
                                || 1
                            );


                        const max =
                            Number(
                                input.max
                                || 0
                            );


                        const oldValue =
                            Number(
                                input.dataset.oldValue
                                || 0
                            );


                      
                        if (!Number.isInteger(value)
                                || value < min
                                || value > max) {

                            return;
                        }


                        if (value === oldValue) {

                            return;
                        }


                     
                        timer =
                            setTimeout(
                                function () {

                                    if (input.form) {

                                        input.form.submit();
                                    }

                                },
                                500
                            );

                    }
                );


                input.addEventListener(
                    "blur",
                    function () {


                        let value =
                            Number(
                                input.value
                            );


                        const min =
                            Number(
                                input.min
                                || 1
                            );


                        const max =
                            Number(
                                input.max
                                || 1
                            );


                        if (!Number.isFinite(value)
                                || value < min) {

                            input.value =
                                min;

                        } else if (value > max) {

                            input.value =
                                max;
                        }
                    }
                );
            }
        );


        function attachSelectedItems(
                form) {


            form.querySelectorAll(
                ".dynamic-selected-item"
            ).forEach(
                function (input) {

                    input.remove();
                }
            );


            const selected =
                document.querySelectorAll(
                    ".cart-checkbox:checked:not(:disabled)"
                );


            
            selected.forEach(
                function (checkbox) {


                    const input =
                        document.createElement(
                            "input"
                        );


                    input.type =
                        "hidden";


                    input.name =
                        "selectedItems";


                    input.value =
                        checkbox.value;


                    input.className =
                        "dynamic-selected-item";


                    form.appendChild(
                        input
                    );
                }
            );


            return selected.length;
        }


       

        if (bottomCheckoutForm) {


            bottomCheckoutForm.addEventListener(
                "submit",
                function (event) {


                    const selectedLength =
                        attachSelectedItems(
                            bottomCheckoutForm
                        );


                    if (selectedLength === 0) {


                        event.preventDefault();


                        alert(
                            "Vui lòng chọn ít nhất một sản phẩm để đặt hàng."
                        );
                    }
                }
            );
        }


        

        if (bottomDeleteSelected) {


            bottomDeleteSelected.addEventListener(
                "click",
                function () {


                    const selected =
                        document.querySelectorAll(
                            ".cart-checkbox:checked:not(:disabled)"
                        );


                 
                    if (selected.length === 0) {


                        alert(
                            "Vui lòng chọn sản phẩm cần xóa."
                        );


                        return;
                    }


                    if (!confirm(
                            "Bạn có chắc muốn xóa "
                            + selected.length
                            + " sản phẩm đã chọn?"
                    )) {


                        return;
                    }


                    
                    const form =
                        document.createElement(
                            "form"
                        );


                    form.method =
                        "post";


                    form.action =
                        "${pageContext.request.contextPath}/cart";


                    
                    const actionInput =
                        document.createElement(
                            "input"
                        );


                    actionInput.type =
                        "hidden";


                    actionInput.name =
                        "action";


                    actionInput.value =
                        "removeSelected";


                    form.appendChild(
                        actionInput
                    );


                  
                    selected.forEach(
                        function (checkbox) {


                            const input =
                                document.createElement(
                                    "input"
                                );


                            input.type =
                                "hidden";


                            input.name =
                                "selectedItems";


                            input.value =
                                checkbox.value;


                            form.appendChild(
                                input
                            );
                        }
                    );


                    document.body.appendChild(
                        form
                    );


                    form.submit();

                }
            );
        }



        updateSummary();

    }
);

</script>


<%@include file="/WEB-INF/include/footer.jsp" %>