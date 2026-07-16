begin;
select plan(21);

select has_table('public', 'products', 'products exists');
select has_table('public', 'product_variants', 'variants exist');
select has_table('public', 'orders', 'orders exist');
select has_table('public', 'stripe_events', 'event dedupe exists');
select has_view('public', 'public_catalog', 'approved-only storefront view exists');
select has_table('public', 'profiles', 'account profiles exist');
select has_table('public', 'supplier_variant_mappings', 'private supplier mappings exist');
select has_table('public', 'supplier_observations', 'private supplier staging exists');
select has_table('public', 'status_audit', 'supplier status audit exists');
select has_table('public', 'fulfillment_jobs', 'durable fulfillment jobs exist');
select has_table('public', 'fulfillment_lines', 'immutable provider line snapshots exist');
select has_table('public', 'order_shipping_addresses', 'private shipping snapshots exist');
select has_table('public', 'fulfillment_tracking', 'tracking storage exists');
select ok(row_security_active('public.orders'), 'orders has RLS');
select ok(row_security_active('public.order_lines'), 'order lines have RLS');
select ok(row_security_active('public.profiles'), 'profiles have RLS');
select ok(row_security_active('public.supplier_observations'), 'supplier observations have RLS');
select ok(row_security_active('public.status_audit'), 'status audit has RLS');
select is((select count(*)::bigint from public.catalog where sellable), 0::bigint, 'seed catalog is fail-closed');
select throws_ok($$insert into public.order_lines(order_id,variant_id,quantity,currency,unit_price_minor,price_version,title_snapshot,sku_snapshot) values(gen_random_uuid(),gen_random_uuid(),0,'EUR',1,1,'x','x')$$, null, null, 'zero quantity rejected');
select throws_ok($$insert into public.orders(user_id,subtotal_minor,total_minor,checkout_attempt) values(gen_random_uuid(),100,99,gen_random_uuid())$$, null, null, 'mismatched total rejected');

select * from finish();
rollback;
