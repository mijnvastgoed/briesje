# Onafhankelijke review Briesje-webshop

Datum: 16 juli 2026  
Scope: `web/`, `supabase/`, `PLAN.md` en `evidence/M0-ACCEPTANCE-CONTRACT.md`  
Uitkomst: **FAIL — geen deploy-/checkoutclaim; demostorefront is wel fail-closed bruikbaar**

## Geprioriteerde bevindingen

### P0 — checkoutcontract tussen browser en Edge Function is incompatibel

`web/app.js:34` stuurt geen `shippingCountry`, terwijl `supabase/functions/create-checkout-session/index.ts:23` exact `shippingCountry === "NL"` eist. Iedere checkout eindigt daardoor met `invalid_request`. Zelfs na herstel daarvan leest de browser `data.url`, terwijl de functie op regel 37 `checkoutUrl` retourneert. De browser zal dus iedere succesvolle sessie alsnog als ongeldig blokkeren. Dit is veilig/fail-closed, maar de betaalflow werkt nooit.

Herstel: definieer één gedeeld request/responsecontract; stuur `{shippingCountry:"NL"}` en kies consequent `url` of `checkoutUrl`. Voeg een contracttest toe die browserpayload, functionvalidatie en responseveld samen uitvoert.

### P1 — implementatie voldoet niet aan het bindende checkoutcontract

De huidige flow vereist een account (`web/app.js:34`, `orders.user_id NOT NULL`), terwijl §6 gastcheckout én vrijwillig account vereist. Daarnaast ontbreekt bestemming/postcode vóór definitieve prijs, een logistieke quote, btw/verzend-/retourkosten, immutable voorwaarden- en informatiesnapshots en expliciete instemming. De huidige RPC telt uitsluitend `sale_price_minor` op (`202607160002_checkout_rpcs.sql:15-35`). Dit is geen productierijpe checkout volgens PLAN/M0.

Herstel: checkout uitgeschakeld houden. Modelleer eerst orderdraft, bestemming, quote/TTL, prijsledger, contractarchief en gasttokenflow; laat Stripe pas daarna starten.

### P1 — Stripe-eventstatus kan foutief als verwerkt worden geregistreerd

`process_checkout_event` markeert een betaald event altijd `processed`, ook wanneer de orderupdate niets wijzigt (bijvoorbeeld een out-of-order event nadat de order al is geannuleerd/refunded). Er is geen `FOUND`-controle na de update. Ook `async_payment_failed` blijft slechts `ignored`; de order blijft onbeperkt `checkout_pending`. Refunds, disputes, expiratie en reconciliatie uit M0 zijn niet geïmplementeerd.

Herstel: leg een expliciete statusovergangstabel vast, verifieer dat exact één toegestane overgang plaatsvond en quarantine anders; implementeer expiratie/failure/refund/dispute vóór productie.

### P1 — RLS/securitytestdekking is onvoldoende

De policies voor `orders` en `order_lines` zijn in beginsel correct voor read-own en er zijn geen client-write grants. De test controleert echter alleen of RLS actief is. Verplichte tests voor twee gebruikers, anon, vervalste JWT/IDOR, service role en sessie-intrekking ontbreken. Er zijn evenmin geautomatiseerde tests voor de security-definer RPC's, dubbele/out-of-order webhooks of bedragmismatch. Hierdoor is de securityclaim niet bewijsbaar.

Herstel: voeg database-integratietests met twee echte auth-identiteiten toe en test allow/deny-matrices plus RPC execute privileges en event-idempotentie.

### P1 — GitHub Pages-deployment en browserbeveiliging ontbreken

Er is geen GitHub Actions Pages-workflow aangetroffen, geen artifact-/secret-scan en geen productiebuildcontrole. Relatieve assets (`styles.css`, `app.js`, `assets/...`) zijn wel compatibel met een repository-basepath. Op GitHub Pages kan de repository zelf geen HTTP security headers zetten; er is geen gedocumenteerde/geteste CSP-strategie. De runtime laadt Supabase-JS ongepind vanaf jsDelivr zonder SRI (`web/app.js:19`), wat de supply-chain- en CSP-eisen niet haalt.

Herstel: voeg een Pages-workflow toe met expliciete `web/` artifact-root, scans en smokecheck; vendore/pin de client of gebruik exact versie+integrity; documenteer welke headers Pages niet kan leveren en kies zo nodig een host/proxy die ze wel afdwingt.

### P2 — winkelmandpaneel mist modale focusafhandeling

Het winkelmandje is een `aside` met alleen `aria-hidden`; bij openen gaat focus niet naar het paneel, focus wordt niet begrensd en bij sluiten niet teruggezet. Toetsenbord- en screenreadergebruikers kunnen achter de zichtbare scrim navigeren. De filters communiceren hun actieve status alleen via CSS, niet via `aria-pressed`.

Herstel: gebruik bij voorkeur een native `dialog`, of implementeer focus-in/focus-return/inert en correcte dialogsemantiek; beheer `aria-pressed` op filters.

### P2 — runtimeconfiguratie en auth-redirect zijn handmatig en ongetest

`web/config.js` is bewust leeg en dus veilig, maar er is geen deploymentstap die de echte publieke URL/key injecteert. `config.toml` allowlist alleen localhost; GitHub Pages redirect/origin moet exact worden ingesteld. De magic-link redirect volgt `location.origin + location.pathname`, wat repository-basepaths correct kan behouden, maar een expliciete allowlist en hosted test ontbreken.

## Positieve observaties

- Seedproducten zijn demo en alle vijf statussen blijven standaard `pending`; `public_catalog` bevat alleen `sellable=true` varianten.
- Definitieve prijzen worden server-side uit varianten opgehaald; browserbedragen worden niet vertrouwd.
- Tabellen met bronvarianten en Stripe-events zijn niet rechtstreeks beschikbaar voor anon/authenticated; orders hebben read-own RLS.
- Webhooksignatuur, testmode, bedrag, valuta, sessie-ID en event-ID-deduplicatie worden gecontroleerd.
- AliExpress-referenties blijven geblokkeerd; de storefront communiceert duidelijk dat verkoop niet actief is.
- Relatieve browserassets ondersteunen GitHub Pages onder een project-basepath; JavaScript gebruikt geen absolute `/`-assetpaden.

## Uitgevoerde statische validatie

- Alle HTML/JS/CSS, migraties, Edge Functions, seed, test-SQL en configuratiebestanden handmatig/statisch geïnspecteerd.
- Contractzoektocht uitgevoerd op viewnaam, checkoutvelden, shipping country, security headers en dialogsemantiek.
- Python `compileall` uitgevoerd (geen Python-bronnen/fouten).
- Node, Deno en Supabase CLI waren in de beschikbare shell niet aanwezig; JS/TS typecheck, lokale database-reset en pgTAP konden daarom niet werkelijk worden uitgevoerd. De aangeleverde schema-test is bovendien intern veranderd tijdens de review; deze review gebruikt de uiteindelijke zichtbare versie met `public.public_catalog`.

## Acceptatieadvies

De huidige site mag uitsluitend als duidelijke **TEST — GEEN VERKOOP**-demo worden gepubliceerd. Houd `CHECKOUT_ENABLED=false`. Voor een volgende review moeten minimaal P0, de P1-eventstatuskwestie, echte RLS/contracttests en een reproduceerbare Pages/Supabase-deployment zijn opgelost. Publieke verkoop blijft daarnaast terecht NO-GO totdat alle M0-bedrijfs-, compliance-, prijs- en logistieke gates aantoonbaar groen zijn.
