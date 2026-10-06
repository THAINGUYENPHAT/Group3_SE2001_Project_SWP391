<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/include/header.jsp" %>

<style>
  .report-page {
    padding: 28px 0 40px;
  }

  /* ================= PAGE TITLE ================= */
  .page-title {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 22px;
  }

  .page-title h1 {
    margin: 0;
    font-size: 28px;
    color: #172033;
    font-weight: 700;
  }

  .page-title p {
    margin: 6px 0 0;
    color: #748198;
    font-size: 14px;
  }

  .page-badge {
    background: #eaf2ff;
    color: #1677ff;
    padding: 9px 15px;
    border-radius: 9px;
    font-size: 13px;
    font-weight: 700;
  }

  /* ================= COMMON CARD ================= */
  .report-card {
    background: white;
    border: 1px solid #e3e8ef;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(15, 23, 42, 0.035);
  }

  /* ================= FILTER ================= */
  .filter-card {
    padding: 20px 22px;
    margin-bottom: 20px;
    position: relative;
    z-index: 20;
    overflow: visible;
  }

  .section-heading {
    margin-bottom: 18px;
  }

  .section-heading h2 {
    margin: 0;
    font-size: 16px;
    color: #172033;
  }

  .section-heading span {
    display: block;
    margin-top: 4px;
    color: #8490a3;
    font-size: 12px;
  }

  .filter-form {
    display: flex;
    align-items: flex-end;
    gap: 14px;
    flex-wrap: wrap;
  }

  .filter-group {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .filter-group.type-group,
  .filter-group.date-group {
    width: 220px;
  }

  .filter-group label {
    color: #64748b;
    font-size: 12px;
    font-weight: 600;
  }

  select,
  input[type="date"] {
    width: 100%;
    height: 40px;
    border: 1px solid #d8dee8;
    border-radius: 7px;
    background: #fff;
    color: #263449;
    padding: 0 11px;
    font-size: 13px;
    box-sizing: border-box;
  }

  select:focus,
  input[type="date"]:focus {
    outline: none;
    border-color: #1677ff;
    box-shadow: 0 0 0 2px rgba(22, 119, 255, 0.08);
  }

  /* ================= ACTIONS ================= */
  .filter-actions {
    display: flex;
    align-items: flex-end;
    gap: 14px;
    margin-left: 4px;
  }

  .btn-filter {
    height: 40px;
    padding: 0 20px;
    border: 0;
    border-radius: 7px;
    background: #1677ff;
    color: white;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    white-space: nowrap;
    transition: 0.2s ease;
  }

  .btn-filter:hover {
    background: #0969e8;
  }

  /* ================= EXPORT ================= */
  .export-group {
    position: relative;
  }

  .btn-export-main {
    height: 40px;
    min-width: 150px;
    padding: 0 18px;
    border: 1px solid #d8dee8;
    border-radius: 7px;
    background: #ffffff;
    color: #334155;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: space-between;
    gap: 15px;
    transition: 0.2s ease;
  }

  .btn-export-main:hover {
    background: #f8fafc;
    border-color: #bfc9d8;
  }

  .btn-export-main .arrow {
    font-size: 12px;
    transition: transform 0.2s ease;
  }

  .btn-export-main.active .arrow {
    transform: rotate(180deg);
  }

  /* ================= EXPORT MENU ================= */
  .export-menu {
    display: none;
    position: absolute;
    top: calc(100% + 7px);
    right: 0;
    width: 180px;
    background: #ffffff;
    border: 1px solid #e1e6ed;
    border-radius: 8px;
    box-shadow: 0 8px 22px rgba(15, 23, 42, 0.12);
    padding: 5px;
    z-index: 9999;
  }

  .export-menu.show {
    display: block;
  }

  .export-menu a {
    display: block;
    padding: 10px 12px;
    border-radius: 6px;
    color: #334155;
    text-decoration: none;
    font-size: 13px;
    font-weight: 500;
    transition: 0.15s ease;
  }

  .export-menu a:hover {
    background: #f5f7fa;
  }

  .export-menu .excel-option:hover {
    color: #198754;
  }

  .export-menu .pdf-option:hover {
    color: #dc3545;
  }

  /* ================= KPI ================= */
  .kpi-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 18px;
    margin-bottom: 20px;
  }

  .kpi-card {
    min-height: 108px;
    padding: 20px;
    display: flex;
    align-items: center;
    gap: 15px;
  }

  .kpi-icon {
    width: 48px;
    height: 48px;
    flex-shrink: 0;
    border-radius: 10px;
    background: #edf4ff;
    color: #1677ff;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
    font-weight: bold;
  }

  .kpi-label {
    color: #748198;
    font-size: 12px;
    margin-bottom: 5px;
  }

  .kpi-value {
    color: #172033;
    font-size: 22px;
    font-weight: 700;
  }

  .kpi-unit {
    font-size: 12px;
    color: #7b8799;
    margin-left: 3px;
  }

  /* ================= REPORT HEADER ================= */
  .report-header {
    padding: 19px 22px;
    border-bottom: 1px solid #e7ebf1;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .report-title {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .report-icon {
    width: 36px;
    height: 36px;
    border-radius: 8px;
    background: #edf4ff;
    color: #1677ff;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 17px;
  }

  .report-title h2 {
    margin: 0;
    font-size: 17px;
  }

  .report-title p {
    margin: 3px 0 0;
    color: #8a96a8;
    font-size: 12px;
  }

  .report-period {
    background: #f5f7fa;
    color: #66748a;
    padding: 7px 11px;
    border-radius: 7px;
    font-size: 12px;
  }

  /* ================= TABLE ================= */
  .table-wrapper {
    width: 100%;
  }

  table {
    width: 100%;
    border-collapse: collapse;
  }

  th {
    background: #f8fafc;
    color: #68768b;
    font-size: 11px;
    font-weight: 700;
    text-align: left;
    padding: 13px 22px;
    border-bottom: 1px solid #e4e9f0;
    text-transform: uppercase;
  }

  td {
    padding: 14px 22px;
    border-bottom: 1px solid #edf0f4;
    font-size: 13px;
    color: #334155;
  }

  tbody tr:hover {
    background: #fafcff;
  }

  .date {
    font-weight: 600;
    color: #263b5a;
  }

  .revenue {
    font-weight: 700;
    color: #172033;
  }

  .order-count {
    color: #64748b;
  }

  .order-badge {
    display: inline-flex;
    min-width: 30px;
    justify-content: center;
    padding: 4px 8px;
    border-radius: 6px;
    background: #f1f5f9;
    color: #475569;
    font-weight: 600;
    font-size: 12px;
  }

  /* ================= TOTAL ================= */
  .report-footer {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: 8px;
    padding: 17px 22px;
    background: #fafbfd;
    border-top: 1px solid #e9edf2;
  }

  .total-label {
    color: #718096;
    font-size: 13px;
  }

  .total-value {
    color: #1677ff;
    font-size: 18px;
    font-weight: 700;
  }

  /* ================= EMPTY ================= */
  .empty {
    text-align: center;
    padding: 42px 20px !important;
    color: #8a96a8;
  }

  .empty-icon {
    font-size: 25px;
    margin-bottom: 8px;
  }

  /* ================= RESPONSIVE ================= */
  @media (max-width: 900px) {
    .page-title {
      align-items: flex-start;
    }

    .page-title h1 {
      font-size: 24px;
    }

    .kpi-grid {
      grid-template-columns: 1fr;
    }

    .filter-form {
      flex-direction: column;
      align-items: stretch;
    }

    .filter-group.type-group,
    .filter-group.date-group {
      width: 100%;
    }

    .filter-actions {
      width: 100%;
      flex-direction: column;
      align-items: stretch;
      gap: 10px;
      margin-left: 0;
    }

    .btn-filter {
      width: 100%;
    }

    .export-group {
      width: 100%;
    }

    .btn-export-main {
      width: 100%;
    }

    .export-menu {
      width: 100%;
      left: 0;
      right: auto;
    }

    .report-header {
      align-items: flex-start;
      gap: 10px;
      flex-direction: column;
    }

    .table-wrapper {
      overflow-x: auto;
    }

    table {
      min-width: 650px;
    }
  }
