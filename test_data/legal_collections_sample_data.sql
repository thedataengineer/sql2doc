-- Sample Data for Legal and Collections Database
-- Realistic test data for demonstration

\c legal_collections_db;

-- =====================================================
-- CLIENTS (Creditors)
-- =====================================================
INSERT INTO clients (client_name, client_type, tax_id, contact_email, contact_phone, address_line1, city, state, zip_code, credit_limit, status) VALUES
('MegaBank Financial Corp', 'CORPORATE', '12-3456789', 'collections@megabank.com', '555-0100', '100 Wall Street', 'New York', 'NY', '10005', 1000000.00, 'ACTIVE'),
('City Medical Center', 'CORPORATE', '98-7654321', 'billing@citymedical.org', '555-0200', '500 Healthcare Dr', 'Los Angeles', 'CA', '90001', 500000.00, 'ACTIVE'),
('State Tax Authority', 'GOVERNMENT', '00-1111111', 'collections@statetax.gov', '555-0300', '1 Tax Plaza', 'Austin', 'TX', '78701', NULL, 'ACTIVE'),
('Premier Auto Finance', 'CORPORATE', '45-6789012', 'recovery@premierauto.com', '555-0400', '2000 Finance Way', 'Detroit', 'MI', '48201', 750000.00, 'ACTIVE'),
('Regional Credit Union', 'CORPORATE', '67-8901234', 'legal@regionalcu.com', '555-0500', '300 Credit Blvd', 'Seattle', 'WA', '98101', 250000.00, 'ACTIVE'),
('National Utility Services', 'CORPORATE', '78-9012345', 'ar@nationalutility.com', '555-0600', '400 Power St', 'Chicago', 'IL', '60601', 100000.00, 'ACTIVE');

-- =====================================================
-- DEBTORS
-- =====================================================
INSERT INTO debtors (client_id, debtor_name, ssn_or_tax_id, date_of_birth, email, phone_primary, address_line1, city, state, zip_code, employer_name, employment_status, monthly_income, credit_score, risk_rating, notes) VALUES
-- MegaBank debtors
(1, 'John Smith', '***-**-1234', '1985-03-15', 'jsmith@email.com', '555-1001', '123 Main St', 'Brooklyn', 'NY', '11201', 'Tech Solutions Inc', 'EMPLOYED', 5500.00, 650, 'MEDIUM', 'Has been responsive to contact attempts'),
(1, 'Sarah Johnson', '***-**-2345', '1978-07-22', 'sjohnson@email.com', '555-1002', '456 Oak Ave', 'Queens', 'NY', '11354', 'Retail Corp', 'EMPLOYED', 3200.00, 580, 'HIGH', 'Recently filed for bankruptcy protection'),
(1, 'Michael Davis', '***-**-3456', '1992-11-08', NULL, '555-1003', '789 Pine Rd', 'Bronx', 'NY', '10451', NULL, 'UNEMPLOYED', 0.00, 520, 'CRITICAL', 'No contact in 6 months, high flight risk'),

-- City Medical debtors
(2, 'Emily Rodriguez', '***-**-4567', '1990-05-30', 'erodriguez@email.com', '555-2001', '321 Health St', 'Pasadena', 'CA', '91101', 'Healthcare Plus', 'EMPLOYED', 4800.00, 690, 'LOW', 'On payment plan, consistent payments'),
(2, 'David Wilson', '***-**-5678', '1965-12-14', 'dwilson@email.com', '555-2002', '654 Medical Ln', 'Glendale', 'CA', '91201', 'Self-employed', 'EMPLOYED', 6200.00, 720, 'LOW', 'Business owner, good payment history'),
(2, 'Lisa Martinez', '***-**-6789', '1988-09-25', NULL, '555-2003', '987 Care Blvd', 'Santa Monica', 'CA', '90401', NULL, 'UNEMPLOYED', 1200.00, 495, 'HIGH', 'Recently lost job, disputing charges'),

-- State Tax debtors
(3, 'Robert Brown', '***-**-7890', '1972-04-18', 'rbrown@email.com', '555-3001', '111 Tax Way', 'Dallas', 'TX', '75201', 'Construction LLC', 'EMPLOYED', 7500.00, 640, 'MEDIUM', 'Business tax debt, negotiating settlement'),
(3, 'Jennifer Taylor', '***-**-8901', '1983-08-07', 'jtaylor@email.com', '555-3002', '222 Revenue Rd', 'Houston', 'TX', '77001', 'Marketing Agency', 'EMPLOYED', 5800.00, 610, 'MEDIUM', 'Personal income tax, setting up payment plan'),

