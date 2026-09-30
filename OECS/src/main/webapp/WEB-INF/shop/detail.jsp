<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html>
    <head>
        <title>${product.productName} - OECS</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    </head>
    <body class="bg-light">

        <nav class="navbar navbar-dark bg-dark mb-4">
            <div class="container">
                <a class="navbar-brand fw-bold" href="${pageContext.request.contextPath}/shop">OECS STORE</a>
            </div>
        </nav>

        <div class="container mb-5 bg-white p-4 shadow-sm rounded">
            <div class="row">
                <!-- Cột Trái: Hình ảnh -->
                <div class="col-md-5 text-center">
                    <c:choose>
                        <c:when test="${not empty product.imageUrl}">
                            <img src="${product.imageUrl}" class="img-fluid rounded" style="max-height: 400px; object-fit: contain;">
                        </c:when>
                        <c:otherwise>
                            <img src="https://via.placeholder.com/400x400?text=No+Image" class="img-fluid rounded">
                        </c:otherwise>
                    </c:choose>
                </div>

                <!-- Cột Phải: Thông tin mua hàng -->
                <div class="col-md-7">
                    <span class="badge bg-secondary mb-2">${product.brand.brandName}</span>
                    <h2 class="fw-bold">${product.productName}</h2>

                    <!-- Giá hiển thị (Sẽ thay đổi bằng JS khi chọn SKU) -->
                    <h3 class="text-danger fw-bold my-3" id="displayPrice">
                        <fmt:formatNumber value="${product.price}" pattern="#,##0"/> đ
                    </h3>

                    <p class="text-muted">${product.description}</p>
                    <hr>

                    <!-- Form Thêm vào giỏ -->
                    <form action="${pageContext.request.contextPath}/cart" method="POST">
                        <input type="hidden" name="action" value="add">

                        <div class="mb-4">
                            <label class="fw-bold mb-2">Chọn phiên bản (SKU):</label>
                            <select class="form-select w-50" name="skuId" id="skuSelector" onchange="updatePriceAndStock()" required>
                                <option value="" disabled selected>-- Chọn phiên bản --</option>
                                <c:forEach items="${skus}" var="sku">
                                    <!-- Lưu giá và tồn kho vào data-attribute để JS đọc -->
                                    <option value="${sku.skuId}" 
                                            data-price="${sku.price}" 
                                            data-stock="${sku.stockQuantity}">
                                        ${sku.skuCode}
                                    </option>
                                </c:forEach>
                            </select>
                        </div>

                        <div class="mb-4">
                            <span class="text-success fw-bold" id="stockStatus">Vui lòng chọn phiên bản để xem tồn kho</span>
                        </div>

                        <button type="submit" class="btn btn-danger btn-lg px-5" id="btnAddToCart" disabled>
                            Thêm vào giỏ hàng
                        </button>
                    </form>
                </div>
            </div>

            <div class="row mt-5">
                <!-- Bảng Thông số kỹ thuật -->
                <div class="col-12">
                    <h4 class="fw-bold mb-3">Thông số kỹ thuật</h4>
                    <table class="table table-striped table-bordered">
                        <tbody>
                        <c:forEach items="${specs}" var="spec">
                            <tr>
                                <td class="fw-bold w-25 bg-light">${spec.attributeName}</td>
                                <td>${spec.value}</td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty specs}">
                            <tr><td colspan="2" class="text-muted">Đang cập nhật thông số...</td></tr>
                        </c:if>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <script>
            // Xử lý động đổi giá tiền và tồn kho khi chọn SKU
            function updatePriceAndStock() {
                const selector = document.getElementById("skuSelector");
                const selectedOption = selector.options[selector.selectedIndex];

                const price = selectedOption.getAttribute("data-price");
                const stock = selectedOption.getAttribute("data-stock");

                const displayPrice = document.getElementById("displayPrice");
                const stockStatus = document.getElementById("stockStatus");
                const btnAdd = document.getElementById("btnAddToCart");

                if (price && stock) {
                    // Định dạng lại giá (Format to locale string)
                    const formattedPrice = parseFloat(price).toLocaleString('vi-VN');
                    displayPrice.innerHTML = formattedPrice + " đ";

                    if (parseInt(stock) > 0) {
                        stockStatus.innerHTML = "Còn hàng (" + stock + " sản phẩm)";
                        stockStatus.className = "text-success fw-bold";
                        btnAdd.disabled = false;
                    } else {
                        stockStatus.innerHTML = "Tạm hết hàng";
                        stockStatus.className = "text-danger fw-bold";
                        btnAdd.disabled = true;
                    }
                }
            }
        </script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>