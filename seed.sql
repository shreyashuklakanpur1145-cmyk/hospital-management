INSERT INTO departments(name) VALUES
('Cardiology'), ('Neurology'), ('Orthopedics'), ('General Medicine');

INSERT INTO doctors(name,specialization,consultation_fee,department_id) VALUES
('Dr. Sharma','Cardiology',800,1),
('Dr. Verma','Neurology',700,2),
('Dr. Mehta','Orthopedics',600,3),
('Dr. Patel','General Medicine',500,4);

INSERT INTO patients(name,age,gender,phone) VALUES
('Rahul Kumar',29,'Male','9988776655'),
('Priya Singh',34,'Female','8877665544'),
('Aarav Shah',41,'Male','9900112233'),
('Neha Patel',26,'Female','9011223344');

INSERT INTO appointments(patient_id,doctor_id,appointment_date,status) VALUES
(1,1,'2026-09-10 10:00:00','Scheduled'),
(2,2,'2026-09-10 11:00:00','Completed'),
(3,3,'2026-09-11 12:00:00','Scheduled'),
(4,4,'2026-09-12 09:30:00','Scheduled');

-- Demonstrates UPDATE + billing trigger
UPDATE appointments SET status='Completed' WHERE appointment_id=2;