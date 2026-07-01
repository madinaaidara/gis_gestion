import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/packaging_utils.dart';
import '../../../data/models/produit_model.dart';

/// Couleurs & textes simples pour la page Produits (accessible, sans jargon).
class ProduitUi {
  static const Color bg = Color(0xFF050505);
  static const Color surface = Color(0xFF0E0E10);
  static const Color surfaceHi = Color(0xFF161618);
  static const Color border = Color(0xFF222226);
  static const Color text = Color(0xFFF5F5F7);
  static const Color textMute = Color(0xFF8A8A92);
  static const Color textDim = Color(0xFF5C5C63);
  static const Color accent = Color(0xFF7C5CFF);
  static const Color accentSoft = Color(0xFFB8A4FF);
  static const Color achat = Color(0xFFF59E0B);
  static const Color vente = Color(0xFF22C55E);
  static const Color stock = Color(0xFF3B82F6);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);

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

  static Color stockColor(ProduitModel p) {
    switch (PackagingUtils.stockLevel(p)) {
      case StockLevel.rupture:
        return danger;
      case StockLevel.faible:
        return warning;
      case StockLevel.ok:
        return success;
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
                    style: GoogleFonts.plusJakartaSans(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                if (title.isNotEmpty) const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: ProduitUi.text, fontSize: 12, height: 1.4)),
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

  Widget _dot(String label, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: ProduitUi.textDim, fontSize: 11)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(spacing: 16, runSpacing: 6, children: [
        _dot('En stock', ProduitUi.success),
        _dot('Bientôt fini', ProduitUi.warning),
        _dot('Rupture', ProduitUi.danger),
      ]),
    );
  }
}

class ProduitStockBadge extends StatelessWidget {
  final ProduitModel product;

  const ProduitStockBadge({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final c = ProduitUi.stockColor(product);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        ProduitUi.stockLabelSimple(product),
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700),
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
                Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(color: ProduitUi.text, fontSize: 14, fontWeight: FontWeight.w700)),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [ProduitUi.accent.withValues(alpha: 0.18), ProduitUi.surfaceHi]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProduitUi.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: ProduitUi.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.storefront_rounded, color: ProduitUi.accentSoft, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Votre liste de produits', style: GoogleFonts.plusJakartaSans(color: ProduitUi.text, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'Touchez un produit pour voir les détails. Vert = OK · Orange = bientôt fini · Rouge = plus rien.',
                  style: TextStyle(color: ProduitUi.textMute, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
