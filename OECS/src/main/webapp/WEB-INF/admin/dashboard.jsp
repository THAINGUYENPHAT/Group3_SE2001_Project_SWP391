
<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/include/header.jsp" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<style>


.oecs-dashboard {
    width: 100%;
    padding: 20px 0 40px;
    color: #0f172a;
    font-family: "Inter", sans-serif;
}

.oecs-dashboard * {
    box-sizing: border-box;
}


.oecs-dashboard .db-heading {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 16px;
    margin-bottom: 22px;
}

.oecs-dashboard .db-heading h1 {
    font-size: 27px;
    font-weight: 800;
    margin: 0 0 7px;
    color: #0f172a;
}

.oecs-dashboard .db-heading p {
    color: #64748b;
    font-size: 13px;
    margin: 0;
    line-height: 1.6;
}

.oecs-dashboard .db-page-tag {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    padding: 9px 13px;
    background: #eff6ff;
    color: #2563eb;
    border-radius: 9px;
    font-size: 12px;
    font-weight: 700;
}


.oecs-dashboard .db-card {
    min-width: 0;
    background: #ffffff;
    border: 1px solid #e2e8f0;
    border-radius: 14px;
    padding: 22px;
    box-shadow: 0 3px 12px rgba(15, 23, 42, .04);
}

.oecs-dashboard .db-card-title {
    margin: 0 0 7px;
    font-size: 17px;
    font-weight: 750;
    color: #0f172a;
}

.oecs-dashboard .db-card-desc {
    margin: 0 0 18px;
    color: #64748b;
    font-size: 12px;
    line-height: 1.65;
}

.oecs-dashboard .db-filter {
    margin-bottom: 20px;
}

.oecs-dashboard .db-filter-form {
    display: flex;
    align-items: flex-end;
    gap: 12px;
    flex-wrap: wrap;
}

.oecs-dashboard .db-date-field {
    display: flex;
    flex-direction: column;
    gap: 7px;
}

.oecs-dashboard .db-date-field label {
    color: #475569;
    font-size: 12px;
    font-weight: 650;
}

.oecs-dashboard .db-date-field input {
    height: 41px;
    padding: 0 12px;
    border: 1px solid #cbd5e1;
    border-radius: 8px;
    background: #ffffff;
    color: #0f172a;
    font-size: 13px;
}

.oecs-dashboard .db-date-field input:focus {
    border-color: #2563eb;
    outline: 2px solid rgba(37, 99, 235, .12);
}

.oecs-dashboard .db-btn {
    height: 41px;
    padding: 0 17px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 650;
    text-decoration: none;
    cursor: pointer;
    transition: .2s;
}

.oecs-dashboard .db-btn-primary {
    background: #2563eb;
    border: 1px solid #2563eb;
    color: #ffffff;
}

.oecs-dashboard .db-btn-primary:hover {
    background: #1d4ed8;
    color: #ffffff;
}

.oecs-dashboard .db-btn-secondary {
    background: #ffffff;
    border: 1px solid #cbd5e1;
    color: #475569;
}

.oecs-dashboard .db-btn-secondary:hover {
    background: #f8fafc;
    color: #0f172a;
}

.oecs-dashboard .db-error {
    display: flex;
    align-items: center;
    gap: 9px;
    padding: 12px 15px;
    margin-top: 15px;
    border: 1px solid #fecaca;
    background: #fef2f2;
    color: #b91c1c;
    border-radius: 9px;
    font-size: 13px;
}

.oecs-dashboard .db-kpi-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 15px;
    margin-bottom: 20px;
}

.oecs-dashboard .db-kpi {
    min-height: 145px;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 10px;
}

.oecs-dashboard .db-kpi-content {
    flex: 1;
    min-width: 0;
}

.oecs-dashboard .db-kpi-title {
    color: #64748b;
    font-size: 12px;
    font-weight: 650;
    margin-bottom: 14px;
}

.oecs-dashboard .db-kpi-number {
    color: #0f172a;
    font-size: clamp(20px, 2vw, 27px);
    font-weight: 800;
    font-variant-numeric: tabular-nums;
    overflow-wrap: anywhere;
}

