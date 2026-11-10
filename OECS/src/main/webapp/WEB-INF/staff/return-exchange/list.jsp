
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .return-page {
        color: #263238;
    }

    .return-page .page-description {
        color: #64748b;
        font-size: 14px;
    }

    .return-page .stat-card {
        background: #fff;
        border: 1px solid #edf0f5;
        border-radius: 12px;
        padding: 20px;
        height: 100%;
        box-shadow: 0 2px 8px rgba(0, 0, 0, .03);
    }

    .return-page .card-custom {
        background: #fff;
        border: 1px solid #edf0f5;
        border-radius: 12px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, .03);
    }

    .return-page .table-custom {
        margin-bottom: 0;
    }

    .return-page .table-custom thead th {
        background: #f8fafc;
        color: #64748b;
        font-size: 12px;
        font-weight: 700;
        letter-spacing: .35px;
        padding: 15px 14px;
        white-space: nowrap;
        border-bottom: 1px solid #e9edf3;
    }

    .return-page .table-custom tbody td {
        padding: 15px 14px;
        border-bottom: 1px solid #f0f2f6;
        vertical-align: middle;
    }

    .return-page .table-custom tbody tr:last-child td {
        border-bottom: none;
    }

    .return-page .table-custom tbody tr:hover {
        background: #fafcff;
    }

    .return-page .status-badge {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 6px 11px;
        border-radius: 30px;
        font-size: 12px;
        font-weight: 600;
        white-space: nowrap;
    }

    .return-page .status-pending {
        background: #fff7df;
        color: #946200;
    }

    .return-page .status-approved {
        background: #e4f8ec;
        color: #187744;
    }

    .return-page .status-rejected {
        background: #ffebeb;
        color: #b42318;
    }

    .return-page .request-id {
        font-weight: 700;
        color: #2563eb;
    }

    .return-page .empty-state {
        padding: 55px 20px;
        text-align: center;
        color: #64748b;
    }

    .return-page .reason-cell {
        min-width: 180px;
        max-width: 280px;
        overflow-wrap: anywhere;
    }

    .return-page .filter-panel {
        background: #f8fafc;
        border-bottom: 1px solid #edf0f5;
        padding: 18px;
    }

    .return-page .filter-panel .form-label {
        font-size: 12px;
        font-weight: 700;
        color: #64748b;
        margin-bottom: 7px;
    }

    .return-page .filter-panel .form-control,
    .return-page .filter-panel .form-select {
        min-height: 42px;
        border-radius: 8px;
        border-color: #e2e8f0;
        font-size: 13px;
    }

    .return-page .filter-result {
        font-size: 13px;
        color: #64748b;
    }

    @media (max-width: 768px) {
        .return-page .page-heading {
            align-items: stretch !important;
        }

        .return-page .page-heading .btn {
            width: 100%;
        }
    }
</style>

