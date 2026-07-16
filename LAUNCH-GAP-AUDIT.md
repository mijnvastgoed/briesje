# Briesje — launch-gap audit voor echte verkoop

Peildatum: 16 juli 2026  
Oordeel: **NO-GO voor live verkoop.** De repository is een nette fail-closed demo/spike, geen operationele Nederlandse webshop.

## Samenvatting

| Domein | Huidige staat | Wat nu gebouwd kan worden | Vereist eigenaar/credentials/verificatie |
|---|---|---|---|
| Storefront | Duidelijke demo met lokale mand; geen volwaardige checkout/legal UX | Productdetail, adres/quote-flow, gastcheckout, orderstatus, herroepingsformulier, toegankelijkheid | Bedrijfsnaam, adres, KvK, btw-id, support- en retourgegevens; juridische goedkeuring |
| Supabase | Basisschema, vijf fail-closed statussen, read-own RLS, catalogusview | Volledig order-/prijs-/retourmodel, RLS/IDOR-tests, adminrollen, auditlog, retentiejobs | Echt project, regio/DPA-keuze, redirect-URL's, SMTP, MFA, back-up/RPO en productie-instellingen |
| Stripe | Test-only Checkout Function en ondertekende webhookbasis | Refund/dispute/expiry/reconciliation, adrescheck, E2E-fixtures | Geactiveerd Stripe-bedrijfsaccount, test/live keys, webhooksecret, iDEAL-activering, echte test/refund |
| Productbron | Twee AliExpress-referenties, maar geen adapter/sync | Eén gevalideerd `SupplierQuote`-contract, staging, prijsengine, breaker en syncjob | Schriftelijk toegestane API/feed, app-key/secret, leveranciercontract, echte SKU-/NL-verzendresponses |
| Productveiligheid | Alleen statusvelden; alle demo-SKU's geblokkeerd | Evidence-register, expiratie/recallworkflow, verplichte productvelden | Samples, fabrikant/importeur/EU-verantwoordelijke, testrapporten, CE/GPSR-beoordeling door deskundige |
| Consumentenrecht | Placeholdercontact/privacy/voorwaarden | Juridische pagina-templates, informatiechecklist, herroepingsknop, duurzame bevestiging | Jurist, Nederlandse retourroute, echte leverbelofte, klachten-/garantie-/refundproces |
| Btw/import | Geen fiscale implementatie | Configureerbare kostenledger en prijsfixtures | Boekhouder/fiscalist: goederenstroom, importeur, IOSS/OSS, btw, rechten en facturatie |
| Privacy | Magic-linkprototype; mand in localStorage | Privacyrechten, export/verwijdering, veldretentie, loggingredactie, cookie-inventaris | Verwerkerslijst/DPA's, grondslagen, bewaartermijnen, doorgiften, contactpunt en beleid |

## Kritieke technische gaps

