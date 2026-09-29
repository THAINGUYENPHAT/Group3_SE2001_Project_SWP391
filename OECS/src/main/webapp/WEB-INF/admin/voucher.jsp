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

        <style>
            body {
                background-color: #f5f6f8;
            }

            .page-container {
                margin-top: 40px;
                margin-bottom: 40px;
            }

            .card {
                border: none;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
            }

            .table-container {
                background: white;
                padding: 20px;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
            }

            .voucher-code {
                font-weight: bold;
            }

            .action-buttons {
                white-space: nowrap;
            }
        </style>
    </head>

    <body>

        <div class="container page-container">

            <h2 class="mb-4">
                Quản lý Voucher
            </h2>


            <!-- ============================== -->
            <!-- SUCCESS MESSAGE -->
            <!-- ============================== -->

            <c:if test="${not empty sessionScope.successMessage}">

                <div class="alert alert-success alert-dismissible fade show">

                    ${sessionScope.successMessage}

                    <button
                        type="button"
                        class="btn-close"
                        data-bs-dismiss="alert">
                    </button>

                </div>

                <c:remove
                    var="successMessage"
                    scope="session"/>

            </c:if>


            <!-- ============================== -->
            <!-- ERROR MESSAGE -->
            <!-- ============================== -->

            <c:if test="${not empty sessionScope.errorMessage}">

                <div class="alert alert-danger alert-dismissible fade show">

                    ${sessionScope.errorMessage}

                    <button
                        type="button"
                        class="btn-close"
                        data-bs-dismiss="alert">
                    </button>

                </div>

                <c:remove
                    var="errorMessage"
                    scope="session"/>

            </c:if>


            <div class="row g-4">


                <!-- ================================== -->
                <!-- FORM CREATE / UPDATE -->
                <!-- ================================== -->

                <div class="col-lg-4">

                    <div class="card">

                        <div class="card-header">

                            <c:choose>

                                <c:when test="${not empty editVoucher}">
                                    Cập nhật Voucher
                                </c:when>

                                <c:otherwise>
                                    Tạo Voucher mới
                                </c:otherwise>

                            </c:choose>

                        </div>


                        <div class="card-body">

                            <form
                                action="${pageContext.request.contextPath}/admin/voucher"
                                method="post">


                                <!-- ACTION -->

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


                                <!-- CODE -->

                                <div class="mb-3">

                                    <label
                                        for="code"
                                        class="form-label">

                                        Mã Voucher

                                    </label>

                                    <input
                                        type="text"
                                        id="code"
                                        name="code"
                                        class="form-control"
                                        value="${editVoucher.code}"
                                        placeholder="VD: SALE50K"
                                        maxlength="50"
                                        required>

                                </div>


                                <!-- DISCOUNT -->

                                <div class="mb-3">

                                    <label
                                        for="discountAmount"
                                        class="form-label">

                                        Số tiền giảm

                                    </label>

                                    <div class="input-group">
                                        <c:choose>
                                            <c:when test="${not empty editVoucher}">
                                                <input
                                                    type="number"
                                                    id="discountAmount"
                                                    name="discountAmount"
                                                    class="form-control"
                                                    value="${editVoucher.discountAmount}"
                                                    min="1"
                                                    step="1000"
                                                    required>
                                            </c:when>

                                            <c:otherwise>
                                                <input
                                                    type="number"
                                                    id="discountAmount"
                                                    name="discountAmount"
                                                    class="form-control"
                                                    min="1"
                                                    step="1000"
                                                    required>
                                            </c:otherwise>
                                        </c:choose>

                                        <span class="input-group-text">
                                            đ
                                        </span>

                                    </div>

                                </div>


                                <!-- MIN ORDER -->

                                <div class="mb-3">

                                    <label
                                        for="minOrderValue"
                                        class="form-label">

                                        Giá trị đơn tối thiểu

                                    </label>

                                    <div class="input-group">

                                        <!-- MIN ORDER -->

                                        <div class="mb-3">

                                            <label
                                                for="minOrderValue"
                                                class="form-label">

                                                Giá trị đơn tối thiểu

                                            </label>

                                            <div class="input-group">

                                                <c:choose>

                                                    <c:when test="${not empty editVoucher}">

                                                        <input
                                                            type="number"
                                                            id="minOrderValue"
                                                            name="minOrderValue"
                                                            class="form-control"
                                                            value="${editVoucher.minOrderValue}"
                                                            min="0"
                                                            step="1000"
                                                            required>

                                                    </c:when>

                                                    <c:otherwise>

                                                        <input
                                                            type="number"
                                                            id="minOrderValue"
                                                            name="minOrderValue"
                                                            class="form-control"
                                                            min="0"
                                                            step="1000"
                                                            required>

                                                    </c:otherwise>

                                                </c:choose>


                                                <span class="input-group-text">
                                                    đ
                                                </span>

                                            </div>

                                        </div>
                                        <span class="input-group-text">
                                            đ
                                        </span>

                                    </div>

                                </div>


                                <!-- VALID FROM -->

                                <div class="mb-3">

                                    <label
                                        for="validFrom"
                                        class="form-label">

                                        Ngày bắt đầu

                                    </label>

                                    <input
                                        type="datetime-local"
                                        id="validFrom"
                                        name="validFrom"
                                        class="form-control"
                                        required>

                                </div>


                                <!-- VALID TO -->

                                <div class="mb-3">

                                    <label
                                        for="validTo"
                                        class="form-label">

                                        Ngày kết thúc

                                    </label>

                                    <input
                                        type="datetime-local"
                                        id="validTo"
                                        name="validTo"
                                        class="form-control"
                                        required>

                                </div>


                                <!-- BUTTON -->

                                <div class="d-flex gap-2">

                                    <button
                                        type="submit"
                                        class="btn btn-primary">

                                        <c:choose>

                                            <c:when test="${not empty editVoucher}">
                                                Cập nhật
                                            </c:when>

                                            <c:otherwise>
                                                Tạo Voucher
                                            </c:otherwise>

                                        </c:choose>

                                    </button>


                                    <c:if test="${not empty editVoucher}">

                                        <a
                                            href="${pageContext.request.contextPath}/admin/voucher"
                                            class="btn btn-secondary">

                                            Hủy

                                        </a>

                                    </c:if>

                                </div>

                            </form>

                        </div>

                    </div>

                </div>


                <!-- ================================== -->
                <!-- TABLE -->
                <!-- ================================== -->

                <div class="col-lg-8">

                    <div class="table-container">

                        <h5 class="mb-3">
                            Danh sách Voucher
                        </h5>


                        <!-- EMPTY -->

                        <c:if test="${empty vouchers}">

                            <div class="alert alert-info">

                                Chưa có Voucher nào.

                            </div>

                        </c:if>


                        <!-- LIST -->

                        <c:if test="${not empty vouchers}">

                            <div class="table-responsive">

                                <table
                                    class="table table-bordered table-hover align-middle">


                                    <thead class="table-dark">

                                        <tr>

                                            <th>ID</th>

                                            <th>Code</th>

                                            <th>Giảm</th>

                                            <th>Đơn tối thiểu</th>

                                            <th>Bắt đầu</th>

                                            <th>Kết thúc</th>

                                            <th>Thao tác</th>

                                        </tr>

                                    </thead>


                                    <tbody>

                                        <c:forEach
                                            var="voucher"
                                            items="${vouchers}">


                                            <tr>

                                                <!-- ID -->

                                                <td>

                                                    ${voucher.voucherId}

                                                </td>


                                                <!-- CODE -->

                                                <td>

                                                    <span class="voucher-code">

                                                        ${voucher.code}

                                                    </span>

                                                </td>


                                                <!-- DISCOUNT -->

                                                <td>

                                                    <fmt:formatNumber
                                                        value="${voucher.discountAmount}"
                                                        type="number"
                                                        groupingUsed="true"/>

                                                    đ

                                                </td>


                                                <!-- MIN ORDER -->

                                                <td>

                                                    <fmt:formatNumber
                                                        value="${voucher.minOrderValue}"
                                                        type="number"
                                                        groupingUsed="true"/>

                                                    đ

                                                </td>


                                                <!-- FROM -->

                                                <td>

                                                    <fmt:formatDate
                                                        value="${voucher.validFrom}"
                                                        pattern="dd/MM/yyyy HH:mm"/>

                                                </td>


                                                <!-- TO -->

                                                <td>

                                                    <fmt:formatDate
                                                        value="${voucher.validTo}"
                                                        pattern="dd/MM/yyyy HH:mm"/>

                                                </td>


                                                <!-- ACTION -->

                                                <td class="action-buttons">

                                                    <a
                                                        href="${pageContext.request.contextPath}/admin/voucher?action=edit&id=${voucher.voucherId}"
                                                        class="btn btn-warning btn-sm">

                                                        Edit

                                                    </a>


                                                    <a
                                                        href="${pageContext.request.contextPath}/admin/voucher?action=delete&id=${voucher.voucherId}"
                                                        class="btn btn-danger btn-sm"
                                                        onclick="return confirm('Bạn có chắc muốn xóa Voucher ${voucher.code} không?')">

                                                        Delete

                                                    </a>

                                                </td>

                                            </tr>

                                        </c:forEach>

                                    </tbody>

                                </table>

                            </div>

                        </c:if>

                    </div>

                </div>

            </div>

        </div>


        <script
            src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js">
        </script>

    </body>

</html>