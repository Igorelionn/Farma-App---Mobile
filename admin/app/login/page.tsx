'use client'

import { useState } from 'react'
import Image from 'next/image'
import { supabase } from '@/lib/supabase'

// idle → loading → error-x → error-text → idle
//                → success
type BtnState = 'idle' | 'loading' | 'error-x' | 'error-text' | 'success'

export default function LoginPage() {
  const [email, setEmail]               = useState('')
  const [password, setPassword]         = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [btnState, setBtnState]         = useState<BtnState>('idle')

  const busy = btnState !== 'idle'

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    if (busy) return
    setBtnState('loading')

    const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password })

    const triggerError = async () => {
      setBtnState('error-x')
      await new Promise(r => setTimeout(r, 650))
      setBtnState('error-text')
      await new Promise(r => setTimeout(r, 2000))
      setBtnState('idle')
    }

    if (authError || !data.user) { triggerError(); return }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', data.user.id)
      .single()

    if (profile?.role !== 'admin') {
      await supabase.auth.signOut()
      triggerError()
      return
    }

    setBtnState('success')
    // Pequena espera para garantir que a sessão foi persistida no localStorage
    await new Promise(r => setTimeout(r, 800))
    window.location.replace('/dashboard')
  }

  const btnCls: Record<BtnState, string> = {
    'idle':       'border-gray-300 text-gray-700 hover:border-[#0CF7D8] hover:bg-[#0CF7D8] hover:text-black active:border-[#0CF7D8] active:bg-[#0CF7D8] active:text-black',
    'loading':    'border-gray-300 text-gray-500 cursor-not-allowed',
    'error-x':    'border-red-500 bg-red-500 text-white cursor-not-allowed',
    'error-text': 'border-red-500 bg-red-500 text-white cursor-not-allowed',
    'success':    'border-emerald-500 bg-emerald-500 text-white cursor-not-allowed',
  }

  return (
    <div className="min-h-screen bg-white flex items-center justify-center">
      <div className="w-full max-w-xl px-16">

        {/* Logo */}
        <div className="flex justify-center mb-16">
          <Image
            src="/logo.png"
            alt="Suevit"
            width={164}
            height={164}
            style={{ width: 164, height: 'auto' }}
            className="object-contain"
          />
        </div>

        <form onSubmit={handleLogin} className="space-y-12">

          {/* Usuário */}
          <div>
            <label className="block text-lg text-gray-500 mb-3">Usuário</label>
            <input
              type="text"
              inputMode="email"
              autoComplete="email"
              required
              value={email}
              onChange={e => setEmail(e.target.value)}
              disabled={busy}
              className="w-full bg-transparent border-0 border-b-2 border-gray-200 outline-none focus:outline-none focus:border-gray-600 pb-3 text-lg text-gray-900 placeholder:text-gray-300 transition-colors duration-150 disabled:opacity-60"
            />
          </div>

          {/* Senha */}
          <div>
            <label className="block text-lg text-gray-500 mb-3">Senha</label>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                autoComplete="current-password"
                required
                value={password}
                onChange={e => setPassword(e.target.value)}
                disabled={busy}
                className="w-full bg-transparent border-0 border-b-2 border-gray-200 outline-none focus:outline-none focus:border-gray-600 pb-3 text-lg text-gray-900 pr-10 placeholder:text-gray-300 transition-colors duration-150 disabled:opacity-60"
              />
              <button
                type="button"
                onClick={() => setShowPassword(v => !v)}
                className="absolute right-0 bottom-3 text-gray-400"
                tabIndex={-1}
              >
                {showPassword ? (
                  <svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                ) : (
                  <svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                )}
              </button>
            </div>
          </div>

          {/* Botão */}
          <div className="pt-2 -mx-6">
            <button
              type="submit"
              disabled={busy}
              className={`w-full border-2 text-lg font-medium py-4 rounded-full transition-all duration-300 flex items-center justify-center gap-2.5 overflow-hidden ${btnCls[btnState]}`}
            >
              {/* idle */}
              <span
                className="transition-all duration-300"
                style={{
                  opacity: btnState === 'idle' ? 1 : 0,
                  transform: btnState === 'idle' ? 'translateY(0)' : 'translateY(-8px)',
                  position: btnState === 'idle' ? 'relative' : 'absolute',
                }}
              >
                Entrar
              </span>

              {/* loading */}
              <span
                className="transition-all duration-300"
                style={{
                  opacity: btnState === 'loading' ? 1 : 0,
                  transform: btnState === 'loading' ? 'translateY(0)' : 'translateY(8px)',
                  position: btnState === 'loading' ? 'relative' : 'absolute',
                }}
              >
                Entrando...
              </span>

              {/* error-x — só o X centralizado */}
              <span
                className="transition-all duration-300"
                style={{
                  opacity: btnState === 'error-x' ? 1 : 0,
                  transform: btnState === 'error-x' ? 'scale(1)' : 'scale(0.5)',
                  position: btnState === 'error-x' ? 'relative' : 'absolute',
                }}
              >
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </span>

              {/* error-text — só o texto, sem ícone */}
              <span
                className="transition-all duration-300"
                style={{
                  opacity: btnState === 'error-text' ? 1 : 0,
                  transform: btnState === 'error-text' ? 'translateY(0)' : 'translateY(8px)',
                  position: btnState === 'error-text' ? 'relative' : 'absolute',
                }}
              >
                Credenciais inválidas!
              </span>

              {/* success — só o check */}
              <span
                className="transition-all duration-300"
                style={{
                  opacity: btnState === 'success' ? 1 : 0,
                  transform: btnState === 'success' ? 'scale(1)' : 'scale(0.5)',
                  position: btnState === 'success' ? 'relative' : 'absolute',
                }}
              >
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </span>
            </button>
          </div>

        </form>
      </div>
    </div>
  )
}
