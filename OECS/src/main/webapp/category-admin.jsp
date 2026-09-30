<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html>
<head>
    <title>Quản lý danh mục</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
</head>
<body>
<div class="container mt-5">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2>Quản lý danh mục sản phẩm</h2>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
            <i class="bi bi-plus-circle"></i> Thêm danh mục
        </button>
    </div>

    <table class="table table-bordered table-hover align-middle">
        <thead class="table-dark">
            <tr>
                <th>ID</th>
                <th>Tên danh mục</th>
                <th>Thứ tự hiển thị</th>
                <th>Thao tác</th>
            </tr>
        </thead>
        <tbody>
            <!-- Lặp để hiển thị danh mục GỐC (parent_id == null) -->
            <c:forEach items="${categories}" var="parent">
                <c:if test="${parent.parentId == null}">
                    <tr class="table-light fw-bold">
                        <td>${parent.categoryId}</td>
                        <td>${parent.categoryName}</td>
                        <td>${parent.displayOrder}</td>
                        <td>
                            <button class="btn btn-sm btn-warning" onclick="openEditModal(${parent.categoryId}, '${parent.categoryName}', 0, ${parent.displayOrder})">Sửa</button>
                            <a href="category?action=delete&id=${parent.categoryId}" class="btn btn-sm btn-danger" onclick="return confirm('Bạn có chắc muốn xóa?')">Xóa</a>
                        </td>
                    </tr>
                    
                    <!-- Lặp để hiển thị danh mục CON của danh mục gốc này -->
                    <c:forEach items="${categories}" var="child">
                        <c:if test="${child.parentId == parent.categoryId}">
                            <tr>
                                <td>${child.categoryId}</td>
                                <td><span class="ms-4 text-muted">|_</span> ${child.categoryName}</td>
                                <td>${child.displayOrder}</td>
                                <td>
                                    <button class="btn btn-sm btn-outline-warning" onclick="openEditModal(${child.categoryId}, '${child.categoryName}', ${child.parentId}, ${child.displayOrder})">Sửa</button>
                                    <a href="category?action=delete&id=${child.categoryId}" class="btn btn-sm btn-outline-danger" onclick="return confirm('Bạn có chắc muốn xóa?')">Xóa</a>
                                </td>
                            </tr>
                        </c:if>
                    </c:forEach>

                </c:if>
            </c:forEach>
        </tbody>
    </table>
</div>

<!-- Modal Thêm/Sửa Danh Mục -->
<div class="modal fade" id="categoryModal" tabindex="-1">
    <div class="modal-dialog">
        <form action="category" method="POST" class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="modalTitle">Thêm danh mục</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" name="action" id="formAction" value="add">
                <input type="hidden" name="categoryId" id="catId" value="">
                
                <div class="mb-3">
                    <label>Tên danh mục</label>
                    <input type="text" name="categoryName" id="catName" class="form-control" required>
                </div>
                <div class="mb-3">
                    <label>Danh mục cha (Để trống nếu là DM gốc)</label>
                    <select name="parentId" id="catParent" class="form-select">
                        <option value="0">-- Là danh mục gốc --</option>
                        <c:forEach items="${categories}" var="c">
                            <c:if test="${c.parentId == null}">
                                <option value="${c.categoryId}">${c.categoryName}</option>
                            </c:if>
                        </c:forEach>
                    </select>
                </div>
                <div class="mb-3">
                    <label>Thứ tự hiển thị</label>
                    <input type="number" name="displayOrder" id="catOrder" class="form-control" value="0">
                </div>
            </div>
            <div class="modal-footer">
                <button type="submit" class="btn btn-success">Lưu lại</button>
            </div>
        </form>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    const categoryModal = new bootstrap.Modal(document.getElementById('categoryModal'));
    
    // Gắn sự kiện cho nút Thêm mới (Reset form)
    document.querySelector('[data-bs-target="#addModal"]').addEventListener('click', function() {
        document.getElementById('modalTitle').innerText = 'Thêm danh mục';
        document.getElementById('formAction').value = 'add';
        document.getElementById('catId').value = '';
        document.getElementById('catName').value = '';
        document.getElementById('catParent').value = '0';
        document.getElementById('catOrder').value = '0';
        categoryModal.show();
    });

    // Hàm gọi khi bấm nút Sửa
    function openEditModal(id, name, parentId, order) {
        document.getElementById('modalTitle').innerText = 'Sửa danh mục';
        document.getElementById('formAction').value = 'update';
        document.getElementById('catId').value = id;
        document.getElementById('catName').value = name;
        document.getElementById('catParent').value = parentId === null ? 0 : parentId;
        document.getElementById('catOrder').value = order;
        categoryModal.show();
    }
</script>
</body>
</html>