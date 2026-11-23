USE master;
GO

IF DB_ID(N'OECS') IS NOT NULL
BEGIN
    ALTER DATABASE OECS SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE OECS;
END;
GO

CREATE DATABASE OECS;
GO

USE OECS;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE ROLES (
    role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_name NVARCHAR(50) NOT NULL UNIQUE,
    description NVARCHAR(MAX)
);

CREATE TABLE [USER] (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role_id INT NOT NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    is_active BIT NOT NULL
        CONSTRAINT DF_USER_IsActive DEFAULT (1),
    failed_login_attempts INT NOT NULL
        CONSTRAINT DF_USER_FailedLogin DEFAULT (0),
    locked_until DATETIME2 NULL,
    deleted_at DATETIME2 NULL,

    CONSTRAINT FK_USER_ROLES
        FOREIGN KEY (role_id)
        REFERENCES ROLES(role_id),
    CONSTRAINT CK_USER_FailedLogin CHECK (failed_login_attempts >= 0),
    CONSTRAINT CK_USER_Email CHECK (email LIKE '%_@_%._%')
);

CREATE TABLE ADDRESSBOOK (
    address_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    recipient_name NVARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    address_line NVARCHAR(MAX) NOT NULL,
    is_default BIT NOT NULL DEFAULT (0),
    is_deleted BIT NOT NULL
        CONSTRAINT DF_ADDRESSBOOK_is_deleted DEFAULT (0),
    CONSTRAINT FK_AddressBook_User FOREIGN KEY (user_id)
        REFERENCES [USER](user_id) ON DELETE CASCADE,
    CONSTRAINT UQ_AddressBook_Id_User UNIQUE (address_id, user_id)
);

CREATE TABLE CATEGORY (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    category_name NVARCHAR(100) NOT NULL,
    parent_id INT NULL,
    description NVARCHAR(500) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_CATEGORY_IsActive DEFAULT (1),
    CONSTRAINT FK_Category_Parent FOREIGN KEY (parent_id)
        REFERENCES CATEGORY(category_id),
    CONSTRAINT CK_Category_NotSelfParent
        CHECK (parent_id IS NULL OR parent_id <> category_id)
);

CREATE TABLE BRAND (
    brand_id INT IDENTITY(1,1) PRIMARY KEY,
    brand_name NVARCHAR(100) NOT NULL,
    logo_url VARCHAR(2048),
    is_active BIT NOT NULL CONSTRAINT DF_BRAND_IsActive DEFAULT (1)
);

CREATE TABLE PRODUCT (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    category_id INT NOT NULL,
    brand_id INT NOT NULL,
    product_name NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    image_url VARCHAR(2048) NULL,
    model_code VARCHAR(100) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_PRODUCT_IsActive DEFAULT (1),
    updated_at DATETIME2 NULL,
    CONSTRAINT FK_Product_Category FOREIGN KEY (category_id)
        REFERENCES CATEGORY(category_id),
    CONSTRAINT FK_Product_Brand FOREIGN KEY (brand_id)
        REFERENCES BRAND(brand_id)
);

CREATE TABLE ATTRIBUTE (
    attribute_id INT IDENTITY(1,1) PRIMARY KEY,
    attribute_name NVARCHAR(100) NOT NULL,
    data_type VARCHAR(20) NOT NULL CONSTRAINT DF_ATTRIBUTE_DataType DEFAULT ('TEXT'),
    unit NVARCHAR(30) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_ATTRIBUTE_IsActive DEFAULT (1),
    CONSTRAINT CK_ATTRIBUTE_DataType CHECK (data_type IN ('TEXT', 'NUMBER', 'BOOLEAN'))
);

CREATE TABLE PRODUCT_SPECIFICATION (
    product_id INT NOT NULL,
    attribute_id INT NOT NULL,
    value NVARCHAR(255) NOT NULL,
    numeric_value DECIMAL(18,4) NULL,
    boolean_value BIT NULL,
    CONSTRAINT PK_PRODUCT_SPECIFICATION
        PRIMARY KEY (product_id, attribute_id),
    CONSTRAINT FK_Spec_Product FOREIGN KEY (product_id)
        REFERENCES PRODUCT(product_id) ON DELETE CASCADE,
    CONSTRAINT FK_Spec_Attribute FOREIGN KEY (attribute_id)
        REFERENCES ATTRIBUTE(attribute_id) ON DELETE CASCADE
);

CREATE TABLE PRODUCT_SKU (
    sku_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    sku_code VARCHAR(100) NOT NULL UNIQUE,
    price DECIMAL(18,2) NOT NULL,
    stock_quantity INT DEFAULT (0),
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    original_price DECIMAL(18,2) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_SKU_IsActive DEFAULT (1),
    variant_key VARBINARY(32) NULL,
    CONSTRAINT CK_SKU_Price CHECK (price >= 0),
    CONSTRAINT CK_SKU_OriginalPrice CHECK (original_price IS NULL OR original_price >= 0),
    CONSTRAINT CK_SKU_Stock CHECK (stock_quantity IS NULL OR stock_quantity >= 0),
    CONSTRAINT CK_OECS_Inventory_StockValid CHECK (stock_quantity IS NOT NULL AND stock_quantity >= 0),
    CONSTRAINT UQ_SKU_IdProduct UNIQUE (sku_id, product_id),
    CONSTRAINT FK_SKU_Product FOREIGN KEY (product_id)
        REFERENCES PRODUCT(product_id) ON DELETE CASCADE
);

CREATE TABLE PRODUCT_IMAGES (
    image_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    image_url VARCHAR(2048) NOT NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    sku_id INT NULL,
    is_primary BIT NOT NULL CONSTRAINT DF_PI_Primary DEFAULT (0),
    display_order INT NOT NULL CONSTRAINT DF_PI_Order DEFAULT (0),
    alt_text NVARCHAR(255) NULL,
    CONSTRAINT CK_PI_DisplayOrder CHECK (display_order >= 0),
    CONSTRAINT FK_PI_SKU_Product FOREIGN KEY (sku_id, product_id) REFERENCES dbo.PRODUCT_SKU(sku_id, product_id),
    CONSTRAINT FK_ProductImages_Product FOREIGN KEY (product_id) 
        REFERENCES PRODUCT(product_id) ON DELETE CASCADE
);

CREATE TABLE CART (
    cart_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Cart_User FOREIGN KEY (user_id)
        REFERENCES [USER](user_id) ON DELETE CASCADE
);

CREATE TABLE CART_ITEMS (
    cart_item_id INT IDENTITY(1,1) PRIMARY KEY,
    cart_id INT NOT NULL,
    sku_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT (1),

    CONSTRAINT FK_CartItems_Cart
        FOREIGN KEY (cart_id)
        REFERENCES CART(cart_id) ON DELETE CASCADE,

    CONSTRAINT FK_CartItems_SKU
        FOREIGN KEY (sku_id)
        REFERENCES PRODUCT_SKU(sku_id) ON DELETE CASCADE,

    CONSTRAINT UQ_CartItems_Cart_SKU
        UNIQUE (cart_id, sku_id),

    CONSTRAINT CK_CartItems_Quantity
        CHECK (quantity > 0)
);

CREATE TABLE VOUCHER (
    voucher_id INT IDENTITY(1,1) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    min_order_value DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_Voucher_MinOrder DEFAULT (0),
    valid_from DATETIME2 NOT NULL,
    valid_to DATETIME2 NOT NULL,
    discount_type VARCHAR(20) NOT NULL,
    discount_value DECIMAL(18,2) NOT NULL,
    max_discount DECIMAL(18,2) NULL,
    usage_limit INT NULL,
    per_user_limit INT NULL,

    CONSTRAINT CK_Voucher_DiscountType
        CHECK (discount_type IN ('AMOUNT', 'PERCENT')),
    CONSTRAINT CK_Voucher_DiscountValue
        CHECK (discount_value > 0),
    CONSTRAINT CK_Voucher_MinOrder
        CHECK (min_order_value >= 0),
    CONSTRAINT CK_Voucher_ValidDate
        CHECK (valid_to > valid_from),
    CONSTRAINT CK_Voucher_MaxDiscount
        CHECK (max_discount IS NULL OR max_discount > 0),
    CONSTRAINT CK_Voucher_UsageLimit
        CHECK (usage_limit IS NULL OR usage_limit > 0),
    CONSTRAINT CK_Voucher_PerUserLimit
        CHECK (per_user_limit IS NULL OR per_user_limit > 0),
    CONSTRAINT CK_Voucher_PerUserVsTotal
        CHECK (
            usage_limit IS NULL
            OR per_user_limit IS NULL
            OR per_user_limit <= usage_limit
        ),
    CONSTRAINT CK_Voucher_MaxDiscountType
        CHECK (discount_type = 'PERCENT' OR max_discount IS NULL)
);

CREATE TABLE [ORDER] (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    address_id INT NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL,
    shipping_fee DECIMAL(18,2) NOT NULL DEFAULT (0),
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    order_status VARCHAR(30) NOT NULL DEFAULT 'PENDING_CONFIRMATION',
    payment_method VARCHAR(20) NOT NULL,
    payment_status VARCHAR(30) NOT NULL DEFAULT 'UNPAID',
    payment_expires_at DATETIME2 NULL,
    recipient_name NVARCHAR(100) NULL,
    recipient_phone VARCHAR(20) NULL,
    shipping_address NVARCHAR(MAX) NULL,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT (0),
    stock_restored_at DATETIME2 NULL,
    checkout_token VARCHAR(64) NULL,
    delivered_at DATETIME2 NULL,

    cancellation_source VARCHAR(20) NULL,
    cancelled_at DATETIME2 NULL,

    cancel_request_status VARCHAR(20) NULL,
    cancel_request_reason NVARCHAR(500) NULL,
    cancel_requested_at DATETIME2 NULL,
    cancel_reviewed_by INT NULL,
    cancel_reviewed_at DATETIME2 NULL,
    cancel_review_note NVARCHAR(500) NULL,

    CONSTRAINT FK_Order_User FOREIGN KEY (user_id)
        REFERENCES [USER](user_id),

    CONSTRAINT FK_Order_Address FOREIGN KEY (address_id)
        REFERENCES ADDRESSBOOK(address_id),
    CONSTRAINT FK_Order_AddressOwner FOREIGN KEY (address_id, user_id)
        REFERENCES ADDRESSBOOK(address_id, user_id),
    CONSTRAINT UQ_Order_Id_User UNIQUE (order_id, user_id),

    CONSTRAINT FK_Order_CancelReviewer FOREIGN KEY (cancel_reviewed_by)
        REFERENCES [USER](user_id),
    CONSTRAINT CK_Order_CancelRequest CHECK (
        (cancel_request_status IS NULL
         AND cancel_request_reason IS NULL AND cancel_requested_at IS NULL
         AND cancel_reviewed_by IS NULL AND cancel_reviewed_at IS NULL
         AND cancel_review_note IS NULL)
        OR (
            cancel_request_status IN ('PENDING','APPROVED','REJECTED')
            AND (cancel_request_status <> 'PENDING' OR order_status IN ('CONFIRMED','PACKING'))
            AND NULLIF(LTRIM(RTRIM(cancel_request_reason)), N'') IS NOT NULL
            AND cancel_requested_at IS NOT NULL
            AND (
                (cancel_request_status = 'PENDING'
                 AND cancel_reviewed_by IS NULL AND cancel_reviewed_at IS NULL
                 AND cancel_review_note IS NULL)
                OR (cancel_request_status IN ('APPROVED','REJECTED')
                    AND cancel_reviewed_by IS NOT NULL AND cancel_reviewed_at IS NOT NULL)
            )
            AND (cancel_request_status <> 'REJECTED'
                 OR NULLIF(LTRIM(RTRIM(cancel_review_note)), N'') IS NOT NULL)
        )
    ),

    CONSTRAINT CK_Order_CancellationSource
        CHECK (
            cancellation_source IS NULL
            OR cancellation_source IN ('CUSTOMER', 'STAFF', 'SYSTEM')
        ),

    CONSTRAINT CK_Order_Amounts
        CHECK (total_amount >= 0 AND shipping_fee >= 0 AND discount_amount >= 0),
    CONSTRAINT CK_Order_Status CHECK (order_status IN
        ('PENDING_CONFIRMATION','PENDING_PAYMENT','CONFIRMED','PACKING','SHIPPING',
         'COMPLETED','CANCELLED','EXPIRED','RETURNED')),
    CONSTRAINT CK_Order_PaymentMethod CHECK (payment_method IN
        ('COD','VNPAY','MOMO')),
    CONSTRAINT CK_Order_PaymentStatus CHECK (payment_status IN
        ('UNPAID','PENDING','PAID','FAILED','CANCELLED','EXPIRED','REFUNDED'))

);

CREATE INDEX IX_Order_CustomerCancellationPolicy
ON dbo.[ORDER] (
    user_id,
    cancellation_source,
    cancelled_at
)
INCLUDE (order_id);

CREATE TABLE ORDER_ITEM (
    order_item_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    sku_id INT NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    quantity INT NOT NULL,
    product_name_snapshot NVARCHAR(255) NULL,
    sku_code_snapshot VARCHAR(100) NULL,
    CONSTRAINT FK_OrderItem_Order FOREIGN KEY (order_id)
        REFERENCES [ORDER](order_id),
    CONSTRAINT FK_OrderItem_SKU FOREIGN KEY (sku_id)
        REFERENCES PRODUCT_SKU(sku_id),
    CONSTRAINT UQ_OrderItem_Id_SKU UNIQUE (order_item_id, sku_id),
    CONSTRAINT CK_OrderItem_Quantity CHECK (quantity > 0),
    CONSTRAINT CK_OrderItem_Price CHECK (price >= 0)
);

CREATE TABLE ORDER_STATUS_HISTORY (
    status_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    status NVARCHAR(50) NOT NULL,
    updated_at DATETIME2 DEFAULT SYSDATETIME(),
    old_status NVARCHAR(50) NULL,
    actor_type VARCHAR(20) NULL,
    changed_by INT NULL,
    reason NVARCHAR(500) NULL,
    CONSTRAINT FK_StatusHistory_Order FOREIGN KEY (order_id)
        REFERENCES [ORDER](order_id),
    CONSTRAINT FK_StatusHistory_User FOREIGN KEY (changed_by)
        REFERENCES [USER](user_id),
    CONSTRAINT CK_StatusHistory_Actor
        CHECK (actor_type IS NULL OR actor_type IN ('CUSTOMER', 'STAFF', 'SYSTEM')),
    CONSTRAINT CK_StatusHistory_Status CHECK (status IN
        ('PENDING_CONFIRMATION','PENDING_PAYMENT','CONFIRMED','PACKING','SHIPPING',
         'COMPLETED','CANCELLED','EXPIRED','RETURNED')),
    CONSTRAINT CK_StatusHistory_OldStatus CHECK (old_status IS NULL OR old_status IN
        ('PENDING_CONFIRMATION','PENDING_PAYMENT','CONFIRMED','PACKING','SHIPPING',
         'COMPLETED','CANCELLED','EXPIRED','RETURNED')),
    CONSTRAINT CK_OECS_CancelHistory_RequiredFields
    CHECK (
        status <> N'CANCELLED'
        OR (
            actor_type IN ('CUSTOMER', 'STAFF', 'SYSTEM')
            AND reason IS NOT NULL
            AND LEN(LTRIM(RTRIM(reason))) > 0
            AND updated_at IS NOT NULL
            AND (
                (actor_type IN ('CUSTOMER', 'STAFF') AND changed_by IS NOT NULL)
                OR actor_type = 'SYSTEM'
            )
        )
    )

);

CREATE TABLE VOUCHER_USAGES (
    usage_id INT IDENTITY(1,1) PRIMARY KEY,
    voucher_id INT NOT NULL,
    order_id INT NOT NULL,
    user_id INT NOT NULL,
    used_at DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_VoucherUsage_Voucher FOREIGN KEY (voucher_id)
        REFERENCES VOUCHER(voucher_id),
    CONSTRAINT FK_VoucherUsage_Order FOREIGN KEY (order_id)
        REFERENCES [ORDER](order_id),
    CONSTRAINT FK_VoucherUsage_User FOREIGN KEY (user_id)
        REFERENCES [USER](user_id),
    CONSTRAINT FK_VoucherUsage_OrderOwner FOREIGN KEY (order_id, user_id)
        REFERENCES [ORDER](order_id, user_id)
);

CREATE TABLE NOTIFICATION (
    notification_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    order_id INT NULL,
    title NVARCHAR(200) NOT NULL,
    message NVARCHAR(500) NOT NULL,
    is_read BIT NOT NULL CONSTRAINT DF_Notification_IsRead DEFAULT (0),
    created_at DATETIME2 NOT NULL
        CONSTRAINT DF_Notification_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT FK_Notification_User FOREIGN KEY (user_id)
        REFERENCES [USER](user_id) ON DELETE CASCADE,
    CONSTRAINT FK_Notification_Order FOREIGN KEY (order_id)
        REFERENCES [ORDER](order_id) ON DELETE SET NULL
);

CREATE INDEX IX_Notification_User_Unread
    ON NOTIFICATION(user_id, is_read)
    WHERE is_read = 0;

CREATE TABLE PRODUCT_REVIEWS (
    review_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    order_item_id INT NOT NULL,
    sku_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment NVARCHAR(MAX),
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    is_hidden BIT NOT NULL
        CONSTRAINT DF_PRODUCT_REVIEWS_is_hidden DEFAULT (0),

    CONSTRAINT FK_Review_User FOREIGN KEY (user_id)
        REFERENCES [USER](user_id),
    CONSTRAINT FK_Review_OrderItem FOREIGN KEY (order_item_id, sku_id)
        REFERENCES ORDER_ITEM(order_item_id, sku_id),
    CONSTRAINT FK_Review_SKU FOREIGN KEY (sku_id)
        REFERENCES PRODUCT_SKU(sku_id)
);

CREATE TABLE REVIEW_IMAGES (
    image_id INT IDENTITY(1,1) PRIMARY KEY,
    review_id INT NOT NULL,
    image_url NVARCHAR(2048) NOT NULL,
    CONSTRAINT FK_ReviewImages_Review FOREIGN KEY (review_id)
        REFERENCES PRODUCT_REVIEWS(review_id) ON DELETE CASCADE
);

CREATE TABLE REVIEW_REPORTS (
    report_id INT IDENTITY(1,1) PRIMARY KEY,
    review_id INT NOT NULL,
    reported_by INT NOT NULL,
    reason NVARCHAR(500) NOT NULL,
    report_status VARCHAR(20) NOT NULL
        CONSTRAINT DF_REVIEW_REPORTS_status DEFAULT ('PENDING'),
    created_at DATETIME2 NOT NULL
        CONSTRAINT DF_REVIEW_REPORTS_created_at DEFAULT (SYSDATETIME()),
    resolved_by INT NULL,
    resolved_at DATETIME2 NULL,

    CONSTRAINT CK_REVIEW_REPORTS_status
        CHECK (report_status IN ('PENDING', 'RESOLVED', 'REJECTED')),
    CONSTRAINT FK_REVIEW_REPORTS_review FOREIGN KEY (review_id)
        REFERENCES PRODUCT_REVIEWS(review_id),
    CONSTRAINT FK_REVIEW_REPORTS_reporter FOREIGN KEY (reported_by)
        REFERENCES [USER](user_id),
    CONSTRAINT FK_REVIEW_REPORTS_resolver FOREIGN KEY (resolved_by)
        REFERENCES [USER](user_id)
);

CREATE INDEX IX_REVIEW_REPORTS_status_created
    ON REVIEW_REPORTS(report_status, created_at DESC);

CREATE UNIQUE INDEX UX_REVIEW_REPORTS_one_pending_per_user
    ON REVIEW_REPORTS(review_id, reported_by)
    WHERE report_status = 'PENDING';

CREATE TABLE PAYMENT_TRANSACTION (
    transaction_id BIGINT IDENTITY(1,1)
        CONSTRAINT PK_PAYMENT_TRANSACTION PRIMARY KEY,
    order_id INT NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    transaction_code VARCHAR(100) NOT NULL,
    provider_transaction_id VARCHAR(150) NULL,
    status VARCHAR(30) NOT NULL
        CONSTRAINT DF_PaymentTransaction_Status DEFAULT ('PENDING'),
    provider_response_code VARCHAR(100) NULL,
    created_at DATETIME2 NOT NULL
        CONSTRAINT DF_PaymentTransaction_Created DEFAULT (SYSDATETIME()),
    completed_at DATETIME2 NULL,
    pay_url NVARCHAR(2048) NULL,

    CONSTRAINT FK_PaymentTransaction_Order FOREIGN KEY (order_id)
        REFERENCES [ORDER](order_id),
    CONSTRAINT UQ_PaymentTransaction_Code UNIQUE (transaction_code),
    CONSTRAINT CK_PaymentTransaction_Method
        CHECK (payment_method IN ('VNPAY', 'MOMO')),
    CONSTRAINT CK_PaymentTransaction_Amount CHECK (amount >= 0),
    CONSTRAINT CK_PaymentTransaction_Status
        CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED', 'EXPIRED'))
);

CREATE TABLE ORDER_CUSTOMER_POLICY (
    user_id INT NOT NULL PRIMARY KEY REFERENCES [USER](user_id),
    violation_count INT NOT NULL DEFAULT (0),
    blocked_until DATETIME2 NULL,
    CONSTRAINT CK_OrderCustomerPolicy_Count CHECK (violation_count BETWEEN 0 AND 3)
);


CREATE TABLE PAYMENT_REFUND (
    refund_id BIGINT IDENTITY(1,1)
        CONSTRAINT PK_PAYMENT_REFUND PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    refund_amount DECIMAL(18,2) NOT NULL,
    refund_type VARCHAR(20) NOT NULL CONSTRAINT DF_PaymentRefund_Type DEFAULT ('RETURN'),
    refund_status VARCHAR(30) NOT NULL
        CONSTRAINT DF_PaymentRefund_Status DEFAULT ('PENDING'),
    provider_refund_id VARCHAR(150) NULL,
    processed_by INT NULL REFERENCES [USER](user_id),
    approved_by INT NULL REFERENCES [USER](user_id),
    approved_at DATETIME2 NULL,
    approval_note NVARCHAR(1000) NULL,
    updated_at DATETIME2 NULL,
    reason NVARCHAR(500) NOT NULL,
    requested_at DATETIME2 NOT NULL
        CONSTRAINT DF_PaymentRefund_Requested DEFAULT (SYSDATETIME()),
    completed_at DATETIME2 NULL,

    CONSTRAINT FK_PaymentRefund_Transaction FOREIGN KEY (transaction_id)
        REFERENCES PAYMENT_TRANSACTION(transaction_id),
    CONSTRAINT CK_PaymentRefund_Amount CHECK (refund_amount > 0),
    CONSTRAINT CK_PaymentRefund_Type CHECK (refund_type IN ('RETURN','CANCELLATION')) ,
    CONSTRAINT CK_PaymentRefund_Reason CHECK (LEN(LTRIM(RTRIM(reason))) > 0),
    CONSTRAINT CK_PaymentRefund_ApprovalPair CHECK
        ((approved_by IS NULL AND approved_at IS NULL) OR
         (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
    CONSTRAINT CK_PaymentRefund_Status
        CHECK (refund_status IN ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED'))
);

CREATE UNIQUE INDEX UX_Payment_Provider_Success
    ON PAYMENT_TRANSACTION(payment_method, provider_transaction_id)
    WHERE status = 'SUCCESS' AND provider_transaction_id IS NOT NULL;
CREATE INDEX IX_Payment_Refund_Transaction
    ON PAYMENT_REFUND(transaction_id, refund_status);

CREATE INDEX IX_PaymentTransaction_Order
    ON PAYMENT_TRANSACTION(order_id, created_at DESC);

CREATE INDEX IX_Order_Expiry
    ON [ORDER](order_status, payment_expires_at);

CREATE UNIQUE INDEX UX_Order_CheckoutToken
    ON [ORDER](checkout_token)
    WHERE checkout_token IS NOT NULL;

CREATE UNIQUE INDEX UX_AddressBook_OneDefault
    ON ADDRESSBOOK(user_id)
    WHERE is_default = 1 AND is_deleted = 0;

CREATE UNIQUE INDEX UX_PRODUCT_REVIEWS_order_item
    ON PRODUCT_REVIEWS(order_item_id);

CREATE UNIQUE INDEX UX_VoucherUsages_Voucher_Order
    ON VOUCHER_USAGES(voucher_id, order_id);

CREATE INDEX IX_VoucherUsages_Voucher_User
    ON VOUCHER_USAGES(voucher_id, user_id);

CREATE INDEX IX_Order_User_CreatedAt
    ON [ORDER](user_id, created_at DESC);

CREATE INDEX IX_OrderItem_Order
    ON ORDER_ITEM(order_id);

CREATE INDEX IX_OrderItem_SKU
    ON ORDER_ITEM(sku_id);

CREATE INDEX IX_OrderStatusHistory_Order
    ON ORDER_STATUS_HISTORY(order_id, updated_at);


CREATE TABLE PASSWORD_RESET_TOKEN (
    reset_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at DATETIME2 NOT NULL,
    used_at DATETIME2 NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_PasswordReset_User FOREIGN KEY (user_id)
        REFERENCES [USER](user_id) ON DELETE CASCADE
);

CREATE TABLE AUDIT_LOG (
    log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    actor_user_id INT NULL,
    actor_identifier VARCHAR(150) NULL,
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT NULL,
    description NVARCHAR(500) NULL,
    ip_address VARCHAR(45) NULL,
    created_at DATETIME2 NOT NULL
        CONSTRAINT DF_AuditLog_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT FK_AuditLog_Actor FOREIGN KEY (actor_user_id)
        REFERENCES [USER](user_id) ON DELETE SET NULL
);

CREATE TABLE BANNER (
    banner_id INT IDENTITY(1,1) PRIMARY KEY,
    image_url NVARCHAR(2048) NOT NULL,
    alt_text NVARCHAR(255) NULL,
    target_url NVARCHAR(2048) NULL,
    is_active BIT NOT NULL DEFAULT (1),
    display_order INT NOT NULL DEFAULT (0),
    created_at DATETIME2 NOT NULL DEFAULT (SYSDATETIME())
);

CREATE TABLE RETURN_REQUEST (
    request_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    user_id INT NOT NULL,
    request_type VARCHAR(20) NOT NULL,
    reason NVARCHAR(1000) NOT NULL,
    request_status VARCHAR(20) NOT NULL DEFAULT ('PENDING'),
    created_at DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    reviewed_by INT NULL,
    reviewed_at DATETIME2 NULL,
    staff_note NVARCHAR(1000) NULL,

    CONSTRAINT FK_RETURN_REQUEST_ORDER_OWNER
    FOREIGN KEY (order_id, user_id)
    REFERENCES dbo.[ORDER](order_id, user_id),
    CONSTRAINT FK_RETURN_REQUEST_REVIEWER FOREIGN KEY (reviewed_by)
        REFERENCES [USER](user_id),
    CONSTRAINT CK_RETURN_REQUEST_TYPE
        CHECK (request_type IN ('RETURN', 'EXCHANGE')),
    CONSTRAINT CK_RETURN_REQUEST_STATUS
        CHECK (request_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    CONSTRAINT CK_RETURN_REQUEST_REASON CHECK (LEN(LTRIM(RTRIM(reason))) > 0),
    CONSTRAINT CK_RETURN_REQUEST_REVIEW_PAIR CHECK
       ((request_status = 'PENDING' AND reviewed_by IS NULL AND reviewed_at IS NULL)
        OR (request_status IN ('APPROVED', 'REJECTED') AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)),
    CONSTRAINT CK_RETURN_REQUEST_REJECT_REASON CHECK
       (request_status <> 'REJECTED' OR LEN(LTRIM(RTRIM(ISNULL(staff_note, N'')))) > 0)
);

CREATE TABLE RETURN_REQUEST_ITEM (
    request_item_id INT IDENTITY(1,1) PRIMARY KEY,
    request_id INT NOT NULL,
    order_item_id INT NOT NULL,
    quantity INT NOT NULL,
    exchange_sku_id INT NULL,

    CONSTRAINT FK_RETURN_REQUEST_ITEM_REQUEST FOREIGN KEY (request_id)
        REFERENCES RETURN_REQUEST(request_id),
    CONSTRAINT FK_RETURN_REQUEST_ITEM_ORDER_ITEM FOREIGN KEY (order_item_id)
        REFERENCES ORDER_ITEM(order_item_id),
    CONSTRAINT FK_RETURN_REQUEST_ITEM_EXCHANGE_SKU FOREIGN KEY (exchange_sku_id)
        REFERENCES PRODUCT_SKU(sku_id),
    CONSTRAINT CK_RETURN_REQUEST_ITEM_QUANTITY CHECK (quantity > 0),
    CONSTRAINT UQ_RETURN_REQUEST_ITEM UNIQUE(request_id, order_item_id),
    CONSTRAINT UQ_RETURN_REQUEST_ITEM_ID_REQUEST UNIQUE(request_item_id, request_id)
);


CREATE TABLE RETURN_REQUEST_HISTORY (
    history_id INT IDENTITY(1,1) PRIMARY KEY,
    request_id INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    updated_by INT NULL,
    note NVARCHAR(1000) NULL,
    updated_at DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),

    CONSTRAINT FK_RETURN_REQUEST_HISTORY_REQUEST FOREIGN KEY (request_id)
        REFERENCES RETURN_REQUEST(request_id),
    CONSTRAINT FK_RETURN_REQUEST_HISTORY_USER FOREIGN KEY (updated_by)
        REFERENCES [USER](user_id)
);

CREATE TABLE dbo.CATEGORY_ATTRIBUTE (
        category_id INT NOT NULL,
        attribute_id INT NOT NULL,

        group_name NVARCHAR(100) NOT NULL
            CONSTRAINT DF_CA_Group
            DEFAULT (N'Thông số khác'),

        attribute_type VARCHAR(20) NOT NULL
            CONSTRAINT DF_CA_Type
            DEFAULT ('SPECIFICATION'),

        is_required BIT NOT NULL
            CONSTRAINT DF_CA_Required DEFAULT (0),

        is_filterable BIT NOT NULL
            CONSTRAINT DF_CA_Filterable DEFAULT (0),

        display_order INT NOT NULL
            CONSTRAINT DF_CA_Order DEFAULT (0),

        CONSTRAINT PK_CATEGORY_ATTRIBUTE
            PRIMARY KEY (category_id, attribute_id),

        CONSTRAINT FK_CA_Category
            FOREIGN KEY (category_id)
            REFERENCES dbo.CATEGORY(category_id),

        CONSTRAINT FK_CA_Attribute
            FOREIGN KEY (attribute_id)
            REFERENCES dbo.ATTRIBUTE(attribute_id),

        CONSTRAINT CK_CA_Type
            CHECK (
                attribute_type IN (
                    'SPECIFICATION',
                    'VARIANT',
                    'BOTH'
                )
            ),

        CONSTRAINT CK_CA_Order
            CHECK (display_order >= 0)
    );


CREATE TABLE dbo.SKU_ATTRIBUTE_VALUE (
        sku_id INT NOT NULL,
        attribute_id INT NOT NULL,

        text_value NVARCHAR(255) NULL,
        numeric_value DECIMAL(18,4) NULL,
        boolean_value BIT NULL,

        CONSTRAINT PK_SKU_ATTRIBUTE_VALUE
            PRIMARY KEY (sku_id, attribute_id),

        CONSTRAINT FK_SAV_SKU
            FOREIGN KEY (sku_id)
            REFERENCES dbo.PRODUCT_SKU(sku_id)
            ON DELETE CASCADE,

        CONSTRAINT FK_SAV_Attribute
            FOREIGN KEY (attribute_id)
            REFERENCES dbo.ATTRIBUTE(attribute_id),

        CONSTRAINT CK_SAV_OneValue
            CHECK (
                (CASE WHEN text_value IS NOT NULL
                    THEN 1 ELSE 0 END)
              + (CASE WHEN numeric_value IS NOT NULL
                    THEN 1 ELSE 0 END)
              + (CASE WHEN boolean_value IS NOT NULL
                    THEN 1 ELSE 0 END)
                = 1
            ),

        CONSTRAINT CK_SAV_NonEmpty
            CHECK (
                text_value IS NULL
                OR LEN(LTRIM(RTRIM(text_value))) > 0
            )
    );


CREATE TABLE dbo.INVENTORY_MOVEMENT (
        movement_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_INVENTORY_MOVEMENT PRIMARY KEY,
        sku_id INT NOT NULL,
        movement_type VARCHAR(12) NOT NULL,
        quantity_delta INT NOT NULL,
        quantity_before INT NOT NULL,
        quantity_after INT NOT NULL,
        note NVARCHAR(500) NULL,
        actor_user_id INT NULL,
        created_at DATETIME2(3) NOT NULL
            CONSTRAINT DF_INVENTORY_MOVEMENT_created_at DEFAULT SYSDATETIME(),
        CONSTRAINT FK_INVENTORY_MOVEMENT_SKU FOREIGN KEY (sku_id)
            REFERENCES dbo.PRODUCT_SKU(sku_id),
        CONSTRAINT FK_INVENTORY_MOVEMENT_USER FOREIGN KEY (actor_user_id)
            REFERENCES dbo.[USER](user_id),
        CONSTRAINT CK_INVENTORY_MOVEMENT_type CHECK
            (movement_type IN ('OPENING', 'IN', 'OUT', 'SET', 'SYSTEM')),
        CONSTRAINT CK_INVENTORY_MOVEMENT_balances CHECK
            (quantity_before >= 0 AND quantity_after >= 0
             AND quantity_delta = quantity_after - quantity_before)
    );


CREATE TABLE dbo.PRODUCT_CONTENT_SECTION (
    section_id INT IDENTITY(1,1) NOT NULL
      CONSTRAINT PK_PRODUCT_CONTENT_SECTION PRIMARY KEY,
    product_id INT NOT NULL,
    section_key VARCHAR(40) NOT NULL,
    section_title NVARCHAR(160) NOT NULL,
    section_content NVARCHAR(1500) NOT NULL,
    image_url NVARCHAR(500) NULL,
    image_alt NVARCHAR(200) NULL,
    display_order INT NOT NULL
      CONSTRAINT DF_PRODUCT_CONTENT_ORDER DEFAULT (0),
    is_active BIT NOT NULL
      CONSTRAINT DF_PRODUCT_CONTENT_ACTIVE DEFAULT (1),
    created_at DATETIME2(3) NOT NULL
      CONSTRAINT DF_PRODUCT_CONTENT_CREATED DEFAULT SYSDATETIME(),
    updated_at DATETIME2(3) NULL,
    CONSTRAINT FK_PRODUCT_CONTENT_PRODUCT
      FOREIGN KEY (product_id) REFERENCES dbo.PRODUCT(product_id),
    CONSTRAINT UQ_PRODUCT_CONTENT_KEY UNIQUE(product_id,section_key),
    CONSTRAINT CK_PRODUCT_CONTENT_ORDER CHECK (display_order>=0),
    CONSTRAINT CK_PRODUCT_CONTENT_TITLE CHECK(LEN(LTRIM(RTRIM(section_title)))>0),
    CONSTRAINT CK_PRODUCT_CONTENT_BODY CHECK(LEN(LTRIM(RTRIM(section_content)))>0)
  );

CREATE UNIQUE INDEX UX_PI_PrimaryProduct
    ON dbo.PRODUCT_IMAGES(product_id) WHERE sku_id IS NULL AND is_primary = 1;
CREATE UNIQUE INDEX UX_PI_PrimarySKU
    ON dbo.PRODUCT_IMAGES(sku_id) WHERE sku_id IS NOT NULL AND is_primary = 1;
CREATE UNIQUE INDEX UX_SKU_ProductVariant
    ON dbo.PRODUCT_SKU(product_id,variant_key) WHERE variant_key IS NOT NULL;
CREATE INDEX IX_INVENTORY_MOVEMENT_sku_time
    ON dbo.INVENTORY_MOVEMENT(sku_id, movement_id DESC);

GO
---------------------------------------Create Table & Db------------------------------------------





USE [OECS];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET CONTEXT_INFO 0x00;


IF
    EXISTS (SELECT TOP (1) 1 FROM dbo.ROLES)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.[USER])
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.ADDRESSBOOK)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.CATEGORY)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.BRAND)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.PRODUCT)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.ATTRIBUTE)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.PRODUCT_SPECIFICATION)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.PRODUCT_SKU)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.PRODUCT_IMAGES)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.CART)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.CART_ITEMS)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.VOUCHER)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.[ORDER])
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.ORDER_ITEM)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.ORDER_STATUS_HISTORY)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.VOUCHER_USAGES)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.NOTIFICATION)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.PRODUCT_REVIEWS)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.REVIEW_IMAGES)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.REVIEW_REPORTS)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.PAYMENT_TRANSACTION)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.ORDER_CUSTOMER_POLICY)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.PAYMENT_REFUND)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.PASSWORD_RESET_TOKEN)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.AUDIT_LOG)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.BANNER)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.RETURN_REQUEST)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.RETURN_REQUEST_ITEM)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.RETURN_REQUEST_HISTORY)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.CATEGORY_ATTRIBUTE)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.SKU_ATTRIBUTE_VALUE)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.INVENTORY_MOVEMENT)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.PRODUCT_CONTENT_SECTION)
BEGIN
    THROW 60013, N'OECS da co du lieu trong it nhat 1 bang. Dung lai, KHONG nap lai seed!', 1;
