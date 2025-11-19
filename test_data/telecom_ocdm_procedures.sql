-- Telecommunications OCDM Stored Procedures and Functions
-- Purpose: Business logic for telecom operations

\c telecom_ocdm_db;

-- =====================================================
-- TRIGGER: Update updated_at timestamp
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update trigger to relevant tables
CREATE TRIGGER update_customer_updated_at BEFORE UPDATE ON dwb_customer FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_account_updated_at BEFORE UPDATE ON dwb_account FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subscription_updated_at BEFORE UPDATE ON dwb_subscription FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_order_updated_at BEFORE UPDATE ON dwb_service_order FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_invoice_updated_at BEFORE UPDATE ON dwb_invoice FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_network_element_updated_at BEFORE UPDATE ON dwb_network_element FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_device_updated_at BEFORE UPDATE ON dwb_device FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trouble_ticket_updated_at BEFORE UPDATE ON dwb_trouble_ticket FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTION: Create New Customer with Account
-- =====================================================

CREATE OR REPLACE FUNCTION create_customer_with_account(
    p_customer_type VARCHAR,
    p_first_name VARCHAR DEFAULT NULL,
    p_last_name VARCHAR DEFAULT NULL,
    p_business_name VARCHAR DEFAULT NULL,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_customer_segment VARCHAR DEFAULT 'STANDARD',
    p_account_type VARCHAR DEFAULT 'POSTPAID',
    p_billing_cycle_day INTEGER DEFAULT 15
)
RETURNS TABLE(
    customer_id INTEGER,
    customer_number VARCHAR,
    account_id INTEGER,
    account_number VARCHAR
) AS $$
DECLARE
    v_customer_id INTEGER;
    v_customer_number VARCHAR;
    v_account_id INTEGER;
    v_account_number VARCHAR;
    v_account_name VARCHAR;
BEGIN
    -- Generate customer number
    v_customer_number := 'CUST-' || LPAD(NEXTVAL('dwb_customer_customer_id_seq')::TEXT, 6, '0');

    -- Insert customer
    INSERT INTO dwb_customer (
        customer_number,
        customer_type,
        first_name,
        last_name,
        business_name,
        email,
        phone_primary,
        customer_segment,
        kyc_status,
        customer_status
    ) VALUES (
        v_customer_number,
        p_customer_type,
        p_first_name,
        p_last_name,
        p_business_name,
        p_email,
        p_phone,
        p_customer_segment,
        'PENDING',
        'ACTIVE'
    ) RETURNING dwb_customer.customer_id INTO v_customer_id;

    -- Generate account number
    v_account_number := 'ACC-' || LPAD(NEXTVAL('dwb_account_account_id_seq')::TEXT, 6, '0');

    -- Set account name
    IF p_customer_type = 'INDIVIDUAL' THEN
        v_account_name := p_first_name || ' ' || p_last_name || ' - Personal';
    ELSE
        v_account_name := p_business_name || ' - Business';
    END IF;

    -- Create account
    INSERT INTO dwb_account (
        account_number,
        customer_id,
        account_name,
        account_type,
        billing_cycle_day,
        account_status,
        activation_date
    ) VALUES (
        v_account_number,
        v_customer_id,
        v_account_name,
        p_account_type,
        p_billing_cycle_day,
        'ACTIVE',
        CURRENT_DATE
    ) RETURNING dwb_account.account_id INTO v_account_id;

    -- Log audit
    INSERT INTO dwb_audit_log (table_name, record_id, action, new_values, changed_by)
    VALUES (
        'dwb_customer',
        v_customer_id,
        'INSERT',
        json_build_object('customer_number', v_customer_number, 'email', p_email)::jsonb,
        CURRENT_USER
    );

    RETURN QUERY SELECT v_customer_id, v_customer_number, v_account_id, v_account_number;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_customer_with_account IS 'Create new customer and associated billing account';

-- =====================================================
-- FUNCTION: Provision New Subscription
-- =====================================================

CREATE OR REPLACE FUNCTION provision_subscription(
    p_account_id INTEGER,
    p_product_id INTEGER,
    p_plan_id INTEGER DEFAULT NULL,
    p_msisdn VARCHAR DEFAULT NULL,
    p_contract_term_months INTEGER DEFAULT 0
)
RETURNS TABLE(
    success BOOLEAN,
    subscription_id INTEGER,
    subscription_number VARCHAR,
    message TEXT
) AS $$
DECLARE
    v_subscription_id INTEGER;
    v_subscription_number VARCHAR;
    v_customer_id INTEGER;
    v_monthly_charge NUMERIC;
    v_contract_end_date DATE;