-- Premier Auto debtors
(4, 'Christopher Lee', '***-**-9012', '1995-01-20', 'clee@email.com', '555-4001', '333 Drive St', 'Ann Arbor', 'MI', '48103', 'University', 'EMPLOYED', 3800.00, 560, 'HIGH', 'Vehicle repossessed, deficiency balance'),
(4, 'Amanda White', '***-**-0123', '1987-06-12', 'awhite@email.com', '555-4002', '444 Motor Ave', 'Grand Rapids', 'MI', '49501', 'Hospital', 'EMPLOYED', 4500.00, 625, 'MEDIUM', 'Voluntarily surrendered vehicle'),

-- Regional Credit Union debtors
(5, 'James Anderson', '***-**-1235', '1980-10-03', 'janderson@email.com', '555-5001', '555 Credit Pl', 'Tacoma', 'WA', '98401', 'Boeing', 'EMPLOYED', 8200.00, 695, 'LOW', 'Credit card debt, good income'),
(5, 'Patricia Thomas', '***-**-2346', '1976-02-28', 'pthomas@email.com', '555-5002', '666 Union St', 'Spokane', 'WA', '99201', 'School District', 'EMPLOYED', 4200.00, 605, 'MEDIUM', 'Personal loan default'),

-- National Utility debtors
(6, 'Daniel Martinez', '***-**-3457', '1991-07-16', NULL, '555-6001', '777 Power Dr', 'Evanston', 'IL', '60201', NULL, 'UNEMPLOYED', 0.00, 480, 'CRITICAL', 'Multiple disconnection notices'),
(6, 'Michelle Garcia', '***-**-4568', '1984-11-29', 'mgarcia@email.com', '555-6002', '888 Utility Ln', 'Naperville', 'IL', '60540', 'Corporate', 'EMPLOYED', 5200.00, 650, 'MEDIUM', 'Disputed billing, resolved');

-- =====================================================
-- CASES
-- =====================================================

-- Using the create_case function
SELECT create_case(1, 1, 'COLLECTIONS', 15750.50, 'Credit card debt - Account ending 4523');
SELECT create_case(1, 2, 'BANKRUPTCY', 23400.00, 'Chapter 7 bankruptcy filed - Monitoring');
SELECT create_case(1, 3, 'LITIGATION', 45200.75, 'Personal loan default - Filed lawsuit');

SELECT create_case(2, 4, 'COLLECTIONS', 8920.00, 'Medical services - Emergency room visit');
SELECT create_case(2, 5, 'SETTLEMENT', 12500.00, 'Surgical procedure - Settlement agreed');
SELECT create_case(2, 6, 'COLLECTIONS', 3450.25, 'Outpatient services - Multiple visits');

SELECT create_case(3, 7, 'COLLECTIONS', 67800.00, 'Business tax debt - 2022 tax year');
SELECT create_case(3, 8, 'COLLECTIONS', 12300.50, 'Personal income tax - 2023');

SELECT create_case(4, 9, 'LITIGATION', 18900.00, 'Auto loan deficiency - Vehicle repossessed');
SELECT create_case(4, 10, 'SETTLEMENT', 11200.00, 'Auto loan - Voluntary surrender');

SELECT create_case(5, 11, 'COLLECTIONS', 9500.00, 'Credit card debt - Multiple accounts');
SELECT create_case(5, 12, 'COLLECTIONS', 15800.00, 'Personal loan default');

SELECT create_case(6, 13, 'COLLECTIONS', 1250.75, 'Utility services - 6 months past due');
SELECT create_case(6, 14, 'SETTLEMENT', 890.50, 'Utility services - Billing dispute resolved');

-- Update case details
UPDATE cases SET
    case_status = 'IN_PROGRESS',
    filed_date = CURRENT_DATE - INTERVAL '90 days',
    statute_of_limitations = CURRENT_DATE + INTERVAL '3 years',
    assigned_attorney = 'Rebecca Chen, Esq.',
    assigned_collector = 'Mark Thompson',
    court_name = 'New York Supreme Court',
    court_case_number = 'SC-2024-001234'
WHERE case_id = 3;

