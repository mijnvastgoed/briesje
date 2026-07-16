import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@16?target=denonext";
import { cors, json, required } from "../_shared/http.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

Deno.serve(async (req) => {
  const corsHeaders = cors(req.headers.get("origin"));
  if (req.method === "OPTIONS") return corsHeaders ? new Response(null, { status: 204, headers: corsHeaders }) : json({ error: "origin_not_allowed" }, 403);
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405, corsHeaders ?? {});
  if (!corsHeaders) return json({ error: "origin_not_allowed" }, 403);
  try {
    if (Deno.env.get("CHECKOUT_ENABLED") !== "true") return json({ error: "checkout_disabled" }, 503, corsHeaders);
    const stripeKey = required("STRIPE_SECRET_KEY"), stripeMode = Deno.env.get("STRIPE_MODE") ?? "test";
    const safeMode = stripeMode === "test" ? stripeKey.startsWith("sk_test_") : stripeMode === "live" && Deno.env.get("LIVE_PAYMENTS_ENABLED") === "true" && stripeKey.startsWith("sk_live_");
    if (!safeMode) return json({ error: "payment_mode_not_enabled" }, 503, corsHeaders);
    const auth = req.headers.get("authorization") ?? "";
    if (!auth.startsWith("Bearer ")) return json({ error: "authentication_required" }, 401, corsHeaders);
    const url = required("SUPABASE_URL"), anon = required("SUPABASE_ANON_KEY"), service = required("SUPABASE_SERVICE_ROLE_KEY");
    const userClient = createClient(url, anon, { global: { headers: { Authorization: auth } } });
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) return json({ error: "authentication_required" }, 401, corsHeaders);
    const body = await req.json();
    if (!UUID.test(body.checkoutAttempt ?? "") || body.shippingCountry !== "NL" || !Array.isArray(body.items)) return json({ error: "invalid_request" }, 400, corsHeaders);
    const admin = createClient(url, service);
    const { data: draft, error } = await admin.rpc("create_checkout_draft", { p_user_id: user.id, p_checkout_attempt: body.checkoutAttempt, p_items: body.items, p_shipping_country: "NL" });
    if (error) return json({ error: "cart_not_sellable" }, 409, corsHeaders);
    const orderId = draft.orderId;
    const { data: lines, error: linesError } = await admin.from("order_lines").select("quantity,currency,unit_price_minor,title_snapshot").eq("order_id", orderId);
    if (linesError || !lines?.length) return json({ error: "checkout_unavailable" }, 503, corsHeaders);
    const stripe = new Stripe(stripeKey, { apiVersion: "2024-06-20" });
    const session = await stripe.checkout.sessions.create({ mode: "payment", client_reference_id: orderId, metadata: { order_id: orderId },
      line_items: lines.map((l) => ({ quantity: l.quantity, price_data: { currency: l.currency.toLowerCase(), unit_amount: l.unit_price_minor, product_data: { name: l.title_snapshot } } })),
      success_url: required("CHECKOUT_SUCCESS_URL"), cancel_url: required("CHECKOUT_CANCEL_URL"), shipping_address_collection: { allowed_countries: ["NL"] }
    }, { idempotencyKey: `checkout:${orderId}:${body.checkoutAttempt}` });
    const { error: saveError } = await admin.rpc("record_checkout_session", { p_order_id: orderId, p_session_id: session.id });
    if (saveError) return json({ error: "checkout_unavailable" }, 503, corsHeaders);
    return json({ checkoutUrl: session.url, orderId }, 200, corsHeaders);
  } catch (error) {
    console.error(error instanceof Error ? error.message : "checkout_failure");
    return json({ error: "checkout_unavailable" }, 503, corsHeaders);
  }
});
