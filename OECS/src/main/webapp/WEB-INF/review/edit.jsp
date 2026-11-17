
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fn" uri="jakarta.tags.functions"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<style>
    .review-page {
        max-width: 900px;
        margin: 0 auto;
        padding-bottom: 30px;
    }

    .page-title {
        font-size: 1.55rem;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 4px;
    }

    .page-description {
        color: #64748b;
        font-size: 0.9rem;
    }

    .review-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        overflow: hidden;
    }

    .review-card-header {
        padding: 20px 24px;
        border-bottom: 1px solid #e2e8f0;
    }

    .review-card-body {
        padding: 25px;
    }

    .review-card-title {
        color: #0f172a;
        font-size: 1rem;
        font-weight: 700;
        margin: 0;
    }

    .form-label {
        color: #475569;
        font-size: 0.85rem;
        font-weight: 600;
    }

    .form-control {
        border-radius: 8px;
        border: 1px solid #cbd5e1;
    }

    .form-control:focus {
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }

    .rating-box {
        display: flex;
        flex-direction: row-reverse;
        justify-content: flex-end;
        gap: 6px;
    }

    .rating-box input {
        display: none;
    }

    .rating-box label {
        color: #cbd5e1;
        cursor: pointer;
        font-size: 2rem;
    }

    .rating-box label:hover,
    .rating-box label:hover ~ label,
    .rating-box input:checked ~ label {
        color: #f59e0b;
    }

    .review-images {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
    }

    .review-images img {
        width: 90px;
        height: 90px;
        object-fit: cover;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
    }

    .review-image-item {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 6px;
        font-size: 0.82rem;
        color: #475569;
        cursor: pointer;
    }

    .review-image-item:has(input:checked) img {
        opacity: 0.4;
        outline: 2px solid #ef4444;
    }

    .review-image-item input {
        margin-right: 4px;
    }

    .image-hint {
        font-size: 0.83rem;
        color: #64748b;
        margin-top: 8px;
    }

    .btn-save {
        background: #2563eb;
        color: white;
        border: none;
        border-radius: 8px;
        padding: 10px 17px;
        font-weight: 600;
    }

    .btn-save:hover {
        background: #1d4ed8;
    }

    .btn-back {
        padding: 9px 16px;
        border: 1px solid #cbd5e1;
        border-radius: 8px;
        background: white;
        color: #475569;
        text-decoration: none;
    }

    .btn-back:hover {
        background: #f8fafc;
        color: #0f172a;
    }
</style>

