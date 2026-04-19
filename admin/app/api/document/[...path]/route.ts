import { NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { createAdminClient } from '@/lib/supabase-server'
import { checkRateLimit } from '@/lib/rate-limit'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  // Rate limiting por IP
  const ip = request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown'
  if (!checkRateLimit(`document:${ip}`, 60, 60000)) { // 60 requisições por minuto
    console.error('[document] Rate limit excedido para IP:', ip)
    return NextResponse.json({ error: 'Muitas requisições' }, { status: 429 })
  }
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
    console.error('[document] Não autenticado')
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
    console.error('[document] Usuário não é admin')
    return NextResponse.json({ error: 'Acesso negado' }, { status: 403 })
  }

  // Reconstrói o path do arquivo
  const filePath = resolvedParams.path.join('/')

  // SEGURANÇA: Previne path traversal
  if (filePath.includes('..') || filePath.includes('//') || filePath.startsWith('/')) {
    console.error('[document] Path traversal detectado:', filePath)
    return NextResponse.json({ error: 'Path inválido' }, { status: 400 })
  }

  // SEGURANÇA: Valida extensão do arquivo
  const ext = filePath.split('.').pop()?.toLowerCase()
  const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png']
  if (!ext || !allowedExtensions.includes(ext)) {
    console.error('[document] Extensão não permitida:', ext)
    return NextResponse.json({ error: 'Tipo de arquivo não permitido' }, { status: 400 })
  }

  // SEGURANÇA: Valida formato do path (deve ser userId/documento_N.ext)
  const pathParts = filePath.split('/')
  if (pathParts.length !== 2) {
    console.error('[document] Formato de path inválido:', filePath)
    return NextResponse.json({ error: 'Formato de path inválido' }, { status: 400 })
  }

  // SEGURANÇA: Valida que userId é um UUID válido
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!uuidRegex.test(pathParts[0])) {
    console.error('[document] User ID inválido:', pathParts[0])
    return NextResponse.json({ error: 'User ID inválido' }, { status: 400 })
  }

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
  let contentType = 'application/octet-stream'
  
  if (ext === 'pdf') contentType = 'application/pdf'
  else if (ext === 'jpg' || ext === 'jpeg') contentType = 'image/jpeg'
  else if (ext === 'png') contentType = 'image/png'

  return new NextResponse(arrayBuffer, {
    headers: {
      'Content-Type': contentType,
      'Content-Disposition': `inline; filename="${pathParts[1]}"`,
      'Cache-Control': 'private, max-age=3600',
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
    },
  })
}
