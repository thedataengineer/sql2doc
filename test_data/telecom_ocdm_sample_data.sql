-- Telecommunications OCDM Sample Data
-- Purpose: Populate test data for telecom operational database

\c telecom_ocdm_db;

-- =====================================================
-- REFERENCE DATA - Geography
-- =====================================================

INSERT INTO dwr_geography (geography_type, geography_code, geography_name, parent_geography_id, iso_code, timezone) VALUES
('COUNTRY', 'USA', 'United States', NULL, 'US', 'America/New_York'),
('STATE', 'IL', 'Illinois', 1, 'US-IL', 'America/Chicago'),
('STATE', 'CA', 'California', 1, 'US-CA', 'America/Los_Angeles'),
('STATE', 'NY', 'New York', 1, 'US-NY', 'America/New_York'),
('CITY', 'CHI', 'Chicago', 2, NULL, 'America/Chicago'),
('CITY', 'LAX', 'Los Angeles', 3, NULL, 'America/Los_Angeles'),
('CITY', 'NYC', 'New York City', 4, NULL, 'America/New_York'),
('ZIP_CODE', '60601', 'Chicago Downtown', 5, NULL, 'America/Chicago'),
('ZIP_CODE', '90001', 'Los Angeles Central', 6, NULL, 'America/Los_Angeles'),
('ZIP_CODE', '10001', 'Manhattan', 7, NULL, 'America/New_York'),
('COVERAGE_AREA', 'MIDWEST', 'Midwest Region', 1, NULL, 'America/Chicago'),
('COVERAGE_AREA', 'WEST', 'West Coast Region', 1, NULL, 'America/Los_Angeles'),
('COVERAGE_AREA', 'EAST', 'East Coast Region', 1, NULL, 'America/New_York');

-- =====================================================
-- REFERENCE DATA - Network Technology
-- =====================================================

INSERT INTO dwr_network_technology (technology_code, technology_name, technology_generation, max_speed_mbps, frequency_band) VALUES
('5G-NR', '5G New Radio', '5G', 10000, 'n41 (2.5 GHz)'),
('LTE-A', 'LTE Advanced', '4G', 1000, 'Band 2/4/12'),
('LTE', 'Long Term Evolution', '4G', 300, 'Band 2/4/12'),
('HSPA+', 'HSPA Plus', '3G', 42, '1900/2100 MHz'),
('FIBER', 'Fiber Optic', 'FIBER', 10000, 'N/A'),
('CABLE', 'Cable Internet', 'CABLE', 1000, 'N/A'),
('DSL', 'Digital Subscriber Line', 'DSL', 100, 'N/A');

-- =====================================================
-- REFERENCE DATA - Product Catalog
-- =====================================================

INSERT INTO dwr_product_catalog (product_code, product_name, product_type, product_category, product_description, base_price, pricing_model, billing_frequency, launch_date) VALUES
('MOB-UNL-5G', 'Unlimited 5G Premium', 'MOBILE', 'POSTPAID', 'Unlimited 5G data with premium features', 85.00, 'FLAT_RATE', 'MONTHLY', '2023-01-01'),
('MOB-20GB-4G', '20GB 4G Plan', 'MOBILE', 'POSTPAID', '20GB high-speed data with unlimited talk and text', 55.00, 'FLAT_RATE', 'MONTHLY', '2022-06-01'),
('MOB-PREPAID-10', 'Prepaid 10GB', 'MOBILE', 'PREPAID', '10GB prepaid plan', 40.00, 'FLAT_RATE', 'MONTHLY', '2021-01-01'),
('INT-FIBER-1G', 'Fiber Internet 1Gbps', 'INTERNET', 'RESIDENTIAL', 'Gigabit fiber internet', 79.99, 'FLAT_RATE', 'MONTHLY', '2023-03-01'),
('INT-CABLE-500', 'Cable Internet 500Mbps', 'INTERNET', 'RESIDENTIAL', '500Mbps cable internet', 59.99, 'FLAT_RATE', 'MONTHLY', '2022-01-01'),
('TV-BASIC', 'Basic TV Package', 'TV', 'RESIDENTIAL', '100+ channels basic package', 49.99, 'FLAT_RATE', 'MONTHLY', '2020-01-01'),
('TV-PREMIUM', 'Premium TV Package', 'TV', 'RESIDENTIAL', '300+ channels with premium content', 99.99, 'FLAT_RATE', 'MONTHLY', '2020-01-01'),
('BUNDLE-TRIPLE', 'Triple Play Bundle', 'BUNDLE', 'RESIDENTIAL', 'Internet + TV + Phone bundle', 129.99, 'BUNDLED', 'MONTHLY', '2023-01-01'),
('VAS-HOTSPOT', 'Mobile Hotspot Add-on', 'VALUE_ADDED_SERVICE', 'ADDON', '20GB mobile hotspot', 15.00, 'FLAT_RATE', 'MONTHLY', '2022-01-01'),
('VAS-INTL', 'International Calling', 'VALUE_ADDED_SERVICE', 'ADDON', 'Unlimited international calls to 50 countries', 20.00, 'FLAT_RATE', 'MONTHLY', '2021-01-01');

-- =====================================================
-- REFERENCE DATA - Service Plans
-- =====================================================

