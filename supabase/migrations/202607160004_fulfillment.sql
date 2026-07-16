create table public.order_shipping_addresses (
  order_id uuid primary key references public.orders(id) on delete restrict,
  recipient_name text not null check(char_length(recipient_name) between 1 and 120),
  line1 text not null check(char_length(line1) between 1 and 160),
  line2 text check(line2 is null or char_length(line2)<=160),
  postal_code text not null check(postal_code ~ '^[0-9]{4}[[:space:]]?[A-Za-z]{2}$'),
  city text not null check(char_length(city) between 1 and 100),
  country text not null check(country='NL'),
  phone text check(phone is null or phone ~ '^\+[1-9][0-9]{7,14}$'),
  created_at timestamptz not null default now()
);

create table public.fulfillment_jobs (
  id uuid primary key default gen_random_uuid(), order_id uuid not null unique references public.orders(id) on delete restrict,
  provider text not null default 'aliexpress_official_api' check(provider='aliexpress_official_api'),
  status text not null check(status in ('ready','processing','retry','submitted','tracking','cancel_requested','cancelled','manual_review')),
  idempotency_key uuid not null default gen_random_uuid() unique,
  max_purchase_total_minor integer check(max_purchase_total_minor is null or max_purchase_total_minor>=0),
  provider_order_id text unique, attempt_count integer not null default 0,
  next_attempt_at timestamptz not null default now(), lease_until timestamptz,
  last_error_code text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), submitted_at timestamptz,
  constraint submitted_has_provider_order check(status<>'submitted' or (provider_order_id is not null and char_length(provider_order_id) between 1 and 120))
);

create table public.fulfillment_lines (
  job_id uuid not null references public.fulfillment_jobs(id) on delete restrict,
  variant_id uuid not null references public.product_variants(id), source_product_id text not null, source_sku_id text not null,
  quantity integer not null check(quantity between 1 and 10), max_purchase_minor integer not null check(max_purchase_minor>=0),
  primary key(job_id,variant_id)
);

create table public.fulfillment_tracking (
  id uuid primary key default gen_random_uuid(), job_id uuid not null references public.fulfillment_jobs(id) on delete restrict,
  carrier text not null check(char_length(carrier)<=80), tracking_number text not null check(char_length(tracking_number)<=120),
  tracking_url text check(tracking_url is null or char_length(tracking_url)<=500), observed_at timestamptz not null,
  unique(job_id,carrier,tracking_number)
);

alter table public.order_shipping_addresses enable row level security;
alter table public.fulfillment_jobs enable row level security;
alter table public.fulfillment_lines enable row level security;
alter table public.fulfillment_tracking enable row level security;
revoke all on public.order_shipping_addresses,public.fulfillment_jobs,public.fulfillment_lines,public.fulfillment_tracking from anon,authenticated;

