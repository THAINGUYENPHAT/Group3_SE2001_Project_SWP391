
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="row justify-content-center">
    <div class="col-12 col-xl-11">

        <%-- ========================================
             1. ĐIỀU HƯỚNG
             ======================================== --%>

        <div class="mb-3">
            <a href="${pageContext.request.contextPath}/product-sku?productId=${product.productId}"
               class="text-decoration-none text-muted fw-medium">
                <i class="bi bi-arrow-left me-1"></i>
                Quay lại quản lý SKU
            </a>
        </div>

        <%-- ========================================
             2. THÔNG BÁO
             ======================================== --%>

        <c:if test="${not empty sessionScope.errorMsg}">
            <div class="alert alert-danger alert-dismissible fade show"
                 role="alert">

                <i class="bi bi-exclamation-triangle-fill me-2"></i>
                <c:out value="${sessionScope.errorMsg}"/>

                <button type="button"
                        class="btn-close"
                        data-bs-dismiss="alert"
                        aria-label="Đóng">
                </button>
            </div>

            <c:remove var="errorMsg" scope="session"/>
        </c:if>

        <c:if test="${not empty sessionScope.successMsg}">
            <div class="alert alert-success alert-dismissible fade show"
                 role="alert">

                <i class="bi bi-check-circle-fill me-2"></i>
                <c:out value="${sessionScope.successMsg}"/>

                <button type="button"
                        class="btn-close"
                        data-bs-dismiss="alert"
                        aria-label="Đóng">
                </button>
            </div>

            <c:remove var="successMsg" scope="session"/>
        </c:if>

        <%-- ========================================
             3. TIÊU ĐỀ
             ======================================== --%>

        <div class="card shadow-sm border-0 rounded-4 mb-4">
            <div class="card-body p-4">

                <div class="d-flex flex-wrap gap-3
                     justify-content-between align-items-center">

                    <div class="d-flex align-items-center">

                        <div class="bg-primary bg-opacity-10 text-primary
                             rounded d-flex align-items-center
                             justify-content-center me-3"
                             style="width:48px;height:48px;">
                            <i class="bi bi-grid-3x3-gap fs-4"></i>
                        </div>

                        <div>
                            <h4 class="fw-bold mb-1">
                                Tạo SKU Hàng Loạt
                            </h4>

                            <div class="text-muted">
                                Sản phẩm:
                                <strong class="text-dark">
                                    <c:out value="${product.productName}"/>
                                </strong>
                            </div>

                            <div class="small text-muted mt-1">
                                Product ID:
                                #<c:out value="${product.productId}"/>
                            </div>
                        </div>
                    </div>

                    <span class="badge bg-primary-subtle
                          text-primary border p-2">
                        <i class="bi bi-boxes me-1"></i>
                        OECS V2
                    </span>
                </div>
            </div>
        </div>

        <%-- ========================================
             4. HƯỚNG DẪN
             ======================================== --%>

        <div class="alert alert-info border-0 mb-4">

            <h6 class="fw-bold mb-2">
                <i class="bi bi-info-circle me-2"></i>
                Cách sử dụng
            </h6>

            <p class="mb-2">
                <strong>Bước 1:</strong>
                Nhập các lựa chọn cho từng thuộc tính biến thể,
                sau đó chọn <strong>Tạo bản xem trước</strong>.
            </p>

            <p class="mb-0">
                <strong>Bước 2:</strong>
                Kiểm tra các tổ hợp, điều chỉnh thông tin
                từng SKU và chọn
                <strong>Xác nhận lưu tất cả</strong>.
            </p>
        </div>

        <%-- ========================================
             5. FORM TẠO SKU HÀNG LOẠT
             ======================================== --%>

        <div class="card shadow-sm border-0 rounded-4 mb-4">
            <div class="card-body p-4">

                <div class="d-flex align-items-center mb-4">

                    <div class="bg-light border rounded-circle
                         d-flex align-items-center
                         justify-content-center me-3"
                         style="width:40px;height:40px;">
                        <span class="fw-bold text-primary">1</span>
                    </div>

                    <div>
                        <h5 class="fw-bold mb-0">
                            Cấu Hình Tạo SKU
                        </h5>

                        <small class="text-muted">
                            Chọn các giá trị cần kết hợp
                        </small>
                    </div>
                </div>

                <c:choose>

                    <%-- Không có thuộc tính biến thể --%>

                    <c:when test="${empty variantAttributes}">

                        <div class="alert alert-warning mb-0">
                            <i class="bi bi-exclamation-triangle me-2"></i>

                            Danh mục của sản phẩm này chưa có
                            thuộc tính biến thể được cấu hình.

                            Vui lòng cấu hình thuộc tính
                            VARIANT hoặc BOTH trước khi sử dụng
                            tính năng tạo SKU hàng loạt.
                        </div>

                    </c:when>

                    <%-- Có thuộc tính biến thể --%>

                    <c:otherwise>

                        <form id="bulkPreviewForm"
                              action="${pageContext.request.contextPath}/sku-bulk"
                              method="POST">

                            <input type="hidden"
                                   name="action"
                                   value="preview">

                            <input type="hidden"
                                   name="productId"
                                   value="${product.productId}">

                            <%-- =========================
                                 5.1. GIÁ TRỊ BIẾN THỂ
                                 ========================= --%>

                            <div class="mb-4">

                                <h6 class="fw-bold mb-3">
                                    <i class="bi bi-sliders me-2 text-primary"></i>
                                    Giá Trị Biến Thể
                                </h6>

                                <div class="row g-3">

                                    <c:forEach items="${variantAttributes}"
                                               var="config">

                                        <div class="col-md-6">

                                            <div class="border rounded-3 p-3 h-100">

                                                <label class="form-label fw-semibold">

                                                    <c:out value="${config.attributeName}"/>

                                                    <c:if test="${config.required}">
                                                        <span class="text-danger">*</span>
                                                    </c:if>
                                                </label>

                                                <div class="small text-muted mb-2">
                                                    Kiểu dữ liệu:

                                                    <strong>
                                                        <c:out value="${config.dataType}"/>
                                                    </strong>

                                                    <c:if test="${not empty config.unit}">
                                                        · Đơn vị:
                                                        <c:out value="${config.unit}"/>
                                                    </c:if>
                                                </div>

                                                <%-- QUAN TRỌNG:
                                                     Không dùng comment HTML
                                                     trực tiếp trong c:choose.
                                                --%>

                                                <c:choose>

                                                    <%-- BOOLEAN --%>

                                                    <c:when test="${config.dataType eq 'BOOLEAN'}">

                                                        <div class="form-check mb-2">

                                                            <input
                                                                class="form-check-input"
                                                                type="checkbox"
                                                                name="option_${config.attributeId}"
                                                                value="true"
                                                                id="option_${config.attributeId}_true">

                                                            <label
                                                                class="form-check-label"
                                                                for="option_${config.attributeId}_true">
                                                                Có
                                                            </label>
                                                        </div>

                                                        <div class="form-check">

                                                            <input
                                                                class="form-check-input"
                                                                type="checkbox"
                                                                name="option_${config.attributeId}"
                                                                value="false"
                                                                id="option_${config.attributeId}_false">

                                                            <label
                                                                class="form-check-label"
                                                                for="option_${config.attributeId}_false">
                                                                Không
                                                            </label>
                                                        </div>

                                                    </c:when>

                                                    <%-- TEXT / NUMBER --%>

                                                    <c:otherwise>

                                                        <textarea
                                                            name="option_${config.attributeId}"
                                                            class="form-control variant-options"
                                                            rows="4"
                                                            data-required="${config.required}"
                                                            data-type="${config.dataType}"
                                                            placeholder="${config.dataType eq 'NUMBER'
                                                                           ? 'Ví dụ: 8, 16, 32'
                                                                           : 'Ví dụ: Đen, Bạc, Xanh'}"></textarea>

                                                        <div class="form-text">
                                                            Nhập mỗi giá trị trên một dòng
                                                            hoặc phân tách bằng dấu phẩy.
                                                        </div>

                                                    </c:otherwise>

                                                </c:choose>

                                            </div>
                                        </div>

                                    </c:forEach>

                                </div>
                            </div>

                            <%-- =========================
                                 5.2. THÔNG TIN CHUNG SKU
                                 ========================= --%>

                            <div class="border-top pt-4 mb-4">

                                <h6 class="fw-bold mb-3">
                                    <i class="bi bi-currency-dollar me-2 text-primary"></i>
                                    Giá Và Tồn Kho Mặc Định
                                </h6>

                                <div class="row g-3">

                                    <div class="col-md-6">

                                        <label class="form-label fw-semibold">
                                            Tiền tố mã SKU
                                            <span class="text-danger">*</span>
                                        </label>

                                        <input type="text"
                                               name="skuPrefix"
                                               class="form-control"
                                               maxlength="95"
                                               placeholder="VD: IP15P"
                                               required>

                                        <div class="form-text">
                                            Mã sẽ được sinh dạng
                                            IP15P-001, IP15P-002...
                                        </div>
                                    </div>

                                    <div class="col-md-6">

                                        <label class="form-label fw-semibold">
                                            Trạng thái mặc định
                                        </label>

                                        <select name="isActive"
                                                class="form-select">

                                            <option value="true" selected>
                                                Đang kinh doanh
                                            </option>

                                            <option value="false">
                                                Ngừng kinh doanh
                                            </option>
                                        </select>
                                    </div>

                                    <div class="col-md-4">

                                        <label class="form-label fw-semibold">
                                            Giá bán (VNĐ)
                                            <span class="text-danger">*</span>
                                        </label>

                                        <input type="text"
                                               name="priceStr"
                                               class="form-control money-input"
                                               inputmode="numeric"
                                               placeholder="27.990.000"
                                               required>
                                    </div>

                                    <div class="col-md-4">

                                        <label class="form-label fw-semibold">
                                            Giá niêm yết (VNĐ)
                                        </label>

                                        <input type="text"
                                               name="originalPriceStr"
                                               class="form-control money-input"
                                               inputmode="numeric"
                                               placeholder="29.990.000">
                                    </div>

                                    <div class="col-md-4">

                                        <label class="form-label fw-semibold">
                                            Tồn kho mặc định
                                            <span class="text-danger">*</span>
                                        </label>

                                        <input type="number"
                                               name="stock"
                                               class="form-control"
                                               min="0"
                                               step="1"
                                               value="0"
                                               required>
                                    </div>

                                </div>
                            </div>

                            <%-- =========================
                                 5.3. SỐ TỔ HỢP DỰ KIẾN
                                 ========================= --%>

                            <div class="bg-light rounded-3 p-3 mb-4">

                                <div class="d-flex flex-wrap gap-2
                                     justify-content-between align-items-center">

                                    <div>
                                        <div class="small text-muted">
                                            Số tổ hợp dự kiến
                                        </div>

                                        <div class="fs-4 fw-bold text-primary"
                                             id="estimatedCombinations">
                                            0
                                        </div>
                                    </div>

                                    <div class="small text-muted">
                                        Tối đa 200 tổ hợp mỗi lần.
                                        Các giá trị trùng trong cùng
                                        một thuộc tính được loại bỏ.
                                    </div>

                                </div>
                            </div>

                            <%-- =========================
                                 5.4. TẠO PREVIEW
                                 ========================= --%>

                            <div class="d-flex justify-content-end">

                                <button type="submit"
                                        class="btn btn-primary px-4"
                                        id="generatePreviewBtn">

                                    <i class="bi bi-grid-3x3-gap me-1"></i>
                                    Tạo Bản Xem Trước
                                </button>
                            </div>

                        </form>

                    </c:otherwise>

                </c:choose>

            </div>
        </div>

        <%-- ========================================
             6. DANH SÁCH SKU XEM TRƯỚC
             ======================================== --%>

        <c:if test="${not empty previewSkuList}">

            <div class="card shadow-sm border-0 rounded-4 mb-4"
                 id="previewSection">

                <div class="card-body p-0">

                    <%-- HEADER PREVIEW --%>

                    <div class="p-4 border-bottom">

                        <div class="d-flex flex-wrap gap-3
                             align-items-center justify-content-between">

                            <div class="d-flex align-items-center">

                                <div class="bg-light border rounded-circle
                                     d-flex align-items-center
                                     justify-content-center me-3"
                                     style="width:40px;height:40px;">

                                    <span class="fw-bold text-primary">
                                        2
                                    </span>
                                </div>

                                <div>
                                    <h5 class="fw-bold mb-1">
                                        Xem Trước Các SKU
                                    </h5>

                                    <small class="text-muted">
                                        Chỉnh sửa thông tin trước khi lưu
                                    </small>
                                </div>
                            </div>

                            <span class="badge bg-primary-subtle
                                  text-primary border p-2">

                                ${fn:length(previewSkuList)} SKU mới
                            </span>

                        </div>
                    </div>

                    <%-- THÔNG BÁO PREVIEW --%>

                    <div class="px-4 pt-4">

                        <div class="alert alert-warning">

                            <i class="bi bi-exclamation-triangle me-2"></i>

                            Đây mới là bản xem trước.
                            Các SKU chưa được lưu vào database.

                            Nếu một SKU bị trùng hoặc không hợp lệ
                            khi xác nhận, toàn bộ thao tác lưu
                            sẽ thất bại và transaction rollback.
                        </div>
                    </div>

                    <%-- =========================
                         6.1. FORM XÁC NHẬN
                         ========================= --%>

                    <form id="bulkCommitForm"
                          action="${pageContext.request.contextPath}/sku-bulk"
                          method="POST">

                        <input type="hidden"
                               name="action"
                               value="commit">

                        <input type="hidden"
                               name="productId"
                               value="${product.productId}">

                        <input type="hidden"
                               name="previewToken"
                               value="<c:out value='${previewToken}'/>">

                        <div class="table-responsive">

                            <table class="table table-hover align-middle mb-0">

                                <thead class="table-light">

                                    <tr>
                                        <th class="ps-4"
                                            style="min-width:70px;">
                                            #
                                        </th>

                                        <th style="min-width:160px;">
                                            BIẾN THỂ
                                        </th>

                                        <th style="min-width:180px;">
                                            MÃ SKU
                                        </th>

                                        <th style="min-width:160px;">
                                            GIÁ BÁN
                                        </th>

                                        <th style="min-width:160px;">
                                            GIÁ NIÊM YẾT
                                        </th>

                                        <th style="min-width:110px;">
                                            TỒN KHO
                                        </th>

                                        <th style="min-width:160px;">
                                            TRẠNG THÁI
                                        </th>
                                    </tr>

                                </thead>

                                <tbody>

                                    <c:forEach items="${previewSkuList}"
                                               var="sku"
                                               varStatus="status">

                                        <%-- Định dạng tiền cho input --%>

                                        <fmt:formatNumber
                                            value="${sku.price}"
                                            pattern="#,##0"
                                            var="formattedPrice"/>

                                        <c:set var="formattedOriginalPrice"
                                               value=""/>

                                        <c:if test="${sku.originalPrice ne null}">

                                            <fmt:formatNumber
                                                value="${sku.originalPrice}"
                                                pattern="#,##0"
                                                var="formattedOriginalPrice"/>

                                        </c:if>

                                        <tr>

                                            <%-- STT --%>

                                            <td class="ps-4 fw-semibold">
                                                ${status.count}
                                            </td>

                                            <%-- BIẾN THỂ --%>

                                            <td>

                                                <div class="d-flex flex-wrap gap-1">

                                                    <c:forEach items="${sku.attributeValues}"
                                                               var="attr">

                                                        <span class="badge bg-light
                                                              text-dark border">

                                                            <c:choose>

                                                                <c:when test="${attr.textValue ne null}">
                                                                    <c:out value="${attr.textValue}"/>
                                                                </c:when>

                                                                <c:when test="${attr.numericValue ne null}">
                                                                    <fmt:formatNumber
                                                                        value="${attr.numericValue}"
                                                                        pattern="0.####"
                                                                        groupingUsed="false"/>
                                                                </c:when>

                                                                <c:when test="${attr.booleanValue ne null}">
                                                                    <c:out value="${attr.booleanValue ? 'Có' : 'Không'}"/>
                                                                </c:when>

                                                            </c:choose>

                                                        </span>

                                                    </c:forEach>

                                                </div>

                                                <div class="small text-muted mt-1">
                                                    Tổ hợp cố định từ preview
                                                </div>
                                            </td>

                                            <%-- MÃ SKU --%>

                                            <td>
                                                <input type="text"
                                                       name="skuCode"
                                                       class="form-control form-control-sm sku-code-input"
                                                       maxlength="100"
                                                       value="<c:out value='${sku.skuCode}'/>"
                                                       required>
                                            </td>

                                            <%-- GIÁ BÁN --%>

                                            <td>
                                                <input type="text"
                                                       name="priceStr"
                                                       class="form-control form-control-sm money-input"
                                                       inputmode="numeric"
                                                       value="<c:out value='${formattedPrice}'/>"
                                                       required>
                                            </td>

                                            <%-- GIÁ NIÊM YẾT --%>

                                            <td>
                                                <input type="text"
                                                       name="originalPriceStr"
                                                       class="form-control form-control-sm money-input"
                                                       inputmode="numeric"
                                                       value="<c:out value='${formattedOriginalPrice}'/>">
                                            </td>

                                            <%-- TỒN KHO --%>

                                            <td>
                                                <input type="number"
                                                       name="stock"
                                                       class="form-control form-control-sm"
                                                       min="0"
                                                       step="1"
                                                       value="${sku.stockQuantity}"
                                                       required>
                                            </td>

                                            <%-- TRẠNG THÁI --%>

                                            <td>
                                                <select name="isActive"
                                                        class="form-select form-select-sm">

                                                    <option value="true"
                                                            ${sku.active ? 'selected' : ''}>
                                                        Đang bán
                                                    </option>

                                                    <option value="false"
                                                            ${not sku.active ? 'selected' : ''}>
                                                        Ngừng bán
                                                    </option>

                                                </select>
                                            </td>

                                        </tr>

                                    </c:forEach>

                                </tbody>

                            </table>
                        </div>

                        <%-- =========================
                             6.2. NÚT XÁC NHẬN
                             ========================= --%>

                        <div class="p-4 border-top">

                            <div class="d-flex flex-wrap gap-2
                                 justify-content-between align-items-center">

                                <div class="small text-muted">

                                    <i class="bi bi-shield-check me-1"></i>

                                    Tất cả SKU sẽ được lưu
                                    trong một transaction SQL.
                                </div>

                                <button type="submit"
                                        id="commitBulkBtn"
                                        class="btn btn-success px-4">

                                    <i class="bi bi-check-circle me-1"></i>
                                    Xác Nhận Lưu
                                    ${fn:length(previewSkuList)} SKU
                                </button>

                            </div>
                        </div>

                    </form>

                </div>
            </div>

            <%-- =====================================
                 6.3. XÓA BẢN XEM TRƯỚC
                 ===================================== --%>

            <form action="${pageContext.request.contextPath}/sku-bulk"
                  method="POST"
                  class="text-end mb-4">

                <input type="hidden"
                       name="action"
                       value="clear">

                <input type="hidden"
                       name="productId"
                       value="${product.productId}">

                <button type="submit"
                        class="btn btn-outline-danger"
                        onclick="return confirm('Xóa bản xem trước hiện tại?');">

                    <i class="bi bi-trash me-1"></i>
                    Xóa Bản Xem Trước

                </button>
            </form>

        </c:if>

    </div>