1. **Checkoutmodel is niet compleet.** `orders` bevat geen adres, postcodegebonden verzendquote, btw-uitsplitsing, leverbelofte, retourkosten, prijsledger of immutable kopie van de getoonde voorwaarden. De RPC telt alleen `sale_price_minor` op. Bouw dit vóór Stripe; laat de server altijd bedrag en verkoopbaarheid bepalen. Stripe bevestigt eveneens dat bedragen server-side moeten worden bepaald en dat afhandeling via webhooks hoort te lopen ([Stripe iDEAL](https://docs.stripe.com/payments/ideal/accept-a-payment), [Checkout lifecycle](https://docs.stripe.com/payments/checkout/how-checkout-works)).
2. **Gastcheckout ontbreekt.** De browser en database eisen een account, hoewel het eigen M0-contract gastcheckout vereist. Implementeer een hoog-entropisch ordergebonden gasttoken buiten URL/logs plus veilige orderstatus en herroeping.
3. **Betaallevenscyclus is incompleet.** Voeg `checkout.session.expired`, async failure, gedeeltelijke/volledige refund, dispute, bedrag-/adresreconciliatie en out-of-order tests toe. Fulfilment mag pas na geverifieerde webhook starten; Stripe adviseert server-side webhookfulfilment ([Stripe fulfillment](https://docs.stripe.com/checkout/fulfillment), [webhooks](https://docs.stripe.com/webhooks)).
4. **Securitybewijs ontbreekt.** Test anon, twee accounts, admin/service role, IDOR, ingetrokken sessie, security-definer-RPC's en logredactie. Productie vereist daarnaast Supabase Security Advisor, RLS op alle blootgestelde tabellen, SSL/network controls, MFA, eigen SMTP, loadtest en back-up/RPO-keuze ([Supabase Production Checklist](https://supabase.com/docs/guides/deployment/going-into-prod)).
5. **Operations ontbreken.** Geen admin voor productgoedkeuring, syncincidenten, orders, refunds, recalls of support; geen monitoring/alerts, restoretest of betrouwbare transactional e-mail.

## AliExpress, prijs en fulfilment

Er is geen bewijs dat de getoonde AliExpress consumentenlinks een contractueel bruikbare dropshippingbron zijn. De publiek vindbare officiële AliExpress-documentatie betreft onder meer een **verouderde affiliate-API** en promotionele `app_sale_price`; dat is geen garantie van exacte SKU-prijs, voorraad, NL-verzending of fulfilment ([AliExpress Open Platform — deprecated Affiliate API](https://open.alitrip.com/docs/doc.htm?articleId=118195&docType=1&treeId=674), [product-detail response](https://open.alitrip.com/docs/api.htm?apiId=48595)). Gebruik deze data dus niet automatisch als inkoopprijs.

De eigenaar moet vóór implementatieproductie verkrijgen en archiveren:

- toegestane API/feedvoorwaarden en app-credentials;
- exacte product-ID + SKU + variant/fingerprint;
- echte quote voor aantal, NL-postcode, verzendmethode, voorraad, prijs en valuta;
- juridische leveranciersidentiteit, factuurpartij, substitutieverbod, incident-/recallmedewerking en persoonsgegevensafspraken;
- heen- en retourproef, tracking, p50/p90-levertijd, schade, douane/bijkosten en Nederlands retouradres.

Daarna kan de code één private stagingadapter, FX-audit, prijsledger, TTL, margepoorten en circuit breaker krijgen. Nooit scrapen of supplierdata rechtstreeks publiceren.

## Consumentenrecht en juridische pagina's

Voor livegang ontbreken minimaal: contact/bedrijfsgegevens, privacyverklaring, verkoopvoorwaarden, verzend-/leverinformatie, betaalinformatie, retour-/herroepingsbeleid, garantie/klachten, modelformulier, productveiligheidsinformatie en een toegankelijke online herroepingsfunctie. De huidige footer opent placeholders en is dus onvoldoende.

De ACM noemt voor Nederlandse dropshipping onder meer bedrijfsnaam, vestigingsadres, KvK- en btw-nummer, correcte herkomst/levertijd, het annuleringsrecht en een **Nederlands retouradres**; sinds 19 juni 2026 is de online herroepingsfunctie relevant ([ACM Checklist dropshipping](https://www.acm.nl/nl/verkoop-aan-consumenten/online-verkoop/checklist-dropshipping)). Laat een Nederlandse e-commercejurist de uiteindelijke teksten én checkout-UX goedkeuren. Toon vóór de betaalactie de handelaar, totaalprijs, btw/verplichte kosten, herkomst, levertermijn, retourkosten, garantie, herroeping en productveiligheidsinformatie; archiveer exact wat de klant zag.

## Btw en import

De eigenaar moet met een fiscalist vastleggen wie importeur is, waar invoer plaatsvindt, welke Incoterm/risico-overgang geldt, of IOSS wordt gebruikt en welke kosten niet-terugvorderbaar zijn. De Belastingdienst kwalificeert rechtstreekse invoer en levering aan EU-consumenten als dropshipping; de Invoerregeling kan onder voorwaarden gelden voor zendingen tot €150, terwijl doorgaans btw van het bestemmingsland geldt ([Belastingdienst invoerregeling](https://www.belastingdienst.nl/wps/wcm/connect/nl/btw/content/btw-goederen-importeren-leveren), [OSS/IOSS](https://www.belastingdienst.nl/wps/wcm/connect/nl/btw/content/btw-melden-eenloketsysteem)).

Pas na dit memo kan de prijsengine correct btw, invoerrechten, IOSS/expediteur, betaalfee, retour-/garantie-/recallreserve, producentenverplichtingen en doelmarge verwerken. De huidige eenvoudige artikelsom mag niet live.

## Productveiligheid

Draagbare elektrische ventilatoren kunnen naast GPSR onder productspecifieke regels voor elektrische apparatuur, EMC, RoHS, batterijen/laders en producentenverantwoordelijkheid vallen; bepaal dit per exacte SKU met een bevoegde deskundige. Sinds 13 december 2024 is GPSR toepasbaar. Voor afstandsverkoop moet de productpagina identificatie, fabrikant, en bij een fabrikant buiten de EU ook de EU-verantwoordelijke persoon plus waarschuwingen/veiligheidsinformatie tonen ([Europese Commissie GPSR Q&A](https://webgate.ec.europa.eu/safety/consumers/consumers_safety_gate/obligationsForBusinesses/documents/Q%26A.pdf), [GPSR-samenvatting](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=LEGISSUM%3A4670517)).

Per SKU vereist: fysiek sample en fingerprint, fabrikant/importeur/EU-verantwoordelijke, batchtraceerbaarheid, Nederlandstalige instructies/waarschuwingen, toepasselijke conformiteitsverklaring en testrapporten geverifieerd bij uitgevende partij, Safety Gate-check, batterij-/adaptergegevens, claimsbewijs, klachten/incident/recallproces en verzekeringsbesluit. Een CE-logo of AliExpress-vermelding is geen voldoende bewijs.

## Privacy en cookies

Maak een veldniveau-dataflow voor GitHub, Supabase, Stripe, leverancier, vervoerder en mailprovider: doel, grondslag, ontvanger, regio/doorgifte, bewaartermijn, verwijderpad en verwerkersovereenkomst. Implementeer inzage/export/rectificatie/verwijdering met identiteitscontrole; de AP wijst erop dat webshops privacyrechten veilig in een accountflow kunnen opnemen ([AP privacyrechten](https://autoriteitpersoonsgegevens.nl/themas/basis-avg/privacyrechten-avg/voor-organisaties-privacyrechten-in-de-praktijk)).

Houd analytics/advertising standaard afwezig. Functionele winkelmand-/loginopslag kan zonder trackingtoestemming mogelijk zijn, maar tracking vereist vrije, specifieke toestemming en weigeren mag de winkel niet blokkeren ([AP cookiebanners](https://www.autoriteitpersoonsgegevens.nl/actueel/foute-cookiebanners-aangepast-na-ingrijpen-ap)). Test cookies, localStorage en third-party requests vóór en na toestemming. Log geen adressen, tokens, betaaldata, webhookpayloads of IOSS-nummer.

## Uitvoerbare volgorde

1. **Nu zonder credentials:** voltooi schema/RLS-testmatrix, guest/order/quote/contractsnapshot/refundmodellen, juridische paginatemplates met placeholders, accessibility, testfixtures en admin-workflows; checkout blijft uit.
2. **Eigenaar:** lever bedrijfs-/retour-/supportgegevens, Stripe- en Supabase-projecttoegang, API-contract, leverancierdossier en fiscale/logistieke beslissingen.
3. **Professionals:** fiscalist, e-commercejurist en product-compliancedeskundige keuren respectievelijk geldstroom, UX/teksten en iedere SKU goed.
4. **Testomgeving:** echte Supabase-migraties/RLS, Stripe iDEAL-testbetaling, dubbele/out-of-order webhook, refund, magic-link/SMTP, guest flow, adresmismatch en restoretest.
5. **Alleen daarna:** één goedgekeurde SKU met echte quote publiceren, end-to-end bestelling + retour/refund uitvoeren, onafhankelijke security/launchreview afronden en pas dan live keys/`CHECKOUT_ENABLED` activeren.
