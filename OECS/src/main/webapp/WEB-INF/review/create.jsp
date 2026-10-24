
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@include file="/WEB-INF/include/header.jsp"%>

<c:set var="backUrl"
       value="${pageContext.request.contextPath}/my-orders"/>

<c:if test="${not empty orderId}">
    <c:set var="backUrl"
           value="${pageContext.request.contextPath}/my-orders/detail?id=${orderId}"/>
</c:if>

<style>
    /* ==============================
       OECS REVIEW PAGE
       ============================== */
    .oe-review-page {
        max-width: 920px;
        margin: 28px auto 55px;
        padding: 0 16px;
        color: #0f172a;
    }

    .oe-review-back {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        color: #64748b;
        text-decoration: none;
        font-size: 14px;
        margin-bottom: 20px;
    }

    .oe-review-back:hover {
        color: #2563eb;
    }

    .oe-review-heading {
        margin-bottom: 24px;
    }

    .oe-review-heading h1 {
        font-size: 27px;
        font-weight: 750;
        margin-bottom: 7px;
        color: #0f172a;
    }

    .oe-review-heading p {
        font-size: 14px;
        color: #64748b;
        margin: 0;
    }

    .oe-review-card {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 17px;
        margin-bottom: 18px;
        overflow: hidden;
        box-shadow: 0 4px 20px rgba(15,23,42,.035);
    }

    .oe-review-card-body {
        padding: 25px;
    }

    .oe-review-section-title {
        font-size: 17px;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 18px;
    }

    /* PRODUCT */
    .oe-review-product {
        display: flex;
        align-items: center;
        gap: 16px;
        padding: 20px 25px;
    }

    .oe-review-product-icon {
        width: 70px;
        height: 70px;
        background: #eff6ff;
        color: #2563eb;
        border: 1px solid #dbeafe;
        border-radius: 12px;
        display: flex;
        justify-content: center;
        align-items: center;
        font-size: 29px;
        flex-shrink: 0;
    }

    .oe-review-product-name {
        font-weight: 700;
        font-size: 16px;
        margin: 0 0 6px;
    }

    .oe-review-product-meta {
        color: #64748b;
        font-size: 13px;
        margin: 0;
    }

    .oe-review-tag {
        display: inline-block;
        background: #ecfdf5;
        color: #15803d;
        padding: 5px 10px;
        border-radius: 6px;
        font-size: 12px;
        font-weight: 600;
        margin-top: 9px;
    }

    /* RATING */
    .oe-review-rating {
        display: flex;
        flex-direction: row-reverse;
        justify-content: flex-end;
        gap: 7px;
    }

    .oe-review-rating input {
        position: absolute;
        opacity: 0;
        width: 1px;
        height: 1px;
    }

    .oe-review-rating label {
        color: #cbd5e1;
        font-size: 43px;
        line-height: 1.25;
        cursor: pointer;
        transition: color .15s, transform .15s;
        user-select: none;
    }

    .oe-review-rating label:hover {
        transform: scale(1.08);
    }

    .oe-review-rating label:hover,
    .oe-review-rating label:hover ~ label,
    .oe-review-rating input:checked ~ label {
        color: #ffb81c;
    }

    .oe-review-rating input:focus-visible + label {
        outline: 2px solid #2563eb;
        outline-offset: 3px;
        border-radius: 4px;
    }

    .oe-review-rating-text {
        font-size: 13px;
        color: #64748b;
        margin-top: 8px;
    }

    /* UPLOAD */
    .oe-review-upload {
        border: 2px dashed #cbd5e1;
        background: #f8fafc;
        border-radius: 13px;
        padding: 25px 15px;
        text-align: center;
        transition: .2s;
    }

    .oe-review-upload:hover {
        border-color: #2563eb;
        background: #eff6ff;
    }

    .oe-review-upload-label {
        display: inline-flex;
        flex-direction: column;
        align-items: center;
        gap: 8px;
        color: #2563eb;
        cursor: pointer;
        font-weight: 600;
        font-size: 14px;
    }

    .oe-review-upload-label i {
        font-size: 30px;
    }

    .oe-review-upload-hint {
        font-size: 12px;
        color: #64748b;
        margin-top: 9px;
    }

    .oe-review-preview {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(90px, 1fr));
        gap: 12px;
        margin-top: 16px;
    }

    .oe-review-preview img {
        width: 100%;
        aspect-ratio: 1;
        object-fit: cover;
        border-radius: 10px;
        border: 1px solid #e2e8f0;
    }

    /* COMMENT */
    .oe-review-label {
        font-weight: 650;
        font-size: 14px;
        margin-bottom: 10px;
        display: block;
    }

    .oe-review-suggestions {
        display: flex;
        flex-wrap: wrap;
        gap: 9px;
        margin-bottom: 15px;
    }

    .oe-review-suggestion {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        padding: 8px 12px;
        color: #475569;
        font-size: 12px;
        cursor: pointer;
        transition: .2s;
    }

    .oe-review-suggestion:hover {
        background: #eff6ff;
        color: #2563eb;
        border-color: #bfdbfe;
    }

    .oe-review-comment {
        width: 100%;
        min-height: 175px;
        resize: vertical;
        padding: 16px;
        border-radius: 11px;
        border: 1px solid #cbd5e1;
        background: #f8fafc;
        color: #0f172a;
        font-size: 14px;
        line-height: 1.7;
        outline: none;
        transition: .2s;
    }

    .oe-review-comment:focus {
        background: #fff;
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37,99,235,.1);
    }

    .oe-review-count {
        text-align: right;
        font-size: 12px;
        color: #94a3b8;
        margin-top: 6px;
    }

    /* FOOTER */
    .oe-review-actions {
        display: flex;
        align-items: center;
        justify-content: flex-end;
        gap: 12px;
        padding: 17px 25px;
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 13px;
        position: sticky;
        bottom: 10px;
        z-index: 10;
        box-shadow: 0 5px 25px rgba(15,23,42,.08);
    }

    .oe-review-cancel {
        padding: 11px 22px;
        color: #475569;
        background: #fff;
        border: 1px solid #cbd5e1;
        border-radius: 9px;
        text-decoration: none;
        font-weight: 600;
        font-size: 14px;
    }

    .oe-review-cancel:hover {
        color: #2563eb;
        border-color: #2563eb;
    }

    .oe-review-submit {
        border: none;
        border-radius: 9px;
        background: #2563eb;
        color: #fff;
        padding: 12px 30px;
        font-size: 14px;
        font-weight: 700;
        cursor: pointer;
        transition: .2s;
    }

    .oe-review-submit:hover {
        background: #1d4ed8;
    }

    .oe-review-submit:disabled {
        opacity: .6;
        cursor: not-allowed;
    }

    @media (max-width: 576px) {
        .oe-review-page {
            margin: 18px auto 30px;
            padding: 0 12px;
        }

        .oe-review-card-body {
            padding: 19px;
        }

        .oe-review-product {
            padding: 17px;
        }

        .oe-review-heading h1 {
            font-size: 23px;
        }

        .oe-review-rating label {
            font-size: 37px;
        }

        .oe-review-actions {
            bottom: 0;
            border-radius: 12px 12px 0 0;
            padding: 12px;
        }

        .oe-review-cancel,
        .oe-review-submit {
            flex: 1;
            text-align: center;
            padding: 12px 10px;
        }
    }
