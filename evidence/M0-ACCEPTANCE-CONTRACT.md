# M0 bindend acceptatiecontract

Status: **concept na onafhankelijke reviews — alle gates fail-closed**  
Peildatum: 16 juli 2026

Dit contract verenigt compliance, product, prijs en techniek. Bij verschil met een los M0-document geldt de strengste eis. `unknown`, verlopen bewijs, een parserfout of bronconflict betekent altijd blokkeren.

## 1. Exacte identiteit en bewijs

Een verkoopbare variant heeft een interne onveranderlijke `variant_id` plus bronproduct-ID, bron-SKU, leverancier/wettelijke entiteit, winkel-ID, modelnummer, GTIN indien aanwezig, kleur/maat/plug/batterij/adapter, foto's-hashes en een fingerprint van veiligheidskritische kenmerken. Een wijziging in leverancier, materiaal, elektrisch vermogen, batterij, adapter, fabrikant, EU-verantwoordelijke, afbeeldingen of modelnummer maakt de goedkeuring ongeldig.

Per variant zijn verplicht: gedateerde ruwe bronresponse, requestcontext zonder secret, aankoop/sample-order, fysieke vergelijking met de fingerprint, leveranciercontract/voorwaarden, fabrikant en EU-verantwoordelijke marktdeelnemer, traceerbaarheid, waarschuwingen/handleiding, toepasselijke conformiteits- en testrapporten, Safety Gate-controle en schriftelijke beoordeling door een bevoegde product-complianceprofessional. Documenten worden bij uitgevende instantie/lab geverifieerd; alleen een CE-logo of leveranciersverklaring is onvoldoende.

## 2. Gescheiden statussen

`product_compliance_status`, `supplier_test_status`, `source_data_status`, `logistics_status` en `price_status` zijn onafhankelijke velden met `pending|approved|blocked|expired`, plus een verplichte machineleesbare `reason_code`. `rejected_supplier` wordt `supplier_test_status=blocked` met die reason; `pending_requalification` wordt de betrokken status `pending` met die reason. `sellable` is afgeleid en alleen waar als alle vijf `approved` zijn en geen bewijs verlopen is. Een oude verkoopprijs blijft nooit actief als een nieuwe bronmeting de margepoort niet haalt; dan wordt `price_status=blocked` vóór publicatie of checkout.

## 3. Logistiek en retour

Een quote is minimaal specifiek voor exacte variant, aantal, bestemmingsland, postcodezone, verzendmethode en tijdstip. De belofte bevat herkomst, derde-levering, tracking, bandbreedte en uiterste leverdatum. Checkout vraagt bestemming vóór de definitieve prijs.

Per variant wordt een heen- én retourproef uitgevoerd en vastgelegd: werkelijke duur, schade/verpakking, tracking, douane/bijkosten, Nederlands retouradres, retourkosten, restwaarde en refunddoorlooptijd. Onverwachte kosten voor de consument of een onbewezen retourroute blokkeren verkoop.

## 4. Eén kostenledger en prijsalgoritme

Alle bedragen worden intern in eurocenten bewaard. De immutable calculatie-input bevat minimaal: netto bronprijs, variant, aantal, wisselkoersbron/-tijd, inkomende/verzendkosten, invoerrechten, invoer- en verkoop-btw-route, IOSS/expediteur, betaalfee vast/procentueel, platformkosten, verpakking, producenten-/UPV-kosten, retour/refundreserve, chargebackreserve en overige risicobuffer.

Definities:

- `landed_ex_vat`: alle niet-terugvorderbare kosten vóór betaalfee, verkoop-btw en gewenste winst.
- `gross_price`: consumententotaal inclusief toepasselijke verkoop-btw en verplichte kosten.
- `net_revenue`: `gross_price - verschuldigde_verkoop_btw`.
- `contribution`: `net_revenue - landed_ex_vat - payment_fee(gross_price)`.
- `contribution_margin`: `contribution / net_revenue` als `net_revenue > 0`.

De server zoekt de laagste `gross_price` in centen waarvoor zowel `contribution >= minimum_contribution_cents` als `contribution_margin >= target_margin` geldt, en rondt daarna deterministisch **omhoog** naar het eerstvolgende bedrag dat eindigt op `,95`; vervolgens worden beide poorten opnieuw gecontroleerd. Btw wordt als deel van een inclusieve prijs berekend (`gross * rate/(1+rate)`), nooit als `gross * rate`. Parameters en formuleversie worden bij iedere calculatie opgeslagen.

