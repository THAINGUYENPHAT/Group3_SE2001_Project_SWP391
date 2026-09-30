<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin Order Management</title>
</head>

<body>

<h1>Admin Order Management</h1>

<table border="1">

    <thead>
        <tr>
            <th>Order ID</th>
            <th>User ID</th>
            <th>Total Amount</th>
            <th>Shipping Fee</th>
            <th>Created At</th>
            <th>Action</th>
        </tr>
    </thead>

    <tbody>

        <c:forEach var="order" items="${orders}">

            <tr>

                <td>${order.orderId}</td>

                <td>${order.userId}</td>

                <td>${order.totalAmount}</td>

                <td>${order.shippingFee}</td>

                <td>${order.createdAt}</td>

                <td>
                    <a href="${pageContext.request.contextPath}/admin/orders/detail?id=${order.orderId}">
                        View Detail
                    </a>
                </td>

            </tr>

        </c:forEach>

    </tbody>

</table>

</body>
</html>