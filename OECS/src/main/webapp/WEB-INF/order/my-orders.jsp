<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Đơn hàng của tôi</title>

        <link
            href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
            rel="stylesheet">
    </head>

    <body class="bg-light">

        <div class="container py-4">

            <h2 class="mb-4">
                Đơn hàng của tôi
            </h2>
            <!-- ============================
                 THONG BAO
            ============================= -->
            <c:if test="${not empty sessionScope.orderMessage}">

                <div class="alert alert-success">

                    ${sessionScope.orderMessage}

                </div>

                <c:remove
                    var="orderMessage"
                    scope="session"/>

            </c:if>


            <c:if test="${not empty sessionScope.orderError}">

                <div class="alert alert-danger">

                    ${sessionScope.orderError}

                </div>

                <c:remove
                    var="orderError"
                    scope="session"/>

            </c:if>

            <!-- ============================
                 CHUA CO DON HANG
            ============================= -->
            <c:if test="${empty orders}">

                <div class="alert alert-info">

                    Bạn chưa có đơn hàng nào.

                </div>

                <a
                    href="${pageContext.request.contextPath}/home"
                    class="btn btn-primary">

                    Tiếp tục mua sắm

                </a>

            </c:if>


            <!-- ============================
                 DANH SACH DON HANG
            ============================= -->
            <c:if test="${not empty orders}">

                <div class="card">

                    <div class="card-body">

                        <div class="table-responsive">

                            <table class="table align-middle">

                                <thead>

                                    <tr>
                                        <th>Mã đơn</th>
                                        <th>Ngày đặt</th>
                                        <th>Thanh toán</th>
                                        <th>Trạng thái</th>
                                        <th>Tổng tiền</th>
                                        <th></th>
                                    </tr>

                                </thead>

                                <tbody>

                                    <c:forEach
                                        var="order"
                                        items="${orders}">

                                        <tr>

                                            <td>
                                                #${order.orderId}
                                            </td>

                                            <td>
                                                <fmt:formatDate
                                                    value="${order.createdAt}"
                                                    pattern="dd/MM/yyyy HH:mm"/>
                                            </td>

                                            <td>
                                                ${order.paymentMethod}
                                            </td>

                                            <td>

                                                <c:choose>

                                                    <c:when test="${order.orderStatus == 'PENDING_CONFIRMATION'}">
                                                        <span class="badge bg-warning text-dark">
                                                            Chờ xác nhận
                                                        </span>
                                                    </c:when>

                                                    <c:when test="${order.orderStatus == 'CONFIRMED'}">
                                                        <span class="badge bg-primary">
                                                            Đã xác nhận
                                                        </span>
                                                    </c:when>

                                                    <c:when test="${order.orderStatus == 'SHIPPING'}">
                                                        <span class="badge bg-info text-dark">
                                                            Đang giao
                                                        </span>
                                                    </c:when>

                                                    <c:when test="${order.orderStatus == 'COMPLETED'}">
                                                        <span class="badge bg-success">
                                                            Hoàn thành
                                                        </span>
                                                    </c:when>

                                                    <c:when test="${order.orderStatus == 'CANCELLED'}">
                                                        <span class="badge bg-danger">
                                                            Đã hủy
                                                        </span>
                                                    </c:when>

                                                    <c:otherwise>
                                                        ${order.orderStatus}
                                                    </c:otherwise>

                                                </c:choose>

                                            </td>

                                            <td>

                                                <fmt:formatNumber
                                                    value="${order.totalAmount}"
                                                    type="number"
                                                    groupingUsed="true"/>
                                                đ

                                            </td>

                                            <td>

                                                <div class="d-flex gap-2">

                                                    <a
                                                        href="${pageContext.request.contextPath}/order-detail?id=${order.orderId}"
                                                        class="btn btn-outline-primary btn-sm">

                                                        Xem chi tiết

                                                    </a>

                                                    <c:if test="${order.orderStatus == 'PENDING_CONFIRMATION'}">

                                                        <form
                                                            action="${pageContext.request.contextPath}/cancel-order"
                                                            method="post"
                                                            onsubmit="return confirm('Bạn có chắc muốn hủy đơn này không?');">

                                                            <input
                                                                type="hidden"
                                                                name="orderId"
                                                                value="${order.orderId}">

                                                            <button
                                                                type="submit"
                                                                class="btn btn-outline-danger btn-sm">

                                                                Hủy đơn

                                                            </button>

                                                        </form>

                                                    </c:if>

                                                </div>

                                            </td>

                                        </tr>

                                    </c:forEach>

                                </tbody>

                            </table>

                        </div>

                    </div>

                </div>

            </c:if>

        </div>

    </body>
</html>