# Finale onafhankelijke M0-review

Reviewdatum: 16 juli 2026  
Beoordeeld: `M0-ACCEPTANCE-CONTRACT.md` en `M0-DECISION.md` tegen `REVIEW-COMPLIANCE.md`, `REVIEW-PRODUCTS.md` en `REVIEW-TECHNICAL.md`.

## Eindoordeel

**Niet akkoord als volledig gecorrigeerd M0-contract; NO-GO blijft correct.**

Het acceptatiecontract verwerkt de kern goed: fail-closed, onafhankelijke statussen, exacte variantidentiteit, server-side totaalprijs, één kostenledger, immutable snapshots, gastcheckout, juridische versies, herroeping, idempotente Stripe-webhook, privacyprincipes en professionele gates. Het beslisdossier claimt terecht geen afgeronde externe gate.

Er blijven echter open P0/P1- en andere concrete reviewbezwaren. Volgens de eigen GO-regel (“onafhankelijke eindreview zonder open P0/P1”) kan M0 dus niet naar GO. De hiaten hieronder moeten als toetsbare acceptatiecriteria worden toegevoegd; alleen verwijzen naar “strengste eis uit losse documenten” is onvoldoende voor een bindend, zelfstandig uitvoerbaar contract.

## Traceerbaarheid technische P0/P1

| Reviewbezwaar | Dekking | Resterende vereiste correctie |
|---|---|---|
| P0 hosted spike geen verkoopaanbod | **Deels** | `M0-DECISION` staat fictieve/gemarkeerde testdata en een niet-geïndexeerde preview toe, maar eist geen synthetische persoonsgegevens, prominente “test—geen verkoop”-melding, server-side tester-allowlist, verbod op echte SKU/prijs/voorraad/fulfilment, testdataverwijdering en secretrotatie. Voeg deze als spikegates toe; `robots.txt` alleen telt niet. |
| P0 totaalprijs, NL en fiscale route | **Deels** | Volledige prijsopbouw en fiscale review zijn gedekt. Een harde server-side `shipping_country=NL`-beperking én validatie van het door Stripe teruggegeven adres vóór fulfilment ontbreken. Leg NL-only voor MVP vast, snapshot de goedgekeurde import-/fulfilmentroute en blokkeer mismatch. |
| P0 contractbewijs/precontractuele informatie | **Grotendeels** | Versies/hashes en duurzame bevestiging zijn opgenomen. Eis daarnaast een immutable archival render/copy van wat werkelijk is getoond, bewijs van verzending zonder mailinhoud onbeperkt te loggen, en expliciete juridische UX-review. |
| P0 herroeping/retour/garantie | **Grotendeels** | Domeinstatussen, gasttoegang en bevestiging staan erin. Ontbreken: concrete wettelijke deadlines/grondslag, standaard-heenzendkosten in refundberekening en E2E-cases voor tijdig/laat/gedeeltelijk/dubbel verzoek plus refundfout. |
| P0 verplicht account/gastrechten | **Deels** | Gastcheckout is verplicht gesteld. Het veilige gastproces is niet gespecificeerd: hoog-entropische, beperkte, roteerbare toegang; geen token in querystring, analytics, referrer of logs; account-export/rectificatie/verwijdering met fiscale bewaarplicht. Voeg model en tests toe. |
| P0 privacyrollen/doorgiften | **Deels** | Rollen/regio/grondslag/retentie worden genoemd. Eis een veldniveau ROPA-light met doel, ontvanger, rol, regio/doorgiftemechanisme, bewaartermijn en verwijderpad; verwerkersvoorwaarden; webhookveld-allowlist; geen volledige payload/metadata-dump; logredactie- en retentietests. Neem vervoerder én mailprovider expliciet op. |
| P1 auth/sessie/browserprivacy | **Open** | RLS/IDOR alleen dekt dit niet. Voeg vaste auth/checkout-redirectallowlist, enumeratie- en brute-forcecontrole, logout/herstel/intrekking, admin-MFA/step-up, least privilege en auditlog toe. Eis CSP, `Referrer-Policy`, framebeperking en resource-allowlist, met gedocumenteerde GitHub Pages-beperkingen. |
| P1 cookies/third-party scripts | **Deels** | “Geen niet-noodzakelijke scripts vóór toestemming” is opgenomen. Ontbreken: default zonder analytics/advertising, inventaris van cookies/local storage/third-party requests, intrekbare toestemming en browsertest vóór toestemming. |
| P1 betaal-/refundstatus | **Deels** | Authorized/captured/refunded/disputed en gescheiden statussen zijn goed. Ontbreken: immutable refundregels en snapshot per component/grondslag, gescheiden request/transaction, vier-ogencontrole boven grens, Stripe-reconciliatie en fulfilmentgate op betaald + compliance + adres. Voeg volledige/gedeeltelijke herroeping, standaard-heenzendkosten, dubbele refund, chargeback en webhookvolgorde expliciet toe. |
| P1 dataminimalisatie/retentie | **Open als constraint** | Het contract vraagt bewaartermijnen maar geen scheduled deletion/anonymisation, legal hold, scheiding event-dedupe/contract/fiscaal/logs, of test bij accountverwijdering. Leg veldspecifieke retentie en jobs vast; bewaar event-id maar geen payload en behandel hashes als persoonsgegevens zolang herleidbaar. |
| P1 voorraad/levertijd freshness | **Grotendeels** | Exacte variant, quote, versheid, checkout-hermeting, fail-closed en beloftesnapshot zijn gedekt. Voeg expliciet toe: geen schaarsteclaim zonder bewijs en bron/TTL per veld in de snapshot. |

