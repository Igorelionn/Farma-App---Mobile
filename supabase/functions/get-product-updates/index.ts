import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

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
    const syncSecret = req.headers.get('x-sync-secret');
    if (!SYNC_SECRET || syncSecret !== SYNC_SECRET) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const url = new URL(req.url);
    const since = url.searchParams.get('since');
    const allProducts = url.searchParams.get('all') === 'true';

    let query = supabase
      .from('products')
      .select('id, excel_row_id, nome, laboratorio, preco, estoque, codigo_barras, unidade, classificacao_fiscal, imagem_url, disponivel, updated_at, categories(nome)')
      .order('updated_at', { ascending: false });

    if (!allProducts && since) {
      query = query.gt('updated_at', since);
    }

    if (!allProducts && !since) {
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

    return new Response(
      JSON.stringify({
        count: products.length,
        timestamp: new Date().toISOString(),
        products,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
