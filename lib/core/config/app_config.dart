/// Configuração centralizada do aplicativo
/// 
/// IMPORTANTE: Não empacote o .env no APK/IPA!
/// Use uma das alternativas abaixo:
library;

import 'package:flutter/foundation.dart';

class AppConfig {
  // ============================================================
  // OPÇÃO 1: Variáveis de build-time (RECOMENDADO)
  // ============================================================
  // Configure no momento do build:
  // flutter build apk --dart-define=SUPABASE_URL=https://...
  // flutter build apk --dart-define=SUPABASE_ANON_KEY=...
  
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // Vazio força configuração explícita
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  
  // ============================================================
  // OPÇÃO 2: Configuração nativa (Android/iOS)
  // ============================================================
  // Android: Configure em android/app/build.gradle
  // iOS: Configure em Info.plist
  //
  // Depois, leia com platform channels ou use package como:
  // flutter_config: ^2.0.2
  
  // ============================================================
  // OPÇÃO 3: Para desenvolvimento local (não commitar .env)
  // ============================================================
  // Se usar flutter_dotenv para dev local:
  // 1. Crie .env na raiz (já está no .gitignore)
  // 2. NÃO adicione ao pubspec.yaml assets
  // 3. Use apenas em modo debug
  
  /// Valida se a configuração está completa
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
  
  /// Lança erro se configuração estiver incompleta
  static void validate() {
    if (!isConfigured) {
      throw StateError(
        'App não configurado!\n\n'
        'Configure as variáveis de ambiente:\n'
        '- SUPABASE_URL\n'
        '- SUPABASE_ANON_KEY\n\n'
        'Opção 1 (build-time):\n'
        'flutter run --dart-define=SUPABASE_URL=https://... \\\n'
        '           --dart-define=SUPABASE_ANON_KEY=...\n\n'
        'Opção 2 (local dev):\n'
        'Crie arquivo .env na raiz do projeto (não commitar!)\n'
      );
    }
  }
  
  /// Flag de modo de desenvolvimento
  static bool get isDevelopment => kDebugMode;
  
  /// Flag de modo de produção
  static bool get isProduction => kReleaseMode;
  
  // Outras configurações
  static const String appName = 'Suevit';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheExpiration = Duration(hours: 24);
  
  // Feature flags (podem ser configurados remotamente)
  static const bool enableVoiceSearch = true;
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = true;
}
