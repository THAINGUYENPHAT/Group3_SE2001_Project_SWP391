<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>
<%@include file="/WEB-INF/include/header.jsp"%>

<c:url var="prevPageUrl" value="/inventory">
    <c:param name="page" value="${pageNumber - 1}"/>
    <c:param name="keyword" value="${keyword}"/>
    <c:param name="status" value="${status}"/>
</c:url>
<c:url var="nextPageUrl" value="/inventory">
    <c:param name="page" value="${pageNumber + 1}"/>
    <c:param name="keyword" value="${keyword}"/>
    <c:param name="status" value="${status}"/>
</c:url>

<style>
    .inventory-page {
        background:#f6f8fc;
        min-height:100vh;
        padding:28px 0 65px;
    }
    .inventory-title {
        font-size:clamp(23px,3vw,31px);
        font-weight:800;
        color:#142b4a;
    }
    .inventory-panel {
        border:1px solid #e6ebf2;
        border-radius:16px;
        background:#fff;
        overflow:hidden;
    }
    .inventory-panel-header {
        padding:20px 22px;
        border-bottom:1px solid #e6ebf2;
    }
    .inventory-table {
        margin:0;
        min-width:900px;
        vertical-align:middle;
    }
    .inventory-table th {
        background:#f8fafc;
        color:#475569;
        font-size:12px;
        white-space:nowrap;
    }
    .inventory-table td {
        padding-top:14px;
        padding-bottom:14px;
    }
    .inventory-sku {
        font-size:13px;
        font-weight:700;
        color:#1d4ed8;
        overflow-wrap:anywhere;
    }
    .inventory-product {
        font-size:14px;
        font-weight:700;
        color:#1e293b;
    }
    .inventory-form {
        display:flex;
        align-items:center;
        flex-wrap:wrap;
        gap:7px;
    }
    .inventory-form select {
        width:128px;
        flex:0 0 auto;
    }
    .inventory-form input[type=number] {
        width:86px;
        flex:0 0 auto;
    }
    .inventory-form input[name=note] {
        width:190px;
        flex:1 1 160px;
        min-width:140px;
    }
    .inventory-form button {
        white-space:nowrap;
    }
    .inventory-positive {
        color:#15803d;
        font-weight:700;
    }
    .inventory-negative {
        color:#dc2626;
        font-weight:700;
    }
    .inventory-history td {
        font-size:13px;
        vertical-align:middle;
    }
    .inventory-muted {
        color:#64748b;
        font-size:13px;
    }
    @media(max-width:575.98px) {
        .inventory-page {
            padding-top:17px;
        }
        .inventory-panel-header {
            padding:16px;
        }
    }
</style>

