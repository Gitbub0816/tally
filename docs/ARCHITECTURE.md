# Tally architecture

## Implemented product

Tally is a native SwiftUI aircraft-discovery and collecting app with four finished surfaces: Contacts radar, the card Collection, UNICOM social frequencies, and collector Profile/settings. Demo mode is credential-free and persists collection decisions and radar state. Live mode adds Sign in with Apple, scoped radar sessions, AirLabs observations, deterministic rarity, APNs alerts, authenticated sync, and durable UNICOM transmissions.

The Objective-C++ bridge is deliberately thin. Swift owns UI and networking; the portable C++20 core owns deterministic rarity scoring and has independent tests. That keeps a future high-throughput native processor possible without putting C++ into ordinary app code.

## Production topology

```text
iOS (SwiftUI + Objective-C++ bridge)
  │ Sign in with Apple / HTTPS / APNs
  ▼
Cloudflare Worker ── Hyperdrive ── Neon PostgreSQL + PostGIS
  │        │
  │        └── Frequency Durable Objects ── durable social write
  │
  ├── scheduled active-session polls ── AirLabs
  └── Queue ── rarity processor ── encounter write ── APNs

R2 card-assets bucket is provisioned for generated/shareable artwork; v1 cards render natively.
```

## Processor choices

The repository implements the simplest reliable launch split:

- Worker request processor: auth, validation, radar, collection, and social contracts. Fast and globally distributed.
- Scheduled provider adapter: isolates flight-data licensing/vendor changes from the app.
- Queue encounter processor: retries/idempotency, rarity calculation, persistence, and priority alerts outside requests.
- Frequency Durable Object: a single ordering authority per UNICOM frequency.
- C++ rarity core: portable deterministic business logic; keep expensive future track matching or card rasterization in a container/Batch service rather than request Workers.

Alternatives are intentionally replaceable. FlightAware can replace AirLabs for stronger aviation enterprise support, at higher/minimum pricing. A managed container can replace the TypeScript rarity implementation when track volume warrants native C++; the public score contract and tests remain the boundary.

## Rarity model

```text
14% aircraft-type scarcity
25% exact-livery scarcity
12% operator scarcity
31% local contextual scarcity
12% event significance
 6% first personal sighting
```

Inputs are clamped to `[0,1]` and the result to `[0,100]`: Frequent 0–34, Notable 35–59, Rare 60–77, Exceptional 78–91, Singular 92–100. Cards show human-readable reasons so scores are explainable.

## Privacy and reliability

- Radar is explicit, time-bounded, and stores a search center—not a continuous trail.
- Public posts contain airport/city context, never a home coordinate.
- Postgres IDs and queue event IDs make observation ingestion idempotent.
- Cloudflare secrets are never committed; `.dev.vars` is ignored.
- Provider handling must respect blocked/sensitive aircraft and redistribution rights.
- Before App Store public release, complete policy/legal review for reporting, blocking, moderation, account deletion, privacy disclosures, and licensed airline artwork. These are operational launch requirements, not mocked buttons.
