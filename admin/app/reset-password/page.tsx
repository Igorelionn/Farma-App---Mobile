'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase'
import Image from 'next/image'

export default function ResetPasswordPage() {
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')
  const [passwordError, setPasswordError] = useState('')
  const [confirmError, setConfirmError] = useState('')

  const supabase = createClient()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    // Validações
    setPasswordError('')
    setConfirmError('')
    setError('')

    if (password.length < 6) {
      setPasswordError('A senha deve ter pelo menos 6 caracteres')
      return
    }

    if (password !== confirmPassword) {
      setConfirmError('As senhas não coincidem')
      return
    }

    setLoading(true)

    try {
      const { error: updateError } = await supabase.auth.updateUser({
        password: password
      })

      if (updateError) throw updateError

      setSuccess(true)

      // Redirecionar após 3 segundos
      setTimeout(() => {
        window.close()
      }, 3000)
    } catch (err: any) {
      setError('Erro ao atualizar senha. Por favor, tente novamente.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center p-5" style={{
        background: 'linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)'
      }}>
        <div className="bg-white rounded-[20px] shadow-lg max-w-[440px] w-full p-12 text-center">
          <div className="w-16 h-16 bg-green-500 rounded-full flex items-center justify-center mx-auto mb-6">
            <svg className="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-gray-900 mb-3">Senha redefinida!</h1>
          <p className="text-gray-600 text-[15px]">
            Sua senha foi atualizada com sucesso. Você já pode fazer login com sua nova senha.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-5" style={{
      background: 'linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)'
    }}>
      <div className="bg-white rounded-[20px] shadow-lg max-w-[440px] w-full p-12">
        <div className="text-center mb-8">
          <Image 
            src="/logo.png" 
            alt="Suevit" 
            width={160} 
            height={60} 
            className="mx-auto"
          />
        </div>

        <h1 className="text-[26px] font-bold text-gray-900 text-center mb-3">Nova senha</h1>
        <p className="text-gray-600 text-[15px] text-center mb-8">
          Digite sua nova senha abaixo
        </p>

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label className="block text-sm font-semibold text-gray-900 mb-2">
              Nova senha
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Digite sua nova senha"
              className="w-full px-4 py-3.5 text-[15px] bg-gray-50 border-2 border-transparent rounded-xl focus:outline-none focus:border-[#11F2D4] focus:bg-white transition-all"
              required
            />
            {passwordError && (
              <p className="text-red-500 text-sm mt-1.5">{passwordError}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-900 mb-2">
              Confirmar senha
            </label>
            <input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Confirme sua nova senha"
              className="w-full px-4 py-3.5 text-[15px] bg-gray-50 border-2 border-transparent rounded-xl focus:outline-none focus:border-[#11F2D4] focus:bg-white transition-all"
              required
            />
            {confirmError && (
              <p className="text-red-500 text-sm mt-1.5">{confirmError}</p>
            )}
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3">
              <p className="text-red-600 text-sm">{error}</p>
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 text-[15px] font-semibold text-gray-900 rounded-xl transition-all disabled:opacity-60 disabled:cursor-not-allowed hover:-translate-y-0.5"
            style={{
              background: 'linear-gradient(135deg, #11F2D4 0%, #0dd4b8 100%)',
              boxShadow: '0 4px 12px rgba(17,242,212,0.2)'
            }}
          >
            {loading ? 'Atualizando...' : 'Redefinir senha'}
          </button>
        </form>
      </div>
    </div>
  )
}
