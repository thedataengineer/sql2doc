-- Stored Procedures for Legal and Collections Database
-- Business logic for case management, payments, and reporting

\c legal_collections_db;

-- =====================================================
-- PROCEDURE: Create New Case
-- =====================================================
CREATE OR REPLACE FUNCTION create_case(
    p_client_id INTEGER,
    p_debtor_id INTEGER,
    p_case_type VARCHAR,
    p_original_amount NUMERIC,
    p_description TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_case_id INTEGER;
    v_case_number VARCHAR(50);
BEGIN
    -- Generate unique case number
    v_case_number := 'CASE-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(nextval('cases_case_id_seq')::TEXT, 6, '0');

    -- Insert case
    INSERT INTO cases (
        case_number, client_id, debtor_id, case_type,
        original_amount, current_balance, description
    ) VALUES (
        v_case_number, p_client_id, p_debtor_id, p_case_type,
        p_original_amount, p_original_amount, p_description
    ) RETURNING case_id INTO v_case_id;

    -- Update client total outstanding
    UPDATE clients
    SET total_outstanding = total_outstanding + p_original_amount
    WHERE client_id = p_client_id;

    RETURN v_case_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_case IS 'Creates a new case and updates client outstanding balance';

-- =====================================================
-- PROCEDURE: Process Payment
-- =====================================================
CREATE OR REPLACE FUNCTION process_payment(
    p_case_id INTEGER,
    p_payment_amount NUMERIC,
    p_payment_method VARCHAR,
    p_transaction_id VARCHAR DEFAULT NULL,
    p_principal_amount NUMERIC DEFAULT NULL,
    p_interest_amount NUMERIC DEFAULT NULL,
    p_fees_amount NUMERIC DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_payment_id INTEGER;
    v_new_balance NUMERIC;
    v_client_id INTEGER;
BEGIN
    -- Get client_id and current balance
    SELECT client_id, current_balance
    INTO v_client_id, v_new_balance
    FROM cases
    WHERE case_id = p_case_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Case not found: %', p_case_id;
    END IF;

    -- Calculate new balance
    v_new_balance := v_new_balance - p_payment_amount;

    -- Insert payment record
    INSERT INTO payments (
        case_id, payment_date, payment_amount, payment_method,
        transaction_id, principal_amount, interest_amount, fees_amount
    ) VALUES (
        p_case_id, CURRENT_DATE, p_payment_amount, p_payment_method,
        p_transaction_id, p_principal_amount, p_interest_amount, p_fees_amount
    ) RETURNING payment_id INTO v_payment_id;

    -- Update case balance
    UPDATE cases
    SET current_balance = v_new_balance,
        updated_at = CURRENT_TIMESTAMP
    WHERE case_id = p_case_id;

    -- Update client total outstanding
    UPDATE clients
    SET total_outstanding = total_outstanding - p_payment_amount
    WHERE client_id = v_client_id;

    -- Check if case is paid off
    IF v_new_balance <= 0 THEN
        UPDATE cases
        SET case_status = 'SETTLED',
            closed_at = CURRENT_TIMESTAMP
        WHERE case_id = p_case_id;
    END IF;

    RETURN v_payment_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION process_payment IS 'Processes a payment and updates case and client balances';

-- =====================================================
-- PROCEDURE: Calculate Age of Case
-- =====================================================
CREATE OR REPLACE FUNCTION get_case_age_days(p_case_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_filed_date DATE;
    v_age_days INTEGER;
BEGIN
    SELECT filed_date INTO v_filed_date
    FROM cases
    WHERE case_id = p_case_id;

    IF v_filed_date IS NULL THEN
        SELECT created_at::DATE INTO v_filed_date
        FROM cases
        WHERE case_id = p_case_id;
    END IF;

    v_age_days := CURRENT_DATE - v_filed_date;

    RETURN v_age_days;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_case_age_days IS 'Returns the age of a case in days';

-- =====================================================
-- PROCEDURE: Get Cases Approaching Statute of Limitations
-- =====================================================
CREATE OR REPLACE FUNCTION get_cases_near_statute(p_days_threshold INTEGER DEFAULT 90)
RETURNS TABLE(
    case_id INTEGER,
    case_number VARCHAR,
    debtor_name VARCHAR,
    current_balance NUMERIC,
    statute_date DATE,
    days_remaining INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.case_id,
        c.case_number,
        d.debtor_name,
        c.current_balance,
        c.statute_of_limitations,
        (c.statute_of_limitations - CURRENT_DATE) as days_remaining
    FROM cases c
    JOIN debtors d ON c.debtor_id = d.debtor_id
    WHERE c.statute_of_limitations IS NOT NULL
        AND c.statute_of_limitations > CURRENT_DATE
        AND (c.statute_of_limitations - CURRENT_DATE) <= p_days_threshold
        AND c.case_status NOT IN ('SETTLED', 'CLOSED', 'DISMISSED')
    ORDER BY c.statute_of_limitations ASC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_cases_near_statute IS 'Returns cases approaching statute of limitations';

-- =====================================================
-- PROCEDURE: Calculate Collection Rate
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_collection_rate(
    p_client_id INTEGER DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE(
    total_cases INTEGER,
    original_amount NUMERIC,
    collected_amount NUMERIC,
    collection_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT c.case_id)::INTEGER as total_cases,
        SUM(c.original_amount) as original_amount,
        COALESCE(SUM(p.payment_amount), 0) as collected_amount,
        CASE
            WHEN SUM(c.original_amount) > 0 THEN
                ROUND((COALESCE(SUM(p.payment_amount), 0) / SUM(c.original_amount) * 100), 2)
            ELSE 0
        END as collection_rate
    FROM cases c
    LEFT JOIN payments p ON c.case_id = p.case_id
        AND p.payment_status = 'COMPLETED'
        AND (p_start_date IS NULL OR p.payment_date >= p_start_date)
        AND (p_end_date IS NULL OR p.payment_date <= p_end_date)
    WHERE (p_client_id IS NULL OR c.client_id = p_client_id)
        AND (p_start_date IS NULL OR c.created_at::DATE >= p_start_date)
        AND (p_end_date IS NULL OR c.created_at::DATE <= p_end_date);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_collection_rate IS 'Calculates collection rate for a client or overall';

-- =====================================================
-- PROCEDURE: Log Activity
-- =====================================================
CREATE OR REPLACE FUNCTION log_activity(
    p_case_id INTEGER,
    p_activity_type VARCHAR,
    p_performed_by VARCHAR,
    p_outcome VARCHAR DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_follow_up_required BOOLEAN DEFAULT FALSE,
    p_follow_up_date DATE DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_activity_id INTEGER;
BEGIN
    INSERT INTO activities (
        case_id, activity_type, performed_by, outcome,
        notes, follow_up_required, follow_up_date
    ) VALUES (
        p_case_id, p_activity_type, p_performed_by, p_outcome,
        p_notes, p_follow_up_required, p_follow_up_date
    ) RETURNING activity_id INTO v_activity_id;

    -- Update case timestamp
    UPDATE cases
    SET updated_at = CURRENT_TIMESTAMP
    WHERE case_id = p_case_id;

    RETURN v_activity_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION log_activity IS 'Logs an activity/communication for a case';

-- =====================================================
-- PROCEDURE: Get Debtor Payment History
-- =====================================================
CREATE OR REPLACE FUNCTION get_debtor_payment_history(p_debtor_id INTEGER)
RETURNS TABLE(
    case_number VARCHAR,
    payment_date DATE,
    payment_amount NUMERIC,
    payment_method VARCHAR,
    payment_status VARCHAR,
    running_total NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.case_number,
        p.payment_date,
        p.payment_amount,
        p.payment_method,
        p.payment_status,
        SUM(p.payment_amount) OVER (ORDER BY p.payment_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
    FROM payments p
    JOIN cases c ON p.case_id = c.case_id
    WHERE c.debtor_id = p_debtor_id
        AND p.payment_status = 'COMPLETED'
    ORDER BY p.payment_date DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_debtor_payment_history IS 'Returns complete payment history for a debtor';

-- =====================================================
-- PROCEDURE: Assign Case to Collector/Attorney
-- =====================================================
CREATE OR REPLACE FUNCTION assign_case(
    p_case_id INTEGER,
    p_assigned_to VARCHAR,
    p_role VARCHAR DEFAULT 'COLLECTOR' -- 'COLLECTOR' or 'ATTORNEY'
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_role = 'ATTORNEY' THEN
        UPDATE cases
        SET assigned_attorney = p_assigned_to,
            updated_at = CURRENT_TIMESTAMP
        WHERE case_id = p_case_id;
    ELSE
        UPDATE cases
        SET assigned_collector = p_assigned_to,
            updated_at = CURRENT_TIMESTAMP
        WHERE case_id = p_case_id;
    END IF;

    -- Log the assignment
    PERFORM log_activity(
        p_case_id,
        'OTHER',
        'SYSTEM',
        'SUCCESSFUL',
        'Case assigned to ' || p_assigned_to || ' as ' || p_role,
        FALSE,
        NULL
    );

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION assign_case IS 'Assigns a case to a collector or attorney';

-- =====================================================
-- PROCEDURE: Get High-Value Cases
-- =====================================================
CREATE OR REPLACE FUNCTION get_high_value_cases(p_min_balance NUMERIC DEFAULT 10000)
RETURNS TABLE(
    case_id INTEGER,
    case_number VARCHAR,
    client_name VARCHAR,
    debtor_name VARCHAR,
    current_balance NUMERIC,
    case_age_days INTEGER,
    last_payment_date DATE,
    assigned_collector VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.case_id,
        c.case_number,
        cl.client_name,
        d.debtor_name,
        c.current_balance,
        (CURRENT_DATE - COALESCE(c.filed_date, c.created_at::DATE))::INTEGER as case_age_days,
        (SELECT MAX(p.payment_date) FROM payments p WHERE p.case_id = c.case_id AND p.payment_status = 'COMPLETED') as last_payment_date,
        c.assigned_collector
    FROM cases c
    JOIN clients cl ON c.client_id = cl.client_id
    JOIN debtors d ON c.debtor_id = d.debtor_id
    WHERE c.current_balance >= p_min_balance
        AND c.case_status IN ('OPEN', 'IN_PROGRESS')
    ORDER BY c.current_balance DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_high_value_cases IS 'Returns high-value cases requiring attention';

-- =====================================================
-- TRIGGER: Update client outstanding on case changes
-- =====================================================
CREATE OR REPLACE FUNCTION trg_update_client_outstanding()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Adjust client outstanding if balance changed
        IF NEW.current_balance != OLD.current_balance THEN
            UPDATE clients
            SET total_outstanding = total_outstanding + (NEW.current_balance - OLD.current_balance)
            WHERE client_id = NEW.client_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_client_outstanding
    AFTER UPDATE ON cases
    FOR EACH ROW
    EXECUTE FUNCTION trg_update_client_outstanding();

COMMENT ON FUNCTION trg_update_client_outstanding IS 'Trigger to maintain client outstanding balance';

-- =====================================================
-- TRIGGER: Auto-update timestamps
-- =====================================================
CREATE OR REPLACE FUNCTION trg_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_clients_timestamp
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION trg_update_timestamp();

CREATE TRIGGER update_cases_timestamp
    BEFORE UPDATE ON cases
    FOR EACH ROW
    EXECUTE FUNCTION trg_update_timestamp();

CREATE TRIGGER update_payment_plans_timestamp
    BEFORE UPDATE ON payment_plans
    FOR EACH ROW
    EXECUTE FUNCTION trg_update_timestamp();

COMMENT ON FUNCTION trg_update_timestamp IS 'Auto-updates updated_at timestamp on row changes';
