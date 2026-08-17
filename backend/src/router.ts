import { authenticate, exchangeAppleToken } from "./auth";
import { isPublishInput } from "./contracts";
import { collectEncounter, createRadarSession, createUserIfNeeded, listEncounters, persistTransmission, upsertDeviceToken } from "./database";

const jsonHeaders = { "content-type": "application/json; charset=utf-8" } as const;

function json(value: unknown, status = 200): Response {
  return Response.json(value, { status, headers: jsonHeaders });
}

function frequencyFrom(pathname: string): string | null {
  const match = pathname.match(/^\/v1\/frequencies\/([0-9]{3}\.[0-9]{3})\/transmissions$/);
  return match?.[1] ?? null;
}

export async function route(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  if (request.method === "GET" && url.pathname === "/v1/health") {
    return json({ status: "ok", service: "tally-edge", environment: env.ENVIRONMENT });
  }
  if (request.method === "POST" && url.pathname === "/v1/auth/apple") {
    const value: unknown = await request.json();
    if (!isAppleAuthInput(value)) return json({ error: { code: "invalid_token", message: "Apple identity token required" } }, 422);
    try {
      const token = await exchangeAppleToken(value.identityToken, env);
      const principal = await authenticate(new Request(request.url, { headers: { authorization: `Bearer ${token}` } }), env);
      if (principal) await createUserIfNeeded(env, principal.userId);
      return json({ token });
    } catch {
      return json({ error: { code: "invalid_token", message: "Apple identity token could not be verified" } }, 401);
    }
  }
  const principal = await authenticate(request, env);
  if (!principal) return json({ error: { code: "unauthorized", message: "Sign in with Apple is required" } }, 401);
  if (request.method === "POST" && url.pathname === "/v1/radar-sessions") {
    const value: unknown = await request.json();
    if (!isRadarSessionInput(value)) return json({ error: { code: "invalid_session", message: "Invalid radar session" } }, 422);
    const id = crypto.randomUUID();
    await createRadarSession(env, { id, userId: principal.userId, ...value });
    return json({ id }, 201);
  }
  if (request.method === "GET" && url.pathname === "/v1/encounters") {
    return json({ encounters: await listEncounters(env, principal.userId) });
  }
  const collection = url.pathname.match(/^\/v1\/encounters\/([0-9a-f-]{36})\/collect$/i);
  if (request.method === "POST" && collection) {
    return await collectEncounter(env, principal.userId, collection[1]!) ? json({ collected: true }) : json({ error: { code: "not_found", message: "Encounter not found" } }, 404);
  }
  if (request.method === "POST" && url.pathname === "/v1/devices") {
    const value: unknown = await request.json();
    if (!isDeviceInput(value)) return json({ error: { code: "invalid_device", message: "Invalid APNs device token" } }, 422);
    await upsertDeviceToken(env, principal.userId, value.token, value.environment);
    return json({ registered: true }, 201);
  }
  const frequencyId = frequencyFrom(url.pathname);
  if (frequencyId && request.method === "GET") {
    const room = env.FREQUENCIES.getByName(frequencyId);
    return json({ frequency: frequencyId, transmissions: await room.recent(30) });
  }
  if (frequencyId && request.method === "POST") {
    const value: unknown = await request.json();
    if (!isPublishInput(value)) return json({ error: { code: "invalid_transmission", message: "Transmission must be 1–500 characters" } }, 422);
    const room = env.FREQUENCIES.getByName(frequencyId);
    const transmission = await room.publish(frequencyId, { ...value, authorId: principal.userId });
    await persistTransmission(env, transmission);
    return json(transmission, 201);
  }
  return json({ error: { code: "not_found", message: "Route not found" } }, 404);
}

function isDeviceInput(value: unknown): value is { token: string; environment: "development" | "production" } {
  if (typeof value !== "object" || value === null) return false;
  const item = value as Record<string, unknown>;
  return typeof item.token === "string" && /^[0-9a-f]{64,200}$/i.test(item.token) && (item.environment === "development" || item.environment === "production");
}

function isAppleAuthInput(value: unknown): value is { identityToken: string } {
  return typeof value === "object" && value !== null && typeof (value as Record<string, unknown>).identityToken === "string";
}

function isRadarSessionInput(value: unknown): value is { latitude: number; longitude: number; radiusMeters: number; startsAt: string; endsAt: string } {
  if (typeof value !== "object" || value === null) return false;
  const item = value as Record<string, unknown>;
  return typeof item.latitude === "number" && typeof item.longitude === "number" &&
    typeof item.radiusMeters === "number" && item.radiusMeters >= 100 && item.radiusMeters <= 100_000 &&
    typeof item.startsAt === "string" && typeof item.endsAt === "string";
}
