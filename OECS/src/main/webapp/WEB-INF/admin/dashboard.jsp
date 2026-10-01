<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html>
<head>

    <meta charset="UTF-8">

    <title>Admin Dashboard</title>

    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>


    <style>

        /* =========================================
           RESET
           ========================================= */

        * {
            box-sizing: border-box;
        }


        html,
        body {
            width: 100%;
            height: 100%;

            margin: 0;
            padding: 0;
        }


        body {
            font-family: Arial, Helvetica, sans-serif;

            background-color: #f4f6f8;

            color: #222;

            overflow: hidden;
        }


        /* =========================================
           HEADER
           ========================================= */

        .header {

            width: 100%;
            height: 65px;

            background-color: #ffffff;

            border-bottom: 1px solid #e5e5e5;

            display: flex;
            align-items: center;

            padding: 0 30px;

            flex-shrink: 0;
        }


        .header h1 {

            margin: 0;

            font-size: 24px;

            font-weight: 600;

            color: #222;
        }


        /* =========================================
           MAIN CONTAINER
           ========================================= */

        .container {

            width: 100%;

            height: calc(100vh - 65px);

            padding: 18px 25px;

            display: flex;

            flex-direction: column;

            gap: 15px;

            overflow: hidden;
        }


        /* =========================================
           KPI
           ========================================= */

        .kpi-container {

            width: 100%;

            height: 105px;

            display: grid;

            grid-template-columns:
                repeat(3, minmax(0, 1fr));

            gap: 15px;

            flex-shrink: 0;
        }


        .kpi-card {

            min-width: 0;

            background-color: #ffffff;

            border: 1px solid #e3e6e8;

            border-radius: 10px;

            padding: 18px 22px;

            box-shadow:
                0 2px 6px rgba(0, 0, 0, 0.04);

            display: flex;

            flex-direction: column;

            justify-content: center;
        }


        .kpi-title {

            font-size: 14px;

            color: #777;

            margin-bottom: 10px;
        }


        .kpi-value {

            font-size: 25px;

            font-weight: 700;

            color: #222;

            white-space: nowrap;

            overflow: hidden;

            text-overflow: ellipsis;
        }


        /* =========================================
           GENERAL CHART CARD
           ========================================= */

        .chart-container {

            background-color: #ffffff;

            border: 1px solid #e3e6e8;

            border-radius: 10px;

            padding: 15px 20px;

            box-shadow:
                0 2px 6px rgba(0, 0, 0, 0.04);

            min-width: 0;

            min-height: 0;

            overflow: hidden;
        }


        .chart-title {

            margin: 0 0 10px 0;

            font-size: 17px;

            font-weight: 600;

            color: #222;
        }


        /* =========================================
           REVENUE CHART
           ========================================= */

        .revenue-card {

            width: 100%;

            flex: 1;

            min-height: 0;
        }


        .revenue-chart-wrapper {

            position: relative;

            width: 100%;

            height: calc(100% - 30px);

            min-height: 0;
        }


        /* =========================================
           BOTTOM CHARTS
           ========================================= */

        .bottom-charts {

            width: 100%;

            height: 250px;

            display: grid;

            grid-template-columns:
                minmax(0, 1fr)
                minmax(0, 1fr);

            gap: 15px;

            flex-shrink: 0;

            min-height: 0;
        }


        .small-chart-wrapper {

            position: relative;

            width: 100%;

            height: calc(100% - 30px);

            min-height: 0;
        }


        /* =========================================
           MOBILE / SMALL SCREEN
           ========================================= */

        @media (max-width: 900px) {

            body {
                overflow: auto;
            }


            .container {

                height: auto;

                min-height: calc(100vh - 65px);

                overflow: visible;
            }


            .kpi-container {

                height: auto;

                grid-template-columns: 1fr;
            }


            .bottom-charts {

                height: auto;

                grid-template-columns: 1fr;
            }


            .revenue-card {

                height: 400px;

                flex: none;
            }


            .revenue-chart-wrapper {

                height: 340px;
            }


            .small-chart-wrapper {

                height: 300px;
            }

        }

    </style>

</head>


<body>


    <!-- =========================================
         HEADER
         ========================================= -->

    <div class="header">

        <h1>
            Admin Dashboard
        </h1>

    </div>


    <!-- =========================================
         MAIN
         ========================================= -->

    <div class="container">


        <!-- =====================================
             KPI
             ===================================== -->

        <div class="kpi-container">


            <!-- TOTAL REVENUE -->

            <div class="kpi-card">

                <div class="kpi-title">
                    Tổng doanh thu
                </div>

                <div class="kpi-value">
                    ${totalRevenue} VNĐ
                </div>

            </div>


            <!-- TOTAL ORDERS -->

            <div class="kpi-card">

                <div class="kpi-title">
                    Tổng số đơn hàng
                </div>

                <div class="kpi-value">
                    ${totalOrders}
                </div>

            </div>


            <!-- COMPLETED ORDERS -->

            <div class="kpi-card">

                <div class="kpi-title">
                    Đơn hàng hoàn thành
                </div>

                <div class="kpi-value">
                    ${completedOrders}
                </div>

            </div>


        </div>


        <!-- =====================================
             REVENUE CHART
             ===================================== -->

        <div class="chart-container revenue-card">


            <h2 class="chart-title">
                Doanh thu theo thời gian
            </h2>


            <div class="revenue-chart-wrapper">

                <canvas id="revenueChart"></canvas>

            </div>


        </div>


        <!-- =====================================
             BOTTOM CHARTS
             ===================================== -->

        <div class="bottom-charts">


            <!-- =================================
                 TOP PRODUCTS
                 ================================= -->

            <div class="chart-container">


                <h2 class="chart-title">
                    Top sản phẩm bán chạy
                </h2>


                <div class="small-chart-wrapper">

                    <canvas id="productChart"></canvas>

                </div>


            </div>


            <!-- =================================
                 ORDER STATUS
                 ================================= -->

            <div class="chart-container">


                <h2 class="chart-title">
                    Tỉ lệ đơn hàng
                </h2>


                <div class="small-chart-wrapper">

                    <canvas id="orderStatusChart"></canvas>

                </div>


            </div>


        </div>


    </div>


    <!-- =========================================
         REVENUE CHART SCRIPT
         ========================================= -->

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
            revenueData.map(
                item => item.date
            );


        const revenueValues =
            revenueData.map(
                item => item.revenue
            );


        new Chart(

            document.getElementById(
                "revenueChart"
            ),

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

        );


    </script>


    <!-- =========================================
         PRODUCT CHART SCRIPT
         ========================================= -->

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
            productData.map(
                item => item.name
            );


        const productValues =
            productData.map(
                item => item.quantity
            );


        new Chart(

            document.getElementById(
                "productChart"
            ),

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

        );


    </script>


    <!-- =========================================
         ORDER STATUS CHART SCRIPT
         ========================================= -->

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
            orderStatusData.map(
                item => item.status
            );


        const orderStatusValues =
            orderStatusData.map(
                item => item.total
            );


        new Chart(

            document.getElementById(
                "orderStatusChart"
            ),

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


</body>

</html>
