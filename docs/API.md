# Tally edge API

All routes are under `/v1` and return JSON. Apart from health and Apple token exchange, routes require `Authorization: Bearer <Tally session JWT>`.

| Method | Route | Purpose |
|---|---|---|
| GET | `/health` | Deployment health |
| POST | `/auth/apple` | Exchange an Apple identity token for a short-lived Tally JWT |
| POST | `/radar-sessions` | Start a bounded, opt-in aircraft search zone |
| GET | `/encounters` | Read the signed-in collector's newest 200 contacts |
| POST | `/encounters/:id/collect` | Intentionally save a contact |
| POST | `/devices` | Register a development or production APNs token |
| GET | `/frequencies/:channel/transmissions` | Read the ordered frequency timeline |
| POST | `/frequencies/:channel/transmissions` | Transmit a collected encounter (1–500 characters) |

The Worker polls the configured licensed provider every two minutes only while radar sessions are active. Provider observations are queued, scored idempotently, stored through Hyperdrive, and eligible rare contacts are sent through APNs.

Channel-like numbers are social identifiers inside Tally; they do not transmit on or claim access to aviation radio spectrum.
