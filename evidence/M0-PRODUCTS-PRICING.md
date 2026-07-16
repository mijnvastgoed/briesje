# M0 — AliExpress, productselectie en prijsmodel

Status: **geblokkeerd voor verkoop**  
Onderzocht op: 16 juli 2026  
Scope: uitsluitend de AliExpress-/product-/prijsdelen van M0. Dit document is geen productveiligheids- of fiscaal advies.

## Conclusie

Er is nog geen reproduceerbare, toegestane bronrespons voor de twee opgegeven varianten. De links identificeren wel twee AliExpress-product-ID's en bevatten elk een voorkeurs-SKU in `pdp_ext_f`, maar de publieke productpagina's konden tijdens dit onderzoek niet betrouwbaar worden uitgelezen. Daarom zijn titel, variantkenmerken, actuele prijs, voorraad, verzending, leverancier, beoordelingen en veiligheidsinformatie bewust niet ingevuld.

AliExpress documenteert een affiliate productzoek-API en een affiliate productdetail-API. Die kunnen onder meer zoeken op land, levertermijn en trefwoord en productniveau-prijzen in een doelvaluta teruggeven. De gepubliceerde responsespecificatie bewijst echter niet dat deze route voor Briesje de gekozen **SKU**, SKU-voorraad of de actuele verzendkosten naar een Nederlands adres levert. De oudere dropshipping-API documenteert wel SKU-prijs en SKU-voorraad, maar de officiële documentatie markeert de gehele Dropshipping-sectie als verouderd. Briesje mag daar dus niet zonder schriftelijke bevestiging en een geslaagde eigen API-proef op bouwen.

**M0-besluit voor deze scope: no-go.** Eerst moeten API-toegang, toepasselijke gebruiksvoorwaarden en echte, opgeslagen responses voor land `NL`, valuta `EUR` en beide gekozen SKU's worden bewezen. Handmatig beheerde bronprijzen mogen later hoogstens voor een besloten prototype worden gebruikt, niet als automatische prijs-sync of productieclaim.

## Officiële API-bevindingen

| Mogelijkheid | Wat officieel is gedocumenteerd | Wat niet is bewezen voor Briesje |
|---|---|---|
| `aliexpress.affiliate.product.query` | Productzoeken met onder andere `keywords`, `ship_to_country`, `delivery_days`, `target_currency`, `target_language` en sortering; responsevoorbeeld bevat product-ID, productprijs, winkel, beoordeling en volume. De pagina noemt de API gratis en zonder gebruikersautorisatie, maar requests vereisen nog steeds een platform-app-key en ondertekening. | SKU-ID, SKU-voorraad, verzendoptie/-prijs naar een concreet adres, productveiligheidsdocumenten en het recht om de gevonden data als wederverkoper te gebruiken. |
| `aliexpress.affiliate.productdetail.get` | Detailopvraag voor een lijst product-ID's met `country`, `target_currency` en `target_language`; responsevoorbeeld bevat productniveau-verkoopprijs en productmetadata. | Dat de opgegeven SKU wordt geselecteerd of dat variantprijs, voorraad en verzending worden teruggegeven. |
| `aliexpress.ds.product.get` | De responsebeschrijving bevat SKU-records met SKU-ID, prijs, voorraadstatus en beschikbare voorraad. | Beschikbaarheid voor nieuwe integraties: de officiële navigatie noemt `Dropshipping（已废弃）` (verouderd) en de endpoint vereist autorisatie/session. Geen implementatiebasis zonder bevestiging van AliExpress. |

Primaire bronnen:

