<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Order Detail</title>
    </head>

    <body>

        <h1>Order Detail</h1>

        <h2>Order Information</h2>

        <p>Order ID: ${order.orderId}</p>

        <p>User ID: ${order.userId}</p>

        <p>Address ID: ${order.addressId}</p>

        <p>Total Amount: ${order.totalAmount}</p>

        <p>Shipping Fee: ${order.shippingFee}</p>

        <p>Created At: ${order.createdAt}</p>

        <p>
            Status:
            <strong>${status}</strong>
        </p>

        <c:if test="${status == 'Pending'}">

            <form method="post"
                  action="${pageContext.request.contextPath}/admin/orders">

                <input type="hidden" name="action" value="confirm">
                <input type="hidden"
                       name="orderId"
                       value="${order.orderId}">

                <button type="submit">
                    Confirm Order
                </button>

            </form>

            <form method="post"
                  action="${pageContext.request.contextPath}/admin/orders">

                <input type="hidden" name="action" value="cancel">
                <input type="hidden"
                       name="orderId"
                       value="${order.orderId}">

                <button type="submit">
                    Cancel Order
                </button>

            </form>

        </c:if>

        <c:if test="${status == 'Confirmed'}">

            <form method="post"
                  action="${pageContext.request.contextPath}/admin/orders">

                <input type="hidden"
                       name="action"
                       value="changeStatus">

                <input type="hidden"
                       name="orderId"
                       value="${order.orderId}">

                <input type="hidden"
                       name="status"
                       value="Packing">

                <button type="submit">
                    Start Packing
                </button>

            </form>

        </c:if>

        <c:if test="${status == 'Packing'}">

            <form method="post"
                  action="${pageContext.request.contextPath}/admin/orders">

                <input type="hidden"
                       name="action"
                       value="changeStatus">

                <input type="hidden"
                       name="orderId"
                       value="${order.orderId}">

                <input type="hidden"
                       name="status"
                       value="Shipping">

                <button type="submit">
                    Ship Order
                </button>

            </form>

        </c:if>

        <c:if test="${status == 'Shipping'}">

            <form method="post"
                  action="${pageContext.request.contextPath}/admin/orders">

                <input type="hidden"
                       name="action"
                       value="changeStatus">

                <input type="hidden"
                       name="orderId"
                       value="${order.orderId}">

                <input type="hidden"
                       name="status"
                       value="Completed">

                <button type="submit">
                    Delivery Completed
                </button>

            </form>


            <form method="post"
                  action="${pageContext.request.contextPath}/admin/orders">

                <input type="hidden"
                       name="action"
                       value="changeStatus">

                <input type="hidden"
                       name="orderId"
                       value="${order.orderId}">

                <input type="hidden"
                       name="status"
                       value="Failed">

                <button type="submit">
                    Delivery Failed
                </button>

            </form>

        </c:if>


        <h2>Order Items</h2>

        <table border="1">

            <tr>
                <th>Order Item ID</th>
                <th>SKU ID</th>
                <th>Price</th>
                <th>Quantity</th>
            </tr>

            <c:forEach var="item" items="${items}">

                <tr>

                    <td>${item.orderItemId}</td>

                    <td>${item.skuId}</td>

                    <td>${item.price}</td>

                    <td>${item.quantity}</td>

                </tr>

            </c:forEach>

        </table>

        <br>

        <a href="${pageContext.request.contextPath}/admin/orders">
            Back to Orders
        </a>

    </body>
</html>