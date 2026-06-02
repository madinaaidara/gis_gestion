class UnitConverter {
  static double toBaseUnit({
    required double quantity,
    required String unit,
  }) {
    switch (unit) {
      // POIDS
      case 'kg':
        return quantity;
      case 'g':
        return quantity / 1000;

      // VOLUME
      case 'litre':
        return quantity;
      case 'ml':
        return quantity / 1000;

      // QUANTITÉ
      case 'piece':
        return quantity;

      default:
        return quantity;
    }
  }

  static double fromBaseUnit({
    required double quantity,
    required String unit,
  }) {
    switch (unit) {
      case 'kg':
        return quantity;
      case 'g':
        return quantity * 1000;

      case 'litre':
        return quantity;
      case 'ml':
        return quantity * 1000;

      case 'piece':
        return quantity;

      default:
        return quantity;
    }
  }
}