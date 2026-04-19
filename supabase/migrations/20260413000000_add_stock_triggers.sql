-- ============================================================
-- Migration: Add Stock Control Triggers
-- ============================================================
-- Data: 2026-04-13
-- Descrição: Conecta as funções de controle de estoque aos triggers
--            para reduzir estoque ao criar itens e restaurar ao cancelar
-- ============================================================

-- Trigger para reduzir estoque quando item de pedido é inserido
CREATE TRIGGER trg_reduce_stock_on_order_item
  AFTER INSERT ON public.order_items
  FOR EACH ROW
  EXECUTE FUNCTION public.reduce_stock_on_order_item();

-- Trigger para restaurar estoque quando pedido é cancelado
CREATE TRIGGER trg_restore_stock_on_cancel
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled' AND OLD.status != 'cancelled')
  EXECUTE FUNCTION public.restore_stock_on_cancel();

-- ============================================================
-- Comentários
-- ============================================================
COMMENT ON TRIGGER trg_reduce_stock_on_order_item ON public.order_items IS 
  'Reduz o estoque do produto quando um item é adicionado ao pedido';

COMMENT ON TRIGGER trg_restore_stock_on_cancel ON public.orders IS 
  'Restaura o estoque dos produtos quando um pedido é cancelado';
