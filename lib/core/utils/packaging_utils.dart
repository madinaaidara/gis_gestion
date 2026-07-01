import '../../data/models/produit_model.dart';

enum StockLevel { ok, faible, rupture }

/// Options de vente avec conversion vers l'unité de base (stock).
class SaleUnitOption {
  final String unite;
  final String label;
  final double factorToBase;

  const SaleUnitOption({
    required this.unite,
    required this.label,
    required this.factorToBase,
  });
}

/// Conversions conditionnement (2 ou 3 niveaux) et unités poids/volume.
class PackagingUtils {
  static bool hasThreeLevels(ProduitModel p) => p.hasPackagingIntermediaire;

  /// Pièces/kg/ml de base contenues dans 1 lot d'achat (paquet, carton…).
  static double baseUnitsPerLot(ProduitModel p) {
    if (p.hasPackagingIntermediaire) {
      return p.quantiteIntermediaireParLot! * p.quantiteBaseParIntermediaire!;
    }
    return p.quantiteParUnite > 0 ? p.quantiteParUnite : 1;
  }

  static List<SaleUnitOption> saleOptions(ProduitModel p) {
    final String base = p.uniteVente ?? 'pièce';
    final options = <SaleUnitOption>[
      SaleUnitOption(unite: base, label: base, factorToBase: 1),
    ];

    if (p.hasPackagingIntermediaire) {
      final inter = p.uniteIntermediaire!;
      final qteInter = p.quantiteBaseParIntermediaire!;
      options.add(SaleUnitOption(
        unite: inter,
        label: inter,
        factorToBase: qteInter,
      ));
    }

    final lot = p.uniteAchat;
    if (lot != null && lot.isNotEmpty) {
      final lotFactor = baseUnitsPerLot(p);
      final alreadyListed = options.any((o) => o.unite == lot);
      if (lotFactor > 1 && !alreadyListed) {
        options.add(SaleUnitOption(unite: lot, label: lot, factorToBase: lotFactor));
      }
    }

    _appendWeightVolumeAlternatives(base, options);
    return options;
  }

  static void _appendWeightVolumeAlternatives(String base, List<SaleUnitOption> options) {
    if (base == 'kg' && !options.any((o) => o.unite == 'g')) {
      options.add(const SaleUnitOption(unite: 'g', label: 'g', factorToBase: 0.001));
    } else if (base == 'g' && !options.any((o) => o.unite == 'kg')) {
      options.add(const SaleUnitOption(unite: 'kg', label: 'kg', factorToBase: 1000));
    } else if (base == 'litre' && !options.any((o) => o.unite == 'ml')) {
      options.add(const SaleUnitOption(unite: 'ml', label: 'ml', factorToBase: 0.001));
    } else if (base == 'ml' && !options.any((o) => o.unite == 'litre')) {
      options.add(const SaleUnitOption(unite: 'litre', label: 'litre', factorToBase: 1000));
    }
  }

  static double factorToBase(ProduitModel p, String unite) {
    for (final opt in saleOptions(p)) {
      if (opt.unite == unite) return opt.factorToBase;
    }
    return 1;
  }

  static double priceForUnit(ProduitModel p, String unite) {
    return p.prixVenteUnitaire * factorToBase(p, unite);
  }

  /// Affichage stock lisible : « 455 pièces (5 paquets) »
  static String formatStock(ProduitModel p) {
    final base = p.uniteVente ?? 'pièce';
    final stockBase = p.stock;
    if (stockBase <= 0) return '0 $base';

    if (p.hasPackagingIntermediaire) {
      final perInter = p.quantiteBaseParIntermediaire!;
      final perLot = p.quantiteIntermediaireParLot!;
      final inter = p.uniteIntermediaire!;
      final lot = p.uniteAchat ?? 'lot';
      final totalPerLot = perInter * perLot;

      if (totalPerLot > 0 && stockBase >= totalPerLot) {
        final lots = stockBase / totalPerLot;
        if ((lots - lots.round()).abs() < 0.01) {
          return '${stockBase.toStringAsFixed(0)} $base (${lots.toStringAsFixed(0)} $lot)';
        }
      }
      if (perInter > 0 && stockBase >= perInter) {
        final interQty = stockBase / perInter;
        if ((interQty - interQty.round()).abs() < 0.01) {
          return '${stockBase.toStringAsFixed(0)} $base (${interQty.toStringAsFixed(0)} $inter)';
        }
      }
    } else if (p.quantiteParUnite > 1 && p.uniteAchat != null) {
      final lots = stockBase / p.quantiteParUnite;
      if ((lots - lots.round()).abs() < 0.01) {
        return '${stockBase.toStringAsFixed(0)} $base (${lots.toStringAsFixed(0)} ${p.uniteAchat})';
      }
    }

    return '${stockBase.toStringAsFixed(stockBase % 1 == 0 ? 0 : 1)} $base';
  }

  /// Nombre de lots d'achat (cartons, sacs…) encore en stock.
  static double lotsInStock(ProduitModel p) {
    final perLot = baseUnitsPerLot(p);
    if (perLot <= 1) return p.stock;
    return p.stock / perLot;
  }

  static StockLevel stockLevel(ProduitModel p) {
    if (p.stock <= 0) return StockLevel.rupture;

    final perLot = baseUnitsPerLot(p);
    if (perLot > 1 && p.uniteAchat != null && p.uniteAchat!.isNotEmpty) {
      final lots = lotsInStock(p);
      if (lots < 1 || lots <= 2) return StockLevel.faible;
      return StockLevel.ok;
    }

    if (p.stock <= 5) return StockLevel.faible;
    return StockLevel.ok;
  }

  /// Message d'alerte lisible : « Plus que 2 cartons », « Rupture », etc.
  static String? stockAlertMessage(ProduitModel p) {
    if (p.stock <= 0) return 'Rupture de stock';

    final perLot = baseUnitsPerLot(p);
    final lot = p.uniteAchat;
    if (perLot > 1 && lot != null && lot.isNotEmpty) {
      final lots = lotsInStock(p);
      if (lots < 1) {
        return 'Moins d\'1 $lot (${p.stock.toStringAsFixed(0)} ${p.uniteVente ?? 'unités'})';
      }
      if (lots <= 2) {
        final entier = lots.floor();
        if ((lots - entier).abs() < 0.05) {
          return entier <= 1 ? 'Plus que 1 $lot' : 'Plus que $entier $lot';
        }
        return 'Stock faible (${lots.toStringAsFixed(1)} $lot)';
      }
      return null;
    }

    if (p.stock <= 5) {
      return 'Stock faible (${p.stock.toStringAsFixed(0)} ${p.uniteVente ?? 'unités'})';
    }
    return null;
  }
}