INSERT INTO dwr_service_plans (product_id, plan_code, plan_name, data_allowance_gb, voice_minutes, sms_allowance, speed_mbps, contract_term_months, early_termination_fee, overage_charge_per_gb, is_unlimited) VALUES
(1, 'PLAN-UNL-5G', 'Unlimited 5G Premium Plan', NULL, NULL, NULL, 1000, 24, 350.00, 0, TRUE),
(2, 'PLAN-20GB-4G', '20GB 4G Plan', 20, NULL, NULL, 300, 12, 150.00, 15.00, FALSE),
(3, 'PLAN-PRE-10', 'Prepaid 10GB Plan', 10, NULL, NULL, 100, 0, 0, 10.00, FALSE),
(4, 'PLAN-FIB-1G', 'Fiber 1Gbps Plan', NULL, NULL, NULL, 1000, 24, 200.00, 0, TRUE),
(5, 'PLAN-CAB-500', 'Cable 500Mbps Plan', NULL, NULL, NULL, 500, 12, 100.00, 0, TRUE);

-- =====================================================
-- CUSTOMERS
-- =====================================================

INSERT INTO dwb_customer (customer_number, customer_type, first_name, last_name, business_name, date_of_birth, ssn_tax_id, email, phone_primary, preferred_contact_method, customer_segment, credit_score, credit_class, kyc_status, customer_status, registration_date, last_activity_date) VALUES
('CUST-000001', 'INDIVIDUAL', 'John', 'Anderson', NULL, '1985-03-15', '123-45-6789', 'john.anderson@email.com', '312-555-0001', 'EMAIL', 'PREMIUM', 780, 'EXCELLENT', 'VERIFIED', 'ACTIVE', '2022-01-15 10:30:00', '2024-02-20 14:22:00'),
('CUST-000002', 'INDIVIDUAL', 'Sarah', 'Martinez', NULL, '1990-07-22', '234-56-7890', 'sarah.martinez@email.com', '312-555-0002', 'SMS', 'STANDARD', 720, 'GOOD', 'VERIFIED', 'ACTIVE', '2022-03-20 09:15:00', '2024-02-19 11:45:00'),
('CUST-000003', 'BUSINESS', 'Michael', 'Chen', 'Chen Tech Solutions', '1978-11-05', '34-5678901', 'michael@chentech.com', '312-555-0003', 'EMAIL', 'PREMIUM', 810, 'EXCELLENT', 'VERIFIED', 'ACTIVE', '2021-06-10 14:00:00', '2024-02-21 09:30:00'),
('CUST-000004', 'INDIVIDUAL', 'Emily', 'Johnson', NULL, '1995-02-14', '456-78-9012', 'emily.j@email.com', '213-555-0001', 'EMAIL', 'BASIC', 650, 'FAIR', 'VERIFIED', 'ACTIVE', '2023-05-12 11:20:00', '2024-02-18 16:55:00'),
('CUST-000005', 'INDIVIDUAL', 'David', 'Williams', NULL, '1982-09-30', '567-89-0123', 'dwilliams@email.com', '212-555-0001', 'PHONE', 'STANDARD', 690, 'GOOD', 'VERIFIED', 'ACTIVE', '2022-08-05 13:45:00', '2024-02-20 10:15:00'),
('CUST-000006', 'BUSINESS', NULL, NULL, 'Global Enterprises Inc', NULL, '45-6789012', 'billing@globalenterprises.com', '312-555-0100', 'EMAIL', 'VIP', 850, 'EXCELLENT', 'VERIFIED', 'ACTIVE', '2020-11-20 08:00:00', '2024-02-21 15:30:00'),
('CUST-000007', 'INDIVIDUAL', 'Lisa', 'Thompson', NULL, '1988-06-18', '678-90-1234', 'lisa.thompson@email.com', '213-555-0002', 'SMS', 'STANDARD', 700, 'GOOD', 'VERIFIED', 'ACTIVE', '2023-01-22 10:00:00', '2024-02-19 14:20:00'),
('CUST-000008', 'INDIVIDUAL', 'Robert', 'Garcia', NULL, '1975-12-25', '789-01-2345', 'rgarcia@email.com', '312-555-0004', 'EMAIL', 'PREMIUM', 760, 'GOOD', 'VERIFIED', 'ACTIVE', '2021-09-15 12:30:00', '2024-02-20 17:40:00'),
('CUST-000009', 'INDIVIDUAL', 'Jennifer', 'Lee', NULL, '1992-04-08', '890-12-3456', 'jlee@email.com', '212-555-0002', 'EMAIL', 'BASIC', 620, 'FAIR', 'VERIFIED', 'SUSPENDED', '2023-07-30 09:45:00', '2024-01-10 11:00:00'),
('CUST-000010', 'INDIVIDUAL', 'Thomas', 'Brown', NULL, '1980-10-12', '901-23-4567', 'tbrown@email.com', '213-555-0003', 'PHONE', 'STANDARD', 710, 'GOOD', 'VERIFIED', 'ACTIVE', '2022-12-05 15:20:00', '2024-02-21 13:10:00');

-- =====================================================
-- CUSTOMER ADDRESSES
-- =====================================================