## 5. Prijs-sync en circuit breaker

Alle externe data wordt als onbetrouwbaar behandeld: schema- en typevalidatie, maximale payload/tekst/lijsten, time-outs, beperkte retries met jitter, rate-limit, escaping/sanitizing en observability zonder secrets/PII. Alleen serverfuncties mogen ingesteren; bron-html wordt niet gepubliceerd.

Een meting is pas bruikbaar na exacte SKU/fingerprintmatch en geldige logistieke quote. Versheid wordt per bronveld geconfigureerd; checkout vereist een verse servermeting en rekent opnieuw. Blokkeer bij ontbrekend/oud veld, currency mismatch, variantwijziging, negatieve/onmogelijke waarde, margepoort-fout, bronprijs- of landed-costsprong boven ingestelde absolute/procentuele grens, drie opeenvolgende fouten of bronconflict. Fixtures en alerts gebruiken exact dezelfde `landed_ex_vat`-metriek. Geen fallback naar oude verlieslatende verkoopprijs.

## 6. Checkout-, contract- en betaalbewijs

Gastcheckout en vrijwillig account worden beide ondersteund; geen account als onnodige voorwaarde. De server ontvangt variant, aantal en bestemming, controleert alle vijf statussen inclusief `supplier_test_status`, rekent het volledige consumententotaal opnieuw en retourneert prijsopbouw, btw, verzending, herkomst, levertijd, retourkosten, verkoper en versies/hashes van voorwaarden, privacy, productinformatie en herroepingsinformatie.

Vóór Stripe ontstaat een immutable orderdraft met bovenstaande snapshot en expliciete instemming. De bestelknop benoemt ondubbelzinnig de betalingsverplichting. Na betaling worden duurzame contractbevestiging en modelformulier verstrekt. Alleen een geverifieerde, atomair idempotent verwerkte Stripe-webhook wijzigt betaalstatus; success-URL nooit.

Het model omvat afzonderlijk `amount_authorized`, `amount_captured`, `amount_refunded` en `amount_disputed`, plus order-, fulfilment-, annulering-, herroeping-, retour-, wettelijke-garantie- en refundstatussen. De sinds 19 juni 2026 vereiste online herroepingsfunctie werkt ook zonder account via een veilig ordergebonden proces en geeft onmiddellijk duurzame bevestiging.

## 7. Privacy en security

Leg verwerkingsverantwoordelijke/verwerkers, regio's, doorgiften, grondslagen, bewaartermijnen en verwijder-/exportproces vast voor GitHub, Supabase, Stripe, leverancier en mailprovider. Verzamel alleen noodzakelijke data; leverancier ontvangt pas na betaalbevestiging alleen fulfilmentvelden. Logs bevatten geen betaalgegevens, adressen, tokens, IOSS-nummer of volledige webhookbody. Geen niet-noodzakelijke cookies/scripts vóór geldige toestemming.

RLS- en autorisatietests dekken gasttokens, accounts, admin/service-role, IDOR, sessievervalsing en gegevensscheiding. Secrets staan alleen server-side en secret-scanning controleert bron én build artifacts.

## 8. Bewijsbare tests

Minimaal: zestien prijsfixtures tegen de formele definities; postcode-/variant-/aantalquotes; verlopen brondata; productsubstitutie; margeval; parserpayloads; parallelle checkouts; dubbele/out-of-order webhook; betaald bedrag mismatch; gedeeltelijke en volledige refund; dispute; gast- en accounttoegang; RLS/IDOR; herroeping zonder account; duurzame bevestiging; leverancier- en retourproef; herstel na syncstoring.

Voor iedere test worden input, verwachte uitkomst, werkelijke uitkomst, timestamp, uitvoerder en artifact vastgelegd. Een driedaagse observatie is pas bewijs als succesvolle én bewust gemanipuleerde/falende responses correct worden verwerkt.

## 9. GO-regel en hergoedkeuring

Live verkoop vereist alle gates uit `M0-DECISION.md`, alle vijf variantstatussen inclusief `supplier_test_status` groen, echte Stripe-testbetaling/dubbele webhook/refund, professionele fiscale/juridische/productreview en een onafhankelijke eindreview zonder open P0/P1. Goedkeuring verloopt op vaste reviewdatum en onmiddellijk bij leverancier-, SKU-, product-, document-, formule-, fiscale-, logistieke-, API- of wettelijke wijziging, incident/recall of relevante klacht.

