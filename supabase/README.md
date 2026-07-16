# Briesje Supabase backend

Deze backend is standaard fail-closed. De seed bevat alleen synthetische demo-artikelen; `catalog.sellable` is voor alle rijen `false`. Checkout vereist een ingelogde testgebruiker, exacte `NL`-bestemming, verse data, vijf onafhankelijke goedkeuringen, alle secrets, `CHECKOUT_ENABLED=true` en een `sk_test_` Stripe-sleutel.

```sh
cp supabase/.env.example supabase/.env.local
supabase start
supabase db reset
supabase test db
supabase functions serve --env-file supabase/.env.local
```

Gebruik voor de webhook lokaal `stripe listen --forward-to http://127.0.0.1:54321/functions/v1/stripe-webhook`. Commit `.env.local`, Stripe-payloads en persoonsgegevens nooit. `create-checkout-session` accepteert bewust nog geen gastcheckout: dat vereist eerst het beveiligde, roteerbare gasttokencontract uit M0.