INSERT INTO dwb_customer_address (customer_id, address_type, address_line1, city, state, zip_code, geography_id, latitude, longitude, is_primary, is_verified, valid_from) VALUES
(1, 'BILLING', '123 N Michigan Ave', 'Chicago', 'IL', '60601', 8, 41.8781, -87.6298, TRUE, TRUE, '2022-01-15'),
(1, 'SERVICE', '123 N Michigan Ave', 'Chicago', 'IL', '60601', 8, 41.8781, -87.6298, TRUE, TRUE, '2022-01-15'),
(2, 'BILLING', '456 W Lake St', 'Chicago', 'IL', '60606', 8, 41.8855, -87.6396, TRUE, TRUE, '2022-03-20'),
(3, 'BILLING', '789 S Wacker Dr Suite 500', 'Chicago', 'IL', '60606', 8, 41.8781, -87.6369, TRUE, TRUE, '2021-06-10'),
(4, 'BILLING', '321 S Spring St', 'Los Angeles', 'CA', '90013', 9, 34.0522, -118.2437, TRUE, TRUE, '2023-05-12'),
(5, 'BILLING', '147 W 42nd St', 'New York', 'NY', '10036', 10, 40.7580, -73.9855, TRUE, TRUE, '2022-08-05'),
(6, 'BILLING', '500 N LaSalle Dr', 'Chicago', 'IL', '60654', 8, 41.8906, -87.6328, TRUE, TRUE, '2020-11-20'),
(7, 'BILLING', '258 Broadway', 'Los Angeles', 'CA', '90012', 9, 34.0574, -118.2402, TRUE, TRUE, '2023-01-22'),
(8, 'BILLING', '369 E Randolph St', 'Chicago', 'IL', '60601', 8, 41.8847, -87.6197, TRUE, TRUE, '2021-09-15'),
(9, 'BILLING', '741 5th Ave', 'New York', 'NY', '10022', 10, 40.7614, -73.9776, TRUE, TRUE, '2023-07-30'),
(10, 'BILLING', '852 W Sunset Blvd', 'Los Angeles', 'CA', '90012', 9, 34.0775, -118.2420, TRUE, TRUE, '2022-12-05');

-- =====================================================
-- ACCOUNTS
-- =====================================================

INSERT INTO dwb_account (account_number, customer_id, account_name, account_type, billing_cycle_day, payment_method, credit_limit, current_balance, outstanding_balance, account_status, activation_date) VALUES
('ACC-100001', 1, 'John Anderson - Personal', 'POSTPAID', 15, 'AUTOPAY', 2000.00, 85.00, 0.00, 'ACTIVE', '2022-01-15'),
('ACC-100002', 2, 'Sarah Martinez - Personal', 'POSTPAID', 20, 'CREDIT_CARD', 1500.00, 55.00, 0.00, 'ACTIVE', '2022-03-20'),
('ACC-100003', 3, 'Chen Tech Solutions - Business', 'POSTPAID', 1, 'BANK_TRANSFER', 10000.00, 450.00, 0.00, 'ACTIVE', '2021-06-10'),
('ACC-100004', 4, 'Emily Johnson - Personal', 'PREPAID', NULL, 'DEBIT_CARD', 500.00, 40.00, 0.00, 'ACTIVE', '2023-05-12'),
('ACC-100005', 5, 'David Williams - Personal', 'POSTPAID', 5, 'CREDIT_CARD', 1500.00, 139.98, 0.00, 'ACTIVE', '2022-08-05'),
('ACC-100006', 6, 'Global Enterprises - Corporate', 'POSTPAID', 1, 'BANK_TRANSFER', 50000.00, 1250.00, 0.00, 'ACTIVE', '2020-11-20'),
('ACC-100007', 7, 'Lisa Thompson - Personal', 'POSTPAID', 22, 'AUTOPAY', 1500.00, 55.00, 0.00, 'ACTIVE', '2023-01-22'),
('ACC-100008', 8, 'Robert Garcia - Personal', 'POSTPAID', 10, 'CREDIT_CARD', 2000.00, 164.99, 0.00, 'ACTIVE', '2021-09-15'),
('ACC-100009', 9, 'Jennifer Lee - Personal', 'POSTPAID', 25, 'DEBIT_CARD', 1000.00, 55.00, 165.00, 'SUSPENDED', '2023-07-30'),
('ACC-100010', 10, 'Thomas Brown - Personal', 'POSTPAID', 12, 'CREDIT_CARD', 1500.00, 79.99, 0.00, 'ACTIVE', '2022-12-05');

-- =====================================================
-- SUBSCRIPTIONS
-- =====================================================

