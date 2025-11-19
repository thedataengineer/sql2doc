-- Healthcare ODS Sample Data
-- Purpose: Populate test data for healthcare operational data store

\c healthcare_ods_db;

-- =====================================================
-- ORGANIZATIONS & FACILITIES
-- =====================================================

INSERT INTO organizations (organization_name, organization_type, tax_id, npi, contact_email, contact_phone, address_line1, city, state, zip_code, license_number, accreditation_status, status) VALUES
('St. Mary''s General Hospital', 'HOSPITAL', '12-3456789', '1234567890', 'admin@stmarys.org', '555-0100', '123 Medical Center Drive', 'Springfield', 'IL', '62701', 'H-12345', 'JCAHO_ACCREDITED', 'ACTIVE'),
('Springfield Community Clinic', 'CLINIC', '23-4567890', '2345678901', 'info@springfieldclinic.org', '555-0200', '456 Main Street', 'Springfield', 'IL', '62702', 'C-23456', 'AAAHC_ACCREDITED', 'ACTIVE'),
('MedLab Diagnostics', 'LABORATORY', '34-5678901', '3456789012', 'contact@medlab.com', '555-0300', '789 Lab Way', 'Springfield', 'IL', '62703', 'L-34567', 'CAP_ACCREDITED', 'ACTIVE'),
('HealthPlus Pharmacy', 'PHARMACY', '45-6789012', '4567890123', 'service@healthplusrx.com', '555-0400', '321 Pharmacy Blvd', 'Springfield', 'IL', '62704', 'P-45678', 'NABP_ACCREDITED', 'ACTIVE'),
('Blue Shield Insurance Co', 'INSURANCE', '56-7890123', '5678901234', 'claims@blueshield.com', '555-0500', '999 Insurance Plaza', 'Chicago', 'IL', '60601', 'I-56789', NULL, 'ACTIVE');

INSERT INTO locations (organization_id, location_name, location_type, parent_location_id, capacity, building_code, floor_number, room_number, specialty) VALUES
-- St. Mary's Hospital Locations
(1, 'Main Hospital Building', 'BUILDING', NULL, 500, 'MHB', NULL, NULL, NULL),
(1, 'Emergency Department', 'DEPARTMENT', 1, 50, 'MHB', 1, NULL, 'EMERGENCY_MEDICINE'),
(1, 'Intensive Care Unit', 'ICU', 1, 20, 'MHB', 3, NULL, 'CRITICAL_CARE'),
(1, 'Operating Room 1', 'OPERATING_ROOM', 1, 1, 'MHB', 2, 'OR-1', 'SURGERY'),
(1, 'Operating Room 2', 'OPERATING_ROOM', 1, 1, 'MHB', 2, 'OR-2', 'SURGERY'),
(1, 'Room 301', 'ROOM', 3, 1, 'MHB', 3, '301', NULL),
(1, 'Bed 301-A', 'BED', 6, 1, 'MHB', 3, '301', 'ICU'),
(1, 'Bed 301-B', 'BED', 6, 1, 'MHB', 3, '301', 'ICU'),
(1, 'Cardiology Department', 'DEPARTMENT', 1, 30, 'MHB', 4, NULL, 'CARDIOLOGY'),
(1, 'Radiology Department', 'DEPARTMENT', 1, 15, 'MHB', 1, NULL, 'RADIOLOGY'),
-- Springfield Clinic Locations
(2, 'Main Clinic', 'BUILDING', NULL, 50, 'MC', NULL, NULL, NULL),
(2, 'Exam Room 1', 'ROOM', 11, 1, 'MC', 1, 'E1', 'FAMILY_MEDICINE'),
(2, 'Exam Room 2', 'ROOM', 11, 1, 'MC', 1, 'E2', 'FAMILY_MEDICINE');

-- =====================================================
-- PERSONNEL
-- =====================================================

INSERT INTO personnel (organization_id, first_name, last_name, middle_name, personnel_type, specialty, npi, license_number, license_state, license_expiry_date, employee_id, email, phone, hire_date) VALUES
(1, 'John', 'Smith', 'Michael', 'PHYSICIAN', 'CARDIOLOGY', '1234567001', 'MD-12345', 'IL', '2026-12-31', 'EMP001', 'j.smith@stmarys.org', '555-1001', '2015-01-15'),
(1, 'Sarah', 'Johnson', 'Ann', 'PHYSICIAN', 'EMERGENCY_MEDICINE', '1234567002', 'MD-12346', 'IL', '2026-12-31', 'EMP002', 's.johnson@stmarys.org', '555-1002', '2016-03-20'),
(1, 'Michael', 'Williams', 'David', 'PHYSICIAN', 'SURGERY', '1234567003', 'MD-12347', 'IL', '2027-06-30', 'EMP003', 'm.williams@stmarys.org', '555-1003', '2014-07-01'),
(1, 'Emily', 'Brown', 'Grace', 'NURSE', 'CRITICAL_CARE', '1234567004', 'RN-45678', 'IL', '2025-12-31', 'EMP004', 'e.brown@stmarys.org', '555-1004', '2017-02-15'),
(1, 'David', 'Martinez', 'Luis', 'NURSE', 'EMERGENCY', '1234567005', 'RN-45679', 'IL', '2025-12-31', 'EMP005', 'd.martinez@stmarys.org', '555-1005', '2018-05-10'),
(1, 'Lisa', 'Anderson', 'Marie', 'PHARMACIST', NULL, '1234567006', 'RPH-78901', 'IL', '2026-06-30', 'EMP006', 'l.anderson@stmarys.org', '555-1006', '2016-09-01'),
(1, 'Robert', 'Taylor', 'James', 'PHYSICIAN', 'INTERNAL_MEDICINE', '1234567007', 'MD-12348', 'IL', '2027-12-31', 'EMP007', 'r.taylor@stmarys.org', '555-1007', '2015-11-15'),
(2, 'Jennifer', 'Davis', 'Lynn', 'PHYSICIAN', 'FAMILY_MEDICINE', '1234567008', 'MD-12349', 'IL', '2026-12-31', 'EMP008', 'j.davis@springfieldclinic.org', '555-2001', '2017-01-10'),
(2, 'Christopher', 'Wilson', 'Paul', 'NURSE', 'AMBULATORY', '1234567009', 'RN-45680', 'IL', '2025-12-31', 'EMP009', 'c.wilson@springfieldclinic.org', '555-2002', '2018-03-15'),
(3, 'Amanda', 'Moore', 'Jane', 'TECHNICIAN', 'LABORATORY', '1234567010', 'MLT-98765', 'IL', '2026-12-31', 'EMP010', 'a.moore@medlab.com', '555-3001', '2016-06-20');

