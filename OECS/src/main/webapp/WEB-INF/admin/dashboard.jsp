<%@ page pageEncoding="UTF-8" %>
<%@include file="/WEB-INF/include/header.jsp" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>


<style>
    /* ========== DASHBOARD PAGE ========== */

    .dashboard-page {
        width: 100%;
        display: flex;
        flex-direction: column;
        gap: 22px;
        padding: 12px 0 30px;
        font-family: 'Inter', sans-serif;
    }

    .dashboard-page * {
        box-sizing: border-box;
    }

    /* ========== PAGE HEADING ========== */

    .dashboard-heading {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 16px;
        flex-wrap: wrap;
    }

    .dashboard-heading h1 {
        font-size: 24px;
        font-weight: 700;
        color: #0f172a;
        margin: 0 0 6px;
    }

    .dashboard-heading p {
        font-size: 14px;
        color: #64748b;
        margin: 0;
    }

    /* ========== SIX KPI CARDS ========== */

    .kpi-container {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 16px;
    }

    .kpi-card-dashboard {
        min-width: 0;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        padding: 22px;
        box-shadow: 0 2px 8px rgba(15, 23, 42, 0.035);
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 12px;
        transition: box-shadow .2s ease,
            transform .2s ease;
    }

    .kpi-card-dashboard:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 18px rgba(15, 23, 42, .08);
    }

    .kpi-card-content {
        flex: 1;
        min-width: 0;
    }

    .kpi-title-dashboard {
        font-size: 13px;
        font-weight: 500;
        color: #64748b;
        margin-bottom: 10px;
    }

    .kpi-value-dashboard {
        font-size: clamp(19px, 2vw, 27px);
        font-weight: 700;
        color: #0f172a;
        line-height: 1.3;
        overflow-wrap: anywhere;
        font-variant-numeric: tabular-nums;
    }

    .kpi-icon-dashboard {
        width: 46px;
        height: 46px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 22px;
        flex-shrink: 0;
    }

    .kpi-icon-dashboard.blue {
        color: #2563eb;
        background: #eff6ff;
    }

    .kpi-icon-dashboard.green {
        color: #16a34a;
        background: #f0fdf4;
    }

    .kpi-icon-dashboard.orange {
        color: #d97706;
        background: #fffbeb;
    }

    .kpi-icon-dashboard.red {
        color: #dc2626;
        background: #fef2f2;
    }

    .kpi-icon-dashboard.purple {
        color: #7c3aed;
        background: #f5f3ff;
    }

    /* ========== CHART CARDS ========== */

    .dashboard-chart-card {
        min-width: 0;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        padding: 22px;
        box-shadow: 0 2px 8px rgba(15, 23, 42, .035);
    }

    .dashboard-chart-title {
        font-size: 17px;
        font-weight: 600;
        color: #0f172a;
        margin: 0 0 8px;
    }

    .dashboard-chart-description {
        font-size: 13px;
        color: #64748b;
        margin-bottom: 18px;
    }


    .dashboard-date-filter {
        display: flex;
        align-items: flex-end;
        flex-wrap: wrap;
        gap: 12px;
        margin-bottom: 22px;
    }

    .dashboard-date-field {
        display: flex;
        flex-direction: column;
        gap: 6px;
    }

    .dashboard-date-field label {
        color: #64748b;
        font-size: 12px;
        font-weight: 600;
    }

    .dashboard-date-field input {
        height: 40px;
        padding: 0 12px;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        background: #fff;
        color: #0f172a;
        font: inherit;
        font-size: 13px;
    }

    .dashboard-filter-btn,
    .dashboard-reset-btn {
        height: 40px;
        padding: 0 16px;
        border-radius: 8px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 7px;
        font-size: 13px;
        font-weight: 600;
        text-decoration: none;
        cursor: pointer;
    }

    .dashboard-filter-btn {
        background: #2563eb;
        color: white;
        border: 1px solid #2563eb;
    }

    .dashboard-reset-btn {
        background: white;
        color: #475569;
        border: 1px solid #e2e8f0;
    }

    .dashboard-date-error {
        color: #dc2626;
        font-size: 13px;
        margin: 0 0 16px;
    }


    /* ========== REVENUE CHART ========== */

    .revenue-card-dashboard {
        width: 100%;
    }

    .revenue-chart-wrapper {
        position: relative;
        width: 100%;
        height: 320px;
    }


    .revenue-empty-state {
        height: 320px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        text-align: center;
        gap: 10px;
        color: #64748b;
    }

    .revenue-empty-state i {
        font-size: 42px;
        color: #94a3b8;
    }

    .revenue-empty-state h3 {
        margin: 0;
        font-size: 17px;
        font-weight: 600;
        color: #334155;
    }

    .revenue-empty-state p {
        margin: 0;
        font-size: 13px;
        color: #64748b;
    }


    /* ========== BOTTOM SECTION ========== */

    .bottom-charts-dashboard {
        display: grid;
        grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
        gap: 16px;
        align-items: stretch;
    }

    .small-chart-wrapper {
        position: relative;
        width: 100%;
        height: 260px;
    }

    /* ========== TOP SELLING TABLE ========== */

    .top-products-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 13px;
    }

    .top-products-table th {
        padding: 12px 10px;
        text-align: left;
        color: #64748b;
        font-weight: 600;
        border-bottom: 1px solid #e2e8f0;
    }

    .top-products-table td {
        padding: 14px 10px;
        color: #334155;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .top-products-table tbody tr:last-child td {
        border-bottom: none;
    }

    .top-products-table th:last-child,
    .top-products-table td:last-child {
        text-align: right;
    }

    .top-product-rank {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 28px;
        height: 28px;
        border-radius: 8px;
        background: #f1f5f9;
        color: #475569;
        font-weight: 700;
    }

    .top-products-table tbody tr:nth-child(1) .top-product-rank {
        background: #fef3c7;
        color: #92400e;
    }

    .top-products-table tbody tr:nth-child(2) .top-product-rank {
        background: #e2e8f0;
        color: #475569;
    }

    .top-products-table tbody tr:nth-child(3) .top-product-rank {
        background: #ffedd5;
        color: #9a3412;
    }

    .top-product-quantity {
        font-weight: 700;
        color: #0f172a;
    }

    /* ========== RESPONSIVE ========== */

    @media (max-width: 991px) {
        .kpi-container {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }

        .bottom-charts-dashboard {
            grid-template-columns: 1fr;
        }
    }

    @media (max-width: 575px) {
        .dashboard-page {
            gap: 16px;
        }

        .dashboard-heading h1 {
            font-size: 21px;
        }

        .kpi-container {
            grid-template-columns: 1fr;
        }

        .kpi-card-dashboard,
        .dashboard-chart-card {
            padding: 16px;
        }

        .revenue-chart-wrapper {
            height: 260px;
        }

        .small-chart-wrapper {
            height: 240px;
        }
    }
