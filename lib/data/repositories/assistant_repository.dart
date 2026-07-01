import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/assistant_predictions.dart';
import '../models/assistant_message.dart';
import 'accueil_repository.dart';
import 'stats_repository.dart';

class AssistantRepository {
  final AccueilRepository _accueilRepo;
  final StatsRepository _statsRepo;
  final SupabaseClient _supabase;

  AssistantRepository({
    AccueilRepository? accueilRepo,
    StatsRepository? statsRepo,
    SupabaseClient? supabase,
  })  : _accueilRepo = accueilRepo ?? AccueilRepository(),
        _statsRepo = statsRepo ?? StatsRepository(),
        _supabase = supabase ?? Supabase.instance.client;

  Future<AssistantContext> loadContext({
    required String shopId,
    required String shopName,
    required String devise,
  }) async {
    try {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      final results = await Future.wait([
        _accueilRepo.getDashboardSummary(shopId),
        _statsRepo.getTopProducts(shopId, 'mois'),
        _statsRepo.getDashboardData(shopId, 'mois'),
        _statsRepo.getDashboardData(shopId, 'semaine'),
        _fetchTopCredits(shopId),
        _fetchStockForecasts(shopId),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      final topProductsData = results[1] as Map<String, dynamic>;
      final dashboardMois = results[2] as Map<String, dynamic>;
      final dashboardSemaine = results[3] as Map<String, dynamic>;
      final topCredits = results[4] as List<Map<String, dynamic>>;
      final stockForecasts = results[5] as List<StockForecast>;

      final caMois = (summary['ca_mois'] as num?)?.toDouble() ?? 0;
      final products = List<Map<String, dynamic>>.from(topProductsData['products'] ?? []);

      return AssistantContext(
        shopName: shopName,
        devise: devise,
        summary: summary,
        topProducts: products,
        topCredits: topCredits,
        evolutionCaMois: (dashboardMois['evolution_ca'] as num?)?.toDouble() ?? 0,
        evolutionCaSemaine: (dashboardSemaine['evolution_ca'] as num?)?.toDouble() ?? 0,
        projectedCaEndOfMonth: AssistantPredictions.projectEndOfMonthCa(caMois, now),
        dayOfMonth: now.day,
        daysInMonth: daysInMonth,
        daysRemainingInMonth: daysInMonth - now.day,
        stockForecasts: stockForecasts,
      );
    } catch (e) {
      debugPrint('❌ Erreur loadContext assistant: $e');
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      return AssistantContext(
        shopName: shopName,
        devise: devise,
        summary: {},
        topProducts: [],
        topCredits: [],
        evolutionCaMois: 0,
        evolutionCaSemaine: 0,
        projectedCaEndOfMonth: 0,
        dayOfMonth: now.day,
        daysInMonth: daysInMonth,
        daysRemainingInMonth: daysInMonth - now.day,
        stockForecasts: [],
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTopCredits(String shopId) async {
    try {
      final response = await _supabase
          .from('credits')
          .select('client_nom, reste, statut')
          .eq('shop_id', shopId)
          .eq('statut', 'en_cours')
          .order('reste', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur top credits assistant: $e');
      return [];
    }
  }

  Future<List<StockForecast>> _fetchStockForecasts(String shopId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));

      final results = await Future.wait([
        _supabase
            .from('produits')
            .select('nom, stock')
            .eq('shop_id', shopId),
        _supabase
            .from('ventes')
            .select('nom_produit, quantite, status, date_vente')
            .eq('shop_id', shopId)
            .gte('date_vente', weekStart.toIso8601String())
            .lte('date_vente', now.toIso8601String()),
      ]);

      final produits = List<Map<String, dynamic>>.from(results[0]);
      final ventes = List<Map<String, dynamic>>.from(results[1])
          .where((v) => !_isAnnulee(v))
          .toList();

      final soldByName = _aggregateSoldQuantities(ventes);
      final forecasts = <StockForecast>[];

      for (final row in produits) {
        final nom = row['nom']?.toString() ?? '';
        if (nom.isEmpty) continue;
        final stock = (row['stock'] as num?)?.toDouble() ?? 0;
        final sold = soldByName[nom] ?? 0;
        final days = AssistantPredictions.daysUntilStockOut(
          stock: stock,
          soldLast7Days: sold,
        );
        forecasts.add(StockForecast(
          nom: nom,
          stock: stock,
          soldLast7Days: sold,
          daysUntilRupture: days,
        ));
      }

      forecasts.sort((a, b) {
        if (a.isAlreadyOut && !b.isAlreadyOut) return -1;
        if (!a.isAlreadyOut && b.isAlreadyOut) return 1;
        final da = a.daysUntilRupture;
        final db = b.daysUntilRupture;
        if (da == null && db == null) return a.stock.compareTo(b.stock);
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

      return forecasts.take(12).toList();
    } catch (e) {
      debugPrint('❌ Erreur stock forecasts assistant: $e');
      return [];
    }
  }

  bool _isAnnulee(Map<String, dynamic> v) {
    final s = v['status']?.toString().toLowerCase() ?? '';
    return s == 'annulee' || s == 'annulée';
  }

  Map<String, double> _aggregateSoldQuantities(List<Map<String, dynamic>> ventes) {
    final agg = <String, double>{};
    final pattern = RegExp(r'^(.+?)\s*\(x\s*(\d+(?:\.\d+)?)\s*\)$', caseSensitive: false);

    for (final vente in ventes) {
      final nomRaw = vente['nom_produit']?.toString() ?? '';
      if (nomRaw.isEmpty) continue;

      final parts = nomRaw.split(', ');
      if (parts.length == 1 && !pattern.hasMatch(parts.first.trim())) {
        final qty = (vente['quantite'] as num?)?.toDouble() ?? 1;
        agg[nomRaw.trim()] = (agg[nomRaw.trim()] ?? 0) + qty;
        continue;
      }

      for (final part in parts) {
        final match = pattern.firstMatch(part.trim());
        if (match != null) {
          final name = match.group(1)!.trim();
          final qty = double.tryParse(match.group(2)!) ?? 1;
          agg[name] = (agg[name] ?? 0) + qty;
        }
      }
    }
    return agg;
  }
}
