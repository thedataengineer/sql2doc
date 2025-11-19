-- Healthcare Operational Data Store (ODS) Schema
-- Purpose: Track patient encounters, clinical events, medications, diagnoses, and procedures
-- Based on: Cerner Millennium ODS Domain Model

-- Drop existing database if exists
DROP DATABASE IF EXISTS healthcare_ods_db;
CREATE DATABASE healthcare_ods_db;

\c healthcare_ods_db;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- ORGANIZATIONS & FACILITIES
-- =====================================================

CREATE TABLE organizations (
    organization_id SERIAL PRIMARY KEY,
    organization_name VARCHAR(255) NOT NULL,
    organization_type VARCHAR(50) CHECK (organization_type IN ('HOSPITAL', 'CLINIC', 'LABORATORY', 'PHARMACY', 'INSURANCE')),
    tax_id VARCHAR(50) UNIQUE,
    npi VARCHAR(10) UNIQUE,  -- National Provider Identifier
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    license_number VARCHAR(100),
    accreditation_status VARCHAR(50),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orgs_type ON organizations(organization_type);
CREATE INDEX idx_orgs_status ON organizations(status);
COMMENT ON TABLE organizations IS 'Healthcare organizations, hospitals, clinics, and facilities';

CREATE TABLE locations (
    location_id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organizations(organization_id),
    location_name VARCHAR(255) NOT NULL,
    location_type VARCHAR(50) CHECK (location_type IN ('BUILDING', 'FLOOR', 'DEPARTMENT', 'ROOM', 'BED', 'OPERATING_ROOM', 'ICU')),
    parent_location_id INTEGER REFERENCES locations(location_id),
    capacity INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    building_code VARCHAR(50),
    floor_number INTEGER,
    room_number VARCHAR(50),
    bed_number VARCHAR(50),
    specialty VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_locations_org ON locations(organization_id);
CREATE INDEX idx_locations_type ON locations(location_type);
CREATE INDEX idx_locations_parent ON locations(parent_location_id);
COMMENT ON TABLE locations IS 'Physical locations within healthcare facilities';

-- =====================================================
-- PERSONNEL
-- =====================================================

CREATE TABLE personnel (
    personnel_id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(organization_id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    personnel_type VARCHAR(50) CHECK (personnel_type IN ('PHYSICIAN', 'NURSE', 'PHARMACIST', 'TECHNICIAN', 'THERAPIST', 'ADMIN', 'OTHER')),
    specialty VARCHAR(100),
    npi VARCHAR(10) UNIQUE,  -- National Provider Identifier
    license_number VARCHAR(100),
    license_state VARCHAR(50),
    license_expiry_date DATE,
    employee_id VARCHAR(50),
    email VARCHAR(255),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    hire_date DATE,
    termination_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_personnel_type ON personnel(personnel_type);
CREATE INDEX idx_personnel_org ON personnel(organization_id);
CREATE INDEX idx_personnel_name ON personnel(last_name, first_name);
COMMENT ON TABLE personnel IS 'Healthcare providers, staff, and administrative personnel';

-- =====================================================
-- PATIENTS
-- =====================================================

CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    mrn VARCHAR(50) UNIQUE NOT NULL,  -- Medical Record Number
    ssn VARCHAR(11),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER', 'UNKNOWN')),
    race VARCHAR(50),
    ethnicity VARCHAR(50),
    primary_language VARCHAR(50) DEFAULT 'ENGLISH',
    marital_status VARCHAR(20) CHECK (marital_status IN ('SINGLE', 'MARRIED', 'DIVORCED', 'WIDOWED', 'OTHER')),
    email VARCHAR(255),
    phone_primary VARCHAR(20),
    phone_secondary VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relationship VARCHAR(50),
    blood_type VARCHAR(10) CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    is_deceased BOOLEAN DEFAULT FALSE,
    deceased_date TIMESTAMP,
    patient_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (patient_status IN ('ACTIVE', 'INACTIVE', 'DECEASED', 'MERGED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_patients_mrn ON patients(mrn);
CREATE INDEX idx_patients_name ON patients(last_name, first_name);
CREATE INDEX idx_patients_dob ON patients(date_of_birth);
CREATE INDEX idx_patients_status ON patients(patient_status);
COMMENT ON TABLE patients IS 'Patient demographic and contact information';

-- =====================================================
-- HEALTH PLANS & INSURANCE
-- =====================================================

CREATE TABLE health_plans (
    health_plan_id SERIAL PRIMARY KEY,
    plan_name VARCHAR(255) NOT NULL,
    insurance_company VARCHAR(255) NOT NULL,
    plan_type VARCHAR(50) CHECK (plan_type IN ('HMO', 'PPO', 'EPO', 'POS', 'MEDICARE', 'MEDICAID', 'PRIVATE', 'SELF_PAY')),
    payer_id VARCHAR(50),
    phone VARCHAR(20),
    fax VARCHAR(20),
    email VARCHAR(255),
    address_line1 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_health_plans_type ON health_plans(plan_type);
COMMENT ON TABLE health_plans IS 'Insurance plans and payers';

CREATE TABLE patient_insurance (
    patient_insurance_id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
    health_plan_id INTEGER NOT NULL REFERENCES health_plans(health_plan_id),
    policy_number VARCHAR(100) NOT NULL,
    group_number VARCHAR(100),
    subscriber_name VARCHAR(255),
    subscriber_relationship VARCHAR(50) CHECK (subscriber_relationship IN ('SELF', 'SPOUSE', 'CHILD', 'OTHER')),
    coverage_start_date DATE NOT NULL,
    coverage_end_date DATE,
    priority VARCHAR(20) CHECK (priority IN ('PRIMARY', 'SECONDARY', 'TERTIARY')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_patient_insurance_patient ON patient_insurance(patient_id);
CREATE INDEX idx_patient_insurance_plan ON patient_insurance(health_plan_id);
COMMENT ON TABLE patient_insurance IS 'Patient insurance coverage information';

-- =====================================================
-- ENCOUNTERS
-- =====================================================

CREATE TABLE encounters (
    encounter_id SERIAL PRIMARY KEY,
    encounter_number VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
    organization_id INTEGER REFERENCES organizations(organization_id),
    location_id INTEGER REFERENCES locations(location_id),
    encounter_type VARCHAR(50) CHECK (encounter_type IN ('INPATIENT', 'OUTPATIENT', 'EMERGENCY', 'URGENT_CARE', 'OBSERVATION', 'TELEMEDICINE', 'HOME_HEALTH')),
    encounter_status VARCHAR(50) DEFAULT 'PLANNED' CHECK (encounter_status IN ('PLANNED', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW')),
    admission_date TIMESTAMP NOT NULL,
    discharge_date TIMESTAMP,
    admission_source VARCHAR(50) CHECK (admission_source IN ('EMERGENCY', 'REFERRAL', 'TRANSFER', 'ROUTINE', 'COURT', 'OTHER')),
    discharge_disposition VARCHAR(50) CHECK (discharge_disposition IN ('HOME', 'TRANSFER', 'SNF', 'HOSPICE', 'AMA', 'DECEASED', 'OTHER')),
    attending_physician_id INTEGER REFERENCES personnel(personnel_id),
    admitting_physician_id INTEGER REFERENCES personnel(personnel_id),
    chief_complaint TEXT,
    reason_for_visit TEXT,
    length_of_stay_days INTEGER,
    is_readmission BOOLEAN DEFAULT FALSE,
    readmission_within_days INTEGER,
    financial_class VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_encounters_patient ON encounters(patient_id);
CREATE INDEX idx_encounters_org ON encounters(organization_id);
CREATE INDEX idx_encounters_type ON encounters(encounter_type);
CREATE INDEX idx_encounters_status ON encounters(encounter_status);
CREATE INDEX idx_encounters_admission_date ON encounters(admission_date);
CREATE INDEX idx_encounters_attending ON encounters(attending_physician_id);
COMMENT ON TABLE encounters IS 'Patient healthcare encounters and visits';

-- =====================================================
-- DIAGNOSES
-- =====================================================

CREATE TABLE diagnoses (
    diagnosis_id SERIAL PRIMARY KEY,
    encounter_id INTEGER NOT NULL REFERENCES encounters(encounter_id),
    patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
    diagnosis_code VARCHAR(20) NOT NULL,  -- ICD-10 or ICD-11
    diagnosis_code_type VARCHAR(10) CHECK (diagnosis_code_type IN ('ICD-9', 'ICD-10', 'ICD-11', 'SNOMED')),
    diagnosis_description TEXT NOT NULL,
    diagnosis_type VARCHAR(50) CHECK (diagnosis_type IN ('ADMITTING', 'PRIMARY', 'SECONDARY', 'COMPLICATION', 'COMORBIDITY')),
    present_on_admission BOOLEAN,
    diagnosis_date DATE NOT NULL,
    diagnosed_by INTEGER REFERENCES personnel(personnel_id),
    severity VARCHAR(20) CHECK (severity IN ('MILD', 'MODERATE', 'SEVERE', 'CRITICAL')),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RESOLVED', 'CHRONIC', 'RULED_OUT')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_diagnoses_encounter ON diagnoses(encounter_id);
CREATE INDEX idx_diagnoses_patient ON diagnoses(patient_id);
CREATE INDEX idx_diagnoses_code ON diagnoses(diagnosis_code);
CREATE INDEX idx_diagnoses_type ON diagnoses(diagnosis_type);
COMMENT ON TABLE diagnoses IS 'Patient diagnoses with ICD coding';

-- =====================================================
-- PROCEDURES
-- =====================================================

CREATE TABLE procedures (
    procedure_id SERIAL PRIMARY KEY,
    encounter_id INTEGER NOT NULL REFERENCES encounters(encounter_id),
    patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
    procedure_code VARCHAR(20) NOT NULL,  -- CPT or ICD-10-PCS
    procedure_code_type VARCHAR(10) CHECK (procedure_code_type IN ('CPT', 'ICD-10-PCS', 'HCPCS', 'SNOMED')),
    procedure_description TEXT NOT NULL,
    procedure_date TIMESTAMP NOT NULL,
    procedure_status VARCHAR(50) DEFAULT 'SCHEDULED' CHECK (procedure_status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DELAYED')),
    performing_physician_id INTEGER REFERENCES personnel(personnel_id),
    location_id INTEGER REFERENCES locations(location_id),
    duration_minutes INTEGER,
    procedure_notes TEXT,
    complications TEXT,
    anesthesia_type VARCHAR(50) CHECK (anesthesia_type IN ('GENERAL', 'LOCAL', 'REGIONAL', 'SEDATION', 'NONE')),
    is_emergent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_procedures_encounter ON procedures(encounter_id);
CREATE INDEX idx_procedures_patient ON procedures(patient_id);
CREATE INDEX idx_procedures_code ON procedures(procedure_code);
CREATE INDEX idx_procedures_date ON procedures(procedure_date);
CREATE INDEX idx_procedures_physician ON procedures(performing_physician_id);
COMMENT ON TABLE procedures IS 'Medical procedures performed on patients';

-- =====================================================
-- CLINICAL EVENTS (Labs, Vitals, Observations)
-- =====================================================

CREATE TABLE clinical_events (
    clinical_event_id SERIAL PRIMARY KEY,
    encounter_id INTEGER REFERENCES encounters(encounter_id),
    patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
    event_type VARCHAR(50) CHECK (event_type IN ('VITAL_SIGN', 'LAB_RESULT', 'OBSERVATION', 'ASSESSMENT', 'IMAGING', 'OTHER')),
    event_code VARCHAR(50),  -- LOINC code
    event_description VARCHAR(255) NOT NULL,
    event_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    result_value VARCHAR(500),
    result_unit VARCHAR(50),
    result_status VARCHAR(50) CHECK (result_status IN ('PRELIMINARY', 'FINAL', 'CORRECTED', 'CANCELLED')),
    reference_range_low NUMERIC(15, 4),
    reference_range_high NUMERIC(15, 4),
    abnormal_flag VARCHAR(20) CHECK (abnormal_flag IN ('NORMAL', 'ABNORMAL_HIGH', 'ABNORMAL_LOW', 'CRITICAL_HIGH', 'CRITICAL_LOW')),
    performed_by INTEGER REFERENCES personnel(personnel_id),
    verified_by INTEGER REFERENCES personnel(personnel_id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_clinical_events_patient ON clinical_events(patient_id);
CREATE INDEX idx_clinical_events_encounter ON clinical_events(encounter_id);
CREATE INDEX idx_clinical_events_type ON clinical_events(event_type);
CREATE INDEX idx_clinical_events_date ON clinical_events(event_date);
CREATE INDEX idx_clinical_events_code ON clinical_events(event_code);
COMMENT ON TABLE clinical_events IS 'Clinical observations, lab results, and vital signs';

-- =====================================================
-- MEDICATIONS
-- =====================================================

CREATE TABLE medication_definitions (
    medication_id SERIAL PRIMARY KEY,
    medication_name VARCHAR(255) NOT NULL,
    generic_name VARCHAR(255),
    brand_name VARCHAR(255),
    ndc_code VARCHAR(20),  -- National Drug Code
    drug_class VARCHAR(100),
    drug_category VARCHAR(100),
    dosage_form VARCHAR(50) CHECK (dosage_form IN ('TABLET', 'CAPSULE', 'LIQUID', 'INJECTION', 'TOPICAL', 'INHALER', 'PATCH', 'OTHER')),
    route VARCHAR(50) CHECK (route IN ('ORAL', 'IV', 'IM', 'SUBCUTANEOUS', 'TOPICAL', 'INHALATION', 'RECTAL', 'OTHER')),
    strength VARCHAR(50),
    unit_of_measure VARCHAR(20),
    is_controlled_substance BOOLEAN DEFAULT FALSE,
    dea_schedule VARCHAR(10),
    formulary_status VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_meds_name ON medication_definitions(medication_name);
CREATE INDEX idx_meds_generic ON medication_definitions(generic_name);
CREATE INDEX idx_meds_ndc ON medication_definitions(ndc_code);
COMMENT ON TABLE medication_definitions IS 'Medication formulary and drug definitions';

CREATE TABLE medication_orders (
    order_id SERIAL PRIMARY KEY,
    encounter_id INTEGER REFERENCES encounters(encounter_id),
    patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
    medication_id INTEGER NOT NULL REFERENCES medication_definitions(medication_id),
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ordered_by INTEGER NOT NULL REFERENCES personnel(personnel_id),
    order_status VARCHAR(50) DEFAULT 'ORDERED' CHECK (order_status IN ('ORDERED', 'VERIFIED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DISCONTINUED')),
    order_type VARCHAR(50) CHECK (order_type IN ('ROUTINE', 'STAT', 'PRN', 'ONE_TIME', 'CONTINUOUS')),
    dose VARCHAR(100) NOT NULL,
    route VARCHAR(50) NOT NULL,
    frequency VARCHAR(100),
    duration_days INTEGER,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    indication TEXT,
    special_instructions TEXT,
    pharmacy_notes TEXT,
    priority VARCHAR(20) CHECK (priority IN ('ROUTINE', 'URGENT', 'STAT')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_med_orders_patient ON medication_orders(patient_id);
CREATE INDEX idx_med_orders_encounter ON medication_orders(encounter_id);
CREATE INDEX idx_med_orders_medication ON medication_orders(medication_id);
CREATE INDEX idx_med_orders_date ON medication_orders(order_date);
CREATE INDEX idx_med_orders_status ON medication_orders(order_status);
COMMENT ON TABLE medication_orders IS 'Medication orders and prescriptions';

CREATE TABLE medication_administrations (
    administration_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES medication_orders(order_id),
    patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
    encounter_id INTEGER REFERENCES encounters(encounter_id),
    administration_date TIMESTAMP NOT NULL,
    administered_by INTEGER NOT NULL REFERENCES personnel(personnel_id),
    dose_given VARCHAR(100) NOT NULL,
    route VARCHAR(50) NOT NULL,
    site VARCHAR(100),
    administration_status VARCHAR(50) DEFAULT 'GIVEN' CHECK (administration_status IN ('GIVEN', 'NOT_GIVEN', 'REFUSED', 'HELD', 'WASTED')),
    reason_not_given TEXT,
    patient_response TEXT,
    adverse_reaction BOOLEAN DEFAULT FALSE,
    adverse_reaction_details TEXT,
    documented_by INTEGER REFERENCES personnel(personnel_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_med_admin_patient ON medication_administrations(patient_id);
CREATE INDEX idx_med_admin_order ON medication_administrations(order_id);
CREATE INDEX idx_med_admin_date ON medication_administrations(administration_date);
CREATE INDEX idx_med_admin_status ON medication_administrations(administration_status);
COMMENT ON TABLE medication_administrations IS 'Medication administration records (MAR)';

-- =====================================================
-- ALLERGIES
-- =====================================================

CREATE TABLE patient_allergies (
    allergy_id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
    allergen_type VARCHAR(50) CHECK (allergen_type IN ('MEDICATION', 'FOOD', 'ENVIRONMENTAL', 'OTHER')),
    allergen_name VARCHAR(255) NOT NULL,
    allergen_code VARCHAR(50),
    reaction_severity VARCHAR(20) CHECK (reaction_severity IN ('MILD', 'MODERATE', 'SEVERE', 'LIFE_THREATENING')),
    reaction_description TEXT,
    onset_date DATE,
    reported_by VARCHAR(255),
    verified_by INTEGER REFERENCES personnel(personnel_id),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_allergies_patient ON patient_allergies(patient_id);
CREATE INDEX idx_allergies_type ON patient_allergies(allergen_type);
COMMENT ON TABLE patient_allergies IS 'Patient allergy and adverse reaction history';

-- =====================================================
-- BILLING & CHARGES
-- =====================================================

CREATE TABLE charges (
    charge_id SERIAL PRIMARY KEY,
    encounter_id INTEGER NOT NULL REFERENCES encounters(encounter_id),
    patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
    charge_date DATE NOT NULL,
    charge_code VARCHAR(20) NOT NULL,  -- CPT, HCPCS, or Revenue Code
    charge_code_type VARCHAR(20) CHECK (charge_code_type IN ('CPT', 'HCPCS', 'REVENUE', 'DRG')),
    charge_description TEXT NOT NULL,
    quantity NUMERIC(10, 2) DEFAULT 1,
    unit_price NUMERIC(15, 2) NOT NULL,
    total_amount NUMERIC(15, 2) NOT NULL,
    charge_status VARCHAR(50) DEFAULT 'PENDING' CHECK (charge_status IN ('PENDING', 'SUBMITTED', 'PAID', 'DENIED', 'ADJUSTED', 'WRITTEN_OFF')),
    charged_by INTEGER REFERENCES personnel(personnel_id),
    department VARCHAR(100),
    service_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_charges_encounter ON charges(encounter_id);
CREATE INDEX idx_charges_patient ON charges(patient_id);
CREATE INDEX idx_charges_date ON charges(charge_date);
CREATE INDEX idx_charges_status ON charges(charge_status);
COMMENT ON TABLE charges IS 'Billing charges for services and procedures';

-- =====================================================
-- AUDIT LOG
-- =====================================================

CREATE TABLE audit_log (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(20) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'VIEW')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(255) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

CREATE INDEX idx_audit_table ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_date ON audit_log(changed_at);
CREATE INDEX idx_audit_user ON audit_log(changed_by);
COMMENT ON TABLE audit_log IS 'HIPAA-compliant audit trail for all data access and changes';

-- =====================================================
-- VIEWS
-- =====================================================

-- View: Patient Summary with Latest Encounter
CREATE VIEW v_patient_summary AS
SELECT
    p.patient_id,
    p.mrn,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    EXTRACT(YEAR FROM AGE(p.date_of_birth)) as age,
    p.gender,
    p.patient_status,
    p.phone_primary,
    p.email,
    COUNT(DISTINCT e.encounter_id) as total_encounters,
    MAX(e.admission_date) as last_visit_date,
    COUNT(DISTINCT d.diagnosis_id) as total_diagnoses,
    COUNT(DISTINCT mo.order_id) as total_medications,
    COUNT(DISTINCT pa.allergy_id) as total_allergies
FROM patients p
LEFT JOIN encounters e ON p.patient_id = e.patient_id
LEFT JOIN diagnoses d ON p.patient_id = d.patient_id
LEFT JOIN medication_orders mo ON p.patient_id = mo.patient_id
LEFT JOIN patient_allergies pa ON p.patient_id = pa.patient_id
GROUP BY p.patient_id;

COMMENT ON VIEW v_patient_summary IS 'Comprehensive patient summary with encounter statistics';

-- View: Active Inpatients
CREATE VIEW v_active_inpatients AS
SELECT
    e.encounter_id,
    e.encounter_number,
    p.mrn,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    e.admission_date,
    EXTRACT(DAY FROM (NOW() - e.admission_date)) as length_of_stay_days,
    l.location_name,
    l.room_number,
    l.bed_number,
    phy.first_name || ' ' || phy.last_name as attending_physician,
    e.chief_complaint
FROM encounters e
JOIN patients p ON e.patient_id = p.patient_id
LEFT JOIN locations l ON e.location_id = l.location_id
LEFT JOIN personnel phy ON e.attending_physician_id = phy.personnel_id
WHERE e.encounter_type = 'INPATIENT'
  AND e.encounter_status = 'IN_PROGRESS'
  AND e.discharge_date IS NULL;

COMMENT ON VIEW v_active_inpatients IS 'Current inpatient census with location and attending physician';

-- View: Medication Safety - Active Prescriptions with Allergies
CREATE VIEW v_medication_safety_check AS
SELECT
    mo.order_id,
    mo.patient_id,
    p.mrn,
    p.first_name || ' ' || p.last_name as patient_name,
    md.medication_name,
    md.generic_name,
    mo.dose,
    mo.frequency,
    mo.order_status,
    pa.allergen_name,
    pa.reaction_severity,
    pa.reaction_description
FROM medication_orders mo
JOIN patients p ON mo.patient_id = p.patient_id
JOIN medication_definitions md ON mo.medication_id = md.medication_id
LEFT JOIN patient_allergies pa ON mo.patient_id = pa.patient_id
    AND pa.allergen_type = 'MEDICATION'
    AND pa.is_active = TRUE
    AND (
        LOWER(pa.allergen_name) = LOWER(md.medication_name)
        OR LOWER(pa.allergen_name) = LOWER(md.generic_name)
    )
WHERE mo.order_status IN ('ORDERED', 'VERIFIED', 'IN_PROGRESS');

COMMENT ON VIEW v_medication_safety_check IS 'Active medication orders with potential allergy conflicts';

-- View: Clinical Quality Metrics
CREATE VIEW v_clinical_quality_metrics AS
SELECT
    DATE_TRUNC('month', e.admission_date) as reporting_month,
    e.encounter_type,
    COUNT(DISTINCT e.encounter_id) as total_encounters,
    COUNT(DISTINCT CASE WHEN e.is_readmission THEN e.encounter_id END) as readmissions,
    ROUND(
        COUNT(DISTINCT CASE WHEN e.is_readmission THEN e.encounter_id END)::NUMERIC /
        NULLIF(COUNT(DISTINCT e.encounter_id), 0) * 100,
        2
    ) as readmission_rate_pct,
    AVG(e.length_of_stay_days) as avg_length_of_stay,
    COUNT(DISTINCT CASE WHEN e.discharge_disposition = 'HOME' THEN e.encounter_id END) as discharged_home,
    COUNT(DISTINCT CASE WHEN e.discharge_disposition = 'DECEASED' THEN e.encounter_id END) as mortality_count
FROM encounters e
WHERE e.encounter_status = 'COMPLETED'
  AND e.discharge_date IS NOT NULL
GROUP BY DATE_TRUNC('month', e.admission_date), e.encounter_type;

COMMENT ON VIEW v_clinical_quality_metrics IS 'Monthly clinical quality and performance metrics';

-- View: Pharmacy Workqueue
CREATE VIEW v_pharmacy_workqueue AS
SELECT
    mo.order_id,
    mo.patient_id,
    p.mrn,
    p.first_name || ' ' || p.last_name as patient_name,
    e.encounter_number,
    l.location_name,
    md.medication_name,
    md.generic_name,
    mo.dose,
    mo.route,
    mo.frequency,
    mo.order_type,
    mo.priority,
    mo.order_date,
    mo.start_date,
    physician.first_name || ' ' || physician.last_name as ordered_by,
    mo.order_status
FROM medication_orders mo
JOIN patients p ON mo.patient_id = p.patient_id
JOIN medication_definitions md ON mo.medication_id = md.medication_id
JOIN personnel physician ON mo.ordered_by = physician.personnel_id
LEFT JOIN encounters e ON mo.encounter_id = e.encounter_id
LEFT JOIN locations l ON e.location_id = l.location_id
WHERE mo.order_status IN ('ORDERED', 'VERIFIED')
ORDER BY
    CASE mo.priority
        WHEN 'STAT' THEN 1
        WHEN 'URGENT' THEN 2
        WHEN 'ROUTINE' THEN 3
    END,
    mo.order_date;

COMMENT ON VIEW v_pharmacy_workqueue IS 'Pharmacy workqueue for pending medication orders';
