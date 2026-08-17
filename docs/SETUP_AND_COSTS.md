# Keys, provisioning, and current costs

Prices below are public list prices checked August 16, 2026; usage and taxes vary. Verify a provider's checkout page before purchase.

## Required credentials

| Credential | Where it goes | Cost |
|---|---|---|
| Apple Developer membership, Team ID, bundle ID `app.tally.ios` | Xcode signing and Worker `APPLE_CLIENT_ID` | **$99/year**; APNs and Sign in with Apple are included |
| APNs `.p8` private key, Key ID, Team ID, bundle ID | Worker APNs secrets | No per-message fee beyond membership |
| Cloudflare account ID and scoped API token | Wrangler/GitHub Actions deployment | Workers Paid starts at **$5/month** |
| Neon Postgres connection string | used once to create the Hyperdrive binding | Free dev tier; Launch is usage-based, typical **$15/month** |
| AirLabs API key | Worker `AIRLABS_API_KEY` secret | recommended 100k-query tier **$99/month**; 1m **$499/month** |
| Random Tally JWT secret (32+ bytes) | `SESSION_SIGNING_SECRET` | Free; generate with `openssl rand -base64 48` |

`INGEST_API_KEY` is reserved for a future provider webhook and should also be random. Native MapKit, APNs, and Sign in with Apple do not require Google Maps or Firebase keys.

## Expected spend

- Local/demo development: **$0/month**, with the app running entirely from included sample data.
- Device/TestFlight development: Apple **$99/year**; Cloudflare, Neon, and provider evaluation tiers can remain free while limits fit.
- Recommended small launch: Cloudflare $5 + Neon about $15 + AirLabs 100k $99 = **about $119/month**, plus Apple $99/year and an optional domain (usually $10–20/year).

AirLabs polling occurs only for active sessions, every two minutes. One continuously active search zone is about 21,600 queries per 30 days. Deduplicating overlapping zones is the first scaling optimization; do not assume 100k queries supports thousands of always-on zones.

Cloudflare included/overage highlights: Workers Paid includes 10m requests/month; R2 includes 10 GB-month with free egress; Queues includes 1m operations/month; Hyperdrive adds no separate query fee. See official pricing: [Workers](https://developers.cloudflare.com/workers/platform/pricing/), [R2](https://developers.cloudflare.com/r2/pricing/), [Queues](https://developers.cloudflare.com/queues/platform/pricing/), [Durable Objects](https://developers.cloudflare.com/durable-objects/platform/pricing/), and [Hyperdrive](https://developers.cloudflare.com/hyperdrive/platform/pricing/).

Provider alternatives: [AirLabs](https://airlabs.co/) is the implemented self-serve bbox adapter. [FlightAware AeroAPI](https://www.flightaware.com/commercial/aeroapi/) starts at a $100/month Standard minimum and may add per-query charges, but offers a more enterprise-oriented route. Confirm mobile redistribution/derived-data rights in writing with either provider.

## Provisioning

```bash
cd backend
cp .dev.vars.example .dev.vars
npm ci

# Apply db/001_initial.sql to a Neon database, then:
npx wrangler hyperdrive create tally-postgres --connection-string="$TALLY_DATABASE_URL"
# Replace the placeholder Hyperdrive id in wrangler.jsonc.
npx wrangler queues create tally-encounter-events
npx wrangler queues create tally-encounter-events-dlq
npx wrangler r2 bucket create tally-card-assets

npx wrangler secret put APPLE_CLIENT_ID
npx wrangler secret put SESSION_SIGNING_SECRET
npx wrangler secret put AIRLABS_API_KEY
npx wrangler secret put APNS_KEY_ID
npx wrangler secret put APNS_TEAM_ID
npx wrangler secret put APNS_BUNDLE_ID
npx wrangler secret put APNS_PRIVATE_KEY
npm test && npm run typecheck && npm run deploy:dry
```

Set `TALLY_API_BASE_URL` in the Xcode target to the deployed Worker URL. For automated deployment, add only `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` as GitHub Actions secrets; Apple signing secrets are unnecessary for the simulator compile job.