BEGIN
    -- Get customer_id from account
    SELECT customer_id INTO v_customer_id
    FROM dwb_account
    WHERE account_id = p_account_id;

    IF v_customer_id IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::INTEGER, NULL::VARCHAR, 'Account not found'::TEXT;
        RETURN;
    END IF;

    -- Get base price from product catalog
    SELECT base_price INTO v_monthly_charge
    FROM dwr_product_catalog
    WHERE product_id = p_product_id;

    -- Generate subscription number
    v_subscription_number := 'SUB-' || LPAD(NEXTVAL('dwb_subscription_subscription_id_seq')::TEXT, 6, '0');

    -- Calculate contract end date
    IF p_contract_term_months > 0 THEN
        v_contract_end_date := CURRENT_DATE + (p_contract_term_months || ' months')::INTERVAL;
    END IF;

    -- Insert subscription
    INSERT INTO dwb_subscription (
        subscription_number,
        account_id,
        customer_id,
        product_id,
        plan_id,
        msisdn,
        subscription_status,
        activation_date,
        contract_start_date,
        contract_end_date,
        monthly_recurring_charge
    ) VALUES (
        v_subscription_number,
        p_account_id,
        v_customer_id,
        p_product_id,
        p_plan_id,
        p_msisdn,
        'ACTIVE',
        NOW(),
        CURRENT_DATE,
        v_contract_end_date,
        v_monthly_charge
    ) RETURNING dwb_subscription.subscription_id INTO v_subscription_id;

    -- Log audit
    INSERT INTO dwb_audit_log (table_name, record_id, action, new_values, changed_by)
    VALUES (
        'dwb_subscription',
        v_subscription_id,
        'INSERT',
        json_build_object('subscription_number', v_subscription_number, 'product_id', p_product_id)::jsonb,
        CURRENT_USER
    );

    RETURN QUERY SELECT TRUE, v_subscription_id, v_subscription_number, 'Subscription provisioned successfully'::TEXT;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION provision_subscription IS 'Provision new service subscription for customer';

-- =====================================================
-- FUNCTION: Calculate Usage Charges
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_usage_charges(
    p_subscription_id INTEGER,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    voice_minutes INTEGER,
    sms_count INTEGER,
    data_gb NUMERIC,
    base_charges NUMERIC,
    overage_charges NUMERIC,
    roaming_charges NUMERIC,
    international_charges NUMERIC,
    total_charges NUMERIC
) AS $$
DECLARE
    v_plan_data_allowance INTEGER;
    v_overage_rate NUMERIC;
    v_data_used_mb NUMERIC;
    v_data_overage_gb NUMERIC := 0;
    v_overage_charge NUMERIC := 0;
BEGIN
    -- Get plan allowance
    SELECT sp.data_allowance_gb, sp.overage_charge_per_gb
    INTO v_plan_data_allowance, v_overage_rate
    FROM dwb_subscription s
    LEFT JOIN dwr_service_plans sp ON s.plan_id = sp.plan_id
    WHERE s.subscription_id = p_subscription_id;

    -- Calculate usage and charges
    RETURN QUERY
    SELECT
        COALESCE(SUM(CASE WHEN usage_type = 'VOICE' THEN duration_seconds / 60 ELSE 0 END)::INTEGER, 0) as voice_minutes,
        COALESCE(SUM(CASE WHEN usage_type = 'SMS' THEN sms_count ELSE 0 END)::INTEGER, 0) as sms_count,
        COALESCE(ROUND(SUM(COALESCE(data_volume_mb, 0))::NUMERIC / 1024, 2), 0) as data_gb,
        0.00 as base_charges,  -- Base charges come from subscription MRC
        CASE
            WHEN v_plan_data_allowance IS NOT NULL AND
                 SUM(COALESCE(data_volume_mb, 0)) / 1024 > v_plan_data_allowance
            THEN ROUND(((SUM(COALESCE(data_volume_mb, 0)) / 1024 - v_plan_data_allowance) * v_overage_rate)::NUMERIC, 2)
            ELSE 0.00
        END as overage_charges,
        COALESCE(ROUND(SUM(CASE WHEN is_roaming THEN charge_amount ELSE 0 END)::NUMERIC, 2), 0) as roaming_charges,
        COALESCE(ROUND(SUM(CASE WHEN is_international THEN charge_amount ELSE 0 END)::NUMERIC, 2), 0) as international_charges,
        COALESCE(ROUND(SUM(charge_amount)::NUMERIC, 2), 0) as total_charges
    FROM dwb_usage_detail_record
    WHERE subscription_id = p_subscription_id
      AND usage_date BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_usage_charges IS 'Calculate usage charges for subscription billing period';