INSERT INTO dwb_subscription (subscription_number, account_id, customer_id, product_id, plan_id, msisdn, imsi, iccid, subscription_status, activation_date, contract_start_date, contract_end_date, auto_renew, monthly_recurring_charge, one_time_charge, discount_percentage) VALUES
('SUB-200001', 1, 1, 1, 1, '+13125550001', '310410123456789', '89011234567890123456', 'ACTIVE', '2022-01-15 12:00:00', '2022-01-15', '2024-01-15', TRUE, 85.00, 50.00, 0),
('SUB-200002', 2, 2, 2, 2, '+13125550002', '310410234567890', '89011234567890234567', 'ACTIVE', '2022-03-20 10:00:00', '2022-03-20', '2023-03-20', TRUE, 55.00, 0.00, 0),
('SUB-200003', 3, 3, 1, 1, '+13125550003', '310410345678901', '89011234567890345678', 'ACTIVE', '2021-06-10 14:30:00', '2021-06-10', '2023-06-10', TRUE, 85.00, 0.00, 15),
('SUB-200004', 3, 3, 1, 1, '+13125550103', '310410345678902', '89011234567890345679', 'ACTIVE', '2021-06-10 14:45:00', '2021-06-10', '2023-06-10', TRUE, 85.00, 0.00, 15),
('SUB-200005', 3, 3, 9, NULL, NULL, NULL, NULL, 'ACTIVE', '2021-07-01 09:00:00', '2021-07-01', NULL, TRUE, 15.00, 0.00, 0),
('SUB-200006', 4, 4, 3, 3, '+12135550001', '310410456789012', '89011234567890456789', 'ACTIVE', '2023-05-12 11:30:00', NULL, NULL, FALSE, 40.00, 40.00, 0),
('SUB-200007', 5, 5, 4, 4, NULL, NULL, NULL, 'ACTIVE', '2022-08-05 15:00:00', '2022-08-05', '2024-08-05', TRUE, 79.99, 99.99, 0),
('SUB-200008', 5, 5, 6, NULL, NULL, NULL, NULL, 'ACTIVE', '2022-08-05 15:15:00', '2022-08-05', '2023-08-05', TRUE, 49.99, 0.00, 10),
('SUB-200009', 6, 6, 1, 1, '+13125550100', '310410567890123', '89011234567890567890', 'ACTIVE', '2020-11-20 09:00:00', '2020-11-20', '2024-11-20', TRUE, 75.00, 0.00, 20),
('SUB-200010', 7, 7, 2, 2, '+12135550002', '310410678901234', '89011234567890678901', 'ACTIVE', '2023-01-22 11:00:00', '2023-01-22', '2024-01-22', TRUE, 55.00, 0.00, 0),
('SUB-200011', 8, 8, 1, 1, '+13125550004', '310410789012345', '89011234567890789012', 'ACTIVE', '2021-09-15 13:00:00', '2021-09-15', '2023-09-15', TRUE, 85.00, 0.00, 0),
('SUB-200012', 8, 8, 4, 4, NULL, NULL, NULL, 'ACTIVE', '2021-09-15 13:30:00', '2021-09-15', '2023-09-15', TRUE, 79.99, 99.99, 0),
('SUB-200013', 9, 9, 2, 2, '+12125550002', '310410890123456', '89011234567890890123', 'SUSPENDED', '2023-07-30 10:00:00', '2023-07-30', '2024-07-30', TRUE, 55.00, 0.00, 0),
('SUB-200014', 10, 10, 4, 4, NULL, NULL, NULL, 'ACTIVE', '2022-12-05 16:00:00', '2022-12-05', '2024-12-05', TRUE, 79.99, 99.99, 0);

-- =====================================================
-- SERVICE ORDERS
-- =====================================================

INSERT INTO dwb_service_order (order_number, customer_id, account_id, order_type, order_status, product_id, plan_id, order_date, requested_date, completion_date, priority, sales_channel, installation_address_id, installation_required, order_value, created_by) VALUES
('ORD-300001', 1, 1, 'NEW_ACTIVATION', 'COMPLETED', 1, 1, '2022-01-10 09:00:00', '2022-01-15 10:00:00', '2022-01-15 12:00:00', 'NORMAL', 'ONLINE', 2, FALSE, 135.00, 'web_portal'),
('ORD-300002', 2, 2, 'NEW_ACTIVATION', 'COMPLETED', 2, 2, '2022-03-18 14:30:00', '2022-03-20 09:00:00', '2022-03-20 10:00:00', 'NORMAL', 'STORE', NULL, FALSE, 55.00, 'store_001'),
('ORD-300003', 3, 3, 'NEW_ACTIVATION', 'COMPLETED', 1, 1, '2021-06-08 10:00:00', '2021-06-10 12:00:00', '2021-06-10 14:45:00', 'HIGH', 'AGENT', 3, FALSE, 170.00, 'agent_025'),
('ORD-300004', 5, 5, 'NEW_ACTIVATION', 'COMPLETED', 4, 4, '2022-08-01 11:00:00', '2022-08-05 14:00:00', '2022-08-05 15:00:00', 'NORMAL', 'ONLINE', 5, TRUE, 179.98, 'web_portal'),
('ORD-300005', 8, 8, 'UPGRADE', 'COMPLETED', 1, 1, '2023-09-10 13:00:00', '2023-09-15 10:00:00', '2023-09-15 11:30:00', 'NORMAL', 'CALL_CENTER', NULL, FALSE, 85.00, 'agent_142'),
('ORD-300006', 10, 10, 'NEW_ACTIVATION', 'COMPLETED', 4, 4, '2022-12-01 15:00:00', '2022-12-05 13:00:00', '2022-12-05 16:00:00', 'HIGH', 'ONLINE', 11, TRUE, 179.98, 'web_portal'),
('ORD-300007', 1, 1, 'CHANGE_PLAN', 'IN_PROGRESS', 1, 1, '2024-02-18 10:00:00', '2024-02-25 09:00:00', NULL, 'NORMAL', 'ONLINE', NULL, FALSE, 0.00, 'web_portal'),
('ORD-300008', 6, 6, 'NEW_ACTIVATION', 'PENDING', 1, 1, '2024-02-20 14:00:00', '2024-02-28 09:00:00', NULL, 'URGENT', 'AGENT', 6, FALSE, 75.00, 'agent_089');

