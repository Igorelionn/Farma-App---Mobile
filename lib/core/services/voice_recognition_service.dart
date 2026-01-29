import 'dart:developer' as developer;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceRecognitionService {
  static final VoiceRecognitionService _instance = VoiceRecognitionService._internal();
  factory VoiceRecognitionService() => _instance;
  VoiceRecognitionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  /// Inicializa o serviço de reconhecimento de voz
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Verificar e solicitar permissão do microfone
      final permission = await Permission.microphone.request();
      
      if (!permission.isGranted) {
        return false;
      }

      // Inicializar o speech_to_text
      _isInitialized = await _speech.initialize(
        onError: (error) {
          developer.log('Erro no reconhecimento de voz: $error', name: 'VoiceRecognitionService', error: error);
          _isListening = false;
        },
        onStatus: (status) {
          developer.log('Status do reconhecimento: $status', name: 'VoiceRecognitionService');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      return _isInitialized;
    } catch (e) {
      developer.log('Erro ao inicializar reconhecimento de voz: $e', name: 'VoiceRecognitionService', error: e);
      return false;
    }
  }

  /// Inicia a escuta do microfone
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Falha ao inicializar reconhecimento de voz');
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          
          if (result.finalResult) {
            onResult(text);
            _isListening = false;
          } else if (onPartialResult != null) {
            onPartialResult(text);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
        localeId: 'pt_BR',
      );
    } catch (e) {
      developer.log('Erro ao iniciar escuta: $e', name: 'VoiceRecognitionService', error: e);
      _isListening = false;
      rethrow;
    }
  }

  /// Para a escuta do microfone
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Cancela a escuta
  Future<void> cancel() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }

  /// Verifica se o reconhecimento de voz está disponível
  Future<bool> isAvailable() async {
    try {
      return await _speech.initialize();
    } catch (e) {
      return false;
    }
  }

  /// Obtém os idiomas disponíveis
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final locales = await _speech.locales();
    return locales.map((locale) => locale.localeId).toList();
  }

  /// Libera os recursos
  void dispose() {
    _speech.stop();
    _isListening = false;
  }
}

