
<%@ page pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ include file="/WEB-INF/include/header.jsp" %>

<link rel="stylesheet"
      href="${pageContext.request.contextPath}/assets/css/customer-orders.css">

<style>
    .customer-toast-container {
        position: fixed;
        top: 90px;
        right: 24px;
        z-index: 9999;
        width: min(390px, calc(100vw - 32px));
        display: flex;
        flex-direction: column;
        gap: 12px;
        pointer-events: none;
    }

    .customer-toast {
        position: relative;
        display: flex;
        align-items: flex-start;
        gap: 12px;
        padding: 16px 42px 18px 16px;
        background: #fff;
        border-radius: 12px;
        box-shadow: 0 8px 28px rgba(15, 23, 42, .16);
        border-left: 4px solid #16a34a;
        pointer-events: auto;
        overflow: hidden;
        animation: customerToastIn .3s ease forwards;
    }

    .customer-toast.error {
        border-left-color: #dc2626;
    }

    .customer-toast-icon {
        font-size: 22px;
        color: #16a34a;
        line-height: 1.2;
    }

    .customer-toast.error .customer-toast-icon {
        color: #dc2626;
    }

    .customer-toast-content {
        flex: 1;
        min-width: 0;
    }

    .customer-toast-title {
        display: block;
        color: #1e293b;
        font-size: 14px;
        font-weight: 700;
        margin-bottom: 4px;
    }

    .customer-toast-message {
        color: #64748b;
        font-size: 13px;
        line-height: 1.5;
        overflow-wrap: anywhere;
    }

    .customer-toast-close {
        position: absolute;
        top: 10px;
        right: 12px;
        border: 0;
        background: transparent;
        color: #94a3b8;
        font-size: 20px;
        cursor: pointer;
        line-height: 1;
    }

    .customer-toast-progress {
        position: absolute;
        bottom: 0;
        left: 0;
        height: 3px;
        width: 100%;
        background: #16a34a;
        transform-origin: left;
        animation: customerToastProgress 4s linear forwards;
    }

    .customer-toast.error .customer-toast-progress {
        background: #dc2626;
    }

    .customer-toast.hide {
        animation: customerToastOut .25s ease forwards;
    }

    @keyframes customerToastIn {
        from {
            opacity: 0;
            transform: translateX(25px);
        }
        to {
            opacity: 1;
            transform: translateX(0);
        }
    }

    @keyframes customerToastOut {
        to {
            opacity: 0;
            transform: translateX(25px);
        }
    }

    @keyframes customerToastProgress {
        from {
            transform: scaleX(1);
        }
        to {
            transform: scaleX(0);
        }
    }

    @media (max-width: 576px) {
        .customer-toast-container {
            top: 75px;
            right: 16px;
        }
    }

    /* =========================
       CANCEL CONFIRMATION MODAL
       ========================= */

    .purchase-timeline .purchase-timeline-note {
        grid-column: 1 / -1;
        margin: 4px 0 0;
        overflow-wrap: anywhere;
    }

    #cancel-order.purchase-cancel-button {
        color: #fff;
        background: #de2020;
        border-color: #de2020;
        border-radius: 10px;
        font-weight: 700;
    }

    #cancel-order.purchase-cancel-button:hover,
    #cancel-order.purchase-cancel-button:focus-visible {
        color: #fff;
        background: #bc1919;
        border-color: #bc1919;
    }


    .cancel-modal {
        display: none;
        position: fixed;
        inset: 0;
        z-index: 10000;
        background: rgba(15, 23, 42, .55);
        justify-content: center;
        align-items: center;
        padding: 16px;
        width: 100%;
        height: 100%;
        max-width: none;
        max-height: none;
        margin: 0;
        border: 0;
        box-sizing: border-box;
    }

    .cancel-modal::backdrop {
        background: transparent;
    }

    .cancel-modal-content label {
        display: block;
        text-align: left;
    }

    .cancel-modal-content textarea {
        display: block;
        width: 100%;
        box-sizing: border-box;
        margin: 6px 0 16px;
        padding: 8px;
        font: inherit;
        resize: vertical;
    }

    .cancel-modal[open] {
        display: flex;
    }

    .cancel-modal-content {
        width: 100%;
        max-width: 420px;
        background: #fff;
        border-radius: 14px;
        padding: 26px;
        box-shadow: 0 12px 40px rgba(0, 0, 0, .2);
        animation: cancelModalIn .2s ease;
    }

    .cancel-modal-content h3 {
        margin: 0 0 10px;
        color: #1e293b;
        font-size: 20px;
        font-weight: 700;
    }

    .cancel-modal-content p {
        margin: 0;
        color: #64748b;
        font-size: 14px;
        line-height: 1.6;
    }

    .cancel-modal-actions {
        display: flex;
        justify-content: flex-end;
        gap: 10px;
        margin-top: 24px;
    }

    .cancel-modal-btn {
        border: 0;
        border-radius: 8px;
        padding: 10px 18px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        transition: background .2s ease;
    }

    .cancel-modal-btn:disabled {
        opacity: .6;
        cursor: not-allowed;
    }

    .cancel-modal-btn-secondary {
        background: #f1f5f9;
        color: #334155;
    }

    .cancel-modal-btn-secondary:hover {
        background: #e2e8f0;
    }

    .cancel-modal-btn-danger {
        background: #dc2626;
        color: #fff;
    }

    .cancel-modal-btn-danger:hover {
        background: #b91c1c;
    }

    @keyframes cancelModalIn {
        from {
            opacity: 0;
            transform: translateY(12px) scale(.98);
        }
        to {
            opacity: 1;
            transform: translateY(0) scale(1);
        }
    }

    @media (max-width: 480px) {
        .cancel-modal-content {
            padding: 22px;
        }

        .cancel-modal-actions {
            flex-direction: column-reverse;
        }

        .cancel-modal-btn {
            width: 100%;
        }
    }
