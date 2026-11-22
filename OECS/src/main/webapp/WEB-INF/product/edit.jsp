
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="row justify-content-center">
    <div class="col-12 col-lg-9 col-xl-8">

        <!-- QUAY LẠI -->
        <div class="mb-3">
            <a href="${pageContext.request.contextPath}/product?view=list"
               class="text-decoration-none text-muted fw-medium">
                <i class="bi bi-arrow-left me-1"></i>
                Quay lại danh sách
            </a>
        </div>

        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-body p-4 p-md-5">

                <!-- TIÊU ĐỀ -->
                <div class="d-flex align-items-center mb-4 pb-3 border-bottom">

                    <div class="bg-primary bg-opacity-10 text-primary rounded
                         d-flex align-items-center justify-content-center me-3"
                         style="width:48px;height:48px;">

                        <i class="bi bi-pencil-square fs-4"></i>
                    </div>

                    <div>
                        <h4 class="fw-bold mb-0">
                            Chỉnh Sửa Sản Phẩm
                        </h4>

                        <span class="text-muted">
                            Cập nhật thông tin sản phẩm OECS V2
                        </span>
                    </div>
                </div>

                <!-- THÔNG BÁO LỖI -->
                <c:if test="${not empty sessionScope.errorMsg}">
                    <div class="alert alert-danger">
                        <i class="bi bi-exclamation-triangle me-2"></i>
                        <c:out value="${sessionScope.errorMsg}"/>
                    </div>
                    <c:remove var="errorMsg" scope="session"/>
                </c:if>

                <c:if test="${param.error == 'true'}">
                    <div class="alert alert-danger">
                        Không thể cập nhật sản phẩm.
                        Vui lòng kiểm tra lại thông tin.
                    </div>
                </c:if>

                <!-- TRẠNG THÁI -->
                <div class="mb-4">
                    <c:choose>
                        <c:when test="${product.active}">
                            <span class="badge bg-success-subtle text-success border">
                                <i class="bi bi-check-circle me-1"></i>
                                Đang kinh doanh
                            </span>
                        </c:when>
                        <c:otherwise>
                            <span class="badge bg-secondary-subtle text-secondary border">
                                <i class="bi bi-pause-circle me-1"></i>
                                Đã ngừng kinh doanh
                            </span>
                        </c:otherwise>
                    </c:choose>

                    <span class="text-muted small ms-2">
                        Mã sản phẩm: #<c:out value="${product.productId}"/>
                    </span>
                </div>

                <!-- FORM -->
                <form id="editProductForm"
                      action="${pageContext.request.contextPath}/product"
                      method="POST"
                      enctype="multipart/form-data">

                    <input type="hidden"
                           name="action"
                           value="edit">

                    <input type="hidden"
                           name="id"
                           value="${product.productId}">

                    <!-- =========================== -->
                    <!-- 1. DANH MỤC                -->
                    <!-- =========================== -->

                    <div class="mb-4">

                        <label class="form-label fw-semibold">
                            Danh Mục Sản Phẩm
                        </label>

                        <!-- Giữ categoryId hiện tại khi POST -->
                        <input type="hidden"
                               name="categoryId"
                               value="${product.categoryId}">

                        <select class="form-select form-select-lg"
                                disabled>

                            <c:forEach items="${categoryList}"
                                       var="category">

                                <option value="${category.categoryId}"
                                        ${category.categoryId == product.categoryId
                                          ? 'selected' : ''}>

                                    <c:out value="${category.categoryName}"/>

                                </option>

                            </c:forEach>

                        </select>

                        <div class="form-text">
                            Danh mục được giữ nguyên để bảo toàn
                            cấu hình thông số và các phiên bản SKU.
                        </div>
                    </div>

                    <!-- =========================== -->
                    <!-- 2. TÊN SẢN PHẨM            -->
                    <!-- =========================== -->

                    <div class="mb-4">

                        <label for="productName"
                               class="form-label fw-semibold">

                            Tên Sản Phẩm
                            <span class="text-danger">*</span>
                        </label>

                        <input type="text"
                               id="productName"
                               name="name"
                               class="form-control form-control-lg"
                               maxlength="255"
                               value="<c:out value='${product.productName}'/>"
                               required>
                    </div>

                    <!-- =========================== -->
                    <!-- 3. MÃ MODEL                -->
                    <!-- =========================== -->

                    <div class="mb-4">

                        <label for="modelCode"
                               class="form-label fw-semibold">
                            Mã Model
                        </label>

                        <input type="text"
                               id="modelCode"
                               name="modelCode"
                               class="form-control"
                               maxlength="100"
                               value="<c:out value='${product.modelCode}'/>"
                               placeholder="VD: A3101">

                        <div class="form-text">
                            Mã model chung, không phải mã SKU.
                        </div>
                    </div>

                    <!-- =========================== -->
                    <!-- 4. THƯƠNG HIỆU             -->
                    <!-- =========================== -->

                    <div class="mb-4">

                        <label for="brandId"
                               class="form-label fw-semibold">

                            Thương Hiệu
                            <span class="text-danger">*</span>
                        </label>

                        <select name="brandId"
                                id="brandId"
                                class="form-select form-select-lg"
                                required>

                            <c:forEach items="${brandList}"
                                       var="brand">

                                <option value="${brand.brandId}"
                                        ${brand.brandId == product.brandId
                                          ? 'selected' : ''}>

                                    <c:out value="${brand.brandName}"/>

                                </option>

                            </c:forEach>

                        </select>
                    </div>

                    <!-- =========================== -->
                    <!-- 5. ẢNH ĐẠI DIỆN            -->
                    <!-- =========================== -->

                    <div class="mb-4">

                        <label for="imageFile"
                               class="form-label fw-semibold">
                            Hình Ảnh Đại Diện
                        </label>

                        <c:if test="${not empty product.imageUrl}">

                            <div class="mb-3">

                                <img src="${pageContext.request.contextPath}/${product.imageUrl}"
                                     alt="Ảnh đại diện hiện tại"
                                     class="img-thumbnail"
                                     style="width:150px;height:150px;object-fit:contain;">

                                <div class="form-text">
                                    Ảnh đại diện hiện tại
                                </div>

                            </div>

                        </c:if>

                        <input type="file"
                               id="imageFile"
                               name="imageFile"
                               class="form-control"
                               accept="image/jpeg,image/png,image/webp">

                        <div class="form-text">
                            Để trống nếu không thay đổi ảnh.
                            Dung lượng tối đa 10MB.
                        </div>

                        <div id="imagePreview"
                             class="mt-3 d-none">

                            <img id="previewImage"
                                 alt="Ảnh đại diện mới"
                                 class="img-thumbnail"
                                 style="max-width:180px;max-height:180px;object-fit:contain;">

                            <div class="form-text">
                                Ảnh mới được chọn
                            </div>

                        </div>
                    </div>

                    <!-- =========================== -->
                    <!-- 6. GALLERY                 -->
                    <!-- =========================== -->

                    <div class="mb-4 p-3 border rounded-3 bg-light">

                        <h6 class="fw-bold text-primary mb-3">
                            <i class="bi bi-images me-2"></i>
                            Hình Ảnh Phụ
                        </h6>

                        <div class="d-flex flex-wrap gap-3 mb-3">

                            <!-- Chỉ chỉnh sửa ảnh chung.
                                 Ảnh SKU xử lý riêng. -->

                            <c:forEach items="${product.galleryImages}"
                                       var="img">

                                <c:if test="${empty img.skuId}">

                                    <div class="border rounded-3
                                         p-2 bg-white text-center"
                                         style="width:130px;">

                                        <img src="${pageContext.request.contextPath}/${img.imageUrl}"
                                             alt="<c:out value='${img.altText}'/>"
                                             class="img-thumbnail border-0 mb-2"
                                             style="width:100%;height:95px;object-fit:cover;">

                                        <c:if test="${img.primary}">
                                            <div class="mb-2">
                                                <span class="badge bg-primary-subtle text-primary">
                                                    Ảnh chính
                                                </span>
                                            </div>
                                        </c:if>

                                        <div class="form-check">

                                            <input type="checkbox"
                                                   class="form-check-input"
                                                   name="deleteImageIds"
                                                   value="${img.imageId}"
                                                   id="deleteImage_${img.imageId}">

                                            <label class="form-check-label
                                                   text-danger small"
                                                   for="deleteImage_${img.imageId}">
                                                Gỡ ảnh
                                            </label>

                                        </div>

                                    </div>

                                </c:if>

                            </c:forEach>

                        </div>

                        <label for="galleryFiles"
                               class="form-label fw-semibold">
                            Tải Thêm Hình Ảnh Phụ
                        </label>

                        <input type="file"
                               name="galleryFiles"
                               id="galleryFiles"
                               class="form-control"
                               accept="image/jpeg,image/png,image/webp"
                               multiple>

                        <div class="form-text">
                            Các ảnh cũ không được chọn gỡ
                            sẽ tiếp tục được giữ lại.
                        </div>

                        <div id="galleryPreview"
                             class="d-flex flex-wrap gap-2 mt-3">
                        </div>

                    </div>

                    <!-- =========================== -->
                    <!-- 7. THÔNG SỐ KỸ THUẬT       -->
                    <!-- =========================== -->

                    <div class="mb-4 border rounded-3 p-3 p-md-4">

                        <div class="mb-3">

                            <h6 class="fw-bold mb-1">
                                <i class="bi bi-sliders me-2 text-primary"></i>
                                Thông Số Kỹ Thuật
                            </h6>

                            <small class="text-muted">
                                Các thuộc tính được cấu hình
                                theo danh mục hiện tại.
                            </small>

                        </div>

                        <c:choose>

                            <c:when test="${empty specificationAttributes}">

                                <div class="alert alert-light border mb-0">
                                    Danh mục này chưa có thông số
                                    kỹ thuật được cấu hình.
                                </div>

                            </c:when>

                            <c:otherwise>

                                <c:set var="currentGroup" value=""/>

                                <c:forEach items="${specificationAttributes}"
                                           var="config">

                                    <!-- Lấy giá trị đã lưu -->
                                    <c:set var="savedValue" value=""/>

                                    <c:forEach items="${productSpecs}"
                                               var="spec">

                                        <c:if test="${spec.attributeId == config.attributeId}">

                                            <c:set var="savedValue"
                                                   value="${spec.value}"/>

                                        </c:if>

                                    </c:forEach>

                                    <!-- Tên nhóm thông số -->
                                    <c:if test="${currentGroup ne config.groupName}">

                                        <div class="mt-3 mb-3 pb-2 border-bottom">

                                            <h6 class="fw-semibold text-primary mb-0">
                                                <c:out value="${config.groupName}"/>
                                            </h6>

                                        </div>

                                        <c:set var="currentGroup"
                                               value="${config.groupName}"/>

                                    </c:if>

                                    <div class="row align-items-center mb-3">

                                        <div class="col-md-4 mb-2 mb-md-0">

                                            <label class="form-label fw-medium mb-0">

                                                <c:out value="${config.attributeName}"/>

                                                <c:if test="${config.required}">
                                                    <span class="text-danger">*</span>
                                                </c:if>

                                            </label>

                                        </div>

                                        <div class="col-md-8">

                                            <input type="hidden"
                                                   name="attributeIds"
                                                   value="${config.attributeId}">

                                            <input type="text"
                                                   name="specValues"
                                                   class="form-control"
                                                   maxlength="255"
                                                   value="<c:out value='${savedValue}'/>"
                                                   placeholder="Nhập giá trị thông số"
                                                   ${config.required ? 'required' : ''}>

                                            <c:if test="${not empty config.unit}">

                                                <div class="form-text">
                                                    Đơn vị:
                                                    <c:out value="${config.unit}"/>
                                                </div>

                                            </c:if>

                                        </div>

                                    </div>

                                </c:forEach>

                            </c:otherwise>

                        </c:choose>

                    </div>

                    <!-- =========================== -->
                    <!-- 8. THUỘC TÍNH SKU          -->
                    <!-- =========================== -->

                    <div class="mb-4 p-3 border rounded-3 bg-light">

                        <h6 class="fw-bold mb-2">
                            <i class="bi bi-tags me-2 text-primary"></i>
                            Phiên Bản SKU
                        </h6>

                        <c:choose>

                            <c:when test="${not empty variantAttributes}">

                                <div class="d-flex flex-wrap gap-2 mb-3">

                                    <c:forEach items="${variantAttributes}"
                                               var="config">

                                        <span class="badge bg-white text-dark border p-2">
                                            <c:out value="${config.attributeName}"/>
                                        </span>

                                    </c:forEach>

                                </div>

                            </c:when>

                            <c:otherwise>

                                <p class="small text-muted">
                                    Danh mục chưa cấu hình
                                    thuộc tính biến thể.
                                </p>

                            </c:otherwise>

                        </c:choose>

                        <p class="small text-muted mb-3">
                            Giá bán, tồn kho, màu sắc, dung lượng
                            và các thông số riêng của SKU được
                            quản lý trong trang phiên bản sản phẩm.
                        </p>

                        <a href="${pageContext.request.contextPath}/product-sku?productId=${product.productId}"
                           class="btn btn-outline-primary">

                            <i class="bi bi-tags me-1"></i>
                            Quản Lý SKU

                        </a>

                    </div>

                    <!-- =========================== -->
                    <!-- 9. MÔ TẢ                   -->
                    <!-- =========================== -->

                    <div class="mb-4">

                        <label for="description"
                               class="form-label fw-semibold">
                            Mô Tả Sản Phẩm
                        </label>

                        <textarea name="description"
                                  id="description"
                                  class="form-control"
                                  rows="5"
                                  placeholder="Nhập mô tả sản phẩm..."><c:out value="${product.description}"/></textarea>

                    </div>

                    <!-- =========================== -->
                    <!-- 10. NÚT LƯU                -->
                    <!-- =========================== -->

                    <div class="d-flex flex-wrap gap-2 pt-3 mt-4 border-top">

                        <button type="submit"
                                id="saveProductBtn"
                                class="btn btn-primary btn-lg px-4">

                            <i class="bi bi-check-lg me-1"></i>
                            Lưu Thay Đổi

                        </button>

                        <a href="${pageContext.request.contextPath}/product?view=list"
                           class="btn btn-light btn-lg px-4 border">
                            Hủy
                        </a>

                    </div>

                </form>

            </div>
        </div>
    </div>
