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
    reserved_quantity INT NOT NULL
    CONSTRAINT DF_SKU_Reserved DEFAULT (0),
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    original_price DECIMAL(18,2) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_SKU_IsActive DEFAULT (1),
    variant_key VARBINARY(32) NULL,
    CONSTRAINT CK_SKU_Price CHECK (price >= 0),
    CONSTRAINT CK_SKU_OriginalPrice CHECK (original_price IS NULL OR original_price >= 0),
    CONSTRAINT CK_SKU_Stock CHECK (stock_quantity IS NULL OR stock_quantity >= 0),
    CONSTRAINT CK_SKU_Reserved CHECK (
        reserved_quantity >= 0
        AND reserved_quantity <= stock_quantity
    ),
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
    
    CONSTRAINT CK_Order_PaymentStatus
        CHECK (
            payment_status IN (
                'UNPAID',
                'PENDING',
                'PAID',
                'FAILED',
                'CANCELLED',
                'EXPIRED'
            )
        )
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



CREATE UNIQUE INDEX UX_Payment_Provider_Success
    ON PAYMENT_TRANSACTION(payment_method, provider_transaction_id)
    WHERE status = 'SUCCESS' AND provider_transaction_id IS NOT NULL;

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

    CONSTRAINT FK_RETURN_REQUEST_ITEM_REQUEST FOREIGN KEY (request_id)
        REFERENCES RETURN_REQUEST(request_id),
    CONSTRAINT FK_RETURN_REQUEST_ITEM_ORDER_ITEM FOREIGN KEY (order_item_id)
        REFERENCES ORDER_ITEM(order_item_id),
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
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.PASSWORD_RESET_TOKEN)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.AUDIT_LOG)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.BANNER)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.RETURN_REQUEST)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.RETURN_REQUEST_ITEM)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.RETURN_REQUEST_HISTORY)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.CATEGORY_ATTRIBUTE)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.SKU_ATTRIBUTE_VALUE)
    OR EXISTS (SELECT TOP (1) 1 FROM dbo.INVENTORY_MOVEMENT)
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
(4, 1, N'iPhone 15 Pro', N'<h2>iPhone 15 Pro – Thiết kế Titanium đẳng cấp, chip A17 Pro mạnh mẽ và hệ thống camera chuyên nghiệp</h2><p><strong>iPhone 15 Pro</strong> đánh dấu bước chuyển đáng chú ý trong thiết kế và công nghệ của dòng điện thoại cao cấp Apple. Sản phẩm sở hữu khung viền Titanium, bộ xử lý A17 Pro, màn hình Super Retina XDR 6,1 inch cùng hệ thống camera chuyên nghiệp với cảm biến chính 48 MP. Những trang bị này mang đến sự kết hợp giữa tính di động, hiệu năng mạnh mẽ và trải nghiệm hình ảnh linh hoạt.</p><p>Không chỉ phục vụ nhu cầu liên lạc và giải trí thông thường, iPhone 15 Pro còn hướng đến những người thường xuyên làm việc trên điện thoại, chụp ảnh, quay video và sử dụng các ứng dụng sáng tạo.</p><h3>Những điểm nổi bật trên iPhone 15 Pro</h3><ul><li>Khung viền Titanium cao cấp, trọng lượng khoảng 187 g.</li><li>Màn hình OLED Super Retina XDR 6,1 inch.</li><li>ProMotion với tần số quét thích ứng lên đến 120 Hz.</li><li>Chip A17 Pro với CPU 6 lõi và GPU 6 lõi.</li><li>Camera chính 48 MP, camera telephoto 3x.</li><li>Quay video 4K, Apple ProRes và định dạng Log.</li><li>Action Button và cổng USB-C hỗ trợ USB 3.</li><li>Khả năng kháng nước và bụi IP68.</li></ul><h3>Thiết kế Titanium – Nhẹ nhàng và tinh tế</h3><p>Khung Titanium kết hợp cấu trúc bên trong bằng nhôm giúp giảm trọng lượng so với thế hệ sử dụng thép không gỉ. Các cạnh được bo nhẹ tạo cảm giác cầm nắm dễ chịu, trong khi mặt lưng kính nhám mang đến vẻ ngoài hiện đại. Mặt trước Ceramic Shield hỗ trợ bảo vệ màn hình trong quá trình sử dụng hằng ngày.</p><h3>Màn hình Super Retina XDR 6,1 inch</h3><p>Màn hình OLED có độ phân giải 2556 x 1179 pixel, hỗ trợ HDR, True Tone và dải màu rộng P3. Độ sáng tối đa ngoài trời có thể đạt 2.000 nit trong điều kiện phù hợp. Công nghệ ProMotion 120 Hz giúp thao tác cuộn trang, chuyển đổi ứng dụng và hiển thị chuyển động trở nên mượt mà.</p><h3>Dynamic Island và Always-On Display</h3><p>Dynamic Island hỗ trợ hiển thị các hoạt động đang diễn ra như phát nhạc, cuộc gọi và bộ hẹn giờ. Always-On Display cho phép theo dõi đồng hồ, tiện ích và thông báo ngay cả khi điện thoại đang ở trạng thái chờ.</p><h3>Chip A17 Pro – Hiệu năng cho công việc và giải trí</h3><p>Được sản xuất trên tiến trình 3 nm, A17 Pro sở hữu CPU 6 lõi, GPU 6 lõi và Neural Engine 16 lõi. Thiết bị có khả năng xử lý tốt các ứng dụng văn phòng, chỉnh sửa hình ảnh, đa nhiệm và những trò chơi có yêu cầu đồ họa cao. GPU hỗ trợ tăng tốc dò tia bằng phần cứng trong các ứng dụng tương thích.</p><h3>Hệ thống camera chuyên nghiệp</h3><p>Camera chính 48 MP hỗ trợ ghi lại hình ảnh có độ chi tiết cao. Camera Ultra Wide 12 MP cung cấp góc nhìn rộng khoảng 120 độ và hỗ trợ chụp macro. Camera telephoto 12 MP với zoom quang học 3x phù hợp cho chụp chân dung và các chủ thể ở khoảng cách xa.</p><p>Apple ProRAW cung cấp thêm lựa chọn hậu kỳ cho người yêu thích nhiếp ảnh. Chất lượng hình ảnh thực tế phụ thuộc vào ánh sáng, chế độ chụp và độ ổn định của thiết bị.</p><h3>Quay video 4K và Apple ProRes</h3><p>iPhone 15 Pro hỗ trợ quay video 4K với nhiều tốc độ khung hình, Chế độ Điện ảnh và Chế độ Hành động. Định dạng ProRes và Log mang đến khả năng hậu kỳ linh hoạt. Quay ProRes 4K 60 fps yêu cầu thiết bị lưu trữ ngoài tương thích.</p><h3>Action Button và USB-C</h3><p>Action Button cho phép tùy chỉnh thao tác mở camera, bật đèn pin hoặc kích hoạt phím tắt. Cổng USB-C hỗ trợ sạc và truyền dữ liệu USB 3 với tốc độ tối đa 10 Gb/s khi sử dụng cáp tương thích.</p><h3>Pin và khả năng kết nối</h3><p>Theo Apple, thiết bị có thời gian xem video lên đến 23 giờ trong điều kiện thử nghiệm. Máy hỗ trợ sạc nhanh, MagSafe, 5G, Wi-Fi 6E và Bluetooth 5.3. Thời lượng sử dụng thực tế phụ thuộc vào ứng dụng, độ sáng và tình trạng pin.</p><h3>Bảo mật và khả năng kháng nước</h3><p>Face ID hỗ trợ xác thực khuôn mặt thông qua hệ thống TrueDepth. Thiết bị đạt chuẩn IP68 trong điều kiện thử nghiệm, tuy nhiên khả năng kháng nước có thể giảm theo thời gian.</p><h3>iPhone 15 Pro phù hợp với những ai?</h3><ul><li>Người yêu thích điện thoại cao cấp có kích thước gọn.</li><li>Người thường xuyên chụp ảnh và quay video.</li><li>Người cần hiệu năng mạnh cho công việc và giải trí.</li><li>Người đang sử dụng hệ sinh thái Apple.</li></ul><h3>Câu hỏi thường gặp</h3><h4>iPhone 15 Pro có màn hình 120 Hz không?</h4><p>Có, thiết bị hỗ trợ ProMotion với tần số quét thích ứng lên đến 120 Hz.</p><h4>Camera telephoto có zoom quang học bao nhiêu?</h4><p>iPhone 15 Pro hỗ trợ zoom quang học 3x, khác với mức 5x trên Pro Max.</p><h4>Có hỗ trợ Apple ProRes không?</h4><p>Có. Người dùng nên cân nhắc dung lượng lưu trữ khi thường xuyên quay video chất lượng cao.</p><h3>Có nên lựa chọn iPhone 15 Pro?</h3><p>Đây là lựa chọn đáng cân nhắc dành cho người cần một chiếc smartphone cao cấp, kích thước vừa phải, màn hình đẹp, hiệu năng mạnh và hệ thống camera linh hoạt.</p>', 'assets/images/products/iphone_15_pro.png'),
(4, 1, N'iPhone 15 Pro Max', N'<h2>iPhone 15 Pro Max – Màn hình 6,7 inch, camera zoom quang học 5x và hiệu năng A17 Pro</h2><p><strong>iPhone 15 Pro Max</strong> là mẫu điện thoại cao cấp dành cho người dùng muốn tận hưởng không gian hiển thị lớn, khả năng quay chụp linh hoạt và hiệu năng mạnh mẽ. Thiết bị sở hữu khung Titanium, màn hình Super Retina XDR 6,7 inch và camera telephoto sử dụng thiết kế tetraprism.</p><h3>Những điểm nổi bật</h3><ul><li>Khung Titanium, mặt lưng kính nhám.</li><li>Màn hình OLED 6,7 inch, ProMotion 120 Hz.</li><li>Chip Apple A17 Pro.</li><li>Camera chính 48 MP và telephoto 5x.</li><li>Quay video 4K, ProRes và Log.</li><li>Action Button, USB-C và MagSafe.</li><li>Thời gian xem video lên đến 29 giờ theo công bố của Apple.</li></ul><h3>Thiết kế Titanium cao cấp</h3><p>Khung Titanium kết hợp cấu trúc nhôm bên trong giúp giảm trọng lượng so với thế hệ Pro Max trước đó. Thiết bị nặng khoảng 221 g, mang lại cảm giác chắc chắn khi sử dụng. Các cạnh bo nhẹ và mặt lưng kính nhám tạo nên thiết kế hiện đại, tinh tế.</p><h3>Màn hình Super Retina XDR 6,7 inch</h3><p>Màn hình OLED có độ phân giải 2796 x 1290 pixel, hỗ trợ HDR, True Tone và dải màu rộng P3. Không gian hiển thị rộng mang lại lợi thế khi xem phim, đọc tài liệu, chỉnh sửa hình ảnh và sử dụng các ứng dụng có nhiều thành phần giao diện.</p><h3>ProMotion 120 Hz và Dynamic Island</h3><p>Tần số quét thích ứng lên đến 120 Hz hỗ trợ hiển thị chuyển động mượt mà. Dynamic Island giúp theo dõi các hoạt động đang diễn ra, trong khi Always-On Display cung cấp thông tin cần thiết khi thiết bị ở trạng thái chờ.</p><h3>Hiệu năng mạnh mẽ với A17 Pro</h3><p>CPU 6 lõi, GPU 6 lõi và Neural Engine 16 lõi hỗ trợ xử lý các tác vụ từ công việc văn phòng đến đồ họa nâng cao. Người dùng có thể chuyển đổi giữa các ứng dụng, chỉnh sửa video và trải nghiệm trò chơi tương thích với các công nghệ đồ họa hiện đại.</p><h3>Camera chính 48 MP</h3><p>Camera chính hỗ trợ chống rung quang học dịch chuyển cảm biến thế hệ thứ hai, giúp ghi lại hình ảnh chi tiết trong nhiều điều kiện sử dụng. Apple ProRAW cung cấp thêm khả năng điều chỉnh màu sắc và thông số hình ảnh trong quá trình hậu kỳ.</p><h3>Camera telephoto 5x – Điểm khác biệt của Pro Max</h3><p>Ống kính telephoto sử dụng thiết kế tetraprism, cung cấp zoom quang học 5x. Đây là lợi thế khi chụp phong cảnh, kiến trúc và những chủ thể ở khoảng cách xa. Camera Ultra Wide 12 MP bổ sung góc nhìn rộng và khả năng chụp macro.</p><h3>Quay video chuyên nghiệp</h3><p>Thiết bị hỗ trợ quay 4K, Chế độ Điện ảnh, Chế độ Hành động, ProRes và định dạng Log. Người thường xuyên sản xuất nội dung có thể tận dụng các định dạng ghi hình nâng cao cùng thiết bị lưu trữ ngoài tương thích.</p><h3>Thời lượng pin và sạc</h3><p>Apple công bố thời gian xem video lên đến 29 giờ trong điều kiện thử nghiệm. Sản phẩm hỗ trợ sạc qua USB-C và sạc không dây MagSafe. Thời lượng thực tế thay đổi theo ứng dụng, kết nối mạng và độ sáng màn hình.</p><h3>Kết nối và bảo mật</h3><p>iPhone 15 Pro Max hỗ trợ 5G, Wi-Fi 6E, Bluetooth 5.3, Face ID và các tính năng bảo mật của iOS. Cổng USB-C hỗ trợ USB 3 với tốc độ tối đa 10 Gb/s khi kết hợp cáp phù hợp. Thiết bị đạt chuẩn IP68 trong điều kiện thử nghiệm.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Người yêu thích màn hình lớn.</li><li>Người thường xuyên quay video và sáng tạo nội dung.</li><li>Người cần camera có khả năng zoom quang học xa.</li><li>Người ưu tiên thời lượng pin và hiệu năng cao.</li></ul><h3>Câu hỏi thường gặp</h3><h4>iPhone 15 Pro Max khác gì iPhone 15 Pro?</h4><p>Pro Max có màn hình lớn hơn, camera telephoto 5x thay vì 3x và thời gian xem video được công bố dài hơn.</p><h4>Máy có hỗ trợ sạc MagSafe không?</h4><p>Có, thiết bị tương thích với các bộ sạc và phụ kiện MagSafe phù hợp.</p><h4>Thời lượng pin có cố định 29 giờ không?</h4><p>Không. Đây là kết quả thử nghiệm phát video của Apple, không phải thời lượng sử dụng hỗn hợp cố định.</p><h3>Có nên lựa chọn iPhone 15 Pro Max?</h3><p>Với màn hình rộng, camera telephoto 5x và hiệu năng A17 Pro, sản phẩm phù hợp với người muốn kết hợp công việc, nhiếp ảnh và giải trí trên một thiết bị cao cấp.</p>', 'assets/images/products/iphone-15-pro-max.png'),
(4, 1, N'iPhone 16 Pro', N'<h2>iPhone 16 Pro – Sức mạnh A18 Pro, Camera Control và trải nghiệm Apple Intelligence</h2><p><strong>iPhone 16 Pro</strong> mang đến những cải tiến đáng chú ý về hiệu năng, kích thước màn hình và khả năng nhiếp ảnh trên dòng smartphone cao cấp của Apple. Thiết bị sở hữu khung Titanium, màn hình Super Retina XDR 6,3 inch, chip A18 Pro và hệ thống camera được nâng cấp nhằm phục vụ tốt hơn nhu cầu sáng tạo nội dung, làm việc và giải trí.</p><p>So với iPhone 15 Pro, thế hệ iPhone 16 Pro mở rộng không gian hiển thị, nâng cấp camera siêu rộng lên 48 MP và bổ sung camera telephoto 5x. Sự thay đổi này giúp người dùng tiếp cận nhiều công cụ nhiếp ảnh hơn mà không cần lựa chọn phiên bản Pro Max.</p><h3>Những điểm nổi bật của iPhone 16 Pro</h3><ul><li><strong>Khung Titanium:</strong> Kết hợp độ bền, trọng lượng và phong cách thiết kế cao cấp.</li><li><strong>Màn hình 6,3 inch:</strong> Không gian hiển thị rộng hơn thế hệ trước.</li><li><strong>ProMotion 120 Hz:</strong> Tần số quét thích ứng hỗ trợ chuyển động mượt mà.</li><li><strong>Chip A18 Pro:</strong> Nền tảng xử lý cho đồ họa, đa nhiệm và trí tuệ nhân tạo.</li><li><strong>Camera Fusion 48 MP:</strong> Ghi lại hình ảnh có độ chi tiết cao.</li><li><strong>Ultra Wide 48 MP:</strong> Nâng cấp khả năng chụp góc rộng và macro.</li><li><strong>Telephoto 5x:</strong> Hỗ trợ chụp chủ thể ở khoảng cách xa.</li><li><strong>Camera Control:</strong> Truy cập và điều chỉnh các chức năng camera thuận tiện.</li><li><strong>Quay video 4K Dolby Vision 120 fps:</strong> Mở rộng khả năng sáng tạo video.</li></ul><h3>Thiết kế Titanium – Tối ưu trải nghiệm cầm nắm</h3><p>iPhone 16 Pro tiếp tục sử dụng Titanium kết hợp cấu trúc bên trong bằng nhôm. Phần khung được hoàn thiện tinh tế, mặt lưng kính nhám giúp tạo cảm giác cao cấp và hạn chế dấu vân tay. Viền màn hình được thu gọn để mở rộng không gian hiển thị mà vẫn duy trì kích thước phù hợp cho việc mang theo hằng ngày.</p><p>Mặt trước Ceramic Shield hỗ trợ bảo vệ màn hình trong quá trình sử dụng. Các nút điều khiển được bố trí để người dùng dễ dàng truy cập chức năng thường xuyên sử dụng.</p><h3>Màn hình Super Retina XDR 6,3 inch</h3><p>Màn hình OLED có độ phân giải 2622 x 1206 pixel, hỗ trợ HDR, True Tone và dải màu rộng P3. Công nghệ OLED mang đến màu đen sâu, độ tương phản cao và khả năng tái hiện hình ảnh chi tiết.</p><p>Với kích thước 6,3 inch, người dùng có thêm không gian khi đọc tài liệu, xem video, chỉnh sửa ảnh hoặc thao tác với nhiều thành phần giao diện. ProMotion cho phép điều chỉnh tần số quét thích ứng lên đến 120 Hz nhằm cân bằng chất lượng hiển thị và mức tiêu thụ năng lượng.</p><h3>Dynamic Island và Always-On Display</h3><p>Dynamic Island hiển thị những hoạt động như cuộc gọi, phát nhạc, chỉ đường và bộ hẹn giờ trong các ứng dụng tương thích. Always-On Display cho phép người dùng theo dõi thông tin cần thiết mà không phải liên tục mở khóa điện thoại.</p><h3>Chip A18 Pro – Hiệu năng cho các tác vụ chuyên sâu</h3><p>A18 Pro được xây dựng trên tiến trình 3 nm thế hệ thứ hai, tích hợp CPU 6 lõi, GPU 6 lõi và Neural Engine 16 lõi. Bộ xử lý hỗ trợ vận hành ứng dụng, xử lý hình ảnh, dựng video và những tác vụ sử dụng học máy trên thiết bị.</p><p>Đối với người thường xuyên làm việc bằng smartphone, hiệu năng của A18 Pro giúp xử lý tài liệu, tham gia cuộc họp trực tuyến và chuyển đổi giữa nhiều ứng dụng. Trong giải trí, GPU hỗ trợ các công nghệ đồ họa nâng cao trên những trò chơi tương thích.</p><h3>Apple Intelligence – Công cụ hỗ trợ công việc thông minh</h3><p>iPhone 16 Pro được thiết kế để hỗ trợ Apple Intelligence, hệ thống trí tuệ nhân tạo cá nhân của Apple. Những tính năng tương thích có thể hỗ trợ viết lại văn bản, tóm tắt nội dung, quản lý thông tin và chỉnh sửa hình ảnh.</p><p>Khả năng sử dụng từng tính năng phụ thuộc vào phiên bản iOS, ngôn ngữ, khu vực và các điều kiện hỗ trợ của Apple. Người dùng nên kiểm tra khả năng tương thích trước khi lựa chọn thiết bị dựa trên một tính năng AI cụ thể.</p><h3>Camera Fusion 48 MP – Ghi lại hình ảnh chi tiết</h3><p>Camera chính 48 MP hỗ trợ chống rung quang học dịch chuyển cảm biến. Người dùng có thể lựa chọn nhiều chế độ chụp để cân bằng giữa độ chi tiết, chất lượng hình ảnh và dung lượng lưu trữ.</p><p>Camera phù hợp với các tình huống như chụp chân dung, phong cảnh, kiến trúc, đồ ăn và sản phẩm. Những tính năng xử lý hình ảnh hỗ trợ cải thiện kết quả trong điều kiện ánh sáng phức tạp.</p><h3>Camera Ultra Wide 48 MP – Mở rộng góc nhìn</h3><p>Camera siêu rộng được nâng cấp lên 48 MP, mang đến nhiều khả năng sáng tạo hơn khi chụp phong cảnh, ảnh nhóm hoặc những không gian hạn chế. Chế độ macro giúp ghi lại các chi tiết nhỏ của hoa lá, vật dụng và sản phẩm ở khoảng cách gần.</p><h3>Camera telephoto 5x – Tiếp cận chủ thể từ xa</h3><p>Khác với camera telephoto 3x trên iPhone 15 Pro, iPhone 16 Pro được trang bị camera telephoto 5x. Người dùng có thể ghi lại các chi tiết ở xa và thay đổi bố cục ảnh mà không cần liên tục di chuyển vị trí.</p><h3>Camera Control – Thao tác quay chụp thuận tiện</h3><p>Camera Control cung cấp phương thức tương tác riêng với hệ thống camera. Người dùng có thể truy cập camera, chụp ảnh và điều chỉnh những thông số được hỗ trợ như mức thu phóng hoặc độ phơi sáng. Tính năng này hữu ích khi cần nhanh chóng ghi lại một khoảnh khắc.</p><h3>Quay video 4K Dolby Vision và Audio Mix</h3><p>Camera Fusion hỗ trợ quay video 4K Dolby Vision lên đến 120 fps trong chế độ tương thích. Người sáng tạo có thêm lựa chọn khi ghi hình chuyển động nhanh và thực hiện hiệu ứng chuyển động chậm trong quá trình chỉnh sửa.</p><p>Hệ thống micro cùng tính năng Audio Mix hỗ trợ điều chỉnh cách thể hiện âm thanh trong video. Chất lượng thu âm thực tế phụ thuộc vào môi trường, khoảng cách và nguồn âm thanh.</p><h3>Thời lượng pin và công nghệ sạc</h3><p>Theo công bố của Apple, iPhone 16 Pro có khả năng phát video lên đến 27 giờ trong điều kiện thử nghiệm. Máy hỗ trợ sạc qua USB-C, sạc không dây MagSafe và các bộ sạc tương thích. Mức tiêu thụ năng lượng thay đổi tùy theo ứng dụng và điều kiện sử dụng.</p><h3>Kết nối và bảo mật</h3><p>Thiết bị hỗ trợ 5G, Wi-Fi 7, Bluetooth 5.3 và USB 3 khi sử dụng cáp phù hợp. Face ID hỗ trợ xác thực khuôn mặt, trong khi iOS cung cấp các công cụ quản lý quyền truy cập dữ liệu cá nhân. Khả năng kháng nước IP68 được đánh giá trong điều kiện thử nghiệm tiêu chuẩn.</p><h3>iPhone 16 Pro phù hợp với những ai?</h3><ul><li>Người cần smartphone cao cấp nhưng không muốn kích thước quá lớn.</li><li>Người thường xuyên chụp ảnh và quay video.</li><li>Người muốn trải nghiệm những công cụ Apple Intelligence tương thích.</li><li>Người cần hiệu năng cao để làm việc và giải trí.</li><li>Người đang cân nhắc nâng cấp từ các thế hệ iPhone cũ.</li></ul><h3>Câu hỏi thường gặp về iPhone 16 Pro</h3><h4>iPhone 16 Pro có camera zoom quang học 5x không?</h4><p>Có. Thiết bị sử dụng camera telephoto 5x, tương tự mức zoom quang học trên iPhone 16 Pro Max.</p><h4>Máy có hỗ trợ quay video 4K 120 fps không?</h4><p>Có, trên camera và chế độ ghi hình tương thích.</p><h4>Apple Intelligence có hoạt động với mọi ngôn ngữ không?</h4><p>Khả năng hỗ trợ phụ thuộc vào phiên bản phần mềm, khu vực và danh sách ngôn ngữ được Apple hỗ trợ.</p><h4>iPhone 16 Pro có cần mua cáp riêng để truyền dữ liệu tốc độ cao không?</h4><p>Người dùng cần cáp và thiết bị hỗ trợ USB 3 để tận dụng tốc độ truyền dữ liệu cao.</p><h3>Có nên lựa chọn iPhone 16 Pro?</h3><p>iPhone 16 Pro mang đến sự cân bằng giữa kích thước, hiệu năng, khả năng nhiếp ảnh và công nghệ mới. Đây là lựa chọn phù hợp cho người muốn trải nghiệm đầy đủ những tính năng cao cấp của dòng Pro trong một thiết bị có kích thước tương đối thuận tiện.</p>', 'assets/images/products/iphone-16-pro.png'),
(4, 1, N'iPhone 16 Pro Max', N'<h2>iPhone 16 Pro Max – Màn hình 6,9 inch rộng lớn, A18 Pro mạnh mẽ và camera chuyên nghiệp</h2><p><strong>iPhone 16 Pro Max</strong> là mẫu smartphone cao cấp hướng đến những người ưu tiên màn hình lớn, hiệu năng mạnh, khả năng quay chụp chuyên sâu và thời lượng pin dài. Sản phẩm kết hợp thiết kế Titanium, chip A18 Pro, Camera Control và hệ thống camera được nâng cấp để mang đến trải nghiệm linh hoạt cho công việc lẫn giải trí.</p><p>Với màn hình 6,9 inch, thiết bị tạo thêm không gian khi xem phim, chơi game, chỉnh sửa hình ảnh và xử lý tài liệu. Những cải tiến về camera và bộ xử lý cũng giúp iPhone 16 Pro Max trở thành công cụ hỗ trợ đáng chú ý đối với người sáng tạo nội dung.</p><h3>Những điểm nổi bật của iPhone 16 Pro Max</h3><ul><li>Màn hình OLED Super Retina XDR 6,9 inch.</li><li>ProMotion 120 Hz và Always-On Display.</li><li>Khung Titanium cùng mặt lưng kính nhám.</li><li>Chip A18 Pro hỗ trợ Apple Intelligence.</li><li>Camera Fusion 48 MP và Ultra Wide 48 MP.</li><li>Camera telephoto zoom quang học 5x.</li><li>Quay video 4K Dolby Vision 120 fps.</li><li>Camera Control và Action Button.</li><li>Thời gian phát video lên đến 33 giờ theo công bố của Apple.</li></ul><h3>Thiết kế Titanium – Phong cách cao cấp và chắc chắn</h3><p>Khung Titanium kết hợp cấu trúc nhôm bên trong tạo nên thiết kế được tối ưu cho một thiết bị có màn hình lớn. Các cạnh được hoàn thiện tinh tế, mặt lưng kính nhám mang đến cảm giác hiện đại và hạn chế dấu vân tay trong quá trình sử dụng.</p><p>Viền màn hình mỏng giúp mở rộng diện tích hiển thị. Tuy nhiên, kích thước và trọng lượng của phiên bản Pro Max vẫn là những yếu tố cần cân nhắc đối với người thường xuyên thao tác bằng một tay hoặc mang điện thoại trong túi nhỏ.</p><h3>Màn hình Super Retina XDR 6,9 inch – Không gian hiển thị rộng rãi</h3><p>Màn hình OLED có độ phân giải 2868 x 1320 pixel, hỗ trợ HDR, True Tone và dải màu rộng P3. Công nghệ OLED giúp thể hiện màu đen sâu, độ tương phản cao và hình ảnh có chiều sâu.</p><p>Kích thước 6,9 inch đặc biệt hữu ích khi xem phim, đọc sách điện tử, theo dõi bảng tính hoặc chỉnh sửa ảnh. Những người thường xuyên sử dụng điện thoại thay cho máy tính trong các công việc đơn giản có thể tận dụng không gian hiển thị rộng để quan sát nội dung thuận tiện hơn.</p><h3>ProMotion và trải nghiệm tương tác</h3><p>ProMotion hỗ trợ tần số quét thích ứng lên đến 120 Hz. Chuyển động khi cuộn trang, điều hướng giao diện và chơi trò chơi tương thích có thể được hiển thị mượt mà hơn. Hệ thống tự động điều chỉnh tần số quét theo nội dung nhằm tối ưu điện năng.</p><p>Dynamic Island và Always-On Display bổ sung khả năng theo dõi thông báo, hoạt động đang diễn ra và thông tin cần thiết khi thiết bị ở trạng thái chờ.</p><h3>Chip A18 Pro – Nền tảng hiệu năng cao cấp</h3><p>A18 Pro tích hợp CPU 6 lõi, GPU 6 lõi và Neural Engine 16 lõi. Bộ xử lý được thiết kế để phục vụ các tác vụ tính toán, đồ họa và xử lý học máy trên thiết bị.</p><p>Người dùng có thể chỉnh sửa ảnh, dựng video, quản lý tài liệu và sử dụng những ứng dụng có yêu cầu xử lý cao. Trong các trò chơi tương thích, GPU hỗ trợ những công nghệ đồ họa tiên tiến nhằm cải thiện khả năng tái hiện ánh sáng và hiệu ứng hình ảnh.</p><h3>Apple Intelligence và trải nghiệm sử dụng thông minh</h3><p>Apple Intelligence cung cấp những công cụ hỗ trợ viết, tóm tắt, xử lý thông tin và sáng tạo nội dung trên các phiên bản phần mềm tương thích. Người dùng có thể tận dụng những tính năng này trong học tập, công việc và các hoạt động cá nhân.</p><p>Tính khả dụng của từng công cụ phụ thuộc vào ngôn ngữ, khu vực, phiên bản hệ điều hành và điều kiện hỗ trợ của Apple.</p><h3>Camera Fusion 48 MP – Khả năng ghi hình linh hoạt</h3><p>Camera chính 48 MP hỗ trợ ghi lại hình ảnh độ phân giải cao và nhiều lựa chọn tiêu cự. Hệ thống chống rung quang học giúp cải thiện độ ổn định khi chụp ảnh hoặc quay video trong những điều kiện phù hợp.</p><p>Người dùng có thể lựa chọn định dạng ảnh theo mục đích sử dụng, từ chia sẻ hằng ngày đến hậu kỳ chuyên sâu. Định dạng Apple ProRAW cung cấp thêm khả năng điều chỉnh trong những phần mềm tương thích.</p><h3>Ultra Wide 48 MP và khả năng chụp macro</h3><p>Camera siêu rộng 48 MP giúp ghi lại phong cảnh, công trình kiến trúc và những không gian có nhiều đối tượng. Chế độ macro hỗ trợ quan sát các chi tiết nhỏ ở khoảng cách gần, tạo thêm lựa chọn khi chụp sản phẩm hoặc các vật thể có kết cấu đặc biệt.</p><h3>Camera telephoto 5x – Chụp chủ thể ở khoảng cách xa</h3><p>Camera telephoto 5x sử dụng thiết kế tetraprism để cung cấp khả năng thu phóng quang học trong cấu trúc điện thoại. Người dùng có thể ghi lại những chi tiết ở xa mà không cần tiếp cận trực tiếp chủ thể.</p><p>Khả năng zoom quang học mang lại lợi thế trong nhiếp ảnh du lịch, kiến trúc và các tình huống cần thay đổi góc nhìn. Chất lượng thực tế vẫn phụ thuộc vào điều kiện ánh sáng và độ ổn định khi chụp.</p><h3>Camera Control – Điều khiển camera trực quan</h3><p>Camera Control cho phép truy cập nhanh các chức năng quay chụp và điều chỉnh những thông số được hỗ trợ. Đây là phương thức tương tác bổ sung cho giao diện cảm ứng, hữu ích khi cần ghi lại hình ảnh nhanh chóng.</p><h3>Quay video 4K 120 fps và âm thanh nâng cao</h3><p>Thiết bị hỗ trợ quay 4K Dolby Vision lên đến 120 fps trên camera Fusion trong chế độ tương thích. Các lựa chọn tốc độ khung hình cao mở rộng khả năng dựng video chuyển động chậm và ghi lại những nội dung có chuyển động nhanh.</p><p>Hệ thống bốn micro cùng Audio Mix cung cấp thêm lựa chọn xử lý âm thanh sau khi ghi hình. Apple ProRes và định dạng Log hỗ trợ người làm hậu kỳ chuyên sâu, nhưng có thể yêu cầu dung lượng lưu trữ lớn và thiết bị ngoài tương thích.</p><h3>Thời lượng pin – Hỗ trợ nhiều hoạt động trong ngày</h3><p>Apple công bố iPhone 16 Pro Max có khả năng phát video lên đến 33 giờ trong điều kiện thử nghiệm. Dung lượng pin và khả năng quản lý điện năng giúp thiết bị phục vụ nhiều hoạt động như liên lạc, duyệt web, quay chụp và giải trí.</p><p>Thời lượng thực tế phụ thuộc vào mạng di động, độ sáng màn hình, ứng dụng, nhiệt độ và tình trạng pin. Người dùng nên lựa chọn bộ sạc và phụ kiện tương thích để có trải nghiệm ổn định.</p><h3>Kết nối USB-C, Wi-Fi 7 và 5G</h3><p>Cổng USB-C hỗ trợ sạc, kết nối phụ kiện và truyền dữ liệu USB 3 với tốc độ tối đa 10 Gb/s khi sử dụng cáp phù hợp. Wi-Fi 7, Bluetooth 5.3 và 5G phục vụ nhu cầu kết nối Internet và các thiết bị không dây tương thích.</p><h3>Bảo mật Face ID và khả năng kháng nước</h3><p>Face ID hỗ trợ xác thực khuôn mặt và bảo vệ quyền truy cập thiết bị. iOS cung cấp các công cụ kiểm soát quyền riêng tư của ứng dụng. Khả năng kháng nước IP68 được đánh giá trong điều kiện thử nghiệm và có thể giảm theo thời gian.</p><h3>iPhone 16 Pro Max phù hợp với những ai?</h3><ul><li>Người yêu thích màn hình điện thoại kích thước lớn.</li><li>Người thường xuyên quay phim và chỉnh sửa video.</li><li>Người cần thời lượng pin dài cho nhiều hoạt động.</li><li>Người ưu tiên hiệu năng và các công nghệ cao cấp.</li><li>Người sử dụng nhiều thiết bị thuộc hệ sinh thái Apple.</li></ul><h3>Câu hỏi thường gặp</h3><h4>iPhone 16 Pro Max có màn hình bao nhiêu inch?</h4><p>Thiết bị sở hữu màn hình OLED Super Retina XDR 6,9 inch.</p><h4>Camera có khác iPhone 16 Pro không?</h4><p>Hai phiên bản có những thông số camera chính tương đồng, bao gồm Fusion 48 MP, Ultra Wide 48 MP và telephoto 5x.</p><h4>Máy có hỗ trợ sạc không dây không?</h4><p>Có. Thiết bị hỗ trợ MagSafe và những chuẩn sạc không dây tương thích.</p><h4>Có nên chọn dung lượng lưu trữ lớn?</h4><p>Người thường xuyên quay video 4K hoặc ProRes nên cân nhắc dung lượng lưu trữ phù hợp vì các tệp video có thể chiếm nhiều không gian.</p><h3>Có nên lựa chọn iPhone 16 Pro Max?</h3><p>Sản phẩm phù hợp với những người ưu tiên trải nghiệm màn hình lớn, hiệu năng mạnh, khả năng nhiếp ảnh linh hoạt và thời lượng pin được công bố cao. Đây là lựa chọn đáng cân nhắc cho công việc, giải trí và sáng tạo nội dung chuyên sâu.</p>', 'assets/images/products/iphone-16-pro-max.png'),
(4, 2, N'Samsung Galaxy S24 Ultra', N'<h2>Samsung Galaxy S24 Ultra – Khung Titanium cao cấp, camera 200 MP và sức mạnh Galaxy AI</h2><p><strong>Samsung Galaxy S24 Ultra</strong> kết hợp những công nghệ nổi bật của dòng Galaxy S với hệ thống camera độ phân giải cao, màn hình lớn và bút S Pen tích hợp. Sản phẩm hướng đến người cần một chiếc smartphone có khả năng đáp ứng đồng thời công việc, nhiếp ảnh, sáng tạo nội dung và giải trí.</p><p>Galaxy AI mở rộng trải nghiệm sử dụng thông qua những công cụ hỗ trợ tìm kiếm, dịch thuật, ghi chú và chỉnh sửa hình ảnh. Kết hợp cùng bộ xử lý Snapdragon dành cho Galaxy, thiết bị mang đến nền tảng linh hoạt cho nhiều nhu cầu sử dụng khác nhau.</p><h3>Những điểm nổi bật của Galaxy S24 Ultra</h3><ul><li>Khung Titanium với thiết kế vuông vức đặc trưng.</li><li>Màn hình Dynamic AMOLED 2X 6,8 inch QHD+.</li><li>Tần số quét thích ứng từ 1 đến 120 Hz.</li><li>Snapdragon 8 Gen 3 for Galaxy.</li><li>Camera chính 200 MP.</li><li>Camera telephoto 3x và 5x.</li><li>Bút S Pen tích hợp trong thân máy.</li><li>Pin dung lượng điển hình 5.000 mAh.</li><li>Hỗ trợ sạc có dây 45 W.</li><li>Galaxy AI và khả năng kháng nước IP68.</li></ul><h3>Thiết kế Titanium – Hiện đại và chuyên nghiệp</h3><p>Galaxy S24 Ultra sử dụng khung Titanium kết hợp thiết kế vuông vức, tạo nên phong cách nhận diện đặc trưng. Mặt trước phẳng giúp người dùng dễ thao tác bằng ngón tay hoặc bút S Pen, đặc biệt khi ghi chú và chỉnh sửa nội dung ở khu vực gần cạnh màn hình.</p><p>Kính Corning Gorilla Armor hỗ trợ giảm phản xạ ánh sáng và tăng khả năng bảo vệ bề mặt màn hình. Thiết bị có kích thước tương đối lớn nên người dùng cần cân nhắc sự thuận tiện khi cầm nắm và mang theo.</p><h3>Màn hình Dynamic AMOLED 2X 6,8 inch</h3><p>Màn hình QHD+ có độ phân giải 3120 x 1440 pixel, cung cấp không gian hiển thị rộng và chi tiết. Công nghệ AMOLED hỗ trợ màu đen sâu, độ tương phản cao và khả năng tái hiện nội dung sống động.</p><p>Tần số quét thích ứng lên đến 120 Hz giúp chuyển động giao diện mượt mà. Độ sáng đỉnh được công bố lên đến 2.600 nit trong điều kiện phù hợp, hỗ trợ quan sát thông tin khi sử dụng ngoài trời.</p><h3>Snapdragon 8 Gen 3 for Galaxy – Nền tảng hiệu năng mạnh</h3><p>Bộ xử lý Snapdragon 8 Gen 3 for Galaxy phục vụ các tác vụ đa nhiệm, chỉnh sửa hình ảnh, xử lý video và trò chơi có yêu cầu đồ họa cao. Hệ thống quản lý nhiệt hỗ trợ duy trì hoạt động của thiết bị khi xử lý khối lượng công việc lớn.</p><p>Hiệu năng thực tế phụ thuộc vào phần mềm, nhiệt độ môi trường, thiết lập đồ họa và thời gian sử dụng liên tục. Người dùng có thể điều chỉnh chế độ hiệu năng để cân bằng giữa tốc độ xử lý và mức tiêu thụ năng lượng.</p><h3>Galaxy AI – Hỗ trợ công việc và sáng tạo</h3><p>Circle to Search cho phép người dùng tìm kiếm thông tin liên quan đến nội dung đang hiển thị bằng thao tác khoanh vùng. Note Assist hỗ trợ sắp xếp và tóm tắt ghi chú trong các điều kiện tương thích. Live Translate cung cấp khả năng dịch thuật cuộc gọi đối với những ngôn ngữ được hỗ trợ.</p><p>Những công cụ chỉnh sửa ảnh bằng AI có thể hỗ trợ thay đổi bố cục hoặc xử lý một số thành phần trong hình ảnh. Tính khả dụng phụ thuộc vào phiên bản phần mềm, tài khoản, kết nối Internet và khu vực sử dụng.</p><h3>Camera chính 200 MP – Khai thác chi tiết hình ảnh</h3><p>Camera chính có độ phân giải 200 MP, hỗ trợ chống rung quang học và nhiều chế độ chụp khác nhau. Độ phân giải cao cung cấp thêm không gian khi cắt ảnh hoặc chỉnh sửa hình ảnh trong điều kiện ánh sáng phù hợp.</p><p>Hệ thống ProVisual Engine hỗ trợ xử lý hình ảnh, màu sắc và độ chi tiết. Người dùng có thể sử dụng thiết bị để chụp phong cảnh, chân dung, kiến trúc hoặc hình ảnh sản phẩm phục vụ công việc.</p><h3>Hệ thống camera telephoto linh hoạt</h3><p>Galaxy S24 Ultra sở hữu camera telephoto 10 MP hỗ trợ zoom quang học 3x và camera telephoto 50 MP hỗ trợ zoom quang học 5x. Sự kết hợp này cung cấp nhiều lựa chọn tiêu cự cho chụp chân dung và các chủ thể ở xa.</p><p>Thiết bị hỗ trợ những mức thu phóng kỹ thuật số cao hơn, tuy nhiên chất lượng hình ảnh có thể giảm tùy theo mức zoom và điều kiện ánh sáng.</p><h3>Camera siêu rộng và nhiếp ảnh ban đêm</h3><p>Camera Ultra Wide 12 MP phù hợp cho ảnh nhóm, phong cảnh và các không gian có nhiều đối tượng. Các công nghệ xử lý ảnh thiếu sáng hỗ trợ cải thiện độ sáng và giảm nhiễu trong những tình huống chụp ban đêm.</p><h3>Quay video độ phân giải cao</h3><p>Galaxy S24 Ultra hỗ trợ quay video 4K và 8K trong các chế độ tương thích. Hệ thống chống rung hỗ trợ ổn định hình ảnh khi quay. Người dùng có thể lựa chọn độ phân giải và tốc độ khung hình phù hợp với mục đích sử dụng và dung lượng lưu trữ.</p><h3>Bút S Pen – Công cụ ghi chú và sáng tạo</h3><p>S Pen được tích hợp trực tiếp trong thân máy, cho phép ghi chú, phác thảo và lựa chọn nội dung với độ chính xác cao. Người thường xuyên họp, học tập hoặc chỉnh sửa tài liệu có thể sử dụng bút để ghi lại ý tưởng mà không cần mang theo phụ kiện riêng.</p><p>Màn hình phẳng tạo thêm sự thuận tiện khi viết và thao tác ở gần cạnh thiết bị. Các ứng dụng tương thích có thể tận dụng những tính năng điều khiển bổ sung của S Pen.</p><h3>Samsung DeX – Mở rộng không gian làm việc</h3><p>Samsung DeX cho phép kết nối điện thoại với màn hình và phụ kiện tương thích để sử dụng giao diện làm việc dạng máy tính. Người dùng có thể xử lý tài liệu, duyệt web hoặc trình chiếu nội dung trong môi trường phù hợp.</p><h3>Pin 5.000 mAh và sạc nhanh 45 W</h3><p>Viên pin có dung lượng điển hình 5.000 mAh hỗ trợ nhiều hoạt động trong ngày. Thiết bị tương thích sạc có dây tối đa 45 W, sạc không dây và chia sẻ năng lượng không dây với những phụ kiện phù hợp.</p><p>Để đạt công suất sạc tối đa, người dùng cần bộ sạc và cáp đáp ứng yêu cầu kỹ thuật. Thời lượng pin phụ thuộc vào ứng dụng, độ sáng, mạng di động và tình trạng thiết bị.</p><h3>Bảo mật Samsung Knox và kết nối</h3><p>Samsung Knox cung cấp nền tảng bảo mật nhiều lớp để hỗ trợ bảo vệ dữ liệu và thông tin cá nhân. Thiết bị hỗ trợ cảm biến vân tay dưới màn hình, 5G, Wi-Fi 7 và Bluetooth. Khả năng kháng nước IP68 được đánh giá trong điều kiện thử nghiệm tiêu chuẩn.</p><h3>Galaxy S24 Ultra phù hợp với những ai?</h3><ul><li>Người thường xuyên làm việc và xử lý tài liệu trên điện thoại.</li><li>Người yêu thích nhiếp ảnh và cần nhiều tiêu cự camera.</li><li>Người cần S Pen để ghi chú và phác thảo.</li><li>Người ưu tiên màn hình lớn và hiệu năng cao.</li><li>Người muốn sử dụng các công cụ Galaxy AI tương thích.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Galaxy S24 Ultra có bút S Pen đi kèm không?</h4><p>Có. Bút S Pen được tích hợp trong thân máy.</p><h4>Camera 100x có phải zoom quang học không?</h4><p>Không. Thiết bị có các camera telephoto quang học 3x và 5x; những mức thu phóng cao hơn sử dụng xử lý kỹ thuật số.</p><h4>Máy có hỗ trợ sạc 45 W không?</h4><p>Có, khi sử dụng bộ sạc và cáp tương thích với yêu cầu của thiết bị.</p><h4>Galaxy AI có cần Internet không?</h4><p>Tùy tính năng. Một số chức năng có thể xử lý trên thiết bị, trong khi những chức năng khác cần kết nối mạng.</p><h3>Có nên lựa chọn Samsung Galaxy S24 Ultra?</h3><p>Với màn hình QHD+ rộng, hiệu năng mạnh, camera đa tiêu cự và S Pen tích hợp, Galaxy S24 Ultra là lựa chọn đáng cân nhắc cho người muốn sử dụng smartphone như một công cụ hỗ trợ công việc và sáng tạo đa năng.</p>', 'assets/images/products/s24-ultra.jpg'),
(4, 2, N'Samsung Galaxy S24 Plus', N'<h2>Samsung Galaxy S24 Plus – Màn hình QHD+ rộng rãi, Galaxy AI thông minh và pin 4.900 mAh</h2><p><strong>Samsung Galaxy S24 Plus</strong> mang đến sự cân bằng giữa thiết kế hiện đại, không gian hiển thị lớn và hiệu năng cao cấp. Thiết bị phù hợp với người muốn trải nghiệm những tính năng nổi bật của dòng Galaxy S nhưng không cần bút S Pen và hệ thống camera chuyên sâu như phiên bản Ultra.</p><h3>Những điểm nổi bật</h3><ul><li>Màn hình Dynamic AMOLED 2X 6,7 inch QHD+.</li><li>Tần số quét thích ứng lên đến 120 Hz.</li><li>Khung Armor Aluminum.</li><li>Hệ thống ba camera sau với camera chính 50 MP.</li><li>Camera telephoto zoom quang học 3x.</li><li>Các tính năng Galaxy AI tương thích.</li><li>Pin dung lượng điển hình 4.900 mAh.</li><li>Sạc có dây tối đa 45 W và kháng nước IP68.</li></ul><h3>Thiết kế Armor Aluminum tinh tế</h3><p>Galaxy S24 Plus sử dụng khung Armor Aluminum kết hợp mặt trước và mặt sau bằng kính. Các cạnh phẳng và viền màn hình mỏng tạo nên vẻ ngoài hiện đại, tối giản. Cụm camera được bố trí riêng biệt ở mặt lưng, duy trì phong cách nhận diện của dòng Galaxy.</p><p>Thiết kế phù hợp với môi trường học tập, công việc và giải trí. So với phiên bản Ultra, sản phẩm mang phong cách ít góc cạnh hơn và không tích hợp khe chứa bút S Pen.</p><h3>Màn hình Dynamic AMOLED 2X 6,7 inch</h3><p>Độ phân giải QHD+ mang đến khả năng hiển thị chi tiết khi đọc tài liệu, xem phim và chỉnh sửa hình ảnh. Công nghệ AMOLED cung cấp độ tương phản cao cùng màu đen sâu, giúp nội dung có chiều sâu trong những tình huống giải trí.</p><p>Tần số quét thích ứng lên đến 120 Hz hỗ trợ thao tác cuộn trang mượt mà. Độ sáng đỉnh lên đến 2.600 nit trong điều kiện phù hợp giúp người dùng dễ dàng quan sát màn hình dưới ánh sáng mạnh.</p><h3>Hiệu năng cho đa nhiệm và giải trí</h3><p>Galaxy S24 Plus sử dụng bộ xử lý cao cấp thuộc thế hệ Galaxy S24. Tùy thị trường, thiết bị có thể sử dụng Exynos 2400 hoặc Snapdragon 8 Gen 3 for Galaxy. Người mua nên kiểm tra phiên bản cụ thể trước khi đặt hàng.</p><p>Hiệu năng của thiết bị phục vụ các tác vụ như quản lý email, chỉnh sửa tài liệu, sử dụng mạng xã hội, xử lý hình ảnh và chơi game. Dung lượng RAM và bộ nhớ lưu trữ của từng phiên bản ảnh hưởng đến khả năng đa nhiệm và lưu trữ dữ liệu.</p><h3>Galaxy AI – Hỗ trợ công việc hằng ngày</h3><p>Circle to Search giúp tìm kiếm thông tin về nội dung đang hiển thị. Note Assist hỗ trợ tổ chức và tóm tắt ghi chú. Live Translate cung cấp khả năng dịch thuật trong các cuộc gọi tương thích.</p><p>Các công cụ chỉnh sửa hình ảnh bằng AI mang đến thêm lựa chọn khi điều chỉnh bố cục. Khả năng sử dụng phụ thuộc vào phần mềm, ngôn ngữ, khu vực và kết nối mạng.</p><h3>Camera chính 50 MP</h3><p>Camera chính hỗ trợ chống rung quang học OIS, giúp cải thiện độ ổn định khi chụp ảnh và quay video. Cảm biến 50 MP phù hợp với nhiều tình huống như chụp chân dung, phong cảnh, đồ ăn và các hoạt động hằng ngày.</p><h3>Camera telephoto 3x và Ultra Wide 12 MP</h3><p>Camera telephoto 10 MP với zoom quang học 3x cung cấp lựa chọn tiêu cự phù hợp khi chụp chân dung hoặc chủ thể ở xa. Camera Ultra Wide 12 MP hỗ trợ ghi lại phong cảnh và ảnh nhóm trong không gian hạn chế.</p><p>Hệ thống xử lý hình ảnh giúp cân bằng độ sáng, màu sắc và độ chi tiết trong những điều kiện chụp khác nhau. Chất lượng thực tế phụ thuộc vào ánh sáng và chế độ sử dụng.</p><h3>Quay video và sáng tạo nội dung</h3><p>Thiết bị hỗ trợ quay video độ phân giải cao trong các chế độ tương thích. Người dùng có thể ghi lại hoạt động thường ngày, video du lịch hoặc nội dung phục vụ công việc. Các chế độ chống rung giúp cải thiện độ ổn định của khung hình.</p><h3>Pin 4.900 mAh – Nguồn năng lượng cho nhiều hoạt động</h3><p>Viên pin dung lượng điển hình 4.900 mAh hỗ trợ nhu cầu sử dụng hỗn hợp như duyệt web, nghe nhạc, xem video và liên lạc. Hệ thống quản lý năng lượng giúp phân bổ tài nguyên theo tình trạng hoạt động của thiết bị.</p><p>Galaxy S24 Plus hỗ trợ sạc có dây tối đa 45 W và sạc không dây tương thích. Công suất sạc thực tế thay đổi theo bộ sạc, dây cáp, nhiệt độ và mức pin hiện tại.</p><h3>Kết nối và bảo mật</h3><p>Thiết bị hỗ trợ 5G, Wi-Fi, Bluetooth, NFC và Samsung Knox. Cảm biến vân tay dưới màn hình giúp xác thực người dùng thuận tiện. Khả năng kháng nước IP68 được đánh giá trong điều kiện phòng thí nghiệm và có thể giảm theo thời gian.</p><h3>Galaxy S24 Plus phù hợp với những ai?</h3><ul><li>Người ưu tiên màn hình lớn và chất lượng hiển thị cao.</li><li>Người cần smartphone phục vụ công việc và đa nhiệm.</li><li>Người thích chụp ảnh nhưng không cần hệ thống zoom của Ultra.</li><li>Người muốn trải nghiệm Galaxy AI.</li><li>Người cần sự cân bằng giữa kích thước, hiệu năng và pin.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Galaxy S24 Plus có màn hình QHD+ không?</h4><p>Có. Thiết bị sử dụng màn hình Dynamic AMOLED 2X 6,7 inch với độ phân giải QHD+.</p><h4>Máy có hỗ trợ S Pen không?</h4><p>Galaxy S24 Plus không tích hợp hệ thống S Pen như phiên bản S24 Ultra.</p><h4>Máy sử dụng bộ xử lý nào?</h4><p>Bộ xử lý phụ thuộc vào phiên bản và thị trường phân phối. Người mua cần kiểm tra thông số của SKU đang bán.</p><h4>Có thể sử dụng bộ sạc 25 W không?</h4><p>Có thể sử dụng bộ sạc tương thích, nhưng công suất thấp hơn sẽ không tận dụng được khả năng sạc tối đa 45 W.</p><h3>Có nên lựa chọn Galaxy S24 Plus?</h3><p>Galaxy S24 Plus phù hợp với người muốn trải nghiệm màn hình lớn, hiệu năng cao cấp, camera linh hoạt và các công cụ thông minh trong một thiết bị có thiết kế hiện đại, dễ kết hợp với nhiều nhu cầu sử dụng.</p>', 'assets/images/products/s24-plus.jpg'),
(4, 2, N'Samsung Galaxy A55 5G', N'<h2>Samsung Galaxy A55 5G – Thiết kế kim loại cao cấp, màn hình AMOLED 120 Hz và bảo mật Knox Vault</h2><p><strong>Samsung Galaxy A55 5G</strong> là mẫu smartphone tầm trung hướng đến người dùng cần một thiết bị có chất lượng hoàn thiện tốt, màn hình đẹp, hiệu năng ổn định và khả năng chụp ảnh linh hoạt. Khung kim loại, mặt lưng kính và hệ thống camera hỗ trợ chống rung quang học tạo nên những điểm khác biệt đáng chú ý trong phân khúc.</p><h3>Những điểm nổi bật</h3><ul><li>Khung viền kim loại kết hợp mặt lưng kính.</li><li>Màn hình Super AMOLED 6,6 inch Full HD+.</li><li>Tần số quét lên đến 120 Hz.</li><li>Bộ xử lý Exynos 1480.</li><li>Camera chính 50 MP hỗ trợ OIS.</li><li>Camera trước 32 MP.</li><li>Pin dung lượng điển hình 5.000 mAh.</li><li>Sạc có dây tối đa 25 W.</li><li>Samsung Knox Vault và khả năng kháng nước IP67.</li></ul><h3>Thiết kế kim loại – Nâng tầm trải nghiệm sử dụng</h3><p>Galaxy A55 5G được hoàn thiện với khung kim loại mang lại cảm giác chắc chắn. Thiết kế Key Island tạo điểm nhấn ở khu vực nút nguồn và nút âm lượng, đồng thời hỗ trợ nhận diện vị trí các nút khi thao tác.</p><p>Mặt lưng kính kết hợp cụm camera bố trí riêng biệt tạo nên phong cách gần với các mẫu Galaxy cao cấp. Mặt trước sử dụng kính Gorilla Glass Victus+ nhằm hỗ trợ bảo vệ màn hình trong quá trình sử dụng thông thường.</p><h3>Màn hình Super AMOLED 6,6 inch</h3><p>Màn hình Full HD+ cung cấp hình ảnh sắc nét với độ tương phản cao. Công nghệ AMOLED phù hợp cho nhu cầu xem phim, đọc nội dung, lướt mạng xã hội và giải trí bằng hình ảnh.</p><p>Tần số quét 120 Hz hỗ trợ thao tác vuốt chạm và chuyển cảnh mượt mà. Công nghệ Vision Booster giúp cải thiện khả năng quan sát màn hình dưới ánh sáng mạnh trong những điều kiện phù hợp.</p><h3>Exynos 1480 – Hiệu năng cân bằng</h3><p>Bộ xử lý Exynos 1480 phục vụ tốt các hoạt động hằng ngày như duyệt web, liên lạc, học trực tuyến và sử dụng ứng dụng văn phòng. GPU Xclipse 530 hỗ trợ xử lý đồ họa trên các ứng dụng và trò chơi tương thích.</p><p>Người dùng có thể lựa chọn dung lượng RAM và bộ nhớ phù hợp với thói quen sử dụng. Khi chạy trò chơi có yêu cầu đồ họa cao, việc điều chỉnh chất lượng hình ảnh có thể giúp cân bằng hiệu năng và mức tiêu thụ năng lượng.</p><h3>Camera chính 50 MP chống rung quang học</h3><p>Camera chính 50 MP được trang bị OIS để hỗ trợ ổn định hình ảnh. Thiết bị phù hợp cho nhu cầu chụp ảnh đời sống, phong cảnh, sản phẩm và chân dung trong nhiều điều kiện ánh sáng.</p><p>Các thuật toán xử lý hình ảnh giúp cân bằng màu sắc, độ sáng và độ chi tiết. Trong điều kiện thiếu sáng, khả năng chống rung và chế độ chụp phù hợp có thể cải thiện kết quả.</p><h3>Camera Ultra Wide và camera macro</h3><p>Camera siêu rộng 12 MP hỗ trợ ghi lại những khung cảnh lớn hoặc ảnh nhóm. Camera macro 5 MP cho phép khám phá các chi tiết nhỏ của vật thể ở khoảng cách gần. Hai camera bổ sung giúp người dùng có thêm lựa chọn sáng tạo ngoài camera chính.</p><h3>Camera trước 32 MP và quay video</h3><p>Camera trước 32 MP phục vụ nhu cầu chụp ảnh cá nhân, gọi video và tạo nội dung. Thiết bị hỗ trợ quay video 4K trong các chế độ tương thích, phù hợp cho những người muốn ghi lại hoạt động hằng ngày với độ phân giải cao.</p><h3>Pin 5.000 mAh và sạc nhanh 25 W</h3><p>Viên pin có dung lượng điển hình 5.000 mAh cung cấp năng lượng cho các tác vụ học tập, công việc và giải trí. Thời lượng sử dụng thay đổi theo độ sáng màn hình, kết nối mạng, ứng dụng và tình trạng pin.</p><p>Thiết bị hỗ trợ sạc có dây tối đa 25 W với bộ sạc tương thích. Người dùng nên kiểm tra phụ kiện đi kèm của phiên bản đang bán trước khi mua.</p><h3>Samsung Knox Vault – Bổ sung khả năng bảo vệ dữ liệu</h3><p>Knox Vault cung cấp cơ chế bảo vệ thông tin nhạy cảm thông qua nền tảng bảo mật phần cứng và phần mềm. Các tính năng xác thực, quản lý quyền ứng dụng và bảo vệ dữ liệu giúp người dùng kiểm soát thông tin cá nhân tốt hơn.</p><h3>Khả năng kháng nước IP67 và kết nối 5G</h3><p>Galaxy A55 5G đạt chuẩn IP67 trong điều kiện thử nghiệm tiêu chuẩn. Khả năng này hỗ trợ bảo vệ thiết bị trước bụi và nước trong giới hạn nhất định, nhưng không thay thế cho việc sử dụng và bảo quản đúng hướng dẫn.</p><p>Kết nối 5G, Wi-Fi và Bluetooth phục vụ nhu cầu truy cập Internet, sử dụng tai nghe không dây và kết nối các phụ kiện tương thích.</p><h3>Galaxy A55 5G phù hợp với những ai?</h3><ul><li>Người cần smartphone tầm trung có chất lượng hoàn thiện tốt.</li><li>Học sinh, sinh viên và nhân viên văn phòng.</li><li>Người thường xuyên xem phim và sử dụng mạng xã hội.</li><li>Người cần camera chống rung quang học.</li><li>Người quan tâm đến bảo mật và thời lượng pin.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Galaxy A55 5G sử dụng chip gì?</h4><p>Thiết bị sử dụng Exynos 1480.</p><h4>Máy có chống rung quang học không?</h4><p>Có. Camera chính 50 MP được trang bị OIS.</p><h4>Galaxy A55 có hỗ trợ sạc không dây không?</h4><p>Thiết bị không được trang bị tính năng sạc không dây.</p><h4>Có thể sử dụng điện thoại dưới nước không?</h4><p>Chuẩn IP67 chỉ phản ánh kết quả thử nghiệm trong điều kiện nhất định. Không nên chủ động sử dụng thiết bị dưới nước.</p><h3>Có nên lựa chọn Samsung Galaxy A55 5G?</h3><p>Với thiết kế kim loại, màn hình AMOLED 120 Hz, camera OIS và viên pin 5.000 mAh, Galaxy A55 5G là lựa chọn cân bằng cho người cần một chiếc smartphone phục vụ nhiều hoạt động hằng ngày.</p>', 'assets/images/products/samsung-a55.jpg'),
(4, 2, N'Samsung Galaxy A35 5G', N'<h2>Samsung Galaxy A35 5G – Màn hình Super AMOLED 120 Hz, camera OIS và pin dung lượng lớn</h2><p><strong>Samsung Galaxy A35 5G</strong> hướng đến người dùng cần một chiếc smartphone hiện đại, đáp ứng tốt nhu cầu học tập, liên lạc, giải trí và sử dụng ứng dụng hằng ngày. Thiết bị kết hợp màn hình lớn, camera chống rung quang học, kết nối 5G và viên pin 5.000 mAh.</p><h3>Những điểm nổi bật</h3><ul><li>Màn hình Super AMOLED 6,6 inch Full HD+.</li><li>Tần số quét lên đến 120 Hz.</li><li>Bộ xử lý Exynos 1380.</li><li>Camera chính 50 MP hỗ trợ OIS.</li><li>Camera siêu rộng 8 MP và macro 5 MP.</li><li>Pin dung lượng điển hình 5.000 mAh.</li><li>Sạc có dây tối đa 25 W.</li><li>Samsung Knox Vault và khả năng kháng nước IP67.</li></ul><h3>Thiết kế Key Island hiện đại</h3><p>Galaxy A35 5G sử dụng thiết kế cạnh phẳng kết hợp mặt lưng kính và cụm camera bố trí riêng biệt. Khu vực Key Island tạo điểm nhấn cho nút nguồn và nút âm lượng, giúp tổng thể thiết bị có phong cách trẻ trung.</p><p>Mặt trước được trang bị kính Gorilla Glass Victus+ nhằm hỗ trợ tăng khả năng bảo vệ màn hình. Thiết kế phù hợp với nhiều môi trường sử dụng từ trường học đến văn phòng.</p><h3>Màn hình AMOLED 6,6 inch – Trải nghiệm giải trí sống động</h3><p>Màn hình Super AMOLED Full HD+ cung cấp độ tương phản cao và màu sắc sinh động. Không gian 6,6 inch thuận tiện khi xem video, đọc tài liệu điện tử, tham gia lớp học trực tuyến hoặc sử dụng mạng xã hội.</p><p>Tần số quét 120 Hz giúp các thao tác cuộn trang và chuyển đổi giao diện trở nên mượt mà. Vision Booster hỗ trợ cải thiện khả năng hiển thị dưới điều kiện ánh sáng mạnh.</p><h3>Exynos 1380 – Đáp ứng nhu cầu sử dụng phổ biến</h3><p>Exynos 1380 cung cấp hiệu năng phù hợp với các tác vụ liên lạc, duyệt web, học tập và giải trí thông thường. Thiết bị có thể sử dụng nhiều ứng dụng phổ biến và những trò chơi tương thích với cấu hình.</p><p>Người dùng thường xuyên chơi game có thể lựa chọn mức đồ họa phù hợp để duy trì sự ổn định. Khả năng đa nhiệm còn phụ thuộc vào dung lượng RAM và số lượng ứng dụng đang hoạt động.</p><h3>Camera chính 50 MP hỗ trợ chống rung OIS</h3><p>Camera chính 50 MP giúp ghi lại hình ảnh chi tiết trong điều kiện ánh sáng phù hợp. Hệ thống chống rung quang học hỗ trợ giảm ảnh hưởng của những chuyển động nhỏ trong quá trình quay chụp.</p><p>Thiết bị phù hợp cho việc ghi lại tài liệu học tập, hình ảnh du lịch, đồ ăn, sản phẩm và những khoảnh khắc hằng ngày.</p><h3>Camera siêu rộng và macro</h3><p>Camera Ultra Wide 8 MP cung cấp góc nhìn rộng hơn camera chính, hữu ích khi chụp ảnh nhóm hoặc phong cảnh. Camera macro 5 MP bổ sung khả năng ghi lại chi tiết vật thể ở khoảng cách gần.</p><h3>Camera trước và khả năng quay video</h3><p>Camera trước 13 MP phục vụ nhu cầu gọi video và chụp ảnh cá nhân. Thiết bị hỗ trợ quay video 4K trong các chế độ tương thích, mang đến thêm lựa chọn khi ghi lại những hoạt động hằng ngày.</p><h3>Pin 5.000 mAh – Hỗ trợ học tập và giải trí</h3><p>Viên pin dung lượng điển hình 5.000 mAh cung cấp nguồn năng lượng cho nhiều tác vụ trong ngày. Người dùng có thể điều chỉnh độ sáng, tần số quét và các chế độ tiết kiệm điện để phù hợp với nhu cầu.</p><p>Sạc có dây tối đa 25 W hỗ trợ bổ sung năng lượng bằng bộ sạc tương thích. Thời gian sử dụng và sạc thực tế không cố định mà phụ thuộc vào điều kiện hoạt động.</p><h3>Bảo mật Knox Vault và khả năng kháng nước</h3><p>Samsung Knox Vault cung cấp cơ chế hỗ trợ bảo vệ thông tin nhạy cảm. Thiết bị cũng có các tùy chọn xác thực và quản lý quyền truy cập ứng dụng.</p><p>Chuẩn IP67 giúp tăng khả năng bảo vệ trước bụi và nước trong điều kiện thử nghiệm. Người dùng vẫn nên hạn chế tiếp xúc với nước không cần thiết.</p><h3>Kết nối 5G và hệ sinh thái Galaxy</h3><p>Kết nối 5G hỗ trợ truy cập mạng tại những khu vực và nhà mạng tương thích. Wi-Fi, Bluetooth và các công nghệ kết nối khác cho phép sử dụng tai nghe không dây, chia sẻ dữ liệu và kết hợp với các phụ kiện Galaxy.</p><h3>Galaxy A35 5G phù hợp với những ai?</h3><ul><li>Học sinh, sinh viên cần điện thoại phục vụ học tập.</li><li>Người thường xuyên xem phim và sử dụng mạng xã hội.</li><li>Người cần camera chính có chống rung quang học.</li><li>Người ưu tiên pin dung lượng lớn.</li><li>Người muốn trải nghiệm màn hình AMOLED với chi phí hợp lý.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Galaxy A35 5G có màn hình 120 Hz không?</h4><p>Có. Màn hình hỗ trợ tần số quét lên đến 120 Hz.</p><h4>Galaxy A35 khác A55 ở điểm nào?</h4><p>Hai thiết bị có nhiều điểm chung về màn hình và pin, nhưng khác nhau về bộ xử lý, chất liệu khung và một số thông số camera.</p><h4>Máy có hỗ trợ sạc 45 W không?</h4><p>Công suất sạc có dây được hỗ trợ tối đa là 25 W.</p><h3>Có nên lựa chọn Galaxy A35 5G?</h3><p>Galaxy A35 5G là lựa chọn đáng cân nhắc cho người cần một thiết bị cân bằng giữa chất lượng hiển thị, camera, kết nối và thời lượng pin để sử dụng hằng ngày.</p>', 'assets/images/products/samsung-a35.jpg'),
(5, 1, N'AirPods Pro 2', N'<h2>AirPods Pro 2 – Chống ồn chủ động, âm thanh không gian và trải nghiệm nghe cá nhân hóa</h2><p><strong>AirPods Pro 2</strong> là dòng tai nghe không dây cao cấp của Apple, kết hợp chip H2, công nghệ chống ồn chủ động và hệ thống xử lý âm thanh thích ứng. Sản phẩm hướng đến người muốn nghe nhạc, xem phim, làm việc hoặc tham gia cuộc gọi trong nhiều môi trường khác nhau.</p><h3>Những điểm nổi bật của AirPods Pro 2</h3><ul><li>Chip Apple H2 hỗ trợ xử lý âm thanh.</li><li>Chống ồn chủ động Active Noise Cancellation.</li><li>Chế độ xuyên âm Transparency.</li><li>Adaptive Audio và Conversation Awareness.</li><li>Personalized Spatial Audio.</li><li>Điều khiển âm lượng trực tiếp trên thân tai nghe.</li><li>Thời gian nghe lên đến 6 giờ với ANC trong điều kiện thử nghiệm.</li><li>Thời lượng kết hợp hộp sạc lên đến 30 giờ.</li></ul><h3>Thiết kế in-ear với đệm tai silicon</h3><p>AirPods Pro 2 sử dụng thiết kế nhét tai cùng các kích thước đệm silicon khác nhau. Người dùng có thể lựa chọn đệm phù hợp để tạo độ kín cần thiết cho khả năng chống ồn và chất lượng âm thanh.</p><p>Thân tai nghe nhỏ gọn, hộp sạc thuận tiện mang theo trong túi. Độ vừa vặn thực tế phụ thuộc vào cấu tạo tai của từng người và kích thước đệm được sử dụng.</p><h3>Chip H2 – Nền tảng xử lý âm thanh</h3><p>Chip H2 phối hợp cùng hệ thống loa và micro để xử lý âm thanh theo thời gian thực. Các thuật toán hỗ trợ điều chỉnh chất âm, quản lý tiếng ồn và cải thiện trải nghiệm nghe trong nhiều tình huống sử dụng.</p><h3>Chống ồn chủ động ANC</h3><p>Hệ thống micro thu nhận tiếng ồn từ môi trường và sử dụng công nghệ xử lý để giảm những âm thanh không mong muốn. Tính năng này hữu ích khi làm việc trong văn phòng, di chuyển bằng phương tiện công cộng hoặc nghe nhạc tại nơi có nhiều tiếng ồn nền.</p><p>Hiệu quả chống ồn phụ thuộc vào độ kín của đệm tai, loại tiếng ồn và môi trường sử dụng. ANC không loại bỏ hoàn toàn mọi âm thanh bên ngoài.</p><h3>Chế độ xuyên âm và Adaptive Audio</h3><p>Transparency Mode cho phép người dùng nghe âm thanh môi trường mà không cần tháo tai nghe. Adaptive Audio kết hợp các chế độ nghe để điều chỉnh mức độ kiểm soát tiếng ồn theo môi trường trong điều kiện tương thích.</p><p>Conversation Awareness có thể giảm âm lượng nội dung đang phát khi người đeo bắt đầu trò chuyện, hỗ trợ giao tiếp thuận tiện hơn.</p><h3>Spatial Audio – Không gian âm thanh đa chiều</h3><p>Personalized Spatial Audio kết hợp khả năng theo dõi chuyển động đầu với nội dung được hỗ trợ để tạo cảm giác âm thanh có chiều sâu và vị trí. Tính năng phù hợp với những bộ phim, bản nhạc và ứng dụng tương thích.</p><h3>Điều khiển cảm ứng thuận tiện</h3><p>Người dùng có thể nhấn thân tai nghe để phát, tạm dừng hoặc chuyển nội dung. Thao tác vuốt trên thân tai nghe hỗ trợ điều chỉnh âm lượng mà không cần lấy điện thoại ra khỏi túi.</p><h3>Chất lượng cuộc gọi và micro</h3><p>Hệ thống micro hỗ trợ thu nhận giọng nói trong các cuộc gọi, cuộc họp trực tuyến và tương tác với trợ lý ảo. Chất lượng đàm thoại thực tế phụ thuộc vào tiếng ồn môi trường, kết nối và thiết bị ghép nối.</p><h3>Thời lượng pin và hộp sạc</h3><p>Apple công bố thời gian nghe lên đến 6 giờ mỗi lần sạc với chống ồn chủ động trong điều kiện thử nghiệm. Khi kết hợp hộp sạc, tổng thời lượng nghe có thể đạt 30 giờ. Thời lượng thực tế thay đổi theo âm lượng, chế độ nghe và tình trạng pin.</p><p>AirPods Pro 2 có các phiên bản hộp sạc sử dụng Lightning hoặc USB-C. Người mua nên kiểm tra đúng phiên bản để lựa chọn cáp và phụ kiện phù hợp.</p><h3>Kết nối với hệ sinh thái Apple</h3><p>Tai nghe hỗ trợ ghép nối thuận tiện với iPhone, iPad, Mac và các thiết bị Apple tương thích. Những tính năng như chuyển đổi thiết bị, Find My và tùy chỉnh chế độ nghe phụ thuộc vào hệ điều hành và phiên bản phần cứng.</p><h3>AirPods Pro 2 phù hợp với những ai?</h3><ul><li>Người thường xuyên di chuyển và cần giảm tiếng ồn nền.</li><li>Người sử dụng iPhone, iPad hoặc Mac.</li><li>Người yêu thích nghe nhạc và xem phim.</li><li>Người thường xuyên họp trực tuyến.</li><li>Người muốn sử dụng tai nghe in-ear có nhiều chế độ nghe.</li></ul><h3>Câu hỏi thường gặp</h3><h4>AirPods Pro 2 có dùng được với Android không?</h4><p>Có thể kết nối như tai nghe Bluetooth thông thường, nhưng một số tính năng thuộc hệ sinh thái Apple có thể không khả dụng.</p><h4>Tai nghe có chống ồn hoàn toàn không?</h4><p>Không. ANC hỗ trợ giảm tiếng ồn nhưng không loại bỏ toàn bộ âm thanh môi trường.</p><h4>AirPods Pro 2 dùng cổng sạc nào?</h4><p>Tùy phiên bản hộp sạc, sản phẩm có thể sử dụng Lightning hoặc USB-C.</p><h3>Có nên lựa chọn AirPods Pro 2?</h3><p>Với chất âm được xử lý bởi chip H2, nhiều chế độ kiểm soát tiếng ồn và khả năng kết nối thuận tiện trong hệ sinh thái Apple, AirPods Pro 2 phù hợp cho nhu cầu nghe nhạc, làm việc và giải trí hằng ngày.</p>', 'assets/images/products/airpods-pro-2.jpg'),
(5, 1, N'AirPods 4', N'<h2>AirPods 4 – Thiết kế mở hiện đại, chip H2 và trải nghiệm âm thanh linh hoạt</h2><p><strong>AirPods 4</strong> mang đến thiết kế tai nghe không dây dạng mở được cải tiến, kết hợp chip H2 và hệ thống âm học mới. Sản phẩm phù hợp với người không thích sử dụng đệm silicon nhét sâu vào tai nhưng vẫn muốn trải nghiệm khả năng kết nối thuận tiện trong hệ sinh thái Apple.</p><h3>Những điểm nổi bật</h3><ul><li>Thiết kế open-ear không sử dụng đệm silicon.</li><li>Chip H2 hỗ trợ xử lý âm thanh.</li><li>Personalized Spatial Audio.</li><li>Điều khiển bằng cảm biến lực trên thân tai nghe.</li><li>Hộp sạc nhỏ gọn sử dụng USB-C.</li><li>Khả năng kháng bụi, mồ hôi và nước IP54.</li><li>Tổng thời lượng nghe lên đến 30 giờ trong điều kiện phù hợp.</li></ul><h3>Thiết kế open-ear – Trải nghiệm đeo tự nhiên</h3><p>AirPods 4 sử dụng thiết kế mở, không yêu cầu đệm silicon để tạo độ kín trong ống tai. Kiểu dáng này phù hợp với người yêu thích cảm giác đeo thoáng hơn khi nghe nhạc, học tập hoặc làm việc.</p><p>Độ vừa vặn và ổn định khi đeo phụ thuộc vào cấu tạo tai của mỗi người. Thiết kế mở cũng cho phép một phần âm thanh môi trường đi vào tai tự nhiên.</p><h3>Chip H2 và kiến trúc âm học cải tiến</h3><p>Chip H2 hỗ trợ xử lý âm thanh, quản lý kết nối và các tính năng nghe thông minh. Hệ thống âm học được thiết kế để tái hiện giọng hát, nhạc cụ và các dải âm phù hợp với nhiều thể loại nội dung.</p><h3>Personalized Spatial Audio</h3><p>Âm thanh không gian cá nhân hóa hỗ trợ tạo cảm giác âm thanh đến từ nhiều hướng trong nội dung tương thích. Khi xem phim hoặc nghe nhạc được hỗ trợ, người dùng có thể trải nghiệm không gian âm thanh rộng hơn so với phương thức phát stereo thông thường.</p><h3>Chất lượng cuộc gọi và Voice Isolation</h3><p>Các công nghệ xử lý giọng nói hỗ trợ giảm ảnh hưởng của một số tiếng ồn nền khi đàm thoại. Đây là tiện ích hữu ích đối với người thường xuyên gọi điện, học trực tuyến hoặc tham gia cuộc họp từ xa.</p><h3>Thao tác điều khiển trực tiếp</h3><p>Cảm biến lực trên thân tai nghe cho phép phát, tạm dừng nội dung, chuyển bài hát và quản lý cuộc gọi. Người dùng cũng có thể sử dụng những phương thức tương tác với Siri trên thiết bị và phần mềm tương thích.</p><h3>Hộp sạc USB-C nhỏ gọn</h3><p>Hộp sạc được thiết kế để thuận tiện mang theo và bảo quản tai nghe khi không sử dụng. Cổng USB-C cho phép kết hợp với nhiều bộ sạc và dây cáp tương thích.</p><p>AirPods 4 có phiên bản tiêu chuẩn và phiên bản hỗ trợ chống ồn chủ động. Khả năng sạc không dây và các tính năng của hộp sạc khác nhau giữa hai phiên bản, vì vậy cần kiểm tra thông tin sản phẩm trước khi mua.</p><h3>Thời lượng pin cho nhu cầu hằng ngày</h3><p>Phiên bản tiêu chuẩn có thời gian nghe lên đến 5 giờ mỗi lần sạc và tổng thời lượng lên đến 30 giờ khi kết hợp hộp sạc trong điều kiện thử nghiệm. Phiên bản ANC có thời lượng thay đổi theo chế độ chống ồn được sử dụng.</p><h3>Khả năng kháng bụi và nước IP54</h3><p>AirPods 4 được đánh giá theo chuẩn IP54 trong điều kiện thử nghiệm. Khả năng này hỗ trợ bảo vệ trước bụi, mồ hôi và nước bắn nhẹ. Sản phẩm không được thiết kế để ngâm nước hoặc sử dụng khi bơi.</p><h3>Kết nối trong hệ sinh thái Apple</h3><p>Tai nghe hỗ trợ ghép nối thuận tiện với các thiết bị Apple tương thích, đồng thời có thể sử dụng với những thiết bị Bluetooth khác. Các tính năng nâng cao phụ thuộc vào hệ điều hành và phiên bản sản phẩm.</p><h3>AirPods 4 phù hợp với những ai?</h3><ul><li>Người thích tai nghe dạng mở.</li><li>Người sử dụng iPhone và các thiết bị Apple.</li><li>Người cần tai nghe nhỏ gọn để học tập hoặc làm việc.</li><li>Người thường xuyên gọi điện và nghe nội dung trực tuyến.</li></ul><h3>Câu hỏi thường gặp</h3><h4>AirPods 4 có chống ồn chủ động không?</h4><p>Chỉ phiên bản AirPods 4 with Active Noise Cancellation được trang bị ANC.</p><h4>AirPods 4 có đệm tai silicon không?</h4><p>Không. Sản phẩm sử dụng thiết kế open-ear.</p><h4>Hộp sạc có sử dụng USB-C không?</h4><p>Có. Cả hai phiên bản AirPods 4 đều sử dụng cổng sạc USB-C.</p><h3>Có nên lựa chọn AirPods 4?</h3><p>AirPods 4 là lựa chọn đáng cân nhắc nếu người dùng ưu tiên thiết kế mở, khả năng kết nối thuận tiện và trải nghiệm âm thanh phù hợp cho nhiều hoạt động hằng ngày.</p>', 'assets/images/products/airpods-4.jpg'),
(5, 2, N'Samsung Galaxy Buds3 Pro', N'<h2>Samsung Galaxy Buds3 Pro – Âm thanh Hi-Fi, chống ồn thích ứng và thiết kế Blade hiện đại</h2><p><strong>Samsung Galaxy Buds3 Pro</strong> là dòng tai nghe không dây cao cấp kết hợp hệ thống loa hai đường tiếng, công nghệ xử lý âm thanh và chống ồn thích ứng. Thiết bị hướng đến người yêu thích âm nhạc, thường xuyên gọi điện hoặc muốn tận dụng những tính năng thuộc hệ sinh thái Galaxy.</p><h3>Những điểm nổi bật</h3><ul><li>Thiết kế Blade với đệm tai silicon.</li><li>Hệ thống loa hai đường tiếng.</li><li>Hỗ trợ âm thanh độ phân giải cao trên thiết bị tương thích.</li><li>Chống ồn chủ động thích ứng.</li><li>Âm thanh không gian 360 Audio.</li><li>Điều khiển bằng thao tác bóp và vuốt.</li><li>Khả năng kháng bụi và nước IP57 trên tai nghe.</li></ul><h3>Thiết kế Blade – Phong cách nhận diện mới</h3><p>Galaxy Buds3 Pro sử dụng thiết kế thân tai nghe dạng Blade kết hợp đệm silicon để tạo độ kín. Kiểu dáng góc cạnh và hệ thống Blade Light tạo điểm nhấn khác biệt so với những thế hệ Galaxy Buds trước.</p><p>Người dùng có thể lựa chọn kích thước đệm tai phù hợp để cải thiện độ vừa vặn, khả năng chống ồn và chất lượng âm thanh.</p><h3>Hệ thống loa hai đường tiếng</h3><p>Cấu trúc loa được thiết kế để tái hiện các dải âm khác nhau, giúp giọng hát, nhạc cụ và âm trầm có sự phân tách rõ ràng hơn. Hệ thống khuếch đại và xử lý âm thanh phối hợp để mang đến trải nghiệm nghe cân bằng.</p><p>Trên những thiết bị Galaxy tương thích, tai nghe hỗ trợ codec Samsung Seamless Codec nâng cao với khả năng truyền âm thanh độ phân giải cao. Chất lượng thực tế phụ thuộc vào nguồn nhạc, kết nối và thiết bị phát.</p><h3>Chống ồn chủ động thích ứng</h3><p>Adaptive ANC sử dụng hệ thống micro và thuật toán xử lý để điều chỉnh khả năng giảm tiếng ồn theo điều kiện sử dụng. Tính năng hữu ích khi làm việc tại văn phòng, di chuyển hoặc nghe nhạc trong môi trường có tiếng ồn nền.</p><h3>Chế độ âm thanh môi trường</h3><p>Ambient Sound giúp người dùng nghe được âm thanh xung quanh mà không cần tháo tai nghe. Những chức năng nhận diện giọng nói và âm thanh môi trường tương thích có thể tự động điều chỉnh chế độ nghe trong một số tình huống.</p><h3>360 Audio – Trải nghiệm âm thanh có chiều sâu</h3><p>360 Audio tạo hiệu ứng âm thanh đa chiều trên nội dung và thiết bị hỗ trợ. Khi xem phim hoặc sử dụng ứng dụng tương thích, người dùng có thể cảm nhận vị trí âm thanh theo không gian.</p><h3>Galaxy AI và hỗ trợ phiên dịch</h3><p>Galaxy Buds3 Pro có thể phối hợp với các tính năng phiên dịch trên điện thoại Galaxy tương thích. Tai nghe đóng vai trò thiết bị phát âm thanh, trong khi khả năng xử lý ngôn ngữ phụ thuộc vào điện thoại, phần mềm và các dịch vụ được hỗ trợ.</p><h3>Điều khiển và chất lượng cuộc gọi</h3><p>Người dùng có thể thực hiện thao tác bóp hoặc vuốt trên thân tai nghe để điều khiển nội dung, âm lượng và cuộc gọi. Hệ thống micro hỗ trợ thu nhận giọng nói và giảm ảnh hưởng của tiếng ồn nền trong những điều kiện phù hợp.</p><h3>Thời lượng pin và hộp sạc</h3><p>Galaxy Buds3 Pro hỗ trợ thời gian nghe lên đến khoảng 6 giờ khi bật ANC và tổng thời lượng khoảng 26 giờ khi kết hợp hộp sạc trong điều kiện thử nghiệm. Khi tắt ANC, thời gian nghe có thể dài hơn.</p><p>Hộp sạc hỗ trợ USB-C và sạc không dây tương thích. Thời lượng pin thực tế phụ thuộc vào âm lượng, codec, chế độ nghe và tình trạng pin.</p><h3>Khả năng kháng nước IP57</h3><p>Tai nghe được đánh giá đạt chuẩn IP57 trong điều kiện thử nghiệm. Mức bảo vệ này không áp dụng tương tự cho hộp sạc và không có nghĩa sản phẩm phù hợp để sử dụng khi bơi hoặc ngâm nước.</p><h3>Galaxy Buds3 Pro phù hợp với những ai?</h3><ul><li>Người sử dụng smartphone Galaxy tương thích.</li><li>Người ưu tiên chất lượng âm thanh và chống ồn.</li><li>Người thường xuyên xem phim và nghe nhạc.</li><li>Người cần tai nghe hỗ trợ cuộc gọi và làm việc.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Tai nghe có dùng được với iPhone không?</h4><p>Có thể ghép nối qua Bluetooth, nhưng một số tính năng nâng cao và tùy chỉnh có thể không được hỗ trợ đầy đủ.</p><h4>Galaxy Buds3 Pro có sạc không dây không?</h4><p>Hộp sạc hỗ trợ các phương thức sạc không dây tương thích.</p><h4>Phiên dịch AI có hoạt động độc lập trên tai nghe không?</h4><p>Không. Tính năng phụ thuộc vào điện thoại Galaxy và phần mềm tương thích.</p><h3>Có nên lựa chọn Galaxy Buds3 Pro?</h3><p>Sản phẩm phù hợp với người muốn trải nghiệm tai nghe cao cấp có chất âm linh hoạt, nhiều chế độ kiểm soát tiếng ồn và khả năng kết hợp sâu với hệ sinh thái Samsung.</p>', 'assets/images/products/galaxy-buds3-pro.jpg'),
(5, 2, N'Samsung Galaxy Buds FE', N'<h2>Samsung Galaxy Buds FE – Thiết kế vừa vặn, chống ồn chủ động và âm thanh cân bằng</h2><p><strong>Samsung Galaxy Buds FE</strong> là dòng tai nghe Fan Edition tập trung vào những tính năng thiết yếu như chất lượng âm thanh, khả năng chống ồn chủ động và thiết kế đeo ổn định. Sản phẩm phù hợp cho nhu cầu học tập, làm việc, nghe nhạc và liên lạc hằng ngày.</p><h3>Những điểm nổi bật</h3><ul><li>Thiết kế in-ear với đệm tai silicon.</li><li>Đệm cánh wing-tip hỗ trợ giữ tai nghe ổn định.</li><li>Chống ồn chủ động ANC.</li><li>Chế độ Ambient Sound.</li><li>Điều khiển cảm ứng.</li><li>Tổng thời lượng nghe lên đến 30 giờ khi tắt ANC trong điều kiện thử nghiệm.</li><li>Hỗ trợ Auto Switch trên thiết bị Galaxy tương thích.</li></ul><h3>Thiết kế wing-tip – Tăng độ ổn định khi đeo</h3><p>Galaxy Buds FE kết hợp đệm tai silicon và đệm cánh nhằm hỗ trợ cố định tai nghe trong vành tai. Người dùng có thể lựa chọn kích thước phù hợp để cải thiện độ kín và hạn chế tình trạng tai nghe bị dịch chuyển trong quá trình sử dụng.</p><p>Thiết kế nhỏ gọn giúp tai nghe thuận tiện mang theo. Cảm giác đeo phụ thuộc vào cấu tạo tai và cách lựa chọn đệm của từng người.</p><h3>Chất âm phù hợp với nhiều thể loại nội dung</h3><p>Hệ thống loa được tinh chỉnh nhằm tái hiện các dải âm phổ biến, từ giọng hát và nhạc cụ đến âm trầm. Tai nghe phù hợp với nhu cầu nghe nhạc, podcast, bài giảng và xem video.</p><p>Ứng dụng Galaxy Wearable trên thiết bị tương thích cung cấp các tùy chọn điều chỉnh âm thanh để phù hợp hơn với sở thích cá nhân.</p><h3>Chống ồn chủ động ANC</h3><p>ANC hỗ trợ giảm các tiếng ồn nền như âm thanh từ điều hòa, quạt và môi trường xung quanh. Người dùng có thể tập trung hơn khi học tập hoặc làm việc tại những khu vực có tiếng ồn vừa phải.</p><p>Hiệu quả chống ồn phụ thuộc vào độ kín của đệm tai và đặc điểm âm thanh môi trường.</p><h3>Ambient Sound – Theo dõi âm thanh xung quanh</h3><p>Chế độ Ambient Sound hỗ trợ đưa âm thanh môi trường vào tai nghe. Người dùng có thể chuyển đổi giữa chế độ chống ồn và xuyên âm tùy tình huống sử dụng.</p><h3>Điều khiển cảm ứng và cuộc gọi</h3><p>Bề mặt cảm ứng cho phép quản lý nội dung đang phát và cuộc gọi. Hệ thống micro hỗ trợ thu nhận giọng nói, phục vụ các hoạt động liên lạc, học trực tuyến và trao đổi công việc.</p><h3>Thời lượng pin và sạc USB-C</h3><p>Samsung công bố tổng thời lượng nghe lên đến 30 giờ khi tắt ANC và sử dụng cùng hộp sạc trong điều kiện thử nghiệm. Khi bật chống ồn chủ động, thời lượng sẽ thay đổi theo mức tiêu thụ năng lượng.</p><p>Hộp sạc sử dụng USB-C, phù hợp với nhiều dây cáp và bộ sạc tương thích. Galaxy Buds FE không hỗ trợ sạc không dây.</p><h3>Kết nối với hệ sinh thái Galaxy</h3><p>Tai nghe có thể ghép nối với các thiết bị Bluetooth. Tính năng Auto Switch hỗ trợ chuyển đổi giữa những thiết bị Galaxy đáp ứng yêu cầu về tài khoản và phần mềm, giúp người dùng tiếp tục nghe nội dung thuận tiện hơn.</p><h3>Galaxy Buds FE phù hợp với những ai?</h3><ul><li>Người cần tai nghe chống ồn với các tính năng thiết yếu.</li><li>Học sinh, sinh viên thường xuyên nghe bài giảng.</li><li>Người dùng smartphone Samsung.</li><li>Người thích thiết kế có đệm cánh giữ tai nghe.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Galaxy Buds FE có ANC không?</h4><p>Có. Tai nghe hỗ trợ chống ồn chủ động và chế độ âm thanh môi trường.</p><h4>Hộp sạc có hỗ trợ sạc không dây không?</h4><p>Không. Hộp sạc sử dụng cổng USB-C.</p><h4>Thời lượng 30 giờ có áp dụng khi bật ANC không?</h4><p>Đây là tổng thời lượng tham khảo khi tắt ANC và kết hợp hộp sạc.</p><h3>Có nên lựa chọn Galaxy Buds FE?</h3><p>Galaxy Buds FE phù hợp với người ưu tiên thiết kế đeo ổn định, chống ồn chủ động và khả năng kết nối thuận tiện mà không cần toàn bộ tính năng của dòng tai nghe cao cấp.</p>', 'assets/images/products/galaxy-buds-fe.jpg'),
(6, 1, N'Apple USB-C 20W Power Adapter', N'<h2>Apple USB-C 20W Power Adapter – Giải pháp sạc nhanh nhỏ gọn cho thiết bị Apple</h2><p><strong>Apple USB-C 20W Power Adapter</strong> là bộ tiếp hợp nguồn sử dụng cổng USB-C, được thiết kế để cung cấp năng lượng cho iPhone, iPad và những phụ kiện tương thích. Sản phẩm có kích thước nhỏ gọn, phù hợp sử dụng tại nhà, văn phòng hoặc mang theo khi di chuyển.</p><h3>Những điểm nổi bật</h3><ul><li>Công suất đầu ra tối đa 20 W.</li><li>Cổng kết nối USB-C.</li><li>Hỗ trợ sạc nhanh cho các mẫu iPhone tương thích.</li><li>Tương thích với nhiều dây cáp và phụ kiện Apple.</li><li>Thiết kế đơn giản, thuận tiện mang theo.</li></ul><h3>Công suất 20 W – Phù hợp nhu cầu sạc hằng ngày</h3><p>Bộ sạc cung cấp công suất tối đa 20 W thông qua cổng USB-C. Khi kết hợp với điện thoại và cáp tương thích, thiết bị có thể sử dụng cơ chế sạc nhanh được hỗ trợ để rút ngắn thời gian bổ sung năng lượng.</p><p>Apple công bố một số mẫu iPhone có thể sạc đến khoảng 50 phần trăm trong 30 phút với bộ sạc phù hợp. Đây là kết quả trong điều kiện thử nghiệm, không phải tốc độ cố định cho tất cả thiết bị.</p><h3>USB Power Delivery – Phân phối năng lượng phù hợp</h3><p>Công nghệ USB Power Delivery cho phép bộ sạc và thiết bị tương thích trao đổi thông tin về mức điện áp và công suất được hỗ trợ. Thiết bị chỉ tiếp nhận mức năng lượng phù hợp với khả năng sạc của mình trong điều kiện hoạt động bình thường.</p><h3>Khả năng tương thích với iPhone</h3><p>Đối với iPhone sử dụng USB-C, người dùng có thể kết hợp bộ sạc với cáp USB-C to USB-C. Các mẫu iPhone sử dụng cổng Lightning cần cáp USB-C to Lightning phù hợp để tận dụng khả năng sạc nhanh được hỗ trợ.</p><h3>Sử dụng với iPad và phụ kiện Apple</h3><p>Bộ sạc có thể cung cấp năng lượng cho nhiều mẫu iPad, hộp sạc AirPods và dây sạc Apple Watch tương thích. Tuy nhiên, những thiết bị có yêu cầu công suất cao hơn có thể sạc chậm hơn khi sử dụng bộ tiếp hợp 20 W.</p><h3>Thiết kế nhỏ gọn và tiện dụng</h3><p>Vỏ ngoài được hoàn thiện theo phong cách tối giản của Apple. Kích thước nhỏ gọn giúp sản phẩm dễ bố trí trên bàn làm việc, cạnh giường hoặc mang trong túi phụ kiện. Kiểu chấu cắm có thể khác nhau tùy thị trường phân phối.</p><h3>Lưu ý về dây cáp và phụ kiện</h3><p>Bộ tiếp hợp nguồn thường không bao gồm cáp sạc. Người mua cần lựa chọn dây cáp phù hợp với cổng kết nối của thiết bị. Công suất và thời gian sạc thực tế phụ thuộc vào chất lượng cáp, mức pin, nhiệt độ và khả năng tiếp nhận năng lượng.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Người sử dụng iPhone hoặc iPad tương thích.</li><li>Người cần bộ sạc dự phòng tại văn phòng.</li><li>Người muốn phụ kiện có kích thước nhỏ gọn.</li><li>Người đang sử dụng nhiều thiết bị Apple.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Bộ sạc có đi kèm dây cáp không?</h4><p>Thông thường bộ tiếp hợp nguồn được bán riêng. Người mua nên kiểm tra nội dung hộp sản phẩm.</p><h4>Có sử dụng cho iPhone 15 và iPhone 16 không?</h4><p>Có, khi kết hợp với cáp USB-C tương thích.</p><h4>Có đảm bảo iPhone luôn sạc 50 phần trăm trong 30 phút không?</h4><p>Không. Tốc độ thực tế phụ thuộc vào mẫu điện thoại và điều kiện sạc.</p><h3>Có nên lựa chọn Apple USB-C 20W Power Adapter?</h3><p>Đây là phụ kiện phù hợp với người cần bộ sạc USB-C nhỏ gọn, công suất vừa phải và khả năng tương thích tốt với các thiết bị Apple được hỗ trợ.</p>', 'assets/images/products/apple-20w.jpg'),
(6, 2, N'Samsung 25W USB-C Fast Charger', N'<h2>Samsung 25W USB-C Fast Charger – Sạc nhanh Super Fast Charging với chuẩn USB Power Delivery</h2><p><strong>Samsung 25W USB-C Fast Charger</strong> cung cấp giải pháp bổ sung năng lượng cho smartphone Galaxy và những thiết bị USB-C tương thích. Sản phẩm kết hợp công suất tối đa 25 W với các chuẩn phân phối điện năng hiện đại nhằm đáp ứng nhu cầu sạc hằng ngày.</p><h3>Những điểm nổi bật</h3><ul><li>Công suất đầu ra tối đa 25 W.</li><li>Hỗ trợ USB Power Delivery 3.0 và PPS trên phiên bản tương thích.</li><li>Super Fast Charging cho thiết bị Galaxy được hỗ trợ.</li><li>Cổng đầu ra USB-C.</li><li>Thiết kế nhỏ gọn, thuận tiện sử dụng.</li></ul><h3>Super Fast Charging – Rút ngắn thời gian sạc</h3><p>Khi kết hợp với điện thoại Galaxy và cáp phù hợp, bộ sạc có thể kích hoạt chế độ Super Fast Charging được thiết bị hỗ trợ. Công suất được điều chỉnh theo mức pin, nhiệt độ và trạng thái hoạt động của điện thoại.</p><h3>Power Delivery và Programmable Power Supply</h3><p>USB Power Delivery cho phép bộ sạc trao đổi thông tin với thiết bị để lựa chọn mức năng lượng phù hợp. PPS bổ sung khả năng điều chỉnh điện áp và dòng điện linh hoạt trong phạm vi hỗ trợ.</p><p>Việc sử dụng đồng thời bộ sạc, cáp và thiết bị tương thích giúp tận dụng tốt hơn khả năng sạc nhanh của sản phẩm.</p><h3>Khả năng tương thích với smartphone Galaxy</h3><p>Bộ sạc phù hợp với nhiều mẫu điện thoại Samsung hỗ trợ sạc USB-C, bao gồm những thiết bị Galaxy A và Galaxy S tương thích. Các điện thoại hỗ trợ công suất 45 W vẫn có thể sử dụng bộ sạc phù hợp, nhưng không đạt công suất tối đa của điện thoại khi sử dụng nguồn 25 W.</p><h3>Tương thích với thiết bị USB-C khác</h3><p>Ngoài điện thoại Galaxy, sản phẩm có thể cung cấp năng lượng cho tai nghe, máy tính bảng và smartphone hỗ trợ chuẩn sạc phù hợp. Công suất thực tế được giới hạn bởi khả năng tiếp nhận của từng thiết bị.</p><h3>Thiết kế phục vụ nhu cầu di chuyển</h3><p>Kích thước nhỏ gọn giúp bộ sạc dễ mang theo trong túi xách hoặc balo. Cổng USB-C cho phép sử dụng dây cáp có thể tháo rời, thuận tiện khi thay đổi phụ kiện theo thiết bị cần sạc.</p><h3>Cơ chế quản lý năng lượng</h3><p>Bộ sạc tương thích được thiết kế để cung cấp điện năng trong phạm vi thông số kỹ thuật. Người dùng nên sử dụng phụ kiện có nguồn gốc rõ ràng, tránh dây cáp hư hỏng và thay thế thiết bị sạc khi xuất hiện dấu hiệu bất thường.</p><h3>Lưu ý khi lựa chọn sản phẩm</h3><p>Các phiên bản bán lẻ có thể khác nhau về kiểu chấu cắm, màu sắc và việc đi kèm dây cáp. Người mua nên kiểm tra thông số trên SKU cụ thể trước khi đặt hàng.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Người sử dụng điện thoại Galaxy hỗ trợ sạc 25 W.</li><li>Người cần bộ sạc USB-C tại nhà hoặc văn phòng.</li><li>Người thường xuyên di chuyển.</li><li>Người cần bộ sạc cho nhiều thiết bị USB-C tương thích.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Bộ sạc có hỗ trợ Galaxy A55 và A35 không?</h4><p>Có thể sử dụng với các thiết bị hỗ trợ chuẩn sạc tương thích.</p><h4>Có sạc được Galaxy S24 Ultra không?</h4><p>Có, nhưng công suất tối đa của bộ sạc là 25 W thay vì mức 45 W mà điện thoại có thể hỗ trợ.</p><h4>Có bắt buộc sử dụng cáp USB-C to USB-C không?</h4><p>Để sử dụng cổng đầu ra USB-C với điện thoại USB-C và tận dụng chuẩn sạc phù hợp, người dùng cần dây cáp tương thích.</p><h3>Có nên lựa chọn Samsung 25W USB-C Fast Charger?</h3><p>Sản phẩm là lựa chọn thiết thực cho người sử dụng smartphone Galaxy và cần một bộ sạc có công suất phù hợp, dễ mang theo và hỗ trợ những chuẩn sạc USB-C phổ biến.</p>', 'assets/images/products/samsung-25w.jpg'),
(7, 1, N'Apple USB-C Charge Cable 1m', N'<h2>Apple USB-C Charge Cable 1m – Cáp sạc bện chắc chắn, hỗ trợ công suất lên đến 60 W</h2><p><strong>Apple USB-C Charge Cable 1m</strong> là phụ kiện kết nối hai đầu USB-C, phục vụ nhu cầu sạc và đồng bộ dữ liệu giữa những thiết bị tương thích. Thiết kế dây bện cùng chiều dài 1 mét mang lại sự thuận tiện khi sử dụng tại bàn làm việc hoặc mang theo bên mình.</p><h3>Những điểm nổi bật</h3><ul><li>Hai đầu kết nối USB-C.</li><li>Chiều dài 1 mét.</li><li>Thiết kế dây bện.</li><li>Hỗ trợ công suất sạc tối đa 60 W trên phiên bản tương ứng.</li><li>Truyền dữ liệu theo chuẩn USB 2.</li><li>Tương thích với nhiều thiết bị Apple sử dụng USB-C.</li></ul><h3>Thiết kế dây bện – Tiện lợi khi sử dụng hằng ngày</h3><p>Lớp vỏ dây bện mang đến cảm giác chắc chắn và hỗ trợ hạn chế tình trạng rối dây trong quá trình sử dụng. Chiều dài 1 mét phù hợp với việc kết nối điện thoại hoặc máy tính bảng với bộ sạc đặt gần bàn làm việc.</p><p>Để duy trì tuổi thọ phụ kiện, người dùng nên tránh kéo mạnh tại đầu kết nối, gập dây quá mức hoặc sử dụng khi lớp vỏ đã bị hư hỏng.</p><h3>Khả năng sạc lên đến 60 W</h3><p>Phiên bản cáp USB-C 60 W hỗ trợ truyền tải năng lượng trong phạm vi công suất được thiết kế. Khi kết hợp bộ sạc USB Power Delivery và thiết bị tương thích, dây cáp có thể phục vụ nhu cầu sạc smartphone, máy tính bảng và một số laptop.</p><p>Công suất thực tế phụ thuộc vào bộ sạc, thiết bị nhận điện và điều kiện hoạt động. Dây cáp 60 W không tự làm tăng công suất của một bộ sạc có mức đầu ra thấp hơn.</p><h3>Tương thích với iPhone, iPad và MacBook</h3><p>Dây cáp phù hợp với các mẫu iPhone sử dụng USB-C, nhiều dòng iPad và MacBook tương thích. Đối với MacBook có yêu cầu công suất cao, dây 60 W có thể không tận dụng được tốc độ sạc tối đa của thiết bị.</p><h3>Đồng bộ dữ liệu USB 2</h3><p>Sản phẩm hỗ trợ truyền dữ liệu với tốc độ lý thuyết tối đa 480 Mb/s theo chuẩn USB 2. Đây là mức phù hợp cho việc đồng bộ tài liệu và chuyển các tệp có dung lượng vừa phải.</p><p>Người thường xuyên sao chép video chất lượng cao hoặc cần truyền dữ liệu USB 3 nên lựa chọn dây cáp hỗ trợ tốc độ tương ứng.</p><h3>Chiều dài 1 mét – Bố trí gọn gàng</h3><p>Chiều dài dây phù hợp cho các tình huống sử dụng thông thường tại nhà, văn phòng và khi di chuyển. Người dùng có thể kết hợp với bộ sạc đặt cạnh thiết bị mà không cần quản lý quá nhiều dây thừa.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Người sử dụng iPhone 15, iPhone 16 và các thiết bị USB-C tương thích.</li><li>Người cần cáp thay thế hoặc dự phòng.</li><li>Người ưu tiên dây sạc bện nhỏ gọn.</li><li>Người cần đồng bộ dữ liệu ở tốc độ USB 2.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Cáp có hỗ trợ sạc iPhone 14 không?</h4><p>Không thể kết nối trực tiếp với cổng Lightning của iPhone 14. Người dùng cần cáp USB-C to Lightning phù hợp.</p><h4>Cáp có truyền dữ liệu 10 Gb/s không?</h4><p>Không. Phiên bản cáp sạc 60 W này hỗ trợ tốc độ dữ liệu USB 2.</p><h4>Có sử dụng cùng củ sạc Apple 20 W không?</h4><p>Có, khi thiết bị nhận điện sử dụng cổng USB-C tương thích.</p><h3>Có nên lựa chọn Apple USB-C Charge Cable 1m?</h3><p>Đây là lựa chọn phù hợp cho người cần dây sạc USB-C có thiết kế gọn gàng, hỗ trợ công suất vừa phải và khả năng đồng bộ dữ liệu cơ bản trong hệ sinh thái Apple.</p>', 'assets/images/products/apple-cable-c2c.jpg'),
(7, 1, N'Apple USB-C to Lightning Cable', N'<h2>Apple USB-C to Lightning Cable – Sạc nhanh và đồng bộ dữ liệu cho thiết bị sử dụng Lightning</h2><p><strong>Apple USB-C to Lightning Cable</strong> là dây kết nối giữa bộ sạc hoặc máy tính có cổng USB-C với iPhone, iPad và những phụ kiện sử dụng Lightning. Sản phẩm phù hợp với người muốn tiếp tục sử dụng các thiết bị Apple thế hệ trước cùng những bộ sạc USB-C hiện đại.</p><h3>Những điểm nổi bật</h3><ul><li>Một đầu USB-C và một đầu Lightning.</li><li>Hỗ trợ sạc nhanh trên iPhone tương thích.</li><li>Đồng bộ dữ liệu với máy tính.</li><li>Thiết kế phù hợp cho nhu cầu sử dụng hằng ngày.</li><li>Tương thích với các bộ sạc USB-C của Apple.</li></ul><h3>Kết nối Lightning và USB-C</h3><p>Đầu Lightning được thiết kế cho những thiết bị Apple sử dụng cổng kết nối này. Đầu USB-C cho phép kết nối với bộ tiếp hợp nguồn, MacBook và các máy tính có cổng USB-C tương thích.</p><p>Đây là phụ kiện hữu ích khi người dùng sở hữu cả thiết bị Apple đời trước và những bộ sạc thuộc thế hệ USB-C.</p><h3>Hỗ trợ sạc nhanh USB Power Delivery</h3><p>Khi kết hợp với bộ sạc USB-C hỗ trợ Power Delivery, dây cáp cho phép những mẫu iPhone tương thích sử dụng khả năng sạc nhanh. Tốc độ thực tế phụ thuộc vào bộ sạc và giới hạn công suất của điện thoại.</p><p>Mức sạc khoảng 50 phần trăm trong 30 phút được Apple công bố cho một số mẫu iPhone trong điều kiện thử nghiệm phù hợp, không phải kết quả cố định cho mọi thiết bị.</p><h3>Tương thích với iPhone sử dụng Lightning</h3><p>Sản phẩm phù hợp với nhiều mẫu iPhone từ các thế hệ hỗ trợ Lightning, bao gồm iPhone 14 và những dòng tương thích trước đó. Người dùng cần kiểm tra cổng kết nối thực tế của điện thoại trước khi lựa chọn dây sạc.</p><h3>Đồng bộ dữ liệu với máy tính</h3><p>Ngoài sạc pin, dây cáp hỗ trợ kết nối iPhone hoặc iPad Lightning với máy tính tương thích để sao lưu, chuyển hình ảnh và đồng bộ nội dung. Tốc độ truyền dữ liệu phụ thuộc vào chuẩn kết nối và thiết bị sử dụng.</p><h3>Thiết kế tiện lợi cho nhu cầu hằng ngày</h3><p>Dây cáp có thiết kế đơn giản, dễ bố trí tại nhà hoặc văn phòng. Các phiên bản có thể khác nhau về chiều dài, vì vậy người mua nên kiểm tra thông số của SKU đang bán.</p><h3>Sử dụng và bảo quản dây cáp</h3><p>Người dùng nên rút dây bằng cách cầm phần đầu kết nối thay vì kéo trực tiếp vào thân dây. Tránh để cáp bị gập mạnh, xoắn liên tục hoặc tiếp xúc với môi trường ẩm ướt.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Người sử dụng iPhone có cổng Lightning.</li><li>Người muốn tận dụng củ sạc USB-C 20 W.</li><li>Người cần cáp đồng bộ dữ liệu với máy tính.</li><li>Người cần dây sạc dự phòng cho thiết bị Apple đời trước.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Cáp có dùng trực tiếp với iPhone 15 không?</h4><p>Không. iPhone 15 sử dụng cổng USB-C và cần dây kết nối phù hợp.</p><h4>Có hỗ trợ sạc nhanh cho iPhone 13 không?</h4><p>Có, khi kết hợp với bộ sạc USB Power Delivery phù hợp.</p><h4>Cáp có truyền được dữ liệu không?</h4><p>Có. Sản phẩm hỗ trợ đồng bộ dữ liệu với máy tính tương thích.</p><h3>Có nên lựa chọn Apple USB-C to Lightning Cable?</h3><p>Sản phẩm phù hợp với người đang sử dụng các thiết bị Apple có cổng Lightning và cần một phụ kiện kết nối với bộ sạc USB-C hoặc máy tính hiện đại.</p>', 'assets/images/products/apple-cable-c2l.jpg'),
(7, 2, N'Samsung USB-C Cable 1m', N'<h2>Samsung USB-C Cable 1m – Cáp kết nối tiện dụng cho smartphone và thiết bị USB-C</h2><p><strong>Samsung USB-C Cable 1m</strong> phục vụ nhu cầu sạc pin và trao đổi dữ liệu giữa những thiết bị sử dụng cổng USB-C tương thích. Với chiều dài 1 mét, sản phẩm phù hợp sử dụng tại bàn làm việc, trong gia đình hoặc làm dây cáp dự phòng khi di chuyển.</p><h3>Những điểm nổi bật</h3><ul><li>Thiết kế hai đầu USB-C.</li><li>Chiều dài 1 mét thuận tiện sử dụng.</li><li>Hỗ trợ sạc cho thiết bị Galaxy tương thích.</li><li>Hỗ trợ truyền dữ liệu theo thông số của phiên bản cáp.</li><li>Thiết kế đầu kết nối nhỏ gọn.</li></ul><h3>Kết nối USB-C hai chiều</h3><p>Chuẩn USB-C có thiết kế đối xứng, cho phép cắm đầu kết nối theo cả hai chiều. Điều này giúp việc kết nối điện thoại với bộ sạc hoặc máy tính trở nên thuận tiện hơn.</p><h3>Khả năng hỗ trợ sạc nhanh</h3><p>Khi kết hợp với bộ sạc Samsung và thiết bị hỗ trợ chuẩn sạc phù hợp, dây cáp có thể phục vụ nhu cầu sạc nhanh trong phạm vi dòng điện và công suất được thiết kế.</p><p>Đối với phiên bản cáp 3 A, người dùng cần lưu ý rằng khả năng sạc phụ thuộc vào yêu cầu của thiết bị. Những chế độ Super Fast Charging 45 W yêu cầu cáp 5 A tương thích theo thông số của Samsung.</p><h3>Truyền dữ liệu giữa điện thoại và máy tính</h3><p>Người dùng có thể kết nối smartphone với máy tính để chuyển hình ảnh, tài liệu hoặc sao lưu nội dung. Tốc độ truyền dữ liệu thực tế phụ thuộc vào chuẩn USB được hỗ trợ bởi dây cáp và các thiết bị kết nối.</p><p>Không phải mọi dây USB-C đều hỗ trợ truyền hình ảnh hoặc Samsung DeX. Người cần xuất hình ảnh ra màn hình ngoài nên kiểm tra khả năng hỗ trợ video của phiên bản cáp cụ thể.</p><h3>Chiều dài 1 mét – Phù hợp nhiều không gian</h3><p>Chiều dài dây giúp kết nối thuận tiện với bộ sạc đặt trên bàn hoặc ổ cắm ở khoảng cách gần. Thiết kế dễ cuộn gọn để mang theo trong túi phụ kiện.</p><h3>Tương thích với hệ sinh thái Galaxy</h3><p>Dây cáp có thể sử dụng với nhiều mẫu điện thoại Galaxy, máy tính bảng và hộp sạc tai nghe sử dụng USB-C. Người dùng nên kiểm tra yêu cầu công suất và chuẩn kết nối của từng thiết bị.</p><h3>Bảo quản phụ kiện</h3><p>Để duy trì chất lượng kết nối, nên giữ đầu cáp sạch, tránh làm biến dạng chân kết nối và không kéo căng dây trong quá trình sử dụng. Dây có dấu hiệu hư hỏng cần được thay thế.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Người sử dụng điện thoại Samsung Galaxy.</li><li>Người cần dây USB-C thay thế.</li><li>Người cần kết nối điện thoại với máy tính.</li><li>Người muốn chuẩn bị thêm cáp sạc tại văn phòng.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Cáp 3 A có hỗ trợ đầy đủ sạc Samsung 45 W không?</h4><p>Không nên mặc định như vậy. Chế độ sạc 45 W yêu cầu cáp 5 A tương thích theo thông số của Samsung.</p><h4>Cáp có sử dụng được với thiết bị Apple USB-C không?</h4><p>Có thể sử dụng với thiết bị tương thích, trong phạm vi khả năng sạc và truyền dữ liệu của cáp.</p><h4>Mọi dây USB-C đều hỗ trợ xuất hình ảnh phải không?</h4><p>Không. Khả năng xuất hình ảnh phụ thuộc vào chuẩn và thiết kế của dây cáp.</p><h3>Có nên lựa chọn Samsung USB-C Cable 1m?</h3><p>Đây là phụ kiện thiết thực cho người cần một dây kết nối USB-C phục vụ nhu cầu sạc và trao đổi dữ liệu thông thường. Nên kiểm tra thông số công suất của phiên bản đang bán nếu cần sử dụng chế độ sạc đặc biệt.</p>', 'assets/images/products/samsung-cable-c2c.jpg'),
(8, 3, N'Lenovo IdeaPad Slim 3', N'<h2>Lenovo IdeaPad Slim 3 – Laptop mỏng nhẹ cho học tập, công việc văn phòng và giải trí</h2><p><strong>Lenovo IdeaPad Slim 3</strong> là dòng laptop hướng đến người dùng cần một thiết bị có tính di động cao, hiệu năng phù hợp với các tác vụ phổ biến và thiết kế hiện đại. Sản phẩm đặc biệt phù hợp với học sinh, sinh viên, nhân viên văn phòng và người thường xuyên làm việc với tài liệu.</p><h3>Những điểm nổi bật</h3><ul><li>Thiết kế mỏng nhẹ, dễ mang theo.</li><li>Cấu hình Intel Core i3 thế hệ 13 trên phiên bản tham khảo.</li><li>RAM 8 GB trên cấu hình phổ biến.</li><li>Ổ lưu trữ SSD hỗ trợ khởi động và truy cập dữ liệu nhanh.</li><li>Màn hình 15,6 inch Full HD trên phiên bản tương ứng.</li><li>Bàn phím kích thước phù hợp cho công việc văn phòng.</li></ul><h3>Thiết kế tối giản và tính di động</h3><p>IdeaPad Slim 3 sở hữu phong cách thiết kế đơn giản với các đường nét gọn gàng. Vỏ máy và kích thước được tối ưu cho nhu cầu mang theo khi đến trường, thư viện hoặc văn phòng.</p><p>Trọng lượng và chất liệu hoàn thiện có thể thay đổi giữa những phiên bản thuộc dòng sản phẩm. Người mua nên kiểm tra thông số cụ thể nếu thường xuyên di chuyển.</p><h3>Hiệu năng Intel Core i3 cho công việc phổ biến</h3><p>Phiên bản sử dụng Intel Core i3 thế hệ 13 đáp ứng những tác vụ như soạn thảo văn bản, xử lý bảng tính, trình chiếu, duyệt web và học trực tuyến. Bộ xử lý phù hợp với người không cần thực hiện các công việc đồ họa chuyên sâu.</p><p>Người học lập trình có thể sử dụng các trình soạn thảo mã nguồn, công cụ phát triển nhẹ và những môi trường học tập phù hợp với cấu hình.</p><h3>RAM và khả năng đa nhiệm</h3><p>Cấu hình RAM 8 GB phù hợp với nhu cầu mở nhiều ứng dụng văn phòng và các tab trình duyệt ở mức vừa phải. Khi sử dụng phần mềm nặng hoặc chạy nhiều ứng dụng đồng thời, dung lượng RAM lớn hơn có thể mang lại lợi ích rõ rệt.</p><p>Khả năng nâng cấp RAM phụ thuộc vào thiết kế bo mạch và phiên bản máy. Cần kiểm tra cấu hình SKU trước khi quyết định nâng cấp.</p><h3>Ổ cứng SSD – Phản hồi hệ thống nhanh hơn</h3><p>Ổ SSD hỗ trợ cải thiện tốc độ khởi động hệ điều hành, mở ứng dụng và truy cập tài liệu so với ổ cứng cơ học truyền thống. Người dùng có thể lựa chọn dung lượng lưu trữ theo nhu cầu lưu tài liệu, hình ảnh và phần mềm.</p><h3>Màn hình Full HD 15,6 inch</h3><p>Phiên bản 15,6 inch Full HD mang lại không gian hiển thị thuận tiện cho tài liệu và bảng tính. Những tùy chọn màn hình chống chói hỗ trợ giảm phản xạ ánh sáng khi làm việc trong môi trường có nguồn sáng trực tiếp.</p><p>Chất lượng tấm nền, độ sáng và khả năng tái hiện màu sắc có thể khác nhau tùy cấu hình. Người làm đồ họa cần kiểm tra kỹ thông số màu trước khi lựa chọn.</p><h3>Bàn phím và touchpad</h3><p>Bàn phím được bố trí để hỗ trợ nhu cầu nhập liệu thường xuyên. Trên những phiên bản có bàn phím số riêng, người dùng có thể thao tác thuận tiện hơn khi xử lý bảng tính và nhập dữ liệu.</p><p>Touchpad hỗ trợ điều hướng giao diện và các thao tác đa điểm tương thích với hệ điều hành.</p><h3>Webcam, micro và kết nối</h3><p>Webcam và micro tích hợp phục vụ nhu cầu học trực tuyến, họp từ xa và gọi video. Các cổng USB, HDMI và kết nối âm thanh trên phiên bản tương ứng giúp người dùng kết nối chuột, bàn phím, màn hình ngoài và phụ kiện.</p><h3>Thời lượng pin và sử dụng thực tế</h3><p>IdeaPad Slim 3 hướng đến khả năng sử dụng di động cho những tác vụ văn phòng và học tập. Thời lượng pin phụ thuộc vào dung lượng pin của phiên bản, độ sáng màn hình, ứng dụng và chế độ nguồn điện.</p><h3>Lenovo IdeaPad Slim 3 phù hợp với những ai?</h3><ul><li>Học sinh, sinh viên cần laptop học tập.</li><li>Nhân viên văn phòng thường xuyên sử dụng Word và Excel.</li><li>Người học lập trình ở mức cơ bản.</li><li>Người cần máy tính phục vụ duyệt web và giải trí.</li><li>Người ưu tiên tính di động và chi phí hợp lý.</li></ul><h3>Câu hỏi thường gặp</h3><h4>IdeaPad Slim 3 có phù hợp chơi game nặng không?</h4><p>Dòng máy chủ yếu phục vụ học tập và văn phòng. Khả năng chơi game phụ thuộc vào cấu hình đồ họa cụ thể.</p><h4>Có thể nâng cấp RAM không?</h4><p>Khả năng nâng cấp phụ thuộc vào từng mã máy.</p><h4>Máy có phù hợp học lập trình không?</h4><p>Phù hợp với nhiều công cụ lập trình cơ bản. Những môi trường phát triển nặng hoặc máy ảo có thể cần RAM và CPU cao hơn.</p><h3>Có nên lựa chọn Lenovo IdeaPad Slim 3?</h3><p>Đây là dòng laptop đáng cân nhắc cho người cần thiết bị phục vụ công việc phổ thông, học tập và giải trí với thiết kế gọn gàng. Nên lựa chọn cấu hình SKU phù hợp để đáp ứng nhu cầu sử dụng lâu dài.</p>', 'assets/images/products/lenovo-ideapad-slim-3.jpg'),
(8, 3, N'Lenovo ThinkBook 14', N'<h2>Lenovo ThinkBook 14 – Laptop doanh nghiệp nhỏ gọn, hiệu năng ổn định và bảo mật linh hoạt</h2><p><strong>Lenovo ThinkBook 14</strong> là dòng laptop hướng đến nhân viên văn phòng, người làm việc chuyên nghiệp và sinh viên cần một thiết bị cân bằng giữa tính di động, hiệu năng và khả năng kết nối. Thiết kế thanh lịch cùng những tùy chọn cấu hình đa dạng giúp sản phẩm phù hợp với nhiều môi trường làm việc.</p><h3>Những điểm nổi bật</h3><ul><li>Thiết kế 14 inch thuận tiện mang theo.</li><li>Phong cách hoàn thiện hai tông màu đặc trưng.</li><li>Intel Core i5 thế hệ 13 trên cấu hình tham khảo.</li><li>RAM 16 GB trên phiên bản tương ứng.</li><li>Ổ SSD hỗ trợ phản hồi hệ thống nhanh.</li><li>Các tính năng bảo mật và kết nối phục vụ doanh nghiệp.</li></ul><h3>Thiết kế hiện đại cho môi trường chuyên nghiệp</h3><p>ThinkBook 14 mang phong cách thiết kế tối giản với phần nắp máy có cách phối màu đặc trưng. Những phiên bản hoàn thiện bằng kim loại mang lại cảm giác chắc chắn và phù hợp với môi trường công sở.</p><p>Kích thước màn hình 14 inch tạo sự cân bằng giữa diện tích làm việc và tính di động. Người dùng có thể mang máy đến các cuộc họp, lớp học hoặc không gian làm việc linh hoạt.</p><h3>Hiệu năng Intel Core i5</h3><p>Cấu hình sử dụng Intel Core i5 thế hệ 13 cung cấp khả năng xử lý phù hợp với các ứng dụng văn phòng, quản lý dự án, bảng tính và phần mềm doanh nghiệp. Bộ xử lý có thể đáp ứng nhiều tác vụ đồng thời tùy theo thiết lập nguồn điện và cấu hình hệ thống.</p><h3>RAM 16 GB – Hỗ trợ đa nhiệm</h3><p>Phiên bản RAM 16 GB mang lại thêm không gian bộ nhớ khi sử dụng trình duyệt nhiều tab, phần mềm họp trực tuyến và ứng dụng văn phòng cùng lúc. Đây cũng là mức cấu hình phù hợp cho nhiều nhu cầu học lập trình và xử lý dữ liệu thông thường.</p><h3>Ổ lưu trữ SSD</h3><p>Ổ SSD hỗ trợ khởi động hệ điều hành nhanh, cải thiện tốc độ mở phần mềm và truy cập dữ liệu. Dung lượng lưu trữ có thể thay đổi giữa các phiên bản, vì vậy cần cân nhắc nhu cầu sử dụng trước khi lựa chọn.</p><h3>Màn hình 14 inch – Tối ưu không gian làm việc</h3><p>Màn hình kích thước 14 inch phù hợp cho đọc tài liệu, trình chiếu, làm việc với bảng tính và tham gia cuộc họp trực tuyến. Độ phân giải, tỷ lệ màn hình, tấm nền và độ sáng phụ thuộc vào mã máy cụ thể.</p><p>Những phiên bản có lớp phủ chống chói hỗ trợ giảm phản xạ khi sử dụng dưới ánh sáng văn phòng.</p><h3>Bàn phím và trải nghiệm nhập liệu</h3><p>Bàn phím được thiết kế phục vụ người thường xuyên nhập văn bản và xử lý công việc. Một số phiên bản có đèn nền giúp quan sát ký tự trong môi trường thiếu sáng.</p><p>Touchpad hỗ trợ điều hướng và các cử chỉ đa điểm tương thích, giúp thao tác thuận tiện khi không sử dụng chuột ngoài.</p><h3>Bảo mật TPM và xác thực người dùng</h3><p>Các phiên bản tương thích hỗ trợ TPM 2.0 để phục vụ những chức năng bảo mật và mã hóa của hệ điều hành. Một số cấu hình tích hợp cảm biến vân tay tại nút nguồn, hỗ trợ xác thực nhanh chóng.</p><p>Webcam có nắp che vật lý trên những phiên bản được trang bị giúp người dùng chủ động kiểm soát quyền riêng tư khi không sử dụng camera.</p><h3>Kết nối dành cho công việc</h3><p>ThinkBook 14 cung cấp nhiều tùy chọn kết nối như USB-A, USB-C, HDMI và kết nối mạng trên từng cấu hình. Những cổng này hỗ trợ kết nối màn hình ngoài, thiết bị lưu trữ và phụ kiện văn phòng.</p><h3>Pin và khả năng làm việc di động</h3><p>Dòng ThinkBook hướng đến nhu cầu làm việc linh hoạt giữa nhiều địa điểm. Thời lượng pin phụ thuộc vào cấu hình, độ sáng màn hình, ứng dụng và dung lượng pin thực tế của máy.</p><h3>ThinkBook 14 phù hợp với những ai?</h3><ul><li>Nhân viên văn phòng và người làm việc chuyên nghiệp.</li><li>Sinh viên cần laptop phục vụ học tập và lập trình.</li><li>Người thường xuyên di chuyển giữa các địa điểm.</li><li>Người quan tâm đến bảo mật và khả năng kết nối.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Mọi ThinkBook 14 đều có RAM 16 GB không?</h4><p>Không. Dung lượng RAM phụ thuộc vào cấu hình được bán.</p><h4>Máy có cảm biến vân tay không?</h4><p>Một số phiên bản được trang bị. Cần kiểm tra thông số SKU.</p><h4>ThinkBook 14 có phù hợp lập trình không?</h4><p>Cấu hình CPU và RAM phù hợp có thể đáp ứng nhiều công việc phát triển phần mềm. Các dự án nặng cần kiểm tra yêu cầu riêng.</p><h3>Có nên lựa chọn Lenovo ThinkBook 14?</h3><p>ThinkBook 14 là lựa chọn phù hợp cho người ưu tiên laptop gọn gàng, thiết kế chuyên nghiệp và khả năng xử lý công việc đa dạng. Cấu hình nên được lựa chọn theo nhu cầu sử dụng thực tế.</p>', 'assets/images/products/lenovo-thinkbook-14.jpg'),
(8, 3, N'Lenovo IdeaPad 5', N'<h2>Lenovo IdeaPad 5 – Laptop đa dụng cân bằng hiệu năng, thiết kế và khả năng làm việc di động</h2><p><strong>Lenovo IdeaPad 5</strong> hướng đến những người cần một chiếc laptop có thể đáp ứng đồng thời học tập, công việc văn phòng, chỉnh sửa nội dung và giải trí. Dòng sản phẩm cung cấp nhiều lựa chọn bộ xử lý, màn hình và bộ nhớ để phù hợp với các nhóm người dùng khác nhau.</p><h3>Những điểm nổi bật</h3><ul><li>Thiết kế hiện đại, phù hợp nhiều môi trường sử dụng.</li><li>AMD Ryzen 5 trên cấu hình tham khảo.</li><li>Đồ họa Radeon tích hợp trên phiên bản tương ứng.</li><li>Ổ SSD hỗ trợ truy cập dữ liệu nhanh.</li><li>Tùy chọn màn hình có không gian hiển thị rộng.</li><li>Rapid Charge và Dolby Audio trên những phiên bản hỗ trợ.</li></ul><h3>Thiết kế đa dụng và tính di động</h3><p>IdeaPad 5 sử dụng phong cách thiết kế tối giản, phù hợp khi mang đến trường, văn phòng hoặc không gian làm việc cá nhân. Kích thước và trọng lượng thay đổi theo thế hệ và phiên bản màn hình.</p><p>Những tùy chọn hoàn thiện bằng kim loại mang đến cảm giác chắc chắn, trong khi các phiên bản khác tập trung vào sự cân bằng giữa chi phí và tính di động.</p><h3>Hiệu năng AMD Ryzen 5</h3><p>Cấu hình AMD Ryzen 5 đáp ứng các tác vụ như xử lý văn bản, bảng tính, duyệt web, học lập trình và chỉnh sửa hình ảnh ở mức phù hợp. Kiến trúc đa nhân hỗ trợ thực hiện nhiều công việc đồng thời.</p><p>Hiệu năng cụ thể phụ thuộc vào thế hệ bộ xử lý, mức công suất và hệ thống tản nhiệt của phiên bản máy.</p><h3>Đồ họa Radeon tích hợp</h3><p>GPU Radeon tích hợp trên cấu hình AMD hỗ trợ xử lý hình ảnh, phát video độ phân giải cao và những ứng dụng đồ họa phổ biến. Người dùng có thể thực hiện các công việc thiết kế cơ bản, chỉnh sửa ảnh và giải trí bằng những trò chơi phù hợp với cấu hình.</p><p>Đối với dựng hình 3D, render chuyên sâu hoặc trò chơi có yêu cầu cao, laptop trang bị GPU rời có thể phù hợp hơn.</p><h3>Bộ nhớ RAM và ổ SSD</h3><p>RAM ảnh hưởng đến khả năng mở nhiều ứng dụng đồng thời. Người sử dụng phần mềm thiết kế, lập trình hoặc thường xuyên làm việc với nhiều tab trình duyệt nên cân nhắc dung lượng bộ nhớ phù hợp.</p><p>Ổ SSD giúp cải thiện tốc độ khởi động, mở ứng dụng và truy cập tài liệu. Dung lượng lưu trữ nên được lựa chọn theo khối lượng dữ liệu thực tế.</p><h3>Màn hình phục vụ học tập và sáng tạo</h3><p>Các phiên bản IdeaPad 5 cung cấp nhiều tùy chọn màn hình khác nhau. Màn hình có độ phân giải phù hợp giúp quan sát tài liệu, chỉnh sửa hình ảnh và theo dõi nội dung thuận tiện.</p><p>Người làm thiết kế nên kiểm tra độ phủ màu, độ sáng và công nghệ tấm nền của phiên bản cụ thể thay vì chỉ dựa vào tên dòng sản phẩm.</p><h3>Bàn phím và trải nghiệm làm việc</h3><p>Bàn phím được bố trí để hỗ trợ nhập liệu trong thời gian sử dụng thông thường. Một số phiên bản có đèn nền, giúp thao tác thuận tiện hơn trong điều kiện thiếu sáng.</p><h3>Dolby Audio và giải trí đa phương tiện</h3><p>Những phiên bản hỗ trợ Dolby Audio cung cấp các tùy chọn xử lý âm thanh để cải thiện trải nghiệm xem phim, nghe nhạc và tham gia cuộc họp trực tuyến. Chất lượng thực tế phụ thuộc vào nội dung và thiết lập âm thanh.</p><h3>Pin và Rapid Charge</h3><p>Các phiên bản hỗ trợ Rapid Charge cho phép bổ sung năng lượng trong thời gian ngắn với bộ sạc phù hợp. Thời lượng pin thay đổi theo dung lượng pin, bộ xử lý, màn hình và khối lượng công việc.</p><h3>Cổng kết nối và phụ kiện</h3><p>Tùy cấu hình, máy có thể được trang bị USB-C, USB-A, HDMI và các cổng kết nối khác. Người dùng có thể mở rộng không gian làm việc bằng màn hình ngoài, chuột, bàn phím và thiết bị lưu trữ tương thích.</p><h3>IdeaPad 5 phù hợp với những ai?</h3><ul><li>Sinh viên công nghệ thông tin và các ngành học phổ biến.</li><li>Nhân viên văn phòng và người làm nội dung.</li><li>Người cần chỉnh sửa ảnh ở mức cơ bản.</li><li>Người ưu tiên laptop đa dụng dễ mang theo.</li></ul><h3>Câu hỏi thường gặp</h3><h4>IdeaPad 5 có sử dụng card đồ họa rời không?</h4><p>Điều này phụ thuộc vào phiên bản. Cấu hình AMD Ryzen 5 tham khảo sử dụng đồ họa Radeon tích hợp.</p><h4>Có phù hợp sử dụng Photoshop không?</h4><p>Máy có thể đáp ứng nhiều tác vụ chỉnh sửa ảnh phổ biến nếu cấu hình đáp ứng yêu cầu phần mềm.</p><h4>Mọi phiên bản đều hỗ trợ Rapid Charge không?</h4><p>Cần kiểm tra thông số của mã máy cụ thể.</p><h3>Có nên lựa chọn Lenovo IdeaPad 5?</h3><p>IdeaPad 5 phù hợp với người cần laptop linh hoạt cho học tập, công việc và giải trí. Việc chọn đúng bộ xử lý, RAM, màn hình và dung lượng lưu trữ sẽ giúp tối ưu trải nghiệm sử dụng.</p>', 'assets/images/products/lenovo-ideapad-5.jpg'),
(9, 3, N'Lenovo LOQ 15', N'<h2>Lenovo LOQ 15 – Laptop gaming hiệu năng mạnh, màn hình tốc độ cao và khả năng nâng cấp linh hoạt</h2><p><strong>Lenovo LOQ 15</strong> là dòng laptop gaming hướng đến người dùng cần hiệu năng đồ họa rời cho chơi game, học tập kỹ thuật, lập trình và sáng tạo nội dung. Sản phẩm kết hợp thiết kế đặc trưng của laptop gaming với những công nghệ quản lý hiệu năng và tản nhiệt của Lenovo.</p><h3>Những điểm nổi bật</h3><ul><li>GPU NVIDIA GeForce RTX 4050 6 GB trên cấu hình tham khảo.</li><li>Màn hình 15,6 inch với tùy chọn tần số quét 144 Hz.</li><li>CPU Intel hoặc AMD tùy phiên bản.</li><li>Hệ thống tản nhiệt dành cho tác vụ hiệu năng cao.</li><li>Lenovo AI Engine+ trên cấu hình tương thích.</li><li>RAM và SSD với các tùy chọn dung lượng đa dạng.</li></ul><h3>Thiết kế gaming hiện đại</h3><p>Lenovo LOQ 15 sử dụng các đường nét góc cạnh vừa phải, tạo phong cách gaming nhưng vẫn phù hợp với môi trường học tập và công việc. Các khe thông gió được bố trí để hỗ trợ lưu thông không khí trong quá trình máy hoạt động.</p><p>Một số cổng kết nối được bố trí ở phía sau hoặc hai bên thân máy tùy phiên bản, giúp quản lý dây cáp và bố trí góc làm việc thuận tiện hơn.</p><h3>Hiệu năng CPU cho công việc và giải trí</h3><p>Dòng LOQ 15 có nhiều tùy chọn bộ xử lý Intel Core và AMD Ryzen. Những cấu hình hiệu năng cao phù hợp cho lập trình, biên dịch mã nguồn, xử lý dữ liệu và các ứng dụng yêu cầu tài nguyên tính toán.</p><h3>NVIDIA GeForce RTX 4050 – Nền tảng đồ họa rời</h3><p>Phiên bản RTX 4050 Laptop GPU sở hữu 6 GB bộ nhớ đồ họa, sử dụng kiến trúc Ada Lovelace và hỗ trợ các công nghệ như DLSS 3 cùng Ray Tracing trên ứng dụng tương thích.</p><p>GPU rời hỗ trợ xử lý đồ họa trong trò chơi, dựng hình 3D và tăng tốc một số tác vụ sáng tạo. Hiệu năng thực tế phụ thuộc vào mức công suất GPU, bộ xử lý, RAM và hệ thống tản nhiệt.</p><h3>Màn hình 144 Hz – Chuyển động mượt mà</h3><p>Tùy chọn màn hình 15,6 inch 144 Hz cung cấp khả năng cập nhật hình ảnh thường xuyên hơn so với màn hình 60 Hz. Điều này hữu ích trong những trò chơi có chuyển động nhanh và khi thao tác với giao diện.</p><p>Độ phân giải, độ phủ màu và độ sáng màn hình có thể khác nhau giữa các phiên bản. Người làm thiết kế nên kiểm tra thông số tấm nền trước khi lựa chọn.</p><h3>Hệ thống tản nhiệt và quản lý hiệu năng</h3><p>Hệ thống quạt và khe thoát nhiệt hỗ trợ kiểm soát nhiệt độ khi CPU và GPU hoạt động. Các chế độ hiệu năng cho phép người dùng cân bằng giữa tốc độ xử lý, tiếng quạt và mức tiêu thụ năng lượng.</p><p>Lenovo AI Engine+ trên những cấu hình hỗ trợ có thể điều chỉnh phân bổ tài nguyên theo khối lượng công việc. Kết quả thực tế phụ thuộc vào ứng dụng và phiên bản phần mềm.</p><h3>Bộ nhớ và khả năng lưu trữ</h3><p>Dung lượng RAM phù hợp giúp hệ thống xử lý nhiều tác vụ đồng thời. Ổ SSD NVMe hỗ trợ tăng tốc khởi động và giảm thời gian tải dữ liệu trong các ứng dụng và trò chơi.</p><p>Khả năng nâng cấp RAM và SSD phụ thuộc vào cấu trúc của mã máy cụ thể. Người dùng nên kiểm tra số khe cắm và giới hạn dung lượng trước khi nâng cấp.</p><h3>Bàn phím gaming và trải nghiệm điều khiển</h3><p>Bàn phím có bố cục phục vụ cả nhập liệu và chơi game. Những phiên bản hỗ trợ đèn nền giúp quan sát ký tự trong điều kiện thiếu sáng. Touchpad và các phím chức năng hỗ trợ thao tác khi làm việc.</p><h3>Khả năng kết nối và sử dụng màn hình ngoài</h3><p>Các tùy chọn cổng USB, HDMI, Ethernet và USB-C giúp kết nối màn hình ngoài, chuột, bàn phím, tai nghe và thiết bị lưu trữ tương thích.</p><h3>Pin và chế độ nguồn điện</h3><p>Laptop gaming thường tiêu thụ nhiều năng lượng khi GPU rời hoạt động. Để đạt hiệu năng cao theo thiết kế, người dùng nên sử dụng bộ nguồn đi kèm và lựa chọn chế độ hiệu năng phù hợp. Thời lượng pin thay đổi đáng kể theo khối lượng công việc.</p><h3>Lenovo LOQ 15 phù hợp với những ai?</h3><ul><li>Người chơi game cần laptop có GPU rời.</li><li>Sinh viên công nghệ, kỹ thuật và thiết kế.</li><li>Người học dựng hình 3D và chỉnh sửa video.</li><li>Người cần hiệu năng cao hơn laptop văn phòng.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Mọi Lenovo LOQ 15 đều có RTX 4050 không?</h4><p>Không. Dòng máy có nhiều cấu hình GPU khác nhau.</p><h4>Màn hình 144 Hz có đảm bảo game luôn chạy 144 FPS không?</h4><p>Không. FPS phụ thuộc vào cấu hình, trò chơi và thiết lập đồ họa.</p><h4>Có phù hợp học thiết kế 3D không?</h4><p>Những cấu hình có GPU rời phù hợp cho nhiều ứng dụng 3D, nhưng cần đối chiếu yêu cầu của từng phần mềm.</p><h3>Có nên lựa chọn Lenovo LOQ 15?</h3><p>LOQ 15 là lựa chọn đáng cân nhắc cho người cần laptop gaming có hiệu năng đồ họa rời, khả năng mở rộng và thiết kế phù hợp với nhiều nhu cầu học tập, làm việc và giải trí.</p>', 'assets/images/products/lenovo-loq-15.jpg'),
(9, 3, N'Lenovo Legion 5', N'<h2>Lenovo Legion 5 – Hiệu năng gaming mạnh mẽ, màn hình sắc nét và hệ thống tản nhiệt tối ưu</h2><p><strong>Lenovo Legion 5</strong> là dòng laptop hiệu năng cao dành cho người chơi game, sinh viên kỹ thuật và người sáng tạo nội dung. Sản phẩm kết hợp bộ xử lý mạnh, card đồ họa rời và hệ thống quản lý nhiệt nhằm đáp ứng nhiều loại công việc có yêu cầu tài nguyên cao.</p><h3>Những điểm nổi bật</h3><ul><li>NVIDIA GeForce RTX 4060 8 GB trên cấu hình tham khảo.</li><li>Tùy chọn màn hình độ phân giải cao, tần số quét 165 Hz.</li><li>CPU Intel Core hoặc AMD Ryzen tùy phiên bản.</li><li>Hệ thống tản nhiệt Legion Coldfront.</li><li>Bàn phím Legion TrueStrike trên phiên bản tương ứng.</li><li>Khả năng kết nối nhiều phụ kiện và màn hình ngoài.</li></ul><h3>Thiết kế Legion – Cân bằng gaming và công việc</h3><p>Legion 5 sở hữu thiết kế hiện đại, sử dụng những đường nét đơn giản hơn nhiều mẫu laptop gaming truyền thống. Phong cách này giúp máy phù hợp với cả góc giải trí, lớp học và môi trường làm việc chuyên nghiệp.</p><p>Các khe thông gió và khu vực kết nối được bố trí nhằm hỗ trợ hệ thống tản nhiệt và quản lý dây cáp. Kích thước và trọng lượng thay đổi giữa các thế hệ sản phẩm.</p><h3>Hiệu năng CPU cho các tác vụ chuyên sâu</h3><p>Legion 5 cung cấp nhiều lựa chọn bộ xử lý Intel và AMD thuộc phân khúc hiệu năng cao. Những cấu hình phù hợp có thể đáp ứng công việc lập trình, biên dịch dự án, chạy phần mềm kỹ thuật và xử lý nội dung đa phương tiện.</p><h3>GeForce RTX 4060 Laptop GPU</h3><p>Phiên bản RTX 4060 sở hữu 8 GB bộ nhớ đồ họa, hỗ trợ DLSS 3 và Ray Tracing trên các trò chơi, ứng dụng tương thích. GPU rời cung cấp khả năng tăng tốc cho đồ họa 3D, chỉnh sửa video và những công việc khai thác tài nguyên GPU.</p><p>Hiệu năng không chỉ phụ thuộc vào tên GPU mà còn chịu ảnh hưởng bởi công suất được thiết lập, CPU, RAM và khả năng quản lý nhiệt của máy.</p><h3>Màn hình độ phân giải cao và tần số quét 165 Hz</h3><p>Những phiên bản sử dụng màn hình WQHD hoặc WQXGA cung cấp mật độ điểm ảnh cao hơn Full HD, giúp hiển thị chi tiết khi xem nội dung và làm việc với tài liệu.</p><p>Tần số quét 165 Hz trên cấu hình tương ứng hỗ trợ chuyển động mượt mà. Người dùng làm thiết kế nên kiểm tra thêm độ phủ màu sRGB, độ sáng và các thông số hiệu chỉnh màu.</p><h3>Legion Coldfront – Hệ thống quản lý nhiệt</h3><p>Hệ thống tản nhiệt Coldfront sử dụng quạt, khe thông gió và cấu trúc dẫn nhiệt phù hợp với từng phiên bản. Mục tiêu là hỗ trợ CPU và GPU hoạt động ổn định dưới khối lượng công việc cao.</p><p>Người dùng có thể lựa chọn chế độ yên tĩnh, cân bằng hoặc hiệu năng trên những công cụ điều khiển tương thích để phù hợp với môi trường sử dụng.</p><h3>Bàn phím Legion TrueStrike</h3><p>Bàn phím TrueStrike được thiết kế hướng đến khả năng phản hồi khi gõ và chơi game. Bố cục phím hỗ trợ các thao tác nhập liệu thường xuyên, trong khi đèn nền trên một số cấu hình giúp tăng khả năng quan sát trong môi trường thiếu sáng.</p><h3>RAM và lưu trữ SSD</h3><p>Dung lượng RAM lớn có lợi cho đa nhiệm, chỉnh sửa video và sử dụng nhiều công cụ phát triển phần mềm. SSD NVMe hỗ trợ tốc độ đọc ghi nhanh, giúp giảm thời gian tải ứng dụng và dữ liệu.</p><p>Khả năng nâng cấp phụ thuộc vào mã máy và thiết kế bo mạch. Người mua nên kiểm tra giới hạn bộ nhớ và số khe lưu trữ trước khi lựa chọn.</p><h3>Kết nối và mở rộng góc làm việc</h3><p>Legion 5 cung cấp các tùy chọn USB-A, USB-C, HDMI và Ethernet trên những phiên bản tương ứng. Người dùng có thể kết nối màn hình ngoài, thiết bị âm thanh, chuột, bàn phím và các phụ kiện phục vụ công việc.</p><h3>Pin và hiệu năng khi sử dụng di động</h3><p>Thời lượng pin thay đổi theo chế độ nguồn điện, độ sáng màn hình và trạng thái GPU rời. Khi thực hiện công việc nặng hoặc chơi game, bộ nguồn đi kèm giúp máy tiếp cận mức hiệu năng được thiết kế tốt hơn.</p><h3>Legion 5 phù hợp với những ai?</h3><ul><li>Người chơi game cần hiệu năng đồ họa cao.</li><li>Sinh viên kỹ thuật và công nghệ thông tin.</li><li>Người làm thiết kế, dựng video và đồ họa 3D.</li><li>Người cần laptop có khả năng đa nhiệm mạnh.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Legion 5 có luôn sử dụng RTX 4060 không?</h4><p>Không. RTX 4060 là một trong nhiều tùy chọn cấu hình của dòng máy.</p><h4>Có phù hợp chỉnh sửa video 4K không?</h4><p>Những cấu hình CPU, GPU và RAM phù hợp có thể đáp ứng nhiều quy trình chỉnh sửa video 4K.</p><h4>Có nên chỉ dựa vào tên Legion 5 để chọn màn hình không?</h4><p>Không. Cần kiểm tra độ phân giải, tần số quét và độ phủ màu của phiên bản cụ thể.</p><h3>Có nên lựa chọn Lenovo Legion 5?</h3><p>Legion 5 phù hợp với người muốn một chiếc laptop mạnh cho cả chơi game và công việc sáng tạo. Cấu hình GPU rời, màn hình và hệ thống tản nhiệt là những yếu tố nên được cân nhắc theo nhu cầu thực tế.</p>', 'assets/images/products/lenovo-legion-5.jpg'),
(9, 3, N'Lenovo Legion Pro 5', N'<h2>Lenovo Legion Pro 5 – Laptop hiệu năng cao dành cho gaming, sáng tạo nội dung và công việc chuyên sâu</h2><p><strong>Lenovo Legion Pro 5</strong> hướng đến những người cần sức mạnh xử lý CPU và GPU lớn trong một thiết bị có thể di chuyển. Dòng sản phẩm cung cấp nhiều cấu hình hiệu năng cao, hệ thống tản nhiệt chuyên dụng và màn hình có độ phân giải, tần số quét phù hợp với những công việc yêu cầu chất lượng hiển thị tốt.</p><h3>Những điểm nổi bật</h3><ul><li>Intel Core i9-14900HX trên cấu hình tham khảo.</li><li>NVIDIA GeForce RTX 4070 Laptop GPU 8 GB.</li><li>Tùy chọn màn hình WQXGA 240 Hz.</li><li>Độ sáng 500 nit trên phiên bản màn hình tương ứng.</li><li>Hệ thống quản lý nhiệt Legion Coldfront.</li><li>RAM và SSD phục vụ khối lượng công việc lớn.</li></ul><h3>Thiết kế dành cho hiệu năng cao</h3><p>Legion Pro 5 sử dụng kiểu dáng chắc chắn, các khe thông gió lớn và bố trí kết nối hướng đến nhu cầu sử dụng tại bàn làm việc. Phong cách thiết kế phù hợp với người muốn kết hợp giải trí và công việc chuyên nghiệp.</p><p>Do tập trung vào hiệu năng và khả năng tản nhiệt, kích thước cùng trọng lượng của máy có thể lớn hơn những dòng laptop văn phòng mỏng nhẹ.</p><h3>Intel Core i9-14900HX – Khả năng xử lý đa nhân</h3><p>Cấu hình tham khảo sử dụng Intel Core i9-14900HX với 24 lõi và 32 luồng. Bộ xử lý hỗ trợ những công việc yêu cầu tài nguyên tính toán lớn như biên dịch phần mềm, dựng hình, xử lý dữ liệu và đa nhiệm.</p><p>Hiệu năng duy trì phụ thuộc vào chế độ nguồn điện, nhiệt độ, bộ nhớ và giới hạn công suất được thiết lập trên từng phiên bản máy.</p><h3>RTX 4070 Laptop GPU – Tăng tốc đồ họa</h3><p>Phiên bản NVIDIA GeForce RTX 4070 Laptop GPU có 8 GB VRAM, hỗ trợ DLSS 3, Ray Tracing và những công nghệ tăng tốc GPU tương thích. Đây là nền tảng phù hợp cho nhiều trò chơi, phần mềm dựng hình 3D và quy trình chỉnh sửa video.</p><p>Người dùng cần lưu ý GPU laptop có mức công suất và đặc điểm hiệu năng khác với card đồ họa máy tính để bàn cùng tên.</p><h3>Màn hình WQXGA 240 Hz</h3><p>Tùy chọn màn hình 2560 x 1600 pixel với tỷ lệ 16:10 mang đến không gian hiển thị thuận tiện cho cả công việc và giải trí. Tỷ lệ này cung cấp thêm diện tích theo chiều dọc khi đọc tài liệu, lập trình và chỉnh sửa nội dung.</p><p>Trên phiên bản hỗ trợ 240 Hz, chuyển động có thể được thể hiện mượt mà trong các ứng dụng và trò chơi phù hợp. Độ sáng 500 nit và công nghệ đồng bộ khung hình phụ thuộc vào tùy chọn màn hình cụ thể.</p><h3>Hệ thống tản nhiệt Legion Coldfront</h3><p>Hệ thống quản lý nhiệt được thiết kế để hỗ trợ CPU và GPU khi hoạt động dưới khối lượng công việc cao. Quạt, ống dẫn nhiệt và các cấu trúc tản nhiệt khác thay đổi theo thế hệ và cấu hình.</p><p>Người dùng có thể điều chỉnh chế độ hiệu năng bằng phần mềm Lenovo tương thích, lựa chọn sự cân bằng giữa tốc độ xử lý, nhiệt độ và tiếng ồn.</p><h3>RAM và SSD – Phục vụ các dự án lớn</h3><p>Những cấu hình có RAM dung lượng cao hỗ trợ mở nhiều ứng dụng, sử dụng máy ảo và làm việc với các dự án có nhiều dữ liệu. SSD NVMe cải thiện tốc độ truy xuất tệp và thời gian tải phần mềm.</p><p>Người làm video, đồ họa 3D hoặc phát triển phần mềm nên cân nhắc dung lượng lưu trữ theo kích thước dự án. Khả năng nâng cấp cần được kiểm tra theo mã máy.</p><h3>Bàn phím và điều khiển hiệu năng</h3><p>Bàn phím Legion hỗ trợ nhu cầu nhập liệu và chơi game. Các tùy chọn đèn nền và phím chức năng cung cấp thêm khả năng cá nhân hóa trong những cấu hình tương ứng.</p><h3>Khả năng kết nối mở rộng</h3><p>Legion Pro 5 cung cấp nhiều cổng phục vụ màn hình ngoài, thiết bị lưu trữ và mạng có dây. Người dùng có thể xây dựng góc làm việc với nhiều phụ kiện để tận dụng khả năng xử lý của máy.</p><h3>Thời lượng pin và bộ nguồn</h3><p>Cấu hình hiệu năng cao có mức tiêu thụ điện năng lớn khi CPU và GPU hoạt động đồng thời. Bộ nguồn đi kèm được thiết kế để đáp ứng yêu cầu của phiên bản máy. Thời lượng pin khi sử dụng độc lập phụ thuộc đáng kể vào khối lượng công việc.</p><h3>Legion Pro 5 phù hợp với những ai?</h3><ul><li>Người chơi game có yêu cầu cao về hiệu năng.</li><li>Người sử dụng phần mềm dựng hình và thiết kế 3D.</li><li>Người chỉnh sửa video độ phân giải cao.</li><li>Lập trình viên làm việc với các dự án lớn.</li><li>Người cần laptop thay thế một phần công việc của máy tính để bàn.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Mọi Legion Pro 5 đều có Core i9 và RTX 4070 không?</h4><p>Không. Đây là cấu hình tham khảo, dòng máy có nhiều tùy chọn CPU và GPU.</p><h4>Màn hình có luôn đạt 240 Hz không?</h4><p>Chỉ các phiên bản được trang bị tùy chọn màn hình 240 Hz mới hỗ trợ mức này.</p><h4>RTX 4070 Laptop có giống RTX 4070 Desktop không?</h4><p>Không hoàn toàn. Hai phiên bản khác nhau về đặc điểm phần cứng, công suất và hiệu năng thực tế.</p><h3>Có nên lựa chọn Lenovo Legion Pro 5?</h3><p>Đây là lựa chọn phù hợp cho người cần laptop có năng lực xử lý mạnh, GPU rời và màn hình chất lượng cao. Việc chọn đúng SKU giúp cân bằng hiệu năng, chi phí và yêu cầu của phần mềm sử dụng.</p>', 'assets/images/products/lenovo-legion-pro-5.png'),
(10, 3, N'Lenovo Legion M300 RGB', N'<h2>Lenovo Legion M300 RGB – Chuột gaming có dây, cảm biến quang học chính xác và thiết kế đối xứng</h2><p><strong>Lenovo Legion M300 RGB</strong> là chuột gaming có dây hướng đến người cần thiết bị điều khiển linh hoạt cho chơi game, học tập và làm việc. Thiết kế đối xứng, cảm biến quang học và hệ thống nút có thể tùy chỉnh mang đến trải nghiệm phù hợp với nhiều kiểu sử dụng.</p><h3>Những điểm nổi bật</h3><ul><li>Cảm biến quang học hỗ trợ tối đa 8.000 DPI.</li><li>Thiết kế thân chuột đối xứng.</li><li>Kết nối có dây USB.</li><li>Các nút điều khiển có thể tùy chỉnh.</li><li>Đèn RGB tạo điểm nhấn.</li><li>Bề mặt hỗ trợ tăng độ bám khi thao tác.</li></ul><h3>Thiết kế đối xứng – Linh hoạt khi cầm nắm</h3><p>Legion M300 sử dụng kiểu dáng cân đối với đường cong hỗ trợ vị trí đặt tay tự nhiên. Thiết kế phù hợp với nhiều kiểu cầm chuột, tuy nhiên mức độ thoải mái phụ thuộc vào kích thước bàn tay và thói quen sử dụng.</p><h3>Cảm biến quang học 8.000 DPI</h3><p>Cảm biến quang học theo dõi chuyển động trên bề mặt sử dụng và chuyển thành tín hiệu điều khiển con trỏ. Mức DPI tối đa 8.000 cung cấp phạm vi điều chỉnh độ nhạy cho nhiều nhu cầu khác nhau.</p><p>Người dùng có thể lựa chọn DPI thấp khi cần thao tác chính xác hoặc DPI cao khi muốn con trỏ di chuyển nhanh hơn. DPI cao không đồng nghĩa với độ chính xác hoặc hiệu quả sử dụng tốt hơn trong mọi tình huống.</p><h3>Kết nối có dây ổn định</h3><p>Chuột sử dụng kết nối USB có dây, không cần sạc pin hoặc thay pin trong quá trình sử dụng. Phương thức kết nối này phù hợp với góc máy tính cố định và những người ưu tiên sự đơn giản.</p><h3>Nút bấm và khả năng tùy chỉnh</h3><p>Các nút điều khiển hỗ trợ những thao tác như nhấp chuột, cuộn nội dung và truy cập chức năng bổ sung. Trên phần mềm Lenovo tương thích, người dùng có thể thiết lập một số chức năng theo nhu cầu cá nhân.</p><h3>Đèn RGB – Cá nhân hóa góc máy tính</h3><p>Hệ thống đèn RGB tạo điểm nhấn cho thiết kế và có thể phối hợp với những phụ kiện gaming khác. Tùy chọn màu sắc và hiệu ứng phụ thuộc vào khả năng hỗ trợ của phần mềm.</p><h3>Trải nghiệm sử dụng trong công việc</h3><p>Ngoài chơi game, Legion M300 có thể sử dụng để duyệt web, chỉnh sửa tài liệu, lập trình và thao tác với phần mềm thiết kế. Độ nhạy có thể điều chỉnh giúp người dùng lựa chọn tốc độ con trỏ phù hợp từng công việc.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Người chơi game cần chuột có dây.</li><li>Người thích thiết kế chuột đối xứng.</li><li>Học sinh, sinh viên sử dụng máy tính để bàn hoặc laptop.</li><li>Người muốn đồng bộ phụ kiện với góc máy Legion.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Legion M300 có cần sạc pin không?</h4><p>Không. Chuột sử dụng nguồn điện thông qua kết nối USB có dây.</p><h4>Có thể thay đổi DPI không?</h4><p>Có. Người dùng có thể lựa chọn mức độ nhạy trong phạm vi hỗ trợ.</p><h4>Có sử dụng được cho công việc văn phòng không?</h4><p>Có. Chuột hỗ trợ các thao tác máy tính thông thường.</p><h3>Có nên lựa chọn Lenovo Legion M300 RGB?</h3><p>Legion M300 phù hợp với người cần chuột gaming có dây với cảm biến có thể điều chỉnh, thiết kế linh hoạt và khả năng cá nhân hóa bằng đèn RGB.</p>', 'assets/images/products/lenovo-m300.jpg'),
(10, 3, N'Lenovo Legion M600 Wireless', N'<h2>Lenovo Legion M600 Wireless – Chuột gaming không dây đa chế độ, cảm biến 16.000 DPI</h2><p><strong>Lenovo Legion M600 Wireless</strong> là chuột gaming hướng đến người dùng muốn kết hợp sự linh hoạt của kết nối không dây với khả năng điều chỉnh độ nhạy và các nút điều khiển. Sản phẩm phù hợp cho cả chơi game, công việc và sử dụng với nhiều thiết bị tương thích.</p><h3>Những điểm nổi bật</h3><ul><li>Cảm biến quang học hỗ trợ tối đa 16.000 DPI.</li><li>Tốc độ theo dõi lên đến 400 IPS theo thông số công bố.</li><li>Kết nối không dây 2,4 GHz.</li><li>Hỗ trợ Bluetooth và sử dụng có dây.</li><li>Pin sạc tích hợp.</li><li>Thời lượng pin lên đến 200 giờ trong điều kiện phù hợp.</li><li>Thiết kế đối xứng và tùy chỉnh RGB.</li></ul><h3>Thiết kế đối xứng cho nhiều kiểu cầm</h3><p>Legion M600 có kiểu dáng cân đối, hướng đến khả năng sử dụng linh hoạt. Bề mặt thân chuột và các khu vực đặt ngón tay được thiết kế để hỗ trợ độ bám khi thao tác.</p><p>Trọng lượng và độ vừa vặn nên được cân nhắc theo kích thước bàn tay, kiểu cầm và sở thích cá nhân của người sử dụng.</p><h3>Cảm biến 16.000 DPI – Phạm vi điều chỉnh rộng</h3><p>Cảm biến quang học hỗ trợ theo dõi chuyển động và cung cấp nhiều mức độ nhạy. Mức DPI cao cho phép con trỏ di chuyển xa hơn với cùng một khoảng chuyển động vật lý, trong khi mức thấp có thể phù hợp cho những thao tác cần kiểm soát.</p><h3>Kết nối không dây 2,4 GHz</h3><p>Đầu thu USB 2,4 GHz cung cấp phương thức kết nối không dây dành cho nhu cầu phản hồi nhanh. Chất lượng kết nối chịu ảnh hưởng của khoảng cách, môi trường nhiễu và vị trí đặt đầu thu.</p><h3>Bluetooth và chế độ có dây</h3><p>Bluetooth cung cấp thêm lựa chọn kết nối với laptop và thiết bị tương thích mà không cần sử dụng đầu thu riêng. Chế độ có dây giúp tiếp tục sử dụng chuột trong những tình huống phù hợp, đồng thời bổ sung năng lượng cho pin.</p><h3>Pin sạc tích hợp và cổng USB-C</h3><p>Lenovo công bố thời lượng pin có thể lên đến 200 giờ trong điều kiện sử dụng phù hợp. Mức tiêu thụ thực tế thay đổi theo chế độ kết nối, đèn RGB, tần suất sử dụng và tình trạng pin.</p><p>Cổng sạc USB-C giúp kết nối với dây sạc tương thích khi cần bổ sung năng lượng.</p><h3>Nút điều khiển và tùy chỉnh cá nhân</h3><p>Chuột cung cấp các nút bổ sung phục vụ thao tác trong trò chơi hoặc phần mềm. Người dùng có thể sử dụng công cụ Lenovo tương thích để thiết lập những chức năng được hỗ trợ.</p><h3>Đèn RGB và không gian làm việc</h3><p>Hệ thống đèn RGB tạo phong cách cá nhân cho thiết bị. Việc giảm độ sáng hoặc tắt đèn có thể hỗ trợ kéo dài thời lượng pin trong một số điều kiện.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Người thích góc máy tính ít dây cáp.</li><li>Người chơi game cần chuột có độ nhạy linh hoạt.</li><li>Người thường xuyên chuyển đổi giữa laptop và máy tính để bàn.</li><li>Người cần thiết bị có thể sử dụng cả không dây lẫn có dây.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Chuột có hỗ trợ Bluetooth không?</h4><p>Có. Legion M600 hỗ trợ nhiều phương thức kết nối.</p><h4>Thời lượng pin có luôn đạt 200 giờ không?</h4><p>Không. Đây là mức tham khảo trong điều kiện phù hợp, thời lượng thực tế phụ thuộc vào cách sử dụng.</p><h4>Kết nối không dây có hoàn toàn không có độ trễ không?</h4><p>Mọi hệ thống kết nối đều có độ trễ nhất định. Chế độ 2,4 GHz được thiết kế để hỗ trợ phản hồi nhanh trong điều kiện phù hợp.</p><h3>Có nên lựa chọn Lenovo Legion M600 Wireless?</h3><p>Legion M600 là lựa chọn linh hoạt cho người cần chuột không dây có nhiều phương thức kết nối, độ nhạy rộng và pin sạc tích hợp.</p>', 'assets/images/products/lenovo-m600.jpg'),
(11, 3, N'Lenovo Legion K300 RGB', N'<h2>Lenovo Legion K300 RGB – Bàn phím gaming màng, đèn nền đa vùng và hỗ trợ Anti-ghosting</h2><p><strong>Lenovo Legion K300 RGB</strong> là bàn phím gaming sử dụng cơ chế phím màng, hướng đến người cần thiết bị nhập liệu có bố cục đầy đủ, khả năng phản hồi phù hợp và hệ thống đèn nền tùy chỉnh. Sản phẩm có thể phục vụ cả chơi game, học tập và công việc văn phòng.</p><h3>Những điểm nổi bật</h3><ul><li>Cơ chế phím màng.</li><li>Đèn nền RGB 5 vùng.</li><li>Anti-ghosting hỗ trợ tối đa 24 phím theo thông số công bố.</li><li>Bố cục bàn phím đầy đủ.</li><li>Kết nối USB có dây.</li><li>Thiết kế hỗ trợ hạn chế ảnh hưởng của chất lỏng đổ nhẹ.</li></ul><h3>Cơ chế phím màng – Trải nghiệm nhập liệu quen thuộc</h3><p>Legion K300 sử dụng cơ chế phím màng thay vì switch cơ học riêng biệt. Kiểu cấu tạo này mang đến cảm giác gõ đặc trưng, phù hợp với người cần bàn phím phục vụ cả công việc và giải trí.</p><p>Âm thanh khi gõ và lực nhấn thực tế phụ thuộc vào cách thao tác của người dùng. Đây không phải là bàn phím cơ.</p><h3>Bố cục đầy đủ cho nhiều nhu cầu</h3><p>Bàn phím có cụm phím chữ, phím chức năng, phím điều hướng và bàn phím số. Bố cục đầy đủ thuận tiện khi xử lý bảng tính, nhập liệu, sử dụng phần mềm và thiết lập các phím điều khiển trong trò chơi.</p><h3>Anti-ghosting – Hỗ trợ thao tác nhiều phím</h3><p>Công nghệ Anti-ghosting hỗ trợ nhận diện những tổ hợp phím trong phạm vi được thiết kế. Tính năng hữu ích khi người dùng cần nhấn đồng thời nhiều phím trong trò chơi hoặc ứng dụng tương thích.</p><h3>Đèn nền RGB 5 vùng</h3><p>Hệ thống đèn nền được chia thành 5 vùng, cho phép cá nhân hóa màu sắc và hiệu ứng trong phạm vi hỗ trợ. Ánh sáng nền giúp nhận diện vị trí phím khi làm việc trong môi trường thiếu sáng.</p><h3>Thiết kế phím và độ ổn định</h3><p>Các phím được bố trí theo kiểu quen thuộc để người dùng dễ dàng làm quen. Phần thân bàn phím tạo nền tảng ổn định khi đặt trên mặt bàn, trong khi chân đế hỗ trợ điều chỉnh góc sử dụng theo thiết kế.</p><h3>Khả năng hạn chế ảnh hưởng của chất lỏng</h3><p>Thiết kế hỗ trợ thoát lượng chất lỏng đổ nhẹ trong một số tình huống. Tuy nhiên, bàn phím không phải thiết bị chống nước hoàn toàn. Người dùng cần tránh tiếp xúc với chất lỏng và ngừng sử dụng nếu thiết bị bị ướt.</p><h3>Kết nối USB có dây</h3><p>Bàn phím kết nối trực tiếp với máy tính qua USB, không yêu cầu pin hoặc sạc. Các chức năng nhập liệu cơ bản có thể sử dụng trên hệ thống tương thích, trong khi tùy chỉnh nâng cao có thể yêu cầu phần mềm Lenovo.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Người muốn bàn phím gaming có bố cục đầy đủ.</li><li>Người thích cảm giác gõ của bàn phím màng.</li><li>Học sinh, sinh viên và nhân viên văn phòng.</li><li>Người muốn bổ sung đèn RGB cho góc máy tính.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Lenovo Legion K300 có phải bàn phím cơ không?</h4><p>Không. Sản phẩm sử dụng cơ chế phím màng.</p><h4>Bàn phím có kết nối Bluetooth không?</h4><p>Không. Sản phẩm sử dụng kết nối USB có dây.</p><h4>Có thể thay đổi đèn RGB không?</h4><p>Có thể tùy chỉnh trong phạm vi hiệu ứng và phần mềm được hỗ trợ.</p><h3>Có nên lựa chọn Lenovo Legion K300 RGB?</h3><p>K300 phù hợp với người muốn bàn phím có dây, bố cục đầy đủ, khả năng hỗ trợ nhiều phím và đèn nền RGB mà không cần sử dụng switch cơ học.</p>', 'assets/images/products/lenovo-k300.jpg'),
(11, 3, N'Lenovo Go Wireless Split Keyboard', N'<h2>Lenovo Go Wireless Split Keyboard – Bàn phím không dây công thái học với thiết kế tách đôi</h2><p><strong>Lenovo Go Wireless Split Keyboard</strong> được thiết kế cho người thường xuyên nhập liệu, xử lý tài liệu hoặc lập trình. Bố cục phím tách đôi cùng phần kê tay tích hợp mang đến lựa chọn khác biệt so với bàn phím phẳng truyền thống.</p><h3>Những điểm nổi bật</h3><ul><li>Bố cục phím tách đôi dạng công thái học.</li><li>Thiết kế nghiêng hỗ trợ vị trí đặt tay.</li><li>Phần kê tay sử dụng vật liệu cork.</li><li>Cơ chế phím scissor-switch.</li><li>Kết nối không dây qua đầu thu tương thích.</li><li>Phù hợp cho công việc nhập liệu thường xuyên.</li></ul><h3>Thiết kế tách đôi – Thay đổi vị trí đặt tay</h3><p>Hai khu vực phím được bố trí theo góc nghiêng nhằm cho phép người dùng đặt tay ở vị trí khác so với bàn phím phẳng truyền thống. Thiết kế này có thể phù hợp với những người muốn thử một bố cục nhập liệu công thái học.</p><p>Người mới sử dụng bàn phím tách đôi có thể cần thời gian làm quen với vị trí các phím. Mức độ thoải mái phụ thuộc vào thói quen gõ, chiều cao bàn ghế và cách bố trí không gian làm việc.</p><h3>Phần kê tay bằng vật liệu cork</h3><p>Phần kê tay tích hợp cung cấp bề mặt hỗ trợ khi đặt tay nghỉ giữa các thao tác. Vật liệu cork tạo đặc điểm bề mặt riêng, đồng thời góp phần tạo nên phong cách thiết kế của sản phẩm.</p><p>Người dùng nên bố trí bàn phím sao cho vị trí tay và vai phù hợp, thay vì chỉ dựa vào phần kê tay để thay đổi tư thế làm việc.</p><h3>Scissor-switch – Cơ chế phím cắt kéo</h3><p>Cơ chế phím scissor-switch thường có hành trình tương đối ngắn và cấu trúc hỗ trợ chuyển động phím ổn định. Kiểu phím này phù hợp với người đã quen trải nghiệm gõ trên bàn phím laptop.</p><h3>Kết nối không dây</h3><p>Bàn phím sử dụng đầu thu không dây tương thích để kết nối với máy tính. Phương thức này giúp giảm số lượng dây cáp trên bàn làm việc. Người mua cần kiểm tra loại đầu thu và các phương thức kết nối của phiên bản đang bán trước khi đặt hàng.</p><h3>Phục vụ công việc văn phòng và lập trình</h3><p>Bố cục bàn phím hỗ trợ nhập văn bản, làm việc với bảng tính và sử dụng các trình soạn thảo mã nguồn. Các phím chức năng có thể cung cấp thao tác truy cập nhanh trên hệ điều hành tương thích.</p><h3>Bố trí góc làm việc phù hợp</h3><p>Bàn phím tách đôi cần không gian đặt thiết bị phù hợp. Người dùng nên cân nhắc vị trí chuột, màn hình và chiều cao bàn để có trải nghiệm thuận tiện. Sản phẩm không phải thiết bị y tế và không bảo đảm ngăn ngừa các vấn đề về cổ tay.</p><h3>Nguồn điện và bảo quản</h3><p>Loại pin và thời lượng hoạt động phụ thuộc vào thông số của phiên bản sản phẩm. Người dùng nên kiểm tra yêu cầu nguồn điện, bảo quản đầu thu và vệ sinh bề mặt theo hướng dẫn của nhà sản xuất.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Nhân viên văn phòng thường xuyên nhập văn bản.</li><li>Lập trình viên muốn thử bàn phím bố cục tách đôi.</li><li>Người ưu tiên góc làm việc ít dây cáp.</li><li>Người yêu thích cơ chế phím hành trình ngắn.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Bàn phím có khó làm quen không?</h4><p>Người quen bố cục truyền thống có thể cần thời gian thích nghi với vị trí phím tách đôi.</p><h4>Đây có phải bàn phím cơ không?</h4><p>Không. Sản phẩm sử dụng cơ chế scissor-switch.</p><h4>Bàn phím có hỗ trợ Bluetooth không?</h4><p>Không nên mặc định có Bluetooth. Cần kiểm tra phương thức kết nối của mã sản phẩm cụ thể.</p><h3>Có nên lựa chọn Lenovo Go Wireless Split Keyboard?</h3><p>Sản phẩm phù hợp với người muốn trải nghiệm bàn phím không dây có bố cục công thái học khác biệt, phần kê tay tích hợp và cảm giác gõ kiểu laptop.</p>', 'assets/images/products/lenovo-go-split.jpg'),
(12, 3, N'Lenovo 300 FHD Webcam', N'<h2>Lenovo 300 FHD Webcam – Webcam Full HD 1080p cho học tập và họp trực tuyến</h2><p><strong>Lenovo 300 FHD Webcam</strong> là phụ kiện camera ngoài dành cho máy tính để bàn và laptop, hỗ trợ cải thiện khả năng ghi hình trong các cuộc gọi video. Sản phẩm phù hợp với nhu cầu học trực tuyến, họp từ xa, phỏng vấn và trao đổi công việc.</p><h3>Những điểm nổi bật</h3><ul><li>Độ phân giải Full HD 1080p.</li><li>Góc nhìn rộng khoảng 95 độ.</li><li>Micro kép tích hợp.</li><li>Kết nối USB thuận tiện.</li><li>Nắp che camera vật lý.</li><li>Thiết kế hỗ trợ gắn trên màn hình tương thích.</li></ul><h3>Chất lượng hình ảnh Full HD</h3><p>Webcam hỗ trợ ghi hình ở độ phân giải 1920 x 1080 pixel trong chế độ tương thích. Độ phân giải này phù hợp với các cuộc họp video, bài giảng trực tuyến và nhu cầu ghi hình thông thường.</p><p>Chất lượng hình ảnh thực tế còn phụ thuộc vào ánh sáng, tốc độ mạng, phần mềm gọi video và mức độ nén dữ liệu.</p><h3>Góc nhìn rộng 95 độ</h3><p>Ống kính có góc nhìn rộng giúp thu nhận nhiều không gian hơn trong khung hình. Đây là lợi thế khi người dùng muốn hiển thị một phần bàn làm việc hoặc có nhiều người cùng xuất hiện trong cuộc gọi.</p><p>Người sử dụng cá nhân có thể điều chỉnh vị trí webcam để bố cục hình ảnh phù hợp và hạn chế những vật dụng không cần thiết xuất hiện phía sau.</p><h3>Micro kép tích hợp</h3><p>Hệ thống micro hỗ trợ thu nhận giọng nói khi tham gia cuộc họp hoặc lớp học trực tuyến. Người dùng có thể sử dụng micro tích hợp mà không cần kết nối thiết bị thu âm riêng trong những môi trường phù hợp.</p><p>Chất lượng âm thanh phụ thuộc vào khoảng cách, tiếng ồn phòng và khả năng xử lý của phần mềm.</p><h3>Nắp che vật lý – Chủ động kiểm soát camera</h3><p>Nắp che camera cho phép che ống kính khi không sử dụng. Đây là phương thức kiểm soát trực quan, giúp người dùng dễ dàng nhận biết trạng thái che chắn của camera.</p><h3>Thiết kế lắp đặt linh hoạt</h3><p>Giá đỡ được thiết kế để gắn webcam lên những màn hình và laptop tương thích. Người dùng có thể điều chỉnh vị trí và góc camera theo chiều cao màn hình và không gian làm việc.</p><h3>Kết nối USB và khả năng tương thích</h3><p>Webcam kết nối với máy tính thông qua USB. Các hệ điều hành hỗ trợ thiết bị camera USB tiêu chuẩn có thể nhận diện sản phẩm mà không cần quá trình cài đặt phức tạp. Một số chức năng có thể phụ thuộc vào phần mềm đang sử dụng.</p><h3>Trải nghiệm học tập và làm việc</h3><p>Lenovo 300 FHD Webcam phù hợp khi sử dụng các nền tảng họp trực tuyến, lớp học từ xa và ứng dụng gọi video tương thích. Người dùng có thể kết hợp thêm đèn chiếu sáng phù hợp để cải thiện chất lượng hình ảnh.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Học sinh, sinh viên tham gia lớp học trực tuyến.</li><li>Nhân viên thường xuyên họp từ xa.</li><li>Người sử dụng máy tính để bàn không có camera.</li><li>Người muốn nâng cấp webcam tích hợp của laptop.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Webcam có micro không?</h4><p>Có. Sản phẩm được trang bị hệ thống micro tích hợp.</p><h4>Hình ảnh có luôn đạt Full HD khi gọi video không?</h4><p>Không. Độ phân giải thực tế phụ thuộc vào phần mềm và chất lượng kết nối mạng.</p><h4>Có cần mua chân máy riêng không?</h4><p>Webcam có giá đỡ tích hợp. Nhu cầu sử dụng chân máy riêng phụ thuộc vào cách bố trí camera.</p><h3>Có nên lựa chọn Lenovo 300 FHD Webcam?</h3><p>Đây là lựa chọn phù hợp cho người cần webcam Full HD có micro tích hợp, nắp che riêng tư và khả năng kết nối đơn giản phục vụ học tập và công việc.</p>', 'assets/images/products/lenovo-300-webcam.jpg'),
(12, 3, N'Lenovo Performance FHD Webcam', N'<h2>Lenovo Performance FHD Webcam – Camera Full HD cho môi trường làm việc chuyên nghiệp</h2><p><strong>Lenovo Performance FHD Webcam</strong> hướng đến người thường xuyên tham gia hội nghị trực tuyến, thuyết trình, phỏng vấn và làm việc từ xa. Sản phẩm cung cấp khả năng ghi hình Full HD cùng những tính năng hỗ trợ kết nối và sử dụng camera trên máy tính tương thích.</p><h3>Những điểm nổi bật</h3><ul><li>Khả năng ghi hình Full HD 1080p.</li><li>Góc nhìn phù hợp cho hội nghị trực tuyến.</li><li>Micro tích hợp trên phiên bản tương ứng.</li><li>Kết nối USB với máy tính tương thích.</li><li>Hỗ trợ Windows Hello trên phiên bản có camera hồng ngoại tương thích.</li><li>Thiết kế phục vụ không gian làm việc chuyên nghiệp.</li></ul><h3>Độ phân giải Full HD – Hình ảnh rõ ràng</h3><p>Webcam cung cấp độ phân giải 1920 x 1080 pixel trong chế độ hỗ trợ, phù hợp cho các cuộc họp, bài thuyết trình và giao tiếp trực tuyến. Người dùng có thể tận dụng chất lượng hình ảnh để hiển thị khuôn mặt và những nội dung cần trình bày.</p><p>Tốc độ khung hình và chất lượng ghi hình phụ thuộc vào mã sản phẩm, chế độ camera, phần mềm và điều kiện ánh sáng. Không nên mặc định mọi phiên bản đều hỗ trợ 1080p 60 fps.</p><h3>Khả năng xử lý hình ảnh trong môi trường văn phòng</h3><p>Camera hỗ trợ ghi nhận hình ảnh trong những điều kiện ánh sáng làm việc thông thường. Việc bố trí nguồn sáng phía trước người sử dụng có thể giúp hình ảnh cân bằng hơn và hạn chế tình trạng ngược sáng.</p><h3>Windows Hello – Xác thực khuôn mặt</h3><p>Những phiên bản được trang bị hệ thống camera hồng ngoại tương thích có thể hỗ trợ Windows Hello trên máy tính đáp ứng yêu cầu phần cứng và hệ điều hành. Tính năng này cho phép người dùng đăng nhập thông qua cơ chế nhận diện khuôn mặt của Windows.</p><p>Khả năng hỗ trợ Windows Hello cần được xác nhận theo mã webcam cụ thể và cấu hình máy tính.</p><h3>Micro và trải nghiệm hội nghị</h3><p>Hệ thống micro tích hợp trên phiên bản tương ứng giúp thu nhận giọng nói trong quá trình họp trực tuyến. Người dùng có thể kết hợp với tai nghe hoặc micro ngoài khi cần chất lượng âm thanh phù hợp hơn với môi trường sử dụng.</p><h3>Giá đỡ và góc đặt camera</h3><p>Thiết kế giá đỡ hỗ trợ bố trí webcam trên màn hình hoặc vị trí tương thích. Việc đặt camera gần tầm mắt giúp tạo góc nhìn tự nhiên trong các cuộc họp và bài thuyết trình.</p><h3>Kết nối và khả năng tương thích</h3><p>Webcam sử dụng kết nối USB với máy tính. Kiểu đầu cáp, chiều dài và khả năng tháo rời có thể khác nhau tùy mã sản phẩm. Người dùng nên kiểm tra cổng kết nối trước khi lựa chọn.</p><h3>Ứng dụng trong công việc chuyên nghiệp</h3><p>Lenovo Performance FHD Webcam có thể sử dụng với các nền tảng họp trực tuyến tương thích, hỗ trợ trao đổi công việc, phỏng vấn, đào tạo và trình bày nội dung. Chất lượng truyền hình ảnh còn phụ thuộc vào băng thông mạng và giới hạn của ứng dụng.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Nhân viên thường xuyên họp trực tuyến.</li><li>Người làm việc tại nhà.</li><li>Giảng viên và người đào tạo từ xa.</li><li>Người cần webcam ngoài cho máy tính để bàn.</li><li>Người quan tâm đến khả năng đăng nhập Windows Hello trên phiên bản hỗ trợ.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Webcam có hỗ trợ Windows Hello không?</h4><p>Những phiên bản có hệ thống camera hồng ngoại tương thích hỗ trợ tính năng này. Cần kiểm tra mã sản phẩm cụ thể.</p><h4>Camera có luôn ghi hình 60 fps không?</h4><p>Không nên mặc định như vậy. Tốc độ khung hình phụ thuộc vào thông số phiên bản và chế độ sử dụng.</p><h4>Webcam có hỗ trợ lấy nét tự động không?</h4><p>Cần kiểm tra thông số chính thức của SKU vì cơ chế lấy nét có thể khác nhau.</p><h3>Có nên lựa chọn Lenovo Performance FHD Webcam?</h3><p>Sản phẩm phù hợp cho môi trường làm việc cần webcam Full HD và những tính năng hội nghị trực tuyến. Người mua nên xác nhận các yêu cầu về Windows Hello, tốc độ khung hình và kết nối trước khi đặt hàng.</p>', 'assets/images/products/lenovo-fhd-webcam.jpg'),
(13, 3, N'Lenovo Laptop Backpack 15.6"', N'<h2>Lenovo Laptop Backpack 15.6 inch – Balo laptop thanh lịch, ngăn chứa tiện dụng và thiết kế di động</h2><p><strong>Lenovo Laptop Backpack 15.6 inch</strong> là phụ kiện dành cho người thường xuyên mang laptop, tài liệu và thiết bị cá nhân khi di chuyển. Thiết kế hướng đến sự gọn gàng, khả năng sắp xếp đồ dùng và phong cách phù hợp với môi trường học tập hoặc văn phòng.</p><h3>Những điểm nổi bật</h3><ul><li>Ngăn chứa laptop hỗ trợ kích thước đến 15,6 inch trên phiên bản tương ứng.</li><li>Thiết kế ngăn chứa phục vụ sắp xếp phụ kiện.</li><li>Quai đeo có thể điều chỉnh.</li><li>Phong cách tối giản, dễ phối hợp.</li><li>Chất liệu vải phù hợp cho nhu cầu mang theo hằng ngày.</li></ul><h3>Thiết kế thanh lịch cho học tập và công việc</h3><p>Balo mang phong cách đơn giản, hạn chế các chi tiết trang trí không cần thiết. Thiết kế phù hợp khi đến trường, văn phòng, thư viện hoặc các địa điểm làm việc khác.</p><p>Màu sắc, kích thước và vật liệu hoàn thiện có thể khác nhau giữa các mã balo Lenovo.</p><h3>Ngăn laptop 15,6 inch</h3><p>Khoang chứa laptop được bố trí riêng để người dùng dễ dàng cất và lấy máy. Lớp đệm trên những phiên bản được trang bị hỗ trợ hạn chế ma sát và va chạm nhẹ trong quá trình di chuyển.</p><p>Kích thước màn hình 15,6 inch không phản ánh đầy đủ kích thước thân máy. Người mua nên đối chiếu chiều dài, chiều rộng và độ dày laptop với kích thước khoang chứa thực tế.</p><h3>Sắp xếp tài liệu và phụ kiện</h3><p>Các ngăn chứa bổ sung hỗ trợ phân loại dây sạc, chuột, tai nghe, sổ tay và những vật dụng cá nhân. Việc phân chia thiết bị giúp hạn chế tình trạng các phụ kiện cứng tiếp xúc trực tiếp với bề mặt laptop.</p><h3>Chất liệu và khả năng bảo quản</h3><p>Chất liệu vải được lựa chọn để phù hợp với nhu cầu sử dụng hằng ngày. Một số phiên bản có bề mặt hỗ trợ hạn chế nước bắn nhẹ. Tuy nhiên, không nên xem balo là vật dụng chống nước hoàn toàn.</p><p>Khi di chuyển trong môi trường mưa, người dùng nên có phương thức bảo vệ bổ sung cho thiết bị điện tử.</p><h3>Quai đeo và khả năng điều chỉnh</h3><p>Quai đeo có thể điều chỉnh giúp người dùng lựa chọn vị trí balo phù hợp. Những phiên bản có lớp đệm ở quai và mặt lưng cung cấp bề mặt tiếp xúc thuận tiện hơn khi mang theo đồ dùng.</p><h3>Sử dụng trong nhiều tình huống</h3><p>Balo có thể sử dụng để mang laptop đến trường, tham gia cuộc họp hoặc làm việc tại quán cà phê. Các khoang chứa giúp tập hợp thiết bị và phụ kiện trong một vật dụng duy nhất.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Học sinh, sinh viên thường xuyên mang laptop.</li><li>Nhân viên văn phòng cần balo thiết kế đơn giản.</li><li>Người cần sắp xếp tài liệu và phụ kiện máy tính.</li><li>Người thường xuyên di chuyển giữa nhiều địa điểm.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Balo có chứa được mọi laptop 15,6 inch không?</h4><p>Không nhất thiết. Cần kiểm tra kích thước thân máy và khoang chứa thực tế.</p><h4>Balo có chống nước hoàn toàn không?</h4><p>Không nên mặc định như vậy. Khả năng hạn chế nước phụ thuộc vào vật liệu và phiên bản sản phẩm.</p><h4>Có thể mang thêm bộ sạc và chuột không?</h4><p>Các ngăn bổ sung hỗ trợ lưu trữ phụ kiện tùy theo dung tích thực tế.</p><h3>Có nên lựa chọn Lenovo Laptop Backpack 15.6 inch?</h3><p>Đây là lựa chọn thiết thực dành cho người cần balo laptop có phong cách thanh lịch, khả năng tổ chức đồ dùng và kích thước phù hợp với nhu cầu di chuyển hằng ngày.</p>', 'assets/images/products/lenovo-backpack-15.jpg'),
(13, 3, N'Lenovo Legion Gaming Backpack', N'<h2>Lenovo Legion Gaming Backpack – Balo gaming đa ngăn, không gian chứa rộng và thiết kế chắc chắn</h2><p><strong>Lenovo Legion Gaming Backpack</strong> được thiết kế hướng đến người sử dụng laptop gaming, thường xuyên mang theo bộ sạc lớn, chuột, tai nghe và nhiều phụ kiện khác. Sản phẩm kết hợp phong cách nhận diện Legion với hệ thống khoang chứa phục vụ nhu cầu di chuyển.</p><h3>Những điểm nổi bật</h3><ul><li>Thiết kế đặc trưng của dòng Lenovo Legion.</li><li>Khoang laptop kích thước lớn trên phiên bản tương ứng.</li><li>Nhiều ngăn chứa phụ kiện gaming.</li><li>Quai đeo và mặt lưng có lớp đệm trên phiên bản hỗ trợ.</li><li>Vật liệu phù hợp cho nhu cầu mang thiết bị hằng ngày.</li><li>Khả năng sắp xếp bộ sạc, chuột, tai nghe và tài liệu.</li></ul><h3>Thiết kế gaming với phong cách Legion</h3><p>Balo sử dụng các đường nét mạnh mẽ và chi tiết nhận diện đặc trưng của dòng Legion. Một số phiên bản có mặt trước cứng hoặc cấu trúc gia cố nhằm hỗ trợ duy trì hình dạng của balo.</p><p>Phong cách thiết kế phù hợp với người muốn đồng bộ phụ kiện cùng laptop và thiết bị gaming Lenovo.</p><h3>Khoang chứa laptop gaming kích thước lớn</h3><p>Khoang laptop được thiết kế để chứa những thiết bị có thân máy lớn hơn laptop văn phòng thông thường. Một số phiên bản Legion Gaming Backpack hỗ trợ laptop đến khoảng 17 inch hoặc 17,3 inch.</p><p>Kích thước hỗ trợ chính xác phụ thuộc vào mã balo. Người dùng cần đối chiếu chiều dài, chiều rộng và độ dày thực tế của laptop gaming trước khi mua.</p><h3>Lớp đệm hỗ trợ bảo vệ thiết bị</h3><p>Khoang chứa có lớp đệm trên những phiên bản tương ứng giúp hạn chế ma sát và ảnh hưởng của va chạm nhẹ trong quá trình mang theo. Việc bố trí laptop riêng biệt cũng giúp giảm tiếp xúc trực tiếp với bộ sạc và các phụ kiện cứng.</p><p>Balo không thể bảo đảm bảo vệ thiết bị khỏi mọi tình huống rơi hoặc va đập mạnh. Người dùng vẫn cần cẩn thận khi đặt và vận chuyển balo.</p><h3>Hệ thống ngăn chứa phụ kiện gaming</h3><p>Các ngăn bổ sung hỗ trợ sắp xếp chuột, tai nghe, dây cáp, bộ sạc và những vật dụng cá nhân. Những phiên bản có khoang chứa lớn có thể phù hợp với nhiều phụ kiện hơn tùy kích thước thực tế.</p><h3>Chất liệu và khả năng sử dụng lâu dài</h3><p>Vật liệu vải và các khu vực gia cố được thiết kế phục vụ nhu cầu mang theo thiết bị thường xuyên. Một số phiên bản có bề mặt hỗ trợ hạn chế nước bắn và bụi bẩn.</p><p>Khả năng chống nước không đồng nghĩa với chống thấm hoàn toàn. Nên sử dụng biện pháp bảo vệ bổ sung khi mang thiết bị điện tử trong môi trường mưa.</p><h3>Quai đeo và mặt lưng</h3><p>Quai đeo có thể điều chỉnh cùng lớp đệm trên những phiên bản tương ứng giúp phân bố đồ dùng thuận tiện hơn khi mang theo. Mặt lưng có thiết kế đệm hoặc thông thoáng tùy mã sản phẩm.</p><p>Người dùng nên sắp xếp thiết bị hợp lý và cân nhắc tổng trọng lượng đồ dùng để phù hợp với quãng đường di chuyển.</p><h3>Phù hợp cho học tập, công việc và giải trí</h3><p>Legion Gaming Backpack không chỉ dành cho người chơi game. Balo còn phù hợp với sinh viên kỹ thuật, người làm thiết kế và người sử dụng laptop hiệu năng cao cần mang theo nhiều phụ kiện.</p><h3>Đối tượng sử dụng phù hợp</h3><ul><li>Người sử dụng Lenovo Legion hoặc laptop gaming tương thích.</li><li>Sinh viên thường xuyên mang laptop và tài liệu.</li><li>Người cần khoang chứa bộ sạc lớn và phụ kiện.</li><li>Người thường xuyên di chuyển với thiết bị máy tính.</li><li>Người yêu thích phong cách thiết kế gaming.</li></ul><h3>Câu hỏi thường gặp</h3><h4>Balo có chứa được laptop gaming 17 inch không?</h4><p>Một số phiên bản hỗ trợ kích thước này. Cần xác nhận kích thước khoang chứa của sản phẩm cụ thể.</p><h4>Có thể mang bàn phím rời không?</h4><p>Điều này phụ thuộc vào chiều dài bàn phím và dung tích khoang chứa thực tế.</p><h4>Balo có chống sốc hoàn toàn không?</h4><p>Không. Lớp đệm chỉ hỗ trợ hạn chế ảnh hưởng của những va chạm trong phạm vi nhất định.</p><h4>Có phù hợp sử dụng đi học không?</h4><p>Có, nếu kích thước và trọng lượng balo phù hợp với nhu cầu mang theo laptop, tài liệu và phụ kiện của người sử dụng.</p><h3>Có nên lựa chọn Lenovo Legion Gaming Backpack?</h3><p>Đây là lựa chọn đáng cân nhắc dành cho người cần balo chứa laptop gaming và nhiều phụ kiện. Thiết kế đa ngăn, phong cách Legion và khoang chứa rộng giúp việc tổ chức thiết bị khi di chuyển trở nên thuận tiện hơn.</p>', 'assets/images/products/lenovo-legion-backpack.jpg');
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

    (N'Đồng hồ thông minh', N'Apple', N'Apple Watch SE 2', N'<h2>Apple Watch SE 2 – Đồng hồ thông minh hiện đại, theo dõi hoạt động hằng ngày và kết nối liền mạch với iPhone</h2><p><strong>Apple Watch SE 2</strong> là mẫu đồng hồ thông minh được Apple phát triển nhằm mang đến những tính năng thiết yếu của dòng Apple Watch với mức chi phí dễ tiếp cận hơn. Sản phẩm kết hợp thiết kế khung nhôm nhẹ nhàng, màn hình Retina sắc nét, bộ xử lý S8 SiP và hệ điều hành watchOS, tạo nên một thiết bị đeo tay linh hoạt phục vụ công việc, liên lạc và theo dõi hoạt động thường ngày.</p><p>Không chỉ đóng vai trò như một chiếc đồng hồ xem giờ, Apple Watch SE 2 còn hỗ trợ người dùng quản lý thông báo, theo dõi giấc ngủ, ghi nhận hoạt động thể chất và sử dụng nhiều tiện ích ngay trên cổ tay. Đây là lựa chọn đáng cân nhắc cho người lần đầu trải nghiệm smartwatch hoặc đang sử dụng hệ sinh thái Apple.</p><h3>Những điểm nổi bật của Apple Watch SE 2</h3><ul><li><strong>Khung nhôm:</strong> Thiết kế nhẹ, hiện đại và phù hợp với nhu cầu đeo hằng ngày.</li><li><strong>Hai kích thước mặt đồng hồ:</strong> Phiên bản 40 mm và 44 mm đáp ứng những sở thích sử dụng khác nhau.</li><li><strong>Màn hình Retina LTPO OLED:</strong> Hiển thị nội dung rõ ràng với độ sáng tối đa được công bố lên đến 1.000 nit.</li><li><strong>Chip S8 SiP:</strong> Hỗ trợ vận hành ứng dụng và các tiện ích của watchOS.</li><li><strong>Theo dõi nhịp tim:</strong> Ghi nhận thông tin nhịp tim bằng cảm biến quang học.</li><li><strong>Theo dõi giấc ngủ:</strong> Cung cấp thông tin tham khảo về thời gian và các giai đoạn ngủ.</li><li><strong>Phát hiện té ngã và va chạm:</strong> Hỗ trợ các tính năng an toàn trong điều kiện tương thích.</li><li><strong>Khả năng kháng nước 50 mét:</strong> Phù hợp với một số hoạt động dưới nước theo hướng dẫn của Apple.</li><li><strong>Thời lượng pin:</strong> Lên đến 18 giờ trong điều kiện thử nghiệm tiêu chuẩn.</li></ul><h3>Thiết kế khung nhôm – Hiện đại và thuận tiện khi sử dụng</h3><p>Apple Watch SE 2 duy trì kiểu dáng mặt vuông bo cong đặc trưng của Apple Watch. Khung nhôm kết hợp mặt kính phía trước mang đến tổng thể tối giản, phù hợp khi sử dụng trong môi trường học tập, văn phòng hoặc các hoạt động thường ngày.</p><p>Sản phẩm có hai lựa chọn kích thước 40 mm và 44 mm. Người dùng có thể lựa chọn dựa trên không gian hiển thị mong muốn, cảm giác đeo và khả năng tương thích với dây đeo. Hệ thống dây đeo có thể thay thế giúp đồng hồ dễ dàng thích nghi với nhiều phong cách sử dụng.</p><h3>Màn hình Retina OLED – Quan sát thông tin thuận tiện</h3><p>Màn hình Retina LTPO OLED cung cấp độ tương phản cao, giúp các biểu tượng, thông báo và nội dung được hiển thị rõ ràng. Độ sáng tối đa lên đến 1.000 nit trong điều kiện phù hợp hỗ trợ khả năng quan sát khi sử dụng ngoài trời.</p><p>Người dùng có thể tùy chỉnh mặt đồng hồ, lựa chọn màu sắc và bổ sung các tiện ích như lịch, thời tiết hoặc thông tin hoạt động. Apple Watch SE 2 không hỗ trợ Always-On Display, vì vậy màn hình thường được kích hoạt khi người dùng nâng cổ tay hoặc tương tác với thiết bị.</p><h3>Chip S8 SiP – Hiệu năng cho các tiện ích thông minh</h3><p>Bộ xử lý S8 SiP cung cấp nền tảng vận hành cho watchOS và các ứng dụng tương thích. Người dùng có thể chuyển đổi giữa các tiện ích, xem thông báo, sử dụng bộ hẹn giờ, quản lý lịch và tương tác với những chức năng được hỗ trợ.</p><p>Digital Crown kết hợp màn hình cảm ứng mang đến nhiều phương thức điều hướng, giúp thao tác thuận tiện ngay cả khi thiết bị có kích thước màn hình nhỏ hơn điện thoại.</p><h3>Theo dõi nhịp tim và thông tin sức khỏe</h3><p>Cảm biến nhịp tim quang học hỗ trợ ghi nhận nhịp tim trong những điều kiện sử dụng phù hợp. Đồng hồ có thể cung cấp thông báo liên quan đến nhịp tim theo thiết lập và khả năng hỗ trợ của phần mềm.</p><p>Các thông tin được ghi nhận có thể đồng bộ với ứng dụng Sức khỏe trên iPhone tương thích. Người dùng có thể quan sát xu hướng theo thời gian, tuy nhiên dữ liệu từ đồng hồ chỉ mang tính tham khảo và không thay thế việc thăm khám hoặc chẩn đoán y tế.</p><h3>Theo dõi giấc ngủ và quản lý lịch sinh hoạt</h3><p>Tính năng theo dõi giấc ngủ hỗ trợ ghi nhận thời gian ngủ và các giai đoạn ngủ được thiết bị ước tính. Người dùng có thể kết hợp đồng hồ với lịch ngủ, chế độ tập trung và những tiện ích nhắc nhở để duy trì thói quen sinh hoạt phù hợp.</p><p>Khả năng ghi nhận dữ liệu phụ thuộc vào cách đeo đồng hồ, thời lượng sử dụng, phiên bản phần mềm và điều kiện thực tế.</p><h3>Ghi nhận hoạt động thể chất và các môn thể thao</h3><p>Ứng dụng Workout hỗ trợ ghi nhận nhiều hoạt động như đi bộ, đạp xe, chạy bộ và bơi lội trong điều kiện phù hợp. Đồng hồ có thể hiển thị thời gian hoạt động, quãng đường và những thông tin liên quan đến buổi vận động.</p><p>Các vòng hoạt động trên watchOS cung cấp cách trình bày trực quan về chuyển động trong ngày. Người dùng có thể điều chỉnh mục tiêu phù hợp với lịch sinh hoạt, khả năng cá nhân và nhu cầu nghỉ ngơi.</p><h3>Phát hiện té ngã, phát hiện va chạm và Emergency SOS</h3><p>Apple Watch SE 2 được trang bị các tính năng an toàn như Fall Detection, Crash Detection và Emergency SOS. Trong những tình huống được hệ thống nhận diện, thiết bị có thể hỗ trợ liên hệ dịch vụ khẩn cấp hoặc người liên hệ khẩn cấp nếu các điều kiện cần thiết được đáp ứng.</p><p>Khả năng hoạt động phụ thuộc vào kết nối mạng, vị trí, thiết lập và phiên bản thiết bị. Những tính năng này không bảo đảm phát hiện được mọi tình huống khẩn cấp.</p><h3>Thông báo, cuộc gọi và kết nối với iPhone</h3><p>Apple Watch SE 2 cho phép người dùng xem thông báo tin nhắn, cuộc gọi, lịch làm việc và các ứng dụng tương thích ngay trên cổ tay. Đây là tiện ích hữu ích khi người dùng không muốn liên tục lấy điện thoại ra để kiểm tra thông tin.</p><p>Phiên bản GPS và phiên bản GPS + Cellular có những khác biệt về khả năng kết nối độc lập. Phiên bản Cellular cần nhà mạng, gói dịch vụ và điều kiện hỗ trợ tương thích để sử dụng các chức năng mạng di động.</p><h3>Khả năng kháng nước 50 mét</h3><p>Apple Watch SE 2 được đánh giá khả năng kháng nước ở mức 50 mét theo tiêu chuẩn ISO 22810:2010. Thiết bị phù hợp với một số hoạt động ở vùng nước nông theo hướng dẫn của Apple, nhưng không được thiết kế cho lặn sâu hoặc các hoạt động dưới nước có áp lực cao.</p><p>Khả năng kháng nước có thể giảm theo thời gian sử dụng. Người dùng nên bảo quản và vệ sinh thiết bị theo hướng dẫn của nhà sản xuất.</p><h3>Thời lượng pin và phương thức sạc</h3><p>Apple công bố thời lượng pin lên đến 18 giờ trong điều kiện thử nghiệm tiêu chuẩn. Thời gian thực tế phụ thuộc vào số lượng thông báo, hoạt động GPS, kết nối mạng, độ sáng màn hình và tình trạng pin.</p><p>Đồng hồ sử dụng hệ thống sạc từ tính tương thích. Người dùng có thể bố trí thời gian sạc phù hợp để duy trì hoạt động của thiết bị và đáp ứng nhu cầu theo dõi giấc ngủ.</p><h3>Apple Watch SE 2 phù hợp với những ai?</h3><ul><li><strong>Người sử dụng iPhone:</strong> Muốn mở rộng trải nghiệm trong hệ sinh thái Apple.</li><li><strong>Người lần đầu sử dụng smartwatch:</strong> Cần những tính năng thông minh thiết yếu.</li><li><strong>Người thường xuyên làm việc:</strong> Muốn theo dõi thông báo và lịch trình thuận tiện.</li><li><strong>Người yêu thích hoạt động ngoài trời:</strong> Cần thiết bị ghi nhận thông tin vận động.</li><li><strong>Người quan tâm đến giấc ngủ:</strong> Muốn quan sát thói quen sinh hoạt thông qua dữ liệu tham khảo.</li></ul><h3>Câu hỏi thường gặp về Apple Watch SE 2</h3><h4>Apple Watch SE 2 có sử dụng được với Android không?</h4><p>Không. Thiết bị được thiết kế để thiết lập và sử dụng với iPhone tương thích.</p><h4>Apple Watch SE 2 có màn hình luôn bật không?</h4><p>Không. Sản phẩm không được trang bị tính năng Always-On Display.</p><h4>Đồng hồ có hỗ trợ điện tâm đồ ECG không?</h4><p>Không. Apple Watch SE 2 không được trang bị cảm biến điện tim cần thiết cho tính năng ECG.</p><h4>Có thể thay dây đeo Apple Watch SE 2 không?</h4><p>Có. Người dùng có thể lựa chọn những dây đeo có kích thước và cơ chế kết nối tương thích.</p><h4>Thời lượng pin có luôn đạt 18 giờ không?</h4><p>Không. Đây là kết quả thử nghiệm của Apple, thời lượng thực tế phụ thuộc vào cách sử dụng và tình trạng thiết bị.</p><h3>Có nên lựa chọn Apple Watch SE 2?</h3><p>Apple Watch SE 2 là lựa chọn phù hợp cho người cần một chiếc đồng hồ thông minh có thiết kế hiện đại, khả năng kết nối tốt với iPhone và những tính năng theo dõi hoạt động thiết yếu. Trước khi đặt hàng, người mua nên kiểm tra kích thước mặt đồng hồ, phiên bản GPS hoặc Cellular và khả năng tương thích với iPhone đang sử dụng.</p>'),

    (N'Đồng hồ thông minh', N'Samsung', N'Samsung Galaxy Watch7', N'<h2>Samsung Galaxy Watch7 – Thiết kế mặt tròn tinh tế, bộ xử lý 3 nm và hệ thống cảm biến BioActive cải tiến</h2><p><strong>Samsung Galaxy Watch7</strong> là dòng đồng hồ thông minh kết hợp thiết kế truyền thống với những công nghệ xử lý, kết nối và theo dõi hoạt động hiện đại. Sản phẩm được trang bị màn hình Super AMOLED, bộ xử lý Exynos W1000 và hệ thống cảm biến BioActive cải tiến nhằm cung cấp trải nghiệm sử dụng linh hoạt trong nhiều tình huống.</p><p>Galaxy Watch7 hướng đến người dùng Android, đặc biệt là những người đang sử dụng smartphone Samsung Galaxy. Đồng hồ hỗ trợ quản lý thông báo, ghi nhận hoạt động thể chất, theo dõi giấc ngủ và truy cập nhiều ứng dụng tương thích ngay trên cổ tay.</p><h3>Những điểm nổi bật của Samsung Galaxy Watch7</h3><ul><li><strong>Thiết kế mặt tròn:</strong> Phong cách hiện đại kết hợp khung Armor Aluminum.</li><li><strong>Hai kích thước:</strong> Phiên bản 40 mm và 44 mm.</li><li><strong>Màn hình Super AMOLED:</strong> Hiển thị màu sắc sống động và độ tương phản cao.</li><li><strong>Kính Sapphire:</strong> Hỗ trợ tăng khả năng chống trầy xước bề mặt.</li><li><strong>Exynos W1000:</strong> Bộ xử lý được sản xuất trên tiến trình 3 nm.</li><li><strong>Cảm biến BioActive:</strong> Hỗ trợ ghi nhận nhiều thông tin liên quan đến hoạt động và sức khỏe.</li><li><strong>GPS tần số kép:</strong> Sử dụng tín hiệu L1 và L5 để hỗ trợ định vị.</li><li><strong>Wear OS:</strong> Hỗ trợ nhiều ứng dụng và tiện ích thông minh.</li><li><strong>Khả năng kháng nước và bụi:</strong> Được đánh giá theo chuẩn 5 ATM và IP68.</li></ul><h3>Thiết kế mặt tròn – Kết hợp phong cách cổ điển và công nghệ hiện đại</h3><p>Galaxy Watch7 sử dụng thiết kế mặt tròn với hai nút điều khiển bố trí ở cạnh bên. Khung Armor Aluminum mang đến phong cách hoàn thiện hiện đại, phù hợp với nhiều môi trường sử dụng từ công việc đến sinh hoạt thường ngày.</p><p>Hai lựa chọn kích thước 40 mm và 44 mm giúp người dùng cân nhắc giữa tính gọn nhẹ và không gian hiển thị. Dây đeo có thể thay thế bằng những phụ kiện tương thích, cho phép thay đổi phong cách theo sở thích cá nhân.</p><h3>Màn hình Super AMOLED và kính Sapphire</h3><p>Màn hình Super AMOLED mang đến độ tương phản cao, màu đen sâu và khả năng hiển thị rõ ràng các biểu tượng giao diện. Người dùng có thể theo dõi thông báo, thông tin hoạt động và những tiện ích trên mặt đồng hồ.</p><p>Kính Sapphire hỗ trợ hạn chế trầy xước trong quá trình sử dụng thông thường. Tính năng Always-On Display cho phép duy trì thông tin mặt đồng hồ trong trạng thái chờ, tuy nhiên có thể làm tăng mức tiêu thụ năng lượng.</p><h3>Exynos W1000 – Nền tảng xử lý trên tiến trình 3 nm</h3><p>Galaxy Watch7 được trang bị bộ xử lý Exynos W1000 sản xuất trên tiến trình 3 nm. Bộ xử lý được thiết kế để hỗ trợ vận hành giao diện, mở ứng dụng, xử lý dữ liệu cảm biến và duy trì những chức năng kết nối của đồng hồ.</p><p>Khả năng phản hồi của hệ thống tạo thuận lợi khi chuyển đổi giữa các ứng dụng, kiểm tra thông báo hoặc truy cập những tiện ích thường xuyên sử dụng.</p><h3>Hệ thống cảm biến BioActive cải tiến</h3><p>Cảm biến BioActive hỗ trợ ghi nhận thông tin nhịp tim và những dữ liệu sinh học được thiết bị hỗ trợ. Samsung Health cung cấp giao diện tổng hợp để người dùng quan sát các thông tin theo thời gian.</p><p>Những chỉ số do đồng hồ ghi nhận chịu ảnh hưởng bởi cách đeo, chuyển động và điều kiện môi trường. Sản phẩm không thay thế thiết bị y tế chuyên dụng và không nên được sử dụng để tự chẩn đoán bệnh.</p><h3>Theo dõi giấc ngủ và các tiện ích Galaxy AI</h3><p>Galaxy Watch7 hỗ trợ ghi nhận thời gian ngủ, các giai đoạn ngủ được ước tính và một số thông tin liên quan đến thói quen nghỉ ngơi. Những công cụ phân tích trên Samsung Health giúp trình bày dữ liệu theo cách trực quan hơn.</p><p>Energy Score trên các thiết bị và phần mềm tương thích sử dụng nhiều nguồn dữ liệu để cung cấp thông tin tham khảo về trạng thái hoạt động trong ngày. Người dùng nên xem đây là công cụ hỗ trợ quan sát xu hướng thay vì đánh giá y tế hoặc yêu cầu phải đạt một mức điểm nhất định.</p><h3>GPS tần số kép – Hỗ trợ ghi nhận vị trí</h3><p>Galaxy Watch7 hỗ trợ GPS tần số kép L1 và L5 nhằm cải thiện khả năng tiếp nhận tín hiệu định vị trong những môi trường phù hợp. Tính năng này hữu ích khi ghi lại tuyến đường đi bộ, chạy bộ hoặc đạp xe ngoài trời.</p><p>Độ chính xác thực tế phụ thuộc vào tín hiệu vệ tinh, công trình xung quanh, thời tiết và vị trí sử dụng. Người dùng có thể xem lại dữ liệu tuyến đường thông qua các ứng dụng tương thích.</p><h3>Ghi nhận hoạt động thể thao đa dạng</h3><p>Đồng hồ hỗ trợ nhiều chế độ vận động, giúp người dùng ghi nhận thời gian hoạt động, quãng đường và những chỉ số liên quan. Các chế độ có thể được lựa chọn theo loại hoạt động đang thực hiện.</p><p>Khả năng đồng bộ với Samsung Health giúp quản lý lịch sử vận động ở một nơi. Người dùng có thể theo dõi sự thay đổi theo thời gian và lựa chọn hoạt động phù hợp với nhu cầu cá nhân.</p><h3>Wear OS và hệ sinh thái ứng dụng</h3><p>Galaxy Watch7 sử dụng nền tảng Wear OS với giao diện của Samsung, cung cấp khả năng truy cập các ứng dụng tương thích dành cho đồng hồ thông minh. Người dùng có thể sử dụng bản đồ, bộ hẹn giờ, trình phát nhạc và những tiện ích hỗ trợ công việc.</p><p>Khả năng sử dụng từng ứng dụng phụ thuộc vào phiên bản phần mềm, tài khoản, khu vực và thiết bị điện thoại được ghép nối.</p><h3>Quản lý thông báo và cuộc gọi</h3><p>Đồng hồ cho phép xem thông báo từ điện thoại, theo dõi lịch trình và tương tác với những chức năng liên lạc được hỗ trợ. Người dùng có thể điều chỉnh ứng dụng được phép gửi thông báo để tránh bị gián đoạn không cần thiết.</p><p>Phiên bản Bluetooth và LTE có khả năng kết nối khác nhau. Những tính năng mạng di động trên phiên bản LTE yêu cầu nhà mạng và dịch vụ tương thích.</p><h3>Khả năng kháng nước và bụi</h3><p>Galaxy Watch7 được đánh giá đạt chuẩn 5 ATM và IP68 trong điều kiện thử nghiệm. Thiết bị hỗ trợ một số hoạt động tiếp xúc với nước theo hướng dẫn của Samsung, nhưng không được thiết kế để chịu mọi điều kiện áp lực nước.</p><p>Khả năng bảo vệ có thể suy giảm theo thời gian và tình trạng thiết bị. Người dùng nên tuân thủ hướng dẫn bảo quản của nhà sản xuất.</p><h3>Thời lượng pin và sạc không dây</h3><p>Galaxy Watch7 sử dụng pin sạc tích hợp, với dung lượng khác nhau giữa phiên bản 40 mm và 44 mm. Thời lượng sử dụng phụ thuộc vào độ sáng màn hình, Always-On Display, GPS, kết nối mạng và tần suất sử dụng ứng dụng.</p><p>Đồng hồ hỗ trợ sạc không dây bằng phụ kiện tương thích. Không phải mọi bộ sạc không dây dành cho điện thoại đều có thể sử dụng với Galaxy Watch7.</p><h3>Galaxy Watch7 phù hợp với những ai?</h3><ul><li>Người đang sử dụng smartphone Samsung Galaxy.</li><li>Người muốn quản lý thông báo và lịch làm việc trên cổ tay.</li><li>Người quan tâm đến dữ liệu giấc ngủ và hoạt động thường ngày.</li><li>Người yêu thích đồng hồ có thiết kế mặt tròn.</li><li>Người cần smartwatch có GPS và nhiều ứng dụng tương thích.</li></ul><h3>Câu hỏi thường gặp về Samsung Galaxy Watch7</h3><h4>Galaxy Watch7 có sử dụng được với iPhone không?</h4><p>Không. Sản phẩm được thiết kế để sử dụng với điện thoại Android tương thích.</p><h4>Galaxy Watch7 sử dụng chip gì?</h4><p>Thiết bị sử dụng Exynos W1000 trên tiến trình 3 nm.</p><h4>Đồng hồ có hỗ trợ Always-On Display không?</h4><p>Có. Người dùng có thể bật hoặc tắt tính năng này theo nhu cầu.</p><h4>GPS kép có bảo đảm định vị chính xác tuyệt đối không?</h4><p>Không. Chất lượng định vị vẫn phụ thuộc vào môi trường và điều kiện tiếp nhận tín hiệu.</p><h4>Mọi tính năng sức khỏe có hoạt động trên tất cả điện thoại Android không?</h4><p>Không nhất thiết. Một số tính năng yêu cầu điện thoại Samsung Galaxy, phần mềm và khu vực được hỗ trợ.</p><h3>Có nên lựa chọn Samsung Galaxy Watch7?</h3><p>Galaxy Watch7 là lựa chọn đáng cân nhắc cho người dùng Android muốn kết hợp đồng hồ thời trang với những tiện ích thông minh, khả năng ghi nhận hoạt động và hệ thống kết nối Galaxy. Người mua nên kiểm tra kích thước, phiên bản kết nối và khả năng tương thích với điện thoại trước khi đặt hàng.</p>'),

    (N'Đồng hồ thông minh', N'Garmin', N'Garmin Forerunner 165', N'<h2>Garmin Forerunner 165 – Đồng hồ GPS chuyên dụng cho chạy bộ, màn hình AMOLED và thời lượng pin dài</h2><p><strong>Garmin Forerunner 165</strong> là mẫu đồng hồ thể thao hướng đến người yêu thích chạy bộ, đi bộ và các hoạt động ngoài trời. Sản phẩm kết hợp hệ thống định vị vệ tinh, cảm biến nhịp tim quang học, màn hình AMOLED và nền tảng phân tích hoạt động Garmin Connect để cung cấp thông tin trực quan trong quá trình sử dụng.</p><p>So với những mẫu smartwatch tập trung chủ yếu vào thông báo và ứng dụng, Forerunner 165 chú trọng khả năng ghi nhận dữ liệu thể thao, quản lý hoạt động và cung cấp thời lượng pin phù hợp cho nhu cầu sử dụng nhiều ngày.</p><h3>Những điểm nổi bật của Garmin Forerunner 165</h3><ul><li><strong>Màn hình AMOLED 1,2 inch:</strong> Hiển thị màu sắc rõ ràng và giao diện trực quan.</li><li><strong>Thiết kế nhẹ:</strong> Thuận tiện khi đeo trong các hoạt động thường ngày.</li><li><strong>GPS tích hợp:</strong> Hỗ trợ ghi nhận tuyến đường, quãng đường và tốc độ.</li><li><strong>Cảm biến nhịp tim quang học:</strong> Ghi nhận thông tin nhịp tim trên cổ tay.</li><li><strong>Garmin Coach:</strong> Cung cấp các chương trình hướng dẫn tập luyện tương thích.</li><li><strong>Morning Report:</strong> Tổng hợp thông tin tham khảo vào buổi sáng.</li><li><strong>Body Battery:</strong> Ước tính mức năng lượng dựa trên dữ liệu thiết bị ghi nhận.</li><li><strong>Hơn 25 hồ sơ hoạt động:</strong> Hỗ trợ nhiều môn thể thao trong nhà và ngoài trời.</li><li><strong>Thời lượng pin:</strong> Lên đến 11 ngày ở chế độ smartwatch trong điều kiện phù hợp.</li><li><strong>Khả năng kháng nước 5 ATM:</strong> Phù hợp với các hoạt động được Garmin hướng dẫn.</li></ul><h3>Thiết kế nhỏ gọn và thuận tiện khi vận động</h3><p>Forerunner 165 sử dụng thiết kế mặt tròn, phần thân nhẹ và dây đeo phù hợp cho nhu cầu sử dụng thể thao. Các nút điều khiển vật lý được bố trí quanh thân đồng hồ để người dùng có thể thao tác trong những tình huống không thuận tiện sử dụng màn hình cảm ứng.</p><p>Thiết kế phù hợp cho việc mang theo hằng ngày, từ môi trường làm việc đến những hoạt động ngoài trời. Dây đeo tương thích có thể được thay thế theo sở thích cá nhân.</p><h3>Màn hình AMOLED 1,2 inch – Hiển thị dữ liệu trực quan</h3><p>Màn hình AMOLED cung cấp độ tương phản cao, màu sắc sống động và khả năng hiển thị rõ ràng các trường dữ liệu. Người dùng có thể lựa chọn mặt đồng hồ và tùy chỉnh những thông tin muốn quan sát.</p><p>Khả năng điều khiển bằng màn hình cảm ứng kết hợp nút vật lý giúp người dùng linh hoạt hơn khi duyệt menu, xem thông báo hoặc chuyển đổi giữa các màn hình hoạt động.</p><h3>GPS tích hợp – Ghi nhận tuyến đường và quãng đường</h3><p>Hệ thống định vị vệ tinh hỗ trợ ghi lại tuyến đường trong những hoạt động ngoài trời mà không cần liên tục sử dụng GPS của điện thoại. Đồng hồ có thể hiển thị quãng đường, tốc độ và thời gian hoạt động theo chế độ đang sử dụng.</p><p>Sau khi đồng bộ với Garmin Connect, người dùng có thể xem lại thông tin tuyến đường và lịch sử hoạt động. Chất lượng định vị phụ thuộc vào môi trường, tín hiệu vệ tinh và cấu hình được lựa chọn.</p><h3>Thông tin tốc độ, Pace và dữ liệu chạy bộ</h3><p>Forerunner 165 cung cấp những trường dữ liệu chuyên dụng như tốc độ, Pace, quãng đường và nhịp tim. Các thông tin có thể được bố trí trên những màn hình khác nhau để thuận tiện quan sát.</p><p>Người dùng có thể xem lại lịch sử hoạt động để hiểu rõ hơn về thói quen vận động. Các chỉ số không phải mục tiêu bắt buộc và cần được xem xét cùng cảm nhận thực tế, thời gian nghỉ ngơi và điều kiện cá nhân.</p><h3>Garmin Coach và các gợi ý hoạt động</h3><p>Garmin Coach cung cấp những chương trình hướng dẫn chạy bộ trên nền tảng tương thích. Đồng hồ cũng hỗ trợ hiển thị các gợi ý hoạt động dựa trên dữ liệu được hệ thống sử dụng.</p><p>Người dùng có thể lựa chọn sử dụng hoặc bỏ qua các gợi ý tùy theo lịch sinh hoạt. Những đề xuất từ phần mềm không thay thế hướng dẫn cá nhân của chuyên gia và không cần được thực hiện khi cơ thể cần nghỉ ngơi.</p><h3>Cảm biến nhịp tim và thông tin phục hồi</h3><p>Cảm biến quang học trên cổ tay hỗ trợ ghi nhận nhịp tim trong quá trình sử dụng. Đồng hồ có thể trình bày dữ liệu nhịp tim cùng các thông tin hoạt động để người dùng quan sát sự thay đổi theo thời gian.</p><p>Các ước tính về thời gian phục hồi cung cấp thêm thông tin tham khảo sau hoạt động. Độ chính xác phụ thuộc vào dữ liệu đầu vào, cách đeo và điều kiện sử dụng. Những chỉ số này không phải kết luận y tế.</p><h3>Body Battery – Quan sát xu hướng năng lượng</h3><p>Body Battery sử dụng các dữ liệu liên quan đến giấc ngủ, hoạt động và mức độ căng thẳng được thiết bị ước tính để trình bày thông tin về trạng thái năng lượng.</p><p>Tính năng giúp người dùng quan sát xu hướng sinh hoạt một cách trực quan. Kết quả chỉ là giá trị ước tính và không phản ánh chính xác tuyệt đối tình trạng của cơ thể.</p><h3>Theo dõi giấc ngủ và Morning Report</h3><p>Forerunner 165 hỗ trợ ghi nhận thời gian ngủ cùng những thông tin liên quan đến giấc ngủ trong điều kiện phù hợp. Morning Report tổng hợp một số dữ liệu và tiện ích để người dùng có thể xem vào buổi sáng.</p><p>Các thông tin được trình bày có thể bao gồm thời tiết, lịch hoạt động và những chỉ số được phần mềm hỗ trợ. Người dùng có thể tùy chỉnh nội dung hiển thị theo nhu cầu.</p><h3>Nhiều chế độ thể thao trong nhà và ngoài trời</h3><p>Ngoài chạy bộ, đồng hồ còn hỗ trợ nhiều hồ sơ hoạt động như đi bộ, đạp xe và các hoạt động thể thao khác. Mỗi chế độ cung cấp những trường dữ liệu phù hợp với loại hoạt động tương ứng.</p><p>Việc lựa chọn đúng hồ sơ giúp tổ chức lịch sử hoạt động thuận tiện hơn trong ứng dụng Garmin Connect.</p><h3>Garmin Connect – Quản lý dữ liệu trên điện thoại</h3><p>Garmin Connect cung cấp giao diện tổng hợp dữ liệu từ đồng hồ, cho phép người dùng xem lịch sử hoạt động, thông tin giấc ngủ và những báo cáo tương thích. Ứng dụng hỗ trợ các thiết bị Android và iOS đáp ứng yêu cầu phần mềm.</p><p>Người dùng có thể quản lý thông báo, thiết lập đồng hồ và lựa chọn những nội dung muốn đồng bộ.</p><h3>Phiên bản tiêu chuẩn và phiên bản Music</h3><p>Garmin Forerunner 165 có phiên bản tiêu chuẩn và Forerunner 165 Music. Phiên bản Music bổ sung khả năng lưu trữ và phát nhạc trực tiếp đến tai nghe Bluetooth tương thích trong những điều kiện được hỗ trợ.</p><p>Người mua nên xác nhận đúng phiên bản nếu muốn nghe nhạc mà không cần mang điện thoại trong quá trình hoạt động ngoài trời.</p><h3>Thời lượng pin lên đến 11 ngày</h3><p>Garmin công bố thời lượng pin lên đến 11 ngày ở chế độ smartwatch. Khi sử dụng GPS liên tục hoặc các chức năng tiêu thụ nhiều năng lượng, thời lượng hoạt động sẽ thấp hơn.</p><p>Mức pin thực tế chịu ảnh hưởng bởi độ sáng màn hình, Always-On Display, thông báo, cảm biến, chế độ định vị và tình trạng pin.</p><h3>Garmin Forerunner 165 phù hợp với những ai?</h3><ul><li>Người yêu thích chạy bộ và đi bộ ngoài trời.</li><li>Người cần đồng hồ có GPS tích hợp.</li><li>Người muốn xem lại lịch sử hoạt động trên điện thoại.</li><li>Người ưu tiên thời lượng pin nhiều ngày.</li><li>Người thích đồng hồ thể thao có màn hình AMOLED.</li></ul><h3>Câu hỏi thường gặp về Garmin Forerunner 165</h3><h4>Forerunner 165 có cần điện thoại để ghi lại quãng đường không?</h4><p>Không nhất thiết. Đồng hồ có GPS tích hợp để ghi nhận vị trí trong các hoạt động tương thích.</p><h4>Mọi phiên bản đều có khả năng lưu nhạc không?</h4><p>Không. Khả năng lưu trữ và phát nhạc trực tiếp thuộc phiên bản Forerunner 165 Music.</p><h4>Có thể kết nối với iPhone không?</h4><p>Có, thông qua ứng dụng Garmin Connect trên thiết bị iOS tương thích.</p><h4>Đồng hồ có hỗ trợ màn hình cảm ứng không?</h4><p>Có. Sản phẩm kết hợp màn hình cảm ứng và các nút điều khiển vật lý.</p><h4>Thời lượng pin có luôn đạt 11 ngày không?</h4><p>Không. Đây là thời lượng tối đa được công bố trong chế độ smartwatch và điều kiện sử dụng phù hợp.</p><h3>Có nên lựa chọn Garmin Forerunner 165?</h3><p>Garmin Forerunner 165 phù hợp với người cần đồng hồ tập trung vào khả năng ghi nhận hoạt động ngoài trời, GPS, màn hình AMOLED và thời lượng pin dài. Trước khi mua, người dùng nên cân nhắc giữa phiên bản tiêu chuẩn và phiên bản Music để lựa chọn sản phẩm đáp ứng đúng nhu cầu.</p>'),

    (N'Tai nghe', N'Sony', N'Sony WH-1000XM5', N'<h2>Sony WH-1000XM5 – Tai nghe không dây cao cấp, chống ồn chủ động và âm thanh Hi-Res giàu chi tiết</h2><p><strong>Sony WH-1000XM5</strong> là mẫu tai nghe over-ear cao cấp được Sony phát triển nhằm mang đến trải nghiệm nghe nhạc, xem phim, làm việc và đàm thoại linh hoạt. Sản phẩm kết hợp hệ thống chống ồn chủ động, hai bộ xử lý âm thanh, tám micro và màng loa 30 mm được thiết kế riêng.</p><p>Với khả năng điều chỉnh âm thanh theo môi trường, kết nối đa điểm và thời lượng pin dài, WH-1000XM5 phù hợp cho người thường xuyên di chuyển, làm việc trong văn phòng hoặc muốn có một không gian nghe nhạc ít bị ảnh hưởng bởi tiếng ồn xung quanh.</p><h3>Những điểm nổi bật của Sony WH-1000XM5</h3><ul><li><strong>Thiết kế over-ear:</strong> Đệm tai bao quanh vành tai, hỗ trợ tạo độ kín khi sử dụng.</li><li><strong>Bộ xử lý QN1 và V1:</strong> Phối hợp xử lý âm thanh và chống ồn.</li><li><strong>Tám micro:</strong> Hỗ trợ thu nhận âm thanh môi trường và xử lý tiếng ồn.</li><li><strong>Màng loa 30 mm:</strong> Được thiết kế để tái hiện âm thanh chi tiết.</li><li><strong>LDAC:</strong> Hỗ trợ truyền âm thanh chất lượng cao trên thiết bị tương thích.</li><li><strong>DSEE Extreme:</strong> Hỗ trợ xử lý nguồn âm thanh nén.</li><li><strong>Speak-to-Chat:</strong> Tự động tạm dừng nội dung khi nhận diện người đeo đang nói.</li><li><strong>Multipoint:</strong> Kết nối đồng thời với hai thiết bị Bluetooth tương thích.</li><li><strong>Thời lượng pin:</strong> Lên đến 30 giờ khi bật chống ồn trong điều kiện thử nghiệm.</li><li><strong>Sạc nhanh:</strong> Có thể cung cấp khoảng 3 giờ nghe sau 3 phút sạc với bộ nguồn USB PD phù hợp.</li></ul><h3>Thiết kế over-ear – Tối giản và thuận tiện khi sử dụng</h3><p>Sony WH-1000XM5 sử dụng kiểu dáng hiện đại với phần quai đeo được thiết kế thanh mảnh. Đệm tai bao quanh vành tai giúp tạo không gian nghe riêng và hỗ trợ khả năng cách âm thụ động.</p><p>Sản phẩm có trọng lượng khoảng 250 g. Phần quai đeo có thể điều chỉnh để phù hợp với người sử dụng. Cảm giác đeo thực tế phụ thuộc vào kích thước đầu, nhiệt độ môi trường và thời gian sử dụng.</p><p>Khác với một số thế hệ trước, WH-1000XM5 không sử dụng thiết kế gập gọn vào bên trong. Người dùng có thể bảo quản tai nghe bằng hộp đựng tương thích khi mang theo.</p><h3>Chống ồn chủ động với bộ xử lý QN1 và V1</h3><p>Hệ thống chống ồn sử dụng nhiều micro để thu nhận tiếng ồn từ môi trường. Bộ xử lý QN1 và V1 phối hợp phân tích tín hiệu nhằm giảm những âm thanh không mong muốn trong phạm vi hoạt động của công nghệ ANC.</p><p>Tính năng đặc biệt hữu ích trong môi trường có tiếng ồn nền liên tục như điều hòa, quạt hoặc phương tiện giao thông công cộng. Hiệu quả thực tế phụ thuộc vào độ kín của đệm tai, đặc điểm tiếng ồn và cách đeo.</p><p>Chống ồn chủ động không loại bỏ hoàn toàn mọi âm thanh bên ngoài. Người dùng vẫn cần duy trì khả năng nhận biết môi trường trong những tình huống cần thiết.</p><h3>Màng loa 30 mm – Tái hiện âm thanh chi tiết</h3><p>Màng loa 30 mm được thiết kế với vật liệu và cấu trúc nhằm hỗ trợ khả năng tái hiện nhiều dải âm. Hệ thống xử lý phối hợp với màng loa để mang đến trải nghiệm nghe nhạc, giọng nói và nội dung đa phương tiện.</p><p>Người dùng có thể lựa chọn các thiết lập âm thanh theo sở thích thông qua ứng dụng Sony tương thích. Chất lượng cảm nhận phụ thuộc vào nguồn phát, bản thu, codec và mức âm lượng được sử dụng.</p><h3>Hi-Res Audio Wireless và codec LDAC</h3><p>LDAC cung cấp khả năng truyền dữ liệu âm thanh ở tốc độ cao hơn một số codec Bluetooth phổ biến trong điều kiện tương thích. Công nghệ này hướng đến người sử dụng nguồn nhạc chất lượng cao và thiết bị phát hỗ trợ LDAC.</p><p>Không phải mọi smartphone hoặc máy tính đều hỗ trợ codec này. Chất lượng kết nối thực tế có thể thay đổi theo môi trường và thiết lập ưu tiên độ ổn định hoặc chất lượng âm thanh.</p><h3>DSEE Extreme – Hỗ trợ xử lý nguồn âm thanh nén</h3><p>DSEE Extreme sử dụng công nghệ xử lý âm thanh nhằm cải thiện cách tái hiện một số thành phần tần số trong nguồn nhạc nén. Tính năng cung cấp thêm lựa chọn khi nghe những bản nhạc có chất lượng nguồn khác nhau.</p><p>Khả năng xử lý không thể bảo đảm khôi phục hoàn toàn mọi dữ liệu đã mất trong quá trình nén. Kết quả phụ thuộc vào nguồn âm thanh và nội dung đang phát.</p><h3>Ambient Sound – Chủ động theo dõi âm thanh môi trường</h3><p>Chế độ Ambient Sound cho phép người dùng nghe một phần âm thanh xung quanh mà không cần tháo tai nghe. Người dùng có thể điều chỉnh mức độ âm thanh môi trường bằng các thiết lập tương thích.</p><p>Tính năng hữu ích khi cần trao đổi ngắn với đồng nghiệp hoặc theo dõi thông báo tại những địa điểm công cộng.</p><h3>Adaptive Sound Control – Điều chỉnh theo tình huống</h3><p>Adaptive Sound Control hỗ trợ điều chỉnh chế độ nghe dựa trên những tình huống và thiết lập được nhận diện. Người dùng có thể quản lý các tùy chọn thông qua ứng dụng Sony Sound Connect tương thích.</p><p>Khả năng nhận diện và điều chỉnh phụ thuộc vào phiên bản phần mềm, quyền truy cập và các thiết lập đã được người dùng cho phép.</p><h3>Speak-to-Chat – Trò chuyện thuận tiện</h3><p>Khi tính năng Speak-to-Chat được kích hoạt, tai nghe có thể nhận diện người đeo đang nói và tự động tạm dừng nội dung phát. Điều này hỗ trợ những cuộc trao đổi ngắn mà không cần thao tác thủ công nhiều lần.</p><p>Người dùng có thể tắt tính năng nếu thường xuyên hát theo nhạc hoặc không muốn nội dung bị gián đoạn.</p><h3>Micro và chất lượng cuộc gọi</h3><p>Hệ thống micro kết hợp công nghệ xử lý giọng nói nhằm hỗ trợ đàm thoại trong các cuộc gọi và cuộc họp trực tuyến. Tai nghe có thể giảm ảnh hưởng của một số tiếng ồn nền lên tín hiệu giọng nói.</p><p>Chất lượng cuộc gọi thực tế phụ thuộc vào khoảng cách tới nguồn tiếng ồn, môi trường, thiết bị ghép nối và kết nối mạng.</p><h3>Kết nối Multipoint với hai thiết bị</h3><p>WH-1000XM5 hỗ trợ kết nối Bluetooth đa điểm với hai thiết bị tương thích. Người dùng có thể kết nối tai nghe với laptop để làm việc và smartphone để theo dõi cuộc gọi mà không cần liên tục thực hiện ghép nối lại.</p><p>Khả năng sử dụng đồng thời một số tính năng phụ thuộc vào firmware, codec và thiết bị phát.</p><h3>Điều khiển cảm ứng và ứng dụng Sony</h3><p>Bề mặt cảm ứng trên tai nghe hỗ trợ điều chỉnh âm lượng, chuyển bài hát và quản lý nội dung đang phát. Các nút vật lý bổ sung cho phép điều khiển nguồn và chế độ chống ồn.</p><p>Ứng dụng Sony Sound Connect cung cấp những tùy chọn như điều chỉnh EQ, cập nhật phần mềm và quản lý các chức năng tương thích.</p><h3>Thời lượng pin và khả năng sạc nhanh</h3><p>Sony công bố thời lượng nghe nhạc lên đến 30 giờ khi bật chống ồn chủ động và lên đến 40 giờ khi tắt chống ồn trong điều kiện thử nghiệm. Thời gian thực tế phụ thuộc vào codec, âm lượng, chế độ sử dụng và tình trạng pin.</p><p>Với nguồn USB Power Delivery tương thích, tai nghe có thể cung cấp khoảng 3 giờ nghe sau 3 phút sạc trong điều kiện được công bố. Cổng USB-C giúp sử dụng với nhiều phụ kiện sạc phù hợp.</p><h3>Sony WH-1000XM5 phù hợp với những ai?</h3><ul><li>Người thường xuyên làm việc trong môi trường có tiếng ồn nền.</li><li>Người yêu thích nghe nhạc bằng tai nghe over-ear.</li><li>Người thường xuyên di chuyển bằng phương tiện công cộng.</li><li>Người cần kết nối tai nghe với laptop và smartphone.</li><li>Người muốn tùy chỉnh âm thanh và chế độ chống ồn.</li></ul><h3>Câu hỏi thường gặp về Sony WH-1000XM5</h3><h4>Tai nghe có hỗ trợ kết nối có dây không?</h4><p>Có. Người dùng có thể sử dụng cáp âm thanh tương thích với cổng kết nối của tai nghe.</p><h4>WH-1000XM5 có sử dụng được với iPhone không?</h4><p>Có. Tai nghe hỗ trợ kết nối Bluetooth với iPhone, nhưng codec LDAC không được iPhone hỗ trợ trực tiếp.</p><h4>Có thể kết nối hai thiết bị cùng lúc không?</h4><p>Có. Sản phẩm hỗ trợ Multipoint với những thiết bị Bluetooth tương thích.</p><h4>Tai nghe có chống nước hoàn toàn không?</h4><p>Không. Người dùng nên tránh tiếp xúc với nước, mưa và môi trường có độ ẩm không phù hợp.</p><h4>Có thể tùy chỉnh âm bass và treble không?</h4><p>Có. Ứng dụng Sony tương thích cung cấp các tùy chọn EQ để điều chỉnh chất âm.</p><h3>Có nên lựa chọn Sony WH-1000XM5?</h3><p>Sony WH-1000XM5 là lựa chọn đáng cân nhắc cho người ưu tiên khả năng chống ồn chủ động, âm thanh có nhiều tùy chọn điều chỉnh, thời lượng pin dài và kết nối linh hoạt. Sản phẩm phù hợp cho công việc, giải trí và nhu cầu nghe nhạc trong nhiều môi trường khác nhau.</p>'),

    (N'Tai nghe', N'JBL', N'JBL Tune 770NC', N'<h2>JBL Tune 770NC – Tai nghe over-ear không dây, chống ồn thích ứng và thời lượng pin lên đến 70 giờ</h2><p><strong>JBL Tune 770NC</strong> là mẫu tai nghe không dây hướng đến người dùng cần sự kết hợp giữa chất âm đặc trưng JBL Pure Bass, khả năng chống ồn chủ động và thời lượng pin dài. Sản phẩm sử dụng thiết kế over-ear có thể gập gọn, phù hợp với nhu cầu nghe nhạc, học tập, làm việc và giải trí hằng ngày.</p><p>Với khả năng tùy chỉnh âm thanh thông qua ứng dụng JBL Headphones và kết nối nhiều thiết bị tương thích, Tune 770NC mang đến trải nghiệm linh hoạt cho người muốn sử dụng một chiếc tai nghe trong nhiều tình huống khác nhau.</p><h3>Những điểm nổi bật của JBL Tune 770NC</h3><ul><li><strong>JBL Pure Bass Sound:</strong> Chất âm hướng đến khả năng tái hiện dải trầm rõ ràng.</li><li><strong>Màng loa 40 mm:</strong> Phục vụ nhu cầu nghe nhạc và giải trí đa phương tiện.</li><li><strong>Adaptive Noise Cancelling:</strong> Hỗ trợ giảm tiếng ồn môi trường.</li><li><strong>Smart Ambient:</strong> Cung cấp các chế độ nghe âm thanh xung quanh.</li><li><strong>Bluetooth 5.3:</strong> Kết nối với nhiều thiết bị tương thích.</li><li><strong>Multipoint:</strong> Hỗ trợ kết nối đa điểm.</li><li><strong>JBL Headphones:</strong> Tùy chỉnh EQ và các chức năng được hỗ trợ.</li><li><strong>Pin lên đến 70 giờ:</strong> Áp dụng trong điều kiện thử nghiệm khi tắt ANC.</li><li><strong>Thiết kế gập gọn:</strong> Thuận tiện khi mang theo và bảo quản.</li></ul><h3>Thiết kế over-ear – Phù hợp nhiều môi trường sử dụng</h3><p>JBL Tune 770NC sử dụng đệm tai bao quanh vành tai, kết hợp phần quai đeo có thể điều chỉnh. Kiểu dáng này hỗ trợ tạo độ kín cần thiết cho khả năng cách âm và trải nghiệm nghe nhạc.</p><p>Cấu trúc gập gọn giúp giảm không gian chiếm dụng khi không sử dụng. Người dùng có thể mang tai nghe trong balo hoặc túi phụ kiện khi đi học, đi làm hoặc di chuyển.</p><p>Độ thoải mái khi đeo phụ thuộc vào kích thước đầu, độ vừa vặn của đệm tai và điều kiện môi trường.</p><h3>JBL Pure Bass Sound – Chất âm đặc trưng</h3><p>Pure Bass Sound là phong cách tinh chỉnh âm thanh của JBL, hướng đến việc thể hiện dải trầm có độ rõ và sức nặng phù hợp. Đây là đặc điểm được nhiều người yêu thích khi nghe nhạc điện tử, pop, hip-hop và những nội dung có nhiều nhạc cụ ở dải tần thấp.</p><p>Người dùng cũng có thể điều chỉnh EQ để thay đổi sự cân bằng giữa âm trầm, âm trung và âm cao theo sở thích hoặc loại nội dung đang nghe.</p><h3>Màng loa 40 mm – Phục vụ nhiều thể loại âm nhạc</h3><p>Hệ thống màng loa 40 mm được thiết kế để tái hiện âm thanh phục vụ nhu cầu giải trí phổ biến. Tai nghe có thể sử dụng để nghe nhạc, xem phim, theo dõi bài giảng và tham gia các cuộc gọi trực tuyến.</p><p>Chất lượng âm thanh cảm nhận phụ thuộc vào bản thu, thiết bị phát, codec Bluetooth và cách thiết lập EQ.</p><h3>Adaptive Noise Cancelling – Hạn chế tiếng ồn nền</h3><p>Công nghệ chống ồn chủ động sử dụng micro và hệ thống xử lý tín hiệu để giảm ảnh hưởng của một số âm thanh từ môi trường. Tính năng hữu ích khi cần nghe nội dung trong văn phòng, thư viện hoặc phương tiện công cộng.</p><p>Hiệu quả chống ồn thay đổi theo loại tiếng ồn, độ kín của đệm tai và môi trường sử dụng. ANC không thể loại bỏ hoàn toàn mọi âm thanh xung quanh.</p><h3>Smart Ambient, Ambient Aware và TalkThru</h3><p>Smart Ambient cung cấp những chế độ hỗ trợ nhận biết môi trường khi đang đeo tai nghe. Ambient Aware cho phép nghe thêm âm thanh xung quanh, trong khi TalkThru hỗ trợ những cuộc trò chuyện ngắn bằng cách điều chỉnh mức âm thanh đang phát.</p><p>Người dùng có thể lựa chọn chế độ phù hợp thông qua nút điều khiển hoặc ứng dụng tương thích mà không cần liên tục tháo tai nghe.</p><h3>Bluetooth 5.3 – Kết nối không dây linh hoạt</h3><p>Bluetooth 5.3 hỗ trợ kết nối với smartphone, laptop, máy tính bảng và các thiết bị phát âm thanh tương thích. Chất lượng kết nối phụ thuộc vào khoảng cách, vật cản và mức độ nhiễu sóng trong môi trường sử dụng.</p><p>Những chức năng liên quan đến LE Audio phụ thuộc vào firmware và khả năng hỗ trợ của thiết bị ghép nối. Người dùng nên kiểm tra tính tương thích nếu cần sử dụng một chức năng Bluetooth cụ thể.</p><h3>Multipoint – Kết nối nhiều thiết bị thuận tiện</h3><p>Kết nối đa điểm cho phép tai nghe duy trì kết nối với hai thiết bị Bluetooth tương thích. Đây là tiện ích phù hợp khi sử dụng laptop để học tập hoặc làm việc và smartphone để theo dõi cuộc gọi.</p><p>Việc chuyển đổi nội dung giữa các thiết bị phụ thuộc vào trạng thái kết nối và khả năng hỗ trợ của hệ điều hành.</p><h3>Ứng dụng JBL Headphones và tùy chỉnh EQ</h3><p>Ứng dụng JBL Headphones cung cấp giao diện quản lý những chức năng tương thích của tai nghe. Người dùng có thể lựa chọn cấu hình âm thanh, điều chỉnh EQ và quản lý các chế độ chống ồn.</p><p>Khả năng cá nhân hóa giúp tai nghe đáp ứng nhiều sở thích nghe khác nhau, từ nội dung giọng nói đến những thể loại nhạc có nhiều âm trầm.</p><h3>Micro tích hợp và đàm thoại rảnh tay</h3><p>Micro tích hợp hỗ trợ nhận cuộc gọi và trao đổi trực tuyến mà không cần sử dụng micro riêng. Các nút trên thân tai nghe cho phép quản lý cuộc gọi và điều chỉnh nội dung đang phát.</p><p>Chất lượng giọng nói phụ thuộc vào tiếng ồn môi trường, kết nối mạng và phần mềm được sử dụng.</p><h3>Thời lượng pin lên đến 70 giờ</h3><p>JBL công bố Tune 770NC có thời lượng nghe lên đến 70 giờ khi tắt ANC và khoảng 44 giờ khi bật ANC trong điều kiện thử nghiệm. Đây là những chỉ số tham khảo, không phải thời lượng cố định trong mọi trường hợp.</p><p>Thời gian sử dụng thực tế thay đổi theo âm lượng, chế độ nghe, kết nối Bluetooth và tình trạng pin. Khả năng sạc nhanh giúp bổ sung năng lượng trong những tình huống cần tiếp tục sử dụng.</p><h3>Kết nối có dây và cổng sạc USB-C</h3><p>Ngoài Bluetooth, tai nghe hỗ trợ sử dụng cáp âm thanh tương thích trong những tình huống phù hợp. Đây là lựa chọn hữu ích khi cần kết nối với thiết bị không hỗ trợ Bluetooth.</p><p>Cổng USB-C được sử dụng để sạc pin. Người dùng nên lựa chọn bộ sạc và cáp đáp ứng thông số kỹ thuật của sản phẩm.</p><h3>JBL Tune 770NC phù hợp với những ai?</h3><ul><li>Người yêu thích chất âm JBL Pure Bass.</li><li>Học sinh, sinh viên cần tai nghe phục vụ học tập và giải trí.</li><li>Người thường xuyên làm việc với laptop và smartphone.</li><li>Người ưu tiên tai nghe có thời lượng pin dài.</li><li>Người muốn trải nghiệm ANC với mức chi phí dễ tiếp cận hơn các dòng cao cấp.</li></ul><h3>Câu hỏi thường gặp về JBL Tune 770NC</h3><h4>JBL Tune 770NC có chống ồn chủ động không?</h4><p>Có. Sản phẩm hỗ trợ Adaptive Noise Cancelling và các chế độ Smart Ambient.</p><h4>Thời lượng 70 giờ có áp dụng khi bật ANC không?</h4><p>Không. Đây là thời lượng tối đa được công bố khi tắt ANC trong điều kiện thử nghiệm.</p><h4>Tai nghe có sử dụng được với iPhone và Android không?</h4><p>Có. Sản phẩm hỗ trợ các thiết bị Bluetooth tương thích.</p><h4>Có thể tùy chỉnh âm thanh không?</h4><p>Có. Người dùng có thể sử dụng ứng dụng JBL Headphones để điều chỉnh EQ và những tính năng được hỗ trợ.</p><h4>Tai nghe có thể gập gọn không?</h4><p>Có. Thiết kế gập gọn hỗ trợ bảo quản và mang theo thuận tiện hơn.</p><h3>Có nên lựa chọn JBL Tune 770NC?</h3><p>JBL Tune 770NC là lựa chọn phù hợp cho người cần tai nghe over-ear không dây có chất âm dễ tùy chỉnh, chống ồn chủ động, khả năng kết nối đa điểm và thời lượng pin dài. Sản phẩm đáp ứng linh hoạt nhu cầu học tập, làm việc, nghe nhạc và giải trí thường ngày.</p>'),

    (N'Tai nghe', N'Samsung', N'Samsung Galaxy Buds3 Pro', N'<h2>Samsung Galaxy Buds3 Pro – Âm thanh Hi-Fi 24-bit, chống ồn thích ứng và thiết kế Blade hiện đại</h2><p><strong>Samsung Galaxy Buds3 Pro</strong> là dòng tai nghe không dây cao cấp của Samsung, được phát triển nhằm kết hợp chất lượng âm thanh, khả năng kiểm soát tiếng ồn và những tính năng thông minh thuộc hệ sinh thái Galaxy. Sản phẩm sở hữu thiết kế Blade đặc trưng, hệ thống loa hai đường tiếng và công nghệ xử lý âm thanh thích ứng.</p><p>Galaxy Buds3 Pro hướng đến người dùng thường xuyên nghe nhạc, xem phim, tham gia cuộc gọi và sử dụng smartphone Galaxy. Khả năng phối hợp giữa phần cứng tai nghe với điện thoại tương thích mang đến nhiều lựa chọn cá nhân hóa và kết nối.</p><h3>Những điểm nổi bật của Samsung Galaxy Buds3 Pro</h3><ul><li><strong>Thiết kế Blade:</strong> Kiểu dáng thân tai nghe góc cạnh kết hợp đệm silicon.</li><li><strong>Blade Light:</strong> Dải đèn tạo điểm nhấn trên thân tai nghe.</li><li><strong>Hệ thống loa hai đường tiếng:</strong> Hỗ trợ phân tách các dải âm.</li><li><strong>Bộ khuếch đại kép:</strong> Phục vụ hệ thống loa bên trong từng tai nghe.</li><li><strong>Âm thanh 24-bit/96 kHz:</strong> Khả dụng trên thiết bị và codec tương thích.</li><li><strong>Adaptive ANC:</strong> Hỗ trợ điều chỉnh chống ồn theo điều kiện sử dụng.</li><li><strong>360 Audio:</strong> Tạo hiệu ứng âm thanh không gian trên nội dung được hỗ trợ.</li><li><strong>Điều khiển bằng thao tác bóp và vuốt:</strong> Truy cập nhanh các chức năng nghe.</li><li><strong>Khả năng kháng nước và bụi IP57:</strong> Áp dụng cho tai nghe theo điều kiện thử nghiệm.</li><li><strong>Hộp sạc USB-C:</strong> Hỗ trợ sạc không dây tương thích.</li></ul><h3>Thiết kế Blade – Phong cách nhận diện khác biệt</h3><p>Galaxy Buds3 Pro đánh dấu sự thay đổi về thiết kế so với các thế hệ Galaxy Buds trước. Phần thân tai nghe có kiểu dáng góc cạnh, tạo khu vực điều khiển riêng và kết hợp dải đèn Blade Light.</p><p>Thiết kế in-ear sử dụng đệm silicon với nhiều kích thước giúp người dùng lựa chọn độ vừa vặn. Độ kín phù hợp có thể cải thiện khả năng cách âm, chất lượng âm trầm và hiệu quả của công nghệ ANC.</p><h3>Hệ thống loa hai đường tiếng và bộ khuếch đại kép</h3><p>Hệ thống loa được thiết kế để xử lý những dải tần khác nhau nhằm cải thiện khả năng tái hiện giọng hát, nhạc cụ và âm trầm. Bộ khuếch đại kép phối hợp với cấu trúc loa để hỗ trợ quá trình phát âm thanh.</p><p>Sự kết hợp này hướng đến trải nghiệm nghe có độ chi tiết và khả năng phân tách tốt hơn. Chất lượng thực tế phụ thuộc vào nguồn nhạc, thiết bị phát và độ vừa vặn khi đeo.</p><h3>Âm thanh độ phân giải cao 24-bit/96 kHz</h3><p>Galaxy Buds3 Pro hỗ trợ truyền âm thanh độ phân giải cao thông qua Samsung Seamless Codec trên những thiết bị Galaxy đáp ứng yêu cầu tương thích. Công nghệ này phù hợp khi sử dụng nguồn nhạc có chất lượng tương ứng.</p><p>Không phải mọi thiết bị Android hoặc iOS đều hỗ trợ chế độ 24-bit/96 kHz. Người dùng cần kiểm tra phiên bản điện thoại, phần mềm và codec trước khi lựa chọn sản phẩm dựa trên tính năng này.</p><h3>Adaptive EQ – Điều chỉnh âm thanh thích ứng</h3><p>Hệ thống xử lý âm thanh có thể sử dụng dữ liệu từ micro để điều chỉnh cách tái hiện âm thanh theo điều kiện đeo. Tính năng hướng đến việc duy trì trải nghiệm nghe phù hợp khi độ kín của tai nghe thay đổi.</p><p>Người dùng có thể kết hợp với các cấu hình EQ trong ứng dụng Galaxy Wearable để lựa chọn chất âm theo sở thích cá nhân.</p><h3>Adaptive ANC – Kiểm soát tiếng ồn thông minh</h3><p>Adaptive ANC sử dụng hệ thống micro để phân tích tiếng ồn môi trường và điều chỉnh quá trình chống ồn trong những điều kiện phù hợp. Tính năng hữu ích khi làm việc, học tập hoặc di chuyển tại những nơi có nhiều tiếng ồn nền.</p><p>Khả năng chống ồn phụ thuộc vào loại âm thanh, độ kín của đệm tai và môi trường sử dụng. Tai nghe không thể loại bỏ hoàn toàn mọi âm thanh từ bên ngoài.</p><h3>Ambient Sound và nhận diện giọng nói</h3><p>Chế độ Ambient Sound hỗ trợ truyền một phần âm thanh môi trường vào tai nghe để người dùng dễ dàng theo dõi những thông tin xung quanh. Những chức năng nhận diện giọng nói tương thích có thể điều chỉnh chế độ nghe khi phát hiện người đeo đang trò chuyện.</p><p>Người dùng có thể tùy chỉnh các chức năng này bằng ứng dụng Galaxy Wearable và lựa chọn chế độ phù hợp với từng tình huống.</p><h3>360 Audio – Trải nghiệm âm thanh không gian</h3><p>360 Audio tạo hiệu ứng âm thanh có vị trí và chiều sâu trên những nội dung tương thích. Khi kết hợp với tính năng theo dõi chuyển động đầu được hỗ trợ, hướng âm thanh có thể thay đổi theo cách người dùng tương tác với thiết bị.</p><p>Tính năng phù hợp với việc xem phim, video và các nội dung đa phương tiện có hỗ trợ âm thanh không gian.</p><h3>Galaxy AI và khả năng hỗ trợ phiên dịch</h3><p>Galaxy Buds3 Pro có thể phối hợp với các công cụ phiên dịch trên smartphone Galaxy tương thích. Tai nghe hỗ trợ phát nội dung âm thanh được xử lý bởi điện thoại, giúp người dùng tiếp nhận thông tin trong những tình huống giao tiếp phù hợp.</p><p>Khả năng phiên dịch phụ thuộc vào điện thoại, ứng dụng, ngôn ngữ, khu vực và kết nối mạng khi cần thiết. Tai nghe không hoạt động như một thiết bị phiên dịch độc lập.</p><h3>Điều khiển bằng thao tác bóp và vuốt</h3><p>Thiết kế Blade cung cấp khu vực tương tác để người dùng thực hiện thao tác bóp nhằm phát hoặc tạm dừng nội dung, quản lý cuộc gọi và chuyển đổi chức năng tương thích. Thao tác vuốt hỗ trợ điều chỉnh âm lượng trực tiếp trên tai nghe.</p><p>Cách điều khiển này giúp giảm nhu cầu sử dụng điện thoại trong những thao tác nghe nhạc thông thường.</p><h3>Micro và khả năng đàm thoại</h3><p>Hệ thống micro kết hợp các thuật toán xử lý giọng nói nhằm hỗ trợ thu nhận âm thanh trong cuộc gọi. Người dùng có thể sử dụng tai nghe cho các cuộc họp trực tuyến, gọi điện và giao tiếp hằng ngày.</p><p>Chất lượng giọng nói thực tế phụ thuộc vào môi trường, kết nối mạng và thiết bị đang sử dụng.</p><h3>Thời lượng pin và hộp sạc</h3><p>Samsung công bố thời lượng nghe lên đến khoảng 6 giờ khi bật ANC và tổng thời lượng khoảng 26 giờ khi sử dụng cùng hộp sạc trong điều kiện thử nghiệm. Khi tắt ANC, thời gian nghe có thể dài hơn.</p><p>Hộp sạc hỗ trợ USB-C và các phương thức sạc không dây tương thích. Mức tiêu thụ pin phụ thuộc vào âm lượng, codec, chế độ chống ồn và tình trạng pin.</p><h3>Khả năng kháng nước và bụi IP57</h3><p>Tai nghe Galaxy Buds3 Pro được đánh giá đạt chuẩn IP57 trong điều kiện thử nghiệm. Khả năng bảo vệ này không áp dụng tương tự cho hộp sạc và có thể suy giảm theo thời gian sử dụng.</p><p>Người dùng nên giữ tai nghe và hộp sạc khô ráo trước khi sạc, đồng thời tuân thủ hướng dẫn bảo quản của Samsung.</p><h3>Kết nối với hệ sinh thái Galaxy</h3><p>Tai nghe hỗ trợ Bluetooth và có thể sử dụng với nhiều thiết bị phát tương thích. Khi ghép nối với smartphone hoặc máy tính bảng Galaxy được hỗ trợ, người dùng có thể tận dụng thêm những tính năng tùy chỉnh, chuyển đổi thiết bị và xử lý âm thanh nâng cao.</p><h3>Galaxy Buds3 Pro phù hợp với những ai?</h3><ul><li>Người đang sử dụng smartphone Samsung Galaxy.</li><li>Người yêu thích nghe nhạc với nhiều tùy chọn âm thanh.</li><li>Người cần chống ồn chủ động trong công việc.</li><li>Người thường xuyên xem phim và tham gia cuộc gọi trực tuyến.</li><li>Người muốn trải nghiệm những tính năng âm thanh nâng cao của hệ sinh thái Galaxy.</li></ul><h3>Câu hỏi thường gặp về Galaxy Buds3 Pro</h3><h4>Tai nghe có hỗ trợ âm thanh 24-bit/96 kHz trên mọi điện thoại không?</h4><p>Không. Tính năng này yêu cầu thiết bị Galaxy và codec tương thích.</p><h4>Galaxy Buds3 Pro có hỗ trợ sạc không dây không?</h4><p>Có. Hộp sạc hỗ trợ các phương thức sạc không dây tương thích.</p><h4>Tai nghe có thể sử dụng với iPhone không?</h4><p>Có thể ghép nối qua Bluetooth, nhưng các tính năng nâng cao có thể không khả dụng đầy đủ.</p><h4>Có thể phiên dịch mà không cần điện thoại không?</h4><p>Không. Khả năng phiên dịch phụ thuộc vào smartphone và phần mềm tương thích.</p><h4>Chuẩn IP57 có áp dụng cho hộp sạc không?</h4><p>Không. Mức bảo vệ được công bố áp dụng cho tai nghe.</p><h3>Có nên lựa chọn Samsung Galaxy Buds3 Pro?</h3><p>Galaxy Buds3 Pro là lựa chọn đáng cân nhắc cho người muốn trải nghiệm tai nghe không dây cao cấp với hệ thống loa hai đường tiếng, chống ồn thích ứng, thiết kế hiện đại và khả năng kết nối sâu với hệ sinh thái Samsung Galaxy.</p>'),

    (N'Máy ảnh Mirrorless', N'Canon', N'Canon EOS R50', N'<h2>Canon EOS R50 – Máy ảnh Mirrorless APS-C nhỏ gọn, lấy nét thông minh và quay video 4K sắc nét</h2><p><strong>Canon EOS R50</strong> là mẫu máy ảnh mirrorless được phát triển dành cho người mới bắt đầu nhiếp ảnh, người sáng tạo nội dung và những người cần một thiết bị quay chụp nhỏ gọn. Sản phẩm kết hợp cảm biến APS-C CMOS 24,2 MP, bộ xử lý DIGIC X và hệ thống lấy nét Dual Pixel CMOS AF II nhằm mang đến khả năng ghi hình linh hoạt.</p><p>Với màn hình cảm ứng xoay lật, chế độ chụp tự động nâng cao và khả năng quay video 4K, EOS R50 phù hợp cho nhiều nhu cầu như chụp ảnh du lịch, chân dung, sản phẩm, sự kiện gia đình và sản xuất nội dung trực tuyến.</p><h3>Những điểm nổi bật của Canon EOS R50</h3><ul><li><strong>Cảm biến APS-C CMOS 24,2 MP:</strong> Ghi nhận hình ảnh có độ chi tiết cao.</li><li><strong>Bộ xử lý DIGIC X:</strong> Hỗ trợ xử lý hình ảnh và video.</li><li><strong>Dual Pixel CMOS AF II:</strong> Công nghệ lấy nét tự động tích hợp trên cảm biến.</li><li><strong>Nhận diện chủ thể:</strong> Hỗ trợ theo dõi người, động vật và phương tiện trong những chế độ phù hợp.</li><li><strong>Quay video 4K 30p:</strong> Lấy mẫu từ dữ liệu cảm biến độ phân giải cao trong chế độ tương ứng.</li><li><strong>Full HD tốc độ khung hình cao:</strong> Hỗ trợ sáng tạo nội dung chuyển động chậm.</li><li><strong>Màn hình cảm ứng xoay lật:</strong> Thuận tiện khi ghi hình từ nhiều góc độ.</li><li><strong>Ngàm Canon RF:</strong> Tương thích với hệ thống ống kính RF và RF-S phù hợp.</li><li><strong>Kết nối Wi-Fi và Bluetooth:</strong> Hỗ trợ chia sẻ hình ảnh và điều khiển từ xa.</li></ul><h3>Thiết kế nhỏ gọn – Thuận tiện mang theo</h3><p>Canon EOS R50 sử dụng thiết kế thân máy mirrorless nhỏ gọn, giảm kích thước so với nhiều hệ thống máy ảnh DSLR truyền thống. Báng cầm và các nút điều khiển được bố trí nhằm hỗ trợ người mới dễ dàng làm quen với thao tác quay chụp.</p><p>Thiết bị phù hợp để mang theo trong những chuyến du lịch, hoạt động gia đình hoặc các buổi ghi hình ngoài trời. Kích thước và trọng lượng của bộ máy thực tế còn phụ thuộc vào ống kính được sử dụng.</p><h3>Cảm biến APS-C CMOS 24,2 MP – Nền tảng chất lượng hình ảnh</h3><p>Cảm biến APS-C 24,2 MP cung cấp khả năng ghi nhận hình ảnh có độ phân giải phù hợp cho nhiều nhu cầu nhiếp ảnh. Kích thước cảm biến tạo thêm lựa chọn kiểm soát độ sâu trường ảnh khi kết hợp với ống kính và thông số chụp phù hợp.</p><p>Người dùng có thể chụp phong cảnh, chân dung, sản phẩm và những hoạt động thường ngày với mức độ chi tiết đáp ứng nhiều mục đích sử dụng. Chất lượng hình ảnh phụ thuộc vào ánh sáng, ống kính, thông số phơi sáng và kỹ thuật chụp.</p><h3>Bộ xử lý DIGIC X – Xử lý hình ảnh và video</h3><p>DIGIC X đảm nhiệm các tác vụ xử lý dữ liệu từ cảm biến, hỗ trợ tái hiện màu sắc, kiểm soát nhiễu và vận hành những chức năng quay chụp. Bộ xử lý phối hợp với hệ thống lấy nét để cải thiện khả năng phản hồi của máy ảnh.</p><p>Người dùng có thể lựa chọn định dạng JPEG hoặc RAW theo nhu cầu sử dụng. JPEG phù hợp khi cần chia sẻ nhanh, trong khi RAW cung cấp thêm dữ liệu để điều chỉnh trong quá trình hậu kỳ.</p><h3>Dual Pixel CMOS AF II – Lấy nét tự động thông minh</h3><p>Hệ thống Dual Pixel CMOS AF II sử dụng dữ liệu từ cảm biến để hỗ trợ xác định và theo dõi vị trí lấy nét. Máy ảnh có thể nhận diện những loại chủ thể được hỗ trợ, giúp đơn giản hóa thao tác khi chụp ảnh và quay video.</p><p>Khả năng nhận diện người và mắt đặc biệt hữu ích khi chụp chân dung. Những chế độ nhận diện động vật và phương tiện mở rộng khả năng sử dụng trong các tình huống nhiếp ảnh khác.</p><p>Hiệu quả lấy nét thực tế phụ thuộc vào ống kính, ánh sáng, chuyển động chủ thể và thiết lập máy ảnh.</p><h3>Chụp liên tục – Ghi lại những khoảnh khắc chuyển động</h3><p>EOS R50 hỗ trợ chụp liên tục lên đến khoảng 12 khung hình mỗi giây với màn trập màn trước điện tử và 15 khung hình mỗi giây với màn trập điện tử trong những điều kiện phù hợp.</p><p>Chế độ này hữu ích khi ghi lại hoạt động có chuyển động nhanh. Tốc độ và số lượng ảnh chụp liên tục phụ thuộc vào thông số máy, định dạng tệp, thẻ nhớ và điều kiện lấy nét.</p><h3>Quay video 4K 30p – Hình ảnh sắc nét</h3><p>Canon EOS R50 hỗ trợ quay video 4K UHD lên đến 30p với phương thức lấy mẫu từ dữ liệu cảm biến 6K trong chế độ tương ứng. Khả năng này giúp tạo ra video có độ chi tiết phù hợp cho các dự án sáng tạo nội dung.</p><p>Chế độ 4K thông thường không yêu cầu cắt thêm vùng cảm biến theo phương thức được công bố. Tuy nhiên, các thiết lập chống rung kỹ thuật số có thể làm thay đổi góc nhìn thực tế.</p><h3>Quay Full HD tốc độ khung hình cao</h3><p>Máy ảnh hỗ trợ những chế độ quay Full HD với tốc độ khung hình cao lên đến 120p trong điều kiện tương thích. Người dùng có thể tận dụng các khung hình bổ sung để tạo hiệu ứng chuyển động chậm khi dựng video.</p><p>Khả năng ghi âm và những chức năng đi kèm có thể khác nhau tùy chế độ quay được lựa chọn.</p><h3>Màn hình cảm ứng xoay lật – Linh hoạt khi quay vlog</h3><p>Màn hình LCD cảm ứng xoay lật cho phép người dùng quan sát khung hình từ nhiều góc độ. Khi quay vlog hoặc tự ghi hình, màn hình có thể được xoay về phía trước để theo dõi bố cục.</p><p>Khả năng điều chỉnh góc màn hình cũng hữu ích khi chụp ở vị trí thấp, cao hoặc những không gian khó quan sát qua kính ngắm.</p><h3>Advanced A+ – Hỗ trợ người mới bắt đầu</h3><p>Chế độ tự động nâng cao Advanced A+ hỗ trợ nhận diện điều kiện chụp và lựa chọn những thiết lập phù hợp trong phạm vi hoạt động của hệ thống. Người dùng có thể tập trung vào bố cục và khoảnh khắc thay vì phải liên tục điều chỉnh các thông số kỹ thuật.</p><p>Khi đã làm quen với máy ảnh, người dùng có thể chuyển sang những chế độ bán tự động hoặc thủ công để kiểm soát khẩu độ, tốc độ màn trập và ISO.</p><h3>Ngàm RF và hệ thống ống kính mở rộng</h3><p>Canon EOS R50 sử dụng ngàm RF, hỗ trợ những ống kính RF và RF-S tương thích. Người dùng có thể lựa chọn ống kính dựa trên thể loại nhiếp ảnh như góc rộng, chân dung hoặc chụp chủ thể ở xa.</p><p>Những ống kính EF và EF-S tương thích có thể được sử dụng thông qua bộ chuyển ngàm phù hợp. Người mua cần kiểm tra khả năng tương thích cụ thể của ống kính và phụ kiện.</p><h3>Khả năng chống rung và lựa chọn ống kính</h3><p>EOS R50 không được trang bị hệ thống chống rung cơ học trong thân máy. Người dùng có thể kết hợp với ống kính hỗ trợ chống rung quang học hoặc sử dụng những chế độ chống rung kỹ thuật số tương thích khi quay video.</p><p>Chất lượng ổn định hình ảnh còn phụ thuộc vào tiêu cự, tốc độ màn trập và cách giữ máy.</p><h3>Kết nối Wi-Fi, Bluetooth và Canon Camera Connect</h3><p>Máy ảnh hỗ trợ kết nối với smartphone thông qua các phương thức tương thích. Ứng dụng Canon Camera Connect cung cấp những chức năng như truyền hình ảnh và điều khiển chụp từ xa.</p><p>Người dùng có thể chuyển ảnh sang điện thoại để xem lại, chỉnh sửa và chia sẻ mà không cần liên tục tháo thẻ nhớ.</p><h3>Pin, thẻ nhớ và phụ kiện</h3><p>EOS R50 sử dụng pin sạc LP-E17 và thẻ nhớ SD tương thích. Thời lượng pin phụ thuộc vào việc sử dụng màn hình, kính ngắm, kết nối không dây và các chế độ quay chụp.</p><p>Người thường xuyên quay video hoặc chụp liên tục nên cân nhắc dung lượng và tốc độ thẻ nhớ phù hợp với yêu cầu của chế độ ghi hình.</p><h3>Canon EOS R50 phù hợp với những ai?</h3><ul><li>Người mới bắt đầu học nhiếp ảnh.</li><li>Người sáng tạo video và vlog.</li><li>Người thường xuyên chụp ảnh du lịch.</li><li>Người cần máy ảnh nhỏ gọn để chụp sản phẩm.</li><li>Người muốn xây dựng hệ thống ống kính Canon RF.</li></ul><h3>Câu hỏi thường gặp về Canon EOS R50</h3><h4>Canon EOS R50 có phải máy ảnh full-frame không?</h4><p>Không. Thiết bị sử dụng cảm biến APS-C CMOS 24,2 MP.</p><h4>Máy có hỗ trợ quay video 4K không?</h4><p>Có. Máy hỗ trợ quay 4K UHD lên đến 30p trong chế độ tương thích.</p><h4>EOS R50 có chống rung trong thân máy không?</h4><p>Không. Máy có thể kết hợp với ống kính chống rung và những chế độ chống rung kỹ thuật số được hỗ trợ.</p><h4>Có phù hợp cho người mới học chụp ảnh không?</h4><p>Có. Giao diện cảm ứng, chế độ tự động và hệ thống lấy nét thông minh hỗ trợ người mới làm quen.</p><h4>Máy có đi kèm ống kính không?</h4><p>Điều này phụ thuộc vào phiên bản Body Only hoặc bộ Kit được bán. Người mua cần kiểm tra cấu hình sản phẩm cụ thể.</p><h3>Có nên lựa chọn Canon EOS R50?</h3><p>Canon EOS R50 là lựa chọn đáng cân nhắc cho người mới bước vào nhiếp ảnh hoặc cần máy ảnh mirrorless nhỏ gọn để quay video và sáng tạo nội dung. Cảm biến APS-C 24,2 MP, hệ thống lấy nét Dual Pixel CMOS AF II và màn hình xoay lật tạo nên một thiết bị linh hoạt cho nhiều nhu cầu sử dụng.</p>'),

    (N'Máy ảnh Mirrorless', N'Sony', N'Sony Alpha A6400', N'<h2>Sony Alpha A6400 – Máy ảnh Mirrorless APS-C, lấy nét theo thời gian thực và quay video 4K HDR</h2><p><strong>Sony Alpha A6400</strong> là mẫu máy ảnh mirrorless thuộc hệ thống Sony Alpha, hướng đến người yêu thích nhiếp ảnh, quay video và sáng tạo nội dung. Thiết bị sử dụng cảm biến APS-C Exmor CMOS 24,2 MP kết hợp bộ xử lý hình ảnh BIONZ X và hệ thống lấy nét tự động có khả năng theo dõi chủ thể theo thời gian thực.</p><p>Với thân máy nhỏ gọn, hệ thống ống kính ngàm E đa dạng và khả năng quay video 4K, A6400 phù hợp với người muốn xây dựng một hệ thống quay chụp linh hoạt có thể mở rộng theo nhu cầu sử dụng.</p><h3>Những điểm nổi bật của Sony Alpha A6400</h3><ul><li><strong>Cảm biến APS-C Exmor CMOS 24,2 MP:</strong> Hỗ trợ ghi nhận hình ảnh chi tiết.</li><li><strong>BIONZ X:</strong> Bộ xử lý hình ảnh phục vụ quay chụp.</li><li><strong>425 điểm lấy nét theo pha:</strong> Phủ rộng khu vực cảm biến.</li><li><strong>Real-time Tracking:</strong> Hỗ trợ theo dõi chủ thể trong khung hình.</li><li><strong>Real-time Eye AF:</strong> Hỗ trợ nhận diện và lấy nét vào mắt trong chế độ tương thích.</li><li><strong>Chụp liên tục:</strong> Lên đến 11 khung hình mỗi giây trong điều kiện phù hợp.</li><li><strong>Quay video 4K:</strong> Hỗ trợ ghi hình UHD và các cấu hình màu chuyên sâu.</li><li><strong>Màn hình lật 180 độ:</strong> Thuận tiện khi tự ghi hình.</li><li><strong>Ngàm Sony E:</strong> Tương thích với nhiều ống kính khác nhau.</li></ul><h3>Thiết kế thân máy nhỏ gọn và chắc chắn</h3><p>Sony A6400 sử dụng kiểu dáng mirrorless với kính ngắm điện tử được bố trí lệch về một bên. Thiết kế giúp thân máy duy trì kích thước tương đối gọn gàng, thuận tiện khi mang theo trong những chuyến du lịch hoặc buổi chụp ngoài trời.</p><p>Cấu trúc thân máy sử dụng hợp kim magie ở những khu vực được thiết kế nhằm tăng độ chắc chắn. Các biện pháp hạn chế bụi và độ ẩm hỗ trợ bảo vệ trong điều kiện phù hợp, nhưng máy không phải thiết bị chống nước hoàn toàn.</p><h3>Cảm biến APS-C Exmor CMOS 24,2 MP</h3><p>Cảm biến APS-C 24,2 MP cung cấp nền tảng ghi nhận hình ảnh có độ phân giải phù hợp cho nhiều thể loại nhiếp ảnh. Người dùng có thể khai thác độ chi tiết khi chụp phong cảnh, chân dung, kiến trúc và hình ảnh sản phẩm.</p><p>Khi kết hợp với ống kính khẩu độ lớn, máy ảnh cung cấp khả năng kiểm soát độ sâu trường ảnh để tạo sự tách biệt giữa chủ thể và hậu cảnh trong những tình huống phù hợp.</p><h3>Bộ xử lý BIONZ X – Hỗ trợ tái hiện hình ảnh</h3><p>BIONZ X xử lý dữ liệu từ cảm biến, hỗ trợ tái hiện màu sắc, chi tiết và kiểm soát nhiễu. Hệ thống xử lý phối hợp với những công nghệ lấy nét và chụp liên tục nhằm nâng cao khả năng phản hồi của máy.</p><p>Người dùng có thể lựa chọn JPEG để sử dụng nhanh hoặc RAW để có thêm khả năng điều chỉnh độ sáng, màu sắc và cân bằng trắng trong phần mềm hậu kỳ tương thích.</p><h3>Hệ thống 425 điểm lấy nét theo pha</h3><p>Sony A6400 được trang bị 425 điểm lấy nét theo pha và 425 điểm lấy nét tương phản. Các điểm lấy nét được bố trí trên vùng rộng của cảm biến nhằm hỗ trợ nhận diện chủ thể ở nhiều vị trí trong khung hình.</p><p>Sony công bố tốc độ lấy nét có thể đạt khoảng 0,02 giây trong điều kiện thử nghiệm phù hợp. Tốc độ thực tế phụ thuộc vào ống kính, ánh sáng, chủ thể và chế độ lấy nét.</p><h3>Real-time Tracking – Theo dõi chủ thể linh hoạt</h3><p>Real-time Tracking sử dụng những thông tin hình ảnh như màu sắc, khoảng cách và đặc điểm chủ thể để hỗ trợ duy trì điểm lấy nét khi chủ thể di chuyển trong khung hình.</p><p>Công nghệ hữu ích trong các tình huống chụp người, hoạt động ngoài trời và những nội dung có chuyển động. Người dùng có thể lựa chọn vùng lấy nét phù hợp với bố cục mong muốn.</p><h3>Real-time Eye AF – Hỗ trợ nhiếp ảnh chân dung</h3><p>Real-time Eye AF giúp hệ thống nhận diện và ưu tiên lấy nét vào mắt trong các chế độ được hỗ trợ. Tính năng giảm bớt thao tác lựa chọn điểm lấy nét thủ công khi chụp chân dung.</p><p>Khả năng nhận diện mắt phụ thuộc vào góc nhìn, ánh sáng, mức độ che khuất và phiên bản firmware. Người dùng vẫn có thể lựa chọn các chế độ lấy nét khác khi cần kiểm soát vị trí lấy nét.</p><h3>Chụp liên tục lên đến 11 khung hình mỗi giây</h3><p>A6400 hỗ trợ chụp liên tục với tốc độ tối đa khoảng 11 khung hình mỗi giây trong điều kiện phù hợp. Chế độ này cung cấp nhiều khung hình liên tiếp để người dùng lựa chọn khoảnh khắc mong muốn.</p><p>Tốc độ thực tế và dung lượng bộ đệm phụ thuộc vào định dạng ảnh, thẻ nhớ, thông số lấy nét và chế độ chụp.</p><h3>Quay video 4K UHD – Phục vụ sáng tạo nội dung</h3><p>Sony A6400 hỗ trợ quay video 4K UHD với các tốc độ khung hình tương thích. Trong những chế độ phù hợp, dữ liệu từ vùng cảm biến được lấy mẫu để tạo video có độ chi tiết cao.</p><p>Máy có thể phục vụ những nhu cầu như quay vlog, video du lịch, giới thiệu sản phẩm và phỏng vấn. Góc nhìn thực tế thay đổi theo chế độ quay và tiêu cự ống kính.</p><h3>HLG, S-Log2 và S-Log3 – Mở rộng lựa chọn hậu kỳ</h3><p>Máy ảnh hỗ trợ các cấu hình hình ảnh như HLG, S-Log2 và S-Log3 nhằm cung cấp thêm lựa chọn cho người muốn kiểm soát màu sắc trong quá trình dựng video.</p><p>Những cấu hình này yêu cầu kiến thức phù hợp về phơi sáng và chỉnh màu để đạt kết quả mong muốn. Người mới có thể bắt đầu với các cấu hình màu tiêu chuẩn trước khi chuyển sang quy trình hậu kỳ chuyên sâu.</p><h3>Màn hình lật 180 độ và khả năng tự ghi hình</h3><p>Màn hình phía sau có thể lật lên 180 độ để người dùng quan sát bố cục khi tự quay video hoặc chụp ảnh. Màn hình cũng hỗ trợ điều chỉnh góc nhìn trong những tình huống đặt máy ở vị trí thấp hoặc cao.</p><p>Khi sử dụng micro gắn trên hot shoe, người dùng nên lưu ý vị trí phụ kiện có thể che một phần màn hình trong trạng thái lật về phía trước.</p><h3>Kính ngắm điện tử và các nút điều khiển</h3><p>Kính ngắm điện tử cho phép quan sát khung hình cùng những thông tin liên quan đến phơi sáng và chế độ chụp. Đây là tiện ích phù hợp khi làm việc ngoài trời hoặc muốn hạn chế ảnh hưởng của ánh sáng môi trường lên màn hình phía sau.</p><p>Những nút chức năng có thể tùy chỉnh giúp người dùng thiết lập cách thao tác theo thói quen quay chụp.</p><h3>Hệ thống ống kính Sony E-mount</h3><p>A6400 sử dụng ngàm Sony E, cho phép kết hợp với nhiều ống kính APS-C và những ống kính full-frame ngàm E tương thích. Người dùng có thể lựa chọn ống kính theo thể loại nhiếp ảnh và ngân sách.</p><p>Ống kính góc rộng phù hợp với phong cảnh và vlog, ống kính tiêu cự tiêu chuẩn phục vụ nhu cầu đa dụng, trong khi những ống kính telephoto mở rộng khả năng chụp chủ thể ở xa.</p><h3>Khả năng chống rung và ổn định hình ảnh</h3><p>Sony A6400 không được trang bị hệ thống chống rung cơ học trong thân máy. Người dùng có thể lựa chọn ống kính tích hợp Optical SteadyShot hoặc kết hợp chân máy và các phụ kiện ổn định hình ảnh tương thích.</p><p>Hiệu quả chống rung phụ thuộc vào tiêu cự, điều kiện quay chụp và phương thức ổn định được sử dụng.</p><h3>Kết nối và chia sẻ hình ảnh</h3><p>Máy ảnh hỗ trợ Wi-Fi và Bluetooth để kết nối với smartphone thông qua phần mềm tương thích. Người dùng có thể truyền ảnh, xem lại nội dung và sử dụng các chức năng điều khiển từ xa được hỗ trợ.</p><h3>Pin, thẻ nhớ và dung lượng lưu trữ</h3><p>A6400 sử dụng pin NP-FW50 và thẻ nhớ tương thích. Thời gian hoạt động thực tế thay đổi theo chế độ quay chụp, mức độ sử dụng màn hình và kết nối không dây.</p><p>Người thường xuyên quay video 4K nên lựa chọn thẻ nhớ đáp ứng yêu cầu tốc độ ghi và dung lượng của định dạng video đang sử dụng.</p><h3>Sony Alpha A6400 phù hợp với những ai?</h3><ul><li>Người yêu thích nhiếp ảnh chân dung và du lịch.</li><li>Người cần hệ thống lấy nét tự động linh hoạt.</li><li>Người sáng tạo nội dung video và vlog.</li><li>Người muốn sử dụng hệ thống ống kính Sony E-mount.</li><li>Người cần máy ảnh APS-C nhỏ gọn có thể mở rộng phụ kiện.</li></ul><h3>Câu hỏi thường gặp về Sony Alpha A6400</h3><h4>Sony A6400 có phải máy ảnh full-frame không?</h4><p>Không. Thiết bị sử dụng cảm biến APS-C 24,2 MP.</p><h4>Máy có quay được video 4K không?</h4><p>Có. A6400 hỗ trợ quay 4K UHD trong những chế độ tương thích.</p><h4>Sony A6400 có chống rung trong thân máy không?</h4><p>Không. Người dùng có thể sử dụng ống kính OSS hoặc phụ kiện ổn định hình ảnh phù hợp.</p><h4>Máy có hỗ trợ micro ngoài không?</h4><p>Có. Thiết bị được trang bị cổng kết nối micro ngoài tương thích.</p><h4>Có thể sử dụng ống kính Sony full-frame ngàm E không?</h4><p>Có thể sử dụng những ống kính tương thích, nhưng góc nhìn sẽ chịu ảnh hưởng bởi kích thước cảm biến APS-C.</p><h3>Có nên lựa chọn Sony Alpha A6400?</h3><p>Sony A6400 phù hợp với người cần máy ảnh mirrorless nhỏ gọn có khả năng lấy nét tự động linh hoạt, quay video 4K và hệ thống ống kính phong phú. Trước khi mua, người dùng nên cân nhắc phiên bản thân máy hoặc bộ Kit, loại ống kính và những phụ kiện phù hợp với nhu cầu quay chụp.</p>'),

    (N'Máy ảnh Mirrorless', N'Fujifilm', N'Fujifilm X-S20', N'<h2>Fujifilm X-S20 – Máy ảnh Mirrorless APS-C đa năng, màu phim đặc trưng và khả năng quay video 6.2K</h2><p><strong>Fujifilm X-S20</strong> là mẫu máy ảnh mirrorless được phát triển nhằm kết hợp khả năng nhiếp ảnh và quay video trong một thân máy tương đối nhỏ gọn. Sản phẩm sở hữu cảm biến X-Trans CMOS 4 26,1 MP, bộ xử lý X-Processor 5, hệ thống chống rung trong thân máy và những chế độ giả lập màu phim đặc trưng của Fujifilm.</p><p>Với khả năng ghi hình lên đến 6.2K, màn hình xoay lật, chế độ Vlog chuyên dụng và thời lượng pin được cải thiện, X-S20 hướng đến người yêu thích nhiếp ảnh, sáng tạo nội dung và những người cần một hệ thống máy ảnh linh hoạt cho cả ảnh tĩnh lẫn video.</p><h3>Những điểm nổi bật của Fujifilm X-S20</h3><ul><li><strong>Cảm biến X-Trans CMOS 4:</strong> Cảm biến APS-C có độ phân giải 26,1 MP.</li><li><strong>X-Processor 5:</strong> Hỗ trợ xử lý hình ảnh, video và nhận diện chủ thể.</li><li><strong>Chống rung IBIS 5 trục:</strong> Hiệu quả tối đa được công bố lên đến 7 stop trong điều kiện tương thích.</li><li><strong>Film Simulation:</strong> Cung cấp nhiều lựa chọn giả lập màu phim.</li><li><strong>Quay video 6.2K 30p:</strong> Mở rộng khả năng ghi hình độ phân giải cao.</li><li><strong>Quay 4K 60p:</strong> Hỗ trợ nội dung có chuyển động nhanh.</li><li><strong>Video 10-bit:</strong> Cung cấp thêm dữ liệu màu trong các chế độ tương thích.</li><li><strong>Chế độ Vlog:</strong> Hỗ trợ người sáng tạo nội dung tự ghi hình.</li><li><strong>Màn hình cảm ứng xoay lật:</strong> Linh hoạt khi thay đổi góc quay chụp.</li><li><strong>Pin NP-W235:</strong> Hỗ trợ thời lượng sử dụng dài hơn so với thế hệ trước.</li></ul><h3>Thiết kế nhỏ gọn với báng cầm chắc chắn</h3><p>Fujifilm X-S20 sử dụng thiết kế thân máy nhỏ gọn kết hợp phần báng cầm tương đối sâu. Cấu trúc này hỗ trợ thao tác khi kết hợp với nhiều loại ống kính, đồng thời giữ được tính di động cần thiết cho một hệ thống máy ảnh APS-C.</p><p>Các vòng xoay và nút điều khiển được bố trí để phục vụ cả chụp ảnh và quay video. Người dùng có thể tùy chỉnh một số chức năng theo thói quen cá nhân.</p><h3>Cảm biến X-Trans CMOS 4 26,1 MP</h3><p>Cảm biến APS-C X-Trans CMOS 4 có độ phân giải 26,1 MP, sử dụng cấu trúc bộ lọc màu đặc trưng của Fujifilm. Thiết kế hướng đến khả năng ghi nhận chi tiết và tái hiện màu sắc trong nhiều điều kiện quay chụp.</p><p>Độ phân giải 26,1 MP phù hợp với nhiều nhu cầu như chụp chân dung, phong cảnh, đường phố, sản phẩm và những dự án sáng tạo. Người dùng có thể lựa chọn định dạng ảnh JPEG hoặc RAW tùy mục đích sử dụng.</p><h3>X-Processor 5 – Nền tảng xử lý thế hệ mới</h3><p>X-Processor 5 hỗ trợ quá trình xử lý dữ liệu từ cảm biến, vận hành hệ thống lấy nét và các chức năng quay video nâng cao. Bộ xử lý phối hợp với những thuật toán nhận diện chủ thể nhằm cải thiện khả năng theo dõi trong những tình huống phù hợp.</p><p>Ngoài khả năng xử lý ảnh tĩnh, bộ xử lý còn hỗ trợ các chế độ ghi hình độ phân giải cao và định dạng video có chiều sâu màu lớn hơn.</p><h3>Film Simulation – Phong cách màu phim đặc trưng</h3><p>Fujifilm X-S20 cung cấp 19 chế độ Film Simulation, cho phép người dùng lựa chọn nhiều phong cách thể hiện màu sắc khác nhau ngay trong máy ảnh. Những chế độ này được phát triển dựa trên đặc điểm hình ảnh và màu sắc thuộc các dòng phim của Fujifilm.</p><p>Các lựa chọn như PROVIA, Velvia, ASTIA, Classic Chrome, Classic Neg. và ETERNA mang đến những cách tái hiện độ tương phản, màu sắc và sắc độ khác nhau.</p><p>Người dùng có thể kết hợp Film Simulation với những thiết lập như cân bằng trắng, vùng sáng, vùng tối và hiệu ứng hạt để xây dựng phong cách hình ảnh riêng mà không cần thực hiện quá nhiều thao tác hậu kỳ.</p><h3>Chống rung IBIS 5 trục – Hỗ trợ ổn định hình ảnh</h3><p>Fujifilm X-S20 được trang bị hệ thống chống rung dịch chuyển cảm biến trong thân máy. Fujifilm công bố hiệu quả chống rung tối đa lên đến 7 stop khi sử dụng ống kính và điều kiện thử nghiệm tương thích.</p><p>Tính năng hỗ trợ giảm ảnh hưởng của những chuyển động nhỏ khi cầm máy, đặc biệt hữu ích trong các tình huống chụp với tốc độ màn trập thấp hoặc quay video cầm tay.</p><p>Hiệu quả thực tế phụ thuộc vào tiêu cự, ống kính, kiểu chuyển động và phương thức sử dụng. IBIS không thể loại bỏ hoàn toàn mọi chuyển động của máy ảnh hoặc chủ thể.</p><h3>Hệ thống lấy nét và nhận diện chủ thể</h3><p>X-S20 sử dụng hệ thống lấy nét tự động kết hợp dữ liệu từ cảm biến và thuật toán nhận diện chủ thể. Máy hỗ trợ nhận diện người, động vật, chim và những loại phương tiện được phần mềm hỗ trợ.</p><p>Khả năng theo dõi chủ thể giúp người dùng giảm bớt thao tác điều chỉnh điểm lấy nét khi chủ thể thay đổi vị trí. Chất lượng lấy nét thực tế phụ thuộc vào ánh sáng, ống kính và chuyển động của chủ thể.</p><h3>Quay video 6.2K 30p – Không gian sáng tạo rộng hơn</h3><p>Fujifilm X-S20 hỗ trợ quay video 6.2K lên đến 30p với tỷ lệ khung hình 3:2 trong chế độ tương thích. Phương thức ghi hình này cung cấp thêm dữ liệu hình ảnh để người dùng lựa chọn bố cục trong quá trình hậu kỳ.</p><p>Người sáng tạo nội dung có thể tận dụng không gian khung hình để xuất video theo nhiều tỷ lệ khác nhau. Tuy nhiên, video độ phân giải cao yêu cầu dung lượng lưu trữ và năng lực xử lý lớn hơn.</p><h3>Quay 4K 60p và Full HD tốc độ khung hình cao</h3><p>Máy hỗ trợ quay 4K lên đến 60p trong những chế độ tương thích. Tốc độ khung hình cao cung cấp thêm lựa chọn khi ghi lại các nội dung có chuyển động nhanh hoặc thực hiện hiệu ứng chuyển động chậm.</p><p>Chế độ Full HD tốc độ khung hình cao mở rộng khả năng sáng tạo video. Góc nhìn, âm thanh và những tính năng hỗ trợ có thể thay đổi theo chế độ ghi hình.</p><h3>Video 10-bit và F-Log2 – Hỗ trợ hậu kỳ chuyên sâu</h3><p>X-S20 hỗ trợ ghi hình 10-bit với các định dạng tương thích, cung cấp thêm dữ liệu màu so với những định dạng có chiều sâu màu thấp hơn. Điều này hữu ích khi thực hiện điều chỉnh màu sắc và độ tương phản trong phần mềm dựng video.</p><p>Cấu hình F-Log2 hướng đến quy trình ghi hình và hậu kỳ chuyên sâu. Người dùng cần lựa chọn thiết lập phơi sáng và phương thức chỉnh màu phù hợp để khai thác tốt những khả năng của định dạng này.</p><h3>Chế độ Vlog – Công cụ dành cho người sáng tạo nội dung</h3><p>Chế độ Vlog cung cấp giao diện điều khiển thuận tiện cho những người thường xuyên tự quay video. Các chức năng tương thích có thể được truy cập trực tiếp trên màn hình, giúp đơn giản hóa quá trình thay đổi thiết lập.</p><p>Những tính năng hỗ trợ quay sản phẩm và điều chỉnh cách thể hiện hậu cảnh cung cấp thêm lựa chọn khi xây dựng nội dung giới thiệu hoặc đánh giá sản phẩm.</p><h3>Màn hình cảm ứng xoay lật và kính ngắm điện tử</h3><p>Màn hình cảm ứng xoay lật giúp người dùng quan sát bố cục khi quay vlog, chụp ở góc thấp hoặc sử dụng chân máy. Giao diện cảm ứng hỗ trợ lựa chọn điểm lấy nét và tương tác với các chức năng được hỗ trợ.</p><p>Kính ngắm điện tử cung cấp thêm phương thức quan sát khung hình khi chụp ngoài trời hoặc cần tập trung vào bố cục ảnh.</p><h3>Kết nối micro và tai nghe ngoài</h3><p>Fujifilm X-S20 cung cấp các cổng kết nối âm thanh tương thích để người sáng tạo có thể sử dụng micro ngoài và theo dõi âm thanh trong quá trình ghi hình.</p><p>Việc sử dụng thiết bị thu âm riêng mang đến thêm lựa chọn kiểm soát chất lượng âm thanh khi quay phỏng vấn, vlog hoặc giới thiệu sản phẩm.</p><h3>Hệ thống ống kính Fujifilm X-mount</h3><p>X-S20 sử dụng ngàm Fujifilm X, tương thích với nhiều ống kính XF, XC và những sản phẩm từ nhà sản xuất bên thứ ba được hỗ trợ. Hệ thống ống kính cung cấp nhiều lựa chọn tiêu cự, khẩu độ và kích thước.</p><p>Người dùng có thể bắt đầu với ống kính Kit đa dụng, sau đó mở rộng sang ống kính chân dung, góc rộng hoặc telephoto theo nhu cầu nhiếp ảnh.</p><h3>Pin NP-W235 – Hỗ trợ thời gian sử dụng dài</h3><p>Fujifilm X-S20 sử dụng pin NP-W235 có dung lượng lớn hơn pin của thế hệ X-S10. Theo thông số công bố, thiết bị có thể chụp khoảng 750 ảnh ở chế độ thường hoặc khoảng 800 ảnh ở chế độ tiết kiệm trong điều kiện thử nghiệm tương ứng.</p><p>Số lượng ảnh và thời lượng quay thực tế thay đổi theo độ sáng màn hình, chế độ lấy nét, kết nối không dây, nhiệt độ và tình trạng pin.</p><h3>Quản lý nhiệt và lưu trữ khi quay video</h3><p>Khi ghi hình ở độ phân giải cao hoặc trong thời gian dài, nhiệt độ môi trường và khả năng quản lý nhiệt có thể ảnh hưởng đến thời lượng ghi hình. Máy hỗ trợ phụ kiện làm mát tương thích dành cho những nhu cầu quay chuyên sâu.</p><p>Người dùng nên lựa chọn thẻ nhớ có dung lượng và tốc độ ghi đáp ứng yêu cầu của định dạng video. Các chế độ có bitrate cao thường tạo ra tệp dữ liệu lớn hơn.</p><h3>Kết nối không dây và Fujifilm XApp</h3><p>Máy ảnh hỗ trợ kết nối không dây với smartphone thông qua ứng dụng Fujifilm XApp tương thích. Người dùng có thể truyền hình ảnh, quản lý một số thiết lập và sử dụng các chức năng điều khiển từ xa được hỗ trợ.</p><h3>Fujifilm X-S20 phù hợp với những ai?</h3><ul><li><strong>Người yêu thích nhiếp ảnh:</strong> Muốn trải nghiệm màu phim đặc trưng của Fujifilm.</li><li><strong>Người sáng tạo nội dung:</strong> Cần máy ảnh có khả năng quay 4K và 6.2K.</li><li><strong>Người thường xuyên đi du lịch:</strong> Muốn hệ thống máy ảnh nhỏ gọn và linh hoạt.</li><li><strong>Người làm video:</strong> Cần các định dạng 10-bit và cấu hình màu phục vụ hậu kỳ.</li><li><strong>Người cần thiết bị đa dụng:</strong> Muốn kết hợp chụp ảnh và quay video trên cùng một thân máy.</li></ul><h3>Câu hỏi thường gặp về Fujifilm X-S20</h3><h4>Fujifilm X-S20 sử dụng cảm biến gì?</h4><p>Máy sử dụng cảm biến APS-C X-Trans CMOS 4 có độ phân giải 26,1 MP.</p><h4>X-S20 có chống rung trong thân máy không?</h4><p>Có. Thiết bị được trang bị hệ thống chống rung IBIS 5 trục với hiệu quả tối đa được công bố lên đến 7 stop trong điều kiện tương thích.</p><h4>Máy có quay video 6.2K không?</h4><p>Có. Fujifilm X-S20 hỗ trợ quay video 6.2K lên đến 30p trong chế độ tương ứng.</p><h4>Có thể sử dụng Film Simulation khi quay video không?</h4><p>Có. Những chế độ giả lập màu phim tương thích có thể được sử dụng để tạo phong cách màu sắc cho video.</p><h4>Máy có phù hợp với người mới bắt đầu không?</h4><p>Có. Máy hỗ trợ những chế độ tự động và giao diện điều khiển linh hoạt, đồng thời cung cấp các chức năng chuyên sâu để người dùng phát triển kỹ năng theo thời gian.</p><h4>Fujifilm X-S20 có chống nước hoàn toàn không?</h4><p>Không. Người dùng cần bảo vệ máy ảnh khỏi nước, bụi và những điều kiện môi trường không phù hợp.</p><h3>Có nên lựa chọn Fujifilm X-S20?</h3><p>Fujifilm X-S20 là lựa chọn đáng cân nhắc cho người cần máy ảnh mirrorless đa dụng có chất lượng hình ảnh tốt, khả năng chống rung trong thân máy, màu phim đặc trưng và các công cụ quay video nâng cao. Trước khi đặt hàng, người mua nên kiểm tra phiên bản thân máy hoặc bộ Kit, ống kính đi kèm, thẻ nhớ và những phụ kiện cần thiết để xây dựng hệ thống quay chụp phù hợp với nhu cầu thực tế.</p>')

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


IF OBJECT_ID(N'dbo.CATEGORY_ATTRIBUTE', N'U') IS NULL
   OR OBJECT_ID(N'dbo.SKU_ATTRIBUTE_VALUE', N'U') IS NULL
   OR OBJECT_ID(N'dbo.INVENTORY_MOVEMENT', N'U') IS NULL
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
