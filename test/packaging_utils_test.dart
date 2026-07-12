import 'package:flutter_test/flutter_test.dart';
import 'package:guissgestion_boutique/core/utils/packaging_utils.dart';
import 'package:guissgestion_boutique/data/models/produit_model.dart';

void main() {
  group('PackagingUtils conversions', () {
    test('gram factor label is not rounded to zero', () {
      const opt = SaleUnitOption(unite: 'g', label: 'g', factorToBase: 0.001);
      expect(PackagingUtils.saleOptionChipLabel(opt, 'kg'), 'g (×0.001 kg)');
    });

    test('ml factor label is not rounded to zero', () {
      const opt = SaleUnitOption(unite: 'ml', label: 'ml', factorToBase: 0.001);
      expect(PackagingUtils.saleOptionChipLabel(opt, 'litre'), 'ml (×0.001 litre)');
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

    test('priceForUnit scales to grams', () {
      final p = ProduitModel(
        nom: 'Riz',
        prixVenteUnitaire: 200,
        uniteVente: 'kg',
        stock: 175,
      );
      expect(PackagingUtils.priceForUnit(p, 'g'), 0.2);
      expect(PackagingUtils.formatSalePrice(0.2), '0.20');
    });
  });
}
