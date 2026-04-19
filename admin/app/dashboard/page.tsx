'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { formatCurrency } from '@/lib/utils'
import Link from 'next/link'
import {
  AreaChart, Area, XAxis, YAxis,
  Tooltip, CartesianGrid,
} from 'recharts'

function greeting() {
  const h = new Date().getHours()
  if (h < 12) return 'Bom dia'
  if (h < 18) return 'Boa tarde'
  return 'Boa noite'
}

interface ChartPoint { month: string; pedidos: number; faturamento: number }

interface PendingUser {
  empresa: string
  nome: string
  email: string
  created_at: string
}

interface TopProduct {
  name: string
  qty: number
}

interface Metrics {
  adminName: string
  activeClients: number
  pendingClients: number
  ordersThisMonth: number
  revenueThisMonth: number
  totalOrders: number
  activeClientsLastMonth: number
  ordersLastMonth: number
  revenueLastMonth: number
  chartData: ChartPoint[]
  pendingUsers: PendingUser[]
  topProducts: TopProduct[]
}

export default function DashboardPage() {
  const [metrics, setMetrics] = useState<Metrics | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      const now = new Date()
      const firstOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString()

      const { data: { user } } = await supabase.auth.getUser()
      const { data: profile } = user
        ? await supabase.from('profiles').select('nome').eq('id', user.id).single()
        : { data: null }

      const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString()
      const lastMonthEnd   = firstOfMonth

      // Janeiro do ano corrente para o gráfico
      const sixMonthsAgo = new Date(now.getFullYear(), 0, 1).toISOString()

      const [
        { data: allCustomers },
        { data: allOrders },
        { data: monthOrders },
        { data: lastMonthOrders },
        { data: lastMonthCustomers },
        { data: chartOrders },
        { data: pendingProfiles },
        { data: orderItemsRaw },
        { data: cancelledOrderIds },
      ] = await Promise.all([
        supabase.from('profiles').select('status, created_at').eq('role', 'customer'),
        supabase.from('orders').select('total').neq('status', 'cancelled'),
        supabase.from('orders').select('total').neq('status', 'cancelled').gte('created_at', firstOfMonth),
        supabase.from('orders').select('total').neq('status', 'cancelled').gte('created_at', lastMonthStart).lt('created_at', lastMonthEnd),
        supabase.from('profiles').select('status, created_at').eq('role', 'customer').lt('created_at', lastMonthEnd),
        supabase.from('orders').select('total, created_at').neq('status', 'cancelled').gte('created_at', sixMonthsAgo),
        supabase.from('profiles').select('empresa, nome, email, created_at').eq('role', 'customer').eq('status', 'pending').order('created_at', { ascending: false }).limit(5),
        supabase.from('order_items').select('product_name, quantity, order_id'),
        supabase.from('orders').select('id').eq('status', 'cancelled'),
      ])

      // Filtra apenas itens de pedidos não cancelados
      const cancelledIds = new Set((cancelledOrderIds ?? []).map((o: any) => o.id))
      const orderItems = (orderItemsRaw ?? []).filter((item: any) => !cancelledIds.has(item.order_id))

      const activeClients          = (allCustomers ?? []).filter(p => p.status === 'approved').length
      const pendingClients         = (allCustomers ?? []).filter(p => p.status === 'pending').length
      const activeClientsLastMonth = (lastMonthCustomers ?? []).filter(p => p.status === 'approved').length
      const revenueThisMonth       = (monthOrders ?? []).reduce((s, o) => s + (o.total ?? 0), 0)
      const revenueLastMonth       = (lastMonthOrders ?? []).reduce((s, o) => s + (o.total ?? 0), 0)

      // Agrupa pedidos por mês — exibe Jan-Dez do ano corrente
      const monthNames = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez']
      const grouped: Record<string, { pedidos: number; faturamento: number }> = {}
      for (let i = 0; i < 12; i++) {
        const key = `${now.getFullYear()}-${i}`
        grouped[key] = { pedidos: 0, faturamento: 0 }
      }
      for (const o of chartOrders ?? []) {
        const d = new Date(o.created_at)
        const key = `${d.getFullYear()}-${d.getMonth()}`
        if (grouped[key]) {
          grouped[key].pedidos++
          grouped[key].faturamento += o.total ?? 0
        }
      }
      const chartData: ChartPoint[] = Object.entries(grouped)
        .sort((a, b) => Number(a[0].split('-')[1]) - Number(b[0].split('-')[1]))
        .map(([key, v]) => {
          const m = Number(key.split('-')[1])
          return { month: monthNames[m], ...v }
        })

      const pendingUsers: PendingUser[] = (pendingProfiles ?? []).map((p: any) => ({
        empresa: p.empresa ?? '',
        nome: p.nome ?? 'Sem nome',
        email: p.email ?? '',
        created_at: p.created_at,
      }))

      const productMap: Record<string, number> = {}
      for (const item of orderItems ?? []) {
        const name = (item as any).product_name ?? 'Desconhecido'
        productMap[name] = (productMap[name] ?? 0) + ((item as any).quantity ?? 1)
      }
      const topProducts: TopProduct[] = Object.entries(productMap)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([name, qty]) => ({ name, qty }))

      setMetrics({
        adminName: profile?.nome ?? '',
        activeClients,
        pendingClients,
        ordersThisMonth: (monthOrders ?? []).length,
        revenueThisMonth,
        totalOrders: (allOrders ?? []).length,
        activeClientsLastMonth,
        ordersLastMonth: (lastMonthOrders ?? []).length,
        revenueLastMonth,
        chartData,
        pendingUsers,
        topProducts,
      })
      setLoading(false)
    }
    load()
  }, [])

  if (loading) return <Skeleton />

  const m = metrics!
  const pendingUsers = m.pendingUsers ?? []
  const topProducts  = m.topProducts ?? []
  const firstName = (m.adminName ?? '').split(' ')[0] || 'Admin'
  const fullDate = new Date().toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
  })

  function pct(current: number, previous: number): number {
    if (!isFinite(current) || !isFinite(previous)) return 0
    if (previous === 0) return 0
    const result = Math.round(((current - previous) / previous) * 100)
    return isNaN(result) ? 0 : result
  }

  const clientsGrowth  = pct(m.activeClients, m.activeClientsLastMonth)
  const ordersGrowth   = pct(m.ordersThisMonth, m.ordersLastMonth)
  const revenueGrowth  = pct(m.revenueThisMonth, m.revenueLastMonth)

  return (
    <div className="space-y-10 pt-2">

      {/* Cabeçalho */}
      <div className="flex items-center justify-between gap-6">

        {/* Saudação */}
        <div>
          <h1 className="text-4xl font-semibold text-gray-900 whitespace-nowrap">
            {greeting()}, {firstName}
          </h1>
          <p className="text-sm text-gray-400 mt-2">Aqui está o resumo das informações</p>
        </div>

        {/* Data */}
        <div className="text-right shrink-0">
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-1">Data atual</p>
          <p className="text-lg font-bold text-gray-800 capitalize">{fullDate}</p>
        </div>

      </div>

      {/* Cards individuais */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Clientes ativos"      value={m.activeClients}                    growth={clientsGrowth}  href="/dashboard/usuarios" />
        <StatCard label="Cadastros pendentes"  value={m.pendingClients}                   growth={0}              href="/dashboard/cadastros" hideGrowth />
        <StatCard label="Pedidos este mês"     value={m.ordersThisMonth}                  growth={ordersGrowth}   href="/dashboard/pedidos" />
        <StatCard label="Faturamento do mês"   value={formatCurrency(m.revenueThisMonth)} growth={revenueGrowth} />
      </div>

      {/* Gráfico */}
      <SalesChart data={m.chartData} />

      {/* Pendentes + Produtos mais vendidos */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* Usuários pendentes */}
        <div className="border border-gray-200 rounded-2xl p-6">
          <div className="flex items-center justify-between mb-5">
            <h3 className="text-lg font-semibold text-gray-900">Pendentes para aprovação ({pendingUsers.length})</h3>
            <Link href="/dashboard/cadastros" className="text-sm text-gray-400 hover:text-gray-600 transition-colors">
              Ver todos →
            </Link>
          </div>

          {pendingUsers.length === 0 ? (
            <p className="text-sm text-gray-400">Nenhum cadastro pendente</p>
          ) : (
            <div className="space-y-4">
              {pendingUsers.map((u, i) => (
                <Link key={i} href="/dashboard/cadastros" className="flex items-center justify-between hover:bg-gray-50 -mx-2 px-2 py-2 rounded-xl transition-colors cursor-pointer">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 bg-gray-100 rounded-full flex items-center justify-center shrink-0">
                      <span className="text-gray-500 text-xs font-bold">{(u.empresa || u.nome)[0]?.toUpperCase()}</span>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">{u.empresa || u.nome}</p>
                      <p className="text-xs text-gray-400">{u.email}</p>
                    </div>
                  </div>
                  <span className="text-xs text-gray-400">
                    {new Date(u.created_at).toLocaleDateString('pt-BR')}
                  </span>
                </Link>
              ))}
            </div>
          )}
        </div>

        {/* Produtos mais vendidos */}
        <div className="border border-gray-200 rounded-2xl p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-5">Produtos mais vendidos</h3>

          {topProducts.length === 0 ? (
            <p className="text-sm text-gray-400">Nenhuma venda registrada</p>
          ) : (
            <div className="space-y-4">
              {topProducts.map((p, i) => (
                <div key={i} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <span className="w-7 h-7 bg-gray-100 rounded-lg flex items-center justify-center text-xs font-bold text-gray-500">
                      {i + 1}
                    </span>
                    <p className="text-sm font-medium text-gray-900">{p.name}</p>
                  </div>
                  <span className="text-sm font-semibold text-gray-700">{p.qty} un.</span>
                </div>
              ))}
            </div>
          )}
        </div>

      </div>

    </div>
  )
}

