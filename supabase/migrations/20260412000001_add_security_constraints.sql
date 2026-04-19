-- ============================================================
-- Migration: Add Security Constraints and Refine RLS Policies
-- ============================================================
-- Data: 2026-04-12
-- Descrição: Adiciona constraints CHECK e refina políticas RLS
--            para prevenir manipulação de dados
-- ============================================================

-- ============================================================
-- PARTE 1: Constraints CHECK
-- ============================================================

-- 1.1 orders: validar valores positivos
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'check_positive_amounts' AND conrelid = 'public.orders'::regclass
  ) THEN
    ALTER TABLE public.orders ADD CONSTRAINT check_positive_amounts 
      CHECK (subtotal >= 0 AND shipping >= 0 AND discount >= 0 AND total >= 0);
  END IF;
END $$;

-- 1.2 order_items: quantidade e preços válidos
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'check_valid_order_item' AND conrelid = 'public.order_items'::regclass
  ) THEN
    ALTER TABLE public.order_items ADD CONSTRAINT check_valid_order_item 
      CHECK (quantity > 0 AND unit_price >= 0 AND subtotal >= 0);
  END IF;
END $$;

-- 1.3 products: valores válidos
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'check_valid_product_values' AND conrelid = 'public.products'::regclass
  ) THEN
    ALTER TABLE public.products ADD CONSTRAINT check_valid_product_values 
      CHECK (preco >= 0 AND estoque >= 0);
  END IF;
END $$;

-- ============================================================
-- PARTE 2: Função para validar ownership de address/payment
-- ============================================================

CREATE OR REPLACE FUNCTION public.validate_order_ownership()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  -- Verificar se address pertence ao user
  IF NOT EXISTS (
    SELECT 1 FROM public.addresses 
    WHERE id = NEW.address_id AND user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'Address does not belong to user';
  END IF;
  
  -- payment_methods é global - validar apenas se está ativo
  IF NEW.payment_method_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.payment_methods 
      WHERE id = NEW.payment_method_id
    ) THEN
      RAISE EXCEPTION 'Invalid payment method';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger para validar ownership antes de INSERT
DROP TRIGGER IF EXISTS trg_validate_order_ownership ON public.orders;
CREATE TRIGGER trg_validate_order_ownership
  BEFORE INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_order_ownership();

-- ============================================================
-- PARTE 3: Refinar política de UPDATE em orders
-- ============================================================

-- Remover política antiga e criar nova mais restritiva
DROP POLICY IF EXISTS "Users can cancel own orders" ON public.orders;
DROP POLICY IF EXISTS "Usuário cancela pedidos" ON public.orders;

CREATE POLICY "Users can cancel own orders"
  ON public.orders FOR UPDATE TO authenticated
  USING (
    auth.uid() = user_id 
    AND status IN ('pending', 'processing')
  )
  WITH CHECK (
    auth.uid() = user_id 
    AND status = 'cancelled'  -- Só pode mudar para cancelled
    AND (
      -- Permitir atualização de discount e notes
      (OLD.subtotal IS NOT DISTINCT FROM subtotal)
      AND (OLD.shipping IS NOT DISTINCT FROM shipping)
      AND (OLD.total IS NOT DISTINCT FROM total)
      AND (OLD.address_id IS NOT DISTINCT FROM address_id)
      AND (OLD.payment_method_id IS NOT DISTINCT FROM payment_method_id)
    )
  );

-- ============================================================
-- PARTE 4: Proteger profiles de auto-elevação
-- ============================================================

-- Remover política antiga e criar nova mais restritiva
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Usuário pode atualizar próprio perfil" ON public.profiles;

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id 
    AND role = OLD.role  -- Não pode mudar role
    AND status = OLD.status  -- Não pode mudar status
    AND approved_by IS NOT DISTINCT FROM OLD.approved_by  -- Não pode mudar approved_by
    -- Pode atualizar outros campos normalmente (nome, empresa, telefone, etc.)
  );

-- ============================================================
-- PARTE 5: Adicionar políticas para order_items com validação
-- ============================================================

-- Garantir que order_items só podem ser criados para pedidos do próprio usuário
DROP POLICY IF EXISTS "Users can insert own order items" ON public.order_items;
DROP POLICY IF EXISTS "Usuários inserem próprios itens" ON public.order_items;

CREATE POLICY "Users can insert own order items"
  ON public.order_items FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id 
        AND orders.user_id = auth.uid()
        AND orders.status = 'pending'  -- Só pode adicionar itens em pedidos pendentes
    )
  );

-- ============================================================
-- PARTE 6: Adicionar política para order_status_history
-- ============================================================

-- Garantir que apenas o próprio usuário ou admin pode ver histórico
DROP POLICY IF EXISTS "Users can view own order history" ON public.order_status_history;
DROP POLICY IF EXISTS "Usuários veem próprio histórico" ON public.order_status_history;

CREATE POLICY "Users can view own order history"
  ON public.order_status_history FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_status_history.order_id 
        AND orders.user_id = auth.uid()
    )
  );

-- Histórico só pode ser inserido por sistema (triggers) ou admins
DROP POLICY IF EXISTS "Users can add own order status" ON public.order_status_history;
DROP POLICY IF EXISTS "Admins can manage order history" ON public.order_status_history;

-- Admins podem gerenciar qualquer histórico
CREATE POLICY "Admins can manage order history"
  ON public.order_status_history FOR ALL TO public
  USING (public.is_admin());

-- Sistema pode inserir (via triggers que rodam como SECURITY DEFINER)
-- Não precisa de política adicional pois triggers com SECURITY DEFINER bypassa RLS

-- ============================================================
-- PARTE 7: Adicionar índice composto para performance
-- ============================================================

-- Índice para acelerar queries de RLS em order_status_history
CREATE INDEX IF NOT EXISTS idx_order_status_history_lookup 
  ON public.order_status_history(order_id, created_at DESC);

-- Índice para acelerar verificação de ownership em addresses
CREATE INDEX IF NOT EXISTS idx_addresses_user_id 
  ON public.addresses(user_id, id);

-- ============================================================
-- Verificação
-- ============================================================
-- Para verificar as constraints criadas:
-- SELECT conname, contype, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid IN ('public.orders'::regclass, 'public.order_items'::regclass, 'public.products'::regclass)
--   AND contype = 'c';
--
-- Para verificar as políticas:
-- SELECT schemaname, tablename, policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE schemaname = 'public' 
--   AND tablename IN ('orders', 'profiles', 'order_items', 'order_status_history')
-- ORDER BY tablename, policyname;
-- ============================================================
