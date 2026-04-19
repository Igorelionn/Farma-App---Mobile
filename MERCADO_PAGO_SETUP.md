# Integração Mercado Pago - Guia Completo

## 🚀 Configuração Inicial

### 1. Criar Conta no Mercado Pago

1. Acesse: https://www.mercadopago.com.br/
2. Crie uma conta ou faça login
3. Acesse o painel de desenvolvedores: https://www.mercadopago.com.br/developers/panel

### 2. Obter Credenciais de Teste (Sandbox)

1. No painel, vá em **"Suas integrações"**
2. Clique em **"Criar aplicação"**
3. Escolha um nome (ex: "Suevit App")
4. Vá em **"Credenciais"** → **"Credenciais de teste"**
5. Copie o **Access Token** (começará com `TEST-...`)

### 3. Configurar no App

Abra o arquivo `lib/core/config/mercado_pago_config.dart` e cole seu Access Token:

```dart
static const String sandboxAccessToken = 'TEST-1234567890-ABCDEF...';
```

## 🧪 Testando a Integração

### Cartões de Teste

Use estes cartões para testar diferentes cenários:

#### ✅ Aprovado
- **Número**: 5031 4332 1540 6351
- **CVV**: 123
- **Validade**: 11/25
- **Titular**: APRO

#### ❌ Recusado
- **Número**: 5031 4332 1540 6351
- **CVV**: 123
- **Validade**: 11/25
- **Titular**: OTHE

#### ⏳ Pendente
- **Número**: 5031 4332 1540 6351
- **CVV**: 123
- **Validade**: 11/25
- **Titular**: CONT

### PIX de Teste

No ambiente de teste (sandbox), quando você gerar um QR Code PIX:

1. O QR Code será gerado normalmente
2. Você pode "aprovar" o pagamento manualmente no painel do Mercado Pago
3. Ou aguardar o timeout (o pagamento expirará em 30 minutos)

Para simular um pagamento aprovado:
1. Acesse: https://www.mercadopago.com.br/developers/panel/payments
2. Encontre o pagamento criado
3. Clique em "Aprovar pagamento"

### Boleto de Teste

No ambiente de teste, os boletos são gerados mas não precisam ser pagos. Você pode:

1. Gerar o boleto
2. Acessar o link do boleto
3. No painel, marcar como "pago" manualmente

## 📱 Fluxo de Pagamento no App

### PIX
1. Usuário escolhe PIX na tela de pagamento
2. App cria o pagamento via Mercado Pago API
3. QR Code é exibido na tela
4. Usuário escaneia ou copia o código
5. App monitora o status automaticamente a cada 3 segundos
6. Quando aprovado, retorna para o app e finaliza o pedido

### Cartão de Crédito
1. Usuário preenche dados do cartão
2. App tokeniza o cartão (via Mercado Pago SDK)
3. Envia o token para criar o pagamento
4. Retorna status imediatamente (aprovado/recusado)

### Boleto
1. Usuário escolhe boleto
2. App gera o boleto via API
3. Exibe o link e código de barras
4. Usuário pode imprimir ou pagar online

## 🔐 Segurança

### ✅ Implementado
- Tokenização de cartões (nunca enviamos dados reais do cartão)
- HTTPS obrigatório
- Access Token protegido
- Validação de valores no servidor

### 🔒 Recomendações
- NUNCA commite o Access Token de produção no GitHub
- Use variáveis de ambiente (.env) para produção
- Implemente webhook para confirmar pagamentos no backend
- Valide valores no backend antes de criar pagamentos

## 🌐 Webhook (Opcional mas Recomendado)

Para receber notificações de pagamentos automaticamente:

1. Crie um endpoint no seu backend (Supabase Edge Function)
2. Configure a URL no painel do Mercado Pago
3. Mercado Pago enviará notificações quando o status mudar

Exemplo de endpoint:
```
https://seu-projeto.supabase.co/functions/v1/mercadopago-webhook
```

## 💰 Taxas (Valores de Referência)

- **PIX**: 0,99%
- **Cartão de crédito**: 4,99% + R$ 0,39
- **Boleto**: R$ 3,49 por boleto

## 📞 Suporte

- Documentação: https://www.mercadopago.com.br/developers/pt
- Suporte: https://www.mercadopago.com.br/ajuda
- Status da API: https://status.mercadopago.com/

## 🚀 Próximos Passos

1. ✅ Instalar dependências: `flutter pub get`
2. ✅ Configurar Access Token de teste
3. ✅ Testar pagamento PIX
4. ✅ Testar pagamento com cartão
5. ⏳ Implementar webhook (opcional)
6. ⏳ Obter credenciais de produção
7. ⏳ Fazer testes finais em produção
8. ⏳ Publicar o app
