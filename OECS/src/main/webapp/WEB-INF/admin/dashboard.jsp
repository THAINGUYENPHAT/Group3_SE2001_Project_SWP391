<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/include/header.jsp" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<style>

    .oecs-dashboard {
        max-width: 1500px;
        margin: 0 auto;
        padding: 24px;
        color: #172033;
        font-size: 14px;
    }
    .oecs-dashboard * {
        box-sizing: border-box;
    }
    .oecs-dashboard h1 {
        font-size: 26px;
        font-weight: 750;
        margin: 0;
        letter-spacing: -.5px;
    }
    .oecs-dashboard h2 {
        font-size: 16px;
        font-weight: 700;
        margin: 0;
    }
    .oecs-dashboard .muted {
        color: #64748b;
        font-size: 12px;
    }
    .oecs-dashboard .heading {
        display:flex;
        align-items:flex-start;
        justify-content:space-between;
        gap:16px;
        margin-bottom:20px;
        flex-wrap:wrap;
    }
    .oecs-dashboard .panel {
        background:#fff;
        border:1px solid #e2e8f0;
        border-radius:10px;
        min-width:0;
        box-shadow:0 2px 5px rgba(15,23,42,.035);
    }
    .oecs-dashboard .panel-head {
        display:flex;
        align-items:center;
        justify-content:space-between;
        gap:12px;
        padding:16px 18px;
        border-bottom:1px solid #edf0f4;
        flex-wrap:wrap;
    }
    .oecs-dashboard .filters {
        display:flex;
        align-items:end;
        gap:10px;
        flex-wrap:wrap;
    }
    .oecs-dashboard .filters label {
        display:block;
        font-size:11px;
        font-weight:700;
        color:#64748b;
        margin:0 0 5px;
    }
    .oecs-dashboard input, .oecs-dashboard select {
        height:36px;
        border:1px solid #dbe2eb;
        border-radius:6px;
        padding:6px 9px;
        background:white;
        color:#334155;
        font:inherit;
    }
    .oecs-dashboard .action {
        display:inline-flex;
        align-items:center;
        justify-content:center;
        gap:6px;
        min-height:36px;
        border:1px solid #dbe2eb;
        border-radius:6px;
        padding:7px 12px;
        font-size:13px;
        font-weight:650;
        text-decoration:none;
        background:#fff;
        color:#334155;
        cursor:pointer;
        white-space:nowrap;
    }
    .oecs-dashboard .primary {
        background:#2563eb;
        border-color:#2563eb;
        color:#fff;
    }
    .oecs-dashboard .action:hover {
        filter:brightness(.96);
    }
    .oecs-dashboard .kpis {
        display:grid;
        grid-template-columns:repeat(4,minmax(0,1fr));
        gap:12px;
        margin-bottom:16px;
    }
    .oecs-dashboard .kpi {
        position:relative;
        min-width:0;
        padding:15px;
        border-radius:9px;
        border:1px solid #e2e8f0;
    }
    .oecs-dashboard .kpi-label {
        font-size:12px;
        font-weight:650;
        color:#475569;
        padding-right:32px;
    }
    .oecs-dashboard .kpi-value {
        font-size:clamp(18px,1.8vw,26px);
        font-weight:750;
        line-height:1.3;
        margin:8px 0 3px;
        overflow-wrap:anywhere;
        font-variant-numeric:tabular-nums;
    }
    .oecs-dashboard .kpi-icon {
        position:absolute;
        right:12px;
        top:12px;
        width:30px;
        height:30px;
        display:grid;
        place-items:center;
        border-radius:7px;
        background:#ffffffa8;
        color:#2563eb;
        font-size:16px;
    }
    .oecs-dashboard .table-wrap {
        overflow:auto;
    }
    .oecs-dashboard table {
        width:100%;
        border-collapse:collapse;
        font-size:13px;
        margin:0;
    }
    .oecs-dashboard th {
        background:#f7f9fc;
        color:#64748b;
        font-size:11px;
        font-weight:700;
        text-align:left;
        white-space:nowrap;
    }
    .oecs-dashboard th,.oecs-dashboard td {
        padding:12px 16px;
        border-bottom:1px solid #edf0f4;
        vertical-align:middle;
    }
    .oecs-dashboard td {
        color:#334155;
    }
    .oecs-dashboard .num {
        text-align:right;
        white-space:nowrap;
        font-variant-numeric:tabular-nums;
    }
    .oecs-dashboard tbody tr:hover {
        background:#f8fafc;
    }
    .oecs-dashboard tfoot td {
        background:#f1f5f9;
        font-weight:700;
    }
    .oecs-dashboard .empty {
        padding:24px;
        text-align:center;
        color:#64748b;
    }
    .oecs-dashboard .error {
        background:#fff1f2;
        border:1px solid #fecdd3;
        color:#9f1239;
        padding:10px 14px;
        border-radius:6px;
        margin:10px 0;
    }
    .oecs-dashboard .status {
        display:inline-block;
        border-radius:5px;
        padding:4px 8px;
        font-size:11px;
        font-weight:650;
        background:#f1f5f9;
        color:#475569;
        white-space:nowrap;
    }
    .oecs-dashboard .ok {
        color:#15803d;
        background:#ecfdf3;
    }
    .oecs-dashboard .warn {
        color:#a16207;
        background:#fef3c7;
    }
    .oecs-dashboard .bad {
        color:#b91c1c;
        background:#fef2f2;
    }
    .oecs-dashboard [hidden] {
        display:none !important;
    }
    @media(max-width:1000px){
        .oecs-dashboard .kpis{
            grid-template-columns:repeat(2,minmax(0,1fr));
        }
    }
    @media(max-width:540px){
        .oecs-dashboard{
            padding:12px;
        }
        .oecs-dashboard .kpis{
            grid-template-columns:1fr;
        }
        .oecs-dashboard .filters{
            align-items:stretch;
        }
        .oecs-dashboard .filters>div{
            flex:1 1 130px;
        }
        .oecs-dashboard input,.oecs-dashboard select{
            width:100%;
        }
    }

    .oecs-dashboard .section-label {
        font-size:11px;
        font-weight:700;
        letter-spacing:.5px;
        text-transform:uppercase;
        color:#64748b;
        margin:16px 0 8px;
    }
    .oecs-dashboard .blue {
        background:#eff6ff;
    }
    .oecs-dashboard .green {
        background:#ecfdf5;
    }
    .oecs-dashboard .amber {
        background:#fffbeb;
    }
    .oecs-dashboard .violet {
        background:#f5f3ff;
    }
    .oecs-dashboard .rose {
        background:#fff1f2;
    }
    .oecs-dashboard .cyan {
        background:#ecfeff;
    }
    .oecs-dashboard .chart-area{
        height:300px;
        padding:16px 18px;
        position:relative;
    }
    .oecs-dashboard .bottom-grid{
        display:grid;
        grid-template-columns:1fr 1fr;
        gap:16px;
        margin-top:16px;
    }
    .oecs-dashboard .product{
        display:flex;
        align-items:center;
        gap:9px;
        min-width:130px;
    }
    .oecs-dashboard .product img{
        width:34px;
        height:34px;
        object-fit:contain;
        background:white;
        border:1px solid #edf0f4;
        border-radius:6px;
    }
    .oecs-dashboard .stock-summary{
        display:flex;
        gap:12px;
        flex-wrap:wrap;
        padding:12px 16px;
        border-bottom:1px solid #edf0f4;
    }
    @media(max-width:1000px){
        .oecs-dashboard .bottom-grid{
            grid-template-columns:1fr;
        }
    }

    .oecs-dashboard .period-panel {
        padding:12px 16px;
        margin-bottom:16px;
    }
    .oecs-dashboard .period-toolbar {
        display:flex;
        align-items:flex-end;
        justify-content:space-between;
        gap:12px 20px;
        flex-wrap:wrap;
    }
    .oecs-dashboard .period-title {
        align-self:center;
    }
    .oecs-dashboard .period-panel .filters {
        margin:0;
    }
    .oecs-dashboard .period-panel input[type=date] {
        width:145px;
        max-width:100%;
    }
    .oecs-dashboard .period-panel .action {
        height:36px;
    }
    @media(max-width:540px){
        .oecs-dashboard .period-panel .filters{
            width:100%;
        }
        .oecs-dashboard .period-panel input[type=date]{
            width:100%;
        }
    }
