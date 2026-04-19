import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class PasswordResetConfirmationScreen extends StatefulWidget {
  final String email;

  const PasswordResetConfirmationScreen({
    super.key,
    required this.email,
  });

  @override
  State<PasswordResetConfirmationScreen> createState() =>
      _PasswordResetConfirmationScreenState();
}

class _PasswordResetConfirmationScreenState
    extends State<PasswordResetConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decoração de fundo sutil
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.03),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Animated check icon in circle
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(100, 100),
                        painter: _CheckCirclePainter(
                          circleProgress: _circleAnimation.value,
                          checkProgress: _checkAnimation.value,
                          color: const Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Email enviado!',
                    style: GoogleFonts.urbanist(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enviamos um link de recuperação para:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Instruções
                  _buildInstruction('Verifique sua caixa de entrada'),
                  const SizedBox(height: 14),
                  _buildInstruction('Não esqueça de verificar o spam'),
                  const SizedBox(height: 14),
                  _buildInstruction('O link expira em 24 horas'),
                  const Spacer(),
                  // Botão: Abrir Email
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Material(
                      color: AppColors.navBarBackground,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () async {
                          // Abrir app do Gmail
                          try {
                            final Uri gmailAppUri = Uri.parse('googlegmail://');
                            if (await canLaunchUrl(gmailAppUri)) {
                              await launchUrl(gmailAppUri);
                            } else {
                              // Fallback para qualquer app de email
                              final Uri emailUri = Uri(
                                scheme: 'mailto',
                                path: widget.email,
                              );
                              await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Não foi possível abrir o app de email',
                                    style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Abrir Email',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botão: Voltar (texto simples)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Voltar',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navBarBackground,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for animated check circle
class _CheckCirclePainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;

  _CheckCirclePainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circle
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -90 * (3.14159 / 180), // Start from top
      360 * circleProgress * (3.14159 / 180),
      false,
      circlePaint,
    );

    // Draw check mark
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final checkPath = Path();
      
      // Check mark coordinates (relative to center)
      final point1 = Offset(center.dx - radius * 0.35, center.dy);
      final point2 = Offset(center.dx - radius * 0.1, center.dy + radius * 0.3);
      final point3 = Offset(center.dx + radius * 0.4, center.dy - radius * 0.35);

      // Draw first line (short part of check)
      final line1Progress = (checkProgress * 2).clamp(0.0, 1.0);
      final line1End = Offset.lerp(point1, point2, line1Progress)!;

      checkPath.moveTo(point1.dx, point1.dy);
      checkPath.lineTo(line1End.dx, line1End.dy);

      // Draw second line (long part of check)
      if (checkProgress > 0.5) {
        final line2Progress = ((checkProgress - 0.5) * 2).clamp(0.0, 1.0);
        final line2End = Offset.lerp(point2, point3, line2Progress)!;
        checkPath.lineTo(line2End.dx, line2End.dy);
      }

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckCirclePainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
        oldDelegate.checkProgress != checkProgress;
  }
}
