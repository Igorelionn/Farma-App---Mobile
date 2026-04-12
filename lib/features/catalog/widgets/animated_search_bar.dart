import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/svg_icon.dart';
import '../../../core/services/voice_recognition_service.dart';

class AnimatedSearchBar extends StatefulWidget {
  final void Function(String query) onSearch;
  final Function(String)? onVoiceSearch;
  
  const AnimatedSearchBar({
    super.key,
    required this.onSearch,
    this.onVoiceSearch,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late AnimationController _placeholderController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Timer _placeholderTimer;
  int _currentIndex = 0;
  bool _isFocused = false;
  
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  bool _isListening = false;

  final List<String> _placeholders = [
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
    
    _placeholderController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _placeholderController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _placeholderController, curve: Curves.easeOutCubic),
    );

    _placeholderController.forward();

    _placeholderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isListening && !_isFocused && _textController.text.isEmpty) {
        _cyclePlaceholder();
      }
    });
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Quando perder o foco, limpa o texto e volta ao estado inicial
        if (_textController.text.isEmpty) {
          setState(() {
            _isFocused = false;
            _currentIndex = 0;
            _placeholderController.forward(from: 0);
          });
        } else {
          // Se tinha texto, limpa também
          _textController.clear();
          setState(() {
            _isFocused = false;
            _currentIndex = 0;
            _placeholderController.forward(from: 0);
          });
        }
      } else {
        setState(() {
          _isFocused = true;
        });
      }
    });
    
    _initializeVoiceService();
  }
  
  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
  }

  void _cyclePlaceholder() async {
    await _placeholderController.reverse();
    if (mounted) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _placeholders.length;
      });
    }
    await _placeholderController.forward();
  }

  void _handleSubmit(String value) {
    final query = value.trim();
    if (query.isNotEmpty) {
      _focusNode.unfocus();
      widget.onSearch(query);
    }
  }

  void _handleClear() {
    _textController.clear();
    setState(() {});
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      try {
        setState(() {
          _isListening = true;
        });
        
        await _voiceService.startListening(
          onResult: (text) {
            setState(() {
              _isListening = false;
              _textController.text = text;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: text.length),
              );
            });
            if (widget.onVoiceSearch != null && text.isNotEmpty) {
              widget.onVoiceSearch!(text);
            }
          },
          onPartialResult: (text) {
            setState(() {
              _textController.text = text;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: text.length),
              );
            });
          },
        );
      } catch (e) {
        developer.log('Erro ao iniciar busca por voz: $e', name: 'AnimatedSearchBar', error: e);
        setState(() {
          _isListening = false;
        });
        
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
    _placeholderTimer.cancel();
    _placeholderController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.isNotEmpty;
    final showPlaceholder = !_isFocused && !hasText && !_isListening;

    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.black54,
              size: 26,
              weight: 1.5,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Stack(
                children: [
                  TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: _handleSubmit,
                    onTapOutside: (event) {
                      _focusNode.unfocus();
                      if (_textController.text.isEmpty) {
                        setState(() {
                          _currentIndex = 0;
                          _placeholderController.forward(from: 0);
                        });
                      }
                    },
                    textInputAction: TextInputAction.search,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                    cursorColor: const Color(0xFF9CA3AF),
                    cursorHeight: 18,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (showPlaceholder)
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              _placeholders[_currentIndex],
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (hasText)
              GestureDetector(
                onTap: _handleClear,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
              ),
            GestureDetector(
              onTap: _toggleVoiceSearch,
              child: SvgIcon(
                assetPath: 'assets/icons/microphone_icon.svg',
                size: 24,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
