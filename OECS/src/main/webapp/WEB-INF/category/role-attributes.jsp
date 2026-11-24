<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>
<%@taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="/WEB-INF/include/header.jsp" %>

<c:set var="variantMode" value="${managedRole == 'VARIANT'}" />
<div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-4">
    <div>
        <a class="text-decoration-none text-muted small" href="${pageContext.request.contextPath}/category?view=list">
            <i class="bi bi-arrow-left"></i> Quay lại Quản lý danh mục
        </a>
        <h3 class="fw-bold text-dark mt-2 mb-1">
            <c:choose>
                <c:when test="${variantMode}">Quản lý thuộc tính biến thể</c:when>
                <c:otherwise>Quản lý thông số kỹ thuật</c:otherwise>
            </c:choose>
        </h3>
        <p class="text-muted mb-0">
            <c:choose>
                <c:when test="${variantMode}">Cấu hình thuộc tính để tạo SKU theo danh mục.</c:when>
                <c:otherwise>Cấu hình thuộc tính hiển thị trên Product và trang Detail.</c:otherwise>
            </c:choose>
        </p>
    </div>
    <div class="btn-group" role="group" aria-label="Loại thuộc tính">
        <a class="btn ${variantMode ? 'btn-primary' : 'btn-outline-primary'}"
           href="${pageContext.request.contextPath}/category?view=variantAttributes&amp;categoryId=${selectedCategoryId}">
            <i class="bi bi-layers"></i> Biến thể SKU
        </a>
        <a class="btn ${variantMode ? 'btn-outline-primary' : 'btn-primary'}"
           href="${pageContext.request.contextPath}/category?view=specificationAttributes&amp;categoryId=${selectedCategoryId}">
            <i class="bi bi-clipboard-data"></i> Thông số kỹ thuật
        </a>
    </div>
</div>

<c:if test="${param.roleSaved == '1'}">
    <div class="alert alert-success">
        <c:choose>
            <c:when test="${param.hardDeleted == '1'}">
                Đã xóa vĩnh viễn thuộc tính khỏi ATTRIBUTE và gỡ toàn bộ cấu hình danh mục của thuộc tính đó.
            </c:when>
            <c:when test="${param.definitionOnly == '1'}">
                Đã tạo thuộc tính trong kho ATTRIBUTE. Thuộc tính <strong>chưa gán vào danh mục</strong>
                và chưa thay đổi Product/SKU hiện có.
            </c:when>
            <c:otherwise>
                Đã lưu thay đổi thành công.
                <c:if test="${variantMode}">
                    Thuộc tính biến thể mới đã gán sẽ xuất hiện ở form tạo/sửa SKU của danh mục.
                    SKU cũ chưa có giá trị mới sẽ được giữ nguyên.
                </c:if>
            </c:otherwise>
        </c:choose>
    </div>
</c:if>
<c:if test="${not empty roleErrorMessage}">
    <div class="alert alert-danger" role="alert"><c:out value="${roleErrorMessage}"/></div>
</c:if>

<div class="card shadow-sm border-0 rounded-4 mb-4">
    <div class="card-body p-4">
        <form method="get" action="${pageContext.request.contextPath}/category"
              class="row g-3 align-items-end">
            <input type="hidden" name="view" value="${managedRoleView}"/>
            <div class="col-md-6">
                <label for="role-category" class="form-label fw-semibold">Danh mục con</label>
                <select class="form-select" name="categoryId" id="role-category" required>
                    <c:forEach items="${roleCategoryList}" var="cat">
                        <option value="${cat.categoryId}"
                                ${cat.categoryId == selectedCategoryId ? 'selected' : ''}>
                            <c:out value="${cat.categoryName}"/>
                        </option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-md-4">
                <label for="role-keyword" class="form-label fw-semibold">Tìm trong kho ATTRIBUTE</label>
                <input class="form-control" id="role-keyword" name="keyword"
                       maxlength="100" placeholder="RAM, Màu sắc, Pin..."
                       value="${fn:escapeXml(roleKeyword)}"/>
            </div>
            <div class="col-md-2">
                <button type="submit" class="btn btn-primary w-100">Xem thuộc tính</button>
            </div>
        </form>
    </div>
</div>

