import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_surface.dart';
import '../../../core/theme/gis_palette.dart';
import '../../../core/theme/gis_theme_ext.dart';
import '../../../core/utils/packaging_utils.dart';
import '../../../data/models/produit_model.dart';

/// Couleurs & textes simples pour la page Produits (accessible, sans jargon).
class ProduitUi {
  static Color get bg => AppSurface.bg;
  static Color get surface => AppSurface.surface;
  static Color get surfaceHi => AppSurface.surfaceHi;
  static Color get border => AppSurface.border;
  static Color get text => AppSurface.text;
  static Color get textMute => AppSurface.textMute;
  static Color get textDim => AppSurface.textDim;
  static Color get accent => AppSurface.accent;
  static Color get accentSoft => AppSurface.accentSoft;
  static Color get achat => AppSurface.warning;
  static Color get vente => AppSurface.success;
  static Color get stock => AppSurface.info;
  static Color get danger => AppSurface.danger;
  static Color get warning => AppSurface.warning;
  static Color get success => AppSurface.success;

  static String stockLabelSimple(ProduitModel p) {
    switch (PackagingUtils.stockLevel(p)) {
      case StockLevel.rupture:
        return 'Rupture';
      case StockLevel.faible:
        return 'Bientôt fini';
      case StockLevel.ok:
        return 'En stock';
    }
  }

  static Color stockColor(BuildContext context, ProduitModel product) {
    final palette = GisPalette.of(context);
    switch (PackagingUtils.stockLevel(product)) {
      case StockLevel.rupture:
        return palette.danger;
      case StockLevel.faible:
        return palette.warning;
      case StockLevel.ok:
        return palette.success;
    }
  }

  static String gainSimple(double marge, String devise, String unite) {
    if (marge >= 0) {
      return 'Sur chaque $unite vendue, il vous reste ${marge.toStringAsFixed(0)} $devise dans la poche';
    }
    return 'Vous perdez ${marge.abs().toStringAsFixed(0)} $devise à chaque vente — augmentez le prix ou baissez l\'achat';
  }
}

class ProduitHelpTip extends StatelessWidget {
  final String title;
  final String message;
  final Color color;
  final IconData icon;

  const ProduitHelpTip({
    super.key,
    required this.title,
    required this.message,
    required this.color,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final text = GisPalette.of(context).text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                if (title.isNotEmpty) const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: text,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProduitStockLegend extends StatelessWidget {
  const ProduitStockLegend({super.key});

  Widget _dot(BuildContext context, String label, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: GisPalette.of(context).textMute, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(spacing: 16, runSpacing: 6, children: [
        _dot(context, 'En stock', p.success),
        _dot(context, 'Bientôt fini', p.warning),
        _dot(context, 'Rupture', p.danger),
      ]),
    );
  }
}

class ProduitStockBadge extends StatelessWidget {
  final ProduitModel product;

  const ProduitStockBadge({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final c = ProduitUi.stockColor(context, product);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        ProduitUi.stockLabelSimple(product),
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class ProduitInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const ProduitInfoTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(value, style: TextStyle(color: GisPalette.of(context).text, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProduitWelcomeStrip extends StatelessWidget {
  const ProduitWelcomeStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: p.isDark(context)
          ? BoxDecoration(
              gradient: LinearGradient(colors: [p.accent.withValues(alpha: 0.20), p.surfaceHi]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.accent.withValues(alpha: 0.28)),
            )
          : p.cardDecoration(context, radius: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: p.accentLinear(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre liste de produits',
                  style: GoogleFonts.plusJakartaSans(color: p.text, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Touchez un produit pour voir les détails. Vert = OK · Orange = bientôt fini · Rouge = plus rien.',
                  style: TextStyle(color: p.textMute, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
