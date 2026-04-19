-- ============================================================
-- Migration: Fix SECURITY DEFINER Functions - Add search_path
-- ============================================================
-- Data: 2026-04-12
-- Descrição: Adiciona SET search_path em todas as funções
--            SECURITY DEFINER para prevenir search_path hijacking
-- ============================================================

-- 1. recalculate_order_totals
CREATE OR REPLACE FUNCTION public.recalculate_order_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_subtotal      NUMERIC(10,2);
  v_shipping      NUMERIC(10,2);
  v_discount      NUMERIC(10,2);
  v_total         NUMERIC(10,2);
  v_free_shipping NUMERIC(10,2) := 1000.00;
  v_ship_cost     NUMERIC(10,2) := 30.00;
BEGIN
  -- Recalcula subtotal baseado nos itens reais
  SELECT COALESCE(SUM(unit_price * quantity), 0)
  INTO v_subtotal
  FROM public.order_items
  WHERE order_id = NEW.id;

  -- Frete grátis se subtotal >= valor mínimo
  v_shipping := CASE WHEN v_subtotal >= v_free_shipping THEN 0 ELSE v_ship_cost END;

  -- Desconto vem do registro do pedido
  v_discount := COALESCE(NEW.discount, 0);

  -- Total = subtotal + frete - desconto
  v_total := v_subtotal + v_shipping - v_discount;

  -- Atualiza os valores calculados
  NEW.subtotal := v_subtotal;
  NEW.shipping := v_shipping;
  NEW.total := v_total;

  RETURN NEW;
END;
$$;

-- 2. generate_order_number
CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  IF NEW.number IS NULL OR NEW.number = '' THEN
    NEW.number := 'PED' || LPAD(nextval('public.order_number_seq')::text, 6, '0');
  END IF;
  RETURN NEW;
END;
$$;

-- 3. bulk_sync_products_from_excel
CREATE OR REPLACE FUNCTION public.bulk_sync_products_from_excel(p_products jsonb)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_count INT := 0;
  v_product JSONB;
  v_category_id UUID;
BEGIN
  FOR v_product IN SELECT * FROM jsonb_array_elements(p_products)
  LOOP
    SELECT id INTO v_category_id FROM public.categories
    WHERE nome = COALESCE(v_product->>'categoria', 'Outros');
    IF v_category_id IS NULL THEN
      SELECT id INTO v_category_id FROM public.categories WHERE nome = 'Outros';
    END IF;
    INSERT INTO public.products (
      excel_row_id, nome, principio_ativo, laboratorio, preco, apresentacao,
      estoque, category_id, imagem_url, tarja, descricao, disponivel, codigo_barras,
      em_promocao, preco_promocional, unidade, classificacao_fiscal, last_synced_at
    ) VALUES (
      v_product->>'excel_row_id', v_product->>'nome', v_product->>'principio_ativo',
      COALESCE(v_product->>'laboratorio',''), COALESCE((v_product->>'preco')::NUMERIC,0),
      COALESCE(v_product->>'apresentacao',''), COALESCE((v_product->>'estoque')::INT,0),
      v_category_id, v_product->>'imagem_url', v_product->>'tarja', v_product->>'descricao',
      COALESCE((v_product->>'disponivel')::BOOLEAN,TRUE), v_product->>'codigo_barras',
      COALESCE((v_product->>'em_promocao')::BOOLEAN,FALSE),
      (v_product->>'preco_promocional')::NUMERIC,
      COALESCE(v_product->>'unidade','UN'), v_product->>'classificacao_fiscal', NOW()
    )
    ON CONFLICT (excel_row_id) DO UPDATE SET
      nome = EXCLUDED.nome, principio_ativo = EXCLUDED.principio_ativo,
      laboratorio = EXCLUDED.laboratorio,
      preco = CASE WHEN EXCLUDED.preco > 0 THEN EXCLUDED.preco ELSE products.preco END,
      apresentacao = EXCLUDED.apresentacao, estoque = EXCLUDED.estoque,
      category_id = v_category_id,
      imagem_url = COALESCE(EXCLUDED.imagem_url, products.imagem_url),
      tarja = EXCLUDED.tarja, descricao = EXCLUDED.descricao,
      disponivel = EXCLUDED.disponivel, codigo_barras = EXCLUDED.codigo_barras,
      em_promocao = EXCLUDED.em_promocao, preco_promocional = EXCLUDED.preco_promocional,
      unidade = COALESCE(EXCLUDED.unidade, products.unidade),
      classificacao_fiscal = EXCLUDED.classificacao_fiscal, last_synced_at = NOW();
    v_count := v_count + 1;
  END LOOP;
  INSERT INTO public.sync_log (source, action, records_affected, status)
  VALUES ('excel_online', 'bulk_sync', v_count, 'success');
  RETURN v_count;
END;
$$;