-- =====================================================
-- PATIENTS
-- =====================================================

INSERT INTO patients (mrn, ssn, first_name, last_name, middle_name, date_of_birth, gender, race, ethnicity, primary_language, marital_status, email, phone_primary, address_line1, city, state, zip_code, emergency_contact_name, emergency_contact_phone, emergency_contact_relationship, blood_type) VALUES
('MRN001234', '123-45-6789', 'James', 'Wilson', 'Robert', '1965-03-15', 'MALE', 'CAUCASIAN', 'NOT_HISPANIC', 'ENGLISH', 'MARRIED', 'j.wilson@email.com', '555-7001', '123 Oak Street', 'Springfield', 'IL', '62701', 'Mary Wilson', '555-7002', 'SPOUSE', 'O+'),
('MRN001235', '234-56-7890', 'Maria', 'Garcia', 'Elena', '1978-07-22', 'FEMALE', 'HISPANIC', 'HISPANIC', 'SPANISH', 'MARRIED', 'm.garcia@email.com', '555-7003', '456 Elm Avenue', 'Springfield', 'IL', '62702', 'Carlos Garcia', '555-7004', 'SPOUSE', 'A+'),
('MRN001236', '345-67-8901', 'William', 'Thompson', 'Henry', '1952-11-30', 'MALE', 'CAUCASIAN', 'NOT_HISPANIC', 'ENGLISH', 'WIDOWED', 'w.thompson@email.com', '555-7005', '789 Maple Drive', 'Springfield', 'IL', '62703', 'Susan Thompson', '555-7006', 'DAUGHTER', 'B+'),
('MRN001237', '456-78-9012', 'Patricia', 'Martinez', 'Ann', '1990-02-14', 'FEMALE', 'HISPANIC', 'HISPANIC', 'ENGLISH', 'SINGLE', 'p.martinez@email.com', '555-7007', '321 Pine Road', 'Springfield', 'IL', '62704', 'Jose Martinez', '555-7008', 'FATHER', 'AB+'),
('MRN001238', '567-89-0123', 'Robert', 'Anderson', 'Lee', '1945-09-05', 'MALE', 'CAUCASIAN', 'NOT_HISPANIC', 'ENGLISH', 'MARRIED', 'r.anderson@email.com', '555-7009', '654 Cedar Lane', 'Springfield', 'IL', '62705', 'Linda Anderson', '555-7010', 'SPOUSE', 'O-'),
('MRN001239', '678-90-1234', 'Linda', 'Thomas', 'Sue', '1982-05-18', 'FEMALE', 'AFRICAN_AMERICAN', 'NOT_HISPANIC', 'ENGLISH', 'DIVORCED', 'l.thomas@email.com', '555-7011', '987 Birch Street', 'Springfield', 'IL', '62706', 'Dorothy Thomas', '555-7012', 'MOTHER', 'A-'),
('MRN001240', '789-01-2345', 'Michael', 'Jackson', 'Joseph', '1970-08-29', 'MALE', 'AFRICAN_AMERICAN', 'NOT_HISPANIC', 'ENGLISH', 'SINGLE', 'm.jackson@email.com', '555-7013', '147 Walnut Ave', 'Springfield', 'IL', '62707', 'Katherine Jackson', '555-7014', 'SISTER', 'B-'),
('MRN001241', '890-12-3456', 'Elizabeth', 'White', 'Anne', '1958-12-10', 'FEMALE', 'CAUCASIAN', 'NOT_HISPANIC', 'ENGLISH', 'MARRIED', 'e.white@email.com', '555-7015', '258 Spruce Court', 'Springfield', 'IL', '62708', 'John White', '555-7016', 'SPOUSE', 'AB-'),
('MRN001242', '901-23-4567', 'David', 'Harris', 'Michael', '1995-04-03', 'MALE', 'ASIAN', 'NOT_HISPANIC', 'ENGLISH', 'SINGLE', 'd.harris@email.com', '555-7017', '369 Ash Boulevard', 'Springfield', 'IL', '62709', 'Helen Harris', '555-7018', 'MOTHER', 'O+'),
('MRN001243', '012-34-5678', 'Jennifer', 'Clark', 'Lynn', '1988-06-25', 'FEMALE', 'CAUCASIAN', 'NOT_HISPANIC', 'ENGLISH', 'MARRIED', 'j.clark@email.com', '555-7019', '741 Willow Way', 'Springfield', 'IL', '62710', 'Brian Clark', '555-7020', 'SPOUSE', 'A+');