drop function if exists public.process_checkout_event(text,text,text,boolean,timestamptz,uuid,text,integer,text,text);
create function public.process_checkout_event(
 p_event_id text,p_event_type text,p_object_id text,p_livemode boolean,p_created_at timestamptz,
 p_order_id uuid,p_currency text,p_amount_total integer,p_payment_status text,p_payment_intent_id text,p_shipping jsonb
) returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare v_order orders%rowtype; v_job uuid; v_expected integer; v_valid integer; v_ceiling bigint;
begin
 insert into stripe_events(event_id,event_type,object_id,livemode,payload_created_at)
 values(p_event_id,p_event_type,p_object_id,p_livemode,p_created_at) on conflict do nothing;
 if not found then return 'duplicate'; end if;
 select * into v_order from orders where id=p_order_id for update;
 if not found or v_order.stripe_checkout_session_id is distinct from p_object_id or v_order.currency<>upper(p_currency) or v_order.total_minor<>p_amount_total then
  update stripe_events set processed_at=now(),outcome='quarantined',error_code='snapshot_mismatch' where event_id=p_event_id; return 'quarantined';
 end if;
 if p_event_type in ('checkout.session.completed','checkout.session.async_payment_succeeded') and p_payment_status='paid' then
  if p_shipping is null or p_shipping->>'country'<>'NL' or char_length(coalesce(p_shipping->>'name','')) not between 1 and 120
    or char_length(coalesce(p_shipping->>'line1','')) not between 1 and 160 or char_length(coalesce(p_shipping->>'city','')) not between 1 and 100
    or coalesce(p_shipping->>'postalCode','') !~ '^[0-9]{4}[[:space:]]?[A-Za-z]{2}$' then
   update stripe_events set processed_at=now(),outcome='quarantined',error_code='invalid_shipping_address' where event_id=p_event_id; return 'quarantined';
  end if;
  insert into order_shipping_addresses(order_id,recipient_name,line1,line2,postal_code,city,country,phone) values
   (p_order_id,p_shipping->>'name',p_shipping->>'line1',nullif(p_shipping->>'line2',''),p_shipping->>'postalCode',p_shipping->>'city','NL',nullif(p_shipping->>'phone',''))
  on conflict(order_id) do nothing;
  update orders set status='paid',amount_authorized=total_minor,amount_captured=total_minor,stripe_payment_intent_id=coalesce(stripe_payment_intent_id,p_payment_intent_id),paid_at=coalesce(paid_at,now())
  where id=p_order_id and status in ('checkout_pending','paid');
  select count(*),count(m.variant_id),sum((o.quantity*m.max_minor)) into v_expected,v_valid,v_ceiling from order_lines o
  left join lateral (select svm.variant_id,(so.source_price_minor+so.shipping_minor)::integer max_minor from supplier_variant_mappings svm
    join supplier_observations so on so.variant_id=svm.variant_id where svm.variant_id=o.variant_id and svm.enabled and so.observed_at+interval '1 hour'>now()
    order by so.observed_at desc limit 1) m on true where o.order_id=p_order_id;
  insert into fulfillment_jobs(order_id,status,max_purchase_total_minor,last_error_code) values
   (p_order_id,case when v_expected=v_valid and v_expected>0 then 'ready' else 'manual_review' end,v_ceiling,case when v_expected=v_valid and v_expected>0 then null else 'missing_fresh_supplier_quote' end)
  on conflict(order_id) do nothing returning id into v_job;
  if v_job is not null and v_expected=v_valid and v_expected>0 then
   insert into fulfillment_lines(job_id,variant_id,source_product_id,source_sku_id,quantity,max_purchase_minor)
   select v_job,ol.variant_id,svm.source_product_id,svm.source_sku_id,ol.quantity,(so.source_price_minor+so.shipping_minor)::integer
   from order_lines ol join supplier_variant_mappings svm on svm.variant_id=ol.variant_id and svm.enabled
   join lateral (select * from supplier_observations x where x.variant_id=ol.variant_id and x.observed_at+interval '1 hour'>now() order by x.observed_at desc limit 1) so on true where ol.order_id=p_order_id;
  end if;
  update stripe_events set processed_at=now(),outcome='processed' where event_id=p_event_id; return 'processed';
 end if;
 update stripe_events set processed_at=now(),outcome='ignored',error_code='not_paid' where event_id=p_event_id; return 'ignored';
