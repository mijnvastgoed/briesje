# Finale onafhankelijke M0-review — ronde 2

Reviewdatum: 16 juli 2026  
Beoordeeld: bijgewerkte `M0-ACCEPTANCE-CONTRACT.md` en `M0-DECISION.md` tegen ieder hiaat uit `REVIEW-FINAL-M0.md`.

## Eindoordeel

**Correctieronde: FAIL met twee resterende contracthiaten. Operationele M0-status: terecht NO-GO.**

Vrijwel alle eerdere P0/P1-, compliance- en pricingbezwaren zijn nu als concrete, fail-closed eisen opgenomen. Eén technisch statusmodelprobleem is nog blokkerend: `supplier_test_status` is wel geïntroduceerd, maar niet opgenomen in de afgeleide `sellable`-poort. Daarnaast ontbreekt nog het expliciete verbod op automatische productpublicatie uit het KISS-hiaat.

Dit oordeel gaat uitsluitend over de kwaliteit van het gecorrigeerde contract. Geen externe gate is door tekstuele correctie bewezen: de geblokkeerde statussen in `M0-DECISION.md` moeten NO-GO blijven totdat echte artifacts en bevoegde beoordelingen aanwezig zijn.

## Technische P0/P1-herreview

| Eerder hiaat | R2 | Bewijs in bijgewerkt contract |
|---|---|---|
| P0 hosted spike geen verkoopaanbod | **PASS** | §13 eist synthetische data/producten, prominente testmelding, server-side tester-allowlist, geen echte SKU/prijs/voorraad/fulfilment, verwijdering, rotatie en scan; niet-indexering is expliciet onvoldoende. |
| P0 totaalprijs, NL en fiscale route | **PASS** | §4 en §6 leggen volledige serverberekening en immutable fiscale inputs vast; §13 dwingt NL server-side af en blokkeert fulfilment bij Stripe-adresmismatch. |
| P0 contractbewijs/precontractuele informatie | **PASS** | §6 en §14 eisen snapshot, archival render/copy, verzendbewijs zonder onbeperkte mailopslag en juridische UX-goedkeuring. |
| P0 herroeping/retour/garantie | **PASS** | §6 en §14 modelleren gescheiden statussen, versieerbare termijnen/grondslagen, standaard-heenzendkosten en alle gevraagde E2E-gevallen. |
| P0 gastcheckout/gastrechten | **PASS** | §6, §13 en §15 eisen gastcheckout, beperkt/roteerbaar high-entropy token buiten URL/logs/referrers en accountrechten met fiscale uitzonderingen. |
| P0 privacyrollen/doorgiften | **PASS** | §15 bevat veldniveau ROPA, alle ontvangers, doorgiftemechanisme, verwerkersvoorwaarden, webhookallowlist, redactie en retentietests. |
| P1 auth/sessie/browserprivacy | **PASS** | §13 bevat redirectallowlists, enumeratie/brute force, logout/herstel/intrekking, least privilege, admin-MFA/step-up, audit en browserpolicies. |
| P1 cookies/third-party scripts | **PASS** | §13 start zonder analytics/advertising en eist intrekbare toestemming plus inventaris/tests van cookies, storage en third-party requests. |
| P1 betaal-/refundstatus | **PASS** | §6 en §14 bevatten bedragstatussen, immutable refundcomponenten/grondslag, request/transactiescheiding, vier ogen, dagelijkse reconciliatie, fulfilmentgate en volledige testmatrix. |
| P1 dataminimalisatie/retentie | **PASS** | §15 maakt veldspecifieke deletion/anonymisation, legal hold, datascheiding, minimale event-dedupe en accountverwijdering testbare constraints. |
| P1 voorraad/levertijd freshness | **PASS** | §3, §5 en §15 leggen quote/freshness, bron/TTL-snapshot, checkout-hercontrole, fail-closed en verbod op onbewezen schaarste vast. |

**Resultaat technisch:** alle eerder opgesomde technische P0/P1-correcties zijn contractueel afgedekt. Dit is nog geen testbewijs.

## Compliance-herreview

| # | Eerder hiaat | R2 | Bewijs in bijgewerkt contract |
|---:|---|---|---|
| 1 | Minimuminhoud leveranciersidentiteit/-contract | **PASS** | §10 noemt geverifieerde identiteit/entiteiten en alle verlangde contractclausules; ontbreken resulteert in `rejected_supplier`. |
| 2 | Baseline en voortdurende vergelijking | **PASS** | §10 bevat batch/serienummer, maat/gewicht, BOM, verpakking, hashes, periodieke fulfilmentmatch en `pending_requalification`. |
| 3 | Reproduceerbaar monstertestprotocol | **PASS** | §10 bevat normversie, methode, limieten, kalibratie, sample-/batchspreiding, chain of custody en scheiding van gebruikersproef. |
| 4 | Sluitende documentacceptatie | **PASS** | §10 bevat verplichte velden/matches, uitgever/ondertekenaar, scope/geldigheid/verificatie en `blocked_document_access`. |
| 5 | Compliancecatalogus beschermd tegen sync | **PASS** | §10 maakt de geverifieerde velden handmatig beheerd, niet overschrijfbaar en reviewplichtig bij verschil. |
| 6 | Operationele logistieke bewijslast | **PASS** | §3 en §11 bevatten variant/postcode/methode plus magazijn, vervoerder, batterij, DDP/IOSS, risico, uitsluitingen en p50/p90. |
| 7 | Veilige/economische retourtest | **PASS** | §11 bevat alle retourscenario's, lithiumquarantaine, SLA, afvoer en niet-recupereerbare kosten. |
| 8 | Complete cost ledger/break-even | **PASS** | §4 en §11 bevatten de extra kosten, scheiden vaste/variabele kosten en eisen break-evenvolume. |
| 9 | Alleen toegestane exacte bron | **PASS** | §12 eist een officieel toegestane contractueel gearchiveerde API/feed en sluit persoonlijke/promotionele prijzen uit. |
| 10 | Evidencevelden, verloop en triggers | **PASS** | §9 en §16 bevatten eigenaar, verificatievelden, geldigheid/frequentie en alle gevraagde wijzigingstriggers. |
| 11 | IP, claims en second source | **PASS** | §10 eist IP-check, SKU-specifieke claimmethode en volledige kwalificatie van iedere second source. |

