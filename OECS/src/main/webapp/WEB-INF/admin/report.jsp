<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/include/header.jsp" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:url var="excelReportUrl" value="/admin/report/export">
    <c:param name="startDate" value="${startDate}"/><c:param name="endDate" value="${endDate}"/><c:param name="format" value="excel"/>
</c:url>
<c:url var="pdfReportUrl" value="/admin/report/export">
    <c:param name="startDate" value="${startDate}"/><c:param name="endDate" value="${endDate}"/><c:param name="format" value="pdf"/>
</c:url>
<style>

    .oecs-report {
        max-width: 1500px;
        margin: 0 auto;
        padding: 24px;
        color: #172033;
        font-size: 14px;
    }
    .oecs-report * {
        box-sizing: border-box;
    }
    .oecs-report h1 {
        font-size: 26px;
        font-weight: 750;
        margin: 0;
        letter-spacing: -.5px;
    }
    .oecs-report h2 {
        font-size: 16px;
        font-weight: 700;
        margin: 0;
    }
    .oecs-report .muted {
        color: #64748b;
        font-size: 12px;
    }
    .oecs-report .heading {
        display:flex;
        align-items:flex-start;
        justify-content:space-between;
        gap:16px;
        margin-bottom:20px;
        flex-wrap:wrap;
    }
    .oecs-report .panel {
        background:#fff;
        border:1px solid #e2e8f0;
        border-radius:10px;
        min-width:0;
        box-shadow:0 2px 5px rgba(15,23,42,.035);
    }
    .oecs-report .panel-head {
        display:flex;
        align-items:center;
        justify-content:space-between;
        gap:12px;
        padding:16px 18px;
        border-bottom:1px solid #edf0f4;
        flex-wrap:wrap;
    }
    .oecs-report .filters {
        display:flex;
        align-items:end;
        gap:10px;
        flex-wrap:wrap;
    }
    .oecs-report .filters label {
        display:block;
        font-size:11px;
        font-weight:700;
        color:#64748b;
        margin:0 0 5px;
    }
    .oecs-report input, .oecs-report select {
        height:36px;
        border:1px solid #dbe2eb;
        border-radius:6px;
        padding:6px 9px;
        background:white;
        color:#334155;
        font:inherit;
    }
    .oecs-report .action {
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
    .oecs-report .primary {
        background:#2563eb;
        border-color:#2563eb;
        color:#fff;
    }
    .oecs-report .action:hover {
        filter:brightness(.96);
    }
    .oecs-report .kpis {
        display:grid;
        grid-template-columns:repeat(4,minmax(0,1fr));
        gap:12px;
        margin-bottom:16px;
    }
    .oecs-report .kpi {
        position:relative;
        min-width:0;
        padding:15px;
        border-radius:9px;
        border:1px solid #e2e8f0;
    }
    .oecs-report .kpi-label {
        font-size:12px;
        font-weight:650;
        color:#475569;
        padding-right:32px;
    }
    .oecs-report .kpi-value {
        font-size:clamp(18px,1.8vw,26px);
        font-weight:750;
        line-height:1.3;
        margin:8px 0 3px;
        overflow-wrap:anywhere;
        font-variant-numeric:tabular-nums;
    }
    .oecs-report .kpi-icon {
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
    .oecs-report .table-wrap {
        overflow:auto;
    }
    .oecs-report table {
        width:100%;
        border-collapse:collapse;
        font-size:13px;
        margin:0;
    }
    .oecs-report th {
        background:#f7f9fc;
        color:#64748b;
        font-size:11px;
        font-weight:700;
        text-align:left;
        white-space:nowrap;
    }
    .oecs-report th,.oecs-report td {
        padding:12px 16px;
        border-bottom:1px solid #edf0f4;
        vertical-align:middle;
    }
    .oecs-report td {
        color:#334155;
    }
    .oecs-report .num {
        text-align:right;
        white-space:nowrap;
        font-variant-numeric:tabular-nums;
    }
    .oecs-report tbody tr:hover {
        background:#f8fafc;
    }
    .oecs-report tfoot td {
        background:#f1f5f9;
        font-weight:700;
    }
    .oecs-report .empty {
        padding:24px;
        text-align:center;
        color:#64748b;
    }
    .oecs-report .error {
        background:#fff1f2;
        border:1px solid #fecdd3;
        color:#9f1239;
        padding:10px 14px;
        border-radius:6px;
        margin:10px 0;
    }
    .oecs-report .status {
        display:inline-block;
        border-radius:5px;
        padding:4px 8px;
        font-size:11px;
        font-weight:650;
        background:#f1f5f9;
        color:#475569;
        white-space:nowrap;
    }
    .oecs-report .ok {
        color:#15803d;
        background:#ecfdf3;
    }
    .oecs-report .warn {
        color:#a16207;
        background:#fef3c7;
    }
    .oecs-report .bad {
        color:#b91c1c;
        background:#fef2f2;
    }
    .oecs-report [hidden] {
        display:none !important;
    }
    @media(max-width:1000px){
        .oecs-report .kpis{
            grid-template-columns:repeat(2,minmax(0,1fr));
        }
    }
    @media(max-width:540px){
        .oecs-report{
            padding:12px;
        }
        .oecs-report .kpis{
            grid-template-columns:1fr;
        }
        .oecs-report .filters{
            align-items:stretch;
        }
        .oecs-report .filters>div{
            flex:1 1 130px;
        }
        .oecs-report input,.oecs-report select{
            width:100%;
        }
    }

    .oecs-report .kpi{
        background:white;
        box-shadow:0 2px 5px rgba(15,23,42,.035);
    }
    .oecs-report .kpi-icon{
        background:#eff6ff;
    }
    .oecs-report .filter-panel{
        padding:15px 18px;
        margin-bottom:16px;
    }
    .oecs-report .filter-toolbar{
        display:flex;
        align-items:flex-end;
        justify-content:flex-start;
        gap:12px 20px;
        flex-wrap:wrap;
    }
    .oecs-report .filter-toolbar .filters{
        margin:0;
    }
    .oecs-report .filter-toolbar input[type=date]{
        width:145px;
        max-width:100%;
    }
    .oecs-report .filter-toolbar .action{
        height:36px;
        min-height:36px;
    }
    .oecs-report .filter-note{
        margin-top:12px;
        padding-top:10px;
        border-top:1px solid #edf0f4;
        line-height:1.5;
    }
    @media(max-width:540px){
        .oecs-report .filter-toolbar .filters{
            width:100%;
        }
        .oecs-report .filter-toolbar input[type=date]{
            width:100%;
        }
    }
    .oecs-report .report-tabs{
        display:flex;
        gap:4px;
        overflow-x:auto;
        border-bottom:1px solid #e2e8f0;
        margin-bottom:16px;
    }
    .oecs-report .report-tab{
        font:inherit;
        white-space:nowrap;
        background:none;
        border:0;
        border-bottom:3px solid transparent;
        padding:11px 14px;
        color:#64748b;
        cursor:pointer;
        font-weight:600;
    }
    .oecs-report .report-tab[aria-selected="true"]{
        color:#2563eb;
        border-color:#2563eb;
    }
    .oecs-report .report-section{
        margin-bottom:16px;
    }
    .oecs-report .report-section .panel-head{
        background:#f3f6fb;
        border-radius:10px 10px 0 0;
    }
    .oecs-report .export-excel{
        color:#15803d;
    }
    .oecs-report .export-pdf{
        color:#b91c1c;
    }
    .oecs-report .report-note{
        padding:12px 16px;
        border-left:3px solid #94a3b8;
        background:#f1f5f9;
        line-height:1.6;
    }
</style>
<div class="oecs-report">
    <div class="heading"><div><h1>Báo cáo kinh doanh</h1><div class="muted">Phân tích số liệu và trích xuất báo cáo theo khoảng thời gian</div></div><span class="muted">Admin / Báo cáo</span></div>
                <c:if test="${empty filterError}">
        <div class="kpis">
            <div class="kpi ">
                <span class="kpi-icon"><i class="bi bi-cash-stack"></i></span>
                <div class="kpi-label">Tổng doanh thu</div>
                <div class="kpi-value"><fmt:formatNumber value="${totalRevenue}" pattern="#,##0"/> ₫</div>
                <div class="muted">Hoàn thành và đã thanh toán</div>
            </div>
            <div class="kpi ">
                <span class="kpi-icon"><i class="bi bi-cart3"></i></span>
                <div class="kpi-label">Tổng đơn hàng</div>
                <div class="kpi-value"><fmt:formatNumber value="${totalOrders}" pattern="#,##0"/></div>
                <div class="muted">Tất cả đơn tạo trong kỳ</div>
            </div>
            <div class="kpi ">
                <span class="kpi-icon"><i class="bi bi-graph-up-arrow"></i></span>
                <div class="kpi-label">Giá trị đơn trung bình</div>
                <div class="kpi-value"><fmt:formatNumber value="${averageOrderValue}" pattern="#,##0"/> ₫</div>
                <div class="muted">Trên số đơn ghi nhận doanh thu</div>
            </div>
            <div class="kpi ">
                <span class="kpi-icon"><i class="bi bi-box-seam"></i></span>
                <div class="kpi-label">Sản phẩm đã bán</div>
                <div class="kpi-value"><fmt:formatNumber value="${totalProductsSold}" pattern="#,##0"/></div>
                <div class="muted">Đơn hoàn thành đã thanh toán</div>
            </div>
        </div>
    </c:if>
    <section class="panel filter-panel">
        <div class="filter-toolbar">
            <form id="reportFilter" class="filters" method="get" action="${pageContext.request.contextPath}/admin/report">
                <div><label for="startDate">Từ ngày</label><input id="startDate" name="startDate" type="date" value="<c:out value='${startDate}'/>" required></div>
                <div><label for="endDate">Đến ngày</label><input id="endDate" name="endDate" type="date" value="<c:out value='${endDate}'/>" required></div>
                <button type="submit" class="action primary"><i class="bi bi-search"></i> Lập báo cáo</button>
                <c:if test="${empty filterError}">
                    <a class="action export-excel" href="<c:out value='${excelReportUrl}'/>"><i class="bi bi-file-earmark-excel"></i> Excel</a>
                    <a class="action export-pdf" href="<c:out value='${pdfReportUrl}'/>"><i class="bi bi-file-earmark-pdf"></i> PDF</a>
                </c:if>
            </form>
        </div>
        <div class="muted filter-note">Lọc theo ngày tạo đơn. Excel/PDF xuất tất cả các mục theo khoảng ngày đã áp dụng; tồn kho là số liệu hiện tại.</div>
        <c:if test="${not empty filterError}"><div class="error"><c:out value="${filterError}"/></div></c:if>
        </section>
    <c:if test="${empty filterError}">
        <nav class="report-tabs" role="tablist" aria-label="Loại báo cáo">
            <button type="button" class="report-tab" role="tab" id="tab-revenue" aria-controls="reportRevenue" aria-selected="true">Doanh thu</button>
            <button type="button" class="report-tab" role="tab" id="tab-orders" aria-controls="reportOrders" aria-selected="false">Đơn hàng</button>
            <button type="button" class="report-tab" role="tab" id="tab-products" aria-controls="reportProducts" aria-selected="false">Sản phẩm bán chạy</button>
            <button type="button" class="report-tab" role="tab" id="tab-stock" aria-controls="reportInventory" aria-selected="false">Tồn kho</button>
            <button type="button" class="report-tab" role="tab" id="tab-payments" aria-controls="reportPayments" aria-selected="false">Thanh toán</button>
        </nav>
        <section id="reportRevenue" class="panel report-section" role="tabpanel" aria-labelledby="tab-revenue">
            <div class="panel-head"><div><h2><i class="bi bi-calendar3"></i> Doanh thu theo ngày</h2><div class="muted">Đơn hoàn thành và đã thanh toán</div></div><span class="status"><c:out value="${startDate}"/> – <c:out value="${endDate}"/></span></div>
            <div class="table-wrap"><table>
                    <thead><tr><th>Ngày tạo đơn</th><th class="num">Số đơn ghi nhận doanh thu</th><th class="num">Doanh thu (VNĐ)</th></tr></thead>
                    <tbody>
                        <c:forEach var="row" items="${revenueByDate}"><tr><td><fmt:formatDate value="${row[0]}" pattern="dd/MM/yyyy"/></td><td class="num">${row[2]}</td><td class="num"><strong><fmt:formatNumber value="${row[1]}" pattern="#,##0"/></strong></td></tr></c:forEach>
                        <c:if test="${empty revenueByDate}"><tr><td colspan="3" class="empty">Không có doanh thu trong khoảng thời gian đã chọn.</td></tr></c:if>
                        </tbody>
                        <tfoot><tr><td>Tổng cộng</td><td class="num">${revenueOrders}</td><td class="num"><fmt:formatNumber value="${totalRevenue}" pattern="#,##0"/></td></tr></tfoot>
                </table></div>
        </section>
        <section id="reportOrders" class="panel report-section" role="tabpanel" aria-labelledby="tab-orders">
            <div class="panel-head"><div><h2>Báo cáo đơn hàng theo trạng thái</h2><div class="muted">Trạng thái hiện tại của các đơn tạo trong kỳ</div></div><span class="status">${totalOrders} đơn</span></div>
            <div class="table-wrap"><table><thead><tr><th>Trạng thái</th><th class="num">Số đơn</th><th class="num">Tỷ lệ</th></tr></thead><tbody>
                        <c:forEach var="row" items="${orderStatusStats}"><tr><td><c:choose>
                                        <c:when test="${row[0] eq 'PENDING_PAYMENT'}">Chờ thanh toán</c:when>
                                        <c:when test="${row[0] eq 'PENDING_CONFIRMATION'}">Chờ xác nhận</c:when>
                                        <c:when test="${row[0] eq 'CONFIRMED'}">Đã xác nhận</c:when>
                                        <c:when test="${row[0] eq 'PACKING'}">Đang đóng gói</c:when>
                                        <c:when test="${row[0] eq 'SHIPPING'}">Đang giao hàng</c:when>
                                        <c:when test="${row[0] eq 'COMPLETED'}">Hoàn thành</c:when>
                                        <c:when test="${row[0] eq 'CANCELLED'}">Đã hủy</c:when>
                                        <c:when test="${row[0] eq 'EXPIRED'}">Hết hạn</c:when>
                                        <c:when test="${row[0] eq 'RETURNED'}">Đã trả hàng</c:when>
                                        <c:otherwise><c:out value="${row[0]}"/></c:otherwise>
                                    </c:choose></td><td class="num">${row[1]}</td><td class="num"><fmt:formatNumber value="${totalOrders gt 0 ? row[1] / totalOrders : 0}" type="percent" maxFractionDigits="1"/></td></tr></c:forEach>
                        <c:if test="${empty orderStatusStats}"><tr><td colspan="3" class="empty">Không có đơn hàng trong kỳ.</td></tr></c:if>
                    </tbody><tfoot><tr><td>Tổng cộng</td><td class="num">${totalOrders}</td><td class="num">${totalOrders gt 0 ? '100%' : '0%'}</td></tr></tfoot></table></div>
        </section>
        <section id="reportProducts" class="panel report-section" role="tabpanel" aria-labelledby="tab-products">
            <div class="panel-head"><div><h2>Top 5 sản phẩm bán chạy</h2><div class="muted">Xếp theo số lượng bán, chưa điều chỉnh đổi trả</div></div><span class="status">Top 5</span></div>
            <div class="table-wrap"><table><thead><tr><th>Hạng</th><th>Sản phẩm</th><th class="num">Số lượng đã bán</th></tr></thead><tbody>
                        <c:forEach var="row" items="${topSellingProducts}" varStatus="loop"><tr><td>${loop.count}</td><td><c:out value="${row[0]}"/></td><td class="num"><strong>${row[1]}</strong></td></tr></c:forEach>
                        <c:if test="${empty topSellingProducts}"><tr><td colspan="3" class="empty">Không có sản phẩm bán trong kỳ.</td></tr></c:if>
                        </tbody></table></div>
            </section>
            <section id="reportInventory" class="panel report-section" role="tabpanel" aria-labelledby="tab-stock">
                <div class="panel-head"><div><h2>Báo cáo tồn kho hiện tại</h2><div class="muted">Theo từng SKU · Không áp dụng bộ lọc ngày</div></div><span class="status">Số liệu hiện tại</span></div>
                <div class="table-wrap"><table><thead><tr><th>Mã SKU</th><th>Sản phẩm</th><th class="num">Tồn thực tế</th><th class="num">Giữ chỗ</th><th class="num">Có thể bán</th><th>Tình trạng khả dụng</th></tr></thead><tbody>
                        <c:forEach var="item" items="${inventory}"><tr><td><c:out value="${item[0]}"/></td><td><c:out value="${item[1]}"/></td><td class="num">${item[2]}</td><td class="num">${item[3]}</td><td class="num"><strong>${item[4]}</strong></td><td><span class="status ${item[4] le 0 ? 'bad' : item[4] le 5 ? 'warn' : 'ok'}">${item[4] le 0 ? 'Hết hàng' : item[4] le 5 ? 'Sắp hết' : 'Còn hàng'}</span></td></tr></c:forEach>
                        <c:if test="${empty inventory}"><tr><td colspan="6" class="empty">Không có dữ liệu tồn kho.</td></tr></c:if>
                        </tbody></table></div>
            </section>
            <section id="reportPayments" class="panel report-section" role="tabpanel" aria-labelledby="tab-payments">
                <div class="panel-head"><div><h2>Báo cáo thanh toán</h2><div class="muted">Theo phương thức và trạng thái của đơn tạo trong kỳ</div></div></div>
                <div class="table-wrap"><table><thead><tr><th>Phương thức</th><th>Trạng thái thanh toán</th><th class="num">Số đơn</th><th class="num">Giá trị đơn (VNĐ)</th></tr></thead><tbody>
                        <c:forEach var="item" items="${payments}"><tr><td><c:out value="${item[0]}"/></td><td><span class="status ${item[1] eq 'PAID' ? 'ok' : item[1] eq 'FAILED' ? 'bad' : item[1] eq 'PENDING' ? 'warn' : ''}"><c:choose>
                                            <c:when test="${item[1] eq 'PAID'}">Đã thanh toán</c:when>
                                            <c:when test="${item[1] eq 'UNPAID'}">Chưa thanh toán</c:when>
                                            <c:when test="${item[1] eq 'PENDING'}">Chờ thanh toán</c:when>
                                            <c:when test="${item[1] eq 'FAILED'}">Thất bại</c:when>
                                            <c:when test="${item[1] eq 'CANCELLED'}">Đã hủy thanh toán</c:when>
                                            <c:when test="${item[1] eq 'EXPIRED'}">Hết hạn</c:when>
                                            <c:otherwise><c:out value="${item[1]}"/></c:otherwise>
                                        </c:choose></span></td><td class="num">${item[2]}</td><td class="num"><strong><fmt:formatNumber value="${item[3]}" pattern="#,##0"/></strong></td></tr></c:forEach>
                        <c:if test="${empty payments}"><tr><td colspan="4" class="empty">Không có dữ liệu thanh toán trong kỳ.</td></tr></c:if>
                        </tbody></table></div>
            </section>
            <div class="report-note muted">Doanh thu lấy tổng tiền đơn đã gồm phí giao hàng và trừ giảm giá. Doanh thu và số lượng bán phản ánh giao dịch gốc, chưa điều chỉnh đổi trả hoặc hoàn tiền. Báo cáo thanh toán là giá trị đơn theo trạng thái, không phải số tiền đã hoàn.</div>
    </c:if>
</div>
<script>
    (function () {
        const root = document.querySelector('.oecs-report');
        const tabs = root.querySelectorAll('.report-tab');
        function selectTab(selected) {
            tabs.forEach(tab => {
                const active = tab === selected;
                tab.setAttribute('aria-selected', String(active));
                document.getElementById(tab.getAttribute('aria-controls')).hidden = !active;
            });
        }
        tabs.forEach(tab => tab.addEventListener('click', () => selectTab(tab)));
        if (tabs.length)
            selectTab(tabs[0]);
    })();
</script>

<%@ include file="/WEB-INF/include/footer.jsp" %>
