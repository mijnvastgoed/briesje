# Tweede opinie M0-TECHNICAL — compliance, privacy en consumentenrecht

**Reviewdatum:** 16 juli 2026  
**Beoordeeld:** `briesje/evidence/M0-TECHNICAL.md`  
**Oordeel:** technisch ontwerp is in de kern zorgvuldig, maar **niet akkoord als launchcontract**. Het document noemt juridische/fiscale blokkades terecht als extern aan de spike, maar het voorgestelde datamodel en de hosted demonstratie missen controles die later moeilijk of riskant zijn om achteraf toe te voegen. Onderstaande bezwaren zijn concrete correcties; P0 blokkeert publieke verkoop.

## Bevindingen

### P0 — Hosted spike mag geen publiek verkoopaanbod worden

De voorgestelde tijdelijke GitHub Pages-URL is publiek. Zonder productdossiers kan een ingevulde productpagina met prijs en bestelknop al als online aanbod onder GPSR art. 19 of als uitnodiging tot aankoop worden gezien, ook als Stripe in testmodus staat. Bovendien kan een bezoeker echte persoonsgegevens in de testcheckout invoeren.

**Vereiste correctie:** definieer de hosted spike uitsluitend met fictieve productnamen/afbeeldingen en synthetische persoonsgegevens, toon prominent “test — geen verkoop”, voorkom indexering en zorg dat alleen aangewezen testers de flow kunnen starten (bijvoorbeeld server-side tester-allowlist; alleen `robots.txt` is onvoldoende toegangscontrole). Geen AliExpress-SKU, consumentenprijs, voorraadclaim of echt fulfilment. Verwijder testdata en roteer secrets na aftekening. Een echte productpagina blijft geblokkeerd tot de SKU-gate uit `M0-COMPLIANCE.md` slaagt.

### P0 — Totaalprijs, verzendland en fiscale route ontbreken in het servercontract

Het schema bevat alleen `subtotal_minor` en `total_minor`; de checkoutbeschrijving zegt niet hoe btw, verzending, invoer/inklaring en korting afzonderlijk en reproduceerbaar worden berekend. Stripe kan adressen verzamelen nadat de lokale snapshot is gemaakt. Daarmee kan een gemanipuleerd of niet-goedgekeurd afleverland tot een fiscaal/compliance-onjuiste order leiden en is niet bewezen dat vóór betaling de volledige consumentenprijs zichtbaar is.

**Vereiste correctie:** beperk M0/MVP server-side tot `shipping_country=NL`; valideer dit zowel vóór sessieaanmaak als op de voltooide Checkout Session en laat mismatch nooit automatisch fulfilment starten. Sla minimaal `net_minor`, `vat_rate`, `vat_minor`, `shipping_minor`, `discount_minor`, `gross_total_minor`, valuta, prijs-/belastingregelversie en goedgekeurde fulfilment-/import-route als onveranderlijke snapshot op. Laat Stripe exact hetzelfde bruto totaal tonen. Een fiscalist moet dit schema en refundcorrecties aftekenen vóór productie.

### P0 — Contractbewijs en verplichte precontractuele informatie zijn niet gemodelleerd

Een betalingssnapshot bewijst niet welke productkenmerken, levertijd, handelaargegevens, retourkosten, voorwaarden en herroepingsinformatie de consument vóór bestellen zag. Er is evenmin een duurzame contractbevestiging voorzien. Dit is essentieel bij geschillen en voor de wettelijke informatieplichten.

**Vereiste correctie:** versieer de juridische/productinhoud en leg per order minimaal vast: `terms_version`, `privacy_notice_version`, `withdrawal_notice_version`, producttitel/-kenmerken/-waarschuwingen, fabrikant/EU-verantwoordelijke persoon, beloofde levertermijn, retourkostenregel, verkoopland en timestamp. Bewaar een onveranderlijke render/hash of archival copy van de daadwerkelijk getoonde teksten. Verstuur na sluiten van de overeenkomst een bevestiging op een duurzame gegevensdrager met alle vereiste informatie en modelformulier; bewijs verzending zonder volledige e-mailinhoud onbeperkt te loggen. Laat tekst en UX door Nederlandse jurist beoordelen.

### P0 — Herroeping, annulering, retour en wettelijke garantie ontbreken uit de architectuur

De technische statusmachine behandelt betaling/refund maar niet de sinds 19 juni 2026 verplichte online ontbindings-/herroepingsfunctie, de 14-dagentermijn, retourontvangst of klachten/wettelijke conformiteit. `cancelled` is niet hetzelfde als rechtsgeldige herroeping en een Stripe-refund is niet het juridische dossier.

