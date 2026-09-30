<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html>
    <head>
        <title>Thêm Sản Phẩm Mới</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    </head>
    <body class="bg-light">
        <div class="container mt-5 mb-5">
            <div class="row justify-content-center">
                <div class="col-md-8">
                    <div class="card shadow-sm">
                        <div class="card-header bg-primary text-white">
                            <h4 class="mb-0">Thêm Sản Phẩm Mới</h4>
                        </div>
                        <div class="card-body">
                            <form action="${pageContext.request.contextPath}/product" method="POST">
                                <input type="hidden" name="action" value="create">

                                <div class="mb-3">
                                    <label class="form-label fw-bold">Tên sản phẩm *</label>
                                    <input type="text" name="name" class="form-control" required placeholder="Nhập tên sản phẩm...">
                                </div>

                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold">Giá gốc (VNĐ) *</label>
                                        <input type="number" name="price" class="form-control" required min="0" value="0">
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold">Hình ảnh đại diện (URL)</label>
                                        <input type="url" name="imageUrl" class="form-control" placeholder="https://domain.com/image.jpg">
                                    </div>
                                </div>

                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold">Danh mục *</label>
                                        <select name="categoryId" class="form-select" required>
                                            <option value="">-- Chọn danh mục --</option>
                                            <c:forEach items="${categoryList}" var="c">
                                                <option value="${c.categoryId}">${c.categoryName}</option>
                                            </c:forEach>
                                        </select>
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold">Thương hiệu *</label>
                                        <select name="brandId" class="form-select" required>
                                            <option value="">-- Chọn thương hiệu --</option>
                                            <c:forEach items="${brandList}" var="b">
                                                <option value="${b.brandId}">${b.brandName}</option>
                                            </c:forEach>
                                        </select>
                                    </div>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label fw-bold">Mô tả sản phẩm</label>
                                    <textarea name="description" class="form-control" rows="5" placeholder="Nhập mô tả chi tiết..."></textarea>
                                </div>

                                <div class="d-flex justify-content-end gap-2">
                                    <a href="${pageContext.request.contextPath}/product?view=list" class="btn btn-secondary">Hủy bỏ</a>
                                    <button type="submit" class="btn btn-primary">Lưu Sản Phẩm</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </body>
</html>