</style>

<div class="container-fluid report-page">
  <!-- ================= PAGE TITLE ================= -->
  <div class="page-title">
    <div>
      <h1>Reporting System</h1>
      <p>Theo dõi doanh thu và hiệu quả hoạt động bán hàng</p>
    </div>
    <div class="page-badge">Báo cáo</div>
  </div>

  <!-- ================= FILTER ================= -->
  <section class="report-card filter-card">
    <div class="section-heading">
      <h2>Bộ lọc báo cáo</h2>
      <span>Chọn khoảng thời gian cần xem</span>
    </div>

    <form
      class="filter-form"
      method="get"
      action="${pageContext.request.contextPath}/admin/report"
    >
      <!-- ================= REPORT TYPE ================= -->
      <div class="filter-group type-group">
        <label for="type">Loại báo cáo</label>
        <select id="type" name="type">
          <option value="day" ${selectedType == 'day' ? 'selected' : ''}>
            Theo ngày
          </option>
          <option value="week" ${selectedType == 'week' ? 'selected' : ''}>
            Theo tuần
          </option>
          <option value="month" ${selectedType == 'month' ? 'selected' : ''}>
            Theo tháng
          </option>
          <option value="year" ${selectedType == 'year' ? 'selected' : ''}>
            Theo năm
          </option>
        </select>
      </div>

      <!-- ================= DATE ================= -->
      <div class="filter-group date-group">
        <label for="date">Ngày tham chiếu</label>
        <input
          id="date"
          type="date"
          name="date"
          value="${selectedDate}"
          required
        />
      </div>

      <!-- ================= ACTIONS ================= -->
      <div class="filter-actions">
        <!-- FILTER BUTTON -->
        <button type="submit" class="btn-filter">Lọc báo cáo</button>

        <!-- ================= EXPORT ================= -->
        <div class="export-group">
          <button type="button" class="btn-export-main" id="exportButton">
            <span>Xuất báo cáo</span>
            <span class="arrow">▼</span>
          </button>

          <div class="export-menu" id="exportMenu">
            <!-- EXCEL -->
            <a
              class="excel-option"
              href="${pageContext.request.contextPath}/admin/report/export?type=${selectedType}&date=${selectedDate}"
            >
              Excel (.xlsx)
            </a>

            <!-- PDF -->
            <a
              class="pdf-option"
              href="${pageContext.request.contextPath}/admin/report/export?type=${selectedType}&date=${selectedDate}&format=pdf"
            >
              PDF (.pdf)
            </a>
          </div>
        </div>
      </div>
    </form>
  </section>

  <!-- ================= KPI ================= -->
  <section class="kpi-grid">
    <!-- TOTAL REVENUE -->
    <div class="report-card kpi-card">
      <div class="kpi-icon">₫</div>
      <div>
        <div class="kpi-label">Tổng doanh thu</div>
        <div class="kpi-value">
          ${totalRevenue}
          <span class="kpi-unit">VNĐ</span>
        </div>
      </div>
    </div>

    <!-- COMPLETED ORDERS -->
    <div class="report-card kpi-card">
      <div class="kpi-icon">🛒</div>
      <div>
        <div class="kpi-label">Đơn hàng hoàn thành</div>
        <div class="kpi-value">
          ${completedOrders}
          <span class="kpi-unit">đơn</span>
        </div>
      </div>
    </div>

    <!-- PRODUCTS SOLD -->
    <div class="report-card kpi-card">
      <div class="kpi-icon">📦</div>
      <div>
        <div class="kpi-label">Sản phẩm đã bán</div>
        <div class="kpi-value">
          ${totalProductsSold}
          <span class="kpi-unit">sản phẩm</span>
        </div>
      </div>
    </div>
  </section>

  <!-- ================= REPORT TABLE ================= -->
  <section class="report-card">
    <div class="report-header">
      <div class="report-title">
        <div class="report-icon">📈</div>
        <div>
          <h2>Báo cáo doanh thu</h2>
          <p>Dữ liệu được tính từ các đơn hàng đã hoàn thành</p>
        </div>
      </div>

      <div class="report-period">
        <c:choose>
          <c:when test="${selectedType == 'day'}"> Theo ngày </c:when>
          <c:when test="${selectedType == 'week'}"> Theo tuần </c:when>
          <c:when test="${selectedType == 'month'}"> Theo tháng </c:when>
          <c:when test="${selectedType == 'year'}"> Theo năm </c:when>
          <c:otherwise> Theo ngày </c:otherwise>
        </c:choose>
        &nbsp;•&nbsp; ${selectedDate}
      </div>
    </div>

    <!-- ================= TABLE ================= -->
    <div class="table-wrapper">
      <table>
        <thead>
          <tr>
            <th>Ngày</th>
            <th>Doanh thu</th>
            <th>Số đơn hàng</th>
          </tr>
        </thead>

        <tbody>
          <c:choose>
            <c:when test="${not empty revenueByDate}">
              <c:forEach var="row" items="${revenueByDate}">
                <tr>
                  <td class="date">${row[0]}</td>
                  <td class="revenue">${row[1]} VNĐ</td>
                  <td class="order-count">
                    <span class="order-badge">${row[2]}</span>
                  </td>
                </tr>
              </c:forEach>
            </c:when>
            <c:otherwise>
              <tr>
                <td colspan="3" class="empty">
                  <div class="empty-icon">📭</div>
                  Không có dữ liệu trong khoảng thời gian này.
                </td>
              </tr>
            </c:otherwise>
          </c:choose>
        </tbody>
      </table>
    </div>

    <!-- ================= TOTAL ================= -->
    <div class="report-footer">
      <span class="total-label">Tổng doanh thu:</span>
      <span class="total-value">${totalRevenue} VNĐ</span>
    </div>
  </section>
</div>

<%@ include file="/WEB-INF/include/footer.jsp" %>

<!-- ================= JAVASCRIPT ================= -->
<script>
  document.addEventListener("DOMContentLoaded", function () {
    const exportButton = document.getElementById("exportButton");
    const exportMenu = document.getElementById("exportMenu");

    if (!exportButton || !exportMenu) {
      return;
    }

    /* =========================
       CLICK EXPORT BUTTON
       ========================= */
    exportButton.addEventListener("click", function (event) {
      event.stopPropagation();
      exportMenu.classList.toggle("show");
      exportButton.classList.toggle("active");
    });

    /* =========================
       CLICK INSIDE MENU
       ========================= */
    exportMenu.addEventListener("click", function (event) {
      event.stopPropagation();
    });

    /* =========================
       CLICK OUTSIDE
       ========================= */
    document.addEventListener("click", function () {
      exportMenu.classList.remove("show");
      exportButton.classList.remove("active");
    });
  });
</script>