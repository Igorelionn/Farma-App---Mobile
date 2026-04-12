import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
// Service role key: NUNCA exponha no client-side (NEXT_PUBLIC_*).
// Use apenas em Server Components, Route Handlers e Server Actions.
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

/**
 * Cliente Supabase com service role.
 * Bypassa RLS — use somente em contextos server-side autenticados.
 */
export function createAdminClient() {
  return createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  })
}
