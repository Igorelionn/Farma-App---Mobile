import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class RegisterSuccessScreen extends StatefulWidget {
  const RegisterSuccessScreen({super.key});

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _fadeAnimation;

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
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
                color: const Color(0xFF10B981).withValues(alpha: 0.03),
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
                color: const Color(0xFF10B981).withValues(alpha: 0.03),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Círculo animado com check
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
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
                  // Título e subtítulo com fade
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Cadastro solicitado!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.urbanist(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Seus dados e documentos foram\nrecebidos com sucesso.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.urbanist(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _buildItem(Icons.manage_search_rounded,
                            'Nossa equipe irá analisar seu cadastro'),
                        const SizedBox(height: 14),
                        _buildItem(Icons.verified_outlined,
                            'Licenças e autorizações serão verificadas'),
                        const SizedBox(height: 14),
                        _buildItem(Icons.notifications_outlined,
                            'Você receberá o retorno em até 7 dias úteis'),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Material(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => Navigator.of(context)
                              .pushReplacementNamed('/pending-approval'),
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: Text(
                              'Acompanhar cadastro',
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
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

  Widget _buildItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF10B981)),
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

class _CheckCirclePainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;

  const _CheckCirclePainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -90 * (3.14159 / 180),
      360 * circleProgress * (3.14159 / 180),
      false,
      circlePaint,
    );

    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final checkPath = Path();

      final point1 = Offset(center.dx - radius * 0.35, center.dy);
      final point2 =
          Offset(center.dx - radius * 0.1, center.dy + radius * 0.3);
      final point3 =
          Offset(center.dx + radius * 0.4, center.dy - radius * 0.35);

      final line1Progress = (checkProgress * 2).clamp(0.0, 1.0);
      final line1End = Offset.lerp(point1, point2, line1Progress)!;

      checkPath.moveTo(point1.dx, point1.dy);
      checkPath.lineTo(line1End.dx, line1End.dy);

      if (checkProgress > 0.5) {
        final line2Progress = ((checkProgress - 0.5) * 2).clamp(0.0, 1.0);
        final line2End = Offset.lerp(point2, point3, line2Progress)!;
        checkPath.lineTo(line2End.dx, line2End.dy);
      }

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckCirclePainter old) =>
      old.circleProgress != circleProgress || old.checkProgress != checkProgress;
}
