import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SYNC_SECRET = Deno.env.get('SYNC_SECRET') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const GOOGLE_SHEET_WEBHOOK_URL = Deno.env.get('GOOGLE_SHEET_WEBHOOK_URL') || '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface ProductUpdatePayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  record?: any;
  old_record?: any;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Validar autenticação via x-sync-secret header
    const syncSecret = req.headers.get('x-sync-secret');
    if (!SYNC_SECRET || syncSecret !== SYNC_SECRET) {
      console.warn('⚠️ Unauthorized access attempt');
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const payload: ProductUpdatePayload = await req.json();
    
    console.log('📦 Received webhook payload:', payload.type, payload.table);

    // Ignorar se não for da tabela products
    if (payload.table !== 'products') {
      return new Response(
        JSON.stringify({ success: true, message: 'Ignored non-product table' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!GOOGLE_SHEET_WEBHOOK_URL) {
      console.warn('⚠️ GOOGLE_SHEET_WEBHOOK_URL not configured');
      return new Response(
        JSON.stringify({ success: false, message: 'Google Sheet webhook not configured' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    // Preparar dados para enviar ao Google Sheet
    let sheetData: any = null;
    
    if (payload.type === 'UPDATE' || payload.type === 'INSERT') {
      const record = payload.record;
      
      // Buscar categoria do produto se necessário
      if (record.category_id) {
        const { data: category } = await supabase
          .from('categories')
          .select('nome')
          .eq('id', record.category_id)
          .single();
        
        record.categoria_nome = category?.nome || 'Outros';
      }
      
      sheetData = {
        action: payload.type.toLowerCase(),
        product: {
          codigo: record.excel_row_id || '',
          descricao: record.nome || '',
          fabricante: record.laboratorio || '',
          vlr_unit: record.preco || 0,
          estoque: record.estoque || 0,
          codigo_ean: record.codigo_barras || '',
          und: record.unidade || 'UN',
          class_fiscal: record.classificacao_fiscal || '',
          disponivel: record.disponivel !== false,
          categoria: record.categoria_nome || 'Outros',
        }
      };
    } else if (payload.type === 'DELETE') {
      sheetData = {
        action: 'delete',
        product: {
          codigo: payload.old_record?.excel_row_id || '',
        }
      };
    }

    // Enviar para Google Sheet
    if (sheetData && GOOGLE_SHEET_WEBHOOK_URL) {
      console.log('📤 Sending to Google Sheet:', sheetData.action);
      
      // Google Apps Script precisa do secret como parâmetro de URL
      const urlWithSecret = `${GOOGLE_SHEET_WEBHOOK_URL}?secret=${encodeURIComponent(SYNC_SECRET)}`;
      // NÃO logar a URL completa com o secret em produção
      
      const sheetResponse = await fetch(urlWithSecret, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(sheetData),
      });

      const responseText = await sheetResponse.text();
      console.log('📥 Response status:', sheetResponse.status);

      if (!sheetResponse.ok) {
        console.error('❌ Google Sheet update failed with status:', sheetResponse.status);
        // Não logar o corpo completo da resposta que pode conter dados sensíveis
        throw new Error(`Google Sheet update failed with status ${sheetResponse.status}`);
      }

      console.log('✅ Google Sheet updated successfully');
    } else {
      console.warn('⚠️ Not sending - missing configuration');
    }

    // Log da sincronização
    await supabase.from('sync_log').insert({
      source: 'supabase_to_excel',
      action: `${payload.type.toLowerCase()}_product`,
      records_affected: 1,
      status: 'success',
    });

    return new Response(
      JSON.stringify({ success: true, synced_to_sheet: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('❌ Internal error:', err);
    
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    await supabase.from('sync_log').insert({
      source: 'supabase_to_excel',
      action: 'error',
      records_affected: 0,
      status: 'error',
      error_message: err instanceof Error ? err.message : 'Unknown error',
    });

    // Não expor detalhes do erro ao cliente
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