Alle technische P0/P1 zijn dus nog niet volledig gesloten: minimaal auth/browserprivacy en retentie zijn materieel open; de overige gedeeltelijke punten moeten toetsbaar worden aangescherpt.

## Resterende compliancebezwaren

1. **Leverancierscontract is niet minimum-inhoudelijk gedefinieerd.** Het contract noemt identiteit en “leveranciercontract/voorwaarden”, maar niet registratienummer, facturerende/betaalentiteit, onafhankelijke contactverificatie of verplichte clausules voor exacte BOM/SKU, substitutieverbod, wijzigings- en incidentmelding, batchtraceerbaarheid, documentauthenticiteit, recallmedewerking, aansprakelijkheid, persoonsgegevens en bewaartermijn. Zonder schriftelijke acceptatie hoort status `rejected_supplier` te zijn.

2. **Productbaseline en voortdurende vergelijking zijn incompleet.** Fingerprint en samplevergelijking zijn aanwezig, maar batch-/serienummer, gewicht/afmetingen, BOM/componenten, verpakking, documenthashes en periodieke vergelijking van echte fulfilmentorders ontbreken. Elke afwijking moet `pending_requalification` geven, niet alleen een generieke statusinvalidate.

3. **Monstertestprotocol blijft te globaal.** Een complianceprofessional is vereist, maar niet normreferenties, meetmethode, pass/fail-limieten, gekalibreerde middelen, minimumaantal/batchspreiding, chain of custody en scheiding gebruikersproef versus conformiteitstest. Interne tests mogen geen normnalevingsclaim dragen.

4. **Documentacceptatie is niet reproduceerbaar genoeg.** Labverificatie staat erin, maar verplichte velden, ondertekenaar, normversie, model/BOM/batterij/adapter-match, rapportomvang, geldigheidsdatum, verificatieantwoord en tijdige toegang tot het technisch dossier ontbreken. Definieer `blocked_document_access`.

5. **Geverifieerde compliancecatalogus is niet beschermd tegen sync.** Versie/hashes worden gesnapshot, maar er staat niet dat fabrikant, EU-verantwoordelijke, waarschuwingen, handleiding, titel en goedgekeurde beelden handmatig beheerd zijn en nooit door leverancierssync overschreven mogen worden. Een wijziging moet een menselijke reviewtaak openen.

6. **Logistieke bewijslast mist operationele details.** Variant/aantal/postcode/methode/tijd zijn gedekt, maar verzendland/magazijn, vervoerder/service, batterijacceptatie, DDP/IOSS-route, verlies-/schadehouder, uitgesloten postcodegebieden en p50/p90 uit meerdere orders ontbreken.

7. **Retourtest mist productveiligheid en volledige economie.** Het heen/retourbewijs noemt kosten en refundduur, maar geen beslisboom voor ongeopend, gebruikt, defect, schade, batterijzwelling en recall; geen lithiumquarantaine, inspectie-SLA, eindbestemming/afvoer of niet-recupereerbare heen-/retour-/betaal-/afvalkosten.

8. **Kostenledger is breed maar niet compleet als reviewcontract.** Voeg laboratorium/documentreview, samples, support, defecten/garantie, verzekering, recallreserve en Nederlandse fulfilment expliciet toe. Scheid vaste periodieke van variabele kosten en bewijs break-evenvolume.

9. **Toegestane bron is niet hard genoeg benoemd.** Het contract vraagt ruwe bronresponses en validatie, maar zegt niet expliciet: alleen officieel toegestane API/feed die exacte product-ID, SKU, bestemming, voorraad, prijs en verzending levert; archiveer voorwaarden; sluit persoonlijke/welkomst/coupon/munt/app-prijzen uit tenzij contractueel per order gegarandeerd.