<div class="return-page">

    <div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4 page-heading">
        <div>
            <h3 class="fw-bold text-dark mb-1">
                <i class="bi bi-arrow-counterclockwise text-primary me-2"></i>
                Quản lý yêu cầu đổi/trả hàng
            </h3>
            <p class="page-description mb-0">
                Theo dõi yêu cầu của khách hàng và xử lý các yêu cầu trả hàng.
            </p>
        </div>

        <a href="${pageContext.request.contextPath}/staff/return-exchange"
           class="btn btn-outline-secondary rounded-3 px-3 py-2">
            <i class="bi bi-arrow-clockwise me-1"></i>
            Làm mới danh sách
        </a>
    </div>

    <c:if test="${not empty param.message}">
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="bi bi-check-circle-fill me-2"></i>
            <c:out value="${param.message}"/>
            <button type="button" class="btn-close"
                    data-bs-dismiss="alert" aria-label="Đóng"></button>
        </div>
    </c:if>

    <c:if test="${not empty param.error}">
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-2"></i>
            <c:choose>
                <c:when test="${param.error == 'notFound'}">
                    Không tìm thấy yêu cầu.
                </c:when>
                <c:when test="${param.error == 'invalidId'}">
                    Mã yêu cầu không hợp lệ.
                </c:when>
                <c:otherwise>
                    Có lỗi xảy ra. Vui lòng thử lại.
                </c:otherwise>
            </c:choose>
            <button type="button" class="btn-close"
                    data-bs-dismiss="alert" aria-label="Đóng"></button>
        </div>
    </c:if>

    <div class="row g-3 mb-4">

        <div class="col-12 col-sm-6 col-xl-4">
            <div class="stat-card">
                <div class="d-flex align-items-center justify-content-between">
                    <span class="text-muted small fw-medium">Tổng yêu cầu</span>
                    <span class="badge bg-primary-subtle text-primary rounded-3 p-2">
                        <i class="bi bi-clipboard-data fs-5"></i>
                    </span>
                </div>
                <div class="mt-3">
                    <span class="fs-3 fw-bold text-dark">
                        ${not empty requestList ? fn:length(requestList) : 0}
                    </span>
                    <div class="text-muted small mt-1">Yêu cầu trong danh sách hiện tại</div>
                </div>
            </div>
        </div>

        <div class="col-12 col-sm-6 col-xl-4">
            <div class="stat-card">
                <div class="d-flex align-items-center justify-content-between">
                    <span class="text-muted small fw-medium">Chờ xử lý</span>
                    <span class="badge bg-warning-subtle text-warning rounded-3 p-2">
                        <i class="bi bi-hourglass-split fs-5"></i>
                    </span>
                </div>
                <div class="mt-3">
                    <span class="fs-3 fw-bold text-dark">
                        <c:set var="pendingCount" value="0"/>
                        <c:forEach var="request" items="${requestList}">
                            <c:if test="${request.requestStatus == 'PENDING'}">
                                <c:set var="pendingCount" value="${pendingCount + 1}"/>
                            </c:if>
                        </c:forEach>
                        ${pendingCount}
                    </span>
                    <div class="text-muted small mt-1">Yêu cầu cần được xem xét</div>
                </div>
            </div>
        </div>

        <div class="col-12 col-sm-6 col-xl-4">
            <div class="stat-card">
                <div class="d-flex align-items-center justify-content-between">
                    <span class="text-muted small fw-medium">Quyền xử lý</span>
                    <span class="badge bg-info-subtle text-info rounded-3 p-2">
                        <i class="bi bi-shield-check fs-5"></i>
                    </span>
                </div>
                <div class="mt-3">
                    <span class="fs-3 fw-bold text-dark">Staff</span>
                    <div class="text-muted small mt-1">Tiếp nhận và xử lý yêu cầu</div>
                </div>
            </div>
        </div>

    </div>

    <div class="card-custom overflow-hidden">

        <div class="p-3 border-bottom d-flex flex-column flex-sm-row justify-content-between align-items-sm-center gap-2">
            <div>
                <h5 class="fw-bold mb-1">Danh sách yêu cầu</h5>
                <span class="text-muted small">
                    Chọn một yêu cầu để xem thông tin chi tiết.
                </span>
            </div>
        </div>

        <div class="filter-panel">
            <div class="row g-3">

                <div class="col-12 col-lg-4">
                    <label for="searchRequest" class="form-label">
                        TÌM KIẾM
                    </label>
                    <div class="input-group">
                        <span class="input-group-text bg-white">
                            <i class="bi bi-search text-muted"></i>
                        </span>
                        <input type="text"
                               id="searchRequest"
                               class="form-control"
                               placeholder="Nhập tên khách hàng...">
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-lg-2">
                    <label for="filterType" class="form-label">
                        LOẠI YÊU CẦU
                    </label>
                    <select id="filterType" class="form-select">
                        <option value="">Tất cả</option>
                        <option value="RETURN">Trả hàng</option>
                        <option value="EXCHANGE">Đổi hàng</option>
                    </select>
                </div>

                <div class="col-12 col-sm-6 col-lg-2">
                    <label for="filterStatus" class="form-label">
                        TRẠNG THÁI
                    </label>
                    <select id="filterStatus" class="form-select">
                        <option value="">Tất cả</option>
                        <option value="PENDING">Chờ xử lý</option>
                        <option value="APPROVED">Đã chấp nhận</option>
                        <option value="REJECTED">Đã từ chối</option>
                    </select>
                </div>

                <div class="col-6 col-lg-2">
                    <label for="filterFromDate" class="form-label">
                        TỪ NGÀY
                    </label>
                    <input type="date"
                           id="filterFromDate"
                           class="form-control">
                </div>

                <div class="col-6 col-lg-2">
                    <label for="filterToDate" class="form-label">
                        ĐẾN NGÀY
                    </label>
                    <input type="date"
                           id="filterToDate"
                           class="form-control">
                </div>

                <div class="col-12 d-flex flex-column flex-sm-row justify-content-between align-items-sm-center gap-2">
                    <span class="filter-result" id="filterResult">
                        Hiển thị tất cả yêu cầu
                    </span>

                    <button type="button"
                            class="btn btn-outline-secondary btn-sm rounded-3 px-3"
                            id="resetFilters">
                        <i class="bi bi-arrow-counterclockwise me-1"></i>
                        Xóa bộ lọc
                    </button>
                </div>

            </div>
        </div>

        <div class="table-responsive">
            <table class="table table-custom align-middle">
                <thead>
                    <tr>
                        <th style="width: 100px;">MÃ YÊU CẦU</th>
                        <th style="width: 100px;">MÃ ĐƠN</th>
                        <th>KHÁCH HÀNG</th>
                        <th>LOẠI YÊU CẦU</th>
                        <th>LÝ DO</th>
                        <th style="width: 155px;">NGÀY GỬI</th>
                        <th>TRẠNG THÁI</th>
                        <th class="text-end" style="width: 135px;">THAO TÁC</th>
                    </tr>
                </thead>

                <tbody>
                    <c:forEach var="item" items="${requestList}">
                        <tr class="request-row"
                            data-type="${item.requestType}"
                            data-status="${item.requestStatus}">

                            <td>
                                <span class="request-id">
                                    #<c:out value="${item.requestId}"/>
                                </span>
                            </td>

                            <td>
                                <span class="badge bg-light text-secondary border">
                                    #<c:out value="${item.orderId}"/>
                                </span>
                            </td>

                            <td>
                                <div class="fw-semibold text-dark">
                                    <i class="bi bi-person-circle text-secondary me-1"></i>
                                    <c:out value="${item.username}"/>
                                </div>
                            </td>

                            <td>
                                <c:choose>
                                    <c:when test="${item.requestType == 'RETURN'}">
                                        <span class="badge bg-primary-subtle text-primary rounded-pill px-3 py-2">
                                            <i class="bi bi-box-arrow-left me-1"></i>
                                            Trả hàng
                                        </span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge bg-info-subtle text-info rounded-pill px-3 py-2">
                                            <i class="bi bi-arrow-left-right me-1"></i>
                                            Đổi hàng
                                        </span>
                                    </c:otherwise>
                                </c:choose>
                            </td>

                            <td class="reason-cell">
                                <c:choose>
                                    <c:when test="${not empty item.reason}">
                                        <c:out value="${item.reason}"/>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="text-muted">Không có lý do</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>

                            <td>
                                <span class="filter-date d-none">
                                    <fmt:formatDate value="${item.createdAt}"
                                                    pattern="yyyy-MM-dd"/>
                                </span>

                                <span class="text-dark small">
                                    <i class="bi bi-calendar3 text-muted me-1"></i>
                                    <fmt:formatDate value="${item.createdAt}"
                                                    pattern="dd/MM/yyyy"/>
                                </span>
                                <div class="text-muted small">
                                    <fmt:formatDate value="${item.createdAt}"
                                                    pattern="HH:mm"/>
                                </div>
                            </td>

                            <td>
                                <c:choose>
                                    <c:when test="${item.requestStatus == 'PENDING'}">
                                        <span class="status-badge status-pending">
                                            <i class="bi bi-clock-history"></i>
                                            Chờ xử lý
                                        </span>
                                    </c:when>
                                    <c:when test="${item.requestStatus == 'APPROVED'}">
                                        <span class="status-badge status-approved">
                                            <i class="bi bi-check-circle-fill"></i>
                                            Đã chấp nhận
                                        </span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="status-badge status-rejected">
                                            <i class="bi bi-x-circle-fill"></i>
                                            Đã từ chối
                                        </span>
                                    </c:otherwise>
                                </c:choose>
                            </td>

                            <td class="text-end">
                                <a class="btn btn-sm btn-primary rounded-3 px-3"
                                   href="${pageContext.request.contextPath}/staff/return-exchange?view=detail&amp;id=${item.requestId}">
                                    <i class="bi bi-eye me-1"></i>
                                    Chi tiết
                                </a>
                            </td>
                        </tr>
                    </c:forEach>

                    <tr id="noFilterResult" style="display: none;">
                        <td colspan="8">
                            <div class="empty-state">
                                <i class="bi bi-search display-4 d-block mb-3"></i>
                                <h6 class="fw-bold text-dark">Không tìm thấy yêu cầu</h6>
                                <p class="mb-0 small">
                                    Không có yêu cầu nào phù hợp với bộ lọc hiện tại.
                                </p>
                            </div>
                        </td>
                    </tr>

                    <c:if test="${empty requestList}">
                        <tr>
                            <td colspan="8">
                                <div class="empty-state">
                                    <i class="bi bi-inbox display-4 d-block mb-3"></i>
                                    <h6 class="fw-bold text-dark">Chưa có yêu cầu nào</h6>
                                    <p class="mb-0 small">
                                        Các yêu cầu của khách hàng sẽ xuất hiện tại đây.
                                    </p>
                                </div>
                            </td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </div>

