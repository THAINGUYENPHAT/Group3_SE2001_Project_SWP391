<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .return-form-page {
        color: #10213b;
    }

    .return-form-page .page-description {
        color: #71819a;
        font-size: 14px;
    }

    .return-form-page .form-card {
        background: #fff;
        border: 1px solid #dfe7f1;
        border-radius: 15px;
        padding: 24px;
        margin-bottom: 20px;
        box-shadow: 0 5px 18px rgba(27, 61, 99, .06);
    }

    .return-form-page .section-title {
        font-size: 17px;
        font-weight: 700;
        margin-bottom: 18px;
        color: #10213b;
    }

    .return-form-page .notice-box {
        padding: 16px 18px;
        background: #edf6ff;
        border: 1px solid #cfe5ff;
        border-left: 4px solid #1677ff;
        border-radius: 10px;
        color: #24558a;
        line-height: 1.7;
        font-size: 14px;
    }

    .return-form-page .product-item {
        padding: 20px 0;
        border-bottom: 1px solid #edf1f5;
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
        color: #10213b;
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
        background: #f7f9fc;
        border: 1px solid #e5eaf1;
        border-radius: 7px;
        color: #71819a;
        font-size: 12px;
    }

    .return-form-page .form-label {
        font-size: 13px;
        font-weight: 600;
        color: #334155;
    }

    .return-form-page .form-control,
    .return-form-page .form-select {
        border-color: #d5dfeb;
        border-radius: 8px;
        padding: 10px 12px;
        font-size: 14px;
    }

    .return-form-page .form-control:focus,
    .return-form-page .form-select:focus {
        border-color: #1677ff;
        box-shadow: 0 0 0 .2rem rgba(22, 119, 255, .12);
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
        background: #f7f9fc;
        border: 1px solid #e5eaf1;
    }

    .return-form-page .actions {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
    }


    .return-form-page .error-message {
        display: flex;
        align-items: center;
        gap: 12px;
        position: fixed;
        top: 90px;
        right: 28px;
        z-index: 9999;
        width: max-content;
        max-width: min(450px, calc(100vw - 32px));
        padding: 16px 20px;
        border-radius: 12px;
        font-size: 14px;
        font-weight: 600;
        line-height: 1.5;
        color: #b91c1c;
        background: #fef2f2;
        border: 1px solid #fca5a5;
        border-left: 5px solid #ef4444;
        box-shadow: 0 10px 30px rgba(15, 23, 42, .15);
        animation: notification-in .3s ease-out;
    }

    .return-form-page .notification-icon {
        flex-shrink: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 32px;
        height: 32px;
        border-radius: 50%;
        font-size: 18px;
        font-weight: 700;
        color: #dc2626;
        background: #fee2e2;
    }

    .return-form-page .notification-hide {
        animation: notification-out .25s ease-in forwards;
        pointer-events: none;
    }

    @keyframes notification-in {
        from {
            opacity: 0;
            transform: translateX(20px);
        }
        to {
            opacity: 1;
            transform: translateX(0);
        }
    }

    @keyframes notification-out {
        to {
            opacity: 0;
            transform: translateX(20px);
        }
    }


    .return-form-page .validation-toast {
        display: flex;
        align-items: center;
        gap: 12px;
        position: fixed;
        top: 90px;
        right: 28px;
        z-index: 10000;
        width: max-content;
        max-width: min(450px, calc(100vw - 32px));
        padding: 16px 20px;
        border-radius: 12px;
        font-size: 14px;
        font-weight: 600;
        line-height: 1.5;
        color: #b91c1c;
        background: #fef2f2;
        border: 1px solid #fca5a5;
        border-left: 5px solid #ef4444;
        box-shadow: 0 10px 30px rgba(15, 23, 42, .15);
        animation: notification-in .3s ease-out;
    }

    .return-form-page .validation-toast .notification-icon {
        flex-shrink: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 32px;
        height: 32px;
        border-radius: 50%;
        font-size: 18px;
        font-weight: 700;
        color: #dc2626;
        background: #fee2e2;
    }

    .return-form-page .validation-toast.notification-hide {
        animation: notification-out .25s ease-in forwards;
        pointer-events: none;
    }


    .return-form-page .success-message {
        display: flex;
        align-items: center;
        gap: 12px;
        position: fixed;
        top: 90px;
        right: 28px;
        z-index: 9999;
        width: max-content;
        max-width: min(450px, calc(100vw - 32px));
        padding: 16px 20px;
        border-radius: 12px;
        font-size: 14px;
        font-weight: 600;
        line-height: 1.5;
        color: #166534;
        background: #f0fdf4;
        border: 1px solid #86efac;
        border-left: 5px solid #22c55e;
        box-shadow: 0 10px 30px rgba(15, 23, 42, .15);
        animation: notification-in .3s ease-out;
    }

    .return-form-page .success-message .notification-icon {
        flex-shrink: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 32px;
        height: 32px;
        border-radius: 50%;
        color: #15803d;
        background: #dcfce7;
        font-size: 18px;
        font-weight: 700;
    }

    .return-form-page .success-panel {
        padding: 45px 24px;
        text-align: center;
        background: #fff;
        border: 1px solid #dfe7f1;
        border-radius: 15px;
        box-shadow: 0 5px 18px rgba(27, 61, 99, .06);
    }

    .return-form-page .success-panel .success-icon {
        width: 68px;
        height: 68px;
        margin: 0 auto 18px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 50%;
        background: #dcfce7;
        color: #15803d;
        font-size: 32px;
    }

    @media (max-width: 600px) {
        .return-form-page .error-message,
        .return-form-page .validation-toast {
            top: 82px;
            right: 12px;
            max-width: calc(100vw - 24px);
            padding: 12px 14px;
        }

        .return-form-page .success-message {
            top: 82px;
            right: 12px;
            max-width: calc(100vw - 24px);
            padding: 12px 14px;
        }
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

    <c:if test="${not empty successMessage}">
        <div class="success-message notification" role="status">
            <span class="notification-icon">✓</span>
            <span>
                <c:out value="${successMessage}"/>
            </span>
        </div>
    </c:if>

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

        
    </div>

    <c:choose>
        <c:when test="${not empty successMessage}">
            <div class="success-panel">
                <div class="success-icon">
                    <i class="bi bi-check-lg"></i>
                </div>

                <h4 class="fw-bold mb-2" style="color: #10213b;">
                    Gửi yêu cầu thành công!
                </h4>

                <p class="text-muted mb-2">
                    <c:out value="${successMessage}"/>
                </p>

                <p class="text-muted small mb-4">
                    Yêu cầu của bạn đã được ghi nhận.
                    Nhân viên sẽ kiểm tra và xử lý trong thời gian tới.
                </p>

                <a href="${pageContext.request.contextPath}/my-orders"
                   class="btn btn-primary rounded-3 px-4 py-2">
                    <i class="bi bi-arrow-left me-2"></i>
                    Quay về đơn hàng
                </a>
            </div>
        </c:when>

        <c:otherwise>
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
                <div class="error-message notification" role="alert">
                    <span class="notification-icon">!</span>
                    <span>
                        <c:out value="${errorMessage}"/>
                    </span>
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
        </c:otherwise>
    </c:choose>
</div>

<script>

    document.querySelectorAll(".notification").forEach(function (message) {
        setTimeout(function () {
            message.classList.add("notification-hide");

            setTimeout(function () {
                message.remove();
            }, 300);
        }, 3500);
    });


    function showValidationToast(message) {
        document.querySelectorAll(".validation-toast").forEach(function (toast) {
            toast.remove();
        });

        const toast = document.createElement("div");
        toast.className = "validation-toast";
        toast.setAttribute("role", "alert");

        const icon = document.createElement("span");
        icon.className = "notification-icon";
        icon.textContent = "!";

        const text = document.createElement("span");
        text.textContent = message;

        toast.appendChild(icon);
        toast.appendChild(text);

        document.querySelector(".return-form-page").appendChild(toast);

        setTimeout(function () {
            toast.classList.add("notification-hide");

            setTimeout(function () {
                toast.remove();
            }, 300);
        }, 3500);
    }


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

            if (!field) {
                return;
            }

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
            showValidationToast("Vui lòng chọn ít nhất một sản phẩm.");
            return;
        }

        if (requestType.value === "EXCHANGE") {
            for (const checkbox of selectedItems) {
                const field = document.querySelector(
                    '.exchange-field[data-order-item-id="' + checkbox.value + '"]'
                );

                if (!field) {
                    event.preventDefault();
                    showValidationToast(
                        "Không tìm thấy thông tin phiên bản sản phẩm."
                    );
                    return;
                }

                const select = field.querySelector("select");

                if (!select.value) {
                    event.preventDefault();
                    showValidationToast(
                        "Vui lòng chọn phiên bản muốn đổi cho từng sản phẩm."
                    );
                    select.focus();
                    return;
                }
            }
        }
    });

    updateExchangeFields();
</script>

<%@include file="/WEB-INF/include/footer.jsp" %>