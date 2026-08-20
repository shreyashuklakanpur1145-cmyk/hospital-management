-- HOSPITAL MANAGEMENT SYSTEM - PostgreSQL
DROP TABLE IF EXISTS appointment_logs, bills, appointments, doctors, departments, patients CASCADE;

CREATE TABLE departments (
  department_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE doctors (
  doctor_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  specialization VARCHAR(100) NOT NULL,
  consultation_fee NUMERIC(10,2) NOT NULL DEFAULT 500,
  department_id INT NOT NULL REFERENCES departments(department_id)
);

CREATE TABLE patients (
  patient_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  age INT NOT NULL CHECK(age BETWEEN 0 AND 120),
  gender VARCHAR(20),
  phone VARCHAR(20)
);

CREATE TABLE appointments (
  appointment_id SERIAL PRIMARY KEY,
  patient_id INT NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  doctor_id INT NOT NULL REFERENCES doctors(doctor_id) ON DELETE CASCADE,
  appointment_date TIMESTAMP NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'Scheduled'
    CHECK(status IN ('Scheduled','Completed','Cancelled'))
);

CREATE TABLE bills (
  bill_id SERIAL PRIMARY KEY,
  appointment_id INT NOT NULL UNIQUE REFERENCES appointments(appointment_id) ON DELETE CASCADE,
  consultation_fee NUMERIC(10,2) NOT NULL,
  total_amount NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE appointment_logs (
  log_id SERIAL PRIMARY KEY,
  appointment_id INT NOT NULL,
  action VARCHAR(80) NOT NULL,
  log_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- TRIGGER 1: Prevent doctor double-booking
CREATE OR REPLACE FUNCTION prevent_double_booking()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM appointments
    WHERE doctor_id = NEW.doctor_id
      AND appointment_date = NEW.appointment_date
      AND status IN ('Scheduled','Completed')
      AND appointment_id <> COALESCE(NEW.appointment_id, -1)
  ) THEN
    RAISE EXCEPTION 'Doctor is already booked for this date and time.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_double_booking
BEFORE INSERT OR UPDATE ON appointments
FOR EACH ROW EXECUTE FUNCTION prevent_double_booking();

-- TRIGGER 2: Auto-generate bill when appointment becomes Completed
CREATE OR REPLACE FUNCTION create_bill_on_completion()
RETURNS TRIGGER AS $$
DECLARE fee NUMERIC(10,2);
BEGIN
  IF NEW.status = 'Completed' AND OLD.status <> 'Completed' THEN
    SELECT consultation_fee INTO fee FROM doctors WHERE doctor_id = NEW.doctor_id;
    INSERT INTO bills(appointment_id, consultation_fee, total_amount)
    VALUES(NEW.appointment_id, fee, fee)
    ON CONFLICT (appointment_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_bill_on_completion
AFTER UPDATE OF status ON appointments
FOR EACH ROW EXECUTE FUNCTION create_bill_on_completion();

-- TRIGGER 3: Audit appointment deletion
CREATE OR REPLACE FUNCTION log_appointment_deletion()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO appointment_logs(appointment_id, action)
  VALUES(OLD.appointment_id, 'APPOINTMENT_DELETED');
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_appointment_deletion
AFTER DELETE ON appointments
FOR EACH ROW EXECUTE FUNCTION log_appointment_deletion();