.oecs-dashboard .db-kpi-note {
    color: #94a3b8;
    font-size: 11px;
    margin-top: 11px;
    line-height: 1.5;
}

.oecs-dashboard .db-kpi-icon {
    display: grid;
    place-items: center;
    flex-shrink: 0;
    width: 45px;
    height: 45px;
    border-radius: 11px;
    font-size: 20px;
}

.oecs-dashboard .db-blue {
    background: #eff6ff;
    color: #2563eb;
}

.oecs-dashboard .db-purple {
    background: #f5f3ff;
    color: #7c3aed;
}

.oecs-dashboard .db-green {
    background: #f0fdf4;
    color: #16a34a;
}

.oecs-dashboard .db-red {
    background: #fef2f2;
    color: #dc2626;
}

.oecs-dashboard .db-revenue-card {
    margin-bottom: 20px;
}

.oecs-dashboard .db-revenue-chart {
    position: relative;
    width: 100%;
    height: 325px;
}

.oecs-dashboard .db-two-columns {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    gap: 20px;
    margin-bottom: 20px;
    align-items: stretch;
}

.oecs-dashboard .db-status-chart {
    width: 100%;
    height: 330px;
    position: relative;
}

.oecs-dashboard .db-products {
    display: flex;
    flex-direction: column;
}

.oecs-dashboard .db-product {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 13px 0;
    border-bottom: 1px solid #f1f5f9;
}

.oecs-dashboard .db-product:last-child {
    border-bottom: none;
}

.oecs-dashboard .db-product-rank {
    width: 25px;
    flex-shrink: 0;
    text-align: center;
    color: #64748b;
    font-size: 13px;
    font-weight: 800;
}

.oecs-dashboard .db-product:first-child .db-product-rank {
    color: #d97706;
}

.oecs-dashboard .db-product-image {
    width: 60px;
    height: 60px;
    flex-shrink: 0;
    border: 1px solid #e2e8f0;
    border-radius: 10px;
    background: #f8fafc;
    overflow: hidden;
    display: flex;
    justify-content: center;
    align-items: center;
}

.oecs-dashboard .db-product-image img {
    display: block;
    width: 100%;
    height: 100%;
    object-fit: contain;
}

.oecs-dashboard .db-image-fallback {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
    height: 100%;
    font-size: 22px;
    color: #94a3b8;
}

.oecs-dashboard .db-product-info {
    flex: 1;
    min-width: 0;
}

.oecs-dashboard .db-product-name {
    font-size: 13px;
    font-weight: 700;
    color: #0f172a;
    line-height: 1.5;
    margin-bottom: 5px;
    overflow-wrap: anywhere;
}

.oecs-dashboard .db-product-price {
    color: #64748b;
    font-size: 12px;
    line-height: 1.55;
}

.oecs-dashboard .db-product-sold {
    flex-shrink: 0;
    text-align: right;
}

.oecs-dashboard .db-product-sold strong {
    display: block;
    font-size: 16px;
    font-weight: 800;
    color: #0f172a;
}

.oecs-dashboard .db-product-sold small {
    color: #94a3b8;
    font-size: 11px;
}

.oecs-dashboard .db-stock-summary {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 14px;
    margin-bottom: 18px;
}

.oecs-dashboard .db-stock-item {
    border: 1px solid #e2e8f0;
    border-radius: 11px;
    padding: 16px;
}

.oecs-dashboard .db-stock-label {
    color: #64748b;
    font-size: 12px;
    margin-bottom: 9px;
}

.oecs-dashboard .db-stock-value {
    color: #0f172a;
    font-size: 25px;
    font-weight: 800;
}

.oecs-dashboard .db-stock-bar {
    display: flex;
    width: 100%;
    height: 14px;
    background: #e2e8f0;
    border-radius: 999px;
    overflow: hidden;
    margin: 15px 0;
}

.oecs-dashboard .db-stock-good {
    background: #16a34a;
}

.oecs-dashboard .db-stock-low {
    background: #f59e0b;
}

.oecs-dashboard .db-stock-out {
    background: #ef4444;
}

.oecs-dashboard .db-stock-note {
    color: #64748b;
    font-size: 12px;
    line-height: 1.65;
    margin: 10px 0 0;
}

