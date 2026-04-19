import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  validateSyncSecret,
  validateSearchProductImagesBody,
  createErrorResponse,
  createSuccessResponse,
  checkRateLimit
} from '../_shared/validation.ts';

const SYNC_SECRET = Deno.env.get('SYNC_SECRET') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const GOOGLE_API_KEY = Deno.env.get('GOOGLE_SEARCH_API_KEY') || '';
const SEARCH_ENGINE_ID = Deno.env.get('GOOGLE_SEARCH_ENGINE_ID') || '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-sync-secret, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

async function searchImage(productName: string, manufacturer: string): Promise<string | null> {
  const cleanName = productName
    .replace(/\d+\s*MG|\d+\s*ML|\d+\s*G|C\/\d+|PCT|FR|AMP|CMP|CPR|DRG|ENV|INF|SOL|SUS|XPE/gi, '')
    .trim();

  const query = `${cleanName} ${manufacturer} medicamento embalagem`.trim();

  if (GOOGLE_API_KEY && SEARCH_ENGINE_ID) {
    const url = `https://www.googleapis.com/customsearch/v1?key=${GOOGLE_API_KEY}&cx=${SEARCH_ENGINE_ID}&q=${encodeURIComponent(query)}&searchType=image&num=1&imgSize=medium&safe=active`;

    try {
      const res = await fetch(url);
      const json = await res.json();
      if (json.items && json.items.length > 0) {
        return json.items[0].link;
      }
    } catch (e) {
      console.error(`Search error for "${productName}":`, e);
    }
  }

  return null;
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

    if (!GOOGLE_API_KEY || !SEARCH_ENGINE_ID) {
      return createErrorResponse(
        'Google Search API not configured. Set GOOGLE_SEARCH_API_KEY and GOOGLE_SEARCH_ENGINE_ID',
        400,
        corsHeaders
      );
    }

    // Validar body
    const body = await req.json();
    const paramsValidation = validateSearchProductImagesBody(body);
    if (!paramsValidation.success) {
      return createErrorResponse(paramsValidation.error, 400, corsHeaders);
    }

    const { limit, offset } = paramsValidation.data!;
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: products, error } = await supabase
      .from('products')
      .select('id, nome, laboratorio')
      .is('imagem_url', null)
      .order('nome')
      .range(offset, offset + limit - 1);

    if (error) throw error;
    if (!products || products.length === 0) {
      return createSuccessResponse(
        { message: 'No products without images found', updated: 0 },
        corsHeaders
      );
    }

    let updated = 0;
    const results: { nome: string; image_url: string | null }[] = [];

    for (const product of products) {
      const imageUrl = await searchImage(product.nome, product.laboratorio || '');

      if (imageUrl) {
        const { error: updateError } = await supabase
          .from('products')
          .update({ imagem_url: imageUrl })
          .eq('id', product.id);

        if (!updateError) updated++;
      }

      results.push({ nome: product.nome, image_url: imageUrl });

      // Small delay between requests
      await new Promise(r => setTimeout(r, 100));
    }

    return createSuccessResponse(
      {
        processed: products.length,
        updated,
        remaining_without_images: 'run again with offset=' + (offset + limit),
        results,
      },
      corsHeaders
    );

  } catch (err) {
    return createErrorResponse(err, 500, corsHeaders);
  }
});
