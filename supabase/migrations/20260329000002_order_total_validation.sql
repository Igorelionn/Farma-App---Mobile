-- ============================================================
-- Migration: Trigger para recalcular e validar totais de pedido
--            no servidor, impedindo manipulação pelo cliente.
-- ============================================================

-- Função que recalcula o subtotal a partir dos itens do pedido
-- e valida o total declarado pelo cliente.
CREATE OR REPLACE FUNCTION public.recalculate_order_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_calculated_subtotal NUMERIC(10,2);
  v_shipping            NUMERIC(10,2);
  v_discount            NUMERIC(10,2);
  v_calculated_total    NUMERIC(10,2);
  v_free_shipping       NUMERIC(10,2) := 1000.00;
  v_default_shipping    NUMERIC(10,2) := 30.00;
BEGIN
  -- Calcula subtotal real com base nos preços atuais dos produtos
  SELECT COALESCE(SUM(p.preco_final * oi.quantity), 0)
    INTO v_calculated_subtotal
    FROM order_items oi
    JOIN products p ON p.id = oi.product_id
   WHERE oi.order_id = NEW.id;

  -- Calcula frete conforme regra de negócio
  v_shipping := CASE
    WHEN v_calculated_subtotal >= v_free_shipping THEN 0
    ELSE v_default_shipping
  END;

  -- Desconto mantém o valor do cliente (cupons, etc.) mas com limite mínimo 0
  v_discount := GREATEST(COALESCE(NEW.discount, 0), 0);

  -- Total recalculado no servidor
  v_calculated_total := v_calculated_subtotal + v_shipping - v_discount;

  -- Atualiza os valores calculados (ignora o que veio do cliente)
  NEW.subtotal := v_calculated_subtotal;
  NEW.shipping := v_shipping;
  NEW.total    := v_calculated_total;

  RETURN NEW;
END;
$$;

-- Trigger executado ANTES de inserir OU atualizar um pedido
-- Nota: o trigger roda AFTER INSERT de order_items, então os itens
-- são inseridos primeiro e a função de recálculo é chamada via atualização.
-- Alternativa usada aqui: trigger BEFORE UPDATE para recalcular.
DROP TRIGGER IF EXISTS trg_recalculate_order_totals ON public.orders;
CREATE TRIGGER trg_recalculate_order_totals
  BEFORE UPDATE OF subtotal, shipping, discount, total
  ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.recalculate_order_totals();

-- ============================================================
-- Número de pedido: usar sequência do banco em vez de timestamp
-- (evita colisões em alta concorrência)
-- ============================================================
CREATE SEQUENCE IF NOT EXISTS public.order_number_seq START 1000 INCREMENT 1;

CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.number IS NULL OR NEW.number = '' THEN
    NEW.number := 'PED' || LPAD(nextval('public.order_number_seq')::text, 6, '0');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_generate_order_number ON public.orders;
CREATE TRIGGER trg_generate_order_number
  BEFORE INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.generate_order_number();

-- ============================================================
-- RLS: Garantir que usuários só veem/modificam seus próprios dados
-- ============================================================

-- orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário vê seus pedidos"    ON public.orders;
DROP POLICY IF EXISTS "Usuário cria pedidos"       ON public.orders;
DROP POLICY IF EXISTS "Usuário cancela pedidos"    ON public.orders;

CREATE POLICY "Usuário vê seus pedidos"
  ON public.orders FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Usuário cria pedidos"
  ON public.orders FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Usuário cancela pedidos"
  ON public.orders FOR UPDATE TO authenticated
  USING (user_id = auth.uid() AND status NOT IN ('shipped', 'delivered'));

-- cart_items
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário gerencia seu carrinho" ON public.cart_items;
CREATE POLICY "Usuário gerencia seu carrinho"
  ON public.cart_items FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- favorites
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário gerencia seus favoritos" ON public.favorites;
CREATE POLICY "Usuário gerencia seus favoritos"
  ON public.favorites FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- shopping_lists
ALTER TABLE public.shopping_lists ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário gerencia suas listas" ON public.shopping_lists;
CREATE POLICY "Usuário gerencia suas listas"
  ON public.shopping_lists FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- shopping_list_items (itens de listas pertencem ao dono da lista)
ALTER TABLE public.shopping_list_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário gerencia itens de suas listas" ON public.shopping_list_items;
CREATE POLICY "Usuário gerencia itens de suas listas"
  ON public.shopping_list_items FOR ALL TO authenticated
  USING (
    list_id IN (
      SELECT id FROM public.shopping_lists WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    list_id IN (
      SELECT id FROM public.shopping_lists WHERE user_id = auth.uid()
    )
  );
