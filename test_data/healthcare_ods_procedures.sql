-- Healthcare ODS Stored Procedures and Functions
-- Purpose: Business logic, calculations, and data integrity for healthcare operations

\c healthcare_ods_db;

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

-- Apply update trigger to all relevant tables
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_locations_updated_at BEFORE UPDATE ON locations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_personnel_updated_at BEFORE UPDATE ON personnel FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_health_plans_updated_at BEFORE UPDATE ON health_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_patient_insurance_updated_at BEFORE UPDATE ON patient_insurance FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_encounters_updated_at BEFORE UPDATE ON encounters FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_diagnoses_updated_at BEFORE UPDATE ON diagnoses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_procedures_updated_at BEFORE UPDATE ON procedures FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_medication_definitions_updated_at BEFORE UPDATE ON medication_definitions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_medication_orders_updated_at BEFORE UPDATE ON medication_orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_patient_allergies_updated_at BEFORE UPDATE ON patient_allergies FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_charges_updated_at BEFORE UPDATE ON charges FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTION: Calculate Patient Age
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_patient_age(patient_dob DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(patient_dob));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION calculate_patient_age IS 'Calculate patient age in years from date of birth';

-- =====================================================
-- FUNCTION: Calculate Length of Stay
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_length_of_stay(
    p_admission_date TIMESTAMP,
    p_discharge_date TIMESTAMP
)
RETURNS INTEGER AS $$
BEGIN
    IF p_discharge_date IS NULL THEN
        RETURN EXTRACT(DAY FROM (NOW() - p_admission_date))::INTEGER;
    ELSE
        RETURN EXTRACT(DAY FROM (p_discharge_date - p_admission_date))::INTEGER;
    END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_length_of_stay IS 'Calculate length of stay in days for an encounter';

-- =====================================================
-- TRIGGER: Auto-calculate length of stay on encounter update
-- =====================================================

CREATE OR REPLACE FUNCTION update_encounter_length_of_stay()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.discharge_date IS NOT NULL THEN
        NEW.length_of_stay_days := EXTRACT(DAY FROM (NEW.discharge_date - NEW.admission_date))::INTEGER;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_los_trigger
BEFORE INSERT OR UPDATE ON encounters
FOR EACH ROW
EXECUTE FUNCTION update_encounter_length_of_stay();

-- =====================================================
-- FUNCTION: Check Medication Allergy Conflict
-- =====================================================

CREATE OR REPLACE FUNCTION check_medication_allergy(
    p_patient_id INTEGER,
    p_medication_id INTEGER
)
RETURNS TABLE(
    has_conflict BOOLEAN,
    allergen_name VARCHAR,
    reaction_severity VARCHAR,
    reaction_description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        TRUE as has_conflict,
        pa.allergen_name,
        pa.reaction_severity,
        pa.reaction_description
    FROM patient_allergies pa
    JOIN medication_definitions md ON md.medication_id = p_medication_id
    WHERE pa.patient_id = p_patient_id
      AND pa.allergen_type = 'MEDICATION'
      AND pa.is_active = TRUE
      AND (
          LOWER(pa.allergen_name) = LOWER(md.medication_name)
          OR LOWER(pa.allergen_name) = LOWER(md.generic_name)
          OR LOWER(pa.allergen_name) = LOWER(md.drug_class)
      );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_medication_allergy IS 'Check if patient has allergy to medication before ordering';

-- =====================================================
-- PROCEDURE: Admit Patient
-- =====================================================

CREATE OR REPLACE FUNCTION admit_patient(
    p_patient_id INTEGER,
    p_organization_id INTEGER,
    p_location_id INTEGER,
    p_encounter_type VARCHAR,
    p_admission_source VARCHAR,
    p_attending_physician_id INTEGER,
    p_admitting_physician_id INTEGER,
    p_chief_complaint TEXT,
    p_reason_for_visit TEXT
)
RETURNS VARCHAR AS $$
DECLARE
    v_encounter_number VARCHAR;
    v_encounter_id INTEGER;
BEGIN
    -- Generate encounter number
    v_encounter_number := 'ENC-' || TO_CHAR(NOW(), 'YYYY') || '-' ||
                          LPAD(NEXTVAL('encounters_encounter_id_seq')::TEXT, 6, '0');

    -- Insert encounter
    INSERT INTO encounters (
        encounter_number,
        patient_id,
        organization_id,
        location_id,
        encounter_type,
        encounter_status,
        admission_date,
        admission_source,
        attending_physician_id,
        admitting_physician_id,
        chief_complaint,
        reason_for_visit
    ) VALUES (
        v_encounter_number,
        p_patient_id,
        p_organization_id,
        p_location_id,
        p_encounter_type,
        'IN_PROGRESS',
        NOW(),
        p_admission_source,
        p_attending_physician_id,
        p_admitting_physician_id,
        p_chief_complaint,
        p_reason_for_visit
    ) RETURNING encounter_id INTO v_encounter_id;

    -- Log audit entry
    INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by)
    VALUES (
        'encounters',
        v_encounter_id,
        'INSERT',
        json_build_object('encounter_number', v_encounter_number, 'patient_id', p_patient_id)::jsonb,
        CURRENT_USER
    );

    RETURN v_encounter_number;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION admit_patient IS 'Admit patient and create new encounter';