.oecs-dashboard .db-stock-details {
    margin-top: 25px;
    padding-top: 23px;
    border-top: 1px solid #e2e8f0;
}

.oecs-dashboard .db-stock-list {
    display: flex;
    flex-direction: column;
    max-height: 450px;
    overflow-y: auto;
    padding-right: 5px;
}

.oecs-dashboard .db-stock-product {
    display: flex;
    align-items: center;
    gap: 15px;
    padding: 15px 6px;
    border-bottom: 1px solid #f1f5f9;
}

.oecs-dashboard .db-stock-product:last-child {
    border-bottom: none;
}

.oecs-dashboard .db-stock-product-info {
    flex: 1;
    min-width: 0;
}

.oecs-dashboard .db-stock-product-right {
    flex-shrink: 0;
    display: flex;
    align-items: flex-end;
    flex-direction: column;
    gap: 5px;
    text-align: right;
}

.oecs-dashboard .db-stock-product-right strong {
    color: #0f172a;
    font-size: 20px;
    font-weight: 800;
}

.oecs-dashboard .db-stock-product-unit {
    color: #64748b;
    font-size: 11px;
}

.oecs-dashboard .db-stock-badge {
    display: inline-block;
    border-radius: 7px;
    padding: 5px 10px;
    font-size: 11px;
    font-weight: 700;
    white-space: nowrap;
}

.oecs-dashboard .db-stock-badge-out {
    color: #dc2626;
    background: #fef2f2;
}

.oecs-dashboard .db-stock-badge-low {
    color: #d97706;
    background: #fffbeb;
}

.oecs-dashboard .db-empty {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    gap: 11px;
    min-height: 180px;
    text-align: center;
    color: #94a3b8;
    font-size: 13px;
}

.oecs-dashboard .db-empty i {
    font-size: 32px;
}

@media (max-width: 1100px) {

    .oecs-dashboard .db-kpi-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }
}

@media (max-width: 850px) {

    .oecs-dashboard .db-two-columns {
        grid-template-columns: 1fr;
    }
}

@media (max-width: 575px) {

    .oecs-dashboard {
        padding-top: 12px;
    }

    .oecs-dashboard .db-card {
        padding: 16px;
    }

    .oecs-dashboard .db-heading h1 {
        font-size: 23px;
    }

    .oecs-dashboard .db-kpi-grid {
        grid-template-columns: 1fr;
    }

    .oecs-dashboard .db-stock-summary {
        grid-template-columns: 1fr;
    }

    .oecs-dashboard .db-revenue-chart {
        height: 270px;
    }

    .oecs-dashboard .db-product-image {
        width: 52px;
        height: 52px;
    }

    .oecs-dashboard .db-stock-product {
        gap: 9px;
    }

    .oecs-dashboard .db-stock-product-right strong {
        font-size: 17px;
    }
}
</style>


