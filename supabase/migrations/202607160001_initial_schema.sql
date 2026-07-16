create extension if not exists pgcrypto;

create type public.approval_status as enum ('pending', 'approved', 'blocked', 'expired');
create type public.stock_state as enum ('unknown', 'in_stock', 'out_of_stock');
create type public.order_status as enum ('draft', 'checkout_pending', 'paid', 'checkout_expired', 'cancelled', 'refund_pending', 'partially_refunded', 'refunded');

create table public.products (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  title text not null check (char_length(title) between 1 and 120),
  short_description text not null default '' check (char_length(short_description) <= 500),
  image_url text,
  is_demo boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  sku text not null unique,
  label text not null,
  currency text not null default 'EUR' check (currency = 'EUR'),
  sale_price_minor integer check (sale_price_minor is null or sale_price_minor >= 0),
  price_version bigint not null default 1 check (price_version > 0),
  stock_state public.stock_state not null default 'unknown',
  product_compliance_status public.approval_status not null default 'pending',
  supplier_test_status public.approval_status not null default 'pending',
  source_data_status public.approval_status not null default 'pending',
  logistics_status public.approval_status not null default 'pending',
  price_status public.approval_status not null default 'pending',
  reason_code text not null default 'demo_not_approved',
  approved_at timestamptz,
  evidence_valid_until timestamptz,
  source_observed_at timestamptz,
  source_ttl_seconds integer check (source_ttl_seconds is null or source_ttl_seconds > 0),
  source_product_id text,
  source_sku_id text,
  created_at timestamptz not null default now(),
  constraint approved_has_evidence check (
    not (product_compliance_status = 'approved' or supplier_test_status = 'approved')
    or (approved_at is not null and evidence_valid_until is not null)
  )
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  status public.order_status not null default 'draft',
  currency text not null default 'EUR' check (currency = 'EUR'),
  subtotal_minor integer not null check (subtotal_minor >= 0),
  total_minor integer not null check (total_minor >= 0 and total_minor = subtotal_minor),
  amount_authorized integer not null default 0 check (amount_authorized >= 0),
  amount_captured integer not null default 0 check (amount_captured >= 0),
  amount_refunded integer not null default 0 check (amount_refunded >= 0),
  amount_disputed integer not null default 0 check (amount_disputed >= 0),
  checkout_attempt uuid not null,
  stripe_checkout_session_id text unique,
  stripe_payment_intent_id text unique,
  shipping_country text not null default 'NL' check (shipping_country = 'NL'),
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  unique (user_id, checkout_attempt)
);

create table public.order_lines (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  quantity integer not null check (quantity between 1 and 10),
  currency text not null check (currency = 'EUR'),
  unit_price_minor integer not null check (unit_price_minor >= 0),
  price_version bigint not null,
  title_snapshot text not null,
  sku_snapshot text not null,
  unique (order_id, variant_id)
);

create table public.stripe_events (
  event_id text primary key,
  event_type text not null,
  object_id text,
  livemode boolean not null,
  payload_created_at timestamptz,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  outcome text not null default 'received' check (outcome in ('received','processed','ignored','quarantined','failed')),
  error_code text
);

create view public.catalog as
select p.id, p.slug, p.title, p.short_description, p.image_url, p.is_demo,
       v.id as variant_id, v.label, v.currency, v.sale_price_minor,
       (not p.is_demo
        and v.stock_state = 'in_stock'
        and v.sale_price_minor is not null
        and v.product_compliance_status = 'approved'
        and v.supplier_test_status = 'approved'
        and v.source_data_status = 'approved'
        and v.logistics_status = 'approved'
        and v.price_status = 'approved'
        and v.approved_at is not null
        and v.evidence_valid_until > now()
        and v.source_observed_at + make_interval(secs => v.source_ttl_seconds) > now()) as sellable
from public.products p join public.product_variants v on v.product_id = p.id;

alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.orders enable row level security;
alter table public.order_lines enable row level security;
alter table public.stripe_events enable row level security;

grant select on public.catalog to anon, authenticated;

create view public.public_catalog as
select variant_id as id,
       title,
       label as subtitle,
       short_description as description,
       'all'::text as category,
       sale_price_minor,
       currency,
       'approved'::text as status
from public.catalog
where sellable = true;

grant select on public.public_catalog to anon, authenticated;
grant select on public.orders, public.order_lines to authenticated;
revoke all on public.products, public.product_variants, public.stripe_events from anon, authenticated;

create policy orders_read_own on public.orders for select to authenticated using (user_id = auth.uid());
create policy order_lines_read_own on public.order_lines for select to authenticated
using (exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid()));

comment on view public.catalog is 'Public projection only; source costs, margins and evidence remain private.';
comment on view public.public_catalog is 'Approved-only storefront contract. Empty until every sellability gate is approved and fresh.';
comment on table public.stripe_events is 'Minimal Stripe deduplication metadata; never store webhook payloads.';
