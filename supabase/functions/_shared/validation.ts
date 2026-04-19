// ============================================================
// Shared Validation & Error Handling for Supabase Edge Functions
// ============================================================

// Tipos base para validação
export interface ValidationResult<T> {
  success: boolean;
  data?: T;
  error?: string;
}

// ============================================================
// SECRET VALIDATION
// ============================================================

export function validateSyncSecret(
  request: Request,
  expectedSecret: string
): ValidationResult<boolean> {
  const providedSecret = request.headers.get('x-sync-secret');
  
  if (!expectedSecret) {
    console.error('❌ SYNC_SECRET not configured');
    return { success: false, error: 'Server configuration error' };
  }
  
  if (!providedSecret || providedSecret !== expectedSecret) {
    console.warn('⚠️ Unauthorized access attempt');
    return { success: false, error: 'Unauthorized' };
  }
  
  return { success: true, data: true };
}

// ============================================================
// INPUT VALIDATION - SYNC PRODUCTS
// ============================================================

export interface ProductInput {
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

export interface SyncProductsPayload {
  action: 'upsert' | 'bulk_sync' | 'delete';
  products?: ProductInput[];
  codigo?: string;
}

export function validateSyncProductsPayload(
  body: unknown
): ValidationResult<SyncProductsPayload> {
  if (!body || typeof body !== 'object') {
    return { success: false, error: 'Invalid request body' };
  }
  
  const payload = body as Record<string, unknown>;
  
  // Validar action
  const action = payload.action;
  if (!action || typeof action !== 'string') {
    return { success: false, error: 'Missing or invalid action' };
  }
  
  if (!['upsert', 'bulk_sync', 'delete'].includes(action)) {
    return { success: false, error: 'Invalid action. Must be: upsert, bulk_sync, or delete' };
  }
  
  // Validar products array para bulk_sync e upsert
  if (action === 'bulk_sync' || action === 'upsert') {
    const products = payload.products;
    
    if (!Array.isArray(products)) {
      return { success: false, error: 'Products must be an array' };
    }
    
    if (products.length === 0) {
      return { success: false, error: 'Products array cannot be empty' };
    }
    
    if (products.length > 100) {
      return { success: false, error: 'Too many products. Maximum 100 per request' };
    }
    
    // Validar cada produto
    for (let i = 0; i < products.length; i++) {
      const product = products[i];
      
      if (!product || typeof product !== 'object') {
        return { success: false, error: `Invalid product at index ${i}` };
      }
      
      const p = product as Record<string, unknown>;
      
      // Validar campos obrigatórios
      if (!p.codigo || typeof p.codigo !== 'string' || p.codigo.length === 0) {
        return { success: false, error: `Missing or invalid codigo at index ${i}` };
      }
      
      if (p.codigo.length > 100) {
        return { success: false, error: `Codigo too long at index ${i} (max 100 chars)` };
      }
      
      if (!p.descricao || typeof p.descricao !== 'string' || p.descricao.length === 0) {
        return { success: false, error: `Missing or invalid descricao at index ${i}` };
      }
      
      if (p.descricao.length > 500) {
        return { success: false, error: `Descricao too long at index ${i} (max 500 chars)` };
      }
      
      // Validar tipos de campos opcionais
      if (p.vlr_unit !== undefined && typeof p.vlr_unit !== 'number') {
        return { success: false, error: `Invalid vlr_unit at index ${i}` };
      }
      
      if (p.estoque !== undefined && typeof p.estoque !== 'number') {
        return { success: false, error: `Invalid estoque at index ${i}` };
      }
      
      if (p.fabricante !== undefined && typeof p.fabricante !== 'string') {
        return { success: false, error: `Invalid fabricante at index ${i}` };
      }
      
      if (p.fabricante && (p.fabricante as string).length > 200) {
        return { success: false, error: `Fabricante too long at index ${i} (max 200 chars)` };
      }
    }
  }
  
  // Validar codigo para delete
  if (action === 'delete') {
    const codigo = payload.codigo;
    if (!codigo || typeof codigo !== 'string' || codigo.length === 0) {
      return { success: false, error: 'Missing or invalid codigo for delete action' };
    }
  }
  
  return { success: true, data: payload as SyncProductsPayload };
}

// ============================================================
// INPUT VALIDATION - GET PRODUCT UPDATES
// ============================================================

export interface GetProductUpdatesParams {
  since?: string;
  all?: boolean;
}

export function validateGetProductUpdatesParams(
  url: URL
): ValidationResult<GetProductUpdatesParams> {
  const since = url.searchParams.get('since');
  const all = url.searchParams.get('all');
  
  const params: GetProductUpdatesParams = {};
  
  if (since) {
    // Validar formato ISO 8601
    const sinceDate = new Date(since);
    if (isNaN(sinceDate.getTime())) {
      return { success: false, error: 'Invalid date format for since parameter. Use ISO 8601' };
    }
    
    // Verificar se não é mais de 90 dias atrás
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
    
    if (sinceDate < ninetyDaysAgo) {
      return { success: false, error: 'Since parameter cannot be more than 90 days in the past' };
    }
    
    params.since = since;
  }
  
  if (all) {
    params.all = all === 'true' || all === '1';
  }
  
  return { success: true, data: params };
}

// ============================================================
// INPUT VALIDATION - SEARCH PRODUCT IMAGES
// ============================================================

export interface SearchProductImagesParams {
  limit: number;
  offset: number;
}

export function validateSearchProductImagesBody(
  body: unknown
): ValidationResult<SearchProductImagesParams> {
  if (!body || typeof body !== 'object') {
    return { success: false, error: 'Invalid request body' };
  }
  
  const payload = body as Record<string, unknown>;
  
  let limit = 10; // default
  let offset = 0; // default
  
  if (payload.limit !== undefined) {
    if (typeof payload.limit !== 'number') {
      return { success: false, error: 'Limit must be a number' };
    }
    
    if (payload.limit < 1 || payload.limit > 50) {
      return { success: false, error: 'Limit must be between 1 and 50' };
    }
    
    limit = Math.floor(payload.limit);
  }
  
  if (payload.offset !== undefined) {
    if (typeof payload.offset !== 'number') {
      return { success: false, error: 'Offset must be a number' };
    }
    
    if (payload.offset < 0) {
      return { success: false, error: 'Offset must be >= 0' };
    }
    
    if (payload.offset > 10000) {
      return { success: false, error: 'Offset too large (max 10000)' };
    }
    
    offset = Math.floor(payload.offset);
  }
  
  return { success: true, data: { limit, offset } };
}

// ============================================================
// ERROR HANDLING
// ============================================================

export interface ErrorResponse {
  error: string;
  details?: string;
}

export function createErrorResponse(
  error: unknown,
  status: number = 500,
  corsHeaders: Record<string, string> = {}
): Response {
  // Log detalhado no servidor
  console.error('❌ Internal error:', error);
  
  // Resposta genérica ao cliente
  const errorResponse: ErrorResponse = {
    error: status === 401 ? 'Unauthorized' :
           status === 400 ? 'Bad request' :
           status === 429 ? 'Too many requests' :
           'Internal server error'
  };
  
  // Em desenvolvimento, pode incluir mais detalhes
  const isDevelopment = Deno.env.get('ENVIRONMENT') === 'development';
  if (isDevelopment && error instanceof Error) {
    errorResponse.details = error.message;
  }
  
  return new Response(
    JSON.stringify(errorResponse),
    {
      status,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    }
  );
}

export function createSuccessResponse(
  data: unknown,
  corsHeaders: Record<string, string> = {}
): Response {
  return new Response(
    JSON.stringify(data),
    {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    }
  );
}

// ============================================================
// RATE LIMITING (Simple in-memory implementation)
// ============================================================

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

class SimpleRateLimiter {
  private storage: Map<string, RateLimitEntry> = new Map();
  private readonly windowMs: number;
  private readonly maxRequests: number;
  
