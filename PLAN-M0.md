# Briesje — M0 haalbaarheid en compliance

## Resultaat

Na M0 ligt er een onderbouwd stop/go-besluit. Er wordt nog niets publiek verkocht. Elke externe afhankelijkheid en elk juridisch/operationeel risico heeft een eigenaar en bewijsstuk.

## Werkpakketten

1. **Bedrijf en verkoopgebied** — leg handelsnaam, KvK, btw-id, vestigingsadres, Nederlands retouradres, klantenservicekanaal en eerste verkooplanden vast.
2. **Belastingroute** — laat vaststellen wie importeur is, hoe btw/invoer wordt afgehandeld, of IOSS bruikbaar is en hoe prijzen inclusief alle verplichte kosten worden getoond.
3. **Productveiligheid** — verzamel per kandidaat fabrikant, EU-verantwoordelijke marktdeelnemer, waarschuwingen, traceerbaarheid, batterij/USB-specificaties en CE/GPSR-bewijs waar relevant. Controleer Safety Gate/recalls.
4. **Leverancierstest** — bestel elk startproduct zelf, documenteer verpakking, kwaliteit, geluid, batterij, werkelijke levertijd, tracking en retourervaring.
5. **AliExpress-integratie** — registreer toegestane API/affiliate-toegang; bewijs welke endpoints prijs, SKU, voorraad, verzending en productdetails leveren en welke gebruiksvoorwaarden gelden.
6. **Prijsmodel** — bepaal doelmarge, risicobuffer, betalingsfee, retourpercentage, btw en maximale automatische prijsafwijking. Simuleer winst/verlies bij minimaal tien scenario's.
7. **Betaling** — activeer Stripe in testmodus, bepaal beschikbare betaalmethoden, refundproces en webhookvereisten. Houd Stripe-secret buiten de repository.
8. **Privacy en voorwaarden** — laat privacyverklaring, algemene voorwaarden, retour/herroeping, garantie, levertijd en cookiekeuze opstellen/controleren. Neem de verplichte online herroepingsfunctie mee.
9. **Technische spike** — bewijs met een minimale, niet-publieke proef dat GitHub-hosted frontend → Supabase Edge Function → Stripe testcheckout en webhook veilig werken.
10. **Besluit** — noteer open risico's, maandelijkse/variabele kosten en expliciete go/no-go per product en voor de winkel.

## Acceptatiecriteria

- De twee opgegeven AliExpress-items zijn geïdentificeerd op variantniveau; actuele prijs en beschikbaarheid komen reproduceerbaar uit een toegestane bron.
- Minimaal vier aanvullende kandidaten zijn onderzocht, maar alleen kandidaten met complete compliance- en margegegevens krijgen status `approved`.
- Er is een geteste Nederlandse retourroute en een realistische, gemeten levertijdbelofte.
- Het prijsmodel voorkomt verkoop onder de ingestelde minimumcontributie en zet twijfelgevallen automatisch offline.
- Stripe testcheckout en een ondertekende, idempotente webhook zijn gedemonstreerd zonder secrets in client of git.
- Rolverdeling voor fulfilment, tracking, klachten, herroeping, retour en refund is concreet.
- Een professional heeft belasting- en consumententeksten beoordeeld, of het go-besluit blijft geblokkeerd.

## Validatiebewijs dat tijdens uitvoering wordt ingevuld

- [ ] API-toegang en echte endpointresponses — ontwerp en proefprotocol gereed; accountbewijs ontbreekt
- [ ] Product- en veiligheidsdossier per SKU — eisen gereed; leveranciersbewijs ontbreekt
- [ ] Leverancierstest met datums en foto's — protocol gereed; fysieke samples ontbreken
- [x] Prijssimulatie en grensgevallen ontworpen — uitvoering wacht op echte kosteninputs
- [ ] Stripe testbetaling + dubbele webhook + refund — technisch contract gereed; gekoppelde testaccounts ontbreken
- [x] Privacy/security threat model op ontwerpniveau
- [ ] Professionele juridische/fiscale/productreview
- [x] Voorlopig stop/go-besluit: **NO-GO voor publieke verkoop**

## Opgeleverd M0-dossier

- `evidence/M0-COMPLIANCE.md`
- `evidence/M0-PRODUCTS-PRICING.md`
- `evidence/M0-TECHNICAL.md`
- `evidence/REVIEW-COMPLIANCE.md`
- `evidence/REVIEW-PRODUCTS.md`
- `evidence/REVIEW-TECHNICAL.md`
- `evidence/M0-ACCEPTANCE-CONTRACT.md`
- `evidence/M0-DECISION.md`

## Menselijke beslissingen

- In welke landen verkoopt Briesje bij lancering?
- Wat zijn doelmarge en minimale nettobijdrage per order?
- Wie is het Nederlandse retouradres en wie behandelt support?
- Wordt fulfilment eerst bewust handmatig gehouden?
- Welke bedrijfsgegevens en merkmiddelen mogen publiek worden gebruikt?

## Uitvoeringsinstructie

Volg de implementatie-orchestratie in `PLAN.md`. Werk dit bestand bij met links naar bewijs (zonder secrets of persoonsgegevens). Een ontbrekend compliance-, belasting- of productveiligheidsbewijs is een blokkade, geen aanname.
