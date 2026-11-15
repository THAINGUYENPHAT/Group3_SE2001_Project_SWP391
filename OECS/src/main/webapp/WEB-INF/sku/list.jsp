<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="row justify-content-center">
    <div class="col-12 col-lg-10">

        <div class="mb-3">
            <a href="${pageContext.request.contextPath}/product?view=list" class="text-decoration-none text-muted fw-medium">
                <i class="bi bi-arrow-left me-1"></i>
                Quay lại danh sách sản phẩm
            </a>
        </div>

        <c:if test="${not empty sessionScope.errorMsg}">
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-2"></i> <c:out value="${sessionScope.errorMsg}"/>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
            <c:remove var="errorMsg" scope="session"/>
        </c:if>
        <c:if test="${not empty sessionScope.successMsg}">
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="bi bi-check-circle-fill me-2"></i> <c:out value="${sessionScope.successMsg}"/>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
            <c:remove var="successMsg" scope="session"/>
        </c:if>

        <div class="card shadow-sm border-0 rounded-4 mb-4">
            <div class="card-body p-4">
                <div class="d-flex align-items-center mb-3">
                    <div class="bg-success bg-opacity-10 text-success rounded d-flex align-items-center justify-content-center me-3" style="width: 48px; height: 48px;">
                        <i class="bi bi-tags fs-4"></i>
                    </div>
                    <div>
                        <h4 class="fw-bold mb-0">Quản lý SKU (Phiên bản sản phẩm)</h4>
                        <span class="text-muted fs-7">
                            Sản phẩm: <strong class="text-dark"><c:out value="${product.productName}"/></strong>
                        </span>
                    </div>
                </div>

                <hr>

                <h6 class="fw-bold mb-3 mt-4">Thêm phiên bản / SKU mới</h6>
                <form action="${pageContext.request.contextPath}/product-sku" method="POST" class="row g-3">
                    <input type="hidden" name="action" value="create">
                    <input type="hidden" name="productId" value="${product.productId}">

                    <div class="col-md-4">
                        <label class="form-label fw-semibold fs-7">Mã SKU (Gộp Thuộc tính) <span class="text-danger">*</span></label>
                        <input type="text" name="skuCode" class="form-control" placeholder="VD: IP15-256GB-BLACK" required>
                        <small class="text-muted fs-8">Mã duy nhất dùng để phân biệt màu sắc, dung lượng...</small>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold fs-7">Giá bán (VNĐ) <span class="text-danger">*</span></label>
                        <input type="text" name="priceStr" class="form-control" placeholder="VD: 25.000.000" required oninput="formatPrice(this)">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold fs-7">Tồn kho thực tế <span class="text-danger">*</span></label>
                        <input type="number" name="stock" class="form-control" min="0" value="0" required>
                    </div>
                    <div class="col-md-2 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary w-100">
                            <i class="bi bi-plus-lg me-1"></i> Thêm
                        </button>
                    </div>
                </form>

            </div>
        </div>

        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-custom align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-4">ID</th>
                                <th>MÃ SKU (THUỘC TÍNH)</th>
                                <th>GIÁ BÁN</th>
                                <th>TỒN KHO</th>
                                <th class="text-end pe-4">THAO TÁC</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:choose>
                                <c:when test="${not empty skuList}">
                                    <c:forEach items="${skuList}" var="sku">
                                        <tr>
                                            <td class="ps-4"><span class="badge bg-light text-secondary border">#${sku.skuId}</span></td>
                                            <td class="fw-bold text-dark"><c:out value="${sku.skuCode}"/></td>
                                            <td class="text-danger fw-semibold">
                                                <fmt:formatNumber value="${sku.price}" pattern="#,### VNĐ"/>
                                            </td>
                                            <td>
                                                <c:choose>
                                                    <c:when test="${sku.stockQuantity > 10}">
                                                        <span class="badge bg-success-subtle text-success border border-success-subtle">${sku.stockQuantity} sản phẩm</span>
                                                    </c:when>
                                                    <c:when test="${sku.stockQuantity > 0}">
                                                        <span class="badge bg-warning-subtle text-warning border border-warning-subtle">${sku.stockQuantity} sản phẩm</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="badge bg-danger-subtle text-danger border border-danger-subtle">Hết hàng</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>
                                            <td class="text-end pe-4">
                                                <button type="button" class="btn btn-sm btn-light text-primary border rounded-2 me-1" data-bs-toggle="modal" data-bs-target="#editModal${sku.skuId}">
                                                    <i class="bi bi-pencil"></i> Sửa
                                                </button>

                                                <form action="${pageContext.request.contextPath}/product-sku" method="POST" class="d-inline">
                                                    <input type="hidden" name="action" value="delete">
                                                    <input type="hidden" name="productId" value="${product.productId}">
                                                    <input type="hidden" name="skuId" value="${sku.skuId}">
                                                    <button type="submit" class="btn btn-sm btn-light text-danger border rounded-2" onclick="return confirm('Bạn có chắc chắn muốn xóa SKU này?');">
                                                        <i class="bi bi-trash"></i> Xóa
                                                    </button>
                                                </form>
                                            </td>
                                        </tr>

                                    <div class="modal fade" id="editModal${sku.skuId}" tabindex="-1" aria-hidden="true">
                                        <div class="modal-dialog">
                                            <div class="modal-content">
                                                <div class="modal-header">
                                                    <h5 class="modal-title fw-bold">Chỉnh sửa SKU #${sku.skuId}</h5>
                                                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                                </div>
                                                <form action="${pageContext.request.contextPath}/product-sku" method="POST">
                                                    <div class="modal-body text-start">
                                                        <input type="hidden" name="action" value="update">
                                                        <input type="hidden" name="productId" value="${product.productId}">
                                                        <input type="hidden" name="skuId" value="${sku.skuId}">

                                                        <div class="mb-3">
                                                            <label class="form-label fw-semibold">Mã SKU</label>
                                                            <input type="text" name="skuCode" class="form-control" value="<c:out value='${sku.skuCode}'/>" required>
                                                        </div>
                                                        <div class="mb-3">
                                                            <label class="form-label fw-semibold">Giá bán (VNĐ)</label>
                                                            <input type="text" name="priceStr" class="form-control" 
                                                                   value="<fmt:formatNumber value="${sku.price}" pattern="#,###" />" 
                                                                   required oninput="formatPrice(this)">
                                                        </div>
                                                        <div class="mb-3">
                                                            <label class="form-label fw-semibold">Tồn kho</label>
                                                            <input type="number" name="stock" class="form-control" min="0" value="${sku.stockQuantity}" required>
                                                        </div>
                                                    </div>
                                                    <div class="modal-footer border-0">
                                                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Hủy</button>
                                                        <button type="submit" class="btn btn-primary">Lưu thay đổi</button>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>

                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="5" class="text-center py-4 text-muted">
                                        <i class="bi bi-tags fs-2"></i>
                                        <p class="mt-2 mb-0">Sản phẩm này chưa có SKU (Phiên bản) nào.</p>
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    </div>
</div>

<script>
    function formatPrice(input) {
        let value = input.value.replace(/\D/g, '');

        if (value !== '') {
            input.value = value.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
        } else {
            input.value = '';
        }
    }

    document.addEventListener("DOMContentLoaded", function () {
        const priceInputs = document.querySelectorAll('input[name="priceStr"]');
        priceInputs.forEach(input => {
            input.value = input.value.replace(/,/g, '.');
        });
    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>