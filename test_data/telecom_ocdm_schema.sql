-- Telecommunications Data Model (Oracle Communications Data Model - OCDM Pattern)
-- Purpose: Manage customers, products, services, billing, orders, and network infrastructure
-- Based on: Oracle Communications Data Model Reference Architecture

-- Drop existing database if exists
DROP DATABASE IF EXISTS telecom_ocdm_db;
CREATE DATABASE telecom_ocdm_db;

\c telecom_ocdm_db;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";  -- For geographic data

-- =====================================================
-- REFERENCE TABLES (DWR_) - Static reference data
-- =====================================================

-- Geographic Hierarchy
CREATE TABLE dwr_geography (
    geography_id SERIAL PRIMARY KEY,
    geography_type VARCHAR(50) CHECK (geography_type IN ('COUNTRY', 'STATE', 'REGION', 'CITY', 'ZIP_CODE', 'COVERAGE_AREA')),
    geography_code VARCHAR(50) UNIQUE NOT NULL,
    geography_name VARCHAR(255) NOT NULL,
    parent_geography_id INTEGER REFERENCES dwr_geography(geography_id),
    iso_code VARCHAR(10),
    timezone VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_geography_type ON dwr_geography(geography_type);
CREATE INDEX idx_geography_parent ON dwr_geography(parent_geography_id);
COMMENT ON TABLE dwr_geography IS 'Geographic hierarchy for coverage and service areas';

-- Product Catalog
CREATE TABLE dwr_product_catalog (
    product_id SERIAL PRIMARY KEY,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_type VARCHAR(50) CHECK (product_type IN ('MOBILE', 'INTERNET', 'TV', 'LANDLINE', 'BUNDLE', 'VALUE_ADDED_SERVICE')),
    product_category VARCHAR(100),
    product_description TEXT,
    base_price NUMERIC(15, 2),
    pricing_model VARCHAR(50) CHECK (pricing_model IN ('FLAT_RATE', 'USAGE_BASED', 'TIERED', 'BUNDLED', 'FREEMIUM')),
    billing_frequency VARCHAR(20) CHECK (billing_frequency IN ('MONTHLY', 'QUARTERLY', 'ANNUAL', 'ONE_TIME', 'USAGE')),
    is_available BOOLEAN DEFAULT TRUE,
    launch_date DATE,
    end_of_life_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_product_type ON dwr_product_catalog(product_type);
CREATE INDEX idx_product_category ON dwr_product_catalog(product_category);
COMMENT ON TABLE dwr_product_catalog IS 'Product and service catalog definitions';

-- Service Plans
CREATE TABLE dwr_service_plans (
    plan_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES dwr_product_catalog(product_id),
    plan_code VARCHAR(50) UNIQUE NOT NULL,
    plan_name VARCHAR(255) NOT NULL,
    data_allowance_gb INTEGER,
    voice_minutes INTEGER,
    sms_allowance INTEGER,
    speed_mbps INTEGER,
    contract_term_months INTEGER,
    early_termination_fee NUMERIC(10, 2),
    overage_charge_per_gb NUMERIC(10, 4),
    is_unlimited BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_service_plan_product ON dwr_service_plans(product_id);
COMMENT ON TABLE dwr_service_plans IS 'Service plan specifications and allowances';

-- Network Infrastructure Types
CREATE TABLE dwr_network_technology (
    technology_id SERIAL PRIMARY KEY,
    technology_code VARCHAR(20) UNIQUE NOT NULL,
    technology_name VARCHAR(100) NOT NULL,
    technology_generation VARCHAR(10) CHECK (technology_generation IN ('2G', '3G', '4G', '5G', 'FIBER', 'CABLE', 'DSL', 'SATELLITE')),
    max_speed_mbps INTEGER,
    frequency_band VARCHAR(50),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE dwr_network_technology IS 'Network technology types and specifications';

-- =====================================================
-- CUSTOMER DOMAIN (DWB_) - Base customer data
-- =====================================================

CREATE TABLE dwb_customer (
    customer_id SERIAL PRIMARY KEY,
    customer_number VARCHAR(50) UNIQUE NOT NULL,
    customer_type VARCHAR(50) CHECK (customer_type IN ('INDIVIDUAL', 'BUSINESS', 'GOVERNMENT', 'ENTERPRISE')),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    business_name VARCHAR(255),
    date_of_birth DATE,
    ssn_tax_id VARCHAR(50),
    email VARCHAR(255),
    phone_primary VARCHAR(20),
    phone_secondary VARCHAR(20),
    preferred_language VARCHAR(50) DEFAULT 'ENGLISH',
    preferred_contact_method VARCHAR(20) CHECK (preferred_contact_method IN ('EMAIL', 'PHONE', 'SMS', 'MAIL')),
    customer_segment VARCHAR(50) CHECK (customer_segment IN ('PREMIUM', 'STANDARD', 'BASIC', 'VIP')),
    credit_score INTEGER,
    credit_class VARCHAR(20) CHECK (credit_class IN ('EXCELLENT', 'GOOD', 'FAIR', 'POOR')),
    kyc_status VARCHAR(20) CHECK (kyc_status IN ('VERIFIED', 'PENDING', 'FAILED', 'NOT_STARTED')),
    customer_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (customer_status IN ('ACTIVE', 'SUSPENDED', 'INACTIVE', 'CHURNED')),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customer_type ON dwb_customer(customer_type);
CREATE INDEX idx_customer_status ON dwb_customer(customer_status);
CREATE INDEX idx_customer_segment ON dwb_customer(customer_segment);
CREATE INDEX idx_customer_email ON dwb_customer(email);
COMMENT ON TABLE dwb_customer IS 'Customer master data and profiles';

-- Customer Addresses
CREATE TABLE dwb_customer_address (
    address_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES dwb_customer(customer_id) ON DELETE CASCADE,
    address_type VARCHAR(50) CHECK (address_type IN ('BILLING', 'SERVICE', 'MAILING', 'INSTALLATION')),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    geography_id INTEGER REFERENCES dwr_geography(geography_id),
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    is_primary BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customer_address_customer ON dwb_customer_address(customer_id);
CREATE INDEX idx_customer_address_type ON dwb_customer_address(address_type);
CREATE INDEX idx_customer_address_geo ON dwb_customer_address(geography_id);
COMMENT ON TABLE dwb_customer_address IS 'Customer addresses with address type tracking';

-- =====================================================
-- ACCOUNT DOMAIN (DWB_) - Billing accounts
-- =====================================================

CREATE TABLE dwb_account (
    account_id SERIAL PRIMARY KEY,
    account_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES dwb_customer(customer_id),
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) CHECK (account_type IN ('POSTPAID', 'PREPAID', 'HYBRID')),
    billing_cycle_day INTEGER CHECK (billing_cycle_day BETWEEN 1 AND 28),
    payment_method VARCHAR(50) CHECK (payment_method IN ('CREDIT_CARD', 'DEBIT_CARD', 'BANK_TRANSFER', 'CHECK', 'CASH', 'AUTOPAY')),
    credit_limit NUMERIC(15, 2),
    current_balance NUMERIC(15, 2) DEFAULT 0.00,
    outstanding_balance NUMERIC(15, 2) DEFAULT 0.00,
    deposit_amount NUMERIC(10, 2),
    account_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (account_status IN ('ACTIVE', 'SUSPENDED', 'DISCONNECTED', 'COLLECTIONS', 'CLOSED')),
    activation_date DATE NOT NULL,
    suspension_date DATE,
    closure_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_account_customer ON dwb_account(customer_id);
CREATE INDEX idx_account_status ON dwb_account(account_status);
CREATE INDEX idx_account_type ON dwb_account(account_type);
COMMENT ON TABLE dwb_account IS 'Billing accounts for customers';

-- =====================================================
-- SUBSCRIPTION DOMAIN (DWB_) - Service subscriptions
-- =====================================================

CREATE TABLE dwb_subscription (
    subscription_id SERIAL PRIMARY KEY,
    subscription_number VARCHAR(50) UNIQUE NOT NULL,
    account_id INTEGER NOT NULL REFERENCES dwb_account(account_id),
    customer_id INTEGER NOT NULL REFERENCES dwb_customer(customer_id),
    product_id INTEGER NOT NULL REFERENCES dwr_product_catalog(product_id),
    plan_id INTEGER REFERENCES dwr_service_plans(plan_id),
    msisdn VARCHAR(20),  -- Mobile number
    imsi VARCHAR(20),    -- International Mobile Subscriber Identity
    iccid VARCHAR(30),   -- SIM card number
    service_identifier VARCHAR(100),  -- Generic service ID (account number, MAC address, etc.)
    subscription_status VARCHAR(50) DEFAULT 'ACTIVE' CHECK (subscription_status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'CANCELLED', 'EXPIRED')),
    activation_date TIMESTAMP,
    suspension_date TIMESTAMP,
    cancellation_date TIMESTAMP,
    contract_start_date DATE,
    contract_end_date DATE,
    auto_renew BOOLEAN DEFAULT TRUE,
    monthly_recurring_charge NUMERIC(15, 2) NOT NULL,
    one_time_charge NUMERIC(15, 2) DEFAULT 0.00,
    promo_code VARCHAR(50),
    discount_percentage NUMERIC(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_subscription_account ON dwb_subscription(account_id);
CREATE INDEX idx_subscription_customer ON dwb_subscription(customer_id);
CREATE INDEX idx_subscription_product ON dwb_subscription(product_id);
CREATE INDEX idx_subscription_status ON dwb_subscription(subscription_status);
CREATE INDEX idx_subscription_msisdn ON dwb_subscription(msisdn);
COMMENT ON TABLE dwb_subscription IS 'Customer service subscriptions and activations';

-- =====================================================
-- ORDER MANAGEMENT (DWB_) - Service orders
-- =====================================================

CREATE TABLE dwb_service_order (
    order_id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES dwb_customer(customer_id),
    account_id INTEGER REFERENCES dwb_account(account_id),
    order_type VARCHAR(50) CHECK (order_type IN ('NEW_ACTIVATION', 'UPGRADE', 'DOWNGRADE', 'CHANGE_PLAN', 'PORT_IN', 'PORT_OUT', 'SUSPEND', 'RESUME', 'DISCONNECT')),
    order_status VARCHAR(50) DEFAULT 'PENDING' CHECK (order_status IN ('PENDING', 'VALIDATED', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED')),
    product_id INTEGER REFERENCES dwr_product_catalog(product_id),
    plan_id INTEGER REFERENCES dwr_service_plans(plan_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    requested_date TIMESTAMP,
    scheduled_date TIMESTAMP,
    completion_date TIMESTAMP,
    priority VARCHAR(20) CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    sales_channel VARCHAR(50) CHECK (sales_channel IN ('ONLINE', 'STORE', 'CALL_CENTER', 'PARTNER', 'AGENT')),
    sales_rep_id VARCHAR(50),
    installation_address_id INTEGER REFERENCES dwb_customer_address(address_id),
    installation_required BOOLEAN DEFAULT FALSE,
    order_value NUMERIC(15, 2),
    notes TEXT,
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_customer ON dwb_service_order(customer_id);
CREATE INDEX idx_order_account ON dwb_service_order(account_id);
CREATE INDEX idx_order_status ON dwb_service_order(order_status);
CREATE INDEX idx_order_type ON dwb_service_order(order_type);
CREATE INDEX idx_order_date ON dwb_service_order(order_date);
COMMENT ON TABLE dwb_service_order IS 'Customer service orders and provisioning requests';

-- =====================================================
-- BILLING DOMAIN (DWB_) - Invoices and charges
-- =====================================================

CREATE TABLE dwb_invoice (
    invoice_id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    account_id INTEGER NOT NULL REFERENCES dwb_account(account_id),
    customer_id INTEGER NOT NULL REFERENCES dwb_customer(customer_id),
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    invoice_amount NUMERIC(15, 2) NOT NULL,
    tax_amount NUMERIC(15, 2) DEFAULT 0.00,
    discount_amount NUMERIC(15, 2) DEFAULT 0.00,
    total_amount NUMERIC(15, 2) NOT NULL,
    paid_amount NUMERIC(15, 2) DEFAULT 0.00,
    balance_amount NUMERIC(15, 2) NOT NULL,
    invoice_status VARCHAR(50) DEFAULT 'UNPAID' CHECK (invoice_status IN ('DRAFT', 'ISSUED', 'UNPAID', 'PARTIALLY_PAID', 'PAID', 'OVERDUE', 'WRITTEN_OFF', 'DISPUTED')),
    payment_status VARCHAR(50) CHECK (payment_status IN ('PENDING', 'PAID', 'PARTIAL', 'FAILED', 'REFUNDED')),
    currency VARCHAR(10) DEFAULT 'USD',
    is_final BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_invoice_account ON dwb_invoice(account_id);
CREATE INDEX idx_invoice_customer ON dwb_invoice(customer_id);
CREATE INDEX idx_invoice_status ON dwb_invoice(invoice_status);
CREATE INDEX idx_invoice_date ON dwb_invoice(invoice_date);
CREATE INDEX idx_invoice_due_date ON dwb_invoice(due_date);
COMMENT ON TABLE dwb_invoice IS 'Customer billing invoices';

CREATE TABLE dwb_invoice_line_item (
    line_item_id SERIAL PRIMARY KEY,
    invoice_id INTEGER NOT NULL REFERENCES dwb_invoice(invoice_id) ON DELETE CASCADE,
    subscription_id INTEGER REFERENCES dwb_subscription(subscription_id),
    charge_type VARCHAR(50) CHECK (charge_type IN ('RECURRING', 'USAGE', 'ONE_TIME', 'OVERAGE', 'EQUIPMENT', 'TAX', 'FEE', 'ADJUSTMENT', 'DISCOUNT')),
    charge_description TEXT NOT NULL,
    charge_category VARCHAR(100),
    service_period_start DATE,
    service_period_end DATE,
    quantity NUMERIC(15, 4) DEFAULT 1,
    unit_price NUMERIC(15, 4) NOT NULL,
    line_amount NUMERIC(15, 2) NOT NULL,
    tax_amount NUMERIC(15, 2) DEFAULT 0.00,
    discount_amount NUMERIC(15, 2) DEFAULT 0.00,
    total_amount NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_line_item_invoice ON dwb_invoice_line_item(invoice_id);
CREATE INDEX idx_line_item_subscription ON dwb_invoice_line_item(subscription_id);
CREATE INDEX idx_line_item_type ON dwb_invoice_line_item(charge_type);
COMMENT ON TABLE dwb_invoice_line_item IS 'Detailed invoice line items and charges';

-- =====================================================
-- PAYMENT DOMAIN (DWB_) - Payment transactions
-- =====================================================

CREATE TABLE dwb_payment (
    payment_id SERIAL PRIMARY KEY,
    payment_number VARCHAR(50) UNIQUE NOT NULL,
    account_id INTEGER NOT NULL REFERENCES dwb_account(account_id),
    customer_id INTEGER NOT NULL REFERENCES dwb_customer(customer_id),
    invoice_id INTEGER REFERENCES dwb_invoice(invoice_id),
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_amount NUMERIC(15, 2) NOT NULL CHECK (payment_amount > 0),
    payment_method VARCHAR(50) CHECK (payment_method IN ('CREDIT_CARD', 'DEBIT_CARD', 'BANK_TRANSFER', 'CHECK', 'CASH', 'DIGITAL_WALLET', 'AUTOPAY')),
    payment_channel VARCHAR(50) CHECK (payment_channel IN ('ONLINE', 'STORE', 'PHONE', 'MAIL', 'AUTO', 'THIRD_PARTY')),
    payment_status VARCHAR(50) DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'AUTHORIZED', 'COMPLETED', 'FAILED', 'REVERSED', 'REFUNDED')),
    transaction_id VARCHAR(100) UNIQUE,
    payment_processor VARCHAR(100),
    card_last_four VARCHAR(4),
    confirmation_number VARCHAR(100),
    failure_reason TEXT,
    processed_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_account ON dwb_payment(account_id);
CREATE INDEX idx_payment_customer ON dwb_payment(customer_id);
CREATE INDEX idx_payment_invoice ON dwb_payment(invoice_id);
CREATE INDEX idx_payment_date ON dwb_payment(payment_date);
CREATE INDEX idx_payment_status ON dwb_payment(payment_status);
COMMENT ON TABLE dwb_payment IS 'Customer payment transactions';

-- =====================================================
-- USAGE DOMAIN (DWB_) - Usage records
-- =====================================================

CREATE TABLE dwb_usage_detail_record (
    udr_id BIGSERIAL PRIMARY KEY,
    subscription_id INTEGER NOT NULL REFERENCES dwb_subscription(subscription_id),
    account_id INTEGER NOT NULL REFERENCES dwb_account(account_id),
    usage_date TIMESTAMP NOT NULL,
    usage_type VARCHAR(50) CHECK (usage_type IN ('VOICE', 'SMS', 'DATA', 'MMS', 'ROAMING', 'INTERNATIONAL')),
    call_type VARCHAR(50) CHECK (call_type IN ('OUTGOING', 'INCOMING', 'FORWARDED', 'ROAMING')),
    originating_number VARCHAR(20),
    destination_number VARCHAR(20),
    duration_seconds INTEGER,
    data_volume_mb NUMERIC(15, 6),
    sms_count INTEGER,
    is_roaming BOOLEAN DEFAULT FALSE,
    is_international BOOLEAN DEFAULT FALSE,
    roaming_country VARCHAR(100),
    network_technology VARCHAR(20),
    cell_id VARCHAR(50),
    cost_amount NUMERIC(15, 6),
    charge_amount NUMERIC(15, 6),
    rating_status VARCHAR(20) CHECK (rating_status IN ('UNRATED', 'RATED', 'BILLED', 'ERROR')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Partitioning by month for performance (example for PostgreSQL 10+)
-- In production, you would create partitions by usage_date
CREATE INDEX idx_udr_subscription ON dwb_usage_detail_record(subscription_id);
CREATE INDEX idx_udr_account ON dwb_usage_detail_record(account_id);
CREATE INDEX idx_udr_usage_date ON dwb_usage_detail_record(usage_date);
CREATE INDEX idx_udr_usage_type ON dwb_usage_detail_record(usage_type);
COMMENT ON TABLE dwb_usage_detail_record IS 'Detailed usage records for voice, data, and SMS';

-- =====================================================
-- NETWORK DOMAIN (DWB_) - Network infrastructure
-- =====================================================

CREATE TABLE dwb_network_element (
    element_id SERIAL PRIMARY KEY,
    element_code VARCHAR(50) UNIQUE NOT NULL,
    element_name VARCHAR(255) NOT NULL,
    element_type VARCHAR(50) CHECK (element_type IN ('TOWER', 'BASE_STATION', 'ROUTER', 'SWITCH', 'GATEWAY', 'SERVER', 'ANTENNA')),
    technology_id INTEGER REFERENCES dwr_network_technology(technology_id),
    geography_id INTEGER REFERENCES dwr_geography(geography_id),
    vendor VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),
    ip_address INET,
    mac_address VARCHAR(17),
    capacity INTEGER,
    status VARCHAR(20) CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE', 'DECOMMISSIONED')),
    installation_date DATE,
    last_maintenance_date DATE,
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_network_element_type ON dwb_network_element(element_type);
CREATE INDEX idx_network_element_tech ON dwb_network_element(technology_id);
CREATE INDEX idx_network_element_geo ON dwb_network_element(geography_id);
CREATE INDEX idx_network_element_status ON dwb_network_element(status);
COMMENT ON TABLE dwb_network_element IS 'Physical and logical network infrastructure elements';

-- =====================================================
-- DEVICE DOMAIN (DWB_) - Customer devices
-- =====================================================

CREATE TABLE dwb_device (
    device_id SERIAL PRIMARY KEY,
    subscription_id INTEGER REFERENCES dwb_subscription(subscription_id),
    customer_id INTEGER REFERENCES dwb_customer(customer_id),
    device_type VARCHAR(50) CHECK (device_type IN ('SMARTPHONE', 'TABLET', 'MODEM', 'ROUTER', 'STB', 'IOT_DEVICE', 'WEARABLE')),
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    imei VARCHAR(20) UNIQUE,
    serial_number VARCHAR(100),
    mac_address VARCHAR(17),
    firmware_version VARCHAR(50),
    os_version VARCHAR(50),
    purchase_date DATE,
    warranty_expiry_date DATE,
    device_status VARCHAR(20) CHECK (device_status IN ('ACTIVE', 'INACTIVE', 'LOST', 'STOLEN', 'DAMAGED', 'RETURNED')),
    is_financed BOOLEAN DEFAULT FALSE,
    financing_balance NUMERIC(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_device_subscription ON dwb_device(subscription_id);
CREATE INDEX idx_device_customer ON dwb_device(customer_id);
CREATE INDEX idx_device_imei ON dwb_device(imei);
CREATE INDEX idx_device_status ON dwb_device(device_status);
COMMENT ON TABLE dwb_device IS 'Customer devices and equipment';

-- =====================================================
-- TROUBLE TICKET DOMAIN (DWB_) - Customer support
-- =====================================================

CREATE TABLE dwb_trouble_ticket (
    ticket_id SERIAL PRIMARY KEY,
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES dwb_customer(customer_id),
    account_id INTEGER REFERENCES dwb_account(account_id),
    subscription_id INTEGER REFERENCES dwb_subscription(subscription_id),
    ticket_type VARCHAR(50) CHECK (ticket_type IN ('TECHNICAL', 'BILLING', 'SERVICE', 'COMPLAINT', 'REQUEST', 'INQUIRY')),
    ticket_category VARCHAR(100),
    priority VARCHAR(20) CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    ticket_status VARCHAR(50) DEFAULT 'OPEN' CHECK (ticket_status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'PENDING_CUSTOMER', 'RESOLVED', 'CLOSED', 'CANCELLED')),
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    resolution TEXT,
    opened_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_to VARCHAR(255),
    assigned_date TIMESTAMP,
    resolved_date TIMESTAMP,
    closed_date TIMESTAMP,
    sla_due_date TIMESTAMP,
    channel VARCHAR(50) CHECK (channel IN ('PHONE', 'EMAIL', 'CHAT', 'STORE', 'SOCIAL_MEDIA', 'APP')),
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ticket_customer ON dwb_trouble_ticket(customer_id);
CREATE INDEX idx_ticket_account ON dwb_trouble_ticket(account_id);
CREATE INDEX idx_ticket_status ON dwb_trouble_ticket(ticket_status);
CREATE INDEX idx_ticket_priority ON dwb_trouble_ticket(priority);
CREATE INDEX idx_ticket_opened_date ON dwb_trouble_ticket(opened_date);
COMMENT ON TABLE dwb_trouble_ticket IS 'Customer support tickets and issue tracking';

-- =====================================================
-- AUDIT LOG
-- =====================================================

CREATE TABLE dwb_audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(20) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'VIEW')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(255) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

CREATE INDEX idx_audit_table ON dwb_audit_log(table_name, record_id);
CREATE INDEX idx_audit_date ON dwb_audit_log(changed_at);
CREATE INDEX idx_audit_user ON dwb_audit_log(changed_by);
COMMENT ON TABLE dwb_audit_log IS 'Comprehensive audit trail for all data changes';

-- =====================================================
-- AGGREGATE TABLES (DWA_) - Pre-computed analytics
-- =====================================================

CREATE TABLE dwa_customer_usage_summary (
    summary_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES dwb_customer(customer_id),
    subscription_id INTEGER NOT NULL REFERENCES dwb_subscription(subscription_id),
    summary_month DATE NOT NULL,
    voice_minutes_used INTEGER DEFAULT 0,
    sms_count_used INTEGER DEFAULT 0,
    data_mb_used NUMERIC(15, 2) DEFAULT 0,
    roaming_charges NUMERIC(15, 2) DEFAULT 0,
    international_charges NUMERIC(15, 2) DEFAULT 0,
    total_usage_charges NUMERIC(15, 2) DEFAULT 0,
    overage_charges NUMERIC(15, 2) DEFAULT 0,
    plan_allowance_utilized_pct NUMERIC(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_usage_summary_unique ON dwa_customer_usage_summary(customer_id, subscription_id, summary_month);
COMMENT ON TABLE dwa_customer_usage_summary IS 'Monthly aggregated usage summary per customer subscription';

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View: Customer 360 Summary
CREATE VIEW v_customer_360 AS
SELECT
    c.customer_id,
    c.customer_number,
    CASE
        WHEN c.customer_type = 'INDIVIDUAL' THEN c.first_name || ' ' || c.last_name
        ELSE c.business_name
    END as customer_name,
    c.customer_type,
    c.customer_segment,
    c.customer_status,
    c.email,
    c.phone_primary,
    COUNT(DISTINCT a.account_id) as total_accounts,
    COUNT(DISTINCT s.subscription_id) as total_subscriptions,
    COUNT(DISTINCT CASE WHEN s.subscription_status = 'ACTIVE' THEN s.subscription_id END) as active_subscriptions,
    SUM(a.current_balance) as total_balance,
    MAX(c.last_activity_date) as last_activity_date,
    c.registration_date
FROM dwb_customer c
LEFT JOIN dwb_account a ON c.customer_id = a.customer_id
LEFT JOIN dwb_subscription s ON c.customer_id = s.customer_id
GROUP BY c.customer_id;

COMMENT ON VIEW v_customer_360 IS 'Comprehensive customer overview with accounts and subscriptions';

-- View: Active Subscriptions with Product Details
CREATE VIEW v_active_subscriptions AS
SELECT
    s.subscription_id,
    s.subscription_number,
    s.msisdn,
    c.customer_number,
    CASE
        WHEN c.customer_type = 'INDIVIDUAL' THEN c.first_name || ' ' || c.last_name
        ELSE c.business_name
    END as customer_name,
    a.account_number,
    p.product_name,
    p.product_type,
    sp.plan_name,
    s.monthly_recurring_charge,
    s.activation_date,
    s.contract_end_date,
    s.subscription_status
FROM dwb_subscription s
JOIN dwb_customer c ON s.customer_id = c.customer_id
JOIN dwb_account a ON s.account_id = a.account_id
JOIN dwr_product_catalog p ON s.product_id = p.product_id
LEFT JOIN dwr_service_plans sp ON s.plan_id = sp.plan_id
WHERE s.subscription_status = 'ACTIVE';

COMMENT ON VIEW v_active_subscriptions IS 'All active customer subscriptions with product details';

-- View: Outstanding Balances
CREATE VIEW v_outstanding_balances AS
SELECT
    a.account_id,
    a.account_number,
    c.customer_number,
    CASE
        WHEN c.customer_type = 'INDIVIDUAL' THEN c.first_name || ' ' || c.last_name
        ELSE c.business_name
    END as customer_name,
    a.account_status,
    a.current_balance,
    a.outstanding_balance,
    COUNT(i.invoice_id) as total_invoices,
    COUNT(CASE WHEN i.invoice_status = 'OVERDUE' THEN 1 END) as overdue_invoices,
    SUM(CASE WHEN i.invoice_status IN ('UNPAID', 'OVERDUE') THEN i.balance_amount ELSE 0 END) as total_due
FROM dwb_account a
JOIN dwb_customer c ON a.customer_id = c.customer_id
LEFT JOIN dwb_invoice i ON a.account_id = i.account_id
WHERE a.outstanding_balance > 0
GROUP BY a.account_id, c.customer_id;

COMMENT ON VIEW v_outstanding_balances IS 'Accounts with outstanding balances and invoice details';

-- View: Service Order Pipeline
CREATE VIEW v_service_order_pipeline AS
SELECT
    o.order_id,
    o.order_number,
    o.order_type,
    o.order_status,
    o.priority,
    c.customer_number,
    CASE
        WHEN c.customer_type = 'INDIVIDUAL' THEN c.first_name || ' ' || c.last_name
        ELSE c.business_name
    END as customer_name,
    p.product_name,
    sp.plan_name,
    o.order_date,
    o.scheduled_date,
    o.sales_channel,
    o.order_value,
    EXTRACT(DAY FROM (NOW() - o.order_date)) as days_pending
FROM dwb_service_order o
JOIN dwb_customer c ON o.customer_id = c.customer_id
LEFT JOIN dwr_product_catalog p ON o.product_id = p.product_id
LEFT JOIN dwr_service_plans sp ON o.plan_id = sp.plan_id
WHERE o.order_status NOT IN ('COMPLETED', 'CANCELLED')
ORDER BY
    CASE o.priority
        WHEN 'URGENT' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'NORMAL' THEN 3
        WHEN 'LOW' THEN 4
    END,
    o.order_date;

COMMENT ON VIEW v_service_order_pipeline IS 'Pending and in-progress service orders with priority';