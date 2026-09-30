<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html>
    <head>
        <title>Chỉnh Sửa Sản Phẩm</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    </head>
    <body class="bg-light">
        <div class="container mt-5 mb-5">
            <div class="row justify-content-center">
                <div class="col-md-8">
                    <div class="card shadow-sm">
                        <div class="card-header bg-warning text-dark">
                            <h4 class="mb-0">Chỉnh Sửa Sản Phẩm: ${product.productName}</h4>
                        </div>
                        <div class="card-body">
                            <form action="${pageContext.request.contextPath}/product" method="POST">
                                <input type="hidden" name="action" value="update">
                                <!-- ID sản phẩm ẩn để WHERE khi update -->
                                <input type="hidden" name="id" value="${product.productId}">

                                <div class="mb-3">
                                    <label class="form-label fw-bold">Tên sản phẩm *</label>
                                    <input type="text" name="name" class="form-control" value="${product.productName}" required>
                                </div>

                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold">Giá gốc (VNĐ) *</label>
                                        <!-- Lưu ý: cần parse chuỗi double bỏ .0 nếu cần -->
                                        <input type="number" name="price" class="form-control" value="${product.price}" required min="0">
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold">Hình ảnh đại diện (URL)</label>
                                        <input type="url" name="imageUrl" class="form-control" value="${product.imageUrl}">
                                    </div>
                                </div>

                                <!-- Hiển thị ảnh xem trước nếu có URL -->
                                <c:if test="${not empty product.imageUrl}">
                                    <div class="mb-3">
                                        <img src="${product.imageUrl}" alt="Preview" style="max-height: 150px; border-radius: 8px;">
                                    </div>
                                </c:if>

                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold">Danh mục *</label>
                                        <select name="categoryId" class="form-select" required>
                                            <c:forEach items="${categoryList}" var="c">
                                                <option value="${c.categoryId}" ${c.categoryId == product.category.categoryId ? 'selected' : ''}>
                                                    ${c.categoryName}
                                                </option>
                                            </c:forEach>
                                        </select>
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold">Thương hiệu *</label>
                                        <select name="brandId" class="form-select" required>
                                            <c:forEach items="${brandList}" var="b">
                                                <option value="${b.brandId}" ${b.brandId == product.brand.brandId ? 'selected' : ''}>
                                                    ${b.brandName}
                                                </option>
                                            </c:forEach>
                                        </select>
                                    </div>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label fw-bold">Mô tả sản phẩm</label>
                                    <textarea name="description" class="form-control" rows="5">${product.description}</textarea>
                                </div>

                                <div class="d-flex justify-content-end gap-2">
                                    <a href="${pageContext.request.contextPath}/product?view=list" class="btn btn-secondary">Hủy bỏ</a>
                                    <button type="submit" class="btn btn-warning">Cập Nhật Bảng</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </body>
</html>