export interface EncounterEvent {
  readonly eventId: string;
  readonly userId: string;
  readonly aircraftId: string;
  readonly latitude: number;
  readonly longitude: number;
  readonly altitudeFeet: number;
  readonly observedAt: string;
}

export interface FlightObservationEvent {
  readonly eventId: string;
  readonly sessionId: string;
  readonly userId: string;
  readonly icao24: string;
  readonly registration: string | null;
  readonly aircraftType: string | null;
  readonly airlineIata: string | null;
  readonly flightIata: string | null;
  readonly originIata: string | null;
  readonly destinationIata: string | null;
  readonly latitude: number;
  readonly longitude: number;
  readonly altitudeFeet: number;
  readonly headingDegrees: number;
  readonly observedAt: string;
}

export interface Transmission {
  readonly id: string;
  readonly frequencyId: string;
  readonly authorId: string;
  readonly body: string;
  readonly encounterId: string;
  readonly createdAt: string;
}

export interface PublishTransmissionInput {
  readonly authorId: string;
  readonly body: string;
  readonly encounterId: string;
}

export interface ApiError {
  readonly error: { readonly code: string; readonly message: string };
}

export function isPublishInput(value: unknown): value is PublishTransmissionInput {
  if (typeof value !== "object" || value === null) return false;
  const record = value as Record<string, unknown>;
  return typeof record.authorId === "string" &&
    typeof record.body === "string" && record.body.length > 0 && record.body.length <= 500 &&
    typeof record.encounterId === "string";
}