</style>



<!-- ================= DASHBOARD ================= -->

<div class="dashboard-page">

    <!-- PAGE HEADING -->
    <div class="dashboard-heading">
        <div>
            <h1>Tổng quan kinh doanh</h1>
            <p>
                Theo dõi doanh thu, đơn hàng và
                hoạt động bán hàng của hệ thống OECS.
            </p>
        </div>
    </div>

    <!-- ================= SIX KPI ================= -->
    <div class="kpi-container">

        <!-- 1. TOTAL REVENUE -->
        <div class="kpi-card-dashboard">
            <div class="kpi-card-content">
                <div class="kpi-title-dashboard">
                    Tổng doanh thu
                </div>
                <div class="kpi-value-dashboard">
                    <fmt:formatNumber
                        value="${totalRevenue}"
                        pattern="#,##0"/> ₫
                </div>
            </div>
            <div class="kpi-icon-dashboard blue">
                <i class="bi bi-cash-stack"></i>
            </div>
        </div>

        <!-- 2. TOTAL ORDERS -->
        <div class="kpi-card-dashboard">
            <div class="kpi-card-content">
                <div class="kpi-title-dashboard">
                    Tổng đơn hàng
                </div>
                <div class="kpi-value-dashboard">
                    ${totalOrders}
                </div>
            </div>
            <div class="kpi-icon-dashboard purple">
                <i class="bi bi-bag-check"></i>
            </div>
        </div>

        <!-- 3. COMPLETED ORDERS -->
        <div class="kpi-card-dashboard">
            <div class="kpi-card-content">
                <div class="kpi-title-dashboard">
                    Đơn hàng hoàn thành
                </div>
                <div class="kpi-value-dashboard">
                    ${completedOrders}
                </div>
            </div>
            <div class="kpi-icon-dashboard green">
                <i class="bi bi-check-circle"></i>
            </div>
        </div>

        <!-- 4. PENDING ORDERS -->
        <div class="kpi-card-dashboard">
            <div class="kpi-card-content">
                <div class="kpi-title-dashboard">
                    Chờ xác nhận
                </div>
                <div class="kpi-value-dashboard">
                    ${pendingOrders}
                </div>
            </div>
            <div class="kpi-icon-dashboard orange">
                <i class="bi bi-clock-history"></i>
            </div>
        </div>

        <!-- 5. CANCELLED ORDERS -->
        <div class="kpi-card-dashboard">
            <div class="kpi-card-content">
                <div class="kpi-title-dashboard">
                    Đơn hàng đã hủy
                </div>
                <div class="kpi-value-dashboard">
                    ${cancelledOrders}
                </div>
            </div>
            <div class="kpi-icon-dashboard red">
                <i class="bi bi-x-circle"></i>
            </div>
        </div>

        <!-- 6. PRODUCTS SOLD -->
        <div class="kpi-card-dashboard">
            <div class="kpi-card-content">
                <div class="kpi-title-dashboard">
                    Sản phẩm đã bán
                </div>
                <div class="kpi-value-dashboard">
                    ${totalProductsSold}
                </div>
            </div>
            <div class="kpi-icon-dashboard blue">
                <i class="bi bi-box-seam"></i>
            </div>
        </div>

    </div>

    <!-- ================= REVENUE CHART ================= -->

    <div class="dashboard-chart-card revenue-card-dashboard">
        <h2 class="dashboard-chart-title">
            <i class="bi bi-graph-up-arrow me-2"></i>
            Doanh thu theo thời gian
        </h2>

        <p class="dashboard-chart-description">
            Doanh thu từ các đơn hàng đã hoàn thành,
            thống kê theo ngày tạo đơn.
        </p>

        <form method="get"
              action="${pageContext.request.contextPath}/admin/dashboard"
              class="dashboard-date-filter">

            <div class="dashboard-date-field">
                <label for="startDate">Từ ngày</label>
                <input type="date"
                       id="startDate"
                       name="startDate"
                       value="${startDate}"
                       required>
            </div>

            <div class="dashboard-date-field">
                <label for="endDate">Đến ngày</label>
                <input type="date"
                       id="endDate"
                       name="endDate"
                       value="${endDate}"
                       required>
            </div>

            <button type="submit" class="dashboard-filter-btn">
                <i class="bi bi-funnel"></i>
                Lọc
            </button>

            <a href="${pageContext.request.contextPath}/admin/dashboard"
               class="dashboard-reset-btn">
                <i class="bi bi-arrow-counterclockwise"></i>
                Đặt lại
            </a>
        </form>

        <c:if test="${not empty dateError}">
            <p class="dashboard-date-error">
                <c:out value="${dateError}"/>
            </p>
        </c:if>


        <c:choose>
            <c:when test="${empty revenueByDate}">
                <div class="revenue-empty-state">
                    <i class="bi bi-bar-chart-line"></i>
                    <h3>Không có dữ liệu doanh thu</h3>
                    <p>
                        Không có đơn hàng hoàn thành
                        trong khoảng thời gian đã chọn.
                    </p>
                </div>
            </c:when>

            <c:otherwise>
                <div class="revenue-chart-wrapper">
                    <canvas id="revenueChart"></canvas>
                </div>
            </c:otherwise>
        </c:choose>

    </div>


    <!-- ================= BOTTOM SECTION ================= -->

    <div class="bottom-charts-dashboard">

        <!-- ORDER STATUS CHART -->
        <div class="dashboard-chart-card">

            <h2 class="dashboard-chart-title">
                <i class="bi bi-pie-chart me-2"></i>
                Trạng thái đơn hàng
            </h2>

            <p class="dashboard-chart-description">
                Thống kê số lượng đơn hàng theo từng trạng thái
            </p>

            <div class="small-chart-wrapper">
                <canvas id="orderStatusChart"></canvas>
            </div>

        </div>

        <!-- TOP 5 BEST SELLING PRODUCTS -->
        <div class="dashboard-chart-card">

            <h2 class="dashboard-chart-title">
                <i class="bi bi-trophy me-2"></i>
                Top 5 sản phẩm bán chạy
            </h2>

            <p class="dashboard-chart-description">
                Xếp hạng theo số lượng bán từ đơn hàng hoàn thành
            </p>

            <div class="table-responsive">

                <table class="top-products-table">

                    <thead>
                        <tr>
                        <th style="width: 65px;">Hạng</th>
                        <th>Tên sản phẩm</th>
                        <th style="width: 95px;">Đã bán</th>
                        </tr>
                    </thead>

                    <tbody>

                        <c:forEach var="product"
                                   items="${topSellingProducts}"
                                   varStatus="loop">

                            <tr>
                            <td>
                            <span class="top-product-rank">
                                ${loop.index + 1}
                            </span>
                            </td>

                            <td>
                                <c:out value="${product[0]}"/>
                            </td>

                            <td>
                            <span class="top-product-quantity">
                                <fmt:formatNumber
                                    value="${product[1]}"
                                    pattern="#,##0"/>
                            </span>
                            </td>
                            </tr>

                        </c:forEach>

                        <c:if test="${empty topSellingProducts}">
                            <tr>
                            <td colspan="3"
                                class="text-center text-muted py-4">
                                Chưa có sản phẩm bán ra
                            </td>
                            </tr>
                        </c:if>

                    </tbody>

                </table>

            </div>

        </div>

    </div>