<div class="oecs-dashboard">

    <div class="db-heading">

        <div>
            <h1>
                <i class="bi bi-grid-1x2 me-2"></i>
                Tổng quan kinh doanh
            </h1>

            <p>
                Theo dõi kết quả bán hàng,
                trạng thái đơn hàng và tình hình tồn kho OECS.
            </p>
        </div>

        <span class="db-page-tag">
            <i class="bi bi-shop"></i>
            OECS Admin
        </span>

    </div>


    <div class="db-card db-filter">

        <h2 class="db-card-title">
            <i class="bi bi-calendar-range me-2"></i>
            Khoảng thời gian thống kê
        </h2>

        <p class="db-card-desc">
            Thống kê đơn hàng theo ngày tạo đơn.
            Bộ lọc áp dụng cho KPI, biểu đồ và Top 5.
            Tồn kho được tính tại thời điểm hiện tại.
        </p>

        <form method="get"
              id="dashboardFilterForm"
              action="${pageContext.request.contextPath}/admin/dashboard"
              class="db-filter-form">

            <div class="db-date-field">

                <label for="startDate">
                    Từ ngày
                </label>

                <input type="date"
                       id="startDate"
                       name="startDate"
                       value="${startDate}"
                       required>

            </div>

            <div class="db-date-field">

                <label for="endDate">
                    Đến ngày
                </label>

                <input type="date"
                       id="endDate"
                       name="endDate"
                       value="${endDate}"
                       required>

            </div>

            <button type="submit"
                    class="db-btn db-btn-primary">

                <i class="bi bi-funnel"></i>
                Lọc dữ liệu

            </button>

            <a href="${pageContext.request.contextPath}/admin/dashboard"
               class="db-btn db-btn-secondary">

                <i class="bi bi-arrow-counterclockwise"></i>
                Đặt lại

            </a>

        </form>

        <div id="dashboardDateError"
             class="db-error"
             role="alert"
             style="display: none;">

            <i class="bi bi-exclamation-triangle-fill"></i>

            <span id="dashboardDateErrorText"></span>

        </div>

        
        <c:if test="${not empty dateError}">

            <div class="db-error" role="alert">

                <i class="bi bi-exclamation-triangle-fill"></i>

                <span>
                    <c:out value="${dateError}"/>
                    Đang hiển thị 30 ngày gần nhất.
                </span>

            </div>

        </c:if>

    </div>

   

    <div class="db-kpi-grid">


        <div class="db-card db-kpi">

            <div class="db-kpi-content">

                <div class="db-kpi-title">
                    Giá trị đơn hoàn thành
                </div>

                <div class="db-kpi-number">

                    <fmt:formatNumber
                        value="${totalRevenue}"
                        pattern="#,##0"/> ₫

                </div>

                <div class="db-kpi-note">
                    Đơn tạo trong kỳ, hiện đã hoàn thành
                </div>

            </div>

            <div class="db-kpi-icon db-blue">
                <i class="bi bi-cash-stack"></i>
            </div>

        </div>

        <div class="db-card db-kpi">

            <div class="db-kpi-content">

                <div class="db-kpi-title">
                    Tổng đơn hàng
                </div>

                <div class="db-kpi-number">

                    <fmt:formatNumber
                        value="${totalOrders}"
                        pattern="#,##0"/>

                </div>

                <div class="db-kpi-note">
                    Tất cả đơn được tạo trong kỳ
                </div>

            </div>

            <div class="db-kpi-icon db-purple">
                <i class="bi bi-cart3"></i>
            </div>

        </div>

        <div class="db-card db-kpi">

            <div class="db-kpi-content">

                <div class="db-kpi-title">
                    Đơn hàng hoàn thành
                </div>

                <div class="db-kpi-number">

                    <fmt:formatNumber
                        value="${completedOrders}"
                        pattern="#,##0"/>

                </div>

                <div class="db-kpi-note">
                    Đơn tạo trong kỳ, hiện đã hoàn thành
                </div>

            </div>

            <div class="db-kpi-icon db-green">
                <i class="bi bi-check-circle"></i>
            </div>

        </div>

        <div class="db-card db-kpi">

            <div class="db-kpi-content">

                <div class="db-kpi-title">
                    Đơn hàng đã hủy
                </div>

                <div class="db-kpi-number">

                    <fmt:formatNumber
                        value="${cancelledOrders}"
                        pattern="#,##0"/>

                </div>

                <div class="db-kpi-note">
                    Đơn tạo trong kỳ, hiện đã hủy
                </div>

            </div>

            <div class="db-kpi-icon db-red">
                <i class="bi bi-x-circle"></i>
            </div>

        </div>

    </div>


    <div class="db-card db-revenue-card">

        <h2 class="db-card-title">

            <i class="bi bi-graph-up-arrow me-2"></i>

            Giá trị đơn hoàn thành theo thời gian

        </h2>

        <p class="db-card-desc">
            Tổng giá trị các đơn hiện đã hoàn thành,
            nhóm theo ngày tạo đơn trong khoảng thời gian đã chọn.
        </p>

        <c:choose>

            <c:when test="${empty revenueByDate}">

                <div class="db-empty">

                    <i class="bi bi-bar-chart-line"></i>

                    <span>
                        Không có đơn hoàn thành
                        trong khoảng thời gian này.
                    </span>

                </div>

            </c:when>

            <c:otherwise>

                <div class="db-revenue-chart">
                    <canvas id="revenueChart"></canvas>
                </div>

            </c:otherwise>

        </c:choose>

    </div>


    <div class="db-two-columns">

        <div class="db-card">

            <h2 class="db-card-title">

                <i class="bi bi-pie-chart me-2"></i>
                Trạng thái đơn hàng

            </h2>

            <p class="db-card-desc">
                Phân bổ trạng thái hiện tại
                của các đơn được tạo trong kỳ.
            </p>

            <c:choose>

                <c:when test="${empty orderStatusStatistics}">

                    <div class="db-empty">

                        <i class="bi bi-inbox"></i>

                        <span>
                            Không có đơn hàng trong kỳ.
                        </span>

                    </div>

                </c:when>

                <c:otherwise>

                    <div class="db-status-chart">
                        <canvas id="orderStatusChart"></canvas>
                    </div>

                </c:otherwise>

            </c:choose>

        </div>

        <div class="db-card">

            <h2 class="db-card-title">

                <i class="bi bi-trophy me-2"></i>

                Top 5 sản phẩm bán chạy

            </h2>

            <p class="db-card-desc">
                Xếp hạng theo số lượng từ đơn hoàn thành trong kỳ.
                Giá hiển thị là giá niêm yết hiện tại.
            </p>

            <c:choose>

                <c:when test="${empty topSellingProducts}">

                    <div class="db-empty">

                        <i class="bi bi-box-seam"></i>

                        <span>
                            Chưa có sản phẩm bán ra trong kỳ.
                        </span>

                    </div>

                </c:when>

                <c:otherwise>

                    <div class="db-products">

                        <c:forEach
                            var="product"
                            items="${topSellingProducts}"
                            varStatus="loop">

                            <div class="db-product">

                                <!-- RANK -->

                                <div class="db-product-rank">
                                    #${loop.index + 1}
                                </div>

                                <div class="db-product-image">

                                    <c:choose>

                                        <c:when test="${not empty product[2]}">

                                            <c:url
                                                value="/${product[2]}"
                                                var="productImageUrl"/>

                                            <img
                                                src="<c:out value='${productImageUrl}'/>"
                                                alt="Ảnh sản phẩm"
                                                loading="lazy"
                                                onerror="this.style.display='none';this.nextElementSibling.style.display='flex';">

                                            <div
                                                class="db-image-fallback"
                                                style="display:none;">

                                                <i class="bi bi-image"></i>

                                            </div>

                                        </c:when>

                                        <c:otherwise>

                                            <div class="db-image-fallback">

                                                <i class="bi bi-image"></i>

                                            </div>

                                        </c:otherwise>

                                    </c:choose>

                                </div>

                                <div class="db-product-info">

                                    <div class="db-product-name">

                                        <c:out value="${product[1]}"/>

                                    </div>

                                    <div class="db-product-price">

                                        <c:choose>

                                            <c:when test="${not empty product[3]}">

                                                Giá từ

                                                <fmt:formatNumber
                                                    value="${product[3]}"
                                                    pattern="#,##0"/> ₫

                                            </c:when>

                                            <c:otherwise>

                                                Chưa có giá

                                            </c:otherwise>

                                        </c:choose>

                                    </div>

                                </div>

                                <div class="db-product-sold">

                                    <strong>

                                        <fmt:formatNumber
                                            value="${product[4]}"
                                            pattern="#,##0"/>

                                    </strong>

                                    <small>Đã bán</small>

                                </div>

                            </div>

                        </c:forEach>

                    </div>

                </c:otherwise>

            </c:choose>

        </div>

    </div>

    <div class="db-card">

        <h2 class="db-card-title">

            <i class="bi bi-boxes me-2"></i>

            Tình trạng tồn kho

        </h2>

        <p class="db-card-desc">
            Thống kê số SKU dựa trên số lượng tồn kho hiện tại.
            Không áp dụng bộ lọc ngày.
        </p>

        <div class="db-stock-summary">

            <div class="db-stock-item">

                <div class="db-stock-label">

                    <i class="bi bi-check-circle text-success me-1"></i>

                    Còn hàng (&gt; 5)

                </div>

                <div class="db-stock-value">

                    <fmt:formatNumber
                        value="${stockAvailable}"
                        pattern="#,##0"/>

                </div>

            </div>

            <div class="db-stock-item">

                <div class="db-stock-label">

                    <i class="bi bi-exclamation-triangle text-warning me-1"></i>

                    Sắp hết (1–5)

                </div>

                <div class="db-stock-value">

                    <fmt:formatNumber
                        value="${stockLow}"
                        pattern="#,##0"/>

                </div>

            </div>

            <div class="db-stock-item">

                <div class="db-stock-label">

                    <i class="bi bi-x-circle text-danger me-1"></i>

                    Hết hàng (0)

                </div>

                <div class="db-stock-value">

                    <fmt:formatNumber
                        value="${stockOut}"
                        pattern="#,##0"/>

                </div>

            </div>

        </div>

        <c:choose>

            <c:when test="${totalSku > 0}">

                <div class="db-stock-bar">

                    <div
                        class="db-stock-good"
                        style="width:${stockAvailable * 100.0 / totalSku}%;">
                    </div>

                    <div
                        class="db-stock-low"
                        style="width:${stockLow * 100.0 / totalSku}%;">
                    </div>

                    <div
                        class="db-stock-out"
                        style="width:${stockOut * 100.0 / totalSku}%;">
                    </div>

                </div>

                <p class="db-stock-note">

                    Tổng cộng

                    <strong>
                        <fmt:formatNumber
                            value="${totalSku}"
                            pattern="#,##0"/>
                    </strong>

                    SKU.

                    Mỗi SKU được tính một lần theo số lượng tồn.
                    Ngưỡng cảnh báo sắp hết hàng: từ 1 đến 5.

                </p>

            </c:when>

            <c:otherwise>

                <p class="db-stock-note">
                    Chưa có SKU trong hệ thống.
                </p>

            </c:otherwise>

        </c:choose>

        <div class="db-stock-details">

            <h3 class="db-card-title">

                <i class="bi bi-exclamation-triangle me-2"></i>

                Danh sách sản phẩm cần nhập hàng

            </h3>

            <p class="db-card-desc">
                Các SKU đang hết hàng hoặc sắp hết hàng.
                Ưu tiên hiển thị SKU hết hàng trước,
                sau đó đến SKU có số lượng tồn thấp nhất.
            </p>

            <c:choose>

                <c:when test="${empty lowStockProducts}">

                    <div class="db-empty">

                        <i class="bi bi-check-circle text-success"></i>

                        <span>
                            Hiện không có SKU nào hết hàng
                            hoặc sắp hết hàng.
                        </span>

                    </div>

                </c:when>

                <c:otherwise>

                    <div class="db-stock-list">

                        <c:forEach
                            var="sku"
                            items="${lowStockProducts}">

                            <div class="db-stock-product">

                                <div class="db-product-image">

                                    <c:choose>

                                        <c:when test="${not empty sku[3]}">

                                            <c:url
                                                value="/${sku[3]}"
                                                var="stockImageUrl"/>

                                            <img
                                                src="<c:out value='${stockImageUrl}'/>"
                                                alt="Ảnh sản phẩm"
                                                loading="lazy"
                                                onerror="this.style.display='none';this.nextElementSibling.style.display='flex';">

                                            <div
                                                class="db-image-fallback"
                                                style="display:none;">

                                                <i class="bi bi-image"></i>

                                            </div>

                                        </c:when>

                                        <c:otherwise>

                                            <div class="db-image-fallback">

                                                <i class="bi bi-image"></i>

                                            </div>

                                        </c:otherwise>

                                    </c:choose>

                                </div>


                                <div class="db-stock-product-info">

                                    <div class="db-product-name">

                                        <c:out value="${sku[2]}"/>

                                    </div>

                                    <div class="db-product-price">

                                        Mã SKU:

                                        <c:out value="${sku[1]}"/>

                                    </div>

                                    <div class="db-product-price">

                                        <c:choose>

                                            <c:when test="${not empty sku[5]}">

                                                Giá:

                                                <fmt:formatNumber
                                                    value="${sku[5]}"
                                                    pattern="#,##0"/> ₫

                                            </c:when>

                                            <c:otherwise>

                                                Chưa có giá

                                            </c:otherwise>

                                        </c:choose>

                                    </div>

                                </div>


                                <div class="db-stock-product-right">

                                    <strong>

                                        <fmt:formatNumber
                                            value="${sku[4]}"
                                            pattern="#,##0"/>

                                    </strong>

                                    <span class="db-stock-product-unit">
                                        Còn lại
                                    </span>

                                    <c:choose>

                                        <c:when test="${sku[4] le 0}">

                                            <span
                                                class="db-stock-badge db-stock-badge-out">

                                                <i class="bi bi-x-circle me-1"></i>

                                                Hết hàng

                                            </span>

                                        </c:when>

                                        <c:otherwise>

                                            <span
                                                class="db-stock-badge db-stock-badge-low">

                                                <i class="bi bi-exclamation-triangle me-1"></i>

                                                Sắp hết

                                            </span>

                                        </c:otherwise>

                                    </c:choose>

                                </div>

                            </div>

                        </c:forEach>

                    </div>

                </c:otherwise>

            </c:choose>

        </div>

    </div>

