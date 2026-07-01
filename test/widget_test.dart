import 'package:flutter_test/flutter_test.dart';
import 'package:guissgestion_boutique/data/models/abonnement_model.dart';

void main() {
  test('planLabel pro et annuel', () {
    expect(const AbonnementModel(typeAbonnement: 'pro').planLabel, 'Pro');
    expect(const AbonnementModel(typeAbonnement: 'annuel').planLabel, 'Annuel');
  });
}
