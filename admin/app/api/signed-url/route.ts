import { NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { createAdminClient } from '@/lib/supabase-server'

const STORAGE_PREFIX = 'storage:'
const SIGNED_URL_EXPIRY = 3600 // 1 hora

export async function POST(request: NextRequest) {
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

  if (authError || !user) {
    console.error('[signed-url] Erro de autenticação:', authError)
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 })
  }

  console.log('[signed-url] Usuário autenticado:', user.id)

  // Verifica role de admin via service role (sem RLS)
  const adminClient = createAdminClient()
  const { data: profile } = await adminClient
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  console.log('[signed-url] Profile do usuário:', profile)

  if (profile?.role !== 'admin') {
    console.error('[signed-url] Usuário não é admin:', profile?.role)
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
    console.log('[signed-url] Tentando gerar URL assinada para:', path)
    const { data, error } = await adminClient.storage
      .from('documents')
      .createSignedUrl(path, SIGNED_URL_EXPIRY)

    if (data?.signedUrl) {
      console.log('[signed-url] URL assinada gerada com sucesso:', data.signedUrl)
      signedUrls.push(data.signedUrl)
    } else {
      console.error('[signed-url] Falha ao gerar URL para', path, error)
    }
  }

  console.log('[signed-url] Total de URLs geradas:', signedUrls.length)
  return NextResponse.json({ urls: signedUrls })
}
