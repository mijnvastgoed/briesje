# M0 beslisdossier

## Status

**Voorlopig: NO-GO voor publieke verkoop en echte betalingen.**

Dit is geen afwijzing van het concept. De bouw kan in testmodus doorgaan, maar live verkoop blijft geblokkeerd totdat alle harde launchgates hieronder aantoonbaar zijn gesloten.

## Harde launchgates

| Gate | Status | Vereist bewijs | Eigenaar |
|---|---|---|---|
| Onderneming en openbare bedrijfsgegevens | Geblokkeerd | Handelsnaam, KvK, btw-id, vestigingsadres, contactgegevens | Mens |
| Nederlands retouradres en supportproces | Geblokkeerd | Geteste retourroute, responstijden, verantwoordelijke | Mens |
| Fiscale/importkeuze | Geblokkeerd | Schriftelijk akkoord op btw, IOSS/importeur en verkooplanden | Mens + adviseur |
| Productveiligheid per SKU | Geblokkeerd | Fabrikant, EU-verantwoordelijke, traceerbaarheid, waarschuwingen en toepasselijke conformiteitsdocumenten | Mens + leverancier |
| Leverancierstest | Geblokkeerd | Ontvangen samples, metingen, levertijd, verpakking, tracking en retourtest | Mens |
| Toegestane AliExpress-data | Geblokkeerd | Werkende API/feed-toegang en bevestigde velden/voorwaarden | Mens + techniek |
| Rendabel prijsmodel | Geblokkeerd | Ingevulde kosten, tien scenario's en goedgekeurde minimumcontributie | Mens |
| Stripe testketen | Geblokkeerd | Testaccount, checkout, ondertekende webhook, duplicaat en refund | Mens + techniek |
| Juridische teksten | Geblokkeerd | Beoordeelde voorwaarden, privacy, levering, retour en herroeping | Juridisch adviseur |
| Privacy, dataflow en retentie | Geblokkeerd | Veldniveau ROPA, doorgiften, verwerkersvoorwaarden en deletietests | Privacyprofessional + techniek |
| Auth, browser en adminsecurity | Geblokkeerd | Authmisbruik-, header-, MFA-, RLS- en secret/buildscantests | Securityreviewer |
| Gastcheckout en contractbewijs | Geblokkeerd | Veilige gasttokenflow, archiefcopy, duurzame bevestiging en UX-review | Jurist + techniek |
| Herroeping, retour en garantie | Geblokkeerd | E2E-verzoeken, deadlines, retourbeslisboom en refundbewijs | Operations + jurist |
| Logistiek en freshness | Geblokkeerd | Variant/postcodequote, p50/p90, DDP/IOSS-route en bron/TTL-snapshot | Operations + fiscalist |
| Leveranciercontract en herkwalificatie | Geblokkeerd | Geverifieerde entiteit, clausules, baseline en periodieke samplematch | Inkoop + complianceprofessional |
| Refund/dispute-reconciliatie | Geblokkeerd | Gedeeltelijke/dubbele refund, dispute en Stripe-reconciliatie | Finance + techniek |
| Onafhankelijke P0/P1-eindreview | Geblokkeerd | Traceabilitymatrix en review zonder open hoge bezwaren | Onafhankelijke reviewers |

## Beslisregel

De status wordt pas **GO** als iedere gate groen is, bewijs geen secrets of persoonsgegevens bevat, en een onafhankelijke eindreview geen open kritiek met hoge impact heeft. Een agent mag een menselijke of externe gate niet op basis van aannames sluiten.

Iedere gate wordt operationeel vastgelegd met `owner`, `status=blocked|approved|expired`, `evidence_link`, `verified_by`, `verified_at`, `valid_until`, `source_version` en hercontrolefrequentie.

## Toegestaan tijdens NO-GO

- Ontwerp en technische ontwikkeling met fictieve of duidelijk gemarkeerde testdata.
- Stripe uitsluitend in testmodus.
- Leverancierssamples bestellen en documenteren.
- API-toegang aanvragen en compliance-documenten verzamelen.
- Geautomatiseerde tests, securitytests en een niet-geïndexeerde preview uitvoeren.

## Niet toegestaan tijdens NO-GO

- Publieke productclaims of onbevestigde levertijden publiceren.
- Echte betalingen aannemen.
- Producten automatisch bestellen bij een leverancier.
- Onbevestigde AliExpress-data als actueel presenteren.
- Een product publiceren zonder complete veiligheids- en traceerbaarheidsgegevens.
