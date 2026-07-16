import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@16?target=denonext";
import { json, required } from "../_shared/http.ts";

const accepted = new Set(["checkout.session.completed", "checkout.session.async_payment_succeeded", "checkout.session.async_payment_failed"]);
Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const signature = req.headers.get("stripe-signature");
  if (!signature || Number(req.headers.get("content-length") ?? 0) > 1_000_000) return json({ error: "invalid_webhook" }, 400);
  try {
    const key = required("STRIPE_SECRET_KEY");
    if (!key.startsWith("sk_test_") || Deno.env.get("EXPECTED_STRIPE_LIVEMODE") !== "false") return json({ error: "test_mode_required" }, 503);
    const raw = await req.text();
    if (raw.length > 1_000_000) return json({ error: "invalid_webhook" }, 400);
    const stripe = new Stripe(key, { apiVersion: "2024-06-20" });
    const event = await stripe.webhooks.constructEventAsync(raw, signature, required("STRIPE_WEBHOOK_SECRET"));
    if (event.livemode || !accepted.has(event.type)) return json({ received: true, outcome: "ignored" });
    const session = event.data.object as Stripe.Checkout.Session;
    const orderId = session.metadata?.order_id ?? session.client_reference_id;
    if (!orderId) return json({ received: true, outcome: "quarantined" });
    try {
      const admin = createClient(required("SUPABASE_URL"), required("SUPABASE_SERVICE_ROLE_KEY"));
      const { data, error } = await admin.rpc("process_checkout_event", { p_event_id:event.id,p_event_type:event.type,p_object_id:session.id,p_livemode:event.livemode,
        p_created_at:new Date(event.created*1000).toISOString(),p_order_id:orderId,p_currency:session.currency ?? "",p_amount_total:session.amount_total ?? -1,
        p_payment_status:session.payment_status,p_payment_intent_id:typeof session.payment_intent === "string" ? session.payment_intent : null });
      if (error) throw error;
      return json({ received: true, outcome: data });
    } catch {
      console.error("webhook_database_failure");
      return json({ error: "webhook_unavailable" }, 503);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "webhook_failure";
    console.error(message.startsWith("missing_") ? message : "webhook_rejected");
    return json({ error: message.startsWith("missing_") ? "webhook_unavailable" : "invalid_webhook" }, message.startsWith("missing_") ? 503 : 400);
  }
});
