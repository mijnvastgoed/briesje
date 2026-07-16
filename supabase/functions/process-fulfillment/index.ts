import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { json, required } from "../_shared/http.ts";

const enc=new TextEncoder();
async function equalSecret(a:string,b:string){const [x,y]=await Promise.all([crypto.subtle.digest("SHA-256",enc.encode(a)),crypto.subtle.digest("SHA-256",enc.encode(b))]);const xa=new Uint8Array(x),ya=new Uint8Array(y);let d=xa.length^ya.length;for(let i=0;i<Math.min(xa.length,ya.length);i++)d|=xa[i]^ya[i];return d===0;}
function api(baseName:string,hostName:string,path:string){const base=new URL(required(baseName)),host=required(hostName);if(base.protocol!=="https:"||base.hostname!==host||base.username||base.password)throw new Error("gateway_configuration_invalid");return new URL(path,base);}
async function call(url:URL,key:string,body:unknown,idempotency:string){const c=new AbortController(),t=setTimeout(()=>c.abort(),15_000);try{return await fetch(url,{method:"POST",redirect:"error",signal:c.signal,headers:{authorization:`Bearer ${key}`,"content-type":"application/json",accept:"application/json","idempotency-key":idempotency},body:JSON.stringify(body)});}finally{clearTimeout(t);}}

Deno.serve(async req=>{
 if(req.method!=="POST")return json({error:"method_not_allowed"},405);
 try{
  if(Deno.env.get("FULFILLMENT_ENABLED")!=="true"||Deno.env.get("FULFILLMENT_CONTRACT_APPROVED")!=="true"||Deno.env.get("FULFILLMENT_GATEWAY_IDEMPOTENCY_CONFIRMED")!=="true")return json({error:"fulfillment_disabled"},503);
  if(required("ALIEXPRESS_ORDER_API_METHOD")!=="aliexpress.trade.buy.placeorder")return json({error:"provider_contract_invalid"},503);
  const token=req.headers.get("authorization")?.replace(/^Bearer /,"")??"";if(!token||!await equalSecret(token,required("FULFILLMENT_WORKER_SECRET")))return json({error:"unauthorized"},401);
  const key=required("FULFILLMENT_API_KEY"),base="FULFILLMENT_API_BASE_URL",host="FULFILLMENT_API_ALLOWED_HOST";
  // Validate all configuration before claiming, so disabled/misconfigured deployments cannot strand a lease.
  api(base,host,"quotes"); api(base,host,"orders"); required("ALIEXPRESS_LOGISTICS_SERVICE_NAME");
  const db=createClient(required("SUPABASE_URL"),required("SUPABASE_SERVICE_ROLE_KEY"));
  const {data:job,error:claimError}=await db.rpc("claim_fulfillment_job");if(claimError)throw new Error("claim_failed");if(!job)return json({processed:0});
  const fail=async(outcome:string,code:string)=>{await db.rpc("finish_fulfillment_job",{p_job_id:job.jobId,p_outcome:outcome,p_provider_order_id:null,p_error_code:code});return json({processed:1,outcome},outcome==="retry"?503:200);};
  const [{data:address,error:ae},{data:lines,error:le}]=await Promise.all([db.from("order_shipping_addresses").select("recipient_name,line1,line2,postal_code,city,country,phone").eq("order_id",job.orderId).single(),db.from("fulfillment_lines").select("source_product_id,source_sku_id,quantity,max_purchase_minor").eq("job_id",job.jobId)]);
  if(ae||le||!address||!lines?.length)return await fail("manual_review","snapshot_missing");
  const quoteResponse=await call(api(base,host,"quotes"),key,{destinationCountry:"NL",items:lines.map(l=>({productId:l.source_product_id,skuId:l.source_sku_id,quantity:l.quantity}))},job.idempotencyKey+":quote");
  if(!quoteResponse.ok)return await fail(quoteResponse.status>=500?"retry":"manual_review","preflight_failed");
  const quotes=(await quoteResponse.json()).quotes;if(!Array.isArray(quotes)||quotes.length!==lines.length)return await fail("manual_review","preflight_schema_invalid");
  let total=0;for(const line of lines){const q=quotes.filter((x:Record<string,unknown>)=>x.productId===line.source_product_id&&x.skuId===line.source_sku_id);if(q.length!==1||q[0].stockAvailable!==true||q[0].currency!=="EUR"||!Number.isSafeInteger(q[0].priceMinor)||!Number.isSafeInteger(q[0].shippingMinor))return await fail("manual_review","preflight_identity_or_stock");const unit=q[0].priceMinor+q[0].shippingMinor;if(unit>line.max_purchase_minor)return await fail("manual_review","price_ceiling_exceeded");total+=unit*line.quantity;}
  if(total>job.maxPurchaseTotalMinor)return await fail("manual_review","total_price_ceiling_exceeded");
  const payload={method:"aliexpress.trade.buy.placeorder",logistics_address:{contact_person:address.recipient_name,address:address.line1,address2:address.line2??undefined,city:address.city,zip:address.postal_code,country:"NL",mobile_no:address.phone??undefined},product_items:lines.map(l=>({product_count:l.quantity,product_id:l.source_product_id,sku_attr:l.source_sku_id,logistics_service_name:required("ALIEXPRESS_LOGISTICS_SERVICE_NAME"),order_memo:"NO SUBSTITUTIONS"})),currency:"EUR",max_purchase_total_minor:job.maxPurchaseTotalMinor,allow_substitution:false};
  const orderResponse=await call(api(base,host,"orders"),key,payload,job.idempotencyKey);
  if(!orderResponse.ok)return await fail(orderResponse.status>=500?"retry":"manual_review",orderResponse.status===409?"repeated_order_requires_reconciliation":"provider_order_failed");
  const result=await orderResponse.json();const providerOrderId=result?.order_list?.[0]?.order_id??result?.orderId;
  if(result?.is_success!==true||typeof providerOrderId!=="string"||providerOrderId.length>120)return await fail("manual_review","provider_response_invalid");
  const {error:finishError}=await db.rpc("finish_fulfillment_job",{p_job_id:job.jobId,p_outcome:"submitted",p_provider_order_id:providerOrderId,p_error_code:null});if(finishError)throw new Error("finish_failed");
  return json({processed:1,outcome:"submitted"});
 }catch(error){console.error(error instanceof Error?error.message:"fulfillment_worker_failed");return json({error:"fulfillment_worker_failed"},503);}
});