-- =====================================================
-- PROCEDURE: Discharge Patient
-- =====================================================

CREATE OR REPLACE FUNCTION discharge_patient(
    p_encounter_id INTEGER,
    p_discharge_disposition VARCHAR,
    p_discharge_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_admission_date TIMESTAMP;
    v_los INTEGER;
BEGIN
    -- Get admission date
    SELECT admission_date INTO v_admission_date
    FROM encounters
    WHERE encounter_id = p_encounter_id;

    -- Calculate length of stay
    v_los := EXTRACT(DAY FROM (NOW() - v_admission_date))::INTEGER;

    -- Update encounter
    UPDATE encounters
    SET
        discharge_date = NOW(),
        discharge_disposition = p_discharge_disposition,
        encounter_status = 'COMPLETED',
        length_of_stay_days = v_los
    WHERE encounter_id = p_encounter_id;

    -- Log audit entry
    INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by)
    VALUES (
        'encounters',
        p_encounter_id,
        'UPDATE',
        json_build_object(
            'discharge_date', NOW(),
            'discharge_disposition', p_discharge_disposition,
            'length_of_stay_days', v_los
        )::jsonb,
        CURRENT_USER
    );

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION discharge_patient IS 'Discharge patient and close encounter';

-- =====================================================
-- PROCEDURE: Order Medication with Allergy Check
-- =====================================================

CREATE OR REPLACE FUNCTION order_medication_safe(
    p_encounter_id INTEGER,
    p_patient_id INTEGER,
    p_medication_id INTEGER,
    p_ordered_by INTEGER,
    p_order_type VARCHAR,
    p_dose VARCHAR,
    p_route VARCHAR,
    p_frequency VARCHAR,
    p_duration_days INTEGER,
    p_indication TEXT,
    p_priority VARCHAR DEFAULT 'ROUTINE'
)
RETURNS TABLE(
    success BOOLEAN,
    order_id INTEGER,
    message TEXT,
    allergy_warning TEXT
) AS $$
DECLARE
    v_order_id INTEGER;
    v_allergy_check RECORD;
    v_allergy_warning TEXT := NULL;
BEGIN
    -- Check for allergies
    FOR v_allergy_check IN
        SELECT * FROM check_medication_allergy(p_patient_id, p_medication_id)
    LOOP
        v_allergy_warning := 'ALLERGY ALERT: Patient allergic to ' ||
                            v_allergy_check.allergen_name ||
                            ' (Severity: ' || v_allergy_check.reaction_severity || '). ' ||
                            'Reaction: ' || v_allergy_check.reaction_description;

        -- Don't allow ordering if life-threatening allergy
        IF v_allergy_check.reaction_severity = 'LIFE_THREATENING' THEN
            RETURN QUERY SELECT
                FALSE,
                NULL::INTEGER,
                'MEDICATION ORDER BLOCKED: Life-threatening allergy detected',
                v_allergy_warning;
            RETURN;
        END IF;
    END LOOP;

    -- Insert medication order
    INSERT INTO medication_orders (
        encounter_id,
        patient_id,
        medication_id,
        order_date,
        ordered_by,
        order_status,
        order_type,
        dose,
        route,
        frequency,
        duration_days,
        start_date,
        indication,
        priority
    ) VALUES (
        p_encounter_id,
        p_patient_id,
        p_medication_id,
        NOW(),
        p_ordered_by,
        'ORDERED',
        p_order_type,
        p_dose,
        p_route,
        p_frequency,
        p_duration_days,
        NOW(),
        p_indication,
        p_priority
    ) RETURNING medication_orders.order_id INTO v_order_id;

    -- Log audit entry
    INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by)
    VALUES (
        'medication_orders',
        v_order_id,
        'INSERT',
        json_build_object('order_id', v_order_id, 'patient_id', p_patient_id, 'medication_id', p_medication_id)::jsonb,
        CURRENT_USER
    );

    RETURN QUERY SELECT
        TRUE,
        v_order_id,
        'Medication ordered successfully',
        v_allergy_warning;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION order_medication_safe IS 'Order medication with automatic allergy checking';