</div>

<script>
document.addEventListener("DOMContentLoaded", function () {
    const searchInput = document.getElementById("searchRequest");
    const typeFilter = document.getElementById("filterType");
    const statusFilter = document.getElementById("filterStatus");
    const fromDateFilter = document.getElementById("filterFromDate");
    const toDateFilter = document.getElementById("filterToDate");
    const resetButton = document.getElementById("resetFilters");
    const resultLabel = document.getElementById("filterResult");
    const noResultRow = document.getElementById("noFilterResult");

    const rows = document.querySelectorAll(".request-row");

    function filterRequests() {
        const keyword = searchInput.value.trim().toLowerCase();
        const selectedType = typeFilter.value;
        const selectedStatus = statusFilter.value;
        const fromDate = fromDateFilter.value;
        const toDate = toDateFilter.value;

        let visibleCount = 0;

        rows.forEach(function (row) {
            const customerName = row.cells[2].innerText.trim().toLowerCase();
            const rowType = row.dataset.type;
            const rowStatus = row.dataset.status;

            const dateElement = row.querySelector(".filter-date");
            const rowDate = dateElement
                    ? dateElement.textContent.trim()
                    : "";

            const matchesKeyword = customerName.includes(keyword);

            const matchesType =
                    selectedType === "" || rowType === selectedType;

            const matchesStatus =
                    selectedStatus === "" || rowStatus === selectedStatus;

            const matchesFromDate =
                    fromDate === "" || rowDate >= fromDate;

            const matchesToDate =
                    toDate === "" || rowDate <= toDate;

            const isMatched =
                    matchesKeyword &&
                    matchesType &&
                    matchesStatus &&
                    matchesFromDate &&
                    matchesToDate;

            row.style.display = isMatched ? "" : "none";

            if (isMatched) {
                visibleCount++;
            }
        });

        if (noResultRow) {
            noResultRow.style.display =
                    rows.length > 0 && visibleCount === 0 ? "" : "none";
        }

        resultLabel.textContent =
                "Hiển thị " + visibleCount + " / " + rows.length + " yêu cầu";
    }

    searchInput.addEventListener("input", filterRequests);
    typeFilter.addEventListener("change", filterRequests);
    statusFilter.addEventListener("change", filterRequests);
    fromDateFilter.addEventListener("change", filterRequests);
    toDateFilter.addEventListener("change", filterRequests);

    resetButton.addEventListener("click", function () {
        searchInput.value = "";
        typeFilter.value = "";
        statusFilter.value = "";
        fromDateFilter.value = "";
        toDateFilter.value = "";

        filterRequests();
    });

    filterRequests();
});
</script>

<%@include file="/WEB-INF/include/footer.jsp" %>