</style>

<main class="oe-review-page">

    <!-- BACK -->
    <a class="oe-review-back" href="${backUrl}">
        <i class="bi bi-arrow-left"></i>
        Quay lại đơn hàng
    </a>

    <!-- TITLE -->
    <div class="oe-review-heading">
        <h1>
            <i class="bi bi-star-fill text-warning me-2"></i>
            Đánh giá sản phẩm
        </h1>
        <p>Chia sẻ trải nghiệm mua sắm của bạn tại OECS.</p>
    </div>

    <!-- ERROR -->
    <c:if test="${not empty sessionScope.errorMessage}">
        <div class="alert alert-danger" role="alert">
            <i class="bi bi-exclamation-circle me-2"></i>
            <c:out value="${sessionScope.errorMessage}"/>
        </div>
        <c:remove var="errorMessage" scope="session"/>
    </c:if>

    <form id="oeReviewForm"
          action="${pageContext.request.contextPath}/review"
          method="post"
          enctype="multipart/form-data">

        <input type="hidden" name="action" value="create">
        <input type="hidden"
               name="orderItemId"
               value="${orderItemId}">

        <!-- PRODUCT INFO -->
        <section class="oe-review-card">

            <div class="oe-review-product">

                <div class="oe-review-product-icon">
                    <i class="bi bi-box-seam"></i>
                </div>

                <div>
                    <h2 class="oe-review-product-name">
                        <c:choose>
                            <c:when test="${not empty productName}">
                                <c:out value="${productName}"/>
                            </c:when>
                            <c:otherwise>
                                Sản phẩm đã mua
                            </c:otherwise>
                        </c:choose>
                    </h2>

                    <p class="oe-review-product-meta">
                        SKU #<c:out value="${skuId}"/>
                        · OECS STORE
                    </p>

                    <span class="oe-review-tag">
                        <i class="bi bi-patch-check me-1"></i>
                        Đã mua hàng
                    </span>
                </div>

            </div>

        </section>

        <!-- MAIN REVIEW -->
        <section class="oe-review-card">

            <div class="oe-review-card-body">

                <h2 class="oe-review-section-title">
                    Đánh giá chất lượng sản phẩm
                </h2>

                <!-- RATING -->
                <div class="mb-4">

                    <span class="oe-review-label">
                        Mức độ hài lòng
                        <span class="text-danger">*</span>
                    </span>

                    <div class="oe-review-rating"
                         role="group"
                         aria-label="Đánh giá từ 1 đến 5 sao">

                        <input type="radio"
                               id="oeStar5"
                               name="rating"
                               value="5" required>
                        <label for="oeStar5"
                               title="5 sao"
                               aria-label="5 sao">★</label>

                        <input type="radio"
                               id="oeStar4"
                               name="rating"
                               value="4">
                        <label for="oeStar4"
                               title="4 sao"
                               aria-label="4 sao">★</label>

                        <input type="radio"
                               id="oeStar3"
                               name="rating"
                               value="3">
                        <label for="oeStar3"
                               title="3 sao"
                               aria-label="3 sao">★</label>

                        <input type="radio"
                               id="oeStar2"
                               name="rating"
                               value="2">
                        <label for="oeStar2"
                               title="2 sao"
                               aria-label="2 sao">★</label>

                        <input type="radio"
                               id="oeStar1"
                               name="rating"
                               value="1">
                        <label for="oeStar1"
                               title="1 sao"
                               aria-label="1 sao">★</label>

                    </div>

                    <div id="oeRatingText"
                         class="oe-review-rating-text"
                         aria-live="polite">
                        Vui lòng chọn số sao.
                    </div>

                </div>

                <!-- IMAGE UPLOAD -->
                <div class="mb-4">

                    <label class="oe-review-label">
                        Hình ảnh sản phẩm
                    </label>

                    <div class="oe-review-upload">

                        <label for="oeReviewImages"
                               class="oe-review-upload-label">

                            <i class="bi bi-camera"></i>
                            <span>Thêm hình ảnh</span>

                        </label>

                        <input type="file"
                               id="oeReviewImages"
                               name="images"
                               accept="image/jpeg,image/png,image/webp"
                               multiple
                               class="visually-hidden">

                        <div class="oe-review-upload-hint">
                            JPG, PNG hoặc WEBP · Tối đa 3 ảnh
                            · 5MB mỗi ảnh
                        </div>

                        <div id="oeImagePreview"
                             class="oe-review-preview"></div>

                        <div id="oeImageCount"
                             class="oe-review-upload-hint"
                             aria-live="polite">
                            0/3 ảnh đã chọn
                        </div>

                    </div>

                </div>

                <!-- COMMENT -->
                <div>

                    <label for="oeReviewComment"
                           class="oe-review-label">
                        Nhận xét về sản phẩm
                    </label>

                    <div class="oe-review-suggestions">

                        <button type="button"
                                class="oe-review-suggestion"
                                data-suggestion="Chất lượng tốt">
                            Chất lượng tốt
                        </button>

                        <button type="button"
                                class="oe-review-suggestion"
                                data-suggestion="Đúng mô tả">
                            Đúng mô tả
                        </button>

                        <button type="button"
                                class="oe-review-suggestion"
                                data-suggestion="Đóng gói cẩn thận">
                            Đóng gói cẩn thận
                        </button>

                        <button type="button"
                                class="oe-review-suggestion"
                                data-suggestion="Sản phẩm dễ sử dụng">
                            Dễ sử dụng
                        </button>

                    </div>

                    <textarea id="oeReviewComment"
                              name="comment"
                              class="oe-review-comment"
                              maxlength="2000"
                              placeholder="Hãy chia sẻ cảm nhận của bạn về chất lượng, tính năng và trải nghiệm sử dụng sản phẩm..."></textarea>

                    <div class="oe-review-count">
                        <span id="oeCommentCount">0</span>/2000 ký tự
                    </div>

                </div>

            </div>

        </section>

        <!-- ACTION BUTTONS -->
        <div class="oe-review-actions">

            <a class="oe-review-cancel"
               href="${backUrl}">
                Hủy
            </a>

            <button type="submit"
                    id="oeReviewSubmit"
                    class="oe-review-submit">

                <i class="bi bi-send me-1"></i>
                Gửi đánh giá

            </button>

        </div>

    </form>

