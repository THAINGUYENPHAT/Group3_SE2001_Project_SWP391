<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .form-page {
        max-width: 1050px;
        margin: 0 auto;
        padding-bottom: 30px;
    }

    .page-title {
        font-size: 1.55rem;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 4px;
    }

    .page-description {
        color: #64748b;
        font-size: 0.9rem;
    }

    .voucher-form-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 25px;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }

    .section-title {
        color: #0f172a;
        font-size: 1rem;
        font-weight: 700;
        margin-bottom: 20px;
    }

    .form-label {
        color: #475569;
        font-size: 0.82rem;
        font-weight: 600;
        margin-bottom: 6px;
    }

    .form-control,
    .form-select {
        min-height: 42px;
        border: 1px solid #cbd5e1;
        border-radius: 8px;
        font-size: 0.88rem;
    }

    .form-control:focus,
    .form-select:focus {
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.10);
    }

    .field-note {
        color: #94a3b8;
        font-size: 0.75rem;
        margin-top: 5px;
    }

    .btn-save {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        padding: 10px 17px;
        background: #2563eb;
        color: white;
        border: none;
        border-radius: 8px;
        font-weight: 600;
    }

    .btn-save:hover {
        background: #1d4ed8;
    }

    .btn-back {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 9px 16px;
        background: white;
        color: #475569;
        border: 1px solid #cbd5e1;
        border-radius: 8px;
        text-decoration: none;
    }

    .btn-back:hover {
        background: #f8fafc;
        color: #0f172a;
    }
</style>

<div class="form-page">

    <div class="mb-4">
        <h1 class="page-title">
            Chỉnh sửa Voucher
        </h1>
        <div class="page-description">
            Cập nhật thông tin Voucher <strong>${voucher.code}</strong>.
        </div>
    </div>

    <c:if test="${not empty sessionScope.errorMessage}">
        <div class="alert alert-danger alert-dismissible fade show">
            <i class="bi bi-exclamation-circle-fill me-2"></i>
            ${sessionScope.errorMessage}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="errorMessage" scope="session"/>
    </c:if>

    <div class="voucher-form-card">

        <div class="section-title">
            <i class="bi bi-pencil-square text-primary me-2"></i>
            Thông tin Voucher
        </div>

        <form action="${pageContext.request.contextPath}/admin/voucher" method="post">

            <input type="hidden" name="action" value="update">
            <input type="hidden" name="voucherId" value="${voucher.voucherId}">

            <div class="row g-3">

                <%-- CODE --%>
                <div class="col-md-6">
                    <label class="form-label">
                        Mã Voucher
                    </label>
                    <input type="text"
                           name="code"
                           class="form-control"
                           value="${voucher.code}"
                           required>
                </div>

                <%-- DISCOUNT TYPE --%>
                <div class="col-md-6">
                    <label class="form-label">
                        Loại giảm giá
                    </label>
                    <select name="discountType"
                            id="discountType"
                            class="form-select"
                            required>
                        <option value="AMOUNT" ${voucher.discountType == 'AMOUNT' ? 'selected' : ''}>
                            Giảm số tiền
                        </option>
                        <option value="PERCENT" ${voucher.discountType == 'PERCENT' ? 'selected' : ''}>
                            Giảm phần trăm
                        </option>
                    </select>
                </div>

                <%-- DISCOUNT VALUE --%>
                <div class="col-md-6">
                    <label class="form-label">
                        Giá trị giảm
                    </label>
                    <input type="number"
                           name="discountValue"
                           id="discountValue"
                           class="form-control"
                           value="${voucher.discountValue}"
                           min="1"
                           step="0.01"
                           required>
                </div>

                <%-- MAX DISCOUNT --%>
                <div class="col-md-6" id="maxDiscountGroup">
                    <label class="form-label">
                        Giảm tối đa
                    </label>
                    <input type="number"
                           name="maxDiscount"
                           class="form-control"
                           value="${voucher.maxDiscount}"
                           min="0"
                           step="1000">
                    <div class="field-note">
                        Chỉ áp dụng khi giảm theo phần trăm.
                    </div>
                </div>

                <%-- MIN ORDER VALUE --%>
                <div class="col-md-6">
                    <label class="form-label">
                        Giá trị đơn tối thiểu
                    </label>
                    <input type="number"
                           name="minOrderValue"
                           class="form-control"
                           value="${voucher.minOrderValue}"
                           min="0"
                           step="1000"
                           required>
                </div>

                <%-- USAGE LIMIT --%>
                <div class="col-md-3">
                    <label class="form-label">
                        Tổng lượt sử dụng
                    </label>
                    <input type="number"
                           name="usageLimit"
                           class="form-control"
                           value="${voucher.usageLimit}"
                           min="1">
                    <div class="field-note">
                        Trống = không giới hạn.
                    </div>
                </div>

                <%-- PER USER LIMIT --%>
                <div class="col-md-3">
                    <label class="form-label">
                        Giới hạn mỗi User
                    </label>
                    <input type="number"
                           name="perUserLimit"
                           class="form-control"
                           value="${voucher.perUserLimit}"
                           min="1">
                    <div class="field-note">
                        Trống = không giới hạn.
                    </div>
                </div>

                <%-- VALID FROM --%>
                <div class="col-md-6">
                    <label class="form-label">
                        Thời gian bắt đầu
                    </label>
                    <input type="datetime-local"
                           name="validFrom"
                           class="form-control"
                           value="${validFromValue}"
                           required>
                </div>

                <%-- VALID TO --%>
                <div class="col-md-6">
                    <label class="form-label">
                        Thời gian kết thúc
                    </label>
                    <input type="datetime-local"
                           name="validTo"
                           class="form-control"
                           value="${validToValue}"
                           required>
                </div>

            </div>

            <div class="d-flex gap-2 mt-4">
                <button type="submit" class="btn-save">
                    <i class="bi bi-check-lg"></i> Lưu thay đổi
                </button>

                <a href="${pageContext.request.contextPath}/admin/voucher" class="btn-back">
                    <i class="bi bi-x-lg"></i> Hủy
                </a>
            </div>

        </form>

    </div>

</div>

<script>
    const discountType = document.getElementById("discountType");
    const discountValue = document.getElementById("discountValue");
    const maxDiscountGroup = document.getElementById("maxDiscountGroup");

    function updateDiscountForm() {
        if (discountType.value === "PERCENT") {
            maxDiscountGroup.style.display = "block";
            discountValue.max = "100";
        } else {
            maxDiscountGroup.style.display = "none";
            discountValue.removeAttribute("max");
        }
    }

    discountType.addEventListener("change", updateDiscountForm);
    updateDiscountForm();
</script>

<%@include file="/WEB-INF/include/footer.jsp" %>