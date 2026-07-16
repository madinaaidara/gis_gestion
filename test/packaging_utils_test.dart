import 'package:flutter_test/flutter_test.dart';
import 'package:guissgestion_boutique/core/utils/packaging_utils.dart';
import 'package:guissgestion_boutique/data/models/produit_model.dart';

void main() {
  group('PackagingUtils conversions', () {
    test('500 g is exactly half of one kilogram', () {
      final p = ProduitModel(
        nom: 'Riz',
        prixVenteUnitaire: 1000,
        uniteVente: 'kg',
        stock: 10,
      );

      expect(PackagingUtils.factorToBase(p, '500 g'), 0.5);
      expect(PackagingUtils.priceForUnit(p, '500 g'), 500);
    });

    test('250 g is exactly half of 500 g', () {
      final p = ProduitModel(
        nom: 'Riz',
        prixVenteUnitaire: 1000,
        uniteVente: 'kg',
        stock: 10,
      );

      expect(PackagingUtils.factorToBase(p, '250 g'), 0.25);
      expect(PackagingUtils.priceForUnit(p, '250 g'), 250);
      expect(
        PackagingUtils.priceForUnit(p, '250 g'),
        PackagingUtils.priceForUnit(p, '500 g') / 2,
      );
    });

    test('weight options preserve 1 kg equals 1000 g', () {
      final p = ProduitModel(
        nom: 'Sucre',
        prixVenteUnitaire: 2,
        uniteVente: 'g',
        stock: 5000,
      );

      expect(PackagingUtils.factorToBase(p, '250 g'), 250);
      expect(PackagingUtils.factorToBase(p, '500 g'), 500);
      expect(PackagingUtils.factorToBase(p, 'kg'), 1000);
      expect(PackagingUtils.priceForUnit(p, 'kg'), 2000);
    });

    test('500 ml is half a litre and 250 ml is its half', () {
      final p = ProduitModel(
        nom: 'Huile',
        prixVenteUnitaire: 1200,
        uniteVente: 'litre',
        stock: 10,
      );

      expect(PackagingUtils.priceForUnit(p, '500 ml'), 600);
      expect(PackagingUtils.priceForUnit(p, '250 ml'), 300);
    });

    test('fractional FCFA prices are not rounded before quantity calculation',
        () {
      final p = ProduitModel(
        nom: 'Riz',
        prixVenteUnitaire: 999,
        uniteVente: 'kg',
        stock: 10,
      );

      expect(PackagingUtils.priceForUnit(p, '500 g'), 499.5);
      expect(PackagingUtils.priceForUnit(p, '250 g'), 249.75);
      expect(PackagingUtils.formatSalePrice(499.5), '499.5');
      expect(PackagingUtils.formatSalePrice(249.75), '249.75');
    });

    test('formatQuantityBase keeps small stock values', () {
      expect(PackagingUtils.formatQuantityBase(0.001), '0.001');
      expect(PackagingUtils.formatQuantityBase(175), '175');
    });

    test('coutUnitaireBase uses lot content', () {
      final p = ProduitModel(
        nom: 'Riz',
        prixAchatTotal: 35000,
        uniteAchat: 'sac',
        uniteVente: 'kg',
        quantiteParUnite: 35,
        stock: 175,
      );
      expect(PackagingUtils.coutUnitaireBase(p), 1000);
    });
  });
}
