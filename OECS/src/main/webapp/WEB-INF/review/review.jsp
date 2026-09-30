<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html>

    <head>

        <meta charset="UTF-8">

        <title>Đánh giá sản phẩm</title>

        <link
            href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
            rel="stylesheet">

        <style>

            body {
                background: #f5f6f8;
            }

            .review-container {
                max-width: 700px;
                margin: 50px auto;
            }

            .review-card {
                border: none;
                border-radius: 12px;
                box-shadow: 0 2px 12px rgba(0,0,0,0.08);
            }

            .rating {
                display: flex;
                flex-direction: row-reverse;
                justify-content: flex-end;
                gap: 5px;
            }

            .rating input {
                display: none;
            }

            .rating label {
                font-size: 36px;
                color: #ccc;
                cursor: pointer;
                transition: 0.2s;
            }

            .rating input:checked ~ label,
            .rating label:hover,
            .rating label:hover ~ label {
                color: #ffc107;
            }

            .preview-image {
                width: 100px;
                height: 100px;
                object-fit: cover;
                border-radius: 8px;
                margin-right: 10px;
                margin-top: 10px;
            }

        </style>

    </head>


    <body>


        <div class="container review-container">


            <div class="card review-card">


                <div class="card-body p-4">


                    <h3 class="mb-4">
                        Đánh giá sản phẩm
                    </h3>


                    <!-- ERROR -->

                    <c:if test="${not empty sessionScope.errorMessage}">

                        <div class="alert alert-danger">

                            ${sessionScope.errorMessage}

                        </div>

                        <c:remove
                            var="errorMessage"
                            scope="session"/>

                    </c:if>


                    <form
                        action="${pageContext.request.contextPath}/review"
                        method="post"
                        enctype="multipart/form-data">


                        <!-- ORDER ITEM -->

                        <input
                            type="hidden"
                            name="orderItemId"
                            value="${orderItemId}">


                        <!-- ================================= -->
                        <!-- RATING -->
                        <!-- ================================= -->

                        <div class="mb-4">


                            <label class="form-label d-block">

                                Đánh giá của bạn

                            </label>


                            <div class="rating">


                                <input
                                    type="radio"
                                    name="rating"
                                    id="star5"
                                    value="5"
                                    required>

                                <label
                                    for="star5"
                                    title="5 sao">

                                    ★

                                </label>


                                <input
                                    type="radio"
                                    name="rating"
                                    id="star4"
                                    value="4">

                                <label
                                    for="star4"
                                    title="4 sao">

                                    ★

                                </label>


                                <input
                                    type="radio"
                                    name="rating"
                                    id="star3"
                                    value="3">

                                <label
                                    for="star3"
                                    title="3 sao">

                                    ★

                                </label>


                                <input
                                    type="radio"
                                    name="rating"
                                    id="star2"
                                    value="2">

                                <label
                                    for="star2"
                                    title="2 sao">

                                    ★

                                </label>


                                <input
                                    type="radio"
                                    name="rating"
                                    id="star1"
                                    value="1">

                                <label
                                    for="star1"
                                    title="1 sao">

                                    ★

                                </label>


                            </div>


                        </div>


                        <!-- ================================= -->
                        <!-- COMMENT -->
                        <!-- ================================= -->

                        <div class="mb-4">


                            <label
                                for="comment"
                                class="form-label">

                                Bình luận

                            </label>


                            <textarea
                                id="comment"
                                name="comment"
                                class="form-control"
                                rows="5"
                                maxlength="2000"
                                placeholder="Chia sẻ trải nghiệm của bạn về sản phẩm..."></textarea>


                            <div class="form-text">

                                Tối đa 2000 ký tự.

                            </div>


                        </div>


                        <!-- ================================= -->
                        <!-- IMAGES -->
                        <!-- ================================= -->

                        <div class="mb-4">


                            <label
                                for="images"
                                class="form-label">

                                Ảnh đính kèm

                            </label>


                            <input
                                type="file"
                                id="images"
                                name="images"
                                class="form-control"
                                accept=".jpg,.jpeg,.png,.webp"
                                multiple>


                            <div class="form-text">

                                Tối đa 3 ảnh.
                                JPG, JPEG, PNG hoặc WEBP.
                                Mỗi ảnh tối đa 5MB.

                            </div>


                            <!-- PREVIEW -->

                            <div
                                id="preview"
                                class="d-flex flex-wrap">

                            </div>


                        </div>


                        <!-- ================================= -->
                        <!-- BUTTONS -->
                        <!-- ================================= -->

                        <div class="d-flex gap-2">


                            <button
                                type="submit"
                                class="btn btn-primary">

                                Gửi đánh giá

                            </button>


                            <a
                                href="${pageContext.request.contextPath}/orders"
                                class="btn btn-secondary">

                                Quay lại

                            </a>


                        </div>


                    </form>


                </div>


            </div>


        </div>


        <script>

            const input =
                    document.getElementById(
                            "images"
                            );

            const preview =
                    document.getElementById(
                            "preview"
                            );


            input.addEventListener(
                    "change",
                    function () {


                        preview.innerHTML =
                                "";


                        const files =
                                Array.from(
                                        input.files
                                        );


                        // Chỉ preview 3 file đầu
                        files.slice(0, 3)
                                .forEach(function (file) {


                                    if (!file.type.startsWith(
                                            "image/"
                                            )) {

                                        return;
                                    }


                                    const reader =
                                            new FileReader();


                                    reader.onload =
                                            function (event) {


                                                const img =
                                                        document.createElement(
                                                                "img"
                                                                );


                                                img.src =
                                                        event.target.result;


                                                img.className =
                                                        "preview-image";


                                                preview.appendChild(
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


        <script
            src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js">
        </script>


    </body>

</html>