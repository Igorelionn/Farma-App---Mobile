import 'package:flutter/foundation.dart';

/// Logger de aplicação com suporte a diferentes níveis e modo de debug
/// 
/// Em modo de produção, erros podem ser enviados para serviços externos
/// como Sentry, Firebase Crashlytics, etc.
class AppLogger {
  /// Log de informação geral (apenas em debug)
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[INFO]';
      debugPrint('$prefix $message');
    }
  }

  /// Log de aviso (apenas em debug)
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[WARNING]';
      debugPrint('⚠️ $prefix $message');
    }
  }

  /// Log de erro
  /// Em produção, pode ser enviado para serviço de monitoramento
  static void error(String message, [dynamic error, StackTrace? stackTrace, String? tag]) {
    final prefix = tag != null ? '[$tag]' : '[ERROR]';
    
    if (kDebugMode) {
      debugPrint('❌ $prefix $message');
      if (error != null) {
        debugPrint('Details: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace:\n$stackTrace');
      }
    } else {
      // Em produção, enviar para serviço de monitoramento
      // Exemplo: Sentry.captureException(error, stackTrace: stackTrace);
      // Exemplo: FirebaseCrashlytics.instance.recordError(error, stackTrace);
      
      // Por enquanto, apenas log básico (sem detalhes sensíveis)
      debugPrint('$prefix $message');
    }
  }

  /// Log de debug (apenas em modo debug)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[DEBUG]';
      debugPrint('🔍 $prefix $message');
    }
  }

  /// Log de sucesso (apenas em debug)
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[SUCCESS]';
      debugPrint('✅ $prefix $message');
    }
  }

  /// Log de dados sensíveis (NUNCA em produção)
  /// Use apenas para debugging temporário
  static void sensitive(String message, dynamic data, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[SENSITIVE]';
      debugPrint('🔐 $prefix $message: $data');
      debugPrint('⚠️ ATENÇÃO: Remover este log antes de produção!');
    }
  }

  /// Registrar evento de analytics (sem dados sensíveis)
  static void analytics(String eventName, [Map<String, dynamic>? parameters]) {
    // Em produção, pode ser enviado para Firebase Analytics, Mixpanel, etc.
    // Exemplo: FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
    
    if (kDebugMode) {
      debugPrint('📊 [ANALYTICS] Event: $eventName');
      if (parameters != null) {
        debugPrint('   Parameters: $parameters');
      }
    }
  }

  /// Registrar início de operação
  static void startOperation(String operationName, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[OPERATION]';
      debugPrint('▶️ $prefix Starting: $operationName');
    }
  }

  /// Registrar fim de operação com duração
  static void endOperation(String operationName, Duration duration, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[OPERATION]';
      debugPrint('⏹️ $prefix Completed: $operationName (${duration.inMilliseconds}ms)');
    }
  }

  /// Wrapper para executar e medir tempo de operação
  static Future<T> timed<T>(
    String operationName,
    Future<T> Function() operation, {
    String? tag,
  }) async {
    final stopwatch = Stopwatch()..start();
    startOperation(operationName, tag);
    
    try {
      final result = await operation();
      stopwatch.stop();
      endOperation(operationName, stopwatch.elapsed, tag);
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      error(
        'Operation failed: $operationName (${stopwatch.elapsed.inMilliseconds}ms)',
        e,
        stackTrace,
        tag,
      );
      rethrow;
    }
  }
}
