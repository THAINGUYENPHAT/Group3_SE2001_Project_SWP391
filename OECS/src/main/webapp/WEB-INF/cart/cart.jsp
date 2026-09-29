<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Giỏ hàng</title>

    <!-- Bootstrap -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
          rel="stylesheet">

    <style>
        body {
            background-color: #f5f5f5;
        }

        .cart-container {
            background: white;
            padding: 30px;
            margin-top: 40px;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
        }

        .cart-title {
            font-weight: bold;
            margin-bottom: 25px;
        }

        .quantity-input {
            width: 80px;
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

    <div class="cart-container">

        <h2 class="cart-title">
            Giỏ hàng của bạn
        </h2>


        <!-- ========================= -->
        <!-- THÔNG BÁO THÀNH CÔNG -->
        <!-- ========================= -->

        <c:if test="${not empty sessionScope.successMessage}">

            <div class="alert alert-success alert-dismissible fade show">

                ${sessionScope.successMessage}

                <button type="button"
                        class="btn-close"
                        data-bs-dismiss="alert">
                </button>

            </div>

            <c:remove var="successMessage"
                      scope="session"/>

        </c:if>


        <!-- ========================= -->
        <!-- THÔNG BÁO LỖI -->
        <!-- ========================= -->

        <c:if test="${not empty sessionScope.errorMessage}">

            <div class="alert alert-danger alert-dismissible fade show">

                ${sessionScope.errorMessage}

                <button type="button"
                        class="btn-close"
                        data-bs-dismiss="alert">
                </button>

            </div>

            <c:remove var="errorMessage"
                      scope="session"/>

        </c:if>


        <!-- ========================= -->
        <!-- GIỎ HÀNG TRỐNG -->
        <!-- ========================= -->

        <c:if test="${empty cartItems}">

            <div class="alert alert-info">

                Giỏ hàng của bạn hiện đang trống.

            </div>

            <a href="${pageContext.request.contextPath}/product"
               class="btn btn-primary">

                Tiếp tục mua hàng

            </a>

        </c:if>


        <!-- ========================= -->
        <!-- GIỎ HÀNG CÓ SẢN PHẨM -->
        <!-- ========================= -->

        <c:if test="${not empty cartItems}">

            <div class="table-responsive">

                <table class="table table-bordered table-hover align-middle">

                    <thead class="table-dark">

                    <tr>

                        <th>#</th>

                        <th>Sản phẩm</th>

                        <th>SKU</th>

                        <th>Đơn giá</th>

                        <th>Số lượng</th>

                        <th>Tồn kho</th>

                        <th>Thành tiền</th>

                        <th>Thao tác</th>

                    </tr>

                    </thead>


                    <tbody>

                    <c:forEach var="item"
                               items="${cartItems}"
                               varStatus="status">

                        <tr>

                            <!-- STT -->

                            <td>
                                ${status.index + 1}
                            </td>


                            <!-- PRODUCT NAME -->

                            <td>

                                <strong>
                                    ${item.productName}
                                </strong>

                            </td>


                            <!-- SKU -->

                            <td>

                                ${item.skuCode}

                            </td>


                            <!-- PRICE -->

                            <td>

                                <fmt:formatNumber
                                    value="${item.price}"
                                    type="number"
                                    groupingUsed="true"/>

                                đ

                            </td>


                            <!-- QUANTITY -->

                            <td>

                                <form action="${pageContext.request.contextPath}/cart"
                                      method="post"
                                      class="d-flex align-items-center gap-2">

                                    <input type="hidden"
                                           name="action"
                                           value="update">

                                    <input type="hidden"
                                           name="cartItemId"
                                           value="${item.cartItemId}">


                                    <input type="number"
                                           name="quantity"
                                           value="${item.quantity}"
                                           min="1"
                                           max="${item.stockQuantity}"
                                           class="form-control quantity-input"
                                           required>


                                    <button type="submit"
                                            class="btn btn-warning btn-sm">

                                        Cập nhật

                                    </button>

                                </form>

                            </td>


                            <!-- STOCK -->

                            <td>

                                ${item.stockQuantity}

                            </td>


                            <!-- SUBTOTAL -->

                            <td>

                                <strong>

                                    <fmt:formatNumber
                                        value="${item.subtotal}"
                                        type="number"
                                        groupingUsed="true"/>

                                    đ

                                </strong>

                            </td>


                            <!-- ACTION -->

                            <td>

                                <a href="${pageContext.request.contextPath}/cart?action=remove&cartItemId=${item.cartItemId}"
                                   class="btn btn-danger btn-sm"
                                   onclick="return confirm('Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng?')">

                                    Xóa

                                </a>

                            </td>

                        </tr>

                    </c:forEach>

                    </tbody>

                </table>

            </div>


            <!-- ========================= -->
            <!-- BOTTOM -->
            <!-- ========================= -->

            <div class="row mt-4">

                <!-- LEFT -->

                <div class="col-md-6 mb-3">

                    <a href="${pageContext.request.contextPath}/product"
                       class="btn btn-secondary">

                        ← Tiếp tục mua hàng

                    </a>


                    <a href="${pageContext.request.contextPath}/cart?action=clear"
                       class="btn btn-outline-danger"
                       onclick="return confirm('Bạn có chắc muốn xóa toàn bộ giỏ hàng?')">

                        Xóa toàn bộ

                    </a>

                </div>


                <!-- RIGHT -->

                <div class="col-md-6">

                    <div class="total-box text-end">

                        <p class="mb-1">
                            Tổng thanh toán
                        </p>

                        <div class="total-price">

                            <fmt:formatNumber
                                value="${total}"
                                type="number"
                                groupingUsed="true"/>

                            đ

                        </div>


                        <a href="${pageContext.request.contextPath}/checkout"
                           class="btn btn-success btn-lg mt-3">

                            Thanh toán

                        </a>

                    </div>

                </div>

            </div>

        </c:if>

    </div>

</div>


<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js">
</script>

</body>
</html>