-- =====================================================
-- FUNCTION: Generate Monthly Invoice
-- =====================================================

CREATE OR REPLACE FUNCTION generate_monthly_invoice(
    p_account_id INTEGER,
    p_billing_period_start DATE,
    p_billing_period_end DATE
)
RETURNS VARCHAR AS $$
DECLARE
    v_invoice_id INTEGER;
    v_invoice_number VARCHAR;
    v_customer_id INTEGER;
    v_subscription RECORD;
    v_usage RECORD;
    v_total_amount NUMERIC := 0;
    v_tax_rate NUMERIC := 0.10;  -- 10% tax rate
    v_tax_amount NUMERIC := 0;
BEGIN
    -- Get customer_id
    SELECT customer_id INTO v_customer_id
    FROM dwb_account
    WHERE account_id = p_account_id;

    -- Generate invoice number
    v_invoice_number := 'INV-' || TO_CHAR(p_billing_period_start, 'YYYY-MM') || '-' ||
                        LPAD(NEXTVAL('dwb_invoice_invoice_id_seq')::TEXT, 6, '0');

    -- Create invoice header
    INSERT INTO dwb_invoice (
        invoice_number,
        account_id,
        customer_id,
        billing_period_start,
        billing_period_end,
        invoice_date,
        due_date,
        invoice_amount,
        invoice_status
    ) VALUES (
        v_invoice_number,
        p_account_id,
        v_customer_id,
        p_billing_period_start,
        p_billing_period_end,
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '15 days',
        0,
        'DRAFT'
    ) RETURNING invoice_id INTO v_invoice_id;

    -- Add line items for each active subscription
    FOR v_subscription IN
        SELECT s.subscription_id, s.monthly_recurring_charge, s.discount_percentage,
               p.product_name
        FROM dwb_subscription s
        JOIN dwr_product_catalog p ON s.product_id = p.product_id
        WHERE s.account_id = p_account_id
          AND s.subscription_status = 'ACTIVE'
          AND s.activation_date <= p_billing_period_end
    LOOP
        -- Add recurring charge line item
        INSERT INTO dwb_invoice_line_item (
            invoice_id,
            subscription_id,
            charge_type,
            charge_description,
            service_period_start,
            service_period_end,
            quantity,
            unit_price,
            line_amount,
            total_amount
        ) VALUES (
            v_invoice_id,
            v_subscription.subscription_id,
            'RECURRING',
            v_subscription.product_name || ' - Monthly Service',
            p_billing_period_start,
            p_billing_period_end,
            1,
            v_subscription.monthly_recurring_charge,
            v_subscription.monthly_recurring_charge,
            v_subscription.monthly_recurring_charge
        );

        v_total_amount := v_total_amount + v_subscription.monthly_recurring_charge;

        -- Calculate and add usage charges
        SELECT * INTO v_usage
        FROM calculate_usage_charges(
            v_subscription.subscription_id,
            p_billing_period_start,
            p_billing_period_end
        );

        -- Add overage charges if any
        IF v_usage.overage_charges > 0 THEN
            INSERT INTO dwb_invoice_line_item (
                invoice_id,
                subscription_id,
                charge_type,
                charge_description,
                service_period_start,
                service_period_end,
                quantity,
                unit_price,
                line_amount,
                total_amount
            ) VALUES (
                v_invoice_id,
                v_subscription.subscription_id,
                'OVERAGE',
                'Data Overage Charges',
                p_billing_period_start,
                p_billing_period_end,
                1,
                v_usage.overage_charges,
                v_usage.overage_charges,
                v_usage.overage_charges
            );
            v_total_amount := v_total_amount + v_usage.overage_charges;
        END IF;

        -- Add roaming charges if any
        IF v_usage.roaming_charges > 0 THEN
            INSERT INTO dwb_invoice_line_item (
                invoice_id,
                subscription_id,
                charge_type,
                charge_description,
                service_period_start,
                service_period_end,
                quantity,
                unit_price,
                line_amount,
                total_amount
            ) VALUES (
                v_invoice_id,
                v_subscription.subscription_id,
                'USAGE',
                'Roaming Charges',
                p_billing_period_start,
                p_billing_period_end,
                1,
                v_usage.roaming_charges,
                v_usage.roaming_charges,
                v_usage.roaming_charges
            );
            v_total_amount := v_total_amount + v_usage.roaming_charges;
        END IF;
    END LOOP;

    -- Calculate tax
    v_tax_amount := ROUND(v_total_amount * v_tax_rate, 2);

    -- Update invoice totals
    UPDATE dwb_invoice
    SET
        invoice_amount = v_total_amount,
        tax_amount = v_tax_amount,
        total_amount = v_total_amount + v_tax_amount,
        balance_amount = v_total_amount + v_tax_amount,
        invoice_status = 'ISSUED',
        is_final = TRUE
    WHERE invoice_id = v_invoice_id;

    RETURN v_invoice_number;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_monthly_invoice IS 'Generate monthly invoice for account with all charges';

