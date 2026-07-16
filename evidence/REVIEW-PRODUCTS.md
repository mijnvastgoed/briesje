# Onafhankelijke review — M0 products/pricing

Reviewdatum: 16 juli 2026  
Reviewdimensies: KISS, correctness, security en technische uitvoerbaarheid  
Beoordeeld: `evidence/M0-PRODUCTS-PRICING.md`

## Oordeel

De no-go-conclusie is correct en voorzichtig: het document verzint geen productdata en maakt terecht onderscheid tussen productniveau- en SKU-data. Het prijsmodel is een bruikbare hypothese, maar nog niet implementeerbaar als eenduidig contract. Onderstaande concrete bezwaren moeten worden verwerkt voordat dit document als technische specificatie voor M1/M4 wordt gebruikt.

## Vereiste correcties

### 1 — Kritiek: de prijsformule en contributiecontrole gebruiken niet aantoonbaar dezelfde kostenbasis

`cost` bevat `risk_buffer` en `payment_fee_fixed`, terwijl `contribution` vervolgens `landed_cost` en `payment_fee(candidate_price)` aftrekt. `landed_cost` en `payment_fee()` zijn niet formeel gedefinieerd. Hierdoor kan de vaste fee dubbel worden afgetrokken of juist verdwijnen en kan de buffer wel de verkoopprijs verhogen maar niet meetellen in de minimumcontributietoets. De fixtures impliceren dat de buffer als kostenpost wordt afgetrokken, maar het contract zegt dat niet.

**Vereiste correctie:** definieer één canonieke kostenset in minor units/decimalen, bijvoorbeeld:

```text
variable_cost = source_price_eur + shipping_cost + risk_buffer
payment_fee(sale_price) = payment_fee_fixed + sale_price * payment_fee_rate
vat_amount(sale_price) = sale_price * vat_share_of_gross
net_contribution = sale_price - vat_amount(sale_price)
                   - variable_cost - payment_fee(sale_price)
```

Definieer daarna expliciet of `target_margin_rate` een percentage van bruto omzet, netto-omzet exclusief btw, contributie of kostprijs is. Laat zowel de closed-form minimumprijs als de post-roundingcontrole uit exact deze definities volgen. Voeg een fixture mét vaste betaalfee toe en laat een fiscalist de btw-basis bevestigen.

### 2 — Hoog: `target_margin` en `minimum_contribution` zijn twee poorten, maar hun onderlinge semantiek ontbreekt

De noemer behandelt target margin als aandeel van de bruto verkoopprijs. De contributie wordt exclusief btw berekend en alleen tegen een absoluut minimum getoetst. Dit kan technisch werken, maar “marge” kan door eigenaar, boekhouder en implementator anders worden geïnterpreteerd. Ook wordt nergens na afronding expliciet gecontroleerd dat de gekozen procentuele doelmarge nog wordt gehaald volgens dezelfde definitie.

**Vereiste correctie:** leg één `pricing_policy_version` vast met benoemde definities en valideer na afronding beide invarianten: `net_contribution >= minimum_contribution` én de gekozen margeratio `>= target_margin`. Sla policyversie en alle invoer op in elke prijssnapshot. Tot fiscale bevestiging moeten de velden configuratie in een uitgeschakelde policy zijn, geen productie-defaults.

### 3 — Hoog: circuit-breakerstatus laat ruimte om een verlieslatende oude prijs live te houden

Bij een landed-costwijziging tussen 15% en 30% staat `pending_price_review, niet automatisch publiceren`. Dat kan betekenen “houd de eerder gepubliceerde verkoopprijs actief”. Scenario 8 zegt daarentegen dat checkout een stale SKU weigert. Die laatste interpretatie is veilig, maar is niet als statusinvariant vastgelegd. Ook is “herstel na één geslaagde sync” onvoldoende tegen een eenmalige corrupte lage of hoge bronwaarde.

**Vereiste correctie:** definieer onafhankelijk `catalog_visibility` en `checkout_eligibility`. Elke `pending_price_review`, stale/unknown input of breaker-trip maakt checkout direct onmogelijk, ook als de oude catalogusprijs ter informatie zichtbaar blijft. Definieer herstel conservatief: handmatige unblock of meerdere consistente observaties binnen bandbreedte; één sync mag alleen herstellen als de oorspronkelijke blokkade aantoonbaar tijdelijk en niet handmatig was. Checkout moet dezelfde prijsversie atomair herlezen.

