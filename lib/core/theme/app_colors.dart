import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Verde Esmeralda Azulado Suevit
  static const Color primary = Color(0xFF11F2D4); // rgb(17, 242, 212) - Ciano
  static const Color primaryLight = Color(0xFF34D399); // Verde claro azulado
  static const Color primaryDark = Color(0xFF059669); // Verde escuro azulado
  
  // Secondary Colors - Cinza Suevit
  static const Color secondary = Color(0xFF374151); // Cinza mais escuro
  static const Color secondaryLight = Color(0xFF6B7280); // Cinza médio
  static const Color secondaryDark = Color(0xFF1F2937); // Cinza bem escuro
  
  // Accent Colors
  static const Color accent = Color(0xFFEF4444); // Vermelho para alertas
  static const Color accentOrange = Color(0xFFF59E0B); // Laranja para avisos
  
  // Neutral Colors
  static const Color background = Color(0xFFFFFFFF); // Branco puro
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  
  // Navigation Bar
  static const Color navBarBackground = Color(0xFF020B21); // rgb(2, 11, 33)
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Surface Colors
  static const Color surfaceLight = Color(0xFFF5F6F7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  
  // Status Colors
  static const Color success = Color(0xFF059669);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Specific to Pharmacy/Medical
  static const Color tarjaVermelha = Color(0xFFDC2626);
  static const Color tarjaPreta = Color(0xFF1F2937);
  static const Color tarjaAmarela = Color(0xFFFBBF24);
  
  // Gradient (Mais Discreto)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF374151), Color(0xFF4B5563)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