</div>


<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<script>
document.addEventListener("DOMContentLoaded", function () {


    const filterForm =
            document.getElementById("dashboardFilterForm");

    const startInput =
            document.getElementById("startDate");

    const endInput =
            document.getElementById("endDate");

    const errorBox =
            document.getElementById("dashboardDateError");

    const errorText =
            document.getElementById("dashboardDateErrorText");

    function clearError() {
        errorBox.style.display = "none";
        errorText.textContent = "";
    }

    if (filterForm && startInput && endInput) {

        startInput.addEventListener("change", clearError);
        endInput.addEventListener("change", clearError);

        filterForm.addEventListener(
            "submit",
            function (event) {

                const start = startInput.value;
                const end = endInput.value;

                let message = "";

                if (!start || !end) {

                    message =
                        "Vui lòng chọn đầy đủ ngày bắt đầu "
                        + "và ngày kết thúc.";

                } else if (start > end) {

                    message =
                        "Ngày bắt đầu không được lớn hơn "
                        + "ngày kết thúc.";
                }

                if (message) {

                    event.preventDefault();

                    errorText.textContent = message;
                    errorBox.style.display = "flex";

                } else {

                    clearError();
                }
            }
        );
    }

    function formatVND(value) {

        return new Intl.NumberFormat("vi-VN", {
            style: "currency",
            currency: "VND",
            maximumFractionDigits: 0
        }).format(value);
    }


    const revenueData = [

        <c:forEach
            var="row"
            items="${revenueByDate}"
            varStatus="loop">

            {
                date: "${row[0]}",
                revenue: ${row[1]}
            }<c:if test="${not loop.last}">,</c:if>

        </c:forEach>

    ];

    const revenueCanvas =
            document.getElementById("revenueChart");

    if (
        typeof Chart !== "undefined"
        && revenueCanvas
        && revenueData.length > 0
    ) {

        const ctx = revenueCanvas.getContext("2d");

        const gradient =
                ctx.createLinearGradient(0, 0, 0, 325);

        gradient.addColorStop(
            0,
            "rgba(37, 99, 235, 0.22)"
        );

        gradient.addColorStop(
            1,
            "rgba(37, 99, 235, 0.01)"
        );

        const labels = revenueData.map(
            item => item.date
        );

        const values = revenueData.map(
            item => Number(item.revenue)
        );

        new Chart(revenueCanvas, {

            type: "line",

            data: {

                labels: labels,

                datasets: [{

                    label: "Giá trị đơn hoàn thành",

                    data: values,

                    borderColor: "#2563eb",

                    backgroundColor: gradient,

                    borderWidth: 3,

                    tension: 0.35,

                    fill: true,

                    pointRadius: 3,

                    pointHoverRadius: 6,

                    pointBackgroundColor: "#ffffff",

                    pointBorderColor: "#2563eb",

                    pointBorderWidth: 2

                }]
            },

            options: {

                responsive: true,

                maintainAspectRatio: false,

                interaction: {
                    mode: "index",
                    intersect: false
                },

                plugins: {

                    legend: {
                        display: false
                    },

                    tooltip: {

                        callbacks: {

                            label: function (context) {

                                return "Giá trị: "
                                    + formatVND(context.parsed.y);
                            }
                        }
                    }
                },

                scales: {

                    x: {

                        grid: {
                            display: false
                        },

                        ticks: {
                            color: "#64748b",
                            maxTicksLimit: 9
                        }
                    },

                    y: {

                        beginAtZero: true,

                        ticks: {

                            color: "#64748b",

                            callback: function (value) {

                                return new Intl.NumberFormat(
                                    "vi-VN",
                                    {
                                        notation: "compact",
                                        maximumFractionDigits: 1
                                    }
                                ).format(value) + " ₫";
                            }
                        },

                        grid: {
                            color: "#f1f5f9"
                        }
                    }
                }
            }
        });
    }

    const orderStatusData = [

        <c:forEach
            var="row"
            items="${orderStatusStatistics}"
            varStatus="loop">

            {
                status: "${row[0]}",
                total: ${row[1]}
            }<c:if test="${not loop.last}">,</c:if>

        </c:forEach>

    ];

    const statusNames = {

        "PENDING_CONFIRMATION": "Chờ xác nhận",

        "PENDING": "Chờ xác nhận",

        "CONFIRMED": "Đã xác nhận",

        "PACKING": "Đang đóng gói",

        "SHIPPING": "Đang giao hàng",

        "COMPLETED": "Hoàn thành",

        "CANCELLED": "Đã hủy"
    };

    const statusColors = {

        "PENDING_CONFIRMATION": "#f59e0b",

        "PENDING": "#f59e0b",

        "CONFIRMED": "#3b82f6",

        "PACKING": "#8b5cf6",

        "SHIPPING": "#06b6d4",

        "COMPLETED": "#22c55e",

        "CANCELLED": "#ef4444"
    };

    const statusCanvas =
            document.getElementById("orderStatusChart");

    if (
        typeof Chart !== "undefined"
        && statusCanvas
        && orderStatusData.length > 0
    ) {

        const statusLabels = orderStatusData.map(
            item => statusNames[item.status] || item.status
        );

        const statusValues = orderStatusData.map(
            item => Number(item.total)
        );

        const colors = orderStatusData.map(
            item => statusColors[item.status] || "#94a3b8"
        );

        const totalOrdersInChart =
            statusValues.reduce(
                (sum, value) => sum + value,
                0
            );


        const centerTotalPlugin = {

            id: "dashboardCenterTotal",

            afterDraw: function (chart) {

                const meta = chart.getDatasetMeta(0);

                if (
                    !meta.data
                    || meta.data.length === 0
                ) {
                    return;
                }

                const ctx = chart.ctx;

                const centerX = meta.data[0].x;
                const centerY = meta.data[0].y;

                ctx.save();

                ctx.textAlign = "center";
                ctx.textBaseline = "middle";

                ctx.fillStyle = "#0f172a";
                ctx.font = "700 29px Inter, sans-serif";

                ctx.fillText(
                    totalOrdersInChart,
                    centerX,
                    centerY - 10
                );

                ctx.fillStyle = "#64748b";
                ctx.font = "12px Inter, sans-serif";

                ctx.fillText(
                    "Tổng đơn",
                    centerX,
                    centerY + 18
                );

                ctx.restore();
            }
        };


        new Chart(statusCanvas, {

            type: "doughnut",

            plugins: [centerTotalPlugin],

            data: {

                labels: statusLabels,

                datasets: [{

                    data: statusValues,

                    backgroundColor: colors,

                    borderColor: "#ffffff",

                    borderWidth: 3,

                    hoverOffset: 8

                }]
            },

            options: {

                responsive: true,

                maintainAspectRatio: false,

                cutout: "68%",

                plugins: {

                    legend: {

                        position: "bottom",

                        labels: {

                            usePointStyle: true,

                            boxWidth: 10,

                            padding: 12,

                            font: {
                                size: 11
                            }
                        }
                    },

                    tooltip: {

                        callbacks: {

                            label: function (context) {

                                const count = context.parsed;

                                const percent =
                                    totalOrdersInChart > 0
                                        ? (
                                            count
                                            / totalOrdersInChart
                                            * 100
                                        ).toFixed(1)
                                        : "0.0";

                                return " "
                                    + context.label
                                    + ": "
                                    + count
                                    + " đơn ("
                                    + percent
                                    + "%)";
                            }
                        }
                    }
                }
            }
        });
    }

});
</script>

<%@ include file="/WEB-INF/include/footer.jsp" %>
