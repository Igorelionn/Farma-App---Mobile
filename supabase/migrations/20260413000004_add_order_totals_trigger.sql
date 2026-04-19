-- ============================================================
-- Migration: Add Trigger to Recalculate Totals on Order Insert
-- ============================================================
-- Data: 2026-04-13
-- Descrição: Adiciona trigger para recalcular totais do pedido
--            logo após inserção, garantindo que regras de frete
--            do servidor sejam aplicadas
-- ============================================================

-- Função para recalcular totais no INSERT (baseada na existente)
CREATE OR REPLACE FUNCTION public.recalculate_order_totals_on_insert()
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
  -- Recalcula subtotal baseado nos itens (se já existirem)
  SELECT COALESCE(SUM(unit_price * quantity), 0)
  INTO v_subtotal
  FROM public.order_items
  WHERE order_id = NEW.id;
  
  -- Se não há itens ainda, usa o subtotal do cliente
  IF v_subtotal = 0 THEN
    v_subtotal := COALESCE(NEW.subtotal, 0);
  END IF;

  -- Frete grátis se subtotal >= valor mínimo
  v_shipping := CASE WHEN v_subtotal >= v_free_shipping THEN 0 ELSE v_ship_cost END;

  -- Desconto vem do registro do pedido
  v_discount := COALESCE(NEW.discount, 0);

  -- Total = subtotal + frete - desconto
  v_total := v_subtotal + v_shipping - v_discount;

  -- Atualiza os valores calculados
  UPDATE public.orders
  SET
    subtotal = v_subtotal,
    shipping = v_shipping,
    total = v_total
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$;

-- Trigger AFTER INSERT para recalcular após inserção dos itens
CREATE TRIGGER trg_recalculate_totals_on_insert
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.recalculate_order_totals_on_insert();

-- ============================================================
-- Comentários
-- ============================================================
COMMENT ON FUNCTION public.recalculate_order_totals_on_insert() IS 
  'Recalcula totais do pedido após INSERT, aplicando regras de frete do servidor';

COMMENT ON TRIGGER trg_recalculate_totals_on_insert ON public.orders IS 
  'Garante que totais do pedido seguem regras do servidor, não apenas valores do cliente';