end $$;
revoke all on function public.process_checkout_event(text,text,text,boolean,timestamptz,uuid,text,integer,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.process_checkout_event(text,text,text,boolean,timestamptz,uuid,text,integer,text,text,jsonb) to service_role;

create function public.claim_fulfillment_job() returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare j fulfillment_jobs%rowtype;
begin
 update fulfillment_jobs set status='manual_review',last_error_code='retry_limit_exceeded',lease_until=null,updated_at=now()
 where status in ('retry','processing') and attempt_count>=8 and (lease_until is null or lease_until<now());
 select * into j from fulfillment_jobs where (status in ('ready','retry') or (status='processing' and lease_until<now()))
   and next_attempt_at<=now() and (lease_until is null or lease_until<now()) and attempt_count<8 order by created_at for update skip locked limit 1;
 if not found then return null; end if;
 update fulfillment_jobs set status='processing',lease_until=now()+interval '2 minutes',attempt_count=attempt_count+1,updated_at=now() where id=j.id;
 return jsonb_build_object('jobId',j.id,'orderId',j.order_id,'idempotencyKey',j.idempotency_key,'maxPurchaseTotalMinor',j.max_purchase_total_minor);
end $$;
revoke all on function public.claim_fulfillment_job() from public,anon,authenticated; grant execute on function public.claim_fulfillment_job() to service_role;

create function public.finish_fulfillment_job(p_job_id uuid,p_outcome text,p_provider_order_id text,p_error_code text default null)
returns void language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if p_outcome not in ('submitted','retry','manual_review','cancelled') then raise exception 'invalid_outcome'; end if;
 if p_outcome='submitted' and (p_provider_order_id is null or char_length(p_provider_order_id) not between 1 and 120) then raise exception 'provider_order_id_required'; end if;
 update fulfillment_jobs set status=p_outcome,provider_order_id=case when p_outcome='submitted' then p_provider_order_id else provider_order_id end,
  last_error_code=p_error_code,lease_until=null,next_attempt_at=case when p_outcome='retry' then now()+least(interval '1 hour',interval '30 seconds'*power(2,least(attempt_count,7))) else next_attempt_at end,
  submitted_at=case when p_outcome='submitted' then now() else submitted_at end,updated_at=now()
 where id=p_job_id and status='processing'; if not found then raise exception 'job_not_claimed'; end if;
end $$;
revoke all on function public.finish_fulfillment_job(uuid,text,text,text) from public,anon,authenticated; grant execute on function public.finish_fulfillment_job(uuid,text,text,text) to service_role;

create function public.request_fulfillment_cancellation(p_order_id uuid) returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare s text;
begin
 select status into s from fulfillment_jobs where order_id=p_order_id for update; if not found then raise exception 'job_not_found'; end if;
 if s in ('ready','retry','manual_review') then update fulfillment_jobs set status='cancelled',lease_until=null,updated_at=now() where order_id=p_order_id;
 elsif s in ('submitted','tracking') then update fulfillment_jobs set status='cancel_requested',updated_at=now() where order_id=p_order_id;
 else raise exception 'cancellation_requires_manual_review'; end if;
 return (select status from fulfillment_jobs where order_id=p_order_id);
end $$;
revoke all on function public.request_fulfillment_cancellation(uuid) from public,anon,authenticated; grant execute on function public.request_fulfillment_cancellation(uuid) to service_role;

create function public.record_fulfillment_tracking(p_job_id uuid,p_carrier text,p_tracking_number text,p_tracking_url text,p_observed_at timestamptz)
returns void language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if char_length(p_carrier) not between 1 and 80 or char_length(p_tracking_number) not between 1 and 120
   or (p_tracking_url is not null and p_tracking_url !~ '^https://') or p_observed_at>now()+interval '5 minutes' then raise exception 'invalid_tracking'; end if;
 insert into fulfillment_tracking(job_id,carrier,tracking_number,tracking_url,observed_at) values(p_job_id,p_carrier,p_tracking_number,p_tracking_url,p_observed_at) on conflict do nothing;
 update fulfillment_jobs set status='tracking',updated_at=now() where id=p_job_id and status in ('submitted','tracking');
 if not found then raise exception 'tracking_status_conflict'; end if;
end $$;
revoke all on function public.record_fulfillment_tracking(uuid,text,text,text,timestamptz) from public,anon,authenticated; grant execute on function public.record_fulfillment_tracking(uuid,text,text,text,timestamptz) to service_role;