### 4 — Hoog: percentagedrempels vergelijken “landed cost”, maar fixtures vergelijken alleen bronprijs

Het contract zegt dat 15%/30% versus de vorige goedgekeurde landed cost wordt gemeten. Scenario 7–9 labelt daarentegen veranderingen van de bronprijs (`€8→€9`, enz.) alsof die rechtstreeks de breaker bepalen. Met €2 verzending en €1,50 buffer is `8→9` slechts circa 8,7% landed-coststijging, `8→10` circa 17,4% en `8→12` circa 34,8%. Scenario 8 valt nog steeds in review, maar de vermelde +25% is niet de gecontracteerde metriek en grensgevallen zullen fout worden getest.

**Vereiste correctie:** maak de metriek exact: `abs(new_landed_cost-old_landed_cost)/old_landed_cost`, definieer welke componenten en wisselkoers erin zitten, en herschrijf fixtures met zowel componentwijziging als berekend landed-costpercentage. Voeg exact 15%, net boven 15%, exact 30% en net boven 30% toe. Definieer gedrag als de vorige kost nul/ontbrekend is: blokkeren, niet delen.

### 5 — Hoog: verzendkosten naar “NL” zijn niet genoeg voor een afrekenbare prijs

De API-proef gebruikt landniveauparameters, terwijl verzendkosten, beschikbaarheid en toeslagen kunnen afhangen van postcode, regio, variant, hoeveelheid, magazijn en gekozen vervoerder. Eén productdetailresponse bewijst dus geen fulfilmentkost voor een concrete order. Bovendien kan de prijs bij checkout wijzigen nadat de AliExpress-data 23 uur oud is.

**Vereiste correctie:** leg vast welke verzendquote-granulariteit de toegestane bron werkelijk ondersteunt. Als geen reproduceerbare quote per relevante bestemming/variant/quantity bestaat, gebruik een door de eigenaar goedgekeurde conservatieve verzendkostentabel plus buffer en beperk het verkoopgebied, of houd het product geblokkeerd. Definieer maximale quoteleeftijd bij checkout afzonderlijk van catalogussync; 24 uur is een voorstel dat met volatiliteitsbewijs moet worden onderbouwd.

### 6 — Middel: valuta- en tijdssemantiek zijn onvoldoende deterministisch

`source_price * fx_rate` specificeert niet de koersrichting, provider, handelsdatum, timezone of maximale leeftijd. Bij EUR-responses is onduidelijk of `fx_rate=1` wordt opgeslagen. “Response ouder dan 24 uur” vermeldt niet of bron-, ontvangst- of verwerkingstijd leidend is. Een kwaadwillende of foutieve toekomsttimestamp kan freshness omzeilen.

**Vereiste correctie:** definieer `fx_rate_eur_per_source_unit`, provider/rate-id, `observed_at` van Briesjes server, optionele `source_timestamp`, UTC en maximale clock skew. Freshness wordt uitsluitend vanaf een vertrouwde server-ontvangsttijd bepaald. Sla originele prijs/valuta én genormaliseerde EUR-kosten op; gebruik voor EUR expliciet koers 1 met dezelfde auditvelden.

### 7 — Middel: API-ingestie mist noodzakelijke security- en robuustheidsgrenzen

Het document beschermt secrets, maar niet de parser en downstream assets. Externe data is ontrusted: extreem grote responses, onverwachte types/decimalen, HTML in titels, schadelijke afbeeldings-URL's, redirects, rate limits en gedeeltelijke resultaten kunnen sync of storefront beïnvloeden. “HTTP/API-succes” is onvoldoende; APIs kunnen een HTTP 200 met business-error of onvolledige pagina leveren.

**Vereiste correctie:** voeg een smalle adapterboundary toe met response-size/timeouts, allowlisted HTTPS-hosts, redirectlimiet, schema/type/rangevalidatie, HTML als tekst ontsmetten/escapen, afbeeldingsproxy of strikte image-host/CSP-keuze, pagination-completeness, API error-codecontrole, retry met jitter en rate-limitbudget. Archiveer geredigeerde evidence buiten publiek bereik en zet nooit volledige supplier-payloads rechtstreeks in publieke tabellen.

