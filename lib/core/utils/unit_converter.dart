class UnitConverter {
  static double toBaseUnit({
    required double quantity,
    required String unit,
  }) {
    switch (unit) {
      // POIDS
      case 'kg':
        return quantity;
      case '500 g':
        return quantity * 0.5;
      case '250 g':
        return quantity * 0.25;
      case 'g':
        return quantity / 1000;

      // VOLUME
      case 'litre':
        return quantity;
      case '500 ml':
        return quantity * 0.5;
      case '250 ml':
        return quantity * 0.25;
      case 'ml':
        return quantity / 1000;

      // QUANTITÉ
      case 'piece':
      case 'pièce':
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
      case '500 g':
        return quantity / 0.5;
      case '250 g':
        return quantity / 0.25;
      case 'g':
        return quantity * 1000;

      case 'litre':
        return quantity;
      case '500 ml':
        return quantity / 0.5;
      case '250 ml':
        return quantity / 0.25;
      case 'ml':
        return quantity * 1000;

      case 'piece':
      case 'pièce':
        return quantity;

      default:
        return quantity;
    }
  }
}
