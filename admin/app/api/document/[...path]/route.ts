import { NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { createAdminClient } from '@/lib/supabase-server'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const cookieStore = await cookies()
  const resolvedParams = await params

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
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 })
  }

  // Verifica role de admin via service role (sem RLS)
  const adminClient = createAdminClient()
  const { data: profile } = await adminClient
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'admin') {
    return NextResponse.json({ error: 'Acesso negado' }, { status: 403 })
  }

  // Reconstrói o path do arquivo
  const filePath = resolvedParams.path.join('/')

  console.log('[document] Baixando arquivo:', filePath)

  // Baixa o arquivo do storage
  const { data, error } = await adminClient.storage
    .from('documents')
    .download(filePath)

  if (error || !data) {
    console.error('[document] Erro ao baixar arquivo:', error)
    return NextResponse.json({ error: 'Arquivo não encontrado' }, { status: 404 })
  }

  // Retorna o arquivo como stream
  const arrayBuffer = await data.arrayBuffer()
  
  // Detecta tipo de conteúdo baseado na extensão
  const ext = filePath.split('.').pop()?.toLowerCase()
  let contentType = 'application/octet-stream'
  
  if (ext === 'pdf') contentType = 'application/pdf'
  else if (ext === 'jpg' || ext === 'jpeg') contentType = 'image/jpeg'
  else if (ext === 'png') contentType = 'image/png'

  return new NextResponse(arrayBuffer, {
    headers: {
      'Content-Type': contentType,
      'Content-Disposition': `inline; filename="${filePath.split('/').pop()}"`,
      'Cache-Control': 'private, max-age=3600',
    },
  })
}
