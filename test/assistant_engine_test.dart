import 'package:flutter_test/flutter_test.dart';
import 'package:guissgestion_boutique/core/services/assistant_engine.dart';
import 'package:guissgestion_boutique/core/services/assistant_predictions.dart';
import 'package:guissgestion_boutique/data/models/assistant_message.dart';

void main() {
  final engine = AssistantEngine();

  AssistantContext ctx({
    Map<String, dynamic>? summary,
    List<Map<String, dynamic>>? topProducts,
    List<StockForecast>? stockForecasts,
    double evolutionCaSemaine = 8.5,
    double projectedCaEndOfMonth = 900000,
  }) {
    return AssistantContext(
      shopName: 'Boutique Test',
      devise: 'FCFA',
      summary: summary ??
          {
            'ca_jour': 50000,
            'benefice_jour': 12000,
            'ventes_jour': 5,
            'ventes_comptant_jour': 3,
            'ventes_credit_jour': 2,
            'ca_comptant_jour': 30000,
            'ca_credit_jour': 20000,
            'panier_moyen_jour': 10000,
            'ca_semaine': 120000,
            'ventes_semaine': 14,
            'ca_mois': 450000,
            'benefice_mois': 90000,
            'ventes_mois': 48,
            'credits_en_cours': 2,
            'credits_reste_total': 35000,
            'stock_rupture': 1,
            'stock_faible': 2,
            'stock_ok': 17,
            'total_produits': 20,
            'marge_mois_percent': 20,
            'objectif_jour_percent': 85,
            'ca_moyen_jour_mois': 15000,
            'produits_alerte': [
              {'nom': 'Riz 25kg', 'niveau': 'rupture', 'stock': 0},
            ],
          },
      topProducts: topProducts ??
          [
            {'nom': 'Huile 1L', 'ca': 80000, 'quantite': 40},
            {'nom': 'Sucre', 'ca': 50000, 'quantite': 25},
          ],
      topCredits: [
        {'client_nom': 'Amadou Diallo', 'reste': 20000},
      ],
      evolutionCaMois: 12.5,
      evolutionCaSemaine: evolutionCaSemaine,
      projectedCaEndOfMonth: projectedCaEndOfMonth,
      dayOfMonth: 15,
      daysInMonth: 30,
      daysRemainingInMonth: 15,
      stockForecasts: stockForecasts ??
          [
            const StockForecast(nom: 'Riz 25kg', stock: 0, soldLast7Days: 14, daysUntilRupture: 0),
            const StockForecast(nom: 'Huile 1L', stock: 6, soldLast7Days: 14, daysUntilRupture: 3),
          ],
    );
  }

  test('répond au CA du jour', () {
    final answer = engine.answer('Quel est mon CA aujourd\'hui ?', ctx());
    expect(answer, contains('50'));
    expect(answer.toLowerCase(), contains('aujourd'));
  });

  test('projection fin de mois', () {
    final answer = engine.answer('Projection CA fin de mois ?', ctx());
    expect(answer.toLowerCase(), contains('projection'));
    expect(answer, contains('900'));
    expect(answer.toLowerCase(), contains('rythme'));
  });

  test('tendance sur 7 jours', () {
    final answer = engine.answer('Quelle est la tendance sur 7 jours ?', ctx());
    expect(answer.toLowerCase(), contains('7 derniers jours'));
    expect(answer, contains('8.5'));
  });

  test('prévision stock rupture', () {
    final answer = engine.answer('Quels produits vont bientôt être en rupture ?', ctx());
    expect(answer, contains('Huile 1L'));
    expect(answer.toLowerCase(), contains('rupture'));
  });

  test('répond aux crédits clients', () {
    final answer = engine.answer('Combien me doivent mes clients ?', ctx());
    expect(answer, contains('35'));
    expect(answer.toLowerCase(), contains('crédit'));
  });

  test('bilan du mois inclut projection', () {
    final answer = engine.answer('Fais-moi un bilan du mois', ctx());
    expect(answer.toLowerCase(), contains('projection fin de mois'));
    expect(answer, contains('900'));
  });

  test('AssistantPredictions calcule fin de mois', () {
    final now = DateTime(2026, 6, 15);
    final projected = AssistantPredictions.projectEndOfMonthCa(300000, now);
    expect(projected, 600000);
  });

  test('AssistantPredictions jours avant rupture', () {
    expect(AssistantPredictions.daysUntilStockOut(stock: 10, soldLast7Days: 14), 5);
    expect(AssistantPredictions.daysUntilStockOut(stock: 0, soldLast7Days: 5), 0);
    expect(AssistantPredictions.daysUntilStockOut(stock: 10, soldLast7Days: 0), isNull);
  });
}
