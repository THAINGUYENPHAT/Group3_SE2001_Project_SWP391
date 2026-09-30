<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Đặt hàng thành công</title>

    <link
        href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
        rel="stylesheet">
</head>

<body class="bg-light">

<div class="container py-5">

    <div
        class="card mx-auto shadow-sm"
        style="max-width: 600px;">

        <div class="card-body text-center p-5">

            <!-- ============================
                 DAT HANG THANH CONG
            ============================= -->
            <div
                class="text-success mb-3"
                style="font-size: 60px;">

                ✓

            </div>

            <h2 class="text-success">
                Đặt hàng thành công!
            </h2>

            <p class="mt-4 mb-1">
                Mã đơn hàng của bạn:
            </p>

            <h3 class="text-primary">
                #${orderId}
            </h3>

            <p class="text-muted mt-3">
                Đơn hàng đang chờ xác nhận.
            </p>

            <hr>

            <!-- ============================
                 NUT DIEU HUONG
            ============================= -->
            <div
                class="d-flex justify-content-center gap-2 mt-4">

                <a
                    href="${pageContext.request.contextPath}/home"
                    class="btn btn-primary">

                    Tiếp tục mua sắm

                </a>

                <a
                    href="${pageContext.request.contextPath}/cart"
                    class="btn btn-outline-secondary">

                    Về giỏ hàng

                </a>

            </div>

        </div>
    </div>

</div>

</body>
</html>