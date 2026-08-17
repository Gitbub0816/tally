import { DurableObject } from "cloudflare:workers";
import type { PublishTransmissionInput, Transmission } from "./contracts";

export class FrequencyRoom extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    ctx.blockConcurrencyWhile(async () => {
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS transmissions (
          id TEXT PRIMARY KEY,
          frequency_id TEXT NOT NULL,
          author_id TEXT NOT NULL,
          body TEXT NOT NULL,
          encounter_id TEXT NOT NULL,
          created_at TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS transmissions_created_at
          ON transmissions(created_at DESC);
      `);
    });
  }

  publish(frequencyId: string, input: PublishTransmissionInput): Transmission {
    const transmission: Transmission = {
      id: crypto.randomUUID(),
      frequencyId,
      authorId: input.authorId,
      body: input.body,
      encounterId: input.encounterId,
      createdAt: new Date().toISOString(),
    };
    this.ctx.storage.sql.exec(
      `INSERT INTO transmissions
       (id, frequency_id, author_id, body, encounter_id, created_at)
       VALUES (?, ?, ?, ?, ?, ?)`,
      transmission.id,
      transmission.frequencyId,
      transmission.authorId,
      transmission.body,
      transmission.encounterId,
      transmission.createdAt,
    );
    return transmission;
  }

  recent(limit = 30): Transmission[] {
    const safeLimit = Math.max(1, Math.min(limit, 100));
    return this.ctx.storage.sql.exec<{
      id: string; frequency_id: string; author_id: string; body: string;
      encounter_id: string; created_at: string;
    }>(
      `SELECT id, frequency_id, author_id, body, encounter_id, created_at
       FROM transmissions ORDER BY created_at DESC LIMIT ?`,
      safeLimit,
    ).toArray().map((row) => ({
      id: row.id,
      frequencyId: row.frequency_id,
      authorId: row.author_id,
      body: row.body,
      encounterId: row.encounter_id,
      createdAt: row.created_at,
    }));
  }
}

