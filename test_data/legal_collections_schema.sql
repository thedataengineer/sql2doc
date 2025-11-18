-- Legal and Collections Management Database Schema
-- Purpose: Track legal cases, debtors, payments, and collections activities

-- Drop existing database if exists
DROP DATABASE IF EXISTS legal_collections_db;
CREATE DATABASE legal_collections_db;

\c legal_collections_db;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- CLIENTS & CREDITORS
-- =====================================================

CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    client_name VARCHAR(255) NOT NULL,
    client_type VARCHAR(50) CHECK (client_type IN ('INDIVIDUAL', 'CORPORATE', 'GOVERNMENT')),
    tax_id VARCHAR(50) UNIQUE,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    credit_limit NUMERIC(15, 2),
    total_outstanding NUMERIC(15, 2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_clients_status ON clients(status);
CREATE INDEX idx_clients_type ON clients(client_type);
COMMENT ON TABLE clients IS 'Creditors who engage our services for debt collection';

-- =====================================================
-- DEBTORS
-- =====================================================

CREATE TABLE debtors (
    debtor_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
    debtor_name VARCHAR(255) NOT NULL,
    ssn_or_tax_id VARCHAR(50),
    date_of_birth DATE,
    email VARCHAR(255),
    phone_primary VARCHAR(20),
    phone_secondary VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    employer_name VARCHAR(255),
    employment_status VARCHAR(50),
    monthly_income NUMERIC(12, 2),
    credit_score INTEGER,
    risk_rating VARCHAR(20) CHECK (risk_rating IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_debtors_client ON debtors(client_id);
CREATE INDEX idx_debtors_risk ON debtors(risk_rating);
CREATE INDEX idx_debtors_name ON debtors(debtor_name);
COMMENT ON TABLE debtors IS 'Individuals or entities who owe money to our clients';

-- =====================================================
-- CASES
-- =====================================================

CREATE TABLE cases (
    case_id SERIAL PRIMARY KEY,
    case_number VARCHAR(50) UNIQUE NOT NULL,
    client_id INTEGER NOT NULL REFERENCES clients(client_id),
    debtor_id INTEGER NOT NULL REFERENCES debtors(debtor_id),
    case_type VARCHAR(50) CHECK (case_type IN ('COLLECTIONS', 'LITIGATION', 'BANKRUPTCY', 'SETTLEMENT')),
    case_status VARCHAR(50) DEFAULT 'OPEN' CHECK (case_status IN ('OPEN', 'IN_PROGRESS', 'SETTLED', 'CLOSED', 'DISMISSED')),
    priority VARCHAR(20) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    original_amount NUMERIC(15, 2) NOT NULL,
    current_balance NUMERIC(15, 2) NOT NULL,
    interest_rate NUMERIC(5, 4),
    filed_date DATE,
    statute_of_limitations DATE,
    assigned_attorney VARCHAR(255),
    assigned_collector VARCHAR(255),
    court_name VARCHAR(255),
    court_case_number VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

CREATE INDEX idx_cases_status ON cases(case_status);
CREATE INDEX idx_cases_client ON cases(client_id);
CREATE INDEX idx_cases_debtor ON cases(debtor_id);
CREATE INDEX idx_cases_type ON cases(case_type);
CREATE INDEX idx_cases_filed_date ON cases(filed_date);
COMMENT ON TABLE cases IS 'Legal cases and collection activities';

-- =====================================================
-- PAYMENTS
-- =====================================================

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    case_id INTEGER NOT NULL REFERENCES cases(case_id),
    payment_date DATE NOT NULL,
    payment_amount NUMERIC(15, 2) NOT NULL CHECK (payment_amount > 0),
    payment_method VARCHAR(50) CHECK (payment_method IN ('CASH', 'CHECK', 'WIRE', 'ACH', 'CREDIT_CARD', 'DEBIT_CARD', 'PAYPAL')),
    transaction_id VARCHAR(100) UNIQUE,
    payment_status VARCHAR(50) DEFAULT 'COMPLETED' CHECK (payment_status IN ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED')),
    principal_amount NUMERIC(15, 2),
    interest_amount NUMERIC(15, 2),
    fees_amount NUMERIC(15, 2),
    notes TEXT,
    processed_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_case ON payments(case_id);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_status ON payments(payment_status);
COMMENT ON TABLE payments IS 'Payment transactions for cases';

-- =====================================================
-- ACTIVITIES / COMMUNICATION LOG
-- =====================================================

CREATE TABLE activities (
    activity_id SERIAL PRIMARY KEY,
    case_id INTEGER NOT NULL REFERENCES cases(case_id),
    activity_type VARCHAR(50) CHECK (activity_type IN ('CALL', 'EMAIL', 'LETTER', 'VISIT', 'COURT_APPEARANCE', 'NEGOTIATION', 'OTHER')),
    activity_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    performed_by VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    duration_minutes INTEGER,
    outcome VARCHAR(50) CHECK (outcome IN ('SUCCESSFUL', 'NO_RESPONSE', 'REFUSED', 'PROMISED_PAYMENT', 'DISPUTE', 'OTHER')),
    notes TEXT,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activities_case ON activities(case_id);
CREATE INDEX idx_activities_date ON activities(activity_date);
CREATE INDEX idx_activities_type ON activities(activity_type);
COMMENT ON TABLE activities IS 'Log of all communications and activities related to cases';

-- =====================================================
-- LEGAL DOCUMENTS
-- =====================================================

CREATE TABLE legal_documents (
    document_id SERIAL PRIMARY KEY,
    case_id INTEGER NOT NULL REFERENCES cases(case_id),
    document_type VARCHAR(50) CHECK (document_type IN ('COMPLAINT', 'SUMMONS', 'MOTION', 'JUDGMENT', 'SETTLEMENT_AGREEMENT', 'CORRESPONDENCE', 'OTHER')),
    document_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500),
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    uploaded_by VARCHAR(255),
    document_date DATE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_documents_case ON legal_documents(case_id);
CREATE INDEX idx_documents_type ON legal_documents(document_type);
COMMENT ON TABLE legal_documents IS 'Legal documents associated with cases';

-- =====================================================
-- PAYMENT PLANS
-- =====================================================

CREATE TABLE payment_plans (
    plan_id SERIAL PRIMARY KEY,
    case_id INTEGER NOT NULL REFERENCES cases(case_id),
    plan_status VARCHAR(50) DEFAULT 'ACTIVE' CHECK (plan_status IN ('ACTIVE', 'COMPLETED', 'DEFAULTED', 'CANCELLED')),
    total_amount NUMERIC(15, 2) NOT NULL,
    down_payment NUMERIC(15, 2),
    installment_amount NUMERIC(15, 2) NOT NULL,
    installment_frequency VARCHAR(20) CHECK (installment_frequency IN ('WEEKLY', 'BI_WEEKLY', 'MONTHLY', 'QUARTERLY')),
    number_of_installments INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    agreement_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_plans_case ON payment_plans(case_id);
CREATE INDEX idx_payment_plans_status ON payment_plans(plan_status);
COMMENT ON TABLE payment_plans IS 'Structured payment plans for debtors';

-- =====================================================
-- COURT HEARINGS
-- =====================================================

CREATE TABLE court_hearings (
    hearing_id SERIAL PRIMARY KEY,
    case_id INTEGER NOT NULL REFERENCES cases(case_id),
    hearing_type VARCHAR(50) CHECK (hearing_type IN ('INITIAL', 'MOTION', 'TRIAL', 'SETTLEMENT_CONFERENCE', 'STATUS', 'OTHER')),
    hearing_date TIMESTAMP NOT NULL,
    court_name VARCHAR(255) NOT NULL,
    courtroom VARCHAR(50),
    judge_name VARCHAR(255),
    attorney_present VARCHAR(255),
    outcome VARCHAR(100),
    next_hearing_date TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_hearings_case ON court_hearings(case_id);
CREATE INDEX idx_hearings_date ON court_hearings(hearing_date);
COMMENT ON TABLE court_hearings IS 'Court hearing schedule and outcomes';

-- =====================================================
-- AUDIT LOG
-- =====================================================

CREATE TABLE audit_log (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(20) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(255) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

CREATE INDEX idx_audit_table ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_date ON audit_log(changed_at);
COMMENT ON TABLE audit_log IS 'Audit trail for all data changes';

-- =====================================================
-- VIEWS
-- =====================================================

-- View: Case Summary with Client and Debtor Information
CREATE VIEW v_case_summary AS
SELECT
    c.case_id,
    c.case_number,
    c.case_type,
    c.case_status,
    c.priority,
    cl.client_name,
    cl.client_type,
    d.debtor_name,
    d.risk_rating,
    c.original_amount,
    c.current_balance,
    c.filed_date,
    c.assigned_attorney,
    c.assigned_collector,
    COUNT(DISTINCT p.payment_id) as payment_count,
    COALESCE(SUM(p.payment_amount), 0) as total_paid,
    COUNT(DISTINCT a.activity_id) as activity_count,
    c.created_at,
    c.updated_at
FROM cases c
JOIN clients cl ON c.client_id = cl.client_id
JOIN debtors d ON c.debtor_id = d.debtor_id
LEFT JOIN payments p ON c.case_id = p.case_id AND p.payment_status = 'COMPLETED'
LEFT JOIN activities a ON c.case_id = a.case_id
GROUP BY c.case_id, cl.client_id, d.debtor_id;

COMMENT ON VIEW v_case_summary IS 'Comprehensive case summary with related statistics';

-- View: Outstanding Balances by Client
CREATE VIEW v_client_outstanding AS
SELECT
    cl.client_id,
    cl.client_name,
    cl.client_type,
    COUNT(c.case_id) as total_cases,
    COUNT(CASE WHEN c.case_status = 'OPEN' THEN 1 END) as open_cases,
    SUM(c.current_balance) as total_outstanding,
    SUM(c.original_amount) as total_original,
    ROUND(AVG(c.current_balance), 2) as avg_balance_per_case
FROM clients cl
LEFT JOIN cases c ON cl.client_id = c.client_id
GROUP BY cl.client_id;

COMMENT ON VIEW v_client_outstanding IS 'Outstanding balance summary by client';