-- =====================================================
-- HEALTH PLANS & INSURANCE
-- =====================================================

INSERT INTO health_plans (plan_name, insurance_company, plan_type, payer_id, phone, email, address_line1, city, state, zip_code) VALUES
('Blue Shield PPO Plus', 'Blue Shield Insurance Co', 'PPO', 'BSPPO001', '800-555-0001', 'ppo@blueshield.com', '999 Insurance Plaza', 'Chicago', 'IL', '60601'),
('Medicare Part A & B', 'Centers for Medicare Services', 'MEDICARE', 'CMS001', '800-633-4227', 'medicare@cms.gov', '7500 Security Blvd', 'Baltimore', 'MD', '21244'),
('Medicaid Illinois', 'Illinois Dept of Healthcare', 'MEDICAID', 'IL-MEDICAID', '800-226-0768', 'info@illinois.medicaid.gov', '201 S Grand Ave E', 'Springfield', 'IL', '62763'),
('HealthFirst HMO', 'HealthFirst Insurance', 'HMO', 'HF-HMO001', '800-555-0002', 'hmo@healthfirst.com', '500 Health Plaza', 'Chicago', 'IL', '60602'),
('Self Pay', 'Self Pay', 'SELF_PAY', 'SELFPAY', NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO patient_insurance (patient_id, health_plan_id, policy_number, group_number, subscriber_name, subscriber_relationship, coverage_start_date, coverage_end_date, priority) VALUES
(1, 1, 'BSP123456789', 'GRP1001', 'James Wilson', 'SELF', '2023-01-01', '2025-12-31', 'PRIMARY'),
(2, 4, 'HF987654321', 'GRP2002', 'Maria Garcia', 'SELF', '2023-01-01', '2025-12-31', 'PRIMARY'),
(3, 2, 'MCARE-123456', NULL, 'William Thompson', 'SELF', '2020-01-01', NULL, 'PRIMARY'),
(4, 3, 'IL-MCD-789012', NULL, 'Patricia Martinez', 'SELF', '2024-01-01', '2025-12-31', 'PRIMARY'),
(5, 2, 'MCARE-234567', NULL, 'Robert Anderson', 'SELF', '2015-01-01', NULL, 'PRIMARY'),
(6, 1, 'BSP234567890', 'GRP1001', 'Linda Thomas', 'SELF', '2023-06-01', '2025-12-31', 'PRIMARY'),
(7, 5, 'SELF-001240', NULL, 'Michael Jackson', 'SELF', '2024-01-01', NULL, 'PRIMARY'),
(8, 2, 'MCARE-345678', NULL, 'Elizabeth White', 'SELF', '2018-01-01', NULL, 'PRIMARY'),
(9, 1, 'BSP345678901', 'GRP3003', 'David Harris', 'SELF', '2024-01-01', '2025-12-31', 'PRIMARY'),
(10, 4, 'HF876543210', 'GRP2002', 'Jennifer Clark', 'SELF', '2023-01-01', '2025-12-31', 'PRIMARY');

-- =====================================================
-- ENCOUNTERS
-- =====================================================

INSERT INTO encounters (encounter_number, patient_id, organization_id, location_id, encounter_type, encounter_status, admission_date, discharge_date, admission_source, discharge_disposition, attending_physician_id, admitting_physician_id, chief_complaint, reason_for_visit, length_of_stay_days, is_readmission, financial_class) VALUES
('ENC-2024-001', 1, 1, 3, 'INPATIENT', 'COMPLETED', '2024-01-15 08:30:00', '2024-01-20 14:00:00', 'EMERGENCY', 'HOME', 1, 2, 'Chest pain', 'Acute myocardial infarction', 5, FALSE, 'INSURANCE'),
('ENC-2024-002', 2, 2, 12, 'OUTPATIENT', 'COMPLETED', '2024-01-18 10:00:00', '2024-01-18 11:30:00', 'ROUTINE', 'HOME', 8, 8, 'Annual checkup', 'Routine physical examination', 0, FALSE, 'INSURANCE'),
('ENC-2024-003', 3, 1, 2, 'EMERGENCY', 'COMPLETED', '2024-01-20 15:45:00', '2024-01-20 20:30:00', 'EMERGENCY', 'HOME', 2, 2, 'Fall with head injury', 'Head trauma evaluation', 0, FALSE, 'MEDICARE'),
('ENC-2024-004', 4, 1, 4, 'OUTPATIENT', 'COMPLETED', '2024-01-22 09:00:00', '2024-01-22 12:00:00', 'ROUTINE', 'HOME', 3, 3, 'Scheduled surgery', 'Appendectomy', 0, FALSE, 'MEDICAID'),
('ENC-2024-005', 5, 1, 3, 'INPATIENT', 'COMPLETED', '2024-01-25 06:00:00', '2024-02-03 10:00:00', 'EMERGENCY', 'SNF', 1, 2, 'Shortness of breath', 'Congestive heart failure exacerbation', 9, TRUE, 'MEDICARE'),
('ENC-2024-006', 6, 2, 12, 'OUTPATIENT', 'COMPLETED', '2024-02-01 14:00:00', '2024-02-01 15:00:00', 'ROUTINE', 'HOME', 8, 8, 'Diabetes follow-up', 'Type 2 diabetes management', 0, FALSE, 'INSURANCE'),
('ENC-2024-007', 7, 1, 2, 'EMERGENCY', 'COMPLETED', '2024-02-05 22:30:00', '2024-02-06 02:00:00', 'EMERGENCY', 'HOME', 2, 2, 'Laceration', 'Left hand laceration requiring sutures', 0, FALSE, 'SELF_PAY'),
('ENC-2024-008', 8, 1, 9, 'OUTPATIENT', 'COMPLETED', '2024-02-10 11:00:00', '2024-02-10 12:30:00', 'REFERRAL', 'HOME', 1, 1, 'Palpitations', 'Cardiac arrhythmia evaluation', 0, FALSE, 'MEDICARE'),
('ENC-2024-009', 9, 2, 12, 'OUTPATIENT', 'COMPLETED', '2024-02-12 09:30:00', '2024-02-12 10:15:00', 'ROUTINE', 'HOME', 8, 8, 'Sore throat', 'Pharyngitis', 0, FALSE, 'INSURANCE'),
('ENC-2024-010', 10, 1, 3, 'INPATIENT', 'IN_PROGRESS', '2024-02-15 12:00:00', NULL, 'EMERGENCY', NULL, 7, 2, 'Severe abdominal pain', 'Acute pancreatitis', NULL, FALSE, 'INSURANCE');

-- =====================================================
-- DIAGNOSES
-- =====================================================

INSERT INTO diagnoses (encounter_id, patient_id, diagnosis_code, diagnosis_code_type, diagnosis_description, diagnosis_type, present_on_admission, diagnosis_date, diagnosed_by, severity, status) VALUES
(1, 1, 'I21.9', 'ICD-10', 'Acute myocardial infarction, unspecified', 'PRIMARY', TRUE, '2024-01-15', 1, 'SEVERE', 'RESOLVED'),
(1, 1, 'I10', 'ICD-10', 'Essential (primary) hypertension', 'SECONDARY', TRUE, '2024-01-15', 1, 'MODERATE', 'CHRONIC'),
(1, 1, 'E78.5', 'ICD-10', 'Hyperlipidemia, unspecified', 'COMORBIDITY', TRUE, '2024-01-15', 1, 'MILD', 'CHRONIC'),
(2, 2, 'Z00.00', 'ICD-10', 'Encounter for general adult medical examination without abnormal findings', 'PRIMARY', NULL, '2024-01-18', 8, 'MILD', 'RESOLVED'),
(3, 3, 'S06.0X0A', 'ICD-10', 'Concussion without loss of consciousness, initial encounter', 'PRIMARY', TRUE, '2024-01-20', 2, 'MODERATE', 'RESOLVED'),
(4, 4, 'K35.80', 'ICD-10', 'Unspecified acute appendicitis', 'PRIMARY', TRUE, '2024-01-22', 3, 'MODERATE', 'RESOLVED'),
(5, 5, 'I50.9', 'ICD-10', 'Heart failure, unspecified', 'PRIMARY', TRUE, '2024-01-25', 1, 'SEVERE', 'ACTIVE'),
(5, 5, 'J44.1', 'ICD-10', 'Chronic obstructive pulmonary disease with acute exacerbation', 'SECONDARY', TRUE, '2024-01-25', 1, 'SEVERE', 'ACTIVE'),
(6, 6, 'E11.9', 'ICD-10', 'Type 2 diabetes mellitus without complications', 'PRIMARY', NULL, '2024-02-01', 8, 'MODERATE', 'CHRONIC'),
(7, 7, 'S61.412A', 'ICD-10', 'Laceration without foreign body of left hand, initial encounter', 'PRIMARY', TRUE, '2024-02-05', 2, 'MILD', 'RESOLVED'),
(8, 8, 'I49.9', 'ICD-10', 'Cardiac arrhythmia, unspecified', 'PRIMARY', NULL, '2024-02-10', 1, 'MODERATE', 'ACTIVE'),
(9, 9, 'J02.9', 'ICD-10', 'Acute pharyngitis, unspecified', 'PRIMARY', NULL, '2024-02-12', 8, 'MILD', 'RESOLVED'),
(10, 10, 'K85.9', 'ICD-10', 'Acute pancreatitis, unspecified', 'PRIMARY', TRUE, '2024-02-15', 7, 'SEVERE', 'ACTIVE');

-- =====================================================
-- PROCEDURES
-- =====================================================

INSERT INTO procedures (encounter_id, patient_id, procedure_code, procedure_code_type, procedure_description, procedure_date, procedure_status, performing_physician_id, location_id, duration_minutes, anesthesia_type, is_emergent) VALUES
(1, 1, '92928', 'CPT', 'Percutaneous transcatheter placement of intracoronary stent(s)', '2024-01-15 10:30:00', 'COMPLETED', 1, 9, 90, 'SEDATION', TRUE),
(1, 1, '93010', 'CPT', 'Electrocardiogram, routine ECG with at least 12 leads; interpretation and report', '2024-01-15 08:45:00', 'COMPLETED', 1, 9, 15, 'NONE', TRUE),
(3, 3, '70450', 'CPT', 'Computed tomography, head or brain; without contrast material', '2024-01-20 16:30:00', 'COMPLETED', 2, 10, 30, 'NONE', TRUE),
(4, 4, '44970', 'CPT', 'Laparoscopy, surgical, appendectomy', '2024-01-22 09:30:00', 'COMPLETED', 3, 4, 75, 'GENERAL', FALSE),
(5, 5, '93000', 'CPT', 'Electrocardiogram, routine ECG with at least 12 leads', '2024-01-25 07:00:00', 'COMPLETED', 1, 3, 15, 'NONE', TRUE),
(5, 5, '71046', 'CPT', 'Radiologic examination, chest; 2 views', '2024-01-25 07:30:00', 'COMPLETED', 2, 10, 20, 'NONE', TRUE),
(7, 7, '12002', 'CPT', 'Simple repair of superficial wounds of scalp, neck, axillae, external genitalia, trunk and/or extremities', '2024-02-05 23:00:00', 'COMPLETED', 2, 2, 30, 'LOCAL', TRUE),
(8, 8, '93000', 'CPT', 'Electrocardiogram, routine ECG with at least 12 leads', '2024-02-10 11:15:00', 'COMPLETED', 1, 9, 15, 'NONE', FALSE),
(8, 8, '93306', 'CPT', 'Echocardiography, transthoracic, real-time with image documentation', '2024-02-10 11:45:00', 'COMPLETED', 1, 9, 45, 'NONE', FALSE),
(10, 10, '74150', 'CPT', 'Computed tomography, abdomen; without contrast material', '2024-02-15 13:00:00', 'COMPLETED', 7, 10, 30, 'NONE', TRUE);

-- =====================================================
-- CLINICAL EVENTS (Labs and Vitals)
-- =====================================================

INSERT INTO clinical_events (encounter_id, patient_id, event_type, event_code, event_description, event_date, result_value, result_unit, result_status, reference_range_low, reference_range_high, abnormal_flag, performed_by) VALUES
-- Patient 1 - MI workup
(1, 1, 'LAB_RESULT', '2532-0', 'Lactate dehydrogenase', '2024-01-15 09:00:00', '450', 'U/L', 'FINAL', 140, 280, 'ABNORMAL_HIGH', 10),
(1, 1, 'LAB_RESULT', '2157-6', 'Creatine kinase', '2024-01-15 09:00:00', '850', 'U/L', 'FINAL', 30, 200, 'ABNORMAL_HIGH', 10),
(1, 1, 'LAB_RESULT', '10839-9', 'Troponin I', '2024-01-15 09:00:00', '4.2', 'ng/mL', 'FINAL', 0, 0.04, 'CRITICAL_HIGH', 10),
(1, 1, 'VITAL_SIGN', '8480-6', 'Systolic blood pressure', '2024-01-15 08:30:00', '165', 'mmHg', 'FINAL', 90, 120, 'ABNORMAL_HIGH', 5),
(1, 1, 'VITAL_SIGN', '8462-4', 'Diastolic blood pressure', '2024-01-15 08:30:00', '95', 'mmHg', 'FINAL', 60, 80, 'ABNORMAL_HIGH', 5),
(1, 1, 'VITAL_SIGN', '8867-4', 'Heart rate', '2024-01-15 08:30:00', '102', 'beats/min', 'FINAL', 60, 100, 'ABNORMAL_HIGH', 5),
-- Patient 2 - Routine labs
(2, 2, 'LAB_RESULT', '2093-3', 'Total cholesterol', '2024-01-18 10:30:00', '185', 'mg/dL', 'FINAL', 0, 200, 'NORMAL', 10),
(2, 2, 'LAB_RESULT', '2085-9', 'HDL cholesterol', '2024-01-18 10:30:00', '55', 'mg/dL', 'FINAL', 40, 60, 'NORMAL', 10),
(2, 2, 'LAB_RESULT', '2571-8', 'Triglycerides', '2024-01-18 10:30:00', '120', 'mg/dL', 'FINAL', 0, 150, 'NORMAL', 10),
(2, 2, 'VITAL_SIGN', '8480-6', 'Systolic blood pressure', '2024-01-18 10:00:00', '118', 'mmHg', 'FINAL', 90, 120, 'NORMAL', 9),
(2, 2, 'VITAL_SIGN', '8462-4', 'Diastolic blood pressure', '2024-01-18 10:00:00', '76', 'mmHg', 'FINAL', 60, 80, 'NORMAL', 9),
-- Patient 5 - CHF exacerbation
(5, 5, 'LAB_RESULT', '33762-6', 'NT-proBNP', '2024-01-25 06:30:00', '3500', 'pg/mL', 'FINAL', 0, 125, 'CRITICAL_HIGH', 10),
(5, 5, 'LAB_RESULT', '2160-0', 'Creatinine', '2024-01-25 06:30:00', '1.8', 'mg/dL', 'FINAL', 0.7, 1.3, 'ABNORMAL_HIGH', 10),
(5, 5, 'LAB_RESULT', '6299-2', 'Urea nitrogen', '2024-01-25 06:30:00', '35', 'mg/dL', 'FINAL', 7, 20, 'ABNORMAL_HIGH', 10),
(5, 5, 'VITAL_SIGN', '2708-6', 'Oxygen saturation', '2024-01-25 06:00:00', '88', '%', 'FINAL', 95, 100, 'ABNORMAL_LOW', 5),
-- Patient 6 - Diabetes labs
(6, 6, 'LAB_RESULT', '4548-4', 'Hemoglobin A1c', '2024-02-01 14:30:00', '7.2', '%', 'FINAL', 4.0, 5.6, 'ABNORMAL_HIGH', 10),
(6, 6, 'LAB_RESULT', '2345-7', 'Glucose', '2024-02-01 14:30:00', '165', 'mg/dL', 'FINAL', 70, 100, 'ABNORMAL_HIGH', 10),
-- Patient 10 - Pancreatitis
(10, 10, 'LAB_RESULT', '1798-8', 'Amylase', '2024-02-15 12:30:00', '850', 'U/L', 'FINAL', 30, 110, 'CRITICAL_HIGH', 10),
(10, 10, 'LAB_RESULT', '1742-6', 'Lipase', '2024-02-15 12:30:00', '1250', 'U/L', 'FINAL', 0, 160, 'CRITICAL_HIGH', 10),
(10, 10, 'VITAL_SIGN', '8310-5', 'Body temperature', '2024-02-15 12:00:00', '38.5', 'Cel', 'FINAL', 36.1, 37.2, 'ABNORMAL_HIGH', 4);

-- =====================================================
-- MEDICATIONS
-- =====================================================

INSERT INTO medication_definitions (medication_name, generic_name, brand_name, ndc_code, drug_class, drug_category, dosage_form, route, strength, unit_of_measure, is_controlled_substance, dea_schedule, formulary_status) VALUES
('Aspirin 81mg Tablet', 'Aspirin', 'Bayer', '00074-3109-13', 'ANTIPLATELET', 'CARDIOVASCULAR', 'TABLET', 'ORAL', '81', 'mg', FALSE, NULL, 'TIER_1'),
('Atorvastatin 40mg Tablet', 'Atorvastatin', 'Lipitor', '00071-0155-23', 'STATIN', 'CARDIOVASCULAR', 'TABLET', 'ORAL', '40', 'mg', FALSE, NULL, 'TIER_1'),
('Lisinopril 10mg Tablet', 'Lisinopril', 'Zestril', '00071-3112-23', 'ACE_INHIBITOR', 'CARDIOVASCULAR', 'TABLET', 'ORAL', '10', 'mg', FALSE, NULL, 'TIER_1'),
('Metoprolol 50mg Tablet', 'Metoprolol', 'Lopressor', '00781-1514-01', 'BETA_BLOCKER', 'CARDIOVASCULAR', 'TABLET', 'ORAL', '50', 'mg', FALSE, NULL, 'TIER_1'),
('Furosemide 40mg Tablet', 'Furosemide', 'Lasix', '00054-3298-25', 'LOOP_DIURETIC', 'CARDIOVASCULAR', 'TABLET', 'ORAL', '40', 'mg', FALSE, NULL, 'TIER_1'),
('Metformin 500mg Tablet', 'Metformin', 'Glucophage', '00093-7214-01', 'BIGUANIDE', 'ANTIDIABETIC', 'TABLET', 'ORAL', '500', 'mg', FALSE, NULL, 'TIER_1'),
('Morphine 2mg/mL Injection', 'Morphine Sulfate', 'Morphine', '00409-1234-01', 'OPIOID', 'ANALGESIC', 'INJECTION', 'IV', '2', 'mg/mL', TRUE, 'II', 'TIER_1'),
('Amoxicillin 500mg Capsule', 'Amoxicillin', 'Amoxil', '00093-4151-01', 'PENICILLIN', 'ANTIBIOTIC', 'CAPSULE', 'ORAL', '500', 'mg', FALSE, NULL, 'TIER_1'),
('Heparin 5000 units/mL', 'Heparin Sodium', 'Heparin', '00409-2720-01', 'ANTICOAGULANT', 'CARDIOVASCULAR', 'INJECTION', 'IV', '5000', 'units/mL', FALSE, NULL, 'TIER_1'),
('Albuterol 90mcg Inhaler', 'Albuterol', 'Proventil', '00173-0682-20', 'BRONCHODILATOR', 'RESPIRATORY', 'INHALER', 'INHALATION', '90', 'mcg', FALSE, NULL, 'TIER_2');

INSERT INTO medication_orders (encounter_id, patient_id, medication_id, order_date, ordered_by, order_status, order_type, dose, route, frequency, duration_days, start_date, indication, priority) VALUES
(1, 1, 1, '2024-01-15 11:00:00', 1, 'COMPLETED', 'ROUTINE', '81 mg', 'ORAL', 'Daily', 365, '2024-01-15 12:00:00', 'Post-MI prophylaxis', 'ROUTINE'),
(1, 1, 2, '2024-01-15 11:00:00', 1, 'COMPLETED', 'ROUTINE', '40 mg', 'ORAL', 'Daily at bedtime', 365, '2024-01-15 12:00:00', 'Hyperlipidemia', 'ROUTINE'),
(1, 1, 3, '2024-01-15 11:00:00', 1, 'COMPLETED', 'ROUTINE', '10 mg', 'ORAL', 'Daily', 365, '2024-01-15 12:00:00', 'Hypertension', 'ROUTINE'),
(1, 1, 4, '2024-01-15 11:00:00', 1, 'COMPLETED', 'ROUTINE', '50 mg', 'ORAL', 'Twice daily', 365, '2024-01-15 12:00:00', 'Post-MI beta blockade', 'ROUTINE'),
(1, 1, 7, '2024-01-15 09:00:00', 2, 'COMPLETED', 'STAT', '2 mg', 'IV', 'Once', 1, '2024-01-15 09:15:00', 'Chest pain', 'STAT'),
(5, 5, 5, '2024-01-25 07:00:00', 1, 'COMPLETED', 'ROUTINE', '40 mg', 'ORAL', 'Twice daily', 10, '2024-01-25 08:00:00', 'Acute CHF exacerbation', 'URGENT'),
(6, 6, 6, '2024-02-01 14:30:00', 8, 'COMPLETED', 'ROUTINE', '500 mg', 'ORAL', 'Twice daily with meals', 90, '2024-02-01 18:00:00', 'Type 2 diabetes', 'ROUTINE'),
(9, 9, 8, '2024-02-12 10:00:00', 8, 'COMPLETED', 'ROUTINE', '500 mg', 'ORAL', 'Three times daily', 10, '2024-02-12 12:00:00', 'Bacterial pharyngitis', 'ROUTINE'),
(10, 10, 7, '2024-02-15 12:30:00', 7, 'IN_PROGRESS', 'PRN', '2-4 mg', 'IV', 'Every 4 hours as needed', 7, '2024-02-15 13:00:00', 'Severe abdominal pain', 'URGENT');

INSERT INTO medication_administrations (order_id, patient_id, encounter_id, administration_date, administered_by, dose_given, route, administration_status, patient_response) VALUES
(5, 1, 1, '2024-01-15 09:15:00', 5, '2 mg', 'IV', 'GIVEN', 'Pain decreased from 9/10 to 4/10'),
(1, 1, 1, '2024-01-15 12:00:00', 4, '81 mg', 'ORAL', 'GIVEN', 'No adverse effects'),
(2, 1, 1, '2024-01-15 20:00:00', 4, '40 mg', 'ORAL', 'GIVEN', 'No adverse effects'),
(3, 1, 1, '2024-01-16 08:00:00', 4, '10 mg', 'ORAL', 'GIVEN', 'No adverse effects'),
(4, 1, 1, '2024-01-16 08:00:00', 4, '50 mg', 'ORAL', 'GIVEN', 'No adverse effects'),
(4, 1, 1, '2024-01-16 20:00:00', 4, '50 mg', 'ORAL', 'GIVEN', 'No adverse effects'),
(6, 5, 5, '2024-01-25 08:00:00', 4, '40 mg', 'ORAL', 'GIVEN', 'Good response, diuresis noted'),
(6, 5, 5, '2024-01-25 20:00:00', 4, '40 mg', 'ORAL', 'GIVEN', 'Continued diuresis'),
(7, 6, 6, '2024-02-01 18:00:00', 9, '500 mg', 'ORAL', 'GIVEN', 'Taken with dinner, no GI upset'),
(8, 9, 9, '2024-02-12 12:00:00', 9, '500 mg', 'ORAL', 'GIVEN', 'No adverse effects');

-- =====================================================
-- ALLERGIES
-- =====================================================

INSERT INTO patient_allergies (patient_id, allergen_type, allergen_name, allergen_code, reaction_severity, reaction_description, onset_date, reported_by, verified_by) VALUES
(1, 'MEDICATION', 'Penicillin', 'PENICILLIN', 'MODERATE', 'Hives and itching', '1985-06-15', 'Patient', 1),
(3, 'MEDICATION', 'Sulfa drugs', 'SULFONAMIDE', 'SEVERE', 'Anaphylaxis', '1998-03-22', 'Patient', 2),
(4, 'FOOD', 'Shellfish', 'SHELLFISH', 'SEVERE', 'Angioedema and difficulty breathing', '2010-07-04', 'Patient', 8),
(5, 'MEDICATION', 'Morphine', 'MORPHINE', 'MILD', 'Nausea and vomiting', '2015-11-10', 'Patient', 1),
(6, 'ENVIRONMENTAL', 'Latex', 'LATEX', 'MODERATE', 'Contact dermatitis', '2018-02-14', 'Healthcare provider', 8),
(8, 'MEDICATION', 'Iodinated contrast', 'CONTRAST_MEDIA', 'MODERATE', 'Rash and pruritus', '2020-05-20', 'Patient', 1),
(10, 'FOOD', 'Peanuts', 'PEANUT', 'LIFE_THREATENING', 'Anaphylactic shock requiring epinephrine', '2005-08-30', 'Patient', 8);

-- =====================================================
-- CHARGES
-- =====================================================

INSERT INTO charges (encounter_id, patient_id, charge_date, charge_code, charge_code_type, charge_description, quantity, unit_price, total_amount, charge_status, charged_by, department, service_date) VALUES
-- Encounter 1 - MI patient
(1, 1, '2024-01-15', '99223', 'CPT', 'Initial hospital care, high complexity', 1, 350.00, 350.00, 'SUBMITTED', 1, 'CARDIOLOGY', '2024-01-15'),
(1, 1, '2024-01-15', '92928', 'CPT', 'Cardiac catheterization with stent placement', 1, 15000.00, 15000.00, 'SUBMITTED', 1, 'CARDIOLOGY', '2024-01-15'),
(1, 1, '2024-01-15', '93010', 'CPT', 'Electrocardiogram', 1, 150.00, 150.00, 'SUBMITTED', 1, 'CARDIOLOGY', '2024-01-15'),
(1, 1, '2024-01-15', '0300', 'REVENUE', 'Laboratory services', 1, 450.00, 450.00, 'SUBMITTED', NULL, 'LABORATORY', '2024-01-15'),
(1, 1, '2024-01-16', '99232', 'CPT', 'Subsequent hospital care', 4, 200.00, 800.00, 'SUBMITTED', 1, 'CARDIOLOGY', '2024-01-16'),
(1, 1, '2024-01-15', '0120', 'REVENUE', 'Room and board - ICU', 5, 3500.00, 17500.00, 'SUBMITTED', NULL, 'ICU', '2024-01-15'),
-- Encounter 2 - Annual checkup
(2, 2, '2024-01-18', '99385', 'CPT', 'Preventive visit, age 18-39', 1, 250.00, 250.00, 'PAID', 8, 'FAMILY_MEDICINE', '2024-01-18'),
(2, 2, '2024-01-18', '80061', 'CPT', 'Lipid panel', 1, 85.00, 85.00, 'PAID', NULL, 'LABORATORY', '2024-01-18'),
-- Encounter 3 - Head trauma
(3, 3, '2024-01-20', '99285', 'CPT', 'Emergency department visit, high complexity', 1, 650.00, 650.00, 'PAID', 2, 'EMERGENCY', '2024-01-20'),
(3, 3, '2024-01-20', '70450', 'CPT', 'CT head without contrast', 1, 1200.00, 1200.00, 'PAID', NULL, 'RADIOLOGY', '2024-01-20'),
-- Encounter 4 - Appendectomy
(4, 4, '2024-01-22', '44970', 'CPT', 'Laparoscopic appendectomy', 1, 8500.00, 8500.00, 'SUBMITTED', 3, 'SURGERY', '2024-01-22'),
(4, 4, '2024-01-22', '00840', 'CPT', 'Anesthesia for appendectomy', 1, 850.00, 850.00, 'SUBMITTED', NULL, 'ANESTHESIA', '2024-01-22'),
-- Encounter 5 - CHF
(5, 5, '2024-01-25', '99223', 'CPT', 'Initial hospital care, high complexity', 1, 350.00, 350.00, 'SUBMITTED', 1, 'CARDIOLOGY', '2024-01-25'),
(5, 5, '2024-01-25', '0120', 'REVENUE', 'Room and board - ICU', 9, 3500.00, 31500.00, 'SUBMITTED', NULL, 'ICU', '2024-01-25'),
(5, 5, '2024-01-26', '99232', 'CPT', 'Subsequent hospital care', 8, 200.00, 1600.00, 'SUBMITTED', 1, 'CARDIOLOGY', '2024-01-26'),
-- Encounter 6 - Diabetes follow-up
(6, 6, '2024-02-01', '99213', 'CPT', 'Office visit, established patient', 1, 150.00, 150.00, 'SUBMITTED', 8, 'FAMILY_MEDICINE', '2024-02-01'),
(6, 6, '2024-02-01', '83036', 'CPT', 'Hemoglobin A1c', 1, 65.00, 65.00, 'SUBMITTED', NULL, 'LABORATORY', '2024-02-01'),
-- Encounter 7 - Laceration repair
(7, 7, '2024-02-05', '99284', 'CPT', 'Emergency department visit', 1, 450.00, 450.00, 'PENDING', 2, 'EMERGENCY', '2024-02-05'),
(7, 7, '2024-02-05', '12002', 'CPT', 'Simple laceration repair', 1, 350.00, 350.00, 'PENDING', 2, 'EMERGENCY', '2024-02-05'),
-- Encounter 10 - Pancreatitis (ongoing)
(10, 10, '2024-02-15', '99223', 'CPT', 'Initial hospital care, high complexity', 1, 350.00, 350.00, 'PENDING', 7, 'INTERNAL_MEDICINE', '2024-02-15'),
(10, 10, '2024-02-15', '74150', 'CPT', 'CT abdomen without contrast', 1, 1400.00, 1400.00, 'PENDING', NULL, 'RADIOLOGY', '2024-02-15'),
(10, 10, '2024-02-15', '0300', 'REVENUE', 'Laboratory services', 1, 380.00, 380.00, 'PENDING', NULL, 'LABORATORY', '2024-02-15');

-- =====================================================
-- AUDIT LOG SAMPLES
-- =====================================================

INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by, ip_address) VALUES
('patients', 1, 'INSERT', '{"mrn": "MRN001234", "first_name": "James", "last_name": "Wilson"}'::jsonb, 'admin', '10.0.1.100'),
('encounters', 1, 'INSERT', '{"encounter_number": "ENC-2024-001", "patient_id": 1}'::jsonb, 'j.smith@stmarys.org', '10.0.1.101'),
('medication_orders', 1, 'INSERT', '{"medication_id": 1, "patient_id": 1, "dose": "81 mg"}'::jsonb, 'j.smith@stmarys.org', '10.0.1.101'),
('encounters', 1, 'UPDATE', '{"discharge_date": "2024-01-20 14:00:00", "encounter_status": "COMPLETED"}'::jsonb, 'j.smith@stmarys.org', '10.0.1.101');

-- =====================================================
-- Verification Queries
-- =====================================================

-- Display summary statistics
SELECT 'Total Organizations' as metric, COUNT(*) as count FROM organizations
UNION ALL
SELECT 'Total Locations', COUNT(*) FROM locations
UNION ALL
SELECT 'Total Personnel', COUNT(*) FROM personnel
UNION ALL
SELECT 'Total Patients', COUNT(*) FROM patients
UNION ALL
SELECT 'Total Encounters', COUNT(*) FROM encounters
UNION ALL
SELECT 'Active Inpatients', COUNT(*) FROM encounters WHERE encounter_status = 'IN_PROGRESS' AND encounter_type = 'INPATIENT'
UNION ALL
SELECT 'Total Diagnoses', COUNT(*) FROM diagnoses
UNION ALL
SELECT 'Total Procedures', COUNT(*) FROM procedures
UNION ALL
SELECT 'Total Lab Results', COUNT(*) FROM clinical_events WHERE event_type = 'LAB_RESULT'
UNION ALL
SELECT 'Total Medication Orders', COUNT(*) FROM medication_orders
UNION ALL
SELECT 'Total Allergies', COUNT(*) FROM patient_allergies
UNION ALL
SELECT 'Total Charges', COUNT(*) FROM charges;
