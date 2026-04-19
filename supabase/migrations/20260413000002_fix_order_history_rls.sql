-- ============================================================
-- Migration: Fix Order Status History RLS
-- ============================================================
-- Data: 2026-04-13
-- Descrição: Permite usuários inserirem histórico em seus próprios
--            pedidos, mantendo admin com acesso total
-- ============================================================

-- Remover política restritiva existente se houver
DROP POLICY IF EXISTS "Users can add own order status" ON public.order_status_history;

-- Criar política para usuários inserirem histórico de seus pedidos
CREATE POLICY "Users can insert own order history"
  ON public.order_status_history FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_status_history.order_id 
        AND orders.user_id = auth.uid()
    )
  );

-- Política de visualização já existe ("Users can view own order history")
-- Política de admin já existe ("Admins can manage order history")

-- ============================================================
-- Comentários
-- ============================================================
COMMENT ON POLICY "Users can insert own order history" ON public.order_status_history IS 
  'Permite usuários inserirem histórico de status em seus próprios pedidos';
