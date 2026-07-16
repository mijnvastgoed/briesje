# Briesje M0 — technische architectuur- en securityspike

Status: **ontwerp en reproduceerbaar testcontract gereed; live demonstratie geblokkeerd op externe accounts/secrets**  
Onderzocht: 16 juli 2026  
Scope: GitHub Pages → Supabase Edge Functions/Postgres → Stripe Checkout in testmodus.

## Conclusie

De beoogde keten is technisch haalbaar met een kleine architectuur, mits GitHub Pages uitsluitend als publieke statische client wordt behandeld en alle prijs-, order- en betaalbeslissingen server-side plaatsvinden. Een Stripe testbetaling is in deze repository niet aangetoond: er zijn geen aantoonbaar gekoppelde Supabase- en Stripe-testaccounts, projectreferentie of testsecrets. Daardoor blijft het M0-acceptatiecriterium “testcheckout + ondertekende dubbele webhook + refund gedemonstreerd” open.

Het minimale veilige pad is:

1. De browser stuurt alleen variant-id en hoeveelheid plus een Supabase gebruikers-JWT naar `create-checkout-session`.
2. De Edge Function leest actuele, goedgekeurde varianten en prijzen uit Postgres, controleert voorraad/status/marge, maakt atomair een order met onveranderlijke prijssnapshot en maakt server-side een Stripe Checkout Session.
3. Stripe ontvangt bedrag en orderreferentie uitsluitend van de Edge Function en host de betaalpagina.
4. Alleen een geverifieerde Stripe-webhook mag een order naar `paid` brengen. De return/successpagina is informatief en nooit betaalbewijs.

GitHub omschrijft Pages als statische hosting van HTML/CSS/JavaScript en ondersteunt daar geen server-side runtime. Pages-sites zijn bovendien publiek bereikbaar, ook wanneer een betaald plan publicatie vanuit een private repository toestaat. Secrets of beheergegevens mogen daarom nooit in bron, build artifact, Actions-variabelen die in de client worden geïnjecteerd, local storage of netwerkresponses staan. [GitHub Pages: wat het is](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages), [een Pages-site maken](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site).

## Kleinste architectuur

```text
Publiek / untrusted                         Privileged                         Extern
┌──────────────────────┐       JWT/HTTPS    ┌─────────────────────────┐       ┌──────────────┐
│ GitHub Pages browser │ ─────────────────> │ create-checkout-session │ ────> │ Stripe API   │
│ publishable key      │                    │ Supabase Edge Function  │       │ testmode     │
└──────────────────────┘                    └────────────┬────────────┘       └──────┬───────┘
                                                       │ transaction                │ signed event
                                                       v                            v
                                              ┌─────────────────┐          ┌────────────────┐
                                              │ Postgres + RLS  │ <─────── │ stripe-webhook │
                                              │ order snapshot  │  admin   │ Edge Function  │
                                              └─────────────────┘          └────────────────┘
```

Voor M0 zijn precies twee functies nodig:

