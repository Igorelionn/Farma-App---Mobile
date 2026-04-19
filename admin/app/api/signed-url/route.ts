import { NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { createAdminClient } from '@/lib/supabase-server'

const STORAGE_PREFIX = 'storage:'
const SIGNED_URL_EXPIRY = 3600 // 1 hora

export async function POST(request: NextRequest) {
  try {
    const cookieStore = await cookies()

    // Cria cliente SSR com acesso aos cookies da sessão
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll() {
            return cookieStore.getAll()
          },
          setAll(cookiesToSet) {
            cookiesToSet.forEach(({ name, value, options }) => {
              cookieStore.set(name, value, options)
            })
          },
        },
      }
    )

    // Verifica se o usuário está autenticado
    const { data: { user }, error: authError } = await supabase.auth.getUser()

    console.log('[signed-url] Verificando autenticação...')
    console.log('[signed-url] User:', user?.id)
    console.log('[signed-url] Auth error:', authError)
    console.log('[signed-url] Cookies:', cookieStore.getAll().map(c => c.name))

    if (authError || !user) {
      console.error('[signed-url] Erro de autenticação:', authError)
      return NextResponse.json({ 
        error: 'Não autorizado',
        details: authError?.message || 'Usuário não encontrado'
      }, { status: 401 })
    }

    console.log('[signed-url] Usuário autenticado:', user.id)

    // Verifica role de admin via service role (sem RLS)
    const adminClient = createAdminClient()
    const { data: profile, error: profileError } = await adminClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    console.log('[signed-url] Profile do usuário:', profile)
    console.log('[signed-url] Profile error:', profileError)

    if (profileError || profile?.role !== 'admin') {
      console.error('[signed-url] Usuário não é admin:', profile?.role, profileError)
      return NextResponse.json({ error: 'Acesso negado' }, { status: 403 })
    }

    const body = await request.json()
    const { rawValue } = body as { rawValue: string }

    console.log('[signed-url] rawValue recebido:', rawValue)

    if (!rawValue || typeof rawValue !== 'string') {
      return NextResponse.json({ error: 'Parâmetro inválido' }, { status: 400 })
    }

    // Formato legado: URLs já completas → retorna como está
    if (!rawValue.startsWith(STORAGE_PREFIX)) {
      const urls = rawValue.split('|').filter(Boolean)
      console.log('[signed-url] Formato legado detectado, retornando URLs:', urls)
      return NextResponse.json({ urls })
    }

    // Novo formato: paths do storage → gera signed URLs
    const paths = rawValue.substring(STORAGE_PREFIX.length).split('|').filter(Boolean)
    const signedUrls: string[] = []

    console.log('[signed-url] Processando paths:', paths)

    for (const path of paths) {
      console.log('[signed-url] Gerando URL para:', path)
      
      // Usa o endpoint interno que serve os arquivos diretamente
      const internalUrl = `/api/document/${path}`
      signedUrls.push(internalUrl)
      console.log('[signed-url] URL gerada:', internalUrl)
    }

    console.log('[signed-url] Total de URLs geradas:', signedUrls.length)
    return NextResponse.json({ urls: signedUrls })
  } catch (error) {
    console.error('[signed-url] Erro não tratado:', error)
    return NextResponse.json({ 
      error: 'Erro interno',
      details: error instanceof Error ? error.message : 'Erro desconhecido'
    }, { status: 500 })
  }
}
