class MercadoPagoConfig {
  // SANDBOX (TESTES)
  // Para obter suas credenciais de teste:
  // 1. Acesse: https://www.mercadopago.com.br/developers/panel
  // 2. Vá em "Credenciais" -> "Credenciais de teste"
  // 3. Copie o Access Token
  
  static const String sandboxAccessToken = 'SEU_ACCESS_TOKEN_DE_TESTE_AQUI';
  
  // PRODUCTION (PRODUÇÃO)
  // Para obter suas credenciais de produção:
  // 1. Acesse: https://www.mercadopago.com.br/developers/panel
  // 2. Vá em "Credenciais" -> "Credenciais de produção"
  // 3. Copie o Access Token
  // IMPORTANTE: Nunca commite o token de produção no GitHub!
  
  static const String productionAccessToken = 'SEU_ACCESS_TOKEN_DE_PRODUCAO_AQUI';
  
  // Ambiente atual (mude para production quando for para produção)
  static const bool isProduction = false;
  
  static String get currentAccessToken =>
      isProduction ? productionAccessToken : sandboxAccessToken;
}
