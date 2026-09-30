<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<!DOCTYPE html>
<html>

<head>

    <meta charset="UTF-8">

    <title>Voucher Management</title>

    <link
        href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
        rel="stylesheet">

</head>


<body class="bg-light">


<div class="container mt-5 mb-5">


    <h2 class="mb-4">
        Quản lý Voucher
    </h2>


    <c:if test="${not empty sessionScope.successMessage}">

        <div class="alert alert-success">

            ${sessionScope.successMessage}

        </div>

        <c:remove
            var="successMessage"
            scope="session"/>

    </c:if>


    <c:if test="${not empty sessionScope.errorMessage}">

        <div class="alert alert-danger">

            ${sessionScope.errorMessage}

        </div>

        <c:remove
            var="errorMessage"
            scope="session"/>

    </c:if>


    <div class="row g-4">


        <!-- FORM -->

        <div class="col-lg-4">


            <div class="card">


                <div class="card-header">

                    <c:choose>

                        <c:when test="${not empty editVoucher}">
                            Cập nhật Voucher
                        </c:when>

                        <c:otherwise>
                            Tạo Voucher
                        </c:otherwise>

                    </c:choose>

                </div>


                <div class="card-body">


                    <form
                        action="${pageContext.request.contextPath}/admin/voucher"
                        method="post">


                        <c:choose>

                            <c:when test="${not empty editVoucher}">

                                <input
                                    type="hidden"
                                    name="action"
                                    value="update">

                                <input
                                    type="hidden"
                                    name="voucherId"
                                    value="${editVoucher.voucherId}">

                            </c:when>

                            <c:otherwise>

                                <input
                                    type="hidden"
                                    name="action"
                                    value="create">

                            </c:otherwise>

                        </c:choose>


                        <div class="mb-3">

                            <label class="form-label">
                                Mã Voucher
                            </label>

                            <input
                                type="text"
                                name="code"
                                class="form-control"
                                value="${editVoucher.code}"
                                required>

                        </div>


                        <div class="mb-3">

                            <label class="form-label">
                                Loại giảm
                            </label>

                            <select
                                id="discountType"
                                name="discountType"
                                class="form-select">

                                <option
                                    value="AMOUNT"
                                    ${editVoucher.discountType == 'AMOUNT' ? 'selected' : ''}>

                                    Giảm tiền

                                </option>

                                <option
                                    value="PERCENT"
                                    ${editVoucher.discountType == 'PERCENT' ? 'selected' : ''}>

                                    Giảm %

                                </option>

                            </select>

                        </div>


                        <div class="mb-3">

                            <label class="form-label">
                                Giá trị giảm
                            </label>

                            <input
                                id="discountValue"
                                type="number"
                                name="discountValue"
                                class="form-control"
                                value="${editVoucher.discountValue}"
                                min="1"
                                required>

                        </div>


                        <div
                            class="mb-3"
                            id="maxDiscountGroup">

                            <label class="form-label">
                                Giảm tối đa
                            </label>

                            <input
                                type="number"
                                name="maxDiscount"
                                class="form-control"
                                value="${editVoucher.maxDiscount}">

                        </div>


                        <div class="mb-3">

                            <label class="form-label">
                                Đơn tối thiểu
                            </label>

                            <input
                                type="number"
                                name="minOrderValue"
                                class="form-control"
                                value="${editVoucher.minOrderValue}"
                                min="0"
                                required>

                        </div>


                        <div class="mb-3">

                            <label class="form-label">
                                Tổng lượt sử dụng
                            </label>

                            <input
                                type="number"
                                name="usageLimit"
                                class="form-control"
                                value="${editVoucher.usageLimit}"
                                min="1">

                            <small class="text-muted">
                                Để trống nếu không giới hạn
                            </small>

                        </div>


                        <div class="mb-3">

                            <label class="form-label">
                                Số lượt mỗi user
                            </label>

                            <input
                                type="number"
                                name="perUserLimit"
                                class="form-control"
                                value="${editVoucher.perUserLimit}"
                                min="1">

                            <small class="text-muted">
                                Để trống nếu không giới hạn
                            </small>

                        </div>


                        <div class="mb-3">

                            <label class="form-label">
                                Ngày bắt đầu
                            </label>

                            <input
                                type="datetime-local"
                                name="validFrom"
                                class="form-control"
                                value="${validFromValue}"
                                required>

                        </div>


                        <div class="mb-3">

                            <label class="form-label">
                                Ngày kết thúc
                            </label>

                            <input
                                type="datetime-local"
                                name="validTo"
                                class="form-control"
                                value="${validToValue}"
                                required>

                        </div>


                        <button
                            class="btn btn-primary">

                            Lưu Voucher

                        </button>


                        <c:if test="${not empty editVoucher}">

                            <a
                                href="${pageContext.request.contextPath}/admin/voucher"
                                class="btn btn-secondary">

                                Hủy

                            </a>

                        </c:if>


                    </form>


                </div>


            </div>


        </div>


        <!-- LIST -->

        <div class="col-lg-8">


            <div class="card">


                <div class="card-body">


                    <h5>
                        Danh sách Voucher
                    </h5>


                    <div class="table-responsive">


                        <table class="table table-bordered">


                            <thead class="table-dark">

                            <tr>

                                <th>Code</th>

                                <th>Loại</th>

                                <th>Giá trị</th>

                                <th>Min</th>

                                <th>Usage</th>

                                <th>User</th>

                                <th>Action</th>

                            </tr>

                            </thead>


                            <tbody>


                            <c:forEach
                                var="v"
                                items="${vouchers}">


                                <tr>


                                    <td>
                                        ${v.code}
                                    </td>


                                    <td>
                                        ${v.discountType}
                                    </td>


                                    <td>

                                        <c:choose>

                                            <c:when test="${v.discountType == 'PERCENT'}">

                                                ${v.discountValue}%

                                            </c:when>

                                            <c:otherwise>

                                                <fmt:formatNumber
                                                    value="${v.discountValue}"
                                                    type="number"/>

                                                đ

                                            </c:otherwise>

                                        </c:choose>

                                    </td>


                                    <td>

                                        <fmt:formatNumber
                                            value="${v.minOrderValue}"
                                            type="number"/>

                                    </td>


                                    <td>

                                        <c:choose>

                                            <c:when test="${empty v.usageLimit}">
                                                ∞
                                            </c:when>

                                            <c:otherwise>
                                                ${v.usageLimit}
                                            </c:otherwise>

                                        </c:choose>

                                    </td>


                                    <td>

                                        <c:choose>

                                            <c:when test="${empty v.perUserLimit}">
                                                ∞
                                            </c:when>

                                            <c:otherwise>
                                                ${v.perUserLimit}
                                            </c:otherwise>

                                        </c:choose>

                                    </td>


                                    <td>

                                        <a
                                            href="${pageContext.request.contextPath}/admin/voucher?action=edit&id=${v.voucherId}"
                                            class="btn btn-warning btn-sm">

                                            Edit

                                        </a>


                                        <a
                                            href="${pageContext.request.contextPath}/admin/voucher?action=delete&id=${v.voucherId}"
                                            class="btn btn-danger btn-sm"
                                            onclick="return confirm('Xóa voucher này?')">

                                            Delete

                                        </a>

                                    </td>


                                </tr>


                            </c:forEach>


                            </tbody>


                        </table>


                    </div>


                </div>


            </div>


        </div>


    </div>


</div>


<script>

    const type =
        document.getElementById("discountType");

    const value =
        document.getElementById("discountValue");

    const maxGroup =
        document.getElementById("maxDiscountGroup");


    function updateDiscountForm() {

        if (type.value === "PERCENT") {

            value.max = "100";

            maxGroup.style.display =
                "block";

        } else {

            value.removeAttribute("max");

            maxGroup.style.display =
                "none";
        }
    }


    type.addEventListener(
        "change",
        updateDiscountForm
    );


    updateDiscountForm();

</script>


</body>

</html>