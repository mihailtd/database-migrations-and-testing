import { describe, test, expect } from "bun:test";
import { Pool } from "pg";

const connectionString = "postgresql://demo-owner:5G6S%3F-d%28tBAC%3ENn.%7DbIj%5Ei.8@localhost:5432/demo";

const pool = new Pool({ connectionString });

describe("scheduling", () => {
  test("should schedule a task", async () => {
    const client = await pool.connect();

    const practitionerResult = await client.query(
      `INSERT INTO practitioner(name, email, planning_horizon) 
        VALUES ('Dr. John Doe', 'test@test.test', 7) RETURNING id;`
    );

    const availabilityResult = await client.query(
      `INSERT INTO practitioner_availability(practitioner_id, all_day, start_time, end_time, slot_size)
        VALUES ($1, TRUE, '09:00', '17:00', 60) RETURNING id;`,
      [practitionerResult.rows[0].id]
    );

    await client.query(
      `INSERT INTO practitioner_availability_day_of_week(practitioner_availability_id, day_of_week_id)
        VALUES ($1, 1), ($1, 2), ($1, 3), ($1, 4), ($1, 5);`,
      [availabilityResult.rows[0].id]
    );

    // execute the function that generates the slots
    await client.query(`SELECT generate_appointment_slots($1)`, [practitionerResult.rows[0].id]);

    const slotsResult = await client.query(`SELECT * FROM slot WHERE practitioner_availability_id = $1`, [
      availabilityResult.rows[0].id
    ]);

    expect(slotsResult.rowCount).toEqual(40);
  });
});