</main>

<script>
    document.addEventListener("DOMContentLoaded", function () {

        // =========================================
        // RATING FEEDBACK
        // =========================================
        const ratings = document.querySelectorAll(
                'input[name="rating"]'
                );
        const ratingText =
                document.getElementById("oeRatingText");

        const ratingMessages = {
            1: "1 sao · Rất không hài lòng",
            2: "2 sao · Không hài lòng",
            3: "3 sao · Bình thường",
            4: "4 sao · Hài lòng",
            5: "5 sao · Rất hài lòng"
        };

        ratings.forEach(function (radio) {
            radio.addEventListener("change", function () {
                ratingText.textContent =
                        ratingMessages[this.value];
            });
        });

        // =========================================
        // COMMENT COUNTER
        // =========================================
        const comment =
                document.getElementById("oeReviewComment");

        const commentCount =
                document.getElementById("oeCommentCount");

        function updateCommentCount() {
            commentCount.textContent = comment.value.length;
        }

        comment.addEventListener(
                "input",
                updateCommentCount
                );

        // =========================================
        // SUGGESTION BUTTONS
        // =========================================
        document.querySelectorAll(
                ".oe-review-suggestion"
                ).forEach(function (button) {

            button.addEventListener("click", function () {

                const suggestion =
                        this.dataset.suggestion;

                const current = comment.value.trim();

                if (current.includes(suggestion)) {
                    return;
                }

                const separator = current ? ". " : "";
                const next =
                        current + separator + suggestion;

                comment.value = next.slice(0, 2000);

                updateCommentCount();
                comment.focus();

            });

        });

        // =========================================
        // IMAGE PREVIEW
        // =========================================
        const imageInput =
                document.getElementById("oeReviewImages");

        const imagePreview =
                document.getElementById("oeImagePreview");

        const imageCount =
                document.getElementById("oeImageCount");

        const maxImages = 3;
        const maxSize = 5 * 1024 * 1024;

        let previewUrls = [];

        function clearPreview() {
            previewUrls.forEach(function (url) {
                URL.revokeObjectURL(url);
            });

            previewUrls = [];
            imagePreview.innerHTML = "";
            imageCount.textContent = "0/3 ảnh đã chọn";
        }

        imageInput.addEventListener(
                "change",
                function () {

                    clearPreview();

                    const files = Array.from(this.files);

                    if (files.length > maxImages) {
                        alert("Chỉ được chọn tối đa 3 ảnh.");
                        this.value = "";
                        return;
                    }

                    const allowedTypes = [
                        "image/jpeg",
                        "image/png",
                        "image/webp"
                    ];

                    for (const file of files) {

                        if (!allowedTypes.includes(file.type)) {
                            alert(
                                    "Chỉ hỗ trợ ảnh JPG, PNG và WEBP."
                                    );
                            this.value = "";
                            clearPreview();
                            return;
                        }

                        if (file.size > maxSize) {
                            alert(
                                    "Mỗi ảnh không được vượt quá 5MB."
                                    );
                            this.value = "";
                            clearPreview();
                            return;
                        }
                    }

                    files.forEach(function (file, index) {

                        const url = URL.createObjectURL(file);
                        previewUrls.push(url);

                        const img = document.createElement("img");
                        img.src = url;
                        img.alt = "Ảnh đánh giá " + (index + 1);

                        imagePreview.appendChild(img);

                    });

                    imageCount.textContent =
                            files.length + "/3 ảnh đã chọn";
                }
        );

        // =========================================
        // PREVENT DOUBLE SUBMIT
        // =========================================
        const form =
                document.getElementById("oeReviewForm");

        const submitButton =
                document.getElementById("oeReviewSubmit");

        form.addEventListener("submit", function () {

            if (!form.checkValidity()) {
                return;
            }

            submitButton.disabled = true;
            submitButton.textContent = "Đang gửi...";

        });

        window.addEventListener("pagehide", function () {
            previewUrls.forEach(function (url) {
                URL.revokeObjectURL(url);
            });
        });

    });
</script>

<%@include file="/WEB-INF/include/footer.jsp"%>
