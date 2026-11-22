
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="container-fluid px-0">

    <!-- QUAY LẠI -->
    <div class="mb-3">
        <a href="${pageContext.request.contextPath}/product?view=list"
           class="text-decoration-none text-muted">
            <i class="bi bi-arrow-left me-1"></i>
            Quay lại danh sách sản phẩm
        </a>
    </div>

    <!-- THÔNG BÁO -->
    <c:if test="${not empty sessionScope.errorMsg}">
        <div class="alert alert-danger alert-dismissible fade show">
            <c:out value="${sessionScope.errorMsg}"/>
            <button type="button" class="btn-close"
                    data-bs-dismiss="alert"
                    aria-label="Đóng"></button>
        </div>
        <c:remove var="errorMsg" scope="session"/>
    </c:if>

    <c:if test="${not empty sessionScope.successMsg}">
        <div class="alert alert-success alert-dismissible fade show">
            <c:out value="${sessionScope.successMsg}"/>
            <button type="button" class="btn-close"
                    data-bs-dismiss="alert"
                    aria-label="Đóng"></button>
        </div>
        <c:remove var="successMsg" scope="session"/>
    </c:if>

    <!-- =================================== -->
    <!-- 1. HEADER VÀ ĐIỀU HƯỚNG           -->
    <!-- =================================== -->

    <div class="card shadow-sm border-0 rounded-4 mb-4">
        <div class="card-body p-4">

            <div class="d-flex flex-wrap justify-content-between
                 align-items-center gap-3">

                <div class="d-flex align-items-center">
                    <div class="bg-primary bg-opacity-10 text-primary
                         rounded d-flex align-items-center
                         justify-content-center me-3"
                         style="width:48px;height:48px;">
                        <i class="bi bi-tags fs-4"></i>
                    </div>

                    <div>
                        <h4 class="fw-bold mb-1">
                            Quản Lý SKU
                        </h4>
                        <div class="text-muted">
                            <c:out value="${product.productName}"/>
                        </div>
                        <small class="text-muted">
                            Product ID: #${product.productId}
                        </small>
                    </div>
                </div>

                <div class="d-flex flex-wrap gap-2">

                    <a href="${pageContext.request.contextPath}/product?view=edit&amp;id=${product.productId}"
                       class="btn btn-outline-secondary">
                        <i class="bi bi-pencil-square me-1"></i>
                        Sửa sản phẩm
                    </a>

                    <!-- TÍNH NĂNG MỚI -->
                    <c:if test="${not empty variantAttributes}">
                        <a href="${pageContext.request.contextPath}/sku-bulk?productId=${product.productId}"
                           class="btn btn-success">
                            <i class="bi bi-grid-3x3-gap me-1"></i>
                            Tạo SKU hàng loạt
                        </a>
                    </c:if>

                </div>

            </div>
        </div>
    </div>

    <!-- =================================== -->
    <!-- 2. THUỘC TÍNH BIẾN THỂ           -->
    <!-- =================================== -->

    <div class="card shadow-sm border-0 rounded-4 mb-4">
        <div class="card-body p-4">

            <h6 class="fw-bold mb-3">
                <i class="bi bi-sliders me-2 text-primary"></i>
                Thuộc Tính Biến Thể
            </h6>

            <c:choose>
                <c:when test="${not empty variantAttributes}">

                    <div class="d-flex flex-wrap gap-2">
                        <c:forEach items="${variantAttributes}"
                                   var="config">
                            <span class="badge bg-primary-subtle
                                  text-primary border p-2">
                                <c:out value="${config.attributeName}"/>
                                <c:if test="${config.required}">
                                    <span class="text-danger">*</span>
                                </c:if>
                            </span>
                        </c:forEach>
                    </div>

                    <div class="form-text mt-2">
                        Bạn có thể tạo từng SKU thủ công
                        hoặc sinh nhiều tổ hợp bằng nút
                        <strong>Tạo SKU hàng loạt</strong>.
                    </div>
                </c:when>

                <c:otherwise>
                    <div class="alert alert-warning mb-0">
                        Danh mục chưa cấu hình thuộc tính biến thể.
                        Hiện chỉ hỗ trợ tạo SKU cơ bản.
                    </div>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <!-- =================================== -->
    <!-- 3. FORM THÊM SKU                  -->
    <!-- =================================== -->

    <div class="card shadow-sm border-0 rounded-4 mb-4">
        <div class="card-body p-4">

            <h5 class="fw-bold mb-4">
                <i class="bi bi-plus-circle me-2 text-primary"></i>
                Thêm SKU Thủ Công
            </h5>

            <form action="${pageContext.request.contextPath}/product-sku"
                  method="POST"
                  class="sku-form">

                <input type="hidden" name="action" value="create">
                <input type="hidden" name="productId"
                       value="${product.productId}">

                <div class="row g-3 mb-4">

                    <div class="col-md-6">
                        <label class="form-label fw-semibold">
                            Mã SKU <span class="text-danger">*</span>
                        </label>
                        <input type="text" name="skuCode"
                               class="form-control" maxlength="100"
                               placeholder="VD: IP15P-128-BLK"
                               required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label fw-semibold">
                            Trạng thái
                        </label>
                        <select name="isActive" class="form-select">
                            <option value="true">Đang kinh doanh</option>
                            <option value="false">Ngừng kinh doanh</option>
                        </select>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label fw-semibold">
                            Giá bán (VNĐ)
                            <span class="text-danger">*</span>
                        </label>
                        <input type="text" name="priceStr"
                               class="form-control money-input"
                               inputmode="numeric"
                               placeholder="27.990.000" required>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label fw-semibold">
                            Giá niêm yết (VNĐ)
                        </label>
                        <input type="text" name="originalPriceStr"
                               class="form-control money-input"
                               inputmode="numeric"
                               placeholder="29.990.000">
                    </div>

                    <div class="col-md-4">
                        <label class="form-label fw-semibold">
                            Tồn kho <span class="text-danger">*</span>
                        </label>
                        <input type="number" name="stock"
                               class="form-control" min="0"
                               step="1" value="0" required>
                    </div>
                </div>

                <!-- FORM THUỘC TÍNH ĐỘNG -->
                <c:if test="${not empty variantAttributes}">

                    <div class="border rounded-3 p-3 mb-4">
                        <h6 class="fw-bold mb-3">
                            Giá Trị Biến Thể
                        </h6>

                        <div class="row g-3">
                            <c:forEach items="${variantAttributes}"
                                       var="config">

                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">
                                        <c:out value="${config.attributeName}"/>
                                        <c:if test="${config.required}">
                                            <span class="text-danger">*</span>
                                        </c:if>
                                    </label>

                                    <input type="hidden" name="attributeIds"
                                           value="${config.attributeId}">

                                    <c:choose>
                                        <c:when test="${config.dataType eq 'BOOLEAN'}">
                                            <select name="attributeValues"
                                                    class="form-select"
                                                    ${config.required ? 'required' : ''}>
                                                <option value="">-- Chọn --</option>
                                                <option value="true">Có</option>
                                                <option value="false">Không</option>
                                            </select>
                                        </c:when>

                                        <c:when test="${config.dataType eq 'NUMBER'}">
                                            <input type="number"
                                                   name="attributeValues"
                                                   class="form-control"
                                                   step="0.0001"
                                                   ${config.required ? 'required' : ''}>
                                        </c:when>

                                        <c:otherwise>
                                            <input type="text"
                                                   name="attributeValues"
                                                   class="form-control"
                                                   maxlength="255"
                                                   ${config.required ? 'required' : ''}>
                                        </c:otherwise>
                                    </c:choose>

                                    <c:if test="${not empty config.unit}">
                                        <div class="form-text">
                                            Đơn vị:
                                            <c:out value="${config.unit}"/>
                                        </div>
                                    </c:if>
                                </div>

                            </c:forEach>
                        </div>
                    </div>
                </c:if>

                <div class="text-end">
                    <button type="submit" class="btn btn-primary px-4">
                        <i class="bi bi-plus-lg me-1"></i>
                        Thêm SKU
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- =================================== -->
    <!-- 4. BẢNG DANH SÁCH SKU             -->
    <!-- =================================== -->

    <div class="card shadow-sm border-0 rounded-4">
        <div class="card-body p-0">

            <div class="p-4 border-bottom d-flex
                 justify-content-between align-items-center">
                <h5 class="fw-bold mb-0">Danh Sách SKU</h5>
                <span class="badge bg-light text-dark border">
                    ${fn:length(skuList)} phiên bản
                </span>
            </div>

            <div class="table-responsive">
                <table class="table align-middle mb-0">

                    <thead class="table-light">
                        <tr>
                            <th class="ps-4">MÃ SKU</th>
                            <th>BIẾN THỂ</th>
                            <th>GIÁ BÁN</th>
                            <th>TỒN KHO</th>
                            <th>TRẠNG THÁI</th>
                            <th>ẢNH SKU</th>
                            <th class="text-end pe-4">THAO TÁC</th>
                        </tr>
                    </thead>

                    <tbody>
                        <c:choose>
                            <c:when test="${not empty skuList}">

                                <c:forEach items="${skuList}" var="sku">

                                    <c:set var="skuImages"
                                           value="${skuImagesBySkuId[sku.skuId]}"/>

                                    <tr>
                                        <td class="ps-4">
                                            <div class="fw-bold">
                                                <c:out value="${sku.skuCode}"/>
                                            </div>
                                            <small class="text-muted">
                                                #${sku.skuId}
                                            </small>
                                        </td>

                                        <td>
                                            <c:choose>
                                                <c:when test="${not empty sku.attributeValues}">
                                                    <div class="d-flex flex-wrap gap-1">
                                                        <c:forEach items="${sku.attributeValues}"
                                                                   var="attr">
                                                            <span class="badge bg-light
                                                                  text-dark border">
                                                                <c:out value="${attr.attributeName}"/>:
                                                                <c:choose>
                                                                    <c:when test="${attr.textValue ne null}">
                                                                        <c:out value="${attr.textValue}"/>
                                                                    </c:when>
                                                                    <c:when test="${attr.numericValue ne null}">
                                                                        <c:out value="${attr.numericValue}"/>
                                                                    </c:when>
                                                                    <c:when test="${attr.booleanValue ne null}">
                                                                        ${attr.booleanValue ? 'Có' : 'Không'}
                                                                    </c:when>
                                                                </c:choose>
                                                            </span>
                                                        </c:forEach>
                                                    </div>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="text-muted small">
                                                        Không có
                                                    </span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>

                                        <td>
                                            <div class="fw-semibold text-danger">
                                                <fmt:formatNumber
                                                    value="${sku.price}"
                                                    pattern="#,##0"/> VNĐ
                                            </div>

                                            <c:if test="${sku.originalPrice ne null
                                                          and sku.originalPrice > 0}">
                                                  <div class="small text-muted
                                                       text-decoration-line-through">
                                                      <fmt:formatNumber
                                                          value="${sku.originalPrice}"
                                                          pattern="#,##0"/> VNĐ
                                                  </div>
                                            </c:if>
                                        </td>

                                        <td>
                                            <c:choose>
                                                <c:when test="${sku.stockQuantity > 10}">
                                                    <span class="badge bg-success-subtle text-success border">
                                                        ${sku.stockQuantity} sản phẩm
                                                    </span>
                                                </c:when>
                                                <c:when test="${sku.stockQuantity > 0}">
                                                    <span class="badge bg-warning-subtle text-warning border">
                                                        ${sku.stockQuantity} sản phẩm
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge bg-danger-subtle text-danger border">
                                                        Hết hàng
                                                    </span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>

                                        <td>
                                            <c:choose>
                                                <c:when test="${sku.active}">
                                                    <span class="badge bg-success-subtle text-success border">
                                                        Đang bán
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge bg-secondary-subtle text-secondary border">
                                                        Ngừng bán
                                                    </span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>

                                        <td>
                                            <c:choose>
                                                <c:when test="${not empty skuImages}">
                                                    <c:forEach items="${skuImages}"
                                                               var="img"
                                                               varStatus="st">
                                                        <c:if test="${st.first}">
                                                            <img src="${pageContext.request.contextPath}/${img.imageUrl}"
                                                                 alt="Ảnh SKU"
                                                                 class="img-thumbnail"
                                                                 style="width:55px;height:55px;object-fit:cover;">
                                                        </c:if>
                                                    </c:forEach>
                                                    <div class="small text-muted">
                                                        ${fn:length(skuImages)} ảnh
                                                    </div>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="text-muted small">
                                                        Chưa có
                                                    </span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>

                                        <td class="text-end pe-4">
                                            <div class="d-flex flex-wrap
                                                 justify-content-end gap-1">

                                                <button type="button"
                                                        class="btn btn-sm btn-outline-primary"
                                                        data-bs-toggle="modal"
                                                        data-bs-target="#editModal${sku.skuId}">
                                                    <i class="bi bi-pencil"></i> Sửa
                                                </button>

                                                <button type="button"
                                                        class="btn btn-sm btn-outline-secondary"
                                                        data-bs-toggle="modal"
                                                        data-bs-target="#imagesModal${sku.skuId}">
                                                    <i class="bi bi-images"></i> Ảnh
                                                </button>

                                                <c:if test="${sku.active}">
                                                    <form action="${pageContext.request.contextPath}/product-sku"
                                                          method="POST">
                                                        <input type="hidden" name="action" value="delete">
                                                        <input type="hidden" name="productId"
                                                               value="${product.productId}">
                                                        <input type="hidden" name="skuId"
                                                               value="${sku.skuId}">
                                                        <button type="submit"
                                                                class="btn btn-sm btn-outline-danger"
                                                                onclick="return confirm('Ngừng bán SKU này?');">
                                                            Ngừng bán
                                                        </button>
                                                    </form>
                                                </c:if>
                                                <form action="${pageContext.request.contextPath}/product-sku"
                                                      method="POST"
                                                      class="d-inline">

                                                    <input type="hidden"
                                                           name="action"
                                                           value="hardDelete">

                                                    <input type="hidden"
                                                           name="productId"
                                                           value="${product.productId}">

                                                    <input type="hidden"
                                                           name="skuId"
                                                           value="${sku.skuId}">

                                                    <input type="hidden"
                                                           name="deleteToken"
                                                           value="<c:out value='${sessionScope.skuHardDeleteToken}'/>">

                                                    <button type="submit"
                                                            class="btn btn-sm btn-danger"
                                                            title="Xóa vĩnh viễn SKU"
                                                            onclick="return confirm(
                                                            'XÓA VĨNH VIỄN SKU NÀY?\n\n'
                                                            + 'SKU: ${fn:escapeXml(sku.skuCode)}\n\n'
                                                            + 'Hành động không thể hoàn tác.\n'
                                                            + 'Chỉ SKU chưa có giao dịch mới được xóa.'
                                                            );">

                                                        <i class="bi bi-trash me-1"></i>
                                                        Xóa

                                                    </button>

                                                </form>
                                            </div>
                                        </td>
                                    </tr>

                                </c:forEach>

                            </c:when>

                            <c:otherwise>
                                <tr>
                                    <td colspan="7"
                                        class="text-center text-muted py-5">
                                        <i class="bi bi-box-seam fs-2"></i>
                                        <p class="mt-2 mb-0">
                                            Sản phẩm chưa có SKU.
                                        </p>
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- =================================== -->
    <!-- 5. CÁC MODAL NẰM NGOÀI TABLE     -->
    <!-- =================================== -->

    <c:forEach items="${skuList}" var="sku">

        <fmt:formatNumber value="${sku.price}"
                          pattern="#,##0"
                          var="formattedPrice"/>

        <c:set var="formattedOriginal" value=""/>
        <c:if test="${sku.originalPrice ne null}">
            <fmt:formatNumber value="${sku.originalPrice}"
                              pattern="#,##0"
                              var="formattedOriginal"/>
        </c:if>

        <!-- MODAL SỬA SKU -->
        <div class="modal fade"
             id="editModal${sku.skuId}"
             tabindex="-1"
             aria-hidden="true">

            <div class="modal-dialog modal-lg modal-dialog-scrollable">
                <div class="modal-content">

                    <div class="modal-header">
                        <h5 class="modal-title fw-bold">
                            Sửa SKU:
                            <c:out value="${sku.skuCode}"/>
                        </h5>
                        <button type="button" class="btn-close"
                                data-bs-dismiss="modal"
                                aria-label="Đóng"></button>
                    </div>

                    <form action="${pageContext.request.contextPath}/product-sku"
                          method="POST"
                          class="sku-form">

                        <input type="hidden" name="action" value="update">
                        <input type="hidden" name="productId"
                               value="${product.productId}">
                        <input type="hidden" name="skuId"
                               value="${sku.skuId}">

                        <div class="modal-body">

                            <div class="mb-3">
                                <label class="form-label fw-semibold">
                                    Mã SKU
                                </label>
                                <input type="text" name="skuCode"
                                       class="form-control" maxlength="100"
                                       value="<c:out value='${sku.skuCode}'/>"
                                       required>
                            </div>

                            <div class="row g-3 mb-4">

                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">
                                        Giá bán
                                    </label>
                                    <input type="text" name="priceStr"
                                           class="form-control money-input"
                                           inputmode="numeric"
                                           value="<c:out value='${formattedPrice}'/>"
                                           required>
                                </div>

                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">
                                        Giá niêm yết
                                    </label>
                                    <input type="text" name="originalPriceStr"
                                           class="form-control money-input"
                                           inputmode="numeric"
                                           value="<c:out value='${formattedOriginal}'/>">
                                </div>

                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">
                                        Tồn kho
                                    </label>
                                    <input type="number" name="stock"
                                           class="form-control" min="0"
                                           step="1"
                                           value="${sku.stockQuantity}"
                                           required>
                                </div>

                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">
                                        Trạng thái
                                    </label>
                                    <select name="isActive" class="form-select">
                                        <option value="true"
                                                ${sku.active ? 'selected' : ''}>
                                            Đang kinh doanh
                                        </option>
                                        <option value="false"
                                                ${not sku.active ? 'selected' : ''}>
                                            Ngừng kinh doanh
                                        </option>
                                    </select>
                                </div>
                            </div>

                            <c:if test="${not empty variantAttributes}">
                                <div class="border rounded-3 p-3">

                                    <h6 class="fw-bold mb-3">
                                        Thuộc Tính Biến Thể
                                    </h6>

                                    <div class="row g-3">

                                        <c:forEach items="${variantAttributes}"
                                                   var="config">

                                            <c:set var="savedText" value=""/>
                                            <c:set var="savedNumber" value=""/>
                                            <c:set var="savedBoolean" value=""/>
                                            <c:set var="hasBoolean" value="false"/>

                                            <c:forEach items="${sku.attributeValues}"
                                                       var="saved">
                                                <c:if test="${saved.attributeId == config.attributeId}">
                                                    <c:set var="savedText"
                                                           value="${saved.textValue}"/>
                                                    <c:set var="savedNumber"
                                                           value="${saved.numericValue}"/>

                                                    <c:if test="${saved.booleanValue ne null}">
                                                        <c:set var="hasBoolean" value="true"/>
                                                        <c:set var="savedBoolean"
                                                               value="${saved.booleanValue}"/>
                                                    </c:if>
                                                </c:if>
                                            </c:forEach>

                                            <div class="col-md-6">
                                                <label class="form-label fw-semibold">
                                                    <c:out value="${config.attributeName}"/>
                                                    <c:if test="${config.required}">
                                                        <span class="text-danger">*</span>
                                                    </c:if>
                                                </label>

                                                <input type="hidden"
                                                       name="attributeIds"
                                                       value="${config.attributeId}">

                                                <c:choose>
                                                    <c:when test="${config.dataType eq 'BOOLEAN'}">
                                                        <select name="attributeValues"
                                                                class="form-select"
                                                                ${config.required ? 'required' : ''}>
                                                            <option value="">-- Chọn --</option>
                                                            <option value="true"
                                                                    ${hasBoolean and savedBoolean ? 'selected' : ''}>
                                                                Có
                                                            </option>
                                                            <option value="false"
                                                                    ${hasBoolean and not savedBoolean ? 'selected' : ''}>
                                                                Không
                                                            </option>
                                                        </select>
                                                    </c:when>

                                                    <c:when test="${config.dataType eq 'NUMBER'}">
                                                        <input type="number"
                                                               name="attributeValues"
                                                               class="form-control"
                                                               step="0.0001"
                                                               value="<c:out value='${savedNumber}'/>"
                                                               ${config.required ? 'required' : ''}>
                                                    </c:when>

                                                    <c:otherwise>
                                                        <input type="text"
                                                               name="attributeValues"
                                                               class="form-control"
                                                               maxlength="255"
                                                               value="<c:out value='${savedText}'/>"
                                                               ${config.required ? 'required' : ''}>
                                                    </c:otherwise>
                                                </c:choose>

                                                <c:if test="${not empty config.unit}">
                                                    <div class="form-text">
                                                        Đơn vị:
                                                        <c:out value="${config.unit}"/>
                                                    </div>
                                                </c:if>
                                            </div>

                                        </c:forEach>
                                    </div>
                                </div>
                            </c:if>

                        </div>

                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary"
                                    data-bs-dismiss="modal">
                                Hủy
                            </button>
                            <button type="submit" class="btn btn-primary">
                                Lưu thay đổi
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- =================================== -->
        <!-- MODAL QUẢN LÝ ẢNH SKU             -->
        <!-- =================================== -->

        <c:set var="skuImages"
               value="${skuImagesBySkuId[sku.skuId]}"/>

        <div class="modal fade"
             id="imagesModal${sku.skuId}"
             tabindex="-1"
             aria-hidden="true">

            <div class="modal-dialog modal-xl modal-dialog-scrollable">
                <div class="modal-content">

                    <div class="modal-header">
                        <div>
                            <h5 class="modal-title fw-bold">
                                Quản Lý Ảnh SKU
                            </h5>
                            <small class="text-muted">
                                <c:out value="${sku.skuCode}"/>
                            </small>
                        </div>
                        <button type="button" class="btn-close"
                                data-bs-dismiss="modal"
                                aria-label="Đóng"></button>
                    </div>

                    <div class="modal-body">

                        <!-- UPLOAD -->
                        <form action="${pageContext.request.contextPath}/sku-images"
                              method="POST"
                              enctype="multipart/form-data"
                              class="sku-image-upload-form border rounded-3 p-3 mb-4">

                            <input type="hidden" name="action" value="upload">
                            <input type="hidden" name="productId"
                                   value="${product.productId}">
                            <input type="hidden" name="skuId"
                                   value="${sku.skuId}">

                            <h6 class="fw-bold mb-3">
                                Upload Ảnh Mới
                            </h6>

                            <div class="row g-3 align-items-end">
                                <div class="col-md-9">
                                    <input type="file" name="skuImages"
                                           class="form-control sku-image-input"
                                           accept="image/jpeg,image/png,image/webp"
                                           multiple required>
                                    <div class="form-text">
                                        Tối đa 10 ảnh/lần, mỗi ảnh tối đa 10MB.
                                    </div>
                                </div>

                                <div class="col-md-3">
                                    <button type="submit"
                                            class="btn btn-primary w-100">
                                        Upload
                                    </button>
                                </div>
                            </div>

                            <div class="sku-upload-preview
                                 d-flex flex-wrap gap-2 mt-3"></div>
                        </form>

                        <h6 class="fw-bold mb-3">
                            Ảnh Hiện Có (${fn:length(skuImages)})
                        </h6>

                        <c:choose>
                            <c:when test="${not empty skuImages}">

                                <div class="alert alert-info small">
                                    Sử dụng nút lên/xuống để thay đổi thứ tự.
                                    Sau đó nhấn <strong>Lưu thứ tự</strong>.
                                </div>

                                <div class="sku-image-order-list"
                                     data-sku-id="${sku.skuId}">

                                    <c:forEach items="${skuImages}"
                                               var="img"
                                               varStatus="st">

                                        <div class="sku-image-item
                                             border rounded-3 p-3 mb-2"
                                             data-image-id="${img.imageId}">

                                            <div class="d-flex flex-wrap
                                                 align-items-center gap-3">

                                                <span class="badge bg-light
                                                      text-dark border
                                                      sku-image-position">
                                                    ${st.count}
                                                </span>

                                                <img src="${pageContext.request.contextPath}/${img.imageUrl}"
                                                     alt="Ảnh SKU"
                                                     class="img-thumbnail"
                                                     style="width:100px;height:100px;object-fit:cover;">

                                                <div class="flex-grow-1">
                                                    <div class="fw-semibold">
                                                        Image #${img.imageId}
                                                    </div>

                                                    <c:if test="${img.primary}">
                                                        <span class="badge bg-success-subtle
                                                              text-success border">
                                                            <i class="bi bi-star-fill me-1"></i>
                                                            Ảnh chính
                                                        </span>
                                                    </c:if>

                                                    <div class="small text-muted
                                                         text-break mt-1">
                                                        <c:out value="${img.imageUrl}"/>
                                                    </div>
                                                </div>

                                                <div class="btn-group">
                                                    <button type="button"
                                                            class="btn btn-outline-secondary move-image-up"
                                                            title="Lên">
                                                        <i class="bi bi-arrow-up"></i>
                                                    </button>
                                                    <button type="button"
                                                            class="btn btn-outline-secondary move-image-down"
                                                            title="Xuống">
                                                        <i class="bi bi-arrow-down"></i>
                                                    </button>
                                                </div>

                                                <div class="d-flex flex-wrap gap-2">

                                                    <c:if test="${not img.primary}">
                                                        <form action="${pageContext.request.contextPath}/sku-images"
                                                              method="POST">
                                                            <input type="hidden" name="action"
                                                                   value="setPrimary">
                                                            <input type="hidden" name="productId"
                                                                   value="${product.productId}">
                                                            <input type="hidden" name="skuId"
                                                                   value="${sku.skuId}">
                                                            <input type="hidden" name="imageId"
                                                                   value="${img.imageId}">
                                                            <button type="submit"
                                                                    class="btn btn-sm btn-outline-primary">
                                                                Đặt ảnh chính
                                                            </button>
                                                        </form>
                                                    </c:if>

                                                    <form action="${pageContext.request.contextPath}/sku-images"
                                                          method="POST">
                                                        <input type="hidden" name="action"
                                                               value="delete">
                                                        <input type="hidden" name="productId"
                                                               value="${product.productId}">
                                                        <input type="hidden" name="skuId"
                                                               value="${sku.skuId}">
                                                        <input type="hidden" name="imageId"
                                                               value="${img.imageId}">
                                                        <button type="submit"
                                                                class="btn btn-sm btn-outline-danger"
                                                                onclick="return confirm('Gỡ ảnh này?');">
                                                            Gỡ ảnh
                                                        </button>
                                                    </form>

                                                </div>
                                            </div>
                                        </div>

                                    </c:forEach>
                                </div>

                                <!-- LƯU THỨ TỰ -->
                                <form action="${pageContext.request.contextPath}/sku-images"
                                      method="POST"
                                      class="sku-reorder-form mt-3"
                                      data-sku-id="${sku.skuId}">

                                    <input type="hidden" name="action"
                                           value="reorder">
                                    <input type="hidden" name="productId"
                                           value="${product.productId}">
                                    <input type="hidden" name="skuId"
                                           value="${sku.skuId}">

                                    <div class="reorder-hidden-inputs"></div>

                                    <div class="text-end">
                                        <button type="submit"
                                                class="btn btn-outline-primary">
                                            <i class="bi bi-save me-1"></i>
                                            Lưu thứ tự
                                        </button>
                                    </div>
                                </form>

                            </c:when>

                            <c:otherwise>
                                <div class="text-center text-muted
                                     bg-light rounded-3 py-5">
                                    <i class="bi bi-image fs-2"></i>
                                    <p class="mb-0 mt-2">
                                        SKU chưa có ảnh riêng.
                                    </p>
                                </div>
                            </c:otherwise>
                        </c:choose>

                    </div>

                    <div class="modal-footer">
                        <button type="button"
                                class="btn btn-secondary"
                                data-bs-dismiss="modal">
                            Đóng
                        </button>
                    </div>

                </div>
            </div>
        </div>

    </c:forEach>