## 10. Leverancier-, baseline- en documentcontract

Een leverancier is alleen aanvaard met onafhankelijk geverifieerde juridische naam, registratienummer, adres/contact, facturerende en betaalontvangende entiteit en een schriftelijk contract met: exacte SKU/BOM, substitutieverbod, voorafgaande wijzigings- en incidentmelding, batchtraceerbaarheid, authentieke documenten en tijdige dossierinzage, recallmedewerking, aansprakelijkheid/verzekering, persoonsgegevens en bewaartermijnen. Anders is `supplier_test_status=rejected_supplier`.

De productbaseline omvat batch/serienummer, gewicht/afmetingen, BOM/componenten, elektrische en batterij/adapterwaarden, verpakking, afbeeldingen en documenthashes. Periodieke echte fulfilmentorders worden hiermee vergeleken; verschil geeft `pending_requalification`. Iedere second source is een volledig nieuwe leverancier/SKU. Claims over geluid, luchtstroom, batterijduur of koeling vereisen een SKU-specifieke methode; merken en intellectuele eigendom worden vooraf gecontroleerd.

Een formele monstertest legt normversies, methode, limieten, gekalibreerde middelen, sampleaantal/batchspreiding en chain of custody vast. Een gebruikersproef claimt nooit normconformiteit. Documentcontrole registreert verplichte velden, ondertekenaar, normversie, exacte model/BOM/batterij/adapter-match, rapportomvang, geldigheid, verificatieantwoord en dossierbeschikbaarheid; ontbrekende toegang geeft `blocked_document_access`.

Fabrikant, EU-verantwoordelijke, waarschuwingen, handleiding, goedgekeurde titel/claims en beelden komen uit een handmatig beheerde compliancecatalogus die supplier-sync nooit mag overschrijven. Een verschil opent een menselijke reviewtaak.

## 11. Operationele fulfilment- en retourcriteria

Logistiek bewijs bevat magazijn/verzendland, vervoerder/service, batterijacceptatie, DDP/IOSS-route, verlies-/schadehouder, postcode-uitsluitingen en p50/p90 uit meerdere orders. Retourbeleid en test dekken ongeopend, gebruikt, defect, transportschade, batterijzwelling en recall; inclusief lithiumquarantaine, inspectie-SLA, eindbestemming/afvoer en alle niet-recupereerbare heen-, retour-, betaal- en afvalkosten.

De kostenledger bevat daarnaast lab/documentreview, samples, klantenservice, defect/garantie, verzekering, recallreserve en Nederlandse fulfilment. Vaste periodieke en variabele kosten blijven gescheiden en het goedgekeurde dossier toont break-evenvolume.

## 12. Bron-, FX- en adaptercontract

Alleen een officieel toegestane, contractueel gearchiveerde API/feed die exacte product-ID, SKU, bestemming, voorraad, prijs en verzending levert, mag productie voeden. Persoonlijke, welkomst-, coupon-, munt- of appprijzen zijn uitgesloten tenzij per order contractueel gegarandeerd. Externe data landt eerst in private staging en nooit rechtstreeks in publieke tabellen.

`fx_rate_eur_per_source_unit`, provider/rate-id, server-UTC `observed_at`, optionele brontijd, toegestane clock skew en TTL worden opgeslagen. Versheid gebruikt uitsluitend de vertrouwde servertijd; EUR bewaart expliciet koers `1` en dezelfde auditvelden. De adapter gebruikt allowlisted HTTPS-hosts, beperkte redirects, pagination-completeness, HTTP- én business-errorcontrole en een veilige image-proxy/CSP-strategie.

Er is precies één gevalideerd intern `SupplierQuote`-type, één adapter en één pure pricingfunctie. De driedaagse proef is alleen een minimale canary, nooit parserstabiliteitsbewijs. Breakerherstel volgt een expliciete overgangstabel: handmatige blokkades alleen handmatig; automatische bronfouten pas na het ingestelde aantal consistente observaties en nooit op één meting. Elke statusdimensie heeft eigenaar en append-only auditlog met reason/evidence/actor/timestamp; sync kan alleen `source_data_status` en `price_status` aanscherpen, nooit supplier/compliance goedkeuren. Eerste publicatie en herpublicatie na iedere blokkade of herkwalificatie vereisen altijd expliciete menselijke goedkeuring; geen sync, canary of consistente meetreeks mag automatisch publiceren.

