export function cn(...classes: (string | undefined | false | null)[]) {
  return classes.filter(Boolean).join(' ')
}

export function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString('pt-BR', {
    day: '2-digit', month: '2-digit', year: 'numeric',
  })
}

export function formatCurrency(value: number) {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency', currency: 'BRL',
  }).format(value)
}

export function statusLabel(status: string) {
  const map: Record<string, string> = {
    pending: 'Pendente',
    under_review: 'Em análise',
    approved: 'Aprovado',
    rejected: 'Reprovado',
    active: 'Ativo',
    blocked: 'Bloqueado',
  }
  return map[status] ?? status
}

export function statusColor(status: string) {
  const map: Record<string, string> = {
    pending: 'bg-amber-100 text-amber-700',
    under_review: 'bg-blue-100 text-blue-700',
    approved: 'bg-emerald-100 text-emerald-700',
    rejected: 'bg-red-100 text-red-700',
    active: 'bg-emerald-100 text-emerald-700',
    blocked: 'bg-red-100 text-red-700',
  }
  return map[status] ?? 'bg-gray-100 text-gray-700'
}