<c:choose>
    <c:when test="${selectedCategoryId == 0}">
        <div class="alert alert-warning">Chưa có danh mục con. Hãy tạo danh mục con trước khi cấu hình.</div>
    </c:when>
    <c:otherwise>

        <div class="card shadow-sm border-0 rounded-4 mb-4">
            <div class="card-body p-4">
                <details>
                    <summary class="fw-bold text-primary" style="cursor:pointer;">
                        <i class="bi bi-plus-circle me-1"></i> Tạo thuộc tính mới (có thể gán sau)
                    </summary>
                    <p class="text-muted small mt-3">
                        Nếu thuộc tính đã có trong ATTRIBUTE, hãy chọn <strong>Gán</strong> ở danh sách bên dưới,
                        không tạo thêm một bản ghi trùng tên.
                    </p>
                    <form method="post" action="${pageContext.request.contextPath}/category" class="row g-3 mt-1">
                        <input type="hidden" name="action" value="saveRoleMapping"/>
                        <input type="hidden" name="attributeId" value="0"/>
                        <input type="hidden" name="categoryId" value="${selectedCategoryId}"/>
                        <input type="hidden" name="role" value="${managedRole}"/>
                        <input type="hidden" name="roleCsrfToken" value="${roleCsrfToken}"/>
                        <div class="col-md-5">
                            <label class="form-label">Tên thuộc tính *</label>
                            <input class="form-control" name="attributeName" required maxlength="100"
                                   placeholder="VD: Tần số quét"/>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Kiểu dữ liệu (theo DB6) *</label>
                            <select class="form-select" name="dataType" required>
                                <option value="TEXT">TEXT</option>
                                <option value="NUMBER">NUMBER</option>
                                <option value="BOOLEAN">BOOLEAN</option>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Đơn vị (có thể trống)</label>
                            <input class="form-control" name="unit" maxlength="30" placeholder="GB, Hz, mAh..."/>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Nhóm hiển thị *</label>
                            <input class="form-control" name="groupName" maxlength="100" required
                                   value="${variantMode ? 'Biến thể' : 'Thông số khác'}"/>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Thứ tự hiển thị</label>
                            <input class="form-control" type="number" name="displayOrder" min="0" value="0" required/>
                        </div>
                        <div class="col-md-3 d-flex flex-column justify-content-end gap-2">
                            <label><input type="checkbox" name="isRequired" value="1"/> Bắt buộc</label>
                            <small class="text-muted">
                                Áp dụng khi lưu SKU/Product về sau; không yêu cầu tự động cập nhật dữ liệu cũ.
                            </small>
                            <label><input type="checkbox" name="isFilterable" value="1"/> Cho lọc</label>
                        </div>
                        <div class="col-12">
                            <div class="d-flex flex-wrap gap-2">
                                <button class="btn btn-success" type="submit">
                                    <i class="bi bi-check-lg"></i> Tạo và gán thuộc tính
                                </button>
                                <button class="btn btn-outline-primary" type="submit"
                                        name="saveMode" value="definitionOnly">
                                    <i class="bi bi-archive"></i> Chỉ tạo vào kho ATTRIBUTE
                                </button>
                            </div>
                            <div class="form-text mt-2">
                                <c:choose>
                                    <c:when test="${variantMode}">
                                        <strong>Được tạo và gán thuộc tính biến thể ngay cả khi danh mục đã có SKU.</strong>
                                        Bạn có thể bật hoặc tắt <strong>Bắt buộc</strong> khi lưu cấu hình.
                                        Cờ này được áp dụng khi <strong>tạo hoặc sửa SKU sau đó</strong>;
                                        SKU cũ chưa có giá trị vẫn được giữ nguyên. Nếu chỉnh sửa SKU cũ,
                                        bạn cần nhập đủ các thuộc tính đang được đánh dấu Bắt buộc.
                                        Hệ thống không tạo giá trị hoặc thay đổi khóa biến thể SKU cũ tự động.
                                        Chọn “Chỉ tạo vào kho” nếu chưa muốn gán thuộc tính vào danh mục.
                                    </c:when>
                                    <c:otherwise>
                                        <strong>Chỉ tạo vào kho</strong> sẽ lưu định nghĩa ATTRIBUTE;
                                        bạn có thể gán cho danh mục sau.
                                    </c:otherwise>
                                </c:choose>
                            </div>
                        </div>
                    </form>
                </details>
            </div>
        </div>

        <div class="alert alert-warning small">
            <i class="bi bi-exclamation-triangle"></i>
            <strong>Lưu ý về “Bắt buộc”:</strong> Cấu hình này sẽ được kiểm tra khi tạo/sửa
            SKU hoặc sản phẩm. Những SKU/sản phẩm cũ thiếu giá trị không bị sửa tự động;
            khi mở chỉnh sửa chúng, bạn cần nhập đủ giá trị đang bắt buộc.
        </div>

        <div class="alert alert-info small">
            <i class="bi bi-info-circle"></i>
            <strong>Phân biệt vai trò:</strong> VARIANT dành cho SKU, SPECIFICATION dành cho thông số Product.
            Nếu thuộc tính được dùng ở cả hai, DB6 lưu vai trò <code>BOTH</code>.
            Khi là BOTH, nhóm/thứ tự/bắt buộc là trường <strong>dùng chung</strong> nên không được sửa riêng một phía.
            Các giá trị Product và SKU vẫn lưu ở hai bảng độc lập.
        </div>

        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-header bg-white px-4 py-3">
                <h5 class="fw-bold mb-0">Thuộc tính trong kho ATTRIBUTE</h5>
                <small class="text-muted">Thuộc tính đã gán cho màn hình này được xếp lên đầu.</small>
                <div class="alert alert-warning small mt-3 mb-0">
                    <strong>Xóa vĩnh viễn</strong> là xóa định nghĩa ATTRIBUTE trên <strong>toàn hệ thống</strong>
                    và tất cả liên kết CATEGORY_ATTRIBUTE của thuộc tính đó (không chỉ danh mục đang chọn).
                    Chỉ được xóa khi chưa có giá trị Product/SKU; hệ thống sẽ từ chối nếu đã sử dụng.
                    Nếu chỉ muốn bỏ thuộc tính khỏi một danh mục, hãy dùng <strong>Gỡ vai trò này</strong>.
                </div>
            </div>
            <div class="table-responsive">
                <table class="table align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th style="width:65px;">ID</th>
                            <th>Thuộc tính</th>
                            <th>Kiểu</th>
                            <th>Đơn vị</th>
                            <th>Vai trò trong danh mục</th>
                            <th>Nhóm / Thứ tự</th>
                            <th style="min-width:230px;">Thao tác</th>
                            <th style="min-width:165px;">Xóa cứng</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach items="${roleAttributeList}" var="attr">
                            <c:set var="mapping" value="${roleMappingById[attr.attributeId]}"/>
                            <c:set var="rolePresent" value="${not empty mapping and (mapping.attributeType == managedRole or mapping.attributeType == 'BOTH')}"/>
                            <c:set var="roleShared" value="${not empty mapping and mapping.attributeType == 'BOTH'}"/>
                            <tr>
                                <td class="text-muted">#${attr.attributeId}</td>
                                <td>
                                    <span class="fw-semibold"><c:out value="${attr.attributeName}"/></span>
                                    <c:if test="${not attr.active}">
                                        <span class="badge text-bg-secondary">Ngừng sử dụng</span>
                                    </c:if>
                                </td>
                                <td><code><c:out value="${attr.dataType}"/></code></td>
                                <td><c:out value="${attr.unit}" default="—"/></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${empty mapping}">
                                            <span class="text-muted small">Chưa gán</span>
                                        </c:when>
                                        <c:when test="${roleShared}">
                                            <span class="badge bg-warning-subtle text-warning-emphasis">BOTH</span>
                                        </c:when>
                                        <c:when test="${rolePresent}">
                                            <span class="badge bg-success-subtle text-success">Đã gán</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-light border text-secondary">
                                                <c:out value="${mapping.attributeType}"/>
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td>
                                    <c:if test="${not empty mapping}">
                                        <span><c:out value="${mapping.groupName}"/></span>
                                        <small class="text-muted"> (#${mapping.displayOrder})</small>
                                    </c:if>
                                    <c:if test="${empty mapping}">—</c:if>
                                    </td>
                                    <td>
                                    <c:choose>
                                        <c:when test="${not attr.active}">
                                            <small class="text-muted">Không thể gán khi đã ngừng sử dụng</small>
                                        </c:when>
                                        <c:otherwise>
                                            <details class="mb-2">
                                                <summary class="text-primary small fw-semibold" style="cursor:pointer;">
                                                    <c:choose>
                                                        <c:when test="${roleShared}">Đang dùng chung</c:when>
                                                        <c:when test="${rolePresent}">Sửa cấu hình</c:when>
                                                        <c:when test="${not empty mapping}">Dùng thêm vai trò này</c:when>
                                                        <c:otherwise>Gán vào danh mục</c:otherwise>
                                                    </c:choose>
                                                </summary>
                                                <c:choose>
                                                    <c:when test="${roleShared}">
                                                        <p class="text-muted small mt-2 mb-1">Không sửa nhóm/thứ tự khi dùng chung hai vai trò.</p>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <form method="post" action="${pageContext.request.contextPath}/category"
                                                              class="border rounded-3 p-2 mt-2" style="min-width:235px;">
                                                            <input type="hidden" name="action" value="saveRoleMapping"/>
                                                            <input type="hidden" name="role" value="${managedRole}"/>
                                                            <input type="hidden" name="categoryId" value="${selectedCategoryId}"/>
                                                            <input type="hidden" name="attributeId" value="${attr.attributeId}"/>
                                                            <input type="hidden" name="expectedSignature"
                                                                   value="${roleSignatureById[attr.attributeId]}"/>
                                                            <input type="hidden" name="roleCsrfToken" value="${roleCsrfToken}"/>
                                                            <c:if test="${not empty mapping and not rolePresent}">
                                                                <p class="small text-muted">Sẽ chuyển thành <strong>BOTH</strong> và giữ nguyên cấu hình phía trước.</p>
                                                            </c:if>
                                                            <label class="form-label small mb-1">Nhóm hiển thị</label>
                                                            <input class="form-control form-control-sm mb-2" name="groupName"
                                                                   maxlength="100" required
                                                                   value="${not empty mapping ? fn:escapeXml(mapping.groupName) : (variantMode ? 'Biến thể' : 'Thông số khác')}"/>
                                                            <label class="form-label small mb-1">Thứ tự</label>
                                                            <input type="number" min="0" name="displayOrder" required
                                                                   class="form-control form-control-sm mb-2"
                                                                   value="${not empty mapping ? mapping.displayOrder : 0}"/>
                                                            <label class="d-block small mb-1">
                                                                <input type="checkbox" name="isRequired" value="1"
                                                                       ${not empty mapping and mapping.required ? 'checked' : ''}/>
                                                                Bắt buộc
                                                            </label>
                                                            <small class="text-muted d-block mb-2">
                                                                Bật/tắt Bắt buộc không sửa dữ liệu cũ.
                                                                <c:choose>
                                                                    <c:when test="${variantMode}">
                                                                        SKU tạo mới hoặc được chỉnh sửa sau đó phải có giá trị nếu Bắt buộc đang bật.
                                                                    </c:when>
                                                                    <c:otherwise>
                                                                        Sản phẩm tạo mới hoặc được chỉnh sửa sau đó phải có giá trị nếu Bắt buộc đang bật.
                                                                    </c:otherwise>
                                                                </c:choose>
                                                            </small>
                                                            <label class="d-block small mb-2">
                                                                <input type="checkbox" name="isFilterable" value="1"
                                                                       ${not empty mapping and mapping.filterable ? 'checked' : ''}/>
                                                                Cho lọc
                                                            </label>
                                                            <button type="submit" class="btn btn-primary btn-sm w-100">
                                                                <c:choose>
                                                                    <c:when test="${rolePresent}">Lưu cấu hình</c:when>
                                                                    <c:otherwise>Gán thuộc tính</c:otherwise>
                                                                </c:choose>
                                                            </button>
                                                        </form>
                                                    </c:otherwise>
                                                </c:choose>
                                            </details>
                                            <c:if test="${rolePresent}">
                                                <form method="post" action="${pageContext.request.contextPath}/category"
                                                      onsubmit="return confirm('Gỡ vai trò này khỏi danh mục? Dữ liệu đã dùng sẽ được bảo vệ.');">
                                                    <input type="hidden" name="action" value="removeRoleMapping"/>
                                                    <input type="hidden" name="categoryId" value="${selectedCategoryId}"/>
                                                    <input type="hidden" name="attributeId" value="${attr.attributeId}"/>
                                                    <input type="hidden" name="role" value="${managedRole}"/>
                                                    <input type="hidden" name="expectedSignature"
                                                           value="${roleSignatureById[attr.attributeId]}"/>
                                                    <input type="hidden" name="roleCsrfToken" value="${roleCsrfToken}"/>
                                                    <button class="btn btn-link btn-sm text-danger p-0" type="submit">Gỡ vai trò này</button>
                                                </form>
                                                <c:if test="${not roleShared}">
                                                    <details class="mt-2">
                                                        <summary class="text-muted small" style="cursor:pointer;">Sửa tên / kiểu / đơn vị (có kiểm tra)</summary>
                                                        <form method="post" action="${pageContext.request.contextPath}/category"
                                                              class="border rounded-3 p-2 mt-2" style="min-width:235px;">
                                                            <input type="hidden" name="action" value="updateRoleDefinition"/>
                                                            <input type="hidden" name="categoryId" value="${selectedCategoryId}"/>
                                                            <input type="hidden" name="attributeId" value="${attr.attributeId}"/>
                                                            <input type="hidden" name="role" value="${managedRole}"/>
                                                            <input type="hidden" name="roleCsrfToken" value="${roleCsrfToken}"/>
                                                            <label class="form-label small mb-1">Tên thuộc tính</label>
                                                            <input name="attributeName" maxlength="100" required
                                                                   class="form-control form-control-sm mb-2"
                                                                   value="${fn:escapeXml(attr.attributeName)}"/>
                                                            <label class="form-label small mb-1">Kiểu dữ liệu</label>
                                                            <select name="dataType" class="form-select form-select-sm mb-2">
                                                                <option value="TEXT" ${attr.dataType == 'TEXT' ? 'selected' : ''}>TEXT</option>
                                                                <option value="NUMBER" ${attr.dataType == 'NUMBER' ? 'selected' : ''}>NUMBER</option>
                                                                <option value="BOOLEAN" ${attr.dataType == 'BOOLEAN' ? 'selected' : ''}>BOOLEAN</option>
                                                            </select>
                                                            <label class="form-label small mb-1">Đơn vị</label>
                                                            <input name="unit" maxlength="30" class="form-control form-control-sm mb-2"
                                                                   value="${fn:escapeXml(attr.unit)}"/>
                                                            <p class="small text-muted">Chỉ lưu khi thuộc tính không phục vụ vai trò kia ở bất kỳ danh mục nào. Đổi kiểu bị chặn nếu đã có giá trị.</p>
                                                            <button class="btn btn-outline-primary btn-sm w-100" type="submit">Lưu định nghĩa</button>
                                                        </form>
                                                    </details>
                                                </c:if>
                                            </c:if>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td>
                                    <form method="post" action="${pageContext.request.contextPath}/category"
                                          data-attribute-name="<c:out value='${attr.attributeName}'/>"
                                          onsubmit="return confirmAttributeHardDelete(this);">
                                        <input type="hidden" name="action" value="hardDeleteAttribute"/>
                                        <input type="hidden" name="role" value="${managedRole}"/>
                                        <input type="hidden" name="categoryId" value="${selectedCategoryId}"/>
                                        <input type="hidden" name="attributeId" value="${attr.attributeId}"/>
                                        <input type="hidden" name="roleCsrfToken" value="${roleCsrfToken}"/>
                                        <input type="hidden" name="confirmedAttributeName" value=""/>
                                        <button type="submit" class="btn btn-outline-danger btn-sm">
                                            <i class="bi bi-trash3"></i> Xóa vĩnh viễn
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty roleAttributeList}">
                            <tr><td colspan="8" class="text-center text-muted py-5">
                                    Không tìm thấy thuộc tính. Hãy tạo thuộc tính mới ở phía trên.
                                </td></tr>
                            </c:if>
                    </tbody>
                </table>
            </div>
        </div>

    </c:otherwise>
</c:choose>

<script>
    function confirmAttributeHardDelete(form) {
        var name = form.getAttribute('data-attribute-name');
        var answer = window.prompt(
                'XÓA VĨNH VIỄN thuộc tính "' + name + '" khỏi toàn hệ thống?\n'
                + 'Mọi liên kết của nó với danh mục sẽ bị gỡ.\n'
                + 'Nếu đã có giá trị Product/SKU, hệ thống sẽ không cho xóa.\n\n'
                + 'Để xác nhận, nhập chính xác tên thuộc tính:');
        if (answer === null || answer !== name) {
            if (answer !== null)
                window.alert('Tên xác nhận không khớp. Đã hủy thao tác.');
            return false;
        }
        form.elements['confirmedAttributeName'].value = answer;
        return true;
    }
</script>

<%@include file="/WEB-INF/include/footer.jsp" %>
