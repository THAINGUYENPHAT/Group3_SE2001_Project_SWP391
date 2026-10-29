<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .return-form-page {
        color: #263238;
    }

    .return-form-page .page-description {
        color: #64748b;
        font-size: 14px;
    }

    .return-form-page .form-card {
        background: #fff;
        border: 1px solid #edf0f5;
        border-radius: 12px;
        padding: 24px;
        margin-bottom: 20px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, .03);
    }

    .return-form-page .section-title {
        font-size: 17px;
        font-weight: 700;
        margin-bottom: 18px;
    }

    .return-form-page .notice-box {
        padding: 16px 18px;
        background: #eff6ff;
        border: 1px solid #dbeafe;
        border-radius: 10px;
        color: #1e40af;
        line-height: 1.7;
        font-size: 14px;
    }

    .return-form-page .product-item {
        padding: 20px 0;
        border-bottom: 1px solid #edf0f5;
    }

    .return-form-page .product-item:last-child {
        border-bottom: none;
        padding-bottom: 0;
    }

    .return-form-page .product-heading {
        display: flex;
        align-items: flex-start;
        gap: 12px;
    }

    .return-form-page .product-checkbox {
        width: 18px;
        height: 18px;
        margin-top: 3px;
        flex-shrink: 0;
        cursor: pointer;
    }

    .return-form-page .product-name {
        font-weight: 700;
        color: #263238;
        overflow-wrap: anywhere;
    }

    .return-form-page .product-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
        margin-top: 10px;
    }

    .return-form-page .meta-item {
        padding: 6px 10px;
        background: #f8fafc;
        border: 1px solid #edf0f5;
        border-radius: 7px;
        color: #64748b;
        font-size: 12px;
    }

    .return-form-page .form-label {
        font-size: 13px;
        font-weight: 600;
        color: #334155;
    }

    .return-form-page .form-control,
    .return-form-page .form-select {
        border-color: #dbe1e8;
        border-radius: 8px;
        padding: 10px 12px;
        font-size: 14px;
    }

    .return-form-page .form-control:focus,
    .return-form-page .form-select:focus {
        border-color: #86b7fe;
        box-shadow: 0 0 0 .2rem rgba(13, 110, 253, .12);
    }

    .return-form-page textarea.form-control {
        min-height: 120px;
        resize: vertical;
    }

    .return-form-page .exchange-field {
        display: none;
        margin-top: 16px;
        padding: 16px;
        border-radius: 9px;
        background: #f8fafc;
        border: 1px solid #edf0f5;
    }

    .return-form-page .actions {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
    }

    @media (max-width: 576px) {
        .return-form-page .form-card {
            padding: 17px;
        }

        .return-form-page .actions .btn {
            width: 100%;
        }
    }
</style>