function StatCard({ label, value, growth, href, hideGrowth }: {
  label: string
  value: string | number
  growth?: number
  href?: string
  hideGrowth?: boolean
}) {
  const g    = growth ?? 0
  const up   = g > 0
  const down = g < 0

  const badgeCls = up
    ? 'bg-emerald-50 text-emerald-600'
    : down
      ? 'bg-red-50 text-red-500'
      : 'bg-gray-100 text-gray-500'

  const inner = (
    <div className="border border-gray-200 rounded-2xl p-5 hover:border-gray-300 transition-colors flex flex-col min-h-[130px]">
      <p className="text-xs text-gray-400">{label}</p>
      <p className="text-3xl font-bold tracking-tight text-gray-900 mt-2 flex-1">{value}</p>
      {/* Badge de crescimento — sempre renderizado para manter altura uniforme */}
      <div className={`mt-3 self-start inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full ${
        hideGrowth ? 'bg-gray-100 text-gray-500' : badgeCls
      }`}>
        {!hideGrowth && g !== 0 && (
          <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d={up ? 'M5 10l7-7 7 7' : 'M19 14l-7 7-7-7'} />
          </svg>
        )}
        {g === 0 ? '0% vs mês anterior' : `${Math.abs(g)}% vs mês anterior`}
      </div>
    </div>
  )

  return href
    ? <Link href={href} className="block">{inner}</Link>
    : inner
}

