# Briesje storefront

Statische GitHub Pages-storefront met een veilige demomodus en een optionele Supabase-koppeling. Alle fallback-productnamen, prijzen en eigenschappen zijn expliciet demonstratiedata. De twee AliExpress-referenties blijven fail-closed.

Lokaal testen:

```sh
python3 -m http.server 8080 --directory web
```

Open `http://localhost:8080`. Publiceer de map `web` als Pages-bron of kopieer hem via een GitHub Actions-workflow naar het Pages-artifact. Er staan geen secrets, API-keys of echte klantgegevens in deze map.

## Supabase configureren

Kopieer `config.example.js` naar `config.js` en vul alleen de publieke project-URL en anon/publishable key in. Een service-role key, Stripe-secret of AliExpress-secret mag nooit in deze map staan. De Supabase-client wordt pas via CDN geladen als de configuratie de basisvalidatie doorstaat.

De standaard veilige view heet `public_catalog` en moet uitsluitend de kolommen `id`, `title`, `subtitle`, `description`, `category`, `sale_price_minor`, `currency` en `status` tonen. Alleen regels met `status = approved`, een positieve integerprijs en `currency = EUR` worden geladen. RLS blijft verplicht. Bij een fout, lege catalogus of ongeldige prijs valt de site terug naar expliciete demodata.

Account-login gebruikt een Supabase magic link. Voeg de exacte GitHub Pages-URL toe aan de toegestane redirect-URL's. Checkout roept `create-checkout-session` aan met uitsluitend variant-ID's, aantallen en een UUID-poging. Alleen een `https://checkout.stripe.com/` response wordt gevolgd. De Edge Function moet login, prijs, status en voorraad opnieuw valideren; anders blijft checkout gesloten.
