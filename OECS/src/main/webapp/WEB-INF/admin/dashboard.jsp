<%@ page pageEncoding="UTF-8" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    /* ================= DASHBOARD ================= */

    .dashboard-page {
        width: 100%;
        min-height: calc(100vh - 150px);
        display: flex;
        flex-direction: column;
        gap: 15px;
        padding-top: 5px;
    }

    /* ================= KPI ================= */

    .kpi-container {
        width: 100%;
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 15px;
        flex-shrink: 0;
    }

    .kpi-card-dashboard {
        min-width: 0;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        padding: 18px 22px;
        box-shadow: 0 2px 6px rgba(15, 23, 42, .04);
        display: flex;
        flex-direction: column;
        justify-content: center;
    }

    .kpi-title-dashboard {
        font-size: 14px;
        color: #64748b;
        margin-bottom: 10px;
        font-weight: 500;
    }

    .kpi-value-dashboard {
        font-size: 25px;
        font-weight: 700;
        color: #0f172a;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    /* ================= CHART CARD ================= */

    .dashboard-chart-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        padding: 15px 20px;
        box-shadow: 0 2px 6px rgba(15, 23, 42, .04);
        min-width: 0;
        min-height: 0;
        overflow: hidden;
    }

    .dashboard-chart-title {
        margin: 0 0 10px 0;
        font-size: 17px;
        font-weight: 600;
        color: #0f172a;
    }

    /* ================= REVENUE ================= */

    .revenue-card-dashboard {
        width: 100%;
        height: 390px;
    }

    .revenue-chart-wrapper {
        position: relative;
        width: 100%;
        height: 330px;
    }

    /* ================= BOTTOM ================= */

    .bottom-charts-dashboard {
        width: 100%;
        height: 300px;
        display: grid;
        grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
        gap: 15px;
    }

    .small-chart-wrapper {
        position: relative;
        width: 100%;
        height: 245px;
    }

    /* ================= RESPONSIVE ================= */

    @media (max-width: 900px) {

        .kpi-container {
            grid-template-columns: 1fr;
        }

        .revenue-card-dashboard {
            height: 400px;
        }

        .revenue-chart-wrapper {
            height: 330px;
        }

        .bottom-charts-dashboard {
            height: auto;
            grid-template-columns: 1fr;
        }

        .small-chart-wrapper {
            height: 300px;
        }
    }
</style>


<!-- ================= DASHBOARD ================= -->

<div class="dashboard-page">

    <!-- ================= KPI ================= -->

    <div class="kpi-container">

        <div class="kpi-card-dashboard">

            <div class="kpi-title-dashboard">
                Tổng doanh thu
            </div>

            <div class="kpi-value-dashboard">
                ${totalRevenue} VNĐ
            </div>

        </div>


        <div class="kpi-card-dashboard">

            <div class="kpi-title-dashboard">
                Tổng số đơn hàng
            </div>

            <div class="kpi-value-dashboard">
                ${totalOrders}
            </div>

        </div>


        <div class="kpi-card-dashboard">

            <div class="kpi-title-dashboard">
                Đơn hàng hoàn thành
            </div>

            <div class="kpi-value-dashboard">
                ${completedOrders}
            </div>

        </div>

    </div>


    <!-- ================= REVENUE CHART ================= -->

    <div class="dashboard-chart-card revenue-card-dashboard">

        <h2 class="dashboard-chart-title">
            Doanh thu theo thời gian
        </h2>

        <div class="revenue-chart-wrapper">

            <canvas id="revenueChart"></canvas>

        </div>

    </div>


    <!-- ================= BOTTOM CHARTS ================= -->

    <div class="bottom-charts-dashboard">

        <!-- TOP PRODUCTS -->

        <div class="dashboard-chart-card">

            <h2 class="dashboard-chart-title">
                Top sản phẩm bán chạy
            </h2>

            <div class="small-chart-wrapper">

                <canvas id="productChart"></canvas>

            </div>

        </div>


        <!-- ORDER STATUS -->

        <div class="dashboard-chart-card">

            <h2 class="dashboard-chart-title">
                Tỉ lệ đơn hàng
            </h2>

            <div class="small-chart-wrapper">

                <canvas id="orderStatusChart"></canvas>

            </div>

        </div>

    </div>

