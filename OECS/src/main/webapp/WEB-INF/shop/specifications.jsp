
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>

<style>
    /* ========================================
       OECS V2 - THONG SO NOI BAT COMPACT
       ======================================== */

    .oecs-spec-section {
        width: 100%;
        max-width: 1100px;
        margin: 15px auto 30px;
        display: block;
    }

    .oecs-spec-heading {
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-wrap: wrap;
        gap: 12px;
        margin-bottom: 15px;
    }

    .oecs-spec-heading h2 {
        margin: 0;
        font-size: 21px;
        font-weight: 750;
        color: #172033;
    }

    .oecs-spec-show-all {
        padding: 8px 14px;
        border: 1px solid #d0d5dd;
        border-radius: 10px;
        background: #fff;
        color: #344054;
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
    }

    .oecs-spec-show-all:hover {
        background: #eff6ff;
        border-color: #93c5fd;
        color: #2563eb;
    }

    /* GRID */

    .oecs-spec-grid {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        border: 1px solid #e5eaf0;
        border-radius: 12px;
        overflow: hidden;
        background: #fff;
    }

    .oecs-spec-card {
        min-width: 0;
        min-height: 72px;
        display: flex;
        align-items: flex-start;
        gap: 9px;
        padding: 12px 14px;
        border-right: 1px solid #edf0f4;
        border-bottom: 1px solid #edf0f4;
    }

    .oecs-spec-card:nth-child(3n) {
        border-right: none;
    }

    .oecs-spec-card:nth-child(even) {
        background: #fafbfd;
    }

    .oecs-spec-icon {
        flex: 0 0 26px;
        width: 26px;
        height: 26px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 7px;
        background: #eff6ff;
        color: #2563eb;
        font-size: 15px;
    }

    .oecs-spec-info {
        min-width: 0;
        flex: 1;
    }

    .oecs-spec-label {
        font-size: 12px;
        color: #667085;
        line-height: 1.4;
        margin-bottom: 4px;
    }

    .oecs-spec-value {
        font-size: 14px;
        font-weight: 700;
        color: #172033;
        line-height: 1.5;
        overflow-wrap: anywhere;
        white-space: pre-line;
    }

    .oecs-spec-empty {
        grid-column: 1 / -1;
        padding: 20px;
        text-align: center;
        color: #667085;
        font-size: 14px;
    }

    /* MODAL */

    .oecs-spec-modal .modal-dialog {
        max-width: 850px;
    }

    .oecs-spec-modal .modal-content {
        border: none;
        border-radius: 16px;
    }

    .oecs-spec-modal .modal-header {
        padding: 18px 24px;
    }

    .oecs-spec-modal .modal-title {
        font-size: 20px;
        font-weight: 750;
    }

    .oecs-spec-modal .modal-body {
        padding: 22px 24px;
    }

    .oecs-spec-product-name {
        font-size: 18px;
        font-weight: 700;
        margin-bottom: 4px;
    }

    .oecs-spec-product-brand {
        color: #667085;
        font-size: 13px;
        margin-bottom: 20px;
    }

    .oecs-spec-group {
        margin-bottom: 24px;
    }

    .oecs-spec-group-title {
        font-size: 17px;
        font-weight: 750;
        padding-bottom: 10px;
        border-bottom: 2px solid #edf0f4;
        margin-bottom: 8px;
    }

    .oecs-spec-detail-row {
        display: grid;
        grid-template-columns: 40% minmax(0, 1fr);
        gap: 14px;
        padding: 12px 6px;
        border-bottom: 1px dashed #e2e8f0;
    }

    .oecs-spec-detail-name {
        color: #667085;
        font-size: 13px;
        line-height: 1.6;
    }

    .oecs-spec-detail-value {
        color: #172033;
        font-size: 13px;
        line-height: 1.6;
        overflow-wrap: anywhere;
        white-space: pre-line;
    }

    @media (max-width: 767.98px) {

        .oecs-spec-grid {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }

        .oecs-spec-card {
            padding: 11px 10px;
            min-height: 68px;
        }

        .oecs-spec-heading h2 {
            font-size: 19px;
        }

        .oecs-spec-icon {
            flex-basis: 23px;
            width: 23px;
            height: 23px;
            font-size: 13px;
        }

        .oecs-spec-label {
            font-size: 11px;
        }

        .oecs-spec-value {
            font-size: 12px;
        }

        .oecs-spec-modal .modal-dialog {
            margin: 0;
            max-width: none;
            height: 100%;
        }

        .oecs-spec-modal .modal-content {
            height: 100%;
            border-radius: 0;
        }

        .oecs-spec-detail-row {
            grid-template-columns: 42% minmax(0, 1fr);
            gap: 10px;
        }
    }
</style>

<%-- ========================================
     1. THONG SO NOI BAT
     ======================================== --%>

