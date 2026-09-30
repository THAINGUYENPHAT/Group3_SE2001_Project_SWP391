<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">

        <title>Chi tiết đơn hàng</title>

        <link
            href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
            rel="stylesheet">
    </head>

    <body class="bg-light">

        <div class="container py-4">

            <div class="d-flex justify-content-between mb-4">

                <h2>
                    Chi tiết đơn #${order.orderId}
                </h2>

                <a
                    href="${pageContext.request.contextPath}/my-orders"
                    class="btn btn-outline-secondary">

                    Quay lại

                </a>

            </div>


            <!-- ============================
                 THONG TIN DON HANG
            ============================= -->
            <div class="card mb-4">

                <div class="card-header">
                    <strong>Thông tin đơn hàng</strong>
                </div>


                <div class="card-body">

                    <p>
                        <strong>Ngày đặt:</strong>

                        <fmt:formatDate
                            value="${order.createdAt}"
                            pattern="dd/MM/yyyy HH:mm"/>
                    </p>

                    <p>
                        <strong>Phương thức thanh toán:</strong>
                        ${order.paymentMethod}
                    </p>

                    <p>
                        <strong>Trạng thái thanh toán:</strong>
                        ${order.paymentStatus}
                    </p>

                    <p>
                        <strong>Trạng thái đơn:</strong>
                        ${order.orderStatus}
                    </p>

                </div>

            </div>
            <!-- ============================
                 LICH SU TRANG THAI
            ============================= -->
            <div class="card mb-4">

                <div class="card-header">
                    <strong>Theo dõi đơn hàng</strong>
                </div>

                <div class="card-body">

                    <c:choose>

                        <c:when test="${empty histories}">

                            <div class="text-muted">
                                Chưa có lịch sử trạng thái.
                            </div>

                        </c:when>

                        <c:otherwise>

                            <ul class="list-group list-group-flush">

                                <c:forEach
                                    var="history"
                                    items="${histories}">

                                    <li class="list-group-item">

                                        <div class="d-flex justify-content-between">

                                            <div>

                                                <c:choose>

                                                    <c:when test="${history.status == 'PENDING_CONFIRMATION'}">
                                                        <strong>Chờ xác nhận</strong>
                                                    </c:when>

                                                    <c:when test="${history.status == 'CONFIRMED'}">
                                                        <strong>Đã xác nhận</strong>
                                                    </c:when>

                                                    <c:when test="${history.status == 'SHIPPING'}">
                                                        <strong>Đang giao hàng</strong>
                                                    </c:when>

                                                    <c:when test="${history.status == 'COMPLETED'}">
                                                        <strong>Hoàn thành</strong>
                                                    </c:when>

                                                    <c:when test="${history.status == 'CANCELLED'}">
                                                        <strong class="text-danger">
                                                            Đã hủy
                                                        </strong>
                                                    </c:when>

                                                    <c:otherwise>
                                                        <strong>
                                                            ${history.status}
                                                        </strong>
                                                    </c:otherwise>

                                                </c:choose>

                                            </div>

                                            <div class="text-muted">

                                                <fmt:formatDate
                                                    value="${history.createdAt}"
                                                    pattern="dd/MM/yyyy HH:mm"/>

                                            </div>

                                        </div>

                                    </li>

                                </c:forEach>

                            </ul>

                        </c:otherwise>

                    </c:choose>

                </div>

            </div>

            <!-- ============================
                 THONG TIN NHAN HANG
            ============================= -->
            <div class="card mb-4">

                <div class="card-header">
                    <strong>Thông tin nhận hàng</strong>
                </div>

                <div class="card-body">

                    <p>
                        <strong>Người nhận:</strong>
                        ${order.recipientName}
                    </p>

                    <p>
                        <strong>Số điện thoại:</strong>
                        ${order.recipientPhone}
                    </p>

                    <p>
                        <strong>Địa chỉ:</strong>
                        ${order.shippingAddress}
                    </p>

                </div>

            </div>


            <!-- ============================
                 SAN PHAM
            ============================= -->
            <div class="card mb-4">

                <div class="card-header">
                    <strong>Sản phẩm</strong>
                </div>

                <div class="card-body">

                    <div class="table-responsive">

                        <table class="table">

                            <thead>

                                <tr>
                                    <th>SKU ID</th>
                                    <th>Đơn giá</th>
                                    <th>Số lượng</th>
                                    <th>Thành tiền</th>
                                </tr>

                            </thead>

                            <tbody>

                                <c:forEach
                                    var="item"
                                    items="${items}">

                                    <tr>

                                        <td>
                                            ${item.skuId}
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
                                                value="${item.price * item.quantity}"
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
                 TONG TIEN
            ============================= -->
            <div class="card">

                <div class="card-body">

                    <div class="row justify-content-end">

                        <div class="col-md-5">

                            <div class="d-flex justify-content-between">

                                <span>Phí vận chuyển:</span>

                                <span>
                                    <fmt:formatNumber
                                        value="${order.shippingFee}"
                                        type="number"
                                        groupingUsed="true"/>
                                    đ
                                </span>

                            </div>

                            <div class="d-flex justify-content-between mt-2">

                                <span>Giảm giá:</span>

                                <span class="text-success">

                                    -
                                    <fmt:formatNumber
                                        value="${order.discountAmount}"
                                        type="number"
                                        groupingUsed="true"/>
                                    đ

                                </span>

                            </div>

                            <hr>

                            <div class="d-flex justify-content-between">

                                <strong>Tổng thanh toán:</strong>

                                <strong class="text-danger">

                                    <fmt:formatNumber
                                        value="${order.totalAmount}"
                                        type="number"
                                        groupingUsed="true"/>
                                    đ

                                </strong>

                            </div>

                        </div>

                    </div>

                </div>

            </div>

        </div>

    </body>
</html>