const express = require("express");
const cors = require("cors");
const path = require("path");
const { Pool } = require("pg");

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false
});

app.get("/api/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "ok", database: "connected" });
  } catch (e) { res.status(500).json({ status: "error", error: e.message }); }
});

/* READ + JOIN */
app.get("/api/appointments", async (req, res) => {
  try {
    const q = `
      SELECT a.appointment_id, p.name AS patient_name, p.age, p.gender,
             d.name AS doctor_name, d.specialization,
             dept.name AS department,
             TO_CHAR(a.appointment_date, 'YYYY-MM-DD HH24:MI') AS appointment_date,
             a.status
      FROM appointments a
      JOIN patients p ON p.patient_id = a.patient_id
      JOIN doctors d ON d.doctor_id = a.doctor_id
      JOIN departments dept ON dept.department_id = d.department_id
      ORDER BY a.appointment_date DESC, a.appointment_id DESC`;
    res.json((await pool.query(q)).rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

/* CREATE */
app.post("/api/appointments", async (req, res) => {
  const { patient_name, age, gender, phone, doctor_id, appointment_date } = req.body;
  if (!patient_name || !age || !doctor_id || !appointment_date)
    return res.status(400).json({ error: "Patient name, age, doctor and date are required." });
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const p = await client.query(
      `INSERT INTO patients(name, age, gender, phone) VALUES($1,$2,$3,$4) RETURNING patient_id`,
      [patient_name, age, gender || null, phone || null]
    );
    await client.query(
      `INSERT INTO appointments(patient_id, doctor_id, appointment_date)
       VALUES($1,$2,$3)`, [p.rows[0].patient_id, doctor_id, appointment_date]
    );
    await client.query("COMMIT");
    res.status(201).json({ message: "Appointment created successfully." });
  } catch (e) {
    await client.query("ROLLBACK");
    res.status(400).json({ error: e.message });
  } finally { client.release(); }
});

/* UPDATE */
app.put("/api/appointments/:id", async (req, res) => {
  const { status, appointment_date, doctor_id } = req.body;
  try {
    const r = await pool.query(
      `UPDATE appointments
       SET status = COALESCE($1,status),
           appointment_date = COALESCE($2,appointment_date),
           doctor_id = COALESCE($3,doctor_id)
       WHERE appointment_id=$4
       RETURNING appointment_id`,
      [status || null, appointment_date || null, doctor_id || null, req.params.id]
    );
    if (!r.rowCount) return res.status(404).json({ error: "Appointment not found." });
    res.json({ message: "Appointment updated successfully." });
  } catch (e) { res.status(400).json({ error: e.message }); }
});

/* DELETE — fires database audit trigger */
app.delete("/api/appointments/:id", async (req, res) => {
  try {
    const r = await pool.query(
      "DELETE FROM appointments WHERE appointment_id=$1 RETURNING appointment_id",
      [req.params.id]
    );
    if (!r.rowCount) return res.status(404).json({ error: "Appointment not found." });
    res.json({ message: "Appointment deleted. Database trigger logged the deletion." });
  } catch (e) { res.status(400).json({ error: e.message }); }
});

app.get("/api/doctors", async (req, res) => {
  try {
    const q = `SELECT d.doctor_id, d.name, d.specialization, dept.name AS department,
                      d.consultation_fee
               FROM doctors d JOIN departments dept ON dept.department_id=d.department_id
               ORDER BY d.name`;
    res.json((await pool.query(q)).rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get("/api/patients", async (req, res) => {
  try { res.json((await pool.query("SELECT * FROM patients ORDER BY patient_id DESC")).rows); }
  catch (e) { res.status(500).json({ error: e.message }); }
});

app.get("/api/logs", async (req, res) => {
  try { res.json((await pool.query("SELECT * FROM appointment_logs ORDER BY log_time DESC")).rows); }
  catch (e) { res.status(500).json({ error: e.message }); }
});

app.get("/api/bills", async (req, res) => {
  try {
    const q = `SELECT b.bill_id, p.name AS patient_name, d.name AS doctor_name,
                      b.consultation_fee, b.total_amount,
                      TO_CHAR(b.created_at,'YYYY-MM-DD HH24:MI') AS created_at
               FROM bills b
               JOIN appointments a ON a.appointment_id=b.appointment_id
               JOIN patients p ON p.patient_id=a.patient_id
               JOIN doctors d ON d.doctor_id=a.doctor_id
               ORDER BY b.bill_id DESC`;
    res.json((await pool.query(q)).rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get("/api/stats", async (req, res) => {
  try {
    const q = `SELECT
      (SELECT COUNT(*) FROM patients) AS patients,
      (SELECT COUNT(*) FROM doctors) AS doctors,
      (SELECT COUNT(*) FROM appointments) AS appointments,
      (SELECT COUNT(*) FROM bills) AS bills`;
    res.json((await pool.query(q)).rows[0]);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get("*", (req, res) => res.sendFile(path.join(__dirname, "public", "index.html")));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Hospital DBMS running on port ${PORT}`));