</div>

<script>
    document.addEventListener("DOMContentLoaded", function () {

        const form =
                document.getElementById("editProductForm");

        const imageInput =
                document.getElementById("imageFile");

        const galleryInput =
                document.getElementById("galleryFiles");

        const imagePreview =
                document.getElementById("imagePreview");

        const previewImage =
                document.getElementById("previewImage");

        const galleryPreview =
                document.getElementById("galleryPreview");

        // ========================================
        // 1. PREVIEW ẢNH ĐẠI DIỆN MỚI
        // ========================================

        let previewUrl = null;

        imageInput.addEventListener("change", function () {

            if (previewUrl) {
                URL.revokeObjectURL(previewUrl);
                previewUrl = null;
            }

            const file = this.files[0];

            if (!file) {

                imagePreview.classList.add("d-none");
                previewImage.removeAttribute("src");
                return;
            }

            previewUrl = URL.createObjectURL(file);

            previewImage.src = previewUrl;
            imagePreview.classList.remove("d-none");
        });

        // ========================================
        // 2. PREVIEW ẢNH GALLERY MỚI
        // ========================================

        let galleryUrls = [];

        galleryInput.addEventListener("change", function () {

            galleryUrls.forEach(function (url) {
                URL.revokeObjectURL(url);
            });

            galleryUrls = [];
            galleryPreview.replaceChildren();

            Array.from(this.files).forEach(function (file) {

                const url = URL.createObjectURL(file);

                galleryUrls.push(url);

                const img = document.createElement("img");

                img.src = url;
                img.alt = "Ảnh gallery mới";
                img.className = "img-thumbnail";

                img.style.width = "90px";
                img.style.height = "90px";
                img.style.objectFit = "cover";

                galleryPreview.appendChild(img);
            });
        });

        // ========================================
        // 3. XÁC NHẬN GỠ ẢNH GALLERY
        // ========================================

        form.addEventListener("submit", function (event) {

            const selectedImages =
                    form.querySelectorAll(
                            'input[name="deleteImageIds"]:checked'
                            );

            if (selectedImages.length > 0) {

                const confirmed = confirm(
                        "Bạn đã chọn gỡ "
                        + selectedImages.length
                        + " ảnh gallery. Tiếp tục lưu thay đổi?"
                        );

                if (!confirmed) {
                    event.preventDefault();
                    return;
                }
            }

            if (form.checkValidity()) {

                const saveButton =
                        document.getElementById("saveProductBtn");

                saveButton.disabled = true;
                saveButton.textContent = "Đang lưu thay đổi...";
            }
        });

        // ========================================
        // 4. GIẢI PHÓNG PREVIEW URL
        // ========================================

        window.addEventListener("pagehide", function () {

            if (previewUrl) {
                URL.revokeObjectURL(previewUrl);
            }

            galleryUrls.forEach(function (url) {
                URL.revokeObjectURL(url);
            });
        });
    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>
