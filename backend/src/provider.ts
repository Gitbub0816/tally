import type { FlightObservationEvent } from "./contracts";
import type { RadarSessionRow } from "./database";

interface AirLabsFlight {
  hex?: string; reg_number?: string; aircraft_icao?: string; airline_iata?: string;
  flight_iata?: string; dep_iata?: string; arr_iata?: string;
  lat?: number; lng?: number; alt?: number; dir?: number; updated?: number;
}

interface AirLabsResponse { response?: AirLabsFlight[]; error?: { message?: string } }

export async function observationsForSession(session: RadarSessionRow, env: Env): Promise<FlightObservationEvent[]> {
  const latitudeDelta = session.radius_meters / 111_320;
  const longitudeDelta = latitudeDelta / Math.max(Math.cos(session.latitude * Math.PI / 180), 0.2);
  const bbox = [session.latitude - latitudeDelta, session.longitude - longitudeDelta, session.latitude + latitudeDelta, session.longitude + longitudeDelta].map((n) => n.toFixed(5)).join(",");
  const url = new URL("https://airlabs.co/api/v9/flights");
  url.searchParams.set("api_key", env.AIRLABS_API_KEY);
  url.searchParams.set("bbox", bbox);
  url.searchParams.set("_fields", "hex,reg_number,aircraft_icao,airline_iata,flight_iata,dep_iata,arr_iata,lat,lng,alt,dir,updated");
  const response = await fetch(url, { signal: AbortSignal.timeout(15_000) });
  if (!response.ok) throw new Error(`AirLabs returned ${response.status}`);
  const payload = await response.json<AirLabsResponse>();
  if (payload.error) throw new Error(payload.error.message ?? "AirLabs request failed");
  return (payload.response ?? []).flatMap((flight): FlightObservationEvent[] => {
    if (!flight.hex || flight.lat === undefined || flight.lng === undefined) return [];
    const time = flight.updated ? new Date(flight.updated * 1000) : new Date();
    return [{
      eventId: deterministicEventId(session.id, flight.hex, time), sessionId: session.id, userId: session.user_id,
      icao24: flight.hex, registration: flight.reg_number ?? null, aircraftType: flight.aircraft_icao ?? null,
      airlineIata: flight.airline_iata ?? null, flightIata: flight.flight_iata ?? null,
      originIata: flight.dep_iata ?? null, destinationIata: flight.arr_iata ?? null,
      latitude: flight.lat, longitude: flight.lng, altitudeFeet: Math.round((flight.alt ?? 0) * 3.28084),
      headingDegrees: Math.round(flight.dir ?? 0), observedAt: time.toISOString(),
    }];
  });
}

function deterministicEventId(sessionId: string, icao24: string, time: Date): string {
  const bucket = Math.floor(time.getTime() / 120_000);
  const source = `${sessionId}:${icao24}:${bucket}`;
  let hash = 2166136261;
  for (const char of source) { hash ^= char.charCodeAt(0); hash = Math.imul(hash, 16777619); }
  const tail = (hash >>> 0).toString(16).padStart(8, "0");
  return `00000000-0000-4000-8000-0000${tail}`;
}