-- 4. upsert_product_from_excel (ambas as versões)
CREATE OR REPLACE FUNCTION public.upsert_product_from_excel(
  p_excel_row_id text, p_nome text, p_principio_ativo text, p_laboratorio text,
  p_preco numeric, p_apresentacao text, p_estoque integer, p_categoria_nome text,
  p_imagem_url text, p_tarja text, p_descricao text, p_disponivel boolean,
  p_codigo_barras text, p_em_promocao boolean, p_preco_promocional numeric,
  p_unidade text, p_classificacao_fiscal text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_category_id UUID;
  v_product_id UUID;
BEGIN
  SELECT id INTO v_category_id FROM public.categories WHERE nome = p_categoria_nome;
  IF v_category_id IS NULL THEN
    SELECT id INTO v_category_id FROM public.categories WHERE nome = 'Outros';
  END IF;
  INSERT INTO public.products (
    excel_row_id, nome, principio_ativo, laboratorio, preco,
    apresentacao, estoque, category_id, imagem_url, tarja,
    descricao, disponivel, codigo_barras, em_promocao,
    preco_promocional, unidade, classificacao_fiscal, last_synced_at
  ) VALUES (
    p_excel_row_id, p_nome, p_principio_ativo, p_laboratorio, p_preco,
    p_apresentacao, p_estoque, v_category_id, p_imagem_url, p_tarja,
    p_descricao, p_disponivel, p_codigo_barras, p_em_promocao,
    p_preco_promocional, p_unidade, p_classificacao_fiscal, NOW()
  )
  ON CONFLICT (excel_row_id) DO UPDATE SET
    nome = EXCLUDED.nome, principio_ativo = EXCLUDED.principio_ativo,
    laboratorio = EXCLUDED.laboratorio,
    preco = CASE WHEN EXCLUDED.preco > 0 THEN EXCLUDED.preco ELSE products.preco END,
    apresentacao = EXCLUDED.apresentacao, estoque = EXCLUDED.estoque,
    category_id = v_category_id,
    imagem_url = COALESCE(EXCLUDED.imagem_url, products.imagem_url),
    tarja = EXCLUDED.tarja, descricao = EXCLUDED.descricao,
    disponivel = EXCLUDED.disponivel, codigo_barras = EXCLUDED.codigo_barras,
    em_promocao = EXCLUDED.em_promocao, preco_promocional = EXCLUDED.preco_promocional,
    unidade = EXCLUDED.unidade, classificacao_fiscal = EXCLUDED.classificacao_fiscal,
    last_synced_at = NOW()
  RETURNING id INTO v_product_id;
  INSERT INTO public.sync_log (source, action, records_affected, status)
  VALUES ('excel_online', 'upsert_product', 1, 'success');
  RETURN v_product_id;
END;
$$;

-- 5. bulk_update_prices
CREATE OR REPLACE FUNCTION public.bulk_update_prices(p_data jsonb)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_count INT := 0;
  v_item JSONB;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_data)
  LOOP
    UPDATE public.products
    SET preco = (v_item->>'preco')::NUMERIC
    WHERE UPPER(nome) = UPPER(v_item->>'nome')
      AND preco = 0
      AND (v_item->>'preco')::NUMERIC > 0;
    v_count := v_count + COALESCE((SELECT COUNT(*) FROM public.products WHERE UPPER(nome) = UPPER(v_item->>'nome') AND preco > 0), 0);
  END LOOP;
  RETURN v_count;
END;
$$;

-- 6. check_email_exists
-- Já tem SET search_path ✅

-- 7. get_email_by_username
-- Já tem SET search_path ✅

-- 8. handle_new_user
-- Já tem SET search_path ✅

-- 9. is_admin
-- Já tem SET search_path ✅

-- 10. prevent_profile_escalation
-- Já tem SET search_path ✅

-- 11. recalculate_order_totals_after_items
CREATE OR REPLACE FUNCTION public.recalculate_order_totals_after_items()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_subtotal      NUMERIC(10,2);
  v_shipping      NUMERIC(10,2);
  v_discount      NUMERIC(10,2);
  v_total         NUMERIC(10,2);
  v_free_shipping NUMERIC(10,2) := 1000.00;
  v_ship_cost     NUMERIC(10,2) := 30.00;
BEGIN
  -- Subtotal com preço final (promocional quando aplicável)
  SELECT COALESCE(SUM(
    CASE
      WHEN p.em_promocao AND p.preco_promocional IS NOT NULL
        THEN p.preco_promocional * oi.quantity
      ELSE p.preco * oi.quantity
    END
  ), 0)
  INTO v_subtotal
  FROM public.order_items oi
  JOIN public.products p ON p.id = oi.product_id
  WHERE oi.order_id = NEW.order_id;

  v_shipping := CASE WHEN v_subtotal >= v_free_shipping THEN 0 ELSE v_ship_cost END;

  SELECT COALESCE(discount, 0) INTO v_discount
  FROM public.orders WHERE id = NEW.order_id;

  v_total := v_subtotal + v_shipping - GREATEST(v_discount, 0);

  -- Sobrescreve os valores vindos do cliente com os calculados no servidor
  UPDATE public.orders
  SET
    subtotal = v_subtotal,
    shipping = v_shipping,
    total    = v_total
  WHERE id = NEW.order_id;

  RETURN NEW;
END;
$$;

-- 12. reduce_stock_on_order_item
CREATE OR REPLACE FUNCTION public.reduce_stock_on_order_item()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  UPDATE public.products
  SET estoque = GREATEST(estoque - NEW.quantity, 0)
  WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$;

-- 13. restore_stock_on_cancel
CREATE OR REPLACE FUNCTION public.restore_stock_on_cancel()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    UPDATE public.products p
    SET estoque = estoque + oi.quantity
    FROM public.order_items oi
    WHERE oi.order_id = NEW.id AND p.id = oi.product_id;
  END IF;
  RETURN NEW;
END;
$$;

-- 14. rls_auto_enable
CREATE OR REPLACE FUNCTION public.rls_auto_enable()
RETURNS event_trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;

-- ============================================================
-- Verificação
-- ============================================================
-- Para verificar se todas as funções SECURITY DEFINER têm search_path:
-- SELECT proname, prosecdef, proconfig
-- FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
-- WHERE n.nspname = 'public' AND prosecdef = true;
-- 
-- Todas devem ter proconfig contendo 'search_path='
-- ============================================================
