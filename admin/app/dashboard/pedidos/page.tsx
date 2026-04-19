'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { formatCurrency, formatDate } from '@/lib/utils'

const ORDER_STATUS: Record<string, { label: string, color: string }> = {
  pending: { label: 'Pendente', color: 'bg-amber-100 text-amber-700' },
  confirmed: { label: 'Confirmado', color: 'bg-blue-100 text-blue-700' },
  processing: { label: 'Em preparo', color: 'bg-purple-100 text-purple-700' },
  shipped: { label: 'Enviado', color: 'bg-indigo-100 text-indigo-700' },
  delivered: { label: 'Entregue', color: 'bg-emerald-100 text-emerald-700' },
  cancelled: { label: 'Cancelado', color: 'bg-red-100 text-red-700' },
}

export default function PedidosPage() {
  const [orders, setOrders] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [selected, setSelected] = useState<any | null>(null)
  const [actionLoading, setActionLoading] = useState(false)

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    const { data, error } = await supabase
      .from('orders')
      .select('*, profiles(empresa, nome, email, telefone, endereco, numero, cidade, estado), order_items(id, quantity, unit_price, products(nome))')
      .neq('status', 'cancelled')
      .order('created_at', { ascending: false })
    if (!error) setOrders(data ?? [])
    setLoading(false)
  }

  async function updateOrderStatus(id: string, status: string) {
    setActionLoading(true)
    const { error } = await supabase.from('orders').update({ status }).eq('id', id)
    if (!error) {
      setOrders(prev => prev.map(o => o.id === id ? { ...o, status } : o))
      if (selected?.id === id) setSelected((prev: any) => ({ ...prev, status }))
    }
    setActionLoading(false)
  }

  const filtered = orders.filter(o => {
    const matchSearch = !search || [
      o.profiles?.empresa, o.profiles?.nome, o.profiles?.email, String(o.id)
    ].some(v => v?.toLowerCase().includes(search.toLowerCase()))
    const matchStatus = statusFilter === 'all' || o.status === statusFilter
    return matchSearch && matchStatus
  })

  const nextStatus: Record<string, string> = {
    pending: 'confirmed',
    confirmed: 'processing',
    processing: 'shipped',
    shipped: 'delivered',
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-1">Pedidos</h1>
      <p className="text-sm text-gray-500 mb-6">Acompanhe e gerencie todos os pedidos</p>

      {/* Filtros */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <input
          type="text"
          placeholder="Buscar por empresa ou email..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="flex-1 px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
        />
        <select
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value)}
          className="px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none bg-white focus:ring-2 focus:ring-emerald-500"
        >
          <option value="all">Todos os status</option>
          {Object.entries(ORDER_STATUS).map(([k, v]) => (
            <option key={k} value={k}>{v.label}</option>
          ))}
        </select>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <div className="w-6 h-6 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-16 text-gray-400">
            <p className="text-3xl mb-2">📭</p>
            <p className="text-sm">Nenhum pedido encontrado</p>
          </div>
        ) : (
          <>
            {/* Desktop */}
            <div className="hidden md:block overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-100">
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">Pedido</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">Cliente</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">Data</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">Total</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-right text-xs font-semibold text-gray-400 uppercase tracking-wider">Detalhes</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {filtered.map(o => (
                    <tr key={o.id} className="hover:bg-gray-50/50">
                      <td className="px-6 py-4 text-sm font-mono text-gray-500">#{String(o.id).slice(0, 8)}</td>
                      <td className="px-6 py-4">
                        <p className="text-sm font-medium text-gray-900">{o.profiles?.empresa ?? o.profiles?.nome}</p>
                        <p className="text-xs text-gray-400">{o.profiles?.email}</p>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">{formatDate(o.created_at)}</td>
                      <td className="px-6 py-4 text-sm font-semibold text-gray-900">{formatCurrency(o.total)}</td>
                      <td className="px-6 py-4">
                        <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${ORDER_STATUS[o.status]?.color ?? 'bg-gray-100 text-gray-600'}`}>
                          {ORDER_STATUS[o.status]?.label ?? o.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button
                          onClick={() => setSelected(o)}
                          className="text-xs px-3 py-1.5 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                        >
                          Ver
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Mobile */}
            <div className="md:hidden divide-y divide-gray-50">
              {filtered.map(o => (
                <button key={o.id} onClick={() => setSelected(o)} className="w-full text-left px-4 py-4">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-gray-900 truncate">{o.profiles?.empresa ?? o.profiles?.nome}</p>
                      <p className="text-xs text-gray-400">{formatDate(o.created_at)} · #{String(o.id).slice(0, 8)}</p>
                    </div>
                    <div className="shrink-0 text-right">
                      <p className="text-sm font-semibold text-gray-900">{formatCurrency(o.total)}</p>
                      <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${ORDER_STATUS[o.status]?.color}`}>
                        {ORDER_STATUS[o.status]?.label}
                      </span>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </>
        )}
      </div>

      <p className="text-xs text-gray-400 mt-3 text-right">{filtered.length} pedido{filtered.length !== 1 ? 's' : ''}</p>

      {/* Modal detalhe */}
      {selected && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end lg:items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white px-6 py-4 border-b border-gray-100 flex items-center justify-between">
              <div>
                <h2 className="font-bold text-gray-900">Pedido #{String(selected.id).slice(0, 8)}</h2>
                <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${ORDER_STATUS[selected.status]?.color}`}>
                  {ORDER_STATUS[selected.status]?.label}
                </span>
              </div>
              <button onClick={() => setSelected(null)} className="text-gray-400 hover:text-gray-600 text-xl">✕</button>
            </div>

            <div className="p-6 space-y-5">
              <div>
                <p className="text-xs text-gray-400 mb-1">Cliente</p>
                <p className="text-sm font-medium text-gray-900">{selected.profiles?.empresa ?? selected.profiles?.nome}</p>
                <p className="text-xs text-gray-500">{selected.profiles?.email} · {selected.profiles?.telefone}</p>
              </div>
              <div>
                <p className="text-xs text-gray-400 mb-1">Entrega</p>
                <p className="text-sm text-gray-700">
                  {selected.profiles?.endereco}, {selected.profiles?.numero} — {selected.profiles?.cidade}/{selected.profiles?.estado}
                </p>
              </div>
              <div>
                <p className="text-xs text-gray-400 mb-2">Itens</p>
                <div className="space-y-2">
                  {(selected.order_items ?? []).length === 0 ? (
                    <p className="text-xs text-gray-400 italic">Sem itens registrados</p>
                  ) : (selected.order_items ?? []).map((item: any) => (
                    <div key={item.id} className="flex justify-between text-sm">
                      <span className="text-gray-700">{item.products?.nome ?? '—'} x{item.quantity}</span>
                      <span className="font-medium">{formatCurrency(item.unit_price * item.quantity)}</span>
                    </div>
                  ))}
                </div>
              </div>
              <div className="flex justify-between pt-3 border-t border-gray-100">
                <span className="font-semibold text-gray-900">Total</span>
                <span className="font-bold text-gray-900">{formatCurrency(selected.total)}</span>
              </div>
            </div>

            {/* Avançar status */}
            {nextStatus[selected.status] && (
              <div className="sticky bottom-0 bg-white border-t border-gray-100 px-6 py-4 flex gap-3">
                <button
                  onClick={() => updateOrderStatus(selected.id, 'cancelled')}
                  disabled={actionLoading}
                  className="px-4 py-2.5 rounded-xl border border-red-200 text-red-700 text-sm font-medium hover:bg-red-50 disabled:opacity-50 transition-colors"
                >
                  Cancelar
                </button>
                <button
                  onClick={() => updateOrderStatus(selected.id, nextStatus[selected.status])}
                  disabled={actionLoading}
                  className="flex-1 py-2.5 rounded-xl bg-emerald-500 text-white text-sm font-semibold hover:bg-emerald-600 disabled:opacity-50 transition-colors"
                >
                  {actionLoading ? '...' : `Avançar para: ${ORDER_STATUS[nextStatus[selected.status]]?.label}`}
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
