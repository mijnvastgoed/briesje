import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const app = await readFile(new URL("../web/app.js", import.meta.url), "utf8");
const checkout = await readFile(new URL("../supabase/functions/create-checkout-session/index.ts", import.meta.url), "utf8");
const schema = await readFile(new URL("../supabase/migrations/202607160001_initial_schema.sql", import.meta.url), "utf8");

assert.match(app, /shippingCountry:"NL"/, "frontend sends the NL-only destination contract");
assert.match(checkout, /body\.shippingCountry !== "NL"/, "function validates the same destination contract");
assert.match(app, /data\?\.checkoutUrl/, "frontend reads checkoutUrl");
assert.match(checkout, /checkoutUrl: session\.url/, "function returns checkoutUrl");
assert.ok(app.includes("checkout\\.stripe\\.com"), "frontend allowlists the Stripe Checkout host");
assert.match(schema, /create view public\.public_catalog[\s\S]*where sellable = true;/, "public catalog is approved-only");
assert.doesNotMatch(app, /sk_(?:live|test)_/, "frontend contains no Stripe secret");

console.log("Briesje frontend/backend contract: PASS");
