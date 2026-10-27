<%@ page pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ include file="/WEB-INF/include/header.jsp" %>

<link rel="stylesheet"
      href="${pageContext.request.contextPath}/assets/css/customer-orders.css">

<div class="purchases-root">

    <%-- Quay lai danh sach don hang --%>
    <a class="purchase-back"
       href="${pageContext.request.contextPath}/my-orders">
        <i class="bi bi-arrow-left" aria-hidden="true"></i>
        Trở lại Đơn mua
    </a>

    <%-- Tieu de don hang --%>
    <div class="purchase-heading">
        <div>
            <span class="purchase-eyebrow">THEO DÕI ĐƠN HÀNG</span>

            <h1>Đơn hàng #${order.orderId}</h1>

            <p>
                Đặt ngày
                <fmt:formatDate value="${order.createdAt}"
                                pattern="dd/MM/yyyy · HH:mm" />

            <span aria-hidden="true">—</span>

            <c:out value="${statusLabels[order.orderStatus]}"
                   default="Đang cập nhật trạng thái" />
            </p>
        </div>

        <a class="purchase-button-secondary"
           href="${pageContext.request.contextPath}/my-orders/detail?id=${order.orderId}">
            <i class="bi bi-arrow-clockwise" aria-hidden="true"></i>
            Cập nhật
        </a>
    </div>

    <%-- Thong bao thanh cong --%>
    <c:if test="${not empty sessionScope.customerOrderMessage}">
        <div class="alert alert-success" role="status">
            <c:out value="${sessionScope.customerOrderMessage}" />
        </div>

        <c:remove var="customerOrderMessage" scope="session" />
    </c:if>

    <%-- Thong bao loi --%>
    <c:if test="${not empty sessionScope.customerOrderError}">
        <div class="alert alert-danger" role="alert">
            <c:out value="${sessionScope.customerOrderError}" />
        </div>

        <c:remove var="customerOrderError" scope="session" />
    </c:if>

    <%-- Trang thai va tien trinh don hang --%>
    <c:choose>
        <c:when test="${order.orderStatus == 'CANCELLED'}">
            <div class="purchase-cancelled-banner">
                <i class="bi bi-x-circle" aria-hidden="true"></i>

                <div>
                    <strong>Đơn hàng đã hủy</strong>
                    <p>
                        Đơn này đã dừng xử lý.
                        Bạn có thể xem lại thông tin mua hàng bên dưới.
                    </p>
                </div>
            </div>
        </c:when>

        <c:when test="${not empty trackingSteps}">
            <section class="purchase-panel"
                     aria-label="Tiến trình đơn hàng">

                <ol class="purchase-progress">
                    <c:forEach var="step" items="${trackingSteps}">
                        <li class="${step.done ? 'is-done' : ''} ${step.current ? 'is-current' : ''}"
                            ${step.current ? 'aria-current="step"' : ''}>

                        <span class="purchase-progress-icon">
                            <i class="bi bi-${step.icon}"
                               aria-hidden="true"></i>
                        </span>

                        <strong>
                            <c:out value="${step.label}" />
                        </strong>

                        <c:if test="${not empty step.at}">
                            <time>
                                <fmt:formatDate value="${step.at}"
                                                pattern="dd/MM/yyyy HH:mm" />
                            </time>
                        </c:if>
                        </li>
                    </c:forEach>
                </ol>

                <p class="purchase-tracking-note">
                    Trạng thái do cửa hàng cập nhật.
                    Thời gian chỉ hiển thị khi có mốc được ghi nhận.
                </p>
            </section>
        </c:when>
    </c:choose>

    <div class="purchase-detail-grid">

        <%-- Cot thong tin don hang --%>
        <div>

            <%-- Dia chi nhan hang --%>
            <section class="purchase-panel purchase-address">
                <h2>
                    <i class="bi bi-geo-alt me-2" aria-hidden="true"></i>
                    Địa chỉ nhận hàng
                </h2>

                <strong>
                    <c:out value="${order.recipientName}" />
                </strong>

                <p>
                    <c:out value="${order.recipientPhone}" />
                    <br>
                    <c:out value="${order.shippingAddress}" />
                </p>
            </section>

            <%-- Lich su trang thai --%>
            <section class="purchase-panel">
                <h2>
                    <i class="bi bi-clock-history me-2" aria-hidden="true"></i>
                    Lịch sử trạng thái
                </h2>

                <c:if test="${empty history}">
                    <p class="purchase-muted">
                        Chưa có lịch sử trạng thái.
                    </p>
                </c:if>

                <ol class="purchase-timeline">
                    <c:forEach var="entry" items="${history}">
                        <li>
                        <time>
                            <fmt:formatDate value="${entry.updatedAt}"
                                            pattern="dd/MM/yyyy HH:mm:ss" />
                        </time>

                        <strong>
                            <c:out value="${entry.label}" />
                        </strong>
                        </li>
                    </c:forEach>
                </ol>
            </section>

            <%-- Danh sach san pham --%>
            <section class="purchase-card"
                     aria-label="Sản phẩm đã mua">

                <div class="purchase-card-head">
                    <strong>Sản phẩm đã đặt</strong>
                    <span class="purchase-muted">OECS STORE</span>
                </div>

                <div class="purchase-products">
                    <c:forEach var="item" items="${items}">
                        <div class="purchase-product">
                            <span class="purchase-product-icon">
                                <i class="bi bi-box-seam"
                                   aria-hidden="true"></i>
                            </span>

                            <div class="purchase-product-info">
                                <h2>
                                    <c:out value="${item.productName}"
                                           default="Sản phẩm đã đặt" />
                                </h2>

                                <p>
                                    Mã sản phẩm:
                                    <c:out value="${item.skuCode}"
                                           default="${item.skuId}" />
                                </p>

                                <span>
                                    x${item.quantity} ·
                                    <fmt:formatNumber value="${item.price}"
                                                      maxFractionDigits="0" />đ / sản phẩm
                                </span>

                                <c:if test="${order.orderStatus eq 'COMPLETED'
                                              or order.orderStatus eq 'Completed'
                                              or order.orderStatus eq 'DELIVERED'
                                              or order.orderStatus eq 'Delivered'}">
                                    <c:if test="${not empty item.orderItemId}">
                                        <c:url var="reviewUrl" value="/review">
                                            <c:param name="view" value="create" />
                                            <c:param name="orderItemId" value="${item.orderItemId}" />
                                        </c:url>
                                        <div class="purchase-review-action">
                                            <a href="${reviewUrl}" class="purchase-review-btn">
                                                <i class="bi bi-star-fill"></i>
                                                Đánh giá / Xem đánh giá
                                            </a>
                                        </div>
                                    </c:if>
                                </c:if>
                            </div>

                            <div class="purchase-product-price">
                                <fmt:formatNumber value="${item.price * item.quantity}"
                                                  maxFractionDigits="0" />đ
                            </div>
                        </div>
                    </c:forEach>

                    <c:if test="${empty items}">
                        <p class="purchase-muted my-3">
                            Chưa có thông tin sản phẩm cho đơn này.
                        </p>
                    </c:if>
                </div>
            </section>
        </div>

        <%-- Cot thong tin thanh toan --%>
        <aside class="purchase-panel"
               aria-labelledby="purchase-payment-title">

            <h2 id="purchase-payment-title">Thông tin thanh toán</h2>

            <div class="purchase-summary-row">
                <span>Tiền hàng</span>
                <span>
                    <fmt:formatNumber value="${order.totalAmount + order.discountAmount - order.shippingFee}"
                                      maxFractionDigits="0" />đ
                </span>
            </div>

            <div class="purchase-summary-row">
                <span>Phí vận chuyển</span>
                <span>
                    <fmt:formatNumber value="${order.shippingFee}"
                                      maxFractionDigits="0" />đ
                </span>
            </div>

            <div class="purchase-summary-row">
                <span>Giảm giá</span>
                <span class="text-success">
                    −<fmt:formatNumber value="${order.discountAmount}"
                                      maxFractionDigits="0" />đ
                </span>
            </div>

            <div class="purchase-summary-row is-total">
                <span>Thành tiền</span>
                <strong>
                    <fmt:formatNumber value="${order.totalAmount}"
                                      maxFractionDigits="0" />đ
                </strong>
            </div>

            <%-- Phuong thuc va trang thai thanh toan --%>
            <div class="purchase-payment">
                <p>
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

                <p>
                    <c:choose>
                        <c:when test="${order.paymentStatus == 'PAID' && order.totalAmount == 0}">
                            Không còn số tiền cần thanh toán.
                        </c:when>

                        <c:when test="${order.paymentStatus == 'PAID'}">
                            Đã thanh toán
                        </c:when>

                        <c:when test="${order.paymentStatus == 'UNPAID'}">
                            Chưa thanh toán
                        </c:when>

                        <c:otherwise>
                            <c:out value="${order.paymentStatus}" />
                        </c:otherwise>
                    </c:choose>
                </p>
            </div>

            <%-- Cac thao tac theo trang thai don hang --%>
            <c:choose>
                <c:when test="${order.orderStatus == 'PENDING_PAYMENT'}">
                    <a href="${pageContext.request.contextPath}/payment?id=${order.orderId}"
                       style="display: flex;
                       align-items: center;
                       justify-content: center;
                       gap: 8px;
                       width: 100%;
                       box-sizing: border-box;
                       padding: 12px 16px;
                       margin-top: 16px;
                       background: #c2410c;
                       color: #ffffff;
                       border: 1px solid #c2410c;
                       border-radius: 10px;
                       font-size: 15px;
                       font-weight: 700;
                       text-decoration: none;
                       box-shadow: 0 4px 10px rgba(194, 65, 12, 0.2);">
                        <i class="bi bi-credit-card" aria-hidden="true"></i>
                        Tiếp tục thanh toán
                        <i class="bi bi-arrow-right" aria-hidden="true"></i>
                    </a>

                    <p class="purchase-cancel-note">
                        Bạn có thể thanh toán, đổi sang COD hoặc hủy đơn
                        trong thời gian chờ thanh toán.
                    </p>
                </c:when>

                <c:when test="${order.orderStatus == 'PENDING_CONFIRMATION' && order.paymentMethod == 'COD' && (order.paymentStatus != 'PAID' || order.totalAmount == 0)}">
                    <form class="purchase-cancel-form"
                          action="${pageContext.request.contextPath}/my-orders/cancel"
                          method="post"
                          onsubmit="
                                  if (!confirm('Bạn chắc chắn muốn hủy đơn hàng này?')) {
                                      return false;
                                  }
                                  this.querySelector('button').disabled = true;
                          ">

                        <input type="hidden"
                               name="id"
                               value="${order.orderId}">

                        <input type="hidden"
                               name="csrfToken"
                               value="<c:out value='${sessionScope.customerOrderToken}' />">

                        <button type="submit"
                                class="purchase-button-secondary">
                            Hủy đơn hàng
                        </button>
                    </form>

                    <p class="purchase-cancel-note">
                        Có thể hủy trước khi nhân viên xác nhận.
                        Lượt sử dụng voucher của đơn đã đặt vẫn được giữ.
                    </p>
                </c:when>

                <c:when test="${order.orderStatus != 'CANCELLED'}">
                    <p class="purchase-cancel-note">
                        Không thể tự hủy đơn ở trạng thái hiện tại.
                    </p>
                </c:when>
            </c:choose>
        </aside>
    </div>
</div>

<%@ include file="/WEB-INF/include/footer.jsp" %>
