<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<!DOCTYPE html>
<html>

    <head>

        <meta charset="UTF-8">

        <title>Giỏ hàng</title>

        <link
            href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
            rel="stylesheet">

        <style>

            body {
                background-color: #f5f6f8;
            }

            .cart-box {
                background: white;
                padding: 25px;
                margin-top: 40px;
                margin-bottom: 40px;
                border-radius: 12px;
            }

            .quantity-input {
                width: 85px;
            }

            .total-box {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 10px;
            }

            .total-price {
                font-size: 26px;
                font-weight: bold;
                color: #dc3545;
            }

        </style>

    </head>


    <body>


        <div class="container">


            <div class="cart-box">


                <h2 class="mb-4">
                    Giỏ hàng
                </h2>


                <!-- SUCCESS -->

                <c:if test="${not empty sessionScope.successMessage}">

                    <div class="alert alert-success">

                        ${sessionScope.successMessage}

                    </div>

                    <c:remove
                        var="successMessage"
                        scope="session"/>

                </c:if>


                <!-- ERROR -->

                <c:if test="${not empty sessionScope.errorMessage}">

                    <div class="alert alert-danger">

                        ${sessionScope.errorMessage}

                    </div>

                    <c:remove
                        var="errorMessage"
                        scope="session"/>

                </c:if>


                <!-- EMPTY -->

                <c:if test="${empty cartItems}">

                    <div class="alert alert-info">

                        Giỏ hàng đang trống.

                    </div>

                </c:if>


                <!-- CART ITEMS -->

                <c:if test="${not empty cartItems}">


                    <div class="table-responsive">


                        <table class="table table-bordered align-middle">


                            <thead class="table-dark">

                                <tr>

                                    <th>#</th>

                                    <th>Sản phẩm</th>

                                    <th>SKU</th>

                                    <th>Giá</th>

                                    <th>Số lượng</th>

                                    <th>Tồn kho</th>

                                    <th>Thành tiền</th>

                                    <th>Thao tác</th>

                                </tr>

                            </thead>


                            <tbody>


                                <c:forEach
                                    var="item"
                                    items="${cartItems}"
                                    varStatus="status">


                                    <tr>


                                        <td>
                                            ${status.index + 1}
                                        </td>


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


                                            <form
                                                action="${pageContext.request.contextPath}/cart"
                                                method="post"
                                                class="d-flex gap-2">


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
                                                    class="form-control quantity-input">


                                                <button
                                                    type="submit"
                                                    class="btn btn-warning btn-sm">

                                                    Update

                                                </button>


                                            </form>


                                        </td>


                                        <td>

                                            ${item.stockQuantity}

                                        </td>


                                        <td>

                                            <fmt:formatNumber
                                                value="${item.subtotal}"
                                                type="number"
                                                groupingUsed="true"/>

                                            đ

                                        </td>


                                        <td>

                                            <a
                                                href="${pageContext.request.contextPath}/cart?action=remove&cartItemId=${item.cartItemId}"
                                                class="btn btn-danger btn-sm"
                                                onclick="return confirm('Xóa sản phẩm này?')">

                                                Xóa

                                            </a>

                                        </td>


                                    </tr>


                                </c:forEach>


                            </tbody>


                        </table>


                    </div>


                    <!-- CLEAR -->

                    <div class="mb-4">

                        <a
                            href="${pageContext.request.contextPath}/cart?action=clear"
                            class="btn btn-outline-danger"
                            onclick="return confirm('Xóa toàn bộ giỏ hàng?')">

                            Xóa toàn bộ

                        </a>

                    </div>


                    <div class="row">


                        <!-- VOUCHER -->

                        <div class="col-md-6">


                            <div class="card">


                                <div class="card-body">


                                    <h5>
                                        Mã giảm giá
                                    </h5>


                                    <c:choose>


                                        <c:when test="${empty voucher}">


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


                                        </c:when>


                                        <c:otherwise>


                                            <div class="alert alert-success mb-0">


                                                <strong>
                                                    ${voucher.code}
                                                </strong>


                                                <br>


                                                <c:choose>


                                                    <c:when test="${voucher.discountType == 'PERCENT'}">

                                                        Giảm:

                                                        ${voucher.discountValue}%


                                                        <c:if test="${not empty voucher.maxDiscount}">

                                                            <br>

                                                            Tối đa:

                                                            <fmt:formatNumber
                                                                value="${voucher.maxDiscount}"
                                                                type="number"/>

                                                            đ

                                                        </c:if>


                                                    </c:when>


                                                    <c:otherwise>

                                                        Giảm:

                                                        <fmt:formatNumber
                                                            value="${voucher.discountValue}"
                                                            type="number"/>

                                                        đ

                                                    </c:otherwise>


                                                </c:choose>


                                                <br>


                                                <a
                                                    href="${pageContext.request.contextPath}/cart?action=removeVoucher"
                                                    class="btn btn-sm btn-outline-danger mt-2">

                                                    Bỏ Voucher

                                                </a>


                                            </div>


                                        </c:otherwise>


                                    </c:choose>


                                </div>


                            </div>


                        </div>


                        <!-- TOTAL -->

                        <div class="col-md-6">


                            <div class="total-box text-end">


                                <p>

                                    Tạm tính:

                                    <strong>

                                        <fmt:formatNumber
                                            value="${total}"
                                            type="number"
                                            groupingUsed="true"/>

                                        đ

                                    </strong>

                                </p>


                                <c:if test="${discount > 0}">


                                    <p class="text-success">

                                        Giảm giá:

                                        <strong>

                                            -

                                            <fmt:formatNumber
                                                value="${discount}"
                                                type="number"
                                                groupingUsed="true"/>

                                            đ

                                        </strong>

                                    </p>


                                </c:if>


                                <hr>


                                <div>

                                    Tổng thanh toán

                                </div>


                                <div class="total-price">

                                    <fmt:formatNumber
                                        value="${finalTotal}"
                                        type="number"
                                        groupingUsed="true"/>

                                    đ

                                </div>


                                <a
                                    href="${pageContext.request.contextPath}/checkout"
                                    class="btn btn-success btn-lg mt-3">

                                    Thanh toán

                                </a>


                            </div>


                        </div>


                    </div>


                </c:if>


            </div>


        </div>


        <script
            src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js">
        </script>


    </body>

</html>