**Vereiste correctie:** voeg een afzonderlijk, auditbaar domeinmodel toe voor `withdrawal_requests`, retouren en garantieclaims. De opvallende herroepingsfunctie moet vanaf elke relevante pagina bereikbaar zijn, ook voor een gastkoper via een veilige ordergebonden route, en mag niet afhankelijk zijn van telefoneren of een account. Leg verzoek, onmiddellijke ontvangstbevestiging, wettelijke deadlines, terugbetalingsgrondslag (inclusief standaard heenzendkosten waar vereist) en uitkomst vast. Voorkom account-overname/IDOR zonder onnodig identiteitsbewijs te eisen. E2E-test tijdige, late, gedeeltelijke en dubbele verzoeken plus refundfout.

### P0 — Verplicht account is niet gerechtvaardigd en gastrechten zijn niet ontworpen

`create-checkout-session` vereist altijd een Supabase gebruikers-JWT. Het bedrijfsdoel vraagt dat een account kan worden aangemaakt, niet dat koop zonder account onmogelijk moet zijn. Een verplichte accountregistratie creëert extra persoonsgegevens en bewaarrisico zonder aangetoonde noodzaak. Bovendien ontbreken flows voor vergeten toegang, accountverwijdering met fiscale bewaarplicht en toegang tot herroeping na accountblokkade.

**Vereiste correctie:** voer vóór implementatie een gedocumenteerde noodzakelijkheidstoets uit en kies standaard gastcheckout tenzij een aantoonbare noodzaak een account vereist. Koppel gastorders server-side via hoog-entropische, beperkte en roteerbare ordertoegang; stop tokens nooit in analytics/referrers/logs. Ontwerp account-export, rectificatie en verwijdering waarbij wettelijk te bewaren order/fiscale gegevens beperkt en afgeschermd blijven in plaats van onjuist te worden gewist.

### P0 — Privacyrollen en internationale doorgiften zijn nog geen technische gate

De spike zegt terecht “geen persoonsgegevens in metadata”, maar specificeert niet welke persoonsgegevens naar Stripe, Supabase, GitHub, de AliExpress-leverancier en vervoerder gaan, wie verwerker/zelfstandig verantwoordelijke is, waar data wordt verwerkt, welke grondslag en bewaartermijn geldt, of welke doorgiftewaarborg nodig is. Het afleveradres doorgeven aan een Chinese leverancier is een materieel ander doel/risico dan betaling. De voorgestelde `stripe_events`-metadata kan nog identifiers en persoonsgegevens bevatten.

**Vereiste correctie:** maak vóór echte testdata een dataflow/ROPA-light met veldniveau, doel, grondslag, ontvanger/rol, regio/doorgifte, bewaartermijn en verwijderpad. Sluit/controleer verwerkersvoorwaarden en doorgiftemechanismen. Stuur naar leverancier/vervoerder alleen noodzakelijke fulfilmentvelden en pas nadat de klant hierover transparant is geïnformeerd. Definieer een allowlist voor webhookvelden die lokaal worden opgeslagen; geen volledige payload, klant-e-mail, adres, betaalmethodegegevens of metadata-dump. Test logredactie en automatische retentie/verwijdering.

### P1 — Auth-, sessie- en browserprivacy zijn onvoldoende gespecificeerd

RLS en JWT-validatie zijn nodig maar dekken geen accountbeveiliging. Er ontbreken eisen voor veilige redirect-URL's, e-mailenumeratie, brute-forcebescherming, sessie-uitloggen, herstel-links, MFA voor beheerders en intrekken van beheertoegang. Ook ontbreken CSP, clickjacking- en referrerbeperking; dit is relevant omdat checkout-/orderidentifiers in URLs kunnen staan.

**Vereiste correctie:** voeg een auth threat model en tests toe. Sta uitsluitend vaste auth-/checkout-redirects toe; gebruik geen ordertoegang in querystrings waar deze kan lekken; stel minimaal een strikte CSP, `Referrer-Policy`, frame-/embeddingbeperking en veilige resource-allowlist in voor zover GitHub Pages dit technisch toelaat (anders via meta-CSP en architectuur, met beperkingen gedocumenteerd). MFA/step-up voor admin/refund/productpublicatie, least privilege en auditlog zijn launchgates.

### P1 — Toestemming/cookies en third-party scripts zijn niet begrensd

De spike zegt niets over analytics, pixels, embeds of Stripe-resources vóór interactie. Niet-noodzakelijke tracking mag niet stil als “technisch noodzakelijk” worden geladen; toestemming moet aantoonbaar en intrekbaar zijn. GitHub Pages kan bovendien platformtechnische verwerking meebrengen die in de privacyinformatie moet worden opgenomen.

