import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const read = (path) => readFile(new URL(path, import.meta.url), "utf8");
const [checkout, webhook, sync, migration, fulfillmentMigration, fulfillment, config] = await Promise.all([
  read("../functions/create-checkout-session/index.ts"), read("../functions/stripe-webhook/index.ts"),
  read("../functions/sync-supplier-products/index.ts"), read("../migrations/202607160003_accounts_supplier_sync.sql"),
  read("../migrations/202607160004_fulfillment.sql"), read("../functions/process-fulfillment/index.ts"), read("../config.toml")
]);

assert.match(checkout, /create_checkout_draft/, "checkout delegates atomic draft validation to Postgres");
assert.match(checkout, /shippingCountry !== "NL"/, "checkout remains NL-only");
assert.match(webhook, /constructEventAsync\(raw, signature/, "webhook verifies the unparsed raw body");
assert.match(webhook, /event\.livemode !==/, "webhook enforces configured Stripe mode");
assert.match(sync, /protocol!=="https:"/, "supplier integration requires HTTPS");
assert.match(sync, /hostname!==allowedHost/, "supplier host is allowlisted exactly");
assert.match(sync, /redirect:"error"/, "supplier integration refuses redirects");
assert.doesNotMatch(sync, /cheerio|DOMParser|text\/html/i, "supplier integration contains no scraper");
assert.match(migration, /Sync may only tighten gates/, "supplier sync cannot auto-approve");
assert.match(migration, /enable row level security/g, "new private/account tables enable RLS");
assert.match(config, /\[storage\.vector\]\nenabled = false/, "config preserves disabled vector storage");
assert.match(config, /otp_length = 8/, "config preserves remote email OTP length");
assert.match(fulfillmentMigration, /unique references public\.orders/, "one durable fulfillment job exists per order");
assert.match(fulfillmentMigration, /skip locked/, "workers claim jobs without duplicate concurrent work");
assert.match(fulfillmentMigration, /status='processing' and lease_until<now\(\)/, "expired processing leases are retryable");
assert.match(fulfillmentMigration, /attempt_count>=8/, "retry limit transitions to manual review");
assert.match(fulfillmentMigration, /provider_order_id_required/, "submitted jobs require a nonempty provider order id");
assert.match(fulfillmentMigration, /p_payment_status='paid'[\s\S]*insert into fulfillment_jobs/, "only paid event path queues fulfillment");
assert.match(fulfillment, /aliexpress\.trade\.buy\.placeorder/, "worker names the official AliExpress order method");
assert.match(fulfillment, /FULFILLMENT_GATEWAY_IDEMPOTENCY_CONFIRMED/, "worker requires an approved idempotent gateway contract");
assert.match(fulfillment, /price_ceiling_exceeded/, "worker performs a fresh price ceiling check");
assert.match(fulfillment, /allow_substitution:false/, "worker explicitly prohibits substitutions");
assert.match(fulfillment, /typeof providerOrderId!=="string"/, "gateway must normalize provider order IDs to strings");
assert.doesNotMatch(fulfillment, /console\.(?:log|error)\([^)]*(?:address|payload|response|result)/, "worker never logs PII payloads or provider responses");

console.log("Briesje backend security contracts: PASS");
