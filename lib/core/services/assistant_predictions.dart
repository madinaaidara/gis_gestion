/// Calculs prédictifs simples pour l'Assistant Gis (extrapolation linéaire).
class AssistantPredictions {
  static double projectEndOfMonthCa(double caMois, DateTime now) {
    final day = now.day;
    if (day <= 0 || caMois <= 0) return caMois;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyPace = caMois / day;
    return dailyPace * daysInMonth;
  }

  /// Jours avant rupture ; `0` si déjà en rupture ; `null` si pas assez de ventes.
  static int? daysUntilStockOut({
    required double stock,
    required double soldLast7Days,
  }) {
    if (stock <= 0) return 0;
    final dailyRate = soldLast7Days / 7;
    if (dailyRate < 0.05) return null;
    return (stock / dailyRate).ceil().clamp(1, 365);
  }

  static String trendLabel(double evolutionPercent) {
    if (evolutionPercent.abs() < 0.5) return 'stable';
    if (evolutionPercent >= 10) return 'forte hausse';
    if (evolutionPercent > 0) return 'hausse';
    if (evolutionPercent <= -10) return 'forte baisse';
    return 'baisse';
  }
}
