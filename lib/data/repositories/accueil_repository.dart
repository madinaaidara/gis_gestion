import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/packaging_utils.dart';
import '../models/produit_model.dart';

class AccueilRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isAnnulee(Map<String, dynamic> v) {
    final s = v['status']?.toString().toLowerCase() ?? '';
    return s == 'annulee' || s == 'annulée';
  }

  Future<Map<String, dynamic>> getDashboardSummary(String shopId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final weekStart = now.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        _fetchVentesRange(shopId, todayStart, todayEnd),
        _fetchVentesRange(shopId, weekStart, now),
        _fetchVentesRange(shopId, monthStart, now),
        _fetchCreditsEnCours(shopId),
        _fetchStockAlerts(shopId),
        _fetchRecentVentes(shopId, limit: 5),
        _countProduits(shopId),
      ]);

      final ventesJour = results[0] as List<Map<String, dynamic>>;
      final ventesSemaine = results[1] as List<Map<String, dynamic>>;
      final ventesMois = results[2] as List<Map<String, dynamic>>;
      final credits = results[3] as Map<String, dynamic>;
      final stock = results[4] as Map<String, dynamic>;
      final recent = results[5] as List<Map<String, dynamic>>;
      final totalProduits = results[6] as int;

      double sumCa(List<Map<String, dynamic>> v) =>
          v.fold(0.0, (s, x) => s + ((x['total'] as num?)?.toDouble() ?? 0));
      double sumBenefice(List<Map<String, dynamic>> v) =>
          v.fold(0.0, (s, x) => s + ((x['benefice_reel'] as num?)?.toDouble() ?? 0));

      int countComptant(List<Map<String, dynamic>> v) =>
          v.where((x) => x['est_credit'] != true).length;
      int countCredit(List<Map<String, dynamic>> v) =>
          v.where((x) => x['est_credit'] == true).length;
      double sumComptant(List<Map<String, dynamic>> v) => v
          .where((x) => x['est_credit'] != true)
          .fold(0.0, (s, x) => s + ((x['total'] as num?)?.toDouble() ?? 0));
      double sumCreditCa(List<Map<String, dynamic>> v) => v
          .where((x) => x['est_credit'] == true)
          .fold(0.0, (s, x) => s + ((x['total'] as num?)?.toDouble() ?? 0));

      final stockOk = (totalProduits - (stock['rupture'] as int? ?? 0) - (stock['faible'] as int? ?? 0))
          .clamp(0, totalProduits);
      final dayOfMonth = now.day;
      final caMoyenJourMois = dayOfMonth > 0 ? sumCa(ventesMois) / dayOfMonth : 0.0;
      final objectifJourPct = caMoyenJourMois > 0
          ? (sumCa(ventesJour) / caMoyenJourMois * 100).clamp(0, 150)
          : 0.0;

      return {
        'ca_jour': sumCa(ventesJour),
        'benefice_jour': sumBenefice(ventesJour),
        'ventes_jour': ventesJour.length,
        'ventes_comptant_jour': countComptant(ventesJour),
        'ventes_credit_jour': countCredit(ventesJour),
        'ca_comptant_jour': sumComptant(ventesJour),
        'ca_credit_jour': sumCreditCa(ventesJour),
        'panier_moyen_jour': ventesJour.isEmpty ? 0.0 : sumCa(ventesJour) / ventesJour.length,
        'ca_semaine': sumCa(ventesSemaine),
        'ventes_semaine': ventesSemaine.length,
        'ca_mois': sumCa(ventesMois),
        'benefice_mois': sumBenefice(ventesMois),
        'ventes_mois': ventesMois.length,
        'credits_en_cours': credits['count'],
        'credits_reste_total': credits['reste_total'],
        'stock_rupture': stock['rupture'],
        'stock_faible': stock['faible'],
        'produits_alerte': stock['produits_alerte'],
        'ventes_recentes': recent,
        'total_produits': totalProduits,
        'marge_mois_percent': sumCa(ventesMois) > 0
            ? (sumBenefice(ventesMois) / sumCa(ventesMois) * 100)
            : 0.0,
        'stock_ok': stockOk,
        'objectif_jour_percent': objectifJourPct,
        'ca_moyen_jour_mois': caMoyenJourMois,
      };
    } catch (e) {
      debugPrint('❌ Erreur getDashboardSummary: $e');
      return _emptySummary();
    }
  }

  Map<String, dynamic> _emptySummary() => {
        'ca_jour': 0.0,
        'benefice_jour': 0.0,
        'ventes_jour': 0,
        'ventes_comptant_jour': 0,
        'ventes_credit_jour': 0,
        'ca_comptant_jour': 0.0,
        'ca_credit_jour': 0.0,
        'panier_moyen_jour': 0.0,
        'ca_semaine': 0.0,
        'ventes_semaine': 0,
        'ca_mois': 0.0,
        'benefice_mois': 0.0,
        'ventes_mois': 0,
        'credits_en_cours': 0,
        'credits_reste_total': 0.0,
        'stock_rupture': 0,
        'stock_faible': 0,
        'produits_alerte': <Map<String, dynamic>>[],
        'ventes_recentes': <Map<String, dynamic>>[],
        'total_produits': 0,
        'marge_mois_percent': 0.0,
        'stock_ok': 0,
        'objectif_jour_percent': 0.0,
        'ca_moyen_jour_mois': 0.0,
      };

  Future<List<Map<String, dynamic>>> _fetchVentesRange(
    String shopId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _supabase
        .from('ventes')
        .select('total, benefice_reel, status, date_vente, nom_produit, est_credit, client_nom')
        .eq('shop_id', shopId)
        .gte('date_vente', start.toIso8601String())
        .lte('date_vente', end.toIso8601String());

    return List<Map<String, dynamic>>.from(response).where((v) => !_isAnnulee(v)).toList();
  }

  Future<Map<String, dynamic>> _fetchCreditsEnCours(String shopId) async {
    final response = await _supabase
        .from('credits')
        .select('reste, statut')
        .eq('shop_id', shopId)
        .eq('statut', 'en_cours');

    final rows = List<Map<String, dynamic>>.from(response);
    var resteTotal = 0.0;
    for (final r in rows) {
      resteTotal += (r['reste'] as num?)?.toDouble() ?? 0;
    }
    return {'count': rows.length, 'reste_total': resteTotal};
  }

  Future<Map<String, dynamic>> _fetchStockAlerts(String shopId) async {
    final response = await _supabase
        .from('produits')
        .select('id, nom, stock, quantite_par_unite, unite_achat, unite_vente, '
            'unite_intermediaire, quantite_base_par_intermediaire, quantite_intermediaire_par_lot')
        .eq('shop_id', shopId);

    var rupture = 0;
    var faible = 0;
    final alertes = <Map<String, dynamic>>[];

    for (final row in List<Map<String, dynamic>>.from(response)) {
      final p = ProduitModel.fromJson(row);
      switch (PackagingUtils.stockLevel(p)) {
        case StockLevel.rupture:
          rupture++;
          if (alertes.length < 5) {
            alertes.add({'nom': p.nom, 'niveau': 'rupture', 'stock': p.stock});
          }
        case StockLevel.faible:
          faible++;
          if (alertes.length < 5 && PackagingUtils.stockLevel(p) == StockLevel.faible) {
            alertes.add({'nom': p.nom, 'niveau': 'faible', 'stock': p.stock});
          }
        case StockLevel.ok:
          break;
      }
    }

    return {'rupture': rupture, 'faible': faible, 'produits_alerte': alertes};
  }

  Future<List<Map<String, dynamic>>> _fetchRecentVentes(String shopId, {int limit = 5}) async {
    final response = await _supabase
        .from('ventes')
        .select('id, nom_produit, total, date_vente, est_credit, status, client_nom')
        .eq('shop_id', shopId)
        .order('date_vente', ascending: false)
        .limit(limit + 5);

    return List<Map<String, dynamic>>.from(response)
        .where((v) => !_isAnnulee(v))
        .take(limit)
        .toList();
  }

  Future<int> _countProduits(String shopId) async {
    try {
      final response = await _supabase.from('produits').select('id').eq('shop_id', shopId);
      return List.from(response).length;
    } catch (_) {
      return 0;
    }
  }
}
