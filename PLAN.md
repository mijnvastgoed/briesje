# Briesje — masterplan

## Doel

Briesje wordt een Nederlandstalige, mobile-first dropshipping-webshop voor draagbare ventilatoren. De storefront wordt vanuit GitHub gepubliceerd; Supabase verzorgt database, accounts en serverfuncties; Stripe Checkout verzorgt betalingen. De MVP vermijdt vaste hostingkosten, maar transactiekosten, een domein en eventueel later betaald verbruik blijven voor rekening van de eigenaar.

## Niet-onderhandelbare uitgangspunten

- Geen AliExpress-scraping. Product, variant, voorraad en prijs komen uit een officieel toegestane AliExpress API/feed of worden administratief beheerd totdat toegang beschikbaar is.
- Geen geheime sleutels in browsercode, GitHub Pages of git. AliExpress- en Stripe-secrets staan uitsluitend in Supabase secrets.
- De server berekent altijd de definitieve prijs; nooit vertrouwen op bedragen uit de browser of winkelmand.
- Een bestelling wordt pas `paid` na een geverifieerde Stripe-webhook. Webhooks zijn idempotent.
- Producten gaan automatisch op `unavailable` bij ontbrekende prijs, verdachte prijssprong, ontbrekende variant, onvoldoende marge of mislukte compliance-check.
- Geen product wordt gepubliceerd zonder leverancier, herkomst, realistische levertijd, retourroute, GPSR/CE-documentatie waar van toepassing en traceerbare verantwoordelijke marktdeelnemer.
- Briesje is de verkoper richting de consument en neemt retouren, garantie, terugbetaling en klantenservice niet af van AliExpress.
- Alle wettelijke informatie staat zichtbaar vóór betalen; sinds 19 juni 2026 bevat het account/besteloverzicht een online herroepingsfunctie.
- Geen nep-kortingen, schaarste, reviews of misleidende Nederlandse herkomst.
- Toegankelijkheid, privacy, security, testbaarheid en eenvoudige architectuur zijn acceptatiecriteria, geen latere opsmuk.

## Prijsregel (configureerbaar, server-side)

`verkoopprijs = afronden_naar_0,95((inkoopprijs_EUR + geschatte_verzendkosten + risicobuffer) / (1 - btw - betaalfeepercentage - doelmarge))`

De implementatie bewaart per variant de bronprijs, valuta, wisselkoers, verzending, berekende verkoopprijs, reden en timestamp. Een prijswijziging werkt alleen door voor nieuwe winkelmandberekeningen; betaalde bestellingen houden een onveranderlijke prijssnapshot. Grote wijzigingen vereisen handmatige goedkeuring. Btw- en invoerinstellingen worden pas geactiveerd na controle door boekhouder/fiscalist.

## Startcatalogus

- Bronproduct A: AliExpress item `1005008081738393`, voorkeurs-SKU `12000043648049237`.
- Bronproduct B: AliExpress item `1005007529621225`, voorkeurs-SKU `12000041184498228`.
- Aanvullende zoekgroepen via de officiële productzoek-API: nekventilator, opvouwbare bureauventilator, clip-on kinderwagenventilator, USB-handventilator, campingventilator met lamp en mini-luchtkoeler.
- Kandidaten worden niet automatisch gepubliceerd. Selectie vereist EU-leverbaarheid, voldoende marge, consistente beoordeling/verkoopgeschiedenis, acceptabele levertijd en complete veiligheidsinformatie.

## Milestones

