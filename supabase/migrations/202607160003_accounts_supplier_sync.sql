create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (display_name is null or char_length(display_name) between 1 and 80),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
begin insert into public.profiles(id) values(new.id) on conflict do nothing; return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
revoke all on function public.handle_new_user() from public,anon,authenticated;

create table public.supplier_variant_mappings (
  variant_id uuid primary key references public.product_variants(id) on delete restrict,
  provider text not null check (provider in ('aliexpress_official_api')),
  source_product_id text not null,
  source_sku_id text not null,
  destination_country text not null default 'NL' check (destination_country='NL'),
  enabled boolean not null default false,
  created_at timestamptz not null default now(),
  unique(provider,source_product_id,source_sku_id,destination_country)
);

create table public.supplier_sync_runs (
  id uuid primary key default gen_random_uuid(), provider text not null,
  started_at timestamptz not null default now(), finished_at timestamptz,
  outcome text not null default 'running' check(outcome in ('running','succeeded','partial','failed')),
  observation_count integer not null default 0, error_code text
);

create table public.supplier_observations (
  id uuid primary key default gen_random_uuid(), run_id uuid not null references public.supplier_sync_runs(id),
  variant_id uuid not null references public.product_variants(id), source_product_id text not null, source_sku_id text not null,
  currency text not null, source_price_minor integer not null check(source_price_minor>=0),
  shipping_minor integer not null check(shipping_minor>=0), stock_available boolean not null,
  observed_at timestamptz not null, received_at timestamptz not null default now(),
  response_hash text not null check(char_length(response_hash)=64),
  unique(run_id,variant_id)
);

create table public.status_audit (
  id bigint generated always as identity primary key, variant_id uuid not null references public.product_variants(id),
  dimension text not null check(dimension in ('source_data_status','price_status')),
  old_status public.approval_status not null,new_status public.approval_status not null,
  reason_code text not null,actor text not null,created_at timestamptz not null default now(),run_id uuid references public.supplier_sync_runs(id)
);

alter table public.profiles enable row level security;
alter table public.supplier_variant_mappings enable row level security;
alter table public.supplier_sync_runs enable row level security;
alter table public.supplier_observations enable row level security;
alter table public.status_audit enable row level security;
grant select,update on public.profiles to authenticated;
revoke all on public.supplier_variant_mappings,public.supplier_sync_runs,public.supplier_observations,public.status_audit from anon,authenticated;
create policy profiles_read_own on public.profiles for select to authenticated using(id=auth.uid());
create policy profiles_update_own on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());

create or replace function public.ingest_supplier_observation(
 p_run_id uuid,p_variant_id uuid,p_source_product_id text,p_source_sku_id text,p_currency text,
 p_source_price_minor integer,p_shipping_minor integer,p_stock_available boolean,p_observed_at timestamptz,p_response_hash text
) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare v public.product_variants%rowtype; m public.supplier_variant_mappings%rowtype; old_source public.approval_status; old_price public.approval_status;
begin
 select * into m from supplier_variant_mappings where variant_id=p_variant_id and enabled for update;
 if not found or m.source_product_id<>p_source_product_id or m.source_sku_id<>p_source_sku_id then raise exception 'mapping_mismatch'; end if;
 if p_currency<>'EUR' or p_observed_at > now()+interval '5 minutes' or p_observed_at < now()-interval '24 hours' then raise exception 'invalid_observation'; end if;
 select * into v from product_variants where id=p_variant_id for update; old_source:=v.source_data_status; old_price:=v.price_status;
 insert into supplier_observations(run_id,variant_id,source_product_id,source_sku_id,currency,source_price_minor,shipping_minor,stock_available,observed_at,response_hash)
 values(p_run_id,p_variant_id,p_source_product_id,p_source_sku_id,p_currency,p_source_price_minor,p_shipping_minor,p_stock_available,p_observed_at,p_response_hash);
 -- Sync may only tighten gates. A human-reviewed pricing ledger must approve any new price.
 update product_variants set source_observed_at=p_observed_at,source_ttl_seconds=3600,stock_state=case when p_stock_available then 'in_stock'::stock_state else 'out_of_stock'::stock_state end,
   source_data_status=case when p_stock_available then 'pending'::approval_status else 'blocked'::approval_status end,
   price_status='pending',reason_code=case when p_stock_available then 'supplier_observation_requires_review' else 'supplier_out_of_stock' end
 where id=p_variant_id;
 insert into status_audit(variant_id,dimension,old_status,new_status,reason_code,actor,run_id) values
 (p_variant_id,'source_data_status',old_source,case when p_stock_available then 'pending'::approval_status else 'blocked'::approval_status end,case when p_stock_available then 'supplier_observation_requires_review' else 'supplier_out_of_stock' end,'supplier_sync',p_run_id),
 (p_variant_id,'price_status',old_price,'pending'::approval_status,'new_supplier_price_requires_ledger','supplier_sync',p_run_id);
end $$;
revoke all on function public.ingest_supplier_observation(uuid,uuid,text,text,text,integer,integer,boolean,timestamptz,text) from public,anon,authenticated;
grant execute on function public.ingest_supplier_observation(uuid,uuid,text,text,text,integer,integer,boolean,timestamptz,text) to service_role;

-- Prevent clients from changing immutable profile ownership/timestamps.
create or replace function public.profiles_before_update() returns trigger language plpgsql as $$
begin new.id=old.id; new.created_at=old.created_at; new.updated_at=now(); return new; end $$;
create trigger profiles_update_guard before update on public.profiles for each row execute function public.profiles_before_update();
revoke all on function public.profiles_before_update() from public,anon,authenticated;