</style>

<div class="purchases-root">

    <div class="customer-toast-container"
         aria-live="polite"
         aria-atomic="true">

        <c:if test="${not empty sessionScope.customerOrderMessage}">
            <div class="customer-toast" role="status">
                <i class="bi bi-check-circle-fill customer-toast-icon"
                   aria-hidden="true"></i>

                <div class="customer-toast-content">
                    <strong class="customer-toast-title">
                        Thao tác thành công!
                    </strong>
                    <div class="customer-toast-message">
                        <c:out value="${sessionScope.customerOrderMessage}"/>
                    </div>
                </div>

                <button type="button"
                        class="customer-toast-close"
                        aria-label="Đóng thông báo"
                        onclick="closeCustomerToast(this)">
                    &times;
                </button>

                <div class="customer-toast-progress"></div>
            </div>
            <c:remove var="customerOrderMessage" scope="session"/>
        </c:if>

        <c:if test="${not empty sessionScope.customerOrderError}">
            <div class="customer-toast error" role="alert">
                <i class="bi bi-exclamation-circle-fill customer-toast-icon"
                   aria-hidden="true"></i>

                <div class="customer-toast-content">
                    <strong class="customer-toast-title">
                        Thao tác chưa thành công!
                    </strong>
                    <div class="customer-toast-message">
                        <c:out value="${sessionScope.customerOrderError}"/>
                    </div>
                </div>

                <button type="button"
                        class="customer-toast-close"
                        aria-label="Đóng thông báo"
                        onclick="closeCustomerToast(this)">
                    &times;
                </button>

                <div class="customer-toast-progress"></div>
            </div>
            <c:remove var="customerOrderError" scope="session"/>
        </c:if>

    </div>

    <a class="purchase-back"
       href="${pageContext.request.contextPath}/my-orders">
        <i class="bi bi-arrow-left" aria-hidden="true"></i>
        Trở lại Đơn mua
    </a>

    <div class="purchase-heading">
        <div>
            <span class="purchase-eyebrow">THEO DÕI ĐƠN HÀNG</span>

            <h1>Đơn hàng #${order.orderId}</h1>

            <c:if test="${not empty orderingRestriction}">
                <div class="alert alert-warning" role="alert">
                    <c:out value="${orderingRestriction}"/>
                </div>
            </c:if>

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
    <%-- Thông báo gửi yêu cầu trả hàng thành công --%>
    <c:if test="${not empty returnSuccessMessage}">

        <div class="purchase-panel"
             style="margin-bottom: 20px;
             border-left: 4px solid #16a34a;
             background: #f0fdf4;"
             role="status">

            <div style="color: #166534;">

                <i class="bi bi-check-circle-fill me-2"></i>

                <c:out value="${returnSuccessMessage}"/>

            </div>

        </div>

    </c:if>

    <%-- Lịch sử trả hàng của đơn --%>
    <c:if test="${not empty returnExchangeRequests}">

        <section class="purchase-panel"
                 style="margin-bottom: 20px;">

            <h2>
                <i class="bi bi-arrow-counterclockwise me-2"></i>
                Lịch sử trả hàng
            </h2>

            <c:forEach var="returnRequest"
                       items="${returnExchangeRequests}">

                <div style="border: 1px solid #e5e7eb;
                     border-radius: 10px;
                     padding: 16px;
                     margin-top: 12px;">

                    <%-- Mã yêu cầu và trạng thái --%>
                    <div class="d-flex flex-wrap
                         justify-content-between
                         align-items-center gap-2">

                        <strong>
                            Yêu cầu trả hàng
                            #<c:out value="${returnRequest.requestId}"/>
                        </strong>

                        <c:choose>

                            <c:when test="${returnRequest.requestStatus eq 'PENDING'}">
                                <span class="badge bg-warning text-dark">
                                    <i class="bi bi-clock-history me-1"></i>
                                    Đang chờ xử lý
                                </span>
                            </c:when>

                            <c:when test="${returnRequest.requestStatus eq 'APPROVED'}">
                                <span class="badge bg-success">
                                    <i class="bi bi-check-circle me-1"></i>
                                    Đã chấp nhận
                                </span>
                            </c:when>

                            <c:when test="${returnRequest.requestStatus eq 'REJECTED'}">
                                <span class="badge bg-danger">
                                    <i class="bi bi-x-circle me-1"></i>
                                    Đã từ chối
                                </span>
                            </c:when>

                        </c:choose>

                    </div>

                    <%-- Thời gian gửi yêu cầu --%>
                    <div class="purchase-muted small mt-2">

                        Gửi lúc:

                        <fmt:formatDate
                            value="${returnRequest.createdAt}"
                            pattern="dd/MM/yyyy HH:mm"/>

                    </div>

                    <%-- Danh sách sản phẩm được yêu cầu trả --%>
                    <div class="mt-3">

                        <strong>Sản phẩm trả hàng:</strong>

                        <c:forEach var="returnItem"
                                   items="${returnRequest.items}">

                            <div style="background: #f8fafc;
                                 border-radius: 8px;
                                 padding: 12px;
                                 margin-top: 8px;">

                                <strong>
                                    <c:out value="${returnItem.productName}"/>
                                </strong>

                                <div class="purchase-muted small mt-1">

                                    SKU:
                                    <c:out value="${returnItem.skuCode}"/>

                                </div>

                                <div class="small mt-1">

                                    Số lượng trả:
                                    <strong>
                                        <c:out value="${returnItem.quantity}"/>
                                    </strong>

                                </div>

                            </div>

                        </c:forEach>

                    </div>

                    <%-- Lý do trả hàng --%>
                    <div class="mt-3 small">

                        <strong>Lý do trả hàng:</strong>

                        <c:out value="${returnRequest.reason}"/>

                    </div>

                    <%-- Thời gian Staff xử lý --%>
                    <c:if test="${not empty returnRequest.reviewedAt}">

                        <div class="purchase-muted small mt-2">

                            Xử lý lúc:

                            <fmt:formatDate
                                value="${returnRequest.reviewedAt}"
                                pattern="dd/MM/yyyy HH:mm"/>

                        </div>

                    </c:if>

                    <%-- Ghi chú từ Staff --%>
                    <c:if test="${not empty returnRequest.staffNote}">

                        <div class="mt-3 small">

                            <strong>Ghi chú từ cửa hàng:</strong>

                            <c:out value="${returnRequest.staffNote}"/>

                        </div>

                    </c:if>

                    <%-- Hướng dẫn theo trạng thái --%>
                    <c:choose>

                        <c:when test="${returnRequest.requestStatus eq 'PENDING'}">

                            <div class="alert alert-warning small mt-3 mb-0">

                                Cửa hàng đang xem xét yêu cầu.
                                Vui lòng chờ nhân viên liên hệ
                                để hướng dẫn trả hàng.

                            </div>

                        </c:when>

                        <c:when test="${returnRequest.requestStatus eq 'APPROVED'}">

                            <div class="alert alert-success small mt-3 mb-0">

                                Yêu cầu trả hàng đã được chấp nhận.
                                Nhân viên sẽ liên hệ để xử lý
                                việc hoàn tiền ngoài hệ thống.

                            </div>

                        </c:when>

                        <c:when test="${returnRequest.requestStatus eq 'REJECTED'}">

                            <div class="alert alert-danger small mt-3 mb-0">

                                Yêu cầu trả hàng đã bị từ chối.
                                Bạn chỉ có thể gửi lại yêu cầu
                                nếu đơn hàng vẫn đủ điều kiện.

                            </div>

                        </c:when>

                    </c:choose>

                </div>

            </c:forEach>

        </section>

    </c:if>
    <div class="purchase-detail-grid">

        <div>

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

                            <c:set var="approvedCancellation"
                                   value="${entry.status eq 'CANCELLED' and entry.actorType eq 'STAFF' and order.cancelRequestStatus eq 'APPROVED'}" />
                            <strong>
                                <c:choose>
                                    <c:when test="${approvedCancellation}">Nhân viên đã duyệt hủy đơn</c:when>
                                    <c:otherwise><c:out value="${entry.label}" /></c:otherwise>
                                </c:choose>
                            </strong>
                            <c:set var="historyNote" value="${approvedCancellation ? order.cancelReviewNote : entry.reason}" />
                            <c:if test="${not empty historyNote}">
                                <p class="purchase-timeline-note"><c:out value="${historyNote}" /></p>
                            </c:if>
                        </li>
                    </c:forEach>
                </ol>
            </section>

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
                                <c:choose>
                                    <c:when test="${not empty item.imageUrl}">
                                        <c:url var="productImage" value="/${item.imageUrl}" />
                                        <img src="<c:out value='${productImage}'/>" alt=""
                                             style="width:100%; height:100%; object-fit:contain; border-radius:inherit;" />
                                    </c:when>

                                    <c:otherwise>
                                        <i class="bi bi-box-seam" aria-hidden="true"></i>
                                    </c:otherwise>
                                </c:choose>
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
                                                  Đánh giá
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

            <c:if test="${canRequestReturnExchange}">
                <div class="purchase-panel" style="margin-top: 20px;">
                    <h2>
                        <i class="bi bi-box-arrow-in-left me-2"
                           aria-hidden="true"></i>
                        Trả hàng
                    </h2>

                    <p class="purchase-muted">
                        Bạn có thể gửi yêu cầu trả hàng cho từng
                        sản phẩm trong vòng 7 ngày kể từ ngày nhận hàng.
                        Mỗi sản phẩm chỉ được duyệt trả một lần.
                    </p>

                    <c:url var="returnExchangeUrl" value="/return-exchange">
                        <c:param name="orderId" value="${order.orderId}" />
                    </c:url>

                    <a href="${returnExchangeUrl}"
                       class="purchase-button-secondary"
                       style="display: flex;
                       align-items: center;
                       justify-content: center;
                       gap: 8px;
                       width: 100%;
                       box-sizing: border-box;
                       margin-top: 12px;">
                        <i class="bi bi-arrow-return-left"
                           aria-hidden="true"></i>
                        Yêu cầu trả hàng
                    </a>
                </div>
            </c:if>

        </div>

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

                        <c:when test="${order.paymentStatus == 'REFUNDED'}">
                            Đã hoàn tiền
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

            <c:if test="${order.orderStatus == 'PENDING_PAYMENT'}">
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

            </c:if>

            <c:if test="${order.cancelRequestStatus eq 'PENDING'}">
                <p class="purchase-cancel-note" role="status">Yêu cầu hủy đang chờ nhân viên duyệt.</p>
            </c:if>
            <c:if test="${canCancelOrder}">
                <button type="button" id="cancel-order" class="purchase-button-secondary purchase-cancel-button"
                        onclick="document.getElementById('cancelModal').showModal()">
                    Hủy đơn hàng
                </button>

            </c:if>

            <c:if test="${contactStoreToCancel}">
                <p class="purchase-cancel-note">Đơn đã thanh toán online. Vui lòng liên hệ cửa hàng nếu cần hủy.</p>
            </c:if>

        </aside>
    </div>