- `create-checkout-session`: `POST`, geldige gebruikers-JWT verplicht, strikte CORS allowlist voor de exacte Pages-origin en lokale ontwikkel-origin. Geen wildcard in productie. Rate-limit per user/IP buiten of vroeg in de functie.
- `stripe-webhook`: `POST`, `verify_jwt = false` omdat Stripe geen Supabase-token stuurt; geen CORS nodig. Verifieer vóór parsing of databasewerk de **raw request body**, `Stripe-Signature` en het endpoint-specifieke `whsec_...` secret. Supabase documenteert dit externe-webhookpatroon expliciet. [Supabase function-authenticatie](https://supabase.com/docs/guides/functions/auth), [function-configuratie](https://supabase.com/docs/guides/functions/function-configuration), [Stripe-webhookvoorbeeld voor Edge Functions](https://supabase.com/docs/guides/functions/examples/stripe-webhooks).

Secrets (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`) staan alleen in Supabase project secrets en lokale genegeerde env-bestanden. De secret/service-role key omzeilt RLS en mag nooit de browser bereiken; de publishable key mag wel publiek zijn wanneer RLS correct is. [Supabase secrets](https://supabase.com/docs/guides/functions/secrets).

### Minimale datatabellen voor de spike

- `product_variants(id, status, currency, sale_price_minor, stock_state, price_version, approved_at)`; alleen publieke leesvelden via view/RLS, geen bronkosten of marges.
- `orders(id uuid, user_id, status, currency, subtotal_minor, total_minor, price_version, checkout_attempt, stripe_checkout_session_id unique null, stripe_payment_intent_id unique null, created_at, paid_at)`.
- `order_lines(order_id, variant_id, quantity, unit_price_minor, title_snapshot, sku_snapshot)`; snapshots veranderen nooit na sessieaanmaak.
- `stripe_events(event_id primary key, event_type, object_id, livemode, payload_created_at, received_at, processed_at, outcome, error_code)`; bewaar bij voorkeur minimale metadata, niet onbeperkt volledige Stripe-payloads.

Geldbedragen zijn integer minor units (eurocenten); valuta is expliciet `EUR`. Databaseconstraints eisen positieve hoeveelheden, niet-negatieve bedragen, toegestane statussen en dezelfde valuta op orderregels. De statusmachine laat minimaal toe: `draft → checkout_pending → paid`; `checkout_pending → checkout_expired|cancelled`; `paid → refund_pending → partially_refunded|refunded`. Geen algemene client-updatepolicy op orders/statussen. Klanten mogen met RLS alleen hun eigen niet-gevoelige orders lezen.

## Checkout-contract

Request uit browser:

```json
{"items":[{"variantId":"uuid","quantity":1}],"checkoutAttempt":"client-generated-uuid"}
```

De server negeert clientprijzen, productnamen, korting en totalen. In één database-transactie worden user-id uit de geverifieerde JWT, maximumaantallen, duplicaten, publicatiestatus, prijsversie, voorraadstatus en minimumcontributieregel gevalideerd; daarna worden order plus regels vastgelegd. Bij elke nieuwe checkoutpoging wordt de prijs opnieuw berekend. Reeds betaalde orders behouden de snapshot.

Maak Stripe Checkout server-side in `payment` mode met `line_items.price_data`, uitsluitend uit de snapshot, en zet `client_reference_id=order.id` en `metadata.order_id=order.id`. Gebruik geen persoonsgegevens of gevoelige data in metadata. `success_url` bevat eventueel `{CHECKOUT_SESSION_ID}`, maar de pagina toont “betaling wordt gecontroleerd” totdat de eigen orderstatus via een geautoriseerde read `paid` is. Checkout ondersteunt een Stripe-hosted redirect en `price_data` voor een extern beheerde catalogus. [Stripe: hoe Checkout werkt](https://docs.stripe.com/payments/checkout/how-checkout-works).

Gebruik voor `checkout.sessions.create` een server-afgeleide Stripe idempotency key zoals `checkout:{order_id}:{checkout_attempt}`. Herhaling met dezelfde poging en exact dezelfde parameters levert dezelfde Stripe-response; wijzigende cart/prijs maakt een nieuwe order/poging. Stripe bewaart het resultaat van de eerste request voor een idempotency key, raadt hoog-entropische sleutels aan en kan sleutels na minimaal 24 uur verwijderen; de eigen unieke databaseconstraints blijven dus de duurzame verdediging. [Stripe idempotente requests](https://docs.stripe.com/api/idempotent_requests).

## Webhook-idempotentie en correctness

Stripe kan events dubbel en buiten volgorde leveren. De handler mag dus niet “laatste event wint” toepassen. Stripe adviseert event-id’s te registreren, alleen benodigde eventtypes te ontvangen en waarschuwt dat eventvolgorde niet gegarandeerd is. [Stripe webhooks en best practices](https://docs.stripe.com/webhooks).

Verwerkingsalgoritme:

1. Weiger niet-`POST`, ontbrekende signature en te grote body; log geen body of secrets.
2. Lees body exact één keer als tekst/bytes en voer `constructEvent(rawBody, signature, webhookSecret)` uit. Ongeldig: `400`, geen database-mutatie.
3. Weiger `event.livemode !== EXPECTED_LIVEMODE`; accepteer alleen expliciet geconfigureerde eventtypes.
4. Start database-transactie. `INSERT stripe_events(event_id, ...) ON CONFLICT DO NOTHING`; bij conflict: commit en `200` zonder businessmutatie.
5. Zoek order via vertrouwde Stripe-objectmetadata/referentie, lock de orderrij (`FOR UPDATE`) en vergelijk currency/total/session-id/payment-status met de opgeslagen snapshot. Ontbrekend of afwijkend: event markeren als `quarantined`, order niet betaald maken en alert genereren.
6. Voor `checkout.session.completed`: zet alleen `paid` als `payment_status = 'paid'`; voor uitgestelde betaalmethoden is daarnaast `checkout.session.async_payment_succeeded` nodig, terwijl `async_payment_failed` niet naar paid gaat. Een monotone statusovergang voorkomt dat een ouder event `paid` terugdraait.
7. Schrijf event-resultaat en ordermutatie atomair en commit; antwoord daarna snel `200`. Tijdelijke databasefout: `5xx`, zodat Stripe opnieuw kan leveren. Permanente ongeldige inhoud na geldige signature: registreer/quarantaineer en antwoord `2xx` om eindeloze retries te vermijden.

Voor refunds gebruikt de beheerserver een eigen unieke `refund_request_id` als Stripe idempotency key. Een API-response alleen is niet genoeg voor de definitieve lokale status; bijbehorende refund/charge-events worden opnieuw signature-geverifieerd en idempotent verwerkt. Een refund mag nooit door de publieke client rechtstreeks met een secret worden gestart.

## Trust boundaries en belangrijkste dreigingen

| Boundary/dreiging | Controle | Te bewijzen |
|---|---|---|
| Browser manipuleert prijs/quantity/variant | Server leest prijs/status, schema- en limietvalidatie | Gemanipuleerde prijs verandert totaal niet; ongeldige quantity geeft 4xx |
| Gestolen/ontbrekende login | JWT-validatie plus `user_id` uit claims, nooit requestbody | Anoniem en JWT van ander project geweigerd |
| Cross-origin misbruik | Exacte CORS allowlist; CORS is geen auth | Vreemde Origin krijgt geen allow-origin; directe call blijft JWT-beveiligd |
| Publishable key geeft datatoegang | RLS op alle exposed tabellen; gevoelige velden niet in publieke view | anon/user A kan order van user B niet lezen/schrijven |
| Valse/replayed webhook | Raw-body signature, timestamptolerantie van SDK, event-PK, object/type-dedupe waar nodig | Verkeerd secret 400; hetzelfde event 2× één mutatie |
| Dubbele checkout door retries/dubbelklik | DB-attempt uniqueness + Stripe idempotency key | Eén order/session per attempt |
| Event buiten volgorde | Monotone statusmachine, row lock, retrieve Stripe object bij twijfel | ouder expired event maakt paid niet cancelled |
| Bedrag mismatch | currency/amount/session/object vergelijken met snapshot | event in quarantaine, nooit `paid` |
| Secretlek | secretsmanager, `.gitignore`, secret scan; geen logging | repo/build/netwerk bevatten geen `sk_`, `whsec_`, secret role key |
| Open redirect / fout retouradres | vaste serverconfiguratie voor success/cancel URLs | client kan URL niet overschrijven |

Supabase Edge Functions zijn geschikt voor korte webhook- en Stripe-integraties, maar hebben runtime- en CPU-limieten. Houd de handler klein en idempotent; stuur notificaties/fulfilment later via een durable outbox/worker in plaats van het betaalcommit ervan afhankelijk te maken. [Supabase Edge Functions](https://supabase.com/docs/guides/functions), [limieten](https://supabase.com/docs/guides/functions/limits).

## Reproduceerbaar M0-testplan

### Lokale voorbereiding

Vereist: Supabase CLI plus Docker-compatible runtime, Stripe CLI, een Stripe sandbox/testaccount en een lokaal Supabase-project. Supabase noemt Docker als vereiste voor lokale function-tests. Gebruik alleen `sk_test_...`; zet lokale waarden in een gitignored bestand en verkrijg het lokale webhooksecret uit `stripe listen`. [Supabase quickstart](https://supabase.com/docs/guides/functions/quickstart).

Voorgestelde volgorde (placeholders bewust niet invullen of committen):

```sh
supabase start
supabase db reset
supabase functions serve create-checkout-session --env-file .env.test.local
supabase functions serve stripe-webhook --no-verify-jwt --env-file .env.test.local
stripe listen --forward-to http://127.0.0.1:54321/functions/v1/stripe-webhook
```

Gebruik daarna een browser/E2E-test tegen de lokale statische build en Stripe testkaarten. Leg als evidence uitsluitend test-event/session/payment/refund-id, timestamps, verwachte/werkelijke status, gehashte of synthetische klantreferentie en command exitcodes vast; geen secrets, volledige payloads of echte persoonsgegevens.

### Geautomatiseerde tests

1. Unit: prijs in centen, rounding, quantity-limiet, unavailable/prijsversie, statusovergangen en amount/currencyvergelijking.
2. DB/RLS: anon ziet geen orders; user A kan alleen eigen order lezen; geen user kan `status`, snapshots of `stripe_*` wijzigen; service-handler kan atomair verwerken.
3. Function-integratie: ontbrekende/ongeldige JWT `401`; vreemde origin zonder CORS-toestemming; clientprijs wordt genegeerd; expired/unavailable/margerisico geeft conflict en maakt geen Stripe Session.
4. Checkout-concurrency: twee simultane requests met dezelfde attempt leveren één lokale order en één Stripe Session; dezelfde idempotency key met afwijkende parameters faalt veilig.
5. Signature: ongewijzigde Stripe CLI-payload accepteert; één byte wijzigen, verkeerd secret, ontbrekende header of te oude/fout gesigneerde payload geeft `400` zonder rijmutatie.
6. Dubbel event: stuur exact hetzelfde `checkout.session.completed` event tweemaal; één `stripe_events`-rij, één transitie en één fulfilment-outboxrecord.
7. Parallel dubbel event: stuur dezelfde delivery gelijktijdig om de unieke PK/transactie echt te testen.
8. Buiten volgorde: `expired` na geldige paid-event en async-success vóór completed; eindstatus blijft conform monotone regels.
9. Mismatch: geldig gesigneerd testevent met verkeerde order/amount/currency/livemode wordt quarantained en betaalt niets uit.
10. Uitgestelde betaling: completed met `unpaid` zet niet paid; async success wel, async failed niet.
11. Refund: maak één testrefund, retry dezelfde request, verwerk webhook dubbel; precies één refund en correcte lokale status.
12. Failure injection: database tijdelijk onbeschikbaar geeft webhook `5xx`; replay na herstel verwerkt exact eenmaal.
13. Secret scan: scan gitgeschiedenis én gebouwde Pages-assets op `sk_(test|live)_`, `whsec_`, legacy service-role/secret-key patronen; resultaat nul.

### Hosted demonstratie voor aftekenen M0

- Publiceer de statische spike op een tijdelijke Pages-URL met HTTPS; koppel een afzonderlijk Supabase testproject en Stripe sandbox.
- Configureer de Stripe webhook destination op de hosted function, gepind op een gekozen API-versie en uitsluitend noodzakelijke eventtypes.
- Doorloop één succesvolle testcheckout, bewijs dat de successpagina vóór webhook geen `paid` kan forceren, resend hetzelfde event vanuit Stripe en controleer één mutatie.
- Voer één volledige en één gedeeltelijke testrefund uit indien beide in MVP worden ondersteund.
- Exporteer geschoonde logs/databasequeries als evidence en roteer/verwijder tijdelijke secrets na de spike.

## Go/no-go voor de technische M0-spike

**Voorwaardelijke technische go** voor implementatie van de spike volgens bovenstaand contract. **Nog geen M0-go en geen productieclaim**, omdat echte accountkoppeling, testtransactie, dubbele delivery, refund, RLS-testresultaten en secret-scanbewijs ontbreken. Product-, juridische, fiscale en operationele go/no-go vallen buiten dit technische bewijsdocument en blijven afzonderlijke blokkades uit `PLAN-M0.md`.