- [AliExpress Open Platform — affiliate product query](https://open.alitrip.com/docs/api.htm?apiId=45803)
- [AliExpress Open Platform — affiliate product detail](https://open.alitrip.com/docs/api.htm?apiId=48595)
- [AliExpress Open Platform — oude dropshipping product-API, als verouderd gemarkeerd](https://open.alitrip.com/docs/doc.htm?articleId=60452&docType=2&treeId=762)

De documentatiesite valt onder het Alibaba/Taobao Open Platform en is deels Chineestalig. Voor productie moet de eigenaar in het partnerportaal de actuele voorwaarden, toegestane use case, quota, databehoud en eventuele affiliatebeperkingen vastleggen als gedateerde PDF/screenshot of supportbevestiging.

## Identificatie van de twee bronlinks

| Briesje-ref. | Product-ID uit URL | Voorkeurs-SKU uit `pdp_ext_f` | Gevalideerde productdata | Status |
|---|---:|---:|---|---|
| A | `1005008081738393` | `12000043648049237` | Geen toegestane API-respons beschikbaar | `blocked_source_data` |
| B | `1005007529621225` | `12000041184498228` | Geen toegestane API-respons beschikbaar | `blocked_source_data` |

Vereist bewijs per regel: onbewerkte response (zonder secrets), requestparameters en timestamp; product-ID én SKU-match; variantattributen; bronprijs en valuta; voorraad; verzendmethode, prijs en belofte naar NL; leverancier/winkel-ID; retourroute; en afzonderlijk het complete veiligheidsdossier. Een productniveau-prijs mag nooit stilzwijgend aan de voorkeurs-SKU worden gekoppeld.

## Reproduceerbare API-proef (nog uit te voeren door accounteigenaar)

1. Registreer een AliExpress/Open Platform-app en laat schriftelijk bevestigen dat productdata voor een eigen dropship-webshop en periodieke prijscontrole is toegestaan.
2. Bewaar app-secret uitsluitend als Supabase-secret. Log nooit signatures, tokens of persoonsgegevens.
3. Vraag via `aliexpress.affiliate.productdetail.get` beide product-ID's op met `country=NL`, `target_currency=EUR`, `target_language=NL` en expliciete relevante velden.
4. Zoek daarnaast met `aliexpress.affiliate.product.query` op de zes kandidaatgroepen, steeds met `ship_to_country=NL`, `target_currency=EUR`, `target_language=NL`; archiveer request, response en tijdstip.
5. Controleer of responses de gekozen SKU en verzendkosten werkelijk bevatten. Zo niet: vraag AliExpress welke actuele, toegestane endpoint/feed dat levert. Gebruik de verouderde DS-API niet als impliciete fallback.
6. Herhaal dezelfde request op drie verschillende dagen en vergelijk prijs, voorraad en leverbaarheid. Alleen een stabiel parseercontract mag naar M4.

Geslaagd betekent: HTTP/API-succes, exacte ID-match, geen ontbrekende kernvelden, bedragen als decimalen plus expliciete valuta, en reproduceerbare NL-leverbaarheid. Een HTML-productpagina, browserprijs, vanaf-prijs, couponprijs of ingelogde persoonlijke prijs is geen syncbron.

## Kandidaatselectie

Zoekgroepen: draagbare nekventilator, opvouwbare bureauventilator, clip-on kinderwagenventilator, USB-handventilator, campingventilator met lamp en mini-luchtkoeler. Selecteer minimaal vier kandidaten uit verschillende winkels; publiceer niets automatisch.

### Harde poorten

Een kandidaat wordt direct `rejected` of `blocked` bij:

- geen exacte variant/SKU uit een toegestane bron;
- niet aantoonbaar leverbaar naar Nederland met prijs en realistische termijn;
- ontbrekende fabrikant, traceerbaarheid of EU-verantwoordelijke marktdeelnemer;
- ontbrekende waarschuwingen, batterij-/USB-specificaties of vereiste CE/GPSR-bewijzen;
- Safety Gate-hit of andere recall zonder sluitende verklaring;
- geen werkbare Nederlandse retourroute;
- ontbrekende bronprijs, verzendkosten, belastingroute of minimumcontributie;
- misleidende claims zoals een onbewezen koelvermogen of geschiktheid voor baby's.

`approved` vereist daarna een fysieke leverancierstest: ontvangen SKU-match, verpakking/documentatie, laad- en accuveiligheid, stabiliteit/bescherming van bladen, geluid, werking, werkelijke tracking/levertijd en retourtest. Rating of verkoopvolume vervangt deze controle niet.

### Rangschikking na de harde poorten

Gebruik de API-signalen alleen om handmatige review te prioriteren: levertermijn, prijsstabiliteit over drie metingen, winkeltraceerbaarheid, beoordelingspercentage en recent volume. Vermijd vaste minimumscores voordat de echte responssemantiek is gevalideerd. Kies bij gelijke geschiktheid eenvoudiger producten met minder batterij-/kinder-/claimrisico en minstens twee leveranciersopties.

## Prijscontract

### Benodigde invoer per SKU

`source_price`, `source_currency`, `fx_rate` met bron/timestamp, `shipping_cost`, `risk_buffer`, toepasselijke btw-behandeling, `payment_fee_fixed`, `payment_fee_rate`, `target_margin`, `minimum_contribution`, vorige goedgekeurde prijs en alle bron-timestamps. Coupon-, welkomst-, app-only-, munt- en persoonlijke prijzen zijn uitgesloten tenzij AliExpress schriftelijk bevestigt dat ze structureel voor elke fulfilmentorder gelden.

Het masterplan geeft:

```text
verkoopprijs = afronden_naar_0,95(
  (inkoopprijs_EUR + geschatte_verzendkosten + risicobuffer)
  / (1 - btw - betaalfeepercentage - doelmarge)
)
```

Voor implementatie moet `btw` worden opgeslagen als **aandeel van de bruto verkoopprijs**, niet zonder meer als het wettelijke tarief. Bij een inclusief-btw-prijs en 21% tarief is dat rekenkundig `21/121`, onder voorbehoud van de door de fiscalist gekozen import-/IOSS-route. Vaste betaalkosten moeten bovendien in de teller of in een nacalculatie worden opgenomen. Definitief voorgesteld contract:

```text
cost = source_price * fx_rate + shipping_cost + risk_buffer + payment_fee_fixed
denominator = 1 - vat_share_of_gross - payment_fee_rate - target_margin_rate
raw_price = cost / denominator
candidate_price = eerstvolgende prijs >= raw_price die eindigt op ,95
contribution = candidate_price/(1 + vat_rate) - landed_cost - payment_fee(candidate_price)
```

Als `denominator <= 0`, invoer ontbreekt/verouderd is, of `contribution < minimum_contribution`, wordt de SKU `unavailable`. De berekening gebruikt decimal arithmetic en één eindafronding; geen binary floats of tussentijds afronden. De server herberekent bij cart/checkout. Een betaalde order houdt zijn onveranderlijke snapshot.

### Voorgestelde circuit breaker

- prijsdaling of -stijging tot en met 15% versus de laatste goedgekeurde **landed cost**: automatisch berekenen, mits alle poorten slagen;
- wijziging groter dan 15%: `pending_price_review`, niet automatisch publiceren;
- wijziging groter dan 30%, ontbrekende/negatieve/nulprijs, valutawissel, SKU verdwenen, voorraad onbekend, verzendkosten onbekend of response ouder dan 24 uur: onmiddellijk `unavailable` en waarschuwing;
- pas herstel na één geslaagde sync plus, voor handmatig geblokkeerde gevallen, expliciete goedkeuring.

Deze percentages zijn voorstellen; de eigenaar moet ze samen met doelmarge en minimumcontributie ondertekenen.

## Prijsformule-testscenario's

Onderstaande getallen zijn **illustratieve testfixtures, geen echte AliExpress- of Stripe-prijzen**. Voor de numerieke basisgevallen geldt: btw-tarief 21%, `vat_share_of_gross=21/121`, variabele betaalfee 3%, geen vaste fee, doelmarge 25%, minimumcontributie €4 en afronding naar de eerstvolgende `x,95`.

| # | Scenario / invoer | Verwacht resultaat |
|---:|---|---|
| 1 | bron €5, verzending €0, buffer €1,50 | raw €11,90 → **€11,95**; bijdrage circa €3,02 → `unavailable` wegens minder dan €4 |
| 2 | bron €8, verzending €2, buffer €1,50 | raw €21,05 → **€21,95**; bijdrage circa €5,98 → prijs toegestaan |
| 3 | bron €12, verzending €0, buffer €1,50 | raw €24,71 → **€24,95**; bijdrage circa €6,37 → prijs toegestaan |
| 4 | bron €15, verzending €3, buffer €2 | raw €36,60 → **€36,95**; bijdrage circa €9,43 → prijs toegestaan |
| 5 | bron €20, verzending €5, buffer €2,50 | raw €50,33 → **€50,95**; bijdrage circa €13,08 → prijs toegestaan |
| 6 | goedkope SKU met bron €3 maar verzending €4 en buffer €2 | raw €16,47 → **€16,95**; verzending wordt niet genegeerd; bijdrage circa €4,50 |
| 7 | bron stijgt van €8 naar €9 (+12,5%), overige invoer als #2 | onder 15%-grens: herberekenen naar eerstvolgende `x,95`, alleen als bijdrage en dataversheid slagen |
| 8 | bron stijgt van €8 naar €10 (+25%) | `pending_price_review`; oude prijs niet stil doorverkopen; checkout weigert stale SKU |
| 9 | bron stijgt van €8 naar €12 (+50%) | `unavailable` plus waarschuwing; handmatige goedkeuring vereist |
| 10 | ontbrekende verzendkosten, onbekende voorraad of bronrespons >24 uur | geen prijsberekening; `unavailable` |
| 11 | bron in USD met ontbrekende/verouderde EUR-wisselkoers | geen impliciete koers; `unavailable`; bij geldige koers wordt koers-ID/timestamp opgeslagen |
| 12 | `vat_share + fee_rate + target_margin >= 1` | denominator nul/negatief; validatiefout, geen publicatie |
| 13 | exact raw bedrag eindigt al op `,95` | niet nog €1 verhogen; dezelfde prijs behouden |
| 14 | coupon/welkomstprijs lager dan normale prijs | coupon uitsluiten; normale reproduceerbare SKU-prijs gebruiken of blokkeren |
| 15 | winkelmand gemaakt vóór sync; kosten stijgen vóór checkout | server herberekent, toont prijswijziging en vraagt nieuwe instemming; geen betaling met clientbedrag |
| 16 | reeds betaalde bestelling; latere bronprijswijziging | ordersnapshot blijft exact gelijk; wijziging geldt alleen voor nieuwe berekeningen |

Voeg na vaststelling van de echte vaste/variabele betalingsfee, retourreserve en belastingroute nieuwe fixtures toe. Test daarnaast decimalen met drie of meer cijfers, zeer grote waarden, valuta-omrekening, dubbele sync-events en gelijktijdige checkout/sync.

## Bewijs dat nog ontbreekt

- [ ] goedgekeurd AliExpress partneraccount en toepasselijke voorwaarden voor deze use case;
- [ ] echte, geredigeerde API-responses voor beide product-ID's én exacte SKU's;
- [ ] aantoonbare SKU-prijs, voorraad en verzendkosten/-termijn naar NL;
- [ ] minimaal vier aanvullende kandidaten door alle harde poorten;
- [ ] fysieke leverancierstest en veiligheidsdossier per kandidaat;
- [ ] door eigenaar gekozen doelmarge, buffer en minimumcontributie;
- [ ] door fiscalist bevestigde btw-/import-/IOSS-parameters;
- [ ] actuele betalingsfee en retourreserve;
- [ ] unit-tests van alle scenario's en drie-dagen-syncproef.

Tot deze vakken zijn afgetekend mogen A en B niet `approved` worden en mag automatische prijs-sync niet als gereed worden aangemerkt.
