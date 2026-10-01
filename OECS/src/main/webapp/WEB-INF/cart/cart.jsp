<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Giỏ hàng</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f5f6f8; }
        .cart-box { background: white; padding: 25px; margin-top: 40px; margin-bottom: 40px; border-radius: 12px; }
        .quantity-input { width: 80px; }
        .total-box { background: #f8f9fa; padding: 20px; border-radius: 10px; }
        .total-price { font-size: 26px; font-weight: bold; color: #dc3545; }
    </style>
</head>
<body>

    <div class="container">
        <div class="cart-box shadow-sm">
            <h2 class="mb-4">Giỏ hàng</h2>

            <!-- SUCCESS ALERT -->
            <c:if test="${not empty sessionScope.successMessage}">
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    ${sessionScope.successMessage}
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
                <c:remove var="successMessage" scope="session"/>
            </c:if>

            <!-- ERROR ALERT -->
            <c:if test="${not empty sessionScope.errorMessage}">
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    ${sessionScope.errorMessage}
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
                <c:remove var="errorMessage" scope="session"/>
            </c:if>

            <!-- EMPTY CART -->
            <c:if test="${empty cartItems}">
                <div class="alert alert-info text-center py-4">
                    <p class="mb-3">Giỏ hàng của bạn đang trống.</p>

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
                            <c:forEach var="item" items="${cartItems}" varStatus="status">
                                <tr>
                                    <td>${status.index + 1}</td>
                                    <td class="fw-bold">${item.productName}</td>
                                    <td><code>${item.skuCode}</code></td>
                                    <td>
                                        <fmt:formatNumber value="${item.price}" type="number" groupingUsed="true" maxFractionDigits="0"/> đ
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${item.stockQuantity > 0}">
                                                <form action="${pageContext.request.contextPath}/cart" method="post" class="d-flex gap-2 align-items-center">
                                                    <input type="hidden" name="action" value="update">
                                                    <input type="hidden" name="cartItemId" value="${item.cartItemId}">
                                                    <input type="number" name="quantity" value="${item.quantity}" 
                                                           min="1" max="${item.stockQuantity}" 
                                                           class="form-control quantity-input form-control-sm"
                                                           onchange="this.form.submit()">
                                                    <button type="submit" class="btn btn-warning btn-sm">Cập nhật</button>
                                                </form>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge bg-danger">Hết hàng</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td>${item.stockQuantity}</td>
                                    <td class="fw-bold text-primary">
                                        <fmt:formatNumber value="${item.subtotal}" type="number" groupingUsed="true" maxFractionDigits="0"/> đ
                                    </td>
                                    <td>
                                        <a href="${pageContext.request.contextPath}/cart?action=remove&cartItemId=${item.cartItemId}"
                                           class="btn btn-outline-danger btn-sm"
                                           onclick="return confirm('Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng?')">
                                            Xóa
                                        </a>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>

                <!-- CLEAR CART -->
                <div class="mb-4">
                    <a href="${pageContext.request.contextPath}/cart?action=clear"
                       class="btn btn-outline-danger"
                       onclick="return confirm('Bạn có chắc chắn muốn xóa toàn bộ giỏ hàng?')">
                        Xóa toàn bộ giỏ hàng
                    </a>
                </div>

                <div class="row g-4">
                    <!-- VOUCHER SECTION -->
                    <div class="col-md-6">
                        <div class="card h-100">
                            <div class="card-body">
                                <h5 class="card-title mb-3">Mã giảm giá</h5>
                                <c:choose>
                                    <c:when test="${empty voucher}">
                                        <form action="${pageContext.request.contextPath}/cart" method="post">
                                            <input type="hidden" name="action" value="applyVoucher">
                                            <div class="input-group">
                                                <input type="text" name="voucherCode" class="form-control" placeholder="Nhập mã Voucher" required>
                                                <button type="submit" class="btn btn-primary">Áp dụng</button>
                                            </div>
                                        </form>
                                    </c:when>
                                    <c:otherwise>
                                        <div class="alert alert-success mb-0">
                                            <div>Mã đang dùng: <strong>${voucher.code}</strong></div>
                                            <c:choose>
                                                <c:when test="${voucher.discountType == 'PERCENT'}">
                                                    <small class="d-block text-muted">
                                                        Giảm: ${voucher.discountValue}%
                                                        <c:if test="${not empty voucher.maxDiscount}">
                                                            (Tối đa: <fmt:formatNumber value="${voucher.maxDiscount}" type="number" maxFractionDigits="0"/> đ)
                                                        </c:if>
                                                    </small>
                                                </c:when>
                                                <c:otherwise>
                                                    <small class="d-block text-muted">
                                                        Giảm: <fmt:formatNumber value="${voucher.discountValue}" type="number" maxFractionDigits="0"/> đ
                                                    </small>
                                                </c:otherwise>
                                            </c:choose>
                                            <a href="${pageContext.request.contextPath}/cart?action=removeVoucher" class="btn btn-sm btn-outline-danger mt-2">
                                                Gỡ bỏ Voucher
                                            </a>
                                        </div>
                                    </c:otherwise>
                                </c:choose>
                            </div>
                        </div>
                    </div>

                    <!-- TOTAL SECTION -->
                    <div class="col-md-6">
                        <div class="total-box text-end">
                            <p class="mb-2">
                                Tạm tính: 
                                <strong>
                                    <fmt:formatNumber value="${total}" type="number" groupingUsed="true" maxFractionDigits="0"/> đ
                                </strong>
                            </p>

                            <c:if test="${discount > 0}">
                                <p class="text-success mb-2">
                                    Giảm giá: 
                                    <strong>
                                        - <fmt:formatNumber value="${discount}" type="number" groupingUsed="true" maxFractionDigits="0"/> đ
                                    </strong>
                                </p>
                            </c:if>

                            <hr>

                            <div class="text-muted">Tổng thanh toán</div>
                            <div class="total-price my-2">
                                <fmt:formatNumber value="${finalTotal}" type="number" groupingUsed="true" maxFractionDigits="0"/> đ
                            </div>

                            <a href="${pageContext.request.contextPath}/checkout" class="btn btn-success btn-lg w-100 mt-2">
                                Tiến hành thanh toán
                            </a>
                        </div>
                    </div>
                </div>
            </c:if>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>