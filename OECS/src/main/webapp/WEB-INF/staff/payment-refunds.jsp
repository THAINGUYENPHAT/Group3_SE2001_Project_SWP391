<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@include file="/WEB-INF/include/header.jsp"%>
<main class="container py-4">
    <h1>Đối soát hoàn tiền</h1>
    <p>Kiểm tra giao dịch tại cổng thanh toán và thực hiện hoàn tiền trước khi xác nhận đã hoàn.</p>
    <c:if test="${not empty sessionScope.refundMessage}">
        <div class="alert alert-info" role="status"><c:out value="${sessionScope.refundMessage}"/></div>
        <c:remove var="refundMessage" scope="session"/>
    </c:if>
    <c:if test="${empty refunds}"><p>Không có yêu cầu hoàn tiền ở trang này.</p></c:if>
    <c:forEach var="refund" items="${refunds}">
        <section class="card mb-3">
            <div class="card-body">
                <h2 class="h5">Hoàn tiền #${refund.id} · Đơn #${refund.orderId}</h2>
                <p><strong><fmt:formatNumber value="${refund.amount}" pattern="#,##0"/> đ</strong>
                    · <c:out value="${refund.method}"/> · <c:out value="${refund.statusLabel}"/></p>
                <p>Giao dịch hệ thống <c:out value="${refund.transactionCode}"/><br>
                    Giao dịch cổng thanh toán <c:out value="${refund.providerTransactionId}"/></p>
                <p><c:out value="${refund.reason}"/></p>
                <c:choose>
                    <c:when test="${refund.status == 'SUCCESS'}">
                        <p>Mã tham chiếu hoàn tiền <c:out value="${refund.reference}"/></p>
                    </c:when>
                    <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/staff/payment-refunds">
                            <input type="hidden" name="csrfToken" value="${sessionScope.refundToken}">
                            <input type="hidden" name="id" value="${refund.id}">
                            <input type="hidden" name="expectedStatus" value="${refund.status}">
                            <c:choose>
                                <c:when test="${refund.status == 'PROCESSING'}">
                                    <label class="form-label" for="reference-${refund.id}">Mã tham chiếu hoàn tiền thực tế</label>
                                    <input class="form-control mb-2" id="reference-${refund.id}" name="reference"
                                           maxlength="150" required>
                                    <button class="btn btn-success" name="status" value="SUCCESS">Xác nhận đã hoàn tiền</button>
                                    <button class="btn btn-outline-danger" name="status" value="FAILED" formnovalidate>Ghi nhận chưa thành công</button>
                                </c:when>
                                <c:otherwise>
                                    <button class="btn btn-primary" name="status" value="PROCESSING">Bắt đầu xử lý</button>
                                </c:otherwise>
                            </c:choose>
                        </form>
                    </c:otherwise>
                </c:choose>
            </div>
        </section>
    </c:forEach>
    <nav aria-label="Phân trang hoàn tiền">
        <c:if test="${currentPage > 1}"><a class="btn btn-outline-secondary" href="?page=${currentPage - 1}">Trang trước</a></c:if>
        <c:if test="${refunds.size() == 50}"><a class="btn btn-outline-secondary" href="?page=${currentPage + 1}">Trang sau</a></c:if>
    </nav>
</main>
<%@include file="/WEB-INF/include/footer.jsp"%>
