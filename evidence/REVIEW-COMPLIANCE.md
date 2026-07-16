# Tweede opinie — uitvoerbaarheid M0-compliance

**Reviewdatum:** 16 juli 2026  
**Reviewscope:** product, leverancier en prijsuitvoerbaarheid van `M0-COMPLIANCE.md`. Geen zelfstandige juridische beoordeling.

## Oordeel

Het NO-GO-oordeel is correct en conservatief. Het document benoemt de relevante bewijssoorten en voorkomt terecht dat een AliExpress-pagina, CE-logo of generiek certificaat als productgoedkeuring geldt. Het is echter nog geen uitvoerbaar leveranciers- en productacceptatieprotocol: verschillende checkboxes hebben geen eigenaar, controlehandeling, geldigheidsduur of machineleesbare uitkomst. Ook ontbreekt de koppeling tussen compliancekosten en de prijs-/beschikbaarheidsstatus.

De onderstaande bezwaren moeten worden verwerkt voordat dit dossier als M0-uitvoeringscontract kan gelden. Ze veranderen het huidige NO-GO niet.

## Blokkerende bezwaren en vereiste correcties

### 1. Er is geen leveranciersidentiteit of contracteerbare tegenpartij gedefinieerd

Een AliExpress-winkelnaam of product-ID bewijst niet wie juridisch levert, wie documenten mag afgeven, wie wijzigingen meldt en op wie Briesje verhaal kan halen. De checklist vraagt een factuur/leverancierscontract, maar definieert niet welke gegevens en verplichtingen minimaal nodig zijn.

**Correctie vereist:** voeg per kandidaat een leveranciersrecord toe met juridische naam, registratienummer, vestigingsadres, contactpersoon, winkel-ID/URL, facturerende entiteit, bank-/betaalentiteit en onafhankelijke contactverificatie. Eis contractueel ten minste: exacte BOM/model/SKU, geen ongeautoriseerde substitutie, wijzigingsmelding vooraf, batchtraceerbaarheid, documentauthenticiteit, incidentmelding, recallmedewerking, aansprakelijkheid, lever-/verliesregeling, persoonsgegevensinstructies en bewaartermijn. Als de AliExpress-verkoper dit niet schriftelijk accepteert, blijft de SKU `rejected_supplier`.

### 2. Een eenmalige SKU-match beschermt niet tegen stille productsubstitutie

AliExpress-product-ID's en variant-ID's kunnen blijven bestaan terwijl behuizing, motor, cel, BMS, kabel, adapter, verpakking of fabrikant verandert. De huidige periodieke “herverificatie” is niet concreet genoeg.

**Correctie vereist:** maak een goedgekeurde productbaseline met foto's, afmetingen/gewicht, model- en batchlabels, component-/BOM-identificatie waar beschikbaar, batterijcel/pack, firmware indien aanwezig, verpakking en hashes/versies van verklaring en testrapporten. Vergelijk ieder ontvangen monster en periodiek een fulfilmentorder met die baseline. Elke afwijking in fabrikant, model, batterij, adapter, veiligheidslabel, testdocument, verzendland of leverancier zet de variant automatisch op `pending_requalification`; geen automatische erfenis van goedkeuring.

### 3. De monstertest is niet reproduceerbaar of deskundig afgebakend

“Duurtest”, “temperatuur” en “rotorafscherming” hebben geen testmethode, limiet, meetmiddel, aantal exemplaren of bevoegd beoordelaar. Eén exemplaar zegt weinig over batchvariatie en kan destructive testing niet vervangen.

**Correctie vereist:** laat een product-complianceprofessional per producttype een testplan met normreferenties, meetmethode, pass/fail-limieten en gekalibreerde middelen vaststellen. Leg minimaal monsteraantal en batchspreiding vast. Scheid een gebruikerstest (geluid, bediening, levertijd) van veiligheids-/conformiteitstests; claim op basis van een interne proef nooit naleving van een norm. Bewaar serienummer/batch, meetdata, foto's en chain of custody.

### 4. Documentverificatie heeft geen sluitend acceptatiepad

“Controleer rapportnummer en laboratorium rechtstreeks” is goed, maar er staat niet wat telt als authenticiteitsbewijs, welke model-/variantvelden moeten matchen of hoe om te gaan met vertrouwelijke technische documentatie. Een leverancier zal mogelijk niet het volledige technisch dossier delen.

**Correctie vereist:** definieer per document verplichte velden, uitgever, ondertekenaar, uitgiftedatum, normversie, model/BOM/batterij/adapter-match, rapportomvang, geldigheids-/herbeoordelingsdatum en verificatieantwoord van lab of notified body waar relevant. Leg vast wie het technische dossier wettelijk houdt en hoe Briesje/toezichthouder het binnen de vereiste termijn kan verkrijgen. “Verkoper zegt dat het vertrouwelijk is” is geen goedkeuring. Ontbrekende toegang wordt `blocked_document_access`.