<div class="return-form-page">

    <div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
        <div>
            <h3 class="fw-bold text-dark mb-1">
                <i class="bi bi-arrow-counterclockwise text-primary me-2"></i>
                Yêu cầu trả hàng
            </h3>
            <p class="page-description mb-0">
                Chọn sản phẩm trong đơn hàng và gửi yêu cầu để nhân viên xem xét.
            </p>
        </div>

        <a href="${pageContext.request.contextPath}/my-orders"
           class="btn btn-outline-secondary rounded-3 px-3 py-2">
            <i class="bi bi-arrow-left me-1"></i>
            Quay lại đơn hàng
        </a>
    </div>

    <div class="notice-box mb-4">
        <div class="fw-bold mb-1">
            <i class="bi bi-info-circle-fill me-2"></i>
            Lưu ý trước khi gửi yêu cầu
        </div>
        Chỉ đơn hàng đã giao thành công mới được yêu cầu đổi/trả.
        Thời hạn yêu cầu là 7 ngày kể từ ngày nhận hàng.
        Vui lòng chọn đúng sản phẩm và số lượng cần trả.
    </div>

    <c:if test="${not empty errorMessage}">
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-2"></i>
            <c:out value="${errorMessage}"/>
            <button type="button" class="btn-close"
                    data-bs-dismiss="alert" aria-label="Đóng"></button>
        </div>
    </c:if>

    <form method="post"
          action="${pageContext.request.contextPath}/return-exchange"
          id="returnExchangeForm">

        <input type="hidden" name="orderId" value="${orderId}">

        <div class="form-card">
            <h5 class="section-title">
                <i class="bi bi-receipt text-primary me-2"></i>
                Thông tin yêu cầu
            </h5>

            <div class="mb-3">
                <label for="requestType" class="form-label">Loại yêu cầu</label>
                <select id="requestType" name="requestType"
                        class="form-select" required>
                    <option value="RETURN">Trả hàng</option>
                    <option value="EXCHANGE">Đổi phiên bản sản phẩm</option>
                </select>
            </div>

            <div class="alert alert-light border rounded-3 mb-0 small">
                <i class="bi bi-shield-check text-success me-2"></i>
                Yêu cầu sẽ được nhân viên kiểm tra trước khi xử lý.
            </div>
        </div>

        <div class="form-card">
            <div class="d-flex flex-column flex-sm-row justify-content-between align-items-sm-center gap-2 mb-3">
                <h5 class="section-title mb-0">
                    <i class="bi bi-box-seam text-primary me-2"></i>
                    Chọn sản phẩm
                </h5>
                <span class="text-muted small">Đánh dấu sản phẩm muốn trả</span>
            </div>

            <c:choose>
                <c:when test="${not empty orderItems}">
                    <c:forEach var="item" items="${orderItems}">
                        <div class="product-item">
                            <div class="product-heading">
                                <input type="checkbox"
                                       name="orderItemId"
                                       value="${item.orderItemId}"
                                       class="form-check-input product-checkbox item-checkbox"
                                       aria-label="Chọn sản phẩm">

                                <div class="flex-grow-1">
                                    <div class="product-name">
                                        <c:out value="${item.productName}"/>
                                    </div>

                                    <div class="product-meta">
                                        <span class="meta-item">
                                            <i class="bi bi-upc me-1"></i>
                                            SKU: <c:out value="${item.skuCode}"/>
                                        </span>
                                        <span class="meta-item">
                                            <i class="bi bi-box me-1"></i>
                                            Đã mua: <c:out value="${item.quantity}"/>
                                        </span>
                                        <span class="meta-item">
                                            <i class="bi bi-currency-dollar me-1"></i>
                                            Đơn giá: <c:out value="${item.price}"/>
                                        </span>
                                    </div>

                                    <div class="row g-3 mt-2">
                                        <div class="col-12 col-sm-6 col-md-4">
                                            <label for="quantity_${item.orderItemId}"
                                                   class="form-label">
                                                Số lượng muốn đổi/trả
                                            </label>
                                            <input type="number"
                                                   id="quantity_${item.orderItemId}"
                                                   name="quantity_${item.orderItemId}"
                                                   class="form-control"
                                                   min="1"
                                                   max="${item.quantity}"
                                                   value="1"
                                                   required>
                                        </div>
                                    </div>

                                    <div class="exchange-field"
                                         data-order-item-id="${item.orderItemId}">
                                        <label for="exchangeSkuId_${item.orderItemId}"
                                               class="form-label">
                                            Phiên bản muốn đổi
                                        </label>

                                        <select id="exchangeSkuId_${item.orderItemId}"
                                                name="exchangeSkuId_${item.orderItemId}"
                                                class="form-select">
                                            <option value="">-- Chọn phiên bản --</option>

                                            <c:forEach var="sku"
                                                       items="${exchangeSkus[item.orderItemId]}">
                                                <option value="${sku.skuId}">
                                                    <c:out value="${sku.skuCode}"/>
                                                    - Giá: <c:out value="${sku.price}"/>
                                                    - Còn: <c:out value="${sku.stockQuantity}"/>
                                                </option>
                                            </c:forEach>
                                        </select>

                                        <c:if test="${empty exchangeSkus[item.orderItemId]}">
                                            <div class="text-muted small mt-2">
                                                Hiện không có phiên bản khác còn hàng để đổi.
                                            </div>
                                        </c:if>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </c:forEach>
                </c:when>

                <c:otherwise>
                    <div class="text-center py-5">
                        <i class="bi bi-inbox display-4 text-secondary d-block mb-3"></i>
                        <h6 class="fw-bold">Không có sản phẩm</h6>
                        <p class="text-muted small mb-0">
                            Đơn hàng hiện không có sản phẩm để tạo yêu cầu.
                        </p>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>

        <div class="form-card">
            <h5 class="section-title">
                <i class="bi bi-chat-left-text text-primary me-2"></i>
                Lý do đổi / trả hàng
            </h5>

            <div class="mb-3">
                <label for="reason" class="form-label">Lý do</label>
                <textarea id="reason"
                          name="reason"
                          class="form-control"
                          maxlength="1000"
                          required
                          placeholder="Mô tả lý do bạn muốn trả hàng..."></textarea>
                <div class="form-text">
                    Tối đa 1000 ký tự.
                </div>
            </div>

            <div class="actions mt-4">
                <button type="submit" class="btn btn-primary rounded-3 px-4 py-2">
                    <i class="bi bi-send me-1"></i>
                    Gửi yêu cầu
                </button>

                <a class="btn btn-outline-secondary rounded-3 px-4 py-2"
                   href="${pageContext.request.contextPath}/my-orders">
                    <i class="bi bi-arrow-left me-1"></i>
                    Quay lại đơn hàng
                </a>
            </div>
        </div>
    </form>
</div>

<script>
    const requestType = document.getElementById("requestType");
    const form = document.getElementById("returnExchangeForm");

    function updateExchangeFields() {
        const isExchange = requestType.value === "EXCHANGE";

        document.querySelectorAll(".exchange-field").forEach(function (field) {
            field.style.display = isExchange ? "block" : "none";

            const select = field.querySelector("select");
            const checkbox = document.querySelector(
                '.item-checkbox[value="' + field.dataset.orderItemId + '"]'
            );

            select.required = isExchange && checkbox.checked;
            select.disabled = !isExchange;
        });
    }

    document.querySelectorAll(".item-checkbox").forEach(function (checkbox) {
        checkbox.addEventListener("change", function () {
            const field = document.querySelector(
                '.exchange-field[data-order-item-id="' + checkbox.value + '"]'
            );

            const select = field.querySelector("select");
            select.required =
                requestType.value === "EXCHANGE" && checkbox.checked;
        });
    });

    requestType.addEventListener("change", updateExchangeFields);

    form.addEventListener("submit", function (event) {
        const selectedItems = document.querySelectorAll(
            ".item-checkbox:checked"
        );

        if (selectedItems.length === 0) {
            event.preventDefault();
            alert("Vui lòng chọn ít nhất một sản phẩm.");
            return;
        }

        if (requestType.value === "EXCHANGE") {
            for (const checkbox of selectedItems) {
                const field = document.querySelector(
                    '.exchange-field[data-order-item-id="' + checkbox.value + '"]'
                );
                const select = field.querySelector("select");

                if (!select.value) {
                    event.preventDefault();
                    alert("Vui lòng chọn phiên bản muốn đổi cho từng sản phẩm.");
                    select.focus();
                    return;
                }
            }
        }
    });

    updateExchangeFields();
</script>

<%@include file="/WEB-INF/include/footer.jsp" %>