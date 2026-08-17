import { describe, expect, it } from "vitest";
import { isPublishInput } from "../src/contracts";

describe("transmission validation", () => {
  it("accepts a valid transmission", () => {
    expect(isPublishInput({ authorId: "user-1", body: "A350 over BNA", encounterId: "enc-1" })).toBe(true);
  });

  it("rejects empty and oversized bodies", () => {
    expect(isPublishInput({ authorId: "user-1", body: "", encounterId: "enc-1" })).toBe(false);
    expect(isPublishInput({ authorId: "user-1", body: "x".repeat(501), encounterId: "enc-1" })).toBe(false);
  });
});