**Vereiste correctie:** launch standaard zonder analytics/advertising. Maak een inventaris van cookies/local storage/third-party requests. Laad niet-noodzakelijke middelen pas na geldige keuze en sla bewijs minimaal op. Functionele cart-/authopslag moet worden gedocumenteerd, beperkt en beveiligd. Voeg browsertest toe die vóór toestemming geen niet-noodzakelijke requests/cookies aantreft.

### P1 — Betaal- en refundstatus dekt consumentenbedrag niet volledig

De statusmachine noemt partial refunds, maar niet hoe standaard heenzendkosten, meerdere orderregels, retourkosten, chargebacks en mislukte/asynchrone iDEAL-statussen worden gereconcilieerd. Alleen een `refund_request_id` zegt niet welk wettelijk verschuldigd bedrag is berekend.

**Vereiste correctie:** introduceer immutable refund-berekeningsregels en regelsnapshots, gescheiden `refund_requests` en `refund_transactions`, bedragen per component, reden/grondslag, vier-ogencontrole boven grensbedrag en reconciliatie met Stripe. Fulfilment mag pas starten bij server-bevestigde betaalstatus én geslaagde compliance-/adrescontrole. Test volledige herroeping inclusief standaard heenzendkosten, gedeeltelijke retour, dubbele refund, chargeback en webhookvolgorde.

### P1 — Dataminimalisatie en bewaartermijnen moeten constraints worden

“Bewaar bij voorkeur minimale metadata” is te vrijblijvend. Voor privacy en security moet duidelijk zijn welke data noodzakelijk is en wanneer die wordt verwijderd, terwijl fiscale/contractgegevens mogelijk langer moeten blijven. Hashen van een klantreferentie maakt gegevens niet per definitie anoniem.

**Vereiste correctie:** maak veldspecifieke retentie een acceptatiecriterium en implementeer scheduled deletion/anonymisation met legal holds. Splits operationele event-dedupe, contract-/fiscale records en tijdelijke logs. Bewaar Stripe-event-id voor idempotentie maar geen payload; pseudonimiseer waar mogelijk en behandel hashes als persoonsgegevens zolang herleiding mogelijk is. Test retentiejobs en bewijs dat verwijderde accounts geen toegang meer geven terwijl wettelijk vereiste records afgeschermd blijven.

### P1 — Voorraad- en levertijdclaims vereisen freshness en fail-closed gedrag

`stock_state` en `approved_at` bestaan, maar een toegestane bron, maximale ouderdom en levertermijnsnapshot ontbreken. Bij dropshipping kunnen “op voorraad” en levertijd snel misleidend worden.

**Vereiste correctie:** vereist `source_checked_at`, toegestane bron, variantmatch, maximale TTL, shipping-route en gemeten levertermijn. Een stale/onbekende status maakt checkout onmogelijk. Toon geen schaarsteclaim zonder verifieerbaar bewijs. Snapshot de beloofde levertermijn en test syncstoring/stale data.

## Vereiste launchgates

De technische status mag pas van spike naar productie wanneer naast de bestaande Stripe/RLS/securitytests ook het volgende bewijs bestaat:

- [ ] Publieke test gebruikte uitsluitend fictieve producten en synthetische persoonsgegevens; testdata verwijderd.
- [ ] Nederland-only en volledig bruto bedrag inclusief btw/verzending server-side afgedwongen en fiscaal afgetekend.
- [ ] Versies/snapshots van product-, veiligheids-, leverings- en juridische informatie per order aantoonbaar.
- [ ] Duurzame contractbevestiging en modelformulier correct ontvangen in E2E-test.
- [ ] Herroepingsfunctie, retour, wettelijke garantie en bijbehorende refunds end-to-end getest.
- [ ] Gastcheckout of gedocumenteerde noodzakelijkheid van account; veilige gasttoegang en datasubjectflows getest.
- [ ] Dataflow, privacyrollen, doorgiften, verwerkersvoorwaarden en retentie goedgekeurd; geen echte data vóór die gate.
- [ ] Geen niet-noodzakelijke cookies/requests vóór toestemming; privacy- en securityheaders gecontroleerd.
- [ ] Admin/refund/productpublicatie heeft MFA/step-up, least privilege en auditbewijs.
- [ ] SKU-compliancegate en voorraad-/levertijdfreshness blokkeren checkout fail-closed.
- [ ] Jurist, fiscalist en product-complianceprofessional hebben hun eigen blokkerende oordeel schriftelijk opgeheven.

## Eindoordeel

`M0-TECHNICAL.md` kan dienen als **technisch spikecontract na verwerking van de P0-correcties**, maar niet als productie-architectuur of bewijs dat verkoop gereed is. De huidige formulering “voorwaardelijke technische go” mag uitsluitend betekenen: toestemming om met fictieve data de betaalintegratie te testen. Zij geeft geen toestemming om echte producten aan te bieden, echte klantdata te verwerken of orders te fulfilen.