## Product-/pricing-herreview

| # | Eerder hiaat | R2 | Bewijs in bijgewerkt contract |
|---:|---|---|---|
| 1 | FX- en tijdssemantiek | **PASS** | §12 definieert koersrichting, provider/rate-id, server-UTC, brontijd, clock skew, TTL en EUR=1. |
| 2 | Supplier-adaptersecurity | **PASS** | §5 en §12 dekken limieten, timeouts, validatie, allowlisted HTTPS, redirects, pagination, business errors, private staging en image/CSP. |
| 3 | Onafhankelijke statusdimensies | **FAIL** | §10 introduceert `supplier_test_status`, maar §2 definieert `sellable` nog steeds als AND van slechts vier statussen en noemt `supplier_test_status` niet. Daardoor kan een implementator een variant met `rejected_supplier` toch als sellable afleiden wanneer de vier genoemde velden groen zijn. **Correctie:** voeg `supplier_test_status` expliciet toe aan §2 met toegestane statussen, eigenaar, verloop en aan de `sellable`-AND; controleer dezelfde vijfde gate atomair in §6 vóór orderdraft/checkout. Sync mag deze status nooit goedkeuren of herstellen. |
| 4 | Circuit-breakerherstel | **PASS** | §12 vereist overgangstabel: handmatig blijft handmatig; automatische fout pas na meerdere consistente observaties. |
| 5 | Exacte breakergrenzen/fixtures | **PASS** | §12 eist ondertekende absolute/procentuele grenzen en tests exact op, onder en boven de grens; ontbrekende/oude/nulbasis blokkeert. |
| 6 | Afrondings-boundarycontract | **PASS** | §12 bevat alle vereiste fixtures, falen op negatief/non-finite en configureerbaarheid zonder schijnkorting. |
| 7 | Canary/KISS/geen automatische publicatie | **FAIL (beperkt)** | §12 noemt drie dagen alleen canary en beperkt tot één `SupplierQuote`, adapter en pure pricingfunctie. Het expliciete vereiste “geen automatische publicatie” ontbreekt. **Correctie:** leg vast dat geen supplier-sync, quote of prijsfunctie ooit `product_compliance_status`, `supplier_test_status` of cataloguspublicatie op approved/live mag zetten; eerste publicatie en herpublicatie na product-/supplierblokkade vereisen menselijke goedkeuring en auditbewijs. Automatische prijsupdates binnen een reeds goedgekeurde, ondertekende breakerpolicy mogen uitsluitend `price_status` beïnvloeden. |

## Beslisdossier-herreview

| Eerder hiaat | R2 | Toelichting |
|---|---|---|
| Afzonderlijke privacy/retentiegate | **PASS** | Gate toegevoegd met bevoegde eigenaar en bewijssoort. |
| Afzonderlijke auth/browser/admingate | **PASS** | Gate toegevoegd met securityreviewer en concrete testcategorieën. |
| Gastcheckout/contractbewijs | **PASS** | Eigen gate toegevoegd. |
| Herroeping/retour/garantie | **PASS** | Eigen gate toegevoegd. |
| Logistiek/freshness | **PASS** | Eigen gate toegevoegd. |
| Leveranciercontract/herkwalificatie | **PASS** | Eigen gate toegevoegd. |
| Refund/dispute-reconciliatie | **PASS** | Eigen gate toegevoegd. |
| Onafhankelijke P0/P1-eindreview | **PASS** | Eigen gate met traceabilitymatrix toegevoegd. |
| Operationele evidencevelden/statussen | **PASS** | Beslisregel vereist owner, status, link, verifier, timestamps, versie en frequentie. |

## Vereiste laatste contractcorrecties

1. Maak `supplier_test_status` de vijfde onafhankelijke, verplichte sellability- en checkoutgate in §2 en §6.
2. Verbied automatische eerste publicatie/herpublicatie expliciet; begrens syncbevoegdheid tot bron-/prijsstatus volgens een vooraf menselijk goedgekeurde policy.

Na deze twee tekstuele correcties kan de contractuele herreview **PASS** zijn. De winkel blijft ook dan operationeel **NO-GO** totdat iedere launchgate werkelijk `approved` is met geldig bewijs; geen van die externe of menselijke bewijzen is door deze review geleverd.

