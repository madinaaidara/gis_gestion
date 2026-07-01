import 'package:flutter_test/flutter_test.dart';
import 'package:guissgestion_boutique/data/models/abonnement_model.dart';

void main() {
  group('AbonnementModel', () {
    test('isValid when active and not expired', () {
      final model = AbonnementModel(
        estActive: true,
        dateExpiration: DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        typeAbonnement: 'essai',
      );
      expect(model.isValid, isTrue);
      expect(model.daysRemaining, greaterThan(0));
      expect(model.planLabel, 'Essai gratuit');
    });

    test('isExpired when date passed', () {
      final model = AbonnementModel(
        estActive: true,
        dateExpiration: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      );
      expect(model.isValid, isFalse);
      expect(model.isExpired, isTrue);
    });
  });
}
