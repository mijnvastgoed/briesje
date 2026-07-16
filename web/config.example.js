// Kopieer naar config.js. Gebruik uitsluitend publieke browserconfiguratie.
// De anon/publishable key is openbaar; beveilig alle tabellen met RLS.
window.BRIESJE_CONFIG = {
  supabaseUrl: "https://PROJECT_REF.supabase.co",
  supabaseAnonKey: "PUBLIC_ANON_OR_PUBLISHABLE_KEY",
  catalogView: "public_catalog",
  checkoutFunction: "create-checkout-session"
};