### 8 — Middel: SKU-identiteit en variantcontinuïteit vereisen meer dan een numerieke match

Een leverancier kan attributen achter dezelfde SKU wijzigen of productcontent vervangen. Alleen `product-ID + SKU-ID` match beschermt niet tegen kleur/model/plug/batterijwijziging. Dit is zowel een prijs- als veiligheidsrisico.

**Vereiste correctie:** maak een immutable interne variant-id en bewaar een genormaliseerde fingerprint van kritieke variantattributen, leverancier/winkel, magazijn, batterij-/stekkerspecificatie en relevante compliance-referenties. Iedere wijziging in kritieke attributen zet de variant op `pending_product_review` en checkout uit, ook als SKU-ID gelijk blijft.

### 9 — Middel: productgoedkeuring en prijsgoedkeuring zijn nog niet technisch gescheiden

Het document gebruikt `approved`, `blocked_source_data`, `pending_price_review` en `unavailable` voor verschillende dimensies. Eén statusveld leidt snel tot ongeldige overgangen: een prijssync zou bijvoorbeeld onbedoeld een complianceblokkade kunnen herstellen.

**Vereiste correctie:** houd minimaal onafhankelijke statussen bij voor `source_data`, `compliance`, `supplier_test`, `pricing` en `availability`; bereken `checkout_eligible` als AND van alle verplichte poorten. Alleen de eigenaar van een dimensie mag die dimensie vrijgeven. Leg statusreden, actor, evidence-id en timestamp vast in een append-only auditlog.

### 10 — Middel/KISS: de drie-dagenproef bewijst parserstabiliteit niet

Drie metingen op drie dagen zijn nuttig als eerste evidence, maar geen bewijs van een stabiel contract of betrouwbare prijsfeed. Andersom blokkeert een kalenderdagregel snelle geautomatiseerde ontwikkeling zonder extra veiligheid te garanderen.

**Vereiste correctie:** benoem dit als minimale M0-observatie, niet als stabiliteitsbewijs. Splits tests in (a) contractfixtures met opgeslagen en geredigeerde responses, inclusief ontbrekende/gewijzigde velden, en (b) live canary-metingen over tijd. Houd M0 KISS: één adapter, één gevalideerd intern `SupplierQuote`-type en één pricingfunctie; voeg geen algemene supplierframeworks of automatische publicatie toe.

### 11 — Laag: afronden naar `x,95` is niet volledig gespecificeerd

“Eerstvolgende prijs die eindigt op ,95” is begrijpelijk voor positieve eurobedragen, maar implementaties kunnen verschillen bij €0,95, bedragen met subcenten en exacte grenzen door decimal-context.

**Vereiste correctie:** voer alle eindbedragen in eurocenten uit na een expliciete conservatieve ceiling van kostcomponenten; specificeer een pure functie met voorbeelden voor `0`, `0.949`, `0.95`, `0.951`, `11.949`, `11.95` en `11.951`. Negatieve/niet-finite invoer faalt vóór afronding. De regel moet juridisch/commercieel configureerbaar blijven en mag geen schijnkorting suggereren.

## Securitybevinding zonder bezwaar

Het verbod op scraping, client-side prijsvertrouwen, coupon-/persoonlijke prijzen en secrets in logs is correct. Ook het blokkeren bij ontbrekende data en het behouden van betaalde ordersnapshots sluiten goed aan op de technische trust boundaries. Deze controles moeten wel server-side en met databaseconstraints worden afgedwongen; documentatie of UI-status alleen is niet voldoende.

## Minimale herreviewcriteria

Een herreview kan positief eindigen wanneer:

- kosten-, btw-, fee-, contributie- en margedefinities één sluitend rekencontract vormen;
- de fixtures exact overeenkomen met de gekozen breaker-metriek en vaste fees/afrondingsgrenzen testen;
- elke review/stale/compliance-status checkout aantoonbaar blokkeert;
- tijd, FX, verzendquote en SKU-fingerprint deterministisch zijn vastgelegd;
- externe API-data via een begrensde, gevalideerde adapter naar één intern quote-type gaat;
- fiscale parameters expliciet geblokkeerd blijven totdat een bevoegde professional ze bevestigt.