-- =====================================================
-- FUNCTION: Process Payment
-- =====================================================

CREATE OR REPLACE FUNCTION process_payment(
    p_account_id INTEGER,
    p_invoice_id INTEGER DEFAULT NULL,
    p_payment_amount NUMERIC,
    p_payment_method VARCHAR,
    p_payment_channel VARCHAR DEFAULT 'ONLINE'
)
RETURNS TABLE(
    success BOOLEAN,
    payment_id INTEGER,
    payment_number VARCHAR,
    message TEXT
) AS $$
DECLARE
    v_payment_id INTEGER;
    v_payment_number VARCHAR;
    v_customer_id INTEGER;
    v_remaining_amount NUMERIC;
BEGIN
    -- Validate amount
    IF p_payment_amount <= 0 THEN
        RETURN QUERY SELECT FALSE, NULL::INTEGER, NULL::VARCHAR, 'Invalid payment amount'::TEXT;
        RETURN;
    END IF;

    -- Get customer_id
    SELECT customer_id INTO v_customer_id
    FROM dwb_account
    WHERE account_id = p_account_id;

    -- Generate payment number
    v_payment_number := 'PAY-' || LPAD(NEXTVAL('dwb_payment_payment_id_seq')::TEXT, 6, '0');

    -- Insert payment
    INSERT INTO dwb_payment (
        payment_number,
        account_id,
        customer_id,
        invoice_id,
        payment_date,
        payment_amount,
        payment_method,
        payment_channel,
        payment_status,
        transaction_id
    ) VALUES (
        v_payment_number,
        p_account_id,
        v_customer_id,
        p_invoice_id,
        NOW(),
        p_payment_amount,
        p_payment_method,
        p_payment_channel,
        'COMPLETED',
        'TXN-' || TO_CHAR(NOW(), 'YYYYMMDDHH24MISS')
    ) RETURNING dwb_payment.payment_id INTO v_payment_id;

    -- If payment is for specific invoice, update invoice
    IF p_invoice_id IS NOT NULL THEN
        UPDATE dwb_invoice
        SET
            paid_amount = paid_amount + p_payment_amount,
            balance_amount = GREATEST(balance_amount - p_payment_amount, 0),
            invoice_status = CASE
                WHEN balance_amount - p_payment_amount <= 0 THEN 'PAID'
                ELSE 'PARTIALLY_PAID'
            END,
            payment_status = CASE
                WHEN balance_amount - p_payment_amount <= 0 THEN 'PAID'
                ELSE 'PARTIAL'
            END
        WHERE invoice_id = p_invoice_id;
    END IF;

    -- Update account balance
    UPDATE dwb_account
    SET
        current_balance = GREATEST(current_balance - p_payment_amount, 0),
        outstanding_balance = GREATEST(outstanding_balance - p_payment_amount, 0)
    WHERE account_id = p_account_id;

    RETURN QUERY SELECT TRUE, v_payment_id, v_payment_number, 'Payment processed successfully'::TEXT;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION process_payment IS 'Process customer payment and update account balances';

-- =====================================================
-- FUNCTION: Calculate Customer Lifetime Value (CLV)
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_customer_lifetime_value(p_customer_id INTEGER)
RETURNS TABLE(
    total_revenue NUMERIC,
    months_active INTEGER,
    avg_monthly_revenue NUMERIC,
    total_subscriptions INTEGER,
    active_subscriptions INTEGER,
    churn_risk VARCHAR
) AS $$
DECLARE
    v_registration_date TIMESTAMP;
    v_last_payment_date TIMESTAMP;
    v_months_since_payment INTEGER;
