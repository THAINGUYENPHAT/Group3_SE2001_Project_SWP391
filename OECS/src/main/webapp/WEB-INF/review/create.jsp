<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<%@include file="/WEB-INF/include/header.jsp" %>

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
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }

    .review-card-header {
        padding: 20px 24px;
        border-bottom: 1px solid #e2e8f0;
    }

    .review-card-title {
        color: #0f172a;
        font-size: 1rem;
        font-weight: 700;
        margin: 0;
    }

    .review-card-body {
        padding: 25px;
    }

    .form-label {
        color: #475569;
        font-size: 0.85rem;
        font-weight: 600;
        margin-bottom: 8px;
    }

    .form-control {
        border: 1px solid #cbd5e1;
        border-radius: 8px;
        font-size: 0.9rem;
    }

    .form-control:focus {
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }

    /* ==========================
       RATING STAR
       ========================== */

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
        font-size: 2rem;
        color: #cbd5e1;
        cursor: pointer;
        transition: 0.2s;
    }

    .rating-box label:hover,
    .rating-box label:hover ~ label,
    .rating-box input:checked ~ label {
        color: #f59e0b;
    }

    .rating-text {
        color: #64748b;
        font-size: 0.8rem;
        margin-top: 5px;
    }

    /* ==========================
       IMAGE
       ========================== */

    .upload-box {
        border: 1px dashed #cbd5e1;
        border-radius: 10px;
        padding: 20px;
        background: #f8fafc;
    }

    .upload-icon {
        color: #2563eb;
        font-size: 1.5rem;
    }

    .image-preview {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
        margin-top: 15px;
    }

    .image-preview img {
        width: 90px;
        height: 90px;
        object-fit: cover;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
    }

    /* ==========================
       BUTTON
       ========================== */

    .btn-submit-review {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 7px;

        padding: 10px 18px;

        border: none;
        border-radius: 8px;

        background: #2563eb;
        color: #ffffff;

        font-size: 0.88rem;
        font-weight: 600;

        transition: 0.2s;
    }

    .btn-submit-review:hover {
        background: #1d4ed8;
    }

    .btn-back {
        display: inline-flex;
        align-items: center;
        gap: 6px;

        padding: 9px 16px;

        border: 1px solid #cbd5e1;
        border-radius: 8px;

        background: #ffffff;
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
            Đánh giá sản phẩm
        </h1>

        <div class="page-description">
            Chia sẻ trải nghiệm của bạn về sản phẩm đã mua.
        </div>

    </div>


    <c:if test="${not empty sessionScope.errorMessage}">

        <div class="alert alert-danger alert-dismissible fade show">

            <i class="bi bi-exclamation-circle-fill me-2"></i>

            ${sessionScope.errorMessage}

            <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert">
            </button>

        </div>

        <c:remove
            var="errorMessage"
            scope="session"/>

    </c:if>


    <div class="review-card">

        <div class="review-card-header">

            <h5 class="review-card-title">

                <i class="bi bi-star me-2 text-primary"></i>

                Viết đánh giá

            </h5>

        </div>


        <div class="review-card-body">

            <form
                action="${pageContext.request.contextPath}/review"
                method="post"
                enctype="multipart/form-data">

                <input
                    type="hidden"
                    name="action"
                    value="create">

                <input
                    type="hidden"
                    name="orderItemId"
                    value="${orderItemId}">


                <div class="mb-4">

                    <label class="form-label">
                        Đánh giá của bạn
                    </label>


                    <div class="rating-box">

                        <input
                            type="radio"
                            id="star5"
                            name="rating"
                            value="5"
                            required>

                        <label
                            for="star5"
                            title="5 sao">
                            ★
                        </label>


                        <input
                            type="radio"
                            id="star4"
                            name="rating"
                            value="4">

                        <label
                            for="star4"
                            title="4 sao">
                            ★
                        </label>


                        <input
                            type="radio"
                            id="star3"
                            name="rating"
                            value="3">

                        <label
                            for="star3"
                            title="3 sao">
                            ★
                        </label>


                        <input
                            type="radio"
                            id="star2"
                            name="rating"
                            value="2">

                        <label
                            for="star2"
                            title="2 sao">
                            ★
                        </label>


                        <input
                            type="radio"
                            id="star1"
                            name="rating"
                            value="1">

                        <label
                            for="star1"
                            title="1 sao">
                            ★
                        </label>

                    </div>

                    <div class="rating-text">
                        Chọn từ 1 đến 5 sao.
                    </div>

                </div>


                <div class="mb-4">

                    <label class="form-label">
                        Nội dung đánh giá
                    </label>

                    <textarea
                        name="comment"
                        class="form-control"
                        rows="6"
                        maxlength="2000"
                        placeholder="Hãy chia sẻ cảm nhận của bạn về sản phẩm..."></textarea>

                    <div class="text-muted small mt-1">
                        Tối đa 2000 ký tự.
                    </div>

                </div>


                <div class="mb-4">

                    <label class="form-label">
                        Hình ảnh sản phẩm
                    </label>


                    <div class="upload-box">

                        <div class="d-flex align-items-center gap-3">

                            <div class="upload-icon">
                                <i class="bi bi-images"></i>
                            </div>

                            <div class="flex-grow-1">

                                <input
                                    type="file"
                                    name="images"
                                    id="reviewImages"
                                    class="form-control"
                                    accept=".jpg,.jpeg,.png,.webp"
                                    multiple>

                                <div class="text-muted small mt-2">
                                    Tối đa 3 ảnh, mỗi ảnh tối đa 5MB.
                                </div>

                            </div>

                        </div>


                        <div
                            id="imagePreview"
                            class="image-preview">
                        </div>

                    </div>

                </div>


                <div class="d-flex gap-2">

                    <button
                        type="submit"
                        class="btn-submit-review">

                        <i class="bi bi-send"></i>

                        Gửi đánh giá

                    </button>


                    <a
                        href="${pageContext.request.contextPath}/orders"
                        class="btn-back">

                        <i class="bi bi-arrow-left"></i>

                        Quay lại

                    </a>

                </div>

            </form>

        </div>

    </div>

</div>


<script>
    const reviewImages =
            document.getElementById("reviewImages");

    const imagePreview =
            document.getElementById("imagePreview");


    reviewImages.addEventListener(
        "change",
        function () {

            imagePreview.innerHTML = "";

            const files =
                    Array.from(this.files);

            if (files.length > 3) {

                alert("Bạn chỉ được chọn tối đa 3 ảnh.");

                this.value = "";

                return;
            }


            files.forEach(function (file) {

                if (!file.type.startsWith("image/")) {
                    return;
                }

                const reader =
                        new FileReader();

                reader.onload =
                    function (e) {

                        const img =
                                document.createElement("img");

                        img.src =
                                e.target.result;

                        imagePreview.appendChild(
                                img
                        );
                    };

                reader.readAsDataURL(
                        file
                );
            });
        }
    );
</script>


<%@include file="/WEB-INF/include/footer.jsp" %>