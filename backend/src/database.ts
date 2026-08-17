import postgres from "postgres";
import type { FlightObservationEvent } from "./contracts";

export interface RadarSessionRow {
  readonly id: string;
  readonly user_id: string;
  readonly latitude: number;
  readonly longitude: number;
  readonly radius_meters: number;
}

function client(env: Env) {
  return postgres(env.DATABASE.connectionString, { prepare: false, max: 5 });
}

export async function createUserIfNeeded(env: Env, userId: string): Promise<void> {
  const sql = client(env);
  try {
    await sql`INSERT INTO users (id, handle, display_name)
      VALUES (${userId}, ${`collector-${userId.slice(0, 8)}`}, 'Tally Collector')
      ON CONFLICT (id) DO NOTHING`;
  } finally { await sql.end(); }
}

export async function createRadarSession(env: Env, input: { id: string; userId: string; latitude: number; longitude: number; radiusMeters: number; startsAt: string; endsAt: string }): Promise<void> {
  const sql = client(env);
  try {
    await sql`INSERT INTO radar_sessions (id, user_id, center, radius_meters, starts_at, ends_at)
      VALUES (${input.id}::uuid, ${input.userId},
        ST_SetSRID(ST_MakePoint(${input.longitude}, ${input.latitude}), 4326)::geography,
        ${input.radiusMeters}, ${input.startsAt}::timestamptz, ${input.endsAt}::timestamptz)`;
  } finally { await sql.end(); }
}

export async function activeRadarSessions(env: Env): Promise<RadarSessionRow[]> {
  const sql = client(env);
  try {
    return await sql<RadarSessionRow[]>`SELECT id::text, user_id::text,
      ST_Y(center::geometry)::float8 AS latitude,
      ST_X(center::geometry)::float8 AS longitude,
      radius_meters
      FROM radar_sessions WHERE starts_at <= now() AND ends_at > now()
      ORDER BY ends_at LIMIT 100`;
  } finally { await sql.end(); }
}

export async function persistObservation(env: Env, event: FlightObservationEvent, score: number, tier: string): Promise<void> {
  const sql = client(env);
  try {
    await sql.begin(async (transaction) => {
      const aircraftId = crypto.randomUUID();
      await transaction`INSERT INTO aircraft (id, registration, icao24, manufacturer, model, operator_name, metadata)
        VALUES (${aircraftId}::uuid, ${event.registration ?? event.icao24}, ${event.icao24}, 'Unknown', ${event.aircraftType ?? 'Unknown'}, ${event.airlineIata}, '{}'::jsonb)
        ON CONFLICT (registration) DO UPDATE SET icao24 = EXCLUDED.icao24, model = EXCLUDED.model`;
      await transaction`INSERT INTO encounters
        (id, user_id, aircraft_id, radar_session_id, observed_at, position, altitude_feet, flight_number, origin_iata, destination_iata, rarity_score, rarity, rarity_factors)
        SELECT ${event.eventId}::uuid, ${event.userId}, id, ${event.sessionId}::uuid, ${event.observedAt}::timestamptz,
          ST_SetSRID(ST_MakePoint(${event.longitude}, ${event.latitude}), 4326)::geography,
          ${event.altitudeFeet}, ${event.flightIata}, ${event.originIata}, ${event.destinationIata}, ${score}, ${tier}::rarity_tier,
          ${JSON.stringify({ localScarcity: 0.5 })}::jsonb
        FROM aircraft WHERE registration = ${event.registration ?? event.icao24}
        ON CONFLICT (id) DO NOTHING`;
    });
  } finally { await sql.end(); }
}

export interface EncounterRow {
  readonly id: string; readonly registration: string; readonly manufacturer: string;
  readonly model: string; readonly operator_name: string | null; readonly flight_number: string | null;
  readonly origin_iata: string | null; readonly destination_iata: string | null; readonly observed_at: string;
  readonly altitude_feet: number | null; readonly rarity_score: number; readonly rarity: string;
  readonly collected_at: string | null;
}

export async function listEncounters(env: Env, userId: string): Promise<EncounterRow[]> {
  const sql = client(env);
  try {
    return await sql<EncounterRow[]>`SELECT e.id::text, a.registration, a.manufacturer, a.model,
      a.operator_name, e.flight_number, e.origin_iata, e.destination_iata,
      to_char(e.observed_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') AS observed_at,
      e.altitude_feet, e.rarity_score, e.rarity::text, e.collected_at::text
      FROM encounters e JOIN aircraft a ON a.id = e.aircraft_id
      WHERE e.user_id = ${userId} ORDER BY e.observed_at DESC LIMIT 200`;
  } finally { await sql.end(); }
}

export async function collectEncounter(env: Env, userId: string, encounterId: string): Promise<boolean> {
  const sql = client(env);
  try {
    const rows = await sql`UPDATE encounters SET collected_at = COALESCE(collected_at, now())
      WHERE id = ${encounterId}::uuid AND user_id = ${userId} RETURNING id`;
    return rows.length === 1;
  } finally { await sql.end(); }
}

export async function upsertDeviceToken(env: Env, userId: string, token: string, environment: string): Promise<void> {
  const sql = client(env);
  try {
    await sql`INSERT INTO device_tokens (token, user_id, environment) VALUES (${token}, ${userId}, ${environment})
      ON CONFLICT (token) DO UPDATE SET user_id = EXCLUDED.user_id, environment = EXCLUDED.environment, updated_at = now()`;
  } finally { await sql.end(); }
}

export async function deviceTokens(env: Env, userId: string): Promise<Array<{ token: string; environment: string }>> {
  const sql = client(env);
  try { return await sql<Array<{ token: string; environment: string }>>`SELECT token, environment FROM device_tokens WHERE user_id = ${userId}`; }
  finally { await sql.end(); }
}

export async function persistTransmission(env: Env, transmission: { id: string; frequencyId: string; authorId: string; encounterId: string; body: string; createdAt: string }): Promise<void> {
  const sql = client(env);
  try {
    await sql.begin(async transaction => {
      const frequencyId = crypto.randomUUID();
      await transaction`INSERT INTO frequencies (id, channel, name, visibility, created_by)
        VALUES (${frequencyId}::uuid, ${transmission.frequencyId}::numeric, ${`Frequency ${transmission.frequencyId}`}, 'public', ${transmission.authorId})
        ON CONFLICT (channel) DO NOTHING`;
      await transaction`INSERT INTO transmissions (id, frequency_id, author_id, encounter_id, body, created_at)
        SELECT ${transmission.id}::uuid, id, ${transmission.authorId}, ${transmission.encounterId}::uuid, ${transmission.body}, ${transmission.createdAt}::timestamptz
        FROM frequencies WHERE channel = ${transmission.frequencyId}::numeric ON CONFLICT (id) DO NOTHING`;
    });
  } finally { await sql.end(); }
}