UPDATE cases SET
    case_status = 'IN_PROGRESS',
    filed_date = CURRENT_DATE - INTERVAL '45 days',
    statute_of_limitations = CURRENT_DATE + INTERVAL '4 years',
    assigned_collector = 'Sarah Williams'
WHERE case_id = 1;

UPDATE cases SET
    case_status = 'SETTLED',
    filed_date = CURRENT_DATE - INTERVAL '120 days',
    closed_at = CURRENT_DATE - INTERVAL '10 days',
    assigned_collector = 'Mike Johnson'
WHERE case_id = 5;

-- =====================================================
-- PAYMENTS
-- =====================================================

-- Process some payments
SELECT process_payment(1, 2000.00, 'ACH', 'TXN-20240101-001', 1800.00, 200.00, NULL);
SELECT process_payment(1, 1500.00, 'CREDIT_CARD', 'TXN-20240115-002', 1400.00, 100.00, NULL);
SELECT process_payment(4, 1500.00, 'CHECK', 'CHK-20240120-001', 1500.00, NULL, NULL);
SELECT process_payment(5, 12500.00, 'WIRE', 'WIRE-20240125-001', 11000.00, 1000.00, 500.00);
SELECT process_payment(7, 5000.00, 'ACH', 'TXN-20240201-003', 5000.00, NULL, NULL);
SELECT process_payment(8, 3000.00, 'CREDIT_CARD', 'TXN-20240205-004', 2800.00, 200.00, NULL);
SELECT process_payment(11, 1000.00, 'ACH', 'TXN-20240210-005', 1000.00, NULL, NULL);
SELECT process_payment(14, 890.50, 'CHECK', 'CHK-20240215-002', 890.50, NULL, NULL);

-- Add some older payments
INSERT INTO payments (case_id, payment_date, payment_amount, payment_method, transaction_id, payment_status, principal_amount) VALUES
(1, CURRENT_DATE - INTERVAL '60 days', 1000.00, 'ACH', 'TXN-OLD-001', 'COMPLETED', 1000.00),
(3, CURRENT_DATE - INTERVAL '75 days', 5000.00, 'CHECK', 'CHK-OLD-001', 'COMPLETED', 5000.00),
(7, CURRENT_DATE - INTERVAL '30 days', 10000.00, 'WIRE', 'WIRE-OLD-001', 'COMPLETED', 10000.00);

-- =====================================================
-- ACTIVITIES
-- =====================================================

-- Log various activities
SELECT log_activity(1, 'CALL', 'Mark Thompson', 'PROMISED_PAYMENT', 'Debtor agreed to pay $2000 by end of month', TRUE, CURRENT_DATE + INTERVAL '25 days');
SELECT log_activity(1, 'EMAIL', 'Mark Thompson', 'NO_RESPONSE', 'Sent payment reminder email', TRUE, CURRENT_DATE + INTERVAL '7 days');
SELECT log_activity(3, 'COURT_APPEARANCE', 'Rebecca Chen, Esq.', 'SUCCESSFUL', 'Initial hearing completed, next hearing scheduled', TRUE, CURRENT_DATE + INTERVAL '60 days');
SELECT log_activity(4, 'CALL', 'Sarah Williams', 'SUCCESSFUL', 'Confirmed payment plan details', FALSE, NULL);
SELECT log_activity(6, 'LETTER', 'Mike Johnson', 'NO_RESPONSE', 'Sent demand letter via certified mail', TRUE, CURRENT_DATE + INTERVAL '14 days');
SELECT log_activity(7, 'NEGOTIATION', 'Tax Collections Team', 'PROMISED_PAYMENT', 'Negotiated settlement at 75% of balance', FALSE, NULL);
SELECT log_activity(9, 'VISIT', 'Field Investigator', 'REFUSED', 'Attempted in-person contact, debtor refused to engage', TRUE, CURRENT_DATE + INTERVAL '30 days');
SELECT log_activity(11, 'CALL', 'Collections Agent', 'DISPUTE', 'Debtor disputes charges, requesting validation', TRUE, CURRENT_DATE + INTERVAL '10 days');

-- =====================================================
-- PAYMENT PLANS
-- =====================================================

