// Rate limiting simples baseado em IP
const ratelimit = new Map<string, { count: number; resetAt: number }>()

export function checkRateLimit(identifier: string, maxRequests: number = 100, windowMs: number = 60000): boolean {
  const now = Date.now()
  const record = ratelimit.get(identifier)

  if (!record || now > record.resetAt) {
    ratelimit.set(identifier, { count: 1, resetAt: now + windowMs })
    return true
  }

  if (record.count >= maxRequests) {
    return false
  }

  record.count++
  return true
}

// Limpa registros antigos a cada 5 minutos
setInterval(() => {
  const now = Date.now()
  for (const [key, value] of ratelimit.entries()) {
    if (now > value.resetAt) {
      ratelimit.delete(key)
    }
  }
}, 5 * 60 * 1000)
