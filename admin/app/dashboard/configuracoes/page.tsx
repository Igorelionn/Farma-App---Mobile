'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'

export default function ConfiguracoesPage() {
  const [nome, setNome] = useState('')
  const [email, setEmail] = useState('')
  const [senhaAtual, setSenhaAtual] = useState('')
  const [novaSenha, setNovaSenha] = useState('')
  const [confirmarSenha, setConfirmarSenha] = useState('')
  const [loadingPerfil, setLoadingPerfil] = useState(false)
  const [loadingSenha, setLoadingSenha] = useState(false)
  const [msgPerfil, setMsgPerfil] = useState<{ tipo: 'ok' | 'erro'; texto: string } | null>(null)
  const [msgSenha, setMsgSenha] = useState<{ tipo: 'ok' | 'erro'; texto: string } | null>(null)

  useEffect(() => {
    async function load() {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return
      setEmail(user.email ?? '')
      const { data: profile } = await supabase.from('profiles').select('nome').eq('id', user.id).single()
      if (profile) setNome(profile.nome ?? '')
    }
    load()
  }, [])

  async function salvarPerfil(e: React.FormEvent) {
    e.preventDefault()
    setLoadingPerfil(true)
    setMsgPerfil(null)
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Não autenticado')
      const { error } = await supabase.from('profiles').update({ nome }).eq('id', user.id)
      if (error) throw error
      setMsgPerfil({ tipo: 'ok', texto: 'Nome atualizado com sucesso.' })
    } catch {
      setMsgPerfil({ tipo: 'erro', texto: 'Erro ao salvar. Tente novamente.' })
    } finally {
      setLoadingPerfil(false)
    }
  }

  async function alterarSenha(e: React.FormEvent) {
    e.preventDefault()
    setMsgSenha(null)

    if (!senhaAtual) {
      setMsgSenha({ tipo: 'erro', texto: 'Informe sua senha atual.' })
      return
    }
    if (novaSenha !== confirmarSenha) {
      setMsgSenha({ tipo: 'erro', texto: 'As senhas não coincidem.' })
      return
    }
    if (novaSenha.length < 6) {
      setMsgSenha({ tipo: 'erro', texto: 'A senha deve ter pelo menos 6 caracteres.' })
      return
    }

    setLoadingSenha(true)
    try {
      // Re-autentica com a senha atual para confirmar identidade
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password: senhaAtual,
      })
      if (signInError) {
        setMsgSenha({ tipo: 'erro', texto: 'Senha atual incorreta.' })
        return
      }

      const { error } = await supabase.auth.updateUser({ password: novaSenha })
      if (error) throw error
      setMsgSenha({ tipo: 'ok', texto: 'Senha alterada com sucesso.' })
      setSenhaAtual('')
      setNovaSenha('')
      setConfirmarSenha('')
    } catch {
      setMsgSenha({ tipo: 'erro', texto: 'Erro ao alterar a senha. Tente novamente.' })
    } finally {
      setLoadingSenha(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Configurações</h1>
        <p className="text-sm text-gray-500 mt-1">Gerencie as informações da sua conta</p>
      </div>

      {/* Perfil */}
      <div className="bg-white rounded-2xl border border-gray-100 p-6">
        <h2 className="text-base font-semibold text-gray-900 mb-5">Informações da conta</h2>
        <form onSubmit={salvarPerfil} className="space-y-5">
          <div>
            <label className="block text-sm text-gray-500 mb-1.5">Nome</label>
            <input
              type="text"
              value={nome}
              onChange={e => setNome(e.target.value)}
              required
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm text-gray-900 focus:outline-none focus:border-gray-400 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-500 mb-1.5">E-mail</label>
            <input
              type="email"
              value={email}
              disabled
              className="w-full border border-gray-100 rounded-xl px-4 py-2.5 text-sm text-gray-400 bg-gray-50 cursor-not-allowed"
            />
            <p className="text-xs text-gray-400 mt-1">O e-mail não pode ser alterado.</p>
          </div>

          {msgPerfil && (
            <p className={`text-sm ${msgPerfil.tipo === 'ok' ? 'text-emerald-600' : 'text-red-500'}`}>
              {msgPerfil.texto}
            </p>
          )}

          <button
            type="submit"
            disabled={loadingPerfil}
            className="px-6 py-2.5 bg-gray-900 hover:bg-gray-700 disabled:opacity-50 text-white text-sm font-medium rounded-xl transition-colors"
          >
            {loadingPerfil ? 'Salvando...' : 'Salvar alterações'}
          </button>
        </form>
      </div>

      {/* Senha */}
      <div className="bg-white rounded-2xl border border-gray-100 p-6">
        <h2 className="text-base font-semibold text-gray-900 mb-5">Alterar senha</h2>
        <form onSubmit={alterarSenha} className="space-y-5">
          <div>
            <label className="block text-sm text-gray-500 mb-1.5">Senha atual</label>
            <input
              type="password"
              value={senhaAtual}
              onChange={e => setSenhaAtual(e.target.value)}
              required
              placeholder="Digite sua senha atual"
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm text-gray-900 focus:outline-none focus:border-gray-400 transition-colors placeholder:text-gray-300"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-500 mb-1.5">Nova senha</label>
            <input
              type="password"
              value={novaSenha}
              onChange={e => setNovaSenha(e.target.value)}
              required
              placeholder="Mínimo 6 caracteres"
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm text-gray-900 focus:outline-none focus:border-gray-400 transition-colors placeholder:text-gray-300"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-500 mb-1.5">Confirmar nova senha</label>
            <input
              type="password"
              value={confirmarSenha}
              onChange={e => setConfirmarSenha(e.target.value)}
              required
              placeholder="Repita a nova senha"
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm text-gray-900 focus:outline-none focus:border-gray-400 transition-colors placeholder:text-gray-300"
            />
          </div>

          {msgSenha && (
            <p className={`text-sm ${msgSenha.tipo === 'ok' ? 'text-emerald-600' : 'text-red-500'}`}>
              {msgSenha.texto}
            </p>
          )}

          <button
            type="submit"
            disabled={loadingSenha}
            className="px-6 py-2.5 bg-gray-900 hover:bg-gray-700 disabled:opacity-50 text-white text-sm font-medium rounded-xl transition-colors"
          >
            {loadingSenha ? 'Alterando...' : 'Alterar senha'}
          </button>
        </form>
      </div>

      {/* Sessão */}
      <div className="bg-white rounded-2xl border border-gray-100 p-6">
        <h2 className="text-base font-semibold text-gray-900 mb-1">Sessão</h2>
        <p className="text-sm text-gray-500 mb-4">Você está conectado como administrador.</p>
        <button
          onClick={async () => { await supabase.auth.signOut(); window.location.href = '/login' }}
          className="px-6 py-2.5 border border-red-200 text-red-600 hover:bg-red-50 text-sm font-medium rounded-xl transition-colors"
        >
          Encerrar sessão
        </button>
      </div>
    </div>
  )
}