- **M0 — haalbaarheid en compliance:** leveranciers/API-toegang, productdocumenten, retouradres, KvK/btw/IOSS-keuze, Stripe-account en acceptatiecriteria vastleggen. Stop/go-besluit.
- **M1 — fundering en catalogus:** app-shell, design tokens, Supabase-schema/RLS, seedcatalogus, productlijst en productdetail met echte of duidelijk gemarkeerde beheerdata.
- **M2 — accounts en winkelmand:** Supabase Auth, profiel/adressen, persistent winkelmandje, variant- en voorraadvalidatie, privacy/export/verwijdering.
- **M3 — checkout en orders:** server-side prijsherberekening, Stripe Checkout (iDEAL en kaarten), webhook, orderhistorie, bevestiging en veilige statusmachine.
- **M4 — leveranciers- en prijs-sync:** AliExpress-adapter, geplande synchronisatie, auditlog, prijsregels, circuit breaker, waarschuwingen en admin-approval.
- **M5 — fulfilment en service:** handmatige fulfilmentqueue als veilige basis, tracking, annuleren/herroepen, retouren, refunds en klantenserviceflows. Geen automatische leveranciersorder vóór expliciete goedkeuring van risico en voorwaarden.
- **M6 — productie en kwaliteit:** GitHub deployment, monitoring, back-up/herstel, performance, toegankelijkheid, SEO, securityreview en volledige menselijke acceptatietest.

## Orchestratie voor het maken van een milestoneplan

1. Lees dit bestand, alle repository-instructies en relevante bestaande code volledig.
2. Stel aan het begin alleen vragen die een architectuur- of bedrijfsbeslissing materieel veranderen; bundel ze.
3. Onderzoek actuele primaire documentatie en leg aannames, bronnen en onzekerheden vast. Raad of verzin nooit productdata.
4. Inspecteer bestaande patronen en kies de kleinste architectuur die de milestone volledig draagt.
5. Werk datamodel, trust boundaries, foutpaden, privacy, compliance, tests, uitrol en rollback uit.
6. Vraag een onafhankelijke agent om het conceptplan te beoordelen op eenvoud, aansluiting op de codebase, correctness/security en dekking van het bedrijfsdoel.
7. Verwerk elk bezwaar of motiveer met bewijs waarom het niet wordt gevolgd; herhaal review bij materiële wijzigingen.
8. Schrijf `PLAN-Mx.md` als uitvoerbaar contract met taken, acceptatiecriteria, validatiecommando's en menselijke controles.
9. Stop na het plan; implementeer niet in dezelfde context tenzij de gebruiker dat uitdrukkelijk vraagt.

## Orchestratie voor implementatie

1. Lees het milestoneplan en repository-instructies; controleer vooraf prerequisites en bestaande wijzigingen.
2. Implementeer in kleine verticale stappen en houd het plan bij met besluiten, afwijkingen en bewijs.
3. Test na iedere betekenisvolle stap; herstel oorzaken in plaats van tests af te zwakken.
4. Laat onafhankelijke agents afzonderlijk reviewen op KISS, codebase-conventies, correctness/security en milestonedekking.
5. Behandel alle concrete bezwaren, laat relevante reviews opnieuw uitvoeren en stop niet terwijl een aantoonbaar probleem openstaat.
6. Voer formattering, typechecks, unit/integratie/E2E-tests, RLS/securitytests en een productiebuild uit.
7. Test foutpaden: dubbele webhook, verlopen prijs, uitverkochte variant, syncstoring, terugbetaling en ongeautoriseerde datatoegang.
8. Werk `PLAN-Mx.md` bij met uitgevoerde validatie, resterende risico's en exacte menselijke acceptatiestappen.
9. Lever geen productieclaim op basis van mocks; benoem wat nog echte accounts, secrets, documenten of transacties vereist.

## Definition of done voor de hele winkel

Een bezoeker kan veilig producten vergelijken, een account gebruiken, een server-gevalideerd winkelmandje afrekenen en zijn bestelling/herroeping beheren. Prijzen worden controleerbaar gesynchroniseerd zonder verliesmarges of stille fouten. De eigenaar kan orders, refunds, productstatus en syncproblemen beheren. Alle kritieke flows zijn getest, wettelijke teksten zijn door een bevoegde professional gecontroleerd en minimaal één echte end-to-end bestelling inclusief refund is uitgevoerd vóór publieke lancering.