<div class="review-page">

    <div class="mb-4">
        <h1 class="page-title">
            Chỉnh sửa đánh giá
        </h1>
        <div class="page-description">
            Cập nhật số sao, nội dung và hình ảnh đánh giá của bạn.
        </div>
    </div>

    <c:if test="${not empty sessionScope.errorMessage}">
        <div class="alert alert-danger">
            <c:out value="${sessionScope.errorMessage}"/>
        </div>
        <c:remove var="errorMessage" scope="session"/>
    </c:if>

    <div class="review-card">

        <div class="review-card-header">
            <h5 class="review-card-title">
                <i class="bi bi-pencil-square text-primary me-2"></i>
                Thông tin đánh giá
            </h5>
        </div>

        <div class="review-card-body">

            <form action="${pageContext.request.contextPath}/review"
                  method="post"
                  enctype="multipart/form-data"
                  id="reviewEditForm">

                <input type="hidden" name="action" value="update">
                <input type="hidden" name="reviewId"
                       value="${review.reviewId}">
                <input type="hidden" name="csrfToken"
                       value="${sessionScope.reviewCsrfToken}">

                <div class="mb-4">
                    <label class="form-label">Đánh giá</label>

                    <div class="rating-box">
                        <input type="radio" id="star5" name="rating"
                               value="5" ${review.rating == 5 ? 'checked' : ''}>
                        <label for="star5">★</label>

                        <input type="radio" id="star4" name="rating"
                               value="4" ${review.rating == 4 ? 'checked' : ''}>
                        <label for="star4">★</label>

                        <input type="radio" id="star3" name="rating"
                               value="3" ${review.rating == 3 ? 'checked' : ''}>
                        <label for="star3">★</label>

                        <input type="radio" id="star2" name="rating"
                               value="2" ${review.rating == 2 ? 'checked' : ''}>
                        <label for="star2">★</label>

                        <input type="radio" id="star1" name="rating"
                               value="1" ${review.rating == 1 ? 'checked' : ''}>
                        <label for="star1">★</label>
                    </div>
                </div>

                <div class="mb-4">
                    <label class="form-label">
                        Nội dung đánh giá
                    </label>

                    <textarea name="comment"
                              class="form-control"
                              rows="6"
                              maxlength="2000"><c:out value="${review.comment}"/></textarea>
                </div>

                <div class="mb-4">
                    <label class="form-label">
                        Hình ảnh đánh giá
                    </label>

                    <c:if test="${not empty review.images}">
                        <div class="review-images mb-3">
                            <c:forEach var="img" items="${review.images}">
                                <label class="review-image-item">
                                    <img src="${pageContext.request.contextPath}${fn:escapeXml(img)}"
                                         alt="Ảnh đánh giá hiện tại">

                                    <span>
                                        <input type="checkbox"
                                               name="removeImages"
                                               value="${fn:escapeXml(img)}"
                                               class="image-remove">
                                        Xóa ảnh
                                    </span>
                                </label>
                            </c:forEach>
                        </div>
                    </c:if>

                    <input id="newReviewImages"
                           class="form-control"
                           type="file"
                           name="images"
                           multiple
                           accept="image/jpeg,image/png,image/webp">

                    <div class="image-hint">
                        Chọn ảnh cần xóa hoặc thêm ảnh mới.
                        Tổng số ảnh sau khi lưu tối đa 3,
                        mỗi ảnh không quá 5MB.
                        Không chọn ảnh mới thì ảnh cũ vẫn giữ nguyên.
                    </div>

                    <div id="editImageCount" class="image-hint"></div>
                    <div id="editImagePreview"
                         class="review-images mt-2"></div>
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn-save">
                        <i class="bi bi-check-lg me-1"></i>
                        Lưu thay đổi
                    </button>

                    <a href="${pageContext.request.contextPath}/review?view=create&amp;orderItemId=${review.orderItemId}"
                       class="btn-back">
                        Hủy
                    </a>
                </div>

            </form>
        </div>
    </div>
</div>

<script>
    document.addEventListener("DOMContentLoaded", function () {
        const input = document.getElementById("newReviewImages");
        const preview = document.getElementById("editImagePreview");
        const label = document.getElementById("editImageCount");
        const removals =
            Array.from(document.querySelectorAll(".image-remove"));

        let urls = [];

        function clearPreview() {
            urls.forEach(url => URL.revokeObjectURL(url));
            urls = [];
            preview.innerHTML = "";
        }

        function refresh() {
            const kept =
                removals.filter(box => !box.checked).length;

            const files = Array.from(input.files);
            const validTypes = [
                "image/jpeg",
                "image/png",
                "image/webp"
            ];

            if (kept + files.length > 3
                    || files.some(file =>
                        !validTypes.includes(file.type)
                        || file.size > 5 * 1024 * 1024)) {

                alert(
                    "Tối đa 3 ảnh sau khi lưu; chỉ nhận "
                    + "JPG, PNG, WEBP dưới 5MB/ảnh."
                );

                input.value = "";
            }

            clearPreview();

            Array.from(input.files).forEach(file => {
                const url = URL.createObjectURL(file);
                urls.push(url);

                const img = document.createElement("img");
                img.src = url;
                img.alt = "Ảnh mới";
                preview.appendChild(img);
            });

            label.textContent =
                (kept + input.files.length)
                + "/3 ảnh sau khi lưu";
        }

        removals.forEach(box =>
            box.addEventListener("change", refresh));

        input.addEventListener("change", refresh);
        window.addEventListener("pagehide", clearPreview);

        refresh();
    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>
