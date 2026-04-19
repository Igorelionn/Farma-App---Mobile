import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'password_reset_confirmation_screen.dart';

const _kEmerald = Color(0xFF2DD4A8);
const _kDarkBg = Color(0xFF1F2D2B);
const _kGreen = Color(0xFF6B8F71);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  
  // Estados do botão
  bool _isLoading = false;
  bool _showError = false;
  bool _showErrorMessage = false;
  
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Limpar erro quando usuário digitar
    _usernameCtrl.addListener(_clearError);
    _passwordCtrl.addListener(_clearError);
  }

  void _clearError() {
    if (_showError || _showErrorMessage) {
      setState(() {
        _showError = false;
        _showErrorMessage = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usernameCtrl.removeListener(_clearError);
    _passwordCtrl.removeListener(_clearError);
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    
    // Validação básica
    if (username.isEmpty || password.isEmpty) {
      _showErrorAnimation();
      return;
    }
    
    if (username.length < 3 || password.length < 6) {
      _showErrorAnimation();
      return;
    }
    
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _showError = false;
      _showErrorMessage = false;
    });
    
    context.read<AuthBloc>().add(LoginSubmitted(
      username: username,
      password: password,
    ));
  }
  
  void _showErrorAnimation() async {
    // Passo 1: Mostra X vermelho
    setState(() {
      _isLoading = false;
      _showError = true;
      _showErrorMessage = false;
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Passo 2: Mostra mensagem
    if (mounted) {
      setState(() => _showErrorMessage = true);
      await Future.delayed(const Duration(milliseconds: 2000));
    }
    
    // Passo 3: Volta ao normal
    if (mounted) {
      setState(() {
        _showError = false;
        _showErrorMessage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    const headerHeight = 260.0;
    const overlapHeight = 32.0;

    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthState,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Stack(
              children: [
                // Header with background image
                Container(
                  width: double.infinity,
                  height: headerHeight + topPad,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('public/medicamentos_login.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(28, topPad + 44, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_pharmacy_rounded,
                              size: 28,
                              color: _kEmerald),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Bem-vindo\nde volta',
                          style: GoogleFonts.urbanist(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Faça login para acessar sua conta',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // White body overlapping the dark header
                Container(
                  margin: EdgeInsets.only(
                      top: headerHeight + topPad - overlapHeight),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LabelField(
                                label: 'Usuário',
                                ctrl: _usernameCtrl,
                                focus: _usernameFocus,
                                hint: 'Digite seu usuário',
                                icon: Icons.person_outline_rounded,
                                enabled: !_isLoading,
                                action: TextInputAction.next,
                                onSubmit: (_) => FocusScope.of(context)
                                    .requestFocus(_passwordFocus),
                              ),
                              const SizedBox(height: 22),
                              _LabelField(
                                label: 'Senha',
                                ctrl: _passwordCtrl,
                                focus: _passwordFocus,
                                hint: 'Digite sua senha',
                                icon: Icons.lock_outline_rounded,
                                enabled: !_isLoading,
                                obscure: _obscure,
                                action: TextInputAction.done,
                                onSubmit: (_) => _handleLogin(),
                                suffix: GestureDetector(
                                  onTap: () =>
                                      setState(() => _obscure = !_obscure),
                                  child: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 19,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _isLoading ? null : _showForgotSheet,
                                  child: Text(
                                    'Esqueci minha senha',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              _AnimatedLoginButton(
                                onTap: _handleLogin,
                                isLoading: _isLoading,
                                showError: _showError,
                                showErrorMessage: _showErrorMessage,
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  const Expanded(
                                      child: Divider(color: AppColors.border)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text('ou',
                                        style: GoogleFonts.urbanist(
                                            fontSize: 13,
                                            color: AppColors.textTertiary)),
                                  ),
                                  const Expanded(
                                      child: Divider(color: AppColors.border)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 50,
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    onTap: () => Navigator.of(context)
                                        .pushNamed('/register'),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person_add_outlined,
                                                size: 18,
                                                color:
                                                    AppColors.textSecondary),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Solicitar Cadastro',
                                              style: GoogleFonts.urbanist(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (state is AuthPendingApproval || state is AuthRejected) {
      // PendingApprovalScreen já exibe o status "reprovado" quando aplicável.
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacementNamed('/pending-approval');
    } else if (state is AuthError) {
      _showErrorAnimation();
    }
  }

  void _showForgotSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ForgotSheet(
        authRepository: context.read<AuthRepository>(),
        onSuccess: (email) {
          Navigator.pop(ctx);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PasswordResetConfirmationScreen(email: email),
            ),
          );
        },
      ),
    );
  }
}

// ── Animated Login Button ──

class _AnimatedLoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final bool showError;
  final bool showErrorMessage;

  const _AnimatedLoginButton({
    required this.onTap,
    required this.isLoading,
    required this.showError,
    required this.showErrorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: showError ? AppColors.error : AppColors.navBarBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isLoading || showError) ? null : onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  // Animação diferente para cada estado
                  if (child.key == const ValueKey('error-message')) {
                    // Animação de slide para "Credenciais inválidas"
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  }
                  // Animação padrão (fade + scale) para o resto
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildButtonContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        key: ValueKey('loading'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (showErrorMessage) {
      return Text(
        key: const ValueKey('error-message'),
        'Credenciais inválidas',
        style: GoogleFonts.urbanist(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      );
    }

    if (showError) {
      return const Icon(
        key: ValueKey('error-icon'),
        Icons.close_rounded,
        color: Colors.white,
        size: 28,
      );
    }

    return Text(
      key: const ValueKey('normal'),
      'Entrar',
      style: GoogleFonts.urbanist(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Shared widgets ──

class _LabelField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final FocusNode focus;
  final String hint;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final TextInputAction? action;
  final void Function(String)? onSubmit;
  final Widget? suffix;

  const _LabelField({
    required this.label,
    required this.ctrl,
    required this.focus,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.obscure = false,
    this.action,
    this.onSubmit,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.urbanist(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          focusNode: focus,
          obscureText: obscure,
          enabled: enabled,
          textInputAction: action,
          onSubmitted: onSubmit,
          style: GoogleFonts.urbanist(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary),
          cursorColor: _kEmerald,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.urbanist(
                fontSize: 14, color: AppColors.textTertiary),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, size: 19, color: AppColors.textTertiary),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 42),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12), child: suffix)
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            filled: true,
            fillColor: const Color(0xFFF6F7F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kEmerald, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _GreenButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _GreenButton(
      {required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Material(
        color: _kGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)))
                : Text(label,
                    style: GoogleFonts.urbanist(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }
}

class _ForgotSheet extends StatefulWidget {
  final AuthRepository authRepository;
  final void Function(String email) onSuccess;
  
  const _ForgotSheet({
    required this.authRepository,
    required this.onSuccess,
  });

  @override
  State<_ForgotSheet> createState() => _ForgotSheetState();
}

class _ForgotSheetState extends State<_ForgotSheet> {
  static const _maxAttempts = 3;
  static const _cooldownSeconds = 60;

  // Controle global de tentativas por email (persiste enquanto o app estiver aberto)
  static final Map<String, int> _attempts = {};
  static final Map<String, DateTime> _cooldownUntil = {};

  final _ctrl = TextEditingController();
  bool _isLoading = false;
  bool _showSuccess = false;
  bool _showError = false;
  bool _showErrorMessage = false;
  String _errorText = 'Email inválido';
  String? _infoText;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _ctrl.text.trim().toLowerCase();

    if (email.isEmpty) return;

    final emailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!emailValid) {
      _showErrorAnimation();
      return;
    }

    // Verifica cooldown
    final cooldown = _cooldownUntil[email];
    if (cooldown != null && DateTime.now().isBefore(cooldown)) {
      final remaining = cooldown.difference(DateTime.now()).inSeconds;
      _showErrorAnimation(
          message: 'Aguarde ${remaining}s para tentar novamente');
      return;
    }

    // Verifica tentativas
    final count = _attempts[email] ?? 0;
    if (count >= _maxAttempts) {
      _cooldownUntil[email] =
          DateTime.now().add(const Duration(seconds: _cooldownSeconds));
      _attempts[email] = 0;
      _showErrorAnimation(message: 'Limite atingido. Aguarde 1 minuto.');
      return;
    }

    setState(() {
      _isLoading = true;
      _showError = false;
      _showErrorMessage = false;
      _infoText = null;
    });

    try {
      await widget.authRepository.requestPasswordReset(email);

      // Só conta como tentativa quando o envio foi bem-sucedido
      _attempts[email] = (count + 1);

      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) widget.onSuccess(email);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('rate_limit') || msg.contains('rate limit')) {
        _cooldownUntil[email] =
            DateTime.now().add(const Duration(seconds: _cooldownSeconds));
        _showErrorAnimation(message: 'Limite atingido. Aguarde 1 minuto.');
      } else {
        // Erro não conta como tentativa
        _showErrorAnimation(message: 'Erro ao enviar. Tente novamente.');
      }
    }
  }

  void _showErrorAnimation({String message = 'Email inválido'}) async {
    setState(() {
      _isLoading = false;
      _showError = true;
      _showErrorMessage = false;
      _errorText = message;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _showErrorMessage = true);
      await Future.delayed(const Duration(milliseconds: 2000));
    }

    if (mounted) {
      setState(() {
        _showError = false;
        _showErrorMessage = false;
        _infoText = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        bottom: bottomInset > 0 ? bottomInset : bottomPadding + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Recuperar senha',
                style: GoogleFonts.urbanist(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Informe seu email para receber o link',
                style: GoogleFonts.urbanist(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _ctrl,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading && !_showSuccess && !_showError,
              style: GoogleFonts.urbanist(fontSize: 15),
              cursorColor: _kEmerald,
              decoration: InputDecoration(
                hintText: 'seu@email.com',
                hintStyle: GoogleFonts.urbanist(
                    fontSize: 14, color: AppColors.textTertiary),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 10),
                  child: Icon(Icons.email_outlined,
                      size: 19, color: AppColors.textTertiary),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 42),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: const Color(0xFFF6F7F8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _kEmerald, width: 1.5)),
              ),
            ),
            if (_infoText != null) ...[
              const SizedBox(height: 10),
              Text(
                _infoText!,
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 24),
            _AnimatedSubmitButton(
              isLoading: _isLoading,
              showSuccess: _showSuccess,
              showError: _showError,
              showErrorMessage: _showErrorMessage,
              errorText: _errorText,
              onTap: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

// Botão animado para o modal de recuperação
class _AnimatedSubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool showSuccess;
  final bool showError;
  final bool showErrorMessage;
  final String errorText;
  final VoidCallback onTap;

  const _AnimatedSubmitButton({
    required this.isLoading,
    required this.showSuccess,
    required this.showError,
    required this.showErrorMessage,
    this.errorText = 'Email inválido',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color buttonColor = AppColors.navBarBackground;
    if (showSuccess) {
      buttonColor = const Color(0xFF10B981); // Verde vibrante e moderno
    } else if (showError) {
      buttonColor = AppColors.error;
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isLoading || showSuccess || showError) ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  // Animação diferente para a mensagem de erro
                  if (child.key == const ValueKey('error-message')) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  }
                  // Animação padrão para o resto
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildButtonContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        key: ValueKey('loading'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (showErrorMessage) {
      return Text(
        key: ValueKey('error-message-$errorText'),
        errorText,
        style: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }

    if (showError) {
      return const Icon(
        key: ValueKey('error-icon'),
        Icons.close_rounded,
        color: Colors.white,
        size: 28,
      );
    }

    if (showSuccess) {
      return const Icon(
        key: ValueKey('success'),
        Icons.check_rounded,
        color: Colors.white,
        size: 28,
      );
    }

    return Text(
      key: const ValueKey('normal'),
      'Enviar',
      style: GoogleFonts.urbanist(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }
}