-- =====================================================
-- INVOICES
-- =====================================================

INSERT INTO dwb_invoice (invoice_number, account_id, customer_id, billing_period_start, billing_period_end, invoice_date, due_date, invoice_amount, tax_amount, discount_amount, total_amount, paid_amount, balance_amount, invoice_status, payment_status, is_final) VALUES
('INV-2024-01-001', 1, 1, '2024-01-01', '2024-01-31', '2024-02-01', '2024-02-15', 85.00, 8.50, 0.00, 93.50, 93.50, 0.00, 'PAID', 'PAID', TRUE),
('INV-2024-02-001', 1, 1, '2024-02-01', '2024-02-29', '2024-03-01', '2024-03-15', 85.00, 8.50, 0.00, 93.50, 0.00, 93.50, 'UNPAID', 'PENDING', FALSE),
('INV-2024-01-002', 2, 2, '2024-01-01', '2024-01-31', '2024-02-01', '2024-02-20', 55.00, 5.50, 0.00, 60.50, 60.50, 0.00, 'PAID', 'PAID', TRUE),
('INV-2024-01-003', 3, 3, '2024-01-01', '2024-01-31', '2024-02-01', '2024-02-01', 425.00, 42.50, 63.75, 403.75, 403.75, 0.00, 'PAID', 'PAID', TRUE),
('INV-2024-01-005', 5, 5, '2024-01-01', '2024-01-31', '2024-02-01', '2024-02-05', 127.48, 12.50, 0.00, 139.98, 139.98, 0.00, 'PAID', 'PAID', TRUE),
('INV-2024-01-006', 6, 6, '2024-01-01', '2024-01-31', '2024-02-01', '2024-02-01', 1125.00, 112.50, 112.50, 1125.00, 1125.00, 0.00, 'PAID', 'PAID', TRUE),
('INV-2024-01-007', 7, 7, '2024-01-01', '2024-01-31', '2024-02-01', '2024-02-22', 55.00, 5.50, 0.00, 60.50, 60.50, 0.00, 'PAID', 'PAID', TRUE),
('INV-2024-01-008', 8, 8, '2024-01-01', '2024-01-31', '2024-02-01', '2024-02-10', 152.49, 15.25, 0.00, 167.74, 167.74, 0.00, 'PAID', 'PAID', TRUE),
('INV-2023-12-009', 9, 9, '2023-12-01', '2023-12-31', '2024-01-01', '2024-01-25', 55.00, 5.50, 0.00, 60.50, 0.00, 60.50, 'OVERDUE', 'FAILED', TRUE),
('INV-2024-01-009', 9, 9, '2024-01-01', '2024-01-31', '2024-02-01', '2024-02-25', 55.00, 5.50, 0.00, 60.50, 0.00, 60.50, 'OVERDUE', 'PENDING', TRUE),
('INV-2024-01-010', 10, 10, '2024-01-01', '2024-01-31', '2024-02-01', '2024-02-12', 73.99, 7.40, 0.00, 81.39, 81.39, 0.00, 'PAID', 'PAID', TRUE);

-- =====================================================
-- INVOICE LINE ITEMS
-- =====================================================

INSERT INTO dwb_invoice_line_item (invoice_id, subscription_id, charge_type, charge_description, charge_category, service_period_start, service_period_end, quantity, unit_price, line_amount, tax_amount, total_amount) VALUES
(1, 1, 'RECURRING', 'Unlimited 5G Premium - Monthly Service', 'MOBILE', '2024-01-01', '2024-01-31', 1, 85.00, 85.00, 8.50, 93.50),
(3, 2, 'RECURRING', '20GB 4G Plan - Monthly Service', 'MOBILE', '2024-01-01', '2024-01-31', 1, 55.00, 55.00, 5.50, 60.50),
(4, 3, 'RECURRING', 'Unlimited 5G Premium - Monthly Service', 'MOBILE', '2024-01-01', '2024-01-31', 1, 72.25, 72.25, 7.23, 79.48),
(4, 4, 'RECURRING', 'Unlimited 5G Premium - Monthly Service', 'MOBILE', '2024-01-01', '2024-01-31', 1, 72.25, 72.25, 7.23, 79.48),
(4, 5, 'RECURRING', 'Mobile Hotspot Add-on', 'VALUE_ADDED_SERVICE', '2024-01-01', '2024-01-31', 1, 15.00, 15.00, 1.50, 16.50),
(4, NULL, 'DISCOUNT', 'Business Discount - 15%', 'DISCOUNT', '2024-01-01', '2024-01-31', 1, -63.75, -63.75, 0.00, -63.75),
(5, 7, 'RECURRING', 'Fiber Internet 1Gbps - Monthly Service', 'INTERNET', '2024-01-01', '2024-01-31', 1, 79.99, 79.99, 8.00, 87.99),
(5, 8, 'RECURRING', 'Basic TV Package - Monthly Service', 'TV', '2024-01-01', '2024-01-31', 1, 44.99, 44.99, 4.50, 49.49),
(5, 8, 'DISCOUNT', 'Bundle Discount - 10%', 'DISCOUNT', '2024-01-01', '2024-01-31', 1, -5.00, -5.00, 0.00, -5.00),
(5, 8, 'EQUIPMENT', 'TV Set-Top Box Rental', 'EQUIPMENT', '2024-01-01', '2024-01-31', 1, 7.50, 7.50, 0.75, 8.25);

