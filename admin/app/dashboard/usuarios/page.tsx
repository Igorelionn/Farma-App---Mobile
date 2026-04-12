'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { formatDate } from '@/lib/utils'

const FILTERS = ['all', 'approved', 'blocked', 'pending', 'rejected'] as const
type Filter = typeof FILTERS[number]

const FILTER_LABELS: Record<Filter, string> = {
  all: 'Todos',
  approved: 'Ativos',
  blocked: 'Bloqueados',
  pending: 'Pendentes',
  rejected: 'Reprovados',
}

const STATUS_DOT: Record<string, string> = {
  approved: 'bg-emerald-400',
  blocked: 'bg-red-400',
  pending: 'bg-amber-400',
  rejected: 'bg-gray-300',
  under_review: 'bg-blue-400',
}

const STATUS_LABEL: Record<string, string> = {
  approved: 'Ativo',
  blocked: 'Bloqueado',
  pending: 'Pendente',
  rejected: 'Reprovado',
  under_review: 'Em análise',
}

export default function UsuariosPage() {
  const [users, setUsers] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState<Filter>('all')
  const [actionLoading, setActionLoading] = useState<string | null>(null)
  const [selected, setSelected] = useState<any | null>(null)
  const [counts, setCounts] = useState<Record<string, number>>({})

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'customer')
        .order('created_at', { ascending: false })
      if (!error) {
        const list = data ?? []
        setUsers(list)
        const c: Record<string, number> = {}
        list.forEach(u => { c[u.status] = (c[u.status] ?? 0) + 1 })
        c.all = list.length
        setCounts(c)
      }
    } finally {
      setLoading(false)
    }
  }

  async function toggleBlock(id: string, currentStatus: string) {
    setActionLoading(id)
    const newStatus = currentStatus === 'blocked' ? 'approved' : 'blocked'
    const { error } = await supabase.from('profiles').update({ status: newStatus }).eq('id', id)
    if (!error) {
      setUsers(prev => prev.map(u => u.id === id ? { ...u, status: newStatus } : u))
      if (selected?.id === id) setSelected((s: any) => ({ ...s, status: newStatus }))
      setCounts(prev => {
        const next = { ...prev }
        next[currentStatus] = (next[currentStatus] ?? 1) - 1
        next[newStatus] = (next[newStatus] ?? 0) + 1
        return next
      })
    }
    setActionLoading(null)
  }

  const filtered = users.filter(u => {
    const q = search.toLowerCase()
    const matchSearch = !search || [u.empresa, u.nome, u.email, u.cnpj].some(
      v => v?.toLowerCase().includes(q)
    )
    const matchFilter = filter === 'all' || u.status === filter
    return matchSearch && matchFilter
  })

  if (selected) {
    return (
      <div className="space-y-10">

        {/* Top bar */}
        <div className="flex items-center justify-between">
          <button
            onClick={() => setSelected(null)}
            className="flex items-center gap-2.5 text-sm text-gray-400 hover:text-gray-700 transition-colors group"
          >
            <span className="w-8 h-8 rounded-lg border border-gray-200 flex items-center justify-center group-hover:border-gray-300 transition-colors">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
              </svg>
            </span>
            Voltar aos usuários
          </button>
          <span className="text-xs text-gray-400">
            Cadastrado em {formatDate(selected.created_at)}
          </span>
        </div>

        {/* Header */}
        <div className="flex items-start justify-between gap-6">
          <div className="flex items-center gap-5">
            <div className="w-16 h-16 bg-gradient-to-br from-gray-100 to-gray-50 rounded-2xl flex items-center justify-center border border-gray-100">
              <span className="text-gray-500 font-bold text-xl">{(selected.empresa ?? selected.nome ?? '?')[0]?.toUpperCase()}</span>
            </div>
            <div>
              <h2 className="text-2xl font-semibold text-gray-900 tracking-tight">{selected.empresa ?? selected.nome}</h2>
              <div className="flex items-center gap-3 mt-1.5">
                <p className="text-sm text-gray-400">{selected.email}</p>
                {selected.cnpj && (
                  <>
                    <span className="w-1 h-1 rounded-full bg-gray-300" />
                    <p className="text-sm text-gray-400">{selected.cnpj}</p>
                  </>
                )}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3 shrink-0">
            <div className="flex items-center gap-2 mr-2">
              <span className={`w-2 h-2 rounded-full ${STATUS_DOT[selected.status] ?? 'bg-gray-300'}`} />
              <span className="text-sm text-gray-500">{STATUS_LABEL[selected.status] ?? selected.status}</span>
            </div>
            {(selected.status === 'approved' || selected.status === 'blocked') && (
              <button
                onClick={() => toggleBlock(selected.id, selected.status)}
                disabled={actionLoading === selected.id}
                className={`px-5 py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-30 ${
                  selected.status === 'blocked'
                    ? 'bg-gray-900 text-white hover:bg-gray-800'
                    : 'border border-gray-200 text-red-500 hover:bg-red-50 hover:border-red-200'
                }`}
              >
                {actionLoading === selected.id ? 'Processando...' : selected.status === 'blocked' ? 'Desbloquear' : 'Bloquear'}
              </button>
            )}
          </div>
        </div>

        <div className="h-px bg-gray-100" />

        {/* Conteúdo */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

          <div className="border border-gray-100 rounded-2xl p-6 space-y-5">
            <div className="flex items-center gap-2.5 mb-1">
              <svg className="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest">Empresa</p>
            </div>
            <Field label="Razão Social" value={selected.empresa} />
            <Field label="CNPJ" value={selected.cnpj} />
            <Field label="Tipo" value={selected.tipo} />
            <Field label="Telefone" value={selected.telefone} />
            <Field label="Email" value={selected.email} />
          </div>

          <div className="border border-gray-100 rounded-2xl p-6 space-y-5">
            <div className="flex items-center gap-2.5 mb-1">
              <svg className="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest">Endereço</p>
            </div>
            <Field label="CEP" value={selected.cep} />
            <Field label="Logradouro" value={[selected.endereco, selected.numero, selected.complemento].filter(Boolean).join(', ')} />
            <Field label="Bairro" value={selected.bairro} />
            <Field label="Cidade / UF" value={selected.cidade || selected.estado ? `${selected.cidade ?? ''} – ${selected.estado ?? ''}` : null} />
          </div>

          <div className="border border-gray-100 rounded-2xl p-6 space-y-5">
            <div className="flex items-center gap-2.5 mb-1">
              <svg className="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest">Responsável técnico</p>
            </div>
            <Field label="Nome" value={selected.responsavel_nome} />
            <Field label="CRF" value={selected.responsavel_crf} />
            <Field label="CPF" value={selected.responsavel_cpf} />
            {!selected.responsavel_nome && !selected.responsavel_crf && !selected.responsavel_cpf && (
              <p className="text-xs text-gray-300 italic">Nenhum dado informado</p>
            )}
          </div>

        </div>

        {/* Documentação */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="border border-gray-100 rounded-2xl p-6 space-y-5">
            <div className="flex items-center gap-2.5 mb-1">
              <svg className="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest">Documentação</p>
            </div>
            <Field label="Inscrição Estadual" value={selected.inscricao_estadual} />
            <Field label="Inscrição Municipal" value={selected.inscricao_municipal} />
            <Field label="AFE ANVISA" value={selected.afe} />
            <Field label="Autorização Especial" value={selected.autorizacao_especial} />
            {!selected.inscricao_estadual && !selected.inscricao_municipal && !selected.afe && !selected.autorizacao_especial && (
              <p className="text-xs text-gray-300 italic">Nenhuma documentação informada</p>
            )}
          </div>

          <div className="border border-gray-100 rounded-2xl p-6">
            <div className="flex items-center gap-2.5 mb-5">
              <svg className="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
              </svg>
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest">Arquivos enviados</p>
            </div>
            <div className="space-y-1">
              <DocRow label="Alvará de Funcionamento" urls={selected.alvara_funcionamento} />
              <DocRow label="Licença Sanitária" urls={selected.licenca_sanitaria} />
              <DocRow label="CRT" urls={selected.crt} />
            </div>
          </div>
        </div>

      </div>
    )
  }

  return (
    <div className="space-y-6">

      {/* Header + Busca */}
      <div className="flex items-end justify-between gap-6">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Usuários</h1>
          <p className="text-xs text-gray-400 mt-0.5">{users.length} clientes cadastrados</p>
        </div>

        <div className="relative w-64">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Buscar..."
            className="w-full pl-9 pr-3 py-2 text-sm bg-gray-50 border-0 rounded-lg outline-none focus:bg-gray-100 placeholder:text-gray-300 transition-colors"
          />
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-gray-100 pb-px">
        {FILTERS.map(f => {
          const active = filter === f
          const count = counts[f] ?? 0
          return (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`relative px-4 py-2.5 text-sm font-medium whitespace-nowrap transition-colors ${
                active ? 'text-gray-900' : 'text-gray-400 hover:text-gray-600'
              }`}
            >
              {FILTER_LABELS[f]}
              {count > 0 && (
                <span className={`ml-1.5 text-[11px] tabular-nums ${active ? 'text-gray-900' : 'text-gray-300'}`}>
                  {count}
                </span>
              )}
              {active && (
                <span className="absolute bottom-0 left-4 right-4 h-[2px] bg-gray-900 rounded-full" />
              )}
            </button>
          )
        })}
      </div>

      {/* Lista */}
      {loading ? (
        <div className="flex items-center justify-center py-24">
          <div className="w-5 h-5 border-[1.5px] border-gray-200 border-t-gray-500 rounded-full animate-spin" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-24">
          <p className="text-sm text-gray-300">
            {search ? 'Nenhum resultado' : 'Nenhum usuário encontrado'}
          </p>
        </div>
      ) : (
        <>
          {/* Desktop */}
          <div className="hidden md:block">
            <div className="grid grid-cols-[1fr_140px_100px_100px_100px_90px] gap-x-4 px-1 pb-3">
              <span className="text-[11px] font-medium text-gray-400 uppercase tracking-wider">Empresa</span>
              <span className="text-[11px] font-medium text-gray-400 uppercase tracking-wider">CNPJ</span>
              <span className="text-[11px] font-medium text-gray-400 uppercase tracking-wider">Tipo</span>
              <span className="text-[11px] font-medium text-gray-400 uppercase tracking-wider">Cadastro</span>
              <span className="text-[11px] font-medium text-gray-400 uppercase tracking-wider">Status</span>
              <span className="text-[11px] font-medium text-gray-400 uppercase tracking-wider text-right">Ação</span>
            </div>

            <div className="divide-y divide-gray-50">
              {filtered.map(u => (
                <div
                  key={u.id}
                  className="grid grid-cols-[1fr_140px_100px_100px_100px_90px] gap-x-4 items-center px-1 py-3.5 rounded-xl hover:bg-gray-50/60 transition-colors cursor-pointer group"
                  onClick={() => setSelected(u)}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center shrink-0">
                      <span className="text-gray-500 text-xs font-semibold">{(u.empresa ?? u.nome ?? '?')[0]?.toUpperCase()}</span>
                    </div>
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-gray-800 truncate">{u.empresa ?? u.nome}</p>
                      <p className="text-xs text-gray-400 truncate">{u.email}</p>
                    </div>
                  </div>
                  <span className="text-xs text-gray-400 truncate">{u.cnpj ?? '—'}</span>
                  <span className="text-xs text-gray-400 capitalize">{u.tipo ?? '—'}</span>
                  <span className="text-xs text-gray-400">{formatDate(u.created_at)}</span>
                  <div className="flex items-center gap-1.5">
                    <span className={`w-1.5 h-1.5 rounded-full ${STATUS_DOT[u.status] ?? 'bg-gray-300'}`} />
                    <span className="text-xs text-gray-500">{STATUS_LABEL[u.status] ?? u.status}</span>
                  </div>
                  <div className="text-right">
                    {(u.status === 'approved' || u.status === 'blocked') && (
                      <button
                        onClick={e => { e.stopPropagation(); toggleBlock(u.id, u.status) }}
                        disabled={actionLoading === u.id}
                        className={`text-xs px-3 py-1.5 rounded-lg font-medium transition-colors disabled:opacity-30 ${
                          u.status === 'blocked'
                            ? 'text-emerald-600 hover:bg-emerald-50'
                            : 'text-red-500 hover:bg-red-50'
                        }`}
                      >
                        {actionLoading === u.id ? '...' : u.status === 'blocked' ? 'Ativar' : 'Bloquear'}
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Mobile */}
          <div className="md:hidden divide-y divide-gray-50">
            {filtered.map(u => (
              <button
                key={u.id}
                onClick={() => setSelected(u)}
                className="w-full text-left flex items-center justify-between gap-4 py-4 px-1 hover:bg-gray-50/60 rounded-xl transition-colors"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div className="w-9 h-9 bg-gray-100 rounded-lg flex items-center justify-center shrink-0">
                    <span className="text-gray-500 text-xs font-semibold">{(u.empresa ?? u.nome ?? '?')[0]?.toUpperCase()}</span>
                  </div>
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-gray-800 truncate">{u.empresa ?? u.nome}</p>
                    <p className="text-xs text-gray-400 truncate mt-0.5">{u.email}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <span className={`w-1.5 h-1.5 rounded-full ${STATUS_DOT[u.status] ?? 'bg-gray-300'}`} />
                  <svg className="w-3.5 h-3.5 text-gray-200" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                  </svg>
                </div>
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  )
}

function Field({ label, value }: { label: string; value?: string | null }) {
  if (!value) return null
  return (
    <div>
      <p className="text-[11px] text-gray-400 mb-1">{label}</p>
      <p className="text-sm text-gray-800">{value}</p>
    </div>
  )
}

function DocRow({ label, urls }: { label: string; urls?: string | null }) {
  const [links, setLinks] = useState<string[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!urls) { setLinks([]); setLoading(false); return }
    let cancelled = false
    async function resolve() {
      setLoading(true)
      try {
        const res = await fetch('/api/signed-url', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ rawValue: urls }),
        })
        const data = await res.json()
        if (!cancelled) setLinks(data.urls ?? [])
      } catch {
        if (!cancelled) setLinks([])
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    resolve()
    return () => { cancelled = true }
  }, [urls])

  return (
    <div className="flex items-center justify-between py-3 border-b border-gray-50 last:border-b-0">
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 rounded-lg bg-gray-50 flex items-center justify-center shrink-0">
          <svg className="w-3.5 h-3.5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
          </svg>
        </div>
        <span className="text-sm text-gray-700">{label}</span>
      </div>
      {loading ? (
        <div className="w-3.5 h-3.5 border-[1.5px] border-gray-300 border-t-gray-600 rounded-full animate-spin" />
      ) : links.length === 0 ? (
        <span className="text-xs text-gray-300 italic">Não enviado</span>
      ) : (
        <div className="flex gap-2">
          {links.map((url, i) => (
            <a
              key={i}
              href={url}
              target="_blank"
              rel="noreferrer"
              className="text-xs px-3 py-1.5 text-gray-500 border border-gray-200 rounded-lg hover:bg-gray-50 hover:text-gray-700 transition-colors"
            >
              Abrir{links.length > 1 ? ` (${i + 1})` : ''}
            </a>
          ))}
        </div>
      )}
    </div>
  )
}