const SERIES_OPTIONS = [
  { key: 'ambos',       label: 'Ambos' },
  { key: 'pedidos',     label: 'Pedidos' },
  { key: 'faturamento', label: 'Faturamento' },
] as const
type SeriesKey = (typeof SERIES_OPTIONS)[number]['key']

/* Extraído para fora do componente para evitar recriação a cada render */
function MonthTick({ x, y, payload, activeMonth, onSelect }: any) {
  const monthLabel = String(payload?.value ?? '')
  const isActive = activeMonth === monthLabel
  return (
    <g
      transform={`translate(${x},${y})`}
      onClick={() => onSelect(isActive ? null : monthLabel)}
      style={{ cursor: 'pointer', userSelect: 'none' }}
    >
      {isActive && (
        <rect
          x={-24} y={-1} width={48} height={28}
          rx={10}
          fill="#f3f4f6"
          stroke="none"
        />
      )}
      <text
        x={0}
        y={14}
        dominantBaseline="middle"
        textAnchor="middle"
        fill={isActive ? '#111827' : '#6b7280'}
        fontSize={isActive ? 15 : 14}
        fontWeight={isActive ? 700 : 500}
      >
        {monthLabel}
      </text>
    </g>
  )
}

function SalesChart({ data }: { data: ChartPoint[] }) {
  const [selected, setSelected]       = useState<SeriesKey>('ambos')
  const [dropOpen, setDropOpen]       = useState(false)
  const [activeMonth, setActiveMonth] = useState<string | null>(null)
  const [customStart, setCustomStart] = useState('')
  const [customEnd, setCustomEnd]     = useState('')

  const hasFaturamento = data.some(d => d.faturamento > 0)
  const showPedidos     = selected === 'ambos' || selected === 'pedidos'
  const showFaturamento = (selected === 'ambos' || selected === 'faturamento') && hasFaturamento

  const selectedLabel = SERIES_OPTIONS.find(o => o.key === selected)?.label ?? 'Ambos'

  const renderTick = (props: any) => (
    <MonthTick {...props} activeMonth={activeMonth} onSelect={setActiveMonth} />
  )

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (!active || !payload?.length) return null
    return (
      <div className="bg-gray-900 text-white rounded-xl px-4 py-3 text-xs shadow-lg">
        <p className="font-semibold mb-1">{label}</p>
        {showPedidos && (
          <p className="text-indigo-300">
            {payload.find((p: any) => p.dataKey === 'pedidos')?.value ?? 0} Pedidos
          </p>
        )}
        {showFaturamento && (
          <p className="text-amber-300">
            {formatCurrency(payload.find((p: any) => p.dataKey === 'faturamento')?.value ?? 0)}
          </p>
        )}
      </div>
    )
  }

  const hasAnyPedidos = data.some(d => d.pedidos > 0)

  type PeriodKey = '1d' | '7d' | '30d' | 'max' | 'custom'
  const [period, setPeriod] = useState<PeriodKey>('max')
  const PERIOD_OPTIONS: { key: PeriodKey; label: string }[] = [
    { key: '1d',    label: '1d' },
    { key: '7d',    label: '7d' },
    { key: '30d',   label: '30d' },
    { key: 'max',   label: 'Max' },
    { key: 'custom', label: 'Personalizado' },
  ]

  const now = new Date()
  const filteredData = (() => {
    if (period === 'max' || period === 'custom') return data
    const daysMap = { '1d': 1, '7d': 7, '30d': 30 }
    const days = daysMap[period as '1d' | '7d' | '30d']
    const cutoff = new Date(now.getFullYear(), now.getMonth(), now.getDate() - days)
    const cutoffMonth = cutoff.getMonth()
    const monthNames = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez']
    return data.filter(d => {
      const idx = monthNames.indexOf(d.month)
      return idx >= cutoffMonth
    })
  })()

  const totalSales = filteredData.reduce((sum, item) => sum + (item.faturamento ?? 0), 0)
  const totalPedidos = filteredData.reduce((sum, item) => sum + (item.pedidos ?? 0), 0)
  const currentMonthSales = filteredData[filteredData.length - 1]?.faturamento ?? 0
  const previousMonthSales = filteredData[filteredData.length - 2]?.faturamento ?? 0
  const salesDelta = currentMonthSales - previousMonthSales
  const salesDeltaPct = previousMonthSales === 0 ? 0 : (salesDelta / previousMonthSales) * 100
  const salesUp = salesDelta >= 0

  return (
    <div className="mt-10 relative">
      {/* Bloco da esquerda sem empurrar o gráfico para baixo */}
      <div className="absolute left-0 top-0 pl-1 w-[360px]">
        <p className="text-2xl font-semibold text-gray-900">Relatório de vendas</p>
        <p className="text-base text-gray-400 mt-1">Verifique as vendas</p>
        <p className="text-[2.6rem] font-bold text-gray-900 tracking-tight mt-8">
          {formatCurrency(totalSales)}
        </p>
        <p className={`mt-4 text-xl font-semibold ${salesUp ? 'text-emerald-300' : 'text-red-300'}`}>
          {salesUp ? '+' : '-'}{formatCurrency(Math.abs(salesDelta))} ({salesUp ? '+' : '-'}{Math.abs(salesDeltaPct).toFixed(1)}%)
        </p>

      </div>

      {/* Filtros de período — alinhados com os meses do gráfico */}
      <div className="absolute left-0 pl-1" style={{ bottom: '1.05rem' }}>
        <div className="flex items-center gap-2">
          {PERIOD_OPTIONS.map(opt => (
            <button
              key={opt.key}
              onClick={() => setPeriod(opt.key)}
              className={`px-4 py-2 text-sm font-medium rounded-full cursor-pointer transition-all ${
                period === opt.key
                  ? 'bg-gray-900 text-white'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>

        {period === 'custom' && (
          <div className="flex items-center gap-3 mt-3">
            <input
              type="date"
              value={customStart}
              onChange={e => setCustomStart(e.target.value)}
              className="border border-gray-200 rounded-lg px-3 py-1.5 text-sm text-gray-700 outline-none focus:border-gray-400"
            />
            <span className="text-gray-400 text-sm">até</span>
            <input
              type="date"
              value={customEnd}
              onChange={e => setCustomEnd(e.target.value)}
              className="border border-gray-200 rounded-lg px-3 py-1.5 text-sm text-gray-700 outline-none focus:border-gray-400"
            />
          </div>
        )}
      </div>

      {/* Seletor alinhado com os cards de cima */}
      <div className="flex justify-end mb-4 pr-1">
        <div className="relative">
          <button
            onClick={() => setDropOpen(v => !v)}
            className="flex items-center gap-2 px-6 py-2.5 text-sm font-medium text-gray-600 border border-gray-200 rounded-full hover:border-gray-300 transition-all"
          >
            {selectedLabel}
            <svg
              className={`w-3.5 h-3.5 text-gray-400 transition-transform ${dropOpen ? 'rotate-180' : ''}`}
              fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          {dropOpen && (
            <div className="absolute right-0 mt-1 w-40 bg-white border border-gray-100 rounded-xl shadow-lg z-10 overflow-hidden">
              {SERIES_OPTIONS.map(opt => (
                <button
                  key={opt.key}
                  onClick={() => { setSelected(opt.key); setDropOpen(false) }}
                  className={`w-full text-left px-4 py-2 text-sm transition-colors ${
                    selected === opt.key
                      ? 'bg-gray-50 text-gray-900 font-medium'
                      : 'text-gray-500 hover:bg-gray-50'
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      <div
        style={{ width: 720, transform: 'translateX(450px)' }}
        onMouseDown={e => { const t = e.target as HTMLElement; t.blur?.(); }}
      >
        <style>{`
          .recharts-wrapper, .recharts-wrapper svg, .recharts-wrapper *:focus {
            outline: none !important;
          }
        `}</style>
        <AreaChart
          width={720}
          height={300}
          data={data}
          margin={{ top: 8, right: 28, bottom: 0, left: 24 }}
        >
          <defs>
            <linearGradient id="gradBlue" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%"  stopColor="#6366f1" stopOpacity={0.14} />
              <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
            </linearGradient>
            <linearGradient id="gradAmber" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%"  stopColor="#f59e0b" stopOpacity={0.14} />
              <stop offset="95%" stopColor="#f59e0b" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#d0d0d0" vertical={true} horizontal={false} />
          <XAxis
            dataKey="month"
            axisLine={false}
            tickLine={false}
            interval={0}
            tick={renderTick}
            height={56}
          />
          <YAxis hide />
          <Tooltip content={<CustomTooltip />} cursor={false} />
          {showPedidos && hasAnyPedidos && (
            <Area type="monotone" dataKey="pedidos" stroke="#6366f1" strokeWidth={2} fill="url(#gradBlue)" dot={false} activeDot={false} />
          )}
          {showFaturamento && (
            <Area type="monotone" dataKey="faturamento" stroke="#f59e0b" strokeWidth={2} fill="url(#gradAmber)" dot={false} activeDot={false} />
          )}
        </AreaChart>
      </div>
    </div>
  )
}

function Skeleton() {
  return (
    <div className="space-y-10 pt-2 animate-pulse">
      <div className="flex items-end justify-between">
        <div className="space-y-2">
          <div className="h-8 w-56 bg-gray-100 rounded" />
          <div className="h-4 w-40 bg-gray-100 rounded" />
        </div>
        <div className="h-6 w-48 bg-gray-100 rounded" />
      </div>
      <div className="border border-gray-200 rounded-2xl p-6 h-24" />
    </div>
  )
}
