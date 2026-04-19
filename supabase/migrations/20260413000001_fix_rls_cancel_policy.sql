-- ============================================================
-- Migration: Fix RLS Cancel Policy and Add Immutability Trigger
-- ============================================================
-- Data: 2026-04-13
-- Descrição: Corrige a política RLS de cancelamento removendo
--            referências inválidas a OLD no WITH CHECK e adiciona
--            trigger para validar imutabilidade de campos monetários
-- ============================================================

-- Remover política antiga com sintaxe inválida
DROP POLICY IF EXISTS "Users can cancel own orders" ON public.orders;

-- Criar política simplificada de cancelamento
CREATE POLICY "Users can cancel own orders"
  ON public.orders FOR UPDATE TO authenticated
  USING (
    auth.uid() = user_id 
    AND status IN ('pending', 'processing')
  )
  WITH CHECK (
    auth.uid() = user_id 
    AND status = 'cancelled'
  );

-- Função para validar imutabilidade de campos monetários no cancelamento
CREATE OR REPLACE FUNCTION public.validate_order_immutable_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  -- Se está cancelando, validar que campos monetários não mudaram
  IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    IF (NEW.subtotal IS DISTINCT FROM OLD.subtotal) OR
       (NEW.shipping IS DISTINCT FROM OLD.shipping) OR
       (NEW.total IS DISTINCT FROM OLD.total) OR
       (NEW.discount IS DISTINCT FROM OLD.discount) OR
       (NEW.address_id IS DISTINCT FROM OLD.address_id) OR
       (NEW.payment_method_id IS DISTINCT FROM OLD.payment_method_id) THEN
      RAISE EXCEPTION 'Cannot modify order financial details during cancellation';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger para validar imutabilidade
CREATE TRIGGER trg_validate_order_immutable_fields
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled' AND OLD.status != 'cancelled')
  EXECUTE FUNCTION public.validate_order_immutable_fields();

-- ============================================================
-- Comentários
-- ============================================================
COMMENT ON POLICY "Users can cancel own orders" ON public.orders IS 
  'Permite usuários cancelarem seus próprios pedidos em status pending ou processing';

COMMENT ON FUNCTION public.validate_order_immutable_fields() IS 
  'Valida que campos financeiros e de pagamento não sejam alterados durante cancelamento';

COMMENT ON TRIGGER trg_validate_order_immutable_fields ON public.orders IS 
  'Garante imutabilidade de campos críticos ao cancelar pedido';
