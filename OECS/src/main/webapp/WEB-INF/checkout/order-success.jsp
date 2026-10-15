<%@ page pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@ include file="/WEB-INF/include/header.jsp" %>

<div class="row justify-content-center my-4">
    <div class="col-lg-8">

        <div class="card border-0 shadow-sm rounded-4">
            <div class="card-body p-4 p-md-5">

                <!-- THONG BAO DAT HANG -->
                <div class="text-center mb-4">
                    <i class="bi bi-check-circle-fill text-success display-4"></i>

                    <h3 class="fw-bold mt-3">
                        Đơn hàng đã được ghi nhận
                    </h3>

                    <p class="text-muted mb-0">
                        Cảm ơn bạn đã mua sắm tại OECS.
                    </p>
                </div>

                <!-- MA DON HANG -->
                <div class="alert alert-success text-center">
                    Mã đơn hàng:
                    <strong>
                        #<c:out value="${order.orderId}" />
                    </strong>
                </div>

                <!-- THONG TIN GIAO HANG -->
                <h5 class="fw-bold mb-3">
                    Thông tin giao hàng
                </h5>

                <p class="mb-1">
                    <strong>
                        <c:out value="${order.recipientName}" />
                    </strong>

                    |

                    <c:out value="${order.recipientPhone}" />
                </p>

                <p class="text-muted">
                    <c:out value="${order.shippingAddress}" />
                </p>

                <p class="text-muted small mb-0">
                    Ngày đặt:
                    <fmt:formatDate
                        value="${order.createdAt}"
                        pattern="dd/MM/yyyy HH:mm" />
                </p>

                <hr class="my-4">

                <!-- THONG TIN THANH TOAN -->
                <h5 class="fw-bold mb-3">
                    Thông tin thanh toán
                </h5>

                <div class="d-flex justify-content-between mb-2">
                    <span>Tiền hàng</span>

                    <span>
                        <fmt:formatNumber
                            value="${order.totalAmount + order.discountAmount - order.shippingFee}"
                            type="number"
                            maxFractionDigits="0" />đ
                    </span>
                </div>

                <div class="d-flex justify-content-between mb-2">
                    <span>Phí vận chuyển</span>

                    <span>
                        <fmt:formatNumber
                            value="${order.shippingFee}"
                            type="number"
                            maxFractionDigits="0" />đ
                    </span>
                </div>

                <div class="d-flex justify-content-between mb-3">
                    <span>Giảm giá</span>

                    <span class="text-success">
                        -<fmt:formatNumber
                            value="${order.discountAmount}"
                            type="number"
                            maxFractionDigits="0" />đ
                    </span>
                </div>

                <div class="d-flex justify-content-between align-items-center border-top pt-3 mb-3">
                    <strong>Tổng thanh toán</strong>

                    <strong class="text-danger fs-4">
                        <fmt:formatNumber
                            value="${order.totalAmount}"
                            type="number"
                            maxFractionDigits="0" />đ
                    </strong>
                </div>

                <p class="mb-2">
                    Phương thức:
                    <strong>
                        <c:choose>
                            <c:when test="${order.paymentMethod == 'COD'}">
                                Thanh toán khi nhận hàng (COD)
                            </c:when>

                            <c:otherwise>
                                <c:out value="${order.paymentMethod}" />
                            </c:otherwise>
                        </c:choose>
                    </strong>
                </p>

                <c:choose>
                    <c:when test="${order.paymentStatus == 'PAID'}">
                        <p class="text-success mb-0">
                            Đơn hàng không còn số tiền cần thanh toán.
                        </p>
                    </c:when>

                    <c:when test="${order.paymentMethod == 'COD'}">
                        <p class="text-muted mb-0">
                            Bạn thanh toán khi nhận được hàng.
                        </p>
                    </c:when>

                    <c:otherwise>
                        <p class="text-muted mb-0">
                            Trạng thái thanh toán:
                            <c:out value="${order.paymentStatus}" />
                        </p>
                    </c:otherwise>
                </c:choose>

                <!-- CAC NUT DIEU HUONG -->
                <div class="d-flex flex-wrap justify-content-center gap-2 mt-4">
                    <a href="${pageContext.request.contextPath}/shop"
                       class="btn btn-primary px-4">
                        <i class="bi bi-bag me-1"></i>
                        Tiếp tục mua sắm
                    </a>

                    <a href="${pageContext.request.contextPath}/cart"
                       class="btn btn-outline-secondary px-4">
                        <i class="bi bi-cart me-1"></i>
                        Về giỏ hàng
                    </a>
                </div>

            </div>
        </div>

    </div>
</div>

<%@ include file="/WEB-INF/include/footer.jsp" %>