END;

SET CONTEXT_INFO 0x4F45435353454544;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

INSERT INTO ROLES (role_name, description)
VALUES
(N'ADMIN', N'Quản trị viên hệ thống - Toàn quyền'),
(N'STAFF', N'Nhân viên vận hành và xử lý đơn hàng'),
(N'CUSTOMER', N'Khách hàng mua sắm');

INSERT INTO [USER] (
    username,
    email,
    password_hash,
    phone,
    role_id
)
SELECT
    u.username,
    u.email,
    u.password_hash,
    u.phone,
    r.role_id
FROM (
    VALUES
    ('admin', 'admin@oecs.com',
     'e10adc3949ba59abbe56e057f20f883e', '0901111111', N'ADMIN'),

    ('staff', 'khang.staff@oecs.com',
     'e10adc3949ba59abbe56e057f20f883e', '0902222222', N'STAFF'),

    ('user', 'phat.user@gmail.com',
     'e10adc3949ba59abbe56e057f20f883e', '0903333333', N'CUSTOMER'),

    ('customer', 'lan.nguyen@gmail.com',
     'e10adc3949ba59abbe56e057f20f883e', '0904444444', N'CUSTOMER')
) AS u(username, email, password_hash, phone, role_name)
INNER JOIN ROLES r ON r.role_name = u.role_name;

INSERT INTO ADDRESSBOOK
    (user_id, recipient_name, phone_number, address_line, is_default)
VALUES
(3, N'Trần Phát', '0903333333',
 N'123 Đường 3/2, Phường Xuân Khánh, Quận Ninh Kiều, Cần Thơ', 1),
(3, N'Trần Phát (Văn phòng)', '0903333333',
 N'456 Nguyễn Văn Cừ, Phường An Khánh, Ninh Kiều, Cần Thơ', 0),
(4, N'Nguyễn Thị Lan', '0904444444',
 N'789 Lê Duẩn, Quận 1, TP. Hồ Chí Minh', 1);

INSERT INTO CATEGORY (category_name, parent_id)
VALUES
(N'Điện thoại & Thiết bị di động', NULL),
(N'Máy tính & Laptop', NULL),
(N'Phụ kiện', NULL),
(N'Smartphone', 1),
(N'Tai nghe', 1),
(N'Sạc điện thoại', 1),
(N'Cáp sạc', 1),
(N'Laptop Văn Phòng', 2),
(N'Laptop Gaming', 2),
(N'Chuột', 3),
(N'Bàn phím', 3),
(N'Webcam', 3),
(N'Balo Laptop', 3);

INSERT INTO BRAND (brand_name, logo_url)
VALUES
(N'Apple', 'https://cdn.oecs.com/brands/apple.png'),
(N'Samsung', 'https://cdn.oecs.com/brands/samsung.png'),
(N'Lenovo', 'https://cdn.oecs.com/brands/lenovo.png'),
(N'Logitech', 'https://cdn.oecs.com/brands/logitech.png'),
(N'Sony', 'https://cdn.oecs.com/brands/sony.png'),
(N'JBL', 'https://cdn.oecs.com/brands/jbl.png'),
(N'ASUS', 'https://cdn.oecs.com/brands/asus.png'),
(N'HP', 'https://cdn.oecs.com/brands/hp.png'),
(N'Dell', 'https://cdn.oecs.com/brands/dell.png'),
(N'Razer', 'https://cdn.oecs.com/brands/razer.png'),
(N'Anker', 'https://cdn.oecs.com/brands/anker.png');

INSERT INTO PRODUCT (category_id, brand_id, product_name, description, image_url)
VALUES
(4, 1, N'iPhone 15 Pro', N'<h2>Khung viền Titanium siêu nhẹ, siêu bền bỉ</h2><p><strong>iPhone 15 Pro</strong> là bước nhảy vọt về thiết kế với chất liệu Titanium chuẩn hàng không vũ trụ. Sự thay đổi này không chỉ mang lại cảm giác cầm nắm cực kỳ nhẹ nhàng mà còn vô cùng bền bỉ.</p><ul><li><strong>Vi xử lý A17 Pro:</strong> Con chip 3nm đầu tiên, chiến mượt mọi tựa game AAA di động.</li><li><strong>Camera 48MP:</strong> Nâng cấp cảm biến thế hệ mới, hỗ trợ chụp đêm xuất sắc và quay video ProRes 4K60fps.</li><li><strong>Cổng sạc Type-C mới:</strong> Tốc độ truyền tải dữ liệu USB 3 lên tới 10Gbps, đồng bộ dễ dàng với mọi thiết bị.</li></ul>', 'assets/images/products/iphone_15_pro.png'),
(4, 1, N'iPhone 15 Pro Max', N'<h2>Kỷ nguyên nhiếp ảnh di động đỉnh cao</h2><p><strong>iPhone 15 Pro Max</strong> sở hữu màn hình cực đại 6.7 inch và khung viền Titanium đẳng cấp. Đây là mẫu máy hội tụ tất cả những gì tinh túy nhất của Apple ở thời điểm hiện tại.</p><ul><li><strong>Zoom quang học 5x độc quyền:</strong> Đưa mọi khung hình ở xa vào tầm mắt sắc nét nhất nhờ thấu kính tetraprism.</li><li><strong>Pin cực trâu:</strong> Tối ưu hóa cực tốt, cho thời lượng xem video liên tục lên đến 29 giờ.</li><li><strong>Nút Tác vụ (Action Button):</strong> Thay thế cần gạt rung truyền thống, truy cập nhanh ứng dụng yêu thích chỉ bằng 1 nút nhấn.</li></ul>', 'assets/images/products/iphone-15-pro-max.png'),
(4, 1, N'iPhone 16 Pro', N'<h2>Thế hệ Pro, được tiếp sức bởi Apple Intelligence</h2><p><strong>iPhone 16 Pro</strong> mang đến viền màn hình mỏng nhất từng có và bổ sung sức mạnh AI toàn diện, giúp bạn viết lách, sáng tạo và làm việc một cách thông minh hơn bao giờ hết.</p><ul><li><strong>Màn hình 6.3 inch:</strong> Kích thước được gia tăng, hiển thị đã mắt hơn mà vẫn vừa vặn trong lòng bàn tay.</li><li><strong>Camera Ultra Wide 48MP:</strong> Bắt trọn góc rộng với độ chi tiết đến kinh ngạc, chụp macro sắc nét tuyệt đối.</li><li><strong>Camera Control:</strong> Nút bấm cơ học hoàn toàn mới hỗ trợ lấy nét, thu phóng và chụp ảnh chuyên nghiệp như một nhiếp ảnh gia thực thụ.</li></ul>', 'assets/images/products/iphone-16-pro.png'),
(4, 1, N'iPhone 16 Pro Max', N'<h2>Màn hình 6.9 inch cực đại, hiệu năng vô song</h2><p><strong>iPhone 16 Pro Max</strong> là chiếc iPhone lớn nhất và mạnh nhất, được trang bị chip A18 Pro đột phá cùng viên pin có dung lượng lớn nhất trong lịch sử Apple.</p><ul><li><strong>Chip A18 Pro:</strong> Bứt phá mọi giới hạn hiệu năng, vận hành Apple Intelligence siêu tốc, siêu mượt.</li><li><strong>Xử lý AI thông minh:</strong> Tự động tóm tắt tin nhắn, chỉnh sửa ảnh nâng cao và tạo hình ảnh AI theo ngữ cảnh.</li><li><strong>Studio Audio:</strong> Hệ thống 4 micro chuẩn studio, có khả năng lọc tiếng ồn bằng AI để thu âm chuyên nghiệp khi quay phim.</li></ul>', 'assets/images/products/iphone-16-pro-max.png'),
(4, 2, N'Samsung Galaxy S24 Ultra', N'<h2>Tuyệt tác thiết kế Titan, Quyền năng Galaxy AI</h2><p><strong>Samsung Galaxy S24 Ultra</strong> trang bị khung viền Titan siêu cao cấp cùng bút S-Pen huyền thoại. Chiếc điện thoại này kết hợp cùng sức mạnh AI tích hợp sâu, thay đổi hoàn toàn cách bạn thao tác hằng ngày.</p><ul><li><strong>Circle to Search:</strong> Khoanh tròn bất kỳ vật thể nào trên màn hình bằng tay hoặc S-Pen để tìm kiếm thông tin ngay tức thì.</li><li><strong>Camera 200MP Mắt Thần Bóng Đêm:</strong> Công nghệ ProVisual Engine giúp chụp đêm rực rỡ, zoom quang 5x nhưng chất lượng chuẩn studio.</li><li><strong>Live Translate:</strong> Dịch thuật hai chiều trực tiếp khi gọi điện thoại không cần kết nối mạng.</li></ul>', 'assets/images/products/s24-ultra.jpg'),
(4, 2, N'Samsung Galaxy S24 Plus', N'<h2>Màn hình QHD+ sắc nét, Hiệu năng đỉnh cao</h2><p><strong>Samsung Galaxy S24 Plus</strong> mang đến trải nghiệm màn hình phẳng lớn 6.7 inch rực rỡ chuẩn QHD+ và viên pin được nâng cấp mạnh mẽ giúp bạn sử dụng cả ngày dài mà không lo sạc lại.</p><ul><li><strong>Thiết kế Armor Aluminum:</strong> Chắc chắn, bóng bẩy, viền màn hình siêu mỏng liền mạch tinh tế.</li><li><strong>Trợ lý Note Assist:</strong> Tính năng AI siêu việt tự động tóm tắt, sắp xếp và định dạng ghi chú trong chớp mắt.</li><li><strong>Pin 4900mAh:</strong> Hỗ trợ sạc siêu nhanh 45W, không bao giờ để gián đoạn cuộc vui của bạn.</li></ul>', 'assets/images/products/s24-plus.jpg'),
(4, 2, N'Samsung Galaxy A55 5G', N'<h2>Thiết kế viền kim loại cao cấp, chống nước IP67</h2><p><strong>Galaxy A55 5G</strong> nâng tầm phân khúc cận cao cấp của Samsung với mặt lưng kính sang trọng, khung viền kim loại cứng cáp và hệ thống camera chống rung quang học OIS cực kỳ xịn sò.</p><ul><li><strong>Camera Nightography 50MP:</strong> Cảm biến điểm ảnh lớn giúp chụp đêm sáng rõ, màu sắc chân thực, ít nhiễu hạt.</li><li><strong>Màn hình Super AMOLED 120Hz:</strong> Trải nghiệm vuốt chạm mượt mà, độ sáng cao 1000 nits thách thức ánh nắng gắt.</li><li><strong>Bảo mật Knox Vault:</strong> Chứng nhận bảo mật cao cấp, bảo vệ dữ liệu cá nhân, mật khẩu an toàn tuyệt đối khỏi sự tấn công phần cứng.</li></ul>', 'assets/images/products/samsung-a55.jpg'),
(4, 2, N'Samsung Galaxy A35 5G', N'<h2>Màn hình Infinity-O mượt mà, Pin siêu khủng</h2><p><strong>Galaxy A35 5G</strong> là sự cân bằng hoàn hảo giữa thiết kế hiện đại Key Island, hiệu năng ổn định và mức giá cực kỳ phải chăng dành cho người dùng trẻ tuổi, học sinh, sinh viên.</p><ul><li><strong>Màn hình Super AMOLED 6.6 inch:</strong> Không gian giải trí đắm chìm, sống động, hỗ trợ Vision Booster chống chói.</li><li><strong>Pin 5000mAh bền bỉ:</strong> Hoạt động liên tục suốt 2 ngày với các tác vụ cơ bản.</li><li><strong>Camera 50MP chống rung OIS:</strong> Chụp ảnh ổn định sắc nét, hỗ trợ quay video không rung lắc dù bạn đang di chuyển.</li></ul>', 'assets/images/products/samsung-a35.jpg'),
(5, 1, N'AirPods Pro 2', N'<h2>Âm thanh đắm chìm, chống ồn chủ động gấp đôi</h2><p><strong>AirPods Pro 2</strong> với sức mạnh cốt lõi từ con chip H2 tiên tiến, mang đến trải nghiệm âm thanh không gian (Spatial Audio) cá nhân hóa và khả năng triệt tiêu tiếng ồn xuất sắc nhất thế giới tai nghe In-ear.</p><ul><li><strong>Chống ồn chủ động (ANC):</strong> Loại bỏ tạp âm hiệu quả gấp 2 lần so với thế hệ trước.</li><li><strong>Xuyên âm thích ứng thông minh:</strong> Tự động nhận diện và giảm thiểu tiếng ồn chói tai đột ngột (như tiếng còi xe, công trường) khi bạn đang ở chế độ xuyên âm.</li><li><strong>Điều khiển cảm ứng vuốt:</strong> Tiện lợi tăng giảm âm lượng trực tiếp trên thân tai nghe mà không cần rút điện thoại.</li></ul>', 'assets/images/products/airpods-pro-2.jpg'),
(5, 1, N'AirPods 4', N'<h2>Thiết kế Open-ear mới vừa vặn, Âm thanh nâng tầm</h2><p><strong>AirPods 4</strong> là phiên bản cải tiến mang lại sự thoải mái tối đa khi đeo trong thời gian dài (nhờ thiết kế open-ear không mút cao su) cùng chất lượng đàm thoại trong trẻo nhờ kiến trúc âm học mới.</p><ul><li><strong>Chip H2 mạnh mẽ:</strong> Xử lý âm thanh tính toán vượt trội, kết nối với hệ sinh thái Apple cực nhanh.</li><li><strong>Chống nước và bụi IP54:</strong> Hoàn toàn yên tâm đeo đi mưa nhẹ hoặc tập luyện thể thao đổ mồ hôi.</li><li><strong>Pin 30 giờ:</strong> Hộp sạc nhỏ gọn nhất từ trước đến nay, hỗ trợ sạc phổ quát qua cổng USB-C tiện lợi.</li></ul>', 'assets/images/products/airpods-4.jpg'),
(5, 2, N'Samsung Galaxy Buds3 Pro', N'<h2>Âm thanh Hi-Fi 24bit sống động như phòng thu</h2><p><strong>Galaxy Buds3 Pro</strong> đánh dấu sự thay đổi thiết kế ngoạn mục với thân tai nghe dạng ống tam giác góc cạnh, dải đèn Blade Light cá tính và khả năng chống ồn AI thông minh xuất sắc.</p><ul><li><strong>Adaptive ANC:</strong> Phân tích thói quen đeo và tự động điều chỉnh mức độ chống ồn tối ưu nhất theo môi trường xung quanh.</li><li><strong>Âm thanh đa chiều 360 Audio:</strong> Trải nghiệm nghe nhạc, xem phim như bạn đang ngồi ở vị trí trung tâm rạp hát.</li><li><strong>Phiên dịch viên AI:</strong> Hỗ trợ nghe dịch trực tiếp theo thời gian thực (Live Translate) thông qua điện thoại Galaxy.</li></ul>', 'assets/images/products/galaxy-buds3-pro.jpg'),
(5, 2, N'Samsung Galaxy Buds FE', N'<h2>Chất âm bùng nổ, Thiết kế vừa vặn hoàn hảo</h2><p><strong>Galaxy Buds FE</strong> là dòng tai nghe Fan Edition mang thiết kế công thái học đi kèm bộ đệm cánh (wing-tips) giúp bám cực sát vào vành tai, mang lại trải nghiệm nghe nhạc liên tục không gây rơi rớt hay đau nhức.</p><ul><li><strong>Bass sâu và có lực:</strong> Củ loa tinh chỉnh một màng cho âm trầm bùng nổ, mạnh mẽ.</li><li><strong>Chống ồn ANC xịn sò:</strong> Loại bỏ các tạp âm tĩnh hiệu quả, giúp bạn tập trung tối đa làm việc hoặc giải trí.</li><li><strong>Pin lên đến 30 giờ:</strong> Giải trí không gián đoạn, hỗ trợ kết nối chuyển đổi thông minh Auto Switch.</li></ul>', 'assets/images/products/galaxy-buds-fe.jpg'),
(6, 1, N'Apple USB-C 20W Power Adapter', N'<h2>Sạc nhanh, an toàn cho mọi thiết bị hệ sinh thái Apple</h2><p>Củ sạc <strong>Apple 20W USB-C</strong> mang đến khả năng sạc tốc độ cao, giúp nạp đầy 50% pin iPhone chỉ trong vòng 30 phút. Hàng chính hãng đảm bảo dòng điện ổn định tuyệt đối, chống tình trạng phồng hay chai pin.</p><ul><li><strong>Công suất 20W chuẩn xác:</strong> Sạc nhanh tức thì cho các thế hệ iPhone, iPad.</li><li><strong>Tương thích đa dạng:</strong> Dùng cực tốt để sạc tối ưu cho hộp sạc AirPods, Apple Watch hay iPad.</li><li><strong>Thiết kế nhỏ gọn:</strong> Thiết kế chấu sạc gập (tùy thị trường) dễ dàng mang theo trong balo đi mọi nơi.</li></ul>', 'assets/images/products/apple-20w.jpg'),
(6, 2, N'Samsung 25W USB-C Fast Charger', N'<h2>Sạc siêu tốc 25W chuẩn Power Delivery 3.0</h2><p>Củ sạc <strong>Samsung 25W</strong> hỗ trợ công nghệ sạc cực nhanh Super Fast Charging độc quyền, giúp sạc đầy điện thoại Galaxy trong thời gian ngắn nhất mà không làm quá nhiệt hay hư hại thiết bị.</p><ul><li><strong>Chuẩn sạc PD (Power Delivery) 3.0:</strong> Phân phối điện năng thông minh, giao tiếp với máy để cấp đúng điện áp cần thiết.</li><li><strong>Đa tương thích xuất sắc:</strong> Sạc tốt và an toàn cho smartphone Android, tablet, tai nghe không dây.</li><li><strong>Bảo vệ dòng điện nhiều lớp:</strong> Chống đoản mạch, chống quá dòng, chống tĩnh điện an toàn tuyệt đối.</li></ul>', 'assets/images/products/samsung-25w.jpg'),
(7, 1, N'Apple USB-C Charge Cable 1m', N'<h2>Đồng bộ dữ liệu và sạc nhanh chóng, thiết kế dây bọc dù mới</h2><p>Cáp sạc <strong>Apple USB-C 1m</strong> chính hãng với thiết kế bọc dù chống rối mới nhất, chịu lực uốn cong cực tốt. Rất thích hợp sử dụng cho các dòng iPhone 15, 16 series, iPad Pro và MacBook thế hệ mới.</p><ul><li><strong>Chất liệu bọc dù bền bỉ:</strong> Khắc phục nhược điểm ố vàng và đứt gãy lõi cáp truyền thống của Apple.</li><li><strong>Hỗ trợ sạc lên đến 60W:</strong> Sạc tốt cho cả MacBook Air và iPad Pro ở tốc độ cao nhất.</li><li><strong>Truyền dữ liệu ổn định:</strong> Đạt tốc độ tiêu chuẩn USB 2.0 (480Mbps) cho phép đồng bộ ảnh và tài liệu nhanh.</li></ul>', 'assets/images/products/apple-cable-c2c.jpg'),
(7, 1, N'Apple USB-C to Lightning Cable', N'<h2>Sạc nhanh chuẩn MFi cho các dòng iPhone đời cũ</h2><p>Cáp <strong>USB-C to Lightning</strong> chính hãng Apple giúp bạn tận dụng tối đa các củ sạc 20W/30W chuẩn Type-C để kích hoạt công nghệ sạc nhanh cho các dòng iPhone 14 trở về trước.</p><ul><li><strong>Chứng nhận MFi:</strong> Con chip xác thực tích hợp bên trong tương thích hoàn hảo và bảo vệ hệ sinh thái thiết bị Apple của bạn.</li><li><strong>Chiều dài 1 mét chuẩn mực:</strong> Tiện dụng đặt trên bàn làm việc, gọn gàng không quá vướng víu.</li><li><strong>Sạc nhanh PD hiệu quả:</strong> Đẩy nhanh tiến độ sạc, đầy 50% pin chỉ trong vòng 30 phút cắm sạc.</li></ul>', 'assets/images/products/apple-cable-c2l.jpg'),
(7, 2, N'Samsung USB-C Cable 1m', N'<h2>Cáp C-to-C chính hãng, truyền tải điện năng cực cao</h2><p>Cáp sạc <strong>Samsung USB-C 1m</strong> màu đen nhám đặc trưng, hoàn thiện đúc khối chắc chắn, dẫn điện cực kỳ ổn định, hỗ trợ hoàn hảo cho các chuẩn sạc nhanh 25W và 45W cao cấp nhất của hãng.</p><ul><li><strong>Chịu tải dòng điện lên đến 3A:</strong> Sạc siêu tốc an toàn, không bị nghẽn điện áp.</li><li><strong>Tốc độ đồng bộ cực nhanh:</strong> Chép file giữa máy tính và điện thoại nhanh chóng, cắm Samsung Dex xuất hình ảnh ổn định.</li><li><strong>Đầu cáp bọc nhựa đúc đặc:</strong> Chống gập gãy phần cổ cáp, bảo vệ chân Type-C bền bỉ.</li></ul>', 'assets/images/products/samsung-cable-c2c.jpg'),
(8, 3, N'Lenovo IdeaPad Slim 3', N'<h2>Mỏng nhẹ, cơ động, đáp ứng hoàn hảo mọi nhu cầu cơ bản</h2><p><strong>Lenovo IdeaPad Slim 3</strong> là dòng laptop quốc dân cho giới văn phòng và học sinh, sinh viên. Máy có thiết kế mỏng nhẹ ấn tượng, vỏ ngoài màu xám bạc thanh lịch. Cấu hình đủ sức giải quyết cực kỳ mượt mà các tác vụ Word, Excel, lướt web và xem phim.</p><ul><li><strong>Vi xử lý Intel Core i3 gen 13:</strong> Hiệu năng ổn định, chạy mát, thời lượng pin tiết kiệm cực kỳ.</li><li><strong>RAM 8GB đa nhiệm tốt:</strong> Cho phép bạn mở nhiều tab Chrome và xử lý văn bản cùng lúc.</li><li><strong>Màn hình 15.6 inch FHD viền mỏng:</strong> Lớp phủ chống chói Anti-Glare bảo vệ mắt khi dùng lâu.</li></ul>', 'assets/images/products/lenovo-ideapad-slim-3.jpg'),
(8, 3, N'Lenovo ThinkBook 14', N'<h2>Chuẩn mực doanh nhân trẻ, bảo mật công nghệ tối ưu</h2><p><strong>Lenovo ThinkBook 14</strong> sở hữu thiết kế vỏ nhôm hai tông màu (Dual-tone) cực kỳ thu hút và sang trọng. Bàn phím hành trình gõ cực êm ái đặc trưng và tích hợp cảm biến vân tay ở nút nguồn, mang lại sự chuyên nghiệp cho môi trường công sở.</p><ul><li><strong>Vi xử lý Intel Core i5 gen 13:</strong> Xử lý nhanh gọn báo cáo tài chính, phần mềm doanh nghiệp nặng.</li><li><strong>RAM 16GB chuẩn mới:</strong> Đa nhiệm siêu tốc, chuyển đổi qua lại giữa hàng chục ứng dụng không độ trễ.</li><li><strong>Bảo mật cấp độ phần cứng TPM 2.0:</strong> Mã hóa dữ liệu an toàn, chống lại các rủi ro đánh cắp qua mạng.</li></ul>', 'assets/images/products/lenovo-thinkbook-14.jpg'),
(8, 3, N'Lenovo IdeaPad 5', N'<h2>Cân bằng hoàn hảo giữa hiệu năng và thiết kế đa dụng</h2><p><strong>Lenovo IdeaPad 5</strong> được trang bị bộ vi xử lý AMD Ryzen thế hệ mới cực kỳ mạnh mẽ, thời lượng pin dài, vô cùng phù hợp cho sinh viên Công nghệ hoặc người làm Marketing cần một thiết bị đa dụng, màn hình lớn nhưng không quá cồng kềnh.</p><ul><li><strong>Chip AMD Ryzen 5 đa nhân:</strong> Tích hợp card đồ họa Radeon xử lý tốt các tác vụ Photoshop, Canva mượt mà.</li><li><strong>Pin cực khỏe:</strong> Thời lượng sử dụng thực tế ấn tượng, hỗ trợ sạc nhanh Rapid Charge xua tan nỗi lo về pin.</li><li><strong>Âm thanh công nghệ Dolby Audio:</strong> Âm trầm ấm, phát to rõ ràng giúp giải trí xem phim cực đã.</li></ul>', 'assets/images/products/lenovo-ideapad-5.jpg'),
(9, 3, N'Lenovo LOQ 15', N'<h2>Sát thủ cấu hình chiến mượt mọi Game trong phân khúc phổ thông</h2><p><strong>Lenovo LOQ 15</strong> là dòng laptop gaming hoàn toàn mới kế thừa DNA thiết kế và sức mạnh của dòng Legion cao cấp. Thiết kế hầm hố vừa đủ, khe tản nhiệt siêu lớn phía sau giúp máy luôn mát, chiến mượt các tựa game eSport và AAA ở mức đồ họa cao.</p><ul><li><strong>Card rời RTX 4050 6GB:</strong> Kiến trúc Ada Lovelace mới nhất, hỗ trợ DLSS 3 và Ray Tracing chân thực.</li><li><strong>Màn hình 144Hz chuẩn gaming:</strong> Phản hồi hình ảnh nhanh nhạy, không xé hình trong các pha vẩy chuột.</li><li><strong>Tích hợp chip AI LA1:</strong> Trí tuệ nhân tạo Lenovo AI Engine+ tự động phân bổ tài nguyên giúp tối đa mức FPS.</li></ul>', 'assets/images/products/lenovo-loq-15.jpg'),
(9, 3, N'Lenovo Legion 5', N'<h2>Cỗ máy chiến game thực thụ, cấu hình chuẩn eSport quốc tế</h2><p><strong>Lenovo Legion 5</strong> tiếp tục định nghĩa lại chuẩn mực laptop gaming tầm trung với hệ thống tản nhiệt kép Coldfront 5.0, bàn phím TrueStrike gõ siêu nảy và một thiết kế vuông vức vừa có thể chơi game, vừa mang đi làm việc cực kỳ sang trọng.</p><ul><li><strong>Card đồ họa RTX 4060 8GB TGP cao:</strong> Bung sức mạnh tối đa, cân tốt việc Render làm phim 4K hay thiết kế 3D.</li><li><strong>Màn hình WQHD 165Hz (100% sRGB):</strong> Trải nghiệm thị giác bùng nổ, chuẩn màu phục vụ thiết kế đồ họa tuyệt đối.</li><li><strong>Đa dạng cổng kết nối:</strong> Bố trí thông minh phía sau mặt lưng, giúp góc làm việc của bạn không bị vướng víu dây dợ.</li></ul>', 'assets/images/products/lenovo-legion-5.jpg'),
(9, 3, N'Lenovo Legion Pro 5', N'<h2>Đỉnh cao sức mạnh, không thỏa hiệp ở bất cứ cấu hình nào</h2><p><strong>Lenovo Legion Pro 5</strong> là một quái vật hiệu năng thực sự dành cho giới làm nghề chuyên nghiệp và Hardcore Gamer. Khung viền kim loại cực kỳ chắc chắn, hệ thống tản nhiệt pha nhiệt lỏng siêu cấp mang lại nhiệt độ cực lý tưởng dù máy hoạt động 100% công suất.</p><ul><li><strong>CPU Intel Core i9-14900HX:</strong> Sức mạnh 24 nhân 32 luồng siêu khủng khiếp, render đồ họa chỉ là chuyện nhỏ.</li><li><strong>GPU RTX 4070 8GB VRAM:</strong> Dư sức gánh mọi tựa game 2K hiện nay ở mức đồ họa Ultra mượt mà nhất.</li><li><strong>Màn hình WQXGA 240Hz 500 Nits:</strong> Siêu rực rỡ, tích hợp chống xé hình G-Sync, mang lại lợi thế phản xạ tuyệt đối trong giao tranh.</li></ul>', 'assets/images/products/lenovo-legion-pro-5.png'),
(10, 3, N'Lenovo Legion M300 RGB', N'<h2>Chuột gaming công thái học đối xứng, nhẹ nhàng linh hoạt</h2><p><strong>Lenovo Legion M300</strong> có thiết kế hoàn hảo cho những game thủ thuận tay phải lẫn tay trái. Cảm biến quang học chính xác cao kết hợp nút bấm nảy giòn giúp bạn tự tin lia chuột và xử lý tình huống nhanh nhạy trong các tựa game bắn súng FPS.</p><ul><li><strong>Độ phân giải siêu nhạy 8000 DPI:</strong> Mắt đọc Pixart xử lý thông tin chuẩn xác.</li><li><strong>Đèn LED RGB rực rỡ:</strong> Tùy chỉnh màu sắc cá tính ở phần logo rực sáng.</li><li><strong>Grip hông bọc cao su:</strong> Tăng cường độ bám, chống trượt khi tay ra mồ hôi do căng thẳng.</li></ul>', 'assets/images/products/lenovo-m300.jpg'),
(10, 3, N'Lenovo Legion M600 Wireless', N'<h2>Không dây siêu tốc độ, chính xác từng milimet</h2><p><strong>Legion M600</strong> mang đến kết nối không dây 2.4GHz không có một chút độ trễ nào. Cấu trúc cân bằng trọng lượng thông minh mang lại cảm giác vẩy chuột nhẹ tênh và tự do hoàn toàn tuyệt đối trên mặt bàn di.</p><ul><li><strong>Cảm biến cực khủng 16000 DPI:</strong> Hỗ trợ tốc độ theo dõi lên tới 400 IPS.</li><li><strong>Thời lượng pin 200 giờ:</strong> Chơi game quên ngày tháng, sạc nhanh qua cổng USB-C.</li><li><strong>Kết nối linh hoạt 3 chế độ:</strong> Hỗ trợ dùng dây cáp vừa sạc vừa chơi, đầu thu USB Receiver 2.4G và cả Bluetooth siêu tiện dụng.</li></ul>', 'assets/images/products/lenovo-m600.jpg'),
(11, 3, N'Lenovo Legion K300 RGB', N'<h2>Bàn phím cơ màng êm ái nhưng nảy lửa trong từng pha bấm</h2><p><strong>Lenovo Legion K300</strong> có thiết kế nguyên khối tối giản, độ êm khi gõ cực tốt giúp bạn chiến game đêm khuya không gây ồn ào. Hệ thống đèn nền LED RGB 5 vùng tùy chỉnh mượt mà biến góc máy của bạn thêm phần sinh động.</p><ul><li><strong>Tính năng Anti-ghosting 24 phím:</strong> Đảm bảo không bị sót phím khi nhấn combo nhiều kỹ năng cùng lúc.</li><li><strong>Thiết kế phím bấm hơi lõm:</strong> Ôm ngón tay, hành trình phím sâu cho độ phản hồi cực chân thật.</li><li><strong>Lỗ thoát nước thông minh:</strong> Chống tràn hiệu quả nếu bạn lỡ tay làm đổ nước lọc hay cafe lên phím.</li></ul>', 'assets/images/products/lenovo-k300.jpg'),
(11, 3, N'Lenovo Go Wireless Split Keyboard', N'<h2>Thiết kế công thái học tách đôi, giải pháp bảo vệ ống cổ tay hoàn hảo</h2><p><strong>Lenovo Go Wireless Split Keyboard</strong> là bàn phím không dây sinh ra dành cho giới văn phòng, lập trình viên thường xuyên gõ code. Thiết kế tách đôi hình chữ V nhô cao giúp hai cổ tay luôn giữ ở góc độ tự nhiên nhất, giảm thiểu tối đa triệu chứng chấn thương ống cổ tay.</p><ul><li><strong>Nệm kê tay làm từ vật liệu Cork tự nhiên:</strong> Êm ái tuyệt vời, thân thiện với môi trường, đặc tính chống thấm và chống ẩm mồ hôi.</li><li><strong>Phím cắt kéo (Scissor switch):</strong> Mang lại cảm giác gõ tĩnh âm mượt mà, độ nảy và phản hồi rất tốt.</li><li><strong>Kết nối không dây đa thiết bị:</strong> Ghép đôi nhanh qua đầu thu USB-C hoặc dùng Bluetooth để chuyển đổi giữa PC, điện thoại, máy tính bảng.</li></ul>', 'assets/images/products/lenovo-go-split.jpg'),
(12, 3, N'Lenovo 300 FHD Webcam', N'<h2>Ghi hình 1080p sắc nét, giải pháp họp trực tuyến dễ dàng</h2><p><strong>Lenovo 300 FHD Webcam</strong> là phụ kiện nâng cấp chất lượng hình ảnh ngay tức thì cho những chiếc laptop đời cũ hoặc máy bàn. Sở hữu ống kính rộng 95 độ kết hợp micro kép thu âm đa hướng nhạy bén, mọi hình ảnh của bạn luôn sáng rõ trong mắt đồng nghiệp.</p><ul><li><strong>Độ phân giải thực tế 1080p:</strong> Rõ nét từng sợi tóc, tự động cân bằng sáng (Auto White Balance) ngay cả trong phòng tối.</li><li><strong>Nắp che vật lý an toàn:</strong> Dễ dàng trượt lẫy để che kín ống kính, bảo mật sự riêng tư tuyệt đối khi không sử dụng.</li><li><strong>Cắm là chạy (Plug-and-play):</strong> Không cần tải driver phức tạp, tương thích hoàn hảo mọi hệ điều hành qua cổng USB-A phổ biến.</li></ul>', 'assets/images/products/lenovo-300-webcam.jpg'),
(12, 3, N'Lenovo Performance FHD Webcam', N'<h2>Chất lượng truyền phát chuyên nghiệp 60fps mượt mà như thật</h2><p><strong>Lenovo Performance FHD</strong> là mẫu webcam chuẩn phòng studio thu nhỏ dành cho giới Streamer, Youtuber hoặc các cấp quản lý cần hình ảnh họp trực tuyến cao cấp. Tốc độ khung hình thực lên tới 60fps mang lại video không hề có hiện tượng bóng mờ khi chuyển động mạnh.</p><ul><li><strong>Hỗ trợ chuẩn nhận diện khuôn mặt bảo mật (Windows Hello):</strong> Giúp bạn mở khóa máy tính an toàn, thông minh và cực kỳ nhanh chóng.</li><li><strong>Lấy nét tự động cực nhanh (Auto Focus):</strong> Luôn giữ khuôn mặt bạn nổi bật và sắc nét dù bạn tiến gần hay lùi xa màn hình.</li><li><strong>Dây cáp chuẩn USB-C rời tiện lợi:</strong> Giúp băng thông truyền hình ảnh rộng hơn và hạn chế tình trạng giật lag.</li></ul>', 'assets/images/products/lenovo-fhd-webcam.jpg'),
(13, 3, N'Lenovo Laptop Backpack 15.6"', N'<h2>Balo văn phòng thanh lịch, chống sốc an toàn cho laptop</h2><p>Balo <strong>Lenovo 15.6 inch</strong> có phong cách thiết kế vô cùng gọn gàng, tinh giản, cực kỳ phù hợp cho học sinh và giới văn phòng mang đi làm hằng ngày. Balo làm từ lớp vải sợi nhân tạo có tính năng chống thấm nước nhẹ, duy trì form cứng cáp và khó bám bụi bẩn.</p><ul><li><strong>Khoang chứa thông minh:</strong> Ngăn đựng laptop 15.6 inch riêng biệt lót bông chống sốc chống trầy hiệu quả.</li><li><strong>Trọng lượng siêu nhẹ (chỉ 0.5kg):</strong> Tối giản lớp đệm thừa, không gây ra cảm giác đau mỏi vai nếu phải di chuyển nhiều trên tàu xe.</li><li><strong>Ngăn ẩn bí mật:</strong> Bố trí một ngăn khóa kéo an toàn ép sát vào lưng để đựng ví tiền, giấy tờ hay điện thoại quan trọng.</li></ul>', 'assets/images/products/lenovo-backpack-15.jpg'),
(13, 3, N'Lenovo Legion Gaming Backpack', N'<h2>Balo hầm hố, sức chứa khổng lồ vác trọn thế giới Game thủ</h2><p><strong>Lenovo Legion Backpack</strong> sở hữu một thiết kế như "áo giáp" cứng cáp ở mặt trước, giúp bảo vệ an toàn tối đa cho chiếc laptop gaming đắt tiền của bạn khỏi mọi cú va đập rủi ro nhất. Form dáng đậm chất góc cạnh của hệ sinh thái Legion.</p><ul><li><strong>Khoang chứa ngoại cỡ (vừa laptop 17 inch):</strong> Đủ rộng để bạn đựng cả phím cơ full-size, chuột, tấm lót, tai nghe chùm đầu và cả bộ sạc gạch siêu bự.</li><li><strong>Vải chống đứt rách cường độ cao:</strong> Độ bền siêu việt, lớp lót chống sốc trong túi được làm rất dày bao bọc quanh thân máy.</li><li><strong>Quai đeo nệm đúc EVA xịn sò:</strong> Cấu trúc phân tán lực đều qua vai, lưng có mút thoáng khí dày cộp không lo tụ mồ hôi lưng khi đeo đi phượt.</li></ul>', 'assets/images/products/lenovo-legion-backpack.jpg');

