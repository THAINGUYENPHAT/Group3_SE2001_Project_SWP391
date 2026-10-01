<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đánh giá sản phẩm</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: #f5f6f8; }
        .review-container { max-width: 700px; margin: 50px auto; }
        .review-card { border: none; border-radius: 12px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
        
        /* Star Rating Style */
        .rating {
            display: flex;
            flex-direction: row-reverse;
            justify-content: flex-end;
            gap: 5px;
        }
        .rating input { display: none; }
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
            border: 1px solid #ddd;
        }
    </style>
</head>
<body>

    <div class="container review-container">
        <div class="card review-card">
            <div class="card-body p-4">
                <h3 class="mb-4">Đánh giá sản phẩm</h3>

                <!-- BÁO LỖI TỪ SESSION -->
                <c:if test="${not empty sessionScope.errorMessage}">
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        ${sessionScope.errorMessage}
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                    <c:remove var="errorMessage" scope="session"/>
                </c:if>

                <form id="reviewForm" action="${pageContext.request.contextPath}/review" method="post" enctype="multipart/form-data">
                    <input type="hidden" name="orderItemId" value="${orderItemId}">

                    <!-- RATING -->
                    <div class="mb-4">
                        <label class="form-label d-block fw-semibold">Đánh giá của bạn <span class="text-danger">*</span></label>
                        <div class="rating">
                            <input type="radio" name="rating" id="star5" value="5" required>
                            <label for="star5" title="5 sao">★</label>

                            <input type="radio" name="rating" id="star4" value="4">
                            <label for="star4" title="4 sao">★</label>

                            <input type="radio" name="rating" id="star3" value="3">
                            <label for="star3" title="3 sao">★</label>

                            <input type="radio" name="rating" id="star2" value="2">
                            <label for="star2" title="2 sao">★</label>

                            <input type="radio" name="rating" id="star1" value="1">
                            <label for="star1" title="1 sao">★</label>
                        </div>
                    </div>

                    <!-- COMMENT -->
                    <div class="mb-4">
                        <label for="comment" class="form-label fw-semibold">Bình luận</label>
                        <textarea id="comment" name="comment" class="form-control" rows="4" maxlength="2000" placeholder="Chia sẻ trải nghiệm của bạn về sản phẩm..."></textarea>
                        <div class="form-text text-end">Tối đa 2000 ký tự.</div>
                    </div>

                    <!-- IMAGES UPLOAD -->
                    <div class="mb-4">
                        <label for="images" class="form-label fw-semibold">Ảnh đính kèm</label>
                        <input type="file" id="images" name="images" class="form-control" accept=".jpg,.jpeg,.png,.webp" multiple>
                        <div class="form-text">
                            Tối đa 3 ảnh (JPG, JPEG, PNG, WEBP). Mỗi ảnh không quá 5MB.
                        </div>
                        <div id="fileError" class="text-danger small mt-1 d-none"></div>

                        <!-- PREVIEW CONTAINER -->
                        <div id="preview" class="d-flex flex-wrap"></div>
                    </div>

                    <!-- BUTTONS -->
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary px-4">Gửi đánh giá</button>
                        <a href="${pageContext.request.contextPath}/orders" class="btn btn-outline-secondary">Quay lại</a>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        const input = document.getElementById("images");
        const preview = document.getElementById("preview");
        const fileError = document.getElementById("fileError");

        const MAX_FILES = 3;
        const MAX_SIZE_MB = 5;

        input.addEventListener("change", function () {
            preview.innerHTML = "";
            fileError.classList.add("d-none");
            fileError.textContent = "";

            const files = Array.from(input.files);

            // Kiểm tra số lượng file
            if (files.length > MAX_FILES) {
                showError(`Bạn chỉ được chọn tối đa \${MAX_FILES} hình ảnh.`);
                input.value = ""; // Reset input
                return;
            }

            // Kiểm tra từng file
            for (const file of files) {
                if (file.size > MAX_SIZE_MB * 1024 * 1024) {
                    showError(`File "\${file.name}" vượt quá dung lượng cho phép (\${MAX_SIZE_MB}MB).`);
                    input.value = ""; // Reset input
                    preview.innerHTML = "";
                    return;
                }

                if (!file.type.startsWith("image/")) continue;

                const reader = new FileReader();
                reader.onload = function (e) {
                    const img = document.createElement("img");
                    img.src = e.target.result;
                    img.className = "preview-image";
                    preview.appendChild(img);
                };
                reader.readAsDataURL(file);
            }
        });

        function showError(msg) {
            fileError.textContent = msg;
            fileError.classList.remove("d-none");
        }
    </script>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>