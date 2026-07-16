create or replace function public.create_checkout_draft(
  p_user_id uuid,
  p_checkout_attempt uuid,
  p_items jsonb,
  p_shipping_country text default 'NL'
) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_order_id uuid;
  v_subtotal bigint;
  v_count integer;
begin
  if p_user_id is null or p_shipping_country <> 'NL' then raise exception 'checkout_not_allowed'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) not between 1 and 20 then raise exception 'invalid_cart'; end if;

  select count(*), sum(v.sale_price_minor * i.quantity)
  into v_count, v_subtotal
  from (
    select (x->>'variantId')::uuid variant_id, (x->>'quantity')::integer quantity
    from jsonb_array_elements(p_items) x
  ) i join product_variants v on v.id = i.variant_id
      join products p on p.id = v.product_id
  where i.quantity between 1 and 10
    and not p.is_demo and v.stock_state = 'in_stock' and v.sale_price_minor is not null
    and v.product_compliance_status = 'approved' and v.supplier_test_status = 'approved'
    and v.source_data_status = 'approved' and v.logistics_status = 'approved' and v.price_status = 'approved'
    and v.approved_at is not null and v.evidence_valid_until > now()
    and v.source_observed_at is not null and v.source_ttl_seconds is not null
    and v.source_observed_at + make_interval(secs => v.source_ttl_seconds) > now();

  if v_count <> jsonb_array_length(p_items) or v_subtotal is null then raise exception 'cart_not_sellable'; end if;
  if (select count(distinct x->>'variantId') from jsonb_array_elements(p_items) x) <> jsonb_array_length(p_items) then raise exception 'duplicate_variant'; end if;

  insert into orders(user_id,status,subtotal_minor,total_minor,checkout_attempt,shipping_country)
  values(p_user_id,'checkout_pending',v_subtotal,v_subtotal,p_checkout_attempt,p_shipping_country)
  on conflict(user_id,checkout_attempt) do nothing returning id into v_order_id;

  if v_order_id is null then
    select id into v_order_id from orders where user_id=p_user_id and checkout_attempt=p_checkout_attempt;
    return jsonb_build_object('orderId',v_order_id,'reused',true);
  end if;

  insert into order_lines(order_id,variant_id,quantity,currency,unit_price_minor,price_version,title_snapshot,sku_snapshot)
  select v_order_id, v.id, i.quantity, v.currency, v.sale_price_minor, v.price_version, p.title, v.sku
  from (select (x->>'variantId')::uuid variant_id,(x->>'quantity')::integer quantity from jsonb_array_elements(p_items) x) i
  join product_variants v on v.id=i.variant_id join products p on p.id=v.product_id;

  return jsonb_build_object('orderId',v_order_id,'reused',false);
end $$;

create or replace function public.record_checkout_session(p_order_id uuid,p_session_id text)
returns void language plpgsql security definer set search_path=public,pg_temp as $$
begin
 update orders set stripe_checkout_session_id=p_session_id
 where id=p_order_id and status='checkout_pending'
   and (stripe_checkout_session_id is null or stripe_checkout_session_id=p_session_id);
 if not found then raise exception 'order_session_conflict'; end if;
end $$;

create or replace function public.process_checkout_event(
 p_event_id text,p_event_type text,p_object_id text,p_livemode boolean,p_created_at timestamptz,
 p_order_id uuid,p_currency text,p_amount_total integer,p_payment_status text,p_payment_intent_id text
) returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare v_order orders%rowtype; v_updated integer;
begin
 insert into stripe_events(event_id,event_type,object_id,livemode,payload_created_at)
 values(p_event_id,p_event_type,p_object_id,p_livemode,p_created_at) on conflict do nothing;
 if not found then return 'duplicate'; end if;
 select * into v_order from orders where id=p_order_id for update;
 if not found or v_order.stripe_checkout_session_id is distinct from p_object_id
    or v_order.currency <> upper(p_currency) or v_order.total_minor <> p_amount_total then
   update stripe_events set processed_at=now(),outcome='quarantined',error_code='snapshot_mismatch' where event_id=p_event_id;
   return 'quarantined';
 end if;
 if p_event_type in ('checkout.session.completed','checkout.session.async_payment_succeeded') and p_payment_status='paid' then
   update orders set status='paid',amount_authorized=total_minor,amount_captured=total_minor,
     stripe_payment_intent_id=coalesce(stripe_payment_intent_id,p_payment_intent_id),paid_at=coalesce(paid_at,now())
   where id=p_order_id and status in ('checkout_pending','paid');
   get diagnostics v_updated = row_count;
   if v_updated <> 1 then
     update stripe_events set processed_at=now(),outcome='quarantined',error_code='invalid_status_transition' where event_id=p_event_id;
     return 'quarantined';
   end if;
   update stripe_events set processed_at=now(),outcome='processed' where event_id=p_event_id; return 'processed';
 end if;
 update stripe_events set processed_at=now(),outcome='ignored',error_code='not_paid' where event_id=p_event_id;
 return 'ignored';
end $$;

revoke all on function public.create_checkout_draft(uuid,uuid,jsonb,text) from public,anon,authenticated;
revoke all on function public.record_checkout_session(uuid,text) from public,anon,authenticated;
revoke all on function public.process_checkout_event(text,text,text,boolean,timestamptz,uuid,text,integer,text,text) from public,anon,authenticated;
grant execute on function public.create_checkout_draft(uuid,uuid,jsonb,text) to service_role;
grant execute on function public.record_checkout_session(uuid,text) to service_role;
grant execute on function public.process_checkout_event(text,text,text,boolean,timestamptz,uuid,text,integer,text,text) to service_role;