</div>

<%-- =========================================
     7. JAVASCRIPT
     ========================================= --%>

<script>
    document.addEventListener("DOMContentLoaded", function () {

        // =====================================
        // 7.1. FORMAT GIÁ VNĐ
        // =====================================

        function formatMoney(input) {

            const digits = input.value.replace(/\D/g, "");

            if (digits === "") {
                input.value = "";
                return;
            }

            input.value = digits.replace(
                    /\B(?=(\d{3})+(?!\d))/g,
                    "."
                    );
        }

        document.querySelectorAll(".money-input")
                .forEach(function (input) {

                    formatMoney(input);

                    input.addEventListener("input", function () {
                        formatMoney(this);
                    });
                });

        // =====================================
        // 7.2. ĐỌC GIÁ TRỊ TỪ MỘT THUỘC TÍNH
        // =====================================

        function getDimensionValues(name) {

            const inputs = document.querySelectorAll(
                    '[name="' + name + '"]'
                    );

            const values = [];

            inputs.forEach(function (input) {

                if (input.type === "checkbox") {

                    if (input.checked) {
                        values.push(input.value);
                    }

                } else {

                    // Sửa regex:
                    // Tách theo dấu phẩy hoặc xuống dòng.
                    input.value.split(/[,\r\n]+/)
                            .forEach(function (value) {

                                value = value.trim();

                                if (value !== "") {
                                    values.push(value);
                                }
                            });
                }
            });

            return Array.from(new Set(values));
        }

        // =====================================
        // 7.3. TÍNH SỐ TỔ HỢP
        // =====================================

        const estimatedElement =
                document.getElementById("estimatedCombinations");

        const previewForm =
                document.getElementById("bulkPreviewForm");

        function calculateCombinations() {

            if (!estimatedElement || !previewForm) {
                return 0;
            }

            const dimensionNames = new Set();

            previewForm.querySelectorAll('[name^="option_"]')
                    .forEach(function (input) {
                        dimensionNames.add(input.name);
                    });

            let total = 1;
            let selectedDimensions = 0;

            dimensionNames.forEach(function (name) {

                const values = getDimensionValues(name);

                if (values.length > 0) {

                    selectedDimensions++;

                    total *= values.length;
                }
            });

            if (selectedDimensions === 0) {
                total = 0;
            }

            estimatedElement.textContent =
                    total.toLocaleString("vi-VN");

            if (total > 200) {

                estimatedElement.classList.add("text-danger");
                estimatedElement.classList.remove("text-primary");

            } else {

                estimatedElement.classList.add("text-primary");
                estimatedElement.classList.remove("text-danger");
            }

            return total;
        }

        // =====================================
        // 7.4. VALIDATE FORM PREVIEW
        // =====================================

        if (previewForm) {

            previewForm.querySelectorAll('[name^="option_"]')
                    .forEach(function (input) {

                        input.addEventListener(
                                "input",
                                calculateCombinations
                                );

                        input.addEventListener(
                                "change",
                                calculateCombinations
                                );
                    });

            calculateCombinations();

            previewForm.addEventListener("submit", function (event) {

                const total = calculateCombinations();

                if (total === 0) {

                    event.preventDefault();

                    alert(
                            "Vui lòng nhập ít nhất một giá trị biến thể."
                            );

                    return;
                }

                if (total > 200) {

                    event.preventDefault();

                    alert(
                            "Số tổ hợp vượt quá 200 SKU. "
                            + "Hãy giảm số lượng giá trị."
                            );

                    return;
                }

                // Backend tiếp tục kiểm tra
                // kiểu dữ liệu và thuộc tính bắt buộc.

                if (!previewForm.checkValidity()) {
                    return;
                }

                const button =
                        document.getElementById("generatePreviewBtn");

                if (button) {

                    button.disabled = true;

                    button.textContent =
                            "Đang tạo bản xem trước...";
                }
            });
        }

        // =====================================
        // 7.5. FORM XÁC NHẬN LƯU SKU
        // =====================================

        const commitForm =
                document.getElementById("bulkCommitForm");

        if (commitForm) {

            commitForm.addEventListener("submit", function (event) {

                const skuInputs =
                        commitForm.querySelectorAll(".sku-code-input");

                const usedCodes = new Set();

                for (const input of skuInputs) {

                    const code = input.value.trim();
                    if (code === "") {

                        event.preventDefault();

                        alert("Mã SKU không được để trống.");

                        input.focus();
                        return;
                    }

                    const normalized = code.toUpperCase();

                    if (usedCodes.has(normalized)) {

                        event.preventDefault();

                        alert(
                                "Mã SKU bị trùng trong danh sách: "
                                + code
                                );

                        input.focus();
                        return;
                    }

                    usedCodes.add(normalized);
                }

                if (!commitForm.checkValidity()) {
                    return;
                }

                const confirmed = confirm(
                        "Xác nhận lưu "
                        + skuInputs.length
                        + " SKU vào hệ thống?"
                        );

                if (!confirmed) {

                    event.preventDefault();
                    return;
                }

                const button =
                        document.getElementById("commitBulkBtn");

                if (button) {

                    button.disabled = true;

                    button.textContent =
                            "Đang lưu SKU...";
                }
            });
        }

        // =====================================
        // 7.6. CUỘN ĐẾN PREVIEW
        // =====================================

        const previewSection =
                document.getElementById("previewSection");

        if (previewSection
                && window.location.hash === "#preview") {

            previewSection.scrollIntoView({
                behavior: "smooth",
                block: "start"
            });
        }

    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>
