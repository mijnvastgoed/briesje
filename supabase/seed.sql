insert into public.products (id, slug, title, short_description, image_url, is_demo) values
('10000000-0000-4000-8000-000000000001','briesje-handventilator','Briesje Handventilator','Compact demo-model voor onderweg. TEST — GEEN VERKOOP.',null,true),
('10000000-0000-4000-8000-000000000002','briesje-nekventilator','Briesje Nekventilator','Handsfree demo-model. TEST — GEEN VERKOOP.',null,true),
('10000000-0000-4000-8000-000000000003','briesje-bureauventilator','Briesje Bureauventilator','Stil demo-model voor bureau of nachtkastje. TEST — GEEN VERKOOP.',null,true);

insert into public.product_variants
(id, product_id, sku, label, sale_price_minor, source_product_id, source_sku_id, reason_code)
values
('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','DEMO-HAND-WIT','Wit',1995,'1005008081738393','12000043648049237','demo_not_approved'),
('20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','DEMO-NEK-WIT','Wit',2495,'1005007529621225','12000041184498228','demo_not_approved'),
('20000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000003','DEMO-DESK-GROEN','Saliegroen',2995,null,null,'synthetic_demo');