</div>

<c:if test="${canCancelOrder}">
    <c:set var="needsCancelReview" value="${order.orderStatus eq 'CONFIRMED' or order.orderStatus eq 'PACKING'}" />
    <dialog id="cancelModal" class="cancel-modal" aria-labelledby="cancelModalTitle">
        <form class="cancel-modal-content" method="post"
              action="${pageContext.request.contextPath}/my-orders/cancel">
            <input type="hidden" name="id" value="${order.orderId}">
            <input type="hidden" name="csrfToken"
                   value="<c:out value='${sessionScope.customerOrderToken}' />">

            <h3 id="cancelModalTitle">${needsCancelReview ? 'Gửi yêu cầu hủy' : 'Hủy đơn hàng'}</h3>
            <p>${needsCancelReview ? 'Nhân viên sẽ xem xét yêu cầu trước khi hủy đơn.' : 'Đơn hàng sẽ được hủy sau khi bạn xác nhận.'}</p>
            <c:if test="${order.discountAmount gt 0}">
                <p>Lượt sử dụng voucher của đơn đã đặt vẫn được giữ.</p>
            </c:if>

            <c:if test="${needsCancelReview}">
                <label for="cancelReason">Lý do hủy đơn hàng</label>
                <textarea id="cancelReason" name="reason" rows="3" maxlength="500" required autofocus></textarea>
            </c:if>

            <div class="cancel-modal-actions">
                <button type="button" class="cancel-modal-btn cancel-modal-btn-secondary"
                        onclick="document.getElementById('cancelModal').close()">Quay lại</button>
                <button type="submit" class="cancel-modal-btn cancel-modal-btn-danger">
                    ${needsCancelReview ? 'Gửi yêu cầu hủy' : 'Xác nhận hủy'}
                </button>
            </div>
        </form>
    </dialog>
</c:if>

<script>
    function closeCustomerToast(button) {
        const toast = button.closest(".customer-toast");

        if (toast) {
            toast.classList.add("hide");

            setTimeout(function () {
                toast.remove();
            }, 250);
        }
    }

    document.addEventListener("DOMContentLoaded", function () {
        document.querySelectorAll(".customer-toast").forEach(function (toast) {
            setTimeout(function () {
                if (toast.isConnected) {
                    toast.classList.add("hide");

                    setTimeout(function () {
                        toast.remove();
                    }, 250);
                }
            }, 4000);
        });
    });


    const cancelDialog = document.getElementById("cancelModal");
    if (cancelDialog) {
        cancelDialog.addEventListener("click", function (event) {
            if (event.target === cancelDialog) {
                cancelDialog.close();
            }
        });

        cancelDialog.querySelector("form").addEventListener("submit", function () {
            this.querySelector('button[type="submit"]').disabled = true;
        });

        if (window.location.hash === "#cancel-order") {
            cancelDialog.showModal();
        }
    }
</script>

<%@ include file="/WEB-INF/include/footer.jsp" %>
