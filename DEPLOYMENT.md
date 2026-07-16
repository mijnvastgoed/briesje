# Briesje deployment

## Doelomgevingen

- GitHub: `https://github.com/mijnvastgoed/briesje`
- GitHub Pages: verwacht `https://mijnvastgoed.github.io/briesje/`
- Supabase-organisatie: `Laurens VDV`
- Supabase-project: `Briesje` (`mjfsntdwhdhrhmxayymp`), gescheiden van `MijnVastgoed`

## Status

De repository is gevuld en het aparte Supabase-project is aangemaakt. Migraties, fail-closed seed en beide Edge Functions zijn gedeployed. De publieke catalogus retourneert veilig een lege lijst en private variantdata is niet via de publishable key leesbaar. GitHub Pages blijft bewust uit totdat de publieke-demo-gates zijn gesloten.

## Configuratie na projectaanmaak

1. Voer de migraties in `supabase/migrations` in volgorde uit.
2. Voer uitsluitend voor de demo `supabase/seed.sql` uit; alle producten blijven niet-verkoopbaar.
3. Deploy `create-checkout-session` en `stripe-webhook`.
4. Configureer frontendwaarden via `web/config.example.js` → `web/config.js` met alleen de publieke project-URL en anon/publishable key.
5. Houd `CHECKOUT_ENABLED=false` totdat alle M0-gates aantoonbaar groen zijn.
6. Voeg Stripe- en AliExpress-secrets pas server-side toe; nooit aan GitHub of browsercode.
7. Activeer GitHub Pages vanaf de hoofdbranch en controleer de Pages-URL.

Zie ook `supabase/README.md` voor de technische commando's en veiligheidsvoorwaarden.
