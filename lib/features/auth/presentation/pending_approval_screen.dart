import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../core/services/supabase_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

// Status que o cadastro pode assumir
enum _ApprovalStatus { pending, underReview, approved, rejected }

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  static const _kEmerald = Color(0xFF10B981);
  static const _kDark = Color(0xFF111827);
  static const _kHint = Color(0xFF9CA3AF);
  static const _kBg = Color(0xFFF8F9FB);

  _ApprovalStatus _status = _ApprovalStatus.pending;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadCurrentStatus() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() => _status = _parseStatus(data['status'] as String?));
      }
    } catch (_) {}
  }

  void _subscribeToChanges() {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    _channel = SupabaseService.client
        .channel('profile-status-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['status'] as String?;
            if (mounted) {
              setState(() => _status = _parseStatus(newStatus));
              if (_status == _ApprovalStatus.approved) {
                context.read<AuthBloc>().add(AuthCheckRequested());
              }
            }
          },
        )
        .subscribe();
  }

  _ApprovalStatus _parseStatus(String? raw) {
    return switch (raw) {
      'under_review' => _ApprovalStatus.underReview,
      'approved' => _ApprovalStatus.approved,
      'rejected' => _ApprovalStatus.rejected,
      _ => _ApprovalStatus.pending,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.read<AuthBloc>().add(LogoutRequested());
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F1F3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 20, color: _kDark),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícone animado de status
                      Center(child: _StatusIcon(status: _status)),
                      const SizedBox(height: 28),

                      // Título e subtítulo
                      Center(
                        child: Column(
                          children: [
                            Text(
                              _statusTitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.urbanist(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _kDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _statusSubtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
                                color: _kHint,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Linha do tempo do processo
                      Text(
                        'Status do cadastro',
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kHint,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TimelineStep(
                        icon: Icons.cloud_upload_outlined,
                        label: 'Documentos recebidos',
                        description: 'Todos os seus dados e arquivos chegaram.',
                        state: _stepState(0),
                        isLast: false,
                      ),
                      _TimelineStep(
                        icon: Icons.manage_search_rounded,
                        label: 'Em análise',
                        description:
                            'Nossa equipe está verificando as informações.',
                        state: _stepState(1),
                        isLast: false,
                      ),
                      _TimelineStep(
                        icon: Icons.verified_outlined,
                        label: 'Validação dos documentos',
                        description:
                            'Licenças e autorizações estão sendo conferidas.',
                        state: _stepState(2),
                        isLast: false,
                      ),
                      _TimelineStep(
                        icon: _status == _ApprovalStatus.rejected
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline_rounded,
                        label: _status == _ApprovalStatus.rejected
                            ? 'Cadastro reprovado'
                            : 'Aprovação',
                        description: _status == _ApprovalStatus.rejected
                            ? 'Entre em contato para mais informações.'
                            : 'Acesso liberado ao catálogo e pedidos.',
                        state: _stepState(3),
                        isLast: true,
                      ),

                      const SizedBox(height: 40),

                      // Info de prazo
                      if (_status != _ApprovalStatus.approved &&
                          _status != _ApprovalStatus.rejected)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFE6E7EA), width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(Icons.access_time_rounded,
                                    size: 18, color: _kHint),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Prazo de análise: até 7 dias úteis',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Esta página é atualizada automaticamente assim que houver mudança no status.',
                                      style: GoogleFonts.urbanist(
                                          fontSize: 12.5,
                                          color: _kHint,
                                          height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Botão de sair
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () =>
                          context.read<AuthBloc>().add(LogoutRequested()),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: const Color(0xFFE6E7EA)),
                        ),
                        child: Center(
                          child: Text(
                            'Sair',
                            style: GoogleFonts.urbanist(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kDark,
                            ),
                          ),
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
    );
  }

  // Título conforme status
  String get _statusTitle => switch (_status) {
        _ApprovalStatus.pending => 'Cadastro recebido!',
        _ApprovalStatus.underReview => 'Em análise',
        _ApprovalStatus.approved => 'Cadastro aprovado!',
        _ApprovalStatus.rejected => 'Cadastro reprovado',
      };

  String get _statusSubtitle => switch (_status) {
        _ApprovalStatus.pending =>
          'Seus documentos foram recebidos e\nestão na fila para análise.',
        _ApprovalStatus.underReview =>
          'Nossa equipe está analisando\nseu cadastro agora.',
        _ApprovalStatus.approved =>
          'Bem-vindo! Seu acesso foi liberado.\nRedirecionando...',
        _ApprovalStatus.rejected =>
          'Seu cadastro não foi aprovado.\nEntre em contato para mais informações.',
      };

  // Determina o estado visual de cada etapa da linha do tempo
  _StepState _stepState(int index) {
    final currentIndex = switch (_status) {
      _ApprovalStatus.pending => 0,
      _ApprovalStatus.underReview => 1,
      _ApprovalStatus.approved => 3,
      _ApprovalStatus.rejected => 3,
    };

    if (_status == _ApprovalStatus.rejected && index == 3) {
      return _StepState.rejected;
    }
    if (index < currentIndex) return _StepState.done;
    if (index == currentIndex) return _StepState.active;
    return _StepState.pending;
  }
}

// ── Ícone animado de status ──

class _StatusIcon extends StatelessWidget {
  final _ApprovalStatus status;
  const _StatusIcon({required this.status});

  static const _kEmerald = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color bg, Color fg) = switch (status) {
      _ApprovalStatus.pending => (
          Icons.hourglass_top_rounded,
          const Color(0xFFFFFBEB),
          const Color(0xFFF59E0B)
        ),
      _ApprovalStatus.underReview => (
          Icons.manage_search_rounded,
          const Color(0xFFEFF6FF),
          const Color(0xFF3B82F6)
        ),
      _ApprovalStatus.approved => (
          Icons.check_rounded,
          _kEmerald.withValues(alpha: 0.1),
          _kEmerald
        ),
      _ApprovalStatus.rejected => (
          Icons.close_rounded,
          const Color(0xFFFFECEC),
          const Color(0xFFEF4444)
        ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: child),
      child: Container(
        key: ValueKey(status),
        width: 80,
        height: 80,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 38, color: fg),
      ),
    );
  }
}

// ── Etapa da linha do tempo ──

enum _StepState { pending, active, done, rejected }

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final _StepState state;
  final bool isLast;

  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.description,
    required this.state,
    required this.isLast,
  });

  static const _kEmerald = Color(0xFF10B981);
  static const _kDark = Color(0xFF111827);
  static const _kHint = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final (Color lineColor, Color iconBg, Color iconFg, Color textColor) =
        switch (state) {
      _StepState.done => (
          _kEmerald,
          _kEmerald.withValues(alpha: 0.12),
          _kEmerald,
          _kDark
        ),
      _StepState.active => (
          const Color(0xFFE6E7EA),
          const Color(0xFFEFF6FF),
          const Color(0xFF3B82F6),
          _kDark
        ),
      _StepState.rejected => (
          const Color(0xFFE6E7EA),
          const Color(0xFFFFECEC),
          const Color(0xFFEF4444),
          _kDark
        ),
      _StepState.pending => (
          const Color(0xFFE6E7EA),
          const Color(0xFFF0F1F3),
          _kHint,
          _kHint
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone + linha vertical
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(
                state == _StepState.done ? Icons.check_rounded : icon,
                size: 18,
                color: iconFg,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Texto
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.urbanist(
                      fontSize: 12.5, color: _kHint, height: 1.4),
                ),
                if (!isLast) const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
