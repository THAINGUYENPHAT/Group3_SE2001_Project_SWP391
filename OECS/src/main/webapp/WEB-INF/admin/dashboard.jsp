<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            background-color: #f5f5f5;
        }

        .header {
            background-color: #ffffff;
            padding: 25px 35px;
            border-bottom: 1px solid #ddd;
        }

        .header h1 {
            margin: 0;
        }

        .container {
            padding: 30px;
        }

        .kpi-container {
            display: flex;
            gap: 20px;
            margin-bottom: 30px;
        }

        .kpi-card {
            background-color: white;
            border: 1px solid #ddd;
            border-radius: 10px;
            padding: 25px;
            flex: 1;
        }

        .kpi-title {
            color: #777;
            font-size: 16px;
            margin-bottom: 15px;
        }

        .kpi-value {
            font-size: 28px;
            font-weight: bold;
        }

        .chart-container {
            background-color: white;
            border: 1px solid #ddd;
            border-radius: 10px;
            padding: 25px;
            margin-bottom: 25px;
        }

        .chart-container h2 {
            margin-top: 0;
        }
    </style>
</head>

<body>

<div class="header">
    <h1>Admin Dashboard</h1>
</div>

<div class="container">

    <!-- KPI -->
    <div class="kpi-container">

        <div class="kpi-card">
            <div class="kpi-title">
                Tổng doanh thu
            </div>

            <div class="kpi-value">
                ${totalRevenue}
            </div>
        </div>


        <div class="kpi-card">
            <div class="kpi-title">
                Tổng số đơn hàng
            </div>

            <div class="kpi-value">
                ${totalOrders}
            </div>
        </div>


        <div class="kpi-card">
            <div class="kpi-title">
                Đơn hàng hoàn thành
            </div>

            <div class="kpi-value">
                ${completedOrders}
            </div>
        </div>

    </div>


    <!-- Chart doanh thu -->
    <div class="chart-container">

        <h2>Doanh thu theo thời gian</h2>

        <canvas id="revenueChart"></canvas>

    </div>


    <!-- Chart sản phẩm -->
    <div class="chart-container">

        <h2>Top sản phẩm bán chạy</h2>

        <canvas id="productChart"></canvas>

    </div>


    <!-- Chart trạng thái đơn -->
    <div class="chart-container">

        <h2>Tỉ lệ đơn hàng</h2>

        <canvas id="orderStatusChart"></canvas>

    </div>

</div>

</body>
</html>