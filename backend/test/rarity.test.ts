import { describe, expect, it } from "vitest";
import { rarity } from "../src/rarity";

describe("rarity parity", () => {
  it("makes the same type rarer in an unusual location", () => {
    const common = rarity({ typeScarcity: 0.55, liveryScarcity: 0, operatorScarcity: 0, localScarcity: 0.12, eventSignificance: 0, firstPersonalSighting: true });
    const local = rarity({ typeScarcity: 0.55, liveryScarcity: 0, operatorScarcity: 0, localScarcity: 0.95, eventSignificance: 0, firstPersonalSighting: true });
    expect(local.score).toBeGreaterThan(common.score);
  });
  it("classifies a fully scarce event as singular", () => {
    expect(rarity({ typeScarcity: 1, liveryScarcity: 1, operatorScarcity: 1, localScarcity: 1, eventSignificance: 1, firstPersonalSighting: true }).tier).toBe("singular");
  });
});