-- =====================================================
-- FUNCTION: Calculate Readmission Risk Score
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_readmission_risk(p_patient_id INTEGER)
RETURNS TABLE(
    risk_score INTEGER,
    risk_category VARCHAR,
    contributing_factors TEXT[]
) AS $$
DECLARE
    v_age INTEGER;
    v_recent_admissions INTEGER;
    v_chronic_conditions INTEGER;
    v_score INTEGER := 0;
    v_factors TEXT[] := ARRAY[]::TEXT[];
    v_category VARCHAR;
BEGIN
    -- Get patient age
    SELECT EXTRACT(YEAR FROM AGE(date_of_birth))::INTEGER
    INTO v_age
    FROM patients
    WHERE patient_id = p_patient_id;

    -- Age factor
    IF v_age >= 65 THEN
        v_score := v_score + 20;
        v_factors := array_append(v_factors, 'Age 65+');
    END IF;

    -- Recent admissions (last 30 days)
    SELECT COUNT(*)
    INTO v_recent_admissions
    FROM encounters
    WHERE patient_id = p_patient_id
      AND admission_date >= NOW() - INTERVAL '30 days'
      AND encounter_type = 'INPATIENT';

    IF v_recent_admissions > 0 THEN
        v_score := v_score + (v_recent_admissions * 25);
        v_factors := array_append(v_factors, 'Recent admission(s): ' || v_recent_admissions);
    END IF;

    -- Chronic conditions
    SELECT COUNT(DISTINCT diagnosis_code)
    INTO v_chronic_conditions
    FROM diagnoses
    WHERE patient_id = p_patient_id
      AND status = 'CHRONIC';

    IF v_chronic_conditions >= 3 THEN
        v_score := v_score + 30;
        v_factors := array_append(v_factors, 'Multiple chronic conditions: ' || v_chronic_conditions);
    ELSIF v_chronic_conditions > 0 THEN
        v_score := v_score + 15;
        v_factors := array_append(v_factors, 'Chronic conditions: ' || v_chronic_conditions);
    END IF;

    -- Determine category
    IF v_score >= 60 THEN
        v_category := 'HIGH';
    ELSIF v_score >= 30 THEN
        v_category := 'MODERATE';
    ELSE
        v_category := 'LOW';
    END IF;

    RETURN QUERY SELECT v_score, v_category, v_factors;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_readmission_risk IS 'Calculate 30-day readmission risk score for patient';

-- =====================================================
-- FUNCTION: Generate Patient Summary Report
-- =====================================================

