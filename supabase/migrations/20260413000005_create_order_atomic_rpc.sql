-- ============================================================
-- Migration: Create Atomic Order Creation RPC
-- ============================================================
-- Data: 2026-04-13
-- Descrição: Cria RPC para criar pedido + itens em uma única
--            transação atômica, evitando pedidos órfãos
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_order_atomic(
  p_order_number TEXT,
  p_user_id UUID,
  p_address_id UUID,
  p_payment_method_id UUID,
  p_subtotal NUMERIC(10,2),
  p_shipping NUMERIC(10,2),
  p_discount NUMERIC(10,2),
  p_total NUMERIC(10,2),
  p_notes TEXT,
  p_items JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_order_id UUID;
  v_item JSONB;
  v_product_id UUID;
  v_quantity INT;
  v_unit_price NUMERIC(10,2);
  v_subtotal NUMERIC(10,2);
BEGIN
  -- Validar que há itens
  IF jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Order must have at least one item';
  END IF;
  
  -- Inserir pedido
  INSERT INTO public.orders (
    number,
    user_id,
    address_id,
    payment_method_id,
    subtotal,
    shipping,
    discount,
    total,
    notes,
    status
  ) VALUES (
    p_order_number,
    p_user_id,
    p_address_id,
    p_payment_method_id,
    p_subtotal,
    p_shipping,
    p_discount,
    p_total,
    p_notes,
    'pending'
  )
  RETURNING id INTO v_order_id;
  
  -- Inserir itens do pedido
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_product_id := (v_item->>'product_id')::UUID;
    v_quantity := (v_item->>'quantity')::INT;
    v_unit_price := (v_item->>'unit_price')::NUMERIC;
    v_subtotal := (v_item->>'subtotal')::NUMERIC;
    
    -- Validar que o produto existe e tem estoque
    IF NOT EXISTS (
      SELECT 1 FROM public.products 
      WHERE id = v_product_id 
        AND disponivel = TRUE 
        AND estoque >= v_quantity
    ) THEN
      RAISE EXCEPTION 'Product % is unavailable or insufficient stock', v_product_id;
    END IF;
    
    INSERT INTO public.order_items (
      order_id,
      product_id,
      quantity,
      unit_price,
      subtotal
    ) VALUES (
      v_order_id,
      v_product_id,
      v_quantity,
      v_unit_price,
      v_subtotal
    );
  END LOOP;
  
  -- Inserir histórico inicial
  INSERT INTO public.order_status_history (
    order_id,
    status,
    description
  ) VALUES (
    v_order_id,
    'pending',
    'Pedido realizado'
  );
  
  -- Retornar ID do pedido criado
  RETURN v_order_id;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Em caso de erro, a transação é revertida automaticamente
    RAISE;
END;
$$;

-- ============================================================
-- Comentários
-- ============================================================
COMMENT ON FUNCTION public.create_order_atomic(TEXT, UUID, UUID, UUID, NUMERIC, NUMERIC, NUMERIC, NUMERIC, TEXT, JSONB) IS 
  'Cria pedido com itens e histórico em transação atômica. Valida estoque antes de inserir.';

-- ============================================================
-- Exemplo de uso:
-- ============================================================
-- SELECT create_order_atomic(
--   'PED001',
--   'user-uuid',
--   'address-uuid',
--   'payment-uuid',
--   100.00,
--   30.00,
--   0.00,
--   130.00,
--   'Observações do pedido',
--   '[
--     {"product_id": "prod-uuid-1", "quantity": 2, "unit_price": 25.00, "subtotal": 50.00},
--     {"product_id": "prod-uuid-2", "quantity": 1, "unit_price": 50.00, "subtotal": 50.00}
--   ]'::jsonb
-- );
