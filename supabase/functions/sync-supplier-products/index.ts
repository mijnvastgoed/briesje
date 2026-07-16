import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { json, required } from "../_shared/http.ts";

type Quote = { productId:string; skuId:string; currency:"EUR"; priceMinor:number; shippingMinor:number; stockAvailable:boolean; observedAt:string };
const encoder = new TextEncoder();
async function sameSecret(a:string,b:string) {
  const [x,y]=await Promise.all([crypto.subtle.digest("SHA-256",encoder.encode(a)),crypto.subtle.digest("SHA-256",encoder.encode(b))]);
  const xa=new Uint8Array(x),ya=new Uint8Array(y); let diff=xa.length^ya.length;
  for(let i=0;i<Math.min(xa.length,ya.length);i++) diff|=xa[i]^ya[i]; return diff===0;
}
function validQuote(q:unknown): q is Quote {
  if(!q || typeof q!=="object") return false; const x=q as Record<string,unknown>;
  return typeof x.productId==="string" && x.productId.length<=80 && typeof x.skuId==="string" && x.skuId.length<=80 && x.currency==="EUR" &&
    Number.isSafeInteger(x.priceMinor) && (x.priceMinor as number)>=0 && (x.priceMinor as number)<=1_000_000 &&
    Number.isSafeInteger(x.shippingMinor) && (x.shippingMinor as number)>=0 && (x.shippingMinor as number)<=1_000_000 &&
    typeof x.stockAvailable==="boolean" && typeof x.observedAt==="string" && !Number.isNaN(Date.parse(x.observedAt));
}
async function hash(value:unknown) { const bytes=await crypto.subtle.digest("SHA-256",encoder.encode(JSON.stringify(value))); return [...new Uint8Array(bytes)].map(x=>x.toString(16).padStart(2,"0")).join(""); }

Deno.serve(async(req)=>{
  if(req.method!=="POST") return json({error:"method_not_allowed"},405);
  try {
    if(Deno.env.get("SUPPLIER_SYNC_ENABLED")!=="true") return json({error:"sync_disabled"},503);
    const supplied=req.headers.get("authorization")?.replace(/^Bearer /,"")??"";
    if(!supplied || !await sameSecret(supplied,required("SUPPLIER_SYNC_SECRET"))) return json({error:"unauthorized"},401);
    const base=new URL(required("SUPPLIER_API_BASE_URL")), allowedHost=required("SUPPLIER_API_ALLOWED_HOST");
    if(base.protocol!=="https:" || base.hostname!==allowedHost || base.username || base.password) return json({error:"supplier_configuration_invalid"},503);
    const admin=createClient(required("SUPABASE_URL"),required("SUPABASE_SERVICE_ROLE_KEY"));
    const {data:mappings,error:mapError}=await admin.from("supplier_variant_mappings").select("variant_id,source_product_id,source_sku_id,destination_country").eq("enabled",true).limit(100);
    if(mapError) throw new Error("database_unavailable");
    const {data:run,error:runError}=await admin.from("supplier_sync_runs").insert({provider:"aliexpress_official_api"}).select("id").single();
    if(runError) throw new Error("database_unavailable");
    if(!mappings?.length) { await admin.from("supplier_sync_runs").update({finished_at:new Date().toISOString(),outcome:"succeeded"}).eq("id",run.id); return json({runId:run.id,processed:0}); }
    const controller=new AbortController(), timer=setTimeout(()=>controller.abort(),10_000);
    let response:Response;
    try { response=await fetch(new URL("quotes",base),{method:"POST",redirect:"error",signal:controller.signal,headers:{"authorization":`Bearer ${required("SUPPLIER_API_KEY")}`,"content-type":"application/json","accept":"application/json"},body:JSON.stringify({destinationCountry:"NL",items:mappings.map(m=>({productId:m.source_product_id,skuId:m.source_sku_id,quantity:1}))})}); }
    finally { clearTimeout(timer); }
    if(!response.ok || Number(response.headers.get("content-length")??0)>500_000) throw new Error("supplier_response_invalid");
    const raw=await response.text(); if(raw.length>500_000) throw new Error("supplier_response_invalid");
    const payload=JSON.parse(raw) as {quotes?:unknown[]}; if(!Array.isArray(payload.quotes) || payload.quotes.length!==mappings.length || !payload.quotes.every(validQuote)) throw new Error("supplier_schema_invalid");
    let processed=0;
    for(const mapping of mappings) {
      const matches=payload.quotes.filter(q=>(q as Quote).productId===mapping.source_product_id&&(q as Quote).skuId===mapping.source_sku_id) as Quote[];
      if(matches.length!==1) throw new Error("supplier_identity_mismatch"); const q=matches[0];
      const {error}=await admin.rpc("ingest_supplier_observation",{p_run_id:run.id,p_variant_id:mapping.variant_id,p_source_product_id:q.productId,p_source_sku_id:q.skuId,p_currency:q.currency,p_source_price_minor:q.priceMinor,p_shipping_minor:q.shippingMinor,p_stock_available:q.stockAvailable,p_observed_at:q.observedAt,p_response_hash:await hash(q)});
      if(error) throw new Error("observation_rejected"); processed++;
    }
    await admin.from("supplier_sync_runs").update({finished_at:new Date().toISOString(),outcome:"succeeded",observation_count:processed}).eq("id",run.id);
    return json({runId:run.id,processed});
  } catch(error) {
    console.error(error instanceof Error?error.message:"supplier_sync_failed");
    return json({error:"supplier_sync_failed"},503);
  }
});