CREATE OR REPLACE FUNCTION get_patient_summary(p_patient_id INTEGER)
RETURNS TABLE(
    patient_info JSONB,
    active_encounters JSONB,
    active_medications JSONB,
    allergies JSONB,
    recent_diagnoses JSONB,
    recent_labs JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        -- Patient demographic info
        (SELECT jsonb_build_object(
            'mrn', mrn,
            'name', first_name || ' ' || last_name,
            'dob', date_of_birth,
            'age', EXTRACT(YEAR FROM AGE(date_of_birth)),
            'gender', gender,
            'blood_type', blood_type,
            'phone', phone_primary,
            'email', email
        ) FROM patients WHERE patient_id = p_patient_id),

        -- Active encounters
        (SELECT jsonb_agg(jsonb_build_object(
            'encounter_number', e.encounter_number,
            'type', e.encounter_type,
            'admission_date', e.admission_date,
            'location', l.location_name,
            'attending', per.first_name || ' ' || per.last_name
        ))
        FROM encounters e
        LEFT JOIN locations l ON e.location_id = l.location_id
        LEFT JOIN personnel per ON e.attending_physician_id = per.personnel_id
        WHERE e.patient_id = p_patient_id
          AND e.encounter_status = 'IN_PROGRESS'),

        -- Active medications
        (SELECT jsonb_agg(jsonb_build_object(
            'medication', md.medication_name,
            'dose', mo.dose,
            'route', mo.route,
            'frequency', mo.frequency,
            'ordered_date', mo.order_date
        ))
        FROM medication_orders mo
        JOIN medication_definitions md ON mo.medication_id = md.medication_id
        WHERE mo.patient_id = p_patient_id
          AND mo.order_status IN ('ORDERED', 'VERIFIED', 'IN_PROGRESS')),

        -- Allergies
        (SELECT jsonb_agg(jsonb_build_object(
            'allergen', allergen_name,
            'type', allergen_type,
            'severity', reaction_severity,
            'reaction', reaction_description
        ))
        FROM patient_allergies
        WHERE patient_id = p_patient_id
          AND is_active = TRUE),

        -- Recent diagnoses (last 6 months)
        (SELECT jsonb_agg(jsonb_build_object(
            'diagnosis', diagnosis_description,
            'code', diagnosis_code,
            'date', diagnosis_date,
            'status', status
        ))
        FROM diagnoses
        WHERE patient_id = p_patient_id
          AND diagnosis_date >= NOW() - INTERVAL '6 months'
        ORDER BY diagnosis_date DESC
        LIMIT 10),

        -- Recent lab results (last 30 days)
        (SELECT jsonb_agg(jsonb_build_object(
            'test', event_description,
            'result', result_value || ' ' || COALESCE(result_unit, ''),
            'date', event_date,
            'status', abnormal_flag
        ))
        FROM clinical_events
        WHERE patient_id = p_patient_id
          AND event_type = 'LAB_RESULT'
          AND event_date >= NOW() - INTERVAL '30 days'
        ORDER BY event_date DESC
        LIMIT 10);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_patient_summary IS 'Generate comprehensive patient summary with all relevant clinical data';

-- =====================================================
-- FUNCTION: Check Duplicate Medications
-- =====================================================

CREATE OR REPLACE FUNCTION check_duplicate_medications(
    p_patient_id INTEGER,
    p_medication_id INTEGER
)
RETURNS TABLE(
    has_duplicate BOOLEAN,
    duplicate_info TEXT
) AS $$
DECLARE
    v_drug_class VARCHAR;
    v_duplicate_count INTEGER;
    v_info TEXT;
BEGIN
    -- Get drug class of new medication
    SELECT drug_class INTO v_drug_class
    FROM medication_definitions
    WHERE medication_id = p_medication_id;

    -- Check for active orders in same drug class
    SELECT COUNT(*) INTO v_duplicate_count
    FROM medication_orders mo
    JOIN medication_definitions md ON mo.medication_id = md.medication_id
    WHERE mo.patient_id = p_patient_id
      AND mo.order_status IN ('ORDERED', 'VERIFIED', 'IN_PROGRESS')
      AND md.drug_class = v_drug_class
      AND md.medication_id != p_medication_id;

    IF v_duplicate_count > 0 THEN
        v_info := 'WARNING: Patient already has ' || v_duplicate_count ||
                  ' active medication(s) in the same class: ' || v_drug_class;
        RETURN QUERY SELECT TRUE, v_info;
    ELSE
        RETURN QUERY SELECT FALSE, NULL::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_duplicate_medications IS 'Check for potential duplicate therapy in same drug class';

-- =====================================================
-- FUNCTION: Calculate Hospital Quality Metrics
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_quality_metrics(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    metric_name VARCHAR,
    metric_value NUMERIC,
    metric_unit VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    -- Average length of stay
    SELECT
        'Average Length of Stay'::VARCHAR,
        ROUND(AVG(length_of_stay_days)::NUMERIC, 2),
        'days'::VARCHAR
    FROM encounters
    WHERE discharge_date BETWEEN p_start_date AND p_end_date
      AND encounter_type = 'INPATIENT'

    UNION ALL

    -- 30-day readmission rate
    SELECT
        '30-Day Readmission Rate'::VARCHAR,
        ROUND(
            (COUNT(CASE WHEN is_readmission THEN 1 END)::NUMERIC /
             NULLIF(COUNT(*), 0) * 100),
            2
        ),
        '%'::VARCHAR
    FROM encounters
    WHERE admission_date BETWEEN p_start_date AND p_end_date
      AND encounter_type = 'INPATIENT'

    UNION ALL

    -- Mortality rate
    SELECT
        'Inpatient Mortality Rate'::VARCHAR,
        ROUND(
            (COUNT(CASE WHEN discharge_disposition = 'DECEASED' THEN 1 END)::NUMERIC /
             NULLIF(COUNT(*), 0) * 100),
            2
        ),
        '%'::VARCHAR
    FROM encounters
    WHERE discharge_date BETWEEN p_start_date AND p_end_date
      AND encounter_type = 'INPATIENT'

    UNION ALL

    -- ED visits
    SELECT
        'Total ED Visits'::VARCHAR,
        COUNT(*)::NUMERIC,
        'visits'::VARCHAR
    FROM encounters
    WHERE admission_date BETWEEN p_start_date AND p_end_date
      AND encounter_type = 'EMERGENCY';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_quality_metrics IS 'Calculate hospital quality and performance metrics for date range';

-- =====================================================
-- Example Usage and Testing
-- =====================================================

-- Test patient age calculation
SELECT
    mrn,
    first_name || ' ' || last_name as patient_name,
    date_of_birth,
    calculate_patient_age(date_of_birth) as age
FROM patients
LIMIT 5;

-- Test allergy checking
SELECT * FROM check_medication_allergy(1, 8);  -- Patient 1 has penicillin allergy, checking amoxicillin

-- Test readmission risk calculation
SELECT * FROM calculate_readmission_risk(5);  -- Patient with CHF and recent admission

-- Test quality metrics
SELECT * FROM calculate_quality_metrics('2024-01-01', '2024-02-29');

-- Test patient summary
SELECT * FROM get_patient_summary(1);