</style>
<c:url var="reportUrl" value="/admin/report">
    <c:param name="startDate" value="${startDate}"/>
    <c:param name="endDate" value="${endDate}"/>
</c:url>
<div class="oecs-dashboard">
    <div class="heading">
        <div><h1>Dashboard</h1><div class="muted">Tổng quan kinh doanh và vận hành cửa hàng OECS</div></div>
    </div>
    <div class="section-label">Kết quả kinh doanh trong kỳ</div>
    <div class="kpis">
        <div class="kpi green">
            <span class="kpi-icon"><i class="bi bi-cash-stack"></i></span>
            <div class="kpi-label">Tổng doanh thu</div>
            <div class="kpi-value"><fmt:formatNumber value="${totalRevenue}" pattern="#,##0"/> ₫</div>
            <div class="muted">Hoàn thành và đã thanh toán</div>
        </div>
        <div class="kpi blue">
            <span class="kpi-icon"><i class="bi bi-cart3"></i></span>
            <div class="kpi-label">Tổng đơn hàng</div>
            <div class="kpi-value"><fmt:formatNumber value="${totalOrders}" pattern="#,##0"/></div>
            <div class="muted">Đơn được tạo trong kỳ</div>
        </div>
        <div class="kpi violet">
            <span class="kpi-icon"><i class="bi bi-check-circle"></i></span>
            <div class="kpi-label">Đơn hoàn thành</div>
            <div class="kpi-value"><fmt:formatNumber value="${completedOrders}" pattern="#,##0"/></div>
            <div class="muted">Trạng thái hoàn thành</div>
        </div>
        <div class="kpi rose">
            <span class="kpi-icon"><i class="bi bi-x-circle"></i></span>
            <div class="kpi-label">Đơn đã hủy</div>
            <div class="kpi-value"><fmt:formatNumber value="${cancelledOrders}" pattern="#,##0"/></div>
            <div class="muted">Trạng thái đã hủy</div>
        </div>
    </div>
    <div class="section-label">Vận hành hiện tại · Không áp dụng bộ lọc ngày</div>
    <div class="kpis">
        <div class="kpi amber">
            <span class="kpi-icon"><i class="bi bi-hourglass-split"></i></span>
            <div class="kpi-label">Đơn đang xử lý</div>
            <div class="kpi-value"><fmt:formatNumber value="${processingOrders}" pattern="#,##0"/></div>
            <div class="muted">Chờ xác nhận: ${pendingOrders} · Đã xác nhận: ${confirmedOrders} · Đóng gói: ${packingOrders}</div>
        </div>
        <div class="kpi cyan">
            <span class="kpi-icon"><i class="bi bi-boxes"></i></span>
            <div class="kpi-label">Tồn kho thực tế</div>
            <div class="kpi-value"><fmt:formatNumber value="${totalStock}" pattern="#,##0"/></div>
            <div class="muted">Tổng đơn vị hàng trong kho</div>
        </div>
        <div class="kpi violet">
            <span class="kpi-icon"><i class="bi bi-bookmark-check"></i></span>
            <div class="kpi-label">Hàng giữ chỗ</div>
            <div class="kpi-value"><fmt:formatNumber value="${reservedStock}" pattern="#,##0"/></div>
            <div class="muted">Đã dành cho đơn hàng</div>
        </div>
        <div class="kpi green">
            <span class="kpi-icon"><i class="bi bi-box-seam"></i></span>
            <div class="kpi-label">Hàng có thể bán</div>
            <div class="kpi-value"><fmt:formatNumber value="${sellableStock}" pattern="#,##0"/></div>
            <div class="muted">Tồn thực tế trừ giữ chỗ</div>
        </div>
    </div>
    <section class="panel period-panel" aria-label="Bộ lọc Dashboard">
        <div class="period-toolbar">
            <div class="period-title"><h2>Khoảng thống kê</h2><div class="muted">Áp dụng cho kết quả kinh doanh và sản phẩm bán chạy.</div></div>
            <form class="filters" method="get" action="${pageContext.request.contextPath}/admin/dashboard">
                <div><label for="startDate">Từ ngày</label><input type="date" id="startDate" name="startDate" value="<c:out value='${startDate}'/>" required></div>
                <div><label for="endDate">Đến ngày</label><input type="date" id="endDate" name="endDate" value="<c:out value='${endDate}'/>" required></div>
                <div><label for="groupBy">Biểu đồ</label><select id="groupBy" name="groupBy">
                        <option value="day" ${groupBy eq 'day' ? 'selected' : ''}>Theo ngày</option>
                        <option value="month" ${groupBy eq 'month' ? 'selected' : ''}>Theo tháng</option>
                    </select></div>
                <button class="action primary" type="submit"><i class="bi bi-funnel"></i> Lọc</button>
                <a class="action" href="${pageContext.request.contextPath}/admin/dashboard">Đặt lại</a>
            </form>
        </div>
        <c:if test="${not empty dateError}"><div class="error"><c:out value="${dateError}"/> Đang hiển thị 30 ngày gần nhất.</div></c:if>
        </section>
        <section class="panel">
            <div class="panel-head">
                <div><h2>Doanh thu theo ${groupBy eq 'month' ? 'tháng' : 'ngày'}</h2><div class="muted">Theo ngày tạo đơn · VNĐ</div></div>
            <a class="action" href="<c:out value='${reportUrl}'/>">Xem báo cáo <i class="bi bi-arrow-right"></i></a>
        </div>
        <c:choose>
            <c:when test="${empty revenueByDate}"><div class="empty">Không có đơn hoàn thành đã thanh toán trong kỳ.</div></c:when>
            <c:otherwise>
                <div class="chart-area" id="chartArea"><canvas id="revenueChart" aria-label="Biểu đồ doanh thu" role="img"></canvas></div>
                <div id="chartFallback" class="table-wrap" hidden>
                    <table><thead><tr><th>Thời gian</th><th class="num">Doanh thu</th></tr></thead><tbody>
                            <c:forEach var="row" items="${revenueByDate}"><tr><td><c:out value="${row[0]}"/></td><td class="num"><fmt:formatNumber value="${row[1]}" pattern="#,##0"/> ₫</td></tr></c:forEach>
                            </tbody></table>
                    </div>
            </c:otherwise>
        </c:choose>
    </section>
    <div class="bottom-grid">
        <section class="panel">
            <div class="panel-head"><div><h2>Top 5 sản phẩm bán chạy</h2><div class="muted">Theo số lượng bán từ đơn hoàn thành đã thanh toán</div></div><i class="bi bi-trophy"></i></div>
            <div class="table-wrap"><table>
                    <thead><tr><th>#</th><th>Sản phẩm</th><th class="num">Giá từ</th><th class="num">Đã bán</th></tr></thead>
                    <tbody>
                        <c:forEach var="p" items="${topSellingProducts}" varStatus="loop">
                            <tr><td>${loop.count}</td><td><div class="product">
                                        <c:if test="${not empty p[1]}"><c:url var="imageUrl" value="/${p[1]}"/><img src="<c:out value='${imageUrl}'/>" alt="" loading="lazy" onerror="this.hidden=true"></c:if>
                                        <c:out value="${p[0]}"/>
                                    </div></td><td class="num"><fmt:formatNumber value="${p[2]}" pattern="#,##0"/> ₫</td><td class="num"><strong>${p[3]}</strong></td></tr>
                                </c:forEach>
                                        <c:if test="${empty topSellingProducts}"><tr><td colspan="4" class="empty">Chưa có sản phẩm bán trong kỳ.</td></tr></c:if>
                        </tbody>
                    </table></div>
                <div class="muted" style="padding:12px 16px">Giá từ là giá niêm yết hiện tại; số lượng bán chưa điều chỉnh đổi trả.</div>
            </section>
            <section class="panel">
                <div class="panel-head"><div><h2>SKU tồn kho thấp</h2><div class="muted">Tồn kho thực tế tại thời điểm xem</div></div><i class="bi bi-box-seam"></i></div>
                <div class="stock-summary"><span class="status ok">Đủ hàng: ${stockAvailable}</span><span class="status warn">Sắp hết: ${stockLow}</span><span class="status bad">Hết hàng: ${stockOut}</span></div>
            <div class="table-wrap" style="max-height:320px"><table>
                    <thead><tr><th>Sản phẩm / SKU</th><th class="num">Tồn</th><th>Tình trạng</th></tr></thead><tbody>
                                <c:forEach var="sku" items="${lowStockProducts}">
                            <tr><td><div class="product">
                                        <c:if test="${not empty sku[2]}"><c:url var="imageUrl" value="/${sku[2]}"/><img src="<c:out value='${imageUrl}'/>" alt="" loading="lazy" onerror="this.hidden=true"></c:if>
                                        <div><c:out value="${sku[1]}"/><div class="muted"><c:out value="${sku[0]}"/></div></div>
                                    </div></td><td class="num">${sku[3]}</td><td><span class="status ${sku[3] eq 0 ? 'bad' : 'warn'}">${sku[3] eq 0 ? 'Hết hàng' : 'Sắp hết'}</span></td></tr>
                                </c:forEach>
                                    <c:if test="${empty lowStockProducts}"><tr><td colspan="3" class="empty">Không có SKU tồn kho thấp.</td></tr></c:if>
                        </tbody></table></div>
            </section>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        (function () {
            const canvas = document.getElementById('revenueChart');
            if (!canvas)
                return;
            if (typeof Chart === 'undefined') {
                document.getElementById('chartArea').hidden = true;
                document.getElementById('chartFallback').hidden = false;
                return;
            }
            const rows = [
    <c:forEach var="row" items="${revenueByDate}" varStatus="loop">
        {date: '<c:out value="${row[0]}"/>', revenue: ${row[1]}}${loop.last ? '' : ','}
    </c:forEach>
            ];
            const byMonth = '${groupBy}' === 'month';
            const start = new Date('${startDate}T00:00:00Z');
            const end = new Date('${endDate}T00:00:00Z');
            const count = byMonth ? (end.getUTCFullYear() - start.getUTCFullYear()) * 12 + end.getUTCMonth() - start.getUTCMonth() + 1 : Math.round((end - start) / 86400000) + 1;
            // Điền mốc không có doanh thu, giới hạn độ dài biểu đồ.
            if (count > 0 && count <= (byMonth ? 1200 : 3660)) {
                const amounts = new Map(rows.map(row => [row.date, row.revenue]));
                const date = new Date(start);
                if (byMonth)
                    date.setUTCDate(1);
                rows.length = 0;
                for (let i = 0; i < count; i++) {
                    const key = date.toISOString().slice(0, byMonth ? 7 : 10);
                    rows.push({date: key, revenue: amounts.get(key) || 0});
                    if (byMonth)
                        date.setUTCMonth(date.getUTCMonth() + 1);
                    else
                        date.setUTCDate(date.getUTCDate() + 1);
                }
            }
            const money = new Intl.NumberFormat('vi-VN', {style: 'currency', currency: 'VND'});
            new Chart(canvas, {
                type: 'bar',
                data: {labels: rows.map(row => row.date), datasets: [{label: 'Doanh thu', data: rows.map(row => row.revenue), backgroundColor: '#3b82f6', borderRadius: 3, maxBarThickness: 36}]},
                options: {responsive: true, maintainAspectRatio: false, plugins: {legend: {display: false}, tooltip: {callbacks: {label: ctx => money.format(ctx.parsed.y)}}}, scales: {x: {grid: {display: false}, ticks: {maxTicksLimit: 12}}, y: {beginAtZero: true, ticks: {callback: value => new Intl.NumberFormat('vi-VN', {notation: 'compact'}).format(value)}, grid: {color: '#edf0f4'}}}}
            });
        })();
</script>

<%@ include file="/WEB-INF/include/footer.jsp" %>
