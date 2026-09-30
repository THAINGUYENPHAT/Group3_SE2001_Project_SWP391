<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html>
    <head>
        <title>Quản lý Sản Phẩm</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    </head>
    <body class="bg-light">
        <div class="container-fluid mt-5 px-4 mb-5">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h2 class="fw-bold text-primary">Danh sách Sản Phẩm</h2>
                <a href="${pageContext.request.contextPath}/product?view=create" class="btn btn-primary shadow-sm">
                    <i class="bi bi-plus-circle"></i> Thêm Sản Phẩm Mới
                </a>
            </div>

            <div class="card shadow-sm border-0">
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover table-striped align-middle text-center mb-0">
                            <thead class="table-dark">
                                <tr>
                                    <th>ID</th>
                                    <th>Hình ảnh</th>
                                    <th class="text-start">Tên sản phẩm</th>
                                    <th>Giá bán</th>
                                    <th>Danh mục</th>
                                    <th>Thương hiệu</th>
                                    <th>Thao tác</th>
                                </tr>
                            </thead>
                            <tbody>
                            <c:forEach items="${productList}" var="p">
                                <tr>
                                    <td>${p.productId}</td>
                                    <td>
                                <c:choose>
                                    <c:when test="${not empty p.imageUrl}">
                                        <img src="${p.imageUrl}" alt="${p.productName}" 
                                             style="width: 60px; height: 60px; object-fit: cover; border-radius: 8px; border: 1px solid #ddd;">
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge bg-secondary">No Image</span>
                                    </c:otherwise>
                                </c:choose>
                                </td>
                                <td class="text-start fw-bold text-dark">${p.productName}</td>
                                <td class="text-danger fw-bold">
                                <fmt:formatNumber value="${p.price}" pattern="#,##0"/> đ
                                </td>
                                <td><span class="badge bg-info text-dark">${p.category.categoryName}</span></td>
                                <td><span class="badge bg-secondary">${p.brand.brandName}</span></td>
                                <td>
                                    <!-- Nút Sửa -->
                                    <a href="${pageContext.request.contextPath}/product?view=edit&id=${p.productId}" class="btn btn-sm btn-warning">
                                        <i class="bi bi-pencil-square"></i> Sửa
                                    </a>

                                    <!-- Nút Xóa (Dùng form POST để bảo mật, thay vì truyền link GET) -->
                                    <form action="${pageContext.request.contextPath}/product" method="POST" class="d-inline" onsubmit="return confirm('⚠️ Bạn có chắc chắn muốn xóa sản phẩm: ${p.productName}?');">
                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="id" value="${p.productId}">
                                        <button type="submit" class="btn btn-sm btn-danger">
                                            <i class="bi bi-trash"></i> Xóa
                                        </button>
                                    </form>
                                </td>
                                </tr>
                            </c:forEach>

                            <!-- Hiển thị nếu danh sách rỗng -->
                            <c:if test="${empty productList}">
                                <tr>
                                    <td colspan="7" class="text-muted py-4">Chưa có sản phẩm nào trong cơ sở dữ liệu.</td>
                                </tr>
                            </c:if>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>