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

## Accounts, betalingen en leverancierssync

Een signup maakt via een database-trigger een minimaal profiel. Klanten kunnen onder RLS uitsluitend hun eigen profiel, orders en orderregels lezen; alle order- en betaalmutaties blijven server-only. Checkout haalt prijzen opnieuw uit de database en Stripe-webhooks vergelijken sessie, valuta en bedrag met de immutable snapshot.

`sync-supplier-products` is een adaptercontract voor een **officieel geautoriseerde API/feed**. Het accepteert alleen HTTPS naar de exact geconfigureerde host, blokkeert redirects, hanteert timeout- en payloadlimieten en valideert iedere product/SKU-match. Er is geen HTML-parser of scraper. Pas het endpoint/responsecontract uitsluitend aan op basis van de echte officiële API-documentatie en contracttestfixtures.

Sync-observaties zijn privé en zetten `source_data_status` en `price_status` naar `pending` (of `blocked` bij geen voorraad). Sync kan nooit compliance, leverancier, logistiek, prijs of publicatie goedkeuren. Een menselijke pricing-ledgerreview moet een nieuwe verkoopprijs en alle vijf gates goedkeuren voordat checkout mogelijk is.

Externe vereisten voor live gebruik:

- Supabase-project en SMTP-configuratie met exacte redirect-allowlist;
- Stripe-account, uitsluitend testsecrets tot alle M0-gates zijn bewezen;
- officiële leverancier-API-overeenkomst, endpointdocumentatie en credentials;
- professionele compliance-, fiscale en juridische goedkeuring plus productbewijs;
- scheduler die de sync met `SUPPLIER_SYNC_SECRET` aanroept en alerts op `5xx`/oude observaties.

## Automatische fulfilment

Na uitsluitend een geverifieerd betaald Stripe-event maakt dezelfde databasetransactie maximaal één `fulfillment_jobs`-rij per order. Het verzendadres staat in een private tabel zonder clientpolicy; webhookbody's of adressen worden niet gelogd. Ontbrekende verse quote/SKU-mapping leidt tot `manual_review`, nooit tot bestellen.

`process-fulfillment` claimt één job met `FOR UPDATE SKIP LOCKED` en een lease. Vóór bestellen vraagt de worker opnieuw prijs en voorraad op en vergelijkt die met de immutable ceiling. Daarna verstuurt de goedgekeurde gateway het officiële `aliexpress.trade.buy.placeorder`-contract met exact product, SKU, aantal, gekozen tracked logistics service en `allow_substitution=false`. De gateway moet TOP signing/session-auth afhandelen én de Briesje `Idempotency-Key` duurzaam afdwingen. Zonder schriftelijke bevestiging daarvan blijft `FULFILLMENT_GATEWAY_IDEMPOTENCY_CONFIRMED=false`.

Netwerk-/5xx-fouten worden met dezelfde key opnieuw geprobeerd; verlopen leases zijn herclaimbaar en na acht pogingen volgt `manual_review`. `REPEATED_ORDER_ERROR`/HTTP 409 wordt niet blind herhaald maar vereist reconciliatie. Tracking wordt minimaal opgeslagen in `fulfillment_tracking`. Annulering vóór submit wordt lokaal `cancelled`; na submit wordt dit `cancel_requested` voor een afzonderlijk, professioneel goedgekeurd provider-cancelproces.

De directe TOP-route is `https://eco.taobao.com/router/rest`; methodecontract: `aliexpress.trade.buy.placeorder`. Configureer deze URL niet als generieke JSON-gateway tenzij de adapter ook de vereiste TOP signing, sessieautorisatie en officiële request/response-transformatie implementeert. Zie de officiële [API-documentatie](https://developer.alibaba.com/docs/api.htm?apiId=35446).

Het Briesje-gatewaycontract normaliseert een succesvolle response naar `{ "is_success": true, "order_list": [{ "order_id": "niet-lege-string" }] }`. Ook wanneer TOP numerieke order-ID's retourneert, moet de gateway die verliesvrij als string leveren. Een ontbrekende, numerieke of lege ID gaat naar `manual_review`; Briesje verzint of cast geen provider-ID.