</div>

<!-- ================= CHART.JS ================= -->

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>


<!-- ================= REVENUE CHART ================= -->

<script>
    const revenueData = [
    <c:forEach var="row"
               items="${revenueByDate}"
               varStatus="loop">
    {
    date: "${row[0]}",
            revenue: ${row[1]}
    }<c:if test="${!loop.last}">,</c:if>
    </c:forEach>
    ];
    const revenueLabels = revenueData.map(item => item.date);
    const revenueValues = revenueData.map(item => item.revenue);
    const formatVND = (value) => {
    return new Intl.NumberFormat("vi-VN", {
    style: "currency",
            currency: "VND",
            maximumFractionDigits: 0
    }).format(value);
    };
    const revenueCanvas = document.getElementById("revenueChart");
    const revenueCtx = revenueCanvas.getContext("2d");
    if (revenueCanvas) {
    const revenueGradient = revenueCtx.createLinearGradient(
            0, 0, 0, 320
            );
    revenueGradient.addColorStop(0, "rgba(37, 99, 235, 0.20)");
    revenueGradient.addColorStop(1, "rgba(37, 99, 235, 0.01)");
    new Chart(revenueCanvas, {
    type: "line",
            data: {
            labels: revenueLabels,
                    datasets: [{
                    label: "Doanh thu",
                            data: revenueValues,
                            borderColor: "#2563eb",
                            backgroundColor: revenueGradient,
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
                            backgroundColor: "#0f172a",
                                    padding: 12,
                                    cornerRadius: 8,
                                    callbacks: {
                                    label: function(context) {
                                    return "Doanh thu: "
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
                                    maxRotation: 45,
                                    autoSkip: true,
                                    maxTicksLimit: 10
                            }
                    },
                            y: {
                            beginAtZero: true,
                                    border: {
                                    display: false
                                    },
                                    grid: {
                                    color: "#f1f5f9"
                                    },
                                    ticks: {
                                    color: "#64748b",
                                            callback: function(value) {
                                            return new Intl.NumberFormat(
                                                    "vi-VN", {
                                                    notation: "compact",
                                                            maximumFractionDigits: 1
                                                    }
                                            ).format(value) + " ₫";
                                            }
                                    }
                            }
                    }
            }
    });
    }
</script>





<!-- ================= ORDER STATUS CHART ================= -->

<script>
    // Lấy dữ liệu trạng thái đơn hàng từ Servlet
    const orderStatusData = [
    <c:forEach var="row"
               items="${orderStatusStatistics}"
               varStatus="loop">
    {
    status: "${row[0]}",
            total: ${row[1]}
    }<c:if test="${!loop.last}">,</c:if>
    </c:forEach>
    ];
    // Tên tiếng Việt cho từng trạng thái
    const statusNames = {
    "PENDING_CONFIRMATION": "Chờ xác nhận",
            "CONFIRMED": "Đã xác nhận",
            "PACKING": "Đang đóng gói",
            "SHIPPING": "Đang giao",
            "COMPLETED": "Hoàn thành",
            "CANCELLED": "Đã hủy"
    };
    // Màu sắc cho từng trạng thái
    const statusColors = {
    "PENDING_CONFIRMATION": "#f59e0b",
            "CONFIRMED": "#3b82f6",
            "PACKING": "#8b5cf6",
            "SHIPPING": "#06b6d4",
            "COMPLETED": "#22c55e",
            "CANCELLED": "#ef4444"
    };
    // Chuẩn bị dữ liệu cho biểu đồ
    const orderStatusLabels = orderStatusData.map(
            item => statusNames[item.status] || item.status
            );
    const orderStatusValues = orderStatusData.map(
            item => Number(item.total)
            );
    const orderStatusColors = orderStatusData.map(
            item => statusColors[item.status] || "#94a3b8"
            );
    // Tổng số đơn hàng từ database
    const totalOrdersInChart = orderStatusValues.reduce(
            (sum, value) => sum + value, 0
            );
    // Plugin hiển thị tổng đơn giữa Doughnut
    const centerTotalPlugin = {
    id: "centerTotal",
            afterDraw(chart) {
    const {ctx} = chart;
    const meta = chart.getDatasetMeta(0);
    if (!meta.data || meta.data.length === 0) {
    return;
    }

    const centerX = meta.data[0].x;
    const centerY = meta.data[0].y;
    ctx.save();
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    // Hiển thị số tổng đơn
    ctx.fillStyle = "#0f172a";
    ctx.font = "700 30px Inter, sans-serif";
    ctx.fillText(
            totalOrdersInChart,
            centerX,
            centerY - 10
            );
    // Hiển thị chữ Tổng đơn
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
    // Khởi tạo biểu đồ Doughnut
    new Chart(
            document.getElementById("orderStatusChart"),
    {
    type: "doughnut",
            // Đăng ký plugin
            plugins: [centerTotalPlugin],
            data: {
            labels: orderStatusLabels,
                    datasets: [{
                    data: orderStatusValues,
                            backgroundColor: orderStatusColors,
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
                                    padding: 15,
                                    font: {
                                    size: 12
                                    }
                            }
                    },
                            tooltip: {
                            callbacks: {
                            label: function(context) {
                            const count = context.parsed;
                            const percent =
                                    totalOrdersInChart > 0
                                    ? (
                                            count / totalOrdersInChart * 100
                                            ).toFixed(1)
                                    : "0.0";
                            return " " + context.label
                                    + ": " + count
                                    + " đơn (" + percent + "%)";
                            }
                            }
                            }
                    }
            }
    }
    );
</script>



<%@include file="/WEB-INF/include/footer.jsp" %>