<div class="inventory-page">
    <div class="container-fluid px-3 px-lg-4">

        <%-- BREADCRUMB AND HEADER --%>
        <nav aria-label="breadcrumb" class="mb-3">
            <ol class="breadcrumb small mb-0">
                <li class="breadcrumb-item">
                    <a href="${pageContext.request.contextPath}/home">Trang chủ</a>
                </li>
                <li class="breadcrumb-item active" aria-current="page">Quản lý tồn kho</li>
            </ol>
        </nav>

        <div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-4">
            <div>
                <h1 class="inventory-title mb-2">
                    <i class="bi bi-box-seam text-primary me-2"></i>Quản lý tồn kho SKU
                </h1>
                <p class="text-muted mb-0">
                    Nhập hàng, xuất hàng, kiểm kê số lượng và xem lịch sử thay đổi.
                </p>
            </div>
            <a class="btn btn-outline-primary" href="${pageContext.request.contextPath}/product?view=list">
                <i class="bi bi-arrow-left me-1"></i>Quản lý sản phẩm
            </a>
        </div>

        <%-- FLASH MESSAGES (PRG) --%>
        <c:if test="${not empty sessionScope.inventorySuccess}">
            <div class="alert alert-success" role="status">
                <c:out value="${sessionScope.inventorySuccess}"/>
            </div>
            <c:remove var="inventorySuccess" scope="session"/>
        </c:if>
        <c:if test="${not empty sessionScope.inventoryError}">
            <div class="alert alert-danger" role="alert">
                <c:out value="${sessionScope.inventoryError}"/>
            </div>
            <c:remove var="inventoryError" scope="session"/>
        </c:if>

        <%-- SEARCH & STATUS FILTER --%>
        <section class="inventory-panel mb-4">
            <div class="inventory-panel-header">
                <form method="GET" action="${pageContext.request.contextPath}/inventory"
                      class="row g-2 align-items-end">
                    <div class="col-12 col-md-6">
                        <label for="inventoryKeyword" class="form-label small fw-semibold">Tìm SKU / sản phẩm</label>
                        <input id="inventoryKeyword" type="search" class="form-control"
                               name="keyword" maxlength="100" placeholder="Tên sản phẩm hoặc mã SKU"
                               value="${fn:escapeXml(keyword)}">
                    </div>
                    <div class="col-7 col-md-3">
                        <label for="inventoryStatus" class="form-label small fw-semibold">Trạng thái kho</label>
                        <select id="inventoryStatus" class="form-select" name="status">
                            <option value="ALL" ${status eq 'ALL' ? 'selected' : ''}>Tất cả</option>
                            <option value="LOW" ${status eq 'LOW' ? 'selected' : ''}>Sắp hết (1–5)</option>
                            <option value="OUT" ${status eq 'OUT' ? 'selected' : ''}>Hết hàng (0)</option>
                        </select>
                    </div>
                    <div class="col-5 col-md-3">
                        <button class="btn btn-primary w-100" type="submit">
                            <i class="bi bi-search me-1"></i>Tìm kiếm
                        </button>
                    </div>
                </form>
            </div>
            <div class="px-3 px-md-4 py-3 d-flex justify-content-between flex-wrap gap-2">
                <span class="inventory-muted">Tìm thấy <strong><c:out value="${totalItems}"/></strong> SKU</span>
                <span class="inventory-muted">Trang <c:out value="${pageNumber}"/> / <c:out value="${totalPages}"/></span>
            </div>

            <%-- SKU TABLE --%>
            <div class="table-responsive">
                <table class="table table-hover inventory-table">
                    <thead>
                        <tr>
                            <th scope="col" class="ps-3">Sản phẩm / SKU</th>
                            <th scope="col">Tồn hiện tại</th>
                            <th scope="col">Trạng thái</th>
                            <th scope="col">Nhập / xuất / kiểm kê</th>
                        </tr>
                    </thead>
                    <tbody>
                    <c:choose>
                        <c:when test="${not empty items}">
                            <c:forEach items="${items}" var="item">
                                <tr>
                                    <td class="ps-3">
                                        <div class="inventory-product"><c:out value="${item.productName}"/></div>
                                        <div class="inventory-sku"><c:out value="${item.skuCode}"/></div>
                                        <a class="small" href="${pageContext.request.contextPath}/product-sku?productId=${item.productId}">
                                            Xem quản lý SKU
                                        </a>
                                    </td>
                                    <td>
                                        <strong class="fs-5"><fmt:formatNumber value="${item.stockQuantity}" pattern="#,##0"/></strong>
                                    </td>
                                    <td>
                                <c:choose>
                                    <c:when test="${not item.editable}">
                                        <span class="badge bg-secondary">Ngừng kinh doanh</span>
                                    </c:when>
                                    <c:when test="${item.stockQuantity eq 0}">
                                        <span class="badge bg-danger">Hết hàng</span>
                                    </c:when>
                                    <c:when test="${item.stockQuantity le 5}">
                                        <span class="badge bg-warning text-dark">Sắp hết</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge bg-success">Còn hàng</span>
                                    </c:otherwise>
                                </c:choose>
                                </td>
                                <td>
                                <c:choose>
                                    <c:when test="${item.editable}">
                                        <form method="POST" class="inventory-form"
                                              action="${pageContext.request.contextPath}/inventory">
                                            <input type="hidden" name="csrfToken" value="${fn:escapeXml(csrfToken)}">
                                            <input type="hidden" name="skuId" value="${item.skuId}">
                                            <select name="action" class="form-select form-select-sm"
                                                    aria-label="Thao tác tồn kho" required>
                                                <option value="IN">Nhập thêm</option>
                                                <option value="OUT">Xuất kho</option>
                                                <option value="SET">Kiểm kê</option>
                                            </select>
                                            <input name="quantity" type="number" class="form-control form-control-sm"
                                                   min="0" max="2147483647" step="1" required value="1"
                                                   aria-label="Số lượng hoặc số tồn mục tiêu">
                                            <input name="note" type="text" class="form-control form-control-sm"
                                                   maxlength="500" required placeholder="Lý do (bắt buộc)"
                                                   aria-label="Lý do thay đổi tồn kho">
                                            <button class="btn btn-sm btn-primary" type="submit">Lưu</button>
                                        </form>
                                        <small class="text-muted">Kiểm kê = đặt số tồn đúng bằng số nhập.</small>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="text-muted small">Không thể chỉnh khi ngừng bán.</span>
                                    </c:otherwise>
                                </c:choose>
                                </td>
                                </tr>
                            </c:forEach>
                        </c:when>
                        <c:otherwise>
                            <tr><td colspan="4" class="text-center text-muted py-5">
                                    Không tìm thấy SKU phù hợp.
                                </td></tr>
                        </c:otherwise>
                    </c:choose>
                    </tbody>
                </table>
            </div>

            <%-- PAGINATION --%>
            <div class="d-flex justify-content-end align-items-center gap-2 px-3 px-md-4 py-3 border-top">
                <c:if test="${pageNumber gt 1}">
                    <a class="btn btn-outline-secondary btn-sm"
                       href="${fn:escapeXml(prevPageUrl)}">Trang trước</a>
                </c:if>
                <span class="small text-muted"><c:out value="${pageNumber}"/> / <c:out value="${totalPages}"/></span>
                <c:if test="${pageNumber lt totalPages}">
                    <a class="btn btn-outline-secondary btn-sm"
                       href="${fn:escapeXml(nextPageUrl)}">Trang sau</a>
                </c:if>
            </div>
        </section>

        <%-- RECENT MOVEMENT HISTORY --%>
        <section class="inventory-panel" aria-labelledby="movementTitle">
            <div class="inventory-panel-header">
                <h2 id="movementTitle" class="h5 fw-bold mb-1">Lịch sử biến động kho gần đây</h2>
                <p class="inventory-muted mb-0">
                    Gồm thay đổi thủ công, số dư khi bắt đầu theo dõi và thay đổi từ nghiệp vụ khác.
                </p>
            </div>
            <div class="table-responsive">
                <table class="table table-striped inventory-history mb-0">
                    <thead>
                        <tr>
                            <th scope="col" class="ps-3">Thời gian</th>
                            <th scope="col">SKU</th>
                            <th scope="col">Loại</th>
                            <th scope="col">Thay đổi</th>
                            <th scope="col">Trước → sau</th>
                            <th scope="col">Người thực hiện</th>
                            <th scope="col">Ghi chú</th>
                        </tr>
                    </thead>
                    <tbody>
                    <c:choose>
                        <c:when test="${not empty movements}">
                            <c:forEach items="${movements}" var="m">
                                <tr>
                                    <td class="ps-3 text-nowrap">
                                <fmt:formatDate value="${m.createdAt}" pattern="dd/MM/yyyy HH:mm:ss"/>
                                </td>
                                <td>
                                    <strong><c:out value="${m.skuCode}"/></strong>
                                    <div class="text-muted small"><c:out value="${m.productName}"/></div>
                                </td>
                                <td>
                                <c:choose>
                                    <c:when test="${m.movementType eq 'IN'}">Nhập kho</c:when>
                                    <c:when test="${m.movementType eq 'OUT'}">Xuất kho</c:when>
                                    <c:when test="${m.movementType eq 'SET'}">Kiểm kê</c:when>
                                    <c:when test="${m.movementType eq 'OPENING'}">Số dư đầu</c:when>
                                    <c:otherwise>Hệ thống</c:otherwise>
                                </c:choose>
                                </td>
                                <td>
                                    <span class="${m.quantityDelta ge 0 ? 'inventory-positive' : 'inventory-negative'}">
                                        <c:if test="${m.quantityDelta gt 0}">+</c:if><c:out value="${m.quantityDelta}"/>
                                    </span>
                                </td>
                                <td><c:out value="${m.quantityBefore}"/> → <c:out value="${m.quantityAfter}"/></td>
                                <td>
                                <c:choose>
                                    <c:when test="${not empty m.actorName}"><c:out value="${m.actorName}"/></c:when>
                                    <c:otherwise><span class="text-muted">—</span></c:otherwise>
                                </c:choose>
                                </td>
                                <td style="max-width:280px;overflow-wrap:anywhere;">
                                <c:out value="${m.note}"/>
                                </td>
                                </tr>
                            </c:forEach>
                        </c:when>
                        <c:otherwise>
                            <tr><td colspan="7" class="text-center text-muted py-4">
                                    Chưa có lịch sử biến động tồn kho.
                                </td></tr>
                        </c:otherwise>
                    </c:choose>
                    </tbody>
                </table>
            </div>
        </section>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp"%>