INSERT INTO ATTRIBUTE (attribute_name)
VALUES
(N'Màn hình'),
(N'RAM'),
(N'Dung lượng lưu trữ'),
(N'Chip xử lý (CPU)'),
(N'Card đồ họa (GPU)'),
(N'Hệ điều hành'),
(N'Pin'),
(N'Kết nối'),
(N'Tính năng'),
(N'Màu sắc'),
(N'Kích thước'),
(N'Trọng lượng'),
(N'Độ phân giải'),
(N'DPI'),
(N'Loại kết nối');


INSERT INTO dbo.ATTRIBUTE(attribute_name) VALUES
(N'Camera'),
(N'Tần số quét'),
(N'Loại màn hình'),
(N'Công suất sạc'),
(N'Chống nước'),
(N'Chống ồn'),
(N'Dung lượng pin'),
(N'Chất liệu'),
(N'Kích thước mặt đồng hồ'),
(N'Cảm biến máy ảnh'),
(N'Bộ sản phẩm'),
(N'Chiều dài'),
(N'Gói bán'),
(N'Kích thước vỏ'),
(N'Phiên bản');

INSERT INTO PRODUCT_SPECIFICATION (product_id, attribute_id, value)
VALUES
(1, 1, N'6.1 inch Super Retina XDR OLED'),
(1, 4, N'Apple A17 Pro'),
(2, 1, N'6.7 inch Super Retina XDR OLED'),
(2, 4, N'Apple A17 Pro'),
(3, 1, N'6.3 inch Super Retina XDR OLED'),
(3, 4, N'Apple A18 Pro'),
(4, 1, N'6.9 inch Super Retina XDR OLED'),
(4, 4, N'Apple A18 Pro'),
(5, 1, N'6.8 inch Dynamic AMOLED 2X'),
(5, 4, N'Snapdragon 8 Gen 3 for Galaxy'),
(6, 1, N'6.7 inch Dynamic AMOLED 2X'),
(6, 4, N'Exynos 2400'),
(7, 1, N'6.6 inch Super AMOLED'),
(7, 4, N'Exynos 1480'),
(8, 1, N'6.6 inch Super AMOLED'),
(8, 4, N'Exynos 1380'),
(9, 9, N'Chống ồn chủ động (ANC)'),
(9, 8, N'Bluetooth 5.3'),
(10, 9, N'Âm thanh không gian cá nhân hóa'),
(10, 8, N'Bluetooth 5.3'),
(11, 9, N'Chống ồn chủ động (ANC), Galaxy AI'),
(11, 8, N'Bluetooth 5.4'),
(12, 9, N'Chống ồn chủ động (ANC)'),
(12, 8, N'Bluetooth 5.2'),
(13, 15, N'USB-C'),
(13, 9, N'Sạc nhanh 20W'),
(14, 15, N'USB-C'),
(14, 9, N'Sạc nhanh siêu tốc 25W'),
(15, 15, N'USB-C to USB-C'),
(15, 11, N'1 mét'),
(16, 15, N'USB-C to Lightning'),
(16, 11, N'1 mét'),
(17, 15, N'USB-C to USB-C'),
(17, 11, N'1 mét'),
(18, 1, N'15.6 inch FHD'),
(18, 2, N'8GB DDR4'),
(18, 4, N'Intel Core i3-1315U'),
(19, 1, N'14 inch WUXGA'),
(19, 2, N'16GB DDR5'),
(19, 4, N'Intel Core i5-1335U'),
(20, 1, N'15.6 inch FHD'),
(20, 2, N'16GB DDR4'),
(20, 4, N'AMD Ryzen 5 7530U'),
(21, 1, N'15.6 inch FHD 144Hz'),
(21, 2, N'16GB DDR5'),
(21, 4, N'Intel Core i5-13420H'),
(21, 5, N'NVIDIA GeForce RTX 4050 6GB'),
(22, 1, N'15.6 inch WQHD 165Hz'),
(22, 2, N'16GB DDR5'),
(22, 4, N'AMD Ryzen 7 7735HS'),
(22, 5, N'NVIDIA GeForce RTX 4060 8GB'),
(23, 1, N'16 inch WQXGA 240Hz'),
(23, 2, N'32GB DDR5'),
(23, 4, N'Intel Core i9-14900HX'),
(23, 5, N'NVIDIA GeForce RTX 4070 8GB'),
(24, 14, N'Lên đến 8000 DPI'),
(24, 15, N'Có dây (USB-A)'),
(25, 14, N'Lên đến 16000 DPI'),
(25, 15, N'Không dây (Wireless/Bluetooth)'),
(26, 9, N'LED RGB 5 vùng'),
(26, 15, N'Có dây (USB-A)'),
(27, 9, N'Thiết kế công thái học (Split)'),
(27, 15, N'Không dây'),
(28, 13, N'1080p FHD'),
(28, 15, N'USB-A'),
(29, 13, N'1080p FHD 60fps'),
(29, 15, N'USB-C'),
(30, 11, N'Vừa laptop 15.6 inch'),
(30, 12, N'0.5 kg'),
(31, 11, N'Vừa laptop 17 inch'),
(31, 12, N'0.8 kg');

DECLARE @InitialSkuOptions TABLE (
    sku_code VARCHAR(100) NOT NULL,
    attribute_name NVARCHAR(100) NOT NULL,
    text_value NVARCHAR(255) NOT NULL,
    PRIMARY KEY(sku_code, attribute_name)
);
INSERT INTO @InitialSkuOptions(sku_code,attribute_name,text_value) VALUES
('IP15P-128-BLK', N'Dung lượng lưu trữ', N'128GB'),
('IP15P-128-BLK', N'Màu sắc', N'Đen'),
('IP15P-256-SLV', N'Dung lượng lưu trữ', N'256GB'),
('IP15P-256-SLV', N'Màu sắc', N'Bạc'),
('SS-S24U-256-GRY', N'Dung lượng lưu trữ', N'256GB'),
('SS-S24U-256-GRY', N'Màu sắc', N'Xám'),
('LOQ-15-16GB-512GB', N'RAM', N'16GB DDR5'),
('LOQ-15-16GB-512GB', N'Dung lượng lưu trữ', N'512GB'),
('LOQ-15-16GB-512GB', N'Màu sắc', N'Xám'),
('IP15PM-256-NAT', N'Dung lượng lưu trữ', N'256GB'),
('IP15PM-256-NAT', N'Màu sắc', N'Titan tự nhiên'),
('IP16P-128-BLK', N'Dung lượng lưu trữ', N'128GB'),
('IP16P-128-BLK', N'Màu sắc', N'Đen'),
('IP16PM-256-DES', N'Dung lượng lưu trữ', N'256GB'),
('IP16PM-256-DES', N'Màu sắc', N'Titan sa mạc'),
('SS-S24P-256-BLK', N'Dung lượng lưu trữ', N'256GB'),
('SS-S24P-256-BLK', N'Màu sắc', N'Đen'),
('SS-A55-128-BLU', N'Dung lượng lưu trữ', N'128GB'),
('SS-A55-128-BLU', N'Màu sắc', N'Xanh'),
('SS-A35-128-YLW', N'Dung lượng lưu trữ', N'128GB'),
('SS-A35-128-YLW', N'Màu sắc', N'Vàng'),
('APP-AP2-WHT', N'Phiên bản', N'Hộp Lightning'),
('APP-AP2-WHT', N'Màu sắc', N'Trắng'),
('APP-AP4-WHT', N'Phiên bản', N'Tiêu chuẩn'),
('APP-AP4-WHT', N'Màu sắc', N'Trắng'),
('SS-B3P-SLV', N'Màu sắc', N'Bạc'),
('SS-BFE-BLK', N'Màu sắc', N'Đen'),
('APP-20W-WHT', N'Gói bán', N'1 củ sạc'),
('SS-25W-BLK', N'Màu sắc', N'Đen'),
('APP-C2C-1M', N'Gói bán', N'1 dây'),
('APP-C2L-1M', N'Chiều dài', N'1m'),
('SS-C2C-1M', N'Màu sắc', N'Đen'),
('LEN-IDP3-I3', N'RAM', N'8GB DDR4'),
('LEN-IDP3-I3', N'Dung lượng lưu trữ', N'256GB'),
('LEN-IDP3-I3', N'Màu sắc', N'Xám'),
('LEN-TB14-I5', N'RAM', N'16GB DDR5'),
('LEN-TB14-I5', N'Dung lượng lưu trữ', N'512GB'),
('LEN-TB14-I5', N'Màu sắc', N'Xám'),
('LEN-IDP5-R5', N'RAM', N'16GB DDR4'),
('LEN-IDP5-R5', N'Dung lượng lưu trữ', N'512GB'),
('LEN-IDP5-R5', N'Màu sắc', N'Xám'),
('LEN-LEG5-R7', N'RAM', N'16GB DDR5'),
('LEN-LEG5-R7', N'Dung lượng lưu trữ', N'512GB'),
('LEN-LEG5-R7', N'Màu sắc', N'Xám'),
('LEN-LEG5P-I9', N'RAM', N'32GB DDR5'),
('LEN-LEG5P-I9', N'Dung lượng lưu trữ', N'1TB'),
('LEN-LEG5P-I9', N'Màu sắc', N'Xám'),
('LEN-M300-BLK', N'Màu sắc', N'Đen'),
('LEN-M600-BLK', N'Màu sắc', N'Đen'),
('LEN-K300-BLK', N'Màu sắc', N'Đen'),
('LEN-GOW-GRY', N'Màu sắc', N'Xám'),
('LEN-W300-BLK', N'Màu sắc', N'Đen'),
('LEN-WPF-BLK', N'Màu sắc', N'Đen'),
('LEN-BP15-BLK', N'Màu sắc', N'Đen'),
('LEN-BPG17-BLK', N'Màu sắc', N'Đen');

SET IDENTITY_INSERT dbo.PRODUCT_SKU ON;
INSERT INTO dbo.PRODUCT_SKU(sku_id,product_id,sku_code,price,stock_quantity,variant_key)
SELECT v.sku_id,v.product_id,v.sku_code,v.price,v.stock_quantity,
       HASHBYTES('SHA2_256',variant_values.variant_text)
FROM (VALUES
    (1, 1, 'IP15P-128-BLK', 27990000, 15),
    (2, 1, 'IP15P-256-SLV', 30990000, 10),
    (3, 5, 'SS-S24U-256-GRY', 29990000, 20),
    (4, 21, 'LOQ-15-16GB-512GB', 21490000, 8),
    (5, 2, 'IP15PM-256-NAT', 33990000, 12),
    (6, 3, 'IP16P-128-BLK', 28990000, 20),
    (7, 4, 'IP16PM-256-DES', 34990000, 25),
    (8, 6, 'SS-S24P-256-BLK', 25990000, 15),
    (9, 7, 'SS-A55-128-BLU', 9990000, 30),
    (10, 8, 'SS-A35-128-YLW', 8290000, 35),
    (11, 9, 'APP-AP2-WHT', 5990000, 50),
    (12, 10, 'APP-AP4-WHT', 3490000, 45),
    (13, 11, 'SS-B3P-SLV', 4990000, 40),
    (14, 12, 'SS-BFE-BLK', 1990000, 60),
    (15, 13, 'APP-20W-WHT', 550000, 100),
    (16, 14, 'SS-25W-BLK', 390000, 100),
    (17, 15, 'APP-C2C-1M', 450000, 80),
    (18, 16, 'APP-C2L-1M', 490000, 80),
    (19, 17, 'SS-C2C-1M', 250000, 90),
    (20, 18, 'LEN-IDP3-I3', 10490000, 15),
    (21, 19, 'LEN-TB14-I5', 16990000, 12),
    (22, 20, 'LEN-IDP5-R5', 14490000, 10),
    (23, 22, 'LEN-LEG5-R7', 32990000, 5),
    (24, 23, 'LEN-LEG5P-I9', 45990000, 3),
    (25, 24, 'LEN-M300-BLK', 690000, 40),
    (26, 25, 'LEN-M600-BLK', 1490000, 25),
    (27, 26, 'LEN-K300-BLK', 890000, 30),
    (28, 27, 'LEN-GOW-GRY', 1990000, 20),
    (29, 28, 'LEN-W300-BLK', 750000, 35),
    (30, 29, 'LEN-WPF-BLK', 1250000, 15),
    (31, 30, 'LEN-BP15-BLK', 450000, 50),
    (32, 31, 'LEN-BPG17-BLK', 890000, 40)
) AS v(sku_id,product_id,sku_code,price,stock_quantity)
CROSS APPLY (
    SELECT STRING_AGG(
        CAST(CONCAT(a.attribute_id,N'=T:',UPPER(LTRIM(RTRIM(x.text_value)))) AS NVARCHAR(MAX)),N'|')
        WITHIN GROUP (ORDER BY a.attribute_id) AS variant_text
    FROM @InitialSkuOptions x
    JOIN dbo.ATTRIBUTE a ON a.attribute_name=x.attribute_name
    WHERE x.sku_code=v.sku_code
) variant_values;
SET IDENTITY_INSERT dbo.PRODUCT_SKU OFF;


INSERT INTO CART (user_id)
VALUES (3), (4);

INSERT INTO CART_ITEMS (cart_id, sku_id, quantity)
VALUES (1, 2, 1), (2, 4, 1);

INSERT INTO VOUCHER
    (code, min_order_value, valid_from, valid_to, discount_type,
     discount_value, max_discount, usage_limit, per_user_limit)
VALUES
('OECSHELLO', 10000000, '2026-01-01', '2026-12-31 23:59:59',
 'AMOUNT', 500000, NULL, 100, 1),
('OECSVIP20', 25000000, '2026-01-01', '2026-12-31 23:59:59',
 'PERCENT', 20, 1000000, 50, 1),
('TECH10', 5000000, '2026-01-01', '2026-12-31 23:59:59',
 'PERCENT', 10, 500000, 200, 2),
('SAVE200K', 3000000, '2026-01-01', '2026-12-31 23:59:59',
 'AMOUNT', 200000, NULL, NULL, 1);

INSERT INTO dbo.[ORDER]
    (user_id,address_id,total_amount,shipping_fee,order_status,
     payment_method,payment_status,discount_amount,
     recipient_name,recipient_phone,shipping_address,delivered_at)
SELECT v.user_id,v.address_id,v.total_amount,v.shipping_fee,v.order_status,
       v.payment_method,v.payment_status,v.discount_amount,
       a.recipient_name,a.phone_number,a.address_line,
       CASE WHEN v.order_status='COMPLETED' THEN SYSDATETIME() END
FROM (VALUES
    (3,1,27530000,40000,'COMPLETED','COD','PAID',500000),
    (4,3,29990000,0,'SHIPPING','COD','UNPAID',0)
) v(user_id,address_id,total_amount,shipping_fee,order_status,payment_method,payment_status,discount_amount)
JOIN dbo.ADDRESSBOOK a ON a.address_id=v.address_id;

INSERT INTO ORDER_ITEM (order_id, sku_id, price, quantity)
VALUES
(1, 1, 27990000, 1),
(2, 3, 29990000, 1);

INSERT INTO dbo.ORDER_STATUS_HISTORY
    (order_id,status,old_status,actor_type,changed_by)
SELECT v.order_id,v.status,v.old_status,
       CASE WHEN v.status='PENDING_CONFIRMATION' THEN 'CUSTOMER' ELSE 'STAFF' END,
       CASE WHEN v.status='PENDING_CONFIRMATION' THEN o.user_id ELSE staff.user_id END
FROM (VALUES
    (1,N'PENDING_CONFIRMATION',CAST(NULL AS NVARCHAR(50))),
    (1,N'SHIPPING',N'PENDING_CONFIRMATION'),
    (1,N'COMPLETED',N'SHIPPING'),
    (2,N'PENDING_CONFIRMATION',CAST(NULL AS NVARCHAR(50))),
    (2,N'SHIPPING',N'PENDING_CONFIRMATION')
) v(order_id,status,old_status)
JOIN dbo.[ORDER] o ON o.order_id=v.order_id
CROSS JOIN (SELECT user_id FROM dbo.[USER] WHERE username='staff') staff;

INSERT INTO VOUCHER_USAGES (voucher_id, order_id, user_id)
VALUES (1, 1, 3);

INSERT INTO PRODUCT_REVIEWS (user_id, order_item_id, sku_id, rating, comment)
VALUES
(3, 1, 1, 5, N'Hàng giao cực nhanh tại Cần Thơ, đóng gói cẩn thận, máy chuẩn mới 100%!'),
(4, 2, 3, 4, N'Điện thoại mượt, camera chụp đêm rất nét nhưng pin hơi nhanh tụt.');


INSERT INTO [ORDER]
(
    user_id, address_id, total_amount, shipping_fee,
    created_at, order_status, payment_method, payment_status,
    payment_expires_at, recipient_name, recipient_phone,
    shipping_address, discount_amount, delivered_at,
    cancellation_source, cancelled_at
)
SELECT
    v.user_id,
    v.address_id,
    v.total_amount,
    v.shipping_fee,
    v.created_at,
    v.order_status,
    v.payment_method,
    v.payment_status,
    v.payment_expires_at,
    a.recipient_name,
    a.phone_number,
    a.address_line,
    v.discount_amount,
    CASE v.n
        WHEN 3 THEN CONVERT(DATETIME2,'2026-10-10T15:30:00')
        WHEN 4 THEN CONVERT(DATETIME2,'2026-08-14T14:30:00')
        WHEN 5 THEN CONVERT(DATETIME2,'2026-08-21T16:00:00')
        WHEN 11 THEN CONVERT(DATETIME2,'2026-09-17T17:00:00')
        WHEN 12 THEN CONVERT(DATETIME2,'2026-09-22T10:00:00')
        WHEN 14 THEN CONVERT(DATETIME2,'2026-10-03T10:00:00')
    END,
    CASE WHEN v.n IN (6,13) THEN 'CUSTOMER' END,
    CASE v.n WHEN 6 THEN CONVERT(DATETIME2,'2026-08-25T17:10:00')
             WHEN 13 THEN CONVERT(DATETIME2,'2026-09-25T13:00:00') END
FROM (VALUES
    (3, 3, 1, 63510000.00, 40000.00, '2026-10-08T11:30:00', 'COMPLETED', 'COD', 'PAID', NULL, 500000.00),
    (4, 4, 3, 21870000.00, 0.00, '2026-08-12T14:20:00', 'COMPLETED', 'VNPAY', 'PAID', NULL, 1000000.00),
    (5, 3, 2, 3520000.00, 30000.00, '2026-08-20T10:15:00', 'COMPLETED', 'MOMO', 'PAID', NULL, 0.00),
    (6, 4, 3, 30030000.00, 40000.00, '2026-08-25T16:40:00', 'CANCELLED', 'COD', 'CANCELLED', NULL, 0.00),
    (7, 3, 1, 17020000.00, 30000.00, '2026-09-01T08:10:00', 'PENDING_CONFIRMATION', 'COD', 'UNPAID', NULL, 0.00),
    (8, 4, 3, 30030000.00, 40000.00, '2026-09-03T11:25:00', 'CONFIRMED', 'COD', 'UNPAID', NULL, 0.00),
    (9, 3, 2, 21520000.00, 30000.00, '2026-09-05T13:45:00', 'PACKING', 'VNPAY', 'PAID', NULL, 0.00),
    (10, 4, 3, 15480000.00, 0.00, '2026-09-10T15:00:00', 'SHIPPING', 'MOMO', 'PAID', NULL, 500000.00),
    (11, 3, 1, 46520000.00, 40000.00, '2026-09-15T09:05:00', 'COMPLETED', 'VNPAY', 'PAID', NULL, 1000000.00),
    (12, 4, 3, 8320000.00, 30000.00, '2026-09-20T18:30:00', 'COMPLETED', 'COD', 'PAID', NULL, 0.00),
    (13, 3, 2, 6020000.00, 30000.00, '2026-09-25T12:15:00', 'CANCELLED', 'COD', 'CANCELLED', NULL, 0.00),
    (14, 4, 3, 10530000.00, 40000.00, '2026-10-01T20:10:00', 'COMPLETED', 'COD', 'PAID', NULL, 0.00),
    (15, 3, 1, 720000.00, 30000.00, '2026-10-03T09:00:00', 'PENDING_CONFIRMATION', 'COD', 'UNPAID', DATEADD(HOUR, 24, '2026-10-03T09:00:00'), 0.00),
    (16, 4, 3, 1520000.00, 30000.00, '2026-10-04T10:30:00', 'CONFIRMED', 'VNPAY', 'PAID', NULL, 0.00)
) v (
    n, user_id, address_id, total_amount, shipping_fee,
    created_at, order_status, payment_method, payment_status,
    payment_expires_at, discount_amount
)
JOIN ADDRESSBOOK a ON a.address_id = v.address_id;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;


INSERT INTO ORDER_ITEM (order_id, sku_id, price, quantity)
VALUES
(3, 1, 27990000, 1),
(3, 3, 29990000, 1),
(3, 11, 5990000, 1),

(4, 4, 21490000, 1),
(4, 25, 690000, 2),

(5, 12, 3490000, 1),

(6, 3, 29990000, 1),

(7, 21, 16990000, 1),

(8, 3, 29990000, 1),

(9, 4, 21490000, 1),

(10, 9, 9990000, 1),
(10, 11, 5990000, 1),

(11, 24, 45990000, 1),
(11, 26, 1490000, 1),

(12, 10, 8290000, 1),

(13, 11, 5990000, 1),

(14, 20, 10490000, 1),

(15, 25, 690000, 1),

(16, 26, 1490000, 1);


INSERT INTO dbo.ORDER_STATUS_HISTORY
    (order_id,status,old_status,updated_at,actor_type,changed_by)
SELECT v.order_id,v.status,
       LAG(v.status) OVER(PARTITION BY v.order_id ORDER BY v.updated_at,v.seq),
       v.updated_at,
       CASE WHEN v.status='PENDING_CONFIRMATION' THEN 'CUSTOMER' ELSE 'STAFF' END,
       CASE WHEN v.status='PENDING_CONFIRMATION' THEN o.user_id ELSE staff.user_id END
