# Tally

Tally is a native iOS aircraft-discovery and collecting app. Nearby aircraft become temporary contacts; people intentionally save encounters as collectible cards, build collections across aircraft types, airlines, liveries, registrations, and routes, then share them through **UNICOM**.

The repository includes both a polished credential-free demo and the complete live application path: Sign in with Apple, scoped radar sessions, licensed flight-provider ingestion, queued rarity scoring, PostgreSQL/PostGIS persistence, APNs alerts, collection sync, and ordered UNICOM frequencies.

## Product vocabulary

| Product concept | Tally term |
|---|---|
| Detected aircraft | Contact |
| Saved encounter/card | Tally |
| Social area | UNICOM |
| Social group | Frequency |
| Social post | Transmission |
| Join/follow | Tune in |
| Share | Transmit |

## Repository

```text
ios/Tally/          SwiftUI iOS application
cpp/core/           Deterministic C++ rarity engine
backend/            Cloudflare Worker, Queue, Durable Object, and Postgres schema
docs/               Architecture and product decisions
project.yml         XcodeGen project definition
```

## Run the iOS app

Requirements: Xcode 16+, iOS 17+, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open Tally.xcodeproj
```

Choose an iPhone simulator and run `Tally`. No backend credentials are needed; `AppEnvironment.demo` supplies realistic local data.

## Validate the backend and C++ core

```bash
cd backend
npm install
npm test
npm run typecheck
npm run deploy:dry

cd ../cpp
cmake -S . -B build
cmake --build build
ctest --test-dir build
```

## Architecture boundary

- The iOS app owns presentation, offline collections, card interaction, location consent, and cached UNICOM content.
- The API Worker owns authenticated HTTP contracts and writes durable records through Hyperdrive/Postgres.
- Queues decouple flight ingestion from geospatial matching, rarity scoring, notifications, and card rendering.
- A Durable Object is created per UNICOM frequency for ordered realtime coordination; PostgreSQL remains the durable social record.
- R2 stores rendered card assets. The first milestone draws aircraft cards locally and does not require R2.
- The same deterministic rarity formula is represented in Swift demo data, C++ production core, and backend tests.

See [architecture](docs/ARCHITECTURE.md), the [API contract](docs/API.md), and [keys, provisioning, and costs](docs/SETUP_AND_COSTS.md).