  constructor(windowMs: number = 60000, maxRequests: number = 100) {
    this.windowMs = windowMs;
    this.maxRequests = maxRequests;
    
    // Limpar entradas expiradas a cada 1 minuto
    setInterval(() => this.cleanup(), 60000);
  }
  
  check(identifier: string): { allowed: boolean; remaining: number; resetAt: number } {
    const now = Date.now();
    const entry = this.storage.get(identifier);
    
    if (!entry || entry.resetAt < now) {
      // Nova janela
      const resetAt = now + this.windowMs;
      this.storage.set(identifier, { count: 1, resetAt });
      return { allowed: true, remaining: this.maxRequests - 1, resetAt };
    }
    
    if (entry.count >= this.maxRequests) {
      return { allowed: false, remaining: 0, resetAt: entry.resetAt };
    }
    
    entry.count++;
    return { allowed: true, remaining: this.maxRequests - entry.count, resetAt: entry.resetAt };
  }
  
  private cleanup() {
    const now = Date.now();
    for (const [key, entry] of this.storage.entries()) {
      if (entry.resetAt < now) {
        this.storage.delete(key);
      }
    }
  }
}

// Instância global (compartilhada entre requests na mesma instância)
const globalRateLimiter = new SimpleRateLimiter(60000, 100); // 100 req/min

export function checkRateLimit(
  request: Request,
  corsHeaders: Record<string, string> = {}
): Response | null {
  // Usar IP ou secret como identificador
  const identifier = request.headers.get('x-sync-secret') || 
                     request.headers.get('x-forwarded-for') ||
                     request.headers.get('cf-connecting-ip') ||
                     'unknown';
  
  const result = globalRateLimiter.check(identifier);
  
  if (!result.allowed) {
    console.warn(`⚠️ Rate limit exceeded for: ${identifier.substring(0, 10)}...`);
    return new Response(
      JSON.stringify({ error: 'Too many requests. Please try again later.' }),
      {
        status: 429,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'X-RateLimit-Limit': '100',
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': result.resetAt.toString(),
          'Retry-After': Math.ceil((result.resetAt - Date.now()) / 1000).toString()
        }
      }
    );
  }
  
  // Rate limit OK - adicionar headers informativos
  // (Esses headers podem ser adicionados à resposta de sucesso também)
  return null; // null significa "prosseguir"
}

export function addRateLimitHeaders(
  headers: Record<string, string>,
  remaining: number,
  resetAt: number
): Record<string, string> {
  return {
    ...headers,
    'X-RateLimit-Limit': '100',
    'X-RateLimit-Remaining': remaining.toString(),
    'X-RateLimit-Reset': resetAt.toString()
  };
}