</div>


<!-- ================= CHART.JS ================= -->

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>


<!-- ================= REVENUE CHART ================= -->

<script>

    const revenueData = [

    <c:forEach
        var="row"
        items="${revenueByDate}"
        varStatus="status">

    {
    date: "${row[0]}",
            revenue: ${row[1]}
    }

        <c:if test="${!status.last}">
    ,
        </c:if>

    </c:forEach>

    ];
    const revenueLabels =
            revenueData.map(item => item.date);
    const revenueValues =
            revenueData.map(item => item.revenue);
    new Chart(
            document.getElementById("revenueChart"),
    {
    type: "line",
            data: {
            labels: revenueLabels,
                    datasets: [
                    {
                    label: "Doanh thu",
                            data: revenueValues,
                            borderWidth: 2,
                            pointRadius: 3,
                            pointHoverRadius: 5,
                            tension: 0.3,
                            fill: false
                    }
                    ]
            },
            options: {

            responsive: true,
                    maintainAspectRatio: false,
                    plugins: {

                    legend: {
                    display: true,
                            position: "top"
                    }

                    },
                    scales: {

                    x: {
                    grid: {
                    display: false
                    }
                    },
                            y: {
                            beginAtZero: true
                            }

                    }

            }

    }

    );</script>


<!-- ================= PRODUCT CHART ================= -->

<script>

    const productData = [

    <c:forEach
        var="row"
        items="${topSellingProducts}"
        varStatus="status">

    {
    name: "${row[0]}",
            quantity: ${row[1]}
    }

        <c:if test="${!status.last}">
    ,
        </c:if>

    </c:forEach>

    ];
    const productLabels =
            productData.map(item => item.name);
    const productValues =
            productData.map(item => item.quantity);
    new Chart(
            document.getElementById("productChart"),
    {
    type: "bar",
            data: {

            labels: productLabels,
                    datasets: [
                    {
                    label: "Số lượng bán",
                            data: productValues,
                            borderWidth: 1
                    }
                    ]

            },
            options: {

            responsive: true,
                    maintainAspectRatio: false,
                    plugins: {

                    legend: {
                    display: true,
                            position: "top"
                    }

                    },
                    scales: {

                    x: {
                    grid: {
                    display: false
                    }
                    },
                            y: {

                            beginAtZero: true,
                                    ticks: {
                                    precision: 0
                                    }

                            }

                    }

            }

    }

    );</script>


<!-- ================= ORDER STATUS CHART ================= -->

<script>

    const orderStatusData = [

    <c:forEach
        var="row"
        items="${orderStatusStatistics}"
        varStatus="status">

    {
    status: "${row[0]}",
            total: ${row[1]}
    }

        <c:if test="${!status.last}">
    ,
        </c:if>

    </c:forEach>

    ];
    const orderStatusLabels =
            orderStatusData.map(item => item.status);
    const orderStatusValues =
            orderStatusData.map(item => item.total);
    new Chart(
            document.getElementById("orderStatusChart"),
    {
    type: "pie",
            data: {

            labels: orderStatusLabels,
                    datasets: [
                    {
                    label: "Số đơn hàng",
                            data: orderStatusValues,
                            borderWidth: 1
                    }
                    ]

            },
            options: {

            responsive: true,
                    maintainAspectRatio: false,
                    plugins: {

                    legend: {
                    position: "bottom"
                    }

                    }

            }

    }

    );

</script>


<%@include file="/WEB-INF/include/footer.jsp" %>