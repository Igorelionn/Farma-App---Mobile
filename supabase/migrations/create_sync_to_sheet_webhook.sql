-- SQL para criar o webhook que sincroniza mudanças do Supabase para o Google Sheet

-- Primeiro, vamos criar o webhook usando o supabase_functions schema
-- Este webhook será chamado automaticamente quando houver INSERT, UPDATE ou DELETE na tabela products

-- Para configurar o webhook, você precisará executar este comando no Dashboard do Supabase:
-- 1. Vá em Database > Webhooks
-- 2. Clique em "Create a new webhook"
-- 3. Configure:
--    - Name: sync_products_to_sheet
--    - Table: products
--    - Events: INSERT, UPDATE, DELETE
--    - Type: Edge Function
--    - Edge Function: sync-to-sheet
--    - HTTP Headers: (se necessário adicionar x-sync-secret)

-- Alternativamente, você pode usar o SQL abaixo para criar um trigger que chama a Edge Function via HTTP:

-- Criar função que notifica mudanças
CREATE OR REPLACE FUNCTION notify_product_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Apenas log por enquanto, webhook deve ser configurado via Dashboard
  INSERT INTO sync_log (source, action, records_affected, status)
  VALUES (
    'trigger_to_sheet',
    TG_OP || '_product',
    1,
    'pending'
  );
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Criar trigger na tabela products
DROP TRIGGER IF EXISTS products_sync_to_sheet_trigger ON products;
CREATE TRIGGER products_sync_to_sheet_trigger
  AFTER INSERT OR UPDATE OR DELETE ON products
  FOR EACH ROW
  EXECUTE FUNCTION notify_product_change();

-- Verificar triggers existentes
SELECT 
  trigger_name,
  event_manipulation,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE event_object_table = 'products'
ORDER BY trigger_name;
