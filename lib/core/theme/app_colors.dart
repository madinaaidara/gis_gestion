import 'package:flutter/material.dart';

/// ============================================
/// PALETTE DE COULEURS - GIS Gestion
/// ============================================
/// Design "Dark-Sidebar / Light-Content" style SaaS premium
/// Inspiré des grandes marques (Stripe, Linear, Notion)
/// ============================================

class AppColors {
  // ============================================
  // COULEURS PRIMAIRES (ACCENTS)
  // ============================================

  // Violet principal (couleur de marque)
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryIndigoLight = Color(0xFF818CF8);
  static const Color primaryIndigoDark = Color(0xFF4F46E5);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryPurpleLight = Color(0xFFA78BFA);
  static const Color primaryViolet = Color(0xFF8B5CF6);
  static const Color primaryVioletLight = Color(0xFFA78BFA);
  static const Color primaryVioletDark = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryGradientStart = Color(0xFF6366F1);
  static const Color primaryGradientEnd = Color(0xFF8B5CF6);
  static const Color primaryGradientLight = Color(0xFFA78BFA);
  static const Color primaryGradientDark = Color(0xFF7C3AED);

  // Cyan accent
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentCyanLight = Color(0xFF22D3EE);
  static const Color accentCyanDark = Color(0xFF0891B2);

  // Vert
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color primaryGreenLight = Color(0xFF34D399);
  static const Color primaryGreenDark = Color(0xFF059669);

  // Orange
  static const Color primaryOrange = Color(0xFFF59E0B);
  static const Color primaryOrangeLight = Color(0xFFFBBF24);
  static const Color primaryOrangeDark = Color(0xFFD97706);

  // ============================================
  // COULEURS DE STATUT
  // ============================================

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  static const Color successGradientStart = Color(0xFF10B981);
  static const Color successGradientEnd = Color(0xFF34D399);
  static const Color successGradient = successGradientStart;

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningGradientStart = Color(0xFFF59E0B);
  static const Color warningGradientEnd = Color(0xFFFBBF24);
  static const Color warningGradient = warningGradientStart;

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFF87171);
  static const Color dangerDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color primaryBlue = Color(0xFF3B82F6);

  // ============================================
  // THÈME SIDEBAR (SOMBRE)
  // ============================================

  static const Color sidebarBg = Color(0xFF1E1E2E);
  static const Color sidebarHover = Color(0xFF2A2A3E);
  static const Color sidebarActive = Color(0xFF2D2D4A);
  static const Color sidebarText = Color(0xFF9CA3AF);
  static const Color sidebarTextSelected = Color(0xFFFFFFFF);
  static const Color sidebarBorder = Color(0xFF363652);

  // ============================================
  // THÈME CONTENU (CLAIR)
  // ============================================

  static const Color background = Color(0xFFF1F5F9);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFFE2E8F0);

  // Surfaces (cartes)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceHover = Color(0xFFF1F5F9);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Header sections
  static const Color headerBg = Color(0xFF1E293B);
  static const Color headerBgLight = Color(0xFF334155);
  static const Color headerBgDark = Color(0xFF0F172A);
  static const Color headerGradient = Color(0xFF1E293B);

  // ============================================
  // BORDURES & DIVISEURS
  // ============================================

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);
  static const Color dividerDark = Color(0xFFCBD5E1);
  static const Color darkGradient = Color(0xFF1E293B);

  // ============================================
  // THÈME TEXTE
  // ============================================

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFFCBD5E1);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textInverse = Color(0xFF1F2937);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFF1F2937);

  // ============================================
  // GRADIENTS
  // ============================================

  static const List<Color> primaryGradient = [
    primaryIndigo,
    primaryPurple,
  ];

  static const List<Color> primaryGradientFull = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFA78BFA),
  ];

  static const List<Color> greenGradient = [
    primaryGreen,
    Color(0xFF059669),
  ];

  static const List<Color> cyanGradient = [
    accentCyan,
    Color(0xFF0891B2),
  ];

  static const List<Color> orangeGradient = [
    primaryOrange,
    Color(0xFFD97706),
  ];

  static const List<Color> dangerGradient = [
    danger,
    Color(0xFFDC2626),
  ];

  // ============================================
  // COULEURS INDICATEURS
  // ============================================

  // Profit
  static const Color profit = Color(0xFF10B981);
  static const Color profitBg = Color(0xFFECFDF5);

  // Perte
  static const Color loss = Color(0xFFEF4444);
  static const Color lossBg = Color(0xFFFEE2E2);

  // Marge faible
  static const Color lowMargin = Color(0xFFF59E0B);
  static const Color lowMarginBg = Color(0xFFFFFBEB);

  // Status backgrounds
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color infoBg = Color(0xFFDBEAFE);

  // ============================================
  // COULEURS SPÉCIALES
  // ============================================

  static const Color gold = Color(0xFFF59E0B);
  static const Color silver = Color(0xFF9CA3AF);
  static const Color bronze = Color(0xFFD97706);

  // Glow effects
  static const Color glowIndigo = Color(0x406366F1);
  static const Color glowPurple = Color(0x408B5CF6);
  static const Color glowCyan = Color(0x4006B6D4);
}

/// ============================================
/// STYLES DE TEXTE
/// ============================================

class AppTextStyles {
  // Titres
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Corps de texte
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );

  // Boutons
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Prix
  static const TextStyle price = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryIndigo,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryIndigo,
  );
}

/// ============================================
/// DÉCORATIONS COMMUNES
/// ============================================

class AppDecorations {
  // Carte claire avec ombre
  static BoxDecoration card = BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Carte hover
  static BoxDecoration cardHover = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryIndigo.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Bouton primaire avec dégradé
  static BoxDecoration buttonPrimary = BoxDecoration(
    gradient: const LinearGradient(colors: AppColors.primaryGradient),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryIndigo.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Bouton secondaire
  static BoxDecoration buttonSecondary = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border),
  );

  // Input clair
  static BoxDecoration input = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border),
  );

  static BoxDecoration inputFocused = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.primaryIndigo, width: 2),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryIndigo.withOpacity(0.1),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Surface elevated (cartes sur fond clair)
  static BoxDecoration surfaceElevated = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border, width: 1),
  );
}

/// ============================================
/// RAYONS COMMUNS
/// ============================================

class AppRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}