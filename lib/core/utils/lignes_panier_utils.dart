import 'dart:convert';

import '../../data/models/produit_model.dart';
import 'packaging_utils.dart';

/// Sérialisation / parsing des lignes panier pour restauration stock à l'annulation.
class LignesPanierUtils {
  static List<Map<String, dynamic>> fromPanier(List<Map<String, dynamic>> panier) {
    return panier
        .map((item) => {
              'produit_id': item['produit_id']?.toString(),
              'nom': item['nom']?.toString(),
              'quantite': item['quantite'] ?? 1,
              'facteur_conversion': item['facteur_conversion'] ?? 1.0,
            })
        .where((l) {
          final id = l['produit_id']?.toString();
          return id != null && id.isNotEmpty;
        })
        .toList();
  }

  static List<Map<String, dynamic>> parse(dynamic raw) {
    if (raw == null) return [];

    dynamic decoded = raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        return [];
      }
    }

    if (decoded is! List) return [];

    final result = <Map<String, dynamic>>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final id = map['produit_id']?.toString();
      if (id == null || id.isEmpty) continue;
      result.add({
        'produit_id': id,
        'quantite': map['quantite'] ?? 1,
        'facteur_conversion': map['facteur_conversion'] ?? 1.0,
      });
    }
    return result;
  }

  static double volumeLigne(Map<String, dynamic> ligne) {
    final qty = (ligne['quantite'] ?? 1).toDouble();
    final factor = (ligne['facteur_conversion'] ?? 1.0).toDouble();
    return qty * factor;
  }

  /// Repli si [lignes_panier] absent en base : parse « Riz (x1), Huile (x2) ».
  static List<Map<String, dynamic>> parseFromNomProduit(
    String resume,
    List<ProduitModel> produits, {
    String? typeVente,
  }) {
    if (resume.trim().isEmpty || produits.isEmpty) return [];

    final pattern = RegExp(r'^(.+?)\s*\(x\s*(\d+(?:\.\d+)?)\s*\)$', caseSensitive: false);
    final result = <Map<String, dynamic>>[];

    for (final part in resume.split(', ')) {
      final match = pattern.firstMatch(part.trim());
      if (match == null) continue;

      final name = match.group(1)!.trim().toLowerCase();
      final qtyRaw = double.tryParse(match.group(2)!) ?? 1;
      final found = _findProductByName(name, produits);
      if (found?.id == null) continue;

      final factor = typeVente != null && typeVente.isNotEmpty
          ? PackagingUtils.factorToBase(found!, typeVente)
          : 1.0;

      result.add({
        'produit_id': found!.id,
        'quantite': qtyRaw == qtyRaw.roundToDouble() ? qtyRaw.toInt() : qtyRaw,
        'facteur_conversion': factor,
      });
    }
    return result;
  }

  static ProduitModel? _findProductByName(String name, List<ProduitModel> produits) {
    for (final p in produits) {
      if (p.nom.trim().toLowerCase() == name) return p;
    }
    ProduitModel? partial;
    for (final p in produits) {
      final pn = p.nom.trim().toLowerCase();
      if (pn.contains(name) || name.contains(pn)) {
        partial = p;
        break;
      }
    }
    return partial;
  }
}
