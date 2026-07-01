enum AssistantMessageRole { user, assistant }

class AssistantMessage {
  final AssistantMessageRole role;
  final String text;
  final DateTime createdAt;

  const AssistantMessage({
    required this.role,
    required this.text,
    required this.createdAt,
  });
}

class StockForecast {
  final String nom;
  final double stock;
  final double soldLast7Days;
  final int? daysUntilRupture;

  const StockForecast({
    required this.nom,
    required this.stock,
    required this.soldLast7Days,
    this.daysUntilRupture,
  });

  bool get isAlreadyOut => stock <= 0;
}

class AssistantContext {
  final String shopName;
  final String devise;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> topCredits;
  final double evolutionCaMois;
  final double evolutionCaSemaine;
  final double projectedCaEndOfMonth;
  final int dayOfMonth;
  final int daysInMonth;
  final int daysRemainingInMonth;
  final List<StockForecast> stockForecasts;

  const AssistantContext({
    required this.shopName,
    required this.devise,
    required this.summary,
    required this.topProducts,
    required this.topCredits,
    required this.evolutionCaMois,
    required this.evolutionCaSemaine,
    required this.projectedCaEndOfMonth,
    required this.dayOfMonth,
    required this.daysInMonth,
    required this.daysRemainingInMonth,
    required this.stockForecasts,
  });
}
