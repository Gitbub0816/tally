import { route } from "./router";
import { consumeEncounterEvents } from "./queue";
import { FrequencyRoom } from "./frequency-room";
import type { FlightObservationEvent } from "./contracts";
import { activeRadarSessions } from "./database";
import { observationsForSession } from "./provider";

export { FrequencyRoom };

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      return await route(request, env);
    } catch (error: unknown) {
      console.error(JSON.stringify({ event: "request.failed", reason: error instanceof Error ? error.message : "unknown" }));
      return Response.json({ error: { code: "internal_error", message: "Request failed" } }, { status: 500 });
    }
  },
  async queue(batch: MessageBatch<FlightObservationEvent>, env: Env): Promise<void> {
    await consumeEncounterEvents(batch, env);
  },
  async scheduled(_controller: ScheduledController, env: Env, ctx: ExecutionContext): Promise<void> {
    ctx.waitUntil(pollActiveSessions(env));
  },
} satisfies ExportedHandler<Env, FlightObservationEvent>;

async function pollActiveSessions(env: Env): Promise<void> {
  const sessions = await activeRadarSessions(env);
  for (const session of sessions) {
    try {
      const observations = await observationsForSession(session, env);
      if (observations.length > 0) await env.ENCOUNTER_EVENTS.sendBatch(observations.map((body) => ({ body })));
    } catch (error: unknown) {
      console.error(JSON.stringify({ event: "provider.poll_failed", sessionId: session.id, reason: error instanceof Error ? error.message : "unknown" }));
    }
  }
}
