import 'package:flutter/material.dart';

/// Design System - Paleta Minimalista
/// Migração: Teal/Coral → Tons Escuros/Laranja (alto contraste, baixo impacto)
class AppColors {
  // Primary – Tom escuro minimalista (músico)
  static const Color primary = Color(0xFF37475A);
  static const Color primaryLight = Color(0xFFF0F3F7);
  static const Color primaryDark = Color(0xFF232F3E);

  // Accent – Laranja vibrante (banda)
  static const Color accent = Color(0xFFE47911);
  static const Color accentLight = Color(0xFFFCEEE3);

  // Branding (novos tokens)
  static const Color brandPrimary = Color(0xFFE47911); // Laranja
  static const Color utilityLink = Color(0xFF007EB9); // Azul para links

  // Neutros
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Texto
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF717171);
  static const Color textHint = Color(0xFF9E9E9E);

  // Bordas e divisores
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);

  // Feedback
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFB8C00);

  // Badge Counters
  static const Color badgeRed = Color(0xFFFF2828);

  // MaterialColor Swatch - Primary (#37475A)
  static MaterialColor get primarySwatch => const MaterialColor(
        0xFF37475A,
        <int, Color>{
          50: Color(0xFFF0F3F7),
          100: Color(0xFFD4DBE5),
          200: Color(0xFFB5C2D3),
          300: Color(0xFF96A8C1),
          400: Color(0xFF7E94B3),
          500: Color(0xFF37475A),
          600: Color(0xFF2F3E4F),
          700: Color(0xFF232F3E),
          800: Color(0xFF1A232E),
          900: Color(0xFF0F141A),
        },
      );

  // MaterialColor Swatch - Accent (#E47911)
  static MaterialColor get accentSwatch => const MaterialColor(
        0xFFE47911,
        <int, Color>{
          50: Color(0xFFFCEEE3),
          100: Color(0xFFF9D5B9),
          200: Color(0xFFF5BA8B),
          300: Color(0xFFF19E5D),
          400: Color(0xFFEE893A),
          500: Color(0xFFE47911),
          600: Color(0xFFD36F0F),
          700: Color(0xFFBF630C),
          800: Color(0xFFAB580A),
          900: Color(0xFF874405),
        },
      );
}