### 5. De online-aanboddata zijn niet gekoppeld aan een beheersbare bron

Het dossier noemt GPSR-velden en waarschuwingen, maar niet hoe Briesje voorkomt dat deze uit een wisselende AliExpress-omschrijving worden gekopieerd of na een sync onjuist worden overschreven.

**Correctie vereist:** maak geverifieerde compliancevelden handmatig beheerde, geversioneerde catalogusdata met bewijslink en reviewer; leverancierssync mag deze nooit overschrijven. Wijzigingen creëren een reviewtaak. Producttitel, afbeeldingen, fabrikant, EU-verantwoordelijke persoon, model, waarschuwingen en Nederlandse handleiding moeten exact aan de goedgekeurde SKU-versie zijn gekoppeld.

### 6. Leverbaarheid naar “Nederland” is te grof voor prijs en belofte

Verzendprijs, belastingen, vervoerder en levertijd kunnen afhangen van postcode, verzendmagazijn, batterijrestricties, variant, aantallen en gekozen logistieke dienst. Een generieke NL-productpagina of affiliateprijs bewijst geen fulfilmentroute.

**Correctie vereist:** bewijs per SKU en ondersteunde postcodezone een bestelbare verzendoptie met verzendland, vervoerder/service, batterijacceptatie, trackingniveau, prijs, DDP/IOSS-route, uiterste beloofdatum en wie verlies/schade draagt. Meet meerdere echte orders op verschillende momenten. Blokkeer afwijkende eilanden/postcodegebieden of prijs die niet vooraf betrouwbaar kan worden bepaald. Bewaar p50/p90 werkelijke bezorgtijd en baseer de consumentenbelofte conservatief op meetdata, niet op de marketplace-indicatie.

### 7. Retourbaarheid is alleen winkelbreed genoemd, niet economisch per product getest

Een Nederlands retouradres maakt een retour nog niet uitvoerbaar: inspectie, quarantaine van lithiumproducten, gegevenswissing bij slimme varianten, terugbetaling, refurbish/afvoer en verhaal op leverancier ontbreken. China-retour is doorgaans geen bruikbare consumentenroute.

**Correctie vereist:** maak per product een retourbeslisboom en kostenfixture voor ongeopend, gebruikt binnen bedenktijd, defect, transportschade, batterijzwelling en recall. Leg eigenaar, veiligheidsopslag, inspectietermijn, refund-SLA en eindbestemming vast. Test minimaal één echte retour vanaf consumentscenario tot refund en verwerk niet-recupereerbare product-, heen-, retour-, betaal- en afvalkosten in de reserve.

### 8. Compliance- en producentenkosten ontbreken als concrete prijsinput

De checklist stelt dat de prijs alle kosten moet dekken, maar bevat geen cost ledger. Hierdoor kan een SKU alle compliancevakjes halen en toch structureel verliesgevend zijn.

**Correctie vereist:** voeg per SKU/order toerekening toe voor product, variantgebonden verzending, valutaopslag, invoerrechten/-btw voor zover kosten, inklaring, betaalfee vast/variabel, IOSS/intermediair, verpakking, WEEE/batterij/verpakking-UPV, laboratorium/documentreview, monsters, Nederlandse fulfilment/retour, support, defecten, chargebacks, garantie, verzekering en recallreserve. Scheid vaste periodieke kosten van variabele kosten en toon break-evenvolume. Zonder ondertekende input of minimumcontributie wordt de SKU `unavailable_pricing`.

### 9. Btw en marge zijn niet rekenkundig vastgelegd

“Inclusief 21% btw” is onvoldoende om de serverformule te valideren. Het wettelijke tarief van 21% is niet hetzelfde als 21% aftrek van een bruto verkoopprijs; het btw-aandeel daarin is bij een normale inclusief-btw-berekening `21/121`. De precieze fiscale goederenstroom kan dit verder veranderen. Vaste betaalkosten en retourreserve ontbreken eveneens in het rekencontract.

**Correctie vereist:** laat de fiscalist per goederenstroom een testbare formule accorderen. Bewaar btw-tarief en berekeningswijze afzonderlijk. Prijs minimaal met `landed_cost + vaste fee + reserves`, gedeeld door een geldige noemer voor btw-aandeel, variabele betaalfee en doelmarge; controleer daarna expliciet de minimale nettobijdrage. Gebruik decimal arithmetic, één eindafronding en een onveranderlijke ordersnapshot. Voeg grensgevallen toe voor vaste fees, refunds, gedeeltelijke refunds, coupons, bundels en meerdere stuks.

