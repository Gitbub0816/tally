import type { FlightObservationEvent } from "./contracts";
import { deviceTokens, persistObservation } from "./database";
import { rarity } from "./rarity";
import { sendPriorityPush } from "./apns";

export async function consumeEncounterEvents(batch: MessageBatch<FlightObservationEvent>, env: Env): Promise<void> {
  for (const message of batch.messages) {
    try {
      const result = rarity({
        typeScarcity: message.body.aircraftType ? 0.35 : 0.6,
        liveryScarcity: 0,
        operatorScarcity: message.body.airlineIata ? 0.25 : 0.65,
        localScarcity: 0.5,
        eventSignificance: 0,
        firstPersonalSighting: true,
      });
      await persistObservation(env, message.body, result.score, result.tier);
      if (result.score >= 60) {
        const registration = message.body.registration ?? message.body.icao24.toUpperCase();
        await Promise.all((await deviceTokens(env, message.body.userId)).map(device =>
          sendPriorityPush(env, device, `${result.tier.toUpperCase()} contact found`, `${registration} is inside your active radar session.`)));
      }
      console.log(JSON.stringify({
        event: "encounter.accepted",
        eventId: message.body.eventId,
        aircraftId: message.body.registration ?? message.body.icao24,
      }));
      message.ack();
    } catch (error: unknown) {
      console.error(JSON.stringify({
        event: "encounter.failed",
        eventId: message.body.eventId,
        reason: error instanceof Error ? error.message : "unknown",
      }));
      message.retry();
    }
  }
}
