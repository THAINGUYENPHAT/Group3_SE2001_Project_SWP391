
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<!-- Quill Editor CSS -->
<link rel="stylesheet"
      href="https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.snow.css">

<style>
    #descriptionEditor {
        background: #fff;
        border-radius: 8px;
    }

    #descriptionEditor .ql-editor {
        min-height: 240px;
        font-size: 15px;
        line-height: 1.7;
    }

    .ql-toolbar.ql-snow {
        border-radius: 8px 8px 0 0;
    }

    .ql-container.ql-snow {
        border-radius: 0 0 8px 8px;
    }
</style>

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
                        <i class="bi bi-box-seam fs-4"></i>
                    </div>

                    <div>
                        <h4 class="fw-bold mb-0">
                            Thêm Sản Phẩm Mới
                        </h4>
                        <span class="text-muted">
                            Quản lý sản phẩm theo OECS V2
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
                        Không thể thêm sản phẩm.
                        Vui lòng kiểm tra lại thông tin.
                    </div>
                </c:if>

                <!-- HƯỚNG DẪN -->
                <div class="alert alert-info border-0 mb-4">
                    <i class="bi bi-info-circle me-2"></i>
                    <strong>Bước 1:</strong> Chọn danh mục sản phẩm
                    để tải bộ thông số kỹ thuật tương ứng.
                    Sau đó nhập thông tin và lưu sản phẩm.
                    Các phiên bản SKU sẽ được quản lý riêng.
                </div>

                <!-- FORM -->
                <form id="createProductForm"
                      action="${pageContext.request.contextPath}/product"
                      method="POST"
                      enctype="multipart/form-data">

                    <input type="hidden"
                           name="action"
                           value="create">

                    <!-- =========================== -->
                    <!-- 1. DANH MỤC                -->
                    <!-- =========================== -->

                    <div class="mb-4">
                        <label for="categoryId"
                               class="form-label fw-semibold">
                            Danh Mục
                            <span class="text-danger">*</span>
                        </label>

                        <select name="categoryId"
                                id="categoryId"
                                class="form-select form-select-lg"
                                required>

                            <option value="">
                                -- Chọn danh mục --
                            </option>

                            <c:forEach items="${categoryList}"
                                       var="category">

                                <option value="${category.categoryId}"
                                        ${selectedCategoryId == category.categoryId
                                          ? 'selected' : ''}>

                                    <c:out value="${category.categoryName}"/>

                                </option>

                            </c:forEach>
                        </select>

                        <div class="form-text">
                            Khi thay đổi danh mục, trang sẽ tải lại
                            danh sách thông số kỹ thuật.
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
                               placeholder="VD: iPhone 15 Pro"
                               value="<c:out value='${param.name}'/>"
                               required>
                    </div>

                    <!-- =========================== -->
                    <!-- 3. MODEL CODE              -->
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
                               placeholder="VD: A3101">

                        <div class="form-text">
                            Mã model chung của sản phẩm,
                            khác với mã SKU của từng phiên bản.
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

                            <option value="">
                                -- Chọn thương hiệu --
                            </option>

                            <c:forEach items="${brandList}"
                                       var="brand">

                                <option value="${brand.brandId}"
                                        ${param.brandId == brand.brandId
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
                            <span class="text-danger">*</span>
                        </label>

                        <input type="file"
                               id="imageFile"
                               name="imageFile"
                               class="form-control"
                               accept="image/jpeg,image/png,image/webp"
                               required>

                        <div class="form-text">
                            JPG, PNG hoặc WEBP. Tối đa 10MB.
                        </div>

                        <div id="imagePreview"
                             class="mt-3 d-none">
                            <img id="previewImage"
                                 alt="Xem trước ảnh đại diện"
                                 class="img-thumbnail"
                                 style="max-width:180px;max-height:180px;object-fit:contain;">
                        </div>
                    </div>

                    <!-- =========================== -->
                    <!-- 6. ẢNH PHỤ                 -->
                    <!-- =========================== -->

                    <div class="mb-4 p-3 bg-light border rounded-3">
                        <label for="galleryFiles"
                               class="form-label fw-semibold text-primary">
                            Hình Ảnh Phụ (Gallery)
                        </label>

                        <input type="file"
                               id="galleryFiles"
                               name="galleryFiles"
                               class="form-control"
                               accept="image/jpeg,image/png,image/webp"
                               multiple>

                        <div class="form-text">
                            Có thể chọn nhiều ảnh để hiển thị
                            trong trang chi tiết sản phẩm.
                        </div>

                        <div id="galleryPreview"
                             class="d-flex flex-wrap gap-2 mt-3">
                        </div>
                    </div>

                    <!-- =========================== -->
                    <!-- 7. THÔNG SỐ KỸ THUẬT       -->
                    <!-- =========================== -->

                    <div class="mb-4 border rounded-3 p-3 p-md-4">

                        <div class="d-flex align-items-center
                             justify-content-between mb-3">

                            <div>
                                <h6 class="fw-bold mb-1">
                                    <i class="bi bi-sliders me-2 text-primary"></i>
                                    Thông Số Kỹ Thuật
                                </h6>

                                <small class="text-muted">
                                    Cấu hình theo danh mục sản phẩm
                                </small>
                            </div>

                            <span class="badge bg-primary-subtle text-primary">
                                Tự động
                            </span>
                        </div>

                        <c:choose>

                            <%-- Chưa chọn danh mục --%>
                            <c:when test="${empty selectedCategoryId}">

                                <div class="text-center py-4
                                     bg-light rounded-3 text-muted">
                                    <i class="bi bi-list-check fs-2"></i>

                                    <p class="mb-0 mt-2">
                                        Vui lòng chọn danh mục trước
                                        để xem các thông số kỹ thuật.
                                    </p>
                                </div>

                            </c:when>

                            <%-- Danh mục không có thông số --%>
                            <c:when test="${empty specificationAttributes}">

                                <div class="alert alert-light border mb-0">
                                    Danh mục này chưa được cấu hình
                                    thông số kỹ thuật chung.
                                </div>

                            </c:when>

                            <%-- Hiển thị thông số theo cấu hình --%>
                            <c:otherwise>

                                <c:set var="currentGroup" value=""/>

                                <c:forEach items="${specificationAttributes}"
                                           var="config">

                                    <%-- Tiêu đề nhóm thông số --%>
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
                    <!-- 8. THÔNG TIN BIẾN THỂ      -->
                    <!-- =========================== -->

                    <c:if test="${not empty selectedCategoryId}">

                        <div class="mb-4 p-3 border rounded-3 bg-light">

                            <h6 class="fw-bold mb-2">
                                <i class="bi bi-tags me-2 text-primary"></i>
                                Thuộc Tính Biến Thể SKU
                            </h6>

                            <c:choose>

                                <c:when test="${not empty variantAttributes}">

                                    <p class="text-muted small mb-2">
                                        Danh mục này hỗ trợ các thuộc tính
                                        biến thể sau:
                                    </p>

                                    <div class="d-flex flex-wrap gap-2">

                                        <c:forEach items="${variantAttributes}"
                                                   var="config">

                                            <span class="badge bg-white text-dark border p-2">
                                                <c:out value="${config.attributeName}"/>
                                            </span>

                                        </c:forEach>

                                    </div>

                                </c:when>

                                <c:otherwise>

                                    <p class="text-muted small mb-0">
                                        Danh mục này chưa có thuộc tính
                                        biến thể được cấu hình.
                                    </p>

                                </c:otherwise>

                            </c:choose>

                            <div class="form-text mt-3">
                                Sau khi lưu sản phẩm, vào trang
                                <strong>Quản lý SKU</strong>
                                để tạo phiên bản và nhập giá bán,
                                tồn kho, màu sắc, dung lượng...
                            </div>

                        </div>

                    </c:if>


                    <div class="mb-4">
                        <label class="form-label fw-semibold">
                            Mô Tả Sản Phẩm
                        </label>

                        <!-- Khung soan thao truc quan -->
                        <div id="descriptionEditor"
                             style="display:none"></div>

                        <!-- Du lieu gui den ProductServlet -->
                        <textarea
                            id="description"
                            name="description"
                            class="form-control mt-2"
                            rows="6"
                            placeholder="Nhập mô tả sản phẩm..."
                            ><c:out value="${param.description}"/></textarea>

                        <div class="form-text mt-2">
                            Dùng thanh công cụ để tạo tiêu đề,
                            in đậm, in nghiêng và danh sách.
                            Không cần nhập mã HTML.
                        </div>
                    </div>


                    <!-- =========================== -->
                    <!-- 10. NÚT LƯU                -->
                    <!-- =========================== -->

                    <div class="d-flex flex-wrap gap-2 pt-3 mt-4 border-top">

                        <button type="submit"
                                id="saveProductBtn"
                                class="btn btn-primary btn-lg px-4">

                            <i class="bi bi-check-lg me-1"></i>
                            Lưu Sản Phẩm
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

        const categorySelect =
                document.getElementById("categoryId");

        const productForm =
                document.getElementById("createProductForm");

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
        // 1. ĐỔI CATEGORY -> TẢI LẠI FORM
        // ========================================

        let lastCategoryId = categorySelect.value;

        categorySelect.addEventListener("change", function () {

            const categoryId = this.value;

            const nameInput = document.getElementById("productName");
            const descriptionInput = document.getElementById("description");
            const modelInput = document.getElementById("modelCode");
            const brandInput = document.getElementById("brandId");

            const hasEnteredData =
                    nameInput.value.trim() !== ""
                    || descriptionInput.value.trim() !== ""
                    || modelInput.value.trim() !== ""
                    || brandInput.value !== ""
                    || imageInput.files.length > 0
                    || galleryInput.files.length > 0;

            if (hasEnteredData) {

                const confirmed = confirm(
                        "Thay đổi danh mục sẽ tải lại trang " +
                        "và làm mất dữ liệu chưa lưu. Tiếp tục?"
                        );

                if (!confirmed) {
                    categorySelect.value = lastCategoryId;
                    return;
                }
            }

            const baseUrl =
                    "${pageContext.request.contextPath}/product?view=create";

            if (categoryId) {
                window.location.href =
                        baseUrl + "&categoryId=" +
                        encodeURIComponent(categoryId);
            } else {
                window.location.href = baseUrl;
            }
        });

        // ========================================
        // 2. XEM TRƯỚC ẢNH ĐẠI DIỆN
        // ========================================

        let imagePreviewUrl = null;

        imageInput.addEventListener("change", function () {

            if (imagePreviewUrl) {
                URL.revokeObjectURL(imagePreviewUrl);
                imagePreviewUrl = null;
            }

            const file = this.files[0];

            if (!file) {
                imagePreview.classList.add("d-none");
                previewImage.removeAttribute("src");
                return;
            }

            imagePreviewUrl = URL.createObjectURL(file);

            previewImage.src = imagePreviewUrl;
            imagePreview.classList.remove("d-none");
        });

        // ========================================
        // 3. XEM TRƯỚC ẢNH GALLERY
        // ========================================

        let galleryPreviewUrls = [];

        galleryInput.addEventListener("change", function () {

            galleryPreviewUrls.forEach(function (url) {
                URL.revokeObjectURL(url);
            });

            galleryPreviewUrls = [];
            galleryPreview.replaceChildren();

            Array.from(this.files).forEach(function (file) {

                const url = URL.createObjectURL(file);
                galleryPreviewUrls.push(url);

                const img = document.createElement("img");

                img.src = url;
                img.alt = "Ảnh gallery";
                img.className = "img-thumbnail";

                img.style.width = "90px";
                img.style.height = "90px";
                img.style.objectFit = "cover";

                galleryPreview.appendChild(img);
            });
        });

        // ========================================
        // 4. KIỂM TRA TRƯỚC KHI SUBMIT
        // ========================================

        productForm.addEventListener("submit", function (event) {

            const categoryId = categorySelect.value;

            const selectedCategoryId =
                    "${selectedCategoryId}";

            if (!categoryId
                    || categoryId !== selectedCategoryId) {

                event.preventDefault();

                alert(
                        "Vui lòng chọn danh mục và tải " +
                        "thông số kỹ thuật trước khi lưu."
                        );

                return;
            }

            const saveButton =
                    document.getElementById("saveProductBtn");

            if (productForm.checkValidity()) {

                saveButton.disabled = true;
                saveButton.innerHTML =
                        "Đang lưu sản phẩm...";
            }
        });

        window.addEventListener("pagehide", function () {

            if (imagePreviewUrl) {
                URL.revokeObjectURL(imagePreviewUrl);
            }

            galleryPreviewUrls.forEach(function (url) {
                URL.revokeObjectURL(url);
            });
        });
    });
