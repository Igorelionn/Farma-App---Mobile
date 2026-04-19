-- ============================================================
-- Migration: Optimize bulk_sync_products - Fix N+1 Query
-- ============================================================
-- Data: 2026-04-13
-- Descrição: Remove N+1 query de categorias fazendo lookup
--            uma única vez com CTE ao invés de SELECT por produto
-- ============================================================

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
  v_category_map JSONB;
BEGIN
  -- Criar mapa de categorias uma única vez (evita N+1)
  SELECT jsonb_object_agg(nome, id)
  INTO v_category_map
  FROM public.categories;
  
  -- Buscar ID da categoria "Outros" para fallback
  SELECT id INTO v_category_id 
  FROM public.categories 
  WHERE nome = 'Outros' 
  LIMIT 1;
  
  -- Processar cada produto
  FOR v_product IN SELECT * FROM jsonb_array_elements(p_products)
  LOOP
    -- Lookup de categoria no mapa (O(1) vs N queries)
    DECLARE
      v_cat_nome TEXT := COALESCE(v_product->>'categoria', 'Outros');
      v_mapped_id TEXT;
    BEGIN
      v_mapped_id := v_category_map->>v_cat_nome;
      IF v_mapped_id IS NOT NULL THEN
        v_category_id := v_mapped_id::UUID;
      END IF;
    END;
    
    INSERT INTO public.products (
      excel_row_id, nome, principio_ativo, laboratorio, preco, apresentacao,
      estoque, category_id, imagem_url, tarja, descricao, disponivel, codigo_barras,
      em_promocao, preco_promocional, unidade, classificacao_fiscal, last_synced_at
    ) VALUES (
      v_product->>'excel_row_id', 
      v_product->>'nome', 
      v_product->>'principio_ativo',
      COALESCE(v_product->>'laboratorio',''), 
      COALESCE((v_product->>'preco')::NUMERIC,0),
      COALESCE(v_product->>'apresentacao',''), 
      COALESCE((v_product->>'estoque')::INT,0),
      v_category_id, 
      v_product->>'imagem_url', 
      v_product->>'tarja', 
      v_product->>'descricao',
      COALESCE((v_product->>'disponivel')::BOOLEAN,TRUE), 
      v_product->>'codigo_barras',
      COALESCE((v_product->>'em_promocao')::BOOLEAN,FALSE),
      (v_product->>'preco_promocional')::NUMERIC,
      COALESCE(v_product->>'unidade','UN'), 
      v_product->>'classificacao_fiscal', 
      NOW()
    )
    ON CONFLICT (excel_row_id) DO UPDATE SET
      nome = EXCLUDED.nome, 
      principio_ativo = EXCLUDED.principio_ativo,
      laboratorio = EXCLUDED.laboratorio,
      preco = CASE WHEN EXCLUDED.preco > 0 THEN EXCLUDED.preco ELSE products.preco END,
      apresentacao = EXCLUDED.apresentacao, 
      estoque = EXCLUDED.estoque,
      category_id = v_category_id,
      imagem_url = COALESCE(EXCLUDED.imagem_url, products.imagem_url),
      tarja = EXCLUDED.tarja, 
      descricao = EXCLUDED.descricao,
      disponivel = EXCLUDED.disponivel, 
      codigo_barras = EXCLUDED.codigo_barras,
      em_promocao = EXCLUDED.em_promocao, 
      preco_promocional = EXCLUDED.preco_promocional,
      unidade = COALESCE(EXCLUDED.unidade, products.unidade),
      classificacao_fiscal = EXCLUDED.classificacao_fiscal, 
      last_synced_at = NOW();
      
    v_count := v_count + 1;
  END LOOP;
  
  INSERT INTO public.sync_log (source, action, records_affected, status)
  VALUES ('excel_online', 'bulk_sync', v_count, 'success');
  
  RETURN v_count;
END;
$$;

-- ============================================================
-- Comentários
-- ============================================================
COMMENT ON FUNCTION public.bulk_sync_products_from_excel(jsonb) IS 
  'Sincroniza produtos em lote do Excel. Otimizado para evitar N+1 queries de categoria usando mapa em memória.';
