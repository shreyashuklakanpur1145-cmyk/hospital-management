# Hospital Management System — DBMS Mini Project

## Stack
- Node.js + Express
- PostgreSQL
- HTML/CSS/JavaScript frontend
- Deployment target: Render

## DBMS requirements covered
### CRUD
- CREATE: book appointment / create patient
- READ: appointments, patients, doctors, bills
- UPDATE: appointment status/date/doctor
- DELETE: appointment

### JOINs
The application uses INNER JOINs across Patients, Appointments, Doctors and Departments. See `db/joins.sql`.

### Triggers
1. `trg_prevent_double_booking` — prevents two appointments for the same doctor at the same time.
2. `trg_create_bill_on_completion` — automatically creates a bill when an appointment becomes Completed.
3. `trg_log_appointment_deletion` — writes an audit record when an appointment is deleted.

## Local setup
1. Install Node.js 18+ and PostgreSQL.
2. Create a PostgreSQL database, e.g. `hospital_db`.
3. Run:
   psql -U postgres -d hospital_db -f db/schema.sql
   psql -U postgres -d hospital_db -f db/seed.sql
4. Set DATABASE_URL:
   Windows PowerShell:
   $env:DATABASE_URL="postgresql://postgres:PASSWORD@localhost:5432/hospital_db"
5. Install dependencies:
   npm install
6. Start:
   npm start
7. Open http://localhost:3000

## Render deployment
1. Create a PostgreSQL database on Render.
2. Run `db/schema.sql` and `db/seed.sql` against the Render database.
3. Push this folder to GitHub.
4. Create a Render Web Service connected to the repository.
5. Build command: `npm install`
6. Start command: `npm start`
7. Add environment variable:
   DATABASE_URL = <Render PostgreSQL connection string>
8. Deploy. Render provides the public HTTPS URL.

## Important
Do NOT put your real DATABASE_URL/password inside the ZIP or GitHub repository. Use Render environment variables.

## Demo flow for viva
1. Add/book an appointment → CREATE.
2. Refresh appointments → READ + JOIN.
3. Change an appointment to Completed → UPDATE + automatic billing trigger.
4. Try booking the same doctor at the same date/time → double-booking trigger rejects it.
5. Delete an appointment → DELETE + audit trigger.
6. Open Audit Logs / Bills to show trigger results.
