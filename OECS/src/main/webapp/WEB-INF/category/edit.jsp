
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fn" uri="jakarta.tags.functions" %>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-md-9 col-lg-7">
        <div class="mb-3">
            <a href="${pageContext.request.contextPath}/category?view=list"
               class="text-decoration-none text-muted fw-medium">
                <i class="bi bi-arrow-left me-1"></i>
                Quay lại danh sách
            </a>
        </div>

        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-body p-4 p-md-5">

                <!-- Header -->
                <div class="d-flex align-items-center mb-4 pb-3 border-bottom">
                    <div class="bg-primary bg-opacity-10 text-primary rounded d-flex align-items-center justify-content-center me-3"
                         style="width: 48px; height: 48px;">
                        <i class="bi bi-pencil-square fs-4"></i>
                    </div>

                    <div>
                        <h4 class="fw-bold mb-0">Chỉnh Sửa Danh Mục</h4>
                        <span class="text-muted fs-7">
                            Cập nhật thông tin danh mục
                        </span>
                    </div>
                </div>

                <c:if test="${not empty errorMessage}">
                    <div class="alert alert-danger" role="alert">
                        <i class="bi bi-exclamation-circle me-2"></i>
                        <c:out value="${errorMessage}"/>
                    </div>
                </c:if>

                <form action="${pageContext.request.contextPath}/category"
                      method="POST">

                    <input type="hidden" name="action" value="edit"/>

                    <div class="mb-4">
                        <label for="category-id"
                               class="form-label fw-semibold text-dark">
                            Mã Danh Mục
                        </label>

                        <input type="text"
                               name="id"
                               id="category-id"
                               class="form-control form-control-lg fs-6 bg-light"
                               value="${category.categoryId}"
                               readonly/>
                    </div>

                    <div class="mb-4">
                        <label for="category-name"
                               class="form-label fw-semibold text-dark">
                            Tên Danh Mục <span class="text-danger">*</span>
                        </label>

                        <input type="text"
                               name="name"
                               id="category-name"
                               class="form-control form-control-lg fs-6"
                               value="${fn:escapeXml(category.categoryName)}"
                               placeholder="VD: Điện thoại, Laptop, Phụ kiện..."
                               required/>

                        <div class="form-text mt-2">
                            Chỉ được nhập chữ cái, chữ số và khoảng trắng.
                        </div>
                    </div>

                    <div class="mb-4">
                        <label for="parent-id"
                               class="form-label fw-semibold text-dark">
                            Danh Mục Cha
                        </label>

                        <select name="parentId"
                                id="parent-id"
                                class="form-select form-select-lg fs-6">

                            <option value=""
                                    ${empty category.parentId ? 'selected' : ''}>
                                📁 Danh mục gốc (không có danh mục cha)
                            </option>

                            <c:forEach items="${categoryList}" var="item">
                                <c:if test="${item.categoryId != category.categoryId}">
                                    <option value="${item.categoryId}"
                                            ${item.categoryId == category.parentId ? 'selected' : ''}>

                                        <c:choose>
                                            <c:when test="${empty item.parentId}">
                                                📁 <c:out value="${item.categoryName}"/> — Danh mục gốc
                                            </c:when>
                                            <c:otherwise>
                                                ↳ <c:out value="${item.categoryName}"/> — Danh mục con
                                            </c:otherwise>
                                        </c:choose>
                                    </option>
                                </c:if>
                            </c:forEach>
                        </select>

                        <div class="form-text mt-2">
                            <i class="bi bi-info-circle me-1"></i>
                            Không thể chọn chính danh mục hiện tại làm danh mục cha.
                        </div>
                    </div>

                    <div class="d-flex gap-2 pt-3 mt-4 border-top">
                        <button type="submit"
                                class="btn btn-primary btn-lg fs-6 px-4">
                            <i class="bi bi-check-lg me-1"></i>
                            Lưu Thay Đổi
                        </button>

                        <a href="${pageContext.request.contextPath}/category?view=list"
                           class="btn btn-light btn-lg fs-6 px-4 border text-muted">
                            Hủy
                        </a>
                    </div>

                </form>
            </div>
        </div>
        <%-- ============================================================
             CẤU HÌNH THÔNG SỐ KỸ THUẬT THEO DANH MỤC CON
             Form riêng, không ảnh hưởng nút Lưu Thay Đổi danh mục.
             Không xóa phần VARIANT của SKU khi bỏ chọn thông số.
             ============================================================ --%>
        <c:if test="${not empty category.parentId}">
            <div class="card shadow-sm border-0 rounded-4 mt-4">
                <div class="card-body p-4 p-md-5">
                    <div class="d-flex align-items-start gap-3 mb-3">
                        <div class="bg-primary bg-opacity-10 text-primary rounded p-3">
                            <i class="bi bi-sliders fs-4"></i>
                        </div>
                        <div>
                            <h5 class="fw-bold mb-1">Cấu hình thông số kỹ thuật</h5>
                            <div class="text-muted small">
                                Chọn thuộc tính có sẵn cho danh mục
                                <strong><c:out value="${category.categoryName}"/></strong>.
                                Sau khi lưu, form Thêm/Sửa sản phẩm sẽ tự tải những thông số này.
                            </div>
                        </div>
                    </div>

                    <c:if test="${not empty specErrorMessage}">
                        <div class="alert alert-danger" role="alert">
                            <c:out value="${specErrorMessage}"/>
                        </div>
                    </c:if>
                    <c:if test="${param.specSaved eq '1'}">
                        <div class="alert alert-success" role="status">
                            Đã lưu cấu hình thông số kỹ thuật thành công.
                        </div>
                    </c:if>

                    <div class="alert alert-info small">
                        <strong>Lưu ý:</strong> Các thuộc tính <strong>VARIANT</strong> hoặc
                        <strong>BOTH</strong> được dùng chung cho SKU. Bạn có thể bật/tắt
                        phần thông số của chúng nhưng không được đổi nhóm, thứ tự hay
                        trạng thái bắt buộc tại đây để tránh ảnh hưởng SKU.
                        Nếu một sản phẩm đã nhập giá trị, hệ thống sẽ không cho
                        bỏ thông số đó.
                    </div>

                    <form method="POST"
                          action="${pageContext.request.contextPath}/category"
                          id="categorySpecsForm">
                        <input type="hidden" name="action" value="saveSpecifications"/>
                        <input type="hidden" name="id" value="${category.categoryId}"/>
                        <input type="hidden" name="specFormMarker" value="1"/>
                        <input type="hidden" name="categorySpecCsrfToken"
                               value="${fn:escapeXml(categorySpecCsrfToken)}"/>

                        <div class="table-responsive">
                            <table class="table table-hover align-middle">
                                <thead class="table-light">
                                    <tr>
                                        <th>Áp dụng</th>
                                        <th>Thuộc tính</th>
                                        <th>Nhóm hiển thị</th>
                                        <th>Bắt buộc</th>
                                        <th>Lọc</th>
                                        <th>Thứ tự</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach items="${specAttributeList}" var="attr">
                                        <c:set var="config"
                                               value="${specConfigById[attr.attributeId]}"/>
                                        <c:set var="hasSkuVariant"
                                               value="${not empty config and (config.attributeType eq 'VARIANT' or config.attributeType eq 'BOTH')}"/>
                                        <c:set var="isSpecChecked"
                                               value="${not empty config and (config.attributeType eq 'SPECIFICATION' or config.attributeType eq 'BOTH')}"/>
                                        <c:if test="${specFormSubmitted}">
                                            <c:set var="isSpecChecked"
                                                   value="${submittedSpecChecked[attr.attributeId] eq true}"/>
                                        </c:if>
                                        <c:set var="groupText" value="${empty config ? 'Thông số khác' : config.groupName}"/>
                                        <c:set var="orderValue" value="${empty config ? 0 : config.displayOrder}"/>
                                        <c:set var="isRequired" value="${not empty config and config.required}"/>
                                        <c:set var="isFilterable" value="${not empty config and config.filterable}"/>
                                        <c:if test="${specFormSubmitted and not hasSkuVariant}">
                                            <c:if test="${submittedSpecGroups.containsKey(attr.attributeId)}">
                                                <c:set var="groupText" value="${submittedSpecGroups[attr.attributeId]}"/>
                                            </c:if>
                                            <c:if test="${submittedSpecOrders.containsKey(attr.attributeId)}">
                                                <c:set var="orderValue" value="${submittedSpecOrders[attr.attributeId]}"/>
                                            </c:if>
                                            <c:set var="isRequired"
                                                   value="${submittedSpecRequired[attr.attributeId] eq true}"/>
                                            <c:set var="isFilterable"
                                                   value="${submittedSpecFilterable[attr.attributeId] eq true}"/>
                                        </c:if>
                                        <tr class="oecs-spec-row" data-locked="${hasSkuVariant}">
                                            <td>
                                                <input type="hidden"
                                                       name="visibleSpecAttributeIds"
                                                       value="${attr.attributeId}"/>
                                                <input type="checkbox"
                                                       class="form-check-input oecs-spec-selected"
                                                       name="selectedSpecAttributeIds"
                                                       value="${attr.attributeId}"
                                                       aria-label="Áp dụng ${fn:escapeXml(attr.attributeName)}"
                                                       ${isSpecChecked ? 'checked' : ''}/>
                                            </td>
                                            <td>
                                                <strong><c:out value="${attr.attributeName}"/></strong>
                                                <c:if test="${not empty attr.unit}">
                                                    <small class="text-muted d-block">
                                                        Đơn vị: <c:out value="${attr.unit}"/>
                                                    </small>
                                                </c:if>
                                                <small class="text-muted d-block">
                                                    <c:out value="${attr.dataType}"/>
                                                </small>
                                                <c:if test="${hasSkuVariant}">
                                                    <span class="badge bg-warning-subtle text-dark border">
                                                        <c:out value="${config.attributeType}"/> — SKU
                                                    </span>
                                                </c:if>
                                            </td>
                                            <td style="min-width:160px;">
                                                <input type="text"
                                                       name="specGroup_${attr.attributeId}"
                                                       maxlength="100"
                                                       class="form-control form-control-sm oecs-spec-field"
                                                       value="${fn:escapeXml(groupText)}"
                                                       ${hasSkuVariant or not isSpecChecked ? 'disabled' : ''}/>
                                            </td>
                                            <td class="text-center">
                                                <input type="checkbox"
                                                       name="specRequired_${attr.attributeId}"
                                                       class="form-check-input oecs-spec-field"
                                                       ${isRequired ? 'checked' : ''}
                                                       ${hasSkuVariant or not isSpecChecked ? 'disabled' : ''}/>
                                            </td>
                                            <td class="text-center">
                                                <input type="checkbox"
                                                       name="specFilterable_${attr.attributeId}"
                                                       class="form-check-input oecs-spec-field"
                                                       ${isFilterable ? 'checked' : ''}
                                                       ${hasSkuVariant or not isSpecChecked ? 'disabled' : ''}/>
                                            </td>
                                            <td style="min-width:90px;">
                                                <input type="number"
                                                       name="specOrder_${attr.attributeId}"
                                                       class="form-control form-control-sm oecs-spec-field"
                                                       value="${fn:escapeXml(orderValue)}"
                                                       min="0" max="2147483647"
                                                       ${hasSkuVariant or not isSpecChecked ? 'disabled' : ''}/>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    <c:if test="${empty specAttributeList}">
                                        <tr><td colspan="6" class="text-center text-muted py-4">
                                                Chưa có thuộc tính đang hoạt động trong ATTRIBUTE.
                                            </td></tr>
                                        </c:if>
                                </tbody>
                            </table>
                        </div>
                        <div class="d-flex flex-wrap gap-2 align-items-center pt-3 border-top">
                            <button type="submit" class="btn btn-primary">
                                <i class="bi bi-check-lg me-1"></i>
                                Lưu cấu hình thông số
                            </button>
                            <span class="small text-muted">
                                Nút này chỉ lưu cấu hình thông số, không đổi tên danh mục.
                            </span>
                        </div>
                    </form>
                </div>
            </div>
            <script>
                (function () {
                    const form = document.getElementById('categorySpecsForm');
                    if (!form)
                        return;
                    form.querySelectorAll('.oecs-spec-row').forEach(function (row) {
                        const checkbox = row.querySelector('.oecs-spec-selected');
                        const fields = row.querySelectorAll('.oecs-spec-field');
                        function update() {
                            const locked = row.dataset.locked === 'true';
                            fields.forEach(function (field) {
                                field.disabled = locked || !checkbox.checked;
                            });
                        }
                        checkbox.addEventListener('change', update);
                        update();
                    });
                }());
            </script>
        </c:if>
    </div>
</div>

<%@include file="/WEB-INF/include/footer.jsp" %>
