# Onafhankelijke herreview Briesje-webshop (R2)

Datum: 16 juli 2026  
Scope: correcties op frontend/functioncontract, `public_catalog`, webhook-rowcount, CSP/CDN, Pages-workflow en contracttest  

## Oordeel

- **Publieke demo volgens het bindende M0-contract: FAIL (1 P0-blokker).**
- **Technische, afgeschermde lokale demo: PASS**, mits `CHECKOUT_ENABLED=false` blijft.
- **Live verkoop: FAIL / NO-GO.** De eerder beschreven operationele en contractuele P1-blokkers blijven bestaan.

## Hercontrole van de aangeleverde correcties

| Correctie | R2-oordeel | Bewijs |
|---|---|---|
| Frontend/functioncontract | PASS | `web/app.js:34` stuurt `shippingCountry:"NL"` en leest `checkoutUrl`; de Edge Function valideert/retourneert dezelfde velden op regels 23 en 37. |
| Publieke catalogus | PASS | `public.public_catalog` projecteert alleen de overeengekomen velden en alleen `catalog.sellable=true`; demo-seed blijft leeg in deze view. |
| Webhook-rowcount | PASS voor het gemelde defect | De RPC controleert na de betaalstatusupdate exact één gewijzigde rij en quarantine bij een ongeldige statusovergang. |
| CSP / gepinde browserdependency | DEELS | Versie `2.49.8` is vastgezet en een meta-CSP is aanwezig. Er is geen SRI/hash of lokaal gevendorde dependency. GitHub Pages levert geen header-CSP en `frame-ancestors` kan niet via meta worden afgedwongen. |
| Pages-workflow | PASS voor demo-artifact | De workflow uploadt exact `web/`, controleert kernassets/demolabel en voert een beperkte secretscan uit. Relatieve paden ondersteunen repository Pages-basepaths. |
| Contracttest | PASS als statische regressietest | De test borgt beide veldnamen, catalogusview en afwezigheid van voor de hand liggende sleutels. Het is geen runtime-, RLS- of E2E-test. |

## Resterende blokker voor publieke demo

### P0 — de hosted demo schendt het bindende spikecontract

M0 §13 bepaalt dat een hosted spike prominent **“TEST — GEEN VERKOOP”** toont, alleen voor aangewezen testers toegankelijk is via een server-side allowlist en geen echte SKU bevat. De huidige publieke Pages-workflow heeft geen toegangscontrole. Bovendien worden de twee echte AliExpress item- en SKU-ID's letterlijk naar de browser gedeployed (`web/app.js:6-7`) en toont de UI alleen “Demowinkel · Bestellen en betalen is nog niet mogelijk” (`web/index.html:17`), niet het voorgeschreven prominente label.

GitHub Pages kan zelf geen server-side tester-allowlist afdwingen. Daardoor mag deze artifactversie volgens het eigen bindende contract niet publiek worden gedeployed, ook al kan er niet worden betaald.

Vereiste oplossing: maak voor publieke Pages een puur synthetisch artifact zonder echte item-/SKU-ID's, toon exact en prominent “TEST — GEEN VERKOOP”, en pas M0 via een bewuste herbeslissing aan als een openbare demo gewenst is. Als de allowlist bindend blijft, gebruik dan een hostinglaag met echte server-side toegang of houd de demo lokaal/privé.

## Resterende blokkers voor live verkoop

### P1 — checkoutmodel is nog een technische spike

Checkout is account-only; gastcheckout ontbreekt. De server krijgt geen postcode/bestemmingsdetail vóór prijsbepaling en maakt geen verse logistieke quote. De RPC telt alleen opgeslagen artikelprijzen op. Btw, verzendkosten, retourkosten, kostenledger, prijsformule en margedrempels zijn niet als immutable calculatie vastgelegd.

### P1 — contract- en consumentenbewijs ontbreekt

De orderdraft bewaart geen archival render/copy van productinformatie, levertijd, herkomst, verkoper, voorwaarden, privacy- en herroepingsinformatie. Expliciete instemming, duurzame bevestiging, modelformulier en ordergebonden herroepingsfunctie ontbreken. De knoptekst benoemt geen betalingsverplichting.

### P1 — betaallevenscyclus is incompleet

Het rowcountdefect is gesloten, maar `async_payment_failed` wordt slechts genegeerd en laat de order `checkout_pending`. Expiratie, refunds, partial refunds, disputes, bedragreconciliatie, adresmismatch en out-of-order statusovergangen buiten betalen zijn niet geïmplementeerd of getest.

### P1 — RLS/securitybewijs ontbreekt

De zichtbare read-own-policies en beperkte grants zijn een goede basis. De pgTAP-suite test echter niet twee gebruikers, anon versus authenticated, IDOR, sessievervalsing/-intrekking, service-rolegrenzen of security-definer-RPC's. Er is geen echte database-/function-/Stripe-E2E-run als bewijs.

### P1 — operationele M0-gates blijven rood

Leveranciersidentiteit/contract, officiële AliExpress-feed, productveiligheidsdocumenten en samples, EU-verantwoordelijke, Nederlandse retourroute, fiscale/importbeslissing, professionele juridische/fiscale/productreview en echte Stripe/Supabase-testtransacties ontbreken nog. Geen codecorrectie kan deze bewijsverplichtingen vervangen.

## Niet-blokkerende verbeterpunten voor een lokale demo

- Het winkelmandpaneel heeft nog geen focus trap, focus-return of `inert`; filters missen `aria-pressed`.
- De CSP blokkeert inline `style`-attributen die de productkaartkleuren zetten; functionaliteit blijft bestaan, maar er ontstaan CSP-meldingen en visuele degradatie. Ook `404.html` gebruikt inline style.
- De Pages-secretscan zoekt slechts enkele patronen en scant niet het uiteindelijke artifact met een gespecialiseerde scanner.
- GitHub Actions zijn op tags (`@v4`, `@v5`, `@v3`) en niet op commit-SHA's gepind.
- Supabase/Stripe-imports in Edge Functions gebruiken brede packageversies (`@2`, `@16`) en zijn daardoor niet reproduceerbaar vastgezet.

## Validatie

Statische inspectie uitgevoerd van storefront, CSP, workflow, contracttest, migraties, RLS/grants, Edge Functions en webhook-RPC. De contractvelden en project-basepath zijn consistent. Node, Deno en Supabase CLI waren niet beschikbaar in de review-shell; daarom konden de Node-contracttest, pgTAP, lokale migraties en functiontests niet onafhankelijk worden uitgevoerd.

## Vrijgaveadvies

1. **Lokaal/privé demonstreren:** akkoord, met lege browserconfig of synthetische Supabase-data en `CHECKOUT_ENABLED=false`.
2. **Publiek op GitHub Pages:** nog niet volgens M0; sluit eerst de hosted-spike P0 hierboven of wijzig het contract expliciet met een onderbouwde risicoacceptatie.
3. **Live verkoop/betaling:** niet vrijgeven; alle genoemde P1- en operationele gates moeten aantoonbaar worden gesloten en onafhankelijk herbeoordeeld.
