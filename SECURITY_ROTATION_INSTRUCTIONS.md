# 🔐 Instruções para Rotação de Credenciais - AÇÃO IMEDIATA

## ⚠️ CRITICAL: Credenciais Expostas no Git

As seguintes credenciais foram expostas no repositório Git e **DEVEM SER ROTACIONADAS IMEDIATAMENTE**:

```
SUPABASE_URL: https://klepqdiqpochlkrfyapd.supabase.co
SYNC_SECRET: SuevitSync2026!SecureKey#Farma
```

## 📋 Checklist de Rotação

### 1. Gerar Novo SYNC_SECRET

```bash
# Gerar secret forte de 32 caracteres (execute em qualquer terminal)
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"

# Ou use este gerador online seguro:
# https://www.random.org/passwords/?num=1&len=32&format=plain&rnd=new
```

**Exemplo de secret forte:** `k8zXm9Lp2Qw7Rf4Nv6Bh3Tc5Yg1Jd0Ma`

### 2. Atualizar no Supabase Dashboard

1. Acesse: https://supabase.com/dashboard/project/klepqdiqpochlkrfyapd
2. Vá em **Settings** → **Edge Functions** → **Secrets**
3. Adicione/Atualize a variável:
   - Nome: `SYNC_SECRET`
   - Valor: `<seu_novo_secret_gerado>`
4. Salve as mudanças

### 3. Atualizar Google Apps Script

**IMPORTANTE:** Use Script Properties, NÃO hardcode no código!

#### Para cada Google Apps Script:

1. Abra seu Google Apps Script
2. Vá em **Project Settings** (ícone de engrenagem)
3. Clique em **Script Properties** → **Add property**
4. Adicione as propriedades:
   - `SUPABASE_URL` = `https://klepqdiqpochlkrfyapd.supabase.co`
   - `SYNC_SECRET` = `<seu_novo_secret_gerado>`

5. Copie o conteúdo dos templates:
   - `supabase/functions/sync-products/on-edit.template.js`
   - `supabase/functions/sync-to-sheet/suevit-app-script.template.js`

6. Cole no Google Apps Script (substituindo código antigo)
7. Salve e teste

### 4. Remover Arquivos Comprometidos do Git

Os arquivos já foram adicionados ao `.gitignore`, mas você deve removê-los do histórico:

```bash
# Navegar para o diretório do projeto
cd "c:\Users\igore\Farma-App---Mobile"

# Remover arquivos do Git (mantém localmente)
git rm --cached "supabase/functions/sync-products/on edit.js"
git rm --cached "supabase/functions/sync-to-sheet/suevit app script.js"

# Commit das mudanças
git add .gitignore
git commit -m "security: remove compromised credential files and add to gitignore"

# Push para o repositório
git push origin main
```

### 5. (Opcional) Limpar Histórico do Git

**ATENÇÃO:** Isso reescreve o histórico do Git. Coordene com a equipe antes!

```bash
# Instalar git-filter-repo (se não tiver)
pip install git-filter-repo

# Remover arquivos do histórico completo
git filter-repo --path "supabase/functions/sync-products/on edit.js" --invert-paths
git filter-repo --path "supabase/functions/sync-to-sheet/suevit app script.js" --invert-paths

# Force push (CUIDADO!)
git push origin --force --all
```

### 6. Revogar Service Role Key (Se Exposta)

Se a `SUPABASE_SERVICE_ROLE_KEY` também foi exposta:

1. Acesse o Supabase Dashboard
2. Vá em **Settings** → **API**
3. Em **Project API keys**, clique em **Reset** na Service Role Key
4. Copie a nova chave
5. Atualize em todos os lugares:
   - Edge Functions (via Dashboard Secrets)
   - Admin Next.js (arquivo `.env.local` - NÃO versionar!)
   - CI/CD pipelines

### 7. Verificar Logs de Acesso

1. No Supabase Dashboard, vá em **Logs**
2. Procure por acessos suspeitos usando o SYNC_SECRET antigo
3. Verifique Edge Functions logs nos últimos 7 dias
4. Se houver atividade suspeita, investigue e tome medidas adicionais

## 🎯 Teste Após Rotação

### Testar Edge Functions

```bash
# Testar sync-products (substitua o novo secret)
curl -X POST https://klepqdiqpochlkrfyapd.supabase.co/functions/v1/sync-products \
  -H "Content-Type: application/json" \
  -H "x-sync-secret: SEU_NOVO_SECRET" \
  -d '{"action": "test"}'
```

### Testar Google Apps Script

1. No Google Apps Script, execute a função `testSync()`
2. Verifique os logs para confirmar que está funcionando
3. Teste o webhook `doPost` com dados de exemplo

## 📝 Documentação Atualizada

Após completar a rotação, atualize:

- [ ] Documentação interna da equipe
- [ ] Instruções de deploy
- [ ] README.md (se mencionar configuração)
- [ ] Wiki/Confluence do projeto

## ✅ Verificação Final

- [ ] Novo SYNC_SECRET gerado e salvo em local seguro
- [ ] SYNC_SECRET atualizado no Supabase Dashboard
- [ ] Script Properties configuradas no Google Apps Script
- [ ] Arquivos .js removidos do Git
- [ ] .gitignore atualizado
- [ ] Templates (.template.js) criados
- [ ] Testes realizados com sucesso
- [ ] Documentação atualizada
- [ ] Equipe notificada

## 🚨 Em Caso de Problemas

Se algo quebrar após a rotação:

1. **Reverter temporariamente**: Você pode usar o secret antigo enquanto diagnostica
2. **Verificar logs**: Supabase Dashboard → Logs → Edge Functions
3. **Testar localmente**: Use `supabase functions serve` para debug local
4. **Contatar suporte**: Se for problema da plataforma Supabase

## 📞 Contatos de Emergência

- **Administrador do Projeto**: [seu-email@exemplo.com]
- **Suporte Supabase**: https://supabase.com/support
- **Documentação**: https://supabase.com/docs

---

**Data de criação**: 2026-04-12
**Status**: ⚠️ PENDENTE - Requer ação imediata
**Prioridade**: CRÍTICA