Absolute en procentuele breakerdrempels worden door de eigenaar ondertekend en getest exact op, onder en boven de grens; ontbrekende/oude/nulbasis blokkeert. De pure afrondfunctie test minimaal `0`, `0.949`, `0.95`, `0.951`, `11.949`, `11.95`, `11.951`; negatieve of niet-eindige invoer faalt. De configureerbare regel mag geen schijnkorting creëren.

## 13. Spike-, auth- en browserbeveiliging

Een hosted spike gebruikt alleen synthetische persoonsgegevens en producten, toont prominent “TEST — GEEN VERKOOP”, heeft een server-side tester-allowlist en bevat geen echte SKU, prijs, voorraad of fulfilment. Na afloop worden testdata verwijderd, gebruikte secrets geroteerd en artifacts gescand; niet-indexering alleen is onvoldoende.

De MVP accepteert server-side uitsluitend `shipping_country=NL`. Het door Stripe teruggegeven adres wordt vóór fulfilment vergeleken met de ordersnapshot; mismatch blokkeert. Auth en checkout hebben exacte redirect-allowlists, enumeratie-/brute-forcebescherming, logout/herstel/intrekking, least-privilege rollen, admin-MFA/step-up en append-only audit. Headers/policies omvatten een geteste CSP, `Referrer-Policy`, framebeperking en resource-allowlist binnen gedocumenteerde GitHub Pages-beperkingen.

Gasttoegang gebruikt een hoog-entropisch, beperkt, roteerbaar token, alleen in een beveiligde cookie of POST-body—nooit querystring, analytics, referrer of logs. Accounts ondersteunen export, rectificatie en verwijdering met transparante fiscale uitzonderingen. Standaard zijn analytics/advertising afwezig; eventuele toestemming is intrekbaar en tests inventariseren cookies, local storage en third-party requests vóór en na toestemming.

## 14. Contractarchief, herroeping en refunds

Naast hashes bewaart Briesje een immutable archival render/copy van de werkelijk getoonde precontractuele informatie en bewijs van verzending van de duurzame bevestiging, zonder onbeperkte opslag van mailinhoud. Een jurist keurt de volledige UX goed.

Wettelijke termijnen en grondslagen worden als versieerbare regels vastgelegd en professioneel beoordeeld. Refundberekening bewaart immutable componenten/grondslag en neemt waar vereist standaard-heenzendkosten mee. Refund request en Stripe-transactie zijn gescheiden; boven een ingestelde grens geldt vier-ogencontrole. Dagelijkse Stripe-reconciliatie controleert betaling/refund/dispute. Fulfilment vereist betaald + alle statussen groen + geldig adres. E2E-tests dekken tijdige/late/gedeeltelijke/dubbele herroeping, volledige/gedeeltelijke/dubbele refund, refundfout, chargeback en out-of-order webhooks.

## 15. Privacydataflow en retentie als constraint

Een veldniveau ROPA-light legt per veld doel, grondslag, ontvanger, rol, regio/doorgiftemechanisme, bewaartermijn en verwijderpad vast voor GitHub, Supabase, Stripe, leverancier, vervoerder en mailprovider, inclusief verwerkersvoorwaarden. Webhooks gebruiken een veld-allowlist; geen metadata- of payloaddumps. Logredactie en retentie worden getest.

Veldspecifieke scheduled deletion/anonymisation-jobs scheiden contract/fiscaal bewijs, event-dedupe, operationele data en logs; legal hold is expliciet en geaudit. Event-dedupe bewaart event-id, type en timestamps maar geen payload. Herleidbare hashes blijven persoonsgegevens. Accountverwijdering heeft een E2E-test die verwijdert/anonymiseert wat mag en wettelijk bewaarde records ontoegankelijk maakt voor normaal gebruik.

Voorraad, verzendquote en levertijd bewaren elk bron en TTL in de ordersnapshot. Geen schaarsteclaim zonder actueel controleerbaar bewijs.

## 16. Evidencebeheer

Elk bewijs en iedere gate bevat `owner`, `status`, `evidence_link`, `verified_by`, `verified_at`, `valid_until`, `source_version` en hercontrolefrequentie. Verloop van verzekering/registratie, Safety Gate-signaal, klacht, incident of bron-/wetswijziging triggert onmiddellijke herkwalificatie.