BEGIN
    SELECT registration_date INTO v_registration_date
    FROM dwb_customer
    WHERE customer_id = p_customer_id;

    -- Get last payment date
    SELECT MAX(payment_date) INTO v_last_payment_date
    FROM dwb_payment
    WHERE customer_id = p_customer_id;

    v_months_since_payment := EXTRACT(MONTH FROM AGE(NOW(), v_last_payment_date));

    RETURN QUERY
    SELECT
        COALESCE(SUM(pay.payment_amount), 0) as total_revenue,
        GREATEST(EXTRACT(MONTH FROM AGE(NOW(), v_registration_date))::INTEGER, 1) as months_active,
        ROUND(COALESCE(SUM(pay.payment_amount), 0) /
              GREATEST(EXTRACT(MONTH FROM AGE(NOW(), v_registration_date)), 1), 2) as avg_monthly_revenue,
        COUNT(DISTINCT sub.subscription_id)::INTEGER as total_subscriptions,
        COUNT(DISTINCT CASE WHEN sub.subscription_status = 'ACTIVE' THEN sub.subscription_id END)::INTEGER as active_subscriptions,
        CASE
            WHEN v_months_since_payment > 2 THEN 'HIGH'
            WHEN v_months_since_payment > 1 THEN 'MEDIUM'
            ELSE 'LOW'
        END as churn_risk
    FROM dwb_customer c
    LEFT JOIN dwb_payment pay ON c.customer_id = pay.customer_id
    LEFT JOIN dwb_subscription sub ON c.customer_id = sub.customer_id
    WHERE c.customer_id = p_customer_id
    GROUP BY c.customer_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_customer_lifetime_value IS 'Calculate customer lifetime value and churn risk';

-- =====================================================
-- FUNCTION: Identify Upsell Opportunities
-- =====================================================

CREATE OR REPLACE FUNCTION identify_upsell_opportunities(p_customer_id INTEGER)
RETURNS TABLE(
    opportunity_type VARCHAR,
    current_product VARCHAR,
    recommended_product VARCHAR,
    potential_revenue NUMERIC,
    reasoning TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Customers with only mobile service -> recommend internet
    SELECT
        'ADD_INTERNET'::VARCHAR,
        pc.product_name,
        'Fiber Internet 1Gbps'::VARCHAR,
        79.99::NUMERIC,
        'Customer has mobile service but no home internet'::TEXT
    FROM dwb_subscription s
    JOIN dwr_product_catalog pc ON s.product_id = pc.product_id
    WHERE s.customer_id = p_customer_id
      AND s.subscription_status = 'ACTIVE'
      AND pc.product_type = 'MOBILE'
      AND NOT EXISTS (
          SELECT 1 FROM dwb_subscription s2
          JOIN dwr_product_catalog pc2 ON s2.product_id = pc2.product_id
          WHERE s2.customer_id = p_customer_id
            AND pc2.product_type = 'INTERNET'
            AND s2.subscription_status = 'ACTIVE'
      )

    UNION ALL

    -- High data users on limited plans -> recommend unlimited
    SELECT
        'UPGRADE_TO_UNLIMITED'::VARCHAR,
        pc.product_name,
        'Unlimited 5G Premium'::VARCHAR,
        30.00::NUMERIC,
        'Customer using over 90% of data allowance'::TEXT
    FROM dwb_subscription s
    JOIN dwr_product_catalog pc ON s.product_id = pc.product_id
    JOIN dwr_service_plans sp ON s.plan_id = sp.plan_id
    JOIN dwa_customer_usage_summary us ON s.subscription_id = us.subscription_id
    WHERE s.customer_id = p_customer_id
      AND s.subscription_status = 'ACTIVE'
      AND sp.is_unlimited = FALSE
      AND us.plan_allowance_utilized_pct > 90;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION identify_upsell_opportunities IS 'Identify product upsell opportunities for customer';

-- =====================================================
-- Example Usage and Testing
-- =====================================================

-- Test customer lifetime value
SELECT * FROM calculate_customer_lifetime_value(1);

-- Test upsell opportunities
SELECT * FROM identify_upsell_opportunities(2);

-- Test usage charge calculation
SELECT * FROM calculate_usage_charges(1, '2024-02-01', '2024-02-29');