</div>

<script>
    document.addEventListener("DOMContentLoaded", function () {

        // ========================================
        // 1. ĐỊNH DẠNG TIỀN VNĐ
        // ========================================

        function formatMoney(input) {
            const digits = input.value.replace(/\D/g, "");

            input.value = digits === ""
                    ? ""
                    : digits.replace(
                            /\B(?=(\d{3})+(?!\d))/g, "."
                            );
        }

        document.querySelectorAll(".money-input").forEach(
                function (input) {
                    formatMoney(input);

                    input.addEventListener("input", function () {
                        formatMoney(this);
                    });
                }
        );

        // ========================================
        // 2. PREVIEW ẢNH UPLOAD
        // ========================================

        document.querySelectorAll(".sku-image-upload-form")
                .forEach(function (form) {

                    const input = form.querySelector(".sku-image-input");
                    const preview = form.querySelector(".sku-upload-preview");

                    let objectUrls = [];

                    function clearPreview() {
                        objectUrls.forEach(function (url) {
                            URL.revokeObjectURL(url);
                        });

                        objectUrls = [];
                        preview.replaceChildren();
                    }

                    input.addEventListener("change", function () {
                        clearPreview();

                        const files = Array.from(input.files);

                        if (files.length > 10) {
                            alert("Chỉ được upload tối đa 10 ảnh/lần.");
                            input.value = "";
                            return;
                        }

                        const allowed = [
                            "image/jpeg", "image/png", "image/webp"
                        ];

                        for (const file of files) {
                            if (!allowed.includes(file.type)
                                    || file.size > 10 * 1024 * 1024) {

                                alert("Ảnh không hợp lệ hoặc vượt 10MB.");
                                input.value = "";
                                clearPreview();
                                return;
                            }

                            const url = URL.createObjectURL(file);
                            objectUrls.push(url);

                            const image = document.createElement("img");
                            image.src = url;
                            image.alt = "Xem trước ảnh SKU";
                            image.className = "img-thumbnail";
                            image.style.width = "85px";
                            image.style.height = "85px";
                            image.style.objectFit = "cover";

                            preview.appendChild(image);
                        }
                    });

                    form.addEventListener("submit", function (event) {
                        const files = Array.from(input.files);

                        if (!files.length || files.length > 10
                                || files.some(function (file) {
                                    return file.size > 10 * 1024 * 1024
                                            || !["image/jpeg",
                                                "image/png",
                                                "image/webp"].includes(file.type);
                                })) {

                            event.preventDefault();
                            alert("Danh sách ảnh upload không hợp lệ.");
                            return;
                        }

                        if (form.checkValidity()) {
                            const button = form.querySelector(
                                    'button[type="submit"]'
                                    );
                            button.disabled = true;
                            button.textContent = "Đang upload...";
                        }
                    });

                    window.addEventListener("pagehide", clearPreview);
                });

        // ========================================
        // 3. SẮP XẾP ẢNH
        // ========================================

        function refreshPositions(list) {
            const items = list.querySelectorAll(".sku-image-item");

            items.forEach(function (item, index) {

                item.querySelector(".sku-image-position")
                        .textContent = index + 1;

                item.querySelector(".move-image-up")
                        .disabled = index === 0;

                item.querySelector(".move-image-down")
                        .disabled = index === items.length - 1;
            });
        }

        document.querySelectorAll(".sku-image-order-list")
                .forEach(function (list) {

                    refreshPositions(list);

                    list.addEventListener("click", function (event) {

                        const up = event.target.closest(".move-image-up");
                        const down = event.target.closest(".move-image-down");

                        if (!up && !down)
                            return;

                        const item = event.target.closest(".sku-image-item");

                        if (up && item.previousElementSibling) {
                            list.insertBefore(
                                    item, item.previousElementSibling
                                    );
                        }

                        if (down && item.nextElementSibling) {
                            list.insertBefore(
                                    item.nextElementSibling, item
                                    );
                        }

                        refreshPositions(list);
                    });
                });

        // ========================================
        // 4. GỬI THỨ TỰ ẢNH VỀ SERVLET
        // ========================================

        document.querySelectorAll(".sku-reorder-form")
                .forEach(function (form) {

                    form.addEventListener("submit", function (event) {

                        const modal = document.getElementById(
                                "imagesModal" + form.dataset.skuId
                                );

                        const list = modal.querySelector(
                                ".sku-image-order-list"
                                );

                        const container = form.querySelector(
                                ".reorder-hidden-inputs"
                                );

                        if (!list) {
                            event.preventDefault();
                            return;
                        }

                        container.replaceChildren();

                        list.querySelectorAll(".sku-image-item")
                                .forEach(function (item) {

                                    const input = document.createElement("input");
                                    input.type = "hidden";
                                    input.name = "imageIds";
                                    input.value = item.dataset.imageId;

                                    container.appendChild(input);
                                });
                    });
                });

        // ========================================
        // 5. CHẶN SUBMIT SKU TRÙNG
        // ========================================

        document.querySelectorAll(".sku-form")
                .forEach(function (form) {

                    form.addEventListener("submit", function () {

                        if (!form.checkValidity())
                            return;

                        const button = form.querySelector(
                                'button[type="submit"]'
                                );

                        if (button) {
                            button.disabled = true;
                            button.textContent = "Đang lưu...";
                        }
                    });
                });
    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>