INSERT INTO payment_plans (case_id, plan_status, total_amount, down_payment, installment_amount, installment_frequency, number_of_installments, start_date, agreement_date, notes) VALUES
(1, 'ACTIVE', 12250.50, 2000.00, 500.00, 'MONTHLY', 12, CURRENT_DATE, CURRENT_DATE - INTERVAL '5 days', '12-month payment plan agreed upon'),
(4, 'ACTIVE', 7420.00, 1500.00, 350.00, 'BI_WEEKLY', 17, CURRENT_DATE + INTERVAL '14 days', CURRENT_DATE, 'Bi-weekly payments starting next pay period'),
(8, 'ACTIVE', 9300.50, 3000.00, 700.00, 'MONTHLY', 9, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE - INTERVAL '35 days', 'Monthly plan, 2 payments made so far'),
(12, 'DEFAULTED', 15800.00, 2000.00, 1000.00, 'MONTHLY', 14, CURRENT_DATE - INTERVAL '90 days', CURRENT_DATE - INTERVAL '95 days', 'Missed 2 consecutive payments, plan defaulted');

-- =====================================================
-- COURT HEARINGS
-- =====================================================

INSERT INTO court_hearings (case_id, hearing_type, hearing_date, court_name, courtroom, judge_name, attorney_present, outcome, next_hearing_date, notes) VALUES
(3, 'INITIAL', CURRENT_DATE - INTERVAL '45 days', 'New York Supreme Court', '302', 'Hon. Patricia Morgan', 'Rebecca Chen, Esq.', 'Discovery phase ordered', CURRENT_DATE + INTERVAL '45 days', 'Defendant filed answer, discovery to be completed in 90 days'),
(3, 'STATUS', CURRENT_DATE + INTERVAL '45 days', 'New York Supreme Court', '302', 'Hon. Patricia Morgan', 'Rebecca Chen, Esq.', NULL, CURRENT_DATE + INTERVAL '120 days', 'Upcoming status conference'),
(9, 'MOTION', CURRENT_DATE + INTERVAL '15 days', 'Wayne County Circuit Court', 'Room 5', 'Hon. James Parker', 'David Miller, Esq.', NULL, NULL, 'Hearing on motion for summary judgment');

-- =====================================================
-- LEGAL DOCUMENTS
-- =====================================================

INSERT INTO legal_documents (case_id, document_type, document_name, document_date, description, uploaded_by) VALUES
(3, 'COMPLAINT', 'Complaint_Case_CASE-20241118-000003.pdf', CURRENT_DATE - INTERVAL '90 days', 'Original complaint filed with court', 'Rebecca Chen'),
(3, 'SUMMONS', 'Summons_Case_CASE-20241118-000003.pdf', CURRENT_DATE - INTERVAL '90 days', 'Summons served to defendant', 'Process Server'),
(5, 'SETTLEMENT_AGREEMENT', 'Settlement_Case_CASE-20241118-000005.pdf', CURRENT_DATE - INTERVAL '15 days', 'Executed settlement agreement', 'Mike Johnson'),
(7, 'CORRESPONDENCE', 'Demand_Letter_Case_CASE-20241118-000007.pdf', CURRENT_DATE - INTERVAL '120 days', 'Initial demand letter', 'Tax Collections'),
(9, 'MOTION', 'Motion_Summary_Judgment.pdf', CURRENT_DATE - INTERVAL '5 days', 'Motion for summary judgment filed', 'David Miller');

-- =====================================================
-- AUDIT LOG (Sample entries)
-- =====================================================

INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by, ip_address) VALUES
('cases', 1, 'UPDATE', '{"case_status": "IN_PROGRESS"}', 'mark.thompson@firm.com', '192.168.1.100'),
('payments', 1, 'INSERT', '{"case_id": 1, "amount": 2000.00}', 'system@firm.com', '192.168.1.50'),
('cases', 5, 'UPDATE', '{"case_status": "SETTLED"}', 'mike.johnson@firm.com', '192.168.1.101');

-- =====================================================
-- Summary Report
-- =====================================================

SELECT 'Database populated successfully!' as status;

SELECT
    'Total Clients' as metric,
    COUNT(*)::TEXT as value
FROM clients
UNION ALL
SELECT
    'Total Debtors' as metric,
    COUNT(*)::TEXT as value
FROM debtors
UNION ALL
SELECT
    'Total Cases' as metric,
    COUNT(*)::TEXT as value
FROM cases
UNION ALL
SELECT
    'Total Payments' as metric,
    COUNT(*)::TEXT as value
FROM payments
UNION ALL
SELECT
    'Total Outstanding' as metric,
    TO_CHAR(SUM(current_balance), '$999,999,999.99') as value
FROM cases
WHERE case_status NOT IN ('SETTLED', 'CLOSED');