-- =====================================================
-- PAYMENTS
-- =====================================================

INSERT INTO dwb_payment (payment_number, account_id, customer_id, invoice_id, payment_date, payment_amount, payment_method, payment_channel, payment_status, transaction_id, payment_processor, confirmation_number, processed_by) VALUES
('PAY-400001', 1, 1, 1, '2024-02-10 08:30:00', 93.50, 'AUTOPAY', 'AUTO', 'COMPLETED', 'TXN-2024021001234', 'Stripe', 'CONF-98765', 'autopay_system'),
('PAY-400002', 2, 2, 3, '2024-02-15 14:20:00', 60.50, 'CREDIT_CARD', 'ONLINE', 'COMPLETED', 'TXN-2024021501456', 'PayPal', 'CONF-98766', 'web_portal'),
('PAY-400003', 3, 3, 4, '2024-02-01 09:00:00', 403.75, 'BANK_TRANSFER', 'AUTO', 'COMPLETED', 'TXN-2024020101789', 'ACH', 'CONF-98767', 'autopay_system'),
('PAY-400004', 5, 5, 5, '2024-02-03 10:15:00', 139.98, 'CREDIT_CARD', 'ONLINE', 'COMPLETED', 'TXN-2024020301012', 'Stripe', 'CONF-98768', 'web_portal'),
('PAY-400005', 6, 6, 6, '2024-02-01 08:00:00', 1125.00, 'BANK_TRANSFER', 'AUTO', 'COMPLETED', 'TXN-2024020100999', 'Wire', 'CONF-98769', 'autopay_system'),
('PAY-400006', 7, 7, 7, '2024-02-18 11:45:00', 60.50, 'AUTOPAY', 'AUTO', 'COMPLETED', 'TXN-2024021801345', 'Stripe', 'CONF-98770', 'autopay_system'),
('PAY-400007', 8, 8, 8, '2024-02-08 16:30:00', 167.74, 'CREDIT_CARD', 'PHONE', 'COMPLETED', 'TXN-2024020801678', 'Stripe', 'CONF-98771', 'agent_089'),
('PAY-400008', 9, 9, 9, '2024-01-30 09:00:00', 60.50, 'DEBIT_CARD', 'ONLINE', 'FAILED', 'TXN-2024013001901', 'Stripe', NULL, 'web_portal'),
('PAY-400009', 10, 10, 11, '2024-02-11 13:25:00', 81.39, 'CREDIT_CARD', 'ONLINE', 'COMPLETED', 'TXN-2024021101234', 'PayPal', 'CONF-98772', 'web_portal');

-- =====================================================
-- USAGE DETAIL RECORDS
-- =====================================================

INSERT INTO dwb_usage_detail_record (subscription_id, account_id, usage_date, usage_type, call_type, originating_number, destination_number, duration_seconds, data_volume_mb, sms_count, is_roaming, is_international, network_technology, cost_amount, charge_amount, rating_status) VALUES
-- Voice calls for SUB-200001
(1, 1, '2024-02-15 10:30:00', 'VOICE', 'OUTGOING', '+13125550001', '+13125550234', 420, NULL, NULL, FALSE, FALSE, '5G-NR', 0.00, 0.00, 'RATED'),
(1, 1, '2024-02-15 14:22:00', 'VOICE', 'INCOMING', '+13125550456', '+13125550001', 310, NULL, NULL, FALSE, FALSE, '5G-NR', 0.00, 0.00, 'RATED'),
(1, 1, '2024-02-16 09:15:00', 'VOICE', 'OUTGOING', '+13125550001', '+14155551234', 180, NULL, NULL, FALSE, FALSE, '5G-NR', 0.00, 0.00, 'RATED'),
-- SMS for SUB-200001
(1, 1, '2024-02-15 11:00:00', 'SMS', NULL, '+13125550001', '+13125550234', NULL, NULL, 1, FALSE, FALSE, '5G-NR', 0.00, 0.00, 'RATED'),
(1, 1, '2024-02-16 16:30:00', 'SMS', NULL, '+13125550001', '+13125550789', NULL, NULL, 1, FALSE, FALSE, '5G-NR', 0.00, 0.00, 'RATED'),
-- Data usage for SUB-200001
(1, 1, '2024-02-15 10:00:00', 'DATA', NULL, NULL, NULL, NULL, 2500.50, NULL, FALSE, FALSE, '5G-NR', 0.00, 0.00, 'RATED'),
(1, 1, '2024-02-16 10:00:00', 'DATA', NULL, NULL, NULL, NULL, 3200.75, NULL, FALSE, FALSE, '5G-NR', 0.00, 0.00, 'RATED'),
(1, 1, '2024-02-17 10:00:00', 'DATA', NULL, NULL, NULL, NULL, 1800.25, NULL, FALSE, FALSE, '5G-NR', 0.00, 0.00, 'RATED'),
-- Usage for SUB-200002 (20GB plan - tracking for overage)
(2, 2, '2024-02-15 09:00:00', 'DATA', NULL, NULL, NULL, NULL, 1500.00, NULL, FALSE, FALSE, 'LTE-A', 0.00, 0.00, 'RATED'),
(2, 2, '2024-02-16 09:00:00', 'DATA', NULL, NULL, NULL, NULL, 2100.00, NULL, FALSE, FALSE, 'LTE-A', 0.00, 0.00, 'RATED'),
(2, 2, '2024-02-17 09:00:00', 'DATA', NULL, NULL, NULL, NULL, 1800.00, NULL, FALSE, FALSE, 'LTE-A', 0.00, 0.00, 'RATED'),
-- International call
(2, 2, '2024-02-16 20:00:00', 'VOICE', 'OUTGOING', '+13125550002', '+442012345678', 600, NULL, NULL, FALSE, TRUE, 'LTE-A', 0.05, 0.05, 'RATED'),
-- Roaming usage
(11, 8, '2024-02-10 15:00:00', 'DATA', NULL, NULL, NULL, NULL, 500.00, NULL, TRUE, FALSE, 'LTE', 0.10, 0.10, 'RATED');

-- =====================================================
-- USAGE SUMMARY (Aggregate)
-- =====================================================

INSERT INTO dwa_customer_usage_summary (customer_id, subscription_id, summary_month, voice_minutes_used, sms_count_used, data_mb_used, roaming_charges, international_charges, total_usage_charges, plan_allowance_utilized_pct) VALUES
(1, 1, '2024-01-01', 1250, 185, 45000.00, 0.00, 0.00, 0.00, 0),  -- Unlimited plan
(2, 2, '2024-01-01', 850, 120, 18500.00, 0.00, 5.50, 5.50, 92.5),  -- 20GB plan, 92.5% used
(3, 3, '2024-01-01', 2100, 340, 55000.00, 0.00, 0.00, 0.00, 0),
(3, 4, '2024-01-01', 1950, 290, 48000.00, 0.00, 0.00, 0.00, 0),
(8, 11, '2024-01-01', 980, 95, 38000.00, 0.00, 0.00, 0.00, 0);

-- =====================================================
-- NETWORK ELEMENTS
-- =====================================================

INSERT INTO dwb_network_element (element_code, element_name, element_type, technology_id, geography_id, vendor, model, serial_number, ip_address, capacity, status, installation_date, latitude, longitude) VALUES
('TWR-CHI-001', 'Chicago Downtown Tower 1', 'TOWER', 1, 5, 'Ericsson', 'AIR 6419', 'SN-123456789', '10.10.1.1', 10000, 'ACTIVE', '2023-01-15', 41.8781, -87.6298),
('TWR-CHI-002', 'Chicago North Tower', 'TOWER', 1, 5, 'Nokia', 'AirScale', 'SN-234567890', '10.10.1.2', 10000, 'ACTIVE', '2023-02-20', 41.9200, -87.6500),
('TWR-LAX-001', 'Los Angeles Central Tower', 'TOWER', 1, 6, 'Ericsson', 'AIR 6419', 'SN-345678901', '10.20.1.1', 10000, 'ACTIVE', '2023-03-10', 34.0522, -118.2437),
('BS-CHI-001', 'Chicago Downtown Base Station 1', 'BASE_STATION', 2, 5, 'Samsung', '5G Base Station', 'SN-456789012', '10.10.2.1', 5000, 'ACTIVE', '2022-06-15', 41.8781, -87.6298),
('RTR-CHI-CORE-01', 'Chicago Core Router 1', 'ROUTER', 5, 5, 'Cisco', 'ASR 9000', 'SN-567890123', '10.10.100.1', 100000, 'ACTIVE', '2021-01-10', 41.8500, -87.6500),
('GW-CHI-001', 'Chicago Gateway 1', 'GATEWAY', 5, 5, 'Juniper', 'MX960', 'SN-678901234', '10.10.100.10', 80000, 'ACTIVE', '2021-02-15', 41.8500, -87.6500),
('TWR-NYC-001', 'New York Manhattan Tower', 'TOWER', 1, 7, 'Ericsson', 'AIR 6419', 'SN-789012345', '10.30.1.1', 10000, 'ACTIVE', '2023-04-01', 40.7580, -73.9855);

-- =====================================================
-- DEVICES
-- =====================================================

INSERT INTO dwb_device (subscription_id, customer_id, device_type, manufacturer, model, imei, serial_number, firmware_version, os_version, purchase_date, warranty_expiry_date, device_status, is_financed, financing_balance) VALUES
(1, 1, 'SMARTPHONE', 'Apple', 'iPhone 15 Pro', '123456789012345', 'APPLE-SN-001', '17.3.1', 'iOS 17.3.1', '2022-01-15', '2024-01-15', 'ACTIVE', TRUE, 299.99),
(2, 2, 'SMARTPHONE', 'Samsung', 'Galaxy S23', '234567890123456', 'SAMS-SN-002', '1.5.2', 'Android 14', '2022-03-20', '2024-03-20', 'ACTIVE', FALSE, 0.00),
(3, 3, 'SMARTPHONE', 'Apple', 'iPhone 14 Pro Max', '345678901234567', 'APPLE-SN-003', '17.3.1', 'iOS 17.3.1', '2021-06-10', '2023-06-10', 'ACTIVE', FALSE, 0.00),
(4, 3, 'SMARTPHONE', 'Samsung', 'Galaxy S23 Ultra', '456789012345678', 'SAMS-SN-004', '1.5.2', 'Android 14', '2021-06-10', '2023-06-10', 'ACTIVE', FALSE, 0.00),
(7, 5, 'ROUTER', 'Netgear', 'Nighthawk AX12', NULL, 'NET-SN-007', '1.2.0.68', 'N/A', '2022-08-05', '2023-08-05', 'ACTIVE', FALSE, 0.00),
(11, 8, 'SMARTPHONE', 'Google', 'Pixel 8 Pro', '678901234567890', 'GOOG-SN-011', '14.0.1', 'Android 14', '2021-09-15', '2024-09-15', 'ACTIVE', TRUE, 450.00),
(12, 8, 'ROUTER', 'TP-Link', 'Archer AX6000', NULL, 'TPL-SN-012', '1.3.2', 'N/A', '2021-09-15', '2022-09-15', 'ACTIVE', FALSE, 0.00);

