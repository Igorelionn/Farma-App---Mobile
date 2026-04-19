import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  validateSyncSecret,
  validateGetProductUpdatesParams,
  createErrorResponse,
  createSuccessResponse,
  checkRateLimit
} from '../_shared/validation.ts';

const SYNC_SECRET = Deno.env.get('SYNC_SECRET') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-sync-secret, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
};

// Retorna produtos alterados recentemente usando os mesmos nomes
// de coluna da planilha do cliente (CÓDIGO, DESCRIÇÃO, etc.)
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

    // Validar parâmetros
    const url = new URL(req.url);
    const paramsValidation = validateGetProductUpdatesParams(url);
    if (!paramsValidation.success) {
      return createErrorResponse(paramsValidation.error, 400, corsHeaders);
    }

    const params = paramsValidation.data!;
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    let query = supabase
      .from('products')
      .select('id, excel_row_id, nome, laboratorio, preco, estoque, codigo_barras, unidade, classificacao_fiscal, imagem_url, disponivel, updated_at, categories(nome)')
      .order('updated_at', { ascending: false })
      .limit(1000); // Máximo de 1000 registros

    if (!params.all && params.since) {
      query = query.gt('updated_at', params.since);
    }

    if (!params.all && !params.since) {
      const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
      query = query.gt('updated_at', fiveMinAgo);
    }

    const { data, error } = await query;
    if (error) throw error;

    const products = (data || []).map((p: any) => ({
      codigo: p.excel_row_id || '',
      descricao: p.nome,
      fabricante: p.laboratorio,
      vlr_unit: p.preco,
      estoque: p.estoque,
      codigo_ean: p.codigo_barras || '',
      und: p.unidade || 'UN',
      class_fiscal: p.classificacao_fiscal || '',
      imagem_url: p.imagem_url || '',
      disponivel: p.disponivel,
      updated_at: p.updated_at,
    }));

    return createSuccessResponse(
      {
        count: products.length,
        timestamp: new Date().toISOString(),
        products,
      },
      corsHeaders
    );

  } catch (err) {
    return createErrorResponse(err, 500, corsHeaders);
  }
});