### 10. Actuele prijs/voorraad is een GO-criterium zonder toegestane bron of versheidsregel

De compliance-review noemt reproduceerbare prijs/voorraad, maar specificeert geen AliExpress-endpoint/feed, exacte variantsemantiek of maximaal toegestane ouderdom. Een productniveau-“vanaf”- of affiliateprijs kan afwijken van de gekozen SKU en checkoutprijs; promotie-, app-, account- en couponprijzen zijn vaak niet structureel.

**Correctie vereist:** keur alleen een officieel toegestane API/feed goed die exact product-ID én SKU, valuta, bestemming, voorraad en toepasselijke verzendkosten reproduceert. Archiveer geredigeerde request/response/timestamp en API-voorwaarden. Sluit persoonlijke, welkomst-, coupon-, munt- en tijdelijke app-prijzen uit tenzij contractueel gegarandeerd voor iedere fulfilmentorder. Stel een korte versheidslimiet vast (voorstel: 24 uur voor catalogus, server-side hercontrole bij checkout) en blokkeer ontbrekende of stale velden.

### 11. Automatische prijswijziging heeft geen circuit breaker

“Automatische depublicatie” is niet vertaald naar drempels en toestanden. Daardoor kan een parsefout, valutaomslag, nulprijs of plotselinge promotie een onveilige verkoopprijs publiceren.

**Correctie vereist:** definieer statusovergangen en thresholds. Voorstel: landed-costwijziging tot 15% alleen automatisch verwerken wanneer alle data compleet en vers zijn; boven 15% `pending_price_review`; boven 30%, nul/negatief, valutawissel, verdwenen SKU, onbekende voorraad/verzending of parsefout onmiddellijk `unavailable`. Herstel pas na geldige sync en waar vereist menselijke goedkeuring. Alle besluiten krijgen old/new values, reden, bron en timestamp.

### 12. Goedkeuring heeft geen verloopdatum of wijzigingstriggers

Een eenmalige GO kan onbegrensd blijven staan, terwijl regelgeving, documenten, leverancier, Safety Gate, batterij en logistiek veranderen.

**Correctie vereist:** voeg per bewijsstuk `verified_at`, `verified_by`, `valid_until` en `source_version` toe. Definieer hercontrolefrequenties en directe triggers: supplier-/BOM-/label-/documentwijziging, klacht/incident, Safety Gate-signaal, prijs- of verzendlandwijziging, API-veldverlies, nieuwe regelgeving en verlopen verzekering/registratie. Bij een trigger gaat publicatie standaard dicht totdat de relevante deelreview slaagt.

## Belangrijke niet-blokkerende verduidelijkingen

- Splits `rejected` (inhoudelijk ongeschikt), `blocked` (bewijs ontbreekt), `pending_review`, `approved` en `unavailable` (operationeel tijdelijk) zodat een agent ontbrekend bewijs niet als afwijzing of goedkeuring interpreteert.
- Leg een vaste producteigenaar, compliance-reviewer, fiscalist en operationeel eigenaar per checkbox vast. Zelfgoedkeuring van leverancier of onbevoegde agent telt niet.
- Voeg een expliciete merken-/intellectuele-eigendomscontrole toe vóór het inkopen van monsters en afbeeldingen. De huidige enkele checklistregel is te globaal.
- Maak geluid, luchtstroom, batterijduur, laadduur, vermogen en “koeling”-claims alleen publiceerbaar met een vastgelegde testmethode en exacte SKU-resultaten. Marketplaceclaims mogen niet worden overgenomen.
- Voeg een second-sourcebeleid toe. Een alternatieve AliExpress-aanbieder is een nieuwe leverancier/SKU en moet volledig worden gekwalificeerd; hij is geen directe failover.

## Minimale correctie voor een uitvoerbare M0-go/no-go

Voor minimaal één SKU moet één dossierregel alle volgende links bevatten:

1. exacte product-/SKU-baseline en leveranciersidentiteit;
2. toepasselijkheidsmatrix en geverifieerde documenten;
3. deskundig testplan plus gematchte monsterresultaten;
4. toegestane, geredigeerde prijs-/voorraad-/verzendbronrespons voor NL/EUR;
5. gemeten fulfilment en end-to-end retour/refund;
6. fiscaal goedgekeurde goederenstroom;
7. volledige cost ledger, prijsberekening en minimumcontributie;
8. UPV/verzekering/recall- en supportbewijs;
9. geldigheidsdata, wijzigingstriggers en expliciete ondertekening door bevoegde rollen.

Zonder deze negen gekoppelde bewijsblokken blijft het document een goede risicolijst, maar geen verifieerbaar GO-contract. Het huidige besluit voor product A, product B en publieke lancering blijft daarom **NO-GO**.
