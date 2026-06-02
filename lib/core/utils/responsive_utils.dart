import 'package:flutter/material.dart';

class ResponsiveUtils {
  // ============================================
  // DÉTECTER LA TAILLE DE L'ÉCRAN
  // ============================================

  /// Vérifie si c'est un téléphone (petit écran)
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Vérifie si c'est une tablette
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }

  /// Vérifie si c'est un ordinateur (grand écran)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  // ============================================
  // TAILLE RESPONSIVE DES ÉLÉMENTS
  // ============================================

  /// Retourne la taille des icônes selon l'écran
  static double getIconSize(BuildContext context, {double phone = 24, double tablet = 32, double desktop = 40}) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Retourne la taille des titres selon l'écran
  static double getTitleSize(BuildContext context, {double phone = 20, double tablet = 24, double desktop = 28}) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Retourne la taille du texte selon l'écran
  static double getBodySize(BuildContext context, {double phone = 16, double tablet = 14, double desktop = 16}) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Retourne le padding selon l'écran
  static double getPadding(BuildContext context, {double phone = 16, double tablet = 24, double desktop = 32}) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Retourne le radius des bordures selon l'écran
  static double getRadius(BuildContext context, {double phone = 12, double tablet = 14, double desktop = 16}) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // ============================================
  // OBTENIR LA LARGEUR MAXIMALE DU CONTENU
  // ============================================

  /// Retourne la largeur maximale pour le contenu
  /// - Téléphone: 100% de l'écran
  /// - Tablette: max 600px
  /// - Desktop: max 800px (comme une app mobile)
  static double getMaxContentWidth(BuildContext context) {
    if (isPhone(context)) {
      return double.infinity; // 100% sur téléphone
    } else if (isTablet(context)) {
      return 600; // Max 600px sur tablette
    } else {
      return 600; // Max 600px sur desktop (comme mobile)
    }
  }

  // ============================================
  // CENTRER LE CONTENU SUR GRAND ÉCRAN
  // ============================================

  /// Wrap qui centre le contenu et limite la largeur sur grand écran
  static Widget centerWithMaxWidth(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }

  // ============================================
  // GRILLE ADAPTATIVE
  // ============================================

  /// Retourne le nombre de colonnes selon l'écran
  static int getGridCrossAxisCount(BuildContext context) {
    if (isPhone(context)) {
      return 2; // Téléphone: 2 colonnes
    } else {
      return 3; // Tablette/Desktop: 3-4 colonnes
    }
  }

  /// Retourne l'espacement selon l'écran
  static double getGridSpacing(BuildContext context) {
    if (isPhone(context)) {
      return 8;
    } else {
      return 16;
    }
  }

  // ============================================
  // RÉSOLUTION DE L'ÉCRAN
  // ============================================

  /// Retourne le DPR (Device Pixel Ratio) pour les icônes HD
  static double getDevicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Vérifie si l'écran est HD ou plus
  static bool isHighDensity(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio > 2.0;
  }

  // ============================================
  // TAILLE EN POURCENTAGE
  // ============================================

  /// Retourne une largeur en pourcentage de l'écran
  static double getWidthPercent(BuildContext context, double percent) {
    return MediaQuery.of(context).size.width * (percent / 100);
  }

  /// Retourne une hauteur en pourcentage de l'écran
  static double getHeightPercent(BuildContext context, double percent) {
    return MediaQuery.of(context).size.height * (percent / 100);
  }

  // ============================================
  // LARGEUR MAXIMALE DES CONTAINERS
  // ============================================

  /// Retourne la largeur maximale des cards/containers
  static double getMaxContainerWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return screenWidth * 0.9; // 90% sur téléphone
    } else if (screenWidth < 900) {
      return 500; // Max 500px sur tablette
    } else {
      return 600; // Max 600px sur desktop
    }
  }
}
