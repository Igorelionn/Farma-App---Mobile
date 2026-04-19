import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  validateSyncSecret,
  createErrorResponse,
  createSuccessResponse,
  checkRateLimit
} from '../_shared/validation.ts';

const SYNC_SECRET = Deno.env.get('SYNC_SECRET') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const GOOGLE_SHEET_WEBHOOK_URL = Deno.env.get('GOOGLE_SHEET_WEBHOOK_URL') || '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-sync-secret, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface ProductUpdatePayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  record?: any;
  old_record?: any;
}

function validatePayload(body: unknown): { success: boolean; data?: ProductUpdatePayload; error?: string } {
  if (!body || typeof body !== 'object') {
    return { success: false, error: 'Invalid request body' };
  }
  
  const payload = body as Record<string, unknown>;
  
  if (!payload.type || typeof payload.type !== 'string') {
    return { success: false, error: 'Missing or invalid type' };
  }
  
  if (!['INSERT', 'UPDATE', 'DELETE'].includes(payload.type as string)) {
    return { success: false, error: 'Invalid type. Must be INSERT, UPDATE, or DELETE' };
  }
  
  if (!payload.table || typeof payload.table !== 'string') {
    return { success: false, error: 'Missing or invalid table' };
  }
  
  return { success: true, data: payload as ProductUpdatePayload };
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Rate limiting
    const rateLimitResponse = checkRateLimit(req, corsHeaders);
    if (rateLimitResponse) {
      return rateLimitResponse;
    }

    // Validar secret
    const secretValidation = validateSyncSecret(req, SYNC_SECRET);
    if (!secretValidation.success) {
      return createErrorResponse(secretValidation.error, 401, corsHeaders);
    }

    // Validar payload
    const body = await req.json();
    const payloadValidation = validatePayload(body);
    if (!payloadValidation.success) {
      return createErrorResponse(payloadValidation.error, 400, corsHeaders);
    }

    const payload = payloadValidation.data!;
    
    console.log('📦 Received webhook payload:', payload.type, payload.table);

    // Ignorar se não for da tabela products
    if (payload.table !== 'products') {
      return createSuccessResponse(
        { success: true, message: 'Ignored non-product table' },
        corsHeaders
      );
    }

    if (!GOOGLE_SHEET_WEBHOOK_URL) {
      console.warn('⚠️ GOOGLE_SHEET_WEBHOOK_URL not configured');
      // Log como erro quando configuração está faltando
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
      await supabase.from('sync_log').insert({
        source: 'supabase_to_excel',
        action: 'config_error',
        records_affected: 0,
        status: 'error',
        error_message: 'GOOGLE_SHEET_WEBHOOK_URL not configured',
      });
      
      return createErrorResponse(
        'Google Sheet webhook not configured',
        500,
        corsHeaders
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    // Preparar dados para enviar ao Google Sheet
    let sheetData: any = null;
    
    if (payload.type === 'UPDATE' || payload.type === 'INSERT') {
      const record = payload.record;
      
      if (!record) {
        return createErrorResponse('Missing record for UPDATE/INSERT', 400, corsHeaders);
      }
      
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
    if (sheetData) {
      console.log('📤 Sending to Google Sheet:', sheetData.action);
      
      // Enviar secret no header (mais seguro que query string)
      const sheetResponse = await fetch(GOOGLE_SHEET_WEBHOOK_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-sync-secret': SYNC_SECRET,
        },
        body: JSON.stringify(sheetData),
      });

      console.log('📥 Response status:', sheetResponse.status);

      if (!sheetResponse.ok) {
        console.error('❌ Google Sheet update failed with status:', sheetResponse.status);
        throw new Error(`Google Sheet update failed with status ${sheetResponse.status}`);
      }

      console.log('✅ Google Sheet updated successfully');
    }

    // Log da sincronização
    await supabase.from('sync_log').insert({
      source: 'supabase_to_excel',
      action: `${payload.type.toLowerCase()}_product`,
      records_affected: 1,
      status: 'success',
    });

    return createSuccessResponse(
      { success: true, synced_to_sheet: true },
      corsHeaders
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

    return createErrorResponse(err, 500, corsHeaders);
  }
});