FROM (VALUES
    (3,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-10-08T11:30:00'),1),
    (3,N'CONFIRMED',CONVERT(DATETIME2,'2026-10-08T12:00:00'),2),
    (3,N'PACKING',CONVERT(DATETIME2,'2026-10-08T13:00:00'),3),
    (3,N'SHIPPING',CONVERT(DATETIME2,'2026-10-09T08:00:00'),4),
    (3,N'COMPLETED',CONVERT(DATETIME2,'2026-10-10T15:30:00'),5),
    (4,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-08-12T14:20:00'),6),
    (4,N'CONFIRMED',CONVERT(DATETIME2,'2026-08-12T15:00:00'),7),
    (4,N'PACKING',CONVERT(DATETIME2,'2026-08-13T09:00:00'),8),
    (4,N'SHIPPING',CONVERT(DATETIME2,'2026-08-13T16:00:00'),9),
    (4,N'COMPLETED',CONVERT(DATETIME2,'2026-08-14T14:30:00'),10),
    (5,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-08-20T10:15:00'),11),
    (5,N'CONFIRMED',CONVERT(DATETIME2,'2026-08-20T11:00:00'),12),
    (5,N'PACKING',CONVERT(DATETIME2,'2026-08-20T13:00:00'),13),
    (5,N'SHIPPING',CONVERT(DATETIME2,'2026-08-21T09:00:00'),14),
    (5,N'COMPLETED',CONVERT(DATETIME2,'2026-08-21T16:00:00'),15),
    (6,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-08-25T16:40:00'),16),
    (7,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-09-01T08:10:00'),17),
    (8,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-09-03T11:25:00'),18),
    (8,N'CONFIRMED',CONVERT(DATETIME2,'2026-09-03T13:00:00'),19),
    (9,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-09-05T13:45:00'),20),
    (9,N'CONFIRMED',CONVERT(DATETIME2,'2026-09-05T14:00:00'),21),
    (9,N'PACKING',CONVERT(DATETIME2,'2026-09-05T16:00:00'),22),
    (10,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-09-10T15:00:00'),23),
    (10,N'CONFIRMED',CONVERT(DATETIME2,'2026-09-10T16:00:00'),24),
    (10,N'PACKING',CONVERT(DATETIME2,'2026-09-11T09:00:00'),25),
    (10,N'SHIPPING',CONVERT(DATETIME2,'2026-09-11T15:00:00'),26),
    (11,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-09-15T09:05:00'),27),
    (11,N'CONFIRMED',CONVERT(DATETIME2,'2026-09-15T10:00:00'),28),
    (11,N'PACKING',CONVERT(DATETIME2,'2026-09-15T11:00:00'),29),
    (11,N'SHIPPING',CONVERT(DATETIME2,'2026-09-16T08:00:00'),30),
    (11,N'COMPLETED',CONVERT(DATETIME2,'2026-09-17T17:00:00'),31),
    (12,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-09-20T18:30:00'),32),
    (12,N'CONFIRMED',CONVERT(DATETIME2,'2026-09-20T19:00:00'),33),
    (12,N'PACKING',CONVERT(DATETIME2,'2026-09-21T08:00:00'),34),
    (12,N'SHIPPING',CONVERT(DATETIME2,'2026-09-21T15:00:00'),35),
    (12,N'COMPLETED',CONVERT(DATETIME2,'2026-09-22T10:00:00'),36),
    (13,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-09-25T12:15:00'),37),
    (14,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-10-01T20:10:00'),38),
    (14,N'CONFIRMED',CONVERT(DATETIME2,'2026-10-01T20:30:00'),39),
    (14,N'PACKING',CONVERT(DATETIME2,'2026-10-02T08:00:00'),40),
    (14,N'SHIPPING',CONVERT(DATETIME2,'2026-10-02T15:00:00'),41),
    (14,N'COMPLETED',CONVERT(DATETIME2,'2026-10-03T10:00:00'),42),
    (15,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-10-03T09:00:00'),43),
    (16,N'PENDING_CONFIRMATION',CONVERT(DATETIME2,'2026-10-04T10:30:00'),44),
    (16,N'CONFIRMED',CONVERT(DATETIME2,'2026-10-04T11:00:00'),45)
) v(order_id,status,updated_at,seq)
JOIN dbo.[ORDER] o ON o.order_id=v.order_id
CROSS JOIN (SELECT user_id FROM dbo.[USER] WHERE username='staff') staff;

GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

INSERT INTO dbo.ORDER_STATUS_HISTORY
    (order_id, status, old_status, updated_at, actor_type, changed_by, reason)
SELECT o.order_id, N'CANCELLED', N'PENDING_CONFIRMATION', v.cancelled_at, 'CUSTOMER', o.user_id,
       N'Khách hàng yêu cầu hủy đơn'
FROM (VALUES
    (6, CONVERT(DATETIME2, '2026-08-25T17:10:00')),
    (13, CONVERT(DATETIME2, '2026-09-25T13:00:00'))
) v(order_id, cancelled_at)
JOIN dbo.[ORDER] o ON o.order_id=v.order_id;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

INSERT INTO BRAND (brand_name, logo_url)
SELECT v.brand_name, v.logo_url
FROM (VALUES
    (N'Garmin', 'https://cdn.oecs.com/brands/garmin.png'),
    (N'Xiaomi', 'https://cdn.oecs.com/brands/xiaomi.png'),
    (N'Canon', 'https://cdn.oecs.com/brands/canon.png'),
    (N'Fujifilm', 'https://cdn.oecs.com/brands/fujifilm.png')
) v(brand_name, logo_url)
WHERE NOT EXISTS (
    SELECT 1
    FROM BRAND b
    WHERE b.brand_name = v.brand_name
);
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

IF NOT EXISTS (
    SELECT 1 FROM CATEGORY WHERE category_name = N'Đồng hồ thông minh'
)
    INSERT INTO CATEGORY (category_name, parent_id)
    SELECT N'Đồng hồ thông minh', category_id
    FROM CATEGORY
    WHERE category_name = N'Điện thoại & Thiết bị di động';

IF NOT EXISTS (
    SELECT 1 FROM CATEGORY WHERE category_name = N'Máy ảnh'
)
    INSERT INTO CATEGORY (category_name, parent_id)
    VALUES (N'Máy ảnh', NULL);

IF NOT EXISTS (
    SELECT 1 FROM CATEGORY WHERE category_name = N'Máy ảnh Mirrorless'
)
    INSERT INTO CATEGORY (category_name, parent_id)
    SELECT N'Máy ảnh Mirrorless', category_id
    FROM CATEGORY
    WHERE category_name = N'Máy ảnh';

IF NOT EXISTS (
    SELECT 1 FROM CATEGORY WHERE category_name = N'Máy ảnh Compact'
)
    INSERT INTO CATEGORY (category_name, parent_id)
    SELECT N'Máy ảnh Compact', category_id
    FROM CATEGORY
    WHERE category_name = N'Máy ảnh';
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

INSERT INTO PRODUCT (category_id, brand_id, product_name, description, image_url)
SELECT c.category_id, b.brand_id, v.product_name, v.description,
       CASE v.product_name
    WHEN N'iPhone 15 Pro' THEN 'assets/images/products/iphone_15_pro.png'
    WHEN N'iPhone 15 Pro Max' THEN 'assets/images/products/iphone-15-pro-max.png'
    WHEN N'iPhone 16 Pro' THEN 'assets/images/products/iphone-16-pro.png'
    WHEN N'iPhone 16 Pro Max' THEN 'assets/images/products/iphone-16-pro-max.png'
    WHEN N'Samsung Galaxy S24 Ultra' THEN 'assets/images/products/s24-ultra.jpg'
    WHEN N'Samsung Galaxy S24 Plus' THEN 'assets/images/products/s24-plus.jpg'
    WHEN N'Samsung Galaxy A55 5G' THEN 'assets/images/products/samsung-a55.jpg'
    WHEN N'Samsung Galaxy A35 5G' THEN 'assets/images/products/samsung-a35.jpg'
    WHEN N'AirPods Pro 2' THEN 'assets/images/products/airpods-pro-2.jpg'
    WHEN N'AirPods 4' THEN 'assets/images/products/airpods-4.jpg'
    WHEN N'Samsung Galaxy Buds3 Pro' THEN 'assets/images/products/galaxy-buds3-pro.jpg'
    WHEN N'Samsung Galaxy Buds FE' THEN 'assets/images/products/galaxy-buds-fe.jpg'
    WHEN N'Sony WH-1000XM5' THEN 'assets/images/products/sony-wh-1000xm5.jpg'
    WHEN N'JBL Tune 770NC' THEN 'assets/images/products/jbl-tune-770nc.jpg'
    WHEN N'Apple USB-C 20W Power Adapter' THEN 'assets/images/products/apple-20w.jpg'
    WHEN N'Samsung 25W USB-C Fast Charger' THEN 'assets/images/products/samsung-25w.jpg'
    WHEN N'Apple USB-C Charge Cable 1m' THEN 'assets/images/products/apple-cable-c2c.jpg'
    WHEN N'Apple USB-C to Lightning Cable' THEN 'assets/images/products/apple-cable-c2l.jpg'
    WHEN N'Samsung USB-C Cable 1m' THEN 'assets/images/products/samsung-cable-c2c.jpg'
    WHEN N'Lenovo IdeaPad Slim 3' THEN 'assets/images/products/lenovo-ideapad-slim-3.jpg'
    WHEN N'Lenovo ThinkBook 14' THEN 'assets/images/products/lenovo-thinkbook-14.jpg'
    WHEN N'Lenovo IdeaPad 5' THEN 'assets/images/products/lenovo-ideapad-5.jpg'
    WHEN N'Lenovo LOQ 15' THEN 'assets/images/products/lenovo-loq-15.jpg'
    WHEN N'Lenovo Legion 5' THEN 'assets/images/products/lenovo-legion-5.jpg'
    WHEN N'Lenovo Legion Pro 5' THEN 'assets/images/products/lenovo-legion-pro-5.png'
    WHEN N'Lenovo Legion M300 RGB' THEN 'assets/images/products/lenovo-m300.jpg'
    WHEN N'Lenovo Legion M600 Wireless' THEN 'assets/images/products/lenovo-m600.jpg'
    WHEN N'Lenovo Legion K300 RGB' THEN 'assets/images/products/lenovo-k300.jpg'
    WHEN N'Lenovo Go Wireless Split Keyboard' THEN 'assets/images/products/lenovo-go-split.jpg'
    WHEN N'Lenovo 300 FHD Webcam' THEN 'assets/images/products/lenovo-300-webcam.jpg'
    WHEN N'Lenovo Performance FHD Webcam' THEN 'assets/images/products/lenovo-fhd-webcam.jpg'
    WHEN N'Lenovo Laptop Backpack 15.6"' THEN 'assets/images/products/lenovo-backpack-15.jpg'
    WHEN N'Lenovo Legion Gaming Backpack' THEN 'assets/images/products/lenovo-legion-backpack.jpg'
    WHEN N'Apple Watch SE 2' THEN 'assets/images/products/apple-watch-se-2.jpg'
    WHEN N'Samsung Galaxy Watch7' THEN 'assets/images/products/galaxy-watch-7.jpg'
    WHEN N'Garmin Forerunner 165' THEN 'assets/images/products/garmin-165.jpg'
    WHEN N'Canon EOS R50' THEN 'assets/images/products/canon-eos-r50.png'
    WHEN N'Sony Alpha A6400' THEN 'assets/images/products/sony-a6400.jpg'
    WHEN N'Fujifilm X-S20' THEN 'assets/images/products/fujifilm-xs20.jpg'
END
FROM (VALUES
    (N'Đồng hồ thông minh', N'Apple', N'Apple Watch SE 2',
     N'<h2>Năng động, thông minh và thân thiện với túi tiền</h2><p><strong>Apple Watch SE 2</strong> sở hữu những tính năng cốt lõi của Apple Watch với mức giá cực kỳ dễ tiếp cận. Khung viền nhôm bền bỉ, màn hình Retina sắc nét cùng khả năng theo dõi sức khỏe toàn diện như đo nhịp tim, theo dõi giấc ngủ và phát hiện té ngã. Đây là người bạn đồng hành hoàn hảo cho cuộc sống năng động.</p><ul><li>Chip S8 mạnh mẽ, xử lý mượt mà.</li><li>Chống nước 50m, thoải mái bơi lội.</li><li>Kết nối liền mạch với hệ sinh thái Apple.</li></ul>'),

    (N'Đồng hồ thông minh', N'Samsung', N'Samsung Galaxy Watch7',
     N'<h2>Bứt phá giới hạn, thấu hiểu sức khỏe</h2><p><strong>Samsung Galaxy Watch7</strong> mang đến thiết kế mặt tròn thời thượng cùng cảm biến BioActive thế hệ mới. Đo lường chính xác các chỉ số cơ thể (BIA), theo dõi giấc ngủ chuyên sâu bằng AI và cảnh báo nhịp tim bất thường.</p><ul><li>Màn hình Super AMOLED rực rỡ dưới mọi điều kiện sáng.</li><li>Vi xử lý 3nm đầu tiên trên smartwatch.</li><li>GPS kép (L1+L5) định vị siêu chuẩn xác.</li></ul>'),

    (N'Đồng hồ thông minh', N'Garmin', N'Garmin Forerunner 165',
     N'<h2>Huấn luyện viên cá nhân trên cổ tay</h2><p><strong>Garmin Forerunner 165</strong> là chiếc đồng hồ chạy bộ chuyên nghiệp trang bị màn hình AMOLED rực rỡ. Máy cung cấp các bài tập gợi ý hàng ngày, theo dõi Pace, nhịp tim và đo lường độ phục hồi của cơ thể sau mỗi buổi tập.</p><ul><li>Thời lượng pin lên đến 11 ngày ở chế độ smartwatch.</li><li>Hơn 25 môn thể thao trong nhà và ngoài trời.</li><li>Garmin Coach: Giáo án tập luyện miễn phí.</li></ul>'),

    (N'Tai nghe', N'Sony', N'Sony WH-1000XM5',
     N'<h2>Chống ồn đỉnh cao, âm thanh tuyệt hảo</h2><p><strong>Sony WH-1000XM5</strong> hội tụ tinh hoa công nghệ âm thanh của Sony. Thiết kế mới nhẹ nhàng hơn, kết hợp 2 chip xử lý và 8 micro giúp triệt tiêu tiếng ồn môi trường một cách hoàn hảo. Màng loa 30mm tinh chỉnh đặc biệt mang lại chất âm Hi-Res cực kỳ chi tiết.</p><ul><li>Thời lượng pin 30 giờ, sạc nhanh 3 phút nghe 3 giờ.</li><li>Tính năng Speak-to-Chat thông minh.</li><li>Kết nối 2 thiết bị cùng lúc.</li></ul>'),

    (N'Tai nghe', N'JBL', N'JBL Tune 770NC',
     N'<h2>Trải nghiệm âm nhạc không giới hạn</h2><p><strong>JBL Tune 770NC</strong> nổi bật với công nghệ chống ồn chủ động (ANC) và chất âm JBL Pure Bass trứ danh. Thiết kế over-ear êm ái giúp bạn chìm đắm vào thế giới âm nhạc mà không bị xao nhãng bởi tiếng ồn xung quanh.</p><ul><li>Pin siêu khủng lên đến 70 giờ (khi tắt ANC).</li><li>Bluetooth 5.3 với LE Audio tiên tiến.</li><li>Điều chỉnh EQ qua ứng dụng JBL Headphones.</li></ul>'),

    (N'Tai nghe', N'Samsung', N'Samsung Galaxy Buds3 Pro',
     N'<h2>Âm thanh Hi-Fi không dây chân thực</h2><p><strong>Galaxy Buds3 Pro</strong> sở hữu thiết kế công thái học hoàn toàn mới có dải đèn LED độc đáo. Hỗ trợ âm thanh độ phân giải cao 24-bit/96kHz, mang lại chất âm sống động như phòng thu. Công nghệ Galaxy AI tự động tinh chỉnh chống ồn (ANC) theo môi trường.</p><ul><li>Chống ồn chủ động thông minh (Adaptive ANC).</li><li>Amply kép cho mỗi bên tai nghe.</li><li>Dịch thuật trực tiếp (Live Translate) ngay trên tai nghe.</li></ul>'),

    (N'Máy ảnh Mirrorless', N'Canon', N'Canon EOS R50',
     N'<h2>Nhỏ gọn, sáng tạo không giới hạn</h2><p><strong>Canon EOS R50</strong> là chiếc máy ảnh mirrorless APS-C lý tưởng cho người mới bắt đầu và Vlogger. Cảm biến 24.2MP kết hợp chip DIGIC X mang lại hình ảnh sắc nét, màu sắc rực rỡ đặc trưng của Canon. Khả năng lấy nét Dual Pixel CMOS AF II nhận diện thông minh chủ thể (người, động vật, xe cộ).</p><ul><li>Quay video 4K 30p không crop.</li><li>Màn hình cảm ứng xoay lật linh hoạt.</li><li>Tính năng Advanced A+ chụp đẹp mọi khoảnh khắc.</li></ul>'),

    (N'Máy ảnh Mirrorless', N'Sony', N'Sony Alpha A6400',
     N'<h2>Tốc độ bắt nét đỉnh cao</h2><p><strong>Sony Alpha A6400</strong> nổi tiếng với hệ thống lấy nét tự động siêu tốc chỉ 0.02 giây và tính năng Real-time Eye AF (lấy nét mắt theo thời gian thực). Cảm biến APS-C 24.2MP mang lại dải nhạy sáng rộng và chi tiết ấn tượng. Thân máy hợp kim magie bền bỉ, chống chịu thời tiết tốt.</p><ul><li>Quay video 4K HDR (HLG) chất lượng cao.</li><li>Màn hình lật 180 độ phù hợp quay Vlog.</li><li>Chụp liên tục 11 khung hình/giây.</li></ul>'),

    (N'Máy ảnh Mirrorless', N'Fujifilm', N'Fujifilm X-S20',
     N'<h2>Thiết kế hoài cổ, công nghệ hiện đại</h2><p><strong>Fujifilm X-S20</strong> mang đến trải nghiệm nhiếp ảnh tuyệt vời với cảm biến X-Trans CMOS 4 26.1MP. Chế độ Vlog chuyên dụng kết hợp cùng màu phim (Film Simulation) trứ danh của Fujifilm giúp bạn sáng tạo nội dung một cách đậm chất nghệ thuật ngay khi xuất hình mà không cần hậu kỳ nhiều.</p><ul><li>Chống rung IBIS 7 stops trong thân máy.</li><li>Quay video lên đến 6.2K/30p.</li><li>Pin NP-W235 dung lượng lớn, chụp 800 shot.</li></ul>')
) v(category_name, brand_name, product_name, description)
JOIN CATEGORY c ON c.category_name = v.category_name
JOIN BRAND b ON b.brand_name = v.brand_name
WHERE NOT EXISTS (
    SELECT 1
    FROM PRODUCT p
    WHERE p.product_name = v.product_name
);
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

INSERT INTO PRODUCT_SPECIFICATION (product_id, attribute_id, value)
SELECT p.product_id, a.attribute_id, v.value
FROM (VALUES
    (N'Apple Watch SE 2', N'Màn hình', N'1.78 inch Retina OLED'),
    (N'Apple Watch SE 2', N'Kết nối', N'Bluetooth, Wi-Fi, GPS'),
    (N'Apple Watch SE 2', N'Tính năng', N'Theo doi van dong, nhip tim'),
    (N'Samsung Galaxy Watch7', N'Màn hình', N'1.5 inch Super AMOLED'),
    (N'Samsung Galaxy Watch7', N'Kết nối', N'Bluetooth, Wi-Fi, GPS'),
    (N'Samsung Galaxy Watch7', N'Tính năng', N'Theo doi suc khoe va giac ngu'),
    (N'Garmin Forerunner 165', N'Màn hình', N'1.2 inch AMOLED'),
    (N'Garmin Forerunner 165', N'Kết nối', N'Bluetooth, GPS'),
    (N'Garmin Forerunner 165', N'Tính năng', N'Theo doi chay bo va luyen tap'),
    (N'Sony WH-1000XM5', N'Kết nối', N'Bluetooth, USB-C'),
    (N'Sony WH-1000XM5', N'Tính năng', N'Chong on chu dong ANC'),
    (N'Sony WH-1000XM5', N'Trọng lượng', N'250 g'),
    (N'JBL Tune 770NC', N'Kết nối', N'Bluetooth, USB-C'),
    (N'JBL Tune 770NC', N'Tính năng', N'Chong on chu dong ANC'),
    (N'JBL Tune 770NC', N'Trọng lượng', N'232 g'),
    (N'Samsung Galaxy Buds3 Pro', N'Kết nối', N'Bluetooth'),
    (N'Samsung Galaxy Buds3 Pro', N'Tính năng', N'Chong on chu dong ANC'),
    (N'Canon EOS R50', N'Độ phân giải', N'24.2 MP'),
    (N'Canon EOS R50', N'Tính năng', N'Quay video 4K, lay net tu dong'),
    (N'Canon EOS R50', N'Kết nối', N'Wi-Fi, Bluetooth'),
    (N'Sony Alpha A6400', N'Độ phân giải', N'24.2 MP'),
    (N'Sony Alpha A6400', N'Tính năng', N'Quay video 4K, lay net tu dong'),
    (N'Sony Alpha A6400', N'Kết nối', N'Wi-Fi, Bluetooth'),
    (N'Fujifilm X-S20', N'Độ phân giải', N'26.1 MP'),
    (N'Fujifilm X-S20', N'Tính năng', N'Quay video 6.2K, chong rung trong than'),
    (N'Fujifilm X-S20', N'Kết nối', N'Wi-Fi, Bluetooth')
) v(product_name, attribute_name, value)
JOIN PRODUCT p ON p.product_name = v.product_name
JOIN ATTRIBUTE a ON a.attribute_name = v.attribute_name
WHERE NOT EXISTS (
    SELECT 1
    FROM PRODUCT_SPECIFICATION ps
    WHERE ps.product_id = p.product_id
      AND ps.attribute_id = a.attribute_id
);
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

INSERT INTO PRODUCT_SKU (product_id, sku_code, price, stock_quantity)
SELECT p.product_id, v.sku_code, v.price, v.stock_quantity
FROM (VALUES
    (N'Apple Watch SE 2', 'WATCH-SE2-40', 5990000.00, 20),
    (N'Samsung Galaxy Watch7', 'WATCH-GW7-44', 6990000.00, 15),
    (N'Garmin Forerunner 165', 'WATCH-GARMIN-165', 6490000.00, 12),
    (N'Sony WH-1000XM5', 'SONY-WH1000XM5', 6990000.00, 15),
    (N'JBL Tune 770NC', 'JBL-T770NC', 2490000.00, 25),
    (N'Samsung Galaxy Buds3 Pro', 'SS-BUDS3-PRO', 4990000.00, 20),
    (N'Canon EOS R50', 'CAM-CANON-R50', 18990000.00, 8),
    (N'Sony Alpha A6400', 'CAM-SONY-A6400', 16990000.00, 6),
    (N'Fujifilm X-S20', 'CAM-FUJI-XS20', 28990000.00, 5)
) v(product_name, sku_code, price, stock_quantity)
JOIN PRODUCT p ON p.product_name = v.product_name
WHERE NOT EXISTS (
    SELECT 1
    FROM PRODUCT_SKU s
    WHERE s.sku_code = v.sku_code
);
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

INSERT INTO NOTIFICATION
    (user_id, order_id, title, message, is_read, created_at)
SELECT
    v.user_id,
    v.order_id,
    v.title,
    v.message,
    v.is_read,
    v.created_at
FROM (VALUES
    (3, 3,
     N'Đơn hàng đã được xác nhận',
     N'Đơn hàng #3 của bạn đã được xác nhận và đang được chuẩn bị.',
     0, '2026-10-08T12:00:00'),
    (3, 9,
     N'Đơn hàng đang được đóng gói',
     N'Đơn hàng #9 đã được xác nhận và đang trong quá trình đóng gói.',
     0, '2026-09-05T16:00:00'),
    (3, 11,
     N'Đơn hàng đã giao thành công',
     N'Đơn hàng #11 đã được giao thành công. Cảm ơn bạn đã mua sắm tại OECS!',
     1, '2026-09-17T17:00:00'),
    (3, 13,
     N'Đơn hàng đã bị hủy',
     N'Đơn hàng #13 của bạn đã được hủy. Nếu cần hỗ trợ, vui lòng liên hệ nhân viên OECS.',
     0, '2026-09-25T13:00:00'),
    (4, 8,
     N'Đơn hàng đã được xác nhận',
     N'Đơn hàng #8 của bạn đã được xác nhận. Chúng tôi sẽ sớm chuẩn bị hàng.',
     1, '2026-09-03T13:00:00'),
    (4, 10,
     N'Đơn hàng đang được vận chuyển',
     N'Đơn hàng #10 đã được bàn giao cho đơn vị vận chuyển. Vui lòng chú ý điện thoại để nhận hàng.',
     0, '2026-09-11T15:00:00'),
    (4, 12,
     N'Đơn hàng đã giao thành công',
     N'Đơn hàng #12 đã được giao thành công. Cảm ơn bạn đã tin tưởng OECS!',
     0, '2026-09-22T10:00:00'),
    (4, 14,
     N'Đơn hàng đã hoàn tất',
     N'Đơn hàng #14 đã hoàn tất. Hy vọng bạn hài lòng với sản phẩm!',
     1, '2026-10-03T10:00:00')
) v(user_id, order_id, title, message, is_read, created_at)
WHERE NOT EXISTS (
    SELECT 1
    FROM NOTIFICATION n
    WHERE n.user_id = v.user_id
      AND (
          n.order_id = v.order_id
          OR (n.order_id IS NULL AND v.order_id IS NULL)
      )
      AND n.title = v.title
      AND n.message = v.message
);
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;




BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @PhoneVariants TABLE (
        sku_code VARCHAR(100),
        attribute_name NVARCHAR(100),
        attribute_value NVARCHAR(255)
    );

    INSERT INTO @PhoneVariants VALUES
        ('IP15P-128-BLK', N'Dung lượng lưu trữ', N'128GB'),
        ('IP15P-128-BLK', N'Màu sắc', N'Đen'),

        ('IP15P-256-SLV', N'Dung lượng lưu trữ', N'256GB'),
        ('IP15P-256-SLV', N'Màu sắc', N'Bạc'),

        ('SS-S24U-256-GRY', N'Dung lượng lưu trữ', N'256GB'),
        ('SS-S24U-256-GRY', N'Màu sắc', N'Xám'),

        ('IP15PM-256-NAT', N'Dung lượng lưu trữ', N'256GB'),
        ('IP15PM-256-NAT', N'Màu sắc', N'Titan tự nhiên'),

        ('IP16P-128-BLK', N'Dung lượng lưu trữ', N'128GB'),
        ('IP16P-128-BLK', N'Màu sắc', N'Đen'),

        ('IP16PM-256-DES', N'Dung lượng lưu trữ', N'256GB'),
        ('IP16PM-256-DES', N'Màu sắc', N'Titan sa mạc'),

        ('SS-S24P-256-BLK', N'Dung lượng lưu trữ', N'256GB'),
        ('SS-S24P-256-BLK', N'Màu sắc', N'Đen'),

        ('SS-A55-128-BLU', N'Dung lượng lưu trữ', N'128GB'),
        ('SS-A55-128-BLU', N'Màu sắc', N'Xanh'),

        ('SS-A35-128-YLW', N'Dung lượng lưu trữ', N'128GB'),
        ('SS-A35-128-YLW', N'Màu sắc', N'Vàng');


    INSERT INTO dbo.SKU_ATTRIBUTE_VALUE (
        sku_id, attribute_id, text_value
    )
    SELECT
        s.sku_id,
        a.attribute_id,
        v.attribute_value
    FROM @PhoneVariants v
    JOIN dbo.PRODUCT_SKU s
        ON s.sku_code = v.sku_code
    JOIN dbo.ATTRIBUTE a
        ON a.attribute_name = v.attribute_name
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.SKU_ATTRIBUTE_VALUE sav
        WHERE sav.sku_id = s.sku_id
          AND sav.attribute_id = a.attribute_id
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;



BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.SKU_ATTRIBUTE_VALUE (
        sku_id,
        attribute_id,
        text_value
    )
    SELECT
        s.sku_id,
        ps.attribute_id,
        ps.value
    FROM dbo.PRODUCT_SKU s
    JOIN dbo.PRODUCT p
        ON p.product_id = s.product_id
    JOIN dbo.CATEGORY c
        ON c.category_id = p.category_id
    JOIN dbo.PRODUCT_SPECIFICATION ps
        ON ps.product_id = p.product_id
    JOIN dbo.ATTRIBUTE a
        ON a.attribute_id = ps.attribute_id
    WHERE c.category_name IN (
        N'Laptop Văn Phòng',
        N'Laptop Gaming'
    )
      AND a.attribute_name = N'RAM'
      AND NOT EXISTS (
          SELECT 1
          FROM dbo.SKU_ATTRIBUTE_VALUE sav
          WHERE sav.sku_id = s.sku_id
            AND sav.attribute_id = ps.attribute_id
      );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;



BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.SKU_ATTRIBUTE_VALUE (
        sku_id,
        attribute_id,
        text_value
    )
    SELECT
        s.sku_id,
        a.attribute_id,
        N'512GB'
    FROM dbo.PRODUCT_SKU s
    JOIN dbo.ATTRIBUTE a
        ON a.attribute_name = N'Dung lượng lưu trữ'
    WHERE s.sku_code = 'LOQ-15-16GB-512GB'
      AND NOT EXISTS (
          SELECT 1
          FROM dbo.SKU_ATTRIBUTE_VALUE sav
          WHERE sav.sku_id = s.sku_id
            AND sav.attribute_id = a.attribute_id
      );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;


BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.PRODUCT_IMAGES (
        product_id,
        sku_id,
        image_url,
        is_primary,
        display_order,
        alt_text
    )
    SELECT
        p.product_id,
        NULL,
        p.image_url,
        1,
        0,
        p.product_name
    FROM dbo.PRODUCT p
    WHERE p.image_url IS NOT NULL
      AND LEN(LTRIM(RTRIM(p.image_url))) > 0
      AND NOT EXISTS (
          SELECT 1
          FROM dbo.PRODUCT_IMAGES pi
          WHERE pi.product_id = p.product_id
            AND pi.sku_id IS NULL
            AND pi.image_url = p.image_url
      );


    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;




SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.CATEGORY_ATTRIBUTE', N'U') IS NULL
       OR OBJECT_ID(N'dbo.SKU_ATTRIBUTE_VALUE', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PRODUCT_SKU', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PRODUCT', N'U') IS NULL
       OR OBJECT_ID(N'dbo.ATTRIBUTE', N'U') IS NULL
        THROW 55100, N'Thieu mot hoac nhieu bang catalog/SKU.', 1;

    DECLARE @SkuBefore BIGINT = (SELECT COUNT_BIG(*) FROM dbo.PRODUCT_SKU);
    DECLARE @Inserted BIGINT = 0;
    DECLARE @AddedAttributeRows BIGINT = 0;

    DECLARE @Seed TABLE (
        product_name NVARCHAR(255) NOT NULL,
        sku_code VARCHAR(100) NOT NULL PRIMARY KEY,
        price DECIMAL(18,2) NOT NULL,
        initial_stock INT NOT NULL,
        attr1 NVARCHAR(100) NULL, val1 NVARCHAR(255) NULL,
        attr2 NVARCHAR(100) NULL, val2 NVARCHAR(255) NULL,
        attr3 NVARCHAR(100) NULL, val3 NVARCHAR(255) NULL
    );

    INSERT INTO @Seed (
        product_name, sku_code, price, initial_stock,
        attr1, val1, attr2, val2, attr3, val3
    ) VALUES
    (N'iPhone 15 Pro', 'IP15P-128-BLK', 27990000, 15, N'Dung lượng lưu trữ', N'128GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'iPhone 15 Pro', 'IP15P-128-SLV', 27990000, 18, N'Dung lượng lưu trữ', N'128GB', N'Màu sắc', N'Bạc', NULL, NULL),
    (N'iPhone 15 Pro', 'IP15P-256-BLK', 30990000, 16, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'iPhone 15 Pro', 'IP15P-256-SLV', 30990000, 10, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Bạc', NULL, NULL),
    (N'iPhone 15 Pro', 'IP15P-512-BLK', 34490000, 12, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'iPhone 15 Pro', 'IP15P-512-SLV', 34490000, 10, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Bạc', NULL, NULL),

    (N'iPhone 15 Pro Max', 'IP15PM-256-NAT', 33990000, 12, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Titan tự nhiên', NULL, NULL),
    (N'iPhone 15 Pro Max', 'IP15PM-256-BLK', 33990000, 18, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Titan đen', NULL, NULL),
    (N'iPhone 15 Pro Max', 'IP15PM-512-NAT', 36990000, 16, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Titan tự nhiên', NULL, NULL),
    (N'iPhone 15 Pro Max', 'IP15PM-512-BLK', 36990000, 14, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Titan đen', NULL, NULL),
    (N'iPhone 15 Pro Max', 'IP15PM-1T-NAT', 40990000, 12, N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Titan tự nhiên', NULL, NULL),
    (N'iPhone 15 Pro Max', 'IP15PM-1T-BLK', 40990000, 10, N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Titan đen', NULL, NULL),

    (N'iPhone 16 Pro', 'IP16P-128-BLK', 28990000, 20, N'Dung lượng lưu trữ', N'128GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'iPhone 16 Pro', 'IP16P-128-WHT', 28990000, 18, N'Dung lượng lưu trữ', N'128GB', N'Màu sắc', N'Trắng', NULL, NULL),
    (N'iPhone 16 Pro', 'IP16P-256-BLK', 32990000, 16, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'iPhone 16 Pro', 'IP16P-256-WHT', 32990000, 14, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Trắng', NULL, NULL),
    (N'iPhone 16 Pro', 'IP16P-512-BLK', 36990000, 12, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'iPhone 16 Pro', 'IP16P-512-WHT', 36990000, 10, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Trắng', NULL, NULL),

    (N'iPhone 16 Pro Max', 'IP16PM-256-DES', 34990000, 25, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Titan sa mạc', NULL, NULL),
    (N'iPhone 16 Pro Max', 'IP16PM-256-BLK', 34990000, 18, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Titan đen', NULL, NULL),
    (N'iPhone 16 Pro Max', 'IP16PM-512-DES', 38990000, 16, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Titan sa mạc', NULL, NULL),
    (N'iPhone 16 Pro Max', 'IP16PM-512-BLK', 38990000, 14, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Titan đen', NULL, NULL),
    (N'iPhone 16 Pro Max', 'IP16PM-1T-DES', 42990000, 12, N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Titan sa mạc', NULL, NULL),
    (N'iPhone 16 Pro Max', 'IP16PM-1T-BLK', 42990000, 10, N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Titan đen', NULL, NULL),

    (N'Samsung Galaxy S24 Ultra', 'SS-S24U-256-GRY', 29990000, 20, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Xám', NULL, NULL),
    (N'Samsung Galaxy S24 Ultra', 'SS-S24U-256-BLK', 29990000, 18, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'Samsung Galaxy S24 Ultra', 'SS-S24U-512-GRY', 33490000, 16, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám', NULL, NULL),
    (N'Samsung Galaxy S24 Ultra', 'SS-S24U-512-BLK', 33490000, 14, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'Samsung Galaxy S24 Ultra', 'SS-S24U-1T-GRY', 37990000, 12, N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám', NULL, NULL),
    (N'Samsung Galaxy S24 Ultra', 'SS-S24U-1T-BLK', 37990000, 10, N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Đen', NULL, NULL),

    (N'Samsung Galaxy S24 Plus', 'SS-S24P-256-BLK', 25990000, 15, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'Samsung Galaxy S24 Plus', 'SS-S24P-256-VIO', 25990000, 18, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Tím', NULL, NULL),
    (N'Samsung Galaxy S24 Plus', 'SS-S24P-512-BLK', 28990000, 16, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'Samsung Galaxy S24 Plus', 'SS-S24P-512-VIO', 28990000, 14, N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Tím', NULL, NULL),

    (N'Samsung Galaxy A55 5G', 'SS-A55-128-BLU', 9990000, 30, N'Dung lượng lưu trữ', N'128GB', N'Màu sắc', N'Xanh', NULL, NULL),
    (N'Samsung Galaxy A55 5G', 'SS-A55-128-BLK', 9990000, 18, N'Dung lượng lưu trữ', N'128GB', N'Màu sắc', N'Đen', NULL, NULL),
    (N'Samsung Galaxy A55 5G', 'SS-A55-256-BLU', 10990000, 16, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Xanh', NULL, NULL),
    (N'Samsung Galaxy A55 5G', 'SS-A55-256-BLK', 10990000, 14, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Đen', NULL, NULL),

    (N'Samsung Galaxy A35 5G', 'SS-A35-128-YLW', 8290000, 35, N'Dung lượng lưu trữ', N'128GB', N'Màu sắc', N'Vàng', NULL, NULL),
    (N'Samsung Galaxy A35 5G', 'SS-A35-128-BLU', 8290000, 18, N'Dung lượng lưu trữ', N'128GB', N'Màu sắc', N'Xanh', NULL, NULL),
    (N'Samsung Galaxy A35 5G', 'SS-A35-256-YLW', 9290000, 16, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Vàng', NULL, NULL),
    (N'Samsung Galaxy A35 5G', 'SS-A35-256-BLU', 9290000, 14, N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Xanh', NULL, NULL),

    (N'AirPods Pro 2', 'APP-AP2-WHT', 5990000, 50, N'Phiên bản', N'Hộp Lightning', N'Màu sắc', N'Trắng', NULL, NULL),
    (N'AirPods Pro 2', 'APP-AP2-USBC', 6390000, 18, N'Phiên bản', N'Hộp USB-C', N'Màu sắc', N'Trắng', NULL, NULL),

    (N'AirPods 4', 'APP-AP4-WHT', 3490000, 45, N'Phiên bản', N'Tiêu chuẩn', N'Màu sắc', N'Trắng', NULL, NULL),
    (N'AirPods 4', 'APP-AP4-ANC', 4490000, 24, N'Phiên bản', N'Chống ồn ANC', N'Màu sắc', N'Trắng', NULL, NULL),

    (N'Samsung Galaxy Buds3 Pro', 'SS-B3P-SLV', 4990000, 40, N'Màu sắc', N'Bạc', NULL, NULL, NULL, NULL),
    (N'Samsung Galaxy Buds3 Pro', 'SS-BUDS3-PRO', 4990000, 20, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Samsung Galaxy Buds FE', 'SS-BFE-BLK', 1990000, 60, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Samsung Galaxy Buds FE', 'SS-BFE-WHT', 1990000, 25, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Sony WH-1000XM5', 'SONY-WH1000XM5', 6990000, 15, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Sony WH-1000XM5', 'SONY-WH1000XM5-SLV', 6990000, 12, N'Màu sắc', N'Bạc', NULL, NULL, NULL, NULL),

    (N'JBL Tune 770NC', 'JBL-T770NC', 2490000, 25, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'JBL Tune 770NC', 'JBL-T770NC-WHT', 2490000, 18, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Apple USB-C 20W Power Adapter', 'APP-20W-WHT', 550000, 100, N'Gói bán', N'1 củ sạc', NULL, NULL, NULL, NULL),
    (N'Apple USB-C 20W Power Adapter', 'APP-20W-2PACK', 1050000, 20, N'Gói bán', N'Bộ 2 củ sạc', NULL, NULL, NULL, NULL),

    (N'Samsung 25W USB-C Fast Charger', 'SS-25W-BLK', 390000, 100, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Samsung 25W USB-C Fast Charger', 'SS-25W-WHT', 390000, 32, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Apple USB-C Charge Cable 1m', 'APP-C2C-1M', 450000, 80, N'Gói bán', N'1 dây', NULL, NULL, NULL, NULL),
    (N'Apple USB-C Charge Cable 1m', 'APP-C2C-1M-2PK', 850000, 25, N'Gói bán', N'Bộ 2 dây', NULL, NULL, NULL, NULL),

    (N'Apple USB-C to Lightning Cable', 'APP-C2L-1M', 490000, 80, N'Chiều dài', N'1m', NULL, NULL, NULL, NULL),
    (N'Apple USB-C to Lightning Cable', 'APP-C2L-2M', 790000, 15, N'Chiều dài', N'2m', NULL, NULL, NULL, NULL),

    (N'Samsung USB-C Cable 1m', 'SS-C2C-1M', 250000, 90, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Samsung USB-C Cable 1m', 'SS-C2C-1M-WHT', 250000, 45, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Lenovo IdeaPad Slim 3', 'LEN-IDP3-I3', 10490000, 12, N'RAM', N'8GB DDR4', N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Xám'),
    (N'Lenovo IdeaPad Slim 3', 'LEN-IDP3-8GB-512GB', 11590000, 8, N'RAM', N'8GB DDR4', N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám'),
    (N'Lenovo IdeaPad Slim 3', 'LEN-IDP3-16GB-256GB', 11990000, 7, N'RAM', N'16GB DDR4', N'Dung lượng lưu trữ', N'256GB', N'Màu sắc', N'Xám'),
    (N'Lenovo IdeaPad Slim 3', 'LEN-IDP3-16GB-512GB', 13090000, 6, N'RAM', N'16GB DDR4', N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám'),

    (N'Lenovo ThinkBook 14', 'LEN-TB14-I5', 16990000, 12, N'RAM', N'16GB DDR5', N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám'),
    (N'Lenovo ThinkBook 14', 'LEN-TB14-16GB-1TB', 18990000, 8, N'RAM', N'16GB DDR5', N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám'),
    (N'Lenovo ThinkBook 14', 'LEN-TB14-32GB-512GB', 20990000, 7, N'RAM', N'32GB DDR5', N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám'),
    (N'Lenovo ThinkBook 14', 'LEN-TB14-32GB-1TB', 22990000, 6, N'RAM', N'32GB DDR5', N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám'),

    (N'Lenovo IdeaPad 5', 'LEN-IDP5-R5', 14490000, 12, N'RAM', N'16GB DDR4', N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám'),
    (N'Lenovo IdeaPad 5', 'LEN-IDP5-16GB-1TB', 16490000, 8, N'RAM', N'16GB DDR4', N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám'),
    (N'Lenovo IdeaPad 5', 'LEN-IDP5-32GB-512GB', 18490000, 7, N'RAM', N'32GB DDR4', N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám'),
    (N'Lenovo IdeaPad 5', 'LEN-IDP5-32GB-1TB', 20490000, 6, N'RAM', N'32GB DDR4', N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám'),

    (N'Lenovo LOQ 15', 'LOQ-15-16GB-512GB', 21490000, 12, N'RAM', N'16GB DDR5', N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám'),
    (N'Lenovo LOQ 15', 'LOQ-15-16GB-1TB', 24490000, 8, N'RAM', N'16GB DDR5', N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám'),
    (N'Lenovo LOQ 15', 'LOQ-15-32GB-512GB', 25490000, 7, N'RAM', N'32GB DDR5', N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám'),
    (N'Lenovo LOQ 15', 'LOQ-15-32GB-1TB', 28490000, 6, N'RAM', N'32GB DDR5', N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám'),

    (N'Lenovo Legion 5', 'LEN-LEG5-R7', 32990000, 12, N'RAM', N'16GB DDR5', N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám'),
    (N'Lenovo Legion 5', 'LEN-LEG5-16GB-1TB', 35990000, 8, N'RAM', N'16GB DDR5', N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám'),
    (N'Lenovo Legion 5', 'LEN-LEG5-32GB-512GB', 36990000, 7, N'RAM', N'32GB DDR5', N'Dung lượng lưu trữ', N'512GB', N'Màu sắc', N'Xám'),
    (N'Lenovo Legion 5', 'LEN-LEG5-32GB-1TB', 39990000, 6, N'RAM', N'32GB DDR5', N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám'),

    (N'Lenovo Legion Pro 5', 'LEN-LEG5P-I9', 45990000, 12, N'RAM', N'32GB DDR5', N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám'),
    (N'Lenovo Legion Pro 5', 'LEN-LEG5P-32GB-2TB', 50990000, 8, N'RAM', N'32GB DDR5', N'Dung lượng lưu trữ', N'2TB', N'Màu sắc', N'Xám'),
    (N'Lenovo Legion Pro 5', 'LEN-LEG5P-64GB-1TB', 51990000, 7, N'RAM', N'64GB DDR5', N'Dung lượng lưu trữ', N'1TB', N'Màu sắc', N'Xám'),
    (N'Lenovo Legion Pro 5', 'LEN-LEG5P-64GB-2TB', 56990000, 6, N'RAM', N'64GB DDR5', N'Dung lượng lưu trữ', N'2TB', N'Màu sắc', N'Xám'),

    (N'Lenovo Legion M300 RGB', 'LEN-M300-BLK', 690000, 30, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Lenovo Legion M300 RGB', 'LEN-M300-WHT', 690000, 14, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Lenovo Legion M600 Wireless', 'LEN-M600-BLK', 1490000, 30, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Lenovo Legion M600 Wireless', 'LEN-M600-WHT', 1490000, 14, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Lenovo Legion K300 RGB', 'LEN-K300-BLK', 890000, 30, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Lenovo Legion K300 RGB', 'LEN-K300-WHT', 890000, 14, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Lenovo Go Wireless Split Keyboard', 'LEN-GOW-GRY', 1990000, 30, N'Màu sắc', N'Xám', NULL, NULL, NULL, NULL),
    (N'Lenovo Go Wireless Split Keyboard', 'LEN-GOW-BLK', 1990000, 14, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),

    (N'Lenovo 300 FHD Webcam', 'LEN-W300-BLK', 750000, 30, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Lenovo 300 FHD Webcam', 'LEN-W300-WHT', 750000, 14, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Lenovo Performance FHD Webcam', 'LEN-WPF-BLK', 1250000, 30, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Lenovo Performance FHD Webcam', 'LEN-WPF-WHT', 1250000, 14, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Lenovo Laptop Backpack 15.6"', 'LEN-BP15-BLK', 450000, 30, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Lenovo Laptop Backpack 15.6"', 'LEN-BP15-BLU', 450000, 14, N'Màu sắc', N'Xanh', NULL, NULL, NULL, NULL),

    (N'Lenovo Legion Gaming Backpack', 'LEN-BPG17-BLK', 890000, 30, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Lenovo Legion Gaming Backpack', 'LEN-BPG17-GRY', 890000, 14, N'Màu sắc', N'Xám', NULL, NULL, NULL, NULL),

    (N'Apple Watch SE 2', 'WATCH-SE2-40', 5990000, 20, N'Kích thước vỏ', N'40mm', N'Màu sắc', N'Đen', NULL, NULL),
    (N'Apple Watch SE 2', 'WATCH-SE2-40-SLV', 5990000, 9, N'Kích thước vỏ', N'40mm', N'Màu sắc', N'Bạc', NULL, NULL),
    (N'Apple Watch SE 2', 'WATCH-SE2-44-BLK', 6490000, 13, N'Kích thước vỏ', N'44mm', N'Màu sắc', N'Đen', NULL, NULL),
    (N'Apple Watch SE 2', 'WATCH-SE2-44-SLV', 6490000, 8, N'Kích thước vỏ', N'44mm', N'Màu sắc', N'Bạc', NULL, NULL),

    (N'Samsung Galaxy Watch7', 'WATCH-GW7-44', 6990000, 15, N'Kích thước vỏ', N'44mm', N'Màu sắc', N'Bạc', NULL, NULL),
    (N'Samsung Galaxy Watch7', 'WATCH-GW7-40-SLV', 6490000, 12, N'Kích thước vỏ', N'40mm', N'Màu sắc', N'Bạc', NULL, NULL),
    (N'Samsung Galaxy Watch7', 'WATCH-GW7-40-GRN', 6490000, 9, N'Kích thước vỏ', N'40mm', N'Màu sắc', N'Xanh', NULL, NULL),
    (N'Samsung Galaxy Watch7', 'WATCH-GW7-44-GRN', 6990000, 10, N'Kích thước vỏ', N'44mm', N'Màu sắc', N'Xanh', NULL, NULL),

    (N'Garmin Forerunner 165', 'WATCH-GARMIN-165', 6490000, 12, N'Màu sắc', N'Đen', NULL, NULL, NULL, NULL),
    (N'Garmin Forerunner 165', 'WATCH-GARMIN-165-WHT', 6490000, 7, N'Màu sắc', N'Trắng', NULL, NULL, NULL, NULL),

    (N'Canon EOS R50', 'CAM-CANON-R50', 18990000, 8, N'Bộ sản phẩm', N'Máy ảnh không kèm ống kính', NULL, NULL, NULL, NULL),
    (N'Canon EOS R50', 'CAM-CANON-R50-KIT1845', 21990000, 5, N'Bộ sản phẩm', N'Kit RF-S 18-45mm', NULL, NULL, NULL, NULL),

    (N'Sony Alpha A6400', 'CAM-SONY-A6400', 16990000, 6, N'Bộ sản phẩm', N'Máy ảnh không kèm ống kính', NULL, NULL, NULL, NULL),
    (N'Sony Alpha A6400', 'CAM-SONY-A6400-KIT1650', 19990000, 4, N'Bộ sản phẩm', N'Kit E PZ 16-50mm', NULL, NULL, NULL, NULL),

    (N'Fujifilm X-S20', 'CAM-FUJI-XS20', 28990000, 5, N'Bộ sản phẩm', N'Máy ảnh không kèm ống kính', NULL, NULL, NULL, NULL),
    (N'Fujifilm X-S20', 'CAM-FUJI-XS20-KIT1545', 31990000, 4, N'Bộ sản phẩm', N'Kit XC 15-45mm', NULL, NULL, NULL, NULL);

    IF (SELECT COUNT(DISTINCT product_name) FROM @Seed) <> 39
        THROW 55101, N'Du lieu seed khong du 39 san pham.', 1;

    IF EXISTS (
        SELECT 1 FROM @Seed AS v
        LEFT JOIN dbo.PRODUCT AS p ON p.product_name = v.product_name
        WHERE p.product_id IS NULL
    )
        THROW 55102, N'Co ten san pham seed khong ton tai trong dbo.PRODUCT. Xem danh sach 39 san pham.', 1;

    IF EXISTS (
        SELECT v.product_name
        FROM @Seed AS v JOIN dbo.PRODUCT p ON p.product_name = v.product_name
        GROUP BY v.product_name HAVING COUNT(DISTINCT p.product_id) > 1
    )
        THROW 55103, N'Ten san pham khong duy nhat. Khong the tu ghep SKU an toan.', 1;

    IF EXISTS (
        SELECT 1 FROM @Seed v
        JOIN dbo.PRODUCT_SKU s ON s.sku_code = v.sku_code
        JOIN dbo.PRODUCT p ON p.product_id = s.product_id
        WHERE p.product_name <> v.product_name
    )
        THROW 55104, N'Ma SKU da duoc dung boi san pham khac.', 1;

    IF EXISTS (SELECT 1 FROM @Seed WHERE price <= 0 OR initial_stock < 0)
        THROW 55105, N'Gia SKU phai duong va ton kho khong am.', 1;

    INSERT INTO dbo.ATTRIBUTE (attribute_name)
    SELECT DISTINCT option_name FROM @Seed AS v
    CROSS APPLY (VALUES (v.attr1), (v.attr2), (v.attr3)) AS x(option_name)
    WHERE x.option_name IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM dbo.ATTRIBUTE a
          WHERE a.attribute_name = x.option_name
      );

    IF EXISTS (
        SELECT a.attribute_name
        FROM dbo.ATTRIBUTE AS a
        WHERE a.attribute_name IN (
            SELECT option_name FROM @Seed v
            CROSS APPLY (VALUES (v.attr1), (v.attr2), (v.attr3)) AS x(option_name)
            WHERE x.option_name IS NOT NULL
        )
        GROUP BY a.attribute_name HAVING COUNT(*) > 1
    )
        THROW 55106, N'Trung ten ATTRIBUTE trong database. Can xu ly thu cong.', 1;

    DECLARE @Options TABLE (
        sku_code VARCHAR(100) NOT NULL,
        attribute_id INT NOT NULL,
        attribute_value NVARCHAR(255) NOT NULL,
        text_value NVARCHAR(255) NULL,
        numeric_value DECIMAL(18,4) NULL,
        boolean_value BIT NULL,
        PRIMARY KEY (sku_code, attribute_id)
    );

    INSERT INTO @Options (
        sku_code, attribute_id, attribute_value,
        text_value, numeric_value, boolean_value
    )
    SELECT
        v.sku_code, a.attribute_id, x.option_value,
        CASE
            WHEN oldval.sku_id IS NOT NULL THEN oldval.text_value
            WHEN numeric_mode.use_numeric = 1 THEN NULL
            ELSE x.option_value
        END,
        CASE
            WHEN oldval.sku_id IS NOT NULL THEN oldval.numeric_value
            WHEN numeric_mode.use_numeric = 1 THEN parsed.numeric_number
            ELSE NULL
        END,
        CASE
            WHEN oldval.sku_id IS NOT NULL THEN oldval.boolean_value
            ELSE NULL
        END
    FROM @Seed AS v
    CROSS APPLY (VALUES
        (v.attr1, v.val1),
        (v.attr2, v.val2),
        (v.attr3, v.val3)
    ) AS x(option_name, option_value)
    JOIN dbo.ATTRIBUTE AS a ON a.attribute_name = x.option_name
    LEFT JOIN dbo.PRODUCT_SKU AS oldsku
        ON oldsku.sku_code = v.sku_code
    LEFT JOIN dbo.SKU_ATTRIBUTE_VALUE AS oldval
        ON oldval.sku_id = oldsku.sku_id
       AND oldval.attribute_id = a.attribute_id
    CROSS APPLY (
        SELECT LTRIM(RTRIM(x.option_value)) AS cleaned
    ) AS cleaned
    CROSS APPLY (
        SELECT TRY_CONVERT(DECIMAL(18,4),
            LEFT(cleaned.cleaned,
                PATINDEX('%[^0-9.]%', cleaned.cleaned + N'X') - 1)
        ) AS leading_number
    ) AS leading
    CROSS APPLY (
        SELECT CAST(
          CASE
            WHEN a.attribute_name = N'Dung lượng lưu trữ'
             AND UPPER(cleaned.cleaned) LIKE N'%TB'
             AND UPPER(COALESCE(a.unit, N'GB')) <> N'TB'
            THEN leading.leading_number * 1024
            ELSE leading.leading_number
          END AS DECIMAL(18,4)
        ) AS numeric_number
    ) AS parsed
    CROSS APPLY (
        SELECT CASE
            WHEN parsed.numeric_number IS NOT NULL AND (
               a.data_type = 'NUMBER'
               OR EXISTS (
                   SELECT 1 FROM dbo.SKU_ATTRIBUTE_VALUE AS oldnumeric
                   WHERE oldnumeric.attribute_id = a.attribute_id
                     AND oldnumeric.numeric_value IS NOT NULL
               )
            ) THEN 1 ELSE 0
        END AS use_numeric
    ) AS numeric_mode
    WHERE x.option_name IS NOT NULL;

    IF EXISTS (
        SELECT 1 FROM @Options
        WHERE (CASE WHEN text_value IS NOT NULL THEN 1 ELSE 0 END)
            + (CASE WHEN numeric_value IS NOT NULL THEN 1 ELSE 0 END)
            + (CASE WHEN boolean_value IS NOT NULL THEN 1 ELSE 0 END) <> 1
    )
        THROW 55111, N'Khong the chuan hoa mot gia tri bien the.', 1;

    IF EXISTS (
        SELECT 1 FROM @Seed v
        WHERE NOT EXISTS (SELECT 1 FROM @Options o WHERE o.sku_code=v.sku_code)
    )
        THROW 55107, N'Mot SKU khong co thuoc tinh bien the.', 1;

    INSERT INTO dbo.SKU_ATTRIBUTE_VALUE (
        sku_id, attribute_id, text_value, numeric_value, boolean_value
    )
    SELECT s.sku_id, o.attribute_id,
           o.text_value, o.numeric_value, o.boolean_value
    FROM dbo.PRODUCT_SKU s
    JOIN @Options o ON o.sku_code=s.sku_code
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.SKU_ATTRIBUTE_VALUE sav
        WHERE sav.sku_id=s.sku_id AND sav.attribute_id=o.attribute_id
    );
    SET @AddedAttributeRows = @@ROWCOUNT;


    DECLARE @Expected TABLE (
        sku_code VARCHAR(100) NOT NULL PRIMARY KEY,
        product_id INT NOT NULL,
        expected_key VARBINARY(32) NOT NULL
    );

    INSERT INTO @Expected (sku_code, product_id, expected_key)
    SELECT v.sku_code, p.product_id,
           HASHBYTES('SHA2_256', x.variant_text)
    FROM @Seed v
    JOIN dbo.PRODUCT p ON p.product_name=v.product_name
    CROSS APPLY (
        SELECT STRING_AGG(
            CAST(CONCAT(o.attribute_id, N'=',
                CASE
                    WHEN o.text_value IS NOT NULL
                      THEN N'T:' + UPPER(LTRIM(RTRIM(o.text_value)))
                    WHEN o.numeric_value IS NOT NULL
                      THEN N'N:' + CONVERT(NVARCHAR(60),o.numeric_value)
                    ELSE N'B:' + CONVERT(NVARCHAR(1),o.boolean_value)
                END
            ) AS NVARCHAR(MAX)), N'|')
            WITHIN GROUP (ORDER BY o.attribute_id) AS variant_text
        FROM @Options o
        WHERE o.sku_code=v.sku_code
    ) x;

    IF EXISTS (
        SELECT 1 FROM @Expected
        GROUP BY product_id, expected_key HAVING COUNT(*) > 1
    )
        THROW 55109, N'Bo seed co hai SKU cung to hop bien the.', 1;

    DECLARE @SkippedVariants TABLE (
        proposed_code VARCHAR(100) NOT NULL,
        existing_code VARCHAR(100) NOT NULL,
        product_id INT NOT NULL
    );

    INSERT INTO @SkippedVariants (proposed_code, existing_code, product_id)
    SELECT e.sku_code, existing_sku.sku_code, e.product_id
    FROM @Expected e
    JOIN dbo.PRODUCT_SKU existing_sku
      ON existing_sku.product_id=e.product_id
     AND existing_sku.variant_key=e.expected_key
     AND existing_sku.sku_code<>e.sku_code
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.PRODUCT_SKU s WHERE s.sku_code=e.sku_code
    );

    INSERT INTO dbo.PRODUCT_SKU (
        product_id, sku_code, price, stock_quantity, original_price, is_active, variant_key
    )
    SELECT e.product_id, v.sku_code, v.price, v.initial_stock, NULL, 1, e.expected_key
    FROM @Seed v
    JOIN @Expected e ON e.sku_code=v.sku_code
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.PRODUCT_SKU s WHERE s.sku_code=v.sku_code
    )
      AND NOT EXISTS (
        SELECT 1 FROM @SkippedVariants x WHERE x.proposed_code=v.sku_code
    );
    SET @Inserted = @@ROWCOUNT;

    INSERT INTO dbo.SKU_ATTRIBUTE_VALUE (
        sku_id, attribute_id, text_value, numeric_value, boolean_value
    )
    SELECT s.sku_id, o.attribute_id,
           o.text_value, o.numeric_value, o.boolean_value
    FROM dbo.PRODUCT_SKU s
    JOIN @Options o ON o.sku_code=s.sku_code
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.SKU_ATTRIBUTE_VALUE sav
        WHERE sav.sku_id=s.sku_id AND sav.attribute_id=o.attribute_id
    );


    IF EXISTS (
        SELECT 1 FROM (SELECT DISTINCT product_name FROM @Seed) v
        JOIN dbo.PRODUCT p ON p.product_name=v.product_name
        OUTER APPLY (
            SELECT COUNT(*) AS variants FROM dbo.PRODUCT_SKU s
            WHERE s.product_id=p.product_id AND s.is_active=1
        ) x
        WHERE x.variants < 2
    )
        THROW 55110, N'Mot trong 39 san pham co duoi 2 SKU dang kinh doanh.', 1;

    COMMIT TRANSACTION;

    PRINT N'OECS SKU seed completed; demo variants available for all 39 products.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;



SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.PRODUCT',N'U') IS NULL OR
   OBJECT_ID(N'dbo.ATTRIBUTE',N'U') IS NULL OR
   OBJECT_ID(N'dbo.PRODUCT_SPECIFICATION',N'U') IS NULL OR
   OBJECT_ID(N'dbo.CATEGORY_ATTRIBUTE',N'U') IS NULL
BEGIN
    THROW 56001, N'Thieu cac bang catalog/SKU.', 1;
END;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;
DROP TABLE IF EXISTS #SpecSeed;
CREATE TABLE #SpecSeed (
  product_name NVARCHAR(255) NOT NULL,
  group_name NVARCHAR(100) NOT NULL,
  attribute_name NVARCHAR(100) NOT NULL,
  spec_value NVARCHAR(255) NOT NULL,
  display_order INT NOT NULL,
  PRIMARY KEY(product_name, attribute_name)
);

INSERT INTO #SpecSeed(product_name,group_name,attribute_name,spec_value,display_order)
VALUES
    (N'iPhone 15 Pro', N'Màn hình', N'Tần số quét', N'ProMotion thích ứng đến 120 Hz', 10),
    (N'iPhone 15 Pro', N'Màn hình', N'Công nghệ màn hình', N'Super Retina XDR OLED', 20),
    (N'iPhone 15 Pro', N'Màn hình', N'Tính năng màn hình', N'Dynamic Island, Always-On Display', 30),
    (N'iPhone 15 Pro', N'Camera', N'Camera trước', N'TrueDepth 12 MP', 40),
    (N'iPhone 15 Pro', N'Camera', N'Tính năng camera', N'Chế độ Chân dung, Night mode, Photographic Styles', 50),
    (N'iPhone 15 Pro', N'Pin và sạc', N'Cổng sạc', N'USB-C', 60),
    (N'iPhone 15 Pro', N'Pin và sạc', N'Sạc không dây', N'MagSafe và Qi', 70),
    (N'iPhone 15 Pro', N'Kết nối', N'Mạng di động', N'5G', 80),
    (N'iPhone 15 Pro', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth, NFC', 90),
    (N'iPhone 15 Pro', N'Thiết kế', N'Chống nước và bụi', N'IP68', 100),
    (N'iPhone 15 Pro', N'Thiết kế', N'Chất liệu khung', N'Titan', 110),
    (N'iPhone 15 Pro', N'Bảo mật và phần mềm', N'Bảo mật', N'Face ID', 120),
    (N'iPhone 15 Pro', N'Camera', N'Camera sau', N'48 MP chính + 12 MP siêu rộng + 12 MP tele', 130),
    (N'iPhone 15 Pro', N'Camera', N'Zoom quang học', N'3x', 140),
    (N'iPhone 15 Pro', N'Pin và sạc', N'Thời lượng video', N'Lên đến 23 giờ (theo Apple)', 150),
    (N'iPhone 15 Pro', N'Bảo mật và phần mềm', N'Hệ điều hành khi ra mắt', N'iOS 17', 160),
    (N'iPhone 15 Pro Max', N'Màn hình', N'Tần số quét', N'ProMotion thích ứng đến 120 Hz', 10),
    (N'iPhone 15 Pro Max', N'Màn hình', N'Công nghệ màn hình', N'Super Retina XDR OLED', 20),
    (N'iPhone 15 Pro Max', N'Màn hình', N'Tính năng màn hình', N'Dynamic Island, Always-On Display', 30),
    (N'iPhone 15 Pro Max', N'Camera', N'Camera trước', N'TrueDepth 12 MP', 40),
    (N'iPhone 15 Pro Max', N'Camera', N'Tính năng camera', N'Chế độ Chân dung, Night mode, Photographic Styles', 50),
    (N'iPhone 15 Pro Max', N'Pin và sạc', N'Cổng sạc', N'USB-C', 60),
    (N'iPhone 15 Pro Max', N'Pin và sạc', N'Sạc không dây', N'MagSafe và Qi', 70),
    (N'iPhone 15 Pro Max', N'Kết nối', N'Mạng di động', N'5G', 80),
    (N'iPhone 15 Pro Max', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth, NFC', 90),
    (N'iPhone 15 Pro Max', N'Thiết kế', N'Chống nước và bụi', N'IP68', 100),
    (N'iPhone 15 Pro Max', N'Thiết kế', N'Chất liệu khung', N'Titan', 110),
    (N'iPhone 15 Pro Max', N'Bảo mật và phần mềm', N'Bảo mật', N'Face ID', 120),
    (N'iPhone 15 Pro Max', N'Camera', N'Camera sau', N'48 MP chính + 12 MP siêu rộng + 12 MP tele', 130),
    (N'iPhone 15 Pro Max', N'Camera', N'Zoom quang học', N'5x', 140),
    (N'iPhone 15 Pro Max', N'Pin và sạc', N'Thời lượng video', N'Lên đến 29 giờ (theo Apple)', 150),
    (N'iPhone 15 Pro Max', N'Bảo mật và phần mềm', N'Hệ điều hành khi ra mắt', N'iOS 17', 160),
    (N'iPhone 16 Pro', N'Màn hình', N'Tần số quét', N'ProMotion thích ứng đến 120 Hz', 10),
    (N'iPhone 16 Pro', N'Màn hình', N'Công nghệ màn hình', N'Super Retina XDR OLED', 20),
    (N'iPhone 16 Pro', N'Màn hình', N'Tính năng màn hình', N'Dynamic Island, Always-On Display', 30),
    (N'iPhone 16 Pro', N'Camera', N'Camera trước', N'TrueDepth 12 MP', 40),
    (N'iPhone 16 Pro', N'Camera', N'Tính năng camera', N'Chế độ Chân dung, Night mode, Photographic Styles', 50),
    (N'iPhone 16 Pro', N'Pin và sạc', N'Cổng sạc', N'USB-C', 60),
    (N'iPhone 16 Pro', N'Pin và sạc', N'Sạc không dây', N'MagSafe và Qi', 70),
    (N'iPhone 16 Pro', N'Kết nối', N'Mạng di động', N'5G', 80),
    (N'iPhone 16 Pro', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth, NFC', 90),
    (N'iPhone 16 Pro', N'Thiết kế', N'Chống nước và bụi', N'IP68', 100),
    (N'iPhone 16 Pro', N'Thiết kế', N'Chất liệu khung', N'Titan', 110),
    (N'iPhone 16 Pro', N'Bảo mật và phần mềm', N'Bảo mật', N'Face ID', 120),
    (N'iPhone 16 Pro', N'Camera', N'Camera sau', N'48 MP chính + 48 MP siêu rộng + 12 MP tele', 130),
    (N'iPhone 16 Pro', N'Camera', N'Zoom quang học', N'5x', 140),
    (N'iPhone 16 Pro', N'Pin và sạc', N'Thời lượng video', N'Lên đến 27 giờ (theo Apple)', 150),
    (N'iPhone 16 Pro', N'Bảo mật và phần mềm', N'Hệ điều hành khi ra mắt', N'iOS 18', 160),
    (N'iPhone 16 Pro Max', N'Màn hình', N'Tần số quét', N'ProMotion thích ứng đến 120 Hz', 10),
    (N'iPhone 16 Pro Max', N'Màn hình', N'Công nghệ màn hình', N'Super Retina XDR OLED', 20),
    (N'iPhone 16 Pro Max', N'Màn hình', N'Tính năng màn hình', N'Dynamic Island, Always-On Display', 30),
    (N'iPhone 16 Pro Max', N'Camera', N'Camera trước', N'TrueDepth 12 MP', 40),
    (N'iPhone 16 Pro Max', N'Camera', N'Tính năng camera', N'Chế độ Chân dung, Night mode, Photographic Styles', 50),
    (N'iPhone 16 Pro Max', N'Pin và sạc', N'Cổng sạc', N'USB-C', 60),
    (N'iPhone 16 Pro Max', N'Pin và sạc', N'Sạc không dây', N'MagSafe và Qi', 70),
    (N'iPhone 16 Pro Max', N'Kết nối', N'Mạng di động', N'5G', 80),
    (N'iPhone 16 Pro Max', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth, NFC', 90),
    (N'iPhone 16 Pro Max', N'Thiết kế', N'Chống nước và bụi', N'IP68', 100),
    (N'iPhone 16 Pro Max', N'Thiết kế', N'Chất liệu khung', N'Titan', 110),
    (N'iPhone 16 Pro Max', N'Bảo mật và phần mềm', N'Bảo mật', N'Face ID', 120),
    (N'iPhone 16 Pro Max', N'Camera', N'Camera sau', N'48 MP chính + 48 MP siêu rộng + 12 MP tele', 130),
    (N'iPhone 16 Pro Max', N'Camera', N'Zoom quang học', N'5x', 140),
    (N'iPhone 16 Pro Max', N'Pin và sạc', N'Thời lượng video', N'Lên đến 33 giờ (theo Apple)', 150),
    (N'iPhone 16 Pro Max', N'Bảo mật và phần mềm', N'Hệ điều hành khi ra mắt', N'iOS 18', 160),
    (N'Samsung Galaxy S24 Ultra', N'Màn hình', N'Tần số quét', N'Lên đến 120 Hz', 10),
    (N'Samsung Galaxy S24 Ultra', N'Màn hình', N'Công nghệ màn hình', N'Dynamic AMOLED 2X', 20),
    (N'Samsung Galaxy S24 Ultra', N'Kết nối', N'Mạng di động', N'5G', 80),
    (N'Samsung Galaxy S24 Ultra', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth, NFC', 90),
    (N'Samsung Galaxy S24 Ultra', N'Kết nối', N'Cổng kết nối', N'USB-C', 170),
    (N'Samsung Galaxy S24 Ultra', N'Bảo mật và phần mềm', N'Bảo mật', N'Cảm biến vân tay trên màn hình', 120),
    (N'Samsung Galaxy S24 Ultra', N'Bảo mật và phần mềm', N'Hệ điều hành khi ra mắt', N'Android 14, One UI 6.1', 160),
    (N'Samsung Galaxy S24 Ultra', N'Camera', N'Camera sau', N'200 MP chính + 12 MP siêu rộng + 50 MP tele 5x + 10 MP tele 3x', 130),
    (N'Samsung Galaxy S24 Ultra', N'Camera', N'Camera trước', N'12 MP', 40),
    (N'Samsung Galaxy S24 Ultra', N'Camera', N'Zoom quang học', N'3x và 5x', 140),
    (N'Samsung Galaxy S24 Ultra', N'Pin và sạc', N'Dung lượng pin', N'5.000 mAh', 180),
    (N'Samsung Galaxy S24 Ultra', N'Pin và sạc', N'Sạc có dây', N'Tối đa 45 W', 190),
    (N'Samsung Galaxy S24 Ultra', N'Pin và sạc', N'Sạc không dây', N'Có', 70),
    (N'Samsung Galaxy S24 Ultra', N'Thiết kế', N'Chống nước và bụi', N'IP68', 100),
    (N'Samsung Galaxy S24 Ultra', N'Thiết kế', N'Chất liệu khung', N'Titan', 110),
    (N'Samsung Galaxy S24 Ultra', N'Thiết kế', N'Bút S Pen', N'Tích hợp', 200),
    (N'Samsung Galaxy S24 Plus', N'Màn hình', N'Tần số quét', N'Lên đến 120 Hz', 10),
    (N'Samsung Galaxy S24 Plus', N'Màn hình', N'Công nghệ màn hình', N'Dynamic AMOLED 2X', 20),
    (N'Samsung Galaxy S24 Plus', N'Kết nối', N'Mạng di động', N'5G', 80),
    (N'Samsung Galaxy S24 Plus', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth, NFC', 90),
    (N'Samsung Galaxy S24 Plus', N'Kết nối', N'Cổng kết nối', N'USB-C', 170),
    (N'Samsung Galaxy S24 Plus', N'Bảo mật và phần mềm', N'Bảo mật', N'Cảm biến vân tay trên màn hình', 120),
    (N'Samsung Galaxy S24 Plus', N'Bảo mật và phần mềm', N'Hệ điều hành khi ra mắt', N'Android 14, One UI 6.1', 160),
    (N'Samsung Galaxy S24 Plus', N'Camera', N'Camera sau', N'50 MP chính + 12 MP siêu rộng + 10 MP tele', 130),
    (N'Samsung Galaxy S24 Plus', N'Camera', N'Camera trước', N'12 MP', 40),
    (N'Samsung Galaxy S24 Plus', N'Camera', N'Zoom quang học', N'3x', 140),
    (N'Samsung Galaxy S24 Plus', N'Pin và sạc', N'Dung lượng pin', N'4.900 mAh', 180),
    (N'Samsung Galaxy S24 Plus', N'Pin và sạc', N'Sạc có dây', N'Tối đa 45 W', 190),
    (N'Samsung Galaxy S24 Plus', N'Pin và sạc', N'Sạc không dây', N'Có', 70),
    (N'Samsung Galaxy S24 Plus', N'Thiết kế', N'Chống nước và bụi', N'IP68', 100),
    (N'Samsung Galaxy A55 5G', N'Màn hình', N'Tần số quét', N'Lên đến 120 Hz', 10),
    (N'Samsung Galaxy A55 5G', N'Màn hình', N'Công nghệ màn hình', N'Super AMOLED', 20),
    (N'Samsung Galaxy A55 5G', N'Kết nối', N'Mạng di động', N'5G', 80),
    (N'Samsung Galaxy A55 5G', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth, NFC', 90),
    (N'Samsung Galaxy A55 5G', N'Kết nối', N'Cổng kết nối', N'USB-C', 170),
    (N'Samsung Galaxy A55 5G', N'Bảo mật và phần mềm', N'Bảo mật', N'Cảm biến vân tay trên màn hình', 120),
    (N'Samsung Galaxy A55 5G', N'Bảo mật và phần mềm', N'Hệ điều hành khi ra mắt', N'Android 14, One UI 6.1', 160),
    (N'Samsung Galaxy A55 5G', N'Pin và sạc', N'Dung lượng pin', N'5.000 mAh', 180),
    (N'Samsung Galaxy A55 5G', N'Pin và sạc', N'Sạc có dây', N'Tối đa 25 W', 190),
    (N'Samsung Galaxy A55 5G', N'Thiết kế', N'Chống nước và bụi', N'IP67', 100),
    (N'Samsung Galaxy A55 5G', N'Màn hình', N'Độ phân giải màn hình', N'FHD+', 210),
    (N'Samsung Galaxy A55 5G', N'Camera', N'Camera sau', N'50 MP chính + 12 MP siêu rộng + 5 MP macro', 130),
    (N'Samsung Galaxy A55 5G', N'Camera', N'Camera trước', N'32 MP', 40),
    (N'Samsung Galaxy A35 5G', N'Màn hình', N'Tần số quét', N'Lên đến 120 Hz', 10),
    (N'Samsung Galaxy A35 5G', N'Màn hình', N'Công nghệ màn hình', N'Super AMOLED', 20),
    (N'Samsung Galaxy A35 5G', N'Kết nối', N'Mạng di động', N'5G', 80),
    (N'Samsung Galaxy A35 5G', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth, NFC', 90),
    (N'Samsung Galaxy A35 5G', N'Kết nối', N'Cổng kết nối', N'USB-C', 170),
    (N'Samsung Galaxy A35 5G', N'Bảo mật và phần mềm', N'Bảo mật', N'Cảm biến vân tay trên màn hình', 120),
    (N'Samsung Galaxy A35 5G', N'Bảo mật và phần mềm', N'Hệ điều hành khi ra mắt', N'Android 14, One UI 6.1', 160),
    (N'Samsung Galaxy A35 5G', N'Pin và sạc', N'Dung lượng pin', N'5.000 mAh', 180),
    (N'Samsung Galaxy A35 5G', N'Pin và sạc', N'Sạc có dây', N'Tối đa 25 W', 190),
    (N'Samsung Galaxy A35 5G', N'Thiết kế', N'Chống nước và bụi', N'IP67', 100),
    (N'Samsung Galaxy A35 5G', N'Màn hình', N'Độ phân giải màn hình', N'FHD+', 210),
    (N'Samsung Galaxy A35 5G', N'Camera', N'Camera sau', N'50 MP chính + 8 MP siêu rộng + 5 MP macro', 130),
    (N'Samsung Galaxy A35 5G', N'Camera', N'Camera trước', N'13 MP', 40),
    (N'AirPods Pro 2', N'Thiết kế', N'Kiểu tai nghe', N'True wireless (TWS)', 10),
    (N'AirPods Pro 2', N'Kết nối', N'Kết nối chính', N'Bluetooth', 20),
    (N'AirPods Pro 2', N'Pin và sạc', N'Phương thức sạc', N'Qua hộp sạc', 30),
    (N'AirPods Pro 2', N'Âm thanh', N'Microphone', N'Có, hỗ trợ đàm thoại', 40),
    (N'AirPods Pro 2', N'Điều khiển', N'Điều khiển', N'Cảm ứng / thao tác trên tai nghe', 50),
    (N'AirPods Pro 2', N'Âm thanh', N'Chống ồn chủ động', N'Có (ANC)', 60),
    (N'AirPods Pro 2', N'Âm thanh', N'Âm thanh không gian', N'Có, theo dõi chuyển động đầu', 70),
    (N'AirPods Pro 2', N'Âm thanh', N'Chế độ xuyên âm', N'Có, Adaptive Transparency', 80),
    (N'AirPods Pro 2', N'Kết nối', N'Bluetooth', N'5.3', 90),
    (N'AirPods Pro 2', N'Pin và sạc', N'Thời gian nghe', N'Lên đến 6 giờ mỗi lần sạc (ANC bật)', 100),
    (N'AirPods Pro 2', N'Pin và sạc', N'Cổng sạc hộp', N'USB-C (phiên bản hộp USB-C)', 110),
    (N'AirPods Pro 2', N'Thiết kế', N'Chống bụi và nước', N'IP54 (phiên bản USB-C)', 120),
    (N'AirPods 4', N'Thiết kế', N'Kiểu tai nghe', N'True wireless (TWS)', 10),
    (N'AirPods 4', N'Kết nối', N'Kết nối chính', N'Bluetooth', 20),
    (N'AirPods 4', N'Pin và sạc', N'Phương thức sạc', N'Qua hộp sạc', 30),
    (N'AirPods 4', N'Âm thanh', N'Microphone', N'Có, hỗ trợ đàm thoại', 40),
    (N'AirPods 4', N'Điều khiển', N'Điều khiển', N'Cảm ứng / thao tác trên tai nghe', 50),
    (N'AirPods 4', N'Âm thanh', N'Chống ồn chủ động', N'Tùy SKU: bản thường hoặc bản ANC', 60),
    (N'AirPods 4', N'Âm thanh', N'Âm thanh không gian', N'Có', 70),
    (N'AirPods 4', N'Kết nối', N'Bluetooth', N'5.3', 90),
    (N'AirPods 4', N'Pin và sạc', N'Thời gian nghe', N'Lên đến 5 giờ/bản thường; bản ANC tùy chế độ', 100),
    (N'AirPods 4', N'Pin và sạc', N'Cổng sạc hộp', N'USB-C', 110),
    (N'AirPods 4', N'Thiết kế', N'Chống bụi và nước', N'IP54', 120),
    (N'Samsung Galaxy Buds3 Pro', N'Thiết kế', N'Kiểu tai nghe', N'True wireless (TWS)', 10),
    (N'Samsung Galaxy Buds3 Pro', N'Kết nối', N'Kết nối chính', N'Bluetooth', 20),
    (N'Samsung Galaxy Buds3 Pro', N'Pin và sạc', N'Phương thức sạc', N'Qua hộp sạc', 30),
    (N'Samsung Galaxy Buds3 Pro', N'Âm thanh', N'Microphone', N'Có, hỗ trợ đàm thoại', 40),
    (N'Samsung Galaxy Buds3 Pro', N'Điều khiển', N'Điều khiển', N'Cảm ứng / thao tác trên tai nghe', 50),
    (N'Samsung Galaxy Buds3 Pro', N'Âm thanh', N'Chống ồn chủ động', N'Có (ANC)', 60),
    (N'Samsung Galaxy Buds3 Pro', N'Âm thanh', N'Chế độ âm thanh', N'Adaptive Noise Control', 130),
    (N'Samsung Galaxy Buds3 Pro', N'Âm thanh', N'Kiểu đeo', N'In-ear', 140),
    (N'Samsung Galaxy Buds3 Pro', N'Kết nối', N'Bluetooth', N'5.4', 90),
    (N'Samsung Galaxy Buds3 Pro', N'Pin và sạc', N'Cổng sạc hộp', N'USB-C', 110),
    (N'Samsung Galaxy Buds3 Pro', N'Pin và sạc', N'Thời gian nghe', N'Lên đến 6 giờ (bật ANC, tùy điều kiện)', 100),
    (N'Samsung Galaxy Buds3 Pro', N'Thiết kế', N'Chống nước', N'IP57 (tai nghe)', 150),
    (N'Samsung Galaxy Buds FE', N'Thiết kế', N'Kiểu tai nghe', N'True wireless (TWS)', 10),
    (N'Samsung Galaxy Buds FE', N'Kết nối', N'Kết nối chính', N'Bluetooth', 20),
    (N'Samsung Galaxy Buds FE', N'Pin và sạc', N'Phương thức sạc', N'Qua hộp sạc', 30),
    (N'Samsung Galaxy Buds FE', N'Âm thanh', N'Microphone', N'Có, hỗ trợ đàm thoại', 40),
    (N'Samsung Galaxy Buds FE', N'Điều khiển', N'Điều khiển', N'Cảm ứng / thao tác trên tai nghe', 50),
    (N'Samsung Galaxy Buds FE', N'Âm thanh', N'Chống ồn chủ động', N'Có (ANC)', 60),
    (N'Samsung Galaxy Buds FE', N'Âm thanh', N'Kiểu đeo', N'In-ear, có wingtip', 140),
    (N'Samsung Galaxy Buds FE', N'Kết nối', N'Bluetooth', N'5.2', 90),
    (N'Samsung Galaxy Buds FE', N'Pin và sạc', N'Cổng sạc hộp', N'USB-C', 110),
    (N'Samsung Galaxy Buds FE', N'Pin và sạc', N'Thời gian nghe', N'Lên đến 6 giờ (bật ANC, tùy điều kiện)', 100),
    (N'Samsung Galaxy Buds FE', N'Thiết kế', N'Chống nước', N'IPX2 (tai nghe)', 150),
    (N'Apple USB-C 20W Power Adapter', N'Thông tin chung', N'Loại sản phẩm', N'Củ sạc / bộ tiếp hợp nguồn', 10),
    (N'Apple USB-C 20W Power Adapter', N'Thông tin chung', N'Cổng đầu ra', N'USB-C', 20),
    (N'Apple USB-C 20W Power Adapter', N'Thông tin chung', N'Nguồn điện đầu vào', N'Điện lưới AC', 30),
    (N'Apple USB-C 20W Power Adapter', N'Thông tin chung', N'Phạm vi sử dụng', N'Sạc thiết bị tương thích qua USB-C', 40),
    (N'Apple USB-C 20W Power Adapter', N'Thông tin chung', N'Cáp sạc kèm theo', N'Phụ thuộc gói bán và bộ đóng gói', 50),
    (N'Apple USB-C 20W Power Adapter', N'Kết nối & tương thích', N'Tương thích', N'Điện thoại và thiết bị hỗ trợ sạc qua USB-C', 60),
    (N'Apple USB-C 20W Power Adapter', N'Kết nối & tương thích', N'Chức năng', N'Cấp nguồn và sạc pin', 70),
    (N'Apple USB-C 20W Power Adapter', N'Kết nối & tương thích', N'Số cổng sạc', N'1 cổng USB-C', 80),
    (N'Apple USB-C 20W Power Adapter', N'Nguồn & sạc', N'Công suất tối đa', N'20 W', 90),
    (N'Apple USB-C 20W Power Adapter', N'Nguồn & sạc', N'Chuẩn sạc', N'USB Power Delivery (PD)', 100),
    (N'Samsung 25W USB-C Fast Charger', N'Thông tin chung', N'Loại sản phẩm', N'Củ sạc / bộ tiếp hợp nguồn', 10),
    (N'Samsung 25W USB-C Fast Charger', N'Thông tin chung', N'Cổng đầu ra', N'USB-C', 20),
    (N'Samsung 25W USB-C Fast Charger', N'Thông tin chung', N'Nguồn điện đầu vào', N'Điện lưới AC', 30),
    (N'Samsung 25W USB-C Fast Charger', N'Thông tin chung', N'Phạm vi sử dụng', N'Sạc thiết bị tương thích qua USB-C', 40),
    (N'Samsung 25W USB-C Fast Charger', N'Thông tin chung', N'Cáp sạc kèm theo', N'Phụ thuộc gói bán và bộ đóng gói', 50),
    (N'Samsung 25W USB-C Fast Charger', N'Kết nối & tương thích', N'Tương thích', N'Điện thoại và thiết bị hỗ trợ sạc qua USB-C', 60),
    (N'Samsung 25W USB-C Fast Charger', N'Kết nối & tương thích', N'Chức năng', N'Cấp nguồn và sạc pin', 70),
    (N'Samsung 25W USB-C Fast Charger', N'Kết nối & tương thích', N'Số cổng sạc', N'1 cổng USB-C', 80),
    (N'Samsung 25W USB-C Fast Charger', N'Nguồn & sạc', N'Công suất tối đa', N'25 W', 90),
    (N'Samsung 25W USB-C Fast Charger', N'Nguồn & sạc', N'Chuẩn sạc', N'USB PD PPS / Samsung Super Fast Charging', 100),
    (N'Apple USB-C Charge Cable 1m', N'Thông tin chung', N'Loại sản phẩm', N'Cáp sạc và truyền dữ liệu', 10),
    (N'Apple USB-C Charge Cable 1m', N'Thông tin chung', N'Chức năng', N'Sạc và đồng bộ dữ liệu', 20),
    (N'Apple USB-C Charge Cable 1m', N'Thông tin chung', N'Chiều dài danh nghĩa', N'1 m', 30),
    (N'Apple USB-C Charge Cable 1m', N'Thông tin chung', N'Nguồn cấp', N'Sử dụng bộ sạc/thiết bị tương thích', 40),
    (N'Apple USB-C Charge Cable 1m', N'Kết nối', N'Tương thích', N'Tùy loại cổng của thiết bị', 50),
    (N'Apple USB-C Charge Cable 1m', N'Kết nối', N'Loại kết nối', N'Có dây', 60),
    (N'Apple USB-C Charge Cable 1m', N'Kết nối', N'Cách sử dụng', N'Kết nối thiết bị và bộ sạc hoặc máy tính', 70),
    (N'Apple USB-C Charge Cable 1m', N'Kết nối', N'Đầu cáp 1', N'USB-C', 80),
    (N'Apple USB-C Charge Cable 1m', N'Kết nối', N'Đầu cáp 2', N'USB-C', 90),
    (N'Apple USB-C Charge Cable 1m', N'Thông tin chung', N'Dòng cáp', N'Apple USB-C Charge Cable', 100),
    (N'Apple USB-C to Lightning Cable', N'Thông tin chung', N'Loại sản phẩm', N'Cáp sạc và truyền dữ liệu', 10),
    (N'Apple USB-C to Lightning Cable', N'Thông tin chung', N'Chức năng', N'Sạc và đồng bộ dữ liệu', 20),
    (N'Apple USB-C to Lightning Cable', N'Thông tin chung', N'Chiều dài danh nghĩa', N'1 m', 30),
    (N'Apple USB-C to Lightning Cable', N'Thông tin chung', N'Nguồn cấp', N'Sử dụng bộ sạc/thiết bị tương thích', 40),
    (N'Apple USB-C to Lightning Cable', N'Kết nối', N'Tương thích', N'Tùy loại cổng của thiết bị', 50),
    (N'Apple USB-C to Lightning Cable', N'Kết nối', N'Loại kết nối', N'Có dây', 60),
    (N'Apple USB-C to Lightning Cable', N'Kết nối', N'Cách sử dụng', N'Kết nối thiết bị và bộ sạc hoặc máy tính', 70),
    (N'Apple USB-C to Lightning Cable', N'Kết nối', N'Đầu cáp 1', N'USB-C', 80),
    (N'Apple USB-C to Lightning Cable', N'Kết nối', N'Đầu cáp 2', N'Lightning', 90),
    (N'Apple USB-C to Lightning Cable', N'Thông tin chung', N'Dòng cáp', N'Apple USB-C to Lightning', 100),
    (N'Samsung USB-C Cable 1m', N'Thông tin chung', N'Loại sản phẩm', N'Cáp sạc và truyền dữ liệu', 10),
    (N'Samsung USB-C Cable 1m', N'Thông tin chung', N'Chức năng', N'Sạc và đồng bộ dữ liệu', 20),
    (N'Samsung USB-C Cable 1m', N'Thông tin chung', N'Chiều dài danh nghĩa', N'1 m', 30),
    (N'Samsung USB-C Cable 1m', N'Thông tin chung', N'Nguồn cấp', N'Sử dụng bộ sạc/thiết bị tương thích', 40),
    (N'Samsung USB-C Cable 1m', N'Kết nối', N'Tương thích', N'Tùy loại cổng của thiết bị', 50),
    (N'Samsung USB-C Cable 1m', N'Kết nối', N'Loại kết nối', N'Có dây', 60),
    (N'Samsung USB-C Cable 1m', N'Kết nối', N'Cách sử dụng', N'Kết nối thiết bị và bộ sạc hoặc máy tính', 70),
    (N'Samsung USB-C Cable 1m', N'Kết nối', N'Đầu cáp 1', N'USB-C', 80),
    (N'Samsung USB-C Cable 1m', N'Kết nối', N'Đầu cáp 2', N'USB-C', 90),
    (N'Samsung USB-C Cable 1m', N'Thông tin chung', N'Dòng cáp', N'Samsung USB-C Cable', 100),
    (N'Lenovo IdeaPad Slim 3', N'Bộ nhớ & lưu trữ', N'Loại ổ cứng', N'SSD (dung lượng theo SKU)', 10),
    (N'Lenovo IdeaPad Slim 3', N'Bộ nhớ & lưu trữ', N'Cấu hình RAM', N'Dung lượng theo SKU, xem mục chọn phiên bản', 20),
    (N'Lenovo IdeaPad Slim 3', N'Kết nối', N'Kết nối không dây', N'Wi-Fi và Bluetooth (chuẩn tùy cấu hình)', 30),
    (N'Lenovo IdeaPad Slim 3', N'Kết nối', N'Cổng kết nối phổ biến', N'USB-A, USB-C, HDMI (tùy máy)', 40),
    (N'Lenovo IdeaPad Slim 3', N'Đa phương tiện', N'Webcam', N'Tích hợp trên màn hình', 50),
    (N'Lenovo IdeaPad Slim 3', N'Đa phương tiện', N'Âm thanh', N'Loa và microphone tích hợp', 60),
    (N'Lenovo IdeaPad Slim 3', N'Thông tin khác', N'Nhu cầu sử dụng', N'Học tập, làm việc và giải trí', 70),
    (N'Lenovo IdeaPad Slim 3', N'Thông tin khác', N'Hệ điều hành', N'Tùy cấu hình xuất xưởng / cài đặt thực tế', 80),
    (N'Lenovo IdeaPad Slim 3', N'Thiết kế', N'Kiểu máy', N'Laptop đa dụng / văn phòng', 90),
    (N'Lenovo IdeaPad Slim 3', N'Thiết kế', N'Bàn phím', N'Bàn phím laptop tích hợp', 100),
    (N'Lenovo IdeaPad Slim 3', N'Màn hình', N'Kích thước màn hình', N'15.6 inch', 110),
    (N'Lenovo IdeaPad Slim 3', N'Màn hình', N'Độ phân giải màn hình', N'Full HD', 120),
    (N'Lenovo IdeaPad Slim 3', N'Bộ xử lý', N'Dòng CPU', N'Intel Core i3-1315U (theo cấu hình demo)', 130),
    (N'Lenovo ThinkBook 14', N'Bộ nhớ & lưu trữ', N'Loại ổ cứng', N'SSD (dung lượng theo SKU)', 10),
    (N'Lenovo ThinkBook 14', N'Bộ nhớ & lưu trữ', N'Cấu hình RAM', N'Dung lượng theo SKU, xem mục chọn phiên bản', 20),
    (N'Lenovo ThinkBook 14', N'Kết nối', N'Kết nối không dây', N'Wi-Fi và Bluetooth (chuẩn tùy cấu hình)', 30),
    (N'Lenovo ThinkBook 14', N'Kết nối', N'Cổng kết nối phổ biến', N'USB-A, USB-C, HDMI (tùy máy)', 40),
    (N'Lenovo ThinkBook 14', N'Đa phương tiện', N'Webcam', N'Tích hợp trên màn hình', 50),
    (N'Lenovo ThinkBook 14', N'Đa phương tiện', N'Âm thanh', N'Loa và microphone tích hợp', 60),
    (N'Lenovo ThinkBook 14', N'Thông tin khác', N'Nhu cầu sử dụng', N'Học tập, làm việc và giải trí', 70),
    (N'Lenovo ThinkBook 14', N'Thông tin khác', N'Hệ điều hành', N'Tùy cấu hình xuất xưởng / cài đặt thực tế', 80),
    (N'Lenovo ThinkBook 14', N'Thiết kế', N'Kiểu máy', N'Laptop đa dụng / văn phòng', 90),
    (N'Lenovo ThinkBook 14', N'Thiết kế', N'Bàn phím', N'Bàn phím laptop tích hợp', 100),
    (N'Lenovo ThinkBook 14', N'Màn hình', N'Kích thước màn hình', N'14 inch', 110),
    (N'Lenovo ThinkBook 14', N'Màn hình', N'Độ phân giải màn hình', N'WUXGA', 120),
    (N'Lenovo ThinkBook 14', N'Bộ xử lý', N'Dòng CPU', N'Intel Core i5-1335U (theo cấu hình demo)', 130),
    (N'Lenovo IdeaPad 5', N'Bộ nhớ & lưu trữ', N'Loại ổ cứng', N'SSD (dung lượng theo SKU)', 10),
    (N'Lenovo IdeaPad 5', N'Bộ nhớ & lưu trữ', N'Cấu hình RAM', N'Dung lượng theo SKU, xem mục chọn phiên bản', 20),
    (N'Lenovo IdeaPad 5', N'Kết nối', N'Kết nối không dây', N'Wi-Fi và Bluetooth (chuẩn tùy cấu hình)', 30),
    (N'Lenovo IdeaPad 5', N'Kết nối', N'Cổng kết nối phổ biến', N'USB-A, USB-C, HDMI (tùy máy)', 40),
    (N'Lenovo IdeaPad 5', N'Đa phương tiện', N'Webcam', N'Tích hợp trên màn hình', 50),
    (N'Lenovo IdeaPad 5', N'Đa phương tiện', N'Âm thanh', N'Loa và microphone tích hợp', 60),
    (N'Lenovo IdeaPad 5', N'Thông tin khác', N'Nhu cầu sử dụng', N'Học tập, làm việc và giải trí', 70),
    (N'Lenovo IdeaPad 5', N'Thông tin khác', N'Hệ điều hành', N'Tùy cấu hình xuất xưởng / cài đặt thực tế', 80),
    (N'Lenovo IdeaPad 5', N'Thiết kế', N'Kiểu máy', N'Laptop đa dụng / văn phòng', 90),
    (N'Lenovo IdeaPad 5', N'Thiết kế', N'Bàn phím', N'Bàn phím laptop tích hợp', 100),
    (N'Lenovo IdeaPad 5', N'Màn hình', N'Kích thước màn hình', N'15.6 inch', 110),
    (N'Lenovo IdeaPad 5', N'Màn hình', N'Độ phân giải màn hình', N'Full HD', 120),
    (N'Lenovo IdeaPad 5', N'Bộ xử lý', N'Dòng CPU', N'AMD Ryzen 5 7530U (theo cấu hình demo)', 130),
    (N'Lenovo LOQ 15', N'Bộ nhớ & lưu trữ', N'Loại ổ cứng', N'SSD (dung lượng theo SKU)', 10),
    (N'Lenovo LOQ 15', N'Bộ nhớ & lưu trữ', N'Cấu hình RAM', N'Dung lượng theo SKU, xem mục chọn phiên bản', 20),
    (N'Lenovo LOQ 15', N'Kết nối', N'Kết nối không dây', N'Wi-Fi và Bluetooth (chuẩn tùy cấu hình)', 30),
    (N'Lenovo LOQ 15', N'Kết nối', N'Cổng kết nối phổ biến', N'USB-A, USB-C, HDMI (tùy máy)', 40),
    (N'Lenovo LOQ 15', N'Đa phương tiện', N'Webcam', N'Tích hợp trên màn hình', 50),
    (N'Lenovo LOQ 15', N'Đa phương tiện', N'Âm thanh', N'Loa và microphone tích hợp', 60),
    (N'Lenovo LOQ 15', N'Thông tin khác', N'Nhu cầu sử dụng', N'Học tập, làm việc và giải trí', 70),
    (N'Lenovo LOQ 15', N'Thông tin khác', N'Hệ điều hành', N'Tùy cấu hình xuất xưởng / cài đặt thực tế', 80),
    (N'Lenovo LOQ 15', N'Thiết kế', N'Kiểu máy', N'Laptop gaming', 90),
    (N'Lenovo LOQ 15', N'Thiết kế', N'Bàn phím', N'Bàn phím gaming tích hợp', 100),
    (N'Lenovo LOQ 15', N'Màn hình', N'Kích thước màn hình', N'15.6 inch', 110),
    (N'Lenovo LOQ 15', N'Màn hình', N'Độ phân giải màn hình', N'Full HD', 120),
    (N'Lenovo LOQ 15', N'Màn hình', N'Tần số quét', N'144 Hz', 130),
    (N'Lenovo LOQ 15', N'Bộ xử lý', N'Dòng CPU', N'Intel Core i5-13420H (theo cấu hình demo)', 140),
    (N'Lenovo LOQ 15', N'Bộ xử lý', N'GPU rời', N'NVIDIA GeForce RTX 4050 6 GB (cấu hình demo)', 150),
    (N'Lenovo Legion 5', N'Bộ nhớ & lưu trữ', N'Loại ổ cứng', N'SSD (dung lượng theo SKU)', 10),
    (N'Lenovo Legion 5', N'Bộ nhớ & lưu trữ', N'Cấu hình RAM', N'Dung lượng theo SKU, xem mục chọn phiên bản', 20),
    (N'Lenovo Legion 5', N'Kết nối', N'Kết nối không dây', N'Wi-Fi và Bluetooth (chuẩn tùy cấu hình)', 30),
    (N'Lenovo Legion 5', N'Kết nối', N'Cổng kết nối phổ biến', N'USB-A, USB-C, HDMI (tùy máy)', 40),
    (N'Lenovo Legion 5', N'Đa phương tiện', N'Webcam', N'Tích hợp trên màn hình', 50),
    (N'Lenovo Legion 5', N'Đa phương tiện', N'Âm thanh', N'Loa và microphone tích hợp', 60),
    (N'Lenovo Legion 5', N'Thông tin khác', N'Nhu cầu sử dụng', N'Học tập, làm việc và giải trí', 70),
    (N'Lenovo Legion 5', N'Thông tin khác', N'Hệ điều hành', N'Tùy cấu hình xuất xưởng / cài đặt thực tế', 80),
    (N'Lenovo Legion 5', N'Thiết kế', N'Kiểu máy', N'Laptop gaming', 90),
    (N'Lenovo Legion 5', N'Thiết kế', N'Bàn phím', N'Bàn phím gaming tích hợp', 100),
    (N'Lenovo Legion 5', N'Màn hình', N'Kích thước màn hình', N'15.6 inch', 110),
    (N'Lenovo Legion 5', N'Màn hình', N'Độ phân giải màn hình', N'WQHD', 120),
    (N'Lenovo Legion 5', N'Màn hình', N'Tần số quét', N'165 Hz', 130),
    (N'Lenovo Legion 5', N'Bộ xử lý', N'Dòng CPU', N'AMD Ryzen 7 7735HS (theo cấu hình demo)', 140),
    (N'Lenovo Legion 5', N'Bộ xử lý', N'GPU rời', N'NVIDIA GeForce RTX 4060 8 GB (cấu hình demo)', 150),
    (N'Lenovo Legion Pro 5', N'Bộ nhớ & lưu trữ', N'Loại ổ cứng', N'SSD (dung lượng theo SKU)', 10),
    (N'Lenovo Legion Pro 5', N'Bộ nhớ & lưu trữ', N'Cấu hình RAM', N'Dung lượng theo SKU, xem mục chọn phiên bản', 20),
    (N'Lenovo Legion Pro 5', N'Kết nối', N'Kết nối không dây', N'Wi-Fi và Bluetooth (chuẩn tùy cấu hình)', 30),
    (N'Lenovo Legion Pro 5', N'Kết nối', N'Cổng kết nối phổ biến', N'USB-A, USB-C, HDMI (tùy máy)', 40),
    (N'Lenovo Legion Pro 5', N'Đa phương tiện', N'Webcam', N'Tích hợp trên màn hình', 50),
    (N'Lenovo Legion Pro 5', N'Đa phương tiện', N'Âm thanh', N'Loa và microphone tích hợp', 60),
    (N'Lenovo Legion Pro 5', N'Thông tin khác', N'Nhu cầu sử dụng', N'Học tập, làm việc và giải trí', 70),
    (N'Lenovo Legion Pro 5', N'Thông tin khác', N'Hệ điều hành', N'Tùy cấu hình xuất xưởng / cài đặt thực tế', 80),
    (N'Lenovo Legion Pro 5', N'Thiết kế', N'Kiểu máy', N'Laptop gaming', 90),
    (N'Lenovo Legion Pro 5', N'Thiết kế', N'Bàn phím', N'Bàn phím gaming tích hợp', 100),
    (N'Lenovo Legion Pro 5', N'Màn hình', N'Kích thước màn hình', N'16 inch', 110),
    (N'Lenovo Legion Pro 5', N'Màn hình', N'Độ phân giải màn hình', N'WQXGA', 120),
    (N'Lenovo Legion Pro 5', N'Màn hình', N'Tần số quét', N'240 Hz', 130),
    (N'Lenovo Legion Pro 5', N'Bộ xử lý', N'Dòng CPU', N'Intel Core i9-14900HX (theo cấu hình demo)', 140),
    (N'Lenovo Legion Pro 5', N'Bộ xử lý', N'GPU rời', N'NVIDIA GeForce RTX 4070 8 GB (cấu hình demo)', 150),
    (N'Lenovo Legion M300 RGB', N'Thông tin chung', N'Loại sản phẩm', N'Chuột máy tính / gaming', 10),
    (N'Lenovo Legion M300 RGB', N'Thông tin chung', N'Cảm biến', N'Cảm biến quang học', 20),
    (N'Lenovo Legion M300 RGB', N'Thông tin chung', N'Thiết kế', N'Chuột cho người dùng PC/laptop', 30),
    (N'Lenovo Legion M300 RGB', N'Thông tin chung', N'Chức năng', N'Điều khiển con trỏ, thao tác và chơi game', 40),
    (N'Lenovo Legion M300 RGB', N'Tương thích', N'Thiết bị hỗ trợ', N'Máy tính/laptop có kết nối phù hợp', 50),
    (N'Lenovo Legion M300 RGB', N'Tương thích', N'Hệ điều hành', N'Tương thích phụ thuộc driver và cổng kết nối', 60),
    (N'Lenovo Legion M300 RGB', N'Hiệu năng', N'DPI tối đa', N'8.000 DPI (theo dữ liệu mẫu)', 70),
    (N'Lenovo Legion M300 RGB', N'Hiệu năng', N'Đèn LED', N'RGB', 80),
    (N'Lenovo Legion M300 RGB', N'Kết nối', N'Kiểu kết nối', N'Có dây', 90),
    (N'Lenovo Legion M300 RGB', N'Kết nối', N'Giao tiếp', N'USB-A', 100),
    (N'Lenovo Legion M600 Wireless', N'Thông tin chung', N'Loại sản phẩm', N'Chuột máy tính / gaming', 10),
    (N'Lenovo Legion M600 Wireless', N'Thông tin chung', N'Cảm biến', N'Cảm biến quang học', 20),
    (N'Lenovo Legion M600 Wireless', N'Thông tin chung', N'Thiết kế', N'Chuột cho người dùng PC/laptop', 30),
    (N'Lenovo Legion M600 Wireless', N'Thông tin chung', N'Chức năng', N'Điều khiển con trỏ, thao tác và chơi game', 40),
    (N'Lenovo Legion M600 Wireless', N'Tương thích', N'Thiết bị hỗ trợ', N'Máy tính/laptop có kết nối phù hợp', 50),
    (N'Lenovo Legion M600 Wireless', N'Tương thích', N'Hệ điều hành', N'Tương thích phụ thuộc driver và cổng kết nối', 60),
    (N'Lenovo Legion M600 Wireless', N'Hiệu năng', N'DPI tối đa', N'16.000 DPI (theo dữ liệu mẫu)', 70),
    (N'Lenovo Legion M600 Wireless', N'Hiệu năng', N'Tùy chỉnh độ nhạy', N'Có', 110),
    (N'Lenovo Legion M600 Wireless', N'Kết nối', N'Kiểu kết nối', N'Không dây', 90),
    (N'Lenovo Legion M600 Wireless', N'Kết nối', N'Giao tiếp', N'Bluetooth / bộ thu không dây (tùy chế độ)', 100),
    (N'Lenovo Legion K300 RGB', N'Thông tin chung', N'Loại sản phẩm', N'Bàn phím máy tính', 10),
    (N'Lenovo Legion K300 RGB', N'Thông tin chung', N'Bố cục', N'Bàn phím vật lý', 20),
    (N'Lenovo Legion K300 RGB', N'Thông tin chung', N'Mục đích', N'Nhập liệu và điều khiển máy tính', 30),
    (N'Lenovo Legion K300 RGB', N'Thông tin chung', N'Phím chức năng', N'Có các phím điều khiển và phím tắt', 40),
    (N'Lenovo Legion K300 RGB', N'Tương thích', N'Thiết bị hỗ trợ', N'PC và laptop tương thích', 50),
    (N'Lenovo Legion K300 RGB', N'Tương thích', N'Cài đặt', N'Kết nối với máy tính qua giao tiếp hỗ trợ', 60),
    (N'Lenovo Legion K300 RGB', N'Thiết kế', N'Loại bàn phím', N'Bàn phím gaming', 70),
    (N'Lenovo Legion K300 RGB', N'Thiết kế', N'Đèn nền', N'RGB (5 vùng theo dữ liệu mẫu)', 80),
    (N'Lenovo Legion K300 RGB', N'Kết nối', N'Kiểu kết nối', N'Có dây', 90),
    (N'Lenovo Legion K300 RGB', N'Kết nối', N'Giao tiếp', N'USB-A', 100),
    (N'Lenovo Go Wireless Split Keyboard', N'Thông tin chung', N'Loại sản phẩm', N'Bàn phím máy tính', 10),
    (N'Lenovo Go Wireless Split Keyboard', N'Thông tin chung', N'Bố cục', N'Bàn phím vật lý', 20),
    (N'Lenovo Go Wireless Split Keyboard', N'Thông tin chung', N'Mục đích', N'Nhập liệu và điều khiển máy tính', 30),
    (N'Lenovo Go Wireless Split Keyboard', N'Thông tin chung', N'Phím chức năng', N'Có các phím điều khiển và phím tắt', 40),
    (N'Lenovo Go Wireless Split Keyboard', N'Tương thích', N'Thiết bị hỗ trợ', N'PC và laptop tương thích', 50),
    (N'Lenovo Go Wireless Split Keyboard', N'Tương thích', N'Cài đặt', N'Kết nối với máy tính qua giao tiếp hỗ trợ', 60),
    (N'Lenovo Go Wireless Split Keyboard', N'Thiết kế', N'Loại bàn phím', N'Bàn phím công thái học chia đôi', 70),
    (N'Lenovo Go Wireless Split Keyboard', N'Thiết kế', N'Kiểu thiết kế', N'Split / ergonomic', 110),
    (N'Lenovo Go Wireless Split Keyboard', N'Kết nối', N'Kiểu kết nối', N'Không dây', 90),
    (N'Lenovo Go Wireless Split Keyboard', N'Kết nối', N'Nguồn điện', N'Pin hoặc nguồn phù hợp với phiên bản thiết bị', 120),
    (N'Lenovo 300 FHD Webcam', N'Hình ảnh & video', N'Độ phân giải', N'1920 × 1080 (Full HD)', 10),
    (N'Lenovo 300 FHD Webcam', N'Hình ảnh & video', N'Loại thiết bị', N'Webcam rời', 20),
    (N'Lenovo 300 FHD Webcam', N'Hình ảnh & video', N'Mục đích', N'Họp trực tuyến, học tập và gọi video', 30),
    (N'Lenovo 300 FHD Webcam', N'Tính năng', N'Microphone', N'Tích hợp', 40),
    (N'Lenovo 300 FHD Webcam', N'Tính năng', N'Chân đế', N'Gắn trên màn hình hoặc vị trí phù hợp', 50),
    (N'Lenovo 300 FHD Webcam', N'Tính năng', N'Lấy nét', N'Cơ chế lấy nét tùy mẫu', 60),
    (N'Lenovo 300 FHD Webcam', N'Tương thích', N'Thiết bị hỗ trợ', N'PC/laptop có cổng kết nối phù hợp', 70),
    (N'Lenovo 300 FHD Webcam', N'Tương thích', N'Phần mềm', N'Ứng dụng họp và gọi video hỗ trợ webcam', 80),
    (N'Lenovo 300 FHD Webcam', N'Kết nối', N'Cổng kết nối', N'USB-A (theo dữ liệu mẫu)', 90),
    (N'Lenovo Performance FHD Webcam', N'Hình ảnh & video', N'Độ phân giải', N'1920 × 1080 (Full HD)', 10),
    (N'Lenovo Performance FHD Webcam', N'Hình ảnh & video', N'Loại thiết bị', N'Webcam rời', 20),
    (N'Lenovo Performance FHD Webcam', N'Hình ảnh & video', N'Mục đích', N'Họp trực tuyến, học tập và gọi video', 30),
    (N'Lenovo Performance FHD Webcam', N'Tính năng', N'Microphone', N'Tích hợp', 40),
    (N'Lenovo Performance FHD Webcam', N'Tính năng', N'Chân đế', N'Gắn trên màn hình hoặc vị trí phù hợp', 50),
    (N'Lenovo Performance FHD Webcam', N'Tính năng', N'Lấy nét', N'Cơ chế lấy nét tùy mẫu', 60),
    (N'Lenovo Performance FHD Webcam', N'Tương thích', N'Thiết bị hỗ trợ', N'PC/laptop có cổng kết nối phù hợp', 70),
    (N'Lenovo Performance FHD Webcam', N'Tương thích', N'Phần mềm', N'Ứng dụng họp và gọi video hỗ trợ webcam', 80),
    (N'Lenovo Performance FHD Webcam', N'Kết nối', N'Cổng kết nối', N'USB-C (theo dữ liệu mẫu)', 90),
    (N'Lenovo Laptop Backpack 15.6"', N'Thiết kế', N'Loại sản phẩm', N'Balo đựng laptop', 10),
    (N'Lenovo Laptop Backpack 15.6"', N'Thiết kế', N'Kiểu đeo', N'Hai quai đeo vai', 20),
    (N'Lenovo Laptop Backpack 15.6"', N'Thiết kế', N'Ngăn chứa', N'Ngăn laptop và ngăn phụ kiện', 30),
    (N'Lenovo Laptop Backpack 15.6"', N'Thiết kế', N'Kiểu sử dụng', N'Di chuyển, đi học, đi làm', 40),
    (N'Lenovo Laptop Backpack 15.6"', N'Khả năng sử dụng', N'Bảo vệ thiết bị', N'Ngăn đựng máy tính riêng', 50),
    (N'Lenovo Laptop Backpack 15.6"', N'Khả năng sử dụng', N'Phụ kiện phù hợp', N'Chuột, sạc, cáp và vật dụng cá nhân', 60),
    (N'Lenovo Laptop Backpack 15.6"', N'Khả năng sử dụng', N'Chống nước', N'Khả năng hạn chế thấm tùy vật liệu, không ngâm nước', 70),
    (N'Lenovo Laptop Backpack 15.6"', N'Kích thước & tương thích', N'Kích thước laptop', N'Tối đa 15.6 inch (theo dữ liệu demo)', 80),
    (N'Lenovo Laptop Backpack 15.6"', N'Kích thước & tương thích', N'Khối lượng', N'Khoảng 0.5 kg (theo dữ liệu demo)', 90),
    (N'Lenovo Legion Gaming Backpack', N'Thiết kế', N'Loại sản phẩm', N'Balo đựng laptop', 10),
    (N'Lenovo Legion Gaming Backpack', N'Thiết kế', N'Kiểu đeo', N'Hai quai đeo vai', 20),
    (N'Lenovo Legion Gaming Backpack', N'Thiết kế', N'Ngăn chứa', N'Ngăn laptop và ngăn phụ kiện', 30),
    (N'Lenovo Legion Gaming Backpack', N'Thiết kế', N'Kiểu sử dụng', N'Di chuyển, đi học, đi làm', 40),
    (N'Lenovo Legion Gaming Backpack', N'Khả năng sử dụng', N'Bảo vệ thiết bị', N'Ngăn đựng máy tính riêng', 50),
    (N'Lenovo Legion Gaming Backpack', N'Khả năng sử dụng', N'Phụ kiện phù hợp', N'Chuột, sạc, cáp và vật dụng cá nhân', 60),
    (N'Lenovo Legion Gaming Backpack', N'Khả năng sử dụng', N'Chống nước', N'Khả năng hạn chế thấm tùy vật liệu, không ngâm nước', 70),
    (N'Lenovo Legion Gaming Backpack', N'Kích thước & tương thích', N'Kích thước laptop', N'Tối đa 17 inch (theo dữ liệu demo)', 80),
    (N'Lenovo Legion Gaming Backpack', N'Kích thước & tương thích', N'Khối lượng', N'Khoảng 0.8 kg (theo dữ liệu demo)', 90),
    (N'Apple Watch SE 2', N'Theo dõi sức khỏe', N'Theo dõi nhịp tim', N'Có', 10),
    (N'Apple Watch SE 2', N'Theo dõi sức khỏe', N'Theo dõi vận động', N'Bước chân, bài tập và mức vận động', 20),
    (N'Apple Watch SE 2', N'Theo dõi sức khỏe', N'Theo dõi giấc ngủ', N'Có', 30),
    (N'Apple Watch SE 2', N'Kết nối', N'Định vị', N'GPS', 40),
    (N'Apple Watch SE 2', N'Kết nối', N'Kết nối không dây', N'Bluetooth (và Wi-Fi tùy mẫu)', 50),
    (N'Apple Watch SE 2', N'Kết nối', N'Đồng bộ', N'Thông qua ứng dụng tương thích trên điện thoại', 60),
    (N'Apple Watch SE 2', N'Thiết kế', N'Loại thiết bị', N'Đồng hồ thông minh', 70),
    (N'Apple Watch SE 2', N'Thiết kế', N'Kháng nước', N'Có, theo giới hạn công bố của hãng', 80),
    (N'Apple Watch SE 2', N'Màn hình', N'Công nghệ màn hình', N'Retina OLED', 90),
    (N'Apple Watch SE 2', N'Màn hình', N'Kích thước vỏ', N'40/44 mm (tùy SKU)', 100),
    (N'Apple Watch SE 2', N'Phần mềm', N'Hệ điều hành', N'watchOS', 110),
    (N'Apple Watch SE 2', N'Phần mềm', N'Tương thích', N'iPhone tương thích', 120),
    (N'Apple Watch SE 2', N'Pin và sạc', N'Thời lượng pin', N'Tối đa khoảng 18 giờ (theo Apple)', 130),
    (N'Samsung Galaxy Watch7', N'Theo dõi sức khỏe', N'Theo dõi nhịp tim', N'Có', 10),
    (N'Samsung Galaxy Watch7', N'Theo dõi sức khỏe', N'Theo dõi vận động', N'Bước chân, bài tập và mức vận động', 20),
    (N'Samsung Galaxy Watch7', N'Theo dõi sức khỏe', N'Theo dõi giấc ngủ', N'Có', 30),
    (N'Samsung Galaxy Watch7', N'Kết nối', N'Định vị', N'GPS', 40),
    (N'Samsung Galaxy Watch7', N'Kết nối', N'Kết nối không dây', N'Bluetooth (và Wi-Fi tùy mẫu)', 50),
    (N'Samsung Galaxy Watch7', N'Kết nối', N'Đồng bộ', N'Thông qua ứng dụng tương thích trên điện thoại', 60),
    (N'Samsung Galaxy Watch7', N'Thiết kế', N'Loại thiết bị', N'Đồng hồ thông minh', 70),
    (N'Samsung Galaxy Watch7', N'Thiết kế', N'Kháng nước', N'Có, theo giới hạn công bố của hãng', 80),
    (N'Samsung Galaxy Watch7', N'Màn hình', N'Công nghệ màn hình', N'Super AMOLED', 90),
    (N'Samsung Galaxy Watch7', N'Màn hình', N'Kích thước vỏ', N'40/44 mm (tùy SKU)', 100),
    (N'Samsung Galaxy Watch7', N'Phần mềm', N'Hệ điều hành', N'Wear OS / One UI Watch', 110),
    (N'Samsung Galaxy Watch7', N'Phần mềm', N'Tương thích', N'Điện thoại Android tương thích', 120),
    (N'Samsung Galaxy Watch7', N'Pin và sạc', N'Sạc', N'Sạc không dây', 140),
    (N'Garmin Forerunner 165', N'Theo dõi sức khỏe', N'Theo dõi nhịp tim', N'Có', 10),
    (N'Garmin Forerunner 165', N'Theo dõi sức khỏe', N'Theo dõi vận động', N'Bước chân, bài tập và mức vận động', 20),
    (N'Garmin Forerunner 165', N'Theo dõi sức khỏe', N'Theo dõi giấc ngủ', N'Có', 30),
    (N'Garmin Forerunner 165', N'Kết nối', N'Định vị', N'GPS', 40),
    (N'Garmin Forerunner 165', N'Kết nối', N'Kết nối không dây', N'Bluetooth (và Wi-Fi tùy mẫu)', 50),
    (N'Garmin Forerunner 165', N'Kết nối', N'Đồng bộ', N'Thông qua ứng dụng tương thích trên điện thoại', 60),
    (N'Garmin Forerunner 165', N'Thiết kế', N'Loại thiết bị', N'Đồng hồ thông minh', 70),
    (N'Garmin Forerunner 165', N'Thiết kế', N'Kháng nước', N'Có, theo giới hạn công bố của hãng', 80),
    (N'Garmin Forerunner 165', N'Màn hình', N'Công nghệ màn hình', N'AMOLED', 90),
    (N'Garmin Forerunner 165', N'Màn hình', N'Kích thước màn hình', N'1.2 inch', 150),
    (N'Garmin Forerunner 165', N'Phần mềm', N'Chế độ tập luyện', N'Theo dõi chạy bộ, bài tập gợi ý', 160),
    (N'Garmin Forerunner 165', N'Phần mềm', N'Tương thích', N'Garmin Connect trên điện thoại tương thích', 120),
    (N'Garmin Forerunner 165', N'Pin và sạc', N'Thời lượng pin', N'Tối đa 11 ngày ở chế độ đồng hồ thông minh (theo Garmin)', 130),
    (N'Sony WH-1000XM5', N'Thiết kế', N'Kiểu tai nghe', N'Chụp tai (over-ear)', 10),
    (N'Sony WH-1000XM5', N'Thiết kế', N'Thiết kế', N'Có thể điều chỉnh phần đệm và vòng đầu', 160),
    (N'Sony WH-1000XM5', N'Âm thanh', N'Chống ồn chủ động', N'Có (ANC)', 60),
    (N'Sony WH-1000XM5', N'Âm thanh', N'Microphone', N'Tích hợp, hỗ trợ đàm thoại', 40),
    (N'Sony WH-1000XM5', N'Âm thanh', N'Dải âm', N'Âm thanh stereo', 170),
    (N'Sony WH-1000XM5', N'Kết nối', N'Kết nối chính', N'Bluetooth', 20),
    (N'Sony WH-1000XM5', N'Kết nối', N'Kết nối có dây', N'Cáp âm thanh 3.5 mm', 180),
    (N'Sony WH-1000XM5', N'Kết nối', N'Cổng sạc', N'USB-C', 190),
    (N'Sony WH-1000XM5', N'Điều khiển', N'Chức năng', N'Nghe nhạc, gọi điện, điều chỉnh âm lượng', 200),
    (N'Sony WH-1000XM5', N'Âm thanh', N'Driver', N'30 mm', 210),
    (N'Sony WH-1000XM5', N'Âm thanh', N'Công nghệ chống ồn', N'HD Noise Cancelling Processor QN1, Integrated Processor V1', 220),
    (N'Sony WH-1000XM5', N'Pin và sạc', N'Thời lượng pin', N'Tối đa 30 giờ (bật ANC)', 230),
    (N'Sony WH-1000XM5', N'Kết nối', N'Bluetooth', N'5.2', 90),
    (N'JBL Tune 770NC', N'Thiết kế', N'Kiểu tai nghe', N'Chụp tai (over-ear)', 10),
    (N'JBL Tune 770NC', N'Thiết kế', N'Thiết kế', N'Có thể điều chỉnh phần đệm và vòng đầu', 160),
    (N'JBL Tune 770NC', N'Âm thanh', N'Chống ồn chủ động', N'Có (ANC)', 60),
    (N'JBL Tune 770NC', N'Âm thanh', N'Microphone', N'Tích hợp, hỗ trợ đàm thoại', 40),
    (N'JBL Tune 770NC', N'Âm thanh', N'Dải âm', N'Âm thanh stereo', 170),
    (N'JBL Tune 770NC', N'Kết nối', N'Kết nối chính', N'Bluetooth', 20),
    (N'JBL Tune 770NC', N'Kết nối', N'Kết nối có dây', N'Cáp âm thanh 3.5 mm', 180),
    (N'JBL Tune 770NC', N'Kết nối', N'Cổng sạc', N'USB-C', 190),
    (N'JBL Tune 770NC', N'Điều khiển', N'Chức năng', N'Nghe nhạc, gọi điện, điều chỉnh âm lượng', 200),
    (N'JBL Tune 770NC', N'Âm thanh', N'Công nghệ âm thanh', N'JBL Pure Bass Sound', 240),
    (N'JBL Tune 770NC', N'Âm thanh', N'Chế độ chống ồn', N'Adaptive Noise Cancelling', 250),
    (N'JBL Tune 770NC', N'Kết nối', N'Bluetooth', N'5.3', 90),
    (N'JBL Tune 770NC', N'Kết nối', N'Kết nối đa điểm', N'Có', 260),
    (N'JBL Tune 770NC', N'Pin và sạc', N'Thời lượng pin', N'Tối đa 70 giờ khi tắt ANC', 230),
    (N'JBL Tune 770NC', N'Pin và sạc', N'Sạc nhanh', N'5 phút cho khoảng 3 giờ nghe', 270),
    (N'Canon EOS R50', N'Cảm biến & ảnh', N'Loại máy', N'Máy ảnh mirrorless, ống kính rời', 10),
    (N'Canon EOS R50', N'Cảm biến & ảnh', N'Kích thước cảm biến', N'APS-C', 20),
    (N'Canon EOS R50', N'Cảm biến & ảnh', N'Định dạng ảnh', N'JPEG / RAW', 30),
    (N'Canon EOS R50', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth', 40),
    (N'Canon EOS R50', N'Kết nối', N'Chức năng kết nối', N'Truyền ảnh và điều khiển từ thiết bị tương thích', 50),
    (N'Canon EOS R50', N'Quay video', N'Quay video', N'Có hỗ trợ video độ phân giải cao', 60),
    (N'Canon EOS R50', N'Quay video', N'Microphone', N'Có hỗ trợ ghi âm khi quay video', 70),
    (N'Canon EOS R50', N'Ống kính', N'Bộ ống kính', N'Body hoặc bộ kit theo SKU đã chọn', 80),
    (N'Canon EOS R50', N'Cảm biến & ảnh', N'Độ phân giải hữu dụng', N'24.2 MP', 90),
    (N'Canon EOS R50', N'Cảm biến & ảnh', N'Ngàm ống kính', N'Canon RF / RF-S', 100),
    (N'Canon EOS R50', N'Quay video', N'Độ phân giải video', N'4K UHD', 110),
    (N'Canon EOS R50', N'Lấy nét & chống rung', N'Lấy nét tự động', N'Dual Pixel CMOS AF II', 120),
    (N'Canon EOS R50', N'Lấy nét & chống rung', N'Chống rung', N'Phụ thuộc ống kính và chế độ quay video', 130),
    (N'Sony Alpha A6400', N'Cảm biến & ảnh', N'Loại máy', N'Máy ảnh mirrorless, ống kính rời', 10),
    (N'Sony Alpha A6400', N'Cảm biến & ảnh', N'Kích thước cảm biến', N'APS-C', 20),
    (N'Sony Alpha A6400', N'Cảm biến & ảnh', N'Định dạng ảnh', N'JPEG / RAW', 30),
    (N'Sony Alpha A6400', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth', 40),
    (N'Sony Alpha A6400', N'Kết nối', N'Chức năng kết nối', N'Truyền ảnh và điều khiển từ thiết bị tương thích', 50),
    (N'Sony Alpha A6400', N'Quay video', N'Quay video', N'Có hỗ trợ video độ phân giải cao', 60),
    (N'Sony Alpha A6400', N'Quay video', N'Microphone', N'Có hỗ trợ ghi âm khi quay video', 70),
    (N'Sony Alpha A6400', N'Ống kính', N'Bộ ống kính', N'Body hoặc bộ kit theo SKU đã chọn', 80),
    (N'Sony Alpha A6400', N'Cảm biến & ảnh', N'Độ phân giải hữu dụng', N'24.2 MP', 90),
    (N'Sony Alpha A6400', N'Cảm biến & ảnh', N'Ngàm ống kính', N'Sony E-mount', 100),
    (N'Sony Alpha A6400', N'Quay video', N'Độ phân giải video', N'4K', 110),
    (N'Sony Alpha A6400', N'Lấy nét & chống rung', N'Lấy nét tự động', N'Real-time Tracking / Eye AF', 120),
    (N'Sony Alpha A6400', N'Lấy nét & chống rung', N'Chống rung', N'Không có IBIS trong thân máy', 130),
    (N'Fujifilm X-S20', N'Cảm biến & ảnh', N'Loại máy', N'Máy ảnh mirrorless, ống kính rời', 10),
    (N'Fujifilm X-S20', N'Cảm biến & ảnh', N'Kích thước cảm biến', N'APS-C', 20),
    (N'Fujifilm X-S20', N'Cảm biến & ảnh', N'Định dạng ảnh', N'JPEG / RAW', 30),
    (N'Fujifilm X-S20', N'Kết nối', N'Kết nối không dây', N'Wi-Fi, Bluetooth', 40),
    (N'Fujifilm X-S20', N'Kết nối', N'Chức năng kết nối', N'Truyền ảnh và điều khiển từ thiết bị tương thích', 50),
    (N'Fujifilm X-S20', N'Quay video', N'Quay video', N'Có hỗ trợ video độ phân giải cao', 60),
    (N'Fujifilm X-S20', N'Quay video', N'Microphone', N'Có hỗ trợ ghi âm khi quay video', 70),
    (N'Fujifilm X-S20', N'Ống kính', N'Bộ ống kính', N'Body hoặc bộ kit theo SKU đã chọn', 80),
    (N'Fujifilm X-S20', N'Cảm biến & ảnh', N'Độ phân giải hữu dụng', N'26.1 MP', 90),
    (N'Fujifilm X-S20', N'Cảm biến & ảnh', N'Loại cảm biến', N'X-Trans CMOS 4', 140),
    (N'Fujifilm X-S20', N'Cảm biến & ảnh', N'Ngàm ống kính', N'Fujifilm X-mount', 100),
    (N'Fujifilm X-S20', N'Quay video', N'Độ phân giải video', N'Tối đa 6.2K 30p', 110),
    (N'Fujifilm X-S20', N'Lấy nét & chống rung', N'Chống rung', N'IBIS trong thân máy', 130),
    (N'Fujifilm X-S20', N'Lấy nét & chống rung', N'Lấy nét tự động', N'Lấy nét tự động nhận diện chủ thể', 120);
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

BEGIN TRY
IF (SELECT COUNT(DISTINCT product_name) FROM #SpecSeed) <> 39
    THROW 56002, N'Seed phai du 39 product_name.', 1;
IF EXISTS (
    SELECT 1 FROM (SELECT DISTINCT product_name FROM #SpecSeed) s
    OUTER APPLY (SELECT COUNT(*) n FROM dbo.PRODUCT p WHERE p.product_name = s.product_name) c
    WHERE c.n <> 1
)
    THROW 56003, N'Product khong ton tai hoac trung ten. Kiem tra bang PRODUCT.', 1;
IF EXISTS (
    SELECT 1 FROM (SELECT DISTINCT attribute_name FROM #SpecSeed) s
    OUTER APPLY (SELECT COUNT(*) n FROM dbo.ATTRIBUTE a WHERE a.attribute_name = s.attribute_name) c
    WHERE c.n > 1
)
    THROW 56004, N'Bang ATTRIBUTE co ten thuoc tinh trung. Can xu ly truoc.', 1;
IF EXISTS (
    SELECT 1 FROM dbo.PRODUCT p JOIN #SpecSeed x ON x.product_name = p.product_name
    GROUP BY p.category_id, x.attribute_name
    HAVING COUNT(DISTINCT x.group_name) > 1
)
    THROW 56005, N'Mot category/attribute duoc gan nhieu group_name.', 1;

 BEGIN TRANSACTION;

 INSERT INTO dbo.ATTRIBUTE(attribute_name)
 SELECT DISTINCT x.attribute_name FROM #SpecSeed x
 WHERE NOT EXISTS (
     SELECT 1 FROM dbo.ATTRIBUTE a WITH (UPDLOCK, HOLDLOCK)
     WHERE a.attribute_name = x.attribute_name
 );


 INSERT INTO dbo.PRODUCT_SPECIFICATION(product_id,attribute_id,value)
 SELECT p.product_id,a.attribute_id,x.spec_value
 FROM #SpecSeed x
 JOIN dbo.PRODUCT p ON p.product_name=x.product_name
 JOIN dbo.ATTRIBUTE a ON a.attribute_name=x.attribute_name
 WHERE NOT EXISTS (
   SELECT 1 FROM dbo.PRODUCT_SPECIFICATION ps WITH (UPDLOCK,HOLDLOCK)
   WHERE ps.product_id=p.product_id AND ps.attribute_id=a.attribute_id
 );

 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;


;WITH CategoryAttributePairs AS (
    SELECT DISTINCT p.category_id, ps.attribute_id, CAST(1 AS BIT) AS has_spec, CAST(0 AS BIT) AS has_variant
    FROM dbo.PRODUCT_SPECIFICATION ps JOIN dbo.PRODUCT p ON p.product_id=ps.product_id
    UNION ALL
    SELECT DISTINCT p.category_id, sav.attribute_id, CAST(0 AS BIT), CAST(1 AS BIT)
    FROM dbo.SKU_ATTRIBUTE_VALUE sav
    JOIN dbo.PRODUCT_SKU sku ON sku.sku_id=sav.sku_id
    JOIN dbo.PRODUCT p ON p.product_id=sku.product_id
), GroupedPairs AS (
    SELECT category_id,attribute_id,MAX(CAST(has_spec AS INT)) AS has_spec,
           MAX(CAST(has_variant AS INT)) AS has_variant
    FROM CategoryAttributePairs GROUP BY category_id,attribute_id
), ExtraSpecs AS (
    SELECT p.category_id,a.attribute_id,
           MIN(x.group_name) AS group_name,MIN(x.display_order) AS display_order
    FROM #SpecSeed x
    JOIN dbo.PRODUCT p ON p.product_name=x.product_name
    JOIN dbo.ATTRIBUTE a ON a.attribute_name=x.attribute_name
    GROUP BY p.category_id,a.attribute_id
)
INSERT INTO dbo.CATEGORY_ATTRIBUTE
    (category_id,attribute_id,group_name,attribute_type,is_required,is_filterable,display_order)
SELECT pairs.category_id,pairs.attribute_id,
       CASE
         WHEN pairs.has_variant=1 THEN
           CASE WHEN c.category_name LIKE N'Laptop%' THEN N'Cấu hình'
                WHEN c.category_name=N'Smartphone' THEN N'Phiên bản'
                WHEN a.attribute_name IN (N'RAM',N'Dung lượng lưu trữ') THEN N'Cấu hình'
                WHEN a.attribute_name=N'Màu sắc' THEN N'Màu sắc'
                WHEN a.attribute_name=N'Kích thước vỏ' THEN N'Kích cỡ'
                ELSE N'Phiên bản' END
         WHEN extra.group_name IS NOT NULL THEN extra.group_name
         WHEN a.attribute_name IN (N'Màn hình',N'Độ phân giải',N'Tần số quét',N'Loại màn hình') THEN N'Màn hình'
         WHEN a.attribute_name IN (N'RAM',N'Dung lượng lưu trữ',N'Chip xử lý (CPU)',N'Card đồ họa (GPU)') THEN N'Hiệu năng và bộ nhớ'
         WHEN a.attribute_name IN (N'Pin',N'Dung lượng pin',N'Công suất sạc') THEN N'Pin và sạc'
         WHEN a.attribute_name IN (N'Kết nối',N'Loại kết nối') THEN N'Kết nối'
         WHEN a.attribute_name IN (N'Kích thước',N'Trọng lượng',N'Chất liệu',N'Màu sắc') THEN N'Thiết kế'
         ELSE N'Tính năng và thông số khác' END,
       CASE WHEN pairs.has_spec=1 AND pairs.has_variant=1 THEN 'BOTH'
            WHEN pairs.has_variant=1 THEN 'VARIANT'
            ELSE 'SPECIFICATION' END,
       0,
       CASE WHEN pairs.has_variant=1 OR a.attribute_name IN
              (N'RAM',N'Dung lượng lưu trữ',N'Chip xử lý (CPU)',N'Màn hình',N'Card đồ họa (GPU)')
            THEN 1 ELSE 0 END,
       CASE
         WHEN pairs.has_variant=1 AND c.category_name=N'Smartphone'
              AND a.attribute_name=N'Dung lượng lưu trữ' THEN 10
         WHEN pairs.has_variant=1 AND c.category_name=N'Smartphone'
              AND a.attribute_name=N'Màu sắc' THEN 20
         WHEN pairs.has_variant=1 AND c.category_name LIKE N'Laptop%'
              AND a.attribute_name=N'RAM' THEN 10
         WHEN pairs.has_variant=1 AND c.category_name LIKE N'Laptop%'
              AND a.attribute_name=N'Dung lượng lưu trữ' THEN 20
         WHEN pairs.has_variant=1 AND c.category_name LIKE N'Laptop%'
              AND a.attribute_name=N'Màu sắc' THEN 30
         WHEN pairs.has_variant=1 THEN 100+a.attribute_id
         WHEN extra.display_order IS NOT NULL THEN extra.display_order
         ELSE a.attribute_id END
FROM GroupedPairs pairs
JOIN dbo.CATEGORY c ON c.category_id=pairs.category_id
JOIN dbo.ATTRIBUTE a ON a.attribute_id=pairs.attribute_id
LEFT JOIN ExtraSpecs extra ON extra.category_id=pairs.category_id
                           AND extra.attribute_id=pairs.attribute_id;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

PRINT N'OECS - specifications and category attributes ready.';
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;



SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.PRODUCT',N'U') IS NULL
    THROW 57001,N'Missing dbo.PRODUCT. Initialize OECS first.',1;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;
DROP TABLE IF EXISTS #OverviewSeed;
CREATE TABLE #OverviewSeed(
  product_name NVARCHAR(255) NOT NULL,
  section_key VARCHAR(40) NOT NULL,
  section_title NVARCHAR(160) NOT NULL,
  section_content NVARCHAR(1500) NOT NULL,
  display_order INT NOT NULL,
  PRIMARY KEY(product_name,section_key)
);

INSERT INTO #OverviewSeed(product_name,section_key,section_title,section_content,display_order)
VALUES
  (N'iPhone 15 Pro', 'display', N'Màn hình mượt và rõ nét', N'iPhone 15 Pro sử dụng Super Retina XDR OLED, phù hợp cho việc xem nội dung, đọc tài liệu và sử dụng ứng dụng hằng ngày. Tần số quét ProMotion thích ứng đến 120 Hz giúp các thao tác cuộn và chuyển cảnh mượt mà.', 10),
  (N'iPhone 15 Pro', 'camera', N'Camera cho nhiều khoảnh khắc', N'Cụm camera của máy gồm 48 MP chính + 12 MP siêu rộng + 12 MP tele. Người dùng có thể chuyển giữa các góc chụp phù hợp với chân dung, phong cảnh và nhu cầu ghi lại hoạt động thường ngày.', 20),
  (N'iPhone 15 Pro', 'daily', N'Kết nối và trải nghiệm', N'Thiết bị hỗ trợ kết nối 5G cùng các chuẩn không dây hiện đại. Thông tin pin: Lên đến 23 giờ (theo Apple). Dung lượng bộ nhớ và màu sắc thay đổi theo SKU bạn lựa chọn ở phía trên.', 30),
  (N'iPhone 15 Pro Max', 'display', N'Màn hình mượt và rõ nét', N'iPhone 15 Pro Max sử dụng Super Retina XDR OLED, phù hợp cho việc xem nội dung, đọc tài liệu và sử dụng ứng dụng hằng ngày. Tần số quét ProMotion thích ứng đến 120 Hz giúp các thao tác cuộn và chuyển cảnh mượt mà.', 10),
  (N'iPhone 15 Pro Max', 'camera', N'Camera cho nhiều khoảnh khắc', N'Cụm camera của máy gồm 48 MP chính + 12 MP siêu rộng + 12 MP tele. Người dùng có thể chuyển giữa các góc chụp phù hợp với chân dung, phong cảnh và nhu cầu ghi lại hoạt động thường ngày.', 20),
  (N'iPhone 15 Pro Max', 'daily', N'Kết nối và trải nghiệm', N'Thiết bị hỗ trợ kết nối 5G cùng các chuẩn không dây hiện đại. Thông tin pin: Lên đến 29 giờ (theo Apple). Dung lượng bộ nhớ và màu sắc thay đổi theo SKU bạn lựa chọn ở phía trên.', 30),
  (N'iPhone 16 Pro', 'display', N'Màn hình mượt và rõ nét', N'iPhone 16 Pro sử dụng Super Retina XDR OLED, phù hợp cho việc xem nội dung, đọc tài liệu và sử dụng ứng dụng hằng ngày. Tần số quét ProMotion thích ứng đến 120 Hz giúp các thao tác cuộn và chuyển cảnh mượt mà.', 10),
  (N'iPhone 16 Pro', 'camera', N'Camera cho nhiều khoảnh khắc', N'Cụm camera của máy gồm 48 MP chính + 48 MP siêu rộng + 12 MP tele. Người dùng có thể chuyển giữa các góc chụp phù hợp với chân dung, phong cảnh và nhu cầu ghi lại hoạt động thường ngày.', 20),
  (N'iPhone 16 Pro', 'daily', N'Kết nối và trải nghiệm', N'Thiết bị hỗ trợ kết nối 5G cùng các chuẩn không dây hiện đại. Thông tin pin: Lên đến 27 giờ (theo Apple). Dung lượng bộ nhớ và màu sắc thay đổi theo SKU bạn lựa chọn ở phía trên.', 30),
  (N'iPhone 16 Pro Max', 'display', N'Màn hình mượt và rõ nét', N'iPhone 16 Pro Max sử dụng Super Retina XDR OLED, phù hợp cho việc xem nội dung, đọc tài liệu và sử dụng ứng dụng hằng ngày. Tần số quét ProMotion thích ứng đến 120 Hz giúp các thao tác cuộn và chuyển cảnh mượt mà.', 10),
  (N'iPhone 16 Pro Max', 'camera', N'Camera cho nhiều khoảnh khắc', N'Cụm camera của máy gồm 48 MP chính + 48 MP siêu rộng + 12 MP tele. Người dùng có thể chuyển giữa các góc chụp phù hợp với chân dung, phong cảnh và nhu cầu ghi lại hoạt động thường ngày.', 20),
  (N'iPhone 16 Pro Max', 'daily', N'Kết nối và trải nghiệm', N'Thiết bị hỗ trợ kết nối 5G cùng các chuẩn không dây hiện đại. Thông tin pin: Lên đến 33 giờ (theo Apple). Dung lượng bộ nhớ và màu sắc thay đổi theo SKU bạn lựa chọn ở phía trên.', 30),
  (N'Samsung Galaxy S24 Ultra', 'display', N'Màn hình mượt và rõ nét', N'Samsung Galaxy S24 Ultra sử dụng Dynamic AMOLED 2X, phù hợp cho việc xem nội dung, đọc tài liệu và sử dụng ứng dụng hằng ngày. Tần số quét Lên đến 120 Hz giúp các thao tác cuộn và chuyển cảnh mượt mà.', 10),
  (N'Samsung Galaxy S24 Ultra', 'camera', N'Camera cho nhiều khoảnh khắc', N'Cụm camera của máy gồm 200 MP chính + 12 MP siêu rộng + 50 MP tele 5x + 10 MP tele 3x. Người dùng có thể chuyển giữa các góc chụp phù hợp với chân dung, phong cảnh và nhu cầu ghi lại hoạt động thường ngày.', 20),
  (N'Samsung Galaxy S24 Ultra', 'daily', N'Kết nối và trải nghiệm', N'Thiết bị hỗ trợ kết nối 5G cùng các chuẩn không dây hiện đại. Thông tin pin: 5.000 mAh. Dung lượng bộ nhớ và màu sắc thay đổi theo SKU bạn lựa chọn ở phía trên.', 30),
  (N'Samsung Galaxy S24 Plus', 'display', N'Màn hình mượt và rõ nét', N'Samsung Galaxy S24 Plus sử dụng Dynamic AMOLED 2X, phù hợp cho việc xem nội dung, đọc tài liệu và sử dụng ứng dụng hằng ngày. Tần số quét Lên đến 120 Hz giúp các thao tác cuộn và chuyển cảnh mượt mà.', 10),
  (N'Samsung Galaxy S24 Plus', 'camera', N'Camera cho nhiều khoảnh khắc', N'Cụm camera của máy gồm 50 MP chính + 12 MP siêu rộng + 10 MP tele. Người dùng có thể chuyển giữa các góc chụp phù hợp với chân dung, phong cảnh và nhu cầu ghi lại hoạt động thường ngày.', 20),
  (N'Samsung Galaxy S24 Plus', 'daily', N'Kết nối và trải nghiệm', N'Thiết bị hỗ trợ kết nối 5G cùng các chuẩn không dây hiện đại. Thông tin pin: 4.900 mAh. Dung lượng bộ nhớ và màu sắc thay đổi theo SKU bạn lựa chọn ở phía trên.', 30),
  (N'Samsung Galaxy A55 5G', 'display', N'Màn hình mượt và rõ nét', N'Samsung Galaxy A55 5G sử dụng Super AMOLED, phù hợp cho việc xem nội dung, đọc tài liệu và sử dụng ứng dụng hằng ngày. Tần số quét Lên đến 120 Hz giúp các thao tác cuộn và chuyển cảnh mượt mà.', 10),
  (N'Samsung Galaxy A55 5G', 'camera', N'Camera cho nhiều khoảnh khắc', N'Cụm camera của máy gồm 50 MP chính + 12 MP siêu rộng + 5 MP macro. Người dùng có thể chuyển giữa các góc chụp phù hợp với chân dung, phong cảnh và nhu cầu ghi lại hoạt động thường ngày.', 20),
  (N'Samsung Galaxy A55 5G', 'daily', N'Kết nối và trải nghiệm', N'Thiết bị hỗ trợ kết nối 5G cùng các chuẩn không dây hiện đại. Thông tin pin: 5.000 mAh. Dung lượng bộ nhớ và màu sắc thay đổi theo SKU bạn lựa chọn ở phía trên.', 30),
  (N'Samsung Galaxy A35 5G', 'display', N'Màn hình mượt và rõ nét', N'Samsung Galaxy A35 5G sử dụng Super AMOLED, phù hợp cho việc xem nội dung, đọc tài liệu và sử dụng ứng dụng hằng ngày. Tần số quét Lên đến 120 Hz giúp các thao tác cuộn và chuyển cảnh mượt mà.', 10),
  (N'Samsung Galaxy A35 5G', 'camera', N'Camera cho nhiều khoảnh khắc', N'Cụm camera của máy gồm 50 MP chính + 8 MP siêu rộng + 5 MP macro. Người dùng có thể chuyển giữa các góc chụp phù hợp với chân dung, phong cảnh và nhu cầu ghi lại hoạt động thường ngày.', 20),
  (N'Samsung Galaxy A35 5G', 'daily', N'Kết nối và trải nghiệm', N'Thiết bị hỗ trợ kết nối 5G cùng các chuẩn không dây hiện đại. Thông tin pin: 5.000 mAh. Dung lượng bộ nhớ và màu sắc thay đổi theo SKU bạn lựa chọn ở phía trên.', 30),
  (N'AirPods Pro 2', 'audio', N'Trải nghiệm âm thanh', N'AirPods Pro 2 phục vụ nhu cầu nghe nhạc, xem phim và gọi điện. Hỗ trợ chống ồn chủ động: Có (ANC). Chất lượng âm thanh thực tế còn phụ thuộc nguồn phát và cách đeo.', 10),
  (N'AirPods Pro 2', 'connect', N'Kết nối tiện lợi', N'Kết nối chính: Bluetooth. Thiết kế và thao tác điều khiển được tối ưu cho việc sử dụng cùng thiết bị tương thích trong sinh hoạt hằng ngày.', 20),
  (N'AirPods Pro 2', 'battery', N'Pin và sử dụng', N'Thông tin thời lượng: Lên đến 6 giờ mỗi lần sạc (ANC bật). Khi lựa chọn phiên bản, hãy lưu ý khác biệt về chống ồn hoặc phụ kiện đi kèm nếu có.', 30),
  (N'AirPods 4', 'audio', N'Trải nghiệm âm thanh', N'AirPods 4 phục vụ nhu cầu nghe nhạc, xem phim và gọi điện. Hỗ trợ chống ồn chủ động: Tùy SKU: bản thường hoặc bản ANC. Chất lượng âm thanh thực tế còn phụ thuộc nguồn phát và cách đeo.', 10),
  (N'AirPods 4', 'connect', N'Kết nối tiện lợi', N'Kết nối chính: Bluetooth. Thiết kế và thao tác điều khiển được tối ưu cho việc sử dụng cùng thiết bị tương thích trong sinh hoạt hằng ngày.', 20),
  (N'AirPods 4', 'battery', N'Pin và sử dụng', N'Thông tin thời lượng: Lên đến 5 giờ/bản thường; bản ANC tùy chế độ. Khi lựa chọn phiên bản, hãy lưu ý khác biệt về chống ồn hoặc phụ kiện đi kèm nếu có.', 30),
  (N'Samsung Galaxy Buds3 Pro', 'audio', N'Trải nghiệm âm thanh', N'Samsung Galaxy Buds3 Pro phục vụ nhu cầu nghe nhạc, xem phim và gọi điện. Hỗ trợ chống ồn chủ động: Có (ANC). Chất lượng âm thanh thực tế còn phụ thuộc nguồn phát và cách đeo.', 10),
  (N'Samsung Galaxy Buds3 Pro', 'connect', N'Kết nối tiện lợi', N'Kết nối chính: Bluetooth. Thiết kế và thao tác điều khiển được tối ưu cho việc sử dụng cùng thiết bị tương thích trong sinh hoạt hằng ngày.', 20),
  (N'Samsung Galaxy Buds3 Pro', 'battery', N'Pin và sử dụng', N'Thông tin thời lượng: Lên đến 6 giờ (bật ANC, tùy điều kiện). Khi lựa chọn phiên bản, hãy lưu ý khác biệt về chống ồn hoặc phụ kiện đi kèm nếu có.', 30),
  (N'Samsung Galaxy Buds FE', 'audio', N'Trải nghiệm âm thanh', N'Samsung Galaxy Buds FE phục vụ nhu cầu nghe nhạc, xem phim và gọi điện. Hỗ trợ chống ồn chủ động: Có (ANC). Chất lượng âm thanh thực tế còn phụ thuộc nguồn phát và cách đeo.', 10),
  (N'Samsung Galaxy Buds FE', 'connect', N'Kết nối tiện lợi', N'Kết nối chính: Bluetooth. Thiết kế và thao tác điều khiển được tối ưu cho việc sử dụng cùng thiết bị tương thích trong sinh hoạt hằng ngày.', 20),
  (N'Samsung Galaxy Buds FE', 'battery', N'Pin và sử dụng', N'Thông tin thời lượng: Lên đến 6 giờ (bật ANC, tùy điều kiện). Khi lựa chọn phiên bản, hãy lưu ý khác biệt về chống ồn hoặc phụ kiện đi kèm nếu có.', 30),
  (N'Apple USB-C 20W Power Adapter', 'power', N'Nguồn điện phù hợp', N'Apple USB-C 20W Power Adapter là bộ tiếp hợp nguồn với công suất tối đa 20 W, hỗ trợ USB Power Delivery (PD). Tốc độ sạc thực tế được quyết định bởi cả thiết bị, dây cáp và bộ sạc.', 10),
  (N'Apple USB-C 20W Power Adapter', 'connect', N'Một cổng USB-C tiện dụng', N'Thiết kế một cổng USB-C giúp kết nối nhanh với dây cáp tương thích. Trước khi dùng, cần kiểm tra thiết bị nhận nguồn và chuẩn sạc được hỗ trợ.', 20),
  (N'Apple USB-C 20W Power Adapter', 'daily', N'Sử dụng hằng ngày', N'Thích hợp đặt tại bàn học, bàn làm việc hoặc mang theo. Hãy sử dụng cáp đạt chuẩn và tránh môi trường ẩm ướt để duy trì độ ổn định.', 30),
  (N'Samsung 25W USB-C Fast Charger', 'power', N'Nguồn điện phù hợp', N'Samsung 25W USB-C Fast Charger là bộ tiếp hợp nguồn với công suất tối đa 25 W, hỗ trợ USB PD PPS / Samsung Super Fast Charging. Tốc độ sạc thực tế được quyết định bởi cả thiết bị, dây cáp và bộ sạc.', 10),
  (N'Samsung 25W USB-C Fast Charger', 'connect', N'Một cổng USB-C tiện dụng', N'Thiết kế một cổng USB-C giúp kết nối nhanh với dây cáp tương thích. Trước khi dùng, cần kiểm tra thiết bị nhận nguồn và chuẩn sạc được hỗ trợ.', 20),
  (N'Samsung 25W USB-C Fast Charger', 'daily', N'Sử dụng hằng ngày', N'Thích hợp đặt tại bàn học, bàn làm việc hoặc mang theo. Hãy sử dụng cáp đạt chuẩn và tránh môi trường ẩm ướt để duy trì độ ổn định.', 30),
  (N'Apple USB-C Charge Cable 1m', 'connect', N'Chuẩn đầu nối rõ ràng', N'Apple USB-C Charge Cable 1m sử dụng đầu nối USB-C sang USB-C. Kiểm tra cổng thiết bị và bộ sạc trước khi chọn để tránh mua nhầm loại cáp.', 10),
  (N'Apple USB-C Charge Cable 1m', 'daily', N'Sạc và truyền dữ liệu', N'Dây cáp hỗ trợ kết nối thiết bị với bộ sạc hoặc máy tính phù hợp. Công suất và tốc độ truyền có thể bị giới hạn bởi chuẩn thiết bị, bộ sạc hoặc phiên bản cáp.', 20),
  (N'Apple USB-C Charge Cable 1m', 'design', N'Tiện dụng khi mang theo', N'Thiết kế dây cáp phù hợp nhu cầu sinh hoạt, học tập và làm việc. Tránh bẻ gập mạnh tại hai đầu nối và hạn chế kéo căng trong khi sử dụng.', 30),
  (N'Apple USB-C to Lightning Cable', 'connect', N'Chuẩn đầu nối rõ ràng', N'Apple USB-C to Lightning Cable sử dụng đầu nối USB-C sang Lightning. Kiểm tra cổng thiết bị và bộ sạc trước khi chọn để tránh mua nhầm loại cáp.', 10),
  (N'Apple USB-C to Lightning Cable', 'daily', N'Sạc và truyền dữ liệu', N'Dây cáp hỗ trợ kết nối thiết bị với bộ sạc hoặc máy tính phù hợp. Công suất và tốc độ truyền có thể bị giới hạn bởi chuẩn thiết bị, bộ sạc hoặc phiên bản cáp.', 20),
  (N'Apple USB-C to Lightning Cable', 'design', N'Tiện dụng khi mang theo', N'Thiết kế dây cáp phù hợp nhu cầu sinh hoạt, học tập và làm việc. Tránh bẻ gập mạnh tại hai đầu nối và hạn chế kéo căng trong khi sử dụng.', 30),
  (N'Samsung USB-C Cable 1m', 'connect', N'Chuẩn đầu nối rõ ràng', N'Samsung USB-C Cable 1m sử dụng đầu nối USB-C sang USB-C. Kiểm tra cổng thiết bị và bộ sạc trước khi chọn để tránh mua nhầm loại cáp.', 10),
  (N'Samsung USB-C Cable 1m', 'daily', N'Sạc và truyền dữ liệu', N'Dây cáp hỗ trợ kết nối thiết bị với bộ sạc hoặc máy tính phù hợp. Công suất và tốc độ truyền có thể bị giới hạn bởi chuẩn thiết bị, bộ sạc hoặc phiên bản cáp.', 20),
  (N'Samsung USB-C Cable 1m', 'design', N'Tiện dụng khi mang theo', N'Thiết kế dây cáp phù hợp nhu cầu sinh hoạt, học tập và làm việc. Tránh bẻ gập mạnh tại hai đầu nối và hạn chế kéo căng trong khi sử dụng.', 30),
  (N'Lenovo IdeaPad Slim 3', 'display', N'Không gian hiển thị', N'Màn hình 15.6 inch với độ phân giải Full HD giúp quan sát nội dung thuận tiện khi làm việc hay giải trí.', 10),
  (N'Lenovo IdeaPad Slim 3', 'performance', N'Hiệu năng theo cấu hình', N'Lenovo IdeaPad Slim 3 phù hợp với nhu cầu học tập, công việc văn phòng và các tác vụ hàng ngày. CPU tham khảo của cấu hình demo: Intel Core i3-1315U (theo cấu hình demo). RAM và SSD cần xem theo SKU thực tế, không mặc định mọi phiên bản có cùng cấu hình.', 20),
  (N'Lenovo IdeaPad Slim 3', 'connect', N'Kết nối và tính tiện dụng', N'Máy có webcam, loa và microphone tích hợp. Các cổng USB/HDMI, chuẩn Wi-Fi và Bluetooth phụ thuộc phiên bản máy; khi chọn mua nên đối chiếu mã cấu hình chính xác.', 30),
  (N'Lenovo ThinkBook 14', 'display', N'Không gian hiển thị', N'Màn hình 14 inch với độ phân giải WUXGA giúp quan sát nội dung thuận tiện khi làm việc hay giải trí.', 10),
  (N'Lenovo ThinkBook 14', 'performance', N'Hiệu năng theo cấu hình', N'Lenovo ThinkBook 14 phù hợp với nhu cầu học tập, công việc văn phòng và các tác vụ hàng ngày. CPU tham khảo của cấu hình demo: Intel Core i5-1335U (theo cấu hình demo). RAM và SSD cần xem theo SKU thực tế, không mặc định mọi phiên bản có cùng cấu hình.', 20),
  (N'Lenovo ThinkBook 14', 'connect', N'Kết nối và tính tiện dụng', N'Máy có webcam, loa và microphone tích hợp. Các cổng USB/HDMI, chuẩn Wi-Fi và Bluetooth phụ thuộc phiên bản máy; khi chọn mua nên đối chiếu mã cấu hình chính xác.', 30),
  (N'Lenovo IdeaPad 5', 'display', N'Không gian hiển thị', N'Màn hình 15.6 inch với độ phân giải Full HD giúp quan sát nội dung thuận tiện khi làm việc hay giải trí.', 10),
  (N'Lenovo IdeaPad 5', 'performance', N'Hiệu năng theo cấu hình', N'Lenovo IdeaPad 5 phù hợp với nhu cầu học tập, công việc văn phòng và các tác vụ hàng ngày. CPU tham khảo của cấu hình demo: AMD Ryzen 5 7530U (theo cấu hình demo). RAM và SSD cần xem theo SKU thực tế, không mặc định mọi phiên bản có cùng cấu hình.', 20),
  (N'Lenovo IdeaPad 5', 'connect', N'Kết nối và tính tiện dụng', N'Máy có webcam, loa và microphone tích hợp. Các cổng USB/HDMI, chuẩn Wi-Fi và Bluetooth phụ thuộc phiên bản máy; khi chọn mua nên đối chiếu mã cấu hình chính xác.', 30),
  (N'Lenovo LOQ 15', 'display', N'Không gian hiển thị', N'Màn hình 15.6 inch với độ phân giải Full HD, tần số quét 144 Hz giúp quan sát nội dung thuận tiện khi làm việc hay giải trí.', 10),
  (N'Lenovo LOQ 15', 'performance', N'Hiệu năng theo cấu hình', N'Lenovo LOQ 15 phù hợp với nhu cầu chơi game, giải trí và xử lý công việc nặng. CPU tham khảo của cấu hình demo: Intel Core i5-13420H (theo cấu hình demo). GPU tham khảo: NVIDIA GeForce RTX 4050 6 GB (cấu hình demo). RAM và SSD cần xem theo SKU thực tế, không mặc định mọi phiên bản có cùng cấu hình.', 20),
  (N'Lenovo LOQ 15', 'connect', N'Kết nối và tính tiện dụng', N'Máy có webcam, loa và microphone tích hợp. Các cổng USB/HDMI, chuẩn Wi-Fi và Bluetooth phụ thuộc phiên bản máy; khi chọn mua nên đối chiếu mã cấu hình chính xác.', 30),
  (N'Lenovo Legion 5', 'display', N'Không gian hiển thị', N'Màn hình 15.6 inch với độ phân giải WQHD, tần số quét 165 Hz giúp quan sát nội dung thuận tiện khi làm việc hay giải trí.', 10),
  (N'Lenovo Legion 5', 'performance', N'Hiệu năng theo cấu hình', N'Lenovo Legion 5 phù hợp với nhu cầu chơi game, giải trí và xử lý công việc nặng. CPU tham khảo của cấu hình demo: AMD Ryzen 7 7735HS (theo cấu hình demo). GPU tham khảo: NVIDIA GeForce RTX 4060 8 GB (cấu hình demo). RAM và SSD cần xem theo SKU thực tế, không mặc định mọi phiên bản có cùng cấu hình.', 20),
  (N'Lenovo Legion 5', 'connect', N'Kết nối và tính tiện dụng', N'Máy có webcam, loa và microphone tích hợp. Các cổng USB/HDMI, chuẩn Wi-Fi và Bluetooth phụ thuộc phiên bản máy; khi chọn mua nên đối chiếu mã cấu hình chính xác.', 30),
  (N'Lenovo Legion Pro 5', 'display', N'Không gian hiển thị', N'Màn hình 16 inch với độ phân giải WQXGA, tần số quét 240 Hz giúp quan sát nội dung thuận tiện khi làm việc hay giải trí.', 10),
  (N'Lenovo Legion Pro 5', 'performance', N'Hiệu năng theo cấu hình', N'Lenovo Legion Pro 5 phù hợp với nhu cầu chơi game, giải trí và xử lý công việc nặng. CPU tham khảo của cấu hình demo: Intel Core i9-14900HX (theo cấu hình demo). GPU tham khảo: NVIDIA GeForce RTX 4070 8 GB (cấu hình demo). RAM và SSD cần xem theo SKU thực tế, không mặc định mọi phiên bản có cùng cấu hình.', 20),
  (N'Lenovo Legion Pro 5', 'connect', N'Kết nối và tính tiện dụng', N'Máy có webcam, loa và microphone tích hợp. Các cổng USB/HDMI, chuẩn Wi-Fi và Bluetooth phụ thuộc phiên bản máy; khi chọn mua nên đối chiếu mã cấu hình chính xác.', 30),
  (N'Lenovo Legion M300 RGB', 'design', N'Thiết kế phục vụ thao tác', N'Lenovo Legion M300 RGB được thiết kế cho thao tác với máy tính và laptop. Bố trí và kiểu dáng phù hợp loại thiết bị, hỗ trợ công việc hoặc giải trí hằng ngày.', 10),
  (N'Lenovo Legion M300 RGB', 'performance', N'Khả năng điều khiển', N'Thông số nổi bật: 8.000 DPI (theo dữ liệu mẫu). Hãy chọn phiên bản theo nhu cầu và môi trường sử dụng.', 20),
  (N'Lenovo Legion M300 RGB', 'connect', N'Kết nối với máy tính', N'Kiểu kết nối: Có dây. Đối chiếu hệ điều hành, bộ thu hoặc cổng kết nối trước khi mua để bảo đảm tương thích.', 30),
  (N'Lenovo Legion M600 Wireless', 'design', N'Thiết kế phục vụ thao tác', N'Lenovo Legion M600 Wireless được thiết kế cho thao tác với máy tính và laptop. Bố trí và kiểu dáng phù hợp loại thiết bị, hỗ trợ công việc hoặc giải trí hằng ngày.', 10),
  (N'Lenovo Legion M600 Wireless', 'performance', N'Khả năng điều khiển', N'Thông số nổi bật: 16.000 DPI (theo dữ liệu mẫu). Hãy chọn phiên bản theo nhu cầu và môi trường sử dụng.', 20),
  (N'Lenovo Legion M600 Wireless', 'connect', N'Kết nối với máy tính', N'Kiểu kết nối: Không dây. Đối chiếu hệ điều hành, bộ thu hoặc cổng kết nối trước khi mua để bảo đảm tương thích.', 30),
  (N'Lenovo Legion K300 RGB', 'design', N'Thiết kế phục vụ thao tác', N'Lenovo Legion K300 RGB được thiết kế cho thao tác với máy tính và laptop. Bố trí và kiểu dáng phù hợp loại thiết bị, hỗ trợ công việc hoặc giải trí hằng ngày.', 10),
  (N'Lenovo Legion K300 RGB', 'performance', N'Khả năng điều khiển', N'Thông số nổi bật: RGB (5 vùng theo dữ liệu mẫu). Hãy chọn phiên bản theo nhu cầu và môi trường sử dụng.', 20),
  (N'Lenovo Legion K300 RGB', 'connect', N'Kết nối với máy tính', N'Kiểu kết nối: Có dây. Đối chiếu hệ điều hành, bộ thu hoặc cổng kết nối trước khi mua để bảo đảm tương thích.', 30),
  (N'Lenovo Go Wireless Split Keyboard', 'design', N'Thiết kế phục vụ thao tác', N'Lenovo Go Wireless Split Keyboard được thiết kế cho thao tác với máy tính và laptop. Bố trí và kiểu dáng phù hợp loại thiết bị, hỗ trợ công việc hoặc giải trí hằng ngày.', 10),
  (N'Lenovo Go Wireless Split Keyboard', 'performance', N'Khả năng điều khiển', N'Các tính năng điều khiển đáp ứng nhu cầu nhập liệu hoặc sử dụng chuột thường ngày. Hãy chọn phiên bản theo nhu cầu và môi trường sử dụng.', 20),
  (N'Lenovo Go Wireless Split Keyboard', 'connect', N'Kết nối với máy tính', N'Kiểu kết nối: Không dây. Đối chiếu hệ điều hành, bộ thu hoặc cổng kết nối trước khi mua để bảo đảm tương thích.', 30),
  (N'Lenovo 300 FHD Webcam', 'video', N'Hình ảnh rõ nét cho hội họp', N'Lenovo 300 FHD Webcam hỗ trợ độ phân giải 1920 × 1080 (Full HD), phù hợp các cuộc gọi video, học trực tuyến và họp từ xa khi có ánh sáng thích hợp.', 10),
  (N'Lenovo 300 FHD Webcam', 'audio', N'Microphone tích hợp', N'Webcam hỗ trợ thu tiếng phục vụ giao tiếp trực tuyến. Chất lượng ghi âm phụ thuộc vị trí đặt máy, độ ồn môi trường và cài đặt phần mềm.', 20),
  (N'Lenovo 300 FHD Webcam', 'connect', N'Lắp đặt linh hoạt', N'Thiết bị có chân đế để gắn lên màn hình hoặc bố trí ở vị trí thích hợp. Kiểm tra cổng USB và khả năng tương thích ứng dụng trước khi kết nối.', 30),
  (N'Lenovo Performance FHD Webcam', 'video', N'Hình ảnh rõ nét cho hội họp', N'Lenovo Performance FHD Webcam hỗ trợ độ phân giải 1920 × 1080 (Full HD), phù hợp các cuộc gọi video, học trực tuyến và họp từ xa khi có ánh sáng thích hợp.', 10),
  (N'Lenovo Performance FHD Webcam', 'audio', N'Microphone tích hợp', N'Webcam hỗ trợ thu tiếng phục vụ giao tiếp trực tuyến. Chất lượng ghi âm phụ thuộc vị trí đặt máy, độ ồn môi trường và cài đặt phần mềm.', 20),
  (N'Lenovo Performance FHD Webcam', 'connect', N'Lắp đặt linh hoạt', N'Thiết bị có chân đế để gắn lên màn hình hoặc bố trí ở vị trí thích hợp. Kiểm tra cổng USB và khả năng tương thích ứng dụng trước khi kết nối.', 30),
  (N'Lenovo Laptop Backpack 15.6"', 'design', N'Bố cục ngăn chứa thiết thực', N'Lenovo Laptop Backpack 15.6" có ngăn chính dành cho máy tính cùng không gian đựng phụ kiện. Thiết kế hai quai vai phù hợp đi học, đi làm và di chuyển hằng ngày.', 10),
  (N'Lenovo Laptop Backpack 15.6"', 'protect', N'Mang theo laptop và phụ kiện', N'Kích thước laptop tham khảo: Tối đa 15.6 inch (theo dữ liệu demo). Ngăn riêng hỗ trợ hạn chế cọ xát thông thường, không thay thế túi chống sốc chuyên dụng.', 20),
  (N'Lenovo Laptop Backpack 15.6"', 'daily', N'Lưu ý khi sử dụng', N'Sắp xếp đồ nặng sát lưng và tránh để thiết bị tiếp xúc trực tiếp với nước. Khả năng chống thấm phụ thuộc chất liệu và điều kiện sử dụng thực tế.', 30),
  (N'Lenovo Legion Gaming Backpack', 'design', N'Bố cục ngăn chứa thiết thực', N'Lenovo Legion Gaming Backpack có ngăn chính dành cho máy tính cùng không gian đựng phụ kiện. Thiết kế hai quai vai phù hợp đi học, đi làm và di chuyển hằng ngày.', 10),
  (N'Lenovo Legion Gaming Backpack', 'protect', N'Mang theo laptop và phụ kiện', N'Kích thước laptop tham khảo: Tối đa 17 inch (theo dữ liệu demo). Ngăn riêng hỗ trợ hạn chế cọ xát thông thường, không thay thế túi chống sốc chuyên dụng.', 20),
  (N'Lenovo Legion Gaming Backpack', 'daily', N'Lưu ý khi sử dụng', N'Sắp xếp đồ nặng sát lưng và tránh để thiết bị tiếp xúc trực tiếp với nước. Khả năng chống thấm phụ thuộc chất liệu và điều kiện sử dụng thực tế.', 30),
  (N'Apple Watch SE 2', 'display', N'Màn hình thuận tiện quan sát', N'Apple Watch SE 2 sử dụng Retina OLED, giúp theo dõi thời gian, thông báo và các chỉ số cần thiết.', 10),
  (N'Apple Watch SE 2', 'health', N'Đồng hành cùng hoạt động thể chất', N'Có các chức năng theo dõi nhịp tim, giấc ngủ và vận động. Các dữ liệu đo chỉ mang tính hỗ trợ theo dõi sức khỏe, không thay thế thiết bị hoặc đánh giá y tế.', 20),
  (N'Apple Watch SE 2', 'daily', N'Kết nối, định vị và pin', N'Đồng hồ hỗ trợ GPS và đồng bộ với ứng dụng trên điện thoại tương thích. Thời lượng tham khảo: Tối đa khoảng 18 giờ (theo Apple). ', 30),
  (N'Samsung Galaxy Watch7', 'display', N'Màn hình thuận tiện quan sát', N'Samsung Galaxy Watch7 sử dụng Super AMOLED, giúp theo dõi thời gian, thông báo và các chỉ số cần thiết.', 10),
  (N'Samsung Galaxy Watch7', 'health', N'Đồng hành cùng hoạt động thể chất', N'Có các chức năng theo dõi nhịp tim, giấc ngủ và vận động. Các dữ liệu đo chỉ mang tính hỗ trợ theo dõi sức khỏe, không thay thế thiết bị hoặc đánh giá y tế.', 20),
  (N'Samsung Galaxy Watch7', 'daily', N'Kết nối, định vị và pin', N'Đồng hồ hỗ trợ GPS và đồng bộ với ứng dụng trên điện thoại tương thích. Thời lượng thực tế thay đổi theo cường độ sử dụng.', 30),
  (N'Garmin Forerunner 165', 'display', N'Màn hình thuận tiện quan sát', N'Garmin Forerunner 165 sử dụng AMOLED, giúp theo dõi thời gian, thông báo và các chỉ số cần thiết.', 10),
  (N'Garmin Forerunner 165', 'health', N'Đồng hành cùng hoạt động thể chất', N'Có các chức năng theo dõi nhịp tim, giấc ngủ và vận động. Các dữ liệu đo chỉ mang tính hỗ trợ theo dõi sức khỏe, không thay thế thiết bị hoặc đánh giá y tế.', 20),
  (N'Garmin Forerunner 165', 'daily', N'Kết nối, định vị và pin', N'Đồng hồ hỗ trợ GPS và đồng bộ với ứng dụng trên điện thoại tương thích. Thời lượng tham khảo: Tối đa 11 ngày ở chế độ đồng hồ thông minh (theo Garmin). ', 30),
  (N'Sony WH-1000XM5', 'audio', N'Trải nghiệm âm thanh', N'Sony WH-1000XM5 phục vụ nhu cầu nghe nhạc, xem phim và gọi điện. Hỗ trợ chống ồn chủ động: Có (ANC). Chất lượng âm thanh thực tế còn phụ thuộc nguồn phát và cách đeo.', 10),
  (N'Sony WH-1000XM5', 'connect', N'Kết nối tiện lợi', N'Kết nối chính: Bluetooth. Thiết kế và thao tác điều khiển được tối ưu cho việc sử dụng cùng thiết bị tương thích trong sinh hoạt hằng ngày.', 20),
  (N'Sony WH-1000XM5', 'battery', N'Pin và sử dụng', N'Thông tin thời lượng: Tối đa 30 giờ (bật ANC). Khi lựa chọn phiên bản, hãy lưu ý khác biệt về chống ồn hoặc phụ kiện đi kèm nếu có.', 30),
  (N'JBL Tune 770NC', 'audio', N'Trải nghiệm âm thanh', N'JBL Tune 770NC phục vụ nhu cầu nghe nhạc, xem phim và gọi điện. Hỗ trợ chống ồn chủ động: Có (ANC). Chất lượng âm thanh thực tế còn phụ thuộc nguồn phát và cách đeo.', 10),
  (N'JBL Tune 770NC', 'connect', N'Kết nối tiện lợi', N'Kết nối chính: Bluetooth. Thiết kế và thao tác điều khiển được tối ưu cho việc sử dụng cùng thiết bị tương thích trong sinh hoạt hằng ngày.', 20),
  (N'JBL Tune 770NC', 'battery', N'Pin và sử dụng', N'Thông tin thời lượng: Tối đa 70 giờ khi tắt ANC. Khi lựa chọn phiên bản, hãy lưu ý khác biệt về chống ồn hoặc phụ kiện đi kèm nếu có.', 30),
  (N'Canon EOS R50', 'image', N'Chất lượng hình ảnh linh hoạt', N'Canon EOS R50 sử dụng cảm biến APS-C độ phân giải 24.2 MP, hỗ trợ chụp ảnh JPEG và RAW để điều chỉnh hậu kỳ theo nhu cầu.', 10),
  (N'Canon EOS R50', 'video', N'Ghi hình và lấy nét', N'Khả năng ghi hình 4K UHD. Các tính năng lấy nét đáp ứng nhiều tình huống chụp và quay; hãy xem bảng thông số để biết giới hạn từng chế độ.', 20),
  (N'Canon EOS R50', 'lens', N'Linh hoạt với hệ ống kính', N'Ngàm Canon RF / RF-S. Sản phẩm có thể bán dạng thân máy hoặc bộ kit theo SKU; cần kiểm tra bộ ống kính đi kèm trước khi mua.', 30),
  (N'Sony Alpha A6400', 'image', N'Chất lượng hình ảnh linh hoạt', N'Sony Alpha A6400 sử dụng cảm biến APS-C độ phân giải 24.2 MP, hỗ trợ chụp ảnh JPEG và RAW để điều chỉnh hậu kỳ theo nhu cầu.', 10),
  (N'Sony Alpha A6400', 'video', N'Ghi hình và lấy nét', N'Khả năng ghi hình 4K. Các tính năng lấy nét đáp ứng nhiều tình huống chụp và quay; hãy xem bảng thông số để biết giới hạn từng chế độ.', 20),
  (N'Sony Alpha A6400', 'lens', N'Linh hoạt với hệ ống kính', N'Ngàm Sony E-mount. Sản phẩm có thể bán dạng thân máy hoặc bộ kit theo SKU; cần kiểm tra bộ ống kính đi kèm trước khi mua.', 30),
  (N'Fujifilm X-S20', 'image', N'Chất lượng hình ảnh linh hoạt', N'Fujifilm X-S20 sử dụng cảm biến APS-C độ phân giải 26.1 MP, hỗ trợ chụp ảnh JPEG và RAW để điều chỉnh hậu kỳ theo nhu cầu.', 10),
  (N'Fujifilm X-S20', 'video', N'Ghi hình và lấy nét', N'Khả năng ghi hình Tối đa 6.2K 30p. Các tính năng lấy nét đáp ứng nhiều tình huống chụp và quay; hãy xem bảng thông số để biết giới hạn từng chế độ.', 20),
  (N'Fujifilm X-S20', 'lens', N'Linh hoạt với hệ ống kính', N'Ngàm Fujifilm X-mount. Sản phẩm có thể bán dạng thân máy hoặc bộ kit theo SKU; cần kiểm tra bộ ống kính đi kèm trước khi mua.', 30);
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

IF (SELECT COUNT(DISTINCT product_name) FROM #OverviewSeed) <> 39
  THROW 57002,N'Expected 39 products in overview seed.',1;
IF EXISTS(
  SELECT 1 FROM (SELECT DISTINCT product_name FROM #OverviewSeed) x
  OUTER APPLY(SELECT COUNT(*) AS n FROM dbo.PRODUCT p WHERE p.product_name=x.product_name) chk
  WHERE chk.n<>1
)
BEGIN
  THROW 57003,N'Missing or duplicate product names. No data inserted.',1;
END;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

BEGIN TRY
  BEGIN TRANSACTION;

  INSERT INTO dbo.PRODUCT_CONTENT_SECTION
    (product_id,section_key,section_title,section_content,image_url,image_alt,display_order)
  SELECT p.product_id,s.section_key,s.section_title,s.section_content,
         NULL,NULL,s.display_order
  FROM #OverviewSeed AS s
  JOIN dbo.PRODUCT AS p ON p.product_name=s.product_name
  WHERE NOT EXISTS(
    SELECT 1 FROM dbo.PRODUCT_CONTENT_SECTION x WITH (UPDLOCK,HOLDLOCK)
    WHERE x.product_id=p.product_id AND x.section_key=s.section_key
  );

  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;


INSERT INTO dbo.INVENTORY_MOVEMENT
 (sku_id,movement_type,quantity_delta,quantity_before,quantity_after,note,actor_user_id)
SELECT s.sku_id,'OPENING',s.stock_quantity,0,s.stock_quantity,
       N'Số dư khởi tạo dữ liệu mẫu',NULL
FROM dbo.PRODUCT_SKU s;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;
------------------------------------------------Insert Data-----------------------------------------------------

IF (SELECT COUNT(*) FROM dbo.PRODUCT) <> 39
BEGIN
    THROW 58101, N'OECS bootstrap: expected 39 initial products.', 1;
END;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

IF EXISTS (
    SELECT p.product_id
    FROM dbo.PRODUCT p
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.PRODUCT_SKU s
        WHERE s.product_id = p.product_id
    )
)
BEGIN
    THROW 58102, N'OECS bootstrap: at least one product lacks SKUs.', 1;
END;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

IF (SELECT COUNT(*) FROM dbo.PRODUCT_CONTENT_SECTION) <> 117
BEGIN
    THROW 58103, N'OECS bootstrap: expected 117 product overview sections.', 1;
END;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

IF OBJECT_ID(N'dbo.CATEGORY_ATTRIBUTE', N'U') IS NULL
   OR OBJECT_ID(N'dbo.SKU_ATTRIBUTE_VALUE', N'U') IS NULL
   OR OBJECT_ID(N'dbo.INVENTORY_MOVEMENT', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PRODUCT_CONTENT_SECTION', N'U') IS NULL
BEGIN
    THROW 58104, N'OECS bootstrap: missing a required catalog/inventory object.', 1;
END;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

IF EXISTS (
    SELECT 1
    FROM dbo.PRODUCT_SKU
    WHERE variant_key IS NOT NULL
    GROUP BY product_id, variant_key
    HAVING COUNT(*) > 1
)
BEGIN
    THROW 58105, N'OECS bootstrap: duplicate SKU variant combinations.', 1;
END;
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;

PRINT N'OECS catalog/bootstrap assertions finished; review prior Messages for errors.';
GO
IF SUBSTRING(CONTEXT_INFO(),1,8) <> 0x4F45435353454544 RETURN;



PRINT N'OECS schema and development seed script reached the end. Review any earlier errors before using database.';
SET CONTEXT_INFO 0x00;
GO