<section class="oecs-spec-section"
         id="productSpecifications">

    <div class="oecs-spec-heading">

        <h2>
            Thông số nổi bật
        </h2>

        <button type="button"
                class="oecs-spec-show-all"
                data-bs-toggle="modal"
                data-bs-target="#oecsAllSpecsModal">

            Xem tất cả thông số
            <i class="bi bi-arrow-right ms-1"></i>

        </button>

    </div>

    <div class="oecs-spec-grid">

        <c:choose>

            <%-- Dung featuredSpecs neu co --%>

            <c:when test="${not empty featuredSpecs}">

                <c:forEach items="${featuredSpecs}"
                           var="spec"
                           varStatus="st">

                    <c:if test="${st.index < 6}">

                        <div class="oecs-spec-card">

                            <div class="oecs-spec-icon">
                                <i class="bi bi-sliders"></i>
                            </div>

                            <div class="oecs-spec-info">

                                <div class="oecs-spec-label">
                                    <c:out value="${spec.attributeName}"/>
                                </div>

                                <div class="oecs-spec-value">
                                    <c:out value="${spec.value}"/>
                                </div>

                            </div>

                        </div>

                    </c:if>

                </c:forEach>

            </c:when>

            <%-- Neu Servlet chua co featuredSpecs,
                 su dung specs nhu JSP cu --%>

            <c:when test="${not empty specs}">

                <c:forEach items="${specs}"
                           var="spec"
                           varStatus="st">

                    <c:if test="${st.index < 6}">

                        <div class="oecs-spec-card">

                            <div class="oecs-spec-icon">
                                <i class="bi bi-sliders"></i>
                            </div>

                            <div class="oecs-spec-info">

                                <div class="oecs-spec-label">
                                    <c:out value="${spec.attributeName}"/>
                                </div>

                                <div class="oecs-spec-value">
                                    <c:out value="${spec.value}"/>
                                </div>

                            </div>

                        </div>

                    </c:if>

                </c:forEach>

            </c:when>

            <c:otherwise>

                <div class="oecs-spec-empty">

                    <i class="bi bi-info-circle me-1"></i>
                    Thông số kỹ thuật đang được cập nhật.

                </div>

            </c:otherwise>

        </c:choose>

    </div>

</section>

<%-- ========================================
     2. XEM TAT CA THONG SO
     ======================================== --%>

<div class="modal fade oecs-spec-modal"
     id="oecsAllSpecsModal"
     tabindex="-1"
     aria-labelledby="oecsAllSpecsTitle"
     aria-hidden="true">

    <div class="modal-dialog
         modal-xl
         modal-dialog-centered
         modal-dialog-scrollable">

        <div class="modal-content">

            <div class="modal-header">

                <h2 class="modal-title"
                    id="oecsAllSpecsTitle">
                    Thông số kỹ thuật
                </h2>

                <button type="button"
                        class="btn-close"
                        data-bs-dismiss="modal"
                        aria-label="Đóng">
                </button>

            </div>

            <div class="modal-body">

                <div class="oecs-spec-product-name">
                    <c:out value="${product.productName}"/>
                </div>

                <div class="oecs-spec-product-brand">
                    <c:out value="${product.brand.brandName}"/>
                </div>

                <c:choose>

                    <%-- Hien thi theo nhom --%>

                    <c:when test="${not empty specGroups}">

                        <c:forEach items="${specGroups}"
                                   var="group">

                            <div class="oecs-spec-group">

                                <h3 class="oecs-spec-group-title">
                                    <c:out value="${group.key}"/>
                                </h3>

                                <c:forEach items="${group.value}"
                                           var="spec">

                                    <div class="oecs-spec-detail-row">

                                        <div class="oecs-spec-detail-name">
                                            <c:out value="${spec.attributeName}"/>
                                        </div>

                                        <div class="oecs-spec-detail-value">
                                            <c:out value="${spec.value}"/>
                                        </div>

                                    </div>

                                </c:forEach>

                            </div>

                        </c:forEach>

                    </c:when>

                    <%-- Hien thi danh sach cu neu chua co nhom --%>

                    <c:when test="${not empty specs}">

                        <div class="oecs-spec-group">

                            <h3 class="oecs-spec-group-title">
                                Thông số sản phẩm
                            </h3>

                            <c:forEach items="${specs}"
                                       var="spec">

                                <div class="oecs-spec-detail-row">

                                    <div class="oecs-spec-detail-name">
                                        <c:out value="${spec.attributeName}"/>
                                    </div>

                                    <div class="oecs-spec-detail-value">
                                        <c:out value="${spec.value}"/>
                                    </div>

                                </div>

                            </c:forEach>

                        </div>

                    </c:when>

                    <c:otherwise>

                        <div class="oecs-spec-empty">
                            Chưa có thông số kỹ thuật.
                        </div>

                    </c:otherwise>

                </c:choose>

            </div>

            <div class="modal-footer">

                <button type="button"
                        class="btn btn-outline-secondary"
                        data-bs-dismiss="modal">
                    Đóng
                </button>

            </div>

        </div>

    </div>

</div>
