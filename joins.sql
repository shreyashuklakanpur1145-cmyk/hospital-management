-- Representative JOIN queries for DBMS demonstration

-- 1. Patient + doctor + department + appointment
SELECT a.appointment_id, p.name AS patient, d.name AS doctor,
       dept.name AS department, a.appointment_date, a.status
FROM appointments a
JOIN patients p ON p.patient_id=a.patient_id
JOIN doctors d ON d.doctor_id=a.doctor_id
JOIN departments dept ON dept.department_id=d.department_id;

-- 2. Doctors and their patients
SELECT d.name AS doctor, p.name AS patient
FROM doctors d
JOIN appointments a ON a.doctor_id=d.doctor_id
JOIN patients p ON p.patient_id=a.patient_id;

-- 3. Bills with patient and doctor
SELECT b.bill_id, p.name AS patient, d.name AS doctor,
       b.total_amount
FROM bills b
JOIN appointments a ON a.appointment_id=b.appointment_id
JOIN patients p ON p.patient_id=a.patient_id
JOIN doctors d ON d.doctor_id=a.doctor_id;