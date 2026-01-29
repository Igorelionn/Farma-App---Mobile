import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/svg_icon.dart';
import '../../../core/services/voice_recognition_service.dart';

class AnimatedSearchBar extends StatefulWidget {
  final VoidCallback onTap;
  final Function(String)? onVoiceSearch;
  
  const AnimatedSearchBar({
    super.key,
    required this.onTap,
    this.onVoiceSearch,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Timer _timer;
  int _currentIndex = 0;
  
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  bool _isListening = false;
  String? _recognizedText;

  final List<String> _searchTexts = [
    'O que você precisa hoje?',
    'Dipirona, Paracetamol...',
    'Amoxicilina, Azitromicina...',
    'Omeprazol, Losartana...',
    'Luvas, Seringas, Agulhas...',
    'Gazes, Curativos...',
    'Soro fisiológico...',
    'Fraldas geriátricas...',
    'Vitamina C, Complexo B...',
    'Álcool 70%, Água oxigenada...',
    'Ibuprofeno, Cefalexina...',
    'Materiais hospitalares...',
  ];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Fade suave
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Slide sutil de baixo para cima
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Iniciar animação
    _controller.forward();

    // Trocar texto a cada 4 segundos
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isListening) {
        _changeText();
      }
    });
    
    // Inicializar serviço de voz
    _initializeVoiceService();
  }
  
  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
  }

  void _changeText() async {
    // Fade out suave
    await _controller.reverse();
    
    // Trocar texto
    if (mounted) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _searchTexts.length;
      });
    }
    
    // Fade in suave com slide
    await _controller.forward();
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      // Parar escuta
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
        _recognizedText = null;
      });
    } else {
      // Iniciar escuta
      try {
        setState(() {
          _isListening = true;
          _recognizedText = null;
        });
        
        await _voiceService.startListening(
          onResult: (text) {
            // Texto final reconhecido
            setState(() {
              _recognizedText = text;
              _isListening = false;
            });
            
            // Executar busca com o texto reconhecido
            if (widget.onVoiceSearch != null && text.isNotEmpty) {
              widget.onVoiceSearch!(text);
            }
          },
          onPartialResult: (text) {
            // Texto parcial (enquanto está falando)
            setState(() {
              _recognizedText = text;
            });
          },
        );
      } catch (e) {
        developer.log('Erro ao iniciar busca por voz: $e', name: 'AnimatedSearchBar', error: e);
        setState(() {
          _isListening = false;
          _recognizedText = null;
        });
        
        // Mostrar mensagem de erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao acessar o microfone. Verifique as permissões.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _isListening 
              ? AppColors.primary.withValues(alpha: 0.1) 
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(28),
          border: _isListening 
              ? Border.all(color: AppColors.primary, width: 1.5) 
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: _isListening ? AppColors.primary : Colors.black54,
              size: 26,
              weight: 1.5,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ClipRect(
                child: _isListening || _recognizedText != null
                    ? Text(
                        _recognizedText ?? 'Escutando...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _isListening 
                              ? AppColors.primary 
                              : AppColors.textPrimary,
                          letterSpacing: 0.3,
                          fontWeight: _isListening 
                              ? FontWeight.w500 
                              : FontWeight.normal,
                        ),
                      )
                    : SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            _searchTexts[_currentIndex],
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggleVoiceSearch,
              child: SvgIcon(
                assetPath: 'assets/icons/microphone_icon.svg',
                size: 24,
                color: _isListening ? AppColors.primary : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

