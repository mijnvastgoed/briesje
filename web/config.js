// Alleen publieke browserconfiguratie. Alle privileged secrets blijven server-side.
window.BRIESJE_CONFIG = Object.freeze({
  supabaseUrl: "https://mjfsntdwhdhrhmxayymp.supabase.co",
  supabaseAnonKey: "sb_publishable_HWLlOAYbnXOFhg9z_53mJQ_5gpjSZcl",
  catalogView: "public_catalog",
  checkoutFunction: "create-checkout-session"
});
