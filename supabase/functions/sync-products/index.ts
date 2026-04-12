import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SYNC_SECRET = Deno.env.get('SYNC_SECRET') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-sync-secret, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// Mapeamento direto das colunas da planilha do cliente:
// CLASS.FISCAL -> class_fiscal
// CÓDIGO -> codigo (usado como excel_row_id)
// CODIGO EAN -> codigo_ean
// DESCRIÇÃO -> descricao
// UND -> und
// FABRICANTE -> fabricante
// ESTOQUE -> estoque
// VLR. UNIT -> vlr_unit
interface ProductPayload {
  codigo: string;
  descricao: string;
  fabricante?: string;
  vlr_unit?: number;
  estoque?: number;
  codigo_ean?: string;
  und?: string;
  class_fiscal?: string;
  imagem_url?: string;
}

interface SyncPayload {
  action: 'upsert' | 'delete' | 'bulk_sync';
  product?: ProductPayload;
  products?: ProductPayload[];
}

function categorizeProduct(nome: string): string {
  const nomeLower = nome.toLowerCase();
  
  // 1. INJETÁVEIS
  if (/injetav|ampola|soro|solucao injetavel|injecao|seringa preenchida|sol inj|amp|benzilpenicilina|penicilina/.test(nomeLower)) {
    return 'Injetáveis';
  }
  
  // 2. MATERIAL HOSPITALAR
  if (/gaze|luva|seringa|agulha|cateter|sonda|curativo|atadura|esparadrapo|micropore|algodao|compressa|escalpe|jelco|abocath|equipo|extensor|torneirinha|conector|coletor|bolsa coletora|bolsa colos|bolsa de colos|mascara cirurgica|avental|touca|pro-pe|termometro|estetoscopio|esfigmomanometro|oximetro|bisturi|pinca|tesoura|campo cirurgico|fio cirurgico|fio nylon|fio de nylon|lamina|portaagulha|abaixador de lingua|especulo|espatula|eletrodo|catgut|filtro hmef|colar cervical|espacador|fita adesiva|fita microp|garrote|inc. urinaria|kit citologia|lanceta|malha tubular|mononylon|nylon preto|oculos de protecao|papel crepado|papel grau cirurgico|papel lencol|polipropileno|prancha|preservativo|prope descart|protetor facial|regua de gases|scalp|speedicath|teste hcg|teste de gravidez|tira teste|tubo endotraqueal|vicry|bota de unna/.test(nomeLower)) {
    return 'Material Hospitalar';
  }
  
  // 3. EQUIPAMENTOS E NUTRIÇÃO
  if (/dieta|nutri|suplemento|bomba de infusao|monitor|cardioversor|desfibrilador|eletrocardiografo|nebulizador|inalador|concentrador|ventilador|bisturi eletrico|foco cirurgico|mesa|maca|cadeira|andador|muleta|bengala|aparelho|balanca|bebedouro|purificador|escada|exercitador|filme p\/rx|bota tam|negatoscopio|no-break|otoscopio|palete|pilha|televisor|tens e fes|serra/.test(nomeLower)) {
    return 'Equipamentos e Nutrição';
  }
  
  // 4. HIGIENE E DERMOCOSMÉTICOS
  if (/fralda|sabonete|shampoo|condicionador|locao|oleo|protetor solar|repelente|desodorante|absorvente|papel higienico|lenco|toalha|escova|fio dental|enxaguatorio/.test(nomeLower)) {
    return 'Higiene e Dermocosméticos';
  }
  
  // 5. LIMPEZA E DESINFECÇÃO
  if (/alcool|desinfetante|detergente|sabao|hipoclorito|agua sanitaria|limpador|desinfeccao|esterilizante|bactericida|germicida|quaternario|clorexidina|glutaraldeido|formol|pvpi|agua deionizada|eter etilico/.test(nomeLower)) {
    return 'Limpeza e Desinfecção';
  }
  
  // 6. MEDICAMENTOS (padrão para produtos com indicação medicamentosa)
  if (/mg|mcg|comprimido|capsula|draga|xarope|suspensao|gotas|solucao oral|coliro|vitamina|antibiotico|analgesico|creme|pomada|gel|complexo b|carbon de calc|levonog|sulfadiazina|polivitaminico|sais para reidratacao|troponina/.test(nomeLower) || /[0-9]+(mg|mcg|ml|g)/i.test(nome)) {
    return 'Medicamentos';
  }
  
  // Padrão: Medicamentos (pois a maioria dos produtos são medicamentos)
  return 'Medicamentos';
}

function mapProduct(p: ProductPayload) {
  return {
    p_excel_row_id: String(p.codigo || ''),
    p_nome: p.descricao || '',
    p_principio_ativo: null,
    p_laboratorio: p.fabricante || '',
    p_preco: p.vlr_unit || 0,
    p_apresentacao: p.und || 'UN',
    p_estoque: Math.floor(Number(p.estoque) || 0),
    p_categoria_nome: categorizeProduct(p.descricao || ''),
    p_imagem_url: p.imagem_url || null,
    p_tarja: null,
    p_descricao: null,
    p_disponivel: true,
    p_codigo_barras: p.codigo_ean ? String(p.codigo_ean) : null,
    p_em_promocao: false,
    p_preco_promocional: null,
    p_unidade: p.und || 'UN',
    p_classificacao_fiscal: p.class_fiscal ? String(p.class_fiscal) : null,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const syncSecret = req.headers.get('x-sync-secret');
    if (!SYNC_SECRET || syncSecret !== SYNC_SECRET) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const payload: SyncPayload = await req.json();

    if (payload.action === 'upsert' && payload.product) {
      const params = mapProduct(payload.product);
      const { data, error } = await supabase.rpc('upsert_product_from_excel', params);
      if (error) throw error;

      return new Response(
        JSON.stringify({ success: true, product_id: data, action: 'upsert' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (payload.action === 'bulk_sync' && payload.products) {
      const productsJson = payload.products.map(p => ({
        excel_row_id: String(p.codigo || ''),
        nome: p.descricao || '',
        laboratorio: p.fabricante || '',
        preco: p.vlr_unit || 0,
        estoque: Math.floor(Number(p.estoque) || 0), // Garantir que seja inteiro
        codigo_barras: p.codigo_ean ? String(p.codigo_ean) : null,
        unidade: p.und || 'UN',
        classificacao_fiscal: p.class_fiscal ? String(p.class_fiscal) : null,
        imagem_url: p.imagem_url || null,
        apresentacao: p.und || 'UN',
        categoria: categorizeProduct(p.descricao || ''),
        disponivel: true,
      }));

      const { data, error } = await supabase.rpc('bulk_sync_products_from_excel', {
        p_products: productsJson,
      });
      if (error) throw error;

      return new Response(
        JSON.stringify({ success: true, synced_count: data, action: 'bulk_sync' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (payload.action === 'delete' && payload.product?.codigo) {
      const { error } = await supabase
        .from('products')
        .update({ disponivel: false })
        .eq('excel_row_id', String(payload.product.codigo));
      if (error) throw error;

      await supabase.from('sync_log').insert({
        source: 'excel_online',
        action: 'delete_product',
        records_affected: 1,
        status: 'success',
      });

      return new Response(
        JSON.stringify({ success: true, action: 'delete' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ error: 'Invalid payload' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    await supabase.from('sync_log').insert({
      source: 'excel_online',
      action: 'error',
      records_affected: 0,
      status: 'error',
      error_message: err.message || String(err),
    });

    return new Response(
      JSON.stringify({ error: err.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