</script>

<!-- Quill Editor JavaScript -->
<script src="https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.js"></script>

<script>
document.addEventListener("DOMContentLoaded", function () {

    const editorElement =
        document.getElementById("descriptionEditor");

    const description =
        document.getElementById("description");

    if (!editorElement || !description) {
        return;
    }

    // Neu thu vien khong tai duoc, giu textarea cu
    if (typeof Quill === "undefined") {
        console.error("Khong tai duoc Quill Editor.");
        return;
    }

    editorElement.style.display = "block";

    try {
        const quill = new Quill("#descriptionEditor", {
            theme: "snow",
            placeholder: "Nhập mô tả sản phẩm...",
            modules: {
                toolbar: [
                    [{ header: [2, 3, false] }],
                    ["bold", "italic", "underline"],
                    [
                        { list: "ordered" },
                        { list: "bullet" }
                    ],
                    ["link"],
                    ["clean"]
                ]
            },
            formats: [
                "header",
                "bold",
                "italic",
                "underline",
                "list",
                "link"
            ]
        });

        // Tai noi dung cu vao editor
        if (description.value.trim()) {
            const delta = quill.clipboard.convert({
                html: description.value
            });

            quill.setContents(delta, "silent");
        }

        // An textarea chi khi editor da khoi tao
        description.classList.add("d-none");

        function syncDescription() {
            const text = quill.getText().trim();

            description.value = text
                ? quill.getSemanticHTML()
                : "";
        }

        // Dong bo khi nhan vien nhap noi dung
        quill.on("text-change", syncDescription);

        // Dong bo ngay truoc khi gui form
        const form = description.closest("form");

        if (form) {
            form.addEventListener(
                "submit",
                syncDescription,
                true
            );
        }

        syncDescription();

    } catch (error) {
        console.error("Loi khoi tao Quill:", error);

        editorElement.style.display = "none";
        description.classList.remove("d-none");
    }
});
</script>


<%@include file="/WEB-INF/include/footer.jsp"%>