10. **Hergoedkeuring heeft triggers maar geen evidencevelden/frequenties.** Voeg per bewijs `verified_at`, `verified_by`, `valid_until`, `source_version`, vaste hercontrolefrequentie en eigenaar toe. Safety Gate-signaal, verzekering/registratieverloop en relevante klacht moeten expliciete triggers zijn.

11. **IP-, claims- en second-sourcecontrole ontbreken.** Voeg merken/intellectuele-eigendomscheck toe; publiceer geluid/luchtstroom/batterijduur/koeling alleen met SKU-specifieke testmethode; behandel iedere second source als volledig nieuwe leverancier/SKU, nooit automatische failover.

## Resterende product-/pricingbezwaren

1. **FX- en tijdssemantiek zijn nog open.** Definieer `fx_rate_eur_per_source_unit`, provider/rate-id, UTC server-`observed_at`, optionele source timestamp, clock skew en TTL. Freshness mag nooit op een onvertrouwde toekomsttimestamp rusten; EUR gebruikt expliciet koers 1 met auditvelden.

2. **Supplier-adaptersecurity is slechts gedeeltelijk afgedekt.** Payloadlimiet, timeouts, types en escaping staan erin. Voeg allowlisted HTTPS-hosts, redirectlimiet, pagination-completeness, HTTP-én business-errorcontrole en een veilige image/CSP-strategie toe. Externe payloads mogen niet rechtstreeks publieke tabellen voeden.

3. **Statusdimensies zijn nog onvoldoende gescheiden.** Vier statussen missen afzonderlijk `supplier_test_status`; `logistics_status` is geen veilige vervanging voor sample/compliancekwalificatie. Voeg eigenaar per dimensie en append-only auditlog met reason/evidence/actor/timestamp toe, zodat een prijssync nooit een compliance- of supplierblokkade opheft.

4. **Circuit-breakerherstel is niet bepaald.** Het contract blokkeert correct, maar zegt niet of herstel handmatig of na meerdere consistente observaties gebeurt. Eén toevallig “goede” sync mag een corrupte meting of handmatige blokkade niet opheffen. Leg overgangstabel en autorisatie vast.

5. **Breakergrenzen en fixtures zijn niet exact.** Het contract verwijst naar ingestelde absolute/procentuele grenzen en dezelfde `landed_ex_vat`-metriek, maar specificeert geen exacte grenssemantiek. Test exact op, net onder en net boven iedere grens; oude/ontbrekende/nulbasis blokkeert. De eigenaar moet percentages ondertekenen.

6. **Afronding naar `,95` mist boundarycontract.** “In centen omhoog” is beter, maar voeg pure-functionfixtures toe voor 0, 0.949, 0.95, 0.951, 11.949, 11.95 en 11.951 en wijs negatieve/non-finite invoer af vóór afronding. De regel blijft configureerbaar en mag geen schijnkorting creëren.

7. **Driedaagse observatie is nog ambigu als bewijs.** De tekst verbetert dit met gemanipuleerde responses, maar benoem drie dagen uitsluitend als minimale M0-canary, niet als parserstabiliteitsbewijs. Houd KISS: één gevalideerd intern `SupplierQuote`-type, één adapter en één pure pricingfunctie; geen automatische publicatie.

## Hiaat in `M0-DECISION.md`

De negen launchgates zijn te grof om alle vereisten uit het acceptatiecontract af te dwingen. Voeg afzonderlijke harde gates/eigenaren toe voor:

- privacy/dataflow/doorgiften/retentie en verwerkersvoorwaarden;
- auth/browser/adminsecurity en secret-/buildscan;
- gastcheckout, contractbewijs, herroeping/retour/garantie en duurzame bevestiging;
- logistieke/postcodequote en voorraad-/levertijdfreshness;
- leverancieridentiteit/contract en periodieke productherkwalificatie;
- webhook/refund/dispute-reconciliatie;
- onafhankelijke finale P0/P1-review.

“Juridische teksten”, “productveiligheid” en “Stripe testketen” impliceren deze niet voldoende en hebben soms andere bevoegde eigenaren. Iedere gate moet bewijslink, `verified_by`, `verified_at`, `valid_until`, eigenaar en expliciete `blocked|approved|expired` status krijgen.

## Criteria voor een positieve herreview

Een positieve finale review vereist:

1. alle technische P0/P1-rijen hierboven volledig toetsbaar in contract én beslisgates;
2. alle concrete compliance- en pricinghiaten opgenomen of met bewijs gemotiveerd afgewezen;
3. geen gate op “GO” zonder echt artifact en bevoegde ondertekening;
4. een traceabilitymatrix van elk oorspronkelijk reviewbezwaar naar contractclausule, test en evidence;
5. behoud van **NO-GO** totdat echte externe, professionele en end-to-end bewijzen bestaan.