-- =====================================================
-- TROUBLE TICKETS
-- =====================================================

INSERT INTO dwb_trouble_ticket (ticket_number, customer_id, account_id, subscription_id, ticket_type, ticket_category, priority, ticket_status, subject, description, resolution, opened_date, assigned_to, assigned_date, resolved_date, sla_due_date, channel, created_by) VALUES
('TKT-500001', 1, 1, 1, 'TECHNICAL', 'DATA_SPEED', 'MEDIUM', 'RESOLVED', 'Slow data speeds', 'Customer reporting slow 5G speeds in downtown area during peak hours', 'Network congestion identified. Informed customer of normal peak hour performance. Will monitor area for capacity upgrade.', '2024-02-10 09:00:00', 'tech_support_001', '2024-02-10 09:15:00', '2024-02-10 14:30:00', '2024-02-12 09:00:00', 'PHONE', 'ivr_system'),
('TKT-500002', 2, 2, 2, 'BILLING', 'DISPUTED_CHARGE', 'HIGH', 'RESOLVED', 'Unexpected international call charges', 'Customer questioning international call charges on last bill', 'Verified international call made on 2024-01-16. Provided call details to customer. Customer acknowledged.', '2024-02-08 11:30:00', 'billing_support_002', '2024-02-08 11:35:00', '2024-02-08 15:20:00', '2024-02-10 11:30:00', 'EMAIL', 'email_system'),
('TKT-500003', 5, 5, 7, 'TECHNICAL', 'NO_SERVICE', 'CRITICAL', 'RESOLVED', 'Internet service down', 'Complete internet outage at customer location', 'Fiber cut identified in area. Repair completed. Service restored.', '2024-02-12 08:00:00', 'noc_engineer_005', '2024-02-12 08:05:00', '2024-02-12 16:30:00', '2024-02-12 12:00:00', 'PHONE', 'ivr_system'),
('TKT-500004', 8, 8, 11, 'REQUEST', 'PLAN_CHANGE', 'LOW', 'CLOSED', 'Want to upgrade to unlimited plan', 'Customer interested in upgrading from current plan to unlimited 5G', 'Processed upgrade order. New plan effective next billing cycle.', '2024-02-14 10:00:00', 'sales_rep_010', '2024-02-14 10:05:00', '2024-02-14 11:00:00', '2024-02-16 10:00:00', 'CHAT', 'chat_system'),
('TKT-500005', 9, 9, 13, 'BILLING', 'PAYMENT_ISSUE', 'HIGH', 'OPEN', 'Unable to make payment', 'Customer trying to pay overdue balance but payment keeps failing', NULL, '2024-02-18 14:00:00', 'billing_support_001', '2024-02-18 14:10:00', NULL, '2024-02-20 14:00:00', 'APP', 'mobile_app'),
('TKT-500006', 3, 3, 3, 'COMPLAINT', 'POOR_COVERAGE', 'MEDIUM', 'IN_PROGRESS', 'Poor signal at office location', 'Business customer reporting poor signal strength at office building', NULL, '2024-02-19 09:30:00', 'noc_engineer_003', '2024-02-19 10:00:00', NULL, '2024-02-22 09:30:00', 'EMAIL', 'email_system');

-- =====================================================
-- Verification Queries
-- =====================================================

-- Display summary statistics
SELECT 'Total Customers' as metric, COUNT(*) as count FROM dwb_customer
UNION ALL
SELECT 'Active Customers', COUNT(*) FROM dwb_customer WHERE customer_status = 'ACTIVE'
UNION ALL
SELECT 'Total Accounts', COUNT(*) FROM dwb_account
UNION ALL
SELECT 'Total Subscriptions', COUNT(*) FROM dwb_subscription
UNION ALL
SELECT 'Active Subscriptions', COUNT(*) FROM dwb_subscription WHERE subscription_status = 'ACTIVE'
UNION ALL
SELECT 'Total Orders', COUNT(*) FROM dwb_service_order
UNION ALL
SELECT 'Total Invoices', COUNT(*) FROM dwb_invoice
UNION ALL
SELECT 'Total Payments', COUNT(*) FROM dwb_payment
UNION ALL
SELECT 'Total Usage Records', COUNT(*) FROM dwb_usage_detail_record
UNION ALL
SELECT 'Total Network Elements', COUNT(*) FROM dwb_network_element
UNION ALL
SELECT 'Total Devices', COUNT(*) FROM dwb_device
UNION ALL
SELECT 'Total Trouble Tickets', COUNT(*) FROM dwb_trouble_ticket;
