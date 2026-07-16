import 'package:flutter_test/flutter_test.dart';
import 'package:guissgestion_boutique/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter weight conversions', () {
    test('one kilogram equals 1000 grams', () {
      expect(UnitConverter.toBaseUnit(quantity: 1000, unit: 'g'), 1);
      expect(UnitConverter.fromBaseUnit(quantity: 1, unit: 'g'), 1000);
    });

    test('500 g is half a kilogram', () {
      expect(UnitConverter.toBaseUnit(quantity: 1, unit: '500 g'), 0.5);
    });

    test('250 g is half of 500 g', () {
      final halfKg = UnitConverter.toBaseUnit(quantity: 1, unit: '500 g');
      final quarterKg = UnitConverter.toBaseUnit(quantity: 1, unit: '250 g');
      expect(quarterKg, halfKg / 2);
    });
  });

  group('UnitConverter volume conversions', () {
    test('one litre equals 1000 millilitres', () {
      expect(UnitConverter.toBaseUnit(quantity: 1000, unit: 'ml'), 1);
      expect(UnitConverter.fromBaseUnit(quantity: 1, unit: 'ml'), 1000);
    });

    test('500 ml and 250 ml keep exact proportions', () {
      expect(UnitConverter.toBaseUnit(quantity: 1, unit: '500 ml'), 0.5);
      expect(UnitConverter.toBaseUnit(quantity: 1, unit: '250 ml'), 0.25);